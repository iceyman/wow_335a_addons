tinsert(UISpecialFrames, "CT_RA_ChangelogFrame");
CT_RACHANGES_HEIGHT = 500;
function CT_RAChanges_DisplayDialog()
	CT_RA_ChangelogFrame:SetHeight(CT_RACHANGES_HEIGHT+25);
	-- Initialize dialog
		-- Set title
	CT_RA_ChangelogFrameTitle:SetText(CT_RA_Changes["title"]);
	
		-- Show sections
	local section, totalHeight = 1, 0;
	while ( CT_RA_Changes["section" .. section] ) do
		local objSection = getglobal("CT_RA_ChangelogFrameScrollFrameSection" .. section);
		local part, partHeights = 1, 0;
		
			-- Show section
		objSection:Show();
		
			-- Set section title
		getglobal(objSection:GetName() .. "Title"):SetText(CT_RA_Changes["section" .. section]["title"]);
		
			-- Show parts
		while ( CT_RA_Changes["section" .. section][part] ) do
			local objPart = getglobal("CT_RA_ChangelogFrameScrollFrameSection" .. section .. "Part" .. part);
			
				-- Show part
			objPart:Show();
			
				-- Set part stuff
			getglobal(objPart:GetName() .. "Text"):SetText(CT_RA_Changes["section" .. section][part][2]);
			getglobal(objPart:GetName() .. "Text"):SetHeight(CT_RA_Changes["section" .. section][part][1]);
			objPart:SetHeight(CT_RA_Changes["section" .. section][part][1]);
			partHeights = partHeights + CT_RA_Changes["section" .. section][part][1];
			part = part + 1;
		end
		local addedHeight = ( CT_RA_Changes["section" .. section]["addedHeight"] or 0);
		objSection:SetHeight(partHeights+35+addedHeight);
		totalHeight = totalHeight + partHeights+35+addedHeight;
		section = section + 1;
	end
	CT_RA_ChangelogFrameScrollFrameSection:SetHeight(totalHeight);
	ShowUIPanel(CT_RA_ChangelogFrame);
	CT_RA_ChangelogFrameScrollFrame:UpdateScrollChildRect();
	local minVal, maxVal = CT_RA_ChangelogFrameScrollFrameScrollBar:GetMinMaxValues();
	if ( maxVal == 0 ) then
		CT_RA_ChangelogFrameScrollFrameScrollBar:Hide();
	else
		CT_RA_ChangelogFrameScrollFrameScrollBar:Show();
	end
	CT_RA_ChangelogFrameScrollFrame:SetHeight(CT_RACHANGES_HEIGHT-75);
end

-- Add slash command
CT_RA_RegisterSlashCmd("/ralog", "Shows the changelog for this version.", 15, "RALOG", CT_RAChanges_DisplayDialog, "/ralog");

CT_RA_Changes = {
	["title"] = "CT_RaidAssist Update History (3.014 to 3.302)",
	
	-- |bxxxx|eb (yellow text)
	-- |gxxxx|eg (red text)
	["section1"] = {
		["title"] = "Version 3.302",
		{ 30, "Fixed a chat frame error." },
		["addedHeight"] = 10,
	},
	["section2"] = {
		["title"] = "Version 3.301",
		{ 30, "Added the command /ctraid as an alternative to the existing /raoptions and /ctra commands." },
		{ 30, "Fixed a debuff display issue that was occuring when a new debuff replaced an existing debuff on a player and the number of debuffs didn't change." },
		{ 30, "Fixed a problem involving the names of players on the same server as you. This was causing some CTRA messages in the addon channel to be ignored." },
		{ 50, "Raid target icons are now displayed on all raid frames (if the option to show the icons is enabled in CT_RaidAssist). This can be useful when used in combination with a boss fight addon that places raid target icons on players that get certain debuffs." },
		["addedHeight"] = 10,
	},
	["section3"] = {
		["title"] = "Version 3.300",
		{ 30, "Updated to work with the WoW 3.3 patch." },
		{ 60, "CT_RaidAssist no longer uses the 'RAID' addon channel while in a battleground. This prevents CT_RaidAssist from causing a 'You aren't in a party.' message to appear in the chat window. If you still get that message, then you probably have another addon that is using the 'RAID' addon channel in a battleground." },
		{ 30, "Changed the cooldown time for the Druid's Rebirth spell from 30 to 20 minutes." },
		{ 30, "Fixed a bug that might cause some raid frames to not update correctly." },
		["addedHeight"] = 10,
	},
	["section4"] = {
		["title"] = "Version 3.200",
		{ 30, "Updated to work with the WoW 3.2 patch." },
		["addedHeight"] = 10,
	},
	["section5"] = {
		["title"] = "Version 3.019",
		{ 30, "The range checking option now uses a 40 yard range if you are a druid, priest, paladin, or shaman (these classes have 40 yard healing spells)." },
		["addedHeight"] = 10,
	},
	["section6"] = {
		["title"] = "Version 3.018",
		{ 30, "Updated to work with the WoW 3.1 patch." },
		{ 30, "Corrected a problem that was preventing Dalaran Intellect and Dalaran Brilliance from appearing on raid frames." },
		["addedHeight"] = 10,
	},
	["section7"] = {
		["title"] = "Version 3.016",
		{ 30, "Added support for the Dalaran Intellect and Dalaran Brilliance spells." },
		{ 30, "Added an option to enable range checking for players and pets in the raid. This can be found in the 'Alpha frame' section of the 'Additional options' window." },
		["addedHeight"] = 10,
	},
	["section8"] = {
		["title"] = "Version 3.015",
		{ 30, "Added the shaman talent spell Cleanse Spirit as being capable of removing diseases, posions, and curses." },
		["addedHeight"] = 10,
	},
	["section9"] = {
		["title"] = "Version 3.014",
		{ 30, "Now displays the version number at the top of the options window" },
		{ 30, "Added a menu item to the options window which will take you to the group and class selection window." },
		{ 30, "Changed the priest reagent checked by /rareg to Devout Candle." },
		{ 30, "Changed the druid reagent checked by /rareg to Wild Spineleaf." },
		{ 30, "Added the druid spells Lifebloom and Wild Growth to the buff list." },
		["addedHeight"] = 20,
	},
	-- Max 10 sections.
};
for k, v in pairs(CT_RA_Changes) do
	if ( type(v) == "table" ) then
		for key, val in pairs(v) do
			if ( type(val) == "table" ) then
				while ( string.find(val[2], "|[bg].-|e[bg]") ) do
					CT_RA_Changes[k][key][2] = string.gsub(val[2], "^(.*)|b(.-)|eb(.*)$", "%1|c00FFD100%2|r%3");
					CT_RA_Changes[k][key][2] = string.gsub(CT_RA_Changes[k][key][2], "^(.*)|g(.-)|eg(.*)$", "%1|c00FF0000%2|r%3");
				end
			end
		end
	end
end