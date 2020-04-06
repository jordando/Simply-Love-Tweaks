local args = ...
local player = args.player

local af = Def.ActorFrame{
	Name="Pane1",
}	

af[#af+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/PerPlayer/Pane1"), player)
local position = player == "PlayerNumber_P1" and (_screen.cx - 155 + WideScale(105,0)) or -330
af[#af+1] = LoadActor("./ExperimentJudgmentNumbers.lua", args)..{InitCommand=function(self) self:x(position) end}

return af