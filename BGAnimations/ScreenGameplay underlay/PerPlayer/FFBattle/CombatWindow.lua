LoadActor(THEME:GetPathB("", "_modules/Characters.lua"))
local character = GetCharacter("Steiner")
local enemy = GetEnemy("x001")

local player = ...
local pn = ToEnumShortString(player)

-- -----------------------------------------------------------------------

local PlayerState = GAMESTATE:GetPlayerState(player)
local streams, prevMeasure, streamIndex
local timingData = GAMESTATE:GetCurrentSteps(player):GetTimingData()
local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)
local width, height = 130, 35
local start, finish
local continueUpdating = false
local currentAnimation, currentEnemyHealth

-- We'll want to reset each of these values for each new song in the case of CourseMode
local InitializeMeasureCounter = function()
	-- SL[pn].Streams is initially set (and updated in CourseMode)
	-- in ./ScreenGameplay in/MeasureCounterAndModsLevel.lua
	streams = SL[pn].Streams
	streamIndex = 1
    prevMeasure = -1
    currentEnemyHealth = streams.TotalStreams
end

-- Returns whether or not we've reached the end of this stream segment.
local IsEndOfStream = function(currMeasure, Measures, streamIndex)
	if Measures[streamIndex] == nil then return false end

	-- a "segment" can be either stream or rest
	local segmentStart = Measures[streamIndex].streamStart
	local segmentEnd   = Measures[streamIndex].streamEnd

	local currStreamLength = segmentEnd - segmentStart
	local currCount = math.floor(currMeasure - segmentStart) + 1

	return currCount > currStreamLength
end

local Update = function(self, delta)
	-- Check to make sure we even have any streams populated to display.
	if not streams.Measures or #streams.Measures == 0 then return end

	-- Things to look into:
	-- 1. Does PlayerState:GetSongPosition() take split timing into consideration?  Do we need to?
	-- 2. This assumes each measure is comprised of exactly 4 beats.  Is it safe to assume this?
	local currMeasure = (math.floor(PlayerState:GetSongPosition():GetSongBeatVisible()))/4
	-- If a new measure has occurred
	if currMeasure > prevMeasure then
		prevMeasure = currMeasure
		-- If we've reached the end of the stream, we want to get values for the next stream.
        if PlayerState:GetHealthState() ~= "HealthState_Dead"
        and IsEndOfStream(currMeasure, streams.Measures, streamIndex) then
            streamIndex = streamIndex + 1
            if not streams.Measures[streamIndex - 1].isBreak then
                MESSAGEMAN:Broadcast("SetNumber", {number = streams.Measures[streamIndex-1].streamEnd - streams.Measures[streamIndex-1].streamStart})
                MESSAGEMAN:Broadcast("Attack")
            end
            if not streams.Measures[streamIndex] then return end
            if streams.Measures[streamIndex].isBreak then
                continueUpdating = false
                self:GetChild("ATB"):GetChild("ProgressBar"):GetChild("ProgressQuad"):queuecommand("StopUpdating")
            else
                start = timingData:GetElapsedTimeFromBeat(4*streams.Measures[streamIndex].streamStart)
                finish = timingData:GetElapsedTimeFromBeat(4*streams.Measures[streamIndex].streamEnd)
                continueUpdating = true
                if currentAnimation ~= "attack" then MESSAGEMAN:Broadcast("Standby") end
                self:GetChild("ATB"):GetChild("ProgressBar"):GetChild("ProgressQuad"):queuecommand("Update")
            end
        end
	end
end
-- -----------------------------------------------------------------------

local af = Def.ActorFrame{
    InitCommand=function(self)
        self:queuecommand("SetUpdate")
    end,
    SetUpdateCommand=function(self) self:SetUpdateFunction( Update ) end,
	CurrentSongChangedMessageCommand=function(self)
        InitializeMeasureCounter()
        if not streams.Measures or not next(streams.Measures) then
            currentEnemyHealth=0
            self:sleep(3):queuecommand("InstantDeath") return
        end
        if streamIndex == 1 and not streams.Measures[streamIndex].isBreak then
            start = timingData:GetElapsedTimeFromBeat(4*streams.Measures[streamIndex].streamStart)
            finish = timingData:GetElapsedTimeFromBeat(4*streams.Measures[streamIndex].streamEnd)
            continueUpdating = true
            if currentAnimation ~= "attack" then MESSAGEMAN:Broadcast("Standby") end
            self:GetChild("ATB"):GetChild("ProgressBar"):GetChild("ProgressQuad"):queuecommand("Update")
        end
    end,
    InstantDeathCommand=function(self)
        MESSAGEMAN:Broadcast("Attack")
        self:sleep(1.5):queuecommand("InstantWin")
    end,
    --Card Edge
    Def.Sprite{
        Texture=THEME:GetPathG("FF","CardEdge.png"),
        InitCommand=function(self) self:zoomto(300,265):xy(-47,90):align(0,1) end
    },
    --Blue Frame
    Def.Quad {
        InitCommand=function(self) 
            self:xy(-33,80):zoomto(width*2 + 13, height * 7):align(0,1)
            self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
        end
    },
    --Ground for the sprites to stand on
    Def.Sprite{
        Texture=THEME:GetPathG("FF","CardEdge.png"),
        InitCommand=function(self) self:zoomto(285,55):xy(-40,3):align(0,1) end
    },
}

