------------------------------------------------
--               CT_BottomBar                 --
--                                            --
-- Breaks up the main menu bar into pieces,   --
-- allowing you to hide and move the pieces   --
-- independently of each other.               --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

-- Local copies
local min = min;

local ctRelativeFrame = UIParent;

local ctActionBar;
local ctClassBar;
local ctExpBar;
local ctMultiCastBar;

local ctMenuBar;
local ctVehicleSkin;

local ctPetBar;
local ctRepBar;
local ctPossessBar;
local ctVehicleBar;
local ctVehicleSaved = {};

--------------------------------------------

local function CT_BottomBar_Vehicle_SaveBlizzardData(skin, frame)
	local saved;
	saved = ctVehicleSaved[skin];
	if (not saved) then
		ctVehicleSaved[skin] = {};
	end
	saved = ctVehicleSaved[skin][frame];
	if (not saved) then
		saved = {};
		ctVehicleSaved[skin][frame] = saved;
	end
	saved.height = frame:GetHeight();
	saved.width = frame:GetWidth();
	saved.highlight = frame:GetHighlightTexture();
	saved.normal = frame:GetNormalTexture();
	saved.pushed = frame:GetPushedTexture();
	saved.pt, saved.rel, saved.relpt, saved.xoff, saved.yoff = frame:GetPoint(1);
	if (saved.rel) then
		saved.rel = saved.rel:GetName();
	end
	saved.shown = frame:IsShown();
end

local function CT_BottomBar_Vehicle_LoadBlizzardData(skin, frame, parent)
	local saved;
	saved = ctVehicleSaved[skin];
	if (not saved) then
		return;
	end
	saved = ctVehicleSaved[skin][frame];
	if (not saved) then
		return;
	end
	frame:SetHeight(saved.height);
	frame:SetWidth(saved.width);
	frame:SetHighlightTexture(saved.highlight);
	frame:SetNormalTexture(saved.normal);
	frame:SetPushedTexture(saved.pushed);
	frame:SetParent(parent);
	frame:ClearAllPoints();
	if (saved.pt) then
		frame:SetPoint(saved.pt, saved.rel, saved.relpt, saved.xoff, saved.yoff);
	end
	if (saved.shown) then
		frame:Show();
	else
		frame:Hide();
	end
end

--------------------------------------------
-- Miscellaneous
-- These may reference multiple bars.

local function CT_BottomBar_MainMenuBarVehicleLeaveButton_Update()
	-- (hook) This is called after Blizzard's MainMenuBarVehicleLeaveButton_Update
	-- This function references ctClassBar, ctPossessBar, and ctMultiCastBar.
	--
	if ( CanExitVehicle() ) then
		MainMenuBarVehicleLeaveButton:ClearAllPoints();
		if ( IsPossessBarVisible() ) then
			if ( ctPossessBar.orientation == "ACROSS" ) then
				MainMenuBarVehicleLeaveButton:SetPoint("LEFT", PossessButton2, "RIGHT", 6, 0);
			else
				MainMenuBarVehicleLeaveButton:SetPoint("TOP", PossessButton2, "BOTTOM", 0, -6);
			end
		elseif ( GetNumShapeshiftForms() > 0 ) then
			if ( ctClassBar.orientation == "ACROSS" ) then
				MainMenuBarVehicleLeaveButton:SetPoint("LEFT", "ShapeshiftButton"..GetNumShapeshiftForms(), "RIGHT", 6, 0);
			else
				MainMenuBarVehicleLeaveButton:SetPoint("TOP", "ShapeshiftButton"..GetNumShapeshiftForms(), "BOTTOM", 0, -6);
			end
		elseif ( HasMultiCastActionBar() ) then
			MainMenuBarVehicleLeaveButton:SetPoint("LEFT", ctMultiCastBar.frame, "RIGHT", 30, 0);
		else
			MainMenuBarVehicleLeaveButton:SetPoint("BOTTOMLEFT", ctPossessBar.frame);
		end
	end
end

local function CT_BottomBar_UIParent_ManageFramePositions()
	-- (hook) This is called after Blizzard's UIParent_ManageFramePositions function in UIParent.lua.

	-- Pet bar textures
	SlidingActionBarTexture0:Hide();
	SlidingActionBarTexture1:Hide();

	-- Class bar textures
	ShapeshiftBarLeft:Hide();
	ShapeshiftBarRight:Hide();
	ShapeshiftBarMiddle:Hide();
end

--------------------------------------------
-- Action Bar

local function CT_BottomBar_BelowBonusActionButton_Update(self)
	-- Update the below bonus action button frames.
	-- Enable or disable the mouse in our "CT_BottomBar_BelowBonusActionButton"..self:GetID() frame.
	local enable = false;
	if (BonusActionBarFrame:IsShown()) then
		if (_G["BonusActionButton" .. self:GetID() .. "Icon"]:IsShown()) then
			enable = true;
		else
			if (_G["ActionButton" .. self:GetID() .. "Icon"]:IsShown()) then
				enable = true;
			else
				enable = false;
			end
		end
	else
		enable = false;
	end
	_G["CT_BottomBar_BelowBonusActionButton" .. self:GetID()]:EnableMouse(enable);
end


local function CT_BottomBar_ActionButton_Update(self)
	-- (hook) This is run after Blizzard's ActionButton_Update function,
	-- and also by CT_BottomBar_ActionButton_Refresh in this file.

	local name = self:GetName();

	if (string.sub(name, 1, 12) == "ActionButton" or string.sub(name, 1, 17) == "BonusActionButton") then
		if (module:getOption("barHideGrid")) then
			-- Always hide our frame
			_G["CT_BottomBar_" .. name]:Hide();
		else
			-- Hide our frame if there is no icon shown on the corresponding spot on the action/bonus bar.
			if (not _G[name.."Icon"]:IsShown()) then
				_G["CT_BottomBar_" .. name]:Show();
			else
				_G["CT_BottomBar_" .. name]:Hide();
			end
		end

		-- Set an alpha value for our bonus frame based on the state of the bonus action bar.
		if (not BonusActionBarFrame:IsShown()) then
			_G["CT_BottomBar_BonusActionButton" .. self:GetID()]:SetAlpha(0);
		else
			_G["CT_BottomBar_BonusActionButton" .. self:GetID()]:SetAlpha(1);
		end

		-- Enable or disable the mouse in our "CT_BottomBar_BelowBonusActionButton"..self:GetID() frame.
		CT_BottomBar_BelowBonusActionButton_Update(self);
	end
end

local function CT_BottomBar_BonusActionBarFrame_OnShow(self)
	-- (hook) This is called by the OnShow script for BonusActionBarFrame.
	-- Note: Blizzard shows the BonusActionBarFrame and then animates it into position,
	-- and the UPDATE_BONUS_ACTIONBAR event will occur after the OnShow handler is called.
	local barHideGrid = module:getOption("barHideGrid");
	local obj;
	for i = 1, 12, 1 do
		-- Hide the ActionButton by setting alpha value to zero (save it first).
		obj = _G["ActionButton"..i];
		obj.alpha = obj:GetAlpha();
		obj:SetAlpha(0);
		--obj:Disable();

		-- Hide our action frame by setting alpha value to zero (save it first).
		obj = _G["CT_BottomBar_ActionButton"..i];
		obj.alpha = obj:GetAlpha();
		obj:SetAlpha(0);

		-- Display our bonus action frame.
		obj = _G["CT_BottomBar_BonusActionButton"..i];
		obj:SetAlpha(1);
		if (not barHideGrid) then
			obj:Show();
		else
			obj:Hide();
		end
	end
	-- Update the below bonus action button frames.
	for i = 1, 12 do
		CT_BottomBar_BelowBonusActionButton_Update(_G["BonusActionButton" .. i]);
	end
end

local function CT_BottomBar_BonusActionBarFrame_OnHide(self)
	-- (hook) This is called by the OnHide script for BonusActionBarFrame.
	-- Note: Blizzard animates BonusActionBarFrame off screen and then hides it,
	-- and the UPDATE_BONUS_ACTIONBAR event will occur before the OnHide handler is called.
	local obj, obj2;
	for i = 1, 12, 1 do
		-- Restore the ActionButton alpha values
		obj = _G["ActionButton"..i];
		obj:SetAlpha(obj.alpha or 1);
		obj.alpha = nil;
		--obj:Enable();

		-- Restore our action frame's alpha values
		obj2 = _G["CT_BottomBar_ActionButton"..i];
		obj2:SetAlpha(obj2.alpha or 1);
		obj2.alpha = nil;

		-- Hide our bonus action frame.
		obj2 = _G["CT_BottomBar_BonusActionButton"..i];
		obj2:SetAlpha(0);
		obj2:Hide();
	end
	-- Update the below bonus action button frames.
	for i = 1, 12 do
		CT_BottomBar_BelowBonusActionButton_Update(_G["BonusActionButton" .. i]);
	end
