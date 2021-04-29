------------------------------------------------
--                CT_BuffMod                  --
--                                            --
-- Mod that allows you to heavily customize   --
-- the display of buffs to your liking.       --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_BuffMod";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

module.auraUnit = "player";

--------------------------------------------
-- Variables & Options

-- Variables
local buffModFrame;

-- Options
local showBuffTimers = true;
local expandBuffs = true;
local frameWidth = 275;
local frameHeight = 390;
local sortType = 2;
local subSortType = 1;
local sortReverse;

local buffSize = 20;
local buffSpacing = 0;
local effectiveBuffSize = 20;

local expirationWarningTime1 = 15;
local expirationWarningTime2 = 60;
local expirationWarningTime3 = 180;

local resizeMode = 1;
local unlockWindow = true;
local playerLoggedIn;

local backgroundColors = {
	AURA = { 0.35, 0.8, 0.15, 0.5 },
	BUFF = { 0.1, 0.4, 0.85, 0.5 },
	ITEM = { 0.75, 0.25, 1, 0.75 },
	DEBUFF = { 1, 0, 0, 0.85 }
};

--------------------------------------------
-- Local copies

local ceil = ceil;
local sort = sort;
local format = format;
local type = type;
local GetTime = GetTime;

--------------------------------------------
-- BuffObject handling

local buffObject = { };

-- Metatable for the buff object
local buffObjectMeta = { __index = buffObject };

-- List of all buff objects...
local buffObjectList = { };
module.buffList = buffObjectList;

-- and also a way to execute a given method on all objects
local lastMethod;

local function doMethod(...)
	local method = buffObject[lastMethod];
	if ( method ) then
		for key, obj in ipairs(buffObjectList) do
			method(obj, select(2, ...));
		end
	end
end

setmetatable(buffObjectList, {
	__index = function(key, value)
		local obj = buffObject[value];
		if ( type(obj) == "function" ) then
			lastMethod = value;
			return doMethod;
		else
			return obj;
		end
	end
});

-- Get a new buff object
local buffObjectPool = { };

function module:getBuffObject()
	local obj = tremove(buffObjectPool) or { };
	setmetatable(obj, buffObjectMeta);
	return obj;
end

--------------------------------------------
-- BuffObject

--------------------
-- Frame skeleton

local function buttonOnLoad(self)
	self.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9);
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
end

local defaultClassColors = { r=0.82, g=1, b=0 };

local function buttonOnEnter(self)
	local parent = self.parent;
	local obj = parent.buffObject;

	if (module.lockBuffOnEnter) then
		obj:lock();
	end

	if (not module.showTooltips) then
		return;
	end

	local cursorX, cursorY = GetCursorPosition();
	local centerX, centerY = UIParent:GetCenter();
	centerX = centerX * UIParent:GetScale();
	if (cursorX < centerX) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	end
	if ( obj.type == "ITEM" ) then
		if (module.showItemDetails) then
			GameTooltip:SetInventoryItem(module.auraUnit, obj.bdIndex);
		else
			local timeleft = obj.expirationTime - GetTime();
			if (timeleft < 0) then
				timeleft = 0;
			end
			GameTooltip:SetText(obj.name);
			GameTooltip:AddLine(SecondsToTime(timeleft, nil, true));
		end
	else
		if ( obj.type == "DEBUFF" ) then
			GameTooltip:SetUnitDebuff(module.auraUnit, obj.bdIndex);
		else
			GameTooltip:SetUnitBuff(module.auraUnit, obj.bdIndex);
		end
		if (module.showSpellNumber and obj.spellId) then
			GameTooltip:AddLine("Spell Number " .. obj.spellId, 1, 1, 1);
		end
		if (module.showCasterName and obj.casterUnit and obj.casterName) then
			if (obj.casterName == UNKNOWN) then
				obj:setCasterUnit(obj.casterUnit);
			end
			if (obj.casterName) then
				GameTooltip:AddLine(obj.casterName);
			end
		end
	end
	GameTooltip:Show();
end

local function buttonOnLeave(self)
	local parent = self.parent;
	local obj = parent.buffObject;

	if (obj.locked) then
		obj:unlock();
	end

	module:hideTooltip();
end

local function buttonOnClick(self, button)
	local parent = self.parent;
	local obj = parent.buffObject;

	if ( button == "RightButton" ) then
		if ( obj.type == "ITEM" ) then
			local hand;
			if (obj.bdIndex == (INVSLOT_MAINHAND or 16)) then
				hand = 1; -- main hand
			else
				hand = 2; -- off hand
			end
			CancelItemTempEnchantment(hand);
		elseif ( obj.type == "BUFF" or obj.type == "AURA" ) then
			CancelUnitBuff(module.auraUnit, obj.bdIndex);
		end
	end
end

local buffObjectData;

local function buffObjectSkeleton()
	if ( not buffObjectData ) then
		buffObjectData = {
			["button#i:icon#l"] = {
					"texture#i:texture#all",
				["onload"] = buttonOnLoad,
				["onclick"] = buttonOnClick,
				["onenter"] = buttonOnEnter,
				["onleave"] = buttonOnLeave
			}
		};
	end
	return "frame#s:275:30", buffObjectData;
end

--------------------
-- Helper functions

local function updateKeyBind()
	if (InCombatLockdown()) then
		return;
	end
	if ( buffModFrame ) then
		local bindKey = GetBindingKey("CT_BUFFMOD_RECASTBUFFS");
		if ( bindKey ) then
			SetOverrideBindingClick(buffModFrame, false, bindKey, "CT_BUFFMOD_RECASTBUFFFRAME");
		else
			ClearOverrideBindings(buffModFrame);
		end
	end
end

local function getFrame()
	local frame = module:getFrame(buffObjectSkeleton, buffModFrame);
	frame:SetWidth(frameWidth);
	return frame;
end

local function computeFrameHeight()
	local numObjects = #buffObjectList;
	local lockedBuff = module.lockedBuff;
	if (lockedBuff) then
		if (numObjects < lockedBuff.locked) then
			numObjects = lockedBuff.locked;
		end
	end
	local height = 10 + numObjects * effectiveBuffSize - buffSpacing;
	if ( frameHeight > height ) then
		height = frameHeight;
	end
	return height;
end

local function updatePositions(minPosition)
	-- Update the index number assigned to each object in the buffObjectList starting from minPosition,
	-- and reposition the buff frames within the overall frame.
	local obj;
	if (minPosition) then
		-- We have to update all of the index values before we reposition the buffs
		-- in case one of them is locked.
		for i = minPosition, #buffObjectList, 1 do
			obj = buffObjectList[i];
			obj.index = i;
		end
	end
	-- Reposition the buff object frames.
	for i = (minPosition or 1), #buffObjectList, 1 do
		obj = buffObjectList[i];
		obj:position();
	end
end

