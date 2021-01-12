--Code based on Digital Dance by Aoreo
if not ThemePrefs.Get("ShowCD") then return end

local t = Def.ActorFrame{}

t[#t+1] = Def.ActorFrame {
    OnCommand= function(self)
        self:draworder(101)
        :x(_screen.cx)
        :y(SCREEN_CENTER_Y-150)
        :playcommand("SetCD")
    end,
    OffCommand= function(self)
        self:bouncebegin(0.15)
    end,
    CurrentSongChangedMessageCommand=function(self,params) if params.song then self:playcommand("SetCD")end end,
    SwitchFocusToGroupsMessageCommand=function(self) self:GetChild("CdTitle"):visible(false) end,
    SetCDCommand=function(self)
        local cdtitle = self:GetChild("CdTitle")
        -- TODO: can courses have CD titles? There's no HasCDTitle() for courses
        -- SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
        if SL.Global.GroupType == "Courses" then cdtitle:visible(false) return end
        SongOrCourse = GAMESTATE:GetCurrentSong()
        if SongOrCourse and SongOrCourse:HasCDTitle() then
            cdtitle:visible(true)
            cdtitle:Load( GAMESTATE:GetCurrentSong():GetCDTitlePath() )
            local dim1, dim2=math.max(cdtitle:GetWidth(), cdtitle:GetHeight()), math.min(cdtitle:GetWidth(), cdtitle:GetHeight())
            local ratio=math.max(dim1/dim2, 2.5)
        
            local toScale = cdtitle:GetWidth() > cdtitle:GetHeight() and cdtitle:GetWidth() or cdtitle:GetHeight()
            self:zoom(22/toScale * ratio)
            self:finishtweening():addrotationy(0):linear(.5):addrotationy(360):bounce()
        else
            cdtitle:visible(false)
        end
    end,
    Def.Sprite{
        Name="CdTitle",
    },
}

return t