end

hooksecurefunc("ShowBonusActionBar", function (override)
	if (BonusActionBarFrame.mode == "show") then
		module.showingBonusBar = true;
	end
end);

hooksecurefunc("HideBonusActionBar", function (override)
	if (BonusActionBarFrame.mode == "hide") then
		module.showingBonusBar = false;
	end
end);

local function CT_BottomBar_Action_Orientation(orientation, spacing)
	-- Adjust the orientation and spacing of the action bar buttons.
	if (InCombatLockdown()) then
		return;
	end
	if (not orientation) then
		orientation = ctActionBar.orientation;
	end
	if (not spacing) then
		spacing = module:getOption("barSpacing") or 6;
	end

	ActionButton1:ClearAllPoints();
	ActionButton1:SetPoint("BOTTOMLEFT", ctActionBar.frame);

	local obj, obj2;
	for i = 1, 12, 1 do
		obj = _G["ActionButton"..i];

		-- Center the bonus action buttons over the action buttons.
		obj2 = _G["BonusActionButton"..i];
		obj2:ClearAllPoints();
		obj2:SetPoint("CENTER", obj);

		-- Anchor the action buttons to each other.
		if ( i > 1 ) then
			obj:ClearAllPoints();
			if ( orientation == "ACROSS" ) then
				obj:SetPoint("LEFT", _G["ActionButton"..(i-1)], "RIGHT", spacing, 0);
			else
				obj:SetPoint("TOP", _G["ActionButton"..(i-1)], "BOTTOM", 0, -spacing);
			end
		end
	end
end

local function CT_BottomBar_Action_HideTextures()
	-- Hide textures related to the action and bonus action bars.
	MainMenuBarTexture0:Hide();
	MainMenuBarTexture1:Hide();
	BonusActionBarTexture0:Hide();
	BonusActionBarTexture1:Hide();
end

local function CT_BottomBar_Action_Update()
	-- Update the action and bonus action bars (textures, scale, spacing, visibility).

	CT_BottomBar_Action_HideTextures();

	if (not InCombatLockdown()) then
		MainMenuBar:EnableMouse(0);
		BonusActionBarFrame:EnableMouse(0);

		CT_BottomBar_Action_Orientation();

		module:update("barScale", module:getOption("barScale") or 1);
		module:update("barSpacing", module:getOption("barSpacing") or 6);
	end
end

local function CT_BottomBar_ActionButton_Refresh()
	-- Refresh the buttons on the action and bonus action bars.
	local obj;
	for i = 1, 12 do
		obj = _G["ActionButton" .. i];
		CT_BottomBar_ActionButton_Update(obj);

		obj = _G["BonusActionButton" .. i];
		CT_BottomBar_ActionButton_Update(obj);
	end
end

module:registerAddon(
	"Action Bar",  -- option name & part of frame name
	"Action Bar",  -- shown in options window & tooltips
	"Action Bar",  -- title for horizontal orientation
	"Action",  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -505, 3 },
	nil,
	function(self)
		ctActionBar = self;

		-- Hide the textures behind the bar
		CT_BottomBar_Action_HideTextures();

		-- Position the left gryphon to be left of the bar
		local leftGryphon = MainMenuBarLeftEndCap;
		leftGryphon:ClearAllPoints();
		leftGryphon:SetPoint("BOTTOMRIGHT", ActionButton1, "BOTTOMLEFT", 28, -5);
		leftGryphon:Hide();

		-- Create our own action frame.
		local frame = CreateFrame("Frame", "CT_BottomBar_ActionBarFrame");
		frame:SetPoint("TOPLEFT", ActionButton1);
		frame:SetPoint("BOTTOMRIGHT", ActionButton12);
		self.helperFrame = frame;

		frame = self.frame;
		ActionButton1:ClearAllPoints();
		ActionButton1:SetPoint("BOTTOMLEFT", frame);

		-- Create frames to sit above the action buttons and below the CT_BottomBar_BonusActionBarFrame
		-- frame that we will create after these frames.
		--
		-- Essentially, we want these frames to trap the mouse when the BonusActionBarFrame is shown, and
		-- not trap the mouse when the BonusActionBarFrame is hidden. Whether or not to trap the mouse
		-- is determined separately for each button, and depends on whether the bonus bar frame is shown,
		-- and whether or not there is an icon showing in the corresponding button spot on the ActionBarFrame.
		--
		-- In the default UI, Blizzard does not allow you to hide empty bonus action buttons,
		-- so when an empty bonus action button is hidden by us, the user can still detect the presence
		-- of the action button below.  We can't hide an action button if the user is in combat, so we
		-- have to find a way of preventing the user from clicking the empty bonus action button slot
		-- and having it end up clicking the action button slot below. This is where these below
		-- bonus action button frames come in.  They can trap the mouse to prevent the user from
		-- seeing a tooltip of, and clicking on, the action button below the empty bonus action button slot.
		for i = 1, 12 do
			local obj;
			obj = CreateFrame("Frame", "CT_BottomBar_BelowBonusActionButton" .. i)
			obj:SetWidth(ActionButton1:GetWidth());
			obj:SetHeight(ActionButton1:GetHeight());
			obj:SetPoint("CENTER", _G["BonusActionButton" .. i]);
			obj:SetParent(UIParent);  -- Use UIParent as parent so we can call :EnableMouse() on frame during combat.
			obj:EnableMouse(false);
			obj:SetFrameLevel(ActionButton1:GetFrameLevel() + 1);  -- Ensure frame is above the action buttons.
			obj:Show();
		end

		-- Create our own bonus frame.
		local bonusFrame = CreateFrame("Frame", "CT_BottomBar_BonusActionBarFrame", frame);
