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

-- Options
local displayBindings = true;
local displayRangeDot = true;
local displayActionText = true;
local displayCount = true;
local colorLack = 1;
local buttonLock = false;
local hideGrid = false;
local hideTooltip = false;

-- In combat flag
local inCombat = false;

--------------------------------------------
-- Local Copies

local rangeIndicator = RANGE_INDICATOR;
local GetTime = GetTime;
local ceil = ceil;
local next = next;

local HasAction = HasAction;
local ActionHasRange = ActionHasRange;

local GetActionRange = GetActionRange;
local GetActionTexture = GetActionTexture;
local GetActionCooldown = GetActionCooldown;

local IsUsableAction = IsUsableAction;
local IsAttackAction = IsAttackAction;
local IsCurrentAction = IsCurrentAction;
local IsConsumableAction = IsConsumableAction;
local IsStackableAction = IsStackableAction;
local IsAutoRepeatAction = IsAutoRepeatAction;

--------------------------------------------
-- Cooldown Handler

local cooldownList, cooldownUpdater;

local function updateCooldown(fsCount, time)
	if ( time > 3540 ) then
		-- Hours
		fsCount:SetText(ceil(time/3600).."h");
	elseif ( time > 60 ) then
		-- Minutes
		fsCount:SetText(ceil(time/60).."m");
	elseif ( time > 1 ) then
		-- Seconds
		fsCount:SetText(ceil(time));
	else
		fsCount:SetText("");
	end
end

local function dropCooldownFromQueue(button)
	if ( cooldownList ) then
		cooldownList[button] = nil;
		if ( not next(cooldownList) ) then
			module:unschedule(cooldownUpdater, true);
		end
	end
end

cooldownUpdater = function()
	if ( cooldownList ) then
		local currTime = GetTime();
		local start, duration, enable;
		for button, fsCount in pairs(cooldownList) do
			start, duration, enable = GetActionCooldown(button.id);
			if ( start > 0 and duration > 0 and enable > 0 ) then
				updateCooldown(fsCount, duration - (currTime - start));
			else
				dropCooldownFromQueue(button);
			end
		end
	end
end

local function stopCooldown(cooldown)
	local fsCount = cooldown.fsCount;
	if ( fsCount ) then
		fsCount:Hide();
	end
	if (cooldown.object) then
		dropCooldownFromQueue(cooldown.object);
	end
end

local function hideCooldown(cooldown)
	local fsCount = cooldown.fsCount;
	if ( fsCount ) then
		fsCount:Hide();
	end
end

function CT_BarMod_HideShowAllCooldowns(show)
	if ( cooldownList ) then
		for button, fsCount in pairs(cooldownList) do
			if ( fsCount ) then
				if (show) then
					fsCount:Show();
				else
					fsCount:Hide();
				end
			end
		end
	end
end

local function startCooldown(cooldown, start, duration)
	if ( duration < 2 ) then
		stopCooldown(cooldown);
		return;
	end
	
	local fsCount = cooldown.fsCount;
	local font = "CT_BarMod_CooldownFont";
	if ( not fsCount ) then
		fsCount = cooldown:CreateFontString(nil, "OVERLAY", font);
		fsCount:SetPoint("CENTER", cooldown);
		cooldown.fsCount = fsCount;
	end
	
	if ( not cooldownList ) then
		cooldownList = { [cooldown.object] = fsCount };
		module:schedule(0.5, true, cooldownUpdater);
	else
		if ( not next(cooldownList) ) then
			module:schedule(0.5, true, cooldownUpdater);
		end
		cooldownList[cooldown.object] = fsCount;
	end
	
	fsCount:Show();
	updateCooldown(fsCount, duration - (GetTime() - start));
end

--------------------------------------------
-- Use Button Class

local useButton = { };
local actionButton = module.actionButtonClass;
local actionButtonList = module.actionButtonList;

setmetatable(useButton, { __index = actionButton });
module.useButtonClass = useButton;

