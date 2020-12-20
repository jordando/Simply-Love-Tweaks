local player = ...

if SL[ToEnumShortString(player)].ActiveModifiers.HideTestInput then return end
if #GAMESTATE:GetHumanPlayers() > 1 then return end
local pn = ToEnumShortString(player)
local ar = GetScreenAspectRatio()
local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)

-- -----------------------------------------------------------------------
-- positioning and sizing of side pane

local header_height   = 80
local notefield_width = GetNotefieldWidth()
local sidepane_width  = _screen.w/2
local sidepane_pos_x  = _screen.w * (player==PLAYER_1 and 0.75 or 0.25)

if not IsUltraWide then
	if NoteFieldIsCentered and IsUsingWideScreen() then
		sidepane_width = (_screen.w - GetNotefieldWidth()) / 2

		if player==PLAYER_1 then
			sidepane_pos_x = _screen.cx + notefield_width + (sidepane_width-notefield_width)/2
		else
			sidepane_pos_x = _screen.cx - notefield_width - (sidepane_width-notefield_width)/2
		end
	end

-- ultrawide or wider
else
	if #GAMESTATE:GetHumanPlayers() > 1 then
		sidepane_width = _screen.w/5
		if player==PLAYER_1 then
			sidepane_pos_x = sidepane_width/2
		else
			sidepane_pos_x = _screen.w - (sidepane_width/2)
		end
	end
end

local position = {}
--create a metatable for position. if we have a data visualization we don't need to move for
--return base values
local mt = {
    __index = function(self)
        return {zoom = 1, x = 0, y = 0} end
}
setmetatable(position,mt)

position["Step Statistics"] = {
    zoom = .5,
    x = player == PLAYER_1 and -40 or -95,
    y = -70,
}
position["Alt. Step Statistics"] = {
    zoom = .5,
    x = player == PLAYER_1 and 95 or -95,
    y = 20,
}
position["Target Score Graph"] = {
    zoom = .5,
    x = player == PLAYER_1 and -200 or 200,
    y = -150
}

if NoteFieldIsCentered and IsUsingWideScreen() then
    position["Target Score Graph"].x = 50
    position["Step Statistics"].x = -600
    position["Step Statistics"].zoom = .75
    position["Alt. Step Statistics"].x = -600
    position["Alt. Step Statistics"].y = -70
    position["Alt. Step Statistics"].zoom = .75
end

local adjust = position[SL[pn].ActiveModifiers.DataVisualizations]
local af = Def.ActorFrame{}

af.Name="StepStatsPane"..pn
af.InitCommand=function(self)
	self:x(sidepane_pos_x + adjust.x):y(_screen.cy + header_height + adjust.y)
end

af[#af+1] = LoadActor(THEME:GetPathB("", "_modules/TestInput Pad/default.lua"), {Player=player, ShowMenuButtons=false, ShowPlayerLabel=false})..{
    InitCommand=function(self)
        local styletype = GAMESTATE:GetCurrentStyle():GetStyleType()
        if styletype ~= "StyleType_OnePlayerTwoSides" and styletype ~= "StyleType_TwoPlayersSharedSides" then
            self:visible(GAMESTATE:IsSideJoined(player))
        end
        self:zoom(adjust.zoom)
    end,
}

return af