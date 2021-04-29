------------------------------------------------
--                 CT_MapMod                  --
--                                            --
-- Simple addon that allows the user to add   --
-- notes and gathered nodes to the world map. --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_MapMod";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

--------------------------------------------
-- General Mod Code (recode imminent!)

CT_UserMap_Notes = {};

CT_UserMap_Zone = {};
CT_UserMap_Zone["Alterac Mountains"] = 1;
CT_UserMap_Zone["Arathi Highlands"] = 2;
CT_UserMap_Zone["Badlands"] = 3;
CT_UserMap_Zone["Blackrock Spire"] = 4;
CT_UserMap_Zone["Blasted Lands"] = 5;
CT_UserMap_Zone["Tirisfal Glades"] = 6;
CT_UserMap_Zone["Silverpine Forest"] = 7;
CT_UserMap_Zone["Western Plaguelands"] = 8;
CT_UserMap_Zone["Eastern Plaguelands"] = 9;
CT_UserMap_Zone["Hillsbrad Foothills"] = 10;
CT_UserMap_Zone["The Hinterlands"] = 11;
CT_UserMap_Zone["Dun Morogh"] = 12;
CT_UserMap_Zone["Searing Gorge"] = 13;
CT_UserMap_Zone["Burning Steppes"] = 14;
CT_UserMap_Zone["Elwynn Forest"] = 15;
CT_UserMap_Zone["Darrowmere Lake"] = 16;
CT_UserMap_Zone["Deadwind Pass"] = 17;
CT_UserMap_Zone["Duskwood"] = 18;
CT_UserMap_Zone["Loch Modan"] = 19;
CT_UserMap_Zone["Redridge Mountains"] = 20;
CT_UserMap_Zone["Stranglethorn Vale"] = 21;
CT_UserMap_Zone["Swamp of Sorrows"] = 22;
CT_UserMap_Zone["Westfall"] = 23;
CT_UserMap_Zone["Wetlands"] = 24;
CT_UserMap_Zone["Stonetalon Mountains"] = 25;
CT_UserMap_Zone["Dustwallow Marsh"] = 26;
CT_UserMap_Zone["Feralas"] = 27;
CT_UserMap_Zone["Tanaris"] = 28;
CT_UserMap_Zone["Durotar"] = 29;
CT_UserMap_Zone["Mulgore"] = 30;
CT_UserMap_Zone["The Barrens"] = 31;
CT_UserMap_Zone["Teldrassil"] = 32;
CT_UserMap_Zone["Darkshore"] = 33;
CT_UserMap_Zone["Ashenvale"] = 34;
CT_UserMap_Zone["Desolace"] = 35;
CT_UserMap_Zone["Thousand Needles"] = 36;
CT_UserMap_Zone["Azshara"] = 37;
CT_UserMap_Zone["Felwood"] = 38;
CT_UserMap_Zone["Un'Goro Crater"] = 39;
CT_UserMap_Zone["Moonglade"] = 40;
CT_UserMap_Zone["Stormwind City"] = 41;
CT_UserMap_Zone["Ironforge"] = 42;
CT_UserMap_Zone["Undercity"] = 43;
CT_UserMap_Zone["Darnassus"] = 44;
CT_UserMap_Zone["Durotar"] = 45;
CT_UserMap_Zone["Orgrimmar"] = 46;
CT_UserMap_Zone["Silithus"] = 47;
CT_UserMap_Zone["Thunder Bluff"] = 48;
CT_UserMap_Zone["Winterspring"] = 49;
CT_UserMap_Zone["Blade's Edge Mountains"] = 50;
CT_UserMap_Zone["Hellfire Peninsula"] = 51;
CT_UserMap_Zone["Nagrand"] = 52;
CT_UserMap_Zone["Netherstorm"] = 53;
CT_UserMap_Zone["Shadowmoon Valley"] = 54;
CT_UserMap_Zone["Shattrah City"] = 55;
CT_UserMap_Zone["Terokkar Forest"] = 56;
CT_UserMap_Zone["Zangarmarsh"] = 57;
CT_UserMap_Zone["Azuremyst Isle"] = 58;
CT_UserMap_Zone["Bloodmyst Isle"] = 59;
CT_UserMap_Zone["The Exodar"] = 60;
CT_UserMap_Zone["Eversong Woods"] = 61;
CT_UserMap_Zone["Ghostlands"] = 62;
CT_UserMap_Zone["Silvermoon City"] = 63;
CT_UserMap_Zone["Isle of Quel'Danas"] = 64;
CT_UserMap_Zone["Borean Tundra"] = 65;
CT_UserMap_Zone["Crystalsong Forest"] = 66;
CT_UserMap_Zone["Dalaran"] = 67;
CT_UserMap_Zone["Dragonblight"] = 68;
CT_UserMap_Zone["Grizzly Hills"] = 69;
CT_UserMap_Zone["Howling Fjord"] = 70;
CT_UserMap_Zone["Icecrown"] = 71;
CT_UserMap_Zone["Sholazar Basin"] = 72;
CT_UserMap_Zone["The Storm Peaks"] = 73;
CT_UserMap_Zone["Wintergrasp"] = 74;
CT_UserMap_Zone["Zul'Drak"] = 75;
CT_UserMap_Zone["Hrothgar's Landing"] = 76;

CT_MapMod_Options = {};

-- Do not change the order of the items in this table
CT_UserMap_Icons = {
	"GreyNote",
	"BlueShield",
	"RedDot",
	"WhiteCircle",
	"GreenSquare",
	"RedCross",
	"Herb",
	"Ore"
};