--		bonusFrame:SetWidth(32);
--		bonusFrame:SetHeight(32);
--		bonusFrame:SetPoint("BOTTOMLEFT", frame);
		bonusFrame:SetPoint("TOPLEFT", ActionButton1);
		bonusFrame:SetPoint("BOTTOMRIGHT", ActionButton12);
		bonusFrame:SetFrameLevel(CT_BottomBar_BelowBonusActionButton1:GetFrameLevel()+1); -- Ensure frame is above the ones we're using to trap the mouse

		BonusActionBarFrame:SetParent(bonusFrame);
		BonusActionBarFrame:ClearAllPoints();
		BonusActionBarFrame:SetPoint("TOPLEFT", bonusFrame, "BOTTOMLEFT");
		BonusActionBarFrame:EnableMouse(0);

		-- Create a frame that will be out of sight (below the screen).
		local bonusFrame2 = CreateFrame("Frame", "CT_BottomBar_BonusActionBarFrame2", UIParent);
		bonusFrame2:SetWidth(10);
		bonusFrame2:SetHeight(200);
		bonusFrame2:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, 0);

		-- Create frames that we will use to fill in gaps between buttons
		-- that are there because we've hidden the action bar textures.
		local obj, tex;
		for i = 1, 12 do
			obj = CreateFrame("Frame", "CT_BottomBar_ActionButton" .. i)
			obj:SetWidth(ActionButton1:GetWidth());
			obj:SetHeight(ActionButton1:GetHeight());
			obj:SetPoint("CENTER", _G["ActionButton" .. i]);
			obj:SetParent(frame);
			obj:Hide();

			tex = obj:CreateTexture("CT_BottomBar_ActionButton" .. i .. "Texture");
			tex:SetTexture("Interface\\Buttons\\UI-Quickslot");
			tex:SetVertexColor(1, 1, 1, 0.5);
			tex:SetPoint("CENTER", obj);
			tex:Show();

			obj = CreateFrame("Frame", "CT_BottomBar_BonusActionButton" .. i)
			obj:SetWidth(ActionButton1:GetWidth());
			obj:SetHeight(ActionButton1:GetHeight());
			obj:SetPoint("CENTER", _G["BonusActionButton" .. i]);
			obj:SetParent(bonusFrame);
			obj:Hide();

			tex = obj:CreateTexture("CT_BottomBar_BonusActionButton" .. i .. "Texture");
			tex:SetTexture("Interface\\Buttons\\UI-Quickslot");
			tex:SetVertexColor(1, 1, 1, 0.5);
			tex:SetPoint("CENTER", obj);
			tex:Show();
		end

		-- Hook some functions and script handlers.
		hooksecurefunc("ActionButton_Update", CT_BottomBar_ActionButton_Update);

		local bonusOnShow = BonusActionBarFrame:GetScript("OnShow");
		local bonusOnHide = BonusActionBarFrame:GetScript("OnHide");

		if (bonusOnShow) then
			BonusActionBarFrame:HookScript("OnShow", CT_BottomBar_BonusActionBarFrame_OnShow);
		else
			BonusActionBarFrame:SetScript("OnShow", CT_BottomBar_BonusActionBarFrame_OnShow);
		end

		if (bonusOnHide) then
			BonusActionBarFrame:HookScript("OnHide", CT_BottomBar_BonusActionBarFrame_OnHide);
		else
			BonusActionBarFrame:SetScript("OnHide", CT_BottomBar_BonusActionBarFrame_OnHide);
		end

		if ( BonusActionBarFrame:IsShown() ) then
			BonusActionBarFrame:Hide();
			BonusActionBarFrame:Show(); -- Force OnShow
		end

		-- Function to update the action buttons (spacing, scaling, opacity).
		if (not module.updateMainBar) then
			module.updateMainBar = {};
		end
		tinsert(module.updateMainBar,
			function(obj, type, value)
				if ( type == "barSpacing" ) then
					self:rotateFunc(self.orientation, value);
					return;
				end

				local func, obj, maxFunc;

				if ( type == "barScale" ) then
					if (InCombatLockdown()) then
						return;
					end
					func = ActionButton1.SetScale;
				elseif ( type == "barOpacity" ) then
					func = ActionButton1.SetAlpha;
					if ( ActionButton1.alpha ) then
						maxFunc = ActionButton1.GetAlpha;
					end
				elseif ( type == "barHideGrid" ) then
					CT_BottomBar_ActionButton_Refresh();
				end

				if (func) then
					for i = 1, 12, 1 do
						obj = _G["ActionButton"..i];
						if ( maxFunc ) then
							func(obj, min(maxFunc(obj), value));
							obj.alpha = value;
						else
							func(obj, value);
						end
						obj = _G["CT_BottomBar_ActionButton"..i];
						if ( maxFunc ) then
							func(obj, min(maxFunc(obj), value));
							obj.alpha = value;
						else
							func(obj, value);
						end
						func(_G["BonusActionButton"..i], value);
						func(_G["CT_BottomBar_BonusActionButton"..i], value);
					end
				end
			end
		);

		CT_BottomBar_Action_Update();

		return true;
	end,
	function(self, orientation, spacing)
		CT_BottomBar_Action_Orientation(orientation, spacing);
	end,
	"helperFrame",
	ActionButton1,
	ActionButton2,
	ActionButton3,
	ActionButton4,
	ActionButton5,
	ActionButton6,
	ActionButton7,
	ActionButton8,
	ActionButton9,
	ActionButton10,
	ActionButton11,
	ActionButton12
);

--------------------------------------------
-- Action bar arrows

module:registerAddon(
	"Action Bar Arrows",  -- option name & part of frame name
	"Action Bar Arrows",  -- shown in options window & tooltips
	"ABar",  -- title for horizontal orientation
	nil,  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 1, -6 },
	nil,
	function(self)
		local frame = CreateFrame("Frame", "CT_BottomBar_ActionBarArrowsFrame");
		frame:SetPoint("TOPLEFT", ActionBarUpButton, "TOPLEFT", 0, 0);
		frame:SetPoint("BOTTOMRIGHT", ActionBarDownButton, "BOTTOMRIGHT", 0, 0);
		self.helperFrame = frame;
		
		ActionBarDownButton:ClearAllPoints();
		ActionBarDownButton:SetPoint("BOTTOMLEFT", self.frame, 0, 0);

		ActionBarUpButton:ClearAllPoints();
		ActionBarUpButton:SetPoint("BOTTOMLEFT", ActionBarDownButton, "TOPLEFT", 0, -14);

		MainMenuBarPageNumber:SetParent(self.frame);
		MainMenuBarPageNumber:ClearAllPoints();
		MainMenuBarPageNumber:SetPoint("TOPLEFT", ActionBarDownButton, "TOPLEFT", 27, 0);

		return true;		
	end,
	nil,
	"helperFrame",
	ActionBarUpButton,
	ActionBarDownButton
);

--------------------------------------------
-- Bags Bar

module:registerAddon(
	"Bags Bar",  -- option name & part of frame name
	"Bags Bar",  -- shown in options window & tooltips
	"Bags Bar",  -- title for horizontal orientation
	"Bags",  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 350, 6 },
	nil,
	function(self)
		-- Hide the textures behind the bar
		MainMenuBarTexture3:Hide();
		
		local frame = CreateFrame("Frame", "CT_BottomBar_BagsBarFrame");
		frame:SetPoint("TOPLEFT", CharacterBag3Slot, 0, 0);
		frame:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton);
		self.helperFrame = frame;
		
		CharacterBag3Slot:ClearAllPoints();
		CharacterBag3Slot:SetPoint("BOTTOMLEFT", self.frame, 0, 0);
		
		local rightGryphon = MainMenuBarRightEndCap;
		rightGryphon:ClearAllPoints();
		rightGryphon:SetPoint("BOTTOMLEFT", MainMenuBarBackpackButton, "BOTTOMRIGHT", -28, -5);
		rightGryphon:Hide();

		return true;		
	end,
	function(self, orientation)
		local frames, obj = self.frames;
		for i = 3, #frames, 1 do
			obj = frames[i];
			obj:ClearAllPoints();
			if ( orientation == "ACROSS" ) then
				obj:SetPoint("LEFT", frames[i-1], "RIGHT", 0, 0);
			else
				obj:SetPoint("TOP", frames[i-1], "BOTTOM", 0, 0);
			end
		end
	end,
	"helperFrame",
	CharacterBag3Slot,
	CharacterBag2Slot,
	CharacterBag1Slot,
	CharacterBag0Slot,
	MainMenuBarBackpackButton
);

--------------------------------------------
-- Class Bar (Shapeshift Bar)

local function CT_BottomBar_Shapeshift_Orientation(orientation)
	if (InCombatLockdown()) then
		return;
	end
	if (not orientation) then
		orientation = ctClassBar.orientation;
	end

	ShapeshiftButton1:ClearAllPoints();
	ShapeshiftButton1:SetPoint("BOTTOMLEFT", ctClassBar.frame);

	local obj;
	local spacing = 8;
	for i = 2, 10, 1 do
		obj = _G["ShapeshiftButton"..i];
		obj:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			obj:SetPoint("LEFT", _G["ShapeshiftButton"..(i-1)], "RIGHT", spacing, 0);
		else
			obj:SetPoint("TOP", _G["ShapeshiftButton"..(i-1)], "BOTTOM", 0, -spacing);
		end
	end
end

local function CT_BottomBar_Shapeshift_HideTextures()
	ShapeshiftBarLeft:Hide();
	ShapeshiftBarMiddle:Hide();
	ShapeshiftBarRight:Hide();
	ShapeshiftBarLeft:SetVertexColor(1,1,1,0);
	ShapeshiftBarMiddle:SetVertexColor(1,1,1,0);
	ShapeshiftBarRight:SetVertexColor(1,1,1,0);
end

local function CT_BottomBar_Shapeshift_Update()
	CT_BottomBar_Shapeshift_HideTextures();

	if (not InCombatLockdown()) then
		ShapeshiftBarFrame:EnableMouse(0);

		CT_BottomBar_Shapeshift_Orientation();
	end
end

local function CT_BottomBar_ShapeshiftBar_Update()
	-- (hook) This function is called after Blizzard's ShapeshiftBar_Update function.
	-- Their function re-anchors ShapeshiftButton1 when the player has only 1 shapeshift form.
	-- That stops us from being able to move the class bar.
	-- We have to undo their anchor and re-establish our own.

	CT_BottomBar_Shapeshift_Update();
end

