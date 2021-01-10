-- This screen is called right before going in to SelectMusic when Experiment mode custom scores are enabled.
-- Also load the character for Fantasy. TODO either rename this screen or move this somewhere else
local tweentime = 0.325
local co, text
local count = 0
local finish = false

return Def.ActorFrame{
	InitCommand=function(self)
		self:Center():draworder(101)
		if SL.Global.GameMode == "Experiment" then
			self:sleep(1):queuecommand("LoadScores")
        end
        LoadActor(THEME:GetPathB("", "_modules/Characters.lua"))
        SL.Global.Character = GetCharacter(ThemePrefs.Get("Character"))
	end,

	Def.Quad{
		Name="FadeToBlack",
		InitCommand=function(self)
			self:horizalign(right):vertalign(bottom):FullScreen()
			--self:diffuse( ThemePrefs.Get("RainbowMode") and Color.White or Color.Black ):diffusealpha(0)
		end,
		OnCommand=function(self)
			self:sleep(tweentime):linear(tweentime):diffusealpha(1)
		end
	},

	Def.Quad{
		Name="HorizontalWhiteSwoosh",
		InitCommand=function(self)
			self:horizalign(center):vertalign(middle)
				:diffuse( ThemePrefs.Get("RainbowMode") and Color.Black or Color.White )
				:zoomto(_screen.w + 100,50):faderight(0.1):fadeleft(0.1):cropright(1)
		end,
		OnCommand=function(self)
			self:linear(tweentime):cropright(0):sleep(tweentime)
			self:sleep(.1):queuecommand("Load")
		end,
		LoadCommand=function(self)
			if SL.Global.GameMode ~= "Experiment" then SCREENMAN:GetTopScreen():Continue() end
		end
	},

	Def.BitmapText{
		Font="Wendy/_wendy small",
		Text="Loading Scores: ",
        InitCommand=function(self)
            self:diffusealpha(0):linear(tweentime):diffusealpha(1)
            self:x(WideScale(-250,-400)):horizalign(left):diffuse( ThemePrefs.Get("RainbowMode") and Color.White or Color.Black ):zoom(0.6)
            --Load streamData
            LoadStreamData()
            --Load scores from separate txt file (See /scripts/Experiment-Scores.lua)
            --only if we're in Experiment mode using custom scores
            for player in ivalues(GAMESTATE:GetHumanPlayers()) do
                local pn = ToEnumShortString(player)
                co = coroutine.create(LoadScores)
                coroutine.resume(co,pn)
                text = "Importing from Stats.xml: "
                self:settext("Loading Scores")
                self:queuecommand("SetupCoroutine")
            end
        end,

        LoadHashCommand = function(self)
            co = coroutine.create(LoadHashLookup)
            text = "Generating new hashes: "
            self:settext("Creating hash lookup table")
            self:queuecommand("SetupCoroutine")
            finish = true
        end,

        SetupCoroutineCommand = function(self)
            self:stoptweening()
            if coroutine.status(co) == "suspended" then
                count = count + 1
                self:settext(text..count)
                Trace("COROUTINE: "..count)
                coroutine.resume(co)
            end
            Trace("Yielded, checking dead")
            if coroutine.status(co) ~= "dead" then
                self:sleep(.3):queuecommand("SetupCoroutine")
            else
                self:settext("DONE")
                if finish then
                    Trace("FINISH")
                    self:queuecommand("Finish")
                else
                    Trace("LOAD HASH")
                    self:queuecommand("LoadHash")
                end
            end
        end,

		FinishCommand = function(self)
			SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
		end
	}
}
