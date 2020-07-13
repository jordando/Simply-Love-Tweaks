--This pane is only for doubles

local args = ...
local player = args.player

local pane = Def.ActorFrame{
	Name="Pane6",
	InitCommand=function(self)
		self:visible(false)
	end
}
local position = player == "PlayerNumber_P1" and (_screen.cx-WideScale(270,378)) or -_screen.cx + WideScale(60,167)

pane[#pane+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/PerPlayer/Pane5"), player)..{
	InitCommand=function(self) self:visible(true):x(position) end
	}

return pane