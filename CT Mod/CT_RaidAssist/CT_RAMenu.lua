local UnitName = CT_RA_UnitName;

tinsert(UISpecialFrames, "CT_RAMenuFrame");
CT_RA_Ressers = { };
CT_RAMenu_Locked = 1;
CT_RA_PartyMembers = { };
CT_RA_InCombat = nil;

function CT_RAMenu_OnLoad()
	CT_RAMenuFrameHomeButton1Text:SetText("General Options");
	CT_RAMenuFrameHomeButton2Text:SetText("Buff Options");
	CT_RAMenuFrameHomeButton3Text:SetText("Misc Options");
	CT_RAMenuFrameHomeButton4Text:SetText("Additional Options");
	CT_RAMenuFrameHomeButton5Text:SetText("Option Sets");
	CT_RAMenuFrameHomeButton6Text:SetText("Group and Class Selections");

	CT_RAMenuFrameHomeButton1Description:SetText("Change general stuff, such as whether to show mana bars, etc etc.");
	CT_RAMenuFrameHomeButton2Description:SetText("Change the way Buffs and Debuffs are displayed.");
	CT_RAMenuFrameHomeButton3Description:SetText("Minimap button, Notifications, Display options.");
	CT_RAMenuFrameHomeButton4Description:SetText("Scaling of windows, Emergency Monitor, Background opacity, Health/Range alpha.");
	CT_RAMenuFrameHomeButton5Description:SetText("Save and load sets of options for easier setup.");
	CT_RAMenuFrameHomeButton6Description:SetText("Open CTRA raid window, Change which groups and classes to show.");
end

function CT_RAMenu_OnShow(self)
	if ( InCombatLockdown() ) then
		-- Disable menu
		self:Hide();
		CT_RA_Print("<CTRaid> The options menu is currently disabled in combat - please exit combat to edit options.");
		return;
	end
	CT_RAMenuFrameTitle:SetText("CT_RaidAssist  " .. CT_RA_Version);
	CT_RAMenu_ShowHome();
	self:SetScale(1/UIParent:GetScale()*0.8);
	CT_RAMenuFrameHomeButton1:SetScale(0.9111);
	CT_RAMenuFrameHomeButton2:SetScale(0.9111);
	CT_RAMenuFrameHomeButton3:SetScale(0.9111);
	CT_RAMenuFrameHomeButton4:SetScale(0.9111);
	CT_RAMenuFrameHomeButton5:SetScale(0.9111);
	CT_RAMenuFrameHomeButton6:SetScale(0.9111);
end

function CT_RAMenuButton_OnClick(self, id)
	if ( not id ) then
		id = self:GetID();
	end
	CT_RAMenuFrameHome:Hide();
	if ( id == 1 ) then
		CT_RAMenuFrameGeneral:Show();
	elseif ( id == 2 ) then
		CT_RAMenuFrameBuffs:Show();
	elseif ( id == 3 ) then
		CT_RAMenuFrameMisc:Show();
	elseif ( id == 4 ) then
		CT_RAMenuFrameAdditional:Show();
	elseif ( id == 5 ) then
		CT_RAMenuFrameOptionSets:Show();
	elseif ( id == 6 ) then
		if (not CT_RATabFrame:IsShown()) then
			CT_RATabFrame:Show();
			CT_RATabFrame_Tab_OnClick(CT_RATabFrameTab2);
		else
			CT_RATabFrame:Hide();
		end
		CT_RAMenuFrameHome:Show();
	end
end

function CT_RAMenu_ShowHome()
	CT_RAMenuFrameHome:Show();
	CT_RAMenuFrameGeneral:Hide();
	CT_RAMenuFrameBuffs:Hide();
	CT_RAMenuFrameMisc:Hide();
	CT_RAMenuFrameAdditional:Hide();
	CT_RAMenuFrameOptionSets:Hide();
end

function CT_UIDropDownMenu_SetSelectedID(frame, id, useValue)
	-- This is a copy of the function from UIDropDown.lua but modified
	-- so that no refresh is done. If a different menu is open when 
	-- a refresh is done to the specified frame's menu, it can cause
	-- problems with the open menu.
	frame.selectedID = id;
	frame.selectedName = nil;
	frame.selectedValue = nil;
	-- UIDropDownMenu_Refresh(frame, useValue);
end

