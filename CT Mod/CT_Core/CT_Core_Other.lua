------------------------------------------------
--                  CT_Core                   --
--                                            --
-- Core addon for doing basic and popular     --
-- things in an intuitive way.                --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local _G = getfenv(0);
local module = _G.CT_Core;
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS;

--------------------------------------------
-- Quest Levels

local displayLevels = false;

local questLogPrefixes = {
	[GROUP] = "+",
	[RAID] = "R",
	[RAID .. " (25)"] = "R",
	[RAID .. " (10)"] = "R",
	[PVP] = "P",
	[LFG_TYPE_DUNGEON] = "D",
};

local function toggleDisplayLevels(enable)
	displayLevels = enable;
end

-- Originally this was pre-hooking GetQuestLogTitle() but that was resulting
-- in some taint in WoW 3.3 which caused action blocked messages during combat
-- if you opend the World Map while the "Show quest objectives" option was enabled
-- (or if you enabled it after opening the World Map).

do
	-- Display quest levels in the left panel of the quest log frame.
	local setText;
	if (QuestLogScrollFrameButton1) then
		setText = QuestLogScrollFrameButton1.SetText;
	end
	local allowSetText = true;

	local function questLogScrollFrameButton_SetText(self, text)
		-- Refer to QuestLog_Update() in FrameXML\QuestLogFrame.lua
		if (not displayLevels or not allowSetText or not self or not setText) then
			return;
		end
		if ( not QuestLogFrame:IsShown() ) then
			return;
		end
		local numEntries, numQuests = GetNumQuestLogEntries();
		local questLogTitle = self;
		local questIndex = questLogTitle:GetID();
		if ( questIndex and numEntries and questIndex <= numEntries ) then
			local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(questIndex);
			if ( title and level and not isHeader ) then
				local prefix = questLogPrefixes[questTag or ""] or "";
				title = "[" .. level .. prefix .. "] " .. title;
				setText(questLogTitle, "  " .. title);
				allowSetText = false;
				QuestLogTitleButton_Resize(questLogTitle);
				allowSetText = true;
			end
		end
	end

	if (QuestLogScrollFrame) then
		local buttons = QuestLogScrollFrame.buttons;
		if (buttons) then
			local numButtons = #buttons;
			for i = 1, numButtons do
				local button = _G["QuestLogScrollFrameButton" .. i];
				if (button) then
					hooksecurefunc(button, "SetText", questLogScrollFrameButton_SetText);
				end
			end
		end
	end
end

do
	-- Display quest levels in the title of the quest detail frame (quest log and bottom of world map).
	local setText;
	if (QuestInfoTitleHeader) then
		setText = QuestInfoTitleHeader.SetText;
	end

	local function questInfoTitleHeader_SetText(self, text)
		-- Refer to QuestInfo_ShowTitle() in FrameXML\QuestInfo.lua.
		if (not displayLevels or not setText or not QuestInfoFrame) then
			return;
		end
		local questTitle;
		local level, questTag;
		if ( QuestInfoFrame.questLog ) then
			questTitle, level, questTag = GetQuestLogTitle(GetQuestLogSelection());
			if ( not questTitle ) then
				questTitle = "";
			end
			if ( IsCurrentQuestFailed() ) then
				questTitle = questTitle.." - ("..FAILED..")";
			end
			local prefix = questLogPrefixes[questTag or ""] or "";
			questTitle = "[" .. level .. prefix .. "] " .. questTitle;
		else
			questTitle = GetTitleText();
		end
		setText(self, questTitle);
	end

	hooksecurefunc(QuestInfoTitleHeader, "SetText", function(...)
		questInfoTitleHeader_SetText(...);
	end);
end

--------------------------------------------
-- Hail Mod

local function hail()
	local targetName = UnitName("target");
	if ( targetName ) then
		SendChatMessage("Hail, " .. targetName .. (((UnitIsDead("target") or UnitIsCorpse("target")) and "'s Corpse") or ""));
	else
		SendChatMessage("Hail");
	end
end

module.hail = hail;
module:setSlashCmd(hail, "/hail");

--------------------------------------------
-- Block trades when bank or guild bank is open

do
	local blockOption;
	local blockOriginal;
	local blockcvar = "blockTrades";

	local function restoreBlockState()
		-- Restore blocking to its original state, which could be disabled or enabled.
		if (blockOriginal) then
			SetCVar(blockcvar, blockOriginal);
			blockOriginal = nil;
		end
	end

	local function enableBlockState()
		-- Change blocking state to enabled.
		if (blockOriginal == nil) then
			-- Save the original blocking state before we change it.
			blockOriginal = GetCVar(blockcvar);
		end
		-- Blocking is now enabled.
		SetCVar(blockcvar, "1");
	end

	-- If leaving the world, or the window is being closed, then restore
	-- blocking to its original state.
	module:regEvent("PLAYER_LEAVING_WORLD", restoreBlockState);
	module:regEvent("BANKFRAME_CLOSED", restoreBlockState);
	module:regEvent("GUILDBANKFRAME_CLOSED", restoreBlockState);

	-- If the bank frame has just opened, and the user wants to block while
	-- at the bank, then start blocking.
	module:regEvent("BANKFRAME_OPENED", function()
		if (blockOption) then
			enableBlockState();
		end
	end);

	-- If the guild bank frame has just opened, and the user wants to block while
	-- at the guild bank, then start blocking.
	module:regEvent("GUILDBANKFRAME_OPENED", function()
		if (blockOption) then
			enableBlockState();
		end
	end);

	-- Configure blocking option.
	module.configureBlockTradesBank = function(block)
		blockOption = block; -- Save the option's value in a local variable
		if (blockOption) then
			-- User wants to block trades while at this window.
			-- If the frame is currently shown, then start blocking.
			if ( (BankFrame and BankFrame:IsShown()) or (GuildBankFrame and GuildBankFrame:IsShown()) ) then
				enableBlockState();
			end
		else
			-- User does not want to block trades while at this window.
			-- If we are currently blocking trades (ie. if we have the original
			-- blocking state saved), then restore to the original blocking state.
			if (blockOriginal) then
				restoreBlockState();
			end
		end
	end
end

--------------------------------------------
-- Tooltip Reanchoring

local tooltipAnchorNumber;
local tooltipAnchorMode = 1;  -- 1==Default, 2==On cursor, 3==On anchor frame, 4==On mouse
local tooltipAnchorDisplay = true;
local tooltipAnchorFrame;
local tooltipUpdateFrame;
local tooltipHooked;
local tooltipUpdateTimer = 0;
local tooltipMouseAnchor;
local tooltipMouseDisableFade;
local tooltipFrameDisableFade;

local tooltipStatusbarHooked;
local tooltipStatusbarTimer;
local tooltipStatusbarValue;
local tooltipStatusbarUpdating;
local tooltipStatusbarChanged;

local tooltipText = "Left-click to drag.\nRight-click to change anchor point.";
local tooltipsTooltipText = "|c00FFFFFFTooltip Anchor|r\n" .. tooltipText;

-- tooltipAnchorNumber values:
-- 1 == Top Left
-- 2 == Top Right
-- 3 == Bottom Right
-- 4 == Bottom Left
-- 5 == Top
-- 6 == Right
-- 7 == Bottom
-- 8 == Left
-- 9 == Automatic (used for mouse anchor only)
local anchorPositions = {
	{ seq = 1, mxoff = 20, myoff=-20, uyoff =  0, anchor = "TOPLEFT", relative = "BOTTOMLEFT", text = "Top Left" },
	{ seq = 3, mxoff =  0, myoff=  0, uyoff =  0, anchor = "TOPRIGHT", relative = "BOTTOMRIGHT", text = "Top Right" },
	{ seq = 5, mxoff =  0, myoff=  0, uyoff = 10, anchor = "BOTTOMRIGHT", relative = "TOPRIGHT", text = "Bottom Right" },
	{ seq = 7, mxoff =  0, myoff=  0, uyoff = 10, anchor = "BOTTOMLEFT", relative = "TOPLEFT", text = "Bottom Left" },
	{ seq = 2, mxoff =  0, myoff=-20, uyoff =  0, anchor = "TOP", relative = "BOTTOM", text = "Top" },
	{ seq = 4, mxoff =  0, myoff=  0, uyoff =  0, anchor = "RIGHT", relative = "LEFT", text = "Right" },
	{ seq = 6, mxoff =  0, myoff=  0, uyoff = 10, anchor = "BOTTOM", relative = "TOP", text = "Bottom" },
	{ seq = 8, mxoff = 25, myoff=  0, uyoff =  0, anchor = "LEFT", relative = "RIGHT", text = "Left" },
};

local function onMouseDownFunc(self, button)
	if ( button == "LeftButton" ) then
		module:moveMovable(self.movable);
	end
end

local function anchorFrameSkeleton()
	-- Updates the text
	return "button#st:HIGH#tl:mid:350:-200#s:100:30", {
		"backdrop#tooltip#0:0:0:0.75",
		"font#v:GameFontNormal#i:text",
		["onleave"] = module.hideTooltip,
		["onmousedown"] = onMouseDownFunc
	};
end

local function updateTooltipAnchorVisibility()
	if ( tooltipAnchorFrame ) then
		if ( tooltipAnchorMode == 3 and tooltipAnchorDisplay ) then
			tooltipAnchorFrame:Show();
		else
			tooltipAnchorFrame:Hide();
		end
	end
end

local function updateTooltipText(self)
	-- Update text shown in the movable tooltip anchor frame.
	local data = anchorPositions[tooltipAnchorNumber];
	if (data) then
		self.text:SetText(data.text);
	else
		self.text:SetText("");
	end
end

