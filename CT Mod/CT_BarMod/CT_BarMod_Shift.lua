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

-- This file deals with shifting the party frames
-- and focus frame to the right,
-- as well as shifting up the multicast action
-- (totem) bar, the pet bar, the possess bar,
-- and the shapeshift (class) bar.

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BarMod;


local frameSetPoint;
local frameClearAllPoints;

-------------------------------
-- Shift the party frames

local partyShifted, shiftParty, reshiftParty;

function CT_BarMod_Shift_Party_SetFlag()
	-- Set flag that indicates we need to shift the party frames when possible.
	-- This gets called when the user toggles the shift party option.
	shiftParty = 1;
end

function CT_BarMod_Shift_Party_SetReshiftFlag()
	-- Set flag that indicates we need to reshift the party frames when possible.
	-- This gets called when the user changes the shift party offset option.
	reshiftParty = 1;
end

local function CT_BarMod_Shift_Party_Move2(shift)
	if (InCombatLockdown()) then
		return;
	end
	local point, rel, relpoint, x, y = PartyMemberFrame1:GetPoint(1);
	if ( shift ) then
		if (not partyShifted) then
			local offset = module:getOption("shiftPartyOffset") or 37;
			x = x + offset;
			partyShifted = offset;  -- Remember the offset used.
			PartyMemberFrame1:SetPoint(point, rel, relpoint, x, y);
		end
	else
		if (partyShifted) then
			local offset = partyShifted;  -- Use the remembered offset.
			x = x - offset;
			partyShifted = nil;
			PartyMemberFrame1:SetPoint(point, rel, relpoint, x, y);
		end
	end
	shiftParty = nil;
end

function CT_BarMod_Shift_Party_Move()
	if (InCombatLockdown()) then
		return;
	end
	if (reshiftParty) then
		-- We need to reshift the frames (the offset was changed).
		if (partyShifted) then
			-- Shift the frames back before reshifting with the new offset.
			CT_BarMod_Shift_Party_Move2(false);
		end
		reshiftParty = nil;
	end
	-- Shift (or unshift) the frames using the current values of the options.
	CT_BarMod_Shift_Party_Move2( module:getOption("shiftParty") ~= false );
end

-------------------------------
-- Shift the focus frame

local focusShifted, shiftFocus, reshiftFocus;

function CT_BarMod_Shift_Focus_SetFlag()
	-- Set flag that indicates we need to shift the focus frame when possible.
	-- This gets called when the user toggles the shift focus option.
	shiftFocus = 1;
end

function CT_BarMod_Shift_Focus_SetReshiftFlag()
	-- Set flag that indicates we need to reshift the focus frame when possible.
	-- This gets called when the user toggles the shift focus offset option.
	reshiftFocus = 1;
end

local function CT_BarMod_Shift_Focus_Move2(shift)
	if (InCombatLockdown()) then
		return;
	end
	local point, rel, relpoint, x, y = FocusFrame:GetPoint(1);
	if ( shift ) then
		if (not focusShifted) then
			local offset = module:getOption("shiftFocusOffset") or 37;
			x = x + offset;
			focusShifted = offset;  -- Remember the offset used.
			FocusFrame:SetPoint(point, rel, relpoint, x, y);
		end
	else
		if (focusShifted) then
			local offset = focusShifted;  -- Use the remembered offset.
			x = x - offset;
			focusShifted = nil;
			FocusFrame:SetPoint(point, rel, relpoint, x, y);
		end
	end
	shiftFocus = nil;
end

function CT_BarMod_Shift_Focus_Move()
	if (InCombatLockdown()) then
		return;
	end
	if (reshiftFocus) then
		-- We need to reshift the frames (the offset was changed).
		if (focusShifted) then
			-- Shift the frames back before reshifting with the new offset.
			CT_BarMod_Shift_Focus_Move2(false);
		end
		reshiftFocus = nil;
	end
	-- Shift (or unshift) the frames using the current values of the options.
	CT_BarMod_Shift_Focus_Move2( module:getOption("shiftFocus") ~= false );
end

-------------------------------
-- Shift the MultiCast bar.

local multicastIsShifted;
local multicastNeedToMove;

-- knownMultiCastSummonSpells
-- index: TOTEM_MULTI_CAST_SUMMON_SPELLS 
-- value: spellId if the spell is known, nil otherwise
local knownMultiCastSummonSpells = { };