-- Constructor
function useButton:constructor(...)
	actionButton.constructor(self, ...);
	
	-- Do stuff
	local button = self.button;
	if (self.id == module.controlCancel) then
		-- Since this action id isn't used for anything, we're
		-- going to use it to display a button that can be used
		-- to cancel control.
		-- There are a few other places in this addon that tests
		-- for this action id number.
		button:SetAttribute("type", "click")
		button:SetAttribute("clickbutton", PossessButton2)
	end
	button:SetAttribute("*action*", self.id);
	button:SetAttribute("checkselfcast", true);
	button:SetAttribute("checkfocuscast", true);
	button.border:SetVertexColor(0, 1, 0, 0.35);
end

-- Destructor
function useButton:destructor(...)
	-- Do stuff
	self.hasAction = nil;
	self.hasRange = nil;
	self.checked = nil;
	
	if ( self.flashing ) then
		self:stopFlash();
	end
	
	actionButton.destructor(self, ...);
end

-- Update everything
function useButton:update()
	local id = self.id;
	local hasAction = HasAction(id);
	local button = self.button;
	
	self.hasAction = hasAction;
	self.hasRange = ActionHasRange(id);
	
	self:updateCount();
	self:updateBinding();
	self:updateTexture();
	self:updateOpacity();
	if ( hasAction or self.id == module.controlCancel ) then
		self:updateState();
		self:updateUsable();
		self:updateFlash();
		self:updateCooldown();
		self:updateLock();
		
		if ( not inCombat ) then
			button:Show();
		end
	else
		button.cooldown:Hide();
		if ( not inCombat ) then
			if ( hideGrid and not self.gridShown ) then
				button:Hide();
			else
				button:Show();
			end
		end
	end
	
	-- Textures
	if ( hasAction ) then
		local icon = button.icon;
		icon:SetTexture(GetActionTexture(id));
		icon:Show();
		button.normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2");
	elseif (self.id == module.controlCancel) then
		button.icon:SetTexture("Interface\\Icons\\Spell_Shadow_SacrificialShield");
		button.icon:Show();
		button.normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2");
	else
		button.icon:Hide();
		button.normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot");
	end
	
	-- Equip
	if ( IsEquippedAction(id) ) then
		button.border:SetVertexColor(0, 1.0, 0, 0.35); -- green border for equipped items
		button.border:Show();
	else
		button.border:Hide();
	end
	
	-- Action text
	if ( displayActionText and not IsConsumableAction(id) and not IsStackableAction(id) ) then
		button.name:SetText(GetActionText(id));
	else
		button.name:SetText("");
	end
end

-- Check button lock state to disable shift-click
function useButton:updateLock()
	--[[ Disabling this functionality for now
	if ( buttonLock ) then
		self.button:SetAttribute("shift-type*", ATTRIBUTE_NOOP);
	else
		self.button:SetAttribute("shift-type*", nil);
	end ]]
end

-- Update Usable
function useButton:updateUsable()
	local isUsable, notEnoughMana = IsUsableAction(self.id);
	local button = self.button;
	
	if ( self.id == module.controlCancel) then
		button.icon:SetVertexColor(1, 1, 1);

	elseif ( colorLack and self.outOfRange ) then
		if ( colorLack == 2 ) then
			button.icon:SetVertexColor(0.5, 0.5, 0.5);
		else
			button.icon:SetVertexColor(0.8, 0.4, 0.4);
		end
		
	elseif ( isUsable ) then
		button.icon:SetVertexColor(1, 1, 1);
		
	elseif ( notEnoughMana ) then
		button.icon:SetVertexColor(0.5, 0.5, 1);
		
	else
		button.icon:SetVertexColor(0.4, 0.4, 0.4);
	end
end

-- Update opacity
local fadedButtons = {};
local fadedCount = 0;

local function fadeUpdater()
	for button, value in pairs(fadedButtons) do
		button:updateOpacity();
	end
end