-- Do not change the order of the items in this table
-- These are the names of the .tga files in the Resource folder.
CT_UserMap_HerbIcons = {
	"Herb_Bruiseweed",
        "Herb_ArthasTears",
        "Herb_BlackLotus",
        "Herb_Blindweed",
        "Herb_Briarthorn",
	"Herb_Dreamfoil",
        "Herb_Earthroot",
        "Herb_Fadeleaf",
        "Herb_Firebloom",
        "Herb_GhostMushroom",
	"Herb_GoldenSansam",
        "Herb_Goldthorn",
        "Herb_GraveMoss",
        "Herb_Gromsblood",
        "Herb_Icecap",
	"Herb_KhadgarsWhisker",
        "Herb_Kingsblood",
        "Herb_Liferoot",
        "Herb_Mageroyal",
        "Herb_MountainSilversage",
	"Herb_Peacebloom",
        "Herb_Plaguebloom",
        "Herb_PurpleLotus",
        "Herb_Silverleaf",
        "Herb_Stranglekelp",
	"Herb_Sungrass",
        "Herb_Swiftthistle",
        "Herb_WildSteelbloom",
        "Herb_Wintersbite",
        "Herb_DreamingGlory",
        "Herb_Felweed",
        "Herb_FlameCap",
        "Herb_ManaThistle",
        "Herb_Netherbloom",
        "Herb_NetherdustBush",
        "Herb_NightmareVine",
        "Herb_Ragveil",
        "Herb_Terocone",
        "Herb_AddersTongue",
        "Herb_FrostLotus",
        "Herb_Goldclover",
        "Herb_Icethorn",
        "Herb_Lichbloom",
        "Herb_TalandrasRose",
        "Herb_TigerLily",
        "Herb_FrozenHerb"
};

-- Do not change the order of the items in this table
-- These are the names of the .tga files in the Resource folder.
CT_UserMap_OreIcons = {
	"Ore_CopperVein",
        "Ore_GoldVein",
        "Ore_IronVein",
        "Ore_MithrilVein",
        "Ore_SilverVein",
        "Ore_ThoriumVein",
        "Ore_TinVein",
        "Ore_TruesilverVein",
        "Ore_AdamantiteVein",
        "Ore_FelIronVein",
        "Ore_KhoriumVein",
        "Ore_CobaltVein",
        "Ore_SaroniteVein",
        "Ore_TitaniumVein"
};

local CT_UserMap_NoteButtons = 0;

---------------------------------------------
-- Miscellaneous

CT_MapMod_Print = ( CT_Print or function(msg, r, g, b) DEFAULT_CHAT_FRAME:AddMessage(msg, r, g,b) end );

local function round(num, dec)
	local mult = 10 ^ (dec or 0);
	return math.floor(num * mult + 0.5) / mult;
end

local function CT_MapMod_GetCharKey()
	-- Get the current character's name key (combination of player name and server name).
	return UnitName("player") .. "@" .. GetCVar("realmName");
end

local function CT_MapMod_GetMapName()
	-- Get the name of the current map.
	-- This is for use when the player is looking at the map.
	if (GetCurrentMapZone() == 0) then
		-- Map does not have any zones.
		-- This applies to universe maps, continent maps, instance maps.
		return nil;
	end
	-- Return the name currently assigned to the zone drop down menu.
	return WorldMapZoneDropDownText:GetText();
end

local function CT_MapMod_IsDialogShown()
	-- Is a dialog window currently being shown?
	if (CT_MapMod_NoteWindow:IsShown() or CT_MapMod_FilterWindow:IsShown()) then
		return true;
	end
	return false;
end

local function CT_MapMod_GetCursorMapPosition()
	local button = WorldMapButton;
	local x, y = GetCursorPosition();
	x = x / button:GetEffectiveScale();
	y = y / button:GetEffectiveScale();
	local centerX, centerY = button:GetCenter();
	local width = button:GetWidth();
	local height = button:GetHeight();
	local adjustedY = (centerY + (height/2) - y) / height;
	local adjustedX = (x - (centerX - (width/2))) / width;
	if (adjustedX < 0) then
		adjustedX = 0;
	elseif (adjustedX > 1) then
		adjustedX = 1;
	end
	if (adjustedY < 0) then
		adjustedY = 0;
	elseif (adjustedY > 1) then
		adjustedY = 1;
	end
	return adjustedX, adjustedY;
end

local function CT_MapMod_AdjustPositions()
	-- Adjust position of certain elements based on the size of the world map window.
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		CT_MapMod_CoordPlayer:ClearAllPoints();
		CT_MapMod_CoordPlayer:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", 0, 20);

		CT_MapMod_CoordCursor:ClearAllPoints();
		CT_MapMod_CoordCursor:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", 105, 20);

		CT_MapMod_MainButton:ClearAllPoints();
		CT_MapMod_MainButton:SetPoint("TOPRIGHT", WorldMapDetailFrame, "TOPRIGHT", -40, 23);
	else
		-- Full screen size world map
		CT_MapMod_CoordPlayer:ClearAllPoints();
		CT_MapMod_CoordPlayer:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 10, -5);

		CT_MapMod_CoordCursor:ClearAllPoints();
		CT_MapMod_CoordCursor:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 120, -5);

		CT_MapMod_MainButton:ClearAllPoints();
		CT_MapMod_MainButton:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOPRIGHT", -43, -2);
	end
end

local function CT_MapMod_FindResourceIcon(oldName, prefix)
	if ( prefix == "Ore_" ) then
		local n, endPoint;
		-- Remove the trailing word and set it to "Vein" (we want it
		-- to match the names of the .tga files in the Resource folder).
		n, n, endPoint = string.find(oldName, "(.+)%sVein$");
		if ( endPoint ) then
			oldName = endPoint .. "Vein";
		else
			n, n, endPoint = string.find(oldName, "(.+)%sDeposit$");
			if ( endPoint ) then
				oldName = endPoint .. "Vein";
			else
				n, n, endPoint = string.find(oldName, "(.+)%sNode$");
				if ( endPoint ) then
					oldName = endPoint .. "Vein";
				end
			end
		end
		-- Remove any "Small " prefix
		n, n, endPoint = string.find(oldName, "^Small%s(.+)");
		if ( endPoint ) then
			oldName = endPoint;
		end
		-- Remove any "Rich " prefix
		n, n, endPoint = string.find(oldName, "^Rich%s(.+)");
		if ( endPoint ) then
			oldName = endPoint;
		end
	end
	-- Strip out everything except alphanumeric characters
	local name = "";
	for i = 1, strlen(oldName), 1 do
		local l = strsub(oldName, i, i);
		if ( string.find(l, "%w") ) then
			name = name .. l;
		end
	end
	-- Determine icon number
	local icons;
	if ( prefix == "Ore_" ) then
		icons = CT_UserMap_OreIcons;
	else
		icons = CT_UserMap_HerbIcons;
	end
	for k, v in pairs(icons) do
		if ( v == prefix .. name ) then
			return k;
		end
	end
	return 1;
end

---------------------------------------------
-- Notes

