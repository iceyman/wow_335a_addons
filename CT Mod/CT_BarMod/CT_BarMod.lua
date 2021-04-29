------------------------------------------------
--                 CT_BarMod                  --
--                                            --
-- Intuitive yet powerful action bar addon,   --
-- featuring per-button positioning as well   --
-- as scaling while retaining the concept of  --
-- grouped buttons and action bars.           --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------
-- CT_BottomBar is listed in the toc file as an
-- optional dependency so that it will load
-- first. There is some code in CT_BarMod that
-- tests if CT_BottomBar is loaded.
--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_BarMod";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

--------------------------------------------
-- Variables

-- Local Copies
local tremove = tremove;
local type = type;
local GetActionTexture = GetActionTexture;

-- Referenced at multiple locations
local newButtonMeta;
local currentMode;
local currentButtonClass;
local actionButton = { };
local actionButtonList = { };
local savedButtons;
module.actionButtonList = actionButtonList;

module.maxBarNum = 11;  -- Maximum number of bars allowed
module.controlBarId = 11;  -- id number of the Control Bar
module.controlCancel = 132;  -- action id we're making use of on the control bar to show a cancel button

--------------------------------------------
-- Helpers

local currentHover;

local function updateHover(_, self)
	if ( not self ) then
		self = currentHover;
		if ( not self ) then
			return;
		end
	end
	if ( GetCVar("UberTooltips") == "1" ) then
		-- Note: GameTooltip_SetDefaultAnchor() will set Gametooltip.default to 1.
		-- If we end up not showing a tooltip (because no action associated
		-- with a button), then we want to make sure that the GameTooltip's OnHide
		-- script executes so that it can clear the GameTooltip.default value.
		-- To ensure the OnHide script is executed, set the tooltip to a single
		-- character right before calling GameTooltip:Hide(). That will force the
		-- tooltip to be shown if it wasn't already.
		GameTooltip_SetDefaultAnchor(GameTooltip, self);
	else
		local xthis = self:GetCenter();
		local xui = UIParent:GetCenter();
		if (xthis < xui) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		else
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		end
	end

	-- Note: If no action is associated with the button then no tooltip
	-- will be shown.
	if ( GameTooltip:SetAction(self.object.id) ) then
		currentHover = self;
	elseif (self.object.id == module.controlCancel) then
		GameTooltip:SetText(CANCEL or "Cancel");
		currentHover = self;
	else
		currentHover = nil;
	end
	if (module:getOption("hideTooltip")) then
		-- Before hiding the tooltip, set the tooltip to a character
		-- to ensure the tooltip gets shown. This will ensure that the
		-- GameTooltip's OnHide script will get executed when we hide
		-- the tooltip.
		GameTooltip:SetText(" ");
		GameTooltip:Hide();
	end
end