module:registerAddon(
	"Class Bar",  -- option name & part of frame name
	"Class Bar",  -- shown in options window & tooltips
	"Class Bar",  -- title for horizontal orientation
	"Class",  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -484, 107 },
	{
		-- These classes have this bar and therefore will have this bar enabled in CT_BottomBar by default.
		["perClass"] = {
			["DEATHKNIGHT"] = true,
			["DRUID"] = true,
			["PALADIN"] = true,
			["PRIEST"] = true,
			["ROGUE"] = true,
			["WARRIOR"] = true,
		}
	}, 
	function(self)
		ctClassBar = self;

		local frame = CreateFrame("Frame", "CT_BottomBar_ClassBarFrame");
		frame:SetPoint("TOPLEFT", ShapeshiftButton1);
		frame:SetPoint("BOTTOMRIGHT", ShapeshiftButton10);
		self.helperFrame = frame;

		hooksecurefunc("ShapeshiftBar_Update", CT_BottomBar_ShapeshiftBar_Update);

		hooksecurefunc("UIParent_ManageFramePositions", CT_BottomBar_UIParent_ManageFramePositions);
		-- These are required for Blizzard xml scripts that use this syntax to
		-- call UIParent_ManageFramePositions. This xml syntax does not call our
		-- secure hook of UIParent_ManageFramePositions, so we have to explicitly
		-- hook anything that calls it to ensure our function gets called.
		-- 	<OnShow function="UIParent_ManageFramePositions"/>
		-- 	<OnHide function="UIParent_ManageFramePositions"/>
		ShapeshiftBarFrame:HookScript("OnShow", CT_BottomBar_UIParent_ManageFramePositions);
		ShapeshiftBarFrame:HookScript("OnHide", CT_BottomBar_UIParent_ManageFramePositions);
		PossessBarFrame:HookScript("OnShow", CT_BottomBar_UIParent_ManageFramePositions);
		PossessBarFrame:HookScript("OnHide", CT_BottomBar_UIParent_ManageFramePositions);
		DurabilityFrame:HookScript("OnShow", CT_BottomBar_UIParent_ManageFramePositions);
		DurabilityFrame:HookScript("OnHide", CT_BottomBar_UIParent_ManageFramePositions);
		MainMenuBarMaxLevelBar:HookScript("OnShow", CT_BottomBar_UIParent_ManageFramePositions);
		MainMenuBarMaxLevelBar:HookScript("OnHide", CT_BottomBar_UIParent_ManageFramePositions);
		MultiCastActionBarFrame:HookScript("OnShow", CT_BottomBar_UIParent_ManageFramePositions);
		MultiCastActionBarFrame:HookScript("OnHide", CT_BottomBar_UIParent_ManageFramePositions);
		PetActionBarFrame:HookScript("OnShow", CT_BottomBar_UIParent_ManageFramePositions);
		PetActionBarFrame:HookScript("OnHide", CT_BottomBar_UIParent_ManageFramePositions);
		ReputationWatchBar:HookScript("OnHide", CT_BottomBar_UIParent_ManageFramePositions);

		CT_BottomBar_Shapeshift_Update();

		return true;
	end,
	function(self, orientation)
		CT_BottomBar_Shapeshift_Orientation(orientation);
	end,
	"helperFrame",
	ShapeshiftButton1,
	ShapeshiftButton2,
	ShapeshiftButton3,
	ShapeshiftButton4,
	ShapeshiftButton5,
	ShapeshiftButton6,
	ShapeshiftButton7,
	ShapeshiftButton8,
	ShapeshiftButton9,
	ShapeshiftButton10
);

--------------------------------------------
-- Experience Bar

local function CT_BottomBar_UpdateExpBar(self)
	local frame = self.helperFrame;

	frame:ClearAllPoints();
	frame:SetPoint("TOPLEFT", MainMenuExpBar, 0, 0);
	frame:SetPoint("BOTTOMRIGHT", MainMenuExpBar);
		
	MainMenuExpBar:ClearAllPoints();
	MainMenuExpBar:SetPoint("BOTTOMLEFT", self.frame, 0, 0);
end

module:registerAddon(
	"Experience Bar",  -- option name & part of frame name
	"Experience Bar",  -- shown in options window & tooltips
	"Experience Bar",  -- title for horizontal orientation
	nil,  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -512, 39 },
	nil,
	function(self)
		ctExpBar = self;

		local frame = CreateFrame("Frame", "CT_BottomBar_ExpBarFrame");
		self.helperFrame = frame;

		CT_BottomBar_UpdateExpBar(self);

		MainMenuBarMaxLevelBar:ClearAllPoints();
--		MainMenuBarMaxLevelBar:SetPoint("TOPLEFT", MainMenuExpBar);
		MainMenuBarMaxLevelBar:SetPoint("TOPLEFT", MainMenuExpBar, "TOPLEFT", 0, -11);

		return true;
	end,
	nil,
	"helperFrame",
	MainMenuExpBar,
	MainMenuBarMaxLevelBar,
	ExhaustionTick
);

--------------------------------------------
-- Key Ring

local function CT_BottomBar_MainMenuBar_UpdateKeyRing()
	-- (hook) This is called after Blizzard's MainMenuBar_UpdateKeyRing function.
	if ( GetCVarBool("showKeyring") ) then
		MainMenuBarTexture3:Hide();
		MainMenuBarTexture2:Hide();
		KeyRingButton:Show();
	end
end

module:registerAddon(
	"Key Ring",  -- option name & part of frame name
	"Key Ring",  -- shown in options window & tooltips
	"Key",  -- title for horizontal orientation
	nil,  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 319, 1 },
	nil,
	function(self)
		local frame = CreateFrame("Frame", "CT_BottomBar_KeyRingFrame");
		frame:SetPoint("TOPLEFT", KeyRingButton, 0, 0);
		frame:SetPoint("BOTTOMRIGHT", KeyRingButton);
		self.helperFrame = frame;

		KeyRingButton:ClearAllPoints();
		KeyRingButton:SetPoint("BOTTOMLEFT", self.frame, 0, 0);

		hooksecurefunc("MainMenuBar_UpdateKeyRing", CT_BottomBar_MainMenuBar_UpdateKeyRing);

		return true;		
	end,
	nil,
	"helperFrame",
	KeyRingButton
);

--------------------------------------------
-- Menu Bar

