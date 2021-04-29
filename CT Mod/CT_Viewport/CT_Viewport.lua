------------------------------------------------
--                CT_Viewport                 --
--                                            --
-- Allows you to customize the rendered game  --
-- area, resulting in an overall more         --
-- customizable and usable  user interface.   --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

-- Initialization
local module = { };

local MODULE_NAME = "CT_Viewport";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

CT_Library:registerModule(module);

-- module.frame = "CT_ViewportFrame";
-- module.external = true;

-- Mod code below
local parentWidth, parentHeight;

CT_Viewport = {
	["initialValues"] = {
		[1] = 563,
		[2] = 937, 
		[3] = 736,
		[4] = 455,
		[5] = 375,
		[6] = 281
	},
	["currOffset"] = {
		0, 0, 0, 0
	}
};
CT_Viewport_Saved = { 0, 0, 0, 0, 0, 0, 0 };

-- Not going to bother adding a localization file :)
CT_VIEWPORT_INFO = "Note: |c00FFFFFFLeft click and drag a yellow bar to move the viewport screen.  To enter a custom value, type in the number and hit enter to set it, then click apply to see your changes.|r";
if ( GetLocale() == "deDE" ) then
	CT_VIEWPORT_INFO = "Note: |c00FFFFFFLeft click and drag a yellow bar to move the viewport screen.  To enter a custom value, type in the number and hit enter to set it, then click apply to see your changes.|r";
elseif ( GetLocale() == "frFR" ) then
	CT_VIEWPORT_INFO = "Note: |c00FFFFFFLeft click and drag a yellow bar to move the viewport screen. To enter a custom value, type in the number and hit enter to set it, then click apply to see your changes.|r";
end

local frameClearAllPoints, frameSetAllPoints, frameSetPoint;

function CT_Viewport_GetQuotient(number)
	number = format("%.2f", number);
	
	for a = 1, 100, 1 do
		for b = 1, 100, 1 do
			if ( format("%.2f", b/a) == number ) then
				return format("%.2f |r(|c00FFFFFF%d/%d|r)", number, b, a);
			elseif ( format("%.2f", a/b) == number ) then
				return format("%.2f |r(|c00FFFFFF%d/%d|r)", number, a, b);
			end
		end 
	end
	return number;
end

-- Add to special frames table
tinsert(UISpecialFrames, "CT_ViewportFrame");

-- Slash command to display the frame
SlashCmdList["VIEWPORT"] = function(msg)
	local iStart, iEnd, left, right, top, bottom = string.find(msg, "^(%d+) (%d+) (%d+) (%d+)$");
	if ( left and right and top and bottom ) then
		CT_Viewport_ApplyViewport(tonumber(left), tonumber(right), tonumber(top), tonumber(bottom));
	else
		ShowUIPanel(CT_ViewportFrame);
	end
end
SLASH_VIEWPORT1 = "/viewport";
SLASH_VIEWPORT2 = "/ctvp";
SLASH_VIEWPORT3 = "/ctviewport";