local function CT_MapMod_CanCreateNoteOnPlayer()
	-- Can the user create a note on the player's position?
	local canCreate = false;
	local mapName = CT_MapMod_GetMapName();
	-- If we have a name for the zone and user is not looking at a dialog window...
	if (mapName and not CT_MapMod_IsDialogShown()) then
		-- Only allow if user is looking at the map of the zone they are in.
		local x, y = GetPlayerMapPosition("player");
		if (x and y and not (x == 0 and y == 0)) then
			canCreate = true;
		end
	end
	return canCreate;
end

local function CT_MapMod_CreateNoteButton()
	-- Create a new note button.
	local id = CT_UserMap_NoteButtons + 1;
	local note = CreateFrame("BUTTON", "CT_UserMap_Note" .. id, CT_MapMod_MapButtonFrame, "CT_MapMod_NoteTemplate");
	note:SetID(id);
	CT_UserMap_NoteButtons = id;
end

local function CT_MapMod_HideNotes(first, last)
	-- Hide a range of notes.
	if (not first) then
		first = 1;
	end
	if (not last) then
		last = CT_UserMap_NoteButtons;
	end
	for i = first, last, 1 do
		_G["CT_UserMap_Note" .. i]:Hide();
	end
end

local function CT_MapMod_UpdateMap()
	-- Update the world map.
	local notes, mapName;
	local characterKey;
	local count;

	CT_MapMod_AdjustPositions();

	mapName = CT_MapMod_GetMapName();
	if ( mapName ) then
		notes = CT_UserMap_Notes[mapName];
	end
	if ( not mapName or not notes ) then
		CT_MapMod_HideNotes(1, CT_UserMap_NoteButtons);
		CT_NumNotes:SetText("|c00FFFFFF0|r/|c00FFFFFF0|r");
		return;
	end

	characterKey = CT_MapMod_GetCharKey();

	-- Calculate what notes to show
	count = 1;
	for i, var in pairs(notes) do
		if (
			-- If not hiding this set of notes, and
			not CT_MapMod_Options[characterKey].hideGroups[(CT_MAPMOD_SETS[(var.set or 1)])] and 
			(
				-- not filtering the notes, or
				not CT_MapMod_Filter or 

				-- we are filtering the notes and the note's name matches the filter pattern, or
				string.find(strlower(var.name), strlower(CT_MapMod_Filter)) or

				-- we are filtering the notes and the note's description matches the filter pattern
				string.find(strlower(var.descript), strlower(CT_MapMod_Filter))
			)
		) then
			local note;
			local IconTexture;

			if ( count > CT_UserMap_NoteButtons ) then
				CT_MapMod_CreateNoteButton();
			end

			note = _G["CT_UserMap_Note" .. count];
			IconTexture = _G["CT_UserMap_Note" .. count .."Icon"];
			
			if ( var.set == 7 ) then
				-- Herbalism notes.
				-- If icon is 1 and the name is not what the default was, then try correcting the icon.
				if (var.icon == 1 and var.name and string.lower(var.name) ~= "bruiseweed") then
					var.icon = CT_MapMod_FindResourceIcon(var.name, "Herb_")
				end
				if ( CT_UserMap_HerbIcons[var.icon] ) then
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\" .. CT_UserMap_HerbIcons[var.icon]);
				else
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed");
				end
			elseif ( var.set == 8 ) then
				-- Mining notes.
				-- If icon is 1 and the name is not what the default was, then try correcting the icon.
				if (var.icon == 1 and var.name and string.lower(var.name) ~= "copper vein") then
					var.icon = CT_MapMod_FindResourceIcon(var.name, "Ore_")
				end
				if ( CT_UserMap_OreIcons[var.icon] ) then
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\" .. CT_UserMap_OreIcons[var.icon]);
				else
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein");
				end
			else
				IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Skin\\" .. CT_UserMap_Icons[var.set]);
			end
			note:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", var.x * WorldMapButton:GetWidth(), -var.y * WorldMapButton:GetHeight());			
			note:Show();
			
			if ( not var.name ) then
				var.name = "";
			end
			if ( not var.set or not CT_MAPMOD_SETS[var.set] ) then
				var.set = 1;
			end
			if ( not var.descript ) then
				var.descript = "";
			end
	
			note.name = var.name;
			note.set = CT_MAPMOD_SETS[var.set];
			note.descript = var.descript;
			note.id = i;
			note.x = var.x;
			note.y = var.y;

			count = count + 1;
		end
	end

	-- The number of notes currently displayed on this map / The total number of notes on this map
	CT_NumNotes:SetText("|c00FFFFFF" .. (count - 1) .. "|r/|c00FFFFFF" .. (#notes) .. "|r");

	-- Hide all other notes on this map
	CT_MapMod_HideNotes(count, CT_UserMap_NoteButtons);
end

local function CT_MapMod_ExecuteFilter(filter)
	CT_MapMod_Filter = filter;
	CT_MapMod_UpdateMap();
end

local function CT_MapMod_FindNote(zone, x, y)
	-- Look up note in zone at specified x,y location.
	local notes = CT_UserMap_Notes[zone];
	x = tonumber(x);
	y = tonumber(y);
	if (notes) then
		for num, note in ipairs(notes) do
			if ( abs(note.x - x) <= 0.0000000005 and abs(note.y - y) <= 0.0000000005 ) then
				return num;
			end
		end
	end
	return nil;
end

local function CT_MapMod_AddNote(x, y, zone, text, descript, icon, set)
	-- Add a note to the map (or change existing one at the same x,y location).
	local group;
	if ( tonumber(set) ) then
		group = tonumber(set);
	else
		group = set;
	end

	local notes = CT_UserMap_Notes[zone];
	if ( not notes ) then
		notes = {};
		CT_UserMap_Notes[zone] = notes;
	end

	-- If there is already a note at this x,y location...
	local found = CT_MapMod_FindNote(zone, x, y);
	if (found) then
		-- Update existing note.
		local temp = notes[found];
		temp.name = text;
		temp.descript = descript;
		temp.icon = icon;
		temp.set = group;
		CT_MapMod_UpdateMap();
		return found;
	else
		-- Add new note.
		local temp = { x = x, y = y, name = text, descript = descript, icon = icon, set = group };
		tinsert(notes, temp);
		CT_MapMod_UpdateMap();
		return #notes;
	end
end

local function CT_MapMod_EditNote(id)
	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		if (not id) then
			local notes = CT_UserMap_Notes[mapName];
			if (notes) then
				id = #(notes);
			else
				id = 0;
			end
		end
		if (id > 0) then
			CT_MapMod_NoteWindow.note = id;
			CT_MapMod_NoteWindow.zone = mapName;
			CT_MapMod_NoteWindow:Show();
		end
	end
end

local function CT_MapMod_CreateNoteOnCursor()
	-- Create a new note at the cursor position.
	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		local x, y = CT_MapMod_GetCursorMapPosition();
		local id = CT_MapMod_AddNote(x, y, mapName, "New note at cursor", "", 1, 1);
		CT_MapMod_NoteWindow.note = id;
		CT_MapMod_NoteWindow.zone = mapName;
		CT_MapMod_NoteWindow:Show();
	end
end

local function CT_MapMod_CreateNoteOnPlayer()
	-- Create a new note on the player's position.
	local x, y = GetPlayerMapPosition("player");
	if (not (x == 0 and y == 0)) then
		local mapName = CT_MapMod_GetMapName();
		if (mapName) then
			local id = CT_MapMod_AddNote(x, y, mapName, "New note at player", "", 1, 1);
			CT_MapMod_NoteWindow.note = id;
			CT_MapMod_NoteWindow.zone = mapName;
			CT_MapMod_NoteWindow:Show();
		end
	end
end

function CT_MapMod_OnNoteOver(self)
	-- Mouse is over a note on the map.

	-- Have to do this in order to be able to see our note's tooltip.
	WorldMapPOIFrame.allowBlobTooltip = false;

	-- Display the note's tooltip.
	local x, y = self:GetCenter();
	local parentX, parentY = WorldMapButton:GetCenter();
	if ( x > parentX ) then
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	WorldMapTooltip:ClearLines();
	WorldMapTooltip:AddDoubleLine(self.name, self.set, 0, 1, 0, 0.6, 0.6, 0.6);
	if ( self.descript ) then
		WorldMapTooltip:AddLine(self.descript, nil, nil, nil, 1);
	end
	WorldMapTooltip:AddLine("Right-click to edit.", 0, 0.5, 0.9, 1);
	WorldMapTooltip:Show();
end

function CT_MapMod_OnNoteLeave(self)
	-- Mouse is leaving a note.

	-- Undo what we did in CT_MapMod_OnNoteOver()
	WorldMapPOIFrame.allowBlobTooltip = true;

	-- Hide the note's tooltip.
	WorldMapTooltip:Hide();
end

function CT_MapMod_OnClick(self, btn)
	-- User clicked a note on the map
	if ( btn == "LeftButton" ) then
		return;
	end
	CT_MapMod_EditNote(self.id);
end

---------------------------------------------
-- Note window

function CT_MapMod_NoteWindow_OnLoad(self)
	self.note = -1;
	-- Set names
	CT_MapMod_NoteWindowTitle:SetText(CT_MAPMOD_TEXT_TITLE);
	CT_MapMod_NoteWindowNameText:SetText(CT_MAPMOD_TEXT_NAME);
	CT_MapMod_NoteWindowDescriptText:SetText(CT_MAPMOD_TEXT_DESC);
	CT_MapMod_NoteWindowGroupText:SetText(CT_MAPMOD_TEXT_GROUP);
	CT_MapMod_NoteWindowSendText:SetText(CT_MAPMOD_TEXT_SEND);
	CT_MapMod_NoteWindowOkayButton:SetText(CT_MAPMOD_BUTTON_OKAY);
	CT_MapMod_NoteWindowCancelButton:SetText(CT_MAPMOD_BUTTON_CANCEL);
	CT_MapMod_NoteWindowDeleteButton:SetText(CT_MAPMOD_BUTTON_DELETE);
	CT_MapMod_NoteWindowEditButton:SetText(CT_MAPMOD_BUTTON_EDITGROUPS);
	CT_MapMod_NoteWindowSendButton:SetText(CT_MAPMOD_BUTTON_SEND);
end

function CT_MapMod_NoteWindow_OnShow(self)
	-- The note window is being shown.
	CT_MapMod_MapButtonFrame:Hide();
	CT_MapMod_MainButton:Disable();

	local note = CT_UserMap_Notes[self.zone][self.note];

	CT_MapMod_NoteWindowNameEB:SetText(note.name);
	CT_MapMod_NoteWindowNameEB:HighlightText();

	CT_MapMod_NoteWindowDescriptEB:SetText(note.descript);

	CT_MapMod_NoteWindowSendButton:Disable();

	CT_MapMod_NoteWindowSendEB.lastsend = "";
	CT_MapMod_NoteWindowSendEB:SetText("");

	PlaySound("UChatScrollButton");
end

function CT_MapMod_NoteWindow_OnHide(self)
	-- The note window is being hidden.
	CT_MapMod_MapButtonFrame:Show();
	CT_MapMod_MainButton:Enable();

	PlaySound("UChatScrollButton");
end

function CT_MapMod_NoteWindow_Accept()
	-- Accept the note information.
	local name, descript, set, icon;
	local zoneKey, noteKey;
	local note;

	-- Get information from the note window
	zoneKey = CT_MapMod_NoteWindow.zone;
	noteKey = CT_MapMod_NoteWindow.note;

	note = CT_UserMap_Notes[zoneKey][noteKey];

	name = CT_MapMod_NoteWindowNameEB:GetText();
	descript = CT_MapMod_NoteWindowDescriptEB:GetText();

	icon = note.icon;

	if ( UIDropDownMenu_GetSelectedName(CT_MapMod_NoteWindowGroupDropDown) ) then
		set = note.set;
	else
		set = UIDropDownMenu_GetSelectedID( CT_MapMod_NoteWindowGroupDropDown );
	end

	-- Update the note
	note.name = name;
	note.descript = descript;
	note.set = set;
	note.icon = icon;
	
	CT_MapMod_NoteWindow:Hide();
	CT_MapMod_UpdateMap();
end

function CT_MapMod_NoteWindow_Cancel()
	-- Cancel the note editing.
	CT_MapMod_NoteWindow:Hide();
end

function CT_MapMod_NoteWindow_Delete()
	-- Delete the note
	local zoneKey = CT_MapMod_NoteWindow.zone;
	local noteKey = CT_MapMod_NoteWindow.note;

	tremove(CT_UserMap_Notes[zoneKey], noteKey);

	CT_MapMod_NoteWindow:Hide();
	CT_MapMod_UpdateMap();
end

function CT_MapMod_NoteWindow_GroupDropDown_OnClick(self)
	-- User clicked on an item in the group menu.
	UIDropDownMenu_SetSelectedID(CT_MapMod_NoteWindowGroupDropDown, self:GetID(), 1);
end

function CT_MapMod_NoteWindow_GroupDropDown_OnShow()
	-- The group menu is being displayed (not actually called until note window is being shown).
	local zoneKey = CT_MapMod_NoteWindow.zone;
	local noteKey = CT_MapMod_NoteWindow.note;
	if ( zoneKey and noteKey ) then
		local note = CT_UserMap_Notes[zoneKey][noteKey];
		local set = note.set;
		if ( tonumber(set) and tonumber(set) == set ) then
			UIDropDownMenu_SetSelectedName(CT_MapMod_NoteWindowGroupDropDown, CT_MAPMOD_SETS[set], nil);
		else
			UIDropDownMenu_SetSelectedName(CT_MapMod_NoteWindowGroupDropDown, set, nil);
		end
		UIDropDownMenu_SetText(CT_MapMod_NoteWindowGroupDropDown, CT_MAPMOD_SETS[set]);
	end
end

function CT_MapMod_NoteWindow_GroupDropDown_Initialize(self)
	-- Initialize the group menu.
	for key, val in pairs(CT_MAPMOD_SETS) do
		local info = {};
		info.text = val;
		info.value = val;
		info.owner = self;
		info.func = CT_MapMod_NoteWindow_GroupDropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function CT_MapMod_NoteWindow_GroupDropDown_OnLoad(self)
	-- The group menu is being loaded.
	UIDropDownMenu_Initialize(self, CT_MapMod_NoteWindow_GroupDropDown_Initialize);
	UIDropDownMenu_SetWidth(self, 130);
end

---------------------------------------------
-- Filter window

function CT_MapMod_FilterWindow_OnLoad(self)
	-- Set names
	CT_MapMod_FilterWindowTitleText:SetText("Notes Filter");
	CT_MapMod_FilterWindowOkayButton:SetText(CT_MAPMOD_BUTTON_OKAY);
	CT_MapMod_FilterWindowCancelButton:SetText(CT_MAPMOD_BUTTON_CANCEL);
end

function CT_MapMod_FilterWindow_OnShow(self)
	-- The filter window is being shown.
	CT_MapMod_MapButtonFrame:Hide();
	CT_MapMod_MainButton:Disable();

	local eb = CT_MapMod_FilterWindowFilterEB;
	eb:SetText(CT_MapMod_Filter or "");
	eb:HighlightText();

	PlaySound("UChatScrollButton");
end

function CT_MapMod_FilterWindow_OnHide(self)
	-- The filter window is being hidden.
	CT_MapMod_MapButtonFrame:Show();
	CT_MapMod_MainButton:Enable();

	PlaySound("UChatScrollButton");
end

function CT_MapMod_FilterWindow_Accept()
	-- Accept the filter window information.
	local eb = CT_MapMod_FilterWindowFilterEB;
	CT_MapMod_ExecuteFilter(eb:GetText() or "");
	CT_MapMod_FilterWindow:Hide();
end

function CT_MapMod_FilterWindow_Cancel()
	-- Cancel editing the filter.
	CT_MapMod_FilterWindow:Hide();
end

---------------------------------------------
-- Sending notes

local CT_LastIncMessage = {};
local CT_LastOutMessage = {};

local function CT_MapMod_EnableReceiveNotes(enable)
	local characterKey = CT_MapMod_GetCharKey();
	if (enable) then
		enable = 1;
	else
		enable = nil;
	end
	CT_LastIncMessage.msg = nil;
	CT_LastIncMessage.user = nil;
	CT_MapMod_Options[characterKey].receiveNotes = enable;
end

local function CT_MapMod_GetZone(zoneid)
	if ( not tonumber(zoneid) ) then
		return "(Error: Please report zoneid " .. zoneid .. ")";
	end

	local zone = tonumber(zoneid);
	for key, val in pairs(CT_UserMap_Zone) do
		if ( val == zone ) then
			return key;
		end
	end
	return "(Error: Please report zone " .. zoneid .. ")";
end

local function CT_MapMod_ProcessWhisper(self, event, msg, user)
	-- Process incoming whispers.
	-- Return nil to allow the game to continue processing the message (should show up in chat window).
	-- Return true to prevent the message from being processed any further (won't show up in chat window).

	if (not msg) then
		return nil;
	end

	-- Examine the message
	if (strsub(msg, 1, 7) ~= "<CTMod>") then
		return nil;
	end
	local pos1, pos2, xpos, ypos, zone, name, descript, group, icon = string.find(msg, "^<CTMod> New map note received: x=(.+) y=(.+) z=(.+) n=(.*) d=(.*) g=(.+) i=(.+)$");
	if (not zone) then
		pos1, pos2, name, xpos, ypos, zone = string.find(msg, "^<CTMod> New map note: (.*) x=(.+) y=(.+) z=(.+) v=.+$");
		if (not zone) then
			return nil;
		end
		descript = "Received from " .. user;
		icon = 1;
		group = 1;
	end

	-- If this is the same as the last incoming message we processed...
	if (msg == CT_LastIncMessage.msg and CT_LastIncMessage.user == user) then
		-- Will happen if user has multiple chat frames that trap whispers.
		-- Will happen if user is sent the same whisper twice in a row.
		return true;  -- true == don't show whisper in chat frame
	end

	-- Remember this message for next time.
	CT_LastIncMessage.msg = msg;
	CT_LastIncMessage.user = user;

	-- Notify user of a received message.
	local zonename = CT_MapMod_GetZone(zone);
	local characterKey = CT_MapMod_GetCharKey();

	if ( not CT_MapMod_Options[characterKey].receiveNotes ) then
		module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Blocked incoming map note from " .. user .. ".");
	else
		module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Map note received in zone '" .. zonename .. "' at " .. round(xpos * 100, 0) .. ", " .. round(ypos * 100, 0) .. " from " .. user .. ".");
		if (strsub(zonename, 1, 1) ~= "(") then
			-- Add the note to the map
			CT_MapMod_AddNote(xpos, ypos, zonename, name, descript, tonumber(icon), group);
		end
	end
	return true;  -- true == don't show whisper in chat frame
end

-- Add a chat message filter so we can intercept incoming whispers involving CT_MapMod notes.
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", CT_MapMod_ProcessWhisper);

local function CT_MapMod_ProcessOutgoingWhisper(self, event, msg, user)
	-- Process outgoing whispers.
	-- Return nil to allow the game to continue processing the message (should show up in chat window).
	-- Return true to prevent the message from being processed any further (won't show up in chat window).
	if (not msg) then
		return nil;
	end
	-- Examine the message
	if (strsub(msg, 1, 7) ~= "<CTMod>") then
		return nil;
	end
	local pos1, pos2, xpos, ypos, zone = string.find(msg, "^<CTMod> New map note received: x=(.+) y=(.+) z=(.+) n=.* d=.* g=.+ i=.+$");
	if (not zone) then
		return nil;
	end

	-- If this is the same as the last outgoing message we processed...
	if (msg == CT_LastOutMessage.msg and CT_LastOutMessage.user == user) then
		-- Will happen if user has multiple chat frames that trap whispers.
		return true;  -- true == don't show whisper in chat frame
	end

	-- Remember this message for next time.
	CT_LastOutMessage.msg = msg;
	CT_LastOutMessage.user = user;

	-- Notify user of sent message.
	local zonename = CT_MapMod_GetZone(zone);
	module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Sent map note in zone '" .. zonename .. "' at " .. round(xpos * 100, 0) .. ", " .. round(ypos * 100, 0) .. " to " .. user .. ".");
	return true;  -- true == don't show whisper in chat frame
end

-- Add a chat message filter so we can intercept outgoing whispers involving CT_MapMod notes.
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", CT_MapMod_ProcessOutgoingWhisper);

function CT_MapMod_SendNote()
	-- Send a note to a player.
	local name, descript, zone, player;
	local note;
	local group, x, y, icon;

	CT_LastOutMessage.msg = nil;
	CT_LastOutMessage.user = nil;

	name = CT_MapMod_NoteWindowNameEB:GetText();
	descript = CT_MapMod_NoteWindowDescriptEB:GetText();
	zone = CT_MapMod_NoteWindow.zone;
	player = CT_MapMod_NoteWindowSendEB:GetText();
	
	note = CT_UserMap_Notes[zone][CT_MapMod_NoteWindow.note];

	if ( not CT_MapMod_NoteWindow:IsVisible() or strlen(player) == 0 or not CT_UserMap_Zone[zone] ) then
		return;
	end

	if ( UIDropDownMenu_GetSelectedName(CT_MapMod_NoteWindowGroupDropDown) ) then
		group = note.set;
	else
		group = UIDropDownMenu_GetSelectedID(CT_MapMod_NoteWindowGroupDropDown);
	end

	x = note.x;
	y = note.y;
	icon = note.icon;

	SendChatMessage("<CTMod> New map note received: x="..x.." y="..y.." z="..CT_UserMap_Zone[zone].." n="..name.." d="..descript.." g="..group .. " i=" .. icon, "WHISPER", nil, player);

	CT_MapMod_NoteWindowSendEB.lastsend = player;
	CT_MapMod_NoteWindowSendEB:SetText("");
	CT_MapMod_NoteWindowSendButton:Disable();
end

---------------------------------------------
-- Gathering resources

local function CT_MapMod_EnableGatherNotes(enable)
	local characterKey = CT_MapMod_GetCharKey();
	if (enable) then
		enable = 1;
	else
		enable = nil;
	end
	CT_MapMod_Options[characterKey].autoGather = enable;
end

local function CT_MapMod_GetZoneName(id, ...)
	if ( id >= 1 and select('#', ...) >= id ) then
		return select(id, ...);
	end
end

local function CT_MapMod_GetCurrentZone()
	local x, y = GetPlayerMapPosition("player");
	local currC, currZ = GetCurrentMapContinent(), GetCurrentMapZone();
	SetMapToCurrentZone();
	local name = CT_MapMod_GetZoneName(GetCurrentMapZone(), GetMapZones(GetCurrentMapContinent()));
	if ( x == 0 and y == 0 ) then
		SetMapZoom(currC, currZ);
	end
	return name;
end

local function CT_MapMod_ParseResource(event, arg1)
	local characterKey = CT_MapMod_GetCharKey();
	if ( not CT_MapMod_Options[characterKey].autoGather ) then
		return;
	end
	local x, y = GetPlayerMapPosition("player");
	if ( x == 0 and y == 0 ) then
		return;
	end
	local zone = CT_MapMod_GetCurrentZone();
	if ( not zone or not CT_UserMap_Zone[zone] ) then
		return;
	end
	if ( not CT_UserMap_Notes[zone] ) then
		CT_UserMap_Notes[zone] = { };
	end
	for k, v in pairs(CT_UserMap_Notes[zone]) do
		if ( abs(v.x-x) <= 0.005 and abs(v.y-y) <= 0.005 ) then
			-- Two very close herbs, most likely the same herb, we don't want to add another note then
			return;
		end
	end
	if ( string.find(event, "^CHAT_MSG" ) ) then
		if ( string.find(arg1, "^You perform Herb Gathering on") ) then
			local _,_, name = string.find(arg1, "^You perform Herb Gathering on (.+)%.$");
			if ( name ) then
				CT_MapMod_AddNote(x, y, zone, name, "", CT_MapMod_FindResourceIcon(name, "Herb_"), 7);
			end
		elseif ( string.find(arg1, "^You perform Mining on") ) then
			local _,_, name = string.find(arg1, "^You perform Mining on (.+)%.$");
			if ( name ) then
				CT_MapMod_AddNote(x, y, zone, name, "", CT_MapMod_FindResourceIcon(name, "Ore_"), 8);
			end
		end
	elseif ( string.find(event, "UI_ERROR_MESSAGE") ) then
		local name = GameTooltipTextLeft1:GetText();
		if ( name and strlen(name) > 0 ) then
			if ( string.find(arg1, "Herbalism" ) ) then
				CT_MapMod_AddNote(x, y, zone, name, "", CT_MapMod_FindResourceIcon(name, "Herb_"), 7);
			else
				CT_MapMod_AddNote(x, y, zone, name, "", CT_MapMod_FindResourceIcon(name, "Ore_"), 8);
			end
		end
	end
end

---------------------------------------------
-- Group window (not functional)

function CT_MapMod_GroupWindow_Show()
	CT_MapMod_GroupWindow:Show();
end

function CT_MapMod_GroupWindow_Update()
	local numGroups = #(CT_MAPMOD_SETS);
	FauxScrollFrame_Update(CT_MapMod_GroupWindowScrollFrame, numGroups, 6, 16, CT_MapMod_GroupWindowHighlightFrame, 293, 316);

	local i;
	for i = 1, 6, 1 do
		local btn = _G["CT_MapMod_GroupWindowGroup" .. i];
		if ( i <= numGroups ) then
			btn:Show();
			btn:SetText(" " .. CT_MAPMOD_SETS[FauxScrollFrame_GetOffset(CT_MapMod_GroupWindowScrollFrame)+i]);
		else
			btn:Hide();
		end
	end
end

function CT_MapMod_GroupWindow_SetSelection(id)
	local i;
	for i = 1, 6, 1 do
		_G["CT_MapMod_GroupWindowGroup"..i]:UnlockHighlight();
	end

	-- Get xml id
	local xmlid = id - FauxScrollFrame_GetOffset( CT_MapMod_GroupWindowScrollFrame );
	local groupButton = _G["CT_MapMod_GroupWindowGroup"..xmlid];

	-- Set newly selected quest and highlight it
	CT_MapMod_GroupWindow.selectedButtonID = xmlid;
	local scrollFrameOffset = FauxScrollFrame_GetOffset( CT_MapMod_GroupWindowScrollFrame );
	if ( id > scrollFrameOffset and id <= (scrollFrameOffset + 6) and id <= #(CT_MAPMOD_SETS) ) then
		groupButton:LockHighlight();
	end
end

function CT_MapMod_GroupButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		CT_MapMod_GroupWindow_SetSelection(self:GetID() + FauxScrollFrame_GetOffset(CT_MapMod_GroupWindowScrollFrame))
		CT_MapMod_GroupWindow_Update();
	end
end

---------------------------------------------
-- Update player and cursor coordinates

function CT_MapMod_MapFrame_OnUpdate()
	local cX, cY = CT_MapMod_GetCursorMapPosition();
	local pX, pY = GetPlayerMapPosition("player");
	local dec = 0;

	cX = round(cX * 100, dec);
	cY = round(cY * 100, dec);
	pX = round(pX * 100, dec);
	pY = round(pY * 100, dec);

	CT_MapMod_CoordPlayer:SetText("Player: |c00FFFFFF" .. pX .. "|r, |c00FFFFFF" .. pY .. "|r");
	if (WorldMapButton:IsMouseOver()) then
		if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
			CT_MapMod_CoordCursor:SetText("(|c00FFFFFF" .. cX .. "|r, |c00FFFFFF" .. cY .. "|r)");
		else
			CT_MapMod_CoordCursor:SetText("Cursor: |c00FFFFFF" .. cX .. "|r, |c00FFFFFF" .. cY .. "|r");
		end
	else
		CT_MapMod_CoordCursor:SetText("");
	end
end

---------------------------------------------
-- Main button

function CT_MapMod_MainButton_OnEnter(self)
	local text;

	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		text = "To open the menu, left-click the Notes button.";
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			text = text .. "\n\nTo create a new note at the player, Ctrl left-click the Notes button (or use the menu).";
		end
		text = text .. "\n\nTo create a new note at the cursor, Ctrl left-click an open spot on the map.";
	else
		text = "Left-click the Notes button to open the menu.";
	end

	WorldMapTooltip:SetOwner(self, "ANCHOR_NONE");
	WorldMapTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0);
	WorldMapTooltip:SetText(text, nil, nil, nil, nil, 1);
end

function CT_MapMod_MainButton_OnLeave(self)
	WorldMapTooltip:Hide();
end

function CT_MapMod_MainButton_OnClick(self, button)
	if (IsControlKeyDown()) then
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			CT_MapMod_CreateNoteOnPlayer();
		end
	else
		-- Toggle the main menu
		local dropdown = CT_MapMod_MainMenuDropDown;
		CT_MapMod_MainButton_OnLeave(self);
		dropdown.point = "TOPRIGHT";
		dropdown.relativePoint = "BOTTOMRIGHT";
		dropdown.relativeTo = CT_MapMod_MainButton;
		dropdown.xOffset = 0;
		dropdown.yOffset = 0;
		ToggleDropDownMenu(1, nil, dropdown);
		PlaySound("igMainMenuOptionCheckBoxOn");
	end
end

---------------------------------------------
-- Main menu

function CT_MapMod_MainMenu_DropDown_OnClick(self)
	local characterKey = CT_MapMod_GetCharKey();

	if (self.value == "autogather") then
		if (CT_MapMod_Options[characterKey].autoGather) then
			CT_MapMod_EnableGatherNotes(nil);
		else
			CT_MapMod_EnableGatherNotes(1);
		end

	elseif (self.value == "receivenotes") then
		if (CT_MapMod_Options[characterKey].receiveNotes) then
			CT_MapMod_EnableReceiveNotes(nil);
		else
			CT_MapMod_EnableReceiveNotes(1);
		end

	elseif (self.value == "setfilter") then
		CT_MapMod_FilterWindow:Show();

	elseif (self.value == "clearfilter") then
		CT_MapMod_ExecuteFilter("");

	elseif (self.value == "playernote") then
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			CT_MapMod_CreateNoteOnPlayer();
		end

	elseif (self.value == "editlast") then
		CT_MapMod_EditNote();

	else
		-- Show/hide groups
		local characterKey = CT_MapMod_GetCharKey();
		if ( not CT_MapMod_Options[characterKey].hideGroups ) then
			CT_MapMod_Options[characterKey].hideGroups = { };
		end
		CT_MapMod_Options[characterKey].hideGroups[self.value] = not CT_MapMod_Options[characterKey].hideGroups[self.value];
		CT_MapMod_UpdateMap();
	end
end

function CT_MapMod_MainMenu_DropDown_Initialize(self)
	local info;
	local characterKey = CT_MapMod_GetCharKey();

	info = { };
	info.text = "CT_MapMod";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Create note at player"
	info.value = "playernote";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	if (not CT_MapMod_CanCreateNoteOnPlayer()) then
		info.disabled = true;
	end
	UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Edit last note added to this map"
	info.value = "editlast";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	do
		local id = 0;
		local mapName = CT_MapMod_GetMapName();
		if (mapName) then
			local notes = CT_UserMap_Notes[mapName];
			if (notes) then
				id = #(notes);
			else
				id = 0;
			end
		end
		if (id == 0) then
			info.disabled = true;
		end
	end
	UIDropDownMenu_AddButton(info);

	local emptyFilter = ((CT_MapMod_Filter or "") == "");

	info = { };
	if (emptyFilter) then
		info.text = "Set filter text"
	else
		info.text = "Edit filter text"
	end
	info.value = "setfilter";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Clear filter text"
	info.value = "clearfilter";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	if (emptyFilter) then
		info.disabled = true;
	end
	UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Options";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Auto gather herbs/veins"
	info.value = "autogather";
	if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].autoGather) then
		info.checked = 1;
	end
	info.keepShownOnClick = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Receive notes from players"
	info.value = "receivenotes";
	if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].receiveNotes) then
		info.checked = 1;
	end
	info.keepShownOnClick = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Groups To Show";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	UIDropDownMenu_AddButton(info);

	for key, val in pairs(CT_MAPMOD_SETS) do
		info = { };
		info.text = val;
		info.value = val;
		if ( CT_MapMod_Options[characterKey] and ( not CT_MapMod_Options[characterKey].hideGroups or not CT_MapMod_Options[characterKey].hideGroups[val] ) ) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function CT_MapMod_MainMenu_DropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, CT_MapMod_MainMenu_DropDown_Initialize, "MENU");
	UIDropDownMenu_SetWidth(self, 130);
