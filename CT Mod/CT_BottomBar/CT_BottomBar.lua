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

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_BottomBar";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

-- Local copies
local type = type;

module.hideActionUntilBonus = false;

--------------------------------------------
-- Helper Functions

-- Empty function
local function emptyFunc() end

-- Drag Frame
local addonFrameTable;
local function addonDragSkeleton()
	if ( not addonFrameTable ) then
		addonFrameTable = {
			["button#hidden#i:button#st:LOW"] = {
				"backdrop#tooltip#0:0:0:0.5",
				"font#v:GameFontNormalLarge#i:text",
				["onleave"] = module.hideTooltip,
				["onmousedown"] = function(self, button)
					if ( button == "LeftButton" ) then
						if (IsShiftKeyDown()) then
							self.object:resetPosition();
						else
							module:moveMovable(self.movable);
						end
					end
				end,
				["onmouseup"] = function(self, button)
					if ( button == "LeftButton" ) then
						module:stopMovable(self.movable);
					elseif ( button == "RightButton" ) then
						self.object:rotate();
					end
				end,
				["onload"] = function(self)
					self:SetBackdropBorderColor(1, 1, 1, 0);
				end,
				["onenter"] = function(self)
					local object = self.object;
					local text = "|c00FFFFFF"..object.addonName.."|r\n" ..
						"Left click to drag";
					if ( object.rotateFunc ) then
						text = text .. "\nRight click to rotate";
					end
					text = text .. "\nShift click to reset";
					module:displayTooltip(self, text);
				end
			}
		};
	end
	return "frame#s:30:1", addonFrameTable;
end

local function prepareFrame(frame, parent)
	frame:SetParent(parent);
end

local function isDefaultHidden(self)
	local settings = self.settings;
	if ( settings and settings.perClass ) then
		local _, class = UnitClass("player");
		-- If class isn't listed then hide the bar
		if ( not settings.perClass[class] ) then
			-- Don't hide it if we detect a shapeshift form
			if ( GetNumShapeshiftForms() > 0 ) then
				-- Not hidden
				return false;
			end
			-- It should be hidden
			return true;
		end
	end
	-- Not hidden
	return false;
end

--------------------------------------------
-- Addon Handler

local addon = { };
local addonMeta = { __index = addon };

-- List of addons
local addons = { };
module.addons = addons;

function addon:toggleVisibility(mode, show)
	if ( mode == 3 ) then
		local func = MinimapBorder[(show and "Show") or "Hide"];
		local textures = self["textures"];
		if ( type(textures) == "table" ) then
			for key, value in ipairs(textures) do
				func(value);
			end
		elseif ( frames ) then
			func(frames);
		end
	elseif ( mode == 2 ) then
		if ( show ) then
			self.frame.button:Show();
		else
			self.frame.button:Hide();
		end
	elseif ( mode == 1 ) then
		-- show == true if entering combat, else false/nil.
		self:showhide(show);
	end
end

