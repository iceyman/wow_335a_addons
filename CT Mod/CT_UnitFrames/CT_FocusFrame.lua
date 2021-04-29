-- This is a modified version of Blizzard's TargetFrame (based on the 3.2 source)
-- plus some additional functions.
-- This addon displays focus, and focustarget frames.

-- MAX_COMBO_POINTS = 5;
-- MAX_TARGET_DEBUFFS = 16;
-- MAX_TARGET_BUFFS = 32;

-- aura positioning constants
local AURA_START_X = 5;
local AURA_START_Y = 32;
local AURA_OFFSET_Y = 3;
local LARGE_AURA_SIZE = 21;
local SMALL_AURA_SIZE = 17;
local AURA_ROW_WIDTH = 122;
local TOT_AURA_ROW_WIDTH = 101;
local NUM_TOT_AURA_ROWS = 2;	-- TODO: replace with TOT_AURA_ROW_HEIGHT functionality if this becomes a problem

local PLAYER_UNITS = {
	player = true,
	vehicle = true,
	pet = true,
};

function CT_FocusFrame_OnLoad (self)
	self.statusCounter = 0;
	self.statusSign = -1;
	self.unitHPPercent = 1;

	self.ctUpdate = 0;

	CT_FocusFrame_Update(self);
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_FOCUS_CHANGED");
	self:RegisterEvent("UNIT_HEALTH");
	self:RegisterEvent("UNIT_LEVEL");
	self:RegisterEvent("UNIT_FACTION");
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED");
	self:RegisterEvent("UNIT_AURA");
	self:RegisterEvent("PLAYER_FLAGS_CHANGED");
	self:RegisterEvent("PARTY_MEMBERS_CHANGED");
	self:RegisterEvent("RAID_TARGET_UPDATE");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:RegisterEvent("PLAYER_REGEN_DISABLED");

	local frameLevel = CT_FocusFrameTextureFrame:GetFrameLevel();
	CT_FocusFrameHealthBar:SetFrameLevel(frameLevel-1);
	CT_FocusFrameManaBar:SetFrameLevel(frameLevel-1);
	CT_FocusFrameSpellBar:SetFrameLevel(frameLevel-1);

--	local showmenu = function()
--		ToggleDropDownMenu(1, nil, CT_FocusFrameDropDown, "CT_FocusFrame", 120, 10);
--	end
--	SecureUnitButton_OnLoad(self, "focus", showmenu);
	SecureUnitButton_OnLoad(self, "focus");

	self:SetAttribute("type", "target");
	self:SetAttribute("unit", "focus");
	RegisterUnitWatch(CT_FocusFrame);

	CT_FocusFrameHealthBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	CT_FocusFrameManaBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	ClickCastFrames = ClickCastFrames or { };
	ClickCastFrames[self] = true;
end

function CT_FocusFrame_Update (self)
	-- This check is here so the frame will hide when the focus goes away
	-- even if some of the functions below are hooked by addons.
	if (not self) then
		self = CT_FocusFrame;
	end
	if ( not UnitExists("focus") ) then
--		self:Hide();
	else
--		self:Show();

		-- Moved here to avoid taint from functions below
		CT_TargetofFocus_Update();

		UnitFrame_Update(self);
		CT_FocusFrame_CheckLevel(self);
		CT_FocusFrame_CheckFaction(self);
		CT_FocusFrame_CheckClassification(self);
		CT_FocusFrame_CheckDead(self);
--		if ( UnitIsPartyLeader("focus") ) then
--			CT_FocusLeaderIcon:Show();
--		else
			CT_FocusLeaderIcon:Hide();
--		end
		CT_FocusFrame_UpdateAuras(self);
		CT_FocusPortrait:SetAlpha(1.0);
		CT_FocusHealthCheck();
	end
end

function CT_FocusFrame_OnEvent (self, event, ...)
	UnitFrame_OnEvent(self, event, ...);

	local arg1 = ...;
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if (CT_UnitFramesOptions.shallDisplayFocus) then
			RegisterUnitWatch(CT_FocusFrame);
		else
			UnregisterUnitWatch(CT_FocusFrame);
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofFocus) then
			RegisterUnitWatch(CT_TargetofFocusFrame);
		else
			UnregisterUnitWatch(CT_TargetofFocusFrame);
		end
		if (not InCombatLockdown()) then
			CT_UnitFrames_ResetDragLink("CT_FocusFrame_Drag");
		end
		CT_FocusFrame_Update(self);
	elseif ( event == "PLAYER_FOCUS_CHANGED" ) then
		-- Moved here to avoid taint from functions below
		CT_FocusFrame_Update(self);
		CT_FocusFrame_UpdateRaidTargetIcon(self);
--		CloseDropDownMenus();

