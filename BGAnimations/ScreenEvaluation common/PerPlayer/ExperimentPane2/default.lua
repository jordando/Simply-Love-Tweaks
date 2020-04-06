local args = ...
local player = args.player

local af = Def.ActorFrame{
	Name="Pane2",
	InitCommand=function(self) self:visible(false) end
}

af[#af+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/PerPlayer/Pane1"), player)
local position = player == "PlayerNumber_P1" and (_screen.cx - 155 + WideScale(115,0)) or -330
af[#af+1] = LoadActor("./ExperimentPercents.lua", player)..{InitCommand=function(self) self:x(position) end}
		

return af