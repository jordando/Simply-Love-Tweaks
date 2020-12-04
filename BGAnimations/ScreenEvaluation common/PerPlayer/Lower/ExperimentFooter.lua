local player = ...
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local font_zoom = 0.7
local width = THEME:GetMetric("GraphDisplay", "BodyWidth")

local rate = SL.Global.ActiveModifiers.MusicRate

-- no course mode in Experiment so this shouldn't be an issue but
-- check just in case things change in the future
if GAMESTATE:IsCourseMode() then return end

-- -----------------------------------------------------------------------
-- prefer the engine's SecondsToHMMSS()
-- but define it ourselves if it isn't provided by this version of SM5
local hours, mins, secs
local hmmss = "%d:%02d:%02d"

local SecondsToHMMSS = SecondsToHMMSS or function(s)
	-- native floor division sounds nice but isn't available in Lua 5.1
	hours = math.floor(s/3600)
	mins  = math.floor((s % 3600) / 60)
	secs  = s - (hours * 3600) - (mins * 60)
	return hmmss:format(hours, mins, secs)
end

-- -----------------------------------------------------------------------
-- reference to the function we'll use to format long-form seconds (like 208.64382946)
-- to something presentable (like 3:28)
local fmt = nil

-- how long this song or course is, in seconds
-- we'll use this to choose a formatting function
local totalseconds = 0
local altTotalSeconds = 0

local song = GAMESTATE:GetCurrentSong()
if song then
    --TODO not sure if i should be using GetLastSecond or MusicLengthSeconds here
    totalseconds = song:MusicLengthSeconds()
    altTotalSeconds = song:GetLastSecond()
end

-- totalseconds is initilialzed in the engine as -1
-- https://github.com/stepmania/stepmania/blob/6a645b4710/src/Song.cpp#L80
-- and might not have ever been set to anything meaningful in edge cases
-- e.g. ogg file is 5 seconds, ssc file has 1 tapnote occuring at beat 0
if totalseconds < 0 then totalseconds = 0 end

-- factor in MusicRate
totalseconds = totalseconds / rate
altTotalSeconds = altTotalSeconds / rate

-- choose the appropriate time-to-string formatting function

-- shorter than 10 minutes (M:SS)
if totalseconds < 600 then
	fmt = SecondsToMSS

-- at least 10 minutes, shorter than 1 hour (MM:SS)
elseif totalseconds >= 360 and totalseconds < 3600 then
	fmt = SecondsToMMSS

-- somewhere between 1 and 10 hours (H:MM:SS)
elseif totalseconds >= 3600 and totalseconds < 36000 then
	fmt = SecondsToHMMSS

-- 10 hours or longer (HH:MM:SS)
else
	fmt = SecondsToHHMMSS
end

local aliveSeconds = pss:GetAliveSeconds() / rate

return Def.ActorFrame{
	OnCommand=function(self) self:y(_screen.cy+200.5) end,

	LoadFont("Common Normal")..{
        InitCommand=function(self)
            self:zoom(font_zoom):xy(width/1.4,-5):align(1,0):vertspacing(-6):_wrapwidthpixels((width-10) / font_zoom)
            if round(aliveSeconds,0) >= round(totalseconds,0) then
                self:settext(fmt(totalseconds)):diffuse(Color.White)
            elseif round(aliveSeconds,0) >= round(altTotalSeconds,0) then
                self:settext(fmt(altTotalSeconds)):diffuse(Color.White)
            else
                self:settext(fmt(aliveSeconds).." / "..fmt(totalseconds)):diffuse(Color.Red)
            end
        end

    },

    LoadFont("Common Normal")..{
        InitCommand=function(self)
            self:zoom(font_zoom):xy(width/6,-5):align(0,0):vertspacing(-6):_wrapwidthpixels((width-10) / font_zoom)
            self:settext(pss:GetHighScore():GetDate())
        end

    }
}