-- This is a modified version of Blizzard's TargetFrame (based on the 3.2 source)
-- plus some additional functions.
-- This addon displays targettarget, and targettargettarget frames.

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

function CT_AssistFrame_OnLoad (self)
	self.statusCounter = 0;
	self.statusSign = -1;
	self.unitHPPercent = 1;

	self.ctUpdate = 0;

	CT_AssistFrame_Update(self);
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
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

	local frameLevel = CT_AssistFrameTextureFrame:GetFrameLevel();
	CT_AssistFrameHealthBar:SetFrameLevel(frameLevel-1);
	CT_AssistFrameManaBar:SetFrameLevel(frameLevel-1);
	CT_AssistFrameSpellBar:SetFrameLevel(frameLevel-1);

--	local showmenu = function()
--		ToggleDropDownMenu(1, nil, CT_AssistFrameDropDown, "CT_AssistFrame", 120, 10);
--	end
--	SecureUnitButton_OnLoad(self, "targettarget", showmenu);
	SecureUnitButton_OnLoad(self, "targettarget");

	self:SetAttribute("type", "target");
	self:SetAttribute("unit", "targettarget");
--	RegisterUnitWatch(CT_AssistFrame);

	CT_AssistFrameHealthBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);
	CT_AssistFrameManaBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);

	ClickCastFrames = ClickCastFrames or { };
	ClickCastFrames[self] = true;
end

function CT_AssistFrame_Update (self)
	-- This check is here so the frame will hide when the target goes away
	-- even if some of the functions below are hooked by addons.
	if (not self) then
		self = CT_AssistFrame;
	end
	if ( not UnitExists("targettarget") ) then
--		self:Hide();
	else
--		self:Show();

		-- Moved here to avoid taint from functions below
		CT_TargetofAssist_Update();

		UnitFrame_Update(self);
		CT_AssistFrame_CheckLevel(self);
		CT_AssistFrame_CheckFaction(self);
		CT_AssistFrame_CheckClassification(self);
		CT_AssistFrame_CheckDead(self);
--		if ( UnitIsPartyLeader("targettarget") ) then
--			CT_AssistLeaderIcon:Show();
--		else
			CT_AssistLeaderIcon:Hide();
--		end
		CT_AssistFrame_UpdateAuras(self);
		CT_AssistPortrait:SetAlpha(1.0);
		CT_AssistHealthCheck();
	end
end

function CT_AssistFrame_OnEvent (self, event, ...)
	UnitFrame_OnEvent(self, event, ...);

	local arg1 = ...;
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if (CT_UnitFramesOptions.shallDisplayAssist) then
			RegisterUnitWatch(CT_AssistFrame);
		else
			UnregisterUnitWatch(CT_AssistFrame);
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofAssist) then
			RegisterUnitWatch(CT_TargetofAssistFrame);
		else
			UnregisterUnitWatch(CT_TargetofAssistFrame);
		end
		if (not InCombatLockdown()) then
			CT_UnitFrames_ResetDragLink("CT_AssistFrame_Drag");
		end
		CT_AssistFrame_Update(self);

	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		-- Moved here to avoid taint from functions below
		CT_AssistFrame_Update(self);
		CT_AssistFrame_UpdateRaidTargetIcon(self);
--		CloseDropDownMenus();

--		if ( UnitExists("targettarget") ) then
--			if ( UnitIsEnemy("targettarget", "player") ) then
--				PlaySound("igCreatureAggroSelect");
--			elseif ( UnitIsFriend("player", "targettarget") ) then
--				PlaySound("igCharacterNPCSelect");
--			else
--				PlaySound("igCreatureNeutralSelect");
--			end
--		end
--	elseif ( event == "UNIT_HEALTH" ) then
--		if ( arg1 == "targettarget" ) then
--			CT_AssistFrame_CheckDead(self);
--		end
--	elseif ( event == "UNIT_LEVEL" ) then
--		if ( arg1 == "targettarget" ) then
--			CT_AssistFrame_CheckLevel(self);
--		end
	elseif ( event == "UNIT_FACTION" ) then
		if ( arg1 == "player" ) then
			CT_AssistFrame_CheckFaction(self);
			CT_AssistFrame_CheckLevel(self);
		end