-- knownMultiCastRecallSpells
-- index: TOTEM_MULTI_CAST_RECALL_SPELLS 
-- value: spellId if the spell is known, nil otherwise
local knownMultiCastRecallSpells = { };

local function CT_BarMod_Shift_MultiCast_GetShiftOption()
	return (module:getOption("shiftMultiCast") ~= false);
end

local function CT_BarMod_Shift_MultiCast_UpdateTextures()
end

local function CT_BarMod_Shift_MultiCast_SummonSpellButton_Update(frame, self)
	-- This is a modified version of MultiCastSummonSpellButton_Update
	-- from MultiCastActionBarFrame.lua.

	-- first update which multi-cast spells we actually know
	for index, spellId in next, TOTEM_MULTI_CAST_SUMMON_SPELLS do
		knownMultiCastSummonSpells[index] = (IsSpellKnown(spellId) and spellId) or nil;
	end

	-- update the spell button
	local spellId = knownMultiCastSummonSpells[self:GetID()];
--	self.spellId = spellId;
	if ( HasMultiCastActionBar() and spellId ) then
		-- reanchor the first slot button take make room for this button
		local width = self:GetWidth();
		local xOffset = width + 8 + 3;
		local page;
		for i = 1, NUM_MULTI_CAST_PAGES do
			page = _G["MultiCastActionPage"..i];
			frameClearAllPoints(page);
			frameSetPoint(page, "BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, 3);
		end
		frameClearAllPoints(MultiCastSlotButton1);
		frameSetPoint(MultiCastSlotButton1, "BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, 3);

		self:Show();
	else
		-- reanchor the first slot button take the place of this button
		local xOffset = 3;
		local page;
		for i = 1, NUM_MULTI_CAST_PAGES do
			page = _G["MultiCastActionPage"..i];
			frameClearAllPoints(page);
			frameSetPoint(page, "BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, 3);
		end
		frameClearAllPoints(MultiCastSlotButton1);
		frameSetPoint(MultiCastSlotButton1, "BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, 3);

		self:Hide();
	end

	frameSetPoint(MultiCastSlotButton1, "CENTER", frame, "CENTER", 0, 0);
	frameSetPoint(MultiCastSlotButton2, "CENTER", frame, "CENTER", 0, 0);
	frameSetPoint(MultiCastSlotButton3, "CENTER", frame, "CENTER", 0, 0);
	frameSetPoint(MultiCastSlotButton4, "CENTER", frame, "CENTER", 0, 0);

	frameClearAllPoints(MultiCastSummonSpellButton);
	frameSetPoint(MultiCastSummonSpellButton, "BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3);
end

local function CT_BarMod_Shift_MultiCast_RecallSpellButton_Update(frame, self)
	-- This is a modified version of MultiCastRecallSpellButton_Update
	-- from MultiCastActionBarFrame.lua.

	-- first update which multi-cast spells we actually know
	for index, spellId in next, TOTEM_MULTI_CAST_RECALL_SPELLS do
		knownMultiCastRecallSpells[index] = (IsSpellKnown(spellId) and spellId) or nil;
	end

	-- update the spell button
	local spellId = knownMultiCastRecallSpells[self:GetID()];
--	self.spellId = spellId;
	if ( HasMultiCastActionBar() and spellId ) then
		-- anchor to the last shown slot
		local activeSlots = MultiCastActionBarFrame.numActiveSlots;
		if ( activeSlots > 0 ) then
			frameClearAllPoints(self);
			frameSetPoint(self, "LEFT", _G["MultiCastSlotButton"..activeSlots], "RIGHT", 8, 0);
			frameSetPoint(self, "BOTTOMLEFT", frame, "BOTTOMLEFT", 36, 3);
		end

		self:Show();
	else
		frameClearAllPoints(self);
		frameSetPoint(self, "LEFT", MultiCastSummonSpellButton, "RIGHT", 8, 0);
		frameSetPoint(self, "BOTTOMLEFT", frame, "BOTTOMLEFT", 36, 3);

		self:Hide();
	end
end

function CT_BarMod_Shift_MultiCast_UpdatePositions()
	if (CT_BottomBar) then
		return;
	end

	CT_BarMod_Shift_MultiCast_UpdateTextures();

	if (InCombatLockdown()) then
		return;
	end

	local frame;
	local shift = CT_BarMod_Shift_MultiCast_GetShiftOption();

	if (shift) then
		local frame1, frame2, yoffset;
		frame1 = CT_BarMod_MultiCastActionBarFrame;
		frame2 = MultiCastActionBarFrame;

		yoffset = 7;
		if (PetActionBarFrame_IsAboveShapeshift and PetActionBarFrame_IsAboveShapeshift()) then
			yoffset = 0;
		end

		frame1:SetHeight(frame2:GetHeight());
		frame1:SetWidth(frame2:GetWidth());
		frame1:ClearAllPoints();
		frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, yoffset)

		frame2:EnableMouse(false);

		multicastIsShifted = true;
		frame = frame1;
	else
		if (multicastIsShifted) then
			local frame2 = MultiCastActionBarFrame;

			frame2:EnableMouse(true);

			multicastIsShifted = false;
			frame = frame2;
		else
			return;
		end
	end

	-- update the multi cast spells
	CT_BarMod_Shift_MultiCast_SummonSpellButton_Update(frame, MultiCastSummonSpellButton);
	CT_BarMod_Shift_MultiCast_RecallSpellButton_Update(frame, MultiCastRecallSpellButton);
end

local function CT_BarMod_Shift_MultiCast_SetPoint(self, ap, rt, rp, x, y)
	-- (hook) This is a post hook of the .SetPoint and .SetAllPoints functions
	CT_BarMod_Shift_MultiCast_UpdatePositions();
end

local function CT_BarMod_Shift_MultiCast_OnUpdate()
	-- (hook) This is a post hook of the MultiCastActionBarFrame_OnUpdate function in MultiCastActionBarFrame.lua
	--
	-- Blizzard calls MultiCastActionBarFrame_OnUpdate from MultiCastActionBarFrame.xml using
	-- the <OnUpdate function="MultiCastActionBarFrame_OnUpdate"/> syntax,
	-- so we have to hook the OnUpdate script in order for our function
	-- to get called.
	--
	if (not MultiCastActionBarFrame.completed) then
		-- MultiCast bar is sliding into place.
		multicastNeedToMove = 1;
	else
		-- MultiCast bar has finished sliding into place.
		if (multicastNeedToMove) then
			CT_BarMod_Shift_MultiCast_UpdatePositions();
			multicastNeedToMove = nil;
		end
	end
end

local function CT_BarMod_Shift_MultiCast_Init()
	local frame1, frame2;

	-- Our frame for the MultiCast action buttons
	frame1 = CreateFrame("Frame", "CT_BarMod_MultiCastActionBarFrame");
	frame2 = MultiCastActionBarFrame;

	frame1:SetParent(UIParent);
	frame1:EnableMouse(false);
	frame1:SetHeight(frame2:GetHeight());
	frame1:SetWidth(frame2:GetWidth());
	frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 0)
	frame1:SetAlpha(1);
	frame1:Hide();

	for i = 1, 4 do
		hooksecurefunc(_G["MultiCastSlotButton" .. i], "SetPoint", CT_BarMod_Shift_MultiCast_SetPoint);
		hooksecurefunc(_G["MultiCastSlotButton" .. i], "SetAllPoints", CT_BarMod_Shift_MultiCast_SetPoint);
	end

	hooksecurefunc(MultiCastSummonSpellButton, "SetPoint", CT_BarMod_Shift_MultiCast_SetPoint);
	hooksecurefunc(MultiCastSummonSpellButton, "SetAllPoints", CT_BarMod_Shift_MultiCast_SetPoint);

	hooksecurefunc(MultiCastRecallSpellButton, "SetPoint", CT_BarMod_Shift_MultiCast_SetPoint);
	hooksecurefunc(MultiCastRecallSpellButton, "SetAllPoints", CT_BarMod_Shift_MultiCast_SetPoint);

	-- Hook the function and any xml script handler using the function= syntax to call it.
	hooksecurefunc("MultiCastActionBarFrame_OnUpdate", CT_BarMod_Shift_MultiCast_OnUpdate);
	frame2:HookScript("OnUpdate", CT_BarMod_Shift_MultiCast_OnUpdate);

	CT_BarMod_Shift_MultiCast_UpdatePositions();
end

-------------------------------
-- Shift the pet bar.

local petIsShifted;
local petNeedToMove;

local function CT_BarMod_Shift_Pet_GetShiftOption()
	return (module:getOption("shiftPet") ~= false);
end

local function CT_BarMod_Shift_Pet_UpdateTextures()
	local shift = CT_BarMod_Shift_Pet_GetShiftOption();
	if (shift) then
		SlidingActionBarTexture0:Hide();
		SlidingActionBarTexture1:Hide();
	else
		if (petIsShifted) then
			if ( MultiBarBottomLeft:IsShown() ) then
				SlidingActionBarTexture0:Hide();
				SlidingActionBarTexture1:Hide();
			else
				if (PetActionBarFrame_IsAboveShapeshift and PetActionBarFrame_IsAboveShapeshift()) then
					SlidingActionBarTexture0:Hide();
					SlidingActionBarTexture1:Hide();
				else
					SlidingActionBarTexture0:Show();
					SlidingActionBarTexture1:Show();
				end
			end
		else
			return;
		end
	end
end

function CT_BarMod_Shift_Pet_UpdatePositions()
	if (CT_BottomBar) then
		return;
	end

	CT_BarMod_Shift_Pet_UpdateTextures();

	if (InCombatLockdown()) then
		return;
	end

	local frame;
	local shift = CT_BarMod_Shift_Pet_GetShiftOption();

	if (shift) then
		local frame1, frame2, yoffset;
		frame1 = CT_BarMod_PetActionBarFrame;
		frame2 = PetActionBarFrame;

		yoffset = 2;
		if (PetActionBarFrame_IsAboveShapeshift and PetActionBarFrame_IsAboveShapeshift()) then
			yoffset = 0;
		end

		frame1:SetHeight(frame2:GetHeight());
		frame1:SetWidth(frame2:GetWidth());
		frame1:ClearAllPoints();
		frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, yoffset)

		frame2:EnableMouse(false);

		petIsShifted = true;
		frame = frame1;
	else
		if (petIsShifted) then
			local frame2 = PetActionBarFrame;

			frame2:EnableMouse(true);

			petIsShifted = false;
			frame = frame2;
		else
			return;
		end
	end

	frameClearAllPoints(PetActionButton1);
	frameSetPoint(PetActionButton1, "BOTTOMLEFT", frame, 36, 2);

	local obj;
	for i = 2, 10, 1 do
		obj = _G["PetActionButton"..i];
		frameClearAllPoints(obj);
		frameSetPoint(obj, "LEFT", _G["PetActionButton"..(i-1)], "RIGHT", 8, 0);
	end
end

local function CT_BarMod_Shift_Pet_SetPoint(self, ap, rt, rp, x, y)
	-- (hook) This is a post hook of the .SetPoint and .SetAllPoints functions
	CT_BarMod_Shift_Pet_UpdatePositions();
end

local function CT_BarMod_Shift_Pet_OnUpdate()
	-- (hook) This is a post hook of the PetActionBarFrame_OnUpdate function in PetActionBarFrame.lua
	--
	-- Blizzard calls PetActionBarFrame_OnUpdate from PetActionBarFrame.xml using
	-- the <OnUpdate function="PetActionBarFrame_OnUpdate"/> syntax,
	-- so we have to hook the OnUpdate script in order for our function
	-- to get called.
	--
	if (not PetActionBarFrame.completed) then
		-- Pet bar is sliding into place.
		petNeedToMove = 1;
	else
		-- Pet bar has finished sliding into place.
		if (petNeedToMove) then
			CT_BarMod_Shift_Pet_UpdatePositions();
			petNeedToMove = nil;
		end
	end
end

local function CT_BarMod_Shift_Pet_Init()
	local frame1, frame2;

	-- Our frame for the pet action buttons
	frame1 = CreateFrame("Frame", "CT_BarMod_PetActionBarFrame");
	frame2 = PetActionBarFrame;

	frame1:SetParent(UIParent);
	frame1:EnableMouse(false);
	frame1:SetHeight(frame2:GetHeight());
	frame1:SetWidth(frame2:GetWidth());
	frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 0)
	frame1:SetAlpha(1);
	frame1:Hide();

	for i = 1, 10 do
		hooksecurefunc(_G["PetActionButton" .. i], "SetPoint", CT_BarMod_Shift_Pet_SetPoint);
		hooksecurefunc(_G["PetActionButton" .. i], "SetAllPoints", CT_BarMod_Shift_Pet_SetPoint);
	end

	-- Hook the function and any xml script handler using the function= syntax to call it.
	hooksecurefunc("PetActionBarFrame_OnUpdate", CT_BarMod_Shift_Pet_OnUpdate);
	frame2:HookScript("OnUpdate", CT_BarMod_Shift_Pet_OnUpdate);

	CT_BarMod_Shift_Pet_UpdatePositions();
end

-------------------------------
-- Shift the possess bar.

local possessIsShifted;

local function CT_BarMod_Shift_Possess_GetShiftOption()
	return (module:getOption("shiftPossess") ~= false);
end

local function CT_BarMod_Shift_Possess_UpdateTextures()
	local shift = CT_BarMod_Shift_Possess_GetShiftOption();
	if (shift) then
		local background;
		for i=1, NUM_POSSESS_SLOTS do
			background = _G["PossessBackground"..i];
			background:Hide();
		end
	else
		if (possessIsShifted) then
			local texture, name, enabled;
			local background;
			for i=1, NUM_POSSESS_SLOTS do
				background = _G["PossessBackground"..i];
				texture, name, enabled = GetPossessInfo(i);
				if ( enabled ) then
					background:Show();
				else
					background:Hide();
				end
			end
		else
			return;
		end
	end
end

function CT_BarMod_Shift_Possess_UpdatePositions()
	if (CT_BottomBar) then
		return;
	end

	CT_BarMod_Shift_Possess_UpdateTextures();

	if (InCombatLockdown()) then
		return;
	end

	local frame;
	local shift = CT_BarMod_Shift_Possess_GetShiftOption();

	if (shift) then
		local frame1, frame2;
		frame1 = CT_BarMod_PossessBarFrame;
		frame2 = PossessBarFrame;

		frame1:SetHeight(frame2:GetHeight());
		frame1:SetWidth(frame2:GetWidth());
		frame1:ClearAllPoints();
		frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 12)

		frame2:EnableMouse(false);

		possessIsShifted = true;
		frame = frame1;
	else
		if (possessIsShifted) then
			local frame2 = PossessBarFrame;

			frame2:EnableMouse(true);

			possessIsShifted = false;
			frame = frame2;
		else
			return;
		end
	end

	frameClearAllPoints(PossessButton1);
	frameSetPoint(PossessButton1, "BOTTOMLEFT", frame, 10, 3);

	local obj;
	for i = 2, 2, 1 do
		obj = _G["PossessButton"..i];
		frameClearAllPoints(obj);
		frameSetPoint(obj, "LEFT", _G["PossessButton"..(i-1)], "RIGHT", 8, 0);
	end