function addon:showhide(enteringCombat)
	-- enteringCombat == true if player is entering combat.

	local frame = self.frame;

	local generalHide = module:getOption(self.name);
	if (generalHide == nil) then
		generalHide = isDefaultHidden(self);
	end
	if (frame.forceHide) then
		generalHide = 1;
	end

	local allowHideShow = true;
	if (self.name == "Action Bar" and module.hideActionUntilBonus) then
		allowHideShow = false;  -- Don't :Hide() or :Show() the main action bar (just do alpha changes)
		if (module.showingBonusBar) then
			generalHide = false;
		end
	end

	local vehicleHideOther = (module:getOption("vehicleHideOther") or 1);  -- Hide other bars when in vehicle
	local inVehicle = module.playerHasVehicleUI();  -- true if player is in a vehicle

	-- Special handling for the action bar
	if (self.name == "Action Bar" and not InCombatLockdown()) then
		-- This is to resolve a problem we had if the user hid the action bar.
		--
		-- Originally we were setting BonusActionBarFrame's parent to CT_BottomBar_BonusActionBarFrame
		--   (whose parent was "CT_BottomBarAddon-Action Bar"...the frame we hide if the user
		--   chooses to hide the action bar).
		-- However, if we parent it that way and the user chooses to hide the action bar,
		--   then the OnUpdate routine of BonusActionBarFrame frame won't get called
		--   since its parent's parent (CT_BottomBarAddon-Action Bar) is hidden.
		-- The OnUpdate function is needed because Blizzard uses a timed animation
		--   system to hide the BonusActionBarFrame.
		-- If the OnUpdate doesn't get executed then the timers won't work, and the
		--   BonusActionBarFrame won't get hidden.
		-- If the BonusActionBarFrame doesn't get hidden when you exit a vehicle,
		--   then it prevents the user from being able to use the buttons (via key
		--   bindings) on page 1 of their hidden action bar.
		--
		-- To avoid the above problem we've created a frame and placed it out of sight.
		-- This out-of-sight frame will always be shown and we'll make it the parent
		--   of the BonusActionBarFrame frame, thus ensuring that the OnUpdate routine
		--   will get called whenever Blizzard has the BonusActionBarFrame frame shown.
		--
		-- To ensure the BonusActionButtons are shown/hid correctly, we'll also need
		--   to change their parent based on whether or not the user chose to hide
		--   the action bar.
		-- If user is not hiding the action bar, then parent the buttons to the default
		--   Blizzard bonus action bar frame. This ensure the buttons will hide/show
		--   when Blizzard hides/shows their bonus action bar frame.
		-- If user is hiding the action bar, then parent the buttons to the on screen
		--   frame we created. This ensures they will be hidden when we hide our on
		--   screen frame.
		--
		local frameParent, buttonParent;
		if (generalHide) then
			-- We are hiding the action bar.
			frameParent = CT_BottomBar_BonusActionBarFrame2;  -- The off screen frame
			buttonParent = CT_BottomBar_BonusActionBarFrame;  -- The on screen frame
		else
			-- We are not hiding the action bar.
			frameParent = CT_BottomBar_BonusActionBarFrame;  -- The on screen frame
			buttonParent = BonusActionBarFrame;  -- The default frame
		end
		-- Set the parent of the BonusActionBarFrame.
		BonusActionBarFrame:SetParent(frameParent);
		BonusActionBarFrame:ClearAllPoints();
		BonusActionBarFrame:SetPoint("TOPLEFT", frameParent, "BOTTOMLEFT");
		BonusActionBarFrame:EnableMouse(0);
		-- Set the parent of the BonusActionButton buttons.
		for i = 1, 12 do
			local obj = _G["BonusActionButton" .. i];
			obj:SetParent(buttonParent);
		end
	end

