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

--------------------------------------------
-- Group Management

local groupList = { };
local group = { };
local groupMeta = { __index = group };
module.groupList = groupList;

local function getGroup(id)
	local num = module.GroupIdToNum(id);
	return groupList[num] or group:new(id);
end

local dragOnTop = false;
local groupFrameTable;
local function groupFrameSkeleton()
	-- Frame used to anchor the first action button to.
	if ( not groupFrameTable ) then
		groupFrameTable = {
			-- Frame used to allow dragging of the action buttons.
			["button#hidden#i:button#st:LOW"] = {
				"backdrop#tooltip#0:0:0.5:0.85",
				"font#v:GameFontNormalLarge#i:text",
				["onleave"] = module.hideTooltip,
				["onmousedown"] = function(self, button)
					if ( button == "LeftButton" ) then
						module:moveMovable(self.movable);
					end
				end,
				["onmouseup"] = function(self, button)
					if ( button == "LeftButton" ) then
						if ( IsShiftKeyDown() ) then
							self.object:resetPosition();
						else
							module:stopMovable(self.movable);
						end
					elseif ( button == "RightButton" ) then
						self.object:rotate();
						-- Update some stuff on the options window
						module.updateGroupWidgets_Orientation(self.object.id);
						module.updateGroupWidgets_Columns(self.object.id);
					end
				end,
				["onload"] = function(self)
					self:SetBackdropBorderColor(1, 1, 1, 0);
				end,
				["onenter"] = function(self)
					if (not module:getOption("dragHideTooltip")) then
						local text = "|c00FFFFFF" .. self.object.fullName .. "|r\n" ..
							"Left click to drag\n" ..
							"Right click to rotate\n" ..
							"Shift click to reset";
						module:displayTooltip(self, text);
					end
				end
			}
		};
	end
	return "frame#s:60:30", groupFrameTable;  -- width=60, height=30
end

-- Existing CT_BarMod_GroupNN frames are 60 wide.
-- The first button was positioned TOP relative to the frame (ie. centered).
-- Now that we're positioning TOPLEFT relative to the frame,
-- we'll use the following offset when positioning the first button so that
-- existing users' bars will be in the same place.
local firstButtonOffset = 12;

local function checkMouseover(elapsed)
	for i, group in pairs(groupList) do
		if (group.barMouseover) then
			if (group.overlay:IsMouseOver()) then
				-- Mouse is over the frame
				if (group.hideFlag) then
					module:unschedule(group.hideFunc);
					group.hideFlag = false;
				end
				if (not group.mouseover) then
					-- Mouse has just entered the frame
					if (not group.showFlag) then
						module:schedule(group.showTimer, group.showFunc);
						group.showFlag = true;
					end
				end
			else
				-- Mouse is not over the frame
				if (group.showFlag) then
					module:unschedule(group.showFunc);
					group.showFlag = false;
				end
				if (group.mouseover) then
					-- Mouse was previously over the frame
					if (not group.hideFlag) then
						module:schedule(group.hideTimer, group.hideFunc);
						group.hideFlag = true;
					end
				end
			end
		end
	end
end
module.checkMouseover = checkMouseover;

local function setDragOnTop(onTop)
	-- Show group drag frames on top or behind the action buttons.
	if (onTop) then
		dragOnTop = true;
	else
		dragOnTop = false;
	end
	for i, group in pairs(groupList) do
		local button = group.frame.button;
		group:updateButtonPosition();
		if (dragOnTop) then
			button:SetFrameLevel(button.originalLevel + 2);
		else
			button:SetFrameLevel(button.originalLevel)
		end
		group:updateOverlayPosition();
	end
end
module.setDragOnTop = setDragOnTop;