end

local function CT_BarMod_Shift_Possess_SetPoint(self, ap, rt, rp, x, y)
	-- (hook) This is a post hook of the .SetPoint and .SetAllPoints functions
	CT_BarMod_Shift_Possess_UpdatePositions();
end

local function CT_BarMod_Shift_Possess_Update()
	-- (hook) This is a post hook of the PossessBar_Update function in BonusActionBarFrame.lua
	--
	-- Blizzard's PossessBar_Update function gets called:
	-- a) from PossessBar_OnLoad in BonusActionBarFrame.lua
	-- b) from PossessBar_OnEvent in BonusActionBarFrame.lua for the
	--    PLAYER_ENTERING_WORLD and UPDATE_BONUS_ACTIONBAR events.
	-- c) from MainMenuBar_ToVehicleArt in MainMenuBar.lua
	-- d) from MainMenuBar_ToPlayerArt in MainMenuBar.lua
	-- Blizzard calls UIParent_ManageFramePositions() at the end of PossessBar_Update().
	--
	CT_BarMod_Shift_Possess_UpdatePositions();
end

local function CT_BarMod_Shift_Possess_UpdateState()
	-- (hook) This is a post hook of the PossessBar_UpdateState function in BonusActionBarFrame.lua
	--
	-- Blizzard's PossessBar_UpdateState function gets called:
	-- a) from PossessBar_Update in BonusActionBarFrame.lua
	--
	CT_BarMod_Shift_Possess_UpdateTextures();
