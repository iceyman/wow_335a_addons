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

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BarMod;

-- Local Copies
local InCombatLockdown = InCombatLockdown;
local format = format;
local tostring = tostring;
local actionButtonList = module.actionButtonList;
local groupList = module.groupList;

-- Tooltip for figuring out spell name
local TOOLTIP = CreateFrame("GameTooltip", "CT_BarModTooltip", nil, "GameTooltipTemplate");
local TOOLTIP_TITLELEFT = _G.CT_BarModTooltipTextLeft1;
local TOOLTIP_TITLERIGHT = _G.CT_BarModTooltipTextRight1;

--------------------------------------------
-- Key Bindings Handler

local bindingFrame, currentBinding, attemptedKey;

local function getSpellName(actionId, noRank)
	local spellName, spellRank;

	if (HasAction(actionId)) then
		-- Get information about the action assigned to the button.
		local spellType, id, subType, spellID = GetActionInfo(actionId);

		-- Try to determine the spell name and rank.
		if (spellType == "spell" or spellType == "companion") then
			if (spellID) then
				spellName, spellRank = GetSpellInfo(spellID);
			end
		end
		if (not spellName or spellName == "") then
			-- Scan the tooltip for the spell name and rank.
			-- We must set the tooltip owner each time in case it gets
			-- cleared when attempting to call SetAction() for a spell
			-- the player doesn't know.
			TOOLTIP:SetOwner(WorldFrame, "ANCHOR_NONE");
			TOOLTIP:ClearLines();
			TOOLTIP:SetAction(actionId);
			-- Spell name and rank should be on the first line of the tooltip.
			spellName = TOOLTIP_TITLELEFT:GetText();
			spellRank = TOOLTIP_TITLERIGHT:GetText();
		end
		if (spellName and spellName ~= "") then
			-- We have a spell name.
			-- Format the rank.
			if (spellRank) then
				if (noRank) then
					spellRank = nil;
				else
					spellRank = spellRank:match("(%d+)$");
					if (spellRank) then
						spellRank = " (R" .. spellRank .. ")";
					end
				end
			end
		else
			-- Still don't have a spell name.
			spellRank = nil;

			-- Try some other things.
			spellName = GetActionText(actionId);
			if (not spellName or spellName == "") then
				if (spellType == "macro") then
					spellName = GetMacroInfo(id);
				end
			end
		end
	elseif (actionId == module.controlCancel) then
		spellName = CANCEL or "Cancel";
	end

	-- If we still don't have a spell name, then return "<None>".
	if (not spellName or spellName == "") then
		return "|c00FF2222<|r|c00FFFFFFNone|r|c00FF2222>|r";
	end

	-- Return the spell name with rank, or just the spell name.
	if (spellRank) then
		return spellName .. spellRank;
	end

	return spellName;
end

local function updateEntry(id, object, isGroup)
	local displayObj = bindingFrame[tostring(id)];
	if ( not displayObj ) then
		module:print(id, object, isGroup);
	end
	if ( isGroup ) then
		if ( object.hiddenDisplay ) then
			displayObj.header:SetText("+");
		else
			displayObj.header:SetText("-");
		end
		
		local spell = displayObj.spell;
		spell:SetFontObject(GameFontNormalLarge);
		spell:SetText(object.fullName);
		displayObj.binding:SetText("");
		displayObj.id = -1;
		displayObj.group = object;
	else
		local actionId = object.id;
		local spell = displayObj.spell;
		spell:SetFontObject(ChatFontNormal);
		spell:SetText(format("|c00FFD200%3d|r %s", actionId, getSpellName(actionId)));
		
		displayObj.header:SetText("");
		-- displayObj.binding:SetText(module:getOption("BINDING-"..actionId) or "");
		displayObj.binding:SetText(module.getBindingKey(actionId) or "");
		displayObj.id = actionId;
		displayObj.isGroup = nil;
	end
	displayObj:Show();
	if ( id == 13 ) then
		return true;
	end
end

local function updateKeyBinds()
	local offset = FauxScrollFrame_GetOffset(CT_BarModOptionsKeyBindingsScrollFrame);
	local num = 0;
	local objects = 0;
	local shallBreak;
	for gnum, group in ipairs(groupList) do
		objects = group.objects;
		if ( objects ) then
			num = num + 1;
			if ( num > offset ) then
				if ( updateEntry(num-offset, group, true) ) then
					break;
				end
			end
			if ( not group.hiddenDisplay ) then
				for bid, button in ipairs(objects) do
					num = num + 1;
					if ( num > offset ) then
						if ( updateEntry(num-offset, button) ) then
							shallBreak = true;
							break;
						end
					end
				end
				if ( shallBreak ) then
					break;
				end
			end
		end
	end
	
	-- Hide all other entries
	for i = num+1, 13, 1 do
		bindingFrame[tostring(i)]:Hide();
	end
end

local function captureBinding(obj, conflict)
	if ( obj and conflict ) then
		local bindingKey = GetBindingText(conflict, "BINDING_NAME_");
		local id = bindingKey:match("^CLICK CT_BarModActionButton(%d+)");
		if ( id ) then
			bindingKey = format("|c00FFD200%d|r |c00FFFFFF%s|r", id, getSpellName(id, false));
			local button = actionButtonList[tonumber(id)];
			if ( button ) then
				local num = module.GroupIdToNum(button.group);
				local group = groupList[num];
				if ( group ) then
					bindingKey = bindingKey .. "\non " .. group.fullName .. ".";
				end
			end
		end
		
		bindingFrame.instruction:SetText(format(
			"The key |c00FFFFFF%s|r is used by\n|c00FFFFFF%s|r\n"..
			"|c0000FF00Enter|r to Overwrite / |c00FF0000Escape|r to Cancel.",
			attemptedKey, bindingKey));
	elseif ( obj ) then
		currentBinding = obj;
		-- local currKey = module:getOption("BINDING-"..currentBinding.id);
		local currKey = module.getBindingKey(currentBinding.id);
		attemptedKey = nil;
		bindingFrame:EnableKeyboard(true);
		if (currKey) then
			bindingFrame.instruction:SetText(format(
				"Press a key to set the key binding for\n|c00FFFFFF%s|r\n|c00FF0000Right-Click|r to unbind / |c00FF0000Escape|r to cancel.", getSpellName(obj.id)));
		else
			bindingFrame.instruction:SetText(format(
				"Press a key to set the key binding for\n|c00FFFFFF%s|r\nPress |c00FF0000Escape|r to cancel.", getSpellName(obj.id)));
		end
	else
		currentBinding, attemptedKey = nil;
		bindingFrame:EnableKeyboard(false);
		bindingFrame.instruction:SetText(
			"Click a button below to change its key binding.");
	end
	updateKeyBinds();
end

local prevOffset;
local function updateKeyBindingsScroll()
	local scrollFrame = CT_BarModOptionsKeyBindingsScrollFrame;
	if ( currentBinding ) then
		scrollFrame:SetVerticalScroll(prevOffset or 0);
		return;
	end
	
	-- Get number of entries
	local numEntries, objects = 0;
	for key, value in pairs(groupList) do
		numEntries = numEntries + 1;
		if ( not value.hiddenDisplay ) then
			objects = value.objects;
			if ( objects ) then
				for k, v in ipairs(objects) do
					numEntries = numEntries + 1;
				end
			end
		end
	end
	
	-- Update scrollbar
	prevOffset = scrollFrame:GetVerticalScroll();
	FauxScrollFrame_Update(CT_BarModOptionsKeyBindingsScrollFrame, numEntries, 13, 25);
	updateKeyBinds();
	
--	_G[scrollFrame:GetName().."ScrollChildFrame"]:SetHeight(scrollFrame:GetHeight());
end

