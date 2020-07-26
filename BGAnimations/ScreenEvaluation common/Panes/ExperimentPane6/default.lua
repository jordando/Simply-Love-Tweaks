--This pane is only for doubles

local args = ...
local player = args.player

local pane = Def.ActorFrame{
	Name="Pane6_SideP1",
	InitCommand=function(self)
		self:visible(false)
	end
}
local position = player == "PlayerNumber_P1" and (_screen.cx-WideScale(270,378)) or -_screen.cx + WideScale(60,167)

pane[#pane+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/Panes/Pane5"), {player, PLAYER_1})..{
	InitCommand=function(self) self:visible(true):x(position) end
	}

return pane