end

local function CT_BarMod_Shift_Possess_Init()
	local frame1, frame2;

	-- Our frame for the possess action buttons
	frame1 = CreateFrame("Frame", "CT_BarMod_PossessBarFrame");
	frame2 = PossessBarFrame;

	frame1:SetParent(UIParent);
	frame1:EnableMouse(false);
	frame1:SetHeight(frame2:GetHeight());
	frame1:SetWidth(frame2:GetWidth());
	frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 0)
	frame1:SetAlpha(1);
	frame1:Hide();

	for i = 1, 2 do
		hooksecurefunc(_G["PossessButton" .. i], "SetPoint", CT_BarMod_Shift_Possess_SetPoint);
		hooksecurefunc(_G["PossessButton" .. i], "SetAllPoints", CT_BarMod_Shift_Possess_SetPoint);
	end

	hooksecurefunc("PossessBar_Update", CT_BarMod_Shift_Possess_Update);
	hooksecurefunc("PossessBar_UpdateState", CT_BarMod_Shift_Possess_UpdateState);

	CT_BarMod_Shift_Possess_UpdatePositions();
end

-------------------------------
-- Shift the shapeshift (class) bar.

local shapeshiftIsShifted;

local function CT_BarMod_Shift_Shapeshift_GetShiftOption()
	return (module:getOption("shiftShapeshift") ~= false);