-- Group Class
local firstTime;
function group:new(id)
	local group = { };
	local frame = module:getFrame(groupFrameSkeleton, UIParent, "CT_BarMod_Group" .. id);  -- skeleton, parent, name
	frame.button:SetHitRectInsets(5, 5, 5, 5);
	frame.button:SetParent(UIParent);
	frame.button:SetBackdropColor(0, 0, 0.5, 0.85);
	frame.button.originalLevel = frame.button:GetFrameLevel();
	if (dragOnTop) then
		frame.button:SetFrameLevel(frame.button:GetFrameLevel()+2);
	end
	local movable = "GROUP"..id;
	setmetatable(group, groupMeta);
	
	group.orientation = module:getOption("orientation"..id);
	group.frame = frame;
	group.id = id;
	group.movable = movable;
	group.num = module.GroupIdToNum(id);

	-- .fullName is used in drag frame tooltip, and in keybindings section.
	-- .longName is displayed on bar.
	-- .shortName is displayed on bar.
	if (group.id == module.controlBarId) then
		group.fullName = "Control bar";
		group.longName = "Control";
		group.shortName = "Ctl";
	else
		group.fullName = "Bar " .. group.num;
		group.longName = "Bar " .. group.num;
		group.shortName = "B" .. group.num;
	end

	group.barColumns = 1; -- Desired number of columns (across) or rows (down). Init to 1.
	group.numColumns = 1; -- Actual number of columns (across) or rows (down). Init to 1.
	group.numRows = 1;  -- Actual number of rows (across) or columns (down). Init to 1.

	-- Do the following option tests and sets before we add the group to the groupList table.

	if (module:getOption("orientation" .. id) == nil) then
		-- This character does not have a value assigned to this option yet.
		-- If this is not one of the original 5 bars (ids 1 through 5),
		-- then initially hide this group so that it does not appear in the middle
		-- of the user's screen. They can toggle it on via the CT_BarMod options.
		if (id >= 6) then
			module:setOption("showGroup" .. id, false, true);
		end
	end

	if (module:getOption("barHideInVehicle" .. id) == nil) then
		-- This character does not have a value assigned to this option yet.
		-- This option was added in 3.304 to replace an existing vehicleHideOther option.
		-- Initialize the new option to the same setting as the old option.
		local hide = module:getOption("vehicleHideOther"); -- default was 1, 1=hide, 2=hide, 3=hide, 4=show
		if (hide ~= nil) then
			if (hide == 4) then
				hide = false;
			else
				hide = 1;
			end
			module:setOption("barHideInVehicle" .. id, hide, true);
		end
	end

	if (module:getOption("stdPositions") == nil) then
		-- If this option is nil, then this is a new character,
		-- or an existing character's first time for this option.
		if (module:getOption("orientation1") == nil) then
			-- New character
			local newPositions = module:getOption("newPositions");
			if (newPositions == nil) then
				-- Default to using the standard bar positions.
				newPositions = true;
			end
			module:setOption("stdPositions", newPositions, true);
		else
			-- Existing character's first time for this option.
			-- Default to the original CT_BarMod positions value (false) since
			-- those would be the bar positions that they have been using.
			module:setOption("stdPositions", false, true);
		end
		firstTime = true;
	end

	group:position(group.orientation, module:getOption("stdPositions"));
	groupList[group.num] = group;
	
	local button = frame.button;
	button.movable = movable;
	button.object = group;
	module:registerMovable(movable, frame);

	-- Create an invisible frame and overlay it on the frame used to drag the bar group.
	-- This will allow us to detect OnEnter and OnLeave events when the drag frame is not visible.
	local f = CreateFrame("Frame", "CT_BarMod_Group" .. id .. "Frame", frame);

	group.overlay = f;
	group:updateOverlayPosition();

	f:SetHitRectInsets(10, 10, 10, 10);
	f:Show();
	f.id = id;

	group.mouseover = false;
	group.hideFlag = false;
	group.showFlag = false;
	group.hideTimer = 0;
	group.showTimer = 0;

	group.hideFunc = function()
		group.hideFlag = false;
		group.mouseover = false;
		group:updateOpacity();
	end

	group.showFunc = function()
		group.showFlag = false;
		group.mouseover = true;
		group:updateOpacity();
	end

	return group;
end