-- Resizing functions
function CT_Viewport_Resize(button, anchorPoint)
	button:GetParent():StartSizing(anchorPoint);
	CT_Viewport.isResizing = anchorPoint;
	
	-- A bit hackish, but meh, it works
	if ( anchorPoint == "LEFT" ) then
		button:GetParent():SetMaxResize(CT_Viewport.initialValues[5]-(CT_Viewport.initialValues[2]-CT_ViewportFrameInnerFrame:GetRight()), CT_Viewport.initialValues[6]);
	elseif ( anchorPoint == "RIGHT" ) then
		button:GetParent():SetMaxResize(CT_Viewport.initialValues[5]-(CT_ViewportFrameInnerFrame:GetLeft()-CT_Viewport.initialValues[1]), CT_Viewport.initialValues[6]);
	elseif ( anchorPoint == "TOP" ) then
		button:GetParent():SetMaxResize(CT_Viewport.initialValues[5], CT_Viewport.initialValues[6]-(CT_ViewportFrameInnerFrame:GetBottom()-CT_Viewport.initialValues[4]));
	elseif ( anchorPoint == "BOTTOM" ) then
		button:GetParent():SetMaxResize(CT_Viewport.initialValues[5], CT_Viewport.initialValues[6]-(CT_Viewport.initialValues[3]-CT_ViewportFrameInnerFrame:GetTop()));
	elseif ( anchorPoint == "TOPLEFT" ) then
		button:GetParent():SetMaxResize(CT_Viewport.initialValues[5]-(CT_Viewport.initialValues[2]-CT_ViewportFrameInnerFrame:GetRight()), CT_Viewport.initialValues[6]-(CT_ViewportFrameInnerFrame:GetBottom()-CT_Viewport.initialValues[4]));
	elseif ( anchorPoint == "TOPRIGHT" ) then
		button:GetParent():SetMaxResize(CT_Viewport.initialValues[5]-(CT_ViewportFrameInnerFrame:GetLeft()-CT_Viewport.initialValues[1]), CT_Viewport.initialValues[6]-(CT_ViewportFrameInnerFrame:GetBottom()-CT_Viewport.initialValues[4]));
	elseif ( anchorPoint == "BOTTOMLEFT" ) then
		button:GetParent():SetMaxResize(CT_Viewport.initialValues[5]-(CT_Viewport.initialValues[2]-CT_ViewportFrameInnerFrame:GetRight()), CT_Viewport.initialValues[6]-(CT_Viewport.initialValues[3]-CT_ViewportFrameInnerFrame:GetTop()));
	elseif ( anchorPoint == "BOTTOMRIGHT" ) then
		button:GetParent():SetMaxResize(CT_Viewport.initialValues[5]-(CT_ViewportFrameInnerFrame:GetLeft()-CT_Viewport.initialValues[1]), CT_Viewport.initialValues[6]-(CT_Viewport.initialValues[3]-CT_ViewportFrameInnerFrame:GetTop()));
	end
end

function CT_Viewport_StopResize(button)
	button:GetParent():StopMovingOrSizing();
	CT_Viewport.isResizing = nil;
	CT_ViewportFrameAspectRatioNewText:SetText("Aspect Ratio (Current): |c00FFFFFF" .. CT_Viewport_GetQuotient((CT_Viewport.screenRes[1]-CT_Viewport.currOffset[1]-CT_Viewport.currOffset[2])/(CT_Viewport.screenRes[2]-CT_Viewport.currOffset[3]-CT_Viewport.currOffset[4])));
	CT_ViewportFrameAspectRatioDefaultText:SetText("Aspect Ratio (Default): |c00FFFFFF" .. CT_Viewport_GetQuotient(CT_Viewport.screenRes[1]/CT_Viewport.screenRes[2]));
end

-- Get initial size values
function CT_Viewport_GetInitialValues()
	CT_Viewport.initialValues = {
		CT_ViewportFrameInnerFrame:GetLeft(),
		CT_ViewportFrameInnerFrame:GetRight(),
		CT_ViewportFrameInnerFrame:GetTop(),
		CT_ViewportFrameInnerFrame:GetBottom(),
		CT_ViewportFrameInnerFrame:GetRight()-CT_ViewportFrameInnerFrame:GetLeft(),
		CT_ViewportFrameInnerFrame:GetTop()-CT_ViewportFrameInnerFrame:GetBottom()
	};
end

-- Get current resolution in x and y
function CT_Viewport_GetCurrentResolution(...)
	local currRes = select(GetCurrentResolution(), ...);
	if ( currRes ) then
		local useless, useless, x, y = string.find(currRes, "(%d+)x(%d+)");
		if ( x and y ) then
			return tonumber(x), tonumber(y);
		end
	end
	return nil;
end

-- Apply the viewport settings
function CT_Viewport_ApplyViewport(left, right, top, bottom, r, g, b)
	if ( not left ) then
		right = ((CT_Viewport.initialValues[2]-CT_ViewportFrameInnerFrame:GetRight())/CT_Viewport.initialValues[5])*CT_Viewport.screenRes[1];
		left = ((CT_ViewportFrameInnerFrame:GetLeft()-CT_Viewport.initialValues[1])/CT_Viewport.initialValues[5])*CT_Viewport.screenRes[1];
		top = ((CT_Viewport.initialValues[3]-CT_ViewportFrameInnerFrame:GetTop())/CT_Viewport.initialValues[6])*CT_Viewport.screenRes[2];
		bottom = ((CT_ViewportFrameInnerFrame:GetBottom()-CT_Viewport.initialValues[4])/CT_Viewport.initialValues[6])*CT_Viewport.screenRes[2];
	end
	if ( right < 0 ) then
		right = 0;
	end
	if ( left < 0 ) then
		left = 0;
	end
	if ( top < 0 ) then
		top = 0;
	end
	if ( bottom < 0 ) then
		bottom = 0;
	end
	
	r = ( r or 0 );
	g = ( g or 0 );
	b = ( b or 0 );
	
	CT_Viewport_Saved = { left, right, top, bottom, r, g, b }; -- Need to reverse top and bottom because of how it works

	local update = true;
	if (WorldFrame:IsProtected() and InCombatLockdown()) then
		update = false;
	end
	if (update) then
		frameClearAllPoints(WorldFrame);
		frameSetPoint(WorldFrame, "TOPLEFT", (parentWidth/CT_Viewport.screenRes[1])*left, -(parentHeight/CT_Viewport.screenRes[2])*top);
		frameSetPoint(WorldFrame, "BOTTOMRIGHT", -(parentWidth/CT_Viewport.screenRes[1])*right, (parentHeight/CT_Viewport.screenRes[2])*bottom);
	end

	CT_ViewportOverlay:SetVertexColor(r, g, b, 1);
