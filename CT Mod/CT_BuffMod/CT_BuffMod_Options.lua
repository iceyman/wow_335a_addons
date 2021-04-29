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
local buffObjectList = module.buffList;
local buffModFrame = module.buffFrame;

-- Options frame
local function updateSortType(frame, sortType)
	sortType = sortType or module:getOption("sortType");
	
	local windowOptions = frame.windowOptions;
	local sortOptions = frame.sortOptions;

	local keepRecastPosition = sortOptions.keepRecastPosition;
	if ( sortType == 1 ) then
		-- Type
		sortOptions.subSortTypeFont:Show();
		sortOptions.subSortType:Show();
		
		local subSortType = module:getOption("subSortType");
		if ( subSortType == 2 ) then
			keepRecastPosition:Show();
--			keepRecastPosition:SetPoint("TOPLEFT", 60, -315);
		else
			keepRecastPosition:Hide();
		end
		
	elseif ( sortType == 3 ) then
		-- Order
		sortOptions.subSortTypeFont:Hide();
		sortOptions.subSortType:Hide();
		keepRecastPosition:Show();
--		keepRecastPosition:SetPoint("TOPLEFT", 60, -295);
	else
		sortOptions.subSortTypeFont:Hide();
		sortOptions.subSortType:Hide();
		keepRecastPosition:Hide();
	end
end

local function updateSortTypeSequence()
	local buffTypes = {"AURA", "BUFF", "DEBUFF", "ITEM"};  -- Same sequence as in dropdown menu
	local buffType;
	local seqUsed = {};

	if (not module.sortTypeSequence) then
		module.sortTypeSequence = {};
	end

	module.sortTypeSequence[1] = (module.sortSeq1 or 1); -- Default first to AURA (item 1 in drop down menu)
	module.sortTypeSequence[2] = (module.sortSeq2 or 2); -- Default second to BUFF (item 2 in drop down menu)
	module.sortTypeSequence[3] = (module.sortSeq3 or 4); -- Default third to ITEM (item 4 in drop down menu)
	module.sortTypeSequence[4] = (module.sortSeq4 or 3); -- Default fourth to DEBUFF (item 3 in drop down menu)

	for k, v in ipairs(buffTypes) do
		module.buffSortTypes[v] = nil;
	end
	for k, v in ipairs(module.sortTypeSequence) do
		seqUsed[k] = false;
		buffType = buffTypes[v];
		if (buffType) then
			-- First item with this buffType gets the sequence number
			if (not module.buffSortTypes[buffType]) then
				module.buffSortTypes[buffType] = k;
				seqUsed[k] = true;
			end
		end
	end
	-- Check for items with the same sequence number
	for k, v in ipairs(buffTypes) do
		if (not module.buffSortTypes[v]) then
			-- Assign an unused sequence number
			local seq = 1;
			for k2, v2 in ipairs(seqUsed) do
				if (not v2) then
					seq = k2;
					break;
				end
			end
			module.buffSortTypes[v] = seq;
			seqUsed[seq] = true;
		end
	end
end

-- Options frame
local optionsFrameList;

local function optionsInit()
	optionsFrameList = {};

	-- Dummy frame representing a master frame.
	local frame = {};
	frame.offset = 0;
	frame.size = 0;
	frame.details = "";
	frame.yoffset = 0;
	frame.top = 0;
	frame.data = {};

	tinsert(optionsFrameList, frame);
end

