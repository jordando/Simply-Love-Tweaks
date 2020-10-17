local args = ...
local player = args.player
local hash = args.hash
local pn = ToEnumShortString(player)
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local highScore
local isCustomScore = false
local RateScores

RateScores = GetScores(player, hash, true) --See /scripts/Experiment-Scores.lua
if RateScores then
	highScore = RateScores[1]
	isCustomScore = true
end
if not highScore then
	local song = GAMESTATE:GetCurrentSong()
	local steps = GAMESTATE:GetCurrentSteps(player)
	local highScores = PROFILEMAN:GetProfile(player):GetHighScoreList(song, steps):GetHighScores()
	if #highScores > 0 then
		if highScores[1]:GetPercentDP() > pss:GetPercentDancePoints() then highScore = highScores[1]
		elseif highScores[2] then highScore = highScores[2] end
	end
end

local TapNoteScores = {
	Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' },
	-- x values for P1 and P2
	x = { P1=78, P2=64 }
}

local RadarCategories = {
	Types = { 'Holds', 'Mines', 'Hands', 'Rolls' },
	-- x values for P1 and P2
	x = { P1=-180, P2=218 }
}

-----------------------------------------------------------------------------------------------------------------
--AF for the stats to compare to
local highScorePosition = player == "PlayerNumber_P1" and 0 or WideScale(-100,-115)
local deltaPosition = player == "PlayerNumber_P1" and 0 or WideScale(200,230)
local highScoreT = Def.ActorFrame{
	InitCommand=function(self)self:zoom(0.6):xy(highScorePosition,_screen.cy+10) end,
}

local deltaT = Def.ActorFrame{
	InitCommand=function(self)self:zoom(0.8):xy(deltaPosition,_screen.cy-24) end,
}

local windows = SL.Global.ActiveModifiers.TimingWindows

if highScore then
	local PercentDP
	if isCustomScore then PercentDP = highScore.score
	else PercentDP = highScore:GetPercentDP() end

	-- do "regular" TapNotes first
	for i=1,#TapNoteScores.Types do
		local window = TapNoteScores.Types[i]
		local number
		if isCustomScore then number = highScore[window]
		else number = highScore:GetTapNoteScore(window) end

		--delta between current stats and highscore stats
		deltaT[#deltaT+1] = LoadFont("Wendy/_wendy small")..{
			InitCommand=function(self)
				local toPrint
				toPrint = pss:GetTapNoteScores( "TapNoteScore_"..window ) - number
				if toPrint >= 0 then self:settext("+"..toPrint)
				else self:settext(toPrint) end
				self:zoom(.5):horizalign(left)
				self:x( TapNoteScores.x[pn] - WideScale(175,200))
				self:y((i-1)*35 -20)
				-- if some TimingWindows were turned off, the leading 0s should not
				-- be colored any differently than the (lack of) JudgmentNumber,
				-- so load a unique Metric group.
				if not windows[i] and i ~= #TapNoteScores.Types then
					self:diffuse(color("#444444"))
				end
				
				if toPrint > 0 then
					if window == "Miss" then self:diffuse(Color.Red)
					elseif window == "W1" then self:diffuse(Color.Green) end
				elseif window == "Miss" then self:diffuse(Color.Green)
				elseif window == "W1" and toPrint ~= 0 then self:diffuse(Color.Red)
				else self:diffuse(Color.White) end
			end,
		}
		
		-- actual numbers for previous record
		highScoreT[#highScoreT+1] = Def.RollingNumbers{
			Font="Wendy/_ScreenEvaluation numbers",
			InitCommand=function(self)
				self:zoom(0.5):horizalign(right)

				if SL.Global.GameMode ~= "ITG" then
					self:diffuse( SL.JudgmentColors[SL.Global.GameMode][i] )
				end

				-- if some TimingWindows were turned off, the leading 0s should not
				-- be colored any differently than the (lack of) JudgmentNumber,
				-- so load a unique Metric group.
				if not windows[i] and i ~= #TapNoteScores.Types then
					self:Load("RollingNumbersEvaluationNoDecentsWayOffs")
					self:diffuse(color("#444444"))

				-- Otherwise, We want leading 0s to be dimmed, so load the Metrics
				-- group "RollingNumberEvaluationA"	which does that for us.
				else
					self:Load("RollingNumbersEvaluationA")
				end
			end,
			BeginCommand=function(self)
				self:x( TapNoteScores.x[pn] - WideScale(50,20) )
				self:y((i-1)*35 -20)
				self:targetnumber(number)
			end
		}

	end

	-- then handle holds, mines, hands, rolls
	for index, RCType in ipairs(RadarCategories.Types) do
		local performance
		if isCustomScore then performance = highScore[RCType]
		else performance = highScore:GetRadarValues():GetValue(RCType) end
		-- player performace value
		highScoreT[#highScoreT+1] = Def.RollingNumbers{
			Font="Wendy/_ScreenEvaluation numbers",
			InitCommand=function(self) self:zoom(0.5):horizalign(right):Load("RollingNumbersEvaluationB") end,
			BeginCommand=function(self)
				self:y((index-1)*35 + 53)
				self:x( 218 )
				self:targetnumber(performance)
			end
		}

	end
	--Label for previous record or current record depending on if you got a new high score
	highScoreT[#highScoreT+1] = LoadFont("Wendy/_wendy small")..{
		InitCommand=function(self)
			self:zoom(.8):xy(150,-75)
			if tonumber(PercentDP) <= tonumber(pss:GetPercentDancePoints()) then self:settext("Previous Record")
			else self:settext("Current Record") end
		end,
	}
	--dark quad for the previous record percentage
	highScoreT[#highScoreT+1] =	Def.Quad{
		InitCommand=function(self)
			self:diffuse(color("#101519")):zoomto(150, 60)
			self:horizalign(right)
			self:xy(308,-10)
		end
	}
	local percent = FormatPercentScore(PercentDP)
	-- Format the Percentage string, removing the % symbol
	percent = percent:gsub("%%", "")

	highScoreT[#highScoreT+1] = LoadFont("Wendy/_wendy white")..{
		Name="Percent",
		Text=percent,
		InitCommand=function(self)
			self:horizalign(right):zoom(0.585)
			self:xy(300,-10)
		end
	}

	highScoreT[#highScoreT+1] = LoadActor("./ExperimentJudgmentLabels.lua", player)

else
	highScoreT[#highScoreT+1] = LoadFont("Wendy/_wendy small")..{
		InitCommand=function(self)
			self:zoom(.8):xy(player=="PlayerNumber_P1" and 70 or 200,-45)
			self:settext("No previous score\nat Rate "..SL.Global.ActiveModifiers.MusicRate)
		end,
	}
end


local toReturn = Def.ActorFrame{Name="DeltaT"}
toReturn[#toReturn+1] = deltaT
toReturn[#toReturn+1] = highScoreT

return toReturn