--	elseif ( event == "UNIT_CLASSIFICATION_CHANGED" ) then
--		if ( arg1 == "targettarget" ) then
--			CT_AssistFrame_CheckClassification(self);
--		end
--	elseif ( event == "UNIT_AURA" ) then
--		if ( arg1 == "targettarget" ) then
--			CT_AssistFrame_UpdateAuras(self);
--		end
--	elseif ( event == "PLAYER_FLAGS_CHANGED" ) then
--		if ( arg1 == "targettarget" ) then
--			if ( UnitIsPartyLeader("targettarget") ) then
--				CT_AssistLeaderIcon:Show();
--			else
--				CT_AssistLeaderIcon:Hide();
--			end
--		end
	elseif ( event == "PARTY_MEMBERS_CHANGED" ) then
--		CT_TargetofAssist_Update();
--		CT_AssistFrame_CheckFaction(self);
		CT_AssistFrame_Update();
	elseif ( event == "RAID_TARGET_UPDATE" ) then
		CT_AssistFrame_UpdateRaidTargetIcon(self);
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		if (CT_UnitFramesOptions.shallDisplayAssist) then
			RegisterUnitWatch(CT_AssistFrame);
		else
			UnregisterUnitWatch(CT_AssistFrame);
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofAssist) then
			RegisterUnitWatch(CT_TargetofAssistFrame);
		else
			UnregisterUnitWatch(CT_TargetofAssistFrame);
		end
		CT_UnitFrames_ResetDragLink("CT_AssistFrame_Drag");
	elseif ( event == "PLAYER_REGEN_DISABLED" ) then
		if (CT_UnitFramesOptions.shallDisplayAssist) then
			RegisterUnitWatch(CT_AssistFrame);
		else
			UnregisterUnitWatch(CT_AssistFrame);
		end
		if (CT_UnitFramesOptions.shallDisplayTargetofAssist) then
			RegisterUnitWatch(CT_TargetofAssistFrame);
		else
			UnregisterUnitWatch(CT_TargetofAssistFrame);
		end
		CT_UnitFrames_ResetDragLink("CT_AssistFrame_Drag");
	end
end

function CT_AssistFrame_OnShow(self)
	CT_AssistFrame_Update(self);
end

function CT_AssistFrame_OnHide (self)
--	PlaySound("INTERFACESOUND_LOSTTARGETUNIT");
--	CloseDropDownMenus();
end

function CT_AssistFrame_CheckLevel (self)
	local assistLevel = UnitLevel("targettarget");
	
	if ( UnitIsCorpse("targettarget") ) then
		CT_AssistLevelText:Hide();
		CT_AssistHighLevelTexture:Show();
	elseif ( assistLevel > 0 ) then
		-- Normal level target
		CT_AssistLevelText:SetText(assistLevel);
		-- Color level number
		if ( UnitCanAttack("player", "targettarget") ) then
			local color = GetQuestDifficultyColor(assistLevel);
			CT_AssistLevelText:SetVertexColor(color.r, color.g, color.b);
		else
			CT_AssistLevelText:SetVertexColor(1.0, 0.82, 0.0);
		end
		CT_AssistLevelText:Show();
		CT_AssistHighLevelTexture:Hide();
	else
		-- Target is too high level to tell
		CT_AssistLevelText:Hide();
		CT_AssistHighLevelTexture:Show();
	end
end

function CT_AssistFrame_CheckFaction (self)
	if ( not UnitPlayerControlled("targettarget") and UnitIsTapped("targettarget") and not UnitIsTappedByPlayer("targettarget") ) then
		CT_AssistFrameNameBackground:SetVertexColor(0.5, 0.5, 0.5);
		CT_AssistPortrait:SetVertexColor(0.5, 0.5, 0.5);
	else
		CT_AssistFrameNameBackground:SetVertexColor(UnitSelectionColor("targettarget"));
		CT_AssistPortrait:SetVertexColor(1.0, 1.0, 1.0);
	end

	local factionGroup = UnitFactionGroup("targettarget");
	if ( UnitIsPVPFreeForAll("targettarget") ) then
		CT_AssistPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		CT_AssistPVPIcon:Show();
	elseif ( factionGroup and UnitIsPVP("targettarget") ) then
		CT_AssistPVPIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
		CT_AssistPVPIcon:Show();
	else
		CT_AssistPVPIcon:Hide();
	end