local function createTooltipAnchorFrame()
	local movable = "TOOLTIPANCHOR";	
	tooltipAnchorFrame = module:getFrame(anchorFrameSkeleton);
	updateTooltipText(tooltipAnchorFrame);
	updateTooltipAnchorVisibility();

	module:registerMovable(movable, tooltipAnchorFrame);
	tooltipAnchorFrame.movable = movable;

	tooltipAnchorFrame:SetScript("OnEnter",	function(self)
		module:displayTooltip(self, tooltipsTooltipText, true);
	end);

	tooltipAnchorFrame:SetScript("OnMouseUp", function(self, button)
		if ( button == "LeftButton" ) then
			module:stopMovable(self.movable);
		elseif ( button == "RightButton" ) then
			-- Update anchor & text
			local data = anchorPositions[tooltipAnchorNumber];
			if (data) then
				local seq = data.seq;
				if (IsShiftKeyDown()) then
					seq = seq - 1;
					if (seq < 1) then
						seq = #anchorPositions;
					end
				else
					seq = seq + 1;
					if (seq > #anchorPositions) then
						seq = 1;
					end
				end
				tooltipAnchorNumber = 1;
				for num, data in ipairs(anchorPositions) do
					if (data.seq == seq) then
						tooltipAnchorNumber = num;
						break;
					end
				end
			end
			module:setOption("tooltipFrameAnchor", tooltipAnchorNumber, true);
			updateTooltipText(self);
			if (CTCoreDropdownTooltipFrameAnchor) then
				-- Update the drop down menu in the options window
				local item = tooltipAnchorNumber;
				local frame = CTCoreDropdownTooltipFrameAnchor;
				local level = 1;
				CloseDropDownMenus(level);
				ToggleDropDownMenu(level, item, frame);
				UIDropDownMenu_SetSelectedValue(frame, item);
				CloseDropDownMenus(level);
			end

			-- Display tooltip & play sound
			self:GetScript("OnEnter")(self);
			PlaySound("UChatScrollButton");
		end
	end);
end

local function anchorTooltipToMouse(tooltip)
	-- Anchor the tooltip to the mouse's position
	local xoff, yoff, cursorX, cursorY, scale;
	local anchor, data;

	xoff = 0;
	yoff = 0;
	cursorX, cursorY = GetCursorPosition();
	scale = UIParent:GetEffectiveScale();
	cursorX = cursorX / scale;
	cursorY = cursorY / scale;

	if (tooltipMouseAnchor == #anchorPositions + 1) then
		-- Automatic anchor
		local topSide, leftSide;

		topSide = (cursorY < UIParent:GetTop() / 2);
		leftSide = (cursorX < UIParent:GetRight() / 2);

		if (topSide) then
			if (leftSide) then
				anchor = 4; -- BOTOMLEFT
			else
				anchor = 3; -- BOTTOMRIGHT
			end
		else
			if (leftSide) then
				anchor = 1; -- TOPLEFT
			else
				anchor = 2; -- TOPRIGHT
			end
		end
	else
		anchor = tooltipMouseAnchor;
	end

	data = anchorPositions[anchor];
	if (data) then
		-- Prevent cursor from covering up tooltip
		xoff = xoff + data.mxoff;
		yoff = yoff + data.myoff;
		-- Allow room for the unit's health bar
		if (tooltip:GetUnit()) then
			yoff = yoff + data.uyoff;
		end
		tooltip:ClearAllPoints();
		tooltip:SetPoint(data.anchor, UIParent, "BOTTOMLEFT", cursorX + xoff, cursorY + yoff);
	end
end

local function reanchorTooltip(tooltip, parent)
	-- Re-anchor the tooltip
	if (tooltipAnchorMode == 4) then
		-- To the mouse
		tooltip:SetOwner(parent, "ANCHOR_NONE");
		anchorTooltipToMouse(tooltip);
	elseif (tooltipAnchorMode == 3) then
		-- To the movable anchor frame
		local data = anchorPositions[tooltipAnchorNumber];
		if (data) then
			tooltip:SetOwner(parent, "ANCHOR_NONE");
			if ( not tooltipAnchorFrame ) then
				createTooltipAnchorFrame();
			end
			tooltip:ClearAllPoints();
			if (tooltipAnchorFrame:IsShown()) then
				tooltip:SetPoint(data.anchor, tooltipAnchorFrame, data.relative);
			else
				tooltip:SetPoint(data.anchor, tooltipAnchorFrame, data.anchor);
			end
		end
	elseif (tooltipAnchorMode == 2) then
		-- To the cursor
		tooltip:SetOwner(parent, "ANCHOR_CURSOR");
	end
end

function CT_Core_ResetTooltipAnchor()
	if (tooltipAnchorFrame) then
		tooltipAnchorFrame:ClearAllPoints();
		tooltipAnchorFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 0);
		module:stopMovable(tooltipAnchorFrame.movable);
	end
end

local function CT_Core_GameTooltip_OnUpdate(self, elapsed)
	if (self.default) then
		if (tooltipAnchorMode == 4) then
			-- On mouse
			tooltipUpdateTimer = tooltipUpdateTimer + elapsed;
			if (tooltipUpdateTimer > 0.01) then
				tooltipUpdateTimer = 0;
				anchorTooltipToMouse(self);
				if (tooltipMouseDisableFade) then
					if (self:GetAlpha() < 0.99) then
						self:Hide();
					end
				end
			end
		elseif (tooltipAnchorMode == 3) then
			-- On anchor frame
			tooltipUpdateTimer = tooltipUpdateTimer + elapsed;
			if (tooltipUpdateTimer > 0.01) then
				tooltipUpdateTimer = 0;
				if (tooltipFrameDisableFade) then
					if (self:GetAlpha() < 0.99) then
						self:Hide();
					end
				end
			end
		end
	end
end

local function CT_Core_GameTooltip_OnShow(self)
	if (self.default) then
		if (tooltipAnchorMode == 4) then
			anchorTooltipToMouse(self);
		end
	end
end

local function CT_Core_GameTooltipStatusBar_OnValueChanged(self, ...)
	if (not tooltipStatusbarUpdating) then
		tooltipStatusbarValue = self:GetValue();
		if (not tooltipStatusbarChanged) then
			tooltipStatusbarChanged = true;
			tooltipStatusbarTimer = 0.1;
		end
	end
end

local function CT_Core_GameTooltipStatusBar_OnUpdate(self, elapsed, ...)
	if (tooltipStatusbarChanged) then
		tooltipStatusbarTimer = tooltipStatusbarTimer - elapsed;
		if (tooltipStatusbarTimer <= 0) then
			local value = self:GetValue();
			tooltipStatusbarUpdating = true;
			self:SetValue(0);
			self:SetValue(value);
			tooltipStatusbarUpdating = nil;
			if (value == tooltipStatusbarValue) then
				tooltipStatusbarChanged = nil;
			else
				tooltipStatusbarTimer = 0.1;
			end
		end
	end
end

function CT_Core_GameTooltip_SetDefaultAnchor(tooltip, parent, ...)
	if ( tooltip == GameTooltip and tooltipAnchorMode ) then
		if ( tooltipAnchorMode == 4 or tooltipAnchorMode == 3 ) then
			-- On mouse or On anchor.
			if (not tooltipHooked) then
				tooltipHooked = true;
				tooltip:HookScript("OnUpdate", CT_Core_GameTooltip_OnUpdate);
				tooltip:HookScript("OnShow", CT_Core_GameTooltip_OnShow);
			end
		end
		if ( tooltipAnchorMode == 2 ) then
			-- On cursor.
			--
			-- When using ANCHOR_CURSOR, the game does not always properly update the
			-- health status bar shown below a unit's tooltip. The game does update
			-- the status bar when the unit's health changes. However, if you hover over
			-- a non-injured unit and then over an injured unit who's health is not
			-- changing, the game will show a full health bar for the injured unit.
			-- Even though the status bar shows the injured unit at full health, the
			-- value assigned to the status bar is the unit's correct health value.
			--
			-- To work around this issue, we'll watch for the game to assign values to
			-- the status bar, and then schedule an update to be done a short time
			-- later. If we do the update too soon then the health bar won't change.
			-- To force the game to redraw the status bar, we'll set the bar's value
			-- to 0 and then back to its actual value.
			if (not tooltipStatusbarHooked) then
				tooltipStatusbarHooked = true;
				GameTooltipStatusBar:HookScript("OnValueChanged", CT_Core_GameTooltipStatusBar_OnValueChanged);
				GameTooltipStatusBar:HookScript("OnUpdate", CT_Core_GameTooltipStatusBar_OnUpdate);
			end
		end
		if ( tooltipAnchorMode > 1 ) then
			reanchorTooltip(tooltip, parent);
		end
	end
end
hooksecurefunc("GameTooltip_SetDefaultAnchor", CT_Core_GameTooltip_SetDefaultAnchor);

local function setTooltipRelocationStyle(tooltipStyle)
	tooltipAnchorMode = tooltipStyle;
	updateTooltipAnchorVisibility();
end

local function toggleTooltipAnchorVisibility(show)
	tooltipAnchorDisplay = show;
	
	if ( not tooltipAnchorFrame and show ) then
		createTooltipAnchorFrame();
	else
		updateTooltipAnchorVisibility();
	end
end

local function setTooltipFrameAnchor(anchor)
	tooltipAnchorNumber = (anchor or tooltipAnchorNumber) or 1;  -- default is 1 (top left)
	if (tooltipAnchorNumber > #anchorPositions) then
		tooltipAnchorNumber = #anchorPositions;
	end

	if ( tooltipAnchorDisplay ) then
		if ( not tooltipAnchorFrame ) then
			createTooltipAnchorFrame();
		end
		updateTooltipText(tooltipAnchorFrame);
	end
end

local function setTooltipMouseAnchor(anchor)
	tooltipMouseAnchor = (anchor or tooltipMouseAnchor) or 7;  -- default is 7 (bottom)
	if (tooltipMouseAnchor > #anchorPositions + 1) then  -- +1 to handle the "automatic" option
		tooltipMouseAnchor = #anchorPositions + 1;
	end
end

local function setTooltipFrameDisableFade(value)
	tooltipFrameDisableFade = value;
end

local function setTooltipMouseDisableFade(value)
	tooltipMouseDisableFade = value;
end

--------------------------------------------
-- Tick Mod

local tickFrame;
local tickDisplayType = 1;

local tickFormatHealth_1 = "Health: %d";
local tickFormatHealth_2 = "HP/Tick: %d";
local tickFormatHealth_3 = "HP: %d";
local tickFormatMana_1 = "Mana: %d";
local tickFormatMana_2 = "MP/Tick: %d";
local tickFormatMana_3 = "MP: %d";

local tickFrameWidth;
local tickCounter = 0.05;
local lastTickHealth, lastTickMana;

local function fadeObject(self)
	local alpha = self.alpha;
	if ( alpha and alpha > 0.25 ) then
		alpha = alpha - 0.03;
		self.alpha = alpha;
		self:SetAlpha(alpha);
		return true;
	end
end

local function fadeTicks(self, elapsed)
	tickCounter = tickCounter - elapsed;
	if ( tickCounter < 0 ) then
		local fadedHealth = fadeObject(self.health);
		local fadedMana = fadeObject(self.mana);
		if ( not fadedHealth and not fadedMana ) then
			self:SetScript("OnUpdate", nil);
		end
		tickCounter = 0.05;
	end
end

local function updateTickDisplay(key, diff)
	local obj = tickFrame[key];
	obj:SetText(format(obj.strFormat, diff));
	obj:SetAlpha(1);
	obj.alpha = 1;
	
	if ( tickFrameWidth ) then
		tickFrame:SetWidth(tickFrameWidth);
	end
	
	counter = 0.05;
	tickFrame:SetScript("OnUpdate", fadeTicks);
end

local function tickFrameSkeleton()
	return "button#tl:mid:350:-200#s:90:40", {
		"backdrop#tooltip",
		"font#i:health#t:0:-8",
		"font#i:mana#b:0:8",
		["onload"] = function(self)
			self:RegisterEvent("UNIT_HEALTH");
			self:RegisterEvent("UNIT_MANA");
			self:SetBackdropColor(0, 0, 0, 0.75);
			module:registerMovable("TICKMOD", self, true);
		end,
		["onevent"] = function(self, event, unit)
			if ( unit == "player" ) then
				if ( event == "UNIT_HEALTH" ) then
					local health = UnitHealth("player");
					local diff = health-lastTickHealth;
					if ( diff > 0 ) then
						updateTickDisplay("health", diff);
					end
					lastTickHealth = health;
				else
					local mana = UnitMana("player");
					local diff = mana-lastTickMana;
					if ( diff > 0 ) then
						updateTickDisplay("mana", diff);
					end
					lastTickMana = mana;
				end
			end
		end,
		["onenter"] = function(self)
			module:displayPredefinedTooltip(self, "DRAG");
		end,
		["onleave"] = module.hideTooltip,
		["onmousedown"] = function(self, button)
			if ( button == "LeftButton" ) then
				module:moveMovable("TICKMOD");
			end
		end,
		["onmouseup"] = function(self, button)
			if ( button == "LeftButton" ) then
				module:stopMovable("TICKMOD");
			elseif ( button == "RightButton" ) then
				module:resetMovable("TICKMOD");
				self:ClearAllPoints();
				self:SetPoint("CENTER", UIParent);
			end
		end
	};
end

local function updateTickFrameOptions()
	if ( not tickFrame ) then
		return;
	end
	
	-- Height
	local _, class = UnitClass("player");
	if ( UnitPowerType("player") == 0 or class == "DRUID" ) then
		tickFrame:SetHeight(40);
	else
		tickFrame:SetHeight(30);
	end
	
	-- Width & Format
	if ( not tickDisplayType or tickDisplayType == 1 ) then
		tickFrameWidth = 90;
		tickFrame.health.strFormat = tickFormatHealth_1;
		tickFrame.mana.strFormat = tickFormatMana_1;
	elseif ( tickDisplayType == 2 ) then
		tickFrameWidth = 100;
		tickFrame.health.strFormat = tickFormatHealth_2;
		tickFrame.mana.strFormat = tickFormatMana_2;
	elseif ( tickDisplayType == 3 ) then
		tickFrameWidth = 80;
		tickFrame.health.strFormat = tickFormatHealth_3;
		tickFrame.mana.strFormat = tickFormatMana_3;
	end
end

local function toggleTick(enable)
	if ( enable ) then
		if ( not tickFrame ) then
			tickFrame = module:getFrame(tickFrameSkeleton);
		end
		tickFrame:Show();
		updateTickFrameOptions();
		lastTickHealth, lastTickMana = UnitHealth("player"), UnitMana("player");

	elseif ( tickFrame ) then
		tickFrame:Hide();
	end
end

local function setTickDisplayType(mode)
	tickDisplayType = mode;
	updateTickFrameOptions();
end

--------------------------------------------
-- Casting Bar Timer

local displayTimers;

-- Create our frames
	local countDownText = CastingBarFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	countDownText:SetPoint("TOPRIGHT", 2, 5);
	countDownText:SetPoint("BOTTOMLEFT", CastingBarFrame, "BOTTOMRIGHT", -56, 2);
	CastingBarFrame.countDownText = countDownText;
	CastingBarFrame.ctElapsed = 0;
	
	local countDownTargetText = TargetFrameSpellBar:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	countDownTargetText:SetPoint("TOPRIGHT", 0, 5);
	countDownTargetText:SetPoint("BOTTOMLEFT", TargetFrameSpellBar, "BOTTOMRIGHT", -60, 0);
	TargetFrameSpellBar.countDownText = countDownTargetText;
	TargetFrameSpellBar.ctElapsed = 0;

-- Preparation for repositioning the normal texts
	local castingBarText = CastingBarFrameText;
	local castingBarTargetText = TargetFrameSpellBarText;

-- Hook the CastingBarFrame's OnUpdate
function CT_Core_CastingBarFrame_OnUpdate(self, secondsElapsed)
	if (not self.ctElapsed) then
		return;
	end

	local elapsed = ( self.ctElapsed or 0 ) - secondsElapsed;
	if ( elapsed < 0 ) then
		if ( displayTimers ) then
			-- We need to update
			if ( self.casting ) then
				self.countDownText:SetText(format("(%.1fs)", max(self.maxValue - self.value,0)));
			elseif ( self.channeling ) then
				self.countDownText:SetText(format("(%.1fs)", max(self.value,0)));
			else
				self.countDownText:SetText("");
			end
		end
		self.ctElapsed = 0.1;
	else
		self.ctElapsed = elapsed;
	end
end
hooksecurefunc("CastingBarFrame_OnUpdate", CT_Core_CastingBarFrame_OnUpdate);

local function toggleCastingTimers(enable)
	displayTimers = enable;
	castingBarText:ClearAllPoints();
	castingBarTargetText:ClearAllPoints();
	if ( enable ) then
		countDownText:Show();
		countDownTargetText:Show();
		
		castingBarText:SetPoint("TOPLEFT", 0, 5);
		castingBarText:SetPoint("BOTTOMRIGHT", countDownText, "BOTTOMLEFT", 10, 0);
		
		castingBarTargetText:SetPoint("TOPLEFT", 2, 5);
		castingBarTargetText:SetPoint("BOTTOMRIGHT", countDownTargetText, "BOTTOMLEFT", 10, 0);
	else
		countDownText:Hide();
		countDownTargetText:Hide();
		
		castingBarText:SetWidth(0);
		castingBarText:SetPoint("TOP", 0, 5);
		
		castingBarTargetText:SetWidth(0);
		castingBarTargetText:SetPoint("TOP", 0, 5);
	end
end

--------------------------------------------
-- Player Notes

local guildNotes, friendNotes, ignoreNotes;
local showGuildNotes, showFriendNotes, showIgnoreNotes;
local playerNoteButtons;
local noteFrame;
local forceNotesUpdate;

local function updatePlayerNotes(save)
	if ( save ) then
		module:setOption("guildNotes", guildNotes, true);
		module:setOption("friendNotes", friendNotes, true);
		module:setOption("ignoreNotes", ignoreNotes, true);
	else
		guildNotes = module:getOption("guildNotes");
		friendNotes = module:getOption("friendNotes");
		ignoreNotes = module:getOption("ignoreNotes");
	end
end


local function updateNote(self, playerName)
	local text = (self.wideEditBox):GetText();
	if ( text ~= "" ) then
		currentNoteType[playerName] = text;
	else
		currentNoteType[playerName] = nil;
	end
	if ( currentNoteType == guildNotes ) then
		GuildStatus_Update();
	elseif ( currentNoteType == friendNotes ) then
		FriendsList_Update();
	else
		IgnoreList_Update();
	end
	updatePlayerNotes(true);
end

local function getNoteDialogTable()
	return {
		text = module:getText("EDITING"),
		button1 = TEXT(ACCEPT),
		button2 = TEXT(CANCEL),
		hasEditBox = 1,
		hasWideEditBox = 1,
		maxLetters = 128,
		whileDead = 1,
		OnAccept = function(self, playerName)
			updateNote(self, playerName);
		end,
		timeout = 0,
		EditBoxOnEnterPressed = function(self, playerName)
			updateNote(self:GetParent(), playerName);
			self:GetParent():Hide();
		end,
		EditBoxOnEscapePressed = function(self, playerName)
			self:GetParent():Hide();
		end,
		hideOnEscape = 1
	};
end

local function editNote(playerName, noteType)
	if ( not StaticPopupDialogs["PLAYERNOTE_EDIT"] ) then
		StaticPopupDialogs["PLAYERNOTE_EDIT"] = getNoteDialogTable();
	end
	
	local coloredName;
	if ( noteType == ignoreNotes ) then
		coloredName = "|c00FF0000"..playerName.."|r";
	else
		coloredName = "|c0000FF00"..playerName.."|r";
	end
	
	local dialog = StaticPopup_Show("PLAYERNOTE_EDIT", coloredName);
	local staticPopupName = StaticPopup_Visible("PLAYERNOTE_EDIT");
	local editBox = _G[staticPopupName.."WideEditBox"];
	
	currentNoteType = noteType;
	dialog.data = playerName;
	editBox:SetText(noteType[playerName] or "");
	editBox:HighlightText();
end

local function playerNoteSkeleton()
	return "button#s:16:16#st:TOOLTIP#cache", {
		["onload"] = function(self)
			local normalTexture = self:CreateTexture();
			local highlightTexture = self:CreateTexture();
			normalTexture:SetAllPoints(self);
			highlightTexture:SetAllPoints(self);
			highlightTexture:SetBlendMode("ADD");
			
			self.normalTexture = normalTexture;
			self:SetNormalTexture(normalTexture);
			self:SetHighlightTexture(highlightTexture);
			self:SetDisabledTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled");
			normalTexture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up");
			highlightTexture:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up");
		end,
		["onclick"] = function(self)
			editNote(self.name, self.type);
		end,
		["onenter"] = function(self)
			local tooltip = GameTooltip;
			tooltip:SetOwner(self, "ANCHOR_RIGHT");
			tooltip:ClearLines();
			tooltip:AddLine(module:getText("CLICKEDIT"), 1, 0.7, 0);
			tooltip:AddLine(self.note, 0.9, 0.9, 0.9, 1);
			tooltip:Show();
		end,
		["onleave"] = module.hideTooltip
	};
end

local function getPlayerNoteButton(index)
	local obj = playerNoteButtons[index];
	if ( not obj ) then
		obj = module:getFrame(playerNoteSkeleton);
		playerNoteButtons[index] = obj;
	end
	return obj;
end

--------------------------------------------
-- Friends notes

local function updateFriendsDisplay(framePrefix, frameOffset, tbl, parent, enabled)
	local numButtons = 0;
	local frame, name;
	local btn;
	
	if ( playerNoteButtons ) then
		numButtons = #playerNoteButtons;
	else
		playerNoteButtons = { };
	end
	
	numButtons = FriendsFrameFriendsScrollFrame.numButtons;

	for index = 1, numButtons do
		btn = getPlayerNoteButton(index);
		if ( not enabled ) then
			btn:Hide();
		else
			frame = _G[framePrefix .. index];

			name = nil;
			if ( frame.buttonType ) then
				if ( frame.buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
					name = GetFriendInfo(frame.id);
				end
			end

			if ( not name ) then
				btn:Hide();
			else			
				local note = tbl[name];
				if ( note ) then
					btn.note = note;
					btn.normalTexture:SetVertexColor(1.0, 1.0, 1.0);
				else
					btn.note = "";
					btn.normalTexture:SetVertexColor(0.5, 0.5, 0.5);
				end

				btn.type = tbl;
				btn.name = name;
			
				btn:SetParent(parent or frame);
				btn:ClearAllPoints();
				btn:SetPoint("RIGHT", frame, "LEFT", frameOffset, 0);
				btn:SetFrameLevel(frame:GetFrameLevel()+1);
				btn:Show();
			end
		end
	end
end

local function CTCore_FriendsFrameFriendsScrollFrame_OnVerticalScroll()
	updateFriendsDisplay("FriendsFrameFriendsScrollFrameButton", 
		290, friendNotes, nil, showFriendNotes);

end
FriendsFrameFriendsScrollFrame:HookScript("OnVerticalScroll", CTCore_FriendsFrameFriendsScrollFrame_OnVerticalScroll);

local function CTCore_FriendsList_Update()
	if ( not showFriendNotes and not forceNotesUpdate ) then
		return;
	end
	if ( not FriendsListFrame:IsVisible() ) then
		return;
	end

	if ( not friendNotes ) then
		friendNotes = { };
	end

	updateFriendsDisplay("FriendsFrameFriendsScrollFrameButton", 
		290, friendNotes, nil, showFriendNotes);
end
hooksecurefunc("FriendsList_Update", CTCore_FriendsList_Update);

local function CTCore_FriendNotes_Toggle(enable)
	showFriendNotes = enable;
	forceNotesUpdate = true;
	CTCore_FriendsList_Update();
	forceNotesUpdate = nil;
end

--------------------------------------------
-- Ignore notes

local function updateIgnoreDisplay(framePrefix, frameOffset, tbl, parent, enabled)
	local numButtons = 0;
	local frame, name;
	local btn;
	
	if ( playerNoteButtons ) then
		numButtons = #playerNoteButtons;
	else
		playerNoteButtons = { };
	end
	
	numButtons = IGNORES_TO_DISPLAY;

	for index = 1, numButtons do
		btn = getPlayerNoteButton(index);
		if ( not enabled ) then
			btn:Hide();
		else
			frame = _G[framePrefix .. index];

			name = nil;
			if ( frame.type ) then
				if ( frame.type == SQUELCH_TYPE_IGNORE ) then
					name = GetIgnoreName(frame.index);
				end
			end

			if ( not name ) then
				btn:Hide();
			else			
				local note = tbl[name];
				if ( note ) then
					btn.note = note;
					btn.normalTexture:SetVertexColor(1.0, 1.0, 1.0);
				else
					btn.note = "";
					btn.normalTexture:SetVertexColor(0.5, 0.5, 0.5);
				end

				btn.type = tbl;
				btn.name = name;
			
				btn:SetParent(parent or frame);
				btn:ClearAllPoints();
				btn:SetPoint("RIGHT", frame, "LEFT", frameOffset, 0);
				btn:SetFrameLevel(frame:GetFrameLevel()+1);
				btn:Show();
			end
		end
	end
end

local function CTCore_IgnoreList_Update()
	if ( not showIgnoreNotes and not forceNotesUpdate ) then
		return;
	end
	if ( not IgnoreListFrame:IsVisible() ) then
		return;
	end

	if ( not ignoreNotes ) then
		ignoreNotes = { };
	end

	updateIgnoreDisplay("FriendsFrameIgnoreButton", 
		290, ignoreNotes, nil, showIgnoreNotes);
end
hooksecurefunc("IgnoreList_Update", CTCore_IgnoreList_Update);

local function CTCore_IgnoreNotes_Toggle(enable)
	showIgnoreNotes = enable;
	forceNotesUpdate = true;
	CTCore_IgnoreList_Update();
	forceNotesUpdate = nil;
end

--------------------------------------------
-- Guild member notes

local function updateGuildDisplay(offset, maxNum, framePrefix, frameOffset, tbl, parent, enabled)
	local numButtons = 0;
	local index, frame, name;
	local btn;
	
	if ( playerNoteButtons ) then
		numButtons = #playerNoteButtons;
	else
		playerNoteButtons = { };
	end
	
	for i=1, max(maxNum, numButtons), 1 do
		btn = getPlayerNoteButton(i);
		if ( i > maxNum or not enabled) then
			btn:Hide();
		else
			index = offset + i;
			name = GetGuildRosterInfo(index);
			frame = _G[framePrefix .. i];
			
			local note = tbl[name];
			if ( note ) then
				btn.note = note;
				btn.normalTexture:SetVertexColor(1.0, 1.0, 1.0);
			else
				btn.note = "";
				btn.normalTexture:SetVertexColor(0.5, 0.5, 0.5);
			end

			btn.type = tbl;
			btn.name = name;
			
			btn:SetParent(parent or frame);
			btn:ClearAllPoints();
			btn:SetPoint("RIGHT", frame, "LEFT", frameOffset, 0);
			btn:SetFrameLevel(frame:GetFrameLevel()+1);
			btn:Show();
		end
	end
end

local function CTCore_GuildStatus_Update()
	if ( not showGuildNotes and not forceNotesUpdate ) then
		return;
	end
	if ( not GuildFrame:IsVisible() ) then
		return;
	end

	local framePrefix;
	if ( FriendsFrame.playerStatusFrame ) then
		framePrefix = "GuildFrameGuildStatusButton";
	else
		framePrefix = "GuildFrameButton";
	end

	local maxDisplay = GUILDMEMBERS_TO_DISPLAY;
	local maxNum = GetNumGuildMembers();
	if ( not guildNotes ) then
		guildNotes = { };
	end

	updateGuildDisplay(FauxScrollFrame_GetOffset(GuildListScrollFrame),
		min(maxNum, maxDisplay), framePrefix,
		( ( maxDisplay >= maxNum ) and 320 ) or 303, guildNotes, 
		GuildFrame, showGuildNotes);
end
hooksecurefunc("GuildStatus_Update", CTCore_GuildStatus_Update);

local function CTCore_GuildNotes_Toggle(enable)
	showGuildNotes = enable;
	forceNotesUpdate = true;
	CTCore_GuildStatus_Update();
	forceNotesUpdate = nil;
end

--------------------------------------------
-- Alt+Right-Click to buy full stack

local function CT_Core_MerchantItemButton_OnModifiedClick(self, ...)
	local merchantAltClickItem = module:getOption("merchantAltClickItem") ~= false;  -- if option is nil then default to true
	if (merchantAltClickItem and IsAltKeyDown()) then
		local id = self:GetID();
		local maxStack = GetMerchantItemMaxStack(id);
		local money = GetMoney();
		local _, _, price, quantity = GetMerchantItemInfo(id);
		
		if ( maxStack == 1 and quantity > 1 ) then
			-- We need to check max stack count
			local _, _, _, _, _, _, _, stackCount = GetItemInfo(GetMerchantItemLink(id));
			if ( stackCount and stackCount > 1 ) then
				maxStack = floor(stackCount/quantity);
			end
		end
	
		if ( maxStack*price > money ) then
			maxStack = floor(money/price);
		end

		BuyMerchantItem(id, maxStack);
	end
end

hooksecurefunc("MerchantItemButton_OnModifiedClick", CT_Core_MerchantItemButton_OnModifiedClick);

--------------------------------------------
-- Alt Left Click to add item to auctions frame.

local function CT_Core_AddToAuctions(self, button)
	if (button == "LeftButton" and IsAltKeyDown()) then
		if (AuctionFrame and AuctionFrame:IsShown()) then
			local auctionAltClickItem = module:getOption("auctionAltClickItem");
			if (auctionAltClickItem and
				not CursorHasItem()
			) then
				if (not AuctionFrameAuctions:IsVisible()) then
					-- Switch to the "auctions" tab.
					AuctionFrameTab_OnClick(AuctionFrameTab3, 3);
				end
				-- Pickup and place item in the auction sell button.
				local bag, item = self:GetParent():GetID(), self:GetID();
				PickupContainerItem(bag, item);
				ClickAuctionSellItemButton(AuctionsItemButton, "LeftButton");
				AuctionsFrameAuctions_ValidateAuction();
				return true;
			end
		end
	end
	return false;
end

--------------------------------------------
-- Alt Left Click to initiate trade or add item to trade window.

local CT_Core_AddToTrade;

do
	local prepareTrade;
	local addItemToTrade;

	do
		local prepBag, prepItem, prepPlayer;
		local function clearTrade()
			prepBag, prepItem, prepPlayer = nil;
		end
		
		prepareTrade = function(bag, item, player) -- Local
			prepBag, prepItem, prepPlayer = bag, item, player;
			module:schedule(3, clearTrade);
		end

		addItemToTrade = function(bag, item)
			local slot = TradeFrame_GetAvailableSlot();
			if (slot) then
				PickupContainerItem(bag, item);
				ClickTradeButton(slot);
			end
		end

		module:regEvent("TRADE_SHOW", function()
			if ( prepBag and prepItem and UnitName("target") == prepPlayer ) then
				addItemToTrade(prepBag, prepItem);
			end
			clearTrade();
		end);
	end

	CT_Core_AddToTrade = function(self, button)
		if (button == "LeftButton" and IsAltKeyDown()) then
			if (TradeFrame) then
				if (not TradeFrame:IsShown()) then
					local tradeAltClickOpen = module:getOption("tradeAltClickOpen");
					if (tradeAltClickOpen and
						not CursorHasItem() and 
						UnitExists("target") and
						CheckInteractDistance("target", 2) and
						UnitIsFriend("player", "target") and
						UnitIsPlayer("target")
					) then
						-- Initiate a trade and in a few seconds pickup and add the item to the trade window.
						local bag, item = self:GetParent():GetID(), self:GetID();
						InitiateTrade("target");
						prepareTrade(bag, item, UnitName("target"));
						return true;
					end
				else
					local tradeAltClickAdd = module:getOption("tradeAltClickAdd");
					if (tradeAltClickAdd and
						not CursorHasItem()
					) then
						-- Pickup and add an item to the trade window.
						local bag, item = self:GetParent():GetID(), self:GetID();
						addItemToTrade(bag, item);
						return true;
					end
				end
			end
		end
		return false;
	end
end

--------------------------------------------
-- Handle clicks on item in a container frame.
-- Currently used by CT_Core and CT_MailMod.

local cfibomcTable = {};

function CT_Core_ContainerFrameItemButton_OnModifiedClick_Register(func)
	cfibomcTable[func] = true;
end

function CT_Core_ContainerFrameItemButton_OnModifiedClick_Unregister(func)
	cfibomcTable[func] = nil;
end

local function CT_Core_ContainerFrameItemButton_OnModifiedClick(self, button)
	-- Test registered functions
	for func, value in pairs(cfibomcTable) do
		if (func(self, button)) then
			return;
		end
	end
	-- Test for the Add To Trade function last, since this one
	-- doesn't require a particular frame to be open (unless you're
	-- adding to an open trade frame).
	CT_Core_AddToTrade(self, button);
end

hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", CT_Core_ContainerFrameItemButton_OnModifiedClick);

CT_Core_ContainerFrameItemButton_OnModifiedClick_Register(CT_Core_AddToAuctions);

--------------------------------------------
-- Hide Gryphons

local gryphonLoop;

local function toggleGryphons(hide)
	if (gryphonLoop) then
		-- Ensure no infinite loop.
		gryphonLoop = nil;
		return;
	end
	-- Hide/Show the gryphons
	if ( hide ) then
		MainMenuBarLeftEndCap:Hide();
		MainMenuBarRightEndCap:Hide();
	else
		MainMenuBarLeftEndCap:Show();
		MainMenuBarRightEndCap:Show();
	end
	if (CT_BottomBar) then
		-- CT_BottomBar is loaded, and it may also have an option
		-- to hide the gryphons.
		local optCore = "hideGryphons";
		local optBott = "hideGryphons";
		if (type(module.frame) == "table") then
			-- Update our "hide gryphons" option checkbox.
			-- This is needed for those times when CT_BottomBar calls us
			-- to change the CT_Core "hide gryphons" option.
			local cb = module.frame.section1[optCore];
			cb:SetChecked(hide);
		end
		if (CT_BottomBar:getOption(optBott) ~= module:getOption(optCore)) then
			-- Change CT_BottomBar's "hide gryphons" option.
			gryphonLoop = true;
			CT_BottomBar:setOption(optBott, hide, true);
			gryphonLoop = nil;
		end
	end
end

--------------------------------------------
-- Hide World Map Minimap Button

local function toggleWorldMap(hide)
	if ( hide ) then
		MiniMapWorldMapButton:Hide();
	else
		MiniMapWorldMapButton:Show();
	end
end

--------------------------------------------
-- Movable casting bar

local castingbarAnchorFrame;
local castingbarEnabled;
local castingbarMovable;
local castingbarAlwaysFrame;

local function castingbar_Reanchor()
	CastingBarFrame:ClearAllPoints();
	CastingBarFrame:SetPoint("CENTER", castingbarAnchorFrame, "CENTER", 0, -2);
end

local function CT_Core_Other_castingbar_UIParent_ManageFramePositions()
	if (castingbarEnabled) then
		castingbar_Reanchor();
	end
end

local function castingbar_onMouseDownFunc(self, button)
	if ( button == "LeftButton" ) then
		module:moveMovable(self.movable);
	end
end

local function castingbar_FrameSkeleton()
	return "button#st:HIGH#tl:mid:350:-200#s:100:30", {
		"tooltip#0:0:0:0.75",
		"font#v:GameFontNormal#i:text",
		["onleave"] = module.hideTooltip,
		["onmousedown"] = castingbar_onMouseDownFunc,
	};
end

local function castingbar_AlwaysVisibility(self)
	if (not self) then
		self = CastingBarFrame;
	end
	if (self.channeling or self.casting) then
		return;
	end
	if (not castingbarAlwaysFrame) then
		self:Hide();
		return;
	end
	if (not (castingbarEnabled and castingbarMovable)) then
		self:Hide();
		castingbarAlwaysFrame:Hide();
		return;
	end
	self:SetAlpha(1);
	self:SetStatusBarColor(1.0, 0.7, 0.0);
	local selfName = self:GetName();
	local barText = _G[selfName.."Text"];
	if ( barText ) then
		barText:SetText("");
	end
	self:Show();
	castingbarAlwaysFrame:Show();
end

local function castingbar_CreateAnchorFrame()
	local movable = "CASTINGBARANCHOR2";	
	castingbarAnchorFrame = module:getFrame(castingbar_FrameSkeleton, UIParent, "CT_Core_CastingBarAnchorFrame");
	
	module:registerMovable(movable, castingbarAnchorFrame, true);
	castingbarAnchorFrame.movable = movable;
	castingbarAnchorFrame:SetScript("OnEnter", function(self)
		module:displayTooltip(self, "|c00FFFFFFCasting Bar|r\nLeft-click to drag.\nRight-click to reset.");
	end);
	castingbarAnchorFrame:SetScript("OnMouseUp", function(self, button)
		if ( button == "LeftButton" ) then
			module:stopMovable(self.movable);
		elseif ( button == "RightButton" ) then
			CT_Core_CastingBarAnchorFrame:ClearAllPoints();
			CT_Core_CastingBarAnchorFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 124);
		end
	end);
	castingbarAnchorFrame:SetScript("OnEvent", function(self, event, arg1, ...)
		if (event == "PLAYER_ENTERING_WORLD") then
			hooksecurefunc("UIParent_ManageFramePositions", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			-- These are required for Blizzard xml scripts that use this syntax to
			-- call UIParent_ManageFramePositions. This xml syntax does not call our
			-- secure hook of UIParent_ManageFramePositions, so we have to explicitly
			-- hook anything that calls it to ensure our function gets called.
			-- 	<OnShow function="UIParent_ManageFramePositions"/>
			-- 	<OnHide function="UIParent_ManageFramePositions"/>
			ShapeshiftBarFrame:HookScript("OnShow", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			ShapeshiftBarFrame:HookScript("OnHide", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			PossessBarFrame:HookScript("OnShow", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			PossessBarFrame:HookScript("OnHide", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			DurabilityFrame:HookScript("OnShow", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			DurabilityFrame:HookScript("OnHide", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			MainMenuBarMaxLevelBar:HookScript("OnShow", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			MainMenuBarMaxLevelBar:HookScript("OnHide", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			MultiCastActionBarFrame:HookScript("OnShow", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			MultiCastActionBarFrame:HookScript("OnHide", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			PetActionBarFrame:HookScript("OnShow", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			PetActionBarFrame:HookScript("OnHide", CT_Core_Other_castingbar_UIParent_ManageFramePositions);
			ReputationWatchBar:HookScript("OnHide", CT_Core_Other_castingbar_UIParent_ManageFramePositions);

			-- By now GetCVar("uiScale") has a value, so if Blizzard_CombatLog is already loaded
			-- then it won't cause an error when it tries to multiply by the uiScale.
			UIParent_ManageFramePositions();
		end
	end);
	castingbarAnchorFrame:SetWidth(CastingBarFrame:GetWidth() + 6);
	castingbarAnchorFrame:SetHeight(28);
	castingbarAnchorFrame:Hide();
	castingbarAnchorFrame:SetParent(CastingBarFrame);
	castingbarAnchorFrame:RegisterEvent("PLAYER_ENTERING_WORLD");

	castingbarAlwaysFrame = CreateFrame("Frame");
	castingbarAlwaysFrame:SetScript("OnUpdate", function(self, elapsed)
		castingbar_AlwaysVisibility();
	end);
end

local function castingbar_UpdateAnchorVisibility()
	if (not castingbarAnchorFrame) then
		castingbar_CreateAnchorFrame();
	end
	if (castingbarEnabled and castingbarMovable) then
		castingbarAnchorFrame:Show();
	else
		castingbarAnchorFrame:Hide();
	end
end

local function castingbar_ToggleMovable(movable)
	castingbarMovable = movable;
	castingbar_UpdateAnchorVisibility();
	castingbar_AlwaysVisibility();
end

local function castingbar_ToggleStatus(enable)
	castingbarEnabled = enable;
	castingbar_UpdateAnchorVisibility();
	castingbar_AlwaysVisibility();
	if (castingbarEnabled) then
		castingbar_Reanchor();
	else
		-- When entering the world for the FIRST time after starting the game, GetCVar("uiScale")
		-- returns nil when CT_Core loads (ie. at ADDON_LOADED event time). The game hasn't had
		-- time to update the setting yet. This is also the case for GetCVarBool("scriptErrors").
		--
		-- When the Blizzard_CombatLog addon gets loaded, it hooks the FCF_DockUpdate function
		-- which gets called by the UIParent_ManageFramePositions function in UIParent.lua.
		--
		-- If there is an addon that loads before CT_Core and causes the Blizzard_CombatLog addon
		-- to load, then we want to avoid calling UIParent_ManageFramePositions while GetCVar("uiScale")
		-- is nil. If we do call it when the uiScale is nil, then the Blizzard_CombatLog code will cause an error
		-- when it gets to the Blizzard_CombatLog_AdjustCombatLogHeight() function in Blizzard_CombatLog.lua.
		-- That code tries to multiply by GetCVar("uiScale"), and since it is still nil then there will
		-- be an error.
		--
		-- Blizzard's code won't display the error (see BasicControls.xml) because GetCVarBool("scriptErrors")
		-- is still nil when CT_Core loads. The user won't see the error unless they have an addon that loads
		-- before CT_Core and traps and displays errors.
		--
		-- To avoid this error we will only call UIParent_ManageFramePositions() when the uiScale has
		-- a value. This is the place in this addon where UIParent_ManageFramePositions() may get called
		-- at ADDON_LOADED time by CT_Libary (during the "init" options step).

		CastingBarFrame:ClearAllPoints();
		if (GetCVar("uiScale")) then
			UIParent_ManageFramePositions();
		end
	end
end

--------------------------------------------
-- Open/close bags
do
	local events = {
		["BANKFRAME_OPENED"]      = {option = "bankOpenBags", open = true,  maxBag = 11},
		["BANKFRAME_CLOSED"]      = {option = "bankCloseBags", maxBag = 11},
		["GUILDBANKFRAME_OPENED"] = {option = "gbankOpenBags", open = true},
		["GUILDBANKFRAME_CLOSED"] = {option = "gbankCloseBags"},
		["MERCHANT_SHOW"]         = {option = "merchantOpenBags", open = true},
		["MERCHANT_CLOSED"]       = {option = "merchantCloseBags"},
		["AUCTION_HOUSE_SHOW"]    = {option = "auctionOpenBags", open = true},
		["AUCTION_HOUSE_CLOSED"]  = {option = "auctionCloseBags"},
		["TRADE_SHOW"]            = {option = "tradeOpenBags", open = true},
		["TRADE_CLOSED"]          = {option = "tradeCloseBags"},
	};

	local function onEvent(event)
		local data = events[event];
		if (data and module:getOption(data.option)) then
			-- 0==Backpack
			-- 1==First bag, 4==Last bag
			-- 5==First bank bag, 11==Last bank bag
			for i = (data.minBag or 0), (data.maxBag or 4) do
				if (data.open) then
					OpenBag(i);
				else
					CloseBag(i);
				end
			end
		end
	end

	for event, data in pairs(events) do
		module:regEvent(event, onEvent);
	end
end

--------------------------------------------
-- Block duel requests

local duelsBlocked;

local function duelRequested(event, player)
	if (duelsBlocked) then
		if (module:getOption("blockDuelsMessage")) then
			print(format("Blocked duel request from %s.", tostring(player or UNKNOWN)));
		end
		CancelDuel();
		StaticPopup_Hide("DUEL_REQUESTED");
	end
end

module:regEvent("DUEL_REQUESTED", duelRequested);

local function configureDuelBlockOption(value)
	if (value) then
		duelsBlocked = true;
		UIParent:UnregisterEvent("DUEL_REQUESTED");
	else
		if (duelsBlocked) then
			duelsBlocked = false;
			UIParent:RegisterEvent("DUEL_REQUESTED");
		end
	end
end

--------------------------------------------
-- Objectives window

do
	-- Altering Blizzard's WATCHFRAME_MAXLINEWIDTH variable,
	-- or calling WatchFrame_Update / WatchFrame_Collapse / WatchFrame_Expand / etc,
	-- or creating a menu using Blizzard's UIDropDownMenu_AddButton system,
	-- can cause taint.
	--
	-- That taint could lead to an "Action blocked by an addon" message if the user is
	-- in combat, and has some quests tracked, and opens / minimizes / maximizes the
	-- World Map while the 'show quest objectives' option is enabled.
	--
	-- Toggling that option while in combat may also result in the error.
	--
	-- This addon's options which require changing Blizzard's variable, or calling
	-- their functions, are disabled by default. The user is told in the options 
	-- window that enabling the options may result in an action blocked error under
	-- the described conditions.

	local watchFrame;
	local playerLoggedIn;
	local resizedWidth;
	local resizedHeight;
	local hookedFunctions;
	local isResizing;
	local isEnabled;
	local anchorTopLeft;
	local forceCollapse;

	local frameSetPoint;
	local frameSetParent;
	local frameClearAllPoints;
	local frameSetAllPoints;

	-- Blizzard values (refer to WatchFrame.lua)
	local blizzard_MaxLineWidth1 = 192;
	local blizzard_ExpandedWidth1 = 204;

	local blizzard_MaxLineWidth2 = 294;
	local blizzard_ExpandedWidth2 = 306;

	-- Space on left and right sides of the game's WatchFrame (between us and them)
	local spacingLeft1 = 31; -- when showing objectives (need room for objective button)
	local spacingLeft2 = 7;  -- when not showing objectives

	-- Size of our frame when collapsed
	local collapsedHeight = 27;
	local collapsedWidth = WATCHFRAME_COLLAPSEDWIDTH + 7;

	-- Local copies of option values
	local opt_watchframeEnabled;
	local opt_watchframeLocked;
	local opt_watchframeShowBorder;
	local opt_watchframeBackground;
	local opt_watchframeClamped;
	local opt_watchframeChangeWidth;

	local function getBlizzardExpandedWidth()
		local width;
		if (GetCVar("watchFrameWidth") == "0") then
			width = blizzard_ExpandedWidth1;
		else
			width = blizzard_ExpandedWidth2;
		end
		return width;
	end

	local function getBlizzardMaxLineWidth()
		local width;
		if (GetCVar("watchFrameWidth") == "0") then
			width = blizzard_MaxLineWidth1;
		else
			width = blizzard_MaxLineWidth2;
		end
		return width;
	end

	local function getInnerWidth(ignoreChangeOption)
		local width;
		if (not opt_watchframeChangeWidth or ignoreChangeOption) then
			width = getBlizzardExpandedWidth();
		else
			width = resizedWidth;
			if (WatchFrame.showObjectives) then
				width = width - spacingLeft1;
			else
				width = width - spacingLeft2;
			end
		end
		return width;
	end

	local function getOuterWidth()
		local width;
		if (not opt_watchframeChangeWidth) then
			width = getInnerWidth();
			if (WatchFrame.showObjectives) then
				width = width + spacingLeft1;
			else
				width = width + spacingLeft2;
			end
		else
			width = resizedWidth;
		end
		return width;
	end

	local function getMaxLineWidth()
		local width;
		if (not opt_watchframeChangeWidth) then
			width = getBlizzardMaxLineWidth();
		else
			width = getInnerWidth() - 12;
		end
		return width;
	end

	local function updateClamping()
		if (opt_watchframeShowBorder) then
			-- Clear the insets so that border can touch edge of screen.
			watchFrame:SetClampRectInsets(0, 0, 0, 0);
		else
			-- Change insets so that borderless window can be dragged right to the edge of the screen.
			watchFrame:SetClampRectInsets(5, -5, -5, 5);
		end
		watchFrame:SetClampedToScreen(opt_watchframeClamped);
		WatchFrame:SetClampedToScreen(false);
	end

	local function updateBorder()
		-- Should call udpateClamping() after calling this.
		local alpha;
		if (opt_watchframeShowBorder) then
			alpha = 1;
		else
			alpha = 0;
		end
		watchFrame:SetBackdropBorderColor(1, 1, 1, alpha);
	end

	local function updateBackground()
		watchFrame:SetBackdropColor(unpack(opt_watchframeBackground));
	end

	local function updateLocked()
		-- Show/hide the resize button
		if (opt_watchframeLocked) then
			watchFrame.resizeBL:Hide();
			watchFrame.resizeBR:Hide();
		else
			if ( WatchFrame.collapsed and WatchFrame.userCollapsed ) then
				watchFrame.resizeBL:Hide();
				watchFrame.resizeBR:Hide();
			else
				watchFrame.resizeBL:Show();
				watchFrame.resizeBR:Show();
			end
		end
		watchFrame:EnableMouse(not opt_watchframeLocked);
	end

	local function watchFrame_Update()
		if (opt_watchframeEnabled) then
			local width, height;
			local bwidth;

			frameSetParent(WatchFrame, CT_WatchFrame);
			frameClearAllPoints(WatchFrame);
			frameSetPoint(WatchFrame, "TOPRIGHT", CT_WatchFrame, "TOPRIGHT", 0, 0);
			frameSetPoint(WatchFrame, "BOTTOMRIGHT", CT_WatchFrame, "BOTTOMRIGHT", 0, 0);

			if (WatchFrame.collapsed) then
				if (isResizing) then
					width = resizedWidth;
					height = resizedHeight;
					bwidth = getInnerWidth();
				else
					if ( WatchFrame.collapsed and not WatchFrame.userCollapsed ) then
						width = getOuterWidth();
						height = resizedHeight;
						bwidth = getInnerWidth();
					else
						width = collapsedWidth;
						height = collapsedHeight;
						bwidth = WATCHFRAME_COLLAPSEDWIDTH;
					end
				end
			else
				width = getOuterWidth();
				height = resizedHeight;
				bwidth = getInnerWidth();
			end

			if (opt_watchframeChangeWidth) then
				-- taint
				WATCHFRAME_MAXLINEWIDTH = getMaxLineWidth();
			end
			WatchFrame:SetWidth(bwidth);

			watchFrame:SetWidth(width);
			watchFrame:SetHeight(height);

			if ( WatchFrame.collapsed and not WatchFrame.userCollapsed ) then
				-- WatchFrame is collapsed, but not because user clicked the collapse button.
				-- There was not enough room to show objectives, so Blizzard collapsed the frame.
				WatchFrameCollapseExpandButton:Disable();
			else
				WatchFrameCollapseExpandButton:Enable();
			end

			if (WatchFrameHeader:IsShown()) then
				watchFrame:Show();
			else
				-- Blizzard hid their WatchFrame, so hide ours also.
				watchFrame:Hide();
			end

			updateBackground();
			updateBorder();
			updateClamping();
			updateLocked();
		end
	end

	local function resizeUpdate(self, elapsed)
		-- OnUpdate routine called while resizing
		self.time = ( self.time or 0 ) - elapsed;
		if ( self.time > 0 ) then
			return;
		else
			self.time = 0.02;
		end

		local height, width;
		local x, y = GetCursorPosition();

		if (anchorTopLeft) then
			width = ( x / self.scale ) - self.left + self.xoff;  -- when using a bottom right resize button
		else
			width = self.right - ( x / self.scale ) + self.xoff;  -- when using a bottom left resize button
		end
		height = self.top - ( y / self.scale ) + self.yoff;

		local minHeight = collapsedHeight;
		local minWidth = collapsedWidth;

		if (WatchFrame.showObjectives) then
			minWidth = minWidth + 20;
		end

		if (opt_watchframeChangeWidth) then
			if (width < minWidth) then
				width = minWidth;
			end
		else
			width = getOuterWidth();
		end

		if ( height < minHeight ) then
			height = minHeight;
		end

		resizedWidth = width;
		resizedHeight = height;

		watchFrame_Update();
	end

	local function startResizing(self)
		-- Begin resizing the frame
		if (isResizing) then
			return;
		end

		local x, y = GetCursorPosition();
		local scale = UIParent:GetScale();

		if (anchorTopLeft) then
			self.left = self.parent:GetLeft();  -- when using a bottom right resize button
		else
			self.right = self.parent:GetRight();  -- when using a bottom left resize button
		end
		self.centerX, self.centerY = self.parent:GetCenter();
		self.top = self.parent:GetTop();
		self.bottom = self.parent:GetBottom();

		self.yoff = y/scale - self.parent:GetBottom();
		if (anchorTopLeft) then
			self.xoff = self.parent:GetRight() - x/scale;  -- when using a bottom right resize button
		else
			self.xoff = x/scale - self.parent:GetLeft();  -- when using a bottom left resize button
		end

		self.scale = scale;
		self:SetScript("OnUpdate", resizeUpdate);
		self.background:SetVertexColor(1, 1, 1);

		resizedWidth = self.parent:GetWidth();
		resizedHeight = self.parent:GetHeight();

		isResizing = 1;

		GameTooltip:Hide();
	end

	local function stopResizing(self)
		-- Stop resizing the frame
		if (not isResizing) then
			return;
		end

		resizeUpdate(self, 1);

		local height = self.parent:GetHeight();
		local width = self.parent:GetWidth();

		module:setOption("watchWidth", width, true);
		module:setOption("watchHeight", height, true);

		resizedWidth = width;
		resizedHeight = height;

		self.center = nil;
		self.scale = nil;
		self:SetScript("OnUpdate", nil);
		self.background:SetVertexColor(1, 0.82, 0);

		if ( self:IsMouseOver() ) then
			self:GetScript("OnEnter")(self);
		else
			self:GetScript("OnLeave")(self);
		end

		isResizing = nil;

		watchFrame_Update();
	end

	local function hookStuff()
		if (hookedFunctions) then
			return;
		end

		hooksecurefunc(WatchFrame, "SetPoint", function(frame, ...)
			if (opt_watchframeEnabled) then
				watchFrame_Update();
			end
		end);

		hooksecurefunc(WatchFrame, "SetAllPoints", function(frame, ...)
			if (opt_watchframeEnabled) then
				watchFrame_Update();
			end
		end);

		hooksecurefunc("WatchFrame_Update", function()
			if (opt_watchframeEnabled) then
				watchFrame_Update();
			end
		end);

		hooksecurefunc("WatchFrame_SetWidth", function()
			if (opt_watchframeEnabled) then
				watchFrame_Update();
			end
		end);

		hooksecurefunc("WatchFrame_Expand", function()
			module:setOption("watchframeIsCollapsed", WatchFrame.collapsed, true);
		end);

		hooksecurefunc("WatchFrame_Collapse", function()
			module:setOption("watchframeIsCollapsed", WatchFrame.collapsed, true);
		end);

		hookedFunctions = true;
	end

	local function updateEnabled()
		if (opt_watchframeEnabled) then
			-- Enable our frame
			isEnabled = true;
			hookStuff();
			watchFrame_Update();
		else
			if (isEnabled) then
				watchFrame:Hide();
				-- Restore Blizzard's WatchFrame
				if (opt_watchframeChangeWidth) then
					-- taint
					WATCHFRAME_MAXLINEWIDTH = getBlizzardMaxLineWidth();
				end
				if (WatchFrame.collapsed) then
					width = WATCHFRAME_COLLAPSEDWIDTH;
				else
					width = getBlizzardExpandedWidth();
				end
				WatchFrame:SetWidth(width);
				frameSetParent(WatchFrame, "UIParent");
				WatchFrame:SetClampedToScreen(true);
				UIParent_ManageFramePositions();
			end
		end
		module:setOption("watchframeIsCollapsed", WatchFrame.collapsed, true);
	end

	local pointText = {"BOTTOMLEFT", "BOTTOMRIGHT", "TOPLEFT", "TOPRIGHT", "LEFT"};

	local function anchorOurFrame(topLeft)
		-- Set the anchor point of our frame
		local frame = CT_WatchFrame;
		local oldScale = frame:GetScale() or 1;
		local xOffset, yOffset;
		local anchorX, anchorY, anchorP;
		local relativeP;
		local centerX, centerY = UIParent:GetCenter();

		anchorTopLeft = topLeft;

		if (topLeft) then
			-- Anchor the top left corner of our frame to UIParent
			anchorY = frame:GetTop() or 0;
			anchorP = 3;  -- TOPLEFT
			anchorX = frame:GetLeft() or 0;
		else
			-- Anchor the top right corner of our frame to UIParent
			anchorY = frame:GetTop() or 0;
			anchorP = 4;  -- TOPRIGHT
			anchorX = frame:GetRight() or 0;
		end

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
		module:stopMovable("WATCHFRAME");  -- stops moving and saves the current anchor point
	end

	module.resetWatchFramePosition = function()
		if (not opt_watchframeEnabled) then
			return;
		end
		local width = watchFrame:GetWidth() or frameWidth;
		local height = watchFrame:GetHeight() or frameHeight;
		module:resetMovable("WATCHFRAME");
		watchFrame:ClearAllPoints();
		watchFrame:SetPoint("TOPRIGHT", UIParent, "CENTER", width/2, height/2);
		anchorOurFrame();  -- change the anchor point and save it
	end;

	-- Create the frame
	local function watchFrameSkeleton()
		return "frame#r:0:75#st:LOW", {
			"backdrop#tooltip",

			["button#s:16:16#i:resizeBL#bl"] = {
				"texture#s:12:12#br:0:5#i:background#Interface\\AddOns\\CT_Core\\Images\\resizeBL",
				["onenter"] = function(self)
					if ( isResizing ) then return; end
					self.background:SetVertexColor(1, 1, 1);
					if (module:getOption("watchframeShowTooltip") ~= false) then
						module:displayPredefinedTooltip(self, "RESIZE");
					end
				end,
				["onleave"] = function(self)
					module:hideTooltip();
					if ( isResizing ) then return; end
					self.background:SetVertexColor(1, 0.82, 0);
				end,
				["onload"] = function(self)
					self:SetFrameLevel(self:GetFrameLevel() + 2);
					self.background:SetVertexColor(1, 0.82, 0);
				end,
				["onmousedown"] = function(self)
					anchorOurFrame(false);
					startResizing(self);
				end,
				["onmouseup"] = function(self)
					stopResizing(self);
					anchorOurFrame(false);
					self.background:SetVertexColor(1, 0.82, 0);
				end,
			},

			["button#s:16:16#i:resizeBR#br"] = {
				"texture#s:12:12#br:-5:5#i:background#Interface\\AddOns\\CT_Core\\Images\\resize",
				["onenter"] = function(self)
					if ( isResizing ) then return; end
					self.background:SetVertexColor(1, 1, 1);
					if (module:getOption("watchframeShowTooltip") ~= false) then
						module:displayPredefinedTooltip(self, "RESIZE");
					end
				end,
				["onleave"] = function(self)
					module:hideTooltip();
					if ( isResizing ) then return; end
					self.background:SetVertexColor(1, 0.82, 0);
				end,
				["onload"] = function(self)
					self:SetFrameLevel(self:GetFrameLevel() + 2);
					self.background:SetVertexColor(1, 0.82, 0);
				end,
				["onmousedown"] = function(self)
					anchorOurFrame(true);
					startResizing(self);
				end,
				["onmouseup"] = function(self)
					stopResizing(self);
					anchorOurFrame(false);
					self.background:SetVertexColor(1, 0.82, 0);
				end,
			},

			["onenter"] = function(self)
				if ( isResizing ) then return; end
				if (module:getOption("watchframeShowTooltip") ~= false) then
					module:displayTooltip(self, "Left-click to drag.");
				end
			end,

			["onleave"] = module.hideTooltip,

			["onmousedown"] = function(self, button)
				if ( button == "LeftButton" ) then
					module:moveMovable("WATCHFRAME");
					GameTooltip:Hide();
				end
			end,

			["onmouseup"] = function(self, button)
				if ( button == "LeftButton" ) then
					self:StopMovingOrSizing();  -- Stops moving and lets the game assign an anchor point
					anchorOurFrame();  -- Change the anchor point and save it
					if ( self:IsMouseOver() ) then
						self:GetScript("OnEnter")(self);
					else
						self:GetScript("OnLeave")(self);
					end
				end
			end,

			["onevent"] = function(self, event)
				if (event == "PLAYER_LOGIN") then
					playerLoggedIn = 1;
					-- We've delayed the enabling of the options until PLAYER_LOGIN time
					-- to allow enough time for the UIParent scale to be set by Blizzard,
					-- since it will be needed in anchorOurFrame(). If the scale isn't set
					-- then we will have problems restoring the saved frame position properly.
					opt_watchframeEnabled = module:getOption("watchframeEnabled");
					if (opt_watchframeEnabled) then
						module.watchframeInit();
					end
					updateEnabled();
				elseif (event == "PLAYER_ENTERING_WORLD") then
					if (forceCollapse) then
						forceCollapse = nil;
						if (not WatchFrame.collapsed) then
							-- taint
							WatchFrame_Collapse(WatchFrame);
							-- taint
							WatchFrame.userCollapsed = true;
						end
					end
				end
			end,
		};
	end

	watchFrame = module:getFrame(watchFrameSkeleton, nil, "CT_WatchFrame");
	module.watchFrame = watchFrame;

	opt_watchframeBackground = {0, 0, 0, 0};
	watchFrame:SetBackdropColor(unpack(opt_watchframeBackground));

	-- Save methods to be used when we position the WatchFrame.
	-- This prevents other addons from trying to block repositioning
	-- of the frame via hooks to :SetPoint().
	frameSetPoint = watchFrame.SetPoint;
	frameSetParent = watchFrame.SetParent;
	frameClearAllPoints = watchFrame.ClearAllPoints;
	frameSetAllPoints = watchFrame.SetAllPoints;

	watchFrame:RegisterEvent("PLAYER_LOGIN");
	watchFrame:RegisterEvent("PLAYER_ENTERING_WORLD");

	-- Initialize
	local initDone;
	module.watchframeInit = function()
		if (initDone) then
			return;
		end
		initDone = true;

		local top = WatchFrame:GetTop();
		local bottom = WatchFrame:GetBottom();
		local left = WatchFrame:GetLeft();
		local right = WatchFrame:GetRight();
		local scale = WatchFrame:GetEffectiveScale();

		resizedWidth = module:getOption("watchWidth");
		if (not resizedWidth or not opt_watchframeChangeWidth) then
			resizedWidth = getOuterWidth();
		end

		resizedHeight = module:getOption("watchHeight");
		if (not resizedHeight) then
			if (top and bot) then
				resizedHeight = top - bot;
			end
			if (not resizedHeight or resizedHeight < 50) then
				resizedHeight = 400;
			end
		end

		-- Position the frame before we make the frame movable.
		watchFrame:ClearAllPoints();
		watchFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", right or UIParent:GetRight(), top or UIParent:GetTop());
		watchFrame:SetWidth(resizedWidth);
		watchFrame:SetHeight(resizedHeight);
		watchFrame:Show();

		-- Make frame movable.
		module:registerMovable("WATCHFRAME", watchFrame, true);

		-- Ensure our frame is anchored using a top right anchor point.
		anchorOurFrame(false);

		resizedWidth = watchFrame:GetWidth();
		resizedHeight = watchFrame:GetHeight();

		if (module:getOption("watchframeRestoreState")) then
			-- Restore the last known collapsed/expanded state.
			-- By default, the game starts with the WatchFrame in an expanded state.
			if (module:getOption("watchframeIsCollapsed")) then
				forceCollapse = true;
			end
		end
	end

	-- Option functions
	module.watchframeEnabled = function(value)
		if (not playerLoggedIn) then
			return;
		else
			-- User clicked checkbox
			opt_watchframeEnabled = value;
			if (opt_watchframeEnabled) then
				module.watchframeInit();
			end
			updateEnabled();
		end
	end

	module.watchframeLocked = function(value)
		-- When unlocked, user can drag and resize the frame.
		opt_watchframeLocked = (value ~= false);
		if (not opt_watchframeEnabled) then
			return;
		end
		updateLocked();
	end

	module.watchframeShowBorder = function(value)
		-- Show/hide the frame's border
		opt_watchframeShowBorder = value;
		if (not opt_watchframeEnabled) then
			return;
		end
		updateBorder();
	end

	module.watchframeClamped = function(value)
		-- Allow or prevent user dragging frame off screen.
		opt_watchframeClamped = (value ~= false);
		if (not opt_watchframeEnabled) then
			return;
		end
		updateClamping();
		updateBorder();
	end

	module.watchframeBackground = function(value)
		if (not value) then
			value = {0, 0, 0, 0};
		end
		opt_watchframeBackground = value;
		if (not opt_watchframeEnabled) then
			return;
		end
		updateBackground();
	end

	module.watchframeChangeWidth = function(value)
		local oldValue = opt_watchframeChangeWidth;
		opt_watchframeChangeWidth = value;
		if (not opt_watchframeEnabled) then
			return;
		end
		if (opt_watchframeChangeWidth or (oldValue and not opt_watchframeChangeWidth)) then
			-- Option is enabled, or
			-- Option was previously enabled but has now been disabled.
			-- taint
			WATCHFRAME_MAXLINEWIDTH = getMaxLineWidth();
		end
		watchFrame_Update();
	end
end

--------------------------------------------
-- General Initializer

local modFunctions = {
	["castingTimers"] = toggleCastingTimers,
	["questLevels"] = toggleDisplayLevels,
	["blockBankTrades"] = module.configureBlockTradesBank,
	["tickMod"] = toggleTick,
	["tickModFormat"] = setTickDisplayType,
	["tooltipRelocation"] = setTooltipRelocationStyle,
	["tooltipRelocationAnchor"] = toggleTooltipAnchorVisibility,
	["tooltipFrameAnchor"] = setTooltipFrameAnchor,
	["tooltipMouseAnchor"] = setTooltipMouseAnchor,
	["tooltipFrameDisableFade"] = setTooltipFrameDisableFade,
	["tooltipMouseDisableFade"] = setTooltipMouseDisableFade,
	["hideGryphons"] = toggleGryphons,
	["hideWorldMap"] = toggleWorldMap,
	["castingbarEnabled"] = castingbar_ToggleStatus,
	["castingbarMovable"] = castingbar_ToggleMovable,
	["blockDuels"] = configureDuelBlockOption,
	["watchframeEnabled"] = module.watchframeEnabled,
	["watchframeLocked"] = module.watchframeLocked,
	["watchframeShowBorder"] = module.watchframeShowBorder,
	["watchframeClamped"] = module.watchframeClamped,
	["watchframeBackground"] = module.watchframeBackground,
	["watchframeChangeWidth"] = module.watchframeChangeWidth,
};

local modFunctionsTrue = {
	-- ["name"] = function,
	["showFriendNotes"] = CTCore_FriendNotes_Toggle,
	["showIgnoreNotes"] = CTCore_IgnoreNotes_Toggle,
	["showGuildNotes"] = CTCore_GuildNotes_Toggle,
};

module.modupdate = function(self, type, value)
	if ( type == "init" ) then
		module:setOption("tooltipAnchor", nil, true);  -- Remove obsolete option
		updatePlayerNotes();
		for key, value in pairs(modFunctions) do
			value(self:getOption(key), key);
		end
		for key, value in pairs(modFunctionsTrue) do
			value(self:getOption(key) ~= false, key);
		end
	else
		local func = modFunctions[type];
		if ( func ) then
			func(value, type);
		else
			func = modFunctionsTrue[type];
			if ( func ) then
				func(value ~= false, type);
			end
		end
	end
end