af[#af+1] = Def.ActorFrame{
    InitCommand=function(self) self:xy(125,-35) end,
    --------------------------------------------------------------------------------------------
    --Enemy sprite/Damage text
    Def.ActorFrame{
        InitCommand=function(self) self:xy(-125,0) end,
        EnemyDieMessageCommand=function(self) self:sleep(.5):linear(1):diffusealpha(0) end,
        Def.Sprite{
            Name="EnemySprite",
            Texture=enemy.load,
            InitCommand=function(self)
                self:zoom(enemy.zoom)
                self:SetStateProperties(enemy.idle)
                self:xy(enemy.xy[1],enemy.xy[2])
                :horizalign(left)
            end,
            AttackMessageCommand=function(self)
                if PlayerState:GetHealthState() ~= "HealthState_Dead" then
                    self:sleep(.25):queuecommand("Damage")
                    if currentEnemyHealth == 0 then MESSAGEMAN:Broadcast("EnemyDie") end
                    self:addx(-10):sleep(.05):addy(10):sleep(.05):addy(-10):sleep(.05):addx(10):sleep(.05):addx(-10):linear(.3):addx(10)
                    if currentEnemyHealth ~= 0 then self:queuecommand("Default") end
                end
            end,
            DamageCommand=function(self) self:SetStateProperties(enemy.damage) end,
            DefaultCommand=function(self) self:SetStateProperties(enemy.idle) end,
        },
        -- The damage text is nested in multiple actor frames so we can use multiple
        -- simultaneous tweens
        Def.ActorFrame{
            InitCommand=function(self) 
                self:y(self:GetParent():GetChild("EnemySprite"):GetHeight() * -(1/4))
                self:x(self:GetParent():GetChild("EnemySprite"):GetWidth() / 4)
            end,
            AttackMessageCommand=function(self)
                if PlayerState:GetHealthState() ~= "HealthState_Dead" then
                    self:sleep(.5):queuecommand("Damage")
                end
            end,
            DamageCommand=function(self) self:smooth(1):diffusealpha(0):queuecommand("Default") end,
            DefaultCommand=function(self) self:finishtweening():diffusealpha(1) end,
            Def.ActorFrame{
                InitCommand=function(self) end,
                AttackMessageCommand=function(self)
                    if PlayerState:GetHealthState() ~= "HealthState_Dead" then
                        self:sleep(.25):queuecommand("Damage")
                    end
                end,
                DamageCommand=function(self) self:smooth(1):y(-20):queuecommand("Default") end,
                DefaultCommand=function(self) self:y(0) end,
                LoadFont("Common Header")..{
                    InitCommand=function(self) self:zoom(0) end,
                    SetNumberMessageCommand=function(self, param) self:settext("-"..param.number) end,
                    AttackMessageCommand=function(self)
                        if PlayerState:GetHealthState() ~= "HealthState_Dead" then
                            self:sleep(.25):queuecommand("Damage")
                        end
                    end,
                    DamageCommand=function(self) self:smooth(1):zoom(.5):queuecommand("Fade") end,
                    DefaultCommand=function(self) self:zoom(0) end,
                }
            }
        }
    },
--------------------------------------------------------------------------------------------
-- Character
    Def.Sprite{
        Name="Character",
        Texture=character.load,
        InitCommand=function(self)
            self:zoom(1):xy(character.XY[1],character.XY[2])
            currentAnimation = "idle"
            self:SetStateProperties(character["idle"])
            self:horizalign(left)
        end,
        AttackMessageCommand=function(self)
            currentAnimation = "attack"
            self:finishtweening():SetStateProperties(
                character["attack"]):xy(character["attackXY"][1],character["attackXY"][2])
                :sleep(1.5):xy(character["XY"][1],character["XY"][2]):queuecommand("Default")
        end,
        StandbyMessageCommand=function(self)
            currentAnimation = "magic2"
            self:finishtweening():SetStateProperties(character["magic2"])
        end,
        DefaultCommand=function(self)
            if streams.Measures then
                -- if we get through every stream measure then start the victory dance
                if streamIndex == #streams.Measures and streams.Measures[streamIndex].isBreak then
                    currentAnimation = "win"
                    self:SetStateProperties(character["win"]):xy(character.winXY[1],character.winXY[2])
                -- sometimes runs start while the attack animation is still playing. if we're still updating
                -- the progress bar then jump in to the standby command
                elseif continueUpdating then
                    currentAnimation="magic2"
                    self:SetStateProperties(character["magic2"])
                -- otherwise we're in a no stream section so idle
                else
                    currentAnimation = "idle"
                    self:SetStateProperties(character["idle"])
                end
            end
        end,
        InstantWinCommand=function(self)
            currentAnimation="win"
            self:SetStateProperties(character.win)
        end,
        HealthStateChangedMessageCommand=function(self, param)
            if param.PlayerNumber == player and param.HealthState == "HealthState_Dead" then
                self:SetStateProperties(character["dead"]):xy(character["deadXY"][1],character["deadXY"][2])
                continueUpdating = false
            elseif currentAnimation ~= "attack" then
                if param.HealthState == "HealthState_Danger" then
                    self:SetStateProperties(character["danger"]):xy(character["dangerXY"][1],character["dangerXY"][2])
                else
                    self:SetStateProperties(character[currentAnimation]):xy(0,0)
                end
            end
        end,
    },

}

