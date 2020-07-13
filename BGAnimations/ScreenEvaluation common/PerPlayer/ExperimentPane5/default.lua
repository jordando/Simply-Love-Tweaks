local args = ...
local player = args.player

local pane = Def.ActorFrame{
	Name="Pane5",
	InitCommand=function(self)
		self:visible(false)
	end
}
local position = player == "PlayerNumber_P1" and (_screen.cx + 3 + WideScale(-153,-260)) or -_screen.cx + WideScale(-130,-23)
pane[#pane+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/PerPlayer/Pane4"), player)..{InitCommand=function(self) self:visible(true) end}
pane[#pane+1] = LoadActor("QR.lua", args)..{InitCommand=function(self) self:visible(true):x(position) end}

return pane