end

function CT_Viewport_ApplySavedViewport()
	CT_Viewport_ApplyViewport(CT_Viewport_Saved[1], CT_Viewport_Saved[2], CT_Viewport_Saved[3], CT_Viewport_Saved[4], CT_Viewport_Saved[5], CT_Viewport_Saved[6], CT_Viewport_Saved[7]);
end

-- Apply saved settings to the inner viewport
function CT_Viewport_ApplyInnerViewport(left, right, top, bottom, r, g, b)
	CT_ViewportFrameLeftEB:SetText(floor(left+0.5));
	CT_ViewportFrameRightEB:SetText(floor(right+0.5));
	CT_ViewportFrameTopEB:SetText(floor(top+0.5));
	CT_ViewportFrameBottomEB:SetText(floor(bottom+0.5));
	CT_Viewport.currOffset = {
		floor(left+0.5), floor(right+0.5), floor(top+0.5), floor(bottom+0.5)
	};
	CT_ViewportFrameAspectRatioNewText:SetText("Aspect Ratio (Current): |c00FFFFFF" .. CT_Viewport_GetQuotient((CT_Viewport.screenRes[1]-left-right)/(CT_Viewport.screenRes[2]-top-bottom)));
	CT_ViewportFrameAspectRatioDefaultText:SetText("Aspect Ratio (Default): |c00FFFFFF" .. CT_Viewport_GetQuotient(CT_Viewport.screenRes[1]/CT_Viewport.screenRes[2]));
	left = left*(CT_Viewport.initialValues[5]/CT_Viewport.screenRes[1]);
	right = right*(CT_Viewport.initialValues[5]/CT_Viewport.screenRes[1]);
	top = top*(CT_Viewport.initialValues[6]/CT_Viewport.screenRes[2]);
	bottom = bottom*(CT_Viewport.initialValues[6]/CT_Viewport.screenRes[2]);
	CT_ViewportFrameInnerFrame:ClearAllPoints();
	CT_ViewportFrameInnerFrame:SetPoint("TOPLEFT", "CT_ViewportFrameBorderFrame", "TOPLEFT", left+4, -(top+4));
	CT_ViewportFrameInnerFrame:SetPoint("BOTTOMRIGHT", "CT_ViewportFrameBorderFrame", "BOTTOMRIGHT", -(right+4), bottom+4);
	local frameTop, frameBottom, frameLeft, frameRight = CT_ViewportFrameInnerFrame:GetTop(), CT_ViewportFrameInnerFrame:GetBottom(), CT_ViewportFrameInnerFrame:GetLeft(), CT_ViewportFrameInnerFrame:GetRight();
	if ( frameTop and frameBottom and frameLeft and frameRight ) then
		CT_ViewportFrameInnerFrame:SetHeight(frameTop-frameBottom);
		CT_ViewportFrameInnerFrame:SetWidth(frameRight-frameLeft);
	else
		CT_ViewportFrame.awaitingValues = 1;
	end
end

-- Change a side of the viewport
function CT_Viewport_ChangeViewportSide(editBox)
	local value = tonumber(editBox:GetText());
	if ( not value ) then
		return;
	end
	value = abs(value);
	local id = editBox:GetID();
	local left, right, top, bottom, width, height = CT_Viewport.currOffset[1], CT_Viewport.currOffset[2], CT_Viewport.currOffset[3], CT_Viewport.currOffset[4];
	if ( id == 1 ) then
		-- Left
		CT_Viewport_ApplyInnerViewport(value, right, top, bottom);
	elseif ( id == 2 ) then
		-- Right
		CT_Viewport_ApplyInnerViewport(left, value, top, bottom);
	elseif ( id == 3 ) then
		-- Top
		CT_Viewport_ApplyInnerViewport(left, right, value, bottom);
	elseif ( id == 4 ) then
		-- Bottom
		CT_Viewport_ApplyInnerViewport(left, right, top, value);
	end
