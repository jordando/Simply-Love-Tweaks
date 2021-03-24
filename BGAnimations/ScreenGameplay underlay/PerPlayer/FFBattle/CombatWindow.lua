local _ = LoadActor(THEME:GetPathB("", "_modules/Characters.lua"))
local character = SL.Global.Character
local enemy = GetRandomEnemy()

local player = ...
local pn = ToEnumShortString(player)
character = GetCharacter(ThemePrefs.Get("Character"))
-- -----------------------------------------------------------------------

local PlayerState = GAMESTATE:GetPlayerState(player)
local streams, prevMeasure, streamIndex
local timingData = GAMESTATE:GetCurrentSteps(player):GetTimingData()
local width, height = 130, 35
local start, finish
local continueUpdating = false
local currentAnimation, currentEnemyHealth
local danger = false

-- We'll want to reset each of these values for each new song in the case of CourseMode
local InitializeMeasureCounter = function()
	-- SL[pn].Streams is initially set (and updated in CourseMode)
	-- in ./ScreenGameplay in/MeasureCounterAndModsLevel.lua
	streams = SL[pn].Streams
	streamIndex = 1
    prevMeasure = -1
    if not streams.TotalStreams then
        streams.TotalStreams = 0
        streams.Measures = {}
    end
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
    Def.Sprite{
        Texture=GetRandomBG(),
        InitCommand=function(self) self:zoomto(width*2 + 14, height * 5):align(0,1):xy(-34,10) end
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
                self:zoom(enemy.zoom and enemy.zoom or 1)
                self:SetStateProperties(enemy.idle)
                self:xy(enemy.xy[1],enemy.xy[2])
                :horizalign(left)
            end,
            -- if there are more than 500 measures then replace the small enemy with a big boy
            OnCommand=function(self)
                if streams.TotalStreams and tonumber(streams.TotalStreams) > 500 then
                    self:sleep(3):queuecommand("BigEnemy1")
                end
            end,
            BigEnemy1Command=function(self)
                self:linear(.2):x(enemy.xy[1] - 100):diffusealpha(0):queuecommand("BigEnemy2")
            end,
            BigEnemy2Command=function(self)
                self:Load(THEME:GetPathG("","warning.png"))
                self:xy(40,-100):linear(.4):diffusealpha(1):sleep(.2):linear(.4):diffusealpha(0)
                :linear(.4):diffusealpha(1):sleep(.2):linear(.4):diffusealpha(0)
                :queuecommand("BigEnemy3")
            end,
            BigEnemy3Command=function(self)
                enemy = GetRandomBigEnemy()
                self:zoom(enemy.zoom and enemy.zoom or 1)
                self:Load(enemy.load)
                self:SetStateProperties(enemy.idle)
                self:xy(enemy.xy[1],enemy.xy[2]-100)
                self:linear(1):diffusealpha(1):y(enemy.xy[2])
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
            self:xy(character.idleXY[1],character.idleXY[2])
            currentAnimation = "idle"
            self:SetStateProperties(character["idle"])
            self:horizalign(left)
            if character.zoom then self:zoom(character.zoom) end
        end,
        AttackMessageCommand=function(self)
            currentAnimation = "attack"
            -- attack should have either a table of frame information or a string
            -- pointing to a separate sprite sheet. if we have a string then just
            -- fade out the character so the attack sprite can do its thing
            if type(character.attack) ~= "string" then
                self:finishtweening():SetStateProperties(character["attack"])
                    :xy(character["attackXY"][1],character["attackXY"][2])
                    :sleep(self:GetAnimationLengthSeconds()):queuecommand("Default")
            else
                self:linear(.15):diffusealpha(0):sleep(character.attackTime):queuecommand("Default")
            end
        end,
        StandbyMessageCommand=function(self)
            currentAnimation = "magic2"
            if not danger then
                self:finishtweening():SetStateProperties(character["magic2"])
                self:xy(character.magic2XY[1],character.magic2XY[2])
            end
        end,
        DefaultCommand=function(self)
            if self:GetDiffuseAlpha() ~= 1 then
                self:linear(.15):diffusealpha(1)
            end
            if streams.Measures then
                -- if we get through every stream measure then start the victory dance
                if currentEnemyHealth==0 then
                    self:queuecommand("WinIntro")
                -- sometimes runs start while the attack animation is still playing. if we're still updating
                -- the progress bar then jump in to the standby command
                elseif continueUpdating then
                    currentAnimation="magic2"
                    if not danger then self:SetStateProperties(character["magic2"]) end
                -- otherwise we're in a no stream section so idle
                else
                    currentAnimation = "idle"
                    if not danger then self:SetStateProperties(character["idle"]) end
                end
                if type(character[currentAnimation]) == "table" then
                    self:SetStateProperties(character[currentAnimation]):xy(character[currentAnimation.."XY"][1],character[currentAnimation.."XY"][2])
                end
            end
        end,
        WinIntroCommand=function(self)
            self:xy(character.winIntroXY[1],character.winIntroXY[2])
            currentAnimation="win"
            self:SetStateProperties(character["winIntro"]):sleep(self:GetAnimationLengthSeconds()):queuecommand("Win")
        end,
        WinCommand=function(self)
            self:SetStateProperties(character["win"]):xy(character.winXY[1],character.winXY[2])
        end,
        DeadCommand=function(self)
            self:SetStateProperties(character["dead"]):xy(character["deadXY"][1],character["deadXY"][2])
        end,
        HealthStateChangedMessageCommand=function(self, param)
            if param.PlayerNumber == player and param.HealthState == "HealthState_Dead" then
                continueUpdating = false
                if character["deadIntro"] then
                    self:xy(character.deadIntroXY[1],character.deadIntroXY[2])
                    currentAnimation="deadIntro"
                    self:SetStateProperties(character["deadIntro"]):sleep(self:GetAnimationLengthSeconds()):queuecommand("Dead")
                else
                    self:queuecommand("Dead")
                end
            elseif currentAnimation ~= "attack" then
                if param.HealthState == "HealthState_Danger" then
                    danger = true
                    self:SetStateProperties(character["danger"]):xy(character["dangerXY"][1],character["dangerXY"][2])
                else
                    danger = false
                    self:SetStateProperties(character[currentAnimation]):xy(character[currentAnimation.."XY"][1],character[currentAnimation.."XY"][2])
                end
            end
        end,
    },

    -- Extra sprite for if attack is in a different spritesheet
    Def.Sprite{
        Name="Attack",
        InitCommand=function(self)
            if type(character.attack) == "string" then
                self:Load(character.attack)
                self:SetStateProperties(self.LinearFrames(character.attackFrames[1],character.attackFrames[2]))
                self:zoom(1):xy(character.attackXY[1],character.attackXY[2]):setstate(0):animate(true):visible(false)
                self:horizalign(left)
            end
        end,
        AttackMessageCommand=function(self)
            if type(character.attack) == "string" then
                self:finishtweening():visible(true):
                linear(.15):diffusealpha(1):play():sleep(self:GetAnimationLengthSeconds()-.25):linear(.1):diffusealpha(0):queuecommand("FinishAttack")
            end
        end,
        FinishAttackCommand=function(self)
            self:animate(false):setstate(0):visible(false)
        end,
    }
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