local function selectObject(obj, conflict)
	local id;
	if ( obj ) then
		id = obj.id;
		if ( id == -1 ) then
			-- Group
			if ( not currentBinding ) then
				obj.group.hiddenDisplay = not obj.group.hiddenDisplay;
				updateKeyBindingsScroll();
				captureBinding();
			end
			return;
		end
	end
	
	local tempObj;
	for i = 1, 13, 1 do
		tempObj = bindingFrame[tostring(i)];
		if ( tempObj.id ~= id ) then
			tempObj.selected = false;
			if ( tempObj:IsMouseOver() ) then
				tempObj:GetScript("OnEnter")(tempObj);
			else
				tempObj:GetScript("OnLeave")(tempObj);
			end
		else
			tempObj.selected = true;
			if ( conflict ) then
				tempObj.background:SetVertexColor(1, 0.45, 0.1, 0.6);
			else
				tempObj.background:SetVertexColor(1, 0.87, 0.3, 0.4);
			end
		end
	end
	
	captureBinding(obj, conflict);
end

local function setBindingKey(actionId, key)
	if (InCombatLockdown()) then
		return;
	end
	local obj = actionButtonList[actionId];
	module:setOption("BINDING-"..actionId, key, true);
	if ( obj ) then
		obj:setBinding(key);
		SaveBindings(GetCurrentBindingSet());
	end
end

local function deleteBindingKey(actionId)
	if (InCombatLockdown()) then
		return;
	end
	local obj = actionButtonList[actionId];
	-- local currKey = module:getOption("BINDING-"..actionId);
	local currKey = module.getBindingKey(actionId);
	module:setOption("BINDING-"..actionId, nil, true);
	if ( obj ) then
		if (currKey) then
			obj:setBinding(currKey, true);
			SaveBindings(GetCurrentBindingSet());
		end
	end
end

local function setBinding(key)
	if (
		key == "UNKNOWN" or
		key:match("[LR]?SHIFT") or
		key:match("[LR]?CTRL") or
		key:match("[LR]?ALT")
	) then
		return;
	end
	
	-- Convert the mouse button names
	if ( key == "LeftButton" ) then
		key = "BUTTON1";
	elseif ( key == "RightButton" ) then
		key = "BUTTON2";
	elseif ( key == "MiddleButton" ) then
		key = "BUTTON3";
	elseif ( key == "Button4" ) then
		key = "BUTTON4"
	elseif ( key == "Button5" ) then
		key = "BUTTON5"
	elseif ( key == "Button6" ) then
		key = "BUTTON6"
	elseif ( key == "Button7" ) then
		key = "BUTTON7"
	elseif ( key == "Button8" ) then
		key = "BUTTON8"
	elseif ( key == "Button9" ) then
		key = "BUTTON9"
	elseif ( key == "Button10" ) then
		key = "BUTTON10"
	elseif ( key == "Button11" ) then
		key = "BUTTON11"
	elseif ( key == "Button12" ) then
		key = "BUTTON12"
	elseif ( key == "Button13" ) then
		key = "BUTTON13"
	elseif ( key == "Button14" ) then
		key = "BUTTON14"
	elseif ( key == "Button15" ) then
		key = "BUTTON15"
	elseif ( key == "Button16" ) then
		key = "BUTTON16"
	elseif ( key == "Button17" ) then
		key = "BUTTON17"
	elseif ( key == "Button18" ) then
		key = "BUTTON18"
	elseif ( key == "Button19" ) then
		key = "BUTTON19"
	elseif ( key == "Button20" ) then
		key = "BUTTON20"
	elseif ( key == "Button21" ) then
		key = "BUTTON21"
	elseif ( key == "Button22" ) then
		key = "BUTTON22"
	elseif ( key == "Button23" ) then
		key = "BUTTON23"
	elseif ( key == "Button24" ) then
		key = "BUTTON24"
	elseif ( key == "Button25" ) then
		key = "BUTTON25"
	elseif ( key == "Button26" ) then
		key = "BUTTON26"
	elseif ( key == "Button27" ) then
		key = "BUTTON27"
	elseif ( key == "Button28" ) then
		key = "BUTTON28"
	elseif ( key == "Button29" ) then
		key = "BUTTON29"
	elseif ( key == "Button30" ) then
		key = "BUTTON30"
	elseif ( key == "Button31" ) then
		key = "BUTTON31"
	end

	if ( IsShiftKeyDown() ) then
		key = "SHIFT-"..key;
	end
	if ( IsControlKeyDown() ) then
		key = "CTRL-"..key;
	end
	if ( IsAltKeyDown() ) then
		key = "ALT-"..key;
	end

	if ( key == "ESCAPE" ) then
		selectObject();
		currentBinding = nil;
		attemptedKey = nil;
		return;
	end
	
	if ( key == "BUTTON1") then
		return;
	end

	if ( currentBinding and attemptedKey ) then
		if ( key == "ENTER" ) then
			if (not InCombatLockdown()) then
				deleteBindingKey(currentBinding.id);
				setBindingKey(currentBinding.id, attemptedKey);
			else
				module:print("You cannot change key bindings while in combat.");
			end
			selectObject();
			currentBinding = nil;
			attemptedKey = nil;
		end
		return;
	end
	
	if ( not currentBinding ) then
		return;
	end
	
	if ( key == "BUTTON2" ) then
		if (not InCombatLockdown()) then
			deleteBindingKey(currentBinding.id);
		else
			module:print("You cannot change key bindings while in combat.");
		end
		selectObject();
		return;
	end

	local currKey = GetBindingAction(key);
	if ( currKey and currKey ~= "" ) then
		attemptedKey = key;
		selectObject(currentBinding, currKey);
	else
		if (not InCombatLockdown()) then
			deleteBindingKey(currentBinding.id);
			setBindingKey(currentBinding.id, key);
		else
			module:print("You cannot change key bindings while in combat.");
		end
		selectObject();
	end
end

--------------------------------------------
-- Options Updater

local function updateGroups()
	-- Apply group option values to the groups.
	local id;
	for num, group in pairs(groupList) do
		id = group.id;

		group:update("orientation", module:getOption("orientation"..id) or "ACROSS");
		group:update("barColumns", module:getOption("barColumns"..id) or 12);

		group:update("barScale", module:getOption("barScale"..id) or 1);
		group:update("barSpacing", module:getOption("barSpacing"..id) or 6);

		group:update("barMouseover", module:getOption("barMouseover"..id) == 1);  -- do before "barOpacity"
		group:update("barFaded", module:getOption("barFaded"..id) or 0);  -- do before "barOpacity"
		group:update("barOpacity", module:getOption("barOpacity"..id) or 1);

		group:update("barHideInVehicle", module:getOption("barHideInVehicle"..id));
		group:update("barHideInCombat", module:getOption("barHideInCombat"..id));
		group:update("barHideNotCombat", module:getOption("barHideNotCombat"..id));
		group:update("barCondition", module:getOption("barCondition"..id) or "");
		group:update("showGroup", module:getOption("showGroup"..id) ~= false);
		group:update("barVisibility", module:getOption("barVisibility"..id) or 1);
	end
end


--------------------------------------------
-- Options Frame

----------
-- Reset group positions

local function resetGroupPositions()
	-- Reset each group to its default position.
	if (InCombatLockdown()) then
		module:print("Bar positions cannot be reset while in combat.");
	else
		for key, value in pairs(groupList) do
			value:resetPosition();
		end
		CT_BarMod_Shift_ResetPositions();
	end
end

----------
-- Cooldown font

