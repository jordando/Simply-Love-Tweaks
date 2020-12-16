--High Score

local player = ...

local pane = Def.ActorFrame{
	Name="Pane2",
	InitCommand = function(self) self:visible(false) end,
	ShowPlayerOptionsPane2MessageCommand = function(self, params)
		if params.PlayerNumber == player then self:visible(true) end
	end,
	HidePlayerOptionsPane2MessageCommand = function(self, params)
		if params.PlayerNumber == player then self:visible(false) end
	end,
}

local fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false
local controller = player == 'PlayerNumber_P1' and "left" or "right"

--initialize the high score with a blank template. the actual score will be set when
--SetNewHighScorePane is broadcast
local highScore = {
	score = 0,
	W1 = 0,
	W2 = 0,
	W3 = 0,
	W4 = 0,
	W5 = 0,
	Miss = 0,
	Holds = 0,
	Mines = 0,
	Hands = 0,
	Rolls = 0,
}
if fapping then highScore.W0 = 0 end

--If we don't have a score then display a message saying so
pane[#pane+1] = LoadFont("Common Normal")..{
	Name = "NoScore",
	Text = "No saved scores",
	InitCommand=function(self) self:diffuse(Color.White):zoom(1.25):visible(false) end,
}

--Date
pane[#pane+1] = LoadFont("Common Normal")..{
	Name = "Date",
	InitCommand=function(self)
		self:zoom(.9):xy(player == PLAYER_1 and 125 or -120,90):horizalign(player == PLAYER_1 and right or left)
	end,
	SetNewHighScorePaneMessageCommand = function(self, param)
		self:settext(param[1].dateTime)
	end,
}

pane[#pane+1] = LoadActor(THEME:GetPathB("", "_modules/HighScoreDisplay"), {player, highScore, controller})..{
	InitCommand = function(self) self:y(-225):zoom(.8) end,
	SetOptionPanesMessageCommand = function(self)
		highScore = nil
		local statsScore
		local RateScores
		fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false

		local TapNoteScores = {
			Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' },
		}

		local RadarCategories = {
			Types = { 'Holds', 'Mines', 'Hands', 'Rolls' },
		}

		local hash = GetCurrentHash(player)

		--check to see if we have a custom saved score
		--if we do, it's ready to go
		RateScores = GetScores(player, hash, true) --See /scripts/Experiment-Scores.lua
		if RateScores then
			highScore = DeepCopy(RateScores[1])
			if fapping then
				highScore.W1 = highScore.W1 - highScore.W0
			end
		end
		--if we don't, check if there's a highscore in the normal highscores (stats.xml)
		--if we find one then throw set it to comparisonScore (need to change formatting so judgment numbers can read it)
		if not highScore then
			local song = GAMESTATE:GetCurrentSong()
			local steps = GAMESTATE:GetCurrentSteps(player)
			local highScores = PROFILEMAN:GetProfile(player):GetHighScoreList(song, steps):GetHighScores()
			if #highScores > 0 then
				statsScore = highScores[1]
				highScore = {}
			end
		end
		--clean up the score from stats if we have one
		if statsScore then
			for i=1,#TapNoteScores.Types do
				local window = TapNoteScores.Types[i]
				highScore[window] = statsScore:GetTapNoteScore(window)
			end
			if fapping then
				highScore['W0'] = 0
			end
			for RCType in ivalues(RadarCategories.Types) do
				highScore[RCType] = statsScore:GetRadarValues():GetValue(RCType)
			end
			if statsScore then
				highScore.score = statsScore:GetPercentDP()
				highScore.dateTime = statsScore:GetDate()
			end
		end
		if highScore then
			self:visible(true)
			MESSAGEMAN:Broadcast("SetNewHighScorePane",{highScore})
			self:GetParent():GetChild("NoScore"):visible(false)
			self:GetParent():GetChild("Date"):visible(true)
		else
			self:visible(false)
			self:GetParent():GetChild("NoScore"):visible(true)
			self:GetParent():GetChild("Date"):visible(false)
		end
	end
}
return pane