function useButton:updateOpacity()
--[[
	local start, duration, enable = GetActionCooldown(self.id);
	if ( start > 0 and duration > 0 and enable > 0 ) then
		if (not fadedButtons[self]) then
			fadedButtons[self] = true;
			fadedCount = fadedCount + 1;
			if (fadedCount == 1) then
				module:unschedule(fadeUpdater, true);
				module:schedule(0.3, true, fadeUpdater);
			end
		end
		self.button:SetAlpha(0.1);
	else
		if (fadedButtons[self]) then
			fadedButtons[self] = nil;
			fadedCount = fadedCount - 1;
			if (fadedCount == 0) then
				module:unschedule(fadeUpdater, true);
			end
		end
]]

		self.button:SetAlpha(self.alphaCurrent or 1);

--	end
end

-- Update Cooldown
function useButton:updateCooldown()
	local start, duration, enable = GetActionCooldown(self.id);
	if ( start > 0 and duration > 0 and enable > 0 ) then
		local cooldown = self.button.cooldown;
		cooldown:SetCooldown(start, duration);
		cooldown:Show();
		
		if ( displayCount ) then
			startCooldown(cooldown, start, duration);
		else
			stopCooldown(cooldown);
		end
	else
		local cooldown = self.button.cooldown;
		stopCooldown(cooldown);
		cooldown:Hide();
	end
end

-- Update State
function useButton:updateState()
	local id = self.id;
	
	if ( IsCurrentAction(id) or IsAutoRepeatAction(id) ) then
		self.checked = true;
		self.button:SetChecked(true);
	else
		self.checked = nil;
		self.button:SetChecked(false);
	end
end

-- Update Binding
function useButton:updateBinding()
	local id = self.id;
	if ( displayBindings ) then
		local text = self:getBinding();
		if ( text == "" or text == nil ) then
			if ( not self.hasAction or not IsActionInRange(id) ) then
				self.button.hotkey:SetText("");
				self.hasRange = nil;
				return;
			else
				if (displayRangeDot) then
					self.button.hotkey:SetText(rangeIndicator);
				else
					self.button.hotkey:SetText("");
				end
				self:updateUsable();
			end
		else
			self.button.hotkey:SetText(text);
		end
		self.hasRange = true;
	else
		if (displayRangeDot) then
			if ( not self.hasAction or not IsActionInRange(id) ) then
				self.button.hotkey:SetText("");
				self.hasRange = nil;
				return;
			else
				self.button.hotkey:SetText(rangeIndicator);
				self:updateUsable();
			end
		else
			self.button.hotkey:SetText("");
		end
		self.hasRange = self.hasAction and ActionHasRange(id);
	end
end

-- Update Range
function useButton:updateRange()
	if ( IsActionInRange(self.id) == 0 ) then
		local button = self.button;
		self.outOfRange = true;
		button.hotkey:SetVertexColor(1.0, 0.1, 0.1);
	else
		self.outOfRange = nil;
		self.button.hotkey:SetVertexColor(0.6, 0.6, 0.6);
	end
	self:updateBinding();
	if ( colorLack ) then
		self:updateUsable();
	end
end

-- Update Count
function useButton:updateCount()
	local id = self.id;
	if ( IsConsumableAction(id) or IsStackableAction(id) ) then
		self.button.count:SetText(GetActionCount(id));
	else
		self.button.count:SetText("");
	end
end

-- Update Flash
function useButton:updateFlash()
	local id = self.id;
	if ( ( IsAttackAction(id) and IsCurrentAction(id) ) or IsAutoRepeatAction(id) ) then
		self:startFlash();
	elseif ( self.flashing ) then
		self:stopFlash();
	end
	self:updateState();
end

-- Show Grid
function useButton:showGrid()
	self.gridShown = true;
	
	local button = self.button;
	if ( not inCombat ) then
		button:Show();
	end
	button.normalTexture:SetVertexColor(1, 1, 1, 0.5);
end

-- Hide Grid
function useButton:hideGrid()
	self.gridShown = nil;
	self:updateUsable();
	if ( hideGrid and not self.hasAction and not inCombat ) then
		self.button:Hide();
	end
end