--[[
	local v,c,l,f,m;
	if (inVehicle) then v = "IV"; else v = "nv"; end
	if (enteringCombat) then c = "IC"; else c = "nc"; end
	if (InCombatLockdown()) then l = "IL"; else l = "nl"; end
	if (frame:IsShown()) then f = "IS"; else f = "ns"; end
	m = v .. " " .. c .. " " .. l .. " [In] " .. f .. " " .. frame:GetAlpha();
]]

	-- Set the appropriate parent frame if needed.
	if (not (InCombatLockdown() and frame:IsProtected()) ) then
		local parent = UIParent;

		if (inVehicle) then
			-- We are in a vehicle.
			if (vehicleHideOther == 1 or vehicleHideOther == 2) then
				-- 1==Hide (method 1) (always parented to MainMenuBar)
				-- 2==Hide (method 2) (parented to MainMenuBar while in vehicle)
				parent = MainMenuBar;
			end
		else
			-- Not in a vehicle.
			if (vehicleHideOther == 1) then
				-- 1==Hide (method 1) (always parented to MainMenuBar)
				parent = MainMenuBar;
			end
		end

		if (frame:GetParent() ~= parent) then
			frame:SetParent(parent);
			if (frame:IsShown()) then
				frame:Show();
			else
				frame:Hide();
			end
		end
	end

	if (not inVehicle or (inVehicle and vehicleHideOther == 4)) then
		-----------
		-- Not in a vehicle, OR
		-- In a vehicle and we don't want to hide the bars when in a vehicle.
		-----------
		-- Show the bar unless user has chosen to hide it.
		if (generalHide) then
			-- Hide the bar
			if (frame:IsProtected()) then
				frame:SetAlpha(0);
				if (not InCombatLockdown()) then
					if (allowHideShow) then
						frame:Hide();
					end
				end
			else
				if (allowHideShow) then
					frame:Hide();
				end
			end
		else
			-- Show the bar
			if (frame:IsProtected()) then
				frame:SetAlpha(1);
				if (not InCombatLockdown()) then
					if (allowHideShow) then
						frame:Show();
					end
				end
			else
				if (allowHideShow) then
					frame:Show();
				end
			end
		end
	else
		-----------
		-- In a vehicle and we want to hide the bars when in a vehicle.
		-----------
		if (frame:IsProtected()) then
			-- If we are entering combat..
			if (enteringCombat) then
				-- Rather than hiding the bar, show it and make it invisible.
				-- This way if we exit the vehicle before leaving combat,
				-- then all we need to do to see the bar is adjust the alpha.
				frame:SetAlpha(0);
				if (not InCombatLockdown()) then
					-- There is one exception to the above rule that we can make..

					-- If the player doesn't want to see the bar outside a vehicle,
					-- then we can do a :Hide() for them. The only small risk is if
					-- the player decides to go into the options during the
					-- in-vehicle combat and changes the setting so that the bar shows
					-- when outside a vehicle. Then, if they don't end combat before
					-- exiting the vehicle, the bar will not be seen between the time
					-- they exit the vehicle and combat ends.

					-- Examine the general 'hide' setting..
					if (generalHide) then
						-- Since the player doesn't want to see the bar when not in
						-- the vehicle, :Hide() it for them.
						if (allowHideShow) then
							frame:Hide();
						end
					else
						-- The user does want to see the bar when not in the vehicle,
						-- so we need to :Show() it to them using 0 alpha in case they
						-- exit the vehicle before combat ends. That way we will be
						-- able to set the alpha back to 1 so they can see the bar
						-- between exiting the vehicle and ending combat.
						if (allowHideShow) then
							frame:Show();
						end
					end
				end
			else
				-- Not entering combat.
				frame:SetAlpha(0);
				if (not InCombatLockdown()) then
					if (allowHideShow) then
						frame:Hide();
					end
				end
			end
		else
			if (allowHideShow) then
				frame:Hide();
			end
		end
	end

--	if (frame:IsShown()) then f = "IS"; else f = "ns"; end
--	m = m .. " [Out] " .. f .. " " .. frame:GetAlpha() .. " " .. self.name;
--	ChatFrame1:AddMessage(m);

end

function addon:rotate()
	if ( not self.rotateFunc ) then
		return;
	end
	if ( InCombatLockdown() and self.frame:IsProtected() ) then
		return;
	end
	local newOrientation = "ACROSS";
	if ( self.orientation == "ACROSS" ) then
		self.orientation = "DOWN";
		newOrientation = "DOWN";
	else
		self.orientation = "ACROSS";
	end
	module:setOption("orientation"..self.name, newOrientation, true);
	self:rotateFunc(newOrientation);
	self:update();
end

function addon:position()
	local frame = self.frames;
	if ( not frame[0] ) then
		frame = frame[1];
	end
	if ( InCombatLockdown() and frame:IsProtected() ) then
		return;
	end
	frame:ClearAllPoints();
	frame:SetPoint("BOTTOMLEFT", self.frame);
end