--		if ( UnitExists("focus") ) then
--			if ( UnitIsEnemy("focus", "player") ) then
--				PlaySound("igCreatureAggroSelect");
--			elseif ( UnitIsFriend("player", "focus") ) then
--				PlaySound("igCharacterNPCSelect");
--			else
--				PlaySound("igCreatureNeutralSelect");
--			end
--		end
	elseif ( event == "UNIT_HEALTH" ) then
		if ( arg1 == "focus" ) then
			CT_FocusFrame_CheckDead(self);
		end
	elseif ( event == "UNIT_LEVEL" ) then
		if ( arg1 == "focus" ) then
			CT_FocusFrame_CheckLevel(self);
		end
	elseif ( event == "UNIT_FACTION" ) then
		if ( arg1 == "focus" or arg1 == "player" ) then
			CT_FocusFrame_CheckFaction(self);
			CT_FocusFrame_CheckLevel(self);
		end
	elseif ( event == "UNIT_CLASSIFICATION_CHANGED" ) then
		if ( arg1 == "focus" ) then
			CT_FocusFrame_CheckClassification(self);
		end
	elseif ( event == "UNIT_AURA" ) then
		if ( arg1 == "focus" ) then
			CT_FocusFrame_UpdateAuras(self);
		end
--	elseif ( event == "PLAYER_FLAGS_CHANGED" ) then
--		if ( arg1 == "focus" ) then
--			if ( UnitIsPartyLeader("focus") ) then
--				CT_FocusLeaderIcon:Show();
--			else
--				CT_FocusLeaderIcon:Hide();
--			end
--		end
	elseif ( event == "PARTY_MEMBERS_CHANGED" ) then
		CT_TargetofFocus_Update();
		CT_FocusFrame_CheckFaction(self);
		CT_FocusFrame_Update();
	elseif ( event == "RAID_TARGET_UPDATE" ) then
		CT_FocusFrame_UpdateRaidTargetIcon(self);
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		if (CT_UnitFramesOptions.shallDisplayFocus) then
			RegisterUnitWatch(CT_FocusFrame);
		else
			UnregisterUnitWatch(CT_FocusFrame);
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofFocus) then
			RegisterUnitWatch(CT_TargetofFocusFrame);
		else
			UnregisterUnitWatch(CT_TargetofFocusFrame);
		end
		CT_UnitFrames_ResetDragLink("CT_FocusFrame_Drag");
	elseif ( event == "PLAYER_REGEN_DISABLED" ) then
		if (CT_UnitFramesOptions.shallDisplayFocus) then
			RegisterUnitWatch(CT_FocusFrame);
		else
			UnregisterUnitWatch(CT_FocusFrame);
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofFocus) then
			RegisterUnitWatch(CT_TargetofFocusFrame);
		else
			UnregisterUnitWatch(CT_TargetofFocusFrame);
		end
		CT_UnitFrames_ResetDragLink("CT_FocusFrame_Drag");
	end
end

function CT_FocusFrame_OnShow(self)
	CT_FocusFrame_Update(self);
end

function CT_FocusFrame_OnHide (self)
--	PlaySound("INTERFACESOUND_LOSTTARGETUNIT");
--	CloseDropDownMenus();
end

function CT_FocusFrame_CheckLevel (self)
	local focusLevel = UnitLevel("focus");
	
	if ( UnitIsCorpse("focus") ) then
		CT_FocusLevelText:Hide();
		CT_FocusHighLevelTexture:Show();
	elseif ( focusLevel > 0 ) then
		-- Normal level focus
		CT_FocusLevelText:SetText(focusLevel);
		-- Color level number
		if ( UnitCanAttack("player", "focus") ) then
			local color = GetQuestDifficultyColor(focusLevel);
			CT_FocusLevelText:SetVertexColor(color.r, color.g, color.b);
		else
			CT_FocusLevelText:SetVertexColor(1.0, 0.82, 0.0);
		end
		CT_FocusLevelText:Show();
		CT_FocusHighLevelTexture:Hide();
	else
		-- Focus is too high level to tell
		CT_FocusLevelText:Hide();
		CT_FocusHighLevelTexture:Show();
	end
end

function CT_FocusFrame_CheckFaction (self)
	if ( not UnitPlayerControlled("focus") and UnitIsTapped("focus") and not UnitIsTappedByPlayer("focus") and not UnitIsTappedByAllThreatList("focus") ) then
		CT_FocusFrameNameBackground:SetVertexColor(0.5, 0.5, 0.5);
		CT_FocusPortrait:SetVertexColor(0.5, 0.5, 0.5);
	else
		CT_FocusFrameNameBackground:SetVertexColor(UnitSelectionColor("focus"));
		CT_FocusPortrait:SetVertexColor(1.0, 1.0, 1.0);
	end

	local factionGroup = UnitFactionGroup("focus");
	if ( UnitIsPVPFreeForAll("focus") ) then
		CT_FocusPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		CT_FocusPVPIcon:Show();
	elseif ( factionGroup and UnitIsPVP("focus") ) then
		CT_FocusPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
		CT_FocusPVPIcon:Show();
	else
		CT_FocusPVPIcon:Hide();
	end