end

function CT_AssistFrame_CheckClassification (self)
	local classification = UnitClassification("targettarget");
	if ( classification == "worldboss" ) then
		CT_AssistFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite");
		CT_AssistFrameFlash:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
		CT_AssistFrameFlash:SetWidth(242);
		CT_AssistFrameFlash:SetHeight(112);
		CT_AssistFrameFlash:SetPoint("TOPLEFT", CT_AssistFrame, "TOPLEFT", -22, 9);
	elseif ( classification == "rareelite"  ) then
		CT_AssistFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite");
		CT_AssistFrameFlash:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
		CT_AssistFrameFlash:SetWidth(242);
		CT_AssistFrameFlash:SetHeight(112);
		CT_AssistFrameFlash:SetPoint("TOPLEFT", CT_AssistFrame, "TOPLEFT", -22, 9);
	elseif ( classification == "elite"  ) then
		CT_AssistFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite");
		CT_AssistFrameFlash:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
		CT_AssistFrameFlash:SetWidth(242);
		CT_AssistFrameFlash:SetHeight(112);
		CT_AssistFrameFlash:SetPoint("TOPLEFT", CT_AssistFrame, "TOPLEFT", -22, 9);
	elseif ( classification == "rare"  ) then
		CT_AssistFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare");
		CT_AssistFrameFlash:SetTexCoord(0, 0.9453125, 0.181640625, 0.400390625);
		CT_AssistFrameFlash:SetWidth(242);
		CT_AssistFrameFlash:SetHeight(112);
		CT_AssistFrameFlash:SetPoint("TOPLEFT", CT_AssistFrame, "TOPLEFT", -22, 9);
	else
		CT_AssistFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame");
		CT_AssistFrameFlash:SetTexCoord(0, 0.9453125, 0, 0.181640625);
		CT_AssistFrameFlash:SetWidth(242);
		CT_AssistFrameFlash:SetHeight(93);
		CT_AssistFrameFlash:SetPoint("TOPLEFT", CT_AssistFrame, "TOPLEFT", -24, 0);
	end
end

function CT_AssistFrame_CheckDead (self)
	if ( (UnitHealth("targettarget") <= 0) and UnitIsConnected("targettarget") ) then
		CT_AssistDeadText:Show();
		return true;
	else
		CT_AssistDeadText:Hide();
		return false;
	end
end

function CT_AssistFrame_OnUpdate (self, elapsed)
--	if ( CT_TargetofAssistFrame:IsShown() ~= UnitExists("targettargettarget") ) then
--		CT_TargetofAssist_Update();
--	end
	
	self.ctUpdate = self.ctUpdate + elapsed;
	if ( self.ctUpdate > 0.1 ) then
		self.ctUpdate = 0;
		CT_AssistFrame_Update(self);
	end

	self.elapsed = (self.elapsed or 0) + elapsed;
	if ( self.elapsed > 0.5 ) then
		self.elapsed = 0;
--		UnitFrame_UpdateThreatIndicator(self.threatIndicator, self.threatNumericIndicator, self.feedbackUnit);
	end
end

local largeBuffList = {};
local largeDebuffList = {};