local actionButtonObjectData;
local function actionButtonObjectSkeleton()
	if ( not actionButtonObjectData ) then
		actionButtonObjectData = {
			-- Background
			"texture#all#i:icon##BACKGROUND",
			
			-- Artwork
			"texture#all#i:flash#hidden#Interface\\Buttons\\UI-QuickslotRed",
			"font#s:36:10#tl:-2:-2#i:hotkey#v:NumberFontNormalSmallGray##r",
			"font#br:-2:2#i:count#v:NumberFontNormal##r",
			
			-- Overlay
			"font#s:36:10#b:0:2#i:name#v:GameFontHighlightSmallOutline##OVERLAY",
			"texture#s:62:62#mid#i:border#hidden#Interface\\Buttons\\UI-ActionButton-Border#OVERLAY",
			
			-- OnLoad
			["onload"] = function(self)
				local normalTexture = self:CreateTexture(nil, "ARTWORK");
				local pushedTexture = self:CreateTexture(nil, "ARTWORK");
				local highlightTexture = self:CreateTexture(nil, "ARTWORK");
				local checkedTexture = self:CreateTexture(nil, "ARTWORK");
				local cooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate");
				
				normalTexture:SetWidth(66); normalTexture:SetHeight(66);
				normalTexture:SetPoint("CENTER", self, 0, -1);
				normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2");
				
				pushedTexture:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress");
				pushedTexture:SetAllPoints(self);
				
				highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square");
				highlightTexture:SetBlendMode("ADD");
				highlightTexture:SetAllPoints(self);
				
				checkedTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight");
				checkedTexture:SetBlendMode("ADD");
				checkedTexture:SetAllPoints(self);
				
				self:SetNormalTexture(normalTexture);
				self:SetPushedTexture(pushedTexture);
				self:SetHighlightTexture(highlightTexture);
				self:SetCheckedTexture(checkedTexture);
				
				self.border:SetBlendMode("ADD");
				self.cooldown = cooldown;
				self.normalTexture = normalTexture;
			end,
			
			-- OnEnter
			["onenter"] = function(self)
				updateHover(nil, self);
				module:schedule(1, true, updateHover);
			end,
			
			-- OnLeave
			["onleave"] = function(self)
				-- Before hiding the tooltip, assign some text to it to ensure that the
				-- tooltip gets shown. We need to do this because we won't have shown a
				-- a tooltip if there was no action associated with the button.
				-- We need to make sure the GameTooltip's OnHide script executes so that
				-- it will reset things like the GameTooltip.default value.
				GameTooltip:SetText(" ");
				GameTooltip:Hide();
				currentHover = nil;
				module:unschedule(updateHover, true);
			end,
			
			-- OnMouseDown
			["onmousedown"] = function(self, ...)
				self.object:onmousedown(self, ...);
			end,
			
			-- OnMouseUp
			["onmouseup"] = function(self, ...)
				self.object:onmouseup(self, ...);
			end,
			
			-- OnDragStart
			["ondragstart"] = function(self, ...)
				self.object:ondragstart(self, ...);
			end,
			
			-- OnDragStop
			["ondragstop"] = function(self, ...)
				self.object:ondragstop(self, ...);
			end,
			
			-- OnReceiveDrag
			["onreceivedrag"] = function(self, ...)
				self.object:onreceivedrag(self, ...);
			end,
			
			-- PostClick
			["postclick"] = function(self, ...)
				self.object:postclick(self, ...);
			end
		};
	end
	return "checkbutton#s:36:36#v:SecureActionButtonTemplate", actionButtonObjectData;
end

local actionButtonObjectPool = { };
local function getActionButton(id)
	local button;
	button = tremove(actionButtonObjectPool);
	if (not button) then
		button = module:getFrame(actionButtonObjectSkeleton, nil, "CT_BarModActionButton"..id);
	end
	return button
end

local function getActionButtonId()
	local num = #actionButtonList;
	for i = 1, num, 1 do
		if ( not actionButtonList[i] ) then
			return i;
		end
	end
	return num + 1;
end

--------------------------------------------
-- Action Button Class

module.actionButtonClass = actionButton;

-- Create a new object
function actionButton:new(...)
	local button = { };
	setmetatable(button, newButtonMeta);
	button:constructor(...);
	return button;
end

-- Destroy an object
function actionButton:drop()
	self:destructor();
end

-- Constructor, run on object creation
function actionButton:constructor(id, groupId, noInherit, resetMovable)

	if ( noInherit ) then
		return;
	end
	
	id = id or getActionButtonId();
	local button = getActionButton(id);
	local obj = savedButtons[id];
	
	if ( resetMovable ) then
		module:resetMovable(id);
		self.scale = UIParent:GetScale();
	else
		self.scale = button:GetScale();
	end
	
	self.group = groupId or ceil(id / 12);
	
	button:RegisterForClicks("AnyUp");
	button:RegisterForDrag("LeftButton", "RightButton");
	button:SetAttribute("type", "action");
	module:registerMovable(id, button);
	actionButtonList[id] = self;
	button.object = self;
	button.cooldown.object = self;
	
	self.button = button;
	self.id = id;
	self.name = button:GetName();
	
	self:savePosition();
	self:setMode(currentMode);
	self:setBinding();
end

-- Destructor, run on object destruction
function actionButton:destructor(noInherit)

	if ( noInherit ) then
		return;
	end
	
	self.button:Hide();
	actionButtonList[self.id] = nil;
	
	tinsert(self, actionButtonObjectPool);
end

-- General updater
function actionButton:update()
	-- Placeholder for derived classes
end

-- Update texture
function actionButton:updateTexture()
	self.button.icon:SetTexture(GetActionTexture(self.id));
end