local fontTypeList = {
	["Arial Narrow"] = "Fonts\\ARIALN.TTF",
	["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
	["Morpheus"] = "Fonts\\MORPHEUS.ttf",
	["Skurri"] = "Fonts\\skurri.ttf",
};
local fontStyleList = {
	["Outline"] = "OUTLINE",
	["Plain"] = "MONOCHROME",
	["Thick Outline"] = "THICKOUTLINE",
};

local fontDefaultTypeNum;
local fontDefaultTypeName = "Friz Quadrata TT";
local fontDefaultStyleNum;
local fontDefaultStyleName = "Outline";
local fontDefaultSize = 16;
local fontDefaultColor = {1, 0.82, 0, 1};

local fontCache = {};
local fontTypeListSorted = {};
local fontStyleListSorted = {};

for name, file in pairs(fontTypeList) do
	tinsert(fontTypeListSorted, name);
end
sort(fontTypeListSorted);
fontDefaultTypeNum = 1;
for i = 1, #fontTypeListSorted do
	if (fontTypeListSorted[i] == fontDefaultTypeName) then
		fontDefaultTypeNum = i;
		break;
	end
end

for name, flags in pairs(fontStyleList) do
	tinsert(fontStyleListSorted, name);
end
sort(fontStyleListSorted);
fontDefaultStyleNum = 1;
for i = 1, #fontStyleListSorted do
	if (fontStyleListSorted[i] == fontDefaultStyleName) then
		fontDefaultStyleNum = i;
		break;
	end
end

local function getFont(file, size, flags)
	local name, font;
	if (not file) then
		file = "Fonts\\FRIZQT__.TTF";
	end
	if (not size) then
		size = fontDefaultSize;
	end
	if (not flags) then
		local styleName = fontStyleListSorted[fontDefaultStyleNum];
		flags = fontStyleList[styleName];
	end
	name = "CT_BarMod_Font_" .. file .. size .. flags;
	if (not fontCache[name]) then
		font = CreateFont(name);
		font:SetFont(file, size, flags);
		font:SetJustifyH("CENTER");
		font:SetJustifyV("MIDDLE");
		-- font:SetShadowColor(0, 0, 0, 1);
		-- font:SetShadowOffset(1, -1);
		-- font:SetSpacing(0);
		font:SetTextColor(unpack(fontDefaultColor));
		fontCache[name] = font;
	end
	return name;
end

local function getCooldownFontColor()
	local color = module:getOption("cooldownFontColor");
	if (not color) then
		color = fontDefaultColor;
	end
	return color;
end

local function getCooldownFontSize()
	local size = module:getOption("cooldownFontSize");
	if (not size) then
		size = fontDefaultSize;
	end
	return size;
end

local function getCooldownFontInfo()
	local fontTypeNum, fontTypeName, fontTypeFile;
	fontTypeName = module:getOption("cooldownFontTypeName");
	if (not fontTypeName) then
		fontTypeNum = fontDefaultTypeNum;
	else
		fontTypeNum = 1;
		for i = 1, #fontTypeListSorted do
			if (fontTypeListSorted[i] == fontTypeName) then
				fontTypeNum = i;
				break;
			end
		end
	end
	fontTypeName = fontTypeListSorted[fontTypeNum];
	fontTypeFile = fontTypeList[fontTypeName];
	return fontTypeNum, fontTypeName, fontTypeFile;
end

local function getCooldownFontStyle()
	local fontStyleNum, fontStyleName, fontStyleFlags;
	fontStyleName = module:getOption("cooldownFontStyleName");
	if (not fontStyleName) then
		fontStyleNum = fontDefaultStyleNum;
	else
		fontStyleNum = 1;
		for i = 1, #fontStyleListSorted do
			if (fontStyleListSorted[i] == fontStyleName) then
				fontStyleNum = i;
				break;
			end
		end
	end
	fontStyleName = fontStyleListSorted[fontStyleNum];
	fontStyleFlags = fontStyleList[fontStyleName];
	return fontStyleNum, fontStyleName, fontStyleFlags;
end

local function updateCooldownFontColor()
	local color = module:getOption("cooldownFontColor");
	if (not color) then
		color = fontDefaultColor;
	end
	CT_BarMod_CooldownFont:SetTextColor(unpack(color));
end

local function updateCooldownFont()
	local fontTypeNum, fontTypeName, fontTypeFile = getCooldownFontInfo();
	local fontSize = getCooldownFontSize();
	local fontStyleNum, fontStyleName, fontStyleFlags = getCooldownFontStyle();
	local fontname = getFont(fontTypeFile, fontSize, fontStyleFlags);
	CT_BarMod_CooldownFont:SetFontObject(fontname);
	updateCooldownFontColor();
end

----------
-- Update the group widgets

local currentEditGroup = module.GroupNumToId(1);  -- default to group number 1
local groupFrame;

local function updateGroupWidgets_Visibility(id)
	if ( not groupFrame ) then
		return;
	end

	local basic, advanced;
	local value = module:getOption("barVisibility" .. id) or 1;

	if (value == 2) then
		-- Advanced conditions
		advanced = true;
	else
		-- Basic conditions
		basic = true;
	end

	if (basic) then
		-- Enable basic options
		groupFrame.visBasic:SetChecked(1);
	else
		-- Disable basic options
		groupFrame.visBasic:SetChecked(nil);
	end

	if (advanced) then
		-- Enable advanced options
		groupFrame.visAdvanced:SetChecked(1);
	else
		-- Disable advanced options
		groupFrame.visAdvanced:SetChecked(nil);
	end

	groupFrame.conditionEB:ClearFocus();
	groupFrame.conditionEB:HighlightText(0, 0);
end

local function updateGroupWidgets_Columns(id)
	if ( not groupFrame ) then
		return;
	end

	local value, slider;
	slider = groupFrame.columns;
	value = slider:GetValue();  -- Remember correct value
	slider:SetValue(0);  -- To force the OnValueChanged script, first set value user can't pick.
	slider:SetValue(value);  -- Then set the correct value.
end
module.updateGroupWidgets_Columns = updateGroupWidgets_Columns;

local function updateGroupWidgets_Orientation(id)
	if ( not groupFrame ) then
		return;
	end
	local value;
	UIDropDownMenu_Initialize(CT_BarModDropOrientation, CT_BarModDropOrientation.initialize);
	value = module:getOption("orientation" .. id) or "ACROSS";
	if (value == "DOWN") then
		value = 2;
	else
		value = 1; -- "ACROSS"
	end
	UIDropDownMenu_SetSelectedValue(CT_BarModDropOrientation, value);
end
module.updateGroupWidgets_Orientation = updateGroupWidgets_Orientation;

local function updateGroupWidgets_ShowGroup(id)
	if ( not groupFrame ) then
		return;
	end
	for num = 1, module.maxBarNum do
		local id = module.GroupNumToId(num);
		local cb = "showGroup" .. id;
		local opt = "showGroup" .. id;
		groupFrame[cb]:SetChecked( module:getOption(opt) ~= false );
	end
end

local function updateGroupWidgets(id)
	-- Update UI objects related to the bar that was selected.
	if ( not groupFrame ) then
		return;
	end

	if (not id) then
		id = currentEditGroup;
	end

	local value;

	-- Select Bar menu
	UIDropDownMenu_Initialize(CT_BarModDropdown2, CT_BarModDropdown2.initialize);
	UIDropDownMenu_SetSelectedValue(CT_BarModDropdown2, module.GroupIdToNum(id));

	-- Enable bars
	updateGroupWidgets_ShowGroup(id);

	-- Appearance
	groupFrame.scale:SetValue( module:getOption("barScale" .. id) or 1 );
	groupFrame.spacing:SetValue( module:getOption("barSpacing" .. id) or 6 );

	updateGroupWidgets_Orientation(id);
	updateGroupWidgets_Columns(id);

	-- Opacity
	groupFrame.barFaded:SetValue( module:getOption("barFaded" .. id) or 0 );
	groupFrame.mouseover:SetChecked( module:getOption("barMouseover" .. id) );
	groupFrame.opacity:SetValue( module:getOption("barOpacity" .. id) or 1 );

	-- Visibility
	updateGroupWidgets_Visibility(id);

	-- Basic conditions
	groupFrame.barHideInVehicle:SetChecked( module:getOption("barHideInVehicle" .. id) ~= false );
	groupFrame.hideInCombat:SetChecked( module:getOption("barHideInCombat" .. id) );
	groupFrame.hideNotCombat:SetChecked( module:getOption("barHideNotCombat" .. id) );

	-- Advanced conditions
	groupFrame.conditionEB:SetText( module:getOption("barCondition" .. id) or "" );
	groupFrame.visSave:Disable();

	groupFrame.conditionEB.ctUndo = module:getOption("barCondition" .. id) or "";
	groupFrame.visUndo:Disable();
end

-- Show/Hide headers
local function showGroupHeaders(self)
	for key, value in pairs(groupList) do
		value:toggleHeader(true);
	end
	if ( self and CT_BottomBar and CT_BottomBar.show ) then
		CT_BottomBar.show();
	end
	module.showingHeaders = 1;  -- options window is open
	updateGroups();
--	module.CT_BarMod_UpdateVisibility();
end
local function hideGroupHeaders(self)
	for key, value in pairs(groupList) do
		value:toggleHeader(false);
	end
	if ( self and CT_BottomBar and CT_BottomBar.hide ) then
		CT_BottomBar.hide();
	end
	module.showingHeaders = nil;
	updateGroups();
--	module.CT_BarMod_UpdateVisibility();
end

module.show = showGroupHeaders;
module.hide = hideGroupHeaders;


local function createMultiLineEditBox(name, width, height, parent, bdtype)
	-- Create a multi line edit box
	-- Param: bdtype -- nil==No backdrop, 1=Tooltip backdrop, 2==Dialog backdrop
	local frame, scrollFrame, editBox;
	local backdrop;

	if (bdtype == 1) then
		backdrop = {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		};
	elseif (bdtype == 2) then
		backdrop = {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		};
	end

	frame = CreateFrame("Frame", name, parent);
	frame:SetHeight(height);
	frame:SetWidth(width);
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0);
	frame:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", width, -height);
	if (backdrop) then
		frame:SetBackdrop(backdrop);
		frame:SetBackdropBorderColor(0.4, 0.4, 0.4);
		frame:SetBackdropColor(0, 0, 0);
	end
	frame:EnableMouse(true);
	frame:Hide();

	local sfname;
	if (name) then
		sfname = name .. "ScrollFrame";
	end
	scrollFrame = CreateFrame("ScrollFrame", sfname, frame, "UIPanelScrollFrameTemplate");
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -5);
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 5);

	width = scrollFrame:GetWidth() - 6;

	local ebname;
	if (name) then
		ebname = name .. "EditBox";
	end

	editBox = CreateFrame("EditBox", ebname, frame);
	editBox:SetWidth(width);
	editBox:SetMultiLine(true);
	editBox:EnableMouse(true);
	editBox:SetAutoFocus(false);
	editBox:SetFontObject(ChatFontNormal);

	-- Note:
	--
	-- ScrollingEdit_OnUpdate (in UIPanelTemplates.lua) will cause
	-- an error if the editBox.cursorOffset or editBox.cursorHeight
	-- variables are nil. This can happen if ScrollingEdit_OnTextChanged
	-- gets called before ScrollingEdit_OnCursorChanged.
	--
	-- To avoid this error:
	--    1) Initialize those variables to zero ourself.
	-- or 2) Assign a non-empty string to the editBox. This will
	--       force the OnCursorChanged script to get called
	--       just prior to the OnTextChanged script. As a result,
	--       the ScrollingEdit_OnCursorChanged function will
	--       initialize the variables before they are accessed
	--       by ScrollingEdit_OnUpdate.

	editBox.cursorOffset = 0;
	editBox.cursorHeight = 0;
	editBox:SetText(" ");  -- Assign initial non-empty string.

	editBox:SetScript("OnCursorChanged",
		function(self, x, y, w, h)
			ScrollingEdit_OnCursorChanged(self, x, y-10, w, h);
		end
	);
	editBox:SetScript("OnTextChanged",
		function(self, userInput)
			ScrollingEdit_OnTextChanged(self, scrollFrame);
		end
	);
	editBox:SetScript("OnUpdate",
		function(self, elapsed)
			ScrollingEdit_OnUpdate(self, elapsed, scrollFrame);
		end
	);
	editBox:SetScript("OnEscapePressed",
		function(self)
			self:ClearFocus();
		end
	);
	editBox:SetScript("OnTabPressed",
		function(self)
			self:ClearFocus();
		end
	);

	scrollFrame:SetScrollChild(editBox);
	scrollFrame:Show();
	editBox:Show();

	frame.scrollFrame = scrollFrame;
	frame.editBox = editBox;

	return frame;
