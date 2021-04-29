------------------------------------------------
--                CT_BuffMod                  --
--                                            --
-- Mod that allows you to heavily customize   --
-- the display of buffs to your liking.       --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local _G = getfenv(0);
local module = _G.CT_BuffMod;

local TOOLTIP = CreateFrame("GameTooltip", "CT_BuffModTooltip", nil, "GameTooltipTemplate");
local TOOLTIP_TITLE = _G.CT_BuffModTooltipTextLeft1;
TOOLTIP:SetOwner(WorldFrame, "ANCHOR_NONE");

--------------------------------------------
-- Local copies

local strmatch = strmatch;
local GetTime = GetTime;

--------------------------------------------
-- Gather data

local weaponEnchant1;
local weaponEnchant2;

-- Local copies of some options
local showAuras = true;
local showBuffs = true;
local showDebuffs = true;
local showItemBuffs = true;


-- buffObject properties:
--
-- (initialized in CT_BuffMod_Parsing.lua)
-- .bdIndex        -- UnitBuff() index number
--                    UnitDebuff() index number
--                    Weapon slot number (INVSLOT_MAINHAND or INVSLOT_OFFHAND)
-- .charges        -- Number of charges.
-- .dispelType     -- Type of dispel required (Magic, Disease, Poison, Curse, or nothing)
-- .duration       -- The full duration of the spell in seconds
-- .expirationTime -- The time when the spell will expire (remaining time == expirationTime - GetTime())
-- .name           -- The name of the spell
-- .spellId        -- Spell id number
-- .texture        -- Spell texture
-- .timeleft       -- Remaining time in seconds (as of the last time we calculated this value)
-- .type           -- "AURA", "BUFF", "DEBUFF", or "ITEM"
-- .updatedFlag    -- Used to track if a object has been updated during a scan.

-- (initialized in CT_BuffMod.lua)
-- .casterUnit     -- The unit of the buff's caster.
-- .casterName     -- Formatted string to be used in the buff's tooltip.
-- .frame          -- The object's frame
-- .index          -- The index number in to the buff object list.
-- .isFlashing     -- The object's icon is flashing (true) or not (nil).
-- .locked         -- Is true when the mouse is over the object's icon, locking the object's position within the window.
-- .serial         -- Serial number that may be assigned when buffObject:add() or :renew() is called.
-- .showedWarning  -- Flag that indicates if we've shown an expiration warning for this object yet (true, nil).


-- frame properties:
-- .background -- Texture
-- .bgtimer    -- Texture
-- .buffObject -- The object containing information about the buff/debuff/aura/item.
-- .icon       -- The buffObject's icon button
-- .name       -- Font string used to display the spell name
-- .spark      -- Texture
-- .timeleft   -- Font string used to display the time remaining
-- .update     -- Time remaining (in seconds) before the OnUpdate script updates the buffObject.
-- .updateInterval -- How often (in seconds) the buff object's frame's OnUpdate script will be called.


local function setUnit()
	-- Determine the unit to use for the UnitBuff/UnitDebuff functions, etc.
	local unit;
	if (UnitHasVehicleUI("player")) then
		unit = "vehicle";
	else
		unit = "player";
	end
	-- If the unit has changed...
	if (unit ~= module.auraUnit) then
		-- Remove all buffs/debuffs/auras/enchants.
		local buffObjectList = module.buffList;
		for index = #buffObjectList, 1, -1 do
			buffObject = buffObjectList[index];
			buffObject:drop();
		end
		weaponEnchant1 = nil;
		weaponEnchant2 = nil;
		module.auraUnit = unit;
	end
	return unit;
end

local function unitName(unit)
	local name, realm = UnitName(unit);
	if (name and realm and realm ~= "") then
		return name .. "-" .. realm;
	end
	return name;
end

--------------------------------
-- Buffs/Debuffs/Auras