end

local function CT_BarMod_Shift_Shapeshift_UpdateTextures()
	local shift = CT_BarMod_Shift_Shapeshift_GetShiftOption();
	if (shift) then
		ShapeshiftBarLeft:Hide();
		ShapeshiftBarRight:Hide();
		ShapeshiftBarMiddle:Hide();
		for i=1, GetNumShapeshiftForms() do
			_G["ShapeshiftButton"..i.."NormalTexture"]:SetWidth(50);
			_G["ShapeshiftButton"..i.."NormalTexture"]:SetHeight(50);
		end
	else
		if (shapeshiftIsShifted) then
			if ( MultiBarBottomLeft:IsShown() ) then
				if ( ShapeshiftBarFrame ) then
					ShapeshiftBarLeft:Hide();
					ShapeshiftBarRight:Hide();
					ShapeshiftBarMiddle:Hide();
					for i=1, GetNumShapeshiftForms() do
						_G["ShapeshiftButton"..i.."NormalTexture"]:SetWidth(50);
						_G["ShapeshiftButton"..i.."NormalTexture"]:SetHeight(50);
					end
				end
			else
				if ( ShapeshiftBarFrame ) then
					if ( GetNumShapeshiftForms() > 2 ) then
						ShapeshiftBarMiddle:Show();
					end
					ShapeshiftBarLeft:Show();
					ShapeshiftBarRight:Show();
					for i=1, GetNumShapeshiftForms() do
						_G["ShapeshiftButton"..i.."NormalTexture"]:SetWidth(64);
						_G["ShapeshiftButton"..i.."NormalTexture"]:SetHeight(64);
					end
				end
			end
		else
			return;
		end
	end