local function optionsGetData()
	local frame = optionsFrameList[#optionsFrameList];
	return frame.data;
end

local function optionsAddFrame(offset, size, details)
	local yoffset;
	local prevFrame = optionsFrameList[#optionsFrameList];
	if (prevFrame) then
		yoffset = prevFrame.yoffset;
	else
		yoffset = 0;
	end
	yoffset = yoffset + offset;

	local frame = {};
	frame.offset = offset;
	frame.size = size;
	frame.details = details;
	frame.yoffset = 0;
	frame.top = yoffset;
	frame.data = {};

	tinsert(optionsFrameList, frame);
end

local function optionsAddObject(offset, size, details)
	local frame = optionsFrameList[#optionsFrameList];
	local yoffset = frame.yoffset + offset;

	details = gsub(details, "%%y", yoffset);
	details = gsub(details, "%%s", size);
	tinsert(frame.data, details);

	frame.yoffset = yoffset - size;
end

local function optionsAddScript(name, func)
	local frame = optionsFrameList[#optionsFrameList];
	frame.data[name] = func;
end

local function optionsEndFrame()
	local frame = tremove(optionsFrameList);

	local size = frame.size;
	local top = frame.top;
	local bot;
	if (size == 0) then
		bot = top + frame.yoffset;
	else
		bot = top - size;
	end

	local details = frame.details;

	details = gsub(details, "%%y", top);
	details = gsub(details, "%%b", bot);
	details = gsub(details, "%%s", size);

	local prevFrame = optionsFrameList[#optionsFrameList];
	prevFrame.yoffset = bot;
	prevFrame.data[details] = frame.data;
end

module.frame = function()
	local updateFunc = function(self, value)
		value = (value or self:GetValue());
		local timeLeft = floor( value * 10 + 0.5 ) / 10;
		if ( timeLeft == 0 ) then
			self.title:SetText("Off");
		else
			self.title:SetText(module.humanizeTime(timeLeft));
		end
		local option = self.option;
		if ( option ) then
			module:setOption(option, value, true);
		end
	end;

	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local offset;

	optionsInit();

	-- Tips
	optionsAddFrame(-5, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctbuff or /ctbuffmod to open this options window directly.#" .. textColor2 .. ":l");
	optionsEndFrame();

	-- Blizzard's frames
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r#i:blizzardFrames");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Blizzard's Frames");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:hideBlizzardBuffs:true#Hide the buffs frame");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:hideBlizzardConsolidated:true#Hide the consolidated buffs frame");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:hideBlizzardEnchants:true#Hide the weapon buffs frame");
	optionsEndFrame();

	-- Window Options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r#i:windowOptions");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Window");

		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:unlockWindow:true#Unlock window");
		optionsAddObject( -2, 3*13, "font#tl:46:%y#r#s:0:%s#When unlocked, click to drag the frame. Use the lower/upper right corner to resize the window.#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "checkbutton#tl:46:%y#o:showWindowTooltips:true#Show drag and resize tooltips");

		optionsAddObject( -8,   15, "font#tl:13:%y#v:ChatFontNormal#Vertical resizing direction:");
		optionsAddObject( 12,   20, "dropdown#tl:150:%y#s:100:50#n:CTBuffModResizeModeDropdown#o:resizeMode:1#Downwards#Upwards#Outwards");

		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:expandBuffs:true#Auto expand window height");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:clampWindow:true#Window cannot be moved off screen");

		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:showTitle:true#Show title");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showBorder#Show border");

		optionsAddObject( -2,   16, "colorswatch#tl:14:%y#s:16:16#o:backgroundColor:0,0,0,0.25#true");
		optionsAddObject( 14,   15, "font#tl:40:%y#v:ChatFontNormal#Background color");

		optionsAddFrame( -10,   30, "button#t:0:%y#s:180:%s#v:GameMenuButtonTemplate#Reset window position");
			optionsAddScript("onclick",
				function(self)
					module.resetWindowPosition();
				end
			);
		optionsEndFrame();
		optionsAddObject(-5, 3*13, "font#t:0:%y#s:0:%s#l#r#Note: This will place the CT_BuffMod window at the center of your screen. From there it can dragged anywhere on the screen.#" .. textColor2);
	optionsEndFrame();

	-- Contents Options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r#i:contentOptions");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Contents");

		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:expandUpwards#Display upwards");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:lockBuffOnEnter:true#Lock position while mouse is over icon");

		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:showTooltips:true#Show spell tooltips");
		optionsAddObject(  6,   26, "checkbutton#tl:46:%y#o:showItemDetails:true#Show weapon details for weapon buffs");
		optionsAddObject(  6,   26, "checkbutton#tl:46:%y#o:showCasterName:true#Show caster's name");
		optionsAddObject(  6,   26, "checkbutton#tl:46:%y#o:showSpellNumber#Show spell number");

		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:showAuras:true#Show auras");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showBuffs:true#Show buffs");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showDebuffs:true#Show debuffs");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showItemBuffs:true#Show weapon buffs");

	optionsEndFrame();

	-- Sort Options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r#i:sortOptions");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Sorting");

		optionsAddObject( -8,   15, "font#tl:10:%y#v:ChatFontNormal#Sort by:");
		optionsAddObject( 12,   20, "dropdown#tl:50:%y#s:100:%s#n:CTBuffModDropdown#o:sortType:1#Type#Time#Order#Name");

		optionsAddObject( -8,   15, "font#hidden#tl:30:%y#i:subSortTypeFont#v:ChatFontNormal#Sub-Sort by:");
		optionsAddObject( 12,   20, "dropdown#hidden#tl:100:%y#s:100:%s#i:subSortType#n:CTBuffModDropdown2#o:subSortType:1#Time#Order#Name");

		optionsAddObject( -5,   26, "checkbutton#hidden#tl:25:%y#i:keepRecastPosition#o:keepRecastPosition#Keep Recast Buff Position");

		optionsAddObject( -8,   15, "font#tl:10:%y#v:ChatFontNormal#Use this sequence when sorting by Type:");

		optionsAddObject( -8,   15, "font#tl:30:%y#v:ChatFontNormal#First:");
		optionsAddObject( 12,   20, "dropdown#tl:70:%y#s:100:%s#n:CTBuffModSeq1Dropdown#o:sortSeq1:1#Auras#Buffs#Debuffs#Weapons");

		optionsAddObject( -2,   15, "font#tl:30:%y#v:ChatFontNormal#Second:");
		optionsAddObject( 12,   20, "dropdown#tl:70:%y#s:100:%s#n:CTBuffModSeq2Dropdown#o:sortSeq2:2#Auras#Buffs#Debuffs#Weapons");

		optionsAddObject( -2,   15, "font#tl:30:%y#v:ChatFontNormal#Third:");
		optionsAddObject( 12,   20, "dropdown#tl:70:%y#s:100:%s#n:CTBuffModSeq3Dropdown#o:sortSeq3:4#Auras#Buffs#Debuffs#Weapons");

		optionsAddObject( -2,   15, "font#tl:30:%y#v:ChatFontNormal#Fourth:");
		optionsAddObject( 12,   20, "dropdown#tl:70:%y#s:100:%s#n:CTBuffModSeq4Dropdown#o:sortSeq4:3#Auras#Buffs#Debuffs#Weapons");

		optionsAddObject(  1,   26, "checkbutton#tl:10:%y#o:sortReverse#Reverse the direction of the sort");
	optionsEndFrame();

	-- Appearance Options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r#i:buffOptions");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Appearance");

		optionsAddObject(-18,   17, "slider#t:0:%y#s:170:%s#o:buffSize:20#Icon Size - <value>#15:45:1");
		optionsAddObject(-20,   17, "slider#t:0:%y#s:170:%s#o:buffSpacing:0#Vertical Spacing - <value>#0:30:1");

		optionsAddObject(-10,   26, "checkbutton#tl:10:%y#o:colorBuffs:true#Color the background");

		optionsAddObject(  0,   16, "colorswatch#tl:49:%y#s:16:16#o:bgColorAURA:0.35,0.8,0.15,0.5#true");
		optionsAddObject( 14,   15, "font#tl:75:%y#v:ChatFontNormal#Aura color");

		optionsAddObject( -2,   16, "colorswatch#tl:49:%y#s:16:16#o:bgColorBUFF:0.1,0.4,0.85,0.5#true");
		optionsAddObject( 14,   15, "font#tl:75:%y#v:ChatFontNormal#Buff color");

		optionsAddObject( -2,   16, "colorswatch#tl:49:%y#s:16:16#o:bgColorDEBUFF:1,0,0,0.85#true");
		optionsAddObject( 14,   15, "font#tl:75:%y#v:ChatFontNormal#Debuff color");

		optionsAddObject( -2,   16, "colorswatch#tl:49:%y#s:16:16#o:bgColorITEM:0.75,0.25,1,0.75#true");
		optionsAddObject( 14,   15, "font#tl:75:%y#v:ChatFontNormal#Weapon buff color");

		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:rightAlign#Show icon on right side");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showNames:true#Show name");
		optionsAddObject(  6,   26, "checkbutton#tl:46:%y#o:colorCodeDebuffs#Color code debuff names");

		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showTimers:true#Show time remaining text");

		optionsAddObject(  0,   15, "font#tl:50:%y#v:ChatFontNormal#Format:");
		optionsAddObject( 12,   20, "dropdown#tl:95:%y#s:145:%s#n:CTBuffModDropdown3#o:durationFormat#1 hour / 35 minutes#1 hour / 35 min#1h / 35m#1h 35m / 35m 15s#1:35h / 35:15");

		optionsAddObject( -2,   15, "font#tl:50:%y#v:ChatFontNormal#Location:");
		optionsAddObject( 12,   20, "dropdown#tl:95:%y#s:145:%s#n:CTBuffModDropdown4#o:durationLocation#Side#Below name");

		optionsAddObject(  1,   26, "checkbutton#tl:46:%y#o:durationCenter#Center time if not showing name");

		optionsAddObject(  4,   26, "checkbutton#tl:10:%y#o:showBuffTimer:true#Show time remaining bar");
		optionsAddObject(  6,   26, "checkbutton#tl:46:%y#o:showTimerBackground:true#Show the bar's background");
	optionsEndFrame();

	-- Expiration options
	optionsAddFrame(-20, 0, "frame#tl:0:%y#r#i:buffExpiration");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Expiration");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:flashIcons:true#Flash icon 15 seconds before expiring");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:enableExpiration:true#Enable expiration warning");
		optionsAddObject(  6,   26, "checkbutton#tl:46:%y#o:expirationCastOnly#Ignore buffs you cannot cast");
		optionsAddObject(  6,   26, "checkbutton#tl:46:%y#o:expirationSound:true#Play sound when warning is shown");

		optionsAddObject( -5,   15, "font#tl:49:%y#v:ChatFontNormal#Duration");
		optionsAddObject( 15,   15, "font#tl:150:%y#v:ChatFontNormal#Expiration Warning Time");

		optionsAddObject(-23,   15, "font#tl:49:%y#2:00  -  10:00");
		optionsAddFrame(  18,   17, "slider#tl:150:%y#o:expirationTime1:15#:Off:1 min.#0:60:5");
			optionsAddScript("onvaluechanged", updateFunc);
			optionsAddScript("onload", updateFunc);
		optionsEndFrame();

		optionsAddObject(-27,   15, "font#tl:49:%y#10:01  -  30:00");
		optionsAddFrame(  18,   17, "slider#tl:150:%y#o:expirationTime2:60#:Off:3 min.#0:180:5");
			optionsAddScript("onvaluechanged", updateFunc);
			optionsAddScript("onload", updateFunc);
		optionsEndFrame();

		optionsAddObject(-27,   15, "font#tl:49:%y#30:01  +");
		optionsAddFrame(  18,   17, "slider#tl:150:%y#o:expirationTime3:180#:Off:5 min.#0:300:5");
			optionsAddScript("onvaluechanged", updateFunc);
			optionsAddScript("onload", updateFunc);
		optionsEndFrame();
	optionsEndFrame();

	optionsAddFrame(-25, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Reset Options");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:resetAll#Reset options for all of your characters");
		optionsAddFrame(  -5,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset options");
			optionsAddScript("onclick", function(self)
				if (module:getOption("resetAll")) then
					CT_BuffModOptions = {};
				else
					if (not CT_BuffModOptions or not type(CT_BuffModOptions) == "table") then
						CT_BuffModOptions = {};
					else
						CT_BuffModOptions[module:getCharKey()] = nil;
					end
				end
				ConsoleExec("RELOADUI");
			end);
		optionsEndFrame();
		optionsAddObject( -7, 2*15, "font#t:0:%y#s:0:%s#l#r#Note: Resetting the options to their default values will reload your UI.#" .. textColor2);
	optionsEndFrame();

	optionsAddScript("onload", function(self)
		updateSortType(self);
	end);

	return "frame#all", optionsGetData();
end

local options = {
	showTitle = function(self, value)
		if ( value ~= false ) then
			buffModFrame.title:Show();
		else
			buffModFrame.title:Hide();
		end
	end,
	
	unlockWindow = function(self, value)
		module:unlockWindow(value ~= false);
	end,
	
	expandBuffs = function(self, value)
		module:expandBuffs(value ~= false);
	end,
	
	resizeMode = function(self, value)
		module:setResizeMode(value);
	end,

	showBorder = function(self, value)
		local alpha = 0;
		if (value) then
			alpha = 1;
		end
		module.showBorder = value;
		buffModFrame:SetBackdropBorderColor(1, 1, 1, alpha);
		module:clampBuffWindow();
	end,

	expandUpwards = function(self, value)
		module.expandUpwards = value;
		buffObjectList:position();
	end,
	
	rightAlign = function(self, value)
		module.rightAlign = value;
		buffObjectList:display();
	end,
	
	clampWindow = function(self, value)
		module.clampWindow = value ~= false;
		module:clampBuffWindow();
	end,

	showNames = function(self, value)
		module.showNames = value ~= false;
		buffObjectList:display();
	end,
	
	colorBuffs = function(self, value)
		module.colorBuffs = value ~= false;
		buffObjectList:display();
	end,
	
	showBuffTimer = function(self, value)
		module:showBuffTimers(value ~= false);
	end,
	
	buffSize = function(self, value)
		module:setBuffSize(value);
	end,
	
	showTimers = function(self, value)
		module.showTimers = value ~= false;
		buffObjectList:display();
	end,
	
	showTimerBackground = function(self, value)
		module.showTimerBackground = value ~= false;
		buffObjectList:display();
	end,
	
	lockBuffOnEnter = function(self, value)
		module.lockBuffOnEnter = (value ~= false);
		if (not module.lockBuffOnEnter) then
			-- The option is now off.
			-- If there was something locked, then unlock it.
			if (module.lockedBuff) then
				module.lockedBuff:unlock();
			end
		end
	end,

	durationCenter = function(self, value)
		module.durationCenter = value;
		buffObjectList:display();
	end,

	flashIcons = function(self, value)
		module.flashIcons = value ~= false;
		buffObjectList:checkExpiration();
	end,
	
	enableExpiration = function(self, value)
		module.enableExpiration = value ~= false;
		buffObjectList:checkExpiration();
	end,
	
	expirationSound = function(self, value)
		module.expirationSound = value ~= false;
	end,
	
	expirationCastOnly = function(self, value)
		module.expirationCastOnly = value;
	end,
	
	sortType = function(self, value)
		module:setSortType(value or 1);
		
		local frame = module.frame;
		if ( type(frame) ~= "function" ) then
			updateSortType(frame, value or 1);
		end
	end,
	
	subSortType = function(self, value)
		module:setSubSortType(value or 1);
		local frame = module.frame;
		if ( type(frame) ~= "function" ) then
			updateSortType(frame);
		end
	end,
	
	keepRecastPosition = function(self, value)
		module.keepRecastPosition = value;
	end,

	sortReverse = function(self, value)
		module:setSortReverse(value);
	end,

	sortSeq1 = function(self, value)
		module.sortSeq1 = value;
		updateSortTypeSequence();
		module:setSortType();
	end,
	
	sortSeq2 = function(self, value)
		module.sortSeq2 = value;
		updateSortTypeSequence();
		module:setSortType();
	end,

	sortSeq3 = function(self, value)
		module.sortSeq3 = value;
		updateSortTypeSequence();
		module:setSortType();
	end,

	sortSeq4 = function(self, value)
		module.sortSeq4 = value;
		updateSortTypeSequence();
		module:setSortType();
	end,

	expirationTime1 = function(self, value)
		module:setExpiration(1, value or 15);
	end,
	
	expirationTime2 = function(self, value)
		module:setExpiration(2, value or 60);
	end,
	
	expirationTime3 = function(self, value)
		module:setExpiration(3, value or 180);
	end,
	
	durationFormat = function(self, value)
		module:setTimeFormat(value or 1);
	end,
	
	durationLocation = function(self, value)
		module.durationBelow = value == 2;
		buffObjectList:display();
	end,
	
	backgroundColor = function(self, value)
		if ( value ) then
			buffModFrame:SetBackdropColor(unpack(value));
		else
			buffModFrame:SetBackdropColor(0, 0, 0, 0.25);
		end
	end,
	
	colorCodeDebuffs = function(self, value)
		module.colorCodeDebuffs = value;
		buffObjectList:display();
	end,
	
	buffSpacing = function(self, value)
		module:setSpacing(value or 0);
		buffObjectList:position();
	end,
	
	bgColorAURA = function(self, value)
		module:updateBackgroundColor("AURA", value);
		buffObjectList:display();
	end,
	
	bgColorBUFF = function(self, value)
		module:updateBackgroundColor("BUFF", value);
		buffObjectList:display();
	end,

	bgColorDEBUFF = function(self, value)
		module:updateBackgroundColor("DEBUFF", value);
		buffObjectList:display();
	end,
	
	bgColorITEM = function(self, value)
		module:updateBackgroundColor("ITEM", value);
		buffObjectList:display();
	end,

	hideBlizzardEnchants = function(self, value)
		module:hideBlizzardEnchants(value ~= false);
	end,

	hideBlizzardBuffs = function(self, value)
		module:hideBlizzardBuffs(value ~= false);
	end,

	hideBlizzardConsolidated = function(self, value)
		module:hideBlizzardConsolidated(value ~= false);
	end,

	showAuras = function(self, value)
		module:showAuras(value ~= false, type(module.frame) ~= "function");
	end,
	
	showBuffs = function(self, value)
		module:showBuffs(value ~= false, type(module.frame) ~= "function");
	end,
	
	showDebuffs = function(self, value)
		module:showDebuffs(value ~= false, type(module.frame) ~= "function");
	end,
	
	showItemBuffs = function(self, value)
		module:showItemBuffs(value ~= false, type(module.frame) ~= "function");
	end,

	showTooltips = function(self, value)
		module.showTooltips = (value ~= false);
	end,

	showCasterName = function(self, value)
		module.showCasterName = (value ~= false);
	end,

	showItemDetails = function(self, value)
		module.showItemDetails = (value ~= false);
	end,

	showSpellNumber = function(self, value)
		module.showSpellNumber = value;
	end,

	showWindowTooltips = function(self, value)
		module.showWindowTooltips = (value ~= false);
	end,

};

-- Prior to CT_BuffMod 3.302 the options frame was updating the character
-- specific setting for these options, while the updateFunc function
-- was updating the global setting.
-- We want to get rid of the global setting for those options.
module:setOption("expirationTime1", nil);  -- Remove global setting
module:setOption("expirationTime2", nil);  -- Remove global setting
module:setOption("expirationTime3", nil);  -- Remove global setting

module.update = function(self, type, value)
	self:mainupdate(type, value);
	if ( type == "init" ) then
		for key, val in pairs(options) do
			val(self, self:getOption(key));
		end
	else
		local f = options[type];
		if ( f ) then
			f(self, value);
		end
	end
end