function CT_RAMenu_UpdateMenu()
	local tempOptions = CT_RAMenu_Options["temp"];

	-- General options, Display section
	CT_RAMenuFrameGeneralDisplayShowGroupsCB:SetChecked(not tempOptions["HideNames"]);
	CT_RAMenuFrameGeneralDisplayLockGroupsCB:SetChecked(tempOptions["LockGroups"]);
	CT_RAMenuFrameGeneralDisplayShowMPCB:SetChecked(tempOptions["HideMP"]);
	if ( tempOptions["MemberHeight"] == 32 ) then
		CT_RAMenuFrameGeneralDisplayShowHealthCB:SetChecked(1);
	else
		CT_RAMenuFrameGeneralDisplayShowHealthCB:SetChecked(nil);
	end
	CT_RAMenuFrameGeneralDisplayShowRPCB:SetChecked(tempOptions["HideRP"]);
	if ( tempOptions["ShowHP"] ) then
		CT_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralDisplayHealthDropDown, tempOptions["ShowHP"]);
	else
		CT_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralDisplayHealthDropDown, 5);
	end
	if ( tempOptions["ShowHP"] ) then
		local table = { "Show Values", "Show Percentages", "Show Deficit", "Show only MTT HP %" };
		CT_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralDisplayHealthDropDown, tempOptions["ShowHP"]);
		CT_RAMenuFrameGeneralDisplayHealthDropDownText:SetText(table[tempOptions["ShowHP"]]);
	else
		CT_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralDisplayHealthDropDown, 5);
		CT_RAMenuFrameGeneralDisplayHealthDropDownText:SetText("Show None");
	end
	CT_RAMenuFrameGeneralDisplayShowHPSwatchNormalTexture:SetVertexColor(tempOptions["PercentColor"].r, tempOptions["PercentColor"].g, tempOptions["PercentColor"].b);
	CT_RAMenuFrameGeneralDisplayWindowColorSwatchNormalTexture:SetVertexColor(tempOptions["DefaultColor"].r, tempOptions["DefaultColor"].g, tempOptions["DefaultColor"].b);
	CT_RAMenuFrameGeneralDisplayAlertColorSwatchNormalTexture:SetVertexColor(tempOptions["DefaultAlertColor"].r, tempOptions["DefaultAlertColor"].g, tempOptions["DefaultAlertColor"].b);

	CT_RA_UpdateRaidGroupColors();
	CT_RA_UpdateRaidMovability();
	CT_RA_UpdateGroupOptions();

	-- General options, Main Tanks section
	local numMts = tempOptions["ShowNumMTs"];
	if ( numMts == 1 ) then
		CT_RAMenuFrameGeneralMTsSubtract:Disable();
	elseif ( numMts == 10 ) then
		CT_RAMenuFrameGeneralMTsAdd:Disable();
	end
	CT_RAMenuFrameGeneralMTsNum:SetText(numMts or 10);

	-- General options, Misc section
	CT_RAMenuFrameGeneralMiscSortAlphaCB:SetChecked(tempOptions["SubSortByName"]);
	CT_RAMenuFrameGeneralMiscBorderCB:SetChecked(tempOptions["HideBorder"]);
	CT_RAMenuFrameGeneralMiscRemoveSpacingCB:SetChecked(tempOptions["HideSpace"]);
	CT_RAMenuFrameGeneralMiscShowMTsCB:SetChecked(not tempOptions["HideMTs"]);
	CT_RAMenuFrameGeneralMiscShowMetersCB:SetChecked( (tempOptions["StatusMeters"] and tempOptions["StatusMeters"]["Show"] ) );
	CT_RAMenuFrameGeneralMiscShowHorizontalCB:SetChecked(tempOptions["ShowHorizontal"]);
	CT_RAMenuFrameGeneralMiscShowReversedCB:SetChecked(tempOptions["ShowReversed"]);
	if ( tempOptions["SORTTYPE"] == "class" ) then
		CT_RA_SetSortType("class");
	else
		CT_RA_SetSortType("group");
	end

	if ( not tempOptions["HideBorder"] ) then
		CT_RAMenuFrameGeneralMiscRemoveSpacingCB:Disable();
		CT_RAMenuFrameGeneralMiscRemoveSpacingText:SetTextColor(0.3, 0.3, 0.3);
	end

	-- Buff options, Buffs section, Left side
	local admiralsHat, foundDampen, foundWildGrowth;
	for k, v in pairs(tempOptions["BuffArray"]) do
		if ( v["name"] == CT_RA_DAMPENMAGIC ) then
			foundDampen = k;
		elseif ( v["name"] == CT_RA_ADMIRALSHAT ) then
			admiralsHat = k;
		elseif ( v["name"] == CT_RA_WILDGROWTH ) then
			foundWildGrowth = k;
		elseif ( v["name"] == "Don du fauve" ) then
			-- Change name of buffs.. Not a too great way of doing it, but it works (I'll fix this design as soon as possible, it's terrible I know)
			tempOptions["BuffArray"][k]["name"] = CT_RA_MARKOFTHEWILD[2];
		elseif ( v["name"] == "Marque du fauve" ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_MARKOFTHEWILD[1];
		elseif ( v["name"] == CT_RA_BLESSINGOFMIGHT[1] ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_BLESSINGOFMIGHT;
		elseif ( v["name"] == CT_RA_BLESSINGOFWISDOM[1] ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_BLESSINGOFWISDOM;
		elseif ( v["name"] == CT_RA_BLESSINGOFKINGS[1] ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_BLESSINGOFKINGS;
		elseif ( v["name"] == CT_RA_BLESSINGOFSALVATION[1] ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_BLESSINGOFSALVATION;
		elseif ( v["name"] == CT_RA_BLESSINGOFLIGHT[1] ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_BLESSINGOFLIGHT;
		elseif ( v["name"] == CT_RA_BLESSINGOFSANCTUARY[1] ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_BLESSINGOFSANCTUARY;
		elseif ( v["name"] == CT_RA_DIVINESPIRIT[1] ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_DIVINESPIRIT;
		elseif ( v["name"] == CT_RA_SHADOWPROTECTION[1] ) then
			tempOptions["BuffArray"][k]["name"] = CT_RA_SHADOWPROTECTION;
		elseif ( type(v["name"]) == "table" ) then
			if ( v["name"][1] == CT_RA_ARCANEINTELLECT[1] ) then
				-- Update the list of 'Arcane Intellect' equivalent spell names.
				--   Originally there was just "Arcane Intellect" and "Arcance Billiance".
				--   Now there is also "Dalaran Intellect" and "Dalaran Brilliance".
				tempOptions["BuffArray"][k]["name"] = CT_RA_ARCANEINTELLECT;
			end
		end
	end
	if ( admiralsHat ) then
		tremove(tempOptions["BuffArray"], admiralsHat);
	end
	if ( not foundDampen ) then
		tinsert(tempOptions["BuffArray"], { ["show"] = -1, ["name"] = CT_RA_AMPLIFYMAGIC, ["index"] = 20 });
		tinsert(tempOptions["BuffArray"], { ["show"] = -1, ["name"] = CT_RA_DAMPENMAGIC, ["index"] = 21 });
	end
	if ( not foundWildGrowth ) then
		tinsert(tempOptions["BuffArray"], { ["show"] =  1, ["name"] = CT_RA_LIFEBLOOM, ["index"] = 22 });
		tinsert(tempOptions["BuffArray"], { ["show"] =  1, ["name"] = CT_RA_WILDGROWTH, ["index"] = 23 });
	end
	for key, val in pairs(tempOptions["BuffArray"]) do
		if ( val["show"] ~= -1 ) then
			getglobal("CT_RAMenuFrameBuffsBuff" .. key .. "CheckButton"):SetChecked(1);
			getglobal("CT_RAMenuFrameBuffsBuff" .. key .. "Text"):SetTextColor(1, 1, 1);
		else
			getglobal("CT_RAMenuFrameBuffsBuff" .. key .. "CheckButton"):SetChecked(nil);
			getglobal("CT_RAMenuFrameBuffsBuff" .. key .. "Text"):SetTextColor(0.3, 0.3, 0.3);
		end
		local spell = val["name"];
		if ( type(spell) == "table" ) then
			getglobal("CT_RAMenuFrameBuffsBuff" .. key .. "Text"):SetText(spell[1]);
			local b = getglobal("CT_RAMenuFrameBuffsBuff" .. key);
			b.tooltip = spell[1];
			for i = 2, #spell do
				b.tooltip = b.tooltip .. "\n" .. spell[i];
			end
		else
			getglobal("CT_RAMenuFrameBuffsBuff" .. key .. "Text"):SetText(spell);
			getglobal("CT_RAMenuFrameBuffsBuff" .. key).tooltip = nil;
		end
	end

	-- Buff options, Buffs section, Right side
	for i = 1, 6, 1 do
		if ( type(tempOptions["DebuffColors"][i]["type"]) == "table" ) then
			getglobal("CT_RAMenuFrameBuffsDebuff" .. i .. "Text"):SetText(string.gsub(tempOptions["DebuffColors"][i]["type"][CT_RA_GetLocale()], "_", " "));
		else
			getglobal("CT_RAMenuFrameBuffsDebuff" .. i .. "Text"):SetText(string.gsub(tempOptions["DebuffColors"][i]["type"], "_", " "));
		end
		local val = tempOptions["DebuffColors"][i];
		getglobal("CT_RAMenuFrameBuffsDebuff" .. i .. "SwatchNormalTexture"):SetVertexColor(val.r, val.g, val.b);

		if ( val["id"] ~= -1 ) then
			getglobal("CT_RAMenuFrameBuffsDebuff" .. i .. "CheckButton"):SetChecked(1);
			getglobal("CT_RAMenuFrameBuffsDebuff" .. i .. "Text"):SetTextColor(1, 1, 1);
		else
			getglobal("CT_RAMenuFrameBuffsDebuff" .. i .. "CheckButton"):SetChecked(nil);
			getglobal("CT_RAMenuFrameBuffsDebuff" .. i .. "Text"):SetTextColor(0.3, 0.3, 0.3);
		end
	end

	-- Buff Options, Notifications section
	CT_RAMenuFrameBuffsNotifyDebuffs:SetChecked(tempOptions["NotifyDebuffs"]);
	CT_RAMenuFrameBuffsNotifyDebuffs:SetChecked(tempOptions["NotifyDebuffs"]["main"]);
	CT_RAMenuFrameBuffsNotifyBuffs:SetChecked(not tempOptions["NotifyDebuffs"]["hidebuffs"]);
	for i = 1, NUM_RAID_GROUPS, 1 do
		getglobal("CT_RAMenuFrameBuffsNotifyDebuffsGroup" .. i .. "Text"):SetText("Group " .. i);
		if ( not tempOptions["NotifyDebuffs"] or ( not tempOptions["NotifyDebuffs"]["main"] and tempOptions["NotifyDebuffs"]["hidebuffs"] ) ) then
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsGroup" .. i .. "Text"):SetTextColor(0.3, 0.3, 0.3);
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsGroup" .. i .. "CheckButton"):Disable();
		end
		getglobal("CT_RAMenuFrameBuffsNotifyDebuffsGroup" .. i .. "CheckButton"):SetChecked(tempOptions["NotifyDebuffs"][i]);
	end
	for i = 1, CT_RA_MaxGroups, 1 do
		if ( not tempOptions["NotifyDebuffs"] or ( not tempOptions["NotifyDebuffs"]["main"] and tempOptions["NotifyDebuffs"]["hidebuffs"] ) ) then
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. i .. "Text"):SetTextColor(0.3, 0.3, 0.3);
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. i .. "CheckButton"):Disable();
		end
		getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. i .. "CheckButton"):SetChecked(tempOptions["NotifyDebuffsClass"][i]);
	end
	for k, v in pairs(CT_RA_ClassPositions) do
		getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. v .. "Text"):SetText(k);
	end
	if ( tempOptions["ShowDebuffs"] ) then
		CT_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameBuffsBuffsDropDown, 2);
		CT_RAMenuFrameBuffsBuffsDropDownText:SetText("Show debuffs");
	elseif ( tempOptions["ShowBuffsDebuffed"] ) then
		CT_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameBuffsBuffsDropDown, 3);
		CT_RAMenuFrameBuffsBuffsDropDownText:SetText("Show buffs until debuffed");
	else
		CT_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameBuffsBuffsDropDown, 1);
		CT_RAMenuFrameBuffsBuffsDropDownText:SetText("Show buffs");
	end

	-- Misc Options, Notifications section, Left side
	CT_RAMenuFrameMiscNotificationsShowTankDeathCB:SetChecked(not tempOptions["HideTankNotifications"]);
	CT_RAMenuFrameMiscNotificationsSendRARSCB:SetChecked(tempOptions["SendRARS"]);
	CT_RAMenuFrameMiscNotificationsPlayRSSoundCB:SetChecked(tempOptions["PlayRSSound"]);
	CT_RAMenuFrameMiscNotificationsDisableQueryCB:SetChecked(tempOptions["DisableQuery"]);

	-- Misc Options, Notifications section, Right side
	CT_RAMenuFrameMiscNotificationsAggroNotifierCB:SetChecked(tempOptions["AggroNotifier"]);
	CT_RAMenuFrameMiscNotificationsAggroNotifierSoundCB:SetChecked(tempOptions["AggroNotifierSound"]);
	CT_RAMenuFrameMiscNotificationsNotifyGroupChangeCB:SetChecked(tempOptions["NotifyGroupChange"]);
	CT_RAMenuFrameMiscNotificationsNotifyGroupChangeCBSound:SetChecked(tempOptions["NotifyGroupChangeSound"]);

	if ( not tempOptions["AggroNotifier"] ) then
		CT_RAMenuFrameMiscNotificationsAggroNotifierSoundCB:Disable();
		CT_RAMenuFrameMiscNotificationsAggroNotifierSound:SetTextColor(0.3, 0.3, 0.3);
	end

	if ( not tempOptions["NotifyGroupChange"] ) then
		CT_RAMenuFrameMiscNotificationsNotifyGroupChangeCBSound:Disable();
		CT_RAMenuFrameMiscNotificationsNotifyGroupChangeSound:SetTextColor(0.3, 0.3, 0.3);
	else
		CT_RAMenuFrameMiscNotificationsNotifyGroupChangeCBSound:Enable();
		CT_RAMenuFrameMiscNotificationsNotifyGroupChangeSound:SetTextColor(1, 1, 1);
	end

	-- Misc Options, Display section, Left side
	CT_RAMenuFrameMiscDisplayShowTooltipCB:SetChecked(not tempOptions["HideTooltip"]);
	CT_RAMenuFrameMiscDisplayShowAFKCB:SetChecked(tempOptions["ShowAFK"]);
	CT_RAMenuFrameMiscDisplayShowResMonitorCB:SetChecked(tempOptions["ShowMonitor"]);
	CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeededCB:SetChecked(tempOptions["HideMonitorUntilNeeded"]);
	if (tempOptions["ShowMonitor"]) then
		CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeededCB:Enable();
		CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeeded:SetTextColor(1, 1, 1);
	else
		CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeededCB:Disable();
		CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeeded:SetTextColor(0.3, 0.3, 0.3);
	end
	CT_RAMenuFrameMiscDisplayColorLeaderCB:SetChecked( ( not tempOptions["leaderColor"] or tempOptions["leaderColor"].enabled ) );
	if ( tempOptions["leaderColor"] ) then
		CT_RAMenuFrameMiscDisplayColorLeaderColorSwatchNormalTexture:SetVertexColor(tempOptions["leaderColor"].r, tempOptions["leaderColor"].g, tempOptions["leaderColor"].b);
	else
		CT_RAMenuFrameMiscDisplayColorLeaderColorSwatchNormalTexture:SetVertexColor(1, 1, 0);
	end

	-- Misc Options, Display section, Right side
	CT_RAMenuFrameMiscDisplayHideButtonCB:SetChecked(tempOptions["HideButton"]);
	CT_RAMenuFrameMiscDisplayShowPTTCB:SetChecked(tempOptions["ShowPTT"]);
	CT_RAMenuFrameMiscDisplayShowMTTTCB:SetChecked(tempOptions["ShowMTTT"]);
	CT_RAMenuFrameMiscDisplayNoColorChangeCB:SetChecked(tempOptions["HideColorChange"]);
	CT_RAMenuFrameMiscDisplayShowRaidIconCB:SetChecked(tempOptions["ShowRaidIcon"]);

	if ( tempOptions["HideButton"] ) then
		CT_RASets_Button:Hide();
	else
		CT_RASets_Button:Show();
	end

	if ( not tempOptions["ShowMTTT"] ) then
		CT_RAMenuFrameMiscDisplayNoColorChangeCB:Disable();
		CT_RAMenuFrameMiscDisplayNoColorChange:SetTextColor(0.3, 0.3, 0.3);
	else
		CT_RAMenuFrameMiscDisplayNoColorChangeCB:Enable();
		CT_RAMenuFrameMiscDisplayNoColorChange:SetTextColor(1, 1, 1);
	end

	-- Additional options, Window scaling section
	if ( tempOptions["WindowScaling"] ) then
		CT_RAMenuGlobalFrame.scaleupdate = 0.1;
	end
	CT_RAMenuAdditional_Scaling_OnShow(CT_RAMenuFrameAdditionalScalingSlider1);
	CT_RAMenuAdditional_ScalingMT_OnShow(CT_RAMenuFrameAdditionalScalingSlider2);

	-- Additional options, Emergency Monitor section
	CT_RAMenuAdditional_EM_OnShow(CT_RAMenuFrameAdditionalEMSlider);
	CT_RAMenuAdditional_EM_OnShow(CT_RAMenuFrameAdditionalEMSlider2);

	CT_RAMenuFrameAdditionalEMShowCB:SetChecked(tempOptions["ShowEmergency"]);
	CT_RAMenuFrameAdditionalEMRangeCB:SetChecked(tempOptions["ShowEmergencyRange"]);
	CT_RAMenuFrameAdditionalEMPartyCB:SetChecked(tempOptions["ShowEmergencyParty"]);
	CT_RAMenuFrameAdditionalEMOutsideRaidCB:SetChecked(tempOptions["ShowEmergencyOutsideRaid"]);

	if ( not tempOptions["ShowEmergency"] ) then
		CT_RAMenuFrameAdditionalEMPartyCB:Disable();
		CT_RAMenuFrameAdditionalEMRangeCB:Disable();
		CT_RAMenuFrameAdditionalEMRangeText:SetTextColor(0.3, 0.3, 0.3);
		CT_RAMenuFrameAdditionalEMPartyText:SetTextColor(0.3, 0.3, 0.3);
		CT_RAMenuFrameAdditionalEMOutsideRaidCB:Disable();
		CT_RAMenuFrameAdditionalEMOutsideRaidText:SetTextColor(0.3, 0.3, 0.3);
	end

	-- Additional options, Health and mana Bars' Background Opacity section
	CT_RAMenuAdditional_BG_OnShow(CT_RAMenuFrameAdditionalBGSlider);

	-- Additional options, Frame Alpha section
	CT_RAMenuAdditional_Alpha_OnShow(CT_RAMenuFrameAdditionalAlphaSlider);
	CT_RAMenuFrameAdditionalAlphaRangeCB:SetChecked(tempOptions["AlphaRange"]);
	CT_RAMenuAdditional_Alpha_Update();
	if (tempOptions["AlphaRange"] and not CT_RA_UpdateFrame.rangeTimer) then
		CT_RA_UpdateFrame.rangeTimer = CT_RA_UpdateFrame.rangeTimerMax;
	end

	-- Other things to update
	if ( tempOptions["StatusMeters"] ) then
		CT_RAMetersFrame:SetBackdropColor(tempOptions["StatusMeters"]["Background"].r, tempOptions["StatusMeters"]["Background"].g, tempOptions["StatusMeters"]["Background"].b, tempOptions["StatusMeters"]["Background"].a);
		CT_RAMetersFrame:SetBackdropBorderColor(1, 1, 1, tempOptions["StatusMeters"]["Background"].a);
		if ( tempOptions["StatusMeters"]["Show"] and GetNumRaidMembers() > 0 ) then
			CT_RAMetersFrame:Show();
		else
			CT_RAMetersFrame:Hide();
		end
	end
	if ( tempOptions["EMBG"] ) then
		CT_RA_EmergencyFrame:SetBackdropColor(tempOptions["EMBG"].r, tempOptions["EMBG"].g, tempOptions["EMBG"].b, tempOptions["EMBG"].a);
		CT_RA_EmergencyFrame:SetBackdropBorderColor(1, 1, 1, tempOptions["EMBG"].a);
	end
	if ( tempOptions["RMBG"] ) then
		CT_RA_ResFrame:SetBackdropColor(tempOptions["RMBG"].r, tempOptions["RMBG"].g, tempOptions["RMBG"].b, tempOptions["RMBG"].a);
		CT_RA_ResFrame:SetBackdropBorderColor(1, 1, 1, tempOptions["RMBG"].a);
	end
	CT_RA_Emergency_UpdateHealth();
	CT_RAMenu_UpdateWindowPositions();
end

function CT_RAMenuFrameBuffsNotify_OnShow(self)
	-- Arrange the checkboxes so the classes appear to be in alphabetical order (from left to right).
	for i = 1, CT_RA_MaxGroups do
		cb = getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. i);
		cb:ClearAllPoints();
	end
	local cb, cb2, pos;
	local c = 1;
	local across = 3;
	for i = 1, CT_RA_MaxGroups do
		pos = CT_RA_ClassPositions[(CT_RA_ClassSorted[i])];
		cb = getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. pos);
		if (i == 1) then
			cb:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -150);
		elseif (c == 1) then
			pos = CT_RA_ClassPositions[(CT_RA_ClassSorted[i - across])];
			cb2 = getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. pos);
			cb:SetPoint("TOPLEFT", cb2, "BOTTOMLEFT", 0, -3);
		else
			cb:SetPoint("LEFT", cb2, "RIGHT", 3, 0);
		end
		cb2 = cb;
		c = c + 1;
		if (c > across) then
			c = 1;
		end
	end