function addon:resetPosition()
	if ( InCombatLockdown() and self.frame:IsProtected() ) then
		return;
	end
	local defaults = self.defaults;
	local frame = self.frame;
	local yoffset = (defaults[5] or 0);
	if (TitanMovable_GetPanelYOffset and TITAN_PANEL_PLACE_BOTTOM and TitanPanelGetVar) then
		yoffset = yoffset + (tonumber( TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars")) ) or 0);
	end
	frame:ClearAllPoints();
	frame:SetPoint(defaults[1], UIParent, defaults[3], defaults[4], yoffset);
	if ( self.rotateFunc ) then
		local newOrientation = "ACROSS";
		self.orientation = newOrientation;
		module:setOption("orientation"..self.name, newOrientation, true);
		self:rotateFunc(newOrientation);
		self:update();
	end
	module:stopMovable(self.name);
end

function addon:update()
	local button = self.frame.button;
	if ( button ) then
		local orientation = self.orientation;
		local text = button.text;
		
		text:ClearAllPoints();
		if ( orientation == "ACROSS" ) then
			text:SetText(self.acrossName);
			text:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 10, -11);
		else
			text:SetText(self.downName);
			text:SetPoint("BOTTOM", button, "TOP", 0, -11);
		end
	end
end

function addon:init()
	local frames = self.frames;	
	if ( frames ) then
		local name = self.name;
		local frame = self.frame;
		local button = frame.button;

		if ( not self.skipDefaultPosition ) then
			self:position();
		end
		
		local defaults = self.defaults;
		if ( defaults ) then
			frame:ClearAllPoints();
			frame:SetPoint(unpack(defaults));
		end
		
		button.object = self;
		button.movable = name;

		-- Existing users (CT_BottomBar 3.003 and earlier) have drag
		-- frames relative to MainMenuBar or MainMenuBarArtFrame.
		--
		-- This changes the relative frame to UIParent to match what
		-- CT_BottomBar 3.004 is using. This avoids problems when
		-- entering a vehicle. Unlike MainMenuBar, UIParent does not
		-- move when you enter a vehicle.
		--
		-- Being relative to the bottom of MainMenuBar causes problems
		-- when you enter a vehicle and Blizzard moves MainMenuBar -130
		-- units below the bottom of UIParent. If the user wanted to
		-- show the bars while in a vehicle, then most of them would
		-- shift down and not be visible when Blizzard repositioned
		-- MainMenuBar.
		local movName = "MOVABLE-" .. name;
		local movOpt = module:getOption(movName);
		if (movOpt and (movOpt[2] == "MainMenuBar" or movOpt[2] == "MainMenuBarArtFrame")) then
			movOpt[2] = "UIParent";
			module:setOption(movName, movOpt, true);
		end

		-- Register the drag frame as movable (also repositions
		-- the frame if it was previously moved by the user).
		module:registerMovable(name, frame);

		-- Keep our frames from moving anywhere we don't want them!
		local guideFrame;
		if ( frames[0] ) then
			guideFrame = frames;
			prepareFrame(frames, frame);
		else
			for key, value in ipairs(frames) do
				prepareFrame(value, frame);
			end
			guideFrame = frames[1];
		end
		
		button:SetPoint("TOPLEFT", guideFrame, -11, 11);
		button:SetPoint("BOTTOMRIGHT", guideFrame, 11, -11);

		local settings = self.settings or {};
		local defaultOrientation = (settings.orientation or "ACROSS");

		local orientation = module:getOption("orientation"..name) or defaultOrientation;
		local func = self.rotateFunc;
		
		self.orientation = orientation;
		if ( func ) then
			func(self, orientation);
		end
	end
	
	self:update();
end

--------------------------------------------
-- Bar visibility

local function updateBarVisibility(enteringCombat)
	for key, value in ipairs(addons) do
		value:toggleVisibility(1, enteringCombat);
	end
end
module.updateBarVisibility = updateBarVisibility;

--------------------------------------------
-- Vehicle visibility

local function getVehicleState()
	local ctVehicleState;
	-- nil == no vehicle
	-- 1   == vehicle is not visible
	-- 2   == vehicle is visible
	if (UnitHasVehicleUI("player")) then
		-- Vehicle artwork is in place
		if (VehicleMenuBar:GetParent() == MainMenuBar) then
			-- Vehicle is parented to the main menu (user wanted to hide vehicle frame).
			ctVehicleState = 1;  -- vehicle is not visible
		else
			ctVehicleState = 2;  -- vehicle is visible
		end
	end
	return ctVehicleState;
end
module.getVehicleState = getVehicleState;

local function playerHasVehicleUI()
	return getVehicleState() ~= nil;
end
module.playerHasVehicleUI = playerHasVehicleUI;

local function isVehicleVisible()
	return getVehicleState() == 2;
end
module.isVehicleVisible = isVehicleVisible;

local function isVehicleHidden()
	return getVehicleState() == 1;
end
module.isVehicleHidden = isVehicleHidden;

local function updateVehicleVisibility()
	if (InCombatLockdown()) then
		return;
	end
	local hideVehicle = module:getOption("vehicleHideFrame");
	if (UnitHasVehicleUI("player")) then
		if (hideVehicle) then
			-- We want to hide Blizzard's vehicle frame.
			-- Parent the vehicle menu bar to the main menu bar so that
			-- it will get hidden when Blizzard hides the MainMenuBar frame.
			VehicleMenuBar:SetParent(MainMenuBar);
		else
			-- Restore the original parent for the vehicle menu bar.
			VehicleMenuBar:SetParent(UIParent);
			VehicleMenuBar:Show();
		end
	else
		-- No vehicle artwork is in place.
		if (hideVehicle) then
			VehicleMenuBar:SetParent(MainMenuBar);
		else
			VehicleMenuBar:SetParent(UIParent);
		end
	end
	CT_BottomBar_MenuBar_Update();
	CT_BottomBar_VehicleBar_Update();
end
module.updateVehicleVisibility = updateVehicleVisibility;

--------------------------------------------
-- Hide Gryphons

local gryphonLoop;

local function toggleGryphons(hide)
	if (gryphonLoop) then
		-- Prevent infinite loop.
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
	if (type(module.frame) == "table") then
		-- Change the checkbox in CT_BottomBar
		local cb = module.frame.section1.hideGryphons;
		cb:SetChecked(hide);
	end
	if (CT_Core) then
		local opt = "hideGryphons";
		if (CT_Core:getOption(opt) ~= module:getOption(opt)) then
			-- Change the same option in CT_Core
			gryphonLoop = true;
			CT_Core:setOption(opt, hide, true);
			gryphonLoop = nil;
		end
	end
end

--------------------------------------------
-- Addon Registrar

function module:registerAddon(name, addonName, acrossName, downName, defaults, settings, initFunc, rotateFunc, ...)
	local new = { };
	new.name = name;  -- Name used in drag frame name, to access option value, etc.
	new.addonName = (addonName or name);  -- Name shown in options window and tooltip.
	new.acrossName = (acrossName or name);  -- Name shown above bar when in 'across' orientation.
	new.downName = (downName or name);  -- Name shown above bar when in 'down' orientation.
	new.defaults = defaults;
	new.settings = settings;
	new.rotateFunc = rotateFunc;
	
	-- Store our frames & textures
	local index = 1;
	if ( ( (select(index, ...)) or "" ) ~= "" ) then
		-- Add a drag frame only if we have frame
		local frame = module:getFrame(addonDragSkeleton, nil, "CT_BottomBarAddon-"..name);
		new.frame = frame;
	end
	
	if ( initFunc ) then
		new.skipDefaultPosition = initFunc(new);
	end
	
	local key = "frames";
	local value;
	for i = index, select('#', ...), 1 do
		value = select(i, ...);
		if ( value == "" ) then
			-- Constitutes change to textures
			key = "textures";
		else
			if ( type(value) == "string" ) then
				value = new[value];
			end
			
			-- Add our value
			if ( not new[key] ) then
				new[key] = value;
			elseif ( new[key][0] ) then
				new[key] = { new[key], value };
			else
				tinsert(new[key], value);
			end
		end
	end
	
	setmetatable(new, addonMeta);
	tinsert(addons, new);
	return new;
end

--------------------------------------------
-- Slash command.

local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctbb", "/ctbottom", "/ctbottombar");

----------------------------------------------

local function updateMainBar(obj, type, value)
	if (module.updateMainBar) then
		for key, f in ipairs(module.updateMainBar) do
			f(obj, type, value);
		end
	end
end

module.update = function(self, type, value)
	if ( type == "init" ) then
		for key, value in ipairs(addons) do
			value:init();
			value:toggleVisibility(1);
		end

		updateMainBar(self, "barScale", self:getOption("barScale") or 1);
		updateMainBar(self, "barOpacity", self:getOption("barOpacity") or 1);
		updateMainBar(self, "barSpacing", self:getOption("barSpacing") or 6);
		updateMainBar(self, "barHideGrid", self:getOption("barHideGrid") or 1);
		
		self:updatePetBar("petBarScale", self:getOption("petBarScale") or 1);
		self:updatePetBar("petBarOpacity", self:getOption("petBarOpacity") or 1);
		self:updatePetBar("petBarSpacing", self:getOption("petBarSpacing") or 6);
	else
		if ( type == "barScale" or type == "barOpacity" or type == "barSpacing" or type == "barHideGrid") then
			updateMainBar(self, type, value);
			return;

		elseif ( type == "petBarScale" or type == "petBarOpacity" or type == "petBarSpacing" ) then
			self:updatePetBar(type, value);
			return;

		elseif ( type == "vehicleHideFrame" ) then
			updateVehicleVisibility();
			updateBarVisibility();

		elseif ( type == "vehicleHideOther" ) then
			for key, val in ipairs(addons) do
				val:toggleVisibility(1);
			end
			return;

		elseif ( type == "repBarHideNoRep" or type == "repBarCoverExpBar" or type == "expBarShowMaxLevelBar" ) then
			ReputationWatchBar_Update();

		elseif ( type == "hideGryphons" ) then
			toggleGryphons(value);

		else
			-- Show/hide bar
			for key, val in ipairs(addons) do
				if ( val.name == type ) then
					val:toggleVisibility(1);
					break;
				end
			end
			if (type == "Reputation Bar" or type == "Experience Bar") then
				ReputationWatchBar_Update();
			end
		end
	end
end

-- Options Frame
local function showModules(self)
	for key, value in ipairs(addons) do
		value:toggleVisibility(2, true);
	end
	if ( self and CT_BarMod and CT_BarMod.show ) then
		CT_BarMod.show();
	end
end

local function hideModules(self)
	for key, value in ipairs(addons) do
		value:toggleVisibility(2, false);
	end
	if ( self and CT_BarMod and CT_BarMod.hide ) then
		CT_BarMod.hide();
	end
end

module.show = showModules;
module.hide = hideModules;

local function resetBarPositions()
	if ( InCombatLockdown() and self.frame:IsProtected() ) then
		return;
	end
	for key, value in ipairs(addons) do
		value:resetPosition();
	end
end

module.frame = function()
	local yoffset, ysize;
	local count;
	local toptions, toffset;

	local options = {
		["onshow"] = showModules,
		["onhide"] = hideModules,
	};

	yoffset = 5;

	-- Tips
	ysize = 70;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Tips",
		"font#t:0:-25#s:0:30#l:13:0#r#You can use /ctbb, /ctbottom, or /ctbottombar to open this options window directly.#0.6:0.6:0.6:l",
	};
	yoffset = yoffset + ysize;

	-- General Options
	toptions = {};
	tinsert(toptions, "font#tl:5:0#v:GameFontNormalLarge#General Options");
	toffset = 20;

	tinsert(toptions, "checkbutton#i:hideGryphons#tl:20:-".. toffset .."#o:hideGryphons#Hide the Main Bar gryphons");
	toffset = toffset + 20;

	count = 0;
	for key, value in ipairs(addons) do
		if ( value.frames ) then
			count = count + 1;
			tinsert(toptions, "checkbutton#tl:20:-"..(toffset + ((count - 1) * 20)).."#o:"..value.name..
				((isDefaultHidden(value) and ":true") or "").."#Hide the "..value.addonName);
		end
	end
	toffset = toffset + ((count - 1) * 20) + 30;

	toptions["button#t:0:-" .. toffset .. "#s:170:30#v:GameMenuButtonTemplate#Reset positions"] = {
			["onclick"] = function(self)
				resetBarPositions();
			end
	};
	toffset = toffset + 30;

	tinsert(toptions, "font#t:0:-" .. toffset .. "#s:0:40#l#r#Note: This will reset the bars to their default positions without reloading your UI.#0.5:0.5:0.5");
	toffset = toffset + 40;

	options["frame#i:section1#tl:0:-"..(yoffset).."#r"] = toptions;
	yoffset = yoffset + toffset + 15;

	-- Reputation/Experience Bar Options
	options["frame#tl:0:-"..(yoffset).."#r"] = {
		"font#tl:5:0#v:GameFontNormalLarge#Reputation/Experience Bar Options",
		"checkbutton#tl:20:-20#o:repBarHideNoRep#Hide rep bar when not monitoring a reputation.",
		"checkbutton#tl:20:-40#o:repBarCoverExpBar#Replace the exp bar with the rep bar.",
		"checkbutton#tl:20:-60#o:expBarShowMaxLevelBar#Show solid exp bar if no rep and exp bars.",
		"font#t:0:-90#s:0:60#l#r#Note 1:  If you are using the game's standard action bars, the game will shift them up/down in response to the showing/hiding of the rep and exp bars.#0.5:0.5:0.5",
		"font#t:0:-150#s:0:60#l#r#Note 2:  Enabling all 3 options emulates the game's behavior for a maximum level character (but works at any level) as long as the hide rep bar and hide exp bar options are disabled.#0.5:0.5:0.5",
	};
	yoffset = yoffset + 220;

	-- Action Bar Options
	options["frame#tl:0:-"..(yoffset).."#r"] = {
		"font#tl:5:0#v:GameFontNormalLarge#Action Bar Options",
		"slider#t:0:-35#o:barScale:1#i:scale#s:175:17#Scale - <value>#0.25:2:0.05",
		"slider#t:0:-70#o:barOpacity:1#i:opacity#s:175:17#Opacity - <value>#0:1:0.05",
		"slider#t:0:-105#o:barSpacing:6#i:spacing#s:175:17#Button Spacing - <value>#0:25:1",
		"checkbutton#tl:20:-140#o:barHideGrid#Hide the empty button grid.",
	};
	yoffset = yoffset + 185;

	-- Pet Bar Options
	options["frame#tl:0:-"..(yoffset).."#r"] = {
		"font#tl:5:0#v:GameFontNormalLarge#Pet Bar Options",
		"slider#t:0:-35#o:petBarScale:1#i:scale#s:175:17#Scale - <value>#0.25:2:0.05",
		"slider#t:0:-70#o:petBarOpacity:1#i:opacity#s:175:17#Opacity - <value>#0:1:0.05",
		"slider#t:0:-105#o:petBarSpacing:6#i:spacing#s:175:17#Button Spacing - <value>#0:25:1",
	};
	yoffset = yoffset + 150;

	-- Vehicle Frame Options
	options["frame#tl:0:-"..(yoffset).."#r"] = {
		"font#tl:5:0#v:GameFontNormalLarge#Vehicle Options",
		"checkbutton#tl:17:-20#o:vehicleHideFrame#Hide the standard vehicle frame.",
		"font#tl:20:-50#v:ChatFontNormal#CT_BottomBar bars:",
		"dropdown#n:CT_BottomBarDropdown1#tl:130:-50#o:vehicleHideOther#Hide (method 1)#Hide (method 2)#Make invisible#Do not hide",
		"font#t:0:-80#s:0:70#l#r#Note 1:  'Hide (method 1)' will hide the bars even if you are in combat when you enter a vehicle. (Recommended unless you have an addon that tries to keep the game's MainMenuBar frame hidden all the time)#0.5:0.5:0.5",
		"font#t:0:-160#s:0:70#l#r#Note 2:  'Hide (method 2)' will hide the bars once you are out of combat. Until then they will be made invisible. (Recommended if 'Hide (method 1)' does not work for you)#0.5:0.5:0.5",
		"font#t:0:-228#s:0:90#l#r#Note 3:  'Invisible' bars cannot be seen, but due to combat restrictions their buttons may be clickable until you are out of combat.  Invisible bars will be hidden when possible.  The buttons on hidden bars cannot be clicked.#0.5:0.5:0.5",
	};
	yoffset = yoffset + 330;

	-- Reset Options
	options["frame#tl:0:-"..(yoffset).."#r"] = {
		"font#tl:5:0#v:GameFontNormalLarge#Reset Options",
		"checkbutton#tl:20:-20#o:resetAll#Reset options for all of your characters",
		["button#t:0:-50#s:120:30#v:UIPanelButtonTemplate#Reset options"] = {
			["onclick"] = function(self)
				if (module:getOption("resetAll")) then
					CT_BottomBarOptions = {};
				else
					if (not CT_BottomBarOptions or not type(CT_BottomBarOptions) == "table") then
						CT_BottomBarOptions = {};
					else
						CT_BottomBarOptions[module:getCharKey()] = nil;
					end
				end
				ConsoleExec("RELOADUI");
			end
		},
		"font#t:0:-80#s:0:40#l#r#Note: This will reset options and bar positions to default and then reload your UI.#0.5:0.5:0.5",
	};

	return "frame#all", options;
end