end

-- Handlers
	-- OnLoad
function CT_ViewportFrame_OnLoad(self)
	frameClearAllPoints = CT_ViewportFrame.ClearAllPoints
	frameSetAllPoints = CT_ViewportFrame.SetAllPoints
	frameSetPoint = CT_ViewportFrame.SetPoint

	hooksecurefunc(WorldFrame, "ClearAllPoints", function() CT_Viewport_ApplySavedViewport() end);
	hooksecurefunc(WorldFrame, "SetAllPoints", function() CT_Viewport_ApplySavedViewport() end);
	hooksecurefunc(WorldFrame, "SetPoint", function() CT_Viewport_ApplySavedViewport() end);

	local x, y = CT_Viewport_GetCurrentResolution(GetScreenResolutions());
	if ( x and y ) then
		local modifier = x/y;
		if ( modifier ~= (4/3) ) then
			local newViewportHeight = CT_Viewport.initialValues[6]/(x/y);
			CT_ViewportFrameInnerFrame:SetHeight(newViewportHeight);
			CT_ViewportFrameBorderFrame:SetHeight(newViewportHeight+8);
		end
		CT_Viewport.screenRes = { x, y };
		CT_ViewportFrame:SetHeight(210+CT_ViewportFrameBorderFrame:GetHeight());
		CT_Viewport.awaitingValues = 1;
	end
	CT_ViewportFrameInnerFrame:SetBackdropBorderColor(1, 1, 0, 1);
	CT_ViewportFrameBorderFrame:SetBackdropBorderColor(1, 0, 0, 1);
	CT_ViewportFrameInnerFrameBackground:SetVertexColor(1, 1, 0, 0.1);
	
	CT_ViewportOverlay = WorldFrame:CreateTexture("CT_ViewportOverlay", "BACKGROUND");
	CT_ViewportOverlay:SetTexture(1, 1, 1, 1);
	CT_ViewportOverlay:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", -1, 1);
	CT_ViewportOverlay:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", 1, -1);
	self:RegisterEvent("VARIABLES_LOADED");
end

	-- OnUpdate
function CT_ViewportFrame_OnUpdate(self, elapsed)
	if ( not self.hasAppliedViewport ) then
		self.hasAppliedViewport = 1;
		CT_ViewportFrameInnerFrame:ClearAllPoints();
		CT_ViewportFrameInnerFrame:SetPoint("TOPLEFT", "CT_ViewportFrameBorderFrame", "TOPLEFT", 4, -4);
		CT_ViewportFrameInnerFrame:SetPoint("BOTTOMRIGHT", "CT_ViewportFrameBorderFrame", "BOTTOMRIGHT", -4, 4);
	elseif ( self.hasAppliedViewport == 1 ) then
		self.hasAppliedViewport = 2;
		if ( CT_Viewport.awaitingValues ) then
			CT_Viewport_GetInitialValues();
			CT_Viewport.awaitingValues = nil;
			CT_ViewportFrameInnerFrame:SetMinResize(CT_Viewport.initialValues[5]/2, CT_Viewport.initialValues[6]/2);
			CT_ViewportFrameLeftEB.limitation = CT_Viewport.screenRes[1]/2;
			CT_ViewportFrameRightEB.limitation = CT_Viewport.screenRes[1]/2;
			CT_ViewportFrameTopEB.limitation = CT_Viewport.screenRes[2]/2;
			CT_ViewportFrameBottomEB.limitation = CT_Viewport.screenRes[2]/2;
		end
		CT_ViewportFrame_OnShow();
	end
	if ( CT_Viewport.isResizing ) then
		local right = ((CT_Viewport.initialValues[2]-CT_ViewportFrameInnerFrame:GetRight())/CT_Viewport.initialValues[5])*CT_Viewport.screenRes[1];
		local left = ((CT_ViewportFrameInnerFrame:GetLeft()-CT_Viewport.initialValues[1])/CT_Viewport.initialValues[5])*CT_Viewport.screenRes[1];
		local top = ((CT_Viewport.initialValues[3]-CT_ViewportFrameInnerFrame:GetTop())/CT_Viewport.initialValues[6])*CT_Viewport.screenRes[2];
		local bottom = ((CT_ViewportFrameInnerFrame:GetBottom()-CT_Viewport.initialValues[4])/CT_Viewport.initialValues[6])*CT_Viewport.screenRes[2];
		if ( right < 0 ) then
			right = 0;
		end
		if ( left < 0 ) then
			left = 0;
		end
		if ( top < 0 ) then
			top = 0;
		end
		if ( bottom < 0 ) then
			bottom = 0;
		end
		CT_ViewportFrameLeftEB:SetText(floor(left+0.5));
		CT_ViewportFrameRightEB:SetText(floor(right+0.5));
		CT_ViewportFrameTopEB:SetText(floor(top+0.5));
		CT_ViewportFrameBottomEB:SetText(floor(bottom+0.5));
		CT_Viewport.currOffset = {
			floor(left+0.5), floor(right+0.5), floor(top+0.5), floor(bottom+0.5)
		};
		if ( not self.update ) then
			self.update = 0;
		else
			self.update = self.update - elapsed;
		end
		if ( self.update <= 0 ) then
			CT_ViewportFrameAspectRatioNewText:SetText("Aspect Ratio (Current): |c00FFFFFF" .. CT_Viewport_GetQuotient((CT_Viewport.screenRes[1]-left-right)/(CT_Viewport.screenRes[2]-top-bottom)));
			CT_ViewportFrameAspectRatioDefaultText:SetText("Aspect Ratio (Default): |c00FFFFFF" .. CT_Viewport_GetQuotient(CT_Viewport.screenRes[1]/CT_Viewport.screenRes[2]));
			self.update = 0.1;
		end
	else
		self.update = nil;
	end