end

function CT_BarMod_Shift_Shapeshift_UpdatePositions()
	if (CT_BottomBar) then
		return;
	end

	CT_BarMod_Shift_Shapeshift_UpdateTextures();

	if (InCombatLockdown()) then
		return;
	end

	local frame;
	local shift = CT_BarMod_Shift_Shapeshift_GetShiftOption();

	if (shift) then
		local frame1, frame2;
		frame1 = CT_BarMod_ShapeshiftBarFrame;
		frame2 = ShapeshiftBarFrame;

		frame1:SetHeight(frame2:GetHeight());
		frame1:SetWidth(frame2:GetWidth());
		frame1:ClearAllPoints();
		frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 13)

		frame2:EnableMouse(false);

		shapeshiftIsShifted = true;
		frame = frame1;
	else
		if (shapeshiftIsShifted) then
			local frame2 = ShapeshiftBarFrame;

			frame2:EnableMouse(true);

			shapeshiftIsShifted = false;
			frame = frame2;
		else
			return;
		end
	end

	local xoffset;
	if (GetNumShapeshiftForms() == 1) then
		xoffset = 12;  -- As seen in ShapeshiftBar_Update() in BonusActionBarFrame.lua
	else
		xoffset = 10;
	end

	frameClearAllPoints(ShapeshiftButton1);
	frameSetPoint(ShapeshiftButton1, "BOTTOMLEFT", frame, xoffset, 3);

	local obj;
	for i = 2, 10, 1 do
		obj = _G["ShapeshiftButton"..i];
		frameClearAllPoints(obj);
		if (i == 2) then
			xoffset = 8;  -- As seen in BonusActionBarFrame.xml
		else
			xoffset = 7;
		end
		frameSetPoint(obj, "LEFT", _G["ShapeshiftButton"..(i-1)], "RIGHT", xoffset, 0);
	end
