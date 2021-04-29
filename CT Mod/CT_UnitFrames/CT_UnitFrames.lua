
function CT_UnitFrames_LinkFrameDrag(frame, drag, point, relative, x, y)
	frame:ClearAllPoints();
	frame:SetPoint(point, drag:GetName(), relative, x, y);
end

function CT_UnitFrames_ResetPosition(name)
	-- Reset the position of a movable frame (name == nil == all movable frames).
	if (InCombatLockdown()) then
		return;
	end
	local yoffset = 0;
	if (TitanMovable_GetPanelYOffset and TITAN_PANEL_PLACE_TOP and TitanPanelGetVar) then
		yoffset = yoffset + (tonumber( TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_TOP, TitanPanelGetVar("BothBars")) ) or 0);
	end
	if (not name or name == "CT_PlayerFrame_Drag") then
		CT_PlayerFrame_Drag:ClearAllPoints();
		CT_PlayerFrame_Drag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 97, -25 + yoffset);
		CT_PlayerFrame_Drag:SetUserPlaced(true);
	end
	if (not name or name == "CT_TargetFrame_Drag") then
		CT_TargetFrame_Drag:ClearAllPoints();
		CT_TargetFrame_Drag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 278, -25 + yoffset);
		CT_TargetFrame_Drag:SetUserPlaced(true);
	end
	if (not name or name == "CT_AssistFrame_Drag") then
		CT_AssistFrame_Drag:ClearAllPoints();
		CT_AssistFrame_Drag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, -25 + yoffset);
		CT_AssistFrame_Drag:SetUserPlaced(true);
	end
	if (not name or name == "CT_FocusFrame_Drag") then
		CT_FocusFrame_Drag:ClearAllPoints();
		CT_FocusFrame_Drag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, -180 + yoffset);
		CT_FocusFrame_Drag:SetUserPlaced(true);
	end
end

function CT_UnitFrames_ResetDragLink(name)
	-- Reset the link between a drag frame and its companion frame (name == nil == all movable frames).
	if (InCombatLockdown()) then
		return;
	end
	if (not name or name == "CT_PlayerFrame_Drag") then
		CT_UnitFrames_LinkFrameDrag(PlayerFrame, CT_PlayerFrame_Drag, "TOPLEFT", "TOPLEFT", -117, 21);
	end
	if (not name or name == "CT_TargetFrame_Drag") then
		CT_UnitFrames_LinkFrameDrag(TargetFrame, CT_TargetFrame_Drag, "TOPLEFT", "TOPLEFT", -15, 21);
	end
	if (not name or name == "CT_AssistFrame_Drag") then
		CT_UnitFrames_LinkFrameDrag(CT_AssistFrame, CT_AssistFrame_Drag, "TOPLEFT", "TOPLEFT", -15, 21);
	end
	if (not name or name == "CT_FocusFrame_Drag") then
		CT_UnitFrames_LinkFrameDrag(CT_FocusFrame, CT_FocusFrame_Drag, "TOPLEFT", "TOPLEFT", -15, 21);
	end
end

function CT_UnitFrames_TextStatusBar_UpdateTextString(textStatusBar, settings, lockShow)
	local textString = textStatusBar.TextString;
	if(textString) then
		if (lockShow == nil) then lockShow = textStatusBar.lockShow; end
		local value = textStatusBar:GetValue();
		local valueMin, valueMax = textStatusBar:GetMinMaxValues();
		if ( ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) and not ( textStatusBar.pauseUpdates ) ) then
			local style = settings[1];
			local prefix;
			if (lockShow > 0) then
				style = 4;
				prefix = 1;
			end
			textStatusBar:Show();
--			if ( value and valueMax > 0 and ( GetCVarBool("statusTextPercentage") or textStatusBar.showPercentage ) and not textStatusBar.showNumeric) then
			if ( value and valueMax > 0 and ( style == 2 ) ) then
				-- Percent
				if ( value == 0 and textStatusBar.zeroText ) then
					textString:SetText(textStatusBar.zeroText);
					textStatusBar.isZero = 1;
					textString:Show();
					return;
				end
				value = tostring(math.ceil((value / valueMax) * 100)) .. "%";