function CT_AssistFrame_UpdateAuras (self)
	local frame, frameName;
	local frameIcon, frameCount, frameCooldown;

	local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable;
	local playerIsAssist = UnitIsUnit(PlayerFrame.unit, "targettarget");

	local frameStealable;
	local numBuffs = 0;
	for i=1, MAX_TARGET_BUFFS do
		name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable = UnitBuff("targettarget", i);
		frameName = "CT_AssistFrameBuff"..i;
		frame = _G[frameName];
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, CT_AssistFrame, "CT_AssistBuffFrameTemplate");
				frame.unit = "targettarget";
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

			-- Show stealable frame if the target is not a player and the buff is stealable.
			frameStealable = _G[frameName.."Stealable"];
			if ( not playerIsAssist and isStealable ) then
				frameStealable:Show();
			else
				frameStealable:Hide();
			end

			-- set the buff to be big if the target is not the player and the buff is cast by the player or his pet
			largeBuffList[i] = (not playerIsAssist and PLAYER_UNITS[caster]);

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
		name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitDebuff("targettarget", i);
		frameName = "CT_AssistFrameDebuff"..i;
		frame = _G[frameName];
		if ( not frame ) then
			if ( not icon ) then
				break;
			else
				frame = CreateFrame("Button", frameName, CT_AssistFrame, "CT_AssistDebuffFrameTemplate");
				frame.unit = "targettarget";
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

	CT_AssistFrame.auraRows = 0;
	local haveTargetofAssist = CT_TargetofAssistFrame:IsShown();
	local maxRowWidth;
	-- update buff positions
	maxRowWidth = ( haveTargetofAssist and TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	CT_AssistFrame_UpdateAuraPositions("CT_AssistFrameBuff", numBuffs, numDebuffs, largeBuffList, CT_AssistFrame_UpdateBuffAnchor, maxRowWidth, 3);
	-- update debuff positions
	maxRowWidth = ( haveTargetofAssist and CT_AssistFrame.auraRows < NUM_TOT_AURA_ROWS and TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
	CT_AssistFrame_UpdateAuraPositions("CT_AssistFrameDebuff", numDebuffs, numBuffs, largeDebuffList, CT_AssistFrame_UpdateDebuffAnchor, maxRowWidth, 4);
	-- update the spell bar position
	CT_Assist_Spellbar_AdjustPosition();
end

function CT_AssistFrame_UpdateAuraPositions(auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX)
	-- a lot of this complexity is in place to allow the auras to wrap around the target of target frame if it's shown

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
			CT_AssistFrame.auraRows = CT_AssistFrame.auraRows + 1;
		else
			rowWidth = rowWidth + size + offsetX;
		end
		if ( rowWidth > maxRowWidth ) then
			-- this aura would cause the current row to exceed the max row width, so make this aura
			-- the start of a new row instead
			updateFunc(auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX, offsetY);

			rowWidth = size;
			CT_AssistFrame.auraRows = CT_AssistFrame.auraRows + 1;
			firstBuffOnRow = i;
			offsetY = AURA_OFFSET_Y;

			if ( CT_AssistFrame.auraRows > NUM_TOT_AURA_ROWS ) then
				-- if we exceed the number of tot rows, then reset the max row width
				-- note: don't have to check if we have tot because AURA_ROW_WIDTH is the default anyway
				maxRowWidth = AURA_ROW_WIDTH;
			end
		else
			updateFunc(auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY);
		end
	end
end

function CT_AssistFrame_UpdateBuffAnchor(buffName, index, numDebuffs, anchorIndex, size, offsetX, offsetY)
	local buff = _G[buffName..index];

	if ( index == 1 ) then
		if ( UnitIsFriend("player", "targettarget") or numDebuffs == 0 ) then
			-- unit is friendly or there are no debuffs...buffs start on top
			buff:SetPoint("TOPLEFT", CT_AssistFrame, "BOTTOMLEFT", AURA_START_X, AURA_START_Y);
		else
			-- unit is not friendly and we have debuffs...buffs start on bottom
			buff:SetPoint("TOPLEFT", CT_AssistFrameDebuffs, "BOTTOMLEFT", 0, -offsetY);
		end
		CT_AssistFrameBuffs:SetPoint("TOPLEFT", buff, "TOPLEFT", 0, 0);
		CT_AssistFrameBuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -AURA_OFFSET_Y);
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint("TOPLEFT", _G[buffName..anchorIndex], "BOTTOMLEFT", 0, -offsetY);
		CT_AssistFrameBuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -AURA_OFFSET_Y);
	else
		-- anchor index is the previous index
		buff:SetPoint("TOPLEFT", _G[buffName..anchorIndex], "TOPRIGHT", offsetX, 0);
	end

	-- Resize
	buff:SetWidth(size);
	buff:SetHeight(size);