-- Updates the options table for this button, or creates it
function actionButton:updateOptions()
	local id = self.id;
	local option = module:getOption(id);
	if ( option ) then
		-- Update table
	else
		-- Create new table
	end
end

-- Sets the editing mode
function actionButton:setMode(newMode)
	self:destructor(true);
	setmetatable(self, newButtonMeta);
	self:constructor(nil, nil, true);
	self:update();
end

-- Change a button's scale
function actionButton:setScale(scale)
	scale = min(max(scale, 0.35), 3);
	self:savePosition();
	self.scale = scale;
	self:updatePosition();
	
	if ( not self.moving ) then
		module:stopMovable(self.id);
	end
end

-- Start moving this button
function actionButton:move()
	self.moving = true;
	module:moveMovable(self.id);
end

-- Stop moving this button
function actionButton:stopMove()
	self.moving = nil;
	module:stopMovable(self.id);
	self:savePosition();
end

-- Save position for this session
function actionButton:savePosition()
	local scale, xPos, yPos = self.scale, self.button:GetCenter();
	self.xPos, self.yPos = xPos*scale, yPos*scale;
	self:updatePosition();
end

-- Update position, takes scale into account
function actionButton:updatePosition()
	local scale, xPos, yPos = self.scale, self.xPos, self.yPos;
	local button = self.button;

	if (button:IsProtected() and InCombatLockdown()) then
		return;
	end
	button:SetScale(scale);
	button:ClearAllPoints();
	button:SetPoint("CENTER", nil, "BOTTOMLEFT", xPos/scale, yPos/scale);
end

-- Set binding depending on saved option
function actionButton:setBinding(binding, delete)
	-- binding = binding or module:getOption("BINDING-"..self.id);
	if ( binding and not InCombatLockdown()) then
		if (delete) then
			SetBinding(binding, nil);
		else
			SetBindingClick(binding, self.name);
		end
	end
	self:updateBinding();
end

-- Fallback Placeholders
function actionButton:updateBinding() end
function actionButton:onmousedown() end
function actionButton:onmouseup() end
function actionButton:ondragstart() end
function actionButton:ondragstop() end
function actionButton:onreceivedrag() end
function actionButton:postclick() end

--------------------------------------------
-- Action Button List Handler

local lastMethod;
module.actionButtonList = actionButtonList;

local function doMethod(...)
	for key, value in pairs(actionButtonList) do
		value[lastMethod](value, select(2, ...));
	end
end
setmetatable(actionButtonList, { __index = function(key, value)
	local obj = currentButtonClass[value];
	if ( type(obj) == "function" ) then
		lastMethod = value; return doMethod;
	else return obj; end end });


--------------------------------------------
-- Event Handlers

local function eventHandler_SlotChanged(event, id)
	if ( id == 0 ) then
		actionButtonList:update();
	else
		local object = actionButtonList[id];
		if ( object ) then
			object:update();
		end
	end
end

module:regEvent("ACTIONBAR_SLOT_CHANGED", eventHandler_SlotChanged);

--------------------------------------------
-- Mode Handler

function module:setMode(newMode)
	if ( currentMode ~= newMode ) then
		if ( currentMode ) then
			module[currentMode.."Disable"](module);
		end
		newButtonMeta = module[newMode.."ButtonMeta"];
		currentButtonClass = module[newMode.."ButtonClass"];
		actionButtonList:setMode(newMode);
		currentMode = newMode;
		module[newMode.."Enable"](module);
	end
end

--------------------------------------------
-- Key Bindings

module.getBindingKey = function(buttonNum)
	-- Get key currently bound to the CT_BarMod button number.
	return GetBindingKey("CLICK CT_BarModActionButton" .. buttonNum .. ":LeftButton");
end

--[[
-- Key Bindings Purger
module:regEvent("UPDATE_BINDINGS", function()
	local GetBindingAction = GetBindingAction;
	local strmatch = strmatch;
	local key, action;
	for buttonNum, value in pairs(actionButtonList) do
		key = module:getOption("BINDING-" .. buttonNum);
		if ( key ) then
			action = GetBindingByKey(key);
			if ( action and tostring(buttonNum) ~= strmatch(action,"^CLICK CT_BarModActionButton(%d+)") ) then
				module:setOption("BINDING-" .. buttonNum, nil, true);
			end
		end
	end
end);
]]

--------------------------------------------
-- Group id/number conversion.