end

	-- OnShow
function CT_ViewportFrame_OnShow()
	if ( CT_ViewportFrameInnerFrame:GetLeft() ) then
		local left, right, top, bottom, width, height, r, g, b = CT_Viewport_Saved[1], CT_Viewport_Saved[2], CT_Viewport_Saved[3], CT_Viewport_Saved[4], CT_Viewport_Saved[5], CT_Viewport_Saved[6], CT_Viewport_Saved[7];
		CT_Viewport_ApplyInnerViewport(left, right, top, bottom, r, g, b);
	end
end

	-- OnEvent
function CT_ViewportFrame_OnEvent(event)
	if ( event == "VARIABLES_LOADED" ) then
		parentWidth, parentHeight = UIParent:GetWidth(), UIParent:GetHeight();
		CT_Viewport_ApplyViewport(CT_Viewport_Saved[1], CT_Viewport_Saved[2], CT_Viewport_Saved[3], CT_Viewport_Saved[4], CT_Viewport_Saved[5], CT_Viewport_Saved[6], CT_Viewport_Saved[7]);
	end
end

-- Hook SetScreenResolution to update
CT_Viewport_oldSetScreenResolution = SetScreenResolution;
function CT_Viewport_newSetScreenResolution(newResolution)
	CT_Viewport_oldSetScreenResolution(newResolution);
	CT_ViewportFrame_OnLoad();
	CT_ViewportFrame.hasAppliedViewport = nil;
end
SetScreenResolution = CT_Viewport_newSetScreenResolution;

--------------------------------------------
-- Options Frame Code

module.frame = function()
	local options = {};
	local yoffset = 5;
	local ysize;

	-- Tips
	ysize = 60;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Tips",
		"font#t:0:-25#s:0:30#l:13:0#r#You can use /viewport, /ctvp, or /ctviewport to open the CT_Viewport options window.#0.6:0.6:0.6:l",
	};

	-- General Options
	yoffset = yoffset + ysize + 15;
	ysize = 140;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Options",
		"font#t:5:-25#s:0:30#l:13:0#r#Click the button below to open the CT_Viewport options window.#0.6:0.6:0.6:l",
		"font#t:5:-60#s:0:30#l:13:0#r#Shift-click the button if you want to leave the CTMod Control Panel open.#0.6:0.6:0.6:l",
		["button#t:0:-100#s:120:30#v:GameMenuButtonTemplate#Show options"] = {
			["onclick"] = function(self)
				CT_ViewportFrame:Show();
				if (not IsShiftKeyDown()) then
					module:showControlPanel(false);
				end
			end,
		},
	};
	yoffset = yoffset + ysize;

	return "frame#all", options;
end