local function CT_BottomBar_MenuBar_UpdateVehicleFrameFix()
	-- Anchor the micro buttons together (in Blizzard's vehicle frame)
	local self = ctMenuBar;
	local frames = self.frames;
	local obj;
	for i = 2, #frames, 1 do
		obj = frames[i];
		obj:Show();
		if i > 2 then
			-- Don't change the Character or Socials MicroButton anchor (already done by Blizzard)
			if ( not (obj == CharacterMicroButton or obj == SocialsMicroButton) ) then
				obj:ClearAllPoints();
				obj:SetPoint("LEFT", frames[i-1], "RIGHT", -3, 0);
			end
		end
	end
end

local function CT_BottomBar_MenuBar_SaveSkinData(skinName)
	CT_BottomBar_MenuBar_UpdateVehicleFrameFix();
	local frames = ctMenuBar.frames;
	for i = 2, #frames do
		CT_BottomBar_Vehicle_SaveBlizzardData(skinName, frames[i]);
	end
end

local function CT_BottomBar_MenuBar_LoadSkinData(skinName)
	if (ctVehicleSaved[skinName]) then
		local frames = ctMenuBar.frames;
		local obj;
		for i = 2, #frames do
			frames[i]:ClearAllPoints();
		end
		for i = 2, #frames do
			CT_BottomBar_Vehicle_LoadBlizzardData(skinName, frames[i], VehicleMenuBarArtFrame);
		end
	end
end

local function CT_BottomBar_MenuBar_UpdateOurFrame(orientation)
	-- Anchor the micro buttons together (in CT_BottomBar's Menu Bar)

	MainMenuBarTexture2:Hide();

	local self = ctMenuBar;
	if (not orientation) then
		orientation = self.orientation;
	end

	local frames = self.frames;
	local obj;
	for i = 2, #frames do
		frames[i]:ClearAllPoints();
	end
	for i = 2, #frames do
		obj = frames[i];
		if (i == 2) then
			obj:SetPoint("BOTTOMLEFT", self.frame, 0, -2);
			obj:SetParent(self.frame);
			obj:Show();
		else
			if ( self.orientation == "ACROSS" ) then
				obj:SetPoint("LEFT", frames[i-1], "RIGHT", -3, 0);
			else
				-- Using a large Y value (23) since the buttons look shorter than they are.
				-- See also the talent and achievement hooked functions for the same Y value.
				obj:SetPoint("TOP", frames[i-1], "BOTTOM", 0, 23);
			end
			obj:SetParent(self.frame);
			obj:Show();
		end
	end
end

local function CT_BottomBar_MenuBar_UpdateVehicleFrame()
	-- Anchor the micro buttons together (in Blizzard's vehicle frame)
	local skinName = VehicleMenuBar.currSkin;
	CT_BottomBar_MenuBar_LoadSkinData(skinName);
end

function CT_BottomBar_MenuBar_Update()
	if (module.isVehicleVisible()) then
		CT_BottomBar_MenuBar_UpdateVehicleFrame();
	else
		CT_BottomBar_MenuBar_UpdateOurFrame();
	end
end

module:registerAddon(
	"Menu Bar",  -- option name & part of frame name
	"Menu Bar",  -- shown in options window & tooltips
	"Menu Bar",  -- title for horizontal orientation
	"Menu",  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 48, 3 },
	nil,
	function(self)
		ctMenuBar = self;

		local frame = CreateFrame("Frame", "CT_BottomBar_MenuBarFrame");
		self.helperFrame = frame;

		local frame = self.helperFrame;
		frame:ClearAllPoints();
		frame:SetPoint("TOPLEFT", CharacterMicroButton, 0, -20);
		frame:SetPoint("BOTTOMRIGHT", HelpMicroButton);

		return true;
	end,
	function(self, orientation)
		if (not module.isVehicleVisible()) then
			CT_BottomBar_MenuBar_UpdateOurFrame(orientation);
		end
	end,
	"helperFrame",
	CharacterMicroButton,
	SpellbookMicroButton,
	TalentMicroButton,
	AchievementMicroButton,
	QuestLogMicroButton,
	SocialsMicroButton,
	PVPMicroButton,
	LFDMicroButton,
	MainMenuMicroButton,
	HelpMicroButton
);


--------------------------------------------
-- MultiCast Bar (Totem bar)

-- knownMultiCastSummonSpells
-- index: TOTEM_MULTI_CAST_SUMMON_SPELLS 
-- value: spellId if the spell is known, nil otherwise
local knownMultiCastSummonSpells = { };
-- knownMultiCastRecallSpells
-- index: TOTEM_MULTI_CAST_RECALL_SPELLS 
-- value: spellId if the spell is known, nil otherwise
local knownMultiCastRecallSpells = { };

function CT_BottomBar_MultiCastSummonSpellButton_Update(self)
	local parent = ctMultiCastBar.frame;

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
			page:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 3);
		end
		MultiCastSlotButton1:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 3);

		MultiCastSummonSpellButton:Show();
	else
		-- reanchor the first slot button take the place of this button
		local xOffset = 3;
		local page;
		for i = 1, NUM_MULTI_CAST_PAGES do
			page = _G["MultiCastActionPage"..i];
			page:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 3);
		end
		MultiCastSlotButton1:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 3);

		MultiCastSummonSpellButton:Hide();
	end

	MultiCastSlotButton1:SetPoint("CENTER", parent, "CENTER", 0, 0);
	MultiCastSlotButton2:SetPoint("CENTER", parent, "CENTER", 0, 0);
	MultiCastSlotButton3:SetPoint("CENTER", parent, "CENTER", 0, 0);
	MultiCastSlotButton4:SetPoint("CENTER", parent, "CENTER", 0, 0);

	MultiCastSummonSpellButton:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 3, 3);
end

function CT_BottomBar_MultiCastRecallSpellButton_Update(self)
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
			self:SetPoint("LEFT", _G["MultiCastSlotButton"..activeSlots], "RIGHT", 8, 0);
			self:SetPoint("BOTTOMLEFT", ctMultiCastBar.frame, "BOTTOMLEFT", 36, 3);
		end

		MultiCastRecallSpellButton:Show();
	else
		self:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 8, 0);
		self:SetPoint("BOTTOMLEFT", ctMultiCastBar.frame, "BOTTOMLEFT", 36, 3);

		MultiCastRecallSpellButton:Hide();
	end
end

local function CT_BottomBar_MultiCast_Orientation()
	if (InCombatLockdown()) then
		return;
	end

	CT_BottomBar_MultiCastSummonSpellButton_Update(MultiCastSummonSpellButton);
	CT_BottomBar_MultiCastRecallSpellButton_Update(MultiCastRecallSpellButton);
end

local function CT_BottomBar_MultiCast_HideTextures()
end

local function CT_BottomBar_MultiCast_Update()
	CT_BottomBar_MultiCast_HideTextures();

	if (not InCombatLockdown()) then
		MultiCastActionBarFrame:EnableMouse(0);

		CT_BottomBar_MultiCast_Orientation();
	end
end

local function CT_BottomBar_MultiCastActionBarFrame_Update(self)
	-- (hook) This function is called after Blizzard's MultiCastActionBarFrame_Update function.

	CT_BottomBar_MultiCast_Update();
end

module:registerAddon(
	"MultiCastBar",  -- option name & part of frame name
	"Totem Bar",  -- shown in options window & tooltips
	"Totem Bar",  -- title for horizontal orientation
	"Totem",  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -486, 149 },
	{
		-- These classes have this bar and therefore will have this bar enabled in CT_BottomBar by default.
		["perClass"] = {
			["SHAMAN"] = true,
		}
	}, 
	function(self)
		ctMultiCastBar = self;

		local frame = CreateFrame("Frame", "CT_BottomBar_MultiCastActionBarFrame");
		frame:SetPoint("TOPLEFT", MultiCastSummonSpellButton);
--		frame:SetPoint("BOTTOMRIGHT", MultiCastRecallSpellButton);
		frame:SetWidth(230);
		frame:SetHeight(30);
		self.helperFrame = frame;

		hooksecurefunc("MultiCastActionBarFrame_Update", CT_BottomBar_MultiCastActionBarFrame_Update);

		CT_BottomBar_MultiCast_Update();

		return true;
	end,
	nil,
	"helperFrame",
	MultiCastActionPage1,
	MultiCastActionPage2,
	MultiCastActionPage3,
	MultiCastSlotButton1,
	MultiCastSlotButton2,
	MultiCastSlotButton3,
	MultiCastSlotButton4,
	MultiCastSummonSpellButton,
	MultiCastRecallSpellButton,
	MultiCastFlyoutFrame
);


--------------------------------------------
-- Pet Bar

local function CT_BottomBar_Pet_Orientation(orientation, spacing)
	if (InCombatLockdown()) then
		return;
	end
	if (not orientation) then
		orientation = ctPetBar.orientation;
	end
	if (not spacing) then
		spacing = module:getOption("petBarSpacing") or 6;
	end

	PetActionButton1:ClearAllPoints();
	PetActionButton1:SetPoint("BOTTOMLEFT", ctPetBar.frame);

	local obj;
	for i = 2, 10, 1 do
		obj = _G["PetActionButton"..i];
		obj:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			obj:SetPoint("LEFT", _G["PetActionButton"..(i-1)], "RIGHT", spacing, 0);
		else
			obj:SetPoint("TOP", _G["PetActionButton"..(i-1)], "BOTTOM", 0, -spacing);
		end
	end
end

local function CT_BottomBar_Pet_HideTextures()
	SlidingActionBarTexture0:Hide();
	SlidingActionBarTexture1:Hide();
end

local function CT_BottomBar_Pet_Update()
	CT_BottomBar_Pet_HideTextures();

	if (not InCombatLockdown()) then
		PetActionBarFrame:EnableMouse(0);

		CT_BottomBar_Pet_Orientation();

		module:update("petBarScale", module:getOption("petBarScale") or 1);
		module:update("petBarSpacing", module:getOption("petBarSpacing") or 6);
	end
end

module:registerAddon(
	"Pet Bar",  -- option name & part of frame name
	"Pet Bar",  -- shown in options window & tooltips
	"Pet Bar",  -- title for horizontal orientation
	"Pet",  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -98, 107 },
	nil,
	function(self)
		ctPetBar = self;

		local frame = CreateFrame("Frame", "CT_BottomBar_PetBarFrame");
		frame:SetPoint("TOPLEFT", PetActionButton1);
		frame:SetPoint("BOTTOMRIGHT", PetActionButton10);
		self.helperFrame = frame;

		module.updatePetBar = function(obj, type, value)
			if ( type == "petBarSpacing" ) then
				self:rotateFunc(self.orientation, value);
				return;
			end

			local func;
			if ( type == "petBarScale" ) then
				if (InCombatLockdown()) then
					return;
				end
				func = PetActionButton1.SetScale;
			elseif ( type == "petBarOpacity" ) then
				func = PetActionButton1.SetAlpha;
			end
			if (func) then
				for i = 1, 10, 1 do
					func(_G["PetActionButton"..i], value);
				end
			end
		end

		CT_BottomBar_Pet_Update();

		return true;
	end,
	function(self, orientation, spacing)
		CT_BottomBar_Pet_Orientation(orientation, spacing);
	end,
	"helperFrame",
	PetActionButton1,
	PetActionButton2,
	PetActionButton3,
	PetActionButton4,
	PetActionButton5,
	PetActionButton6,
	PetActionButton7,
	PetActionButton8,
	PetActionButton9,
	PetActionButton10
);

