-- Pane2 displays per-columnm judgment counts.
-- In "dance" the columns are left, down, up, right.
-- In "pump" the columns are downleft, upleft, center, upright, downright
-- etc.

local args = ...
local player = args.player

local af = Def.ActorFrame{
	--Name="Pane3_SideP1",
	InitCommand=function(self) self:visible(false) end,
	-- ExpandForDoubleCommand() does not do anything here, but we check for its presence in
	-- this ActorFrame in ./InputHandler to determine which panes to expand the background for
	ExpandForDoubleCommand=function() end
}

local position = player == "PlayerNumber_P1" and (_screen.cx - 115 + WideScale(115,0)) or -305
af[#af+1] = LoadActor("./Percentage.lua", player)..{InitCommand=function(self) self:visible(true) end}
af[#af+1] = LoadActor("./JudgmentLabels.lua", player)..{InitCommand=function(self) self:visible(true) end}
af[#af+1] = LoadActor("./Arrows.lua", player)..{InitCommand=function(self) self:visible(true) end}

if GAMESTATE:GetCurrentStyle():GetStyleType() ~= "StyleType_OnePlayerTwoSides" then
	if PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
		af[#af+1] = LoadActor(THEME:GetPathB("ScreenEvaluation", "common/Panes/Pane5"), {player, PLAYER_1})..{InitCommand=function(self) self:visible(true):x(position) end}
	end
end

return af