-- Get Binding
function useButton:getBinding()
	-- local text = module:getOption("BINDING-"..self.id);
	local text = module.getBindingKey(self.id);
	if ( not text ) then
		return;
	end
	
	text = text:gsub("(.-)MOUSEWHEELUP(.+)", "%1WU%2");
	text = text:gsub("(.-)MOUSEWHEELDOWN(.+)", "%1WD%2");
	text = text:gsub("(.-)BUTTON(.+)", "%1B%2");
	text = text:gsub("(.-)SHIFT%-(.+)", "%1S-%2");
	text = text:gsub("(.-)CTRL%-(.+)", "%1C-%2");
	text = text:gsub("(.-)ALT%-(.+)", "%1A-%2");
	return text;
end

------------------------
-- Button Handlers

-- PostClick
function useButton:postclick()
	if ( not self.checked ) then
		self.button:SetChecked(false);
	end
	self:updateState();
end

-- OnDragStart
function useButton:ondragstart()
	if (not InCombatLockdown()) then
		if ( not module:getOption("buttonLock") or IsShiftKeyDown() ) then
			PickupAction(self.id);
			self:updateState();
			self:updateFlash();
		end
	end
end

-- OnReceiveDrag
function useButton:onreceivedrag()
	if (not InCombatLockdown()) then
		PlaceAction(self.id);
		self:updateState();
		self:updateFlash();
	end
end

------------------------
-- Flash Handling

local flashingButtons;

-- Toggles flashing on a button
local function toggleFlash(object, enable)
	local flash = object.button.flash;
	
	if ( enable ~= nil ) then
		if ( enable ) then
			flash:Show();
		else
			flash:Hide();
		end
	else
		if ( not flash:IsShown() ) then
			flash:Show();
		else
			flash:Hide();
		end
	end
end

-- Periodic flash updater
local function flashUpdater()
	if ( flashingButtons ) then
		for key, value in pairs(flashingButtons) do
			toggleFlash(key);
		end
	end
end

-- Start Flashing
function useButton:startFlash()
	if ( not flashingButtons ) then
		flashingButtons = { };
	end
	
	self.flashing = true;
	toggleFlash(self, true);
	flashingButtons[self] = true;
	
	module:unschedule(flashUpdater, true);
	module:schedule(0.5, true, flashUpdater);
end

-- Stop Flashing
function useButton:stopFlash()
	if ( flashingButtons and self.flashing ) then
		self.flashing = nil;
		flashingButtons[self] = nil;
		toggleFlash(self, false);
		if ( not next(flashingButtons) ) then
			module:unschedule(flashUpdater, true);
		end
	end
end

--------------------------------------------
-- Event Handlers

local function eventHandler_UpdateAll(event, unit)
	if ( event ~= "UNIT_INVENTORY_CHANGED" or unit == "player" ) then
		actionButtonList:update();
	end
end

local function eventHandler_HideGrid()
	actionButtonList:hideGrid();
end

local function eventHandler_ShowGrid()
	actionButtonList:showGrid();
end

local function eventHandler_UpdateState()
	actionButtonList:updateState();
end

local function eventHandler_UpdateStateVehicle(event, arg1)
	if (arg1 == "player") then
		eventHandler_UpdateState();
	end
end

local function eventHandler_UpdateStateCompanion(event, arg1)
	if (arg1 == "MOUNT") then
		eventHandler_UpdateState();
	end
end

local function eventHandler_UpdateUsable()
	actionButtonList:updateUsable();
	actionButtonList:updateCooldown();
	actionButtonList:updateOpacity();
end

local function eventHandler_UpdateBindings()
	actionButtonList:updateBinding();
end

local function eventHandler_CheckRepeat()
	actionButtonList:updateFlash();
end

-- Range checker
local function rangeUpdater()
	actionButtonList:updateRange();
end

--------------------------------------------
-- Preset Groups

module.setupPresetGroups = function(self)
	local object;

	for num = 1, module.maxBarNum, 1 do
		local id = module.GroupNumToId(num);
		local base = num - 1;
		local action;
		for y = 1, 12, 1 do
			action = base * 12 + y;
			object = useButton:new(action, id);
			self:addObjectToGroup(object, object.group);
		end
	end
end

--------------------------------------------
-- Default-Bar additions