--------------------------------------------
-- Possess Bar

local function CT_BottomBar_Possess_Orientation(orientation)
	if (InCombatLockdown()) then
		return;
	end
	if (not orientation) then
		orientation = ctPossessBar.orientation;
	end

	PossessButton1:ClearAllPoints();
	PossessButton1:SetPoint("BOTTOMLEFT", ctPossessBar.frame);

	local obj;
	for i = 2, 2, 1 do
		obj = _G["PossessButton"..i];
		obj:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			obj:SetPoint("LEFT", _G["PossessButton"..(i-1)], "RIGHT", 9, 0);
		else
			obj:SetPoint("TOP", _G["PossessButton"..(i-1)], "BOTTOM", 0, -9);
		end
	end
end

local function CT_BottomBar_PossessBar_UpdateState()
	-- Modified version of Blizzard's PossessBar_UpdateState() from BonusActionBarFrame.lua.
	-- They don't always manage to call it to update the possess buttons, so sometimes they
	-- don't appear. I think it has something to do with them not wanting to update the buttons
	-- during the in/out animation of the main menu bar/vehicle menu bars, resulting in the
	-- buttons sometimes not getting updated properly.
	-- This copy of their routine is to allow me to update their state even if Blizzard didn't
	-- manage to get them updated.
	local texture, name;
	local button, background, icon, cooldown;

	for i=1, NUM_POSSESS_SLOTS do
		-- Possess Icon
		button = _G["PossessButton"..i];
		background = _G["PossessBackground"..i];
		icon = _G["PossessButton"..i.."Icon"];
		texture, name, enabled = GetPossessInfo(i);
		icon:SetTexture(texture);

		--Cooldown stuffs
		cooldown = _G["PossessButton"..i.."Cooldown"];
		cooldown:Hide();

		button:SetChecked(nil);
		icon:SetVertexColor(1.0, 1.0, 1.0);

		if ( enabled ) then
			if (not InCombatLockdown()) then
				button:Show();
			end
			button:SetAlpha(1);
			-- background:Show();
			background:Hide();
		else
			if (not InCombatLockdown()) then
				button:Hide();
			else
				button:SetAlpha(0);
			end
			background:Hide();
		end
	end
end

local function CT_BottomBar_Possess_HideTextures()
	PossessBackground1:Hide();
	PossessBackground2:Hide();
end

local function CT_BottomBar_Possess_Update()
	CT_BottomBar_PossessBar_UpdateState();

	if (not InCombatLockdown()) then
		PossessBarFrame:EnableMouse(0);

		CT_BottomBar_Possess_Orientation();
	end
end

local function CT_BottomBar_PossessBar_Update()
	-- (hook) This function is called after Blizzard's PossessBar_Update function.
	CT_BottomBar_Possess_Update();
end

local function CT_BottomBar_PossessBar_UpdateState()
	-- (hook) This function is called after Blizzard's PossessBar_UpdateState function.
	-- We need to hide the textures that Blizzard may have shown.
	CT_BottomBar_Possess_HideTextures();
end

module:registerAddon(
	"Possess Bar",  -- option name & part of frame name
	"Possess Bar",  -- shown in options window & tooltips
	"Possess Bar",  -- title for horizontal orientation
	"Possess",  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 385, 107 },
	nil,
	function(self)
		ctPossessBar = self;

		local frame = CreateFrame("Frame", "CT_BottomBar_PossessBarFrame");
		frame:SetPoint("TOPLEFT", PossessButton1);
		frame:SetPoint("BOTTOMRIGHT", PossessButton2);
		self.helperFrame = frame;

		hooksecurefunc("PossessBar_Update", CT_BottomBar_PossessBar_Update);
		hooksecurefunc("PossessBar_UpdateState", CT_BottomBar_PossessBar_UpdateState);
		hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", CT_BottomBar_MainMenuBarVehicleLeaveButton_Update);

		CT_BottomBar_Possess_Update();

		return true;
	end,
	function(self, orientation)
		CT_BottomBar_Possess_Orientation(orientation);
	end,
	"helperFrame",
	PossessButton1,
	PossessButton2
);

--------------------------------------------
-- Reputation Bar
--

local function CT_BottomBar_AnchorRepToRep()
	local frame = ctRepBar.helperFrame;

	frame:ClearAllPoints();
	ReputationWatchBar:ClearAllPoints();
	CT_BottomBar_PlaceHolderWatchBar:ClearAllPoints();

	frame:SetPoint("TOPLEFT", ReputationWatchBar, 0, 0);
	frame:SetPoint("BOTTOMRIGHT", ReputationWatchBar);

	ReputationWatchBar:SetPoint("BOTTOMLEFT", ctRepBar.frame, 0, 0);
end

local function CT_BottomBar_AnchorRepToExp()
	local frame = ctRepBar.helperFrame;

	frame:ClearAllPoints();
	ReputationWatchBar:ClearAllPoints();
	CT_BottomBar_PlaceHolderWatchBar:ClearAllPoints();

	frame:SetPoint("TOPLEFT", CT_BottomBar_PlaceHolderWatchBar, 0, 0);
	frame:SetPoint("BOTTOMRIGHT", CT_BottomBar_PlaceHolderWatchBar);
	CT_BottomBar_PlaceHolderWatchBar:SetPoint("BOTTOMLEFT", ctRepBar.frame, 0, 0);

	ReputationWatchBar:SetPoint("BOTTOMLEFT", ctExpBar.frame, 0, 2);
end

local function CT_BottomBar_ReputationWatchBar_Update(newLevel)
	--
	-- Note: This function references ctExpBar and ctRepBar.
	--
	local name = GetWatchedFactionInfo();
	if (not name) then
		ReputationWatchStatusBar:SetMinMaxValues(0, 0);
		ReputationWatchStatusBar:SetValue(0);
		ReputationWatchStatusBarText:SetText("");
	end

	ReputationWatchStatusBar:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel()-1);
	if (module:getOption("repBarCoverExpBar")) then
		ReputationWatchStatusBar:SetHeight(12);
		ReputationWatchStatusBarText:SetPoint("CENTER", ReputationWatchBarOverlayFrame, "CENTER", 0, 1);

		CT_BottomBar_AnchorRepToExp();

		ReputationWatchBarTexture0:Hide();
		ReputationWatchBarTexture1:Hide();
		ReputationWatchBarTexture2:Hide();
		ReputationWatchBarTexture3:Hide();

		ReputationXPBarTexture0:Show();
		ReputationXPBarTexture1:Show();
		ReputationXPBarTexture2:Show();
		ReputationXPBarTexture3:Show();

		MainMenuExpBar.pauseUpdates = true;
		MainMenuExpBar:Hide();
	else
		ReputationWatchStatusBar:SetHeight(8);
		ReputationWatchStatusBarText:SetPoint("CENTER", ReputationWatchBarOverlayFrame, "CENTER", 0, 3);

		CT_BottomBar_AnchorRepToRep();

		ReputationWatchBarTexture0:Show();
		ReputationWatchBarTexture1:Show();
		ReputationWatchBarTexture2:Show();
		ReputationWatchBarTexture3:Show();

		ReputationXPBarTexture0:Hide();
		ReputationXPBarTexture1:Hide();
		ReputationXPBarTexture2:Hide();
		ReputationXPBarTexture3:Hide();

		MainMenuExpBar.pauseUpdates = nil;
		MainMenuExpBar:Show();
	end
	if (module:getOption("Reputation Bar")) then
		ReputationWatchBar:Hide();
	else
		if (not name and module:getOption("repBarHideNoRep")) then
			ReputationWatchBar:Hide();
		else
			ReputationWatchBar:Show();
		end
	end
	if (module:getOption("expBarShowMaxLevelBar") and not MainMenuExpBar:IsShown() and not ReputationWatchBar:IsShown()) then
		MainMenuBarMaxLevelBar:Show();
	else
		MainMenuBarMaxLevelBar:Hide();
	end

	UIParent_ManageFramePositions();

	CT_BottomBar_UpdateExpBar(ctExpBar);