function group:updateOpacity()
	self:update("barFaded", module:getOption("barFaded" .. self.id) or 0);
	self:update("barOpacity", module:getOption("barOpacity" .. self.id) or 1);
end

function group:updateOverlayPosition()
	local f = self.overlay;
	local frame = self.frame;
	f:ClearAllPoints();
	if (dragOnTop) then
		f:SetPoint("TOPLEFT", frame.button, "TOPLEFT", 8, -8);
		f:SetPoint("BOTTOMRIGHT", frame.button, "BOTTOMRIGHT", -8, 8);
	else
		f:SetPoint("TOPLEFT", frame.button, "TOPLEFT", 11, -11);
		f:SetPoint("BOTTOMRIGHT", frame.button, "BOTTOMRIGHT", -11, 11);
	end
	f:SetFrameLevel(f:GetParent():GetFrameLevel());
end

local defaultPositions = {};

-- These are the original bar positions used by CT_BarMod.
--   Bar  4 = LE = Left
--   Bar  2 = BL = Bottom left
--   Bar  3 = BR = Bottom right
--   Bar  6 = IR = Inside right
--   Bar  5 = OR = Outside right
--   Bar  7 = BC = Bottom center (lowest)
--   Bar  8 = LC = Lower center
--   Bar  9 = UC = Upper center
--   Bar 10 = TC = Top center
--   Bar  1 = AC = Above center
--   Bar 11 = OC = Over center (highest)
--
-- Secondary index is the bar id.
defaultPositions[1] = {
	[10] = {"BOTTOMLEFT",  "BOTTOM",      -260, 560, "ACROSS", "AC"},  -- Bar  1, Above center
	[1]  = {"BOTTOMLEFT",  "BOTTOM",      -516,  97, "ACROSS", "BL"},  -- Bar  2, Bottom left
	[2]  = {"BOTTOMLEFT",  "BOTTOM",        -6,  97, "ACROSS", "BR"},  -- Bar  3, Bottom right
	[3]  = {"BOTTOMLEFT",  "TOPLEFT",      -10, -85, "DOWN",   "LE"},  -- Bar  4, Left
	[4]  = {"BOTTOMRIGHT", "BOTTOMRIGHT",   12, 603, "DOWN",   "OR"},  -- Bar  5, Outside right
	[5]  = {"BOTTOMRIGHT", "BOTTOMRIGHT",  -31, 603, "DOWN",   "IR"},  -- Bar  6, Inside right
	[6]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 300, "ACROSS", "BC"},  -- Bar  7, Bottom center
	[7]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 365, "ACROSS", "LC"},  -- Bar  8, Lower center
	[8]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 430, "ACROSS", "UC"},  -- Bar  9, Upper center
	[9]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 495, "ACROSS", "TC"},  -- Bar 10, Top center
	[11] = {"BOTTOMLEFT",  "BOTTOM",      -260, 625, "ACROSS", "OC"},  -- Bar 11, Over center
};