end

---------------------------------------------
-- Convert old notes

local function CT_MapMod_UpdateOldNotes()
	-- Convert old notes to new format.
	local temp = {};
	local update = false;
	for key, val in pairs(CT_UserMap_Notes) do
		if ( type(key) == "number" and type(val) == "table" ) then
			update = true;
			-- Old notes 
			local tempvar = {
				name = val.desc,
				x = val.x,
				y = val.y,
				icon = 1,
				set = 1,
			};
			local zone = val.zone;
			if (zone) then
				if (not temp[zone]) then
					temp[zone] = {};
				end
				temp[zone][#(temp[zone])+1] = tempvar;
			end
			CT_UserMap_Notes[key] = nil;
		end
	end
	if (update) then
		for key, val in pairs(temp) do
			if ( not CT_UserMap_Notes[key] ) then
				CT_UserMap_Notes[key] = {};
			end
			for k, v in pairs(val) do
				tinsert(CT_UserMap_Notes[key], v);
			end
		end
		CT_MapMod_Print("<CTMod> Updated old notes to new format.", 1, 0.5, 0);
	end
end

---------------------------------------------
-- Event frame

function CT_MapMod_EventFrame_OnEvent(self, event, arg1)
	if ( event == "CHAT_MSG_OPENING" ) then
		CT_MapMod_ParseResource(event, arg1);
	elseif ( event == "UI_ERROR_MESSAGE" ) then
		if ( arg1 and ( string.find(arg1, "Requires Herbalism") or string.find(arg1, "Requires Mining") ) ) then
			CT_MapMod_ParseResource(event, arg1);
		end
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		local characterKey = CT_MapMod_GetCharKey();
		if ( not CT_MapMod_Options[characterKey] ) then
			CT_MapMod_Options[characterKey] = { 
				autoGather = 1,
				receiveNotes = nil,
				hideGroups = {}
			};
		end
		SetMapToCurrentZone();
	elseif ( event == "DISPLAY_SIZE_CHANGED" ) then
		CT_MapMod_AdjustPositions();
	elseif ( event == "WORLD_MAP_UPDATE" ) then
		CT_MapMod_UpdateMap();
	elseif (event == "VARIABLES_LOADED") then
		CT_MapMod_UpdateOldNotes();
	end
end

---------------------------------------------
-- WorldMap hooks

local oldProcessMapClick = ProcessMapClick;
function ProcessMapClick(...)
	-- This gets called from WorldMapFrame.lua when user left clicks on the map.
	local mapName = CT_MapMod_GetMapName();
	if ( IsControlKeyDown() and mapName and not CT_MapMod_IsDialogShown() ) then
		-- Create a new note at the cursor position.
		CT_MapMod_CreateNoteOnCursor();
	else
		oldProcessMapClick(...);
	end
end

local function CT_MapMod_WorldMapFrame_OnHide(...)
	CT_MapMod_NoteWindow_Cancel();
	CT_MapMod_FilterWindow:Hide();
end
WorldMapFrame:HookScript("OnHide", CT_MapMod_WorldMapFrame_OnHide);
hooksecurefunc("WorldMapFrame_OnHide", CT_MapMod_WorldMapFrame_OnHide);


local function CT_MapMod_WorldMap_ToggleSizeUp()
	CT_MapMod_AdjustPositions();
end
hooksecurefunc("WorldMap_ToggleSizeUp", CT_MapMod_WorldMap_ToggleSizeUp);


local function CT_MapMod_WorldMap_ToggleSizeDown()
	CT_MapMod_AdjustPositions();
end
hooksecurefunc("WorldMap_ToggleSizeDown", CT_MapMod_WorldMap_ToggleSizeDown);


hooksecurefunc("WorldMapFrame_SetOpacity",
	function(opacity)
		local alpha;
		alpha = 0.5 + (1.0 - opacity) * 0.50;
		CT_MapMod_MainButton:SetAlpha(alpha);
		CT_MapMod_CoordPlayer:SetAlpha(alpha);
		CT_MapMod_CoordCursor:SetAlpha(alpha);
		CT_MapMod_MapButtonFrame:SetAlpha(alpha);
		WorldMapTrackQuest:SetAlpha(alpha);
		WorldMapQuestShowObjectives:SetAlpha(alpha);
	end
);

hooksecurefunc("WorldMap_OpenToQuest",
	function(...)
		CT_MapMod_UpdateMap();
	end
);

hooksecurefunc("WorldMapFrame_ToggleWindowSize",
	function(...)
		CT_MapMod_UpdateMap();
	end
);


--------------------------------------------
-- Options Frame Code

-- Slash command
local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctmapmod", "/ctmap", "/mapmod");

-- Options frame
module.frame = function()
	local options = {};
	local yoffset = 5;
	local ysize;

	-- Tips
	ysize = 60;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Options",
		"font#t:0:-25#s:0:52#l:13:0#r#To access the options for CT_MapMod, open the game's World Map and click on the Notes button located near the right hand side of the title bar.#0.6:0.6:0.6:l",
	};
	yoffset = yoffset + ysize;

	return "frame#all", options;
end