end

function CT_RAMenuBuffs_OnEvent(self, event, ...)
	if (not event == "VARIABLES_LOADED") then
		return;
	end
	local changed;
	if (not CT_RAMenu_Options) then
		CT_RAMenu_Options = {};
	end
	if (not CT_RAMenu_Options["Default"]) then
		CT_RA_CreateDefaultSet();
	end
	if (not CT_RAMenu_CurrSet or not CT_RAMenu_Options[CT_RAMenu_CurrSet]) then
		CT_RAMenu_CurrSet = "Default";
	end
	if (not CT_RAMenu_Options["temp"]) then
		CT_RAMenu_Options["temp"] = CT_RAMenu_CopyTable(CT_RAMenu_Options[CT_RAMenu_CurrSet]);
	end
	CT_RAMenu_Options["temp"]["unchanged"] = 1;
	for k, v in pairs(CT_RAMenu_Options) do
		if ( v["WindowPositions"] and v["WindowPositions"]["CT_RA_EmergencyFrame"] ) then
			CT_RAMenu_Options[k]["WindowPositions"]["CT_RA_EmergencyFrame"] = nil;
			changed = 1;
		end
	end
	if ( changed ) then
		CT_RAMenu_Options["temp"]["unchanged"] = nil;
	end
	if ( not CT_RA_ModVersion or CT_RA_ModVersion ~= CT_RA_VersionNumber ) then
		if ( not CT_RA_ModVersion or CT_RA_ModVersion < 1.465 ) then
			CT_RA_UpdateFrame.showDialog = 5;
		end
		if ( not CT_RA_ModVersion or CT_RA_ModVersion < 1.165 ) then
			DEFAULT_CHAT_FRAME:AddMessage("<CTRaid> All options reset due to new options format. We apologize for this.", 1, 1, 0);
			CT_RA_ResetOptions();
			CT_RAMenu_Options["temp"]["unchanged"] = nil;
		end
		CT_RA_ModVersion = CT_RA_VersionNumber;
	end
	CT_RAMenu_UpdateWindowPositions();
	CT_RAMenu_UpdateMenu();
	CT_RASets_Button:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - (80 * cos(CT_RASets_ButtonPosition)), (80 * sin(CT_RASets_ButtonPosition)) - 52);
	if ( CT_RAMenu_Locked == 0 ) then
		CT_RAMenuFrameHomeLock:SetText("Lock");
	end

	CT_RA_UpdateResFrame();
--	if ( CT_RAMenu_Options["temp"]["ShowMonitor"] and GetNumRaidMembers() > 0 ) then
--		CT_RA_ResFrame:Show();
--	end
	
	CT_RA_UpdateRaidGroup(0);
end

function CT_RAMenuNotify_SetChecked(self)
	if ( self == CT_RAMenuFrameBuffsNotifyDebuffs ) then
		CT_RAMenu_Options["temp"]["NotifyDebuffs"]["main"] = self:GetChecked();
	else
		CT_RAMenu_Options["temp"]["NotifyDebuffs"]["hidebuffs"] = not self:GetChecked();
	end
	for i = 1, NUM_RAID_GROUPS, 1 do
		if ( not CT_RAMenu_Options["temp"]["NotifyDebuffs"]["main"] and CT_RAMenu_Options["temp"]["NotifyDebuffs"]["hidebuffs"] ) then
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsGroup" .. i .. "Text"):SetTextColor(0.3, 0.3, 0.3);
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsGroup" .. i .. "CheckButton"):Disable();
		else
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsGroup" .. i .. "Text"):SetTextColor(1, 1, 1);
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsGroup" .. i .. "CheckButton"):Enable();
		end
	end
	for i = 1, CT_RA_MaxGroups, 1 do
		if ( not CT_RAMenu_Options["temp"]["NotifyDebuffs"]["main"] and CT_RAMenu_Options["temp"]["NotifyDebuffs"]["hidebuffs"] ) then
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. i .. "Text"):SetTextColor(0.3, 0.3, 0.3);
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. i .. "CheckButton"):Disable();
		else
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. i .. "Text"):SetTextColor(1, 1, 1);
			getglobal("CT_RAMenuFrameBuffsNotifyDebuffsClass" .. i .. "CheckButton"):Enable();
		end
	end
end

function CT_RAMenuGeneralMisc_AddMTs(self)
	local new = ( CT_RAMenu_Options["temp"]["ShowNumMTs"] or 9 ) + 1;
	if ( new == 10 ) then
		self:Disable();
	end
	CT_RAMenuFrameGeneralMTsSubtract:Enable();
	CT_RAMenu_Options["temp"]["ShowNumMTs"] = new;
	CT_RAMenuFrameGeneralMTsNum:SetText(new);
	CT_RA_UpdateMTs(true);
	CT_RA_UpdateRaidFrameOptions();
end

function CT_RAMenuGeneralMisc_SubtractMTs(self)
	local new = ( CT_RAMenu_Options["temp"]["ShowNumMTs"] or 10 ) - 1;
	if ( new == 1 ) then
		self:Disable();
	end
	CT_RAMenuFrameGeneralMTsAdd:Enable();
	CT_RAMenu_Options["temp"]["ShowNumMTs"] = new;
	CT_RAMenuFrameGeneralMTsNum:SetText(new);
	CT_RA_UpdateMTs(true);
	CT_RA_UpdateRaidFrameOptions();
end

function CT_RAMenuNotifyGroup_SetChecked(self)
	CT_RAMenu_Options["temp"]["NotifyDebuffs"][self:GetParent():GetID()] = self:GetChecked();
end

function CT_RAMenuNotifyClass_SetChecked(self)
	CT_RAMenu_Options["temp"]["NotifyDebuffsClass"][self:GetParent():GetID()] = self:GetChecked();
end

function CT_RAMenuDebuff_OnClick(self)
	local frame = self:GetParent();
	local type = getglobal(self:GetParent():GetName() .. "Text"):GetText();
	type = gsub(type, " ", "");
	frame.r = CT_RAMenu_Options["temp"]["DebuffColors"][frame:GetID()]["r"];
	frame.g = CT_RAMenu_Options["temp"]["DebuffColors"][frame:GetID()]["g"];
	frame.b = CT_RAMenu_Options["temp"]["DebuffColors"][frame:GetID()]["b"];
	frame.opacity = CT_RAMenu_Options["temp"]["DebuffColors"][frame:GetID()]["a"];
	frame.opacityFunc = CT_RAMenuDebuff_SetColor;
	frame.swatchFunc = CT_RAMenuDebuff_SetOpacity;
	frame.hasOpacity = 1;
	ColorPickerFrame.frame = frame;
	CloseMenus();
	UIDropDownMenuButton_OpenColorPicker(frame);
end

function CT_RAMenuDebuff_SetColor()
	local type = getglobal(ColorPickerFrame.frame:GetName() .. "Text"):GetText();
	local r, g, b = ColorPickerFrame:GetColorRGB();
	CT_RAMenu_Options["temp"]["DebuffColors"][ColorPickerFrame.frame:GetID()]["r"] = r;
	CT_RAMenu_Options["temp"]["DebuffColors"][ColorPickerFrame.frame:GetID()]["g"] = g;
	CT_RAMenu_Options["temp"]["DebuffColors"][ColorPickerFrame.frame:GetID()]["b"] = b;
	getglobal(ColorPickerFrame.frame:GetName() .. "SwatchNormalTexture"):SetVertexColor(r, g, b);
end

function CT_RAMenuDebuff_SetOpacity()
	local type = getglobal(ColorPickerFrame.frame:GetName() .. "Text"):GetText();
	local a = OpacitySliderFrame:GetValue();
	CT_RAMenu_Options["temp"]["DebuffColors"][ColorPickerFrame.frame:GetID()]["a"] = a;
end

function CT_RAMenuBuff_Move(self, move)

	if ( string.find(self:GetParent():GetName(), "Debuff") ) then
		-- Debuff
		if ( not getglobal("CT_RAMenuFrameBuffsDebuff" .. (self:GetParent():GetID()+move) .. "Text") ) then return; end
		local temp = getglobal("CT_RAMenuFrameBuffsDebuff" .. (self:GetParent():GetID()+move) .. "Text"):GetText();
		local temp2 = getglobal(self:GetParent():GetName() .. "Text"):GetText();
		getglobal("CT_RAMenuFrameBuffsDebuff" .. (self:GetParent():GetID()+move) .. "Text"):SetText(temp2);
		getglobal(self:GetParent():GetName() .. "Text"):SetText(temp);

		local temparr = CT_RAMenu_Options["temp"]["DebuffColors"][self:GetParent():GetID()];
		local temparr2 = CT_RAMenu_Options["temp"]["DebuffColors"][self:GetParent():GetID()+move];
		CT_RAMenu_Options["temp"]["DebuffColors"][self:GetParent():GetID()] = temparr2;
		CT_RAMenu_Options["temp"]["DebuffColors"][self:GetParent():GetID()+move] = temparr;

		getglobal("CT_RAMenuFrameBuffsDebuff" .. self:GetParent():GetID()+move .. "SwatchNormalTexture"):SetVertexColor(temparr.r, temparr.g, temparr.b);
		getglobal("CT_RAMenuFrameBuffsDebuff" .. self:GetParent():GetID() .. "SwatchNormalTexture"):SetVertexColor(temparr2.r, temparr2.g, temparr2.b);

		if ( temparr2["id"] ~= -1 ) then
			getglobal(self:GetParent():GetName() .. "CheckButton"):SetChecked(1);
			getglobal(self:GetParent():GetName() .. "Text"):SetTextColor(1, 1, 1);
		else
			getglobal(self:GetParent():GetName() .. "Text"):SetTextColor(0.3, 0.3, 0.3);
			getglobal(self:GetParent():GetName() .. "CheckButton"):SetChecked(nil);
		end
		if ( temparr["id"] ~= -1 ) then
			getglobal("CT_RAMenuFrameBuffsDebuff" .. (self:GetParent():GetID()+move) .. "CheckButton"):SetChecked(1);
			getglobal("CT_RAMenuFrameBuffsDebuff" .. (self:GetParent():GetID()+move) .. "Text"):SetTextColor(1, 1, 1);
		else
			getglobal("CT_RAMenuFrameBuffsDebuff" .. (self:GetParent():GetID()+move) .. "Text"):SetTextColor(0.3, 0.3, 0.3);
			getglobal("CT_RAMenuFrameBuffsDebuff" .. (self:GetParent():GetID()+move) .. "CheckButton"):SetChecked(nil);
		end

	else
		-- Buff
		if ( not getglobal("CT_RAMenuFrameBuffsBuff" .. (self:GetParent():GetID()+move) .. "Text") ) then return; end
		local temp = getglobal("CT_RAMenuFrameBuffsBuff" .. (self:GetParent():GetID()+move) .. "Text"):GetText();
		local temp2 = getglobal(self:GetParent():GetName() .. "Text"):GetText();
		getglobal("CT_RAMenuFrameBuffsBuff" .. (self:GetParent():GetID()+move) .. "Text"):SetText(temp2);
		getglobal(self:GetParent():GetName() .. "Text"):SetText(temp);

		local temparr = CT_RAMenu_Options["temp"]["BuffArray"][self:GetParent():GetID()];
		local temparr2 = CT_RAMenu_Options["temp"]["BuffArray"][self:GetParent():GetID()+move];
		CT_RAMenu_Options["temp"]["BuffArray"][self:GetParent():GetID()] = temparr2;
		CT_RAMenu_Options["temp"]["BuffArray"][self:GetParent():GetID()+move] = temparr;
		if ( temparr2["show"] ~= -1 ) then
			getglobal(self:GetParent():GetName() .. "CheckButton"):SetChecked(1);
			getglobal(self:GetParent():GetName() .. "Text"):SetTextColor(1, 1, 1);
		else
			getglobal(self:GetParent():GetName() .. "Text"):SetTextColor(0.3, 0.3, 0.3);
			getglobal(self:GetParent():GetName() .. "CheckButton"):SetChecked(nil);
		end
		if ( temparr["show"] ~= -1 ) then
			getglobal("CT_RAMenuFrameBuffsBuff" .. (self:GetParent():GetID()+move) .. "CheckButton"):SetChecked(1);
			getglobal("CT_RAMenuFrameBuffsBuff" .. (self:GetParent():GetID()+move) .. "Text"):SetTextColor(1, 1, 1);
		else
			getglobal("CT_RAMenuFrameBuffsBuff" .. (self:GetParent():GetID()+move) .. "Text"):SetTextColor(0.3, 0.3, 0.3);
			getglobal("CT_RAMenuFrameBuffsBuff" .. (self:GetParent():GetID()+move) .. "CheckButton"):SetChecked(nil);
		end
	end
	CT_RA_UpdateRaidGroup(2);