end

function CT_FocusFrame_CheckClassification (self)
	local classification = UnitClassification("focus");
	if ( classification == "worldboss" ) then
		CT_FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite");
		CT_FocusFrameFlash:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
		CT_FocusFrameFlash:SetWidth(242);
		CT_FocusFrameFlash:SetHeight(112);
		CT_FocusFrameFlash:SetPoint("TOPLEFT", CT_FocusFrame, "TOPLEFT", -22, 9);
	elseif ( classification == "rareelite"  ) then
		CT_FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite");
		CT_FocusFrameFlash:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
		CT_FocusFrameFlash:SetWidth(242);
		CT_FocusFrameFlash:SetHeight(112);
		CT_FocusFrameFlash:SetPoint("TOPLEFT", CT_FocusFrame, "TOPLEFT", -22, 9);
	elseif ( classification == "elite"  ) then
		CT_FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite");
		CT_FocusFrameFlash:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
		CT_FocusFrameFlash:SetWidth(242);
		CT_FocusFrameFlash:SetHeight(112);
		CT_FocusFrameFlash:SetPoint("TOPLEFT", CT_FocusFrame, "TOPLEFT", -22, 9);
	elseif ( classification == "rare"  ) then
		CT_FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare");
		CT_FocusFrameFlash:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
		CT_FocusFrameFlash:SetWidth(242);
		CT_FocusFrameFlash:SetHeight(112);
		CT_FocusFrameFlash:SetPoint("TOPLEFT", CT_FocusFrame, "TOPLEFT", -22, 9);
	else
		CT_FocusFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame");
		CT_FocusFrameFlash:SetTexCoord(0, 0.9453125, 0, 0.181640625);
		CT_FocusFrameFlash:SetWidth(242);
		CT_FocusFrameFlash:SetHeight(93);
		CT_FocusFrameFlash:SetPoint("TOPLEFT", CT_FocusFrame, "TOPLEFT", -24, 0);
	end
end

function CT_FocusFrame_CheckDead (self)
	if ( (UnitHealth("focus") <= 0) and UnitIsConnected("focus") ) then
		CT_FocusDeadText:Show();
		return true;
	else
		CT_FocusDeadText:Hide();
		return false;
	end
end

function CT_FocusFrame_OnUpdate (self, elapsed)
	if ( CT_TargetofFocusFrame:IsShown() ~= UnitExists("focustarget") ) then
		CT_TargetofFocus_Update();
	end
	
	self.ctUpdate = self.ctUpdate + elapsed;
	if ( self.ctUpdate > 0.1 ) then
		self.ctUpdate = 0;
		CT_FocusFrame_Update(self);
	end

	self.elapsed = (self.elapsed or 0) + elapsed;
	if ( self.elapsed > 0.5 ) then
		self.elapsed = 0;
		UnitFrame_UpdateThreatIndicator(self.threatIndicator, self.threatNumericIndicator, self.feedbackUnit);
	end
end

local largeBuffList = {};
local largeDebuffList = {};