-- The following standard (Blizzard) bar positions reorganize the groups
-- so that the bar contents match the bars that Blizzard places in the
-- same screen locations. This makes it easier to switch between using CT_BottomBar
-- and the default Blizzard bars since the icons on the bars will be the same.
--   Bar  2 = LE = Left
--   Bar  6 = BL = Bottom left
--   Bar  5 = BR = Bottom right
--   Bar  4 = IR = Inside right
--   Bar  3 = OR = Outside right
--   Bar  7 = BC = Bottom center (lowest)
--   Bar  8 = LC = Lower center
--   Bar  9 = UC = Upper center
--   Bar 10 = TC = Top center
--   Bar  1 = AC = Above center
--   Bar 11 = OC = Over center (highest)
--
-- Secondary index is the bar id.
defaultPositions[2] = {
	[10] = {"BOTTOMLEFT",  "BOTTOM",      -260, 560, "ACROSS", "AC"},  -- Bar  1, Above center
	[1]  = {"BOTTOMLEFT",  "TOPLEFT",      -10, -85, "DOWN",   "LE"},  -- Bar  2, Left
	[2]  = {"BOTTOMRIGHT", "BOTTOMRIGHT",   12, 603, "DOWN",   "OR"},  -- Bar  3, Outside right
	[3]  = {"BOTTOMRIGHT", "BOTTOMRIGHT",  -31, 603, "DOWN",   "IR"},  -- Bar  4, Inside right
	[4]  = {"BOTTOMLEFT",  "BOTTOM",        -6,  97, "ACROSS", "BR"},  -- Bar  5, Bottom right
	[5]  = {"BOTTOMLEFT",  "BOTTOM",      -516,  97, "ACROSS", "BL"},  -- Bar  6, Bottom left
	[6]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 300, "ACROSS", "BC"},  -- Bar  7, Bottom center
	[7]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 365, "ACROSS", "LC"},  -- Bar  8, Lower center
	[8]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 430, "ACROSS", "UC"},  -- Bar  9, Upper center
	[9]  = {"BOTTOMLEFT",  "BOTTOM",      -260, 495, "ACROSS", "TC"},  -- Bar 10, Top center
	[11] = {"BOTTOMLEFT",  "BOTTOM",      -260, 625, "ACROSS", "OC"},  -- Bar 11, Over center
};