end

function CT_RAMenuBuff_ShowToggle(self)
	local newid;
	if ( self:GetChecked() ) then
		newid = self:GetParent():GetID();
		getglobal(self:GetParent():GetName() .. "Text"):SetTextColor(1, 1, 1);
	else
		getglobal(self:GetParent():GetName() .. "Text"):SetTextColor(0.3, 0.3, 0.3);
		newid = -1;
	end
	local type = getglobal(self:GetParent():GetName() .. "Text"):GetText();
	if ( string.find(self:GetParent():GetName(), "Debuff") ) then
		-- Debuff
		CT_RAMenu_Options["temp"]["DebuffColors"][self:GetParent():GetID()].id = newid;
	else
		-- Buff
		if ( self:GetChecked() ) then
			CT_RAMenu_Options["temp"]["BuffArray"][self:GetParent():GetID()]["show"] = 1;
		else
			CT_RAMenu_Options["temp"]["BuffArray"][self:GetParent():GetID()]["show"] = -1;
		end
	end
	CT_RA_UpdateRaidGroup(2);
end

function CT_RAMenuDisplay_ShowMP(self)
	CT_RAMenu_Options["temp"]["HideMP"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateMTs(true);
end

function CT_RAMenuDisplay_ShowRP(self)
	CT_RAMenu_Options["temp"]["HideRP"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateMTs(true);
end

function CT_RAMenuDisplay_ShowHealth(self)
	if ( not self:GetChecked() ) then
		CT_RAMenu_Options["temp"]["MemberHeight"] = CT_RAMenu_Options["temp"]["MemberHeight"]+8;
	else
		CT_RAMenu_Options["temp"]["MemberHeight"] = CT_RAMenu_Options["temp"]["MemberHeight"]-8;
	end
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateMTs(true);
end

-- This function is not being called from anywhere
--[[
function CT_RAMenuDisplay_ShowHP(self)
	if ( self:GetChecked() ) then
		if ( CT_RAMenuFrameGeneralDisplayShowHPPercentCB:GetChecked() ) then
			CT_RAMenu_Options["temp"]["ShowHP"] = 2;
		else
			CT_RAMenu_Options["temp"]["ShowHP"] = 1;
		end
	else
		CT_RAMenu_Options["temp"]["ShowHP"] = nil;
	end
	if ( self:GetChecked() ) then
		CT_RAMenuFrameGeneralDisplayHealthPercentsText:SetTextColor(1, 1, 1);
		CT_RAMenuFrameGeneralDisplayShowHPPercentCB:Enable();
		CT_RAMenuFrameGeneralDisplayShowHPSwatchNormalTexture:SetVertexColor(CT_RAMenu_Options["temp"]["PercentColor"].r, CT_RAMenu_Options["temp"]["PercentColor"].g, CT_RAMenu_Options["temp"]["PercentColor"].b);
		CT_RAMenuFrameGeneralDisplayShowHPSwatchBG:SetVertexColor(1, 1, 1);
	else
		CT_RAMenuFrameGeneralDisplayHealthPercentsText:SetTextColor(0.3, 0.3, 0.3);
		CT_RAMenuFrameGeneralDisplayShowHPPercentCB:Disable();
		CT_RAMenuFrameGeneralDisplayShowHPSwatchNormalTexture:SetVertexColor(0.3, 0.3, 0.3);
		CT_RAMenuFrameGeneralDisplayShowHPSwatchBG:SetVertexColor(0.3, 0.3, 0.3);
	end
	for i = 1, GetNumRaidMembers(), 1 do
		if ( CT_RA_Stats[UnitName("raid" .. i)] ) then
			CT_RA_UpdateUnitHealth(CT_RA_UnitIDFrameMap["raid"..i], CT_RA_Stats[UnitName("raid" .. i)]["Health"], CT_RA_Stats[UnitName("raid" .. i)]["Healthmax"]);
		end
	end
	CT_RA_UpdateMTs(true);
	CT_RA_UpdatePTs(true);
end
]]

-- This function is not being called from anywhere
--[[
function CT_RAMenuDisplay_ShowHPPercents(self)
	if ( self:GetChecked() ) then
		CT_RAMenu_Options["temp"]["ShowHP"] = 2;
	else
		CT_RAMenu_Options["temp"]["ShowHP"] = 1;
	end
	for i = 1, GetNumRaidMembers(), 1 do
		if ( CT_RA_Stats[UnitName("raid" .. i)] ) then
			CT_RA_UpdateUnitHealth(CT_RA_UnitIDFrameMap["raid"..i], CT_RA_Stats[UnitName("raid" .. i)]["Health"], CT_RA_Stats[UnitName("raid" .. i)]["Healthmax"]);
		end
	end
end
]]

function CT_RAMenuDisplay_ShowGroupNames(self)
	CT_RAMenu_Options["temp"]["HideNames"] = not self:GetChecked();
	CT_RA_UpdateVisibility();
 	CT_RA_UpdateRaidFrames();
end

function CT_RAMenuDisplay_ChangeWC(self)
	local frame = self:GetParent();
	frame.r = CT_RAMenu_Options["temp"]["DefaultColor"]["r"];
	frame.g = CT_RAMenu_Options["temp"]["DefaultColor"]["g"];
	frame.b = CT_RAMenu_Options["temp"]["DefaultColor"]["b"];
	frame.opacity = CT_RAMenu_Options["temp"]["DefaultColor"]["a"];
	frame.opacityFunc = CT_RAMenuDisplay_SetOpacity;
	frame.swatchFunc = CT_RAMenuDisplay_SetColor;
	frame.cancelFunc = CT_RAMenuDisplay_CancelColor;
	frame.hasOpacity = 1;
	CloseMenus();
	UIDropDownMenuButton_OpenColorPicker(frame);
end

function CT_RAMenuDisplay_SetColor()
	local r, g, b = ColorPickerFrame:GetColorRGB();
	CT_RAMenu_Options["temp"]["DefaultColor"]["r"] = r;
	CT_RAMenu_Options["temp"]["DefaultColor"]["g"] = g;
	CT_RAMenu_Options["temp"]["DefaultColor"]["b"] = b;
	CT_RAMenuFrameGeneralDisplayWindowColorSwatchNormalTexture:SetVertexColor(r, g, b);
	CT_RA_UpdateRaidGroupColors();
end

function CT_RAMenuDisplay_SetOpacity()
	CT_RAMenu_Options["temp"]["DefaultColor"]["a"] = OpacitySliderFrame:GetValue();
	CT_RA_UpdateRaidGroupColors();
end

function CT_RAMenuDisplay_CancelColor(val)
	CT_RAMenu_Options["temp"]["DefaultColor"]["r"] = val.r;
	CT_RAMenu_Options["temp"]["DefaultColor"]["g"] = val.g;
	CT_RAMenu_Options["temp"]["DefaultColor"]["b"] = val.b;
	CT_RAMenu_Options["temp"]["DefaultColor"]["a"] = val.opacity;
	CT_RAMenuFrameGeneralDisplayWindowColorSwatchNormalTexture:SetVertexColor(val.r, val.g, val.b);
	CT_RA_UpdateRaidGroupColors();
end

function CT_RAMenuDisplay_LockGroups(self)
	CT_RAMenu_Options["temp"]["LockGroups"] = self:GetChecked();
	CT_RA_UpdateRaidMovability();
	CT_RA_UpdateVisibility();
end

function CT_RAMenuFrameGeneralMiscDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, CT_RAMenuFrameGeneralMiscDropDown_Initialize);
	UIDropDownMenu_SetWidth(self, 130);
	UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralMiscDropDown, 1);
end

function CT_RAMenuFrameGeneralMiscDropDown_Initialize(self)
	local info = {};
	info.text = "Group";
	info.func = CT_RAMenuFrameGeneralMiscDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Class";
	info.func = CT_RAMenuFrameGeneralMiscDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end


function CT_RAMenuFrameGeneralMiscDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralMiscDropDown, self:GetID());
	if ( self:GetID() == 1 ) then
		CT_RA_SetSortType("group");
	elseif ( self:GetID() == 2 ) then
		CT_RA_SetSortType("class");
	end
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrameOptions();
	CT_RAOptions_UpdateGroups();
end

function CT_RAMenuFrameBuffsBuffsDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, CT_RAMenuFrameBuffsBuffsDropDown_Initialize);
	UIDropDownMenu_SetWidth(self, 180);
	UIDropDownMenu_SetSelectedID(CT_RAMenuFrameBuffsBuffsDropDown, 1);
end

function CT_RAMenuFrameBuffsBuffsDropDown_Initialize()
	local info = {};
	info.text = "Show buffs";
	info.func = CT_RAMenuFrameBuffsBuffsDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Show debuffs";
	info.func = CT_RAMenuFrameBuffsBuffsDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Show buffs until debuffed";
	info.func = CT_RAMenuFrameBuffsBuffsDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end


function CT_RAMenuFrameBuffsBuffsDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(CT_RAMenuFrameBuffsBuffsDropDown, self:GetID());
	if ( self:GetID() == 1 ) then
		CT_RAMenu_Options["temp"]["ShowDebuffs"] = nil;
		CT_RAMenu_Options["temp"]["ShowBuffsDebuffed"] = nil;
	elseif ( self:GetID() == 2 ) then
		CT_RAMenu_Options["temp"]["ShowDebuffs"] = 1;
		CT_RAMenu_Options["temp"]["ShowBuffsDebuffed"] = nil;
	else
		CT_RAMenu_Options["temp"]["ShowDebuffs"] = nil;
		CT_RAMenu_Options["temp"]["ShowBuffsDebuffed"] = 1;
	end
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateMTs(true);
end

function CT_RAMenuFrameGeneralDisplayHealthDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, CT_RAMenuFrameGeneralDisplayHealthDropDown_Initialize);
	UIDropDownMenu_SetWidth(self, 130);
	UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralDisplayHealthDropDown, 1);
end

function CT_RAMenuFrameGeneralDisplayHealthDropDown_Initialize()
	local info = {};
	info.text = "Show Values";
	info.func = CT_RAMenuFrameGeneralDisplayHealthDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Show Percentages";
	info.func = CT_RAMenuFrameGeneralDisplayHealthDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Show Deficit";
	info.func = CT_RAMenuFrameGeneralDisplayHealthDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Show only MTT HP %";
	info.func = CT_RAMenuFrameGeneralDisplayHealthDropDown_OnClick;
	UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Show None";
	info.func = CT_RAMenuFrameGeneralDisplayHealthDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end


function CT_RAMenuFrameGeneralDisplayHealthDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralDisplayHealthDropDown, self:GetID());
	if ( self:GetID() < 5 ) then
		CT_RAMenu_Options["temp"]["ShowHP"] = self:GetID();
	else
		CT_RAMenu_Options["temp"]["ShowHP"] = nil;
	end
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateMTs(true);
	CT_RA_UpdatePTs(true);
end

function CT_RAMenu_General_ResetWindows()
	if (InCombatLockdown()) then
		return;
	end
	for i = 1, CT_RA_MaxGroups do
		local drag = getglobal("CT_RAGroupDrag" .. i);
		drag:ClearAllPoints();
	end
	CT_RAMTGroupDrag:ClearAllPoints();
	CT_RAPTGroupDrag:ClearAllPoints();
	CT_RA_EmergencyFrameDrag:ClearAllPoints();

	local x = 950;
	local y;
	local y1 = -135;
	local y2 = y1 - 240;
	local c = 0;
	for i = 1, CT_RA_MaxGroups do
		local drag = getglobal("CT_RAGroupDrag" .. i);
		if (c > 1) then
			c = 0;
			x = x - 95;
		end
		if (c == 0) then
			y = y1;
		else
			y = y2;
		end
		drag:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", x, y);
		c = c + 1;
	end
	y = y1 + 3;
	x = x - 95;
	CT_RAMTGroupDrag:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", x, y);
	x = x - 95;
	CT_RAPTGroupDrag:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", x, y);
	CT_RA_EmergencyFrameDrag:SetPoint("CENTER", "UIParent", "CENTER");
	CT_RA_LinkDrag(CT_RA_EmergencyFrame, CT_RA_EmergencyFrameDrag, "TOP", "TOP", 0, 2);
	CT_RAMenu_SaveWindowPositions();
