function CT_PartyFrameSlider_OnLoad(self)
	_G[self:GetName().."Text"]:SetText(CT_UFO_PARTYTEXTSIZE);
	_G[self:GetName().."High"]:SetText(CT_UFO_PARTYTEXTSIZE_LARGE);
	_G[self:GetName().."Low"]:SetText(CT_UFO_PARTYTEXTSIZE_SMALL);
	self:SetMinMaxValues(1, 5);
	self:SetValueStep(1);
	self.tooltipText = "Allows you to change the text size of the party health & mana texts.";
end

function CT_PartyFrame_ShowBarText()
	UnitFrameHealthBar_Update(PartyMemberFrame1HealthBar, "party1");
	UnitFrameManaBar_Update(PartyMemberFrame1ManaBar, "party1");
	UnitFrameHealthBar_Update(PartyMemberFrame2HealthBar, "party2");
	UnitFrameManaBar_Update(PartyMemberFrame2ManaBar, "party2");
	UnitFrameHealthBar_Update(PartyMemberFrame3HealthBar, "party3");
	UnitFrameManaBar_Update(PartyMemberFrame3ManaBar, "party3");
	UnitFrameHealthBar_Update(PartyMemberFrame4HealthBar, "party4");
	UnitFrameManaBar_Update(PartyMemberFrame4ManaBar, "party4");
end

function CT_PartyFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == PartyMemberFrame1HealthBar or bar == PartyMemberFrame2HealthBar or bar == PartyMemberFrame3HealthBar or bar == PartyMemberFrame4HealthBar) then
		if (CT_UnitFramesOptions) then
			local textRight;
			if (bar == PartyMemberFrame1HealthBar) then
				textRight = CT_PartyFrame1HealthRight; -- _G["CT_PartyFrame" .. bar:GetParent():GetID() .. "HealthBar"];
			elseif (bar == PartyMemberFrame2HealthBar) then
				textRight = CT_PartyFrame2HealthRight;
			elseif (bar == PartyMemberFrame3HealthBar) then
				textRight = CT_PartyFrame3HealthRight;
			elseif (bar == PartyMemberFrame4HealthBar) then
				textRight = CT_PartyFrame4HealthRight;
			end

			bar.TextString:SetTextHeight( ( CT_UnitFramesOptions.partyTextSize or 3 ) + 7);
			textRight:SetTextHeight( ( CT_UnitFramesOptions.partyTextSize or 3 ) + 7);

			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[2][1])
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[2][2], textRight)
		end

	elseif (bar == PartyMemberFrame1ManaBar or bar == PartyMemberFrame2ManaBar or bar == PartyMemberFrame3ManaBar or bar == PartyMemberFrame4ManaBar) then
		if (CT_UnitFramesOptions) then
			local textRight;
			if (bar == PartyMemberFrame1ManaBar) then
				textRight = CT_PartyFrame1ManaRight; -- _G["CT_PartyFrame" .. bar:GetParent():GetID() .. "ManaBar"];
			elseif (bar == PartyMemberFrame2ManaBar) then
				textRight = CT_PartyFrame2ManaRight;
			elseif (bar == PartyMemberFrame3ManaBar) then
				textRight = CT_PartyFrame3ManaRight;
			elseif (bar == PartyMemberFrame4ManaBar) then
				textRight = CT_PartyFrame4ManaRight;
			end

			bar.TextString:SetTextHeight( ( CT_UnitFramesOptions.partyTextSize or 3 ) + 7);
			textRight:SetTextHeight( ( CT_UnitFramesOptions.partyTextSize or 3 ) + 7);

			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[2][3])
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[2][4], textRight)
		end
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_PartyFrame_TextStatusBar_UpdateTextString);

function CT_PartyFrame_ShowTextStatusBarText(bar)
	if (bar == PartyMemberFrame1HealthBar or bar == PartyMemberFrame2HealthBar or bar == PartyMemberFrame3HealthBar or bar == PartyMemberFrame4HealthBar) then
		CT_PartyFrame_TextStatusBar_UpdateTextString(bar);
	elseif (bar == PartyMemberFrame1ManaBar or bar == PartyMemberFrame2ManaBar or bar == PartyMemberFrame3ManaBar or bar == PartyMemberFrame4ManaBar) then
		CT_PartyFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("ShowTextStatusBarText", CT_PartyFrame_ShowTextStatusBarText);

function CT_PartyFrame_HideTextStatusBarText(bar)
	if (bar == PartyMemberFrame1HealthBar or bar == PartyMemberFrame2HealthBar or bar == PartyMemberFrame3HealthBar or bar == PartyMemberFrame4HealthBar) then
		CT_PartyFrame_TextStatusBar_UpdateTextString(bar);
	elseif (bar == PartyMemberFrame1ManaBar or bar == PartyMemberFrame2ManaBar or bar == PartyMemberFrame3ManaBar or bar == PartyMemberFrame4ManaBar) then
		CT_PartyFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("HideTextStatusBarText", CT_PartyFrame_HideTextStatusBarText);