-- num == Index into the groupList table.
-- id  == Unique number assigned to the group.
--        This number is used in option and frame names.
--        It is independent of the bar's position in the groupList table.
-- Bar == Name of group.
--        This is what gets displayed on screen.

-- Bar  1 = id 10 = num  1
-- Bar  2 = id  1 = num  2
-- Bar  3 = id  2 = num  3
-- Bar  4 = id  3 = num  4
-- Bar  5 = id  4 = num  5
-- Bar  6 = id  5 = num  6
-- Bar  7 = id  6 = num  7
-- Bar  8 = id  7 = num  8
-- Bar  9 = id  8 = num  9
-- Bar 10 = id  9 = num 10
-- Bar 11 = id 11 = num 11

-- Originally there were 9 bars.
-- - Bar 1 was action ids 13 to 24.
-- - Bar 1 was stored at index 1 of the groupList table.
-- - Bar 2 was action ids 25 to 36.
-- - Bar 2 was stored at index 2 of the groupList table.
-- - Bars 3 through 9 were action ids 37 to 120.
-- - Bars 3 through 9 were stored at index 3 through 9 of the groupList table.
--
-- Later a 10th bar was added which used action ids 1 to 12.
-- - Bar 1 through Bar 9 were renamed Bar 2 through Bar 10.
-- - The new bar was named Bar 1.
-- - Saved options for all bar are stored in a table using a key
--   that consists of an option name and a number. Originally that
--   number was the index used to access the groupList table.
-- - When the new 10th bar was inserted at position 1 in the groupList
--   table, it caused the position of the other bars in the table
--   to shift by 1. This meant that the bar's position in the
--   groupList table could no longer be used to access the saved
--   option.
-- - To allow access to the correct saved option, an id number
--   was assigned to each group. The id number used was equal
--   to the bar's original position in the groupList table.
-- - The new bar which is now in position 1 of the groupList table
--   was assigned id number 10.
--
-- Later an 11th bar was added which used action ids 121 to 132.
-- - The new bar was assigned id number 11.

module.GroupNumToId = function(num)
	-- Convert group number to group id.
	local id;
	if (num == 1) then
		id = 10;
	else
		if (num <= 10) then
			id = num - 1;
		else
			id = num;
		end
	end
	return id;
end

module.GroupIdToNum = function(id)
	-- Convert group id to group number.
	local num;
	if (id == 10) then
		num = 1;
	else
		if (id <= 9) then
			num = id + 1;
		else
			num = id;
		end
	end
	return num;
end

--------------------------------------------
-- Slash command.

local function slashCommand(msg)
	local val1, val2;
	val1, msg = string.match(msg or "", "^(%S+)%s*(.*)$");
	val2, msg = string.match(msg or "", "^(%S+)%s*(.*)$");
	if (val1) then
		val1 = string.lower(val1);
		if (val1 == "hide" or val1 == "show") then
			-- val2 is the group number.
			val2 = floor(tonumber(val2) or 0);
			if (val2 < 1 or val2 > module.maxBarNum) then
				module:print("You must specify a bar number from 1 to " .. module.maxBarNum .. ".");
				return;
			else
				-- Value to assign to the option.
				local show = false;
				if (val1 == "show") then
					show = 1;
				end

				-- Convert group number into group id.
				local id = module.GroupNumToId(val2);

				-- Enable or disable the bar.
				-- If the bar is enabled it will either show or hide based on the
				-- configured visibility conditions.
				module:setOption("showGroup" .. id, show, true);

				return;
			end
		end
	end
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctbar", "/ctbm", "/ctbarmod");

--------------------------------------------
-- Mod Initialization

module.update = function(self, type, value)
	if ( type == "init" ) then
		-- Font object for use with the cooldown counts.
		module.CooldownFont = CreateFont("CT_BarMod_CooldownFont");
		module.CooldownFont:SetFontObject(GameFontNormalLarge);

		self:setMode("use");
		
		-- Set up our buttons
		--savedButtons = self:getOption("buttons");
		--if ( not buttons ) then
			savedButtons = { };
			module:setupPresetGroups();
		--else
		--	for key, value in ipairs(buttons) do
		--		actionButton:new();
		--	end
		--end
	end
	self:editUpdate(type, value);
	self:useUpdate(type, value);
	self:optionUpdate(type, value);
end