local function scanAuras2(buffFlag)
	-- ----------
	-- Scan the buffs/debuffs/auras and update the object list.
	-- Called from scanAuras().
	-- ----------
	local name, rank, texture, count, dispelType, duration, expirationTime, casterUnit, isStealable, shouldConsolidate, spellId;
	local bdIndex;
	local func;
	local buffObjectList = module.buffList;
	local unit = module.auraUnit;

	if (buffFlag) then
		func = UnitBuff;
	else
		func = UnitDebuff;
	end

	-- UnitBuff() & UnitDebuff() return values:
	-- [1] name -- Name (eg. "Power Word: Fortitude")
	-- [2] rank -- Rank (eg. "Rank 8") ("" if no rank)
	-- [3] texture -- Texture path (eg. "Interface\\Icons\\Spell_Holy_WordFortitude")
	-- [4] count -- Number of charges (0 == does not stack, 1 == 1 stack, etc)
	-- [5] dispelType -- Dispel type ("Magic", "Curse", "Disease", "Poison", nil==Not dispellable)
	-- [6] duration -- Full duration in seconds (0 == infinite)
	-- [7] expirationTime -- Time when it expires (0 == never expires) (eg. 39470.815)
	-- [8] casterUnit -- The unit that cast it (eg. "player")
	-- [9] isStealable -- (nil == )
	-- [10] shouldConsolidate -- (1==Yes, nil==No)
	-- [11] spellId -- Spell number

	-- Get information about the first one.
	bdIndex = 1;
	name, rank, texture, count, dispelType, duration, expirationTime, casterUnit, isStealable, shouldConsolidate, spellId = func(unit, bdIndex);

	while (name) do
		local buffObject, timeleft;
		local showObject;

		duration = (duration or 0);

		-- Is this item already in the table?
		buffObject = nil;
		for index, value in ipairs(buffObjectList) do
			-- If buff/debuff has a spell id...
			if (spellId) then
				-- If the spell id matches the one in our list..
				if (spellId == value.spellId) then
					buffObject = value;
					break;
				end
			else
				-- The buff/debuff has no spell id, so compare the name and textures instead.
				if (value.name == name and value.texture == texture) then
					buffObject = value;
					break;
				end
			end
		end
		
		-- Does the user want to show this type of object?
		showObject = false;
		if (buffFlag) then
			if (duration == 0) then
				if (showAuras) then
					showObject = true;
				end
			else
				if (showBuffs) then
					showObject = true;
				end
			end
		else
			if (showDebuffs) then
				showObject = true;
			end
		end

		if (showObject) then
			count = (count or 0);
			expirationTime = (expirationTime or 0);
			timeleft = expirationTime - GetTime();
			if (timeleft < 0) then
				timeleft = 0;
			end
			if (buffObject) then
				-- Update the existing object.
				buffObject.bdIndex = bdIndex;

				-- If expiration time is different, then this buff was renewed.
				if (buffObject.expirationTime ~= expirationTime) then
					buffObject.expirationTime = expirationTime;
					buffObject.timeleft = timeleft;
					buffObject:renew();
				end

				-- If the number of charges changed, then update the displayed count.
				if (buffObject.charges ~= count) then
					buffObject.charges = count;
					buffObject:updateCharges();
				end
			else
				-- This buff/debuff is not in the buff object list yet.
				local x, masterUnit, masterClass;

				-- Create a new object.
				buffObject = module:getBuffObject();
				buffObject.bdIndex = bdIndex;
				buffObject.charges = count;
				buffObject.dispelType = dispelType;
				buffObject.duration = duration;
				buffObject.expirationTime = expirationTime;
				buffObject.name = name;
				buffObject.spellId = spellId;
				buffObject.texture = texture;
				buffObject.timeleft = timeleft;
				if (buffFlag) then
					if (duration == 0) then
						buffObject.type = "AURA";
					else
						buffObject.type = "BUFF";
					end
				else
					buffObject.type = "DEBUFF";
				end
				buffObject:setCasterUnit(casterUnit);

				buffObject:add();
			end
			buffObject.updatedFlag = true;  -- checked for in scanAuras()
		else
			-- We don't want to show this object
			if (buffObject) then
				buffObject:drop();
			end
		end

		bdIndex = bdIndex + 1;
		name, rank, texture, count, dispelType, duration, expirationTime, casterUnit, isStealable, shouldConsolidate, spellId = func(unit, bdIndex);
	end