end

function CT_RAMenuDisplay_ChangeAC(self)
	local frame = self:GetParent();
	frame.r = CT_RAMenu_Options["temp"]["DefaultAlertColor"]["r"];
	frame.g = CT_RAMenu_Options["temp"]["DefaultAlertColor"]["g"];
	frame.b = CT_RAMenu_Options["temp"]["DefaultAlertColor"]["b"];
	frame.swatchFunc = CT_RAMenuDisplay_SetAlertColor;
	frame.cancelFunc = CT_RAMenuDisplay_CancelAlertColor;
	CloseMenus();
	UIDropDownMenuButton_OpenColorPicker(frame);
end

function CT_RAMenuDisplay_SetAlertColor()
	local r, g, b = ColorPickerFrame:GetColorRGB();
	CT_RAMenu_Options["temp"]["DefaultAlertColor"]["r"] = r;
	CT_RAMenu_Options["temp"]["DefaultAlertColor"]["g"] = g;
	CT_RAMenu_Options["temp"]["DefaultAlertColor"]["b"] = b;
	CT_RAMenuFrameGeneralDisplayAlertColorSwatchNormalTexture:SetVertexColor(r, g, b);
end

function CT_RAMenuDisplay_CancelAlertColor(val)
	CT_RAMenu_Options["temp"]["DefaultAlertColor"]["r"] = val.r;
	CT_RAMenu_Options["temp"]["DefaultAlertColor"]["g"] = val.g;
	CT_RAMenu_Options["temp"]["DefaultAlertColor"]["b"] = val.b;
	CT_RAMenuFrameGeneralDisplayAlertColorSwatchNormalTexture:SetVertexColor(val.r, val.g, val.b);
end

function CT_RAMenuDisplay_ChangeTC(self)
	local frame = self:GetParent();
	frame.r = CT_RAMenu_Options["temp"]["PercentColor"]["r"];
	frame.g = CT_RAMenu_Options["temp"]["PercentColor"]["g"];
	frame.b = CT_RAMenu_Options["temp"]["PercentColor"]["b"];
	frame.swatchFunc = CT_RAMenuDisplayPercent_SetColor;
	frame.cancelFunc = CT_RAMenuDisplayPercent_CancelColor;
	CloseMenus();
	UIDropDownMenuButton_OpenColorPicker(frame);
end

function CT_RAMenuDisplayPercent_SetColor()
	local r, g, b = ColorPickerFrame:GetColorRGB();
	CT_RAMenu_Options["temp"]["PercentColor"] = { ["r"] = r, ["g"] = g, ["b"] = b };
	CT_RAMenuFrameGeneralDisplayShowHPSwatchNormalTexture:SetVertexColor(r, g, b);
	CT_RA_UpdateRaidGroupColors();
end

function CT_RAMenuDisplayPercent_CancelColor(val)
	CT_RAMenu_Options["temp"]["PercentColor"] = { r = val.r, g = val.g, b = val.b };
	CT_RAMenuFrameGeneralDisplayShowHPSwatchNormalTexture:SetVertexColor(val.r, val.g, val.b);
	CT_RA_UpdateRaidGroupColors();
end