local function updateDisplayStatus(isRemoving)
	-- Update the overall frame (set overall height, and hide/show the object frames).

	-- Determine the height to use for the overall frame.
	local newHeight = computeFrameHeight(expandBuffs);

	-- Current height of the overall frame.
	local height = buffModFrame:GetHeight();

	if (not expandBuffs) then
		-- The overall frame is to have a fixed height.
		-- Determine how many buffs we can display within that height.
		local numBuffs = floor((frameHeight - 10 + buffSpacing) / effectiveBuffSize * 1000 + 0.5) / 1000;

		-- Hide/Show the object frames.
		for key, obj in ipairs(buffObjectList) do
			local index = obj:getDisplayPosition();
			if (index > numBuffs) then
				obj.frame:Hide();
			else
				obj.frame:Show();
			end
		end

		-- Set the height of the overall frame
		buffModFrame:SetHeight(frameHeight);
		return;
	end
	
	-- Show all of the object frames.
	for key, obj in ipairs(buffObjectList) do
		obj.frame:Show();
	end
	
	-- Set the height of the overall frame.
	if (isRemoving) then
		if (height > newHeight) then
			buffModFrame:SetHeight(newHeight);
		end
	else
		if (newHeight > height) then
			buffModFrame:SetHeight(newHeight);
		end
	end
end

local function onUpdateNormal(self, elapsed)
	-- An OnUpdate function to update a buff object.
	local update = self.update - elapsed;
	if ( update <= 0 ) then
		local obj = self.buffObject;
		local newTime = obj.expirationTime - GetTime();
		if (newTime < 0) then
			newTime = 0;
		end
		obj.timeleft = newTime;
		obj:updateTimerBar();
		self.update = self.updateInterval;
	else
		self.update = update;
	end
end

local function onUpdateExpire(self, elapsed)
	-- An OnUpdate function to update an expiring buff object.
	local update = self.update - elapsed;
	if ( update <= 0 ) then
		local obj = self.buffObject;
		local newTime = obj.expirationTime - GetTime();
		if (newTime < 0) then
			newTime = 0;
		end
		obj.timeleft = newTime;
		obj:updateTimerBar();
		
		newTime = newTime % 2;
		
		if (newTime > 1) then
			self.icon:SetAlpha(2 - newTime);
		else
			self.icon:SetAlpha(newTime);
		end
		self.update = self.updateInterval;
	else
		self.update = update;
	end
end

local function setUpdater(frame, timeleft)
	-- Based on the amount of time left on the aura, assign the appropriate update function to the frame.
	frame:SetScript("OnUpdate", onUpdateNormal);
	if ( timeleft <= 60 ) then
		frame.updateInterval = 0.02;
	elseif ( timeleft <= 240 ) then
		frame.updateInterval = 0.05;
	elseif ( timeleft <= 540 ) then
		frame.updateInterval = 0.5;
	else
		frame.updateInterval = 1;
	end
	frame.update = 0;  -- Set to zero to force an immediate update next time the OnUpdate handler is called.
end

local buffSubSort;
local buffSortTypes = { AURA = 1, BUFF = 2, ITEM = 3, DEBUFF = 4 };

module.buffSortTypes = buffSortTypes;

local function buffSort1(t1, t2)
	-- Sort method 1 (type)
	local t1type = t1.type;
	local t2type = t2.type;
	
	if ( t1type == t2type ) then
		return buffSubSort(t1, t2);
	else
		if (sortReverse) then
			return buffSortTypes[t1type] > buffSortTypes[t2type];
		else
			return buffSortTypes[t1type] < buffSortTypes[t2type];
		end
	end
end

local function buffSort2(t1, t2)
	-- Sort method 2 (time)
	-- Default sort sequence for time is descending.
	local t1time = t1.timeleft;
	local t2time = t2.timeleft;

	if ( t1time == 0 ) then
		if ( t2time == 0 ) then
			-- Two zero times
			if (sortReverse) then
				return t1.name > t2.name;
			else
				return t1.name < t2.name;
			end
		else
			-- Time1 is zero (infinite), Time2 is non-zero.
			if (sortReverse) then
				return false;
			else
				return true;
			end
		end
	elseif ( t2time == 0 ) then
		-- Time1 is non-zero, Time2 is zero (infinite)
		if (sortReverse) then
			return true;
		else
			return false;
		end
	else
		-- Two non-zero times
		if (sortReverse) then
			return t1time < t2time;
		else
			return t1time > t2time;
		end
	end
end

local function buffSort3(t1, t2)
	-- Sort method 3 (order)
	if (sortReverse) then
		return t1.serial > t2.serial;
	else
		return t1.serial < t2.serial;
	end
end

local function buffSort4(t1, t2)
	-- Sort method 4 (name)
	if (sortReverse) then
		return t1.name > t2.name;
	else
		return t1.name < t2.name;
	end
end

local function timeFormat1(timeLeft)
	-- Time format 1 (unabbreviated minutes/seconds): 1 hour / 35 minutes
	timeLeft = ceil(timeLeft);
	if ( timeLeft > 3540 ) then
		-- Hours
		local hours = ceil(timeLeft / 3600);
		if ( hours ~= 1 ) then
			return format("%d hours", hours);
		else
			return "1 hour";
		end
	elseif ( timeLeft > 60 ) then
		-- Minutes
		local minutes = ceil(timeLeft / 60);
		if ( minutes ~= 1 ) then
			return format("%d minutes", minutes);
		else
			return "1 minute";
		end
	else
		-- Seconds
		if ( timeLeft ~= 1 ) then
			return format("%d seconds", timeLeft);
		else
			return "1 second";
		end
	end
end

local function timeFormat2(timeLeft)
	-- Time format 2 (abbreviated minutes/seconds): 1 hour / 35 min
	timeLeft = ceil(timeLeft);
	if ( timeLeft > 3540 ) then
		-- Hours
		local hours = ceil(timeLeft / 3600);
		if ( hours ~= 1 ) then
			return format("%d hours", hours);
		else
			return "1 hour";
		end
	elseif ( timeLeft > 60 ) then
		-- Minutes
		return format("%d min", ceil(timeLeft / 60));
	else
		-- Seconds
		return format("%d sec", timeLeft);
	end
end

local function timeFormat3(timeLeft)
	-- Time format 3 (single letter for hour/minute/second): 1h / 35m
	timeLeft = ceil(timeLeft);
	if ( timeLeft > 3540 ) then
		-- Hours
		return format("%dh", ceil(timeLeft / 3600));
	elseif ( timeLeft > 60 ) then
		-- Minutes
		return format("%dm", ceil(timeLeft / 60));
	else
		-- Seconds
		return format("%ds", timeLeft);
	end
end

local function timeFormat4(timeLeft)
	-- Time format 4 (single letter for hour/minute/second, and shows 2 values): 1h 35m / 35m 30s
	timeLeft = ceil(timeLeft);
	if ( timeLeft >= 3600 ) then
		-- Hours & Minutes
		local hours = floor(timeLeft / 3600);
		return format("%dh %dm", hours, floor((timeLeft - hours * 3600) / 60));
	elseif ( timeLeft > 60 ) then
		-- Minutes & Seconds
		return format("%dm %.2ds", floor(timeLeft / 60), timeLeft % 60);
	else
		-- Seconds
		return format("%ds", timeLeft);
	end
