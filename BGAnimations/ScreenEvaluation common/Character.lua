local player = ...
LoadActor(THEME:GetPathB("", "_modules/Characters.lua"))
local character = GetCharacter("Quina")

local t = Def.ActorFrame{
    InitCommand=function(self) self:y(_screen.cy-134)
        if player == PLAYER_2 then
            self:x(_screen.cx - 155)
        elseif player == PLAYER_1 then
            self:x(_screen.cx + 155)
        end
    end
}

t[#t+1] = Def.Sprite{
    Texture=THEME:GetPathG("FF","CardEdge.png"),
    InitCommand=function(self) self:xy(-12,40):horizalign(left):zoomto(165,75) end
}

t[#t+1] = Def.Sprite{
    Texture=character.load,
	InitCommand=function(self)
        self:xy(115,20)
	end,
    OnCommand=function(self)
        if not STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetFailed() then
            self:SetStateProperties(character.win)
        else
            self:SetStateProperties(character.dead):addy(character.deadXY[2])
        end
    end
}

return t