--------------------------------------------------------------------------------------------
--ATB Meter/Character Icon/Enemy Damage Bar
af[#af+1] = Def.ActorFrame{
    Name="ATB",
    InitCommand=function(self)
        self:xy(-25,75)
    end,
    --Card Edge
    Def.Sprite{
        Texture=THEME:GetPathG("FF","CardEdge.png"),
        InitCommand=function(self) self:zoomto(285,45):xy(-14,3):align(0,1) end
    },
    --Blue Frame
    Def.Quad {
        InitCommand=function(self) 
            self:xy(-2,0):zoomto(width*2, height + 5):align(0,1)
            self:diffuseleftedge(color("#23279e")):diffuserightedge(Color.Black)
        end
    },
    --Character icon
    Def.Sprite {
        Name="Icon",
        Texture=character.icon,
        InitCommand=function(self) self:xy(0,0):align(0,1) end,
    },
    --Character ATB Meter
    Def.ActorFrame{
        Name="ProgressBar",
        InitCommand=function(self) self:xy(self:GetParent():GetChild("Icon"):GetWidth() + 17,-3) end,
        Def.Quad{
            Name="ProgressQuad",
            InitCommand=function(self)
                self:setsize(width * 1.4, height)
                    :queuecommand("StopUpdating")
                    :align(0,1)
            end,
            UpdateCommand=function(self)
                local song_percent = scale( GAMESTATE:GetCurMusicSeconds(), start, finish, 0, width * 1.4 )
                self:zoomtowidth(clamp(song_percent, 0, width * 1.4)):sleep(0.1)
                if continueUpdating then self:queuecommand("Update")
                else self:queuecommand("StopUpdating") end
            end,
            StopUpdatingCommand=function(self) self:zoomto(0, height) end
        },
        --Frame
        Def.Quad { InitCommand=function(self) self:zoomto(width * 1.4, height):MaskSource(true):align(0,1) end },
        Def.Quad { InitCommand=function(self) self:zoomto(width * 1.4+2,height+2):xy(-1,1):MaskDest():align(0,1) end },
    },
    --Enemy Health Bar
    Def.ActorFrame{
        InitCommand=function(self) self:xy(-2,-50) end,
        -- Black background
        Def.Quad { InitCommand=function(self) self:zoomto(width*2, height/2):align(0,1):diffuse(Color.Black) end },
        -- A white block that animates the drain
        Def.Quad{
            InitCommand=function(self)
                self:setsize(width*2, height/2):align(0,1):diffuse(Color.Red)
            end,
            AttackMessageCommand=function(self)
                local percent = scale( currentEnemyHealth ,0 ,streams.TotalStreams, 0, width*2)
                self:sleep(.5):linear(.5):zoomtowidth(clamp(percent, 0, width*2))
            end,
        },
        -- The actual health bar part
        Def.Quad{
            Name="EnemyHealthBar",
            InitCommand=function(self)
                self:setsize(width*2, height/2):align(0,1):diffuse(color("#fc9403"))
            end,
            SetNumberMessageCommand=function(self, param) currentEnemyHealth = currentEnemyHealth - param.number end,
            AttackMessageCommand=function(self)
                local percent = scale( currentEnemyHealth ,0 ,streams.TotalStreams, 0, width*2)
                self:zoomtowidth(clamp(percent, 0, width*2))
                if currentEnemyHealth == 0 then MESSAGEMAN:Broadcast("EnemyDie") end
            end,
        },
        -- Frame
        Def.Quad { InitCommand=function(self) self:zoomto(width*2, height/2):MaskSource(true):align(0,1) end },
        Def.Quad { InitCommand=function(self) self:xy(-1,1):zoomto(width*2+2, height/2+2):MaskDest():align(0,1) end },
        -- Text
        LoadFont("Common Header")..{
            InitCommand=function(self) self:zoom(.4):xy(125,-9) end,
            OnCommand=function(self) self:settext(currentEnemyHealth.."/"..streams.TotalStreams) end,
            AttackMessageCommand=function(self) self:settext(currentEnemyHealth.."/"..streams.TotalStreams) end,
        }
    }
}

return af