end

function CT_AssistFrame_UpdateDebuffAnchor(debuffName, index, numBuffs, anchorIndex, size, offsetX, offsetY)
	local buff = _G[debuffName..index];

	if ( index == 1 ) then
		if ( UnitIsFriend("player", "targettarget") and numBuffs > 0 ) then
			-- unit is friendly and there are buffs...debuffs start on bottom
			buff:SetPoint("TOPLEFT", CT_AssistFrameBuffs, "BOTTOMLEFT", 0, -offsetY);
		else
			-- unit is not friendly or there are no buffs...debuffs start on top
			buff:SetPoint("TOPLEFT", CT_AssistFrame, "BOTTOMLEFT", AURA_START_X, AURA_START_Y);
		end
		CT_AssistFrameDebuffs:SetPoint("TOPLEFT", buff, "TOPLEFT", 0, 0);
		CT_AssistFrameDebuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -AURA_OFFSET_Y);
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint("TOPLEFT", _G[debuffName..anchorIndex], "BOTTOMLEFT", 0, -offsetY);
		CT_AssistFrameDebuffs:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -AURA_OFFSET_Y);
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

function CT_AssistFrame_HealthUpdate (self, elapsed, unit)
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
			CT_AssistPortrait:SetAlpha(alpha);
		end
	end
end

function CT_AssistHealthCheck (self)
	if ( UnitIsPlayer("targettarget") ) then
		if (not self) then
			self = CT_AssistFrameHealthBar;
		end
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = self:GetMinMaxValues();
		unitCurrHP = self:GetValue();
		self:GetParent().unitHPPercent = unitCurrHP / unitHPMax;
		if ( UnitIsDead("targettarget") ) then
			CT_AssistPortrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
		elseif ( UnitIsGhost("targettarget") ) then
			CT_AssistPortrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
		elseif ( (self:GetParent().unitHPPercent > 0) and (self:GetParent().unitHPPercent <= 0.2) ) then
			CT_AssistPortrait:SetVertexColor(1.0, 0.0, 0.0);
		else
			CT_AssistPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		end
	else
		CT_AssistPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
	if ( not UnitIsPlayer("targettarget") ) then
		CT_AssistFrame_CheckFaction();
	end
end

--[[
function CT_AssistFrameDropDown_OnLoad (self)
	UIDropDownMenu_Initialize(self, CT_AssistFrameDropDown_Initialize, "MENU");
end
]]

--[[
function CT_AssistFrameDropDown_Initialize (self)
	local menu;
	local name;
	local id = nil;
	if ( UnitIsUnit("targettarget", "player") ) then
		menu = "SELF";
	elseif ( UnitIsUnit("targettarget", "vehicle") ) then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		menu = "VEHICLE";
	elseif ( UnitIsUnit("targettarget", "pet") ) then
		menu = "PET";
	elseif ( UnitIsPlayer("targettarget") ) then
		id = UnitInRaid("targettarget");
		if ( id ) then
			menu = "RAID_PLAYER";
			name = GetRaidRosterInfo(id +1);
		elseif ( UnitInParty("targettarget") ) then
			menu = "PARTY";
		else
			menu = "PLAYER";
		end
	else
		menu = "TARGET";
		name = RAID_TARGET_ICON;
	end
	if ( menu ) then
		UnitPopup_ShowMenu(self, menu, "targettarget", name, id);
	end
end
]]