end

local function scanAuras()
	-- ----------
	-- Scan for buffs, debuffs, and auras.
	-- ----------
	local buffObject;
	local buffObjectList = module.buffList;

	setUnit();

	-- Flag everything so we can tell if they get updated.
	for index, buffObject in ipairs(buffObjectList) do
		buffObject.updatedFlag = false;
	end

	-- Since this function doesn't update the weapon enchants,
	-- set the weapon enchants' update flags to true so that
	-- we don't drop them.
	if (weaponEnchant1) then
		weaponEnchant1.updatedFlag = true;
	end
	if (weaponEnchant2) then
		weaponEnchant2.updatedFlag = true;
	end

	-- Scan for buffs and auras
	if (showBuffs or showAuras) then
		scanAuras2(true);
	end

	-- Scan for debuffs
	if (showDebuffs) then
		scanAuras2(false);
	end

	-- Remove buffs/debuffs/auras that are no longer present.
	for index = #buffObjectList, 1, -1 do
		buffObject = buffObjectList[index];
		if (not buffObject.updatedFlag) then
			buffObject:drop();
		end
	end
end

--------------------------------
-- Weapon enchants

local function getWeaponEnchantInfo(slot, unit)
	-- Get information about a weapon enchant.

	-- Extract the enchant name and time remaining from the weapon's tooltip.
	local text, name, numLines;
	TOOLTIP:ClearLines();
	TOOLTIP:SetInventoryItem(unit, slot);
	numLines = TOOLTIP:NumLines();
	for i = 1, numLines do
		text = _G["CT_BuffModTooltipTextLeft" .. i]:GetText();
		name = strmatch(text, "^(.+) %(%d+%s+.+%)$");
		if (name) then
			break;
		end
	end

	-- Return the enchant name (or nil), and the weapon texture.
	return name, GetInventoryItemTexture(unit, slot);
end

local function scanEnchantments()
	-- Scan for weapon enchants
	local unit = setUnit();

	local isPlayer = (unit == "player");
	local enchanted1, timeleft1, count1, enchanted2, timeleft2, count2 = GetWeaponEnchantInfo();

	for hand = 1, 2 do
		local slot, enchanted, timeleft, count;
		local buffObject;

		if (hand == 1) then
			buffObject = weaponEnchant1;
			slot = (INVSLOT_MAINHAND or 16);
			enchanted = enchanted1;
			timeleft = (timeleft1 or 0);
			count = (count1 or 0);
		else
			buffObject = weaponEnchant2;
			slot = (INVSLOT_OFFHAND or 17);
			enchanted = enchanted2;
			timeleft = (timeleft2 or 0);
			count = (count2 or 0);
		end

		-- If this hand is enchanted, and user wants to see item buffs, and the unit is the player...
		if (enchanted and showItemBuffs and isPlayer) then

			local addEnchant;
			local name, texture, expirationTime;

			timeleft = timeleft / 1000; -- Convert from milliseconds to seconds.
			expirationTime = GetTime() + timeleft;

			name, texture = getWeaponEnchantInfo(slot, unit);
			if (not name) then
				-- Weapon is enchanted, but we couldn't figure out what the enchant name is.
				if (timeleft < 1) then
					-- When the timeleft reaches zero, the game will drop the name from
					-- the tooltip. However, GetWeaponEnchantInfo() continues to indicate
					-- (for a few more seconds) that the weapon is enchanted.
					if (buffObject) then
						-- Continue using the name we had for it.
						name = buffObject.name;
					else
						name = UNKNOWN;
					end
				else
					name = UNKNOWN;
				end
			end

			-- If we previously recorded an enchant for this hand...
			if (buffObject) then

				-- If this looks to be the same enchant as before...
				if (name == buffObject.name and texture == buffObject.texture) then
					local oldTimeleft, oldCharges;

					oldTimeleft = buffObject.timeleft;
					oldCharges = buffObject.charges;

					buffObject.bdIndex = slot;
					buffObject.expirationTime = expirationTime;
					buffObject.timeleft = timeleft;

					if (timeleft > buffObject.duration) then
						buffObject.duration = timeleft;
					end

					-- Renew or update the buff object.
					if (timeleft > oldTimeleft + 0.5) then
						-- The buff object was renewed.
						buffObject:renew();
					else
						-- Update the time remaining
						buffObject:updateTimeDisplay();
					end

					-- If the number of charges changed...
					if (count ~= oldCharges) then
						buffObject.charges = count;
						buffObject:updateCharges();
					end

					buffObject.updatedFlag = true;  -- checked for in scanAuras()
				else
					-- This appears to be a different enchant than before.

					-- Drop the old buff object.
					buffObject:drop();
					buffObject = nil;

					-- Add a new buff object.
					addEnchant = true;
				end
			else
				-- We don't have a previous enchant recorded for this hand.

				-- Add a new buff object.
				addEnchant = true;
			end

			if (addEnchant) then
				local class;

				buffObject = module:getBuffObject();

				buffObject.bdIndex = slot;
				buffObject.charges = count;
				buffObject.dispelType = nil;
				buffObject.duration = timeleft;
				buffObject.expirationTime = expirationTime;
				buffObject.name = name;
				buffObject.spellId = nil;
				buffObject.texture = texture;
				buffObject.timeleft = timeleft;
				buffObject.type = "ITEM";
				buffObject:setCasterUnit("player");

				buffObject:add();

				buffObject.updatedFlag = true;  -- checked for in scanAuras()
			end
		else
			-- This hand is not enchanted, or we don't want this enchant in the buff object list.
			if (buffObject) then
				-- Drop the buff object.
				buffObject:drop();
				buffObject = nil;
			end
		end

		if (hand == 1) then
			weaponEnchant1 = buffObject;
		else
			weaponEnchant2 = buffObject;
		end
	end