function CT_FocusFrame_UpdateAuras (self)
	local frame, frameName;
	local frameIcon, frameCount, frameCooldown;

	local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable;
	local playerIsFocus = UnitIsUnit(PlayerFrame.unit, "focus");

	local frameStealable;
	local numBuffs = 0;
	for i=1, MAX_TARGET_BUFFS do
		name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable = UnitBuff("focus", i);
		frameName = "CT_FocusFrameBuff"..i;
		frame = _G[frameName];
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, CT_FocusFrame, "CT_FocusBuffFrameTemplate");
				frame.unit = "focus";
			end
		end
		if ( icon ) then
			frame:SetID(i);

			-- set the icon
			frameIcon = _G[frameName.."Icon"];
			frameIcon:SetTexture(icon);

			-- set the count
			frameCount = _G[frameName.."Count"];
			if ( count > 1 ) then
				frameCount:SetText(count);
				frameCount:Show();
			else
				frameCount:Hide();
			end

			-- Handle cooldowns
			frameCooldown = _G[frameName.."Cooldown"];
			if ( duration > 0 ) then
				frameCooldown:Show();
				CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1);
			else
				frameCooldown:Hide();
			end

			-- Show stealable frame if the focus is not a player and the buff is stealable.
			frameStealable = _G[frameName.."Stealable"];
			if ( not playerIsFocus and isStealable ) then
				frameStealable:Show();
			else
				frameStealable:Hide();
			end

			-- set the buff to be big if the focus is not the player and the buff is cast by the player or his pet
			largeBuffList[i] = (not playerIsFocus and PLAYER_UNITS[caster]);

			numBuffs = numBuffs + 1;

			frame:ClearAllPoints();
			frame:Show();
		else
			frame:Hide();
		end
	end

	local color;
	local frameBorder;
	local numDebuffs = 0;
	for i=1, MAX_TARGET_DEBUFFS do
		name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitDebuff("focus", i);
		frameName = "CT_FocusFrameDebuff"..i;
		frame = _G[frameName];
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, CT_FocusFrame, "CT_FocusDebuffFrameTemplate");
				frame.unit = "focus";
			end
		end
		if ( icon ) then
			frame:SetID(i);

			-- set the icon
			frameIcon = _G[frameName.."Icon"];
			frameIcon:SetTexture(icon);

			-- set the count
			frameCount = _G[frameName.."Count"];
			if ( count > 1 ) then
				frameCount:SetText(count);
				frameCount:Show();
			else
				frameCount:Hide();
			end

			-- Handle cooldowns
			frameCooldown = _G[frameName.."Cooldown"];
			if ( duration > 0 ) then
				frameCooldown:Show();
				CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1);
			else
				frameCooldown:Hide();
			end

			-- set debuff type color
			if ( debuffType ) then
				color = DebuffTypeColor[debuffType];
			else
				color = DebuffTypeColor["none"];
			end
			frameBorder = _G[frameName.."Border"];
			frameBorder:SetVertexColor(color.r, color.g, color.b);

			-- set the debuff to be big if the buff is cast by the player or his pet
			largeDebuffList[i] = (PLAYER_UNITS[caster]);

			numDebuffs = numDebuffs + 1;

			frame:ClearAllPoints();
			frame:Show();
		else
			frame:Hide();
		end
	end

	CT_FocusFrame.auraRows = 0;
	local haveTargetofFocus = CT_TargetofFocusFrame:IsShown();
	local maxRowWidth;
	-- update buff positions
	maxRowWidth = ( haveTargetofFocus and TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	CT_FocusFrame_UpdateAuraPositions("CT_FocusFrameBuff", numBuffs, numDebuffs, largeBuffList, CT_FocusFrame_UpdateBuffAnchor, maxRowWidth, 3);
	-- update debuff positions
	maxRowWidth = ( haveTargetofFocus and CT_FocusFrame.auraRows < NUM_TOT_AURA_ROWS and TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	CT_FocusFrame_UpdateAuraPositions("CT_FocusFrameDebuff", numDebuffs, numBuffs, largeDebuffList, CT_FocusFrame_UpdateDebuffAnchor, maxRowWidth, 4);
	-- update the spell bar position
	CT_Focus_Spellbar_AdjustPosition();
end

function CT_FocusFrame_UpdateAuraPositions(auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX)
	-- a lot of this complexity is in place to allow the auras to wrap around the target of focus frame if it's shown

	-- Position auras
	local size;
	local offsetY = AURA_OFFSET_Y;
	-- current width of a row, increases as auras are added and resets when a new aura's width exceeds the max row width
	local rowWidth = 0;
	local firstBuffOnRow = 1;
	for i=1, numAuras do
		-- update size and offset info based on large aura status
		if ( largeAuraList[i] ) then
			size = LARGE_AURA_SIZE;
			offsetY = AURA_OFFSET_Y + AURA_OFFSET_Y;
		else
			size = SMALL_AURA_SIZE;
		end

		-- anchor the current aura
		if ( i == 1 ) then
			rowWidth = size;
			CT_FocusFrame.auraRows = CT_FocusFrame.auraRows + 1;
		else
			rowWidth = rowWidth + size + offsetX;
		end
		if ( rowWidth > maxRowWidth ) then
			-- this aura would cause the current row to exceed the max row width, so make this aura
			-- the start of a new row instead
			updateFunc(auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX, offsetY);

			rowWidth = size;
			CT_FocusFrame.auraRows = CT_FocusFrame.auraRows + 1;
			firstBuffOnRow = i;
			offsetY = AURA_OFFSET_Y;

			if ( CT_FocusFrame.auraRows > NUM_TOT_AURA_ROWS ) then
				-- if we exceed the number of tot rows, then reset the max row width
				-- note: don't have to check if we have tot because AURA_ROW_WIDTH is the default anyway
				maxRowWidth = AURA_ROW_WIDTH;
			end
		else
			updateFunc(auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY);
		end
	end
end

function CT_FocusFrame_UpdateBuffAnchor(buffName, index, numDebuffs, anchorIndex, size, offsetX, offsetY)
	local buff = _G[buffName..index];

	if ( index == 1 ) then
		if ( UnitIsFriend("player", "focus") or numDebuffs == 0 ) then
			-- unit is friendly or there are no debuffs...buffs start on top
			buff:SetPoint("TOPLEFT", CT_FocusFrame, "BOTTOMLEFT", AURA_START_X, AURA_START_Y);
		else
			-- unit is not friendly and we have debuffs...buffs start on bottom
			buff:SetPoint("TOPLEFT", CT_FocusFrameDebuffs, "BOTTOMLEFT", 0, -offsetY);
		end
		CT_FocusFrameBuffs:SetPoint("TOPLEFT", buff, "TOPLEFT", 0, 0);
		CT_FocusFrameBuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -AURA_OFFSET_Y);
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint("TOPLEFT", _G[buffName..anchorIndex], "BOTTOMLEFT", 0, -offsetY);
		CT_FocusFrameBuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -AURA_OFFSET_Y);
	else
		-- anchor index is the previous index
		buff:SetPoint("TOPLEFT", _G[buffName..anchorIndex], "TOPRIGHT", offsetX, 0);
	end

	-- Resize
	buff:SetWidth(size);
	buff:SetHeight(size);