end

module:registerAddon(
	"Reputation Bar",  -- option name & part of frame name
	"Reputation Bar",  -- shown in options window & tooltips
	"Reputation Bar",  -- title for horizontal orientation
	nil,  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -512, 49 },
	nil,
	function(self)
		ctRepBar = self;

		local frame = CreateFrame("Frame", "CT_BottomBar_RepBarFrame");
		self.helperFrame = frame;

		frame = CreateFrame("Frame", "CT_BottomBar_PlaceHolderWatchBar");
		frame:SetWidth(ReputationWatchBar:GetWidth());
		frame:SetHeight(ReputationWatchBar:GetHeight());
		frame:SetParent(self.frame);

		CT_BottomBar_AnchorRepToRep();

		hooksecurefunc("ReputationWatchBar_Update", CT_BottomBar_ReputationWatchBar_Update);

		return true;
	end,
	nil,
	"helperFrame",
	ReputationWatchBar
);

--------------------------------------------
-- Vehicle Bar

local function CT_BottomBar_VehicleBar_SaveSkinData(skinName)
	-- ChatFrame1:AddMessage("SaveSkinData " .. tostring(skinName));
	local frames = ctVehicleBar.frames;
	for i = 2, #frames do
		CT_BottomBar_Vehicle_SaveBlizzardData(skinName, frames[i]);
	end
end

local function CT_BottomBar_VehicleBar_LoadSkinData(skinName)
	-- ChatFrame1:AddMessage("LoadSkinData " .. tostring(skinName));
	if (ctVehicleSaved[skinName]) then
		local frames = ctVehicleBar.frames;
		local obj;
		for i = 2, #frames do
			frames[i]:ClearAllPoints();
		end
		for i = 2, #frames do
			CT_BottomBar_Vehicle_LoadBlizzardData(skinName, frames[i], VehicleMenuBar);
		end
	end
end

local function CT_BottomBar_VehicleBar_Orientation(orientation)
	-- ChatFrame1:AddMessage("Orientation " .. tostring(orientation));
	if (not orientation) then
		orientation = ctVehicleBar.orientation;
	end

	local frames = ctVehicleBar.frames;
	local offset;
	local obj;
	for i = 2, #frames do
		obj = frames[i];
		obj:ClearAllPoints();
	end		
	for i = 2, #frames do
		obj = frames[i];
		if ( i == 2) then
			obj:SetPoint("BOTTOMLEFT", ctVehicleBar.frame);
			offset = 10;
		else
			if ( orientation == "ACROSS" ) then
				obj:SetPoint("LEFT", frames[i-1], "RIGHT", offset, 0);
			else
				obj:SetPoint("TOP", frames[i-1], "BOTTOM", 0, -offset);
			end
			offset = 2;
		end
	end
end

local function CT_BottomBar_VehicleBar_UpdateOurFrame()
	-- ChatFrame1:AddMessage("UpdateOurFrame");
	local vb;
	local height = 30;
	local width = 30;
	local parent = CT_BottomBar_VehicleBarFrame;
	local hasVehicleUI = UnitHasVehicleUI("player");

	vb = VehicleMenuBarLeaveButton;
	vb:GetNormalTexture():SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]])
	vb:GetNormalTexture():SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
	vb:GetPushedTexture():SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Exit-Down]])
	vb:GetPushedTexture():SetTexCoord(0.140625, 0.859375, 0.140625, 0.859375)
	vb:SetHeight(height);
	vb:SetWidth(width);
	vb:SetParent(parent);
	if (hasVehicleUI) then
		vb:Show();
	else
		vb:Hide();
	end

	vb = VehicleMenuBarPitchUpButton;
	vb:GetNormalTexture():SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Pitch-Up]])
	vb:GetNormalTexture():SetTexCoord(0.21875, 0.765625, 0.234375, 0.78125)
	vb:GetPushedTexture():SetTexture([[Interface\Vehicles\UI-Vehicles-Button-Pitch-Down]])
	vb:GetPushedTexture():SetTexCoord(0.21875, 0.765625, 0.234375, 0.78125)
	vb:SetHeight(height);
	vb:SetWidth(width);
	vb:SetParent(parent);
	if (hasVehicleUI and VehicleMenuBar.currPitchVisible) then
		vb:Show();
	else
		vb:Hide();
	end

	vb = VehicleMenuBarPitchDownButton;
	vb:GetNormalTexture():SetTexture([[Interface\Vehicles\UI-Vehicles-Button-PitchDown-Up]])
	vb:GetNormalTexture():SetTexCoord(0.21875, 0.765625, 0.234375, 0.78125)
	vb:GetPushedTexture():SetTexture([[Interface\Vehicles\UI-Vehicles-Button-PitchDown-Down]])
	vb:GetPushedTexture():SetTexCoord(0.21875, 0.765625, 0.234375, 0.78125)
	vb:SetHeight(height);
	vb:SetWidth(width);
	vb:SetParent(parent);
	if (hasVehicleUI and VehicleMenuBar.currPitchVisible) then
		vb:Show();
	else
		vb:Hide();
	end

	local frame = ctVehicleBar.helperFrame;
	frame:SetPoint("TOPLEFT", VehicleMenuBarLeaveButton);
	frame:SetPoint("BOTTOMRIGHT", VehicleMenuBarPitchDownButton);
	frame:SetParent(ctVehicleBar.frame);
	frame:Show();

	CT_BottomBar_VehicleBar_Orientation();
end

local function CT_BottomBar_VehicleBar_UpdateVehicleFrame()
	-- ChatFrame1:AddMessage("UpdateVehicleFrame");
	local skinName = VehicleMenuBar.currSkin;
	CT_BottomBar_VehicleBar_LoadSkinData(skinName);
end

function CT_BottomBar_VehicleBar_Update()
	-- ChatFrame1:AddMessage("Update");
	if (module.isVehicleVisible()) then
		CT_BottomBar_VehicleBar_UpdateVehicleFrame();
	else
		CT_BottomBar_VehicleBar_UpdateOurFrame();
	end
end

-- In order to toggle between showing and not showing the Blizzard vehicle
-- frame we need to save information about the position of the micro buttons
-- and the vehicle pitch up, pitch down, and leave buttons.
--
-- A convenient function to hook is VehicleMenuBar_SetSkin.
--
-- One problem with the way this function works is that if they did not
-- specify a relative frame in their SkinsData table, then they default to
-- the button's current parent. This is a problem if we currently have
-- the button parented to our vehicle bar...the game will stop with an
-- error.
--
-- To avoid this problem we have to unparent the buttons and clear their
-- point when we get UNIT_ENTERING_VEHICLE and UNIT_EXITING_VEHICLE events.
-- We can re-establish the values at the end of MainMenuBar_ToVehicleArt
-- and MainMenuBar_ToPlayerArt because by then Blizzard has finished
-- trying to position the buttons.

local function CT_BottomBar_VehicleMenuBar_SetSkin(skinName, pitchVisible)
	-- This is called after Blizzard's VehicleMenuBar_SetSkin function
	-- ChatFrame1:AddMessage("VehicleMenuBar_SetSkin " .. tostring(skinName));
	if (VehicleMenuBar.currSkin) then
		CT_BottomBar_VehicleBar_SaveSkinData(VehicleMenuBar.currSkin);
		CT_BottomBar_MenuBar_SaveSkinData(VehicleMenuBar.currSkin);
	end
end

local function CT_BottomBar_MainMenuBar_ToVehicleArt(self)
	-- This is called after Blizzard's MainMenuBar_ToVehicleArt function
	-- ChatFrame1:AddMessage("MainMenuBar_ToVehicleArt");
	CT_BottomBar_VehicleBar_Update();
	CT_BottomBar_MenuBar_Update();
end

local function CT_BottomBar_MainMenuBar_ToPlayerArt(self)
	-- This is called after Blizzard's MainMenuBar_ToPlayerArt function
	-- ChatFrame1:AddMessage("MainMenuBar_ToPlayerArt");
	CT_BottomBar_VehicleBar_Update();
	CT_BottomBar_MenuBar_Update();
end

