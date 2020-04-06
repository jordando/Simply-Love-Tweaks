local args = ...
local player = args.player

local af = Def.ActorFrame{
	Name="Pane3",
	InitCommand=function(self) self:visible(false) end
}
local position = player == "PlayerNumber_P1" and (_screen.cx - 115 + WideScale(115,0)) or -305
local doublePosition = player == "PlayerNumber_P1" and 0 or -305
af[#af+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/PerPlayer/Pane2"), player)..{InitCommand=function(self) self:visible(true):x(doublePosition) end}

if GAMESTATE:GetCurrentStyle():GetStyleType() ~= "StyleType_OnePlayerTwoSides" then
	af[#af+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/PerPlayer/Pane5"), player)..{InitCommand=function(self) self:visible(true):x(position) end}
end

return af