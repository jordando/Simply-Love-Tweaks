local args = ...
local player = args.player

local af = Def.ActorFrame{
	Name="Pane3_SideP1",
	InitCommand=function(self) self:visible(false) end
}
local position = player == "PlayerNumber_P1" and (_screen.cx - 115 + WideScale(115,0)) or -305
local doublePosition = player == "PlayerNumber_P1" and 0 or -305
af[#af+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/Panes/Pane2"), {player, PLAYER_1})..{InitCommand=function(self) self:visible(true):x(doublePosition) end}

if GAMESTATE:GetCurrentStyle():GetStyleType() ~= "StyleType_OnePlayerTwoSides" then
	if PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
		af[#af+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/Panes/Pane5"), {player, PLAYER_1})..{InitCommand=function(self) self:visible(true):x(position) end}
	end
end

return af