module:registerAddon(
	"Vehicle Bar",  -- option name & part of frame name
	"Vehicle Bar",  -- shown in options window & tooltips
	"Vehicle Bar",  -- title for horizontal orientation
	"Vehicle",  -- title for vertical orientation
	{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", 269, 107 },
	nil,
	function(self)
		ctVehicleBar = self;

		local frame = CreateFrame("Frame", "CT_BottomBar_VehicleBarFrame");
		frame:SetPoint("TOPLEFT", VehicleMenuBarLeaveButton);
		frame:SetPoint("BOTTOMRIGHT", VehicleMenuBarPitchDownButton);
		self.helperFrame = frame;

		-- Example of the frame relationships:
		--
		-- CT_BottomBarAddon-Vehicle Bar, ?, nil, ?, ?, ? (parent == UIParent, movable)
		-- 
		-- CT_BottomBar_VehicleBarFrame, TOPLEFT, VehicleMenuBarLeaveButton, TOPLEFT, 0, 0 (parent == CT_BottomBarAddon-Vehicle Bar)
		-- CT_BottomBar_VehicleBarFrame, BOTTOMRIGHT, VehicleMenuBarPitchdownButton, BOTTOMRIGHT, 0, 0 (parent == CT_BottomBarAddon-Vehicle Bar)
		-- 
		-- VehicleMenuBarLeaveButton, BOTTOMLEFT, CT_BottomBarAddon-Vehicle Bar, BOTTOMLEFT, 0, 0 (parent == CT_BottomBar_VehicleBarFrame)
		-- VehicleMenuBarPitchUpButton, LEFT, VehicleMenuBarLeaveButton, RIGHT, 10, 0 (parent == CT_BottomBar_VehicleBarFrame)
		-- VehicleMenuBarPitchDownButton, LEFT, VehicleMenuBarPitchUpButton, RIGHT, 2, 0 (parent == CT_BottomBar_VehicleBarFrame)

		hooksecurefunc("VehicleMenuBar_SetSkin", CT_BottomBar_VehicleMenuBar_SetSkin);
		hooksecurefunc("MainMenuBar_ToVehicleArt", CT_BottomBar_MainMenuBar_ToVehicleArt);
		hooksecurefunc("MainMenuBar_ToPlayerArt", CT_BottomBar_MainMenuBar_ToPlayerArt);

		return true;
	end,
	function(self, orientation)
		CT_BottomBar_VehicleBar_Orientation(orientation);
	end,
	"helperFrame",
	VehicleMenuBarLeaveButton,
	VehicleMenuBarPitchUpButton,
	VehicleMenuBarPitchDownButton
);

-- Frame to handle events for all of the bar addons.
local frame = CreateFrame("Frame", "CT_BottomBar_EventFrame");

frame:RegisterEvent("UNIT_ENTERING_VEHICLE");
frame:RegisterEvent("UNIT_EXITING_VEHICLE");
frame:RegisterEvent("PLAYER_REGEN_ENABLED");
frame:RegisterEvent("PLAYER_REGEN_DISABLED");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("UNIT_ENTERED_VEHICLE");
frame:RegisterEvent("UNIT_EXITED_VEHICLE");
frame:RegisterEvent("UPDATE_BONUS_ACTIONBAR");

-- If you reload the UI while in a vehicle, the PLAYER_ENTERING_VEHICLE and PLAYER_ENTERED_VEHICLE
-- events occur *after* PLAYER_ENTERING_WORLD.
--
-- However, if you /exit and click 'exit now', when you restart the game and log back in,
-- the PLAYER_ENTERING_VEHICLE and PLAYER_ENTERED_VEHICLE events occur *before* PLAYER_ENTERING_WORLD.
--
-- These early entering/entered vehicle events that occur when logging in cause a problem if you had ct_bottombar set to
-- hide the vehicle ui and not hide the bottom bars...  By the time Blizzard finally calls VehicleMenuBar_SetSkin()
-- we have already anchored vehicle buttons to our vehicle bar, which then results in this error message:
-- Framexml\vehicleMenuBar.lua:571: VehicleMenuBarLeaveButton:SetPoint(): CT_BottomBar_VehicleBarFrame is dependent on this.
--
-- To avoid this we have to clear the points on the vehicle buttons before Blizzard can try to 
-- anchor them to their vehicle frame.  The CT_BottomBar_EventFunc() watches for the entering/entered
-- vehicle events happening prior to entering the world, and sets a flag if this is detected.
-- By hooking VehicleMenuBar_ReleaseSkins() and checking for the inWorld and inVehicleBeforeWorld
-- flags we can clear the points on the vehicle buttons just prior to Blizzard anchoring the buttons
-- to their vehicle frame.  Due to other hooks we will reanchor the buttons once Blizzard is done with them.

local inWorld;
local inVehicleBeforeWorld;

local function CT_BottomBar_ClearVehiclePoints()
	-- Clear the anchors on the vehicle buttons that we anchor to our vehicle bar.
	-- This is used to prevent VehicleMenuBar_SetSkin() from causing this error under
	-- two similar conditions, one explained above, and the other explained back where
	-- we hook VehicleMenuBar_SetSkin():
	-- 'VehicleMenuBarLeaveButton:SetPoint(): CT_BottomBar_VehicleBarFrame is dependent on this.'
	local frames = ctVehicleBar.frames;
	for i, frame in ipairs(frames) do
		frame:SetParent(VehicleMenuBar);
		frame:ClearAllPoints();
	end
end

local function CT_BottomBar_VehicleMenuBar_ReleaseSkins()
	-- ChatFrame1:AddMessage("VehicleMenuBar_ReleaseSkins");
	if (inWorld and inVehicleBeforeWorld) then
		-- ChatFrame1:AddMessage("VehicleMenuBar_ReleaseSkins (was in before world)");
		inVehicleBeforeWorld = nil;
		CT_BottomBar_ClearVehiclePoints();
	else
		CT_BottomBar_ClearVehiclePoints();
	end
end
hooksecurefunc("VehicleMenuBar_ReleaseSkins", CT_BottomBar_VehicleMenuBar_ReleaseSkins);

local function CT_BottomBar_EventFunc(self, event, arg1, ...)
		-- ChatFrame1:AddMessage(event .. " " .. tostring(arg1));
		if (event == "UNIT_ENTERED_VEHICLE") then
			-- It is possible to enter one vehicle from another (no exited event appears).
			if (arg1 == "player" ) then
				if (not inWorld) then
					-- This entered vehicle event only occurs before entering the world if you managed to
					-- exit the game while in a vehicle (/exit, exit now), and then log back
					-- in while still in the vehicle.
					inVehicleBeforeWorld = 1;
				end
				module.updateBarVisibility();
			end

		elseif (event == "UNIT_EXITED_VEHICLE") then
			if (arg1 == "player" ) then
				module.updateBarVisibility();
			end

		elseif (event == "UNIT_ENTERING_VEHICLE" or event == "UNIT_EXITING_VEHICLE") then
			-- To prevent issues with Blizzard's VehicleMenuBar_SetSkin we need to
			-- reset the parent and clear the points of the vehicle bar buttons we
			-- are using. We will re-establish control if necessary when Blizzard
			-- is done with them.
			if (arg1 == "player" ) then
				if (not inWorld) then
					-- This entering vehicle event only occurs before entering the world if you managed to
					-- exit the game while in a vehicle (/exit, exit now), and then log back
					-- in while still in the vehicle.
					inVehicleBeforeWorld = 1;
				end
				CT_BottomBar_ClearVehiclePoints();
			end
		elseif (event == "UPDATE_BONUS_ACTIONBAR") then
			module.updateBarVisibility();
		else
			-- PLAYER_REGEN_ENABLED
			-- PLAYER_REGEN_DISABLED
			-- PLAYER_ENTERING_WORLD
			if (event == "PLAYER_ENTERING_WORLD") then
				inWorld = 1;

				if (BonusActionBarFrame:IsShown()) then
					module.showingBonusBar = true;
				else
					module.showingBonusBar = false;
				end
			end

			CT_BottomBar_Action_Update();
			CT_BottomBar_ActionButton_Refresh();
			CT_BottomBar_MultiCast_Update();
			CT_BottomBar_Shapeshift_Update();
			CT_BottomBar_Pet_Update();
			CT_BottomBar_Possess_Update();

			module.updateVehicleVisibility();

			if (event == "PLAYER_REGEN_DISABLED") then
				module.updateBarVisibility(true);
			else
				module.updateBarVisibility();
			end
		end
end

frame:SetScript("OnEvent", CT_BottomBar_EventFunc);