end

function CT_FocusFrame_UpdateDebuffAnchor(debuffName, index, numBuffs, anchorIndex, size, offsetX, offsetY)
	local buff = _G[debuffName..index];

	if ( index == 1 ) then
		if ( UnitIsFriend("player", "focus") and numBuffs > 0 ) then
			-- unit is friendly and there are buffs...debuffs start on bottom
			buff:SetPoint("TOPLEFT", CT_FocusFrameBuffs, "BOTTOMLEFT", 0, -offsetY);
		else
			-- unit is not friendly or there are no buffs...debuffs start on top
			buff:SetPoint("TOPLEFT", CT_FocusFrame, "BOTTOMLEFT", AURA_START_X, AURA_START_Y);
		end
		CT_FocusFrameDebuffs:SetPoint("TOPLEFT", buff, "TOPLEFT", 0, 0);
		CT_FocusFrameDebuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -AURA_OFFSET_Y);
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint("TOPLEFT", _G[debuffName..anchorIndex], "BOTTOMLEFT", 0, -offsetY);
		CT_FocusFrameDebuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -AURA_OFFSET_Y);
	else
		-- anchor index is the previous index
		buff:SetPoint("TOPLEFT", _G[debuffName..(index-1)], "TOPRIGHT", offsetX, 0);
	end

	-- Resize
	buff:SetWidth(size);
	buff:SetHeight(size);
	local debuffFrame =_G[debuffName..index.."Border"];
	debuffFrame:SetWidth(size+2);
	debuffFrame:SetHeight(size+2);
end

function CT_FocusFrame_HealthUpdate (self, elapsed, unit)
	if ( UnitIsPlayer(unit) ) then
		if ( (self.unitHPPercent > 0) and (self.unitHPPercent <= 0.2) ) then
			local alpha = 255;
			local counter = self.statusCounter + elapsed;
			local sign    = self.statusSign;
	
			if ( counter > 0.5 ) then
				sign = -sign;
				self.statusSign = sign;
			end
			counter = mod(counter, 0.5);
			self.statusCounter = counter;
	
			if ( sign == 1 ) then
				alpha = (127  + (counter * 256)) / 255;
			else
				alpha = (255 - (counter * 256)) / 255;
			end
			CT_FocusPortrait:SetAlpha(alpha);
		end
	end
end

function CT_FocusHealthCheck (self)
	if ( UnitIsPlayer("focus") ) then
		if (not self) then
			self = CT_FocusFrameHealthBar;
		end
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = self:GetMinMaxValues();
		unitCurrHP = self:GetValue();
		self:GetParent().unitHPPercent = unitCurrHP / unitHPMax;
		if ( UnitIsDead("focus") ) then
			CT_FocusPortrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
		elseif ( UnitIsGhost("focus") ) then
			CT_FocusPortrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
		elseif ( (self:GetParent().unitHPPercent > 0) and (self:GetParent().unitHPPercent <= 0.2) ) then
			CT_FocusPortrait:SetVertexColor(1.0, 0.0, 0.0);
		else
			CT_FocusPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		end
	else
		CT_FocusPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
	if ( not UnitIsPlayer("focus") ) then
		CT_FocusFrame_CheckFaction();
	end
end

--[[
function CT_FocusFrameDropDown_OnLoad (self)
	UIDropDownMenu_Initialize(self, CT_FocusFrameDropDown_Initialize, "MENU");
end
]]

--[[
function CT_FocusFrameDropDown_Initialize (self)
	local menu;
	local name;
	local id = nil;
	if ( UnitIsUnit("focus", "player") ) then
		menu = "SELF";
	elseif ( UnitIsUnit("focus", "vehicle") ) then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		menu = "VEHICLE";
	elseif ( UnitIsUnit("focus", "pet") ) then
		menu = "PET";
	elseif ( UnitIsPlayer("focus") ) then
		id = UnitInRaid("focus");
		if ( id ) then
			menu = "RAID_PLAYER";
			name = GetRaidRosterInfo(id +1);
		elseif ( UnitInParty("focus") ) then
			menu = "PARTY";
		else
			menu = "PLAYER";
		end
	else
		menu = "TARGET";
		name = RAID_TARGET_ICON;
	end
	if ( menu ) then
		UnitPopup_ShowMenu(self, menu, "focus", name, id);
	end
end
]]