end

local function CT_BarMod_Shift_Shapeshift_SetPoint(self, ap, rt, rp, x, y)
	-- (hook) This is a post hook of the .SetPoint and .SetAllPoints functions
	CT_BarMod_Shift_Shapeshift_UpdatePositions();
end

local function CT_BarMod_Shift_Shapeshift_Update()
	-- (hook) This is a post hook of the ShapeshiftBar_Update function in BonusActionBarFrame.lua
	--
	-- Blizzard's ShapeshiftBar_Update function gets called:
	-- a) from ShapeshiftBar_OnLoad in BonusActionBarFrame.lua
	-- b) from ShapeshiftBar_OnEvent in BonusActionBarFrame.lua for the events
	--    PLAYER_ENTERING_WORLD and UPDATE_SHAPESHIFT_FORMS
	-- Blizzard calls UIParent_ManageFramePositions at the end of ShapeshiftBar_Update.

	-- Blizzard's function re-anchors ShapeshiftButton1 when the player has only 1 shapeshift form.
	-- We have to undo their anchor and re-establish our own.
	-- If we are in combat when Blizzard does it, then there is nothing we can do about it,
	-- since the button is protected.
	CT_BarMod_Shift_Shapeshift_UpdatePositions();
end

local function CT_BarMod_Shift_Shapeshift_Init()
	local frame1, frame2;

	-- Our frame for the class action buttons
	frame1 = CreateFrame("Frame", "CT_BarMod_ShapeshiftBarFrame");
	frame2 = ShapeshiftBarFrame;

	frame1:SetParent(UIParent);
	frame1:EnableMouse(false);
	frame1:SetHeight(frame2:GetHeight());
	frame1:SetWidth(frame2:GetWidth());
	frame1:SetPoint("BOTTOMLEFT", frame2, "TOPLEFT", 0, 0)
	frame1:SetAlpha(1);
	frame1:Hide();

	for i = 1, 10 do
		hooksecurefunc(_G["ShapeshiftButton" .. i], "SetPoint", CT_BarMod_Shift_Shapeshift_SetPoint);
		hooksecurefunc(_G["ShapeshiftButton" .. i], "SetAllPoints", CT_BarMod_Shift_Shapeshift_SetPoint);
	end

	hooksecurefunc("ShapeshiftBar_Update", CT_BarMod_Shift_Shapeshift_Update);

	CT_BarMod_Shift_Shapeshift_UpdatePositions();
end

-------------------------------
-- UIParent_ManageFramePositions

local function CT_BarMod_Shift_UIParent_ManageFramePositions()
	-- (hook) This is called after Blizzard's UIParent_ManageFramePositions function in UIParent.lua.
	CT_BarMod_Shift_MultiCast_UpdateTextures();
	CT_BarMod_Shift_Pet_UpdateTextures();
	CT_BarMod_Shift_Possess_UpdateTextures();
	CT_BarMod_Shift_Shapeshift_UpdateTextures();
end

-------------------------------
-- OnEvent