-- Out of Range timers
	function CT_BarMod_ActionButton_OnUpdate(self, elapsed, ...)
		local rangeTimer = self.rangeTimer;
		if ( rangeTimer and rangeTimer == TOOLTIP_UPDATE_TIME ) then
			if ( colorLack and IsActionInRange(ActionButton_GetPagedID(self)) == 0 ) then
				local icon = _G[self:GetName().."Icon"];
				local normalTexture = _G[self:GetName().."NormalTexture"];
				
				if ( colorLack == 2 ) then
					icon:SetVertexColor(0.5, 0.5, 0.5);
				else
					icon:SetVertexColor(0.8, 0.4, 0.4);
				end
			else
				ActionButton_UpdateUsable(self);
			end
		end
	end
	hooksecurefunc("ActionButton_OnUpdate", CT_BarMod_ActionButton_OnUpdate);

	function CT_BarMod_ActionButton_UpdateUsable(self, ...)
		if ( colorLack and IsActionInRange(ActionButton_GetPagedID(self)) == 0 ) then
			local icon = _G[self:GetName().."Icon"];
			local normalTexture = _G[self:GetName().."NormalTexture"];

			if ( colorLack == 2 ) then
				icon:SetVertexColor(0.5, 0.5, 0.5);
			else
				icon:SetVertexColor(0.8, 0.4, 0.4);
			end
		end
	end
	hooksecurefunc("ActionButton_UpdateUsable", CT_BarMod_ActionButton_UpdateUsable);

-- Cooldown Count
	local function CT_BarMod_ActionButton_UpdateCooldown(self, ...)
		local id = ActionButton_GetPagedID(self);
		local cooldown = _G[self:GetName().."Cooldown"];
		-- Set up variables we need in our cooldown handler
		cooldown.object = self;
		self.id = id;
		local start, duration, enable = GetActionCooldown(id);
		if ( start > 0 and duration > 0 and enable > 0 ) then
			startCooldown(cooldown, start, duration);
			if (not displayCount) then
				hideCooldown(cooldown);
			end
		else
			hideCooldown(cooldown);
		end
	end
	hooksecurefunc("ActionButton_UpdateCooldown", CT_BarMod_ActionButton_UpdateCooldown);

-- Hotkeys
	local function CT_BarMod_ActionButton_UpdateHotkeys(self, ...)
		local hotkey = _G[self:GetName().."HotKey"];
		if (displayBindings and displayRangeDot) then
			-- Default behavior of standard UI is to display both.
			hotkey:SetAlpha(1);
			return;
		end
		local hide;
		if (not displayBindings) then
			if (not displayRangeDot) then
				hide = true;
			else
				if (hotkey:GetText() ~= rangeIndicator) then
					hide = true;
				end
			end
		else
			if (not displayRangeDot) then
				if (hotkey:GetText() == rangeIndicator) then
					hide = true;
				end
			end
		end
		if (hide) then
			hotkey:SetAlpha(0);
		else
			hotkey:SetAlpha(1);
		end
	end
	hooksecurefunc("ActionButton_UpdateHotkeys", CT_BarMod_ActionButton_UpdateHotkeys);

	function CT_BarMod_UpdateActionButtonHotkeys()
		for i=1,12 do
			CT_BarMod_ActionButton_UpdateHotkeys(_G["ActionButton" .. i]);
			CT_BarMod_ActionButton_UpdateHotkeys(_G["BonusActionButton" .. i]);
			CT_BarMod_ActionButton_UpdateHotkeys(_G["MultiBarLeftButton" .. i]);
			CT_BarMod_ActionButton_UpdateHotkeys(_G["MultiBarRightButton" .. i]);
			CT_BarMod_ActionButton_UpdateHotkeys(_G["MultiBarBottomLeftButton" .. i]);
			CT_BarMod_ActionButton_UpdateHotkeys(_G["MultiBarBottomRightButton" .. i]);
		end
	end