function group:position(orientation, stdPositions)
	if (InCombatLockdown()) then
		return;
	end
	local id = self.id;
	local frame = self.frame;
	local pos;
	local yoffset;
	if (stdPositions) then
		pos = defaultPositions[2][id];
	else
		pos = defaultPositions[1][id];
	end
	if (not pos) then
		pos = defaultPositions[2][module.controlBarId];
	end
	yoffset = pos[4];
	if (pos[6] == "BL" or pos[6] == "BR" or pos[6] == "OR" or pos[6] == "IR") then
		if (firstTime and CT_BottomBar) then
			yoffset = yoffset + 9;
		else
			if (MainMenuBarMaxLevelBar and MainMenuBarMaxLevelBar:IsShown()) then
				-- Max level bar only
				yoffset = yoffset - 5;
			else
				if (ReputationWatchBar and ReputationWatchBar:IsShown()) then
					if (MainMenuExpBar and MainMenuExpBar:IsShown()) then
						-- Rep and Exp bars
						yoffset = yoffset + 9;
					-- else
						-- Rep bar only
						-- yoffset = yoffset + 0;
					end
				-- else
					-- Exp bar only
					-- yoffset = yoffset + 0;
				end
			end
		end
	end
	if (TitanMovable_GetPanelYOffset and TITAN_PANEL_PLACE_BOTTOM and TitanPanelGetVar) then
		if (pos[6] == "BL" or pos[6] == "BR") then
			yoffset = yoffset + (tonumber( TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars")) ) or 0);
		end
	end
	frame:ClearAllPoints();
	frame:SetPoint(pos[1], UIParent, pos[2], pos[3], yoffset);
	self:rotate(orientation or pos[5]);
end

function group:resetPosition()
	-- Reset position of the group
	self:position(nil, module:getOption("stdPositions"));
	module:stopMovable(self.movable);
end

function group:positionButtons()
	local objects = self.objects;
	if ( not objects ) then
		return;
	end
	
	if (InCombatLockdown()) then
		return;
	end

	local frame = self.frame;
	local button;
	local offset = self.spacing or 6;
	if ( self.orientation == "DOWN" ) then
		-- DOWN (top to bottom)
		local row, rows, column, columns;
		rows = self.numRows;
		columns = self.numColumns;
		row = 1;
		column = 1;
		for key, value in ipairs(objects) do
			button = value.button;
			button:ClearAllPoints();
			if (key == 1) then
				button:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", firstButtonOffset, -4);
			elseif (column == 1) then
				button:SetPoint("TOPLEFT", objects[key - columns].button, "TOPRIGHT", offset, 0);
			else
				button:SetPoint("TOPLEFT", objects[key-1].button, "BOTTOMLEFT", 0, -offset);
			end
			column = column + 1;
			if (column > columns) then
				column = 1;
				row = row + 1;
				if (row > rows) then
					break;
				end
			end
		end
	else
		-- ACROSS (left to right)
		local row, rows, column, columns;
		rows = self.numRows;
		columns = self.numColumns;
		row = 1;
		column = 1;
		for key, value in ipairs(objects) do
			button = value.button;
			button:ClearAllPoints();
			if (key == 1) then
				button:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", firstButtonOffset, -4);
			elseif (column == 1) then
				button:SetPoint("TOPLEFT", objects[key - columns].button, "BOTTOMLEFT", 0, -offset);
			else
				button:SetPoint("TOPLEFT", objects[key-1].button, "TOPRIGHT", offset, 0);
			end
			column = column + 1;
			if (column > columns) then
				column = 1;
				row = row + 1;
				if (row > rows) then
					break;
				end
			end
		end
	end
	
	self:updateButtonPosition();
end

function group:calculateDimensions()
	-- Determine how many rows and columns are needed.
	--
	-- The user selects how many columns/rows they want to see, and this routine
	-- will determine how many rows/columns will be needed.
	--
	-- The actual interpretation of the number chosen by the user depends on the
	-- bar orientation being used.
	--
	-- In "ACROSS" orientation, the columns var represents columns, and the rows var represents rows.
	-- In "DOWN" orientation, the columns var represents rows, and the rows var represents columns.
	--
	local rows, buttons, columns;
	local objects = self.objects;
	if (not objects) then
		buttons = 0;
	else
		buttons = #objects;
	end
	columns = self.barColumns;  -- desired number of columns
	if (columns > buttons) then
		columns = buttons;
	end
	if (columns <= 0) then
		columns = 1;
	end
	rows = floor((buttons - 1) / columns) + 1;
	-- Actual number of rows and columns.
	self.numRows = rows;
	self.numColumns = columns;
end

function group:addObject(object)
	local objects = self.objects;
	if (not objects) then
		objects = {};
		self.objects = objects;
	end
	
	local button = object.button;
	local frame = self.frame;
	
	-- Add the object to the list.
	local lastObject = objects[#objects];  -- Last object in list before we add this one.
	tinsert(objects, object);

	-- Determine how many rows and columns are needed.
	self:calculateDimensions();

	-- Prepare to position the object
	if (InCombatLockdown()) then
		return;
	end

	button:SetParent(frame);
	button:ClearAllPoints();

	if ( not lastObject ) then
		-- This object is the only one in the group so far.
		button:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", firstButtonOffset, -4);
		return;
	end
	
	-- Calculate row and column of the object.
	local columns, buttons;
	local row, column;
	buttons = #objects;
	columns = self.numColumns;
	row = floor((buttons - 1) / columns) + 1;
	column = buttons - ((row - 1) * columns);

	-- Attach the object to the group.
	local lastButton = lastObject.button;
	local offset = self.spacing or 6;

	if ( self.orientation == "DOWN" ) then
		if (column == 1) then
			button:SetPoint("TOPLEFT", objects[buttons - columns].button, "TOPRIGHT", offset, 0);
		else
			button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -offset);
		end
	else
		if (column == 1) then
			button:SetPoint("TOPLEFT", objects[buttons - columns].button, "BOTTOMLEFT", 0, -offset);
		else
			button:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", offset, 0);
		end
	end
	button:SetScale(self.scale or 1);
	button:SetAlpha(self.opacity or 1);
	
	self:updateButtonPosition();
end

function group:updateButtonPosition()
	-- Update position of the button that allows the user to drag the group.
	local button = self.frame.button;
	local objects = self.objects;
	if ( not objects ) then
		return;
	end
	
	if (InCombatLockdown()) then
		return;
	end

	-- Determine which buttons will be used to anchor
	-- the top right and bottom left corners of the
	-- drag frame.
	local tr, bl;
	tr = self.numColumns;
	if (#objects < tr) then
		tr = #objects;
	end
	bl = (self.numRows - 1) * self.numColumns + 1;
	if (#objects < bl) then
		-- Calculate number of first object on same row as the last object.
		bl = floor((#objects - 1) / self.numColumns) * self.numColumns + 1;
	end
	if ( self.orientation == "DOWN" ) then
		local temp = tr;
		tr = bl;
		bl = temp;
	end

	-- Anchor three corners of the drag frame to buttons.
	local offset;
	if (dragOnTop) then
		offset = 8;
	else
		offset = 11;
	end
	button:ClearAllPoints();
	button:SetPoint("TOPLEFT", objects[1].button, -offset, offset);
	button:SetPoint("TOPRIGHT", objects[tr].button, offset, offset);
	button:SetPoint("BOTTOMLEFT", objects[bl].button, -offset, -offset);
	
	-- Display the name of the group.
	local text = button.text;
	text:ClearAllPoints();
	if (dragOnTop) then
		text:SetPoint("CENTER", button, "CENTER", 0, 0);
	else
		text:SetPoint("BOTTOM", button, "TOP", 0, -5);
	end
	if ( self.orientation == "ACROSS" ) then
		if (self.numColumns == 1) then
			text:SetText(self.shortName);
		else
			text:SetText(self.longName);
		end
	else
		if (self.numRows == 1) then
			text:SetText(self.shortName);
		else
			text:SetText(self.longName);
		end
	end
end

function group:rotate(force)
	if ( force ) then
		self.orientation = force;
	else
		if ( self.orientation == "DOWN" ) then
			self.orientation = "ACROSS";
		else
			self.orientation = "DOWN";
		end
	end
	module:setOption("orientation"..self.id, self.orientation, true);
	self:positionButtons();
end

function group:show()
	if (InCombatLockdown()) then
		return;
	end
--	self.frame:Show();
end

function group:hide()
	if (InCombatLockdown()) then
		return;
	end
--	self.frame:Hide();
end

function group:toggleHeader(show)
	if ( show ) then
		self.frame.button:Show();
	else
		self.frame.button:Hide();
	end
end

local valtype = type;
function group:update(type, value)
	if ( type == "barScale" ) then
		self.scale = value;
		if (InCombatLockdown()) then
			return;
		end
		local objects = self.objects;
		if ( objects ) then
			for key, object in ipairs(objects) do
				object.button:SetScale(value);
			end
		end
	elseif ( type == "barVisibility" ) then
		self.barVisibility = value;
	elseif ( type == "barMouseover" ) then
		self.barMouseover = value;
	elseif ( type == "barCondition" ) then
		self.barCondition = value;
	elseif ( type == "barFaded" ) then
		self.barFaded = value;
	elseif ( type == "barOpacity" ) then
		-- Init "barMouseover" and/or "barFaded" before "barOpacity".
		self.opacity = value;
		if (self.barMouseover) then
--			-- If the group headers are not visible (the CT_BarMod/CT_BottomBar options window are closed)...
--			if (not module.showingHeaders) then
				-- If mouse is not over this bar group...
				if (not self.mouseover) then
					value = (self.barFaded or 0);  -- Fade buttons by changing alpha.
				end
--			end
		end
		local objects = self.objects;
		if ( objects ) then
			for key, object in ipairs(objects) do
				object.alphaCurrent = value;
				object:updateOpacity();
			end
		end
	elseif ( type == "barSpacing" ) then
		self.spacing = value;
		self:positionButtons();
	elseif ( type == "showGroup" ) then
		if (InCombatLockdown()) then
			return;
		end
		if ( value ) then
			self:show();
		else
			self:hide();
		end
	elseif ( type == "orientation" ) then
		self:rotate(value);  -- value is "ACROSS" or "DOWN"
	elseif ( type == "barColumns" ) then
		self.barColumns = value or 12;
		self:calculateDimensions();
		self:positionButtons();
	end
end

--------------------------------------------
-- Interface

function module:addObjectToGroup(object, id)
	local group = getGroup(id);
	group:addObject(object);
end
