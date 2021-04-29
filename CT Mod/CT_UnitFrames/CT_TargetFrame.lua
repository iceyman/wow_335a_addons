local inworld;
function CT_TargetFrameOnEvent(self, event, arg1, ...)

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		inworld = 1;

		hooksecurefunc("UnitFrame_UpdateThreatIndicator", CT_TargetFrame_UpdateThreatIndicator);
		CT_TargetFrame_SetClassPosition(true);

		TargetFrameHealthBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);
		TargetFrameManaBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);

		if (not InCombatLockdown()) then
			CT_UnitFrames_ResetDragLink("CT_TargetFrame_Drag");
		end

		if (TitanMovableFrame_MoveFrames) then
			hooksecurefunc("TitanMovableFrame_MoveFrames", CT_TargetFrame_TitanMovableFrame_MoveFrames);
		end

		if ( GetCVarBool("predictedPower") ) then
			local statusbar = TargetFrameManaBar;
			statusbar:SetScript("OnUpdate", UnitFrameManaBar_OnUpdate);
			UnitFrameManaBar_UnregisterDefaultEvents(statusbar);
		end
	elseif (event == "PLAYER_REGEN_DISABLED") then
		CT_UnitFrames_ResetDragLink("CT_TargetFrame_Drag");

	elseif (event == "PLAYER_REGEN_ENABLED") then
		CT_UnitFrames_ResetDragLink("CT_TargetFrame_Drag");
	end
end

local tfPoint, tfRel;
local tfUpdate = 0;
function CT_TargetFrameOnUpdate(self, elapsed)
	if (not inworld) then
		return;
	end
	tfUpdate = tfUpdate + elapsed;
	if (tfUpdate > 0.5 and not MainMenuBar.busy) then
		tfUpdate = 0;
		-- If our drag link to the player frame gets broken, then fix it.
		tfPoint, tfRel = TargetFrame:GetPoint(1);
		if (tfRel ~= CT_TargetFrame_Drag) then
			if (not InCombatLockdown()) then
				CT_UnitFrames_ResetDragLink("CT_TargetFrame_Drag");
			end
		end
	end
end

function CT_TargetFrame_TitanMovableFrame_MoveFrames()
	-- TitanPanel moves the player frame when it loads which breaks our drag link.
	CT_UnitFrames_ResetDragLink("CT_TargetFrame_Drag");
end

function CT_SetTargetClass()
	if ( not CT_UnitFramesOptions.displayTargetClass ) then
		return;
	end
	if ( not UnitExists("target") or not UnitExists("player") ) then
		CT_TargetFrameClassFrameText:SetText("");
		return;
	end
	if ( UnitIsPlayer("target") ) then
		CT_TargetFrameClassFrameText:SetText(UnitClass("target") or "");
	else
		CT_TargetFrameClassFrameText:SetText(UnitCreatureType("target") or "");
	end
end

function CT_TargetofTargetHealthCheck ()
	if ( not UnitIsPlayer("targettarget") ) then
		TargetFrameToTPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
end
hooksecurefunc("TargetofTargetHealthCheck", CT_TargetofTargetHealthCheck);

function CT_TargetFrame_UpdateThreatIndicator(indicator, numericIndicator, unit)
	if (numericIndicator and numericIndicator == TargetFrameNumericalThreat) then
		local center = true;
		if (numericIndicator:IsShown()) then
			if (CT_UnitFramesOptions and CT_UnitFramesOptions.displayTargetClass) then
				center = false;
			end
		end
		if (center) then
			-- Center class frame over unit name
			CT_TargetFrame_SetClassPosition(true);
			-- Center numeric threat indicator
			CT_TargetFrame_SetThreatPosition(true, numericIndicator);
		else
			-- Shift class frame to the right
			CT_TargetFrame_SetClassPosition(false);
			-- Shift numeric threat indicator to the left.
			CT_TargetFrame_SetThreatPosition(false, numericIndicator);
		end
	end
end

function CT_TargetFrame_SetClassPosition(center)
	local frame = CT_TargetFrameClassFrame;
	frame:ClearAllPoints();
	if (center) then
		-- Center the class over the unit name.
		frame:SetPoint("BOTTOM", TargetFrameTextureFrameName, "TOP", 0, 5);
		frame:SetWidth(100);
		CT_TargetFrameClassFrameText:SetWidth(96);
	else
		-- Leave room on the left to display threat indicator.
		frame:SetPoint("BOTTOMLEFT", TargetFrameTextureFrameName, "TOPLEFT", 35, 5);
		frame:SetWidth(86);
		CT_TargetFrameClassFrameText:SetWidth(82);
	end
end

function CT_TargetFrame_SetThreatPosition(center, numericIndicator)
	local frame = numericIndicator;
	frame:ClearAllPoints();
	if (center) then
		frame:SetPoint("BOTTOM", TargetFrame, "TOP", -50, -22);
	else
		frame:SetPoint("BOTTOMLEFT", TargetFrame, "TOPLEFT", 7, -22);
	end
end

function CT_TargetFrame_ShowBarText()
	UnitFrameHealthBar_Update(TargetFrameHealthBar, "target");
	UnitFrameManaBar_Update(TargetFrameManaBar, "target");
end

function CT_TargetFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == TargetFrameHealthBar and CT_UnitFramesOptions) then
		local style;
		if (UnitIsFriend("target", "player")) then
			style = CT_UnitFramesOptions.styles[3][1];
		else
			style = CT_UnitFramesOptions.styles[3][5];
		end
		CT_UnitFrames_TextStatusBar_UpdateTextString(bar, style, 0)
		CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
		CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[3][2], CT_TargetHealthLeft)

	elseif (bar == TargetFrameManaBar and CT_UnitFramesOptions) then
		CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[3][3], 0)
		CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[3][4], CT_TargetManaLeft)
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_TargetFrame_TextStatusBar_UpdateTextString);

function CT_TargetFrame_ShowTextStatusBarText(bar)
	if (bar == TargetFrameHealthBar or bar == TargetFrameManaBar) then
		CT_TargetFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("ShowTextStatusBarText", CT_TargetFrame_ShowTextStatusBarText);

function CT_TargetFrame_HideTextStatusBarText(bar)
	if (bar == TargetFrameHealthBar or bar == TargetFrameManaBar) then
		CT_TargetFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("HideTextStatusBarText", CT_TargetFrame_HideTextStatusBarText);