-- -- Raid target icon function
-- RAID_TARGET_ICON_DIMENSION = 64;
-- RAID_TARGET_TEXTURE_DIMENSION = 256;
-- RAID_TARGET_TEXTURE_COLUMNS = 4;
-- RAID_TARGET_TEXTURE_ROWS = 4;
function CT_FocusFrame_UpdateRaidTargetIcon (self)
	local index = GetRaidTargetIndex("focus");
	if ( index ) then
		SetRaidTargetIconTexture(CT_FocusRaidTargetIcon, index);
		CT_FocusRaidTargetIcon:Show();
	else
		CT_FocusRaidTargetIcon:Hide();
	end
end


-- function SetRaidTargetIconTexture (texture, raidTargetIconIndex)
-- 	raidTargetIconIndex = raidTargetIconIndex - 1;
-- 	local left, right, top, bottom;
-- 	local coordIncrement = RAID_TARGET_ICON_DIMENSION / RAID_TARGET_TEXTURE_DIMENSION;
-- 	left = mod(raidTargetIconIndex , RAID_TARGET_TEXTURE_COLUMNS) * coordIncrement;
-- 	right = left + coordIncrement;
-- 	top = floor(raidTargetIconIndex / RAID_TARGET_TEXTURE_ROWS) * coordIncrement;
-- 	bottom = top + coordIncrement;
-- 	texture:SetTexCoord(left, right, top, bottom);
-- end

-- function SetRaidTargetIcon (unit, index)
-- 	if ( GetRaidTargetIndex(unit) and GetRaidTargetIndex(unit) == index ) then
-- 		SetRaidTarget(unit, 0);
-- 	else
-- 		SetRaidTarget(unit, index);
-- 	end
-- end

-- ------------------------------------------------------------------------

function CT_TargetofFocus_OnLoad (self)
	UnitFrame_Initialize(self, "focustarget", CT_TargetofFocusName, CT_TargetofFocusPortrait,
		CT_TargetofFocusHealthBar, CT_TargetofFocusHealthBarText,
		CT_TargetofFocusManaBar, CT_TargetofFocusFrameManaBarText,
		nil, nil, nil);
	SetTextStatusBarTextZeroText(CT_TargetofFocusHealthBar, DEAD);
	self:RegisterEvent("UNIT_AURA");

	SecureUnitButton_OnLoad(self, "focustarget");

	self:SetAttribute("type", "target");
	self:SetAttribute("unit", "focustarget");
	RegisterUnitWatch(CT_TargetofFocusFrame);

	ClickCastFrames = ClickCastFrames or { };
	ClickCastFrames[self] = true;
end

function CT_TargetofFocus_OnShow (self)
	local show = CT_TargetofFocus_WantToShow();
	if ( show ) then
--		if ( not CT_TargetofFocusFrame:IsShown() ) then
--			CT_TargetofFocusFrame:Show();
			CT_Focus_Spellbar_AdjustPosition();
--		end
		CT_TargetofFocus_Update (self, 0);
	end
end

function CT_TargetofFocus_OnHide (self)
--		if ( CT_TargetofFocusFrame:IsShown() ) then
--			CT_TargetofFocusFrame:Hide();
			CT_Focus_Spellbar_AdjustPosition();
--		end
	CT_FocusFrame_UpdateAuras(self);
end

function CT_TargetofFocus_Update (self, elapsed)
	if ( not self ) then
		self = CT_TargetofFocusFrame;
	end
	if (not CT_UnitFramesOptions.shallDisplayTargetofFocus) then
		if ( CT_TargetofFocusFrame:IsShown() ) then
			if (not InCombatLockdown()) then
				UnregisterUnitWatch(CT_TargetofFocusFrame);
				return;
			end
		end
	end
	local show = false;
--	if ( SHOW_TARGET_OF_TARGET == "1" and UnitExists("target") and UnitExists("focus") and UnitExists("focustarget")  and ( not UnitIsUnit(PlayerFrame.unit, "focustarget") ) and ( UnitHealth("focus") > 0 ) ) then
--		if ( ( SHOW_TARGET_OF_TARGET_STATE == "5" ) or
--		     ( SHOW_TARGET_OF_TARGET_STATE == "4" and ( (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0) ) ) or
--		     ( SHOW_TARGET_OF_TARGET_STATE == "3" and ( (GetNumRaidMembers() == 0) and (GetNumPartyMembers() == 0) ) ) or
--		     ( SHOW_TARGET_OF_TARGET_STATE == "2" and ( (GetNumPartyMembers() > 0) and (GetNumRaidMembers() == 0) ) ) or
--		     ( SHOW_TARGET_OF_TARGET_STATE == "1" and ( GetNumRaidMembers() > 0 ) ) ) then
--			show = true;
--		end
--	end
--	if ( show ) then
--		if ( not CT_TargetofFocusFrame:IsShown() ) then
--			CT_TargetofFocusFrame:Show();
			CT_Focus_Spellbar_AdjustPosition();