local function CT_BarMod_Shift_OnEvent(self, event, arg1, ...)
	if (event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN") then
		-- Set flags so we will shift the party and focus frames if needed.
		CT_BarMod_Shift_Party_SetFlag();
		CT_BarMod_Shift_Focus_SetFlag();
	end

	if (event == "PLAYER_LOGIN") then
		-- When CT_BottomBar is loaded we don't want CT_BarMod to do any repositioning
		-- of the bars.  CT_BottomBar will handle them.

		if (not CT_BottomBar) then
			CT_BarMod_Shift_MultiCast_Init();
			CT_BarMod_Shift_Pet_Init();
			CT_BarMod_Shift_Possess_Init();
			CT_BarMod_Shift_Shapeshift_Init();

			-- We need to hook the UIParent_ManageFramePositions function since it
			-- may hide/show some textures.
			hooksecurefunc("UIParent_ManageFramePositions", CT_BarMod_Shift_UIParent_ManageFramePositions);

			-- Since Blizzard uses the "function=" syntax in their xml scripts to
			-- call UIParent_ManageFramePositions, we will have to hook all scripts
			-- that do this. This is necessary because scripts using this syntax don't
			-- call post hooks of functions created using hooksecurefunc().
			-- 	<OnShow function="UIParent_ManageFramePositions"/>
			-- 	<OnHide function="UIParent_ManageFramePositions"/>

			ShapeshiftBarFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			ShapeshiftBarFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);

			PossessBarFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			PossessBarFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);

			DurabilityFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			DurabilityFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);

			MainMenuBarMaxLevelBar:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			MainMenuBarMaxLevelBar:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);

			MultiCastActionBarFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			MultiCastActionBarFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);

			PetActionBarFrame:HookScript("OnShow", CT_BarMod_Shift_UIParent_ManageFramePositions);
			PetActionBarFrame:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);

			ReputationWatchBar:HookScript("OnHide", CT_BarMod_Shift_UIParent_ManageFramePositions);
		end

		-- Originally there was only one "shift up" option (shiftShapeshift).
		-- It was then (in v3.301) split into 4 separate options.
		-- The following code converts the shiftShapeshift option (if nil)
		-- from a nil to 1, and then assigns the shiftShapeshift value to
		-- each of the new "shift up" options if they are nil (which will
		-- only be true for the first run of the new version). This way
		-- when people run v3.301 for the first time all 4 of the shift up
		-- options will be the same just like it was prior to v3.301.

		local shiftShapeshift = module:getOption("shiftShapeshift"); -- nil, false, or 1
		if (shiftShapeshift == nil) then
			shiftShapeshift = 1;
			module:setOption("shiftShapeshift", shiftShapeshift, true);
		end
		if (module:getOption("shiftPet") == nil) then
			module:setOption("shiftPet", shiftShapeshift, true);
		end
		if (module:getOption("shiftPossess") == nil) then
			module:setOption("shiftPossess", shiftShapeshift, true);
		end
		if (module:getOption("shiftMultiCast") == nil) then
			module:setOption("shiftMultiCast", shiftShapeshift, true);
		end
	end

	if (event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD") then
		-- Shift the part and focus frames if needed.
		if (shiftParty) then
			CT_BarMod_Shift_Party_Move();
		end
		if (shiftFocus) then
			CT_BarMod_Shift_Focus_Move();
		end

		-- Ensure everything is where it should be.
		if (not CT_BottomBar) then
			CT_BarMod_Shift_UpdatePositions();
		end

	elseif (event == "PLAYER_REGEN_DISABLED") then
		-- Ensure everything is where it should be.
		if (not CT_BottomBar) then
			CT_BarMod_Shift_UpdatePositions();
		end
	end
end

-------------------------------
-- Miscellaneous

function CT_BarMod_Shift_UpdatePositions()
	if (not CT_BottomBar) then
		CT_BarMod_Shift_MultiCast_UpdatePositions();
		CT_BarMod_Shift_Pet_UpdatePositions();
		CT_BarMod_Shift_Possess_UpdatePositions();
		CT_BarMod_Shift_Shapeshift_UpdatePositions();
	end
end

function CT_BarMod_Shift_ResetPositions()
	CT_BarMod_Shift_UpdatePositions();
end

function CT_BarMod_Shift_Init()
	-- Frame to watch for events
	local frame = CreateFrame("Frame", "CT_BarMod_Shift_EventFrame");

	frameSetPoint = frame.SetPoint;
	frameClearAllPoints = frame.ClearAllPoints;

	frame:SetScript("OnEvent", CT_BarMod_Shift_OnEvent);

	frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	frame:RegisterEvent("PLAYER_LOGIN");
	frame:RegisterEvent("PLAYER_ENTERING_WORLD");

	frame:Show();

	-- Finish initializing in the PLAYER_LOGIN and PLAYER_ENTERING_WORLD events,
	-- so that we can be sure if CT_BottomBar is loaded or not (it will load
	-- after CT_BarMod).
end