-- -- Raid target icon function
-- RAID_TARGET_ICON_DIMENSION = 64;
-- RAID_TARGET_TEXTURE_DIMENSION = 256;
-- RAID_TARGET_TEXTURE_COLUMNS = 4;
-- RAID_TARGET_TEXTURE_ROWS = 4;
function CT_AssistFrame_UpdateRaidTargetIcon (self)
	local index = GetRaidTargetIndex("targettarget");
	if ( index ) then
		SetRaidTargetIconTexture(CT_AssistRaidTargetIcon, index);
		CT_AssistRaidTargetIcon:Show();
	else
		CT_AssistRaidTargetIcon:Hide();
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

function CT_TargetofAssist_OnLoad (self)
	UnitFrame_Initialize(self, "targettargettarget", CT_TargetofAssistName, CT_TargetofAssistPortrait,
		CT_TargetofAssistHealthBar, CT_TargetofAssistHealthBarText,
		CT_TargetofAssistManaBar, CT_TargetofAssistFrameManaBarText,
		nil, nil, nil);
	SetTextStatusBarTextZeroText(CT_TargetofAssistHealthBar, DEAD);
	self:RegisterEvent("UNIT_AURA");

	SecureUnitButton_OnLoad(self, "targettargettarget");

	self:SetAttribute("type", "target");
	self:SetAttribute("unit", "targettargettarget");
--	RegisterUnitWatch(CT_TargetofAssistFrame);

	ClickCastFrames = ClickCastFrames or { };
	ClickCastFrames[self] = true;
end

function CT_TargetofAssist_OnShow (self)
	local show = CT_TargetofAssist_WantToShow();
	if ( show ) then
--		if ( not CT_TargetofAssistFrame:IsShown() ) then
--			CT_TargetofAssistFrame:Show();
			CT_Assist_Spellbar_AdjustPosition();
--		end
		CT_TargetofAssist_Update (self, 0);
	end
end

function CT_TargetofAssist_OnHide (self)
--		if ( CT_TargetofAssistFrame:IsShown() ) then
--			CT_TargetofAssistFrame:Hide();
			CT_Assist_Spellbar_AdjustPosition();
--		end
	CT_AssistFrame_UpdateAuras(self);
end

function CT_TargetofAssist_Update (self, elapsed)
	if ( not self ) then
		self = CT_TargetofAssistFrame;
	end
	if (not CT_UnitFramesOptions.shallDisplayTargetofAssist) then
		if ( CT_TargetofAssistFrame:IsShown() ) then
			if (not InCombatLockdown()) then
				UnregisterUnitWatch(CT_TargetofAssistFrame);
				return;
			end
		end
	end
	local show = false;
--	if ( SHOW_TARGET_OF_TARGET == "1" and UnitExists("target") and UnitExists("targettarget") and UnitExists("targettargettarget")  and ( not UnitIsUnit(PlayerFrame.unit, "targettargettarget") ) and ( UnitHealth("targettarget") > 0 ) ) then
--		if ( ( SHOW_TARGET_OF_TARGET_STATE == "5" ) or
--		     ( SHOW_TARGET_OF_TARGET_STATE == "4" and ( (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0) ) ) or
--		     ( SHOW_TARGET_OF_TARGET_STATE == "3" and ( (GetNumRaidMembers() == 0) and (GetNumPartyMembers() == 0) ) ) or
--		     ( SHOW_TARGET_OF_TARGET_STATE == "2" and ( (GetNumPartyMembers() > 0) and (GetNumRaidMembers() == 0) ) ) or
--		     ( SHOW_TARGET_OF_TARGET_STATE == "1" and ( GetNumRaidMembers() > 0 ) ) ) then
--			show = true;
--		end
--	end
--	if ( show ) then
--		if ( not CT_TargetofAssistFrame:IsShown() ) then
--			CT_TargetofAssistFrame:Show();
			CT_Assist_Spellbar_AdjustPosition();
--		end
		UnitFrame_Update(self);
		CT_TargetofAssist_CheckDead();
		CT_TargetofAssistHealthCheck();
		RefreshDebuffs(CT_TargetofAssistFrame, "targettargettarget");
--	else
--		if ( CT_TargetofAssistFrame:IsShown() ) then
--			CT_TargetofAssistFrame:Hide();
--			CT_Assist_Spellbar_AdjustPosition();
--		end
--	end
end