--				if ( textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) ) ) then
				if ( textStatusBar.prefix and prefix ) then -- and (textStatusBar.alwaysPrefix or not (textStatusBar.textLockable) ) ) then
					textString:SetText(textStatusBar.prefix .. " " .. value);
				else
					textString:SetText(value);
				end
			elseif ( value == 0 and textStatusBar.zeroText ) then
				textString:SetText(textStatusBar.zeroText);
				textStatusBar.isZero = 1;
				textString:Show();
				return;
			elseif (style == 1) then
				-- None
				textString:SetText("");
				textStatusBar.isZero = nil;
				textStatusBar:Show();
			elseif (style == 3) then
				-- Deficit
				textStatusBar.isZero = nil;
				value = value - valueMax;
				if (value >= 0) then
					value = "";
				end
--				if ( textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) ) ) then
				if ( textStatusBar.prefix and prefix ) then -- and (textStatusBar.alwaysPrefix or not (textStatusBar.textLockable) ) ) then
					textString:SetText(textStatusBar.prefix.." "..value);
				else
					textString:SetText(value);
				end
			elseif (style == 5) then
				-- Current
				textStatusBar.isZero = nil;
--				if ( textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) ) ) then
				if ( textStatusBar.prefix and prefix ) then -- and (textStatusBar.alwaysPrefix or not (textStatusBar.textLockable) ) ) then
					textString:SetText(textStatusBar.prefix.." "..value);
				else
					textString:SetText(value);
				end
			else
				-- Values
				textStatusBar.isZero = nil;
				if ( textStatusBar.capNumericDisplay ) then
					value = TextStatusBar_CapDisplayOfNumericValue(value);
					valueMax = TextStatusBar_CapDisplayOfNumericValue(valueMax);
				end
--				if ( textStatusBar.prefix and (textStatusBar.alwaysPrefix or not (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) ) ) then
				if ( textStatusBar.prefix and prefix ) then -- and (textStatusBar.alwaysPrefix or not (textStatusBar.textLockable) ) ) then
					textString:SetText(textStatusBar.prefix.." "..value.."/"..valueMax);
				else
					textString:SetText(value.."/"..valueMax);
				end
			end
--			if ( (textStatusBar.cvar and GetCVar(textStatusBar.cvar) == "1" and textStatusBar.textLockable) or textStatusBar.forceShow ) then
--				textString:Show();
--			elseif ( lockShow > 0 ) then
--				textString:Show();
--			else
--				textString:Hide();
--			end
			textString:Show();
		else
			textString:Hide();
			textStatusBar:Hide();
		end
		textString:SetTextColor(settings[2], settings[3], settings[4], settings[5]);
	end
end

function CT_UnitFrames_BesideBar_UpdateTextString(textStatusBar, settings, textString)
	if(textString) then
		local value = textStatusBar:GetValue();
		local valueMin, valueMax = textStatusBar:GetMinMaxValues();
		if ( ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) ) then
			local style = settings[1];
			if ( value and valueMax > 0 and ( style == 2 ) ) then
				-- Percent
				value = tostring(math.ceil((value / valueMax) * 100)) .. "%";
				textString:SetText(value);
			elseif (style == 1) then
				-- None
				textString:SetText("");
			elseif (style == 3) then
				-- Deficit
				value = value - valueMax;
				if (value >= 0) then
					value = "";
				end
				textString:SetText(value);
			elseif (style == 5) then
				-- Current
				textString:SetText(value);
			else
				-- Values
				if ( textStatusBar.capNumericDisplay ) then
					value = TextStatusBar_CapDisplayOfNumericValue(value);
					valueMax = TextStatusBar_CapDisplayOfNumericValue(valueMax);
				end
				textString:SetText(value.."/"..valueMax);
			end
			textString:Show();
		else
			textString:Hide();
		end
		textString:SetTextColor(settings[2], settings[3], settings[4], settings[5]);
	end
end

function CT_UnitFrames_HealthBar_OnValueChanged(self, value, smooth)
	if ( not value ) then
		return;
	end
	local r, g, b;
	local min, max = self:GetMinMaxValues();
	if ( (value < min) or (value > max) ) then
		return;
	end
	if ( (max - min) > 0 ) then
		value = (value - min) / (max - min);
	else
		value = 0;
	end
	if(smooth) then
		if(value > 0.5) then
			r = (1.0 - value) * 2;
			g = 1.0;
		else
			r = 1.0;
			g = value * 2;
		end
	else
		r = 0.0;
		g = 1.0;
	end
	b = 0.0;
	if ( not self.lockColor ) then
		self:SetStatusBarColor(r, g, b);
	end
end