--		end
		UnitFrame_Update(self);
		CT_TargetofFocus_CheckDead();
		CT_TargetofFocusHealthCheck();
		RefreshDebuffs(CT_TargetofFocusFrame, "focustarget");
--	else
--		if ( CT_TargetofFocusFrame:IsShown() ) then
--			CT_TargetofFocusFrame:Hide();
--			CT_Focus_Spellbar_AdjustPosition();
--		end
--	end
end

function CT_TargetofFocus_CheckDead ()
	if ( (UnitHealth("focustarget") <= 0) and UnitIsConnected("focustarget") ) then
		CT_TargetofFocusBackground:SetAlpha(0.9);
		CT_TargetofFocusDeadText:Show();
	else
		CT_TargetofFocusBackground:SetAlpha(1);
		CT_TargetofFocusDeadText:Hide();
	end
end

function CT_TargetofFocusHealthCheck ()
	if ( UnitIsPlayer("focustarget") ) then
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = CT_TargetofFocusHealthBar:GetMinMaxValues();
		unitCurrHP = CT_TargetofFocusHealthBar:GetValue();
		CT_TargetofFocusFrame.unitHPPercent = unitCurrHP / unitHPMax;
		if ( UnitIsDead("focustarget") ) then
			CT_TargetofFocusPortrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
		elseif ( UnitIsGhost("focustarget") ) then
			CT_TargetofFocusPortrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
		elseif ( (CT_TargetofFocusFrame.unitHPPercent > 0) and (CT_TargetofFocusFrame.unitHPPercent <= 0.2) ) then
			CT_TargetofFocusPortrait:SetVertexColor(1.0, 0.0, 0.0);
		else
			CT_TargetofFocusPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		end
	else
		CT_TargetofFocusPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
end

-- -----------------------------------------------------------------------------------

function CT_SetFocusSpellbarAspect()
	local focusFrameSpellBarName = CT_FocusFrameSpellBar:GetName();

	local frameText = _G[focusFrameSpellBarName.."Text"];
	if ( frameText ) then
		frameText:SetFontObject(SystemFont_Shadow_Small);
		frameText:ClearAllPoints();
		frameText:SetPoint("TOP", CT_FocusFrameSpellBar, "TOP", 0, 4);
	end

	local frameBorder = _G[focusFrameSpellBarName.."Border"];
	if ( frameBorder ) then
		frameBorder:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border-Small");
		frameBorder:SetWidth(197);
		frameBorder:SetHeight(49);
		frameBorder:ClearAllPoints();
		frameBorder:SetPoint("TOP", CT_FocusFrameSpellBar, "TOP", 0, 20);
	end

	local frameBorderShield = _G[focusFrameSpellBarName.."BorderShield"];
	if ( frameBorderShield ) then
		frameBorderShield:SetWidth(197);
		frameBorderShield:SetHeight(49);
		frameBorderShield:ClearAllPoints();
		frameBorderShield:SetPoint("TOP", CT_FocusFrameSpellBar, "TOP", -5, 20);
	end

	local frameFlash = _G[focusFrameSpellBarName.."Flash"];
	if ( frameFlash ) then
		frameFlash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small");
		frameFlash:SetWidth(197);
		frameFlash:SetHeight(49);
		frameFlash:ClearAllPoints();
		frameFlash:SetPoint("TOP", CT_FocusFrameSpellBar, "TOP", 0, 20);
	end
end

function CT_Focus_Spellbar_OnLoad (self)
	self:RegisterEvent("PLAYER_FOCUS_CHANGED");
	self:RegisterEvent("CVAR_UPDATE");
	self:RegisterEvent("VARIABLES_LOADED");
	
	CastingBarFrame_OnLoad(self, "focus", false, true);

	local name = self:GetName();

	local barIcon =_G[name.."Icon"];
	barIcon:Show();

	CT_SetFocusSpellbarAspect();
	
	--The focus casting bar has less room for text than most, so shorten it
	_G[name.."Text"]:SetWidth(150)

	-- check to see if the castbar should be shown
--	if ( GetCVar("showTargetCastbar") == "0") then
--		self.showCastbar = false;	
--	end
	CT_Focus_ToggleSpellbar(self);
end

function CT_Focus_ToggleSpellbar(frame)
	if (not frame) then
		frame = CT_FocusFrameSpellBar;
	end
	if ( CT_UnitFramesOptions and not CT_UnitFramesOptions.showFocusCastbar ) then
		frame.showCastbar = false;
	else
		frame.showCastbar = true;
	end
	if ( not frame.showCastbar ) then
		frame:Hide();
	elseif ( frame.casting or frame.channeling ) then
		frame:Show();
	end
end

function CT_Focus_Spellbar_OnEvent (self, event, ...)
	local arg1 = ...

	--	Check for focus specific events
	if ( (event == "VARIABLES_LOADED") or ((event == "CVAR_UPDATE") and (arg1 == "SHOW_FOCUS_CASTBAR")) ) then