function CT_TargetofAssist_CheckDead ()
	if ( (UnitHealth("targettargettarget") <= 0) and UnitIsConnected("targettargettarget") ) then
		CT_TargetofAssistBackground:SetAlpha(0.9);
		CT_TargetofAssistDeadText:Show();
	else
		CT_TargetofAssistBackground:SetAlpha(1);
		CT_TargetofAssistDeadText:Hide();
	end
end

function CT_TargetofAssistHealthCheck ()
	if ( UnitIsPlayer("targettargettarget") ) then
		local unitHPMin, unitHPMax, unitCurrHP;
		unitHPMin, unitHPMax = CT_TargetofAssistHealthBar:GetMinMaxValues();
		unitCurrHP = CT_TargetofAssistHealthBar:GetValue();
		CT_TargetofAssistFrame.unitHPPercent = unitCurrHP / unitHPMax;
		if ( UnitIsDead("targettargettarget") ) then
			CT_TargetofAssistPortrait:SetVertexColor(0.35, 0.35, 0.35, 1.0);
		elseif ( UnitIsGhost("targettargettarget") ) then
			CT_TargetofAssistPortrait:SetVertexColor(0.2, 0.2, 0.75, 1.0);
		elseif ( (CT_TargetofAssistFrame.unitHPPercent > 0) and (CT_TargetofAssistFrame.unitHPPercent <= 0.2) ) then
			CT_TargetofAssistPortrait:SetVertexColor(1.0, 0.0, 0.0);
		else
			CT_TargetofAssistPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
		end
	else
		CT_TargetofAssistPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
end

-- -----------------------------------------------------------------------------------

function CT_SetAssistSpellbarAspect()
	local assistFrameSpellBarName = CT_AssistFrameSpellBar:GetName();

	local frameText = _G[assistFrameSpellBarName.."Text"];
	if ( frameText ) then
		frameText:SetFontObject(SystemFont_Shadow_Small);
		frameText:ClearAllPoints();
		frameText:SetPoint("TOP", CT_AssistFrameSpellBar, "TOP", 0, 4);
	end

	local frameBorder = _G[assistFrameSpellBarName.."Border"];
	if ( frameBorder ) then
		frameBorder:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border-Small");
		frameBorder:SetWidth(197);
		frameBorder:SetHeight(49);
		frameBorder:ClearAllPoints();
		frameBorder:SetPoint("TOP", CT_AssistFrameSpellBar, "TOP", 0, 20);
	end

	local frameBorderShield = _G[assistFrameSpellBarName.."BorderShield"];
	if ( frameBorderShield ) then
		frameBorderShield:SetWidth(197);
		frameBorderShield:SetHeight(49);
		frameBorderShield:ClearAllPoints();
		frameBorderShield:SetPoint("TOP", CT_AssistFrameSpellBar, "TOP", -5, 20);
	end

	local frameFlash = _G[assistFrameSpellBarName.."Flash"];
	if ( frameFlash ) then
		frameFlash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small");
		frameFlash:SetWidth(197);
		frameFlash:SetHeight(49);
		frameFlash:ClearAllPoints();
		frameFlash:SetPoint("TOP", CT_AssistFrameSpellBar, "TOP", 0, 20);
	end
end

function CT_Assist_Spellbar_OnLoad (self)
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("CVAR_UPDATE");
	self:RegisterEvent("VARIABLES_LOADED");
	
	CastingBarFrame_OnLoad(self, "targettarget", false, true);

	local name = self:GetName();

	local barIcon =_G[name.."Icon"];
	barIcon:Show();

	CT_SetAssistSpellbarAspect();
	
	--The target casting bar has less room for text than most, so shorten it
	_G[name.."Text"]:SetWidth(150)

	-- check to see if the castbar should be shown
--	if ( GetCVar("showTargetCastbar") == "0") then
--		self.showCastbar = false;	
--	end
	CT_Assist_ToggleSpellbar(self);
end

function CT_Assist_ToggleSpellbar(frame)
	if (not frame) then
		frame = CT_AssistFrameSpellBar;
	end
	if ( CT_UnitFramesOptions and not CT_UnitFramesOptions.showAssistCastbar ) then
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