-- Action text
	local function CT_BarMod_ActionButton_UpdateActionText(self, ...)
		local name = _G[self:GetName() .. "Name"];
		local id = self.action;
		if ( displayActionText and not IsConsumableAction(id) and not IsStackableAction(id) ) then
			name:SetText(GetActionText(id));
		else
			name:SetText("");
		end
	end
	hooksecurefunc("ActionButton_Update", CT_BarMod_ActionButton_UpdateActionText);

	function CT_BarMod_UpdateActionButtonActionText()
		for i=1,12 do
			CT_BarMod_ActionButton_UpdateActionText(_G["ActionButton" .. i]);
			CT_BarMod_ActionButton_UpdateActionText(_G["BonusActionButton" .. i]);
			CT_BarMod_ActionButton_UpdateActionText(_G["MultiBarLeftButton" .. i]);
			CT_BarMod_ActionButton_UpdateActionText(_G["MultiBarRightButton" .. i]);
			CT_BarMod_ActionButton_UpdateActionText(_G["MultiBarBottomLeftButton" .. i]);
			CT_BarMod_ActionButton_UpdateActionText(_G["MultiBarBottomRightButton" .. i]);
		end
	end

-- Tooltips
	local function CT_BarMod_ActionButton_SetTooltip(self, ...)
		if (hideTooltip) then
			GameTooltip:Hide();
		end
	end
	hooksecurefunc("ActionButton_SetTooltip", CT_BarMod_ActionButton_SetTooltip);

--------------------------------------------
-- Update Initialization

local function combatFlagger(event)
	inCombat = ( event == "PLAYER_REGEN_DISABLED" );
end

local useButtonMeta = { __index = useButton };
module.useButtonMeta = useButtonMeta;
module.useEnable = function(self)
	self:regEvent("PLAYER_ENTERING_WORLD", eventHandler_UpdateAll);
	self:regEvent("UPDATE_SHAPESHIFT_FORM", eventHandler_UpdateAll);
	self:regEvent("UNIT_INVENTORY_CHANGED", eventHandler_UpdateAll);
	self:regEvent("ACTIONBAR_HIDEGRID", eventHandler_HideGrid);
	self:regEvent("ACTIONBAR_SHOWGRID", eventHandler_ShowGrid);
	self:regEvent("ACTIONBAR_UPDATE_STATE", eventHandler_UpdateState);
	self:regEvent("ACTIONBAR_UPDATE_COOLDOWN", eventHandler_UpdateUsable);
	self:regEvent("ACTIONBAR_UPDATE_USABLE", eventHandler_UpdateUsable);
	self:regEvent("UPDATE_INVENTORY_ALERTS", eventHandler_UpdateUsable);
	self:regEvent("CRAFT_SHOW", eventHandler_UpdateState);
	self:regEvent("CRAFT_CLOSE", eventHandler_UpdateState);
	self:regEvent("TRADE_SKILL_SHOW", eventHandler_UpdateState);
	self:regEvent("TRADE_SKILL_CLOSE", eventHandler_UpdateState);
	self:regEvent("UPDATE_BINDINGS", eventHandler_UpdateBindings);
	self:regEvent("PLAYER_ENTER_COMBAT", eventHandler_CheckRepeat);
	self:regEvent("PLAYER_LEAVE_COMBAT", eventHandler_CheckRepeat);
	self:regEvent("STOP_AUTOREPEAT_SPELL", eventHandler_CheckRepeat);
	self:regEvent("START_AUTOREPEAT_SPELL", eventHandler_CheckRepeat);
	self:regEvent("PLAYER_TARGET_CHANGED", rangeUpdater);
	self:regEvent("PLAYER_REGEN_ENABLED", combatFlagger);
	self:regEvent("PLAYER_REGEN_DISABLED", combatFlagger);
	self:regEvent("UNIT_ENTERED_VEHICLE", eventHandler_UpdateStateVehicle);
	self:regEvent("UNIT_EXITED_VEHICLE", eventHandler_UpdateStateVehicle);
	self:regEvent("COMPANION_UPDATE", eventHandler_UpdateStateCompanion);

	self:schedule(0.3, true, rangeUpdater);