end

local function setRadioButtonTextures(checkbutton)
	local tex = "Interface\\Buttons\\UI-RadioButton";

	checkbutton:SetNormalTexture(tex);
	checkbutton:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1);

	checkbutton:SetDisabledTexture(tex);
	checkbutton:GetDisabledTexture():SetTexCoord(0, 0.25, 0, 1);

	checkbutton:SetPushedTexture(tex);
	checkbutton:GetPushedTexture():SetTexCoord(0.25, 0.5, 0, 1);

	checkbutton:SetHighlightTexture(tex);
	checkbutton:GetHighlightTexture():SetTexCoord(0.51, 0.75, 0, 1);
	checkbutton:GetHighlightTexture():SetBlendMode("ADD");

	checkbutton:SetCheckedTexture(tex);
	checkbutton:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1);

	checkbutton:SetDisabledCheckedTexture(tex);
	checkbutton:GetDisabledCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1);
end

local function buildCondition(text)
	-- Convert the user specified text from the multiline editbox
	-- into a single line condition.

	-- Replace line terminators with semicolons.
	-- User should only press enter after typing actions.
	local cond = gsub(text, "\n", ";");

	-- Replace pairs of semicolons with single semicolons.
	-- User might have typed a semicolon after an action, and then pressed enter.
	while (strfind(cond, ";;")) do
		cond = gsub(cond, ";;", ";");
	end

	-- If the final character is a semicolon, then eliminate it.
	if (strsub(cond, #cond, #cond) == ";") then
		cond = strsub(cond, 1, #cond - 1);
	end

	return cond;
end

-- Options frame
local optionsFrameList;

local function optionsInit()
	optionsFrameList = {};

	-- Dummy frame representing a master frame.
	local frame = {};
	frame.offset = 0;
	frame.size = 0;
	frame.details = "";
	frame.yoffset = 0;
	frame.top = 0;
	frame.data = {};

	tinsert(optionsFrameList, frame);
end

local function optionsGetData()
	local frame = optionsFrameList[#optionsFrameList];
	return frame.data;
end

local function optionsAddFrame(offset, size, details, data)
	local yoffset;
	local prevFrame = optionsFrameList[#optionsFrameList];
	if (prevFrame) then
		yoffset = prevFrame.yoffset;
	else
		yoffset = 0;
	end
	yoffset = yoffset + offset;

	local frame = {};
	frame.offset = offset;
	frame.size = size;
	frame.details = details;
	frame.yoffset = 0;
	frame.top = yoffset;
	frame.data = data or {};

	tinsert(optionsFrameList, frame);
end

local function optionsAddObject(offset, size, details)
	local frame = optionsFrameList[#optionsFrameList];
	local yoffset = frame.yoffset + offset;

	details = gsub(details, "%%y", yoffset);
	details = gsub(details, "%%s", size);
	tinsert(frame.data, details);

	frame.yoffset = yoffset - size;
end

local function optionsAddScript(name, func)
	local frame = optionsFrameList[#optionsFrameList];
	frame.data[name] = func;
end

local function optionsEndFrame()
	local frame = tremove(optionsFrameList);

	local size = frame.size;
	local top = frame.top;
	local bot;
	if (size == 0) then
		bot = top + frame.yoffset;
		size = top - bot + 1;
	else
		bot = top - size - 1;
	end

	local details = frame.details;

	details = gsub(details, "%%y", top);
	details = gsub(details, "%%b", bot);
	details = gsub(details, "%%s", size);

	local prevFrame = optionsFrameList[#optionsFrameList];
	prevFrame.yoffset = bot;
	prevFrame.data[details] = frame.data;
end

module.frame = function()
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local offset;

	optionsInit();

	-- Tips
	optionsAddFrame(-5, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctbar, /ctbm, or /ctbarmod to open this options window directly.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#Bars are only movable when this options window is open.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#Some options if changed will only update when you are not in combat.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 4*14, "font#t:0:%y#s:0:%s#l:13:0#r#To hide or show one of the bars in a macro (when not in combat), you can use /ctbar hide, or /ctbar show, followed by the bar number. For example, to hide bar 2 use: /ctbar hide 2#" .. textColor2 .. ":l");
		optionsAddObject( -5, 4*14, "font#t:0:%y#s:0:%s#l:13:0#r#The Control bar (bar 11) is used when the game assigns you some temporary abilties (mind control, vehicles, etc). You cannot assign abilities to the Control bar yourself.#" .. textColor2 .. ":l");
	optionsEndFrame();

	-- General Options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#General Options");

		optionsAddObject(-10,   14, "font#tl:20:%y#v:ChatFontNormal#Out of Range:");
		optionsAddObject( 14,   20, "dropdown#tl:90:%y#n:CT_BarModDropdown1#o:colorLack#Color button red#Fade button out#No change");

		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:displayBindings:true#Display key bindings");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:displayRangeDot:true#Display range dot if there is no key binding");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:displayActionText:true#Display macro names");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:hideTooltip#Hide action button tooltips");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:hideGrid#Hide empty button grid");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:buttonLock#Button lock (use Shift to move buttons)");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:dragOnTop#Display drag frame on top of buttons");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:dragHideTooltip#Hide drag frame tooltip");
	optionsEndFrame();

	-- Shifting options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Shifting Options");

		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:shiftParty:true#Shift default party frames to the right");
		optionsAddFrame( -10,   17, "slider#tl:50:%y#s:220:%s#o:shiftPartyOffset:37#Position = <value>#0:200:1");
		optionsEndFrame();
		optionsAddObject(-10,   26, "checkbutton#tl:20:%y#o:shiftFocus:true#Shift default focus frame to the right");
		optionsAddFrame( -10,   17, "slider#tl:50:%y#s:220:%s#o:shiftFocusOffset:37#Position = <value>#0:200:1");
		optionsEndFrame();

		optionsAddObject(-20,   26, "checkbutton#tl:20:%y#o:shiftShapeshift:true#Shift default class bar up");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:shiftPet:true#Shift default pet bar up");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:shiftPossess:true#Shift default possess bar up");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:shiftMultiCast:true#Shift default totem bar up");

		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:20:0#r#Note: The options to shift the class, pet, possess, and totem bars have no effect if CT_BottomBar is loaded.#" .. textColor2 .. ":l");
	optionsEndFrame();

	-- Cooldown Options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r");
		local fonts = "";
		for i, value in ipairs(fontTypeListSorted) do
			fonts = fonts .. "#" .. value;
		end
		local r,g,b,a = unpack(fontDefaultColor);
		local styles = "";
		for i, value in ipairs(fontStyleListSorted) do
			styles = styles .. "#" .. value;
		end
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Cooldown Options");

		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:displayCount:true#Display cooldown counts");

		optionsAddObject( -5,   14, "font#tl:60:%y#v:ChatFontNormal#Color:");
		optionsAddObject( 14,   16, "colorswatch#tl:100:%y#s:16:%s#o:cooldownFontColor:" ..r.. "," ..g.. "," ..b.. "," ..a.. "#true");

		optionsAddObject(-14,   14, "font#tl:60:%y#v:ChatFontNormal#Font:");
		optionsAddObject( 14,   20, "dropdown#tl:80:%y#n:CT_BarModDropdownCooldownType#o:cooldownFontTypeNum:" .. fontDefaultTypeNum .. fonts);

		optionsAddObject(-10,   14, "font#tl:60:%y#v:ChatFontNormal#Style:");
		optionsAddObject( 14,   20, "dropdown#tl:80:%y#n:CT_BarModDropdownCooldownStyle#o:cooldownFontStyleNum:" .. fontDefaultStyleNum .. styles);

		optionsAddFrame( -20,   17, "slider#t:0:%y#s:175:%s#o:cooldownFontSize:" .. fontDefaultSize .. "#Size = <value>#10:30:1");
		optionsEndFrame();
	optionsEndFrame();

	-- Default Bar Positions
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Default Bar Positions");

		optionsAddObject( -2, 6*14, "font#t:0:%y#s:0:%s#l:20:0#r#There are two sets of default bar positions: the original CT_BarMod positions and the standard UI positions.  Using the standard positions puts four of the bars and their buttons in the same locations as the ones in the standard user interface.#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:stdPositions#Standard bar positions (then click Reset)");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:newPositions:true:true#New characters use standard UI positions");  -- Account wide setting
		optionsAddFrame( -14,   30, "button#t:0:%y#s:180:%s#v:GameMenuButtonTemplate#Reset bar positions");
			optionsAddScript("onclick",
				function(self)
					resetGroupPositions();
				end
			);
		optionsEndFrame();
	optionsEndFrame();

	-- Group Options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Enable Bars");

		-- Bar 1 == id 10, Bar 2 == id 1, etc, Bar 10 == id 9, Bar 11 == id 11
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#i:showGroup10#o:showGroup10#Enable bar 1");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#i:showGroup1#o:showGroup1#Enable bar 2");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#i:showGroup2#o:showGroup2#Enable bar 3");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#i:showGroup3#o:showGroup3#Enable bar 4");
		optionsAddObject(  6,   26, "checkbutton#tl:20:%y#i:showGroup4#o:showGroup4#Enable bar 5");

		optionsAddObject(106,   26, "checkbutton#tl:160:%y#i:showGroup5#o:showGroup5#Enable bar 6");
		optionsAddObject(  6,   26, "checkbutton#tl:160:%y#i:showGroup6#o:showGroup6#Enable bar 7");
		optionsAddObject(  6,   26, "checkbutton#tl:160:%y#i:showGroup7#o:showGroup7#Enable bar 8");
		optionsAddObject(  6,   26, "checkbutton#tl:160:%y#i:showGroup8#o:showGroup8#Enable bar 9");
		optionsAddObject(  6,   26, "checkbutton#tl:160:%y#i:showGroup9#o:showGroup9#Enable bar 10");

		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#i:showGroup11#o:showGroup11#Enable control bar");

		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Bar Options");

		optionsAddObject(-10,   14, "font#tl:15:%y#v:ChatFontNormal#Select bar:");

		optionsAddFrame(  19,   24, "button#tl:80:%y#s:24:%s");
			optionsAddScript("onclick",
				function(self)
					module:setOption("prvsGroup", 1, true);  -- Actual value assigned to option is not important.
				end
			);
			optionsAddScript("onload",
				function(self)
					self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
					self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
					self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
					self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
				end
			);
		optionsEndFrame();

		optionsAddFrame(  25,   24, "button#tl:100:%y#s:24:%s");
			optionsAddScript("onclick",
				function(self)
					module:setOption("nextGroup", 1, true);  -- Actual value assigned to option is not important.
				end
			);
			optionsAddScript("onload",
				function(self)
					self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
					self:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
					self:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
					self:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
				end
			);
		optionsEndFrame();

		optionsAddObject( 20,   20, "dropdown#tl:120:%y#n:CT_BarModDropdown2#o:editGroup#Bar 1#Bar 2#Bar 3#Bar 4#Bar 5#Bar 6#Bar 7#Bar 8#Bar 9#Bar 10#Control bar");

		optionsAddObject(-10,   14, "font#tl:15:%y#Appearance");
		optionsAddObject( -6,   14, "font#tl:40:%y#v:ChatFontNormal#Orientation:");
		optionsAddObject( 14,   20, "dropdown#tl:100:%y#s:150:%s#n:CT_BarModDropOrientation#o:orientation:1#Left to right#Top to bottom");
		optionsAddFrame( -16,   17, "slider#tl:42:%y#s:100:%s#o:barColumns:12#i:columns#Columns = <value>#1:12:1");
			do
				local updateFunc = function(self, value)
					value = (value or self:GetValue());
					local option = self.option;
					if ( option ) then
						module:setOption(option, value, true);
						local group = groupList[ module.GroupIdToNum(currentEditGroup) ];
						if ( group ) then
							if (module:getOption("orientation" .. currentEditGroup) == "ACROSS") then
								self.title:SetText(group.numColumns .. " x " .. group.numRows);  -- columns x rows
							else
								self.title:SetText(group.numRows .. " x " .. group.numColumns);  -- columns x rows
							end
						end
					end
				end;
				optionsAddScript("onvaluechanged", updateFunc);
				optionsAddScript("onload", updateFunc);
			end
		optionsEndFrame();
		optionsAddFrame( -22,   17, "slider#tl:42:%y#s:100:%s#o:barScale:1#i:scale#Scale = <value>#0.25:2:0.05");
		optionsEndFrame();
		optionsAddFrame(  17,   17, "slider#tl:180:%y#s:100:%s#o:barSpacing:6#i:spacing#Spacing = <value>#0:25:1");
		optionsEndFrame();

		optionsAddObject(-15,   14, "font#tl:15:%y#Opacity");
		optionsAddFrame( -17,   17, "slider#tl:42:%y#s:100:%s#o:barOpacity:1#i:opacity#Normal = <value>#0:1:0.01");
		optionsEndFrame();
		optionsAddFrame(  17,   17, "slider#tl:180:%y#s:100:%s#o:barFaded:0#i:barFaded#Faded = <value>#0:1:0.01");
		optionsEndFrame();
		optionsAddObject(-10,   26, "checkbutton#tl:40:%y#i:mouseover#o:barMouseover:false#Fade when mouse is not over the bar");

		optionsAddObject(-10,   15, "font#tl:15:%y#Visibility");

		-- Basic conditions
		optionsAddObject(  0,   20, "checkbutton#tl:15:%y#s:%s:%s#i:visBasic#o:visBasic#Use basic conditions");

		optionsAddObject(  2,   26, "checkbutton#tl:40:%y#i:barHideInVehicle#o:barHideInVehicle:true#Hide when in a vehicle");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:hideNotCombat#o:barHideNotCombat:false#Hide when not in combat");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:hideInCombat#o:barHideInCombat:false#Hide when in combat");

		-- Advanced conditions
		optionsAddObject(  0,   20, "checkbutton#tl:15:%y#s:%s:%s#i:visAdvanced#o:visAdvanced#Use advanced conditions");

		optionsAddFrame(  20,   20, "button#tl:250:%y#s:20:%s#i:visHelp1#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 35);
					GameTooltip:SetText("Advanced conditions");
					GameTooltip:AddLine("Each line should contain zero or more macro conditions followed by an action. If you don't specify a condition it defaults to true.", 1, 1, 1, true);
					GameTooltip:AddLine("\nAll conditions must be enclosed in [square brackets]. Within the brackets you can separate multiple conditions using commas (each comma acts like an 'and').", 1, 1, 1, true);
					GameTooltip:AddLine("\nMultiple [conditions] can be placed next to each other. This acts like an 'or' between each pair of brackets.", 1, 1, 1, true);
					GameTooltip:AddLine("\nThe actions that you can use are: hide, show.", 1, 1, 1, true);
					GameTooltip:AddLine("\nA semicolon ';' must be used to separate an action from a following [condition] on the same line. You can omit the semicolon if you press enter after the action instead.", 1, 1, 1, true);
					GameTooltip:AddLine("\nIt is ok for a long line to automatically wrap onto the next line. Don't press enter unless you do so after an action.", 1, 1, 1, true);
					GameTooltip:AddLine("\nThe game will perform the action that is associated with the first set of true conditions.", 1, 1, 1, true);
					GameTooltip:AddLine("\nA simple example:\n\n[vehicleui]hide\n[combat]hide\nshow", 1, 1, 1, true);
					GameTooltip:AddLine("\nFor information on macro conditions, refer to sections 12 through 14 at: www.wowwiki.com/Making_a_macro", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsAddFrame(  21,   20, "button#tl:278:%y#s:20:%s#i:visHelp2#v:UIPanelButtonTemplate#?");
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 7);
					GameTooltip:SetText("Macro conditions");
					GameTooltip:AddLine("A '/' is used with specific conditions to separate multiple values to test for. The '/' acts like an 'or'.", 1, 1, 1, true);
					GameTooltip:AddLine("\nThe letters 'no' can be placed at the start of most condition names to alter the meaning of the condition.", 1, 1, 1, true);
					GameTooltip:AddLine("\n@<unit or name>\nactionbar:1/.../6\nbar:1/.../6\nbonusbar:5\nchanneling:<spell name>\ncombat\ndead\nequipped:<slot or type or subtype>\nexists\nflyable\nflying\ngroup:party/raid\nform:0/.../n\nharm\nhelp\nindoors\nmod:shift/ctrl/alt\nmodifier:shift/ctrl/alt\nmounted\noutdoors\nparty\npet:<name or type>\nraid\nspec:1/2\nstance:0/1/2/.../n\nstealth\nswimming\ntarget=<unit or name>\nunithasvehicleui\nvehicleui\nworn:<slot or type or subtype>", 1, 1, 1, false);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsAddFrame(   0,  120, "frame#tl:40:%y#r");
			optionsAddScript("onload",
				function(self)
					local width = 260;
					local height = 120;
					local frame = createMultiLineEditBox("CT_BarMod_AdvancedEdit", width, height, self, 1);
					frame:Show();
					do
						local function update(self)
							self:HighlightText(0, 0);
							self:ClearFocus();
						end
						frame.editBox:SetScript("OnEscapePressed", update);
						frame.editBox:SetScript("OnTabPressed", update);
						frame.editBox:SetScript("OnEditFocusLost", update);
					end
					frame.editBox:HookScript("OnTextChanged",
						function(self)
							if (not currentEditGroup) then
								return;
							end
							if ( self:GetText() ~= (module:getOption("barCondition" .. currentEditGroup) or "") ) then
								groupFrame.visSave:Enable();
								groupFrame.visUndo:Enable();
							end
						end
					);
					self:GetParent().conditionEB = frame.editBox;
				end
			);
		optionsEndFrame();

		optionsAddFrame(  -2,   22, "button#tl:60:%y#s:60:%s#i:visTest#v:UIPanelButtonTemplate#Test");
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.conditionEB;
					local cond = buildCondition( editBox:GetText() );
					local action, target = SecureCmdOptionParse(cond);
					print("Tested: ", cond);
					if (target) then
						print("Target used: ", target);
					end
					if (action) then
						print("Result: ", action);
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Test conditions");
					GameTooltip:AddLine("This tests the conditions in the edit box in order to display the current action that will be performed when the conditions are saved.\n\nThis button does not have any effect on the bar.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsAddFrame(  23,   22, "button#tl:140:%y#s:60:%s#i:visSave#v:UIPanelButtonTemplate#Save");
			optionsAddScript("onload",
				function(self)
					self:Disable();
				end
			);
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.conditionEB;
					editBox:HighlightText(0, 0);
					editBox:ClearFocus();
					local cond = editBox:GetText();
					module:setOption("barCondition", cond, true);
					self:Disable();
					editBox.ctUndo = cond;
					groupFrame.visUndo:Disable();
					if (IsShiftKeyDown()) then
						print(buildCondition(cond));
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Save changes");
					GameTooltip:AddLine("This saves the changes you've made to the conditions. The bar will not be affected by the modified conditions until you save the changes.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsAddFrame(  23,   22, "button#tl:220:%y#s:60:%s#i:visUndo#v:UIPanelButtonTemplate#Undo");
			optionsAddScript("onload",
				function(self)
					self:Disable();
				end
			);
			optionsAddScript("onclick",
				function(self)
					local editBox = groupFrame.conditionEB;
					editBox:HighlightText(0, 0);
					editBox:ClearFocus();
					if (editBox.ctUndo) then
						editBox:SetText(editBox.ctUndo);
						self:Disable();
						groupFrame.visSave:Disable();
					end
				end
			);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText("Undo changes");
					GameTooltip:AddLine("This will undo the changes you've made to the conditions.", 1, 1, 1, true);
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();

		optionsAddScript("onload",
			function(self)
				groupFrame = self;
				updateGroupWidgets(currentEditGroup);
				setRadioButtonTextures(self.visBasic);
				setRadioButtonTextures(self.visAdvanced);
			end
		);
	optionsEndFrame();

	-- Reset Options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Reset Options");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:resetAll#Reset options for all of your characters");
		optionsAddFrame( -10,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset options");
			optionsAddScript("onclick",
				function(self)
					-- Delete all options except the key binding reminders.
					-- We're keeping the reminders since the keys will still be bound.
					if (module:getOption("resetAll")) then
						for ck, opt in pairs(CT_BarModOptions) do
							local count = 0;
							if (type(opt) == "table") then
								for k, v in pairs(opt) do
									if (string.sub(k, 1, 8) == "BINDING-") then	
										-- Don't delete
										count = count + 1;
									else
										opt[k] = nil;
									end
								end
							end
							if (count == 0) then
								CT_BarModOptions[ck] = nil;
							end
						end
					else
						if (not CT_BarModOptions or not type(CT_BarModOptions) == "table") then
							CT_BarModOptions = {};
						else
							local ck = module:getCharKey();
							local opt = CT_BarModOptions[ck];
							local count = 0;
							for k, v in pairs(opt) do
								if (string.sub(k, 1, 8) == "BINDING-") then
									-- Don't delete
									count = count + 1;
								else
									opt[k] = nil;
								end
							end
							if (count == 0) then
								CT_BarModOptions[ck] = nil;
							end
						end
					end
					ConsoleExec("RELOADUI");
				end
			);
		optionsEndFrame();
		optionsAddObject( -2, 4*14, "font#t:0:%y#s:0:%s#l#r#Note: This will reset options and bar positions to default and then reload your UI. This will not reset any key bindings.#" .. textColor2);
	optionsEndFrame();

	-- Key Bindings
	-- This should be the last of the options in order to guarantee that
	-- the top part of the keybindings section will always be visible (since
	-- instructions are displayed there while the user is binding keys).

	local keyBindingTemplate = {
		"font#r:l:-2:0#v:GameFontNormalLarge#i:header#1:0.82:0:l",
		"font#r:-5:0#v:GameFontNormal#i:binding##1:0.82:0:r",
		"font#l:5:0#r:l:binding#v:ChatFontNormal#i:spell##1:1:1:l",
		"texture#all#i:background#1:1:1:1:1",

		["onload"] = function(self)
			self.background:SetVertexColor(1, 1, 1, 0);
			self.header:SetFont("FRIZQT__.TTF", 20,"OUTLINE, MONOCHROME")
		end,
		["onenter"] = function(self)
			if ( self.selected ) then
				return;
			end
			self.background:SetVertexColor(1, 1, 1, 0.2);
		end,
		["onleave"] = function(self)
			if ( self.selected ) then
				return;
			end
			self.background:SetVertexColor(1, 1, 1, 0);
		end,
		["onclick"] = function(self)
			if ( currentBinding ~= self ) then
				selectObject(self);
			end
		end,
		["onmousedown"] = function(self, button)
			if ( currentBinding == self ) then
				setBinding(button);
			end
		end
	};

	optionsAddFrame(-15, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Key Bindings");
		optionsAddObject(-10, 4*14, "font#t:5:%y#v:GameFontNormal#i:instruction");
		for i = 1, 13 do
			optionsAddFrame(  0,   25, "button#tl:20:%y#s:0:%s#r:-20:0#i:" .. i, keyBindingTemplate);
			optionsEndFrame();
		end
		optionsAddScript("onload",
			function(self)
				bindingFrame = self;
				module:regEvent("UPDATE_BINDINGS", updateKeyBinds);

				local yoffset = self:GetTop() - self["1"]:GetTop();

				local scrollFrame = CreateFrame("ScrollFrame", "CT_BarModOptionsKeyBindingsScrollFrame",
					self, "FauxScrollFrameTemplate");
				scrollFrame:SetPoint("TOPLEFT", self, 0, -yoffset);
				scrollFrame:SetPoint("BOTTOMRIGHT", self, -19, 0);
				scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
					FauxScrollFrame_OnVerticalScroll(self, offset, 25, updateKeyBindingsScroll);
				end);
				scrollFrame:SetScript("OnMouseWheel", function(self, delta)
					if ( bindingFrame:IsKeyboardEnabled() ) then
						if ( delta > 0 ) then
							setBinding("MOUSEWHEELUP");
						else
							setBinding("MOUSEWHEELDOWN");
						end
					else
						ScrollFrameTemplate_OnMouseWheel(self, delta);
					end
				end);
			end
		);
		optionsAddScript("onshow",
			function(self)
				captureBinding();
				updateKeyBindingsScroll();
			end
		);
		optionsAddScript("onkeydown",
			function(self, key)
				setBinding(key);
			end
		);
	optionsEndFrame();

	optionsAddScript("onshow",
		function(self)
			showGroupHeaders();
		end
	);

	optionsAddScript("onhide",
		function(self)
			hideGroupHeaders();
		end
	);

	return "frame#all", optionsGetData();
end

local function CT_BarMod_UpdateGroupVisibility(groupId)
	if (not InCombatLockdown()) then
		local cond;
		local frame = _G["CT_BarMod_Group" .. groupId];

		if (module:getOption("showGroup" .. groupId) == false) then
			-- Disabled
			UnregisterStateDriver(frame, "visibility");
			frame:Hide();
		else
			local barVisibility = module:getOption("barVisibility" .. groupId) or 1;

			if (barVisibility == 2) then
				-- Advanced conditions
				cond = buildCondition(module:getOption("barCondition" .. groupId) or "");
				RegisterStateDriver(frame, "visibility", cond);
			else
				-- Basic conditions
				local hideInCombat = module:getOption("barHideInCombat" .. groupId);
				local hideNotCombat = module:getOption("barHideNotCombat" .. groupId);
				local hideInVehicle = module:getOption("barHideInVehicle" .. groupId) ~= false;
	
				if (hideInVehicle) then
					cond = "[vehicleui]hide;";
				else
					cond = "";
				end
				if (hideInCombat) then
					cond = cond .. "[combat]hide;";
				end
				if (hideNotCombat) then
					cond = cond .. "[nocombat]hide;";
				end

				if (groupId == module.controlBarId) then
					cond = cond .. "[bonusbar:5]show;hide";
				else
					cond = cond .. "show";
				end
				RegisterStateDriver(frame, "visibility", cond);
			end
		end
	end
end

local function CT_BarMod_UpdateVisibility()
	for num, group in pairs(groupList) do
		CT_BarMod_UpdateGroupVisibility(group.id);
	end
end
module.CT_BarMod_UpdateVisibility = CT_BarMod_UpdateVisibility;

local function CT_BarMod_OnEvent(self, event, arg1, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		CT_BarMod_UpdateVisibility();

	elseif (event == "PLAYER_REGEN_ENABLED") then
		CT_BarMod_UpdateVisibility();
		updateGroups();

	elseif (event == "PLAYER_REGEN_DISABLED") then
		CT_BarMod_UpdateVisibility();
		updateGroups();

	end
end

-------------------
-- Handle options

local function CT_BarMod_UpdateMouseoverSchedule()
	local moFlag;
	for num, group in pairs(groupList) do
		local show = (module:getOption("showGroup" .. group.id) ~= false);
		if (show and group.barMouseover) then
			moFlag = true;
			break;
		end
	end
	if (moFlag) then
		if (not module.groupFrameOnUpdate) then
			module.groupFrameOnUpdate = module.checkMouseover;
			module:schedule(0.03, true, module.groupFrameOnUpdate);
		end
	else
		if (module.groupFrameOnUpdate) then
			module:unschedule(module.groupFrameOnUpdate, true);
			module.groupFrameOnUpdate = nil;
		end
	end
end

module.optionUpdate = function(self, type, value)
	-- Update an option.

	-- Group id of the group currently being edited.
	local id = currentEditGroup;

	if ( type ~= "init" and value == nil ) then
		-- Prevent ininfite loop when clearing an option
		-- from within this function.
		return;
	end

	-- Translate option name, value, etc. if necessary before processing the option.
	if ( type == "visBasic" ) then
		self:setOption(type, nil, true);
		type = "barVisibility";
		value = 1;

	elseif ( type == "visAdvanced" ) then
		self:setOption(type, nil, true);
		type = "barVisibility";
		value = 2;

	end

	-- Process the options
	if ( type == "editGroup" ) then
		-- Select bar to edit.
		self:setOption("editGroup", nil, true);
		currentEditGroup = module.GroupNumToId(value);
		id = currentEditGroup;
		updateGroupWidgets(id);
	
	elseif ( type == "nextGroup" ) then
		-- Select next bar to edit.
		self:setOption("nextGroup", nil, true);
		value = module.GroupIdToNum(currentEditGroup);
		value = value + 1;
		if (value > module.maxBarNum) then
			value = 1
		end
		currentEditGroup = module.GroupNumToId(value);
		id = currentEditGroup;
		updateGroupWidgets(id);

	elseif ( type == "prvsGroup" ) then
		-- Select previous bar to edit.
		self:setOption("prvsGroup", nil, true);
		value = module.GroupIdToNum(currentEditGroup);
		value = value - 1;
		if (value < 1) then
			value = module.maxBarNum;
		end
		currentEditGroup = module.GroupNumToId(value);
		id = currentEditGroup;
		updateGroupWidgets(id);

	elseif (strsub(type, 1, 9) == "showGroup") then
		local groupid = type:match("^showGroup(%d+)$");
		id = (tonumber(groupid) or id);
		type = "showGroup";

		-- Call the group's update function.
		local group = groupList[ module.GroupIdToNum(id) ];
		if ( group ) then
			group:update(type, value);
		end

		updateGroupWidgets_ShowGroup(id);

		-- Update opacity.
		CT_BarMod_UpdateMouseoverSchedule();
		if (group) then
			group:updateOpacity();
		end

		-- Update visibility.
		if (group) then
			CT_BarMod_UpdateGroupVisibility(id);
		end

	elseif (
		-- These are the options that are in the Bar
		-- Options section. We use non-group specific
		-- options in that section and then update
		-- the group specific options here.
		type == "barScale" or 
		type == "barSpacing" or
		type == "orientation" or
		type == "barColumns" or
		type == "barOpacity" or 
		type == "barFaded" or 
		type == "barMouseover" or 
		type == "barVisibility" or
		type == "barHideInVehicle" or
		type == "barHideInCombat" or 
		type == "barHideNotCombat" or
		type == "barCondition"

	) then
		if (type == "orientation") then
			-- Translate drop down menu index value into
			-- the string values the rest of the addon uses.
			if (value == 2) then
				value = "DOWN";
			else
				value = "ACROSS";
			end
		end

		-- Clear the non-group specific option.
		self:setOption(type, nil, true);

		-- Assign the value to the group specific option.
		self:setOption(type .. id, value, true);
		
		-- Call the group's update function.
		local group = groupList[ module.GroupIdToNum(id) ];
		if ( group ) then
			group:update(type, value);
		end

		-- Update some stuff on the options window.
		if (type == "orientation") then
			-- Changing orientation affects two widgets.
			module.updateGroupWidgets_Orientation(id);
			module.updateGroupWidgets_Columns(id);

		elseif (type == "barVisibility") then
			-- Need to update visibility widgets (two checkbuttons
			-- disguised as radio buttons).
			updateGroupWidgets_Visibility(id);
		end

		-- Update opacity.
		if (
			type == "barOpacity" or
			type == "barFaded" or
			type == "barMouseover" or
			type == "barVisibility" or
			type == "barCondition"
		) then
			CT_BarMod_UpdateMouseoverSchedule();
			if (group) then
				group:updateOpacity();
			end
		end

		-- Update visibility.
		if (
			type == "barVisibility" or
			type == "barHideInVehicle" or 
			type == "barHideInCombat" or 
			type == "barHideNotCombat" or
			type == "barCondition"
		) then
			if (group) then
				CT_BarMod_UpdateGroupVisibility(id);
			end
		end

	elseif ( type == "dragOnTop" ) then
		module.setDragOnTop(value);

	elseif ( type == "displayCount" ) then
		CT_BarMod_HideShowAllCooldowns(value);

	elseif ( type == "shiftParty" ) then
		CT_BarMod_Shift_Party_SetFlag();
		CT_BarMod_Shift_Party_Move();

	elseif ( type == "shiftPartyOffset" ) then
		CT_BarMod_Shift_Party_SetReshiftFlag();
		CT_BarMod_Shift_Party_Move();

	elseif ( type == "shiftFocus" ) then
		CT_BarMod_Shift_Focus_SetFlag();
		CT_BarMod_Shift_Focus_Move();

	elseif ( type == "shiftFocusOffset" ) then
		CT_BarMod_Shift_Focus_SetReshiftFlag();
		CT_BarMod_Shift_Focus_Move();

	elseif ( type == "shiftMultiCast" ) then
		CT_BarMod_Shift_MultiCast_UpdatePositions();

	elseif ( type == "shiftPet" ) then
		CT_BarMod_Shift_Pet_UpdatePositions();

	elseif ( type == "shiftPossess" ) then
		CT_BarMod_Shift_Possess_UpdatePositions();

	elseif ( type == "shiftShapeshift" ) then
		CT_BarMod_Shift_Shapeshift_UpdatePositions();

	elseif ( type == "cooldownFontColor" ) then
		updateCooldownFontColor();

	elseif ( type == "cooldownFontStyleNum" ) then
		local fontStyleNum = value;
		if (not fontStyleNum or fontStyleNum > #fontStyleListSorted) then
			fontStyleNum = fontDefaultStyleNum;
		end
		local fontStyleName = fontStyleListSorted[fontStyleNum];
		module:setOption("cooldownFontStyleName", fontStyleName, true);
		updateCooldownFont();

	elseif ( type == "cooldownFontSize" ) then
		updateCooldownFont();

	elseif ( type == "cooldownFontTypeNum" ) then
		local fontTypeNum = value;
		if (not fontTypeNum or fontTypeNum > #fontTypeListSorted) then
			fontTypeNum = fontDefaultTypeNum;
		end
		local fontTypeName = fontTypeListSorted[fontTypeNum];
		module:setOption("cooldownFontTypeName", fontTypeName, true);
		updateCooldownFont();

	elseif ( type == "init" ) then
		updateCooldownFont();
		updateGroups();
		updateGroupWidgets(id);

		CT_BarMod_UpdateMouseoverSchedule();

		module.setDragOnTop(module:getOption("dragOnTop"));

		-- Frame to watch for events
		local frame = CreateFrame("Frame", "CT_BarMod_EventFrame");
		frame:SetScript("OnEvent", CT_BarMod_OnEvent);
		frame:RegisterEvent("PLAYER_REGEN_ENABLED");
		frame:RegisterEvent("PLAYER_REGEN_DISABLED");
		frame:RegisterEvent("PLAYER_ENTERING_WORLD");
		frame:Show();

		CT_BarMod_Shift_Init();
	end

	-- Clear edit box focus and highlight.
	-- Calling it here will ensure the focus is removed regardless of
	-- which option the user changes.
	if (groupFrame) then
		groupFrame.conditionEB:ClearFocus();
		groupFrame.conditionEB:HighlightText(0, 0);
	end
end