function CT_Assist_Spellbar_OnEvent (self, event, ...)
	local arg1 = ...

	--	Check for target specific events
	if ( (event == "VARIABLES_LOADED") or ((event == "CVAR_UPDATE") and (arg1 == "SHOW_TARGET_CASTBAR")) ) then
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
		CT_Assist_ToggleSpellbar(self);
		return;
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		-- check if the new target is casting a spell
		local nameChannel  = UnitChannelInfo(self.unit);
		local nameSpell  = UnitCastingInfo(self.unit);
		if ( nameChannel ) then
			event = "UNIT_SPELLCAST_CHANNEL_START";
			arg1 = "targettarget";
		elseif ( nameSpell ) then
			event = "UNIT_SPELLCAST_START";
			arg1 = "targettarget";
		else
			self.casting = nil;
			self.channeling = nil;
			self:SetMinMaxValues(0, 0);
			self:SetValue(0);
			self:Hide();
			return;
		end
		-- The position depends on the classification of the target
		CT_Assist_Spellbar_AdjustPosition();
	end
	if ( self.unit == "targettarget" and strsub(event, 1, 15) == "UNIT_SPELLCAST_" and UnitIsUnit(arg1, self.unit) ) then
		-- Switch arg1 with "targettarget" to fool the CastingBarFrame_OnEvent() function into showing the casting bar for our assist frame.
		CastingBarFrame_OnEvent(self, event, "targettarget", select(2, ...));
	else
		CastingBarFrame_OnEvent(self, event, arg1, select(2, ...));
	end
end

function CT_Assist_Spellbar_AdjustPosition ()
	local yPos = 5;
	if ( CT_AssistFrame.auraRows ) then
		if ( CT_AssistFrame.auraRows <= NUM_TOT_AURA_ROWS ) then
			yPos = 38;
		else
			yPos = 19 * CT_AssistFrame.auraRows;
		end
	end
	if ( CT_TargetofAssistFrame:IsShown() ) then
		if ( yPos <= 25 ) then
			yPos = yPos + 25;
		end
	else
		yPos = yPos - 5;
		local classification = UnitClassification("targettarget");
		if ( (yPos < 17) and ((classification == "worldboss") or (classification == "rareelite") or (classification == "elite") or (classification == "rare")) ) then
			yPos = 17;
		end
	end
	CT_AssistFrameSpellBar:SetPoint("BOTTOM", "CT_AssistFrame", "BOTTOM", -15, -yPos);
end

-- ------------------------------------------------------------------

function CT_AssistFrame_ShowBarText()
	UnitFrameHealthBar_Update(CT_AssistFrameHealthBar, "targettarget");
	UnitFrameManaBar_Update(CT_AssistFrameManaBar, "targettarget");
end

function CT_AssistFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == CT_AssistFrameHealthBar) then
		if (CT_UnitFramesOptions) then
			local style;
			if (UnitIsFriend("targettarget", "player")) then
				style = CT_UnitFramesOptions.styles[4][1];
			else
				style = CT_UnitFramesOptions.styles[4][5];
			end
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, style, 0)
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[4][2], CT_AssistHealthLeft)
		end

	elseif (bar == CT_AssistFrameManaBar) then
		if (CT_UnitFramesOptions) then
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[4][3], 0)
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[4][4], CT_AssistManaLeft)
		end
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_AssistFrame_TextStatusBar_UpdateTextString);

function CT_AssistFrame_ShowTextStatusBarText(bar)
	if (bar == CT_AssistFrameHealthBar or bar == CT_AssistFrameManaBar) then
		CT_AssistFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("ShowTextStatusBarText", CT_AssistFrame_ShowTextStatusBarText);

function CT_AssistFrame_HideTextStatusBarText(bar)
	if (bar == CT_AssistFrameHealthBar or bar == CT_AssistFrameManaBar) then
		CT_AssistFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("HideTextStatusBarText", CT_AssistFrame_HideTextStatusBarText);

