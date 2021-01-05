local args = ...
local player = args.player
local controller = player == 'PlayerNumber_P1' and "left" or "right"
local hash = args.hash
local otherSide = {left = "right", right = "left"}
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local comparisonScore
local currentScore = {}
local sanitizedComparisonScore
local RateScores
local fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false

local TapNoteScores = {
	Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' },
}

local RadarCategories = {
	Types = { 'Holds', 'Mines', 'Hands', 'Rolls' },
}
--check to see if we have a custom saved score
--if we do, it's ready to go so set sanitizedComparisonScore
RateScores = GetScores(player, hash, true) --See /scripts/Experiment-Scores.lua
if RateScores then
	sanitizedComparisonScore = DeepCopy(RateScores[1])
	if fapping then
		sanitizedComparisonScore.W1 = sanitizedComparisonScore.W1 - sanitizedComparisonScore.W0
	end
end

--if we don't, check if there's a highscore in the normal highscores (stats.xml)
--if we find one then throw set it to comparisonScore (need to change formatting so judgment numbers can read it)
if not sanitizedComparisonScore then
	local song = GAMESTATE:GetCurrentSong()
	local steps = GAMESTATE:GetCurrentSteps(player)
	local highScores = PROFILEMAN:GetProfile(player):GetHighScoreList(song, steps):GetHighScores()
	local rateHighScores = {}
	local rate = SL.Global.ActiveModifiers.MusicRate
	--check to make sure any scores in stats.xml are at the correct rate
	for score in ivalues(highScores) do
		local test = score:GetModifiers()
		if tostring(rate) == tostring(string.find(test, "xMusic") and string.gsub(test,".*(%d.%d+)xMusic.*","%1") or 1) then
			rateHighScores[#rateHighScores+1] = score
		end
	end
	if #rateHighScores > 0 then
		if rateHighScores[1]:GetPercentDP() > pss:GetPercentDancePoints() then comparisonScore = rateHighScores[1]
		elseif rateHighScores[2] then comparisonScore = rateHighScores[2] end
		sanitizedComparisonScore = {}
	end
end
--clean up the current score for judgment numbers
--and comparison score if we have one
for i=1,#TapNoteScores.Types do
	local window = TapNoteScores.Types[i]
	currentScore[window] = pss:GetTapNoteScores( "TapNoteScore_"..window )
	if comparisonScore then sanitizedComparisonScore[window] = comparisonScore:GetTapNoteScore(window) end
end
currentScore['W0'] = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].W0
if fapping then 
	currentScore['W1'] = currentScore['W1'] - currentScore['W0']
	if comparisonScore then sanitizedComparisonScore['W0'] = 0 end
end
for RCType in ivalues(RadarCategories.Types) do
	currentScore[RCType] = pss:GetRadarActual():GetValue( "RadarCategory_"..RCType )
	currentScore['possible'..RCType] = pss:GetRadarPossible():GetValue( "RadarCategory_"..RCType )
	if comparisonScore then
		sanitizedComparisonScore[RCType] = comparisonScore:GetRadarValues():GetValue(RCType)
		sanitizedComparisonScore['possible'..RCType] = currentScore['possible'..RCType]
	end
end
if comparisonScore then
	sanitizedComparisonScore.score = comparisonScore:GetPercentDP()
	sanitizedComparisonScore.dateTime = comparisonScore:GetDate()
end
currentScore.score = pss:GetPercentDancePoints()

local af = Def.ActorFrame{
}

--the default judgment breakdown shown in normal SL
af[#af+1] = Def.ActorFrame{
	InitCommand = function(self)
		--self:addx(controller == "left" and 0 or 310)
	end,

	LoadActor(THEME:GetPathB("", "_modules/HighScoreDisplay"), {player, currentScore, controller})
}

--another pane for either your current top score or the previous high score to compare
local comparisonT = Def.ActorFrame{
	InitCommand = function(self)
		self:addx(otherSide[controller] == "left" and -74 or 310)
		self:zoom(.75):addx(37):addy(88)
	end
}

if sanitizedComparisonScore and sanitizedComparisonScore.score then

	comparisonT[#comparisonT+1] = LoadActor(THEME:GetPathB("", "_modules/HighScoreDisplay"), {player, sanitizedComparisonScore, otherSide[controller]})

	-- delta comparing scores
	comparisonT[#comparisonT+1] = LoadActor("./Delta.lua", {player, currentScore,sanitizedComparisonScore, otherSide[controller]})

	--Label for previous record or current record depending on if you got a new high score
	comparisonT[#comparisonT+1] = LoadFont("Wendy/_wendy small")..{
		InitCommand=function(self)
			self:zoom(.65):xy(otherSide[controller] == "right" and 0 or 5,145)
			self:visible(true)
			if tonumber(sanitizedComparisonScore.score) <= tonumber(pss:GetPercentDancePoints()) then self:settext("Previous Record")
			else self:settext("Current Record") end
		end,
	}
		--Date
		comparisonT[#comparisonT+1] = LoadFont("Wendy/_wendy small")..{
			InitCommand=function(self)
				self:zoom(.4):xy(otherSide[controller] == "right" and 0 or 5,173)
				self:visible(true)
				self:settext(sanitizedComparisonScore.dateTime)
			end,
		}

else
	comparisonT[#comparisonT+1] = LoadFont("Wendy/_wendy small")..{
		InitCommand=function(self)
			self:zoom(.8):xy(otherSide[controller] == "right" and -30 or -350,200)
			self:y(200)
			self:settext("No previous score\nat Rate "..SL.Global.ActiveModifiers.MusicRate)
		end,
	}
end

af[#af+1] = comparisonT

return af