end

--------------------------------
-- Options

function module:showAuras(show, scan)
	-- Set a local var to hold the "Show auras" option's value.
	showAuras = show;
	if (scan) then
		scanAuras();
	end
end

function module:showBuffs(show, scan)
	-- Set a local var to hold the "Show buffs" option's value.
	showBuffs = show;
	if (scan) then
		scanAuras();
	end
end

function module:showDebuffs(show, scan)
	-- Set a local var to hold the "Show debuffs" option's value.
	showDebuffs = show;
	if (scan) then
		scanAuras();
	end
end

function module:showItemBuffs(show, scan)
	-- Set a local var to hold the "Show item buffs" option's value.
	showItemBuffs = show;
	if (scan) then
		scanEnchantments();
	end
end

--------------------------------
-- OnEvent handlers

local function onEvent(event, arg1, ...)
	-- OnEvent handler

	if (event == "UNIT_AURA") then
		local unit = setUnit();
		if (arg1 ~= unit) then
			return;
		end
		scanAuras();

	elseif (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") then
		if (arg1 ~= "player") then
			return;
		end
		scanAuras();
		scanEnchantments();

	elseif (event == "PLAYER_ENTERING_WORLD") then
		scanAuras();
		scanEnchantments();

	end
end

module:regEvent("UNIT_AURA", onEvent);
module:regEvent("PLAYER_ENTERING_WORLD", onEvent);
module:regEvent("UNIT_ENTERED_VEHICLE", onEvent);
module:regEvent("UNIT_EXITED_VEHICLE", onEvent);

--------------------------------
-- Scheduled updates

local function updateTimeRemaining()
	-- Update the time remaining on all buffs/debuffs/auras/enchants
	if (not module.auraUnit) then
		return;
	end

	local buffObjectList = module.buffList;
	local timeleft;

	for key, buffObject in ipairs(buffObjectList) do
		timeleft = buffObject.expirationTime - GetTime();
		if (timeleft < 0) then
			timeleft = 0;
		end
		buffObject.timeleft = timeleft;
		buffObject:updateTimeDisplay();
	end
end

module:schedule(0.25, true, updateTimeRemaining);
module:schedule(1, true, scanEnchantments);
