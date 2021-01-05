local player = ...
local pn = ToEnumShortString(player)

-- -----------------------------------------------------------------------
-- positioning and sizing of side pane
local notefield_width = GetNotefieldWidth()
local sidepane_width  = _screen.w/2 + 30
local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)

-- -----------------------------------------------------------------------
-- if the conditions aren't right, don't bother

local stylename = GAMESTATE:GetCurrentStyle():GetName()

if (SL[pn].ActiveModifiers.DataVisualizations ~= "Battle Statistics")
or (SL.Global.GameMode == "Casual")
or (GetNotefieldWidth() > _screen.w/2)
or (NoteFieldIsCentered and not IsUsingWideScreen())
or (not IsUltraWide and stylename ~= "single")
or (    IsUltraWide and not (stylename == "single" or stylename == "versus"))
then
	return
end

if not IsUltraWide then
	if NoteFieldIsCentered and IsUsingWideScreen() then
		sidepane_width = (_screen.w - GetNotefieldWidth()) / 2
	end

-- ultrawide or wider
else
	if #GAMESTATE:GetHumanPlayers() > 1 then
		sidepane_width = _screen.w/5
	end
end

local af = Def.ActorFrame{
    Name="StepStatsPane"..pn,
    InitCommand=function(self)
        self:xy(SCREEN_CENTER_X,250)
        if NoteFieldIsCentered and IsUsingWideScreen() then
            self:addx(150)
        elseif player==PLAYER_2 then
            self:x(SCREEN_CENTER_X+200)
        end
    end,
}

af[#af+1] = LoadActor("./CombatWindow.lua", player)..{
    InitCommand=function(self)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:xy(player == PLAYER_1 and -530 or 25,45)
        elseif player==PLAYER_2 then
            self:x(-555)
        end
    end
}

local normalStuff = Def.ActorFrame{
    InitCommand=function(self) self:x(player==PLAYER_1 and 0 or -555) end
}

--background for banner and judgments
normalStuff[#normalStuff+1] = Def.Sprite{
    Texture=THEME:GetPathG("FF","CardEdge.png"),
    InitCommand=function(self)
        self:zoomto(148,217):xy(63+175,-26+70):align(0,1)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:zoomto(155,170):addx(-255):addy(0)
        end
    end
}
normalStuff[#normalStuff+1] = Def.Quad{
    InitCommand=function(self)
        self:zoomto(133,200):xy(71+175,-35+70):align(0,1)
        self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:zoomto(140,156):addx(-255):addy(2)
        end
    end
}
--background for banner and holds/mines/rolls (only when centered)
normalStuff[#normalStuff+1] = Def.Sprite{
    Texture=THEME:GetPathG("FF","CardEdge.png"),
    InitCommand=function(self)
        self:zoomto(150,170):xy(130,44):align(0,1):visible(false)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:visible(true)
        end
    end
}
normalStuff[#normalStuff+1] = Def.Quad{
    InitCommand=function(self)
        self:zoomto(134,156):xy(138,37):align(0,1):visible(false)
        self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:visible(true)
        end
    end
}
--background for remaining time
normalStuff[#normalStuff+1] = Def.Sprite{
    Texture=THEME:GetPathG("FF","CardEdge.png"),
    InitCommand=function(self) self:zoomto(148,45):xy(63+175,12+70):align(0,1)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:addx(-255):addy(3):zoomto(155,45)
        end
    end
}
normalStuff[#normalStuff+1] = Def.Quad{
    InitCommand=function(self)
        self:zoomto(133,40):xy(71+175,9.5+70):align(0,1)
        self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:addx(-255):addy(3):zoomto(140,40)
        end
    end
}
--background for score (only visible when notefield is centered)
normalStuff[#normalStuff+1] = Def.Sprite{
    Texture=THEME:GetPathG("FF","CardEdge.png"),
    InitCommand=function(self) self:zoomto(149,45):xy(131,85):align(0,1):visible(false)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:visible(true)
        end
    end
}
normalStuff[#normalStuff+1] = Def.Quad{
    InitCommand=function(self)
        self:zoomto(135,40):xy(138,83):align(0,1)
        self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black):visible(false)
        if (NoteFieldIsCentered and IsUsingWideScreen()) then
            self:visible(true)
        end
    end
}
local otherStuff = Def.ActorFrame{
    InitCommand=function(self)
        self:xy(175,70)
        local zoomfactor = {
            ultrawide    = 0.725,
            sixteen_ten  = 0.825,
            sixteen_nine = 0.9
        }
        if not IsUltraWide then
            if (NoteFieldIsCentered and IsUsingWideScreen()) then
                self:addx(3):addy(5)
                local zoom = scale(GetScreenAspectRatio(), 16/10, 16/9, zoomfactor.sixteen_ten, zoomfactor.sixteen_nine)
                self:zoom( zoom )
            end

        else
            if #GAMESTATE:GetHumanPlayers() > 1 then
                self:zoom(zoomfactor.ultrawide):addy(-55)
            end
        end
    end,
}

-- banner, judgment labels, and judgment numbers will be collectively shrunk
-- if Center1Player is enabled to accommodate the smaller space
otherStuff[#otherStuff+1] = Def.ActorFrame{
	Name="BannerAndData",
    --background for GroupAndArtist
    Def.Sprite{
        Texture=THEME:GetPathG("FF","CardEdge.png"),
        InitCommand=function(self) self:zoomto(452,56):xy(-228,66):align(0,1)
            if (NoteFieldIsCentered and IsUsingWideScreen()) then
                self:zoomto(343,57):addy(1):addx(5)
            end
        end
    },
    Def.Quad{
        InitCommand=function(self)
            self:zoomto(412,50):xy(-208,64):align(0,1)
            self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
            if (NoteFieldIsCentered and IsUsingWideScreen()) then
                self:zoomto(313,50)
            end
        end
    },
    --divider for time/group and artist
    Def.Quad{
        InitCommand=function(self)
            self:zoomto(2,50):xy(-90,65):align(0,1)
            if (NoteFieldIsCentered and IsUsingWideScreen()) then
                self:visible(false)
            elseif player == PLAYER_2 then
                self:x(90)
            end
            if not SL[pn].ActiveModifiers.NPSGraphAtTop then self:visible(false) end
        end,
    },

	LoadActor("./TapNoteJudgments.lua", player),
	LoadActor("./Time.lua", player),
	LoadActor("./GroupAndArtist.lua", player),
}
normalStuff[#normalStuff+1] = LoadActor("./Banner.lua", player)
if (NoteFieldIsCentered and IsUsingWideScreen()) then otherStuff[#otherStuff+1] = LoadActor("./HoldsMinesRolls.lua", player) end
normalStuff[#normalStuff+1] = LoadActor("./DensityGraph.lua", {player, sidepane_width})
normalStuff[#normalStuff+1] = otherStuff

af[#af+1] = normalStuff

return af