end
module.useDisable = function(self)

	self:unregEvent("PLAYER_ENTERING_WORLD", eventHandler_UpdateAll);
	self:unregEvent("UPDATE_SHAPESHIFT_FORM", eventHandler_UpdateAll);
	self:unregEvent("UNIT_INVENTORY_CHANGED", eventHandler_UpdateAll);
	self:unregEvent("ACTIONBAR_HIDEGRID", eventHandler_HideGrid);
	self:unregEvent("ACTIONBAR_SHOWGRID", eventHandler_ShowGrid);
	self:unregEvent("ACTIONBAR_UPDATE_COOLDOWN", eventHandler_UpdateUsable);
	self:unregEvent("ACTIONBAR_UPDATE_STATE", eventHandler_UpdateState);
	self:unregEvent("ACTIONBAR_UPDATE_USABLE", eventHandler_UpdateUsable);
	self:unregEvent("UPDATE_INVENTORY_ALERTS", eventHandler_UpdateUsable);
	self:unregEvent("CRAFT_SHOW", eventHandler_UpdateState);
	self:unregEvent("CRAFT_CLOSE", eventHandler_UpdateState);
	self:unregEvent("TRADE_SKILL_SHOW", eventHandler_UpdateState);
	self:unregEvent("TRADE_SKILL_CLOSE", eventHandler_UpdateState);
	self:unregEvent("UPDATE_BINDINGS", eventHandler_UpdateBindings);
	self:unregEvent("PLAYER_ENTER_COMBAT", eventHandler_CheckRepeat);
	self:unregEvent("PLAYER_LEAVE_COMBAT", eventHandler_CheckRepeat);
	self:unregEvent("STOP_AUTOREPEAT_SPELL", eventHandler_CheckRepeat);
	self:unregEvent("START_AUTOREPEAT_SPELL", eventHandler_CheckRepeat);
	self:unregEvent("PLAYER_TARGET_CHANGED", rangeUpdater);
	self:unregEvent("PLAYER_REGEN_ENABLED", combatFlagger);
	self:unregEvent("PLAYER_REGEN_DISABLED", combatFlagger);
	self:unregEvent("UNIT_ENTERED_VEHICLE", eventHandler_UpdateStateVehicle);
	self:unregEvent("UNIT_EXITED_VEHICLE", eventHandler_UpdateStateVehicle);
	self:unregEvent("COMPANION_UPDATE", eventHandler_UpdateStateCompanion);

	self:unschedule(rangeUpdater, true);
end

module.useUpdate = function(self, type, value)
	if ( type == "colorLack" ) then
		if ( value == 3 ) then
			value = false;
		end
		colorLack = value;
		actionButtonList:updateUsable();
		
	elseif ( type == "displayBindings" ) then
		displayBindings = value;
		actionButtonList:updateBinding();
		CT_BarMod_UpdateActionButtonHotkeys();

	elseif ( type == "displayRangeDot" ) then
		displayRangeDot = value;
		actionButtonList:updateBinding();
		CT_BarMod_UpdateActionButtonHotkeys();

	elseif ( type == "displayActionText" ) then
		displayActionText = value;
		actionButtonList:update();
		CT_BarMod_UpdateActionButtonActionText();

	elseif ( type == "displayCount" ) then
		displayCount = value;
		actionButtonList:updateCooldown();
		
	elseif ( type == "buttonLock" ) then
		buttonLock = value;
		actionButtonList:updateLock();
		
	elseif ( type == "hideGrid" ) then
		hideGrid = value;
		actionButtonList:update();
	
	elseif ( type == "hideTooltip" ) then
		hideTooltip = value;
	
	elseif ( type == "init" ) then
		colorLack = self:getOption("colorLack") or 1;
		if ( colorLack == 3 ) then
			colorLack = false;
		end
		displayBindings = self:getOption("displayBindings") ~= false;
		displayRangeDot = self:getOption("displayRangeDot") ~= false;
		displayActionText = self:getOption("displayActionText") ~= false;
		displayCount = self:getOption("displayCount") ~= false;
		buttonLock = self:getOption("buttonLock");
		hideGrid = self:getOption("hideGrid");
		hideTooltip = self:getOption("hideTooltip");
	end
end