end

local function timeFormat5(timeLeft)
	-- Time format 5 (2 values with a colon): 1:35h / 1:35 / 0:35
	timeLeft = ceil(timeLeft);
	if ( timeLeft >= 3600 ) then
		-- Hours & Minutes
		local hours = floor(timeLeft / 3600);
		return format("%d:%.2dh", hours, floor((timeLeft - hours * 3600) / 60));
	else
		-- Minutes & Seconds
		return format("%.2d:%.2d", floor(timeLeft / 60), timeLeft % 60);
	end
end

local getFormattedTime = timeFormat1;
module.humanizeTime = timeFormat4;  -- used when displaying expiration warning time slider values in options window

-- Buff background colors
function module:updateBackgroundColor(type, color)
	if ( color ) then
		backgroundColors[type] = color;
	end
end

local function setBackgroundColor(background, type)
	background:SetVertexColor(unpack(backgroundColors[type]));
end

-- Recasting buffs
local buffQueue;
local buffButton;

buffButton = CreateFrame("Button", "CT_BUFFMOD_RECASTBUFFFRAME", nil, "SecureActionButtonTemplate");
buffButton:SetAttribute("unit", "player");
buffButton:SetAttribute("type", "spell");

buffButton:SetScript("PreClick", function(self)
	if ( buffQueue and not self:GetAttribute("spell") ) then
		if (not InCombatLockdown()) then
			self:SetAttribute("spell", buffQueue[#buffQueue]);
		end
	end
end);

buffButton:SetScript("PostClick", function(self)
	local spell = self:GetAttribute("spell");
	if (not InCombatLockdown()) then
		self:SetAttribute("spell", nil);
		if ( buffQueue and spell ) then
			for i = #buffQueue, 1, -1 do
				if ( buffQueue[i] == spell ) then
					tremove(buffQueue, i);
					return;
				end
			end
		end
	end
end);

local function setRecastSpell(spellName)
	if (not InCombatLockdown()) then
		buffButton:SetAttribute("spell", spellName);
		return true;
	end
	return false;
end

local function queueBuffRecast(buffName)
	if ( not buffQueue ) then
		buffQueue = { };
	end
	
	-- Make sure it's not in here already
	for key, value in ipairs(buffQueue) do
		if ( value == buffName ) then
			return;
		end
	end

	tinsert(buffQueue, buffName);
	return true;
end

local function removeBuffRecast(buffName)
	if ( buffQueue ) then
		for key, value in ipairs(buffQueue) do
			if ( value == buffName ) then
				tremove(buffQueue, key);
				return;
			end
		end
	end
end

module:regEvent("UPDATE_BINDINGS", updateKeyBind);

	
--------------------
-- Methods

local serial = 0;

function buffObject:getSortedIndex()
	-- Using the sort and subsort types, determine the position of the object within the list.
	-- Returns an index number into the buffObjectList where the buffObject should be inserted.

	if (sortType == 1) then
		-- Sorting by type ("BUFF", "DEBUFF", "AURA", "ITEM")
		local type = self.type;
		local typeIndex = buffSortTypes[type];

		local obj, objType;
		if (sortReverse) then
			for i = #buffObjectList, 1, -1 do
				obj = buffObjectList[i];
				if (obj ~= self) then
					objType = obj.type;
					if (objType == type) then
						-- Identical types, so perform a subsort...
						if (not buffSubSort(self, obj)) then
							return i + 1;
						end
					elseif (typeIndex < buffSortTypes[objType]) then
						return i + 1;
					end
				end
			end
		else
			for i = #buffObjectList, 1, -1 do
				obj = buffObjectList[i];
				if (obj ~= self) then
					objType = obj.type;
					if (objType == type) then
						-- Identical types, so perform a subsort...
						if (not buffSubSort(self, obj)) then
							return i + 1;
						end
					elseif (typeIndex > buffSortTypes[objType]) then
						return i + 1;
					end
				end
			end
		end
		return 1;

	elseif (sortType == 2) then
		-- Sorting by time remaining (and name in the case of auras)
		local timeleft = self.timeleft;
		local duration = self.duration;
		local name = self.name;

		local obj, objTimeleft, objDuration;
		if (sortReverse) then
			for i = #buffObjectList, 1, -1 do
				obj = buffObjectList[i];
				if (obj ~= self) then
					objTimeleft = obj.timeleft;
					objDuration = obj.duration;
					if (duration == 0) then
						if (objDuration == 0 and name < buffObjectList[i].name) then
							-- Both are auras (no duration), so sort by name.
							return i + 1;
						end
					elseif (objDuration == 0) then
						return i + 1;
					elseif (timeleft > objTimeleft) then
						return i + 1;
					end
				end
			end
		else
			for i = #buffObjectList, 1, -1 do
				obj = buffObjectList[i];
				if (obj ~= self) then
					objTimeleft = obj.timeleft;
					objDuration = obj.duration;
					if (duration == 0 ) then
						if ( objDuration == 0 and name > buffObjectList[i].name) then
							-- Both are auras (no duration), so sort by name.
							return i + 1;
						end
					elseif (objDuration == 0) then
						return i + 1;
					elseif (timeleft < objTimeleft) then
						return i + 1;
					end
				end
			end
		end
		return 1;

	elseif (sortType == 3) then
		-- Sorting by order
		local serial = self.serial;
		local index = self.index;
		if (sortReverse) then
			for i = #buffObjectList, 1, -1 do
				if (i ~= index) then
					if (serial < buffObjectList[i].serial) then
						return i + 1;
					end
				end
			end
		else
			for i = #buffObjectList, 1, -1 do
				if (i ~= index) then
					if (serial > buffObjectList[i].serial) then
						return i + 1;
					end
				end
			end
		end
		return 1;

	elseif (sortType == 4) then
		-- Sorting by name
		local name = self.name;
		local index = self.index;
		if (sortReverse) then
			for i = #buffObjectList, 1, -1 do
				if (i ~= index) then
					if (name < buffObjectList[i].name) then
						return i + 1;
					end
				end
			end
		else
			for i = #buffObjectList, 1, -1 do
				if (i ~= index) then
					if (name > buffObjectList[i].name) then
						return i + 1;
					end
				end
			end
		end
		return 1;
	end
end

function buffObject:sort()
	-- Sort this object into the buff object list.

	-- Remove the object from the last position it was in.
	local oldIndex = self.index;
	if (oldIndex) then
		tremove(buffObjectList, oldIndex);
	end
	
	-- Determine where the object should be in the list, and then insert it.
	local index = self:getSortedIndex();
	tinsert(buffObjectList, index, self);
	
	-- Update the index number assigned to each object.
	if (oldIndex and oldIndex < index) then
		-- Update from the old position to the end of the list.
		updatePositions(oldIndex);
	else
		-- Update from the insertion point to the end of the list.
		updatePositions(index);
	end
end

function buffObject:lock()
	-- Lock the buff's display position within the overall frame.
	-- Only one buff can be locked at a time.
	if (not module.lockedBuff) then
		self.locked = self.index;  -- Position of the buff while it is locked.
		module.lockedBuff = self;  -- This is the currently locked buff.
	end
end

function buffObject:unlock()
	-- Unlock the buff's display position within the overall frame.
	-- Only one buff can be locked at a time.
	if (self.locked) then
		self.locked = nil;
		if (module.lockedBuff == self) then
			module.lockedBuff = nil;
		end
		updatePositions();
		updateDisplayStatus();
	end
end

function buffObject:getDisplayPosition()
	-- Get the display position of the buff within the overall frame.
	local index = self.index;
	local lockedBuff = module.lockedBuff;

	-- If there is a locked buff, then we may need to adjust the position of the current buff.
	if (lockedBuff) then
		if (lockedBuff == self) then
			-- This is the locked buff, so use the locked position.
			index = self.locked;
		else
			-- This is not the locked buff.
			local lockedIndex = lockedBuff.index;  -- The unlocked position of the locked buff.
			local lockedAt = lockedBuff.locked;  -- The position where the locked buff was locked.

			-- Adjust the position of the current buff in order to avoid the locked buff's position.
			if (lockedIndex < lockedAt) then
				if (index <= lockedAt) then
					if (index > lockedIndex) then
						-- Display this buff one position sooner than normal.
						index = index - 1;
					end
				end
			elseif (lockedIndex > lockedAt) then
				if (index >= lockedAt) then
					if (index < lockedIndex) then
						-- Display this buff one position later than normal.
						index = index + 1;
					end
				end
			end
		end
	end

	return index;
end

function buffObject:position()
	-- Position the object's frame within the overall frame.
	local frame = self.frame;
	local index = self:getDisplayPosition();
	frame:ClearAllPoints();
	if (module.expandUpwards) then
		frame:SetPoint("BOTTOMLEFT", buffModFrame, 5, (5 - effectiveBuffSize) + index * effectiveBuffSize);
	else
		frame:SetPoint("TOPLEFT", buffModFrame, 5, (effectiveBuffSize - 5) - index * effectiveBuffSize);
	end
end

function buffObject:updateDimension()
	-- Update the size of the object's frame, icon, and spark.
	local frame = self.frame;
	local icon = frame.icon;
	local spark = frame.spark;
	
	if ( spark ) then
		spark:SetWidth(min(buffSize * 2/3, 25));
		spark:SetHeight(buffSize * 1.9);
	end
	
	icon:SetHeight(buffSize);
	icon:SetWidth(buffSize);

	frame:SetHeight(buffSize);
	frame:SetWidth(frameWidth);

	self:updateTimerBar();
end

function buffObject:display()
	-- ----------
	-- Update the aura's appearance.
	-- ---------
	local frame = self.frame;
	local type = self.type;
	local name = frame.name;
	local timeleft = frame.timeleft;
	local background = frame.background;
	local bgtimer = frame.bgtimer;
	local icon = frame.icon;
	local spark = frame.spark;
	local durationBelow;

	-- Set up the frame
	if ( module.colorBuffs ) then
		if ( not background ) then
			background = frame:CreateTexture(nil, "BACKGROUND");
			background:SetTexture("Interface\\AddOns\\CT_BuffMod\\Images\\barSmooth");
			frame.background = background;
		end
		if ( showBuffTimers ) then
			if ( not spark ) then
				spark = frame:CreateTexture(nil, "BORDER");
				spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
				spark:SetBlendMode("ADD");
				frame.spark = spark;
			end
			if ( module.showTimerBackground ) then
				if ( not bgtimer ) then
					bgtimer = frame:CreateTexture(nil, "BACKGROUND");
					bgtimer:SetTexture("Interface\\AddOns\\CT_BuffMod\\Images\\barSmooth");
					frame.bgtimer = bgtimer;
				end
			elseif ( bgtimer ) then
				bgtimer:Hide();
				bgtimer = nil;
			end
		elseif ( spark ) then
			spark:Hide();
			spark = nil;
		end
	elseif ( background ) then
		spark:Hide();
		spark = nil;
		background:Hide();
		background = nil;
		if ( bgtimer ) then
			bgtimer:Hide();
			bgtimer = nil;
		end
	end

	if ( module.showTimers ) then
		if ( not timeleft ) then
			timeleft = frame:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
			frame.timeleft = timeleft;
		end
	elseif ( timeleft ) then
		timeleft:Hide();
		timeleft = nil;
	end

	if ( module.showNames ) then
		if ( not name ) then
			name = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
			frame.name = name;
		end
	elseif ( name ) then
		name:Hide();
		name = nil;
	end

	if ( name and timeleft and type ~= "AURA" and buffSize >= 23 and module.durationBelow ) then
		durationBelow = true;
	end

	-- Position the elements
	if ( module.rightAlign ) then
		icon:ClearAllPoints();
		icon:SetPoint("RIGHT", frame, -10, 0);

		if ( name ) then
			name:ClearAllPoints();
			name:SetJustifyH("RIGHT");
			name:Show();

			if ( timeleft and type ~= "AURA" ) then
				if ( durationBelow ) then
					name:SetPoint("BOTTOMRIGHT", icon, "LEFT", -5, 2);
					name:SetPoint("LEFT", frame);
				else
					name:SetPoint("RIGHT", icon, "LEFT", -5, 0);
					name:SetPoint("LEFT", timeleft, "RIGHT");
				end
			else
				name:SetPoint("RIGHT", icon, "LEFT", -5, 0);
				name:SetPoint("LEFT", frame);
			end
		end

		if ( timeleft ) then
			timeleft:ClearAllPoints();
			timeleft:Show();

			if ( name ) then
				if ( durationBelow ) then
					timeleft:SetJustifyH("RIGHT");
					timeleft:SetPoint("TOPRIGHT", icon, "LEFT", -5, 3);
					timeleft:SetPoint("LEFT", frame, 0, 0);
				else
					timeleft:SetJustifyH("LEFT");
					timeleft:SetPoint("LEFT", frame, 0, 0);
				end
			else
				if (module.durationCenter) then
					timeleft:SetJustifyH("CENTER");
				else
					timeleft:SetJustifyH("RIGHT");
				end
				timeleft:SetPoint("RIGHT", icon, "LEFT", -5, 0);
				timeleft:SetPoint("LEFT", frame, 0, 0);
			end
		end

		if ( background ) then
			background:ClearAllPoints();
			background:SetPoint("TOPRIGHT", icon, "TOPLEFT");
			background:SetPoint("BOTTOM", frame);
			if ( spark ) then
				spark:ClearAllPoints();
				spark:SetPoint("CENTER", background, "LEFT");
			end

			if ( bgtimer ) then
				bgtimer:ClearAllPoints();
				bgtimer:SetPoint("TOPRIGHT", background, "TOPLEFT");
				bgtimer:SetPoint("BOTTOMLEFT", frame);
				bgtimer:Show();
			end
		end
	else
		icon:ClearAllPoints();
		icon:SetPoint("LEFT", frame);

		if ( name ) then
			name:ClearAllPoints();
			name:SetJustifyH("LEFT");
			name:Show();

			if ( timeleft and type ~= "AURA" ) then
				if ( durationBelow ) then
					name:SetPoint("BOTTOMLEFT", icon, "RIGHT", 5, 2);
					name:SetPoint("RIGHT", frame, -10, 0);
				else
					name:SetPoint("LEFT", icon, "RIGHT", 5, 0);
					name:SetPoint("RIGHT", timeleft, "LEFT");
				end
			else
				name:SetPoint("LEFT", icon, "RIGHT", 5, 0);
				name:SetPoint("RIGHT", frame, -10, 0);
			end
		end

		if ( timeleft ) then
			timeleft:ClearAllPoints();
			timeleft:Show();

			if ( name ) then
				if ( durationBelow ) then
					timeleft:SetJustifyH("LEFT");
					timeleft:SetPoint("TOPLEFT", icon, "RIGHT", 5, 3);
					timeleft:SetPoint("RIGHT", frame, -10, 0);
				else
					timeleft:SetJustifyH("RIGHT");
					timeleft:SetPoint("RIGHT", frame, -10, 0);
				end
			else
				if (module.durationCenter) then
					timeleft:SetJustifyH("CENTER");
				else
					timeleft:SetJustifyH("LEFT");
				end
				timeleft:SetPoint("LEFT", icon, "RIGHT", 5, 0);
				timeleft:SetPoint("RIGHT", frame, -10, 0);
			end
		end

		if ( background ) then
			background:ClearAllPoints();
			background:SetPoint("TOPLEFT", icon, "TOPRIGHT");
			background:SetPoint("BOTTOM", frame);
			if ( spark ) then
				spark:ClearAllPoints();
				spark:SetPoint("CENTER", background, "RIGHT");
			end

			if ( bgtimer ) then
				bgtimer:ClearAllPoints();
				bgtimer:SetPoint("TOPLEFT", background, "TOPRIGHT");
				bgtimer:SetPoint("BOTTOMRIGHT", frame, -10, 0);
				bgtimer:Show();
			end
		end
	end

	-- Set icon, frame & name settings
	icon.texture:SetTexture(self.texture);
	self:updateDimension();
	if ( name ) then
		name:SetText(self.name);
	end

	-- Set flash & timer
	if ( background ) then
		background:Show();

		-- Set our color
		if ( name ) then
			name:SetTextColor(1, 0.82, 0);
		end

		setBackgroundColor(background, type);

		-- Set background & spark
		if ( type == "AURA" or not showBuffTimers ) then
			background:SetWidth(frameWidth - 10 - buffSize);
			if ( spark ) then
				spark:Hide();
			end
		else
			if ( bgtimer ) then
				local r, g, b, a = background:GetVertexColor();
				bgtimer:SetVertexColor(r/1.35, g/1.35, b/1.35, a/2);
			end
			self:updateTimerBar();
		end
	end

	if ( type == "DEBUFF" and name ) then
		if ( module.colorCodeDebuffs ) then
			local dispelType = self.dispelType;
			if ( dispelType ) then
				local color = DebuffTypeColor[dispelType];
				if (color) then
					name:SetTextColor(color.r, color.g, color.b);
				else
					name:SetTextColor(1, 0.82, 0);
				end
			else
				name:SetTextColor(1, 0.82, 0);
			end
		elseif ( background ) then
			name:SetTextColor(1, 0.82, 0);
		else
			name:SetTextColor(1, 0, 0);
		end
	elseif (name) then
		name:SetTextColor(1, 0.8, 0, 1);
	end
end

function buffObject:startFlashing()
	self.frame:SetScript("OnUpdate", onUpdateExpire);
	self.frame.updateInterval = 0.02;
	self.frame.update = 0;
	self.isFlashing = true;
end

function buffObject:stopFlashing(timeleft)
	if (not timeleft) then
		self.frame:SetScript("OnUpdate", nil);
	else
		setUpdater(self.frame, timeleft);
	end
	self.isFlashing = nil;
end

function buffObject:checkExpiration()
	-- Check to see if it is time to flash the icon or display an expiration warning.

	local timeleft, duration;
	local displayWarning;

	duration = self.duration;
	timeleft = self.timeleft;

	if (timeleft <= 0) then
		return;
	end
	
	-- Start to flash this object's icon?
	if (timeleft <= 15 and module.flashIcons and not self.isFlashing) then
		self:startFlashing();
	end

	-- If we haven't displayed an expiration warning for this object yet...
	if (not self.showedWarning) then

		-- The duration must be at least 2 minutes, warnings must be enabled, and this must not be a debuff...
		if (duration > 119 and module.enableExpiration and self.type ~= "DEBUFF") then
			if (duration > 1800) then
				-- 30 min 1 second or greater
				if (timeleft <= expirationWarningTime3) then
					displayWarning = true;
				end
			elseif (duration > 600) then
				-- 10 min 1 second to 30 min
				if (timeleft <= expirationWarningTime2) then
					displayWarning = true;
				end
			else
				-- 2 min 0 sec to 10 min
				if (timeleft <= expirationWarningTime1) then
					displayWarning = true;
				end
			end
		end

		if (displayWarning) then
		     	-- Check options
		     	local canRecastKeyBind;
		     	local name;

			name = self.name;

			-- If you don't know how to cast this buff...
		     	if (not module:getSpell(name)) then
				-- If ignoring buffs you cannot cast...
		     		if (module.expirationCastOnly) then
		     			return;
		     		end
		     	else
		     		-- Add the buff to the recast queue
		     		canRecastKeyBind = queueBuffRecast(name) and GetBindingKey("CT_BUFFMOD_RECASTBUFFS");
		     	end

			-- Display the expiration message
			if (canRecastKeyBind) then
				module:printformat(module:getText("PRE_EXPIRATION_WARNING_KEYBINDING"),
					name, timeFormat1(timeleft), canRecastKeyBind);
			else
				module:printformat(module:getText("PRE_EXPIRATION_WARNING"),
					name, timeFormat1(timeleft));
			end

			-- Play a sound
			if (module.expirationSound) then
				PlaySoundFile("Sound\\Spells\\misdirection_impact_head.wav");
			end

			-- Remember that we've displayed a warning for this object.
			self.showedWarning = true;
		end
	end
end

function buffObject:setCasterUnit(casterUnit)
	-- Assign unit of the buff's caster and generate a
	-- string containing the caster's name (and possibly
	-- the caster's master's name) for use in the buff tooltip.
	local x;
	local casterName, casterClass, ccolors;
	local masterName, masterClass, mcolors;
	local masterUnit;

	self.casterUnit = casterUnit;

	-- Determine caster's name, class, and class colors.
	if (not casterUnit) then
		self.casterName = nil;
		return;
	end

	casterName = (UnitName(casterUnit)) or UNKNOWN;
	x, casterClass = UnitClass(casterUnit);
	if (casterClass and RAID_CLASS_COLORS) then
		ccolors = RAID_CLASS_COLORS[casterClass];
	end
	if (not ccolors) then
		ccolors = defaultClassColors;
	end

	if (not UnitIsPlayer(casterUnit)) then
		-- Determine the master's name, class, and class colors.
		if (casterUnit == "pet" or casterUnit == "vehicle") then
			masterUnit = "player";
		else
			local id;
			id = string.match(casterUnit, "^partypet(%d)$");
			if (id) then
				masterUnit = "party" .. id;
			else
				id = string.match(casterUnit, "^raidpet(%d%d?)$");
				if (id) then
					masterUnit = "raid" .. id;
				end
			end
		end
		if (masterUnit) then
			masterName = (UnitName(masterUnit)) or UNKNOWN;
			x, masterClass = UnitClass(masterUnit);
			if (masterClass and RAID_CLASS_COLORS) then
				mcolors = RAID_CLASS_COLORS[masterClass];
			end
			if (not mcolors) then
				mcolors = defaultClassColors;
			end
		end
	end

	-- Generate caster name to be used in the buff tooltip.
	if (casterName and masterName) then
		self.casterName = string.format("|cff%02x%02x%02x%s|r |cff%02x%02x%02x<%s>|r", ccolors.r * 255, ccolors.g * 255, ccolors.b * 255, casterName, mcolors.r * 255, mcolors.g * 255, mcolors.b * 255, masterName);
	elseif (casterName) then
		self.casterName = string.format("|cff%02x%02x%02x%s|r", ccolors.r * 255, ccolors.g * 255, ccolors.b * 255, casterName);
	else
		self.casterName = nil;
	end
end

function buffObject:add()
	-- ----------
	-- Add a buff object.
	-- ----------
	local frame;

	-- Get the frame to use to display this object.
	frame = self.frame;
	if (not frame) then
		-- Create a new frame.
		frame = getFrame();
	end
	
	frame.buffObject = self;
	
	-- Set up the object
	self.frame = frame;

	-- Set the frame's OnUpdate script.
	if (self.duration == 0) then
		-- This object has no duration, so we don't need to udpate the time remaining.
		frame:SetScript("OnUpdate", nil);
	else
		-- Assign the appropriate OnUpdate function to this frame based on the time remaining.
		setUpdater(frame, self.timeleft);
	end

	-- Update the appearance of the object.
	self:display();

	-- Continue via the renew() method...
	self:renew();
end

function buffObject:renew()
	-- ----------
	-- The object has been renewed, or is newly added.
	-- ----------
	local frame = self.frame;

	-- sortType: 1==Type, 2==Time, 3==Order, 4==Name
	-- subSortType: 1==Time, 2==Order, 3==Name
	if (
		not self.serial
		or (not module.keepRecastPosition and (sortType == 3 or (sortType == 1 and subSortType == 2)))
	) then
		serial = serial + 1;
		self.serial = serial;  -- For use when sorting by order
	end

	-- Remove this from buff recasting
	removeBuffRecast(self.name);

	-- If this object was flashing...
	if (self.isFlashing) then
		-- Stop the flashing and set the OnUpdate function based on the new time remaining.
		self:stopFlashing(self.timeleft);
	end

	-- Since this a new/renewed buff, we can reset the displayed expiration warning flag.
	self.showedWarning = nil;

	-- Set the countdown timer to 0 to force the next OnUpdate to udpate the timer bar.
	frame.update = 0;

	-- Display the object and make sure the alpha is at 1.
	frame:Show();
	frame.icon:SetAlpha(1);

	-- Update the position of the object
	self:sort();

	-- Update the time remaining
	self:updateTimeDisplay();

	-- Update the overall frame
	updateDisplayStatus();
end

function buffObject:drop()
	-- ----------
	-- Drop this buff object, and add it to the buff object pool
	-- so it can be re-used later.
	-- ----------
	local frame = self.frame;

	-- If flashing, stop it...
	if (self.isFlashing) then
		self:stopFlashing(nil);
	end

	if (self.locked) then
		self:unlock();
	end

	-- Remove the object from the buff object list.
	tremove(buffObjectList, self.index);

	-- Update the index values assigned to each object starting from this object's spot.
	updatePositions(self.index);

	-- Update the overall frame
	updateDisplayStatus(true);

	-- Ensure this object's frame is hidden, and that it no longer
	-- has an OnUpdate script.
	frame:Hide();
	frame:SetScript("OnUpdate", nil);

	-- Reset the object's properties so it is ready for re-use.
	self.bdIndex = nil;
	self.casterUnit = nil;
	self.casterName = nil;
	self.charges = nil;
	self.dispelType = nil;
	self.duration = nil;
	self.expirationTime = nil;
	self.locked = nil;
	self.name = nil;
	self.spellId = nil;
	self.texture = nil;
	self.timeleft = nil;
	self.type = nil;

	self.index = nil;
	self.isFlashing = nil;
	self.serial = nil;
	self.showedWarning = nil;

	-- Add the object back into the buff object pool.
	tinsert(buffObjectPool, self);
end

function buffObject:updateCharges()
	local charges;
	local icon, iconText;

	charges = self.charges;
	icon = self.frame.icon;
	iconText = icon.text;
	
	if (charges and charges > 1) then
		if (not iconText) then
			iconText = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
			iconText:SetPoint("BOTTOMRIGHT", icon, 5, 0);
			iconText:SetFont("ARIALN.TTF", 12, "MONOCHROME");
		end
		iconText:SetText(charges);
		icon.text = iconText;
	elseif (iconText) then
		iconText:SetText("");
	end
end

function buffObject:updateTimerBar()
	-- Update the timer bar.
	local frame = self.frame;
	local background = frame.background;
	if (not background) then
		return;
	end
	local spark = frame.spark;

	if (not showBuffTimers or self.duration == 0) then
		-- User doesn't want to see the aura timer bar, or this is a buff aura.
		-- Hide the spark graphic, and show the background at full width.
		if (spark) then
			spark:Hide();
		end
		background:SetWidth(frameWidth - buffSize - 10);
	else
		-- Show the spark graphic, and set the frame's background to a width
		-- based on the amount of time remaining on the aura, and the aura's duration.
		if (spark) then
			spark:Show();
		end
		background:SetWidth( max((frameWidth - buffSize - 10) * min(self.timeleft / self.duration, 1), 0.01) );
	end
end

function buffObject:updateTimeDisplay()
	-- Update the time remaining
	local frame = self.frame;
	local timeleftText = frame.timeleft;

	frame.icon.texture:SetTexture(self.texture);

	if (self.duration > 0) then
		if (timeleftText) then
			timeleftText:SetText(getFormattedTime(self.timeleft));
		end

		-- Check expiration warning
		self:checkExpiration();
	else
		-- No duration for this item, so don't display a time remaining.
		if (timeleftText) then
			timeleftText:SetText("");
		end
	end
	
	-- Update charges
	self:updateCharges();
end

--------------------------------------------
-- Main BuffMod Frame

local function updateDimensions(width, height)
	frameWidth, frameHeight = width, height;
	
	for key, obj in ipairs(buffObjectList) do
		obj.frame:SetWidth(width);
		obj:updateTimerBar();
	end
	updateDisplayStatus();
end

local function updateDragButtons()
	if ( unlockWindow ) then
		if (resizeMode == 2) then
			buffModFrame.resize:Hide();
			buffModFrame.resize2:Show();
		else
			buffModFrame.resize:Show();
			buffModFrame.resize2:Hide();
		end
	else
		buffModFrame.resize:Hide();
		buffModFrame.resize2:Hide();
	end
end

local function dragUpdate(self, elapsed)
	local x, y = GetCursorPosition();
	local width = ( x / self.scale ) - self.left + self.xoff;

	local height;
	if (resizeMode == 3) then
		height = (self.centerY - (y / self.scale) + self.yoff)*2;
	elseif (resizeMode == 2) then
		height = ( y / self.scale ) - self.bottom + self.yoff;
	else
		height = self.top - ( y / self.scale ) + self.yoff;
	end
	height = max(height, 25);

	local minHeight = computeFrameHeight();
	
	width = min(max(width, buffSize + 10.1), 500);
	self.parent:SetWidth(width);

	if ( not expandBuffs or height > minHeight ) then
		self.parent:SetHeight(height);
	else
		self.parent:SetHeight(minHeight);
	end
	
	self.time = ( self.time or 0 ) - elapsed;
	if ( self.time <= 0 ) then
		updateDimensions(width, height);
		self.time = 0.05;
	end
end

local function startDragging(self)
	local x, y = GetCursorPosition();
	local scale = UIParent:GetScale();

	self.left = self.parent:GetLeft();
	self.centerX, self.centerY = self.parent:GetCenter();
	self.top = self.parent:GetTop();
	self.bottom = self.parent:GetBottom();

	if (resizeMode == 2) then
		self.yoff = self.parent:GetTop() - y/scale;
	else
		self.yoff = y/scale - self.parent:GetBottom();
	end
	self.xoff = self.parent:GetRight() - x/scale;

	self.scale = scale;
	self:SetScript("OnUpdate", dragUpdate);
	self.background:SetVertexColor(1, 1, 1);
	
	GameTooltip:Hide();
end

local function stopDragging(self)
	local height = self.parent:GetHeight();
	local width = self.parent:GetWidth();

	module:setOption("frameWidth", width, true);
	module:setOption("frameHeight", height, true);
	updateDimensions(width, height);
	
	self.center = nil;
	self.scale = nil;
	self:SetScript("OnUpdate", nil);
	
	if ( self:IsMouseOver() ) then
		self:GetScript("OnEnter")(self);
	else
		self:GetScript("OnLeave")(self);
	end
end

local pointText = {"BOTTOMLEFT", "BOTTOMRIGHT", "TOPLEFT", "TOPRIGHT", "LEFT"};

local function setBuffModFrameAnchor()
	-- -----
	-- Set the anchor point of the buffmod frame.
	-- -----
	if (not playerLoggedIn) then
		return;
	end
	local frame = CT_BuffModFrame;
	local oldScale = frame:GetScale() or 1;
	local xOffset, yOffset;
	local anchorX, anchorY, anchorP;
	local relativeP;
	local centerX, centerY = UIParent:GetCenter();
	if (resizeMode == 3) then
		anchorX, anchorY = frame:GetCenter();
		anchorY = anchorY or (centerY / oldScale);
		anchorP = 5;  -- LEFT
	elseif (resizeMode == 2) then
		anchorY = frame:GetBottom() or 0;
		anchorP = 1;  -- BOTTOMLEFT
	else
		anchorY = frame:GetTop() or 0;
		anchorP = 3;  -- TOPLEFT
	end
	anchorX = frame:GetLeft() or 0;
	if (anchorY <= centerY / oldScale) then
		yOffset = anchorY;
		relativeP = 1;
	else
		yOffset = anchorY - (UIParent:GetTop() / oldScale);
		relativeP = 3;
	end
	if (anchorX <= centerX / oldScale) then
		xOffset = anchorX;
	else
		xOffset = anchorX - (UIParent:GetRight() / oldScale);
		relativeP = relativeP + 1;
	end
	frame:ClearAllPoints();
	frame:SetPoint(pointText[anchorP], "UIParent", pointText[relativeP], xOffset, yOffset);

	module:stopMovable("BUFFMOD");  -- stops moving and saves the current anchor point
end

local function resetWindowPosition()
	local frame = CT_BuffModFrame;
	module:resetMovable("BUFFMOD");
	frame:ClearAllPoints();
	frame:SetPoint("TOPLEFT", UIParent, "CENTER", -frameWidth/2, frameHeight/2);
	setBuffModFrameAnchor();  -- change the anchor point and save it
end
module.resetWindowPosition = resetWindowPosition;

local function buffFrameSkeleton()
	return "frame#r:0:75", {
		"font#b:t#i:title#CT BuffMod",
		"backdrop#tooltip",
		
		["button#s:16:16#i:resize#br"] = {
			"texture#s:12:12#br:-5:5#i:background#Interface\\AddOns\\CT_BuffMod\\Images\\resize",
			["onenter"] = function(self)
				self.background:SetVertexColor(1, 1, 1);
				if ( self.scale ) then return; end
				if (module.showWindowTooltips) then
					module:displayPredefinedTooltip(self, "RESIZE");
				end
			end,
			["onleave"] = function(self)
				module:hideTooltip();
				if ( self.scale ) then return; end
				self.background:SetVertexColor(1, 0.82, 0);
			end,
			["onload"] = function(self)
				self:SetFrameLevel(self:GetFrameLevel() + 2);
				self.background:SetVertexColor(1, 0.82, 0);
			end,
			["onmousedown"] = startDragging,
			["onmouseup"] = stopDragging
		},
		["button#s:16:16#i:resize2#tr"] = {
			"texture#s:12:12#tr:-5:-5#i:background#Interface\\AddOns\\CT_BuffMod\\Images\\resize2",
			["onenter"] = function(self)
				self.background:SetVertexColor(1, 1, 1);
				if ( self.scale ) then return; end
				if (module.showWindowTooltips) then
					module:displayPredefinedTooltip(self, "RESIZE");
				end
			end,
			["onleave"] = function(self)
				module:hideTooltip();
				if ( self.scale ) then return; end
				self.background:SetVertexColor(1, 0.82, 0);
			end,
			["onload"] = function(self)
				self:SetFrameLevel(self:GetFrameLevel() + 2);
				self.background:SetVertexColor(1, 0.82, 0);
			end,
			["onmousedown"] = startDragging,
			["onmouseup"] = stopDragging
		},
		["onenter"] = function(self)
			if ( self.resize.scale ) then return; end
			if (module.showWindowTooltips) then
				module:displayTooltip(self, "Left-click to drag.");
			end
		end,
		["onleave"] = module.hideTooltip,
		["onmousedown"] = function(self, button)
			if ( button == "LeftButton" ) then
				module:moveMovable("BUFFMOD");
			end
		end,
		["onmouseup"] = function(self, button)
			if ( button == "LeftButton" ) then
				self:StopMovingOrSizing();  -- stops moving and lets the game assign an anchor point
				setBuffModFrameAnchor();  -- change the anchor point and save it
			end
		end
	}
end

buffModFrame = module:getFrame(buffFrameSkeleton, nil, "CT_BuffModFrame");
module.buffFrame = buffModFrame;

--------------------------------------------
-- Slash command.

local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctbuff", "/ctbuffmod");


--------------------
-- Initialization & Options

module.unlockWindow = function(self, value)
	unlockWindow = value;
	buffModFrame:EnableMouse(value);
	updateDragButtons();
end

module.setBuffSize = function(self, value)
	if ( value ) then
		local oldBuffSize = buffSize;
		buffSize = value;
		effectiveBuffSize = buffSize + buffSpacing;
		for key, obj in ipairs(buffObjectList) do
			obj:display();
			obj:position();
		end
		updateDisplayStatus(oldBuffSize > buffSize);
	end
end

module.expandBuffs = function(self, enable)
	expandBuffs = enable;
	updateDisplayStatus(not enable);
end

module.setResizeMode = function(self, value)
	resizeMode = value;
	setBuffModFrameAnchor();
	updateDragButtons();
end

module.clampBuffWindow = function()
	local clamped = module.clampWindow ~= false;
	if (module.showBorder) then
		-- Clear the insets so that border can touch edge of screen.
		buffModFrame:SetClampRectInsets(0, 0, 0, 0);
	else
		-- Change insets so that borderless window can be dragged right to the edge of the screen.
		buffModFrame:SetClampRectInsets(5, -5, -5, 5);
	end
	buffModFrame:SetClampedToScreen(clamped);
end

module.showBuffTimers = function(self, enable)
	showBuffTimers = enable;
	buffObjectList:display();
end

module.setSortType = function(self, newSort)
	sortType = newSort or sortType;
	
	-- Re-sort our table
	if ( sortType == 1 ) then
		sort(buffObjectList, buffSort1);
	elseif ( sortType == 2 ) then
		sort(buffObjectList, buffSort2);
	elseif ( sortType == 3 ) then
		sort(buffObjectList, buffSort3);
	elseif ( sortType == 4 ) then
		sort(buffObjectList, buffSort4);
	end
	
	updatePositions(1);
	updateDisplayStatus();
end

module.setSubSortType = function(self, newSort)
	subSortType = newSort or subSortType;
	
	if ( subSortType == 1 ) then
		buffSubSort = buffSort2;
	elseif ( subSortType == 2 ) then
		buffSubSort = buffSort3;
	elseif ( subSortType == 3 ) then
		buffSubSort = buffSort4;
	end
	
	if ( sortType == 1 ) then
		sort(buffObjectList, buffSort1);
		updatePositions(1);
		updateDisplayStatus();
	end
end

module.setSortReverse = function(self, enable)
	sortReverse = enable;
	module.setSortType();
end

module.setExpiration = function(self, id, value)
	if ( id == 1 ) then
		expirationWarningTime1 = value;
	elseif ( id == 2 ) then
		expirationWarningTime2 = value;
	elseif ( id == 3 ) then
		expirationWarningTime3 = value;
	end
	buffObjectList:checkExpiration();
end

module.setTimeFormat = function(self, format)
	if ( format == 1 ) then
		getFormattedTime = timeFormat1;
	elseif ( format == 2 ) then
		getFormattedTime = timeFormat2;
	elseif ( format == 3 ) then
		getFormattedTime = timeFormat3;
	elseif ( format == 4 ) then
		getFormattedTime = timeFormat4;
	elseif ( format == 5 ) then
		getFormattedTime = timeFormat5;
	end
	buffObjectList:updateTimeDisplay();
end

module.setSpacing = function(self, spacing)
	buffSpacing = spacing;
	effectiveBuffSize = buffSize + spacing;
	updateDisplayStatus();
end

-- Blizzard shows the TemporaryEnchants frame once and then never shows/hides it again.
local hidEnchants;
module.hideBlizzardEnchants = function(self, value)
	-- Configure the option.
	if (value) then
		TemporaryEnchantFrame:Hide();
		hidEnchants = true;
	else
		-- Only show the frame if we have previously hidden it,
		-- that way we don't affect anything if the user leaves the option disabled.
		if (hidEnchants) then
			TemporaryEnchantFrame:Show();
			hidEnchants = nil;
		end
	end
end

-- Blizzard shows the BuffFrame frame once and then never shows/hides it again.
local hidBuffs;
module.hideBlizzardBuffs = function(self, value)
	-- Configure the option.
	if (value) then
		BuffFrame:Hide();
		hidBuffs = true;
	else
		-- Only show the frame if we have previously hidden it,
		-- that way we don't affect anything if the user leaves the option disabled.
		if (hidBuffs) then
			BuffFrame:Show();
			hidBuffs = nil;
		end
	end
end

-- Blizzard shows/hides the ConsolidatedBuffs frame as needed.
local hidConsolidated;
local consolidatedOption;
module.hideBlizzardConsolidated = function(self, value)
	-- Configure the option.
	consolidatedOption = value;  -- save option's value for use in the OnShow hook.
	if (value) then
		ConsolidatedBuffs:Hide();
		hidConsolidated = true;
	else
		-- Only show the frame if we have previously hidden it,
		-- that way we don't affect anything if the user leaves the option disabled.
		if (hidConsolidated) then
			-- Only show it if there's at least one consolidated buff.
			if ( BuffFrame.numConsolidated > 0 ) then
				ConsolidatedBuffs:Show();
			end
			hidConsolidated = nil;
		end
	end
end
ConsolidatedBuffs:HookScript("OnShow", function(self)
	if (consolidatedOption) then
		-- Override Blizzard's Show() by hiding the frame.
		ConsolidatedBuffs:Hide();
	end
end);


module.mainupdate = function(self, type, value)
	if ( type == "init" ) then
		self:registerMovable("BUFFMOD", buffModFrame, true);
		frameWidth = self:getOption("frameWidth") or frameWidth;
		frameHeight = self:getOption("frameHeight") or frameHeight;
		
		buffModFrame:SetWidth(frameWidth);
		buffModFrame:SetHeight(frameHeight);
		updateDimensions(frameWidth, frameHeight);
	end
end


local function playerLogin()
	playerLoggedIn = 1;
	setBuffModFrameAnchor();
end

module:regEvent("PLAYER_LOGIN", playerLogin);