--		if ( GetCVar("showTargetCastbar") == "0") then
--			self.showCastbar = false;
--		else
--			self.showCastbar = true;
--		end
--		if ( not self.showCastbar ) then
--			self:Hide();
--		elseif ( self.casting or self.channeling ) then
--			self:Show();
--		end
		CT_Focus_ToggleSpellbar(self);
		return;
	elseif ( event == "PLAYER_FOCUS_CHANGED" ) then
		-- check if the new focus is casting a spell
		local nameChannel  = UnitChannelInfo(self.unit);
		local nameSpell  = UnitCastingInfo(self.unit);
		if ( nameChannel ) then
			event = "UNIT_SPELLCAST_CHANNEL_START";
			arg1 = "focus";
		elseif ( nameSpell ) then
			event = "UNIT_SPELLCAST_START";
			arg1 = "focus";
		else
			self.casting = nil;
			self.channeling = nil;
			self:SetMinMaxValues(0, 0);
			self:SetValue(0);
			self:Hide();
			return;
		end
		-- The position depends on the classification of the focus
		CT_Focus_Spellbar_AdjustPosition();
	end
	if ( self.unit == "focus" and strsub(event, 1, 15) == "UNIT_SPELLCAST_" and UnitIsUnit(arg1, self.unit) ) then
		-- Switch arg1 with "focus" to fool the CastingBarFrame_OnEvent() function into showing the casting bar for our focus frame.
		CastingBarFrame_OnEvent(self, event, "focus", select(2, ...));
	else
		CastingBarFrame_OnEvent(self, event, arg1, select(2, ...));
	end
end

function CT_Focus_Spellbar_AdjustPosition ()
	local yPos = 5;
	if ( CT_FocusFrame.auraRows ) then
		if ( CT_FocusFrame.auraRows <= NUM_TOT_AURA_ROWS ) then
			yPos = 38;
		else
			yPos = 19 * CT_FocusFrame.auraRows;
		end
	end
	if ( CT_TargetofFocusFrame:IsShown() ) then
		if ( yPos <= 25 ) then
			yPos = yPos + 25;
		end
	else
		yPos = yPos - 5;
		local classification = UnitClassification("focus");
		if ( (yPos < 17) and ((classification == "worldboss") or (classification == "rareelite") or (classification == "elite") or (classification == "rare")) ) then
			yPos = 17;
		end
	end
	CT_FocusFrameSpellBar:SetPoint("BOTTOM", "CT_FocusFrame", "BOTTOM", -15, -yPos);
end

-- ------------------------------------------------------------------

function CT_FocusFrame_ShowBarText()
	UnitFrameHealthBar_Update(CT_FocusFrameHealthBar, "focus");
	UnitFrameManaBar_Update(CT_FocusFrameManaBar, "focus");
end

function CT_FocusFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == CT_FocusFrameHealthBar) then
		if (CT_UnitFramesOptions) then
			local style;
			if (UnitIsFriend("focus", "player")) then
				style = CT_UnitFramesOptions.styles[5][1];
			else
				style = CT_UnitFramesOptions.styles[5][5];
			end
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, style, 0)
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[5][2], CT_FocusHealthLeft)
		end

	elseif (bar == CT_FocusFrameManaBar) then
		if (CT_UnitFramesOptions) then
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[5][3], 0)
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[5][4], CT_FocusManaLeft)
		end
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_FocusFrame_TextStatusBar_UpdateTextString);

function CT_FocusFrame_ShowTextStatusBarText(bar)
	if (bar == CT_FocusFrameHealthBar or bar == CT_FocusFrameManaBar) then
		CT_FocusFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("ShowTextStatusBarText", CT_FocusFrame_ShowTextStatusBarText);

function CT_FocusFrame_HideTextStatusBarText(bar)
	if (bar == CT_FocusFrameHealthBar or bar == CT_FocusFrameManaBar) then
		CT_FocusFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("HideTextStatusBarText", CT_FocusFrame_HideTextStatusBarText);

function CT_FocusFrame_ToggleStandardFocus()
	if (InCombatLockdown()) then
		return;
	end
	local frame = FocusFrame;
	if (CT_UnitFramesOptions.hideStdFocus) then
		frame:UnregisterAllEvents();
		frame:Hide();
	else
		frame:RegisterEvent("PLAYER_ENTERING_WORLD");
		frame:RegisterEvent("PLAYER_FOCUS_CHANGED");
		frame:RegisterEvent("UNIT_HEALTH");
		frame:RegisterEvent("UNIT_LEVEL");
		frame:RegisterEvent("UNIT_FACTION");
		frame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED");
		frame:RegisterEvent("UNIT_AURA");
		frame:RegisterEvent("PLAYER_FLAGS_CHANGED");
		frame:RegisterEvent("PARTY_MEMBERS_CHANGED");
		frame:RegisterEvent("RAID_TARGET_UPDATE");
		if (UnitExists("focus")) then
			frame:Show();
		end
	end
end
