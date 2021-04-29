local inworld;
function CT_PlayerFrameOnEvent(self, event, arg1, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		inworld = 1;
		if (not InCombatLockdown()) then
			CT_UnitFrames_ResetDragLink("CT_PlayerFrame_Drag");
		end
		if (TitanMovableFrame_MoveFrames) then
			hooksecurefunc("TitanMovableFrame_MoveFrames", CT_PlayerFrame_TitanMovableFrame_MoveFrames);
		end
	elseif (event == "PLAYER_REGEN_DISABLED") then
		CT_UnitFrames_ResetDragLink("CT_PlayerFrame_Drag");
	elseif (event == "PLAYER_REGEN_ENABLED") then
		CT_UnitFrames_ResetDragLink("CT_PlayerFrame_Drag");
	end
end

local pfPoint, pfRel;
local pfUpdate = 0;
function CT_PlayerFrameOnUpdate(self, elapsed)
	if (not inworld) then
		return;
	end
	pfUpdate = pfUpdate + elapsed;
	if (pfUpdate > 0.5) then
		if (MainMenuBar.busy or MainMenuBar.animComplete == false) then
			return;
		end
		pfUpdate = 0;
		-- If our drag link to the player frame gets broken, then fix it.
		pfPoint, pfRel = PlayerFrame:GetPoint(1);
		if (pfRel ~= CT_PlayerFrame_Drag) then
			if (not InCombatLockdown()) then
				CT_UnitFrames_ResetDragLink("CT_PlayerFrame_Drag");
			end
		end
	end
end

function CT_PlayerFrame_TitanMovableFrame_MoveFrames()
	-- TitanPanel moves the player frame when it loads which breaks our drag link.
	CT_UnitFrames_ResetDragLink("CT_PlayerFrame_Drag");
end

function CT_PlayerFrame_ShowBarText()
	UnitFrameHealthBar_Update(PlayerFrameHealthBar, "player");
	UnitFrameManaBar_Update(PlayerFrameManaBar, "player");
end

function CT_PlayerFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == PlayerFrameHealthBar) then
		if (CT_UnitFramesOptions) then
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[1][1])
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[1][2], CT_PlayerHealthRight)
		end

	elseif (bar == PlayerFrameManaBar) then
		if (CT_UnitFramesOptions) then
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[1][3])
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[1][4], CT_PlayerManaRight)
		end
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_PlayerFrame_TextStatusBar_UpdateTextString);

function CT_PlayerFrame_ShowTextStatusBarText(bar)
	if (bar == PlayerFrameHealthBar or bar == PlayerFrameManaBar) then
		CT_PlayerFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("ShowTextStatusBarText", CT_PlayerFrame_ShowTextStatusBarText);

function CT_PlayerFrame_HideTextStatusBarText(bar)
	if (bar == PlayerFrameHealthBar or bar == PlayerFrameManaBar) then
		CT_PlayerFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("HideTextStatusBarText", CT_PlayerFrame_HideTextStatusBarText);

function CT_PetFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == PetFrameHealthBar) then
		if (CT_UnitFramesOptions) then
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
		end
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_PetFrame_TextStatusBar_UpdateTextString);

-- This re-anchors the player frame to the drag frame after Blizzard does its animate out
-- when entering/exiting a vehicle.
function CT_PlayerFrame_PlayerFrame_UpdateArt()
	if (not InCombatLockdown()) then
		CT_UnitFrames_ResetDragLink("CT_PlayerFrame_Drag");
	end
end
hooksecurefunc("PlayerFrame_UpdateArt", CT_PlayerFrame_PlayerFrame_UpdateArt);

-- This re-anchors the player frame to the drag frame after Blizzard does its animate out
-- when entering/exiting a vehicle.
function CT_PlayerFrame_PlayerFrame_SequenceFinished()
	if (not InCombatLockdown()) then
		CT_UnitFrames_ResetDragLink("CT_PlayerFrame_Drag");
	end
end
hooksecurefunc("PlayerFrame_SequenceFinished", CT_PlayerFrame_PlayerFrame_SequenceFinished);

