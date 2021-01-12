local player = ...
local character = SL.Global.Character

local t = Def.ActorFrame{
    InitCommand=function(self) self:y(_screen.cy-100)
        if player == PLAYER_2 then
            self:x(_screen.cx - 155)
        elseif player == PLAYER_1 then
            self:x(_screen.cx + 270)
        end
    end
}

t[#t+1] = Def.Sprite{
    Texture=THEME:GetPathG("FF","CardEdge.png"),
    InitCommand=function(self) self:xy(-127,6):horizalign(left):zoomto(165,75) end
}

t[#t+1] = Def.Sprite{
    Texture=character.load,
	InitCommand=function(self)
        self:xy(character.winIntroXY[1],character.winIntroXY[2])
	end,
    OnCommand=function(self)
        if not STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetFailed() then
            self:SetStateProperties(character.winIntro):sleep(self:GetAnimationLengthSeconds()):queuecommand("FinalWin")
        else
            self:SetStateProperties(character.dead):xy(character.deadXY[1],character.deadXY[2])
        end
    end,
    FinalWinCommand=function(self)
        self:SetStateProperties(character.win):xy(character.winXY[1],character.winXY[2])
    end,
}

return t