-- This function is not called from anywhere
--[[
function CT_RAMenuGeneral_HideShort(self)
	CT_RAMenu_Options["temp"]["HideShort"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(0);
end
]]

-- This function is not called from anywhere
--[[
function CT_RAMenuBuff_ShowDebuffs(self)
	CT_RAMenu_Options["temp"]["ShowDebuffs"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(0);
end
]]

function CT_RAMenuGeneral_HideBorder(self)
	CT_RAMenu_Options["temp"]["HideBorder"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrameOptions();
	CT_RA_UpdateMTs(true);
	CT_RA_UpdatePTs(true);
	if ( self:GetChecked() ) then
		CT_RAMenuFrameGeneralMiscRemoveSpacingCB:Enable();
		CT_RAMenuFrameGeneralMiscRemoveSpacingText:SetTextColor(1, 1, 1);
	else
		CT_RAMenuFrameGeneralMiscRemoveSpacingCB:Disable();
		CT_RAMenuFrameGeneralMiscRemoveSpacingText:SetTextColor(0.3, 0.3, 0.3);
	end
end

function CT_RAMenuGeneral_RemoveSpacing(self)
	CT_RAMenu_Options["temp"]["HideSpace"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrameOptions();
	CT_RA_UpdateMTs(true);
	CT_RA_UpdatePTs(true);
end

function CT_RAMenu_Misc_ShowTankDeath(self)
	CT_RAMenu_Options["temp"]["HideTankNotifications"] = not self:GetChecked();
end

function CT_RAMenuGeneral_ShowHorizontal(self)
	CT_RAMenu_Options["temp"]["ShowHorizontal"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrameOptions();
end

function CT_RAMenuGeneral_ShowReversed(self)
	CT_RAMenu_Options["temp"]["ShowReversed"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrameOptions();
	CT_RA_UpdateMTs(true);
	CT_RA_UpdatePTs(true);
end

function CT_RAMenuGeneral_ShowMTs(self)
	CT_RAMenu_Options["temp"]["HideMTs"] = not self:GetChecked();
	CT_RA_UpdateRaidGroup(3);
	CT_RA_UpdateRaidFrameOptions();
	CT_RA_UpdateMTs(true);
end

function CT_RAMenuGeneral_ShowMeters(self)
	if ( not CT_RAMenu_Options["temp"]["StatusMeters"]  ) then
		CT_RAMenu_Options["temp"]["StatusMeters"] = {
			["Health Display"] = { },
			["Mana Display"] = { },
			["Raid Health"] = { },
			["Raid Mana"] = { },
			["Background"] = {
				["r"] = 0,
				["g"] = 0,
				["b"] = 1,
				["a"] = 0.5
			}
		};
	end
	CT_RAMenu_Options["temp"]["StatusMeters"]["Show"] = self:GetChecked();
	if ( self:GetChecked() ) then
		CT_RAMetersFrame:Show();
		CT_RAMeters_UpdateWindow();
	else
		CT_RAMetersFrame:Hide();
	end
end

function CT_RAMenuMisc_Slider_OnChange(self)
	local spell = CT_RAMenu_Options["temp"]["ClassHealings"][CT_RA_GetLocale()][UnitClass("player")][self:GetID()];
	local realVal = 0;
	if ( CT_RAMenu_Options["temp"]["UsePercentValues"] ) then
		realVal = self:GetValue();
		CT_RAMenu_Options["temp"]["ClassHealings"][CT_RA_GetLocale()][UnitClass("player")][self:GetID()][5] = realVal;
		if ( type(spell[1]) == "table" ) then
			getglobal(self:GetName() .. "Text"):SetText(spell[1][1] .. ": " .. realVal .. "%");
		else
			getglobal(self:GetName() .. "Text"):SetText(spell[1] .. ": " .. realVal .. "%");
		end
	else
		realVal = 5000-self:GetValue();
		CT_RAMenu_Options["temp"]["ClassHealings"][CT_RA_GetLocale()][UnitClass("player")][self:GetID()][3] = realVal;
		if ( type(spell[1]) == "table" ) then
			getglobal(self:GetName() .. "Text"):SetText(spell[1][1] .. ": -" .. realVal);
		else
			getglobal(self:GetName() .. "Text"):SetText(spell[1] .. ": -" .. realVal);
		end
	end
end

function CT_RAMenuMisc_OnUpdate(self, elapsed)
	if ( GetNumRaidMembers() == 0 ) then
		return
	end;
	if ( self.scaleupdate ) then
		self.scaleupdate = self.scaleupdate - elapsed;
		if ( self.scaleupdate <= 0 ) then
			self.scaleupdate = 10;
			if ( (not InCombatLockdown()) and CT_RAMenu_Options["temp"]["WindowScaling"] ) then
				local newScaling = CT_RAMenu_Options["temp"]["WindowScaling"];
				local member;
				local width, height = CT_RA_GetFrameData(-1);
				for i = 1, CT_RA_MaxGroups, 1 do
					getglobal("CT_RAGroupDrag" .. i):SetWidth(width*newScaling);
					getglobal("CT_RAGroupDrag" .. i):SetHeight(height*newScaling/2);
					getglobal("CT_RAGroup" .. i):SetScale(newScaling);
				end
			end
			if ( (not InCombatLockdown()) and CT_RAMenu_Options["temp"]["MTScaling"] ) then
				local newScaling = CT_RAMenu_Options["temp"]["MTScaling"];
				local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
				CT_RAMTGroup:SetScale(newScaling);
				CT_RAMTTGroup:SetScale(newScaling);
				CT_RAPTGroup:SetScale(newScaling);
				CT_RAPTTGroup:SetScale(newScaling);
				CT_RAMTGroupDrag:SetWidth(mtwidth*newScaling);
				CT_RAMTGroupDrag:SetHeight(height*newScaling/2);
				CT_RAPTGroupDrag:SetWidth(ptwidth*newScaling);
				CT_RAPTGroupDrag:SetHeight(height*newScaling/2);
			end
			if ( CT_RAMenu_Options["temp"]["EMScaling"] ) then
				local newScaling = CT_RAMenu_Options["temp"]["EMScaling"];
				CT_RAMenu_SetScale(CT_RA_EmergencyFrame, newScaling);
				CT_RAMenu_SetScale(CT_RA_EmergencyFrameDrag, newScaling);
				CT_RA_LinkDrag(CT_RA_EmergencyFrame, CT_RA_EmergencyFrameDrag, "TOP", "TOP", 0, 2);
			end
		end
	end
end

function CT_RAMenu_SetScale(frame, scale)
	-- ----------------
	-- Change a window's scale without appearing to change
	-- its position while maintaining the current anchor point.
	-- ----------------
	local parent = frame:GetParent();

	local ap, rf, rp, rx, ry = frame:GetPoint();

	local oldScale = frame:GetScale();
	local newScale = scale;

	local frameX, frameY, parentX, parentY;
	local val;

	-- Determine frame X and Y values.
	if (ap == "TOPLEFT" or ap == "BOTTOMLEFT" or ap == "LEFT") then
		frameX = frame:GetLeft();
	elseif (ap == "TOPRIGHT" or ap == "BOTTOMRIGHT" or ap == "RIGHT") then
		frameX = frame:GetRight();
	elseif (ap == "TOP" or ap == "BOTTOM" or ap == "CENTER") then
		frameX = frame:GetCenter();
	end

	if (ap == "TOPLEFT" or ap == "TOPRIGHT" or ap == "TOP") then
		frameY = frame:GetTop();
	elseif (ap == "BOTTOMLEFT" or ap == "BOTTOMRIGHT" or ap == "BOTTOM") then
		frameY = frame:GetBottom();
	elseif (ap == "LEFT" or ap == "RIGHT" or ap == "CENTER") then
		val, frameY = frame:GetCenter();
	end

	-- Determine parent X and Y values.
	if (rp == "TOPLEFT" or rp == "BOTTOMLEFT" or rp == "LEFT") then
		parentX = parent:GetLeft();
	elseif (rp == "TOPRIGHT" or rp == "BOTTOMRIGHT" or rp == "RIGHT") then
		parentX = parent:GetRight();
	elseif (rp == "TOP" or rp == "BOTTOM" or rp == "CENTER") then
		parentX = parent:GetCenter();
	end

	if (rp == "TOPLEFT" or rp == "TOPRIGHT" or rp == "TOP") then
		parentY = parent:GetTop();
	elseif (rp == "BOTTOMLEFT" or rp == "BOTTOMRIGHT" or rp == "BOTTOM") then
		parentY = parent:GetBottom();
	elseif (rp == "LEFT" or rp == "RIGHT" or rp == "CENTER") then
		val, parentY = parent:GetCenter();
	end

	-- Calculate offsets
	local yOffset = frameY - (parentY / oldScale);
	local xOffset = frameX - (parentX / oldScale);

	-- Calculate the new X and Y offsets for the new scale.
	local newX = xOffset * (oldScale / newScale);
	local newY = yOffset * (oldScale / newScale);

	frame:SetScale(newScale);
	frame:ClearAllPoints();
	frame:SetPoint(ap, rf, rp, newX, newY);
end

function CT_RA_SpellStartCast(spell, target)
	if (
		spell == CT_RA_RESURRECTION or
		spell == CT_RA_ANCESTRALSPIRIT or
		spell == CT_RA_REBIRTH or
		spell == CT_RA_REDEMPTION
	) then
		CT_RA_AddMessage("RES " .. target);
		CT_RA_Ressers[(UnitName("player"))] = target;
		CT_RA_UpdateResFrame();
	end
end

function CT_RA_SpellEndCast(unit)
	if ( unit and unit == "player" and CT_RA_Ressers[(UnitName("player"))] ) then
		CT_RA_AddMessage("RESNO");
	end
end

function CT_RAMenuMisc_OnEvent(self, event, ...)
	if ( event == "PLAYER_REGEN_ENABLED" ) then
		CT_RA_InCombat = nil;
		CT_RA_UpdateRaidFrameOptions();
		CT_RA_UpdateMTs(true);
		CT_RA_UpdatePTs(true);
	elseif ( event == "PLAYER_REGEN_DISABLED" ) then
		CT_RA_InCombat = 1;
		if ( CT_RAMenuFrame:IsVisible() ) then
			CT_RAMenu_OnShow(CT_RAMenuFrame);
		end
	end
end

function CT_RAMenuAdditional_Scaling_OnShow(slider)
	getglobal(slider:GetName().."High"):SetText("150%");
	getglobal(slider:GetName().."Low"):SetText("50%");
	if ( not CT_RAMenu_Options["temp"]["WindowScaling"] ) then
		CT_RAMenu_Options["temp"]["WindowScaling"] = 1;
	end
	getglobal(slider:GetName() .. "Text"):SetText("Group Scaling - " .. floor(CT_RAMenu_Options["temp"]["WindowScaling"]*100+0.5) .. "%");

	slider:SetMinMaxValues(0.5, 1.5);
	slider:SetValueStep(0.01);
	slider:SetValue(CT_RAMenu_Options["temp"]["WindowScaling"]);
end

function CT_RAMenuAdditional_Scaling_OnValueChanged(self)
	CT_RAMenu_Options["temp"]["WindowScaling"] = floor(self:GetValue()*100+0.5)/100;
	getglobal(self:GetName() .. "Text"):SetText("Group Scaling - " .. floor(self:GetValue()*100+0.5) .. "%");
	local newScaling = CT_RAMenu_Options["temp"]["WindowScaling"];
	local member;
	
	if (InCombatLockdown()) then
		return;
	end

	local width, height = CT_RA_GetFrameData(-1);
	for i = 1, CT_RA_MaxGroups, 1 do
		getglobal("CT_RAGroupDrag" .. i):SetWidth(width*newScaling);
		getglobal("CT_RAGroupDrag" .. i):SetHeight(height*newScaling/2);
		getglobal("CT_RAGroup" .. i):SetScale(newScaling);
	end
end

function CT_RAMenuAdditional_EM_OnShow(slider)
	local id = slider:GetID();
	
	if ( not CT_RAMenu_Options["temp"]["EMThreshold"] ) then
		CT_RAMenu_Options["temp"]["EMThreshold"] = 0.9;
	end
	if ( not CT_RAMenu_Options["temp"]["EMScaling"] ) then
		CT_RAMenu_Options["temp"]["EMScaling"] = 1;
	end
	
	local tbl = {
		["hl"] = {
			{ "99%", "25%" },
			{ "150%", "50%" }
		},
		["title"] = {
			"Health Threshold - " .. floor(CT_RAMenu_Options["temp"]["EMThreshold"]*100+0.5) .. "%",
			"Scaling - " .. floor(CT_RAMenu_Options["temp"]["EMScaling"]*100+0.5) .. "%"
		},
		["tooltip"] = {
			"Regulates the health threshold of when to display the health bars.",
			"Rescales the window to make it larger or smaller."
		},
		["minmax"] = {
			{ 0.25, 0.99 },
			{ 0.5, 1.5 }
		},
		["value"] = {
			CT_RAMenu_Options["temp"]["EMThreshold"],
			CT_RAMenu_Options["temp"]["EMScaling"]
		}
	};
	getglobal(slider:GetName().."High"):SetText(tbl["hl"][id][1]);
	getglobal(slider:GetName().."Low"):SetText(tbl["hl"][id][2]);
	getglobal(slider:GetName() .. "Text"):SetText(tbl["title"][id]);
	slider.tooltipText = tbl["tooltip"][id];
	slider:SetMinMaxValues(tbl["minmax"][id][1], tbl["minmax"][id][2]);
	slider:SetValueStep(0.01);
	slider:SetValue(tbl["value"][id]);
end

function CT_RAMenuAdditional_EM_OnValueChanged(self)
	if ( self:GetID() == 1 ) then
		CT_RAMenu_Options["temp"]["EMThreshold"] = floor(self:GetValue()*100+0.5)/100;
		getglobal(self:GetName() .. "Text"):SetText("Health Threshold - " .. floor(self:GetValue()*100+0.5) .. "%");
		CT_RA_Emergency_UpdateHealth();
	else
		CT_RAMenu_Options["temp"]["EMScaling"] = floor(self:GetValue()*100+0.5)/100;
		getglobal(self:GetName() .. "Text"):SetText("Scaling - " .. floor(self:GetValue()*100+0.5) .. "%");
		
		local newScaling = CT_RAMenu_Options["temp"]["EMScaling"];
		CT_RAMenu_SetScale(CT_RA_EmergencyFrame, newScaling);
		CT_RAMenu_SetScale(CT_RA_EmergencyFrameDrag, newScaling);
		CT_RA_LinkDrag(CT_RA_EmergencyFrame, CT_RA_EmergencyFrameDrag, "TOP", "TOP", 0, 2);
	end
end

function CT_RAMenuAdditional_BG_OnShow(slider)
	if ( not CT_RAMenu_Options["temp"]["BGOpacity"] ) then
		CT_RAMenu_Options["temp"]["BGOpacity"] = 0.4;
	end
	getglobal(slider:GetName().."High"):SetText("75%");
	getglobal(slider:GetName().."Low"):SetText("0%");
	getglobal(slider:GetName() .. "Text"):SetText("Background Opacity - " .. floor(CT_RAMenu_Options["temp"]["BGOpacity"]*100+0.5) .. "%");

	slider:SetMinMaxValues(0, 0.75);
	slider:SetValueStep(0.01);
	slider:SetValue(CT_RAMenu_Options["temp"]["BGOpacity"]);
end

function CT_RAMenuAdditional_BG_OnValueChanged(self)
	CT_RAMenu_Options["temp"]["BGOpacity"] = floor(self:GetValue()*100+0.5)/100;
	getglobal(self:GetName() .. "Text"):SetText("Background Opacity - " .. floor(self:GetValue()*100+0.5) .. "%");
	local opacity, r, g = CT_RAMenu_Options["temp"]["BGOpacity"];
	local _, class;
	for key, value in pairs(CT_RA_UnitIDFrameMap) do
		_, class = UnitClass(key);
		r, g = value.HPBar:GetStatusBarColor();
		value.HPBG:SetVertexColor(r, g, 0, opacity);
		
		if ( class == CT_RA_CLASS_WARRIOR ) then
			value.MPBG:SetVertexColor(1, 0, 0, opacity);
		elseif ( class == CT_RA_CLASS_ROGUE ) then
			value.MPBG:SetVertexColor(1, 1, 0, opacity);
		elseif ( class == CT_RA_CLASS_DEATHKNIGHT ) then
			value.MPBG:SetVertexColor(0, 0.82, 1, opacity);
		else
			value.MPBG:SetVertexColor(0, 0, 1, opacity);
		end
	end
end

function CT_RAMenuAdditional_Alpha_OnShow(slider)
	if ( not CT_RAMenu_Options["temp"]["DefaultAlpha"] ) then
		if ( CT_RAMenu_Options["temp"]["AlphaRange"] ) then
			CT_RAMenu_Options["temp"]["DefaultAlpha"] = 0.35;
		else
			CT_RAMenu_Options["temp"]["DefaultAlpha"] = 1;
		end
	end
	CT_RA_UpdateFrame.rangeTimerMax = 0.25;

	local val = CT_RAMenu_Options["temp"]["DefaultAlpha"];
	local formattedVal = floor(val*100+0.5)
	getglobal(slider:GetName().."High"):SetText("Off");
	getglobal(slider:GetName().."Low"):SetText("25%");
	
	if ( formattedVal == 100 ) then
		getglobal(slider:GetName() .. "Text"):SetText("Frame Alpha - Off (100%)");
	else
		getglobal(slider:GetName() .. "Text"):SetText("Frame Alpha - " .. formattedVal .. "%");
	end

	slider:SetMinMaxValues(0.25, 1);
	slider:SetValueStep(0.01);
	slider:SetValue(val);
end

function CT_RAMenuAdditional_Alpha_OnValueChanged(self)
	CT_RAMenu_Options["temp"]["DefaultAlpha"] = floor(self:GetValue()*100+0.5)/100;
	local formattedVal = floor(self:GetValue()*100+0.5);
	if ( formattedVal == 100 ) then
		getglobal(self:GetName() .. "Text"):SetText("Frame Alpha - Off (100%)");
	else
		getglobal(self:GetName() .. "Text"):SetText("Frame Alpha - " .. formattedVal .. "%");
	end
	CT_RAMenuAdditional_Alpha_Update();
end

function CT_RAMenuAdditional_Alpha_Range(self)
	CT_RAMenu_Options["temp"]["AlphaRange"] = self:GetChecked();
	if (CT_RAMenu_Options["temp"]["AlphaRange"]) then
		CT_RA_UpdateFrame.rangeTimer = CT_RA_UpdateFrame.rangeTimerMax;
	else
		CT_RA_UpdateFrame.rangeTimer = nil;
	end
	CT_RAMenuAdditional_Alpha_Update();
end

function CT_RAMenuAdditional_Alpha_Update()
	if (CT_RAMenu_Options["temp"]["AlphaRange"]) then
		CT_RA_UpdateRange();
	else
		for i = 1, GetNumRaidMembers(), 1 do
			CT_RA_UpdateUnitHealth(CT_RA_UnitIDFrameMap["raid"..i]);
		end
	end
	if ( CT_RA_MainTanks ) then
		CT_RA_UpdateMTs(true);
	end
	if ( CT_RA_PTargets ) then
		CT_RA_UpdatePTs(true);
	end
end

function CT_RAMenuAdditional_ScalingMT_OnShow(slider)
	getglobal(slider:GetName().."High"):SetText("150%");
	getglobal(slider:GetName().."Low"):SetText("50%");
	if ( not CT_RAMenu_Options["temp"]["MTScaling"] ) then
		CT_RAMenu_Options["temp"]["MTScaling"] = 1;
	end
	getglobal(slider:GetName() .. "Text"):SetText("MT/PT Scaling - " .. floor(CT_RAMenu_Options["temp"]["MTScaling"]*100+0.5) .. "%");

	slider:SetMinMaxValues(0.5, 1.5);
	slider:SetValueStep(0.01);
	slider:SetValue(CT_RAMenu_Options["temp"]["MTScaling"]);
end

function CT_RAMenuAdditional_ScalingMT_OnValueChanged(self)
	CT_RAMenu_Options["temp"]["MTScaling"] = floor(self:GetValue()*100+0.5)/100;
	getglobal(self:GetName() .. "Text"):SetText("MT/PT Scaling - " .. floor(self:GetValue()*100+0.5) .. "%");
	
	if (InCombatLockdown()) then
		return;
	end

	local newScaling = CT_RAMenu_Options["temp"]["MTScaling"];
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
	CT_RAMTGroup:SetScale(newScaling);
	CT_RAMTTGroup:SetScale(newScaling);
	CT_RAPTGroup:SetScale(newScaling);
	CT_RAPTTGroup:SetScale(newScaling);
	CT_RAMTGroupDrag:SetWidth(mtwidth*newScaling);
	CT_RAMTGroupDrag:SetHeight(height*newScaling/2);
	CT_RAPTGroupDrag:SetWidth(ptwidth*newScaling);
	CT_RAPTGroupDrag:SetHeight(height*newScaling/2);
end

function CT_RA_GetLocale()
	local locale = strsub(GetLocale(), 1, 2);
	if ( locale == "fr" or locale == "de" ) then
		return locale;
	else
		return "en";
	end
end

function CT_RAMenu_Misc_PlaySound(self)
	CT_RAMenu_Options["temp"]["PlayRSSound"] = self:GetChecked();
end

function CT_RAMenu_Misc_AggroNotifier(self)
	CT_RAMenu_Options["temp"]["AggroNotifier"] = self:GetChecked();
	if ( not self:GetChecked() ) then
		CT_RAMenuFrameMiscNotificationsAggroNotifierSoundCB:Disable();
		CT_RAMenuFrameMiscNotificationsAggroNotifierSound:SetTextColor(0.3, 0.3, 0.3);
	else
		CT_RAMenuFrameMiscNotificationsAggroNotifierSoundCB:Enable();
		CT_RAMenuFrameMiscNotificationsAggroNotifierSound:SetTextColor(1, 1, 1);
	end
end

function CT_RAMenu_Misc_AggroNotifierSound(self)
	CT_RAMenu_Options["temp"]["AggroNotifierSound"] = self:GetChecked();
end

function CT_RAMenu_Additional_ShowEmergency(self)
	CT_RAMenu_Options["temp"]["ShowEmergency"] = self:GetChecked();
	if ( not self:GetChecked() ) then
		CT_RAMenuFrameAdditionalEMPartyCB:Disable();
		CT_RAMenuFrameAdditionalEMRangeCB:Disable();
		CT_RAMenuFrameAdditionalEMRangeText:SetTextColor(0.3, 0.3, 0.3);
		CT_RAMenuFrameAdditionalEMPartyText:SetTextColor(0.3, 0.3, 0.3);
		CT_RAMenuFrameAdditionalEMOutsideRaidCB:Disable();
		CT_RAMenuFrameAdditionalEMOutsideRaidText:SetTextColor(0.3, 0.3, 0.3);
	else
		CT_RAMenuFrameAdditionalEMPartyCB:Enable();
		CT_RAMenuFrameAdditionalEMRangeCB:Enable();
		CT_RAMenuFrameAdditionalEMRangeText:SetTextColor(1, 1, 1);
		CT_RAMenuFrameAdditionalEMPartyText:SetTextColor(1, 1, 1);
		CT_RAMenuFrameAdditionalEMOutsideRaidCB:Enable();
		CT_RAMenuFrameAdditionalEMOutsideRaidText:SetTextColor(1, 1, 1);
	end
	CT_RA_Emergency_UpdateHealth();
end

function CT_RAMenu_Additional_ShowEmergencyParty(self)
	CT_RAMenu_Options["temp"]["ShowEmergencyParty"] = self:GetChecked();
	CT_RA_Emergency_UpdateHealth();
end

function CT_RAMenu_Additional_ShowEmergencyRange(self)
	CT_RAMenu_Options["temp"]["ShowEmergencyRange"] = self:GetChecked();
	CT_RA_Emergency_UpdateHealth();
end

function CT_RAMenu_Additional_ShowEmergencyOutsideRaid(self)
	CT_RAMenu_Options["temp"]["ShowEmergencyOutsideRaid"] = self:GetChecked();
	CT_RA_Emergency_UpdateHealth();
end

function CT_RAMenu_Misc_SendRARS(self)
	CT_RAMenu_Options["temp"]["SendRARS"] = self:GetChecked();
end

function CT_RAMenu_Misc_ShowAFK(self)
	CT_RAMenu_Options["temp"]["ShowAFK"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(1);
end

function CT_RAMenu_Misc_ShowPTT(self)
	CT_RAMenu_Options["temp"]["ShowPTT"] = self:GetChecked();
	CT_RA_UpdatePTs(true);
	CT_RA_UpdateRaidFrameOptions();
end

function CT_RAMenu_Misc_ShowMTTT(self)
	CT_RAMenu_Options["temp"]["ShowMTTT"] = self:GetChecked();
	if ( not self:GetChecked() ) then
		CT_RAMenuFrameMiscDisplayNoColorChangeCB:Disable();
		CT_RAMenuFrameMiscDisplayNoColorChange:SetTextColor(0.3, 0.3, 0.3);
	else
		CT_RAMenuFrameMiscDisplayNoColorChangeCB:Enable();
		CT_RAMenuFrameMiscDisplayNoColorChange:SetTextColor(1, 1, 1);
	end
	CT_RA_UpdateMTs(true);
	CT_RA_UpdateRaidFrameOptions();
end

function CT_RAMenu_Misc_NoColorChange(self)
	CT_RAMenu_Options["temp"]["HideColorChange"] = self:GetChecked();
end

function CT_RAMenu_Misc_ShowRaidIcon(self)
	CT_RAMenu_Options["temp"]["ShowRaidIcon"] = self:GetChecked();
	CT_RA_UpdateAllRaidTargetIcons();
end

function CT_RAMenu_Misc_ShowTooltip(self)
	CT_RAMenu_Options["temp"]["HideTooltip"] = not self:GetChecked();
end

function CT_RAMenu_Misc_DisableQuery(self)
	CT_RAMenu_Options["temp"]["DisableQuery"] = self:GetChecked();
end

function CT_RAMenu_Misc_ShowResMonitor(self)
	CT_RAMenu_Options["temp"]["ShowMonitor"] = self:GetChecked();
	if (CT_RAMenu_Options["temp"]["ShowMonitor"]) then
		CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeededCB:Enable();
		CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeeded:SetTextColor(1, 1, 1);
	else
		CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeededCB:Disable();
		CT_RAMenuFrameMiscDisplayHideResMonitorUntilNeeded:SetTextColor(0.3, 0.3, 0.3);
	end
	CT_RA_UpdateResFrame();
--	if ( self:GetChecked() and GetNumRaidMembers() > 0 ) then
--		CT_RA_ResFrame:Show();
--	else
--		CT_RA_ResFrame:Hide();
--	end
end

function CT_RAMenu_Misc_HideResMonitorUntilNeeded(self)
	CT_RAMenu_Options["temp"]["HideMonitorUntilNeeded"] = self:GetChecked();
	CT_RA_UpdateResFrame();
end

function CT_RAMenu_Misc_HideButton(self)
	CT_RAMenu_Options["temp"]["HideButton"] = self:GetChecked();
	if ( self:GetChecked() ) then
		CT_RASets_Button:Hide();
	else
		CT_RASets_Button:Show();
	end
end

function CT_RAMenuGeneral_SortAlpha(self)
	CT_RAMenu_Options["temp"]["SubSortByName"] = self:GetChecked();
	CT_RA_UpdateRaidGroup(3);
	CT_RA_UpdateRaidFrameOptions();
end

function CT_RAMenu_Misc_ColorLeader(self)
	if ( CT_RAMenu_Options["temp"]["leaderColor"] ) then
		CT_RAMenu_Options["temp"]["leaderColor"].enabled = self:GetChecked();
	else
		CT_RAMenu_Options["temp"]["leaderColor"] = {
			r = 1, g = 1, b = 0, enabled = true
		};
	end
end

function CT_RAMenu_Misc_ColorLeader_ShowColorPicker(frame)
	if ( not CT_RAMenu_Options["temp"]["leaderColor"] ) then
		CT_RAMenu_Options["temp"]["leaderColor"] = {
			r = 1, g = 1, b = 0, enabled = true
		};
	end
	frame.r = CT_RAMenu_Options["temp"]["leaderColor"].r;
	frame.g = CT_RAMenu_Options["temp"]["leaderColor"].g;
	frame.b = CT_RAMenu_Options["temp"]["leaderColor"].b;
	frame.swatchFunc = CT_RAMenu_Misc_ColorLeader_SetColor;
	frame.cancelFunc = CT_RAMenu_Misc_ColorLeader_CancelColor;
	UIDropDownMenuButton_OpenColorPicker(frame);
end

function CT_RAMenu_Misc_ColorLeader_SetColor()
	local r, g, b = ColorPickerFrame:GetColorRGB();
	CT_RAMenu_Options["temp"]["leaderColor"].r = r;
	CT_RAMenu_Options["temp"]["leaderColor"].g = g;
	CT_RAMenu_Options["temp"]["leaderColor"].b = b;
	CT_RAMenuFrameMiscDisplayColorLeaderColorSwatchNormalTexture:SetVertexColor(CT_RAMenu_Options["temp"]["leaderColor"].r, CT_RAMenu_Options["temp"]["leaderColor"].g, CT_RAMenu_Options["temp"]["leaderColor"].b);
end

function CT_RAMenu_Misc_ColorLeader_CancelColor()
	CT_RAMenu_Options["temp"]["leaderColor"].r = CT_RAMenuFrameMiscDisplayColorLeaderColorSwatch.r;
	CT_RAMenu_Options["temp"]["leaderColor"].g = CT_RAMenuFrameMiscDisplayColorLeaderColorSwatch.g;
	CT_RAMenu_Options["temp"]["leaderColor"].b = CT_RAMenuFrameMiscDisplayColorLeaderColorSwatch.b;
	CT_RAMenuFrameMiscDisplayColorLeaderColorSwatchNormalTexture:SetVertexColor(CT_RAMenu_Options["temp"]["leaderColor"].r, CT_RAMenu_Options["temp"]["leaderColor"].g, CT_RAMenu_Options["temp"]["leaderColor"].b);
end

function CT_RAMenu_Misc_NotifyGroupChange(self)
	CT_RAMenu_Options["temp"]["NotifyGroupChange"] = self:GetChecked();
	if ( not self:GetChecked() ) then
		CT_RAMenuFrameMiscNotificationsNotifyGroupChangeCBSound:Disable();
		CT_RAMenuFrameMiscNotificationsNotifyGroupChangeSound:SetTextColor(0.3, 0.3, 0.3);
	else
		CT_RAMenuFrameMiscNotificationsNotifyGroupChangeCBSound:Enable();
		CT_RAMenuFrameMiscNotificationsNotifyGroupChangeSound:SetTextColor(1, 1, 1);
	end
end

function CT_RAMenu_Misc_NotifyGroupChangeSound(self)
	CT_RAMenu_Options["temp"]["NotifyGroupChangeSound"] = self:GetChecked();
end

function CT_RA_UpdateResFrameTest(reset)
	-- Build test set of resurrectin data.
	-- (content varies depending on your target or lack of target)
	if (reset) then
		CT_RA_Ressers = {};
	else
		local pname = string.lower(UnitName("player"));
		local targetName;
		if (UnitExists("target")) then
			targetName = UnitName("target");
		end
		if (not targetName) then
			targetName = "";
		end
		local myCorpse = "mcorpse";
		CT_RA_Ressers[pname] = myCorpse;
		CT_RA_Ressers["erezzer"] = "ecorpse";
		CT_RA_Ressers["brezzer"] = "bcorpse";
		CT_RA_Ressers["drezzer"] = "dcorpse";
		CT_RA_Ressers["crezzer"] = "acorpse";
		CT_RA_Ressers["arezzer"] = "acorpse";
		if (targetName == "") then
			-- Pretend some other people are rezzing same corpse as me.
			CT_RA_Ressers["crezzer"] = myCorpse;
			CT_RA_Ressers["arezzer"] = myCorpse;
		else
			if (targetName == UnitName("player")) then
				-- Pretend that I'm the only one rezzing this corpse.
			else
				-- Pretend I'm not rezzing, and other people are rezzing my target.
				CT_RA_Ressers[pname] = nil;
				CT_RA_Ressers["crezzer"] = targetName;
				CT_RA_Ressers["arezzer"] = targetName;
			end
		end
	end
	CT_RA_UpdateResFrame();
end

function CT_RA_UpdateResFrame()
	if ((not CT_RAMenu_Options["temp"]["ShowMonitor"]) or GetNumRaidMembers() == 0) then
		CT_RA_ResFrame:Hide();
		return;
	end
	local text = "";
	local found;
	for key, val in pairs(CT_RA_Ressers) do
		found = 1;
		break;
	end
	if (found) then
		local colour1, colour2;
		local cname;
		local pname = string.lower(UnitName("player"));
		local targetName;
		if (UnitExists("target")) then
			targetName = UnitName("target");
		end
		if (not targetName) then
			targetName = "";
		end

		-- Create array we can sort, and look for name of corpse that the player is resurrecting.
		local temp = {};
		for key, val in pairs(CT_RA_Ressers) do
			tinsert(temp, key);
			if (pname == string.lower(key)) then
				cname = string.lower(val);  -- corpse name being resurrected by the player.
			end
		end

		-- Sort array by corpse name
		sort(temp, 	function (a, b)
					return string.lower(CT_RA_Ressers[a]) < string.lower(CT_RA_Ressers[b]);
				end
		);

		-- Build text string to show in res monitor.
		for i = 1, #temp do
			if ( strlen(text) > 0 ) then
				text = text .. "\n";
			end

			-- Colour of the player's name.
			if (pname == string.lower(temp[i])) then
				-- The person doing the rezzing is you.
				colour1 = "|c00FFFF00";
			else
				colour1 = "";
			end

			-- Colour of the corpse's name.
			if (cname and string.lower(CT_RA_Ressers[(temp[i])]) == cname) then
				-- You are rezzing this corpse, or someone else is rezzing the same corpse as you.
				colour2 = "|c00FFFF00";
			else
				-- Test if person you are targetting is being rezzed.
				if (string.lower(CT_RA_Ressers[(temp[i])]) == string.lower(targetName)) then
					-- Someone is rezzing the corpse you have targeted but that you are not rezzing.
					colour2 = "|c00FFA320";
				else
					-- You are not rezzing this corpse, and you don't have it targeted.
					colour2 = "";
				end
			end

			text = text .. colour1 .. temp[i] .. ":|r " .. colour2 .. CT_RA_Ressers[(temp[i])] .. "|r";  -- rezzer: corpse
		end
		CT_RA_ResFrame:Show();
	else
		if (CT_RAMenu_Options["temp"]["HideMonitorUntilNeeded"]) then
			CT_RA_ResFrame:Hide();
		else
			CT_RA_ResFrame:Show();
		end
	end
	CT_RA_ResFrameText:SetText(text);
	CT_RA_ResFrame:SetWidth(max(CT_RA_ResFrameText:GetWidth()+15, 175));
	CT_RA_ResFrame:SetHeight(max(CT_RA_ResFrameText:GetHeight()+25, 50));
end

function CT_RAMenuHelp_LoadText(self)
	local texts = {
		"|c00FFFFFFShow Group Names -|r Turns on/off the headers for each group.\n\n|c00FFFFFFLock Group Positions -|r Locks all CTRA windows in place.\n\n|c00FFFFFFHide Mana Bars -|r Hides each player's mana bar.\n\n|c00FFFFFFHide Health Bars -|r Hides each player's health bar.\n\n|c00FFFFFFHide Rage/Energy/Power Bars -|r Hides each player's rage, energy, or power bar.\n\n|c00FFFFFFHealth Type -|r Allows you to show each player's health as a percentage, actual value, missing health, only the percentage on Main Tank targets, or not at all. You can also customize the color the text is shown in.\n\n|c00FFFFFFWindow BG Color -|r Changes the color of CTRA raid frame backgrounds. Dragging the slider all the way to 100% makes them transparent.\n\n|c00FFFFFFAlert Message Color -|r Sets the color the /rs alert messages show in the middle of your screen.",
		"|c00FFFFFFHide border -|r Allows you to hide the border of each CTRA raid frame.\n\n|c00FFFFFFSort Type -|r Sort by either group or class. Sorting by Class displays each member in a class category.",
		"Allows you to be notified via chat when someone becomes debuffed with the types listed above, as well as allows you to be notified when someone loses a buff you are able to recast.";
		"Allows you to scale the CTRA group and MT windows.",
		CT_RAMENU_BUFFSDESCRIPT,
		CT_RAMENU_BUFFSTOOLTIP,
		CT_RAMENU_DEBUFFSTOOLTIP,
		CT_RAMENU_ADDITIONALEMTOOLTIP,
		"Allows you to change the name and details of the selected set. In any of the three bottom fields, you can use an asterix (|c00FFFFFF*|r) as a wildcard for zero or more characters. You can also use regular expressions, if you have the knowledge to use that.",
		"Allows you to regulate the classes this set will attempt to cure matching debuffs on."
	};
	self.text = texts[self:GetID()];
end

function CT_RAMenuHelp_SetTooltip(self)
	local uiX, uiY = UIParent:GetCenter();
	local thisX, thisY = self:GetCenter();

	local anchor = "";
	if ( thisY > uiY ) then
		anchor = "BOTTOM";
	else
		anchor = "TOP";
	end
	
	if ( thisX < uiX  ) then
		if ( anchor == "TOP" ) then
			anchor = "TOPLEFT";
		else
			anchor = "BOTTOMRIGHT";
		end
	else
		if ( anchor == "TOP" ) then
			anchor = "TOPRIGHT";
		else
			anchor = "BOTTOMLEFT";
		end
	end
	GameTooltip:SetOwner(self, "ANCHOR_" .. anchor);
end

function CT_RA_LoadSortOptions_WindowPositions()
	local tempOptions = CT_RAMenu_Options["temp"];
	if (tempOptions["SortWindowPositions"]) then
		local sortOptions = CT_RA_GetSortOptions();
		if ( sortOptions["WindowPositions"] ) then
			for k, v in pairs(sortOptions["WindowPositions"]) do
				if (strsub(k, 1, 14) == "CT_RAGroupDrag") then
					if (not tempOptions["WindowPositions"]) then
						tempOptions["WindowPositions"] = {};
					end
					tempOptions["WindowPositions"][k] = v;
				end
			end
		end
	end
end

function CT_RA_SaveSortOptions_WindowPositions()
	local tempOptions = CT_RAMenu_Options["temp"];
	if (tempOptions["SortWindowPositions"]) then
		local sortOptions = CT_RA_GetSortOptions();
		if ( tempOptions["WindowPositions"] ) then
			for k, v in pairs(tempOptions["WindowPositions"]) do
				if (strsub(k, 1, 14) == "CT_RAGroupDrag") then
					if (not sortOptions["WindowPositions"]) then
						sortOptions["WindowPositions"] = {};
					end
					sortOptions["WindowPositions"][k] = v;
				end
			end
		end
	end
end

function CT_RAMenu_SaveWindowPositions()
	local tempOptions = CT_RAMenu_Options["temp"];
	tempOptions["WindowPositions"] = { };
	local left, top, uitop;
	for i = 1, CT_RA_MaxGroups, 1 do
		local frame = getglobal("CT_RAGroupDrag" .. i);
		left, top, uitop = frame:GetLeft(), frame:GetTop(), UIParent:GetTop();
		if ( left and top and uitop ) then
			tempOptions["WindowPositions"][frame:GetName()] = { left, top-uitop };
		end
	end
	CT_RA_SaveSortOptions_WindowPositions();
	left, top, uitop = CT_RAMTGroupDrag:GetLeft(), CT_RAMTGroupDrag:GetTop(), UIParent:GetTop();
	if ( left and top and uitop ) then
		tempOptions["WindowPositions"]["CT_RAMTGroupDrag"] = { left, top-uitop };
	end
	left, top, uitop = CT_RAPTGroupDrag:GetLeft(), CT_RAPTGroupDrag:GetTop(), UIParent:GetTop();
	if ( left and top and uitop ) then
		tempOptions["WindowPositions"]["CT_RAPTGroupDrag"] = { left, top-uitop };
	end
	left, top, uitop = CT_RA_EmergencyFrameDrag:GetLeft(), CT_RA_EmergencyFrameDrag:GetTop(), UIParent:GetTop();
	if ( left and top and uitop ) then
		tempOptions["WindowPositions"]["CT_RA_EmergencyFrameDrag"] = { left, top-uitop };
	end
end

function CT_RAMenu_UpdateWindowPositions()
	local tempOptions = CT_RAMenu_Options["temp"];
	CT_RA_LoadSortOptions_WindowPositions();
	if (InCombatLockdown()) then
		return;
	end
	if ( tempOptions["WindowPositions"] ) then
		for k, v in pairs(tempOptions["WindowPositions"]) do
			getglobal(k):ClearAllPoints();
			getglobal(k):SetPoint("TOPLEFT" , "UIParent", "TOPLEFT", v[1], v[2]);
		end
	end
end

function CT_RAMenu_CopyTable(source)
	if ( type(source) == "table" ) then
		local dest = { };
		for k, v in pairs(source) do
			dest[k] = CT_RAMenu_CopyTable(v);
		end
		return dest;
	else
		return source;
	end
end

function CT_RAMenu_CopySet(copyFrom, copyTo)
	CT_RAMenu_Options[copyTo] = nil;
	CT_RAMenu_Options[copyTo] = CT_RAMenu_CopyTable(CT_RAMenu_Options[copyFrom]);
	CT_RAMenu_UpdateOptionSets();
end

function CT_RAMenu_LoadSet_GetValues(name)
	-- Load the values from a set.
	-- This function is separate from CT_RAMenu_LoadSet() so that
	-- CT_RAMenu_LoadSet_GetValues() can be hooked by a user addon.
	-- This allows the user addon to examine the "temp" options table
	-- for things that might need to be assigned a value (the user might
	-- be loading an old options set and be using a new addon).
	CT_RAMenu_CurrSet = name;
	CT_RAMenu_Options["temp"] = CT_RAMenu_CopyTable(CT_RAMenu_Options[CT_RAMenu_CurrSet]);
end

function CT_RAMenu_LoadSet(name)
	-- Load a set of options.
	CT_RAMenu_LoadSet_GetValues(name);
	CT_RAMenu_UpdateWindowPositions();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateMTs(true);
	CT_RA_UpdatePTs(true);
	CT_RA_UpdateRaidFrameOptions();
	CT_RA_UpdateVisibility();
	CT_RAMenu_UpdateMenu();
	CT_RAOptions_UpdateGroups();
	CT_RAMenu_UpdateOptionSets();
end

function CT_RAMenu_DeleteSet(name)
	if ( name ~= "Default" ) then
		CT_RAMenu_Options[name] = nil;
		if ( CT_RAMenu_CurrSet == name ) then
			CT_RAMenu_LoadSet("Default");
		else
			CT_RAMenu_UpdateOptionSets();
		end
	end
end

function CT_RAMenu_CompareTable(t1, t2)
	for key, val in pairs(t1) do
		if (key ~= "unchanged") then
			if (type(val) == "table") then
				if (type(t2[key]) == "table") then
					if (not CT_RAMenu_CompareTable(val, t2[key])) then
						return false;
					end
				else
					return false;
				end
			else
				if (t2[key] == nil or val ~= t2[key]) then
					return false;
				end
			end
		end
	end
	for key, val in pairs(t2) do
		if (key ~= "unchanged") then
			if (type(val) == "table") then
				if (type(t1[key]) == "table") then
					if (not CT_RAMenu_CompareTable(val, t1[key])) then
						return false;
					end
				else
					return false;
				end
			else
				if (t1[key] == nil or val ~= t1[key]) then
					return false;
				end
			end
		end
	end
	return true;
end

function CT_RAMenu_ExistsSet(set)
	for k, v in pairs(CT_RAMenu_Options) do
		if ( strlower(k) == strlower(set) ) then
			return true;
		end
	end
	return nil;
end

function CT_RAMenu_UpdateOptionSets()
	if (not CT_RAMenuFrameOptionSets:IsVisible()) then
		return;
	end
	local num = 0;
	local postfix = "";
	if ( not CT_RAMenu_CompareTable(CT_RAMenu_Options["temp"], CT_RAMenu_Options[CT_RAMenu_CurrSet]) ) then
		postfix = "*";
		CT_RAMenuFrameOptionSetsUndo:Enable();
		CT_RAMenuFrameOptionSetsSave:Enable();
	else
		CT_RAMenuFrameOptionSetsUndo:Disable();
		CT_RAMenuFrameOptionSetsSave:Disable();
	end
	CT_RAMenuFrameOptionSetsCurrentSet:SetText("Current Set: |c00FFFF00" .. CT_RAMenu_CurrSet .. "|r" .. postfix);
	local sets = {};
	for k, v in pairs(CT_RAMenu_Options) do
		if ( k ~= "temp" and num < 8 ) then
			num = num + 1;
			tinsert(sets, k);
		end
	end
	sort(sets, function (a, b)
			if (string.lower(a) < string.lower(b)) then
				return true;
			else
				return false;
			end
	end);
	num = 0;
	for i, k in ipairs(sets) do
		if ( k ~= "temp" and num < 8 ) then
			num = num + 1;
			local obj = getglobal("CT_RAMenuFrameOptionSetsSet" .. num);
			getglobal(obj:GetName() .. "Name"):SetText(k);
			obj.setName = k;
			-- Make sure last line is hidden
			if ( num == 8 ) then
				getglobal(obj:GetName() .. "Line"):Hide();
			else
				getglobal(obj:GetName() .. "Line"):Show();
			end
			
			-- Disallow loading the current set
			if ( k == CT_RAMenu_CurrSet ) then
				getglobal(obj:GetName() .. "Load"):Disable();
				getglobal(obj:GetName() .. "Name"):SetTextColor(1, 1, 1);
			else
				getglobal(obj:GetName() .. "Load"):Enable();
				getglobal(obj:GetName() .. "Name"):SetTextColor(0.66, 0.66, 0.66);
			end
			
			-- Disallow deleting the default set
			if ( k == "Default" ) then
				getglobal(obj:GetName() .. "Delete"):Disable();
			else
				getglobal(obj:GetName() .. "Delete"):Enable();
			end
			obj:Show();
		end
	end
	for i = num+1, 8, 1 do
		getglobal("CT_RAMenuFrameOptionSetsSet" .. i):Hide();
	end
	if (num >= 8) then
		CT_RAMenuFrameOptionSetsSaveAs:Disable();

		for i = 1, 8 do
			local obj = getglobal("CT_RAMenuFrameOptionSetsSet" .. i .. "Copy");
			obj:Disable();
		end
	else
		CT_RAMenuFrameOptionSetsSaveAs:Enable();

		for i = 1, 8 do
			local obj = getglobal("CT_RAMenuFrameOptionSetsSet" .. i .. "Copy");
			obj:Enable();
		end
	end
end
