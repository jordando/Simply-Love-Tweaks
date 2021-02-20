local args = ...
local player = args.player
local hash = args.hash
local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)

local pane = Def.ActorFrame{
	--Name="Pane4_SideP1",
	InitCommand=function(self)
		self:visible(false):x(WideScale(115,0))
	end,
	OnCommand=function(self)
		self:playcommand("Set")
	end,
	SetCommand=function(self)
		local pn = ToEnumShortString(player)
		local lastPlayed, numPlayed, firstPass
		local chartStats = GetChartStats(player, hash)
		if not chartStats then
			--if there's only one high score than this is the first time we've played the chart
			if #PROFILEMAN:GetProfile(pn):GetHighScoreList(GAMESTATE:GetCurrentSong(),GAMESTATE:GetCurrentSteps(player)):GetHighScores() == 1 then
				lastPlayed = "NEVER"
				numPlayed = 1
				firstPass = pss:GetFailed() and "NEVER" or "Just now"
			else
				lastPlayed = "UNKNOWN"
				numPlayed = "UNKNOWN"
				firstPass = "UNKNOWN"
			end
		else
			--if we played the song today then lastplayed is "TODAY" otherwise it's the date
			lastPlayed = chartStats.LastPlayed
			local lastPlayedDay = Split(lastPlayed)[1]
			local dateTable = Split(lastPlayedDay,"-")
			if Year() == tonumber(dateTable[1]) and MonthOfYear()+1 == tonumber(dateTable[2]) and DayOfMonth() == tonumber(dateTable[3]) then
				lastPlayed = "Today"
			else
				lastPlayed = lastPlayedDay
			end
			numPlayed = tonumber(chartStats.NumTimesPlayed) + 1
			if not pss:GetFailed() and chartStats.FirstPass == "Never" then
				firstPass = "Just now"
			else firstPass = chartStats.FirstPass end
		end
		self:GetChild("stats"):GetChild("LastPlayedNumber"):settext("LAST PLAYED: "..lastPlayed)
		self:GetChild("stats"):GetChild("NumPlayedNumber"):settext("NUMBER OF PLAYS: "..numPlayed)
		self:GetChild("stats"):GetChild("FirstPass"):settext("FIRST PASS: "..firstPass)
		--determining the highest rate we've passed the song at
		local rateScores = GetScores(player,GetCurrentHash(player),false,true) --ignore rate, check for fail
		local highestRate, highestScore
		if rateScores then --if we have scores saved for this song
			table.sort(rateScores,function(k1,k2) if k1.rate == k2.rate then return k1.score > k2.score else return tonumber(k1.rate) > tonumber(k2.rate) end end)
			highestRate = rateScores[1].rate
			highestScore = rateScores[1].score
		end
		--if we passed the song we still need to compare the current song as scores don't save until profile does (after screeneval)
		if not pss:GetFailed() then
			--if there were no scores saved then current song is highest
			if not highestRate then
				highestRate = SL.Global.ActiveModifiers.MusicRate
				highestScore = pss:GetPercentDancePoints()
			--if there is a score saved but our current rate is higher
			elseif highestRate and SL.Global.ActiveModifiers.MusicRate > tonumber(highestRate) then
				highestRate = SL.Global.ActiveModifiers.MusicRate
				highestScore = pss:GetPercentDancePoints()
			--if there is a score saved and the rate is the same
			elseif highestRate and SL.Global.ActiveModifiers.MusicRate == tonumber(highestRate) and
			pss:GetPercentDancePoints() >= tonumber(highestScore) then
				highestScore = pss:GetPercentDancePoints()
			end
		end
		if highestScore then self:GetChild("stats"):GetChild("MaxRate"):settext("MAX RATE CLEAR: "..highestRate.." ("..FormatPercentScore(tonumber(highestScore))..")")
		else self:GetChild("stats"):GetChild("MaxRate"):settext("MAX RATE CLEAR: NONE") end
	end,
}

--Highscore Display
local params = { Player=player, NumHighScores=10, RoundsAgo=1, Hash=hash}
local position = player == "PlayerNumber_P1" and WideScale(0,0) or WideScale(0,10)
if not ThemePrefs.Get("OriginalHighScoreList") and hash then
	pane[#pane+1] = LoadActor("ExperimentHighScoreList.lua", params)..{
		InitCommand=function(self) self:xy(position,_screen.cy - 62):zoom(.8) end
	}
else
	pane[#pane+1] = LoadActor(THEME:GetPathB("", "_modules/HighScoreList.lua"), params)..{
		InitCommand=function(self) self:xy(position,_screen.cy - 62):zoom(.8) end
	}
end

local stats = Def.ActorFrame{
	Name="stats",
	InitCommand=function(self)
		self:x(player == "PlayerNumber_P1" and (_screen.cx - WideScale(150,250)) or (-_screen.cx - WideScale(100,10)))
	end
}
--LastPlayed
stats[#stats+1] = LoadFont("Wendy/_wendy small")..{
	Name="LastPlayedNumber",
	InitCommand=function(self)
		self:zoom(.4):y(200):halign(0)
	end,
}

--NumTimes
stats[#stats+1] = LoadFont("Wendy/_wendy small")..{
	Name="NumPlayedNumber",
	InitCommand=function(self)
		self:zoom(.4):y(230):halign(0)
	end,
}

--MaxRate
stats[#stats+1] = LoadFont("Wendy/_wendy small")..{
	Name="MaxRate",
	InitCommand=function(self)
		self:zoom(.4):y(260):halign(0)
	end,
}

--FirstPass
stats[#stats+1] = LoadFont("Wendy/_wendy small")..{
	Name="FirstPass",
	InitCommand=function(self)
		self:zoom(.4):y(290):halign(0)
	end,
}

pane[#pane+1] = stats

return pane