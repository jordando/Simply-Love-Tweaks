local awards = {FullComboW3 = 2, SingleDigitW3 = 2, OneW3 = 2,
				FullComboW2 = 3, SingleDigitW2 = 3, OneW2 = 3,
				FullComboW1 = 4,}

local function GetSongDirs()
	local songs = SONGMAN:GetAllSongs()
	local list = {}
	for item in ivalues(songs) do
		list[item:GetSongDir()]={title = item:GetMainTitle(), song = item}
	end
	return list
end

--- Checks to see if any songs that have scores in stats but weren't loaded when we first ran LoadFromStats
---  are now on the machine. Does not generate hashes - only adds scores if the hashes are already in the lookup table.
function LoadNewFromStats(player)
	local songs = SONGMAN:GetAllSongs()
	local pn = ToEnumShortString(player)
	for song in ivalues(songs) do
		for chart in ivalues(song:GetAllSteps()) do
			local difficulty = ToEnumShortString(chart:GetDifficulty())
			local stepsType = ToEnumShortString(chart:GetStepsType()):gsub("_","-"):lower()
			local hash = GetHash(chart)
			--if there's a hash for the song and profile scores but no custom scores that means the
			--song wasn't loaded when we did the original LoadFromStats. Add them in now. Ideally
			--we would read stats.xml again to get things like numTimesPlayed but for now just pull
			--what we can from in game stats
			if hash and not GetScores(player,hash) and #PROFILEMAN:GetProfile(pn):GetHighScoreList(song,chart):GetHighScores() > 0 then
				local lastPlayed = "1980-01-01 12:12:00"
				local bestPass = 0
				for highScore in ivalues(PROFILEMAN:GetProfile(pn):GetHighScoreList(song,chart):GetHighScores()) do
						local TapNoteScores = {
							Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' },
						}
						local RadarCategories = {
							Types = { 'Holds', 'Mines', 'Hands', 'Rolls' },
						}
						local stats = {}
						local mods = highScore:GetModifiers()
						stats.rate = string.find(mods, "xMusic") and string.gsub(mods,".*(%d.%d+)xMusic.*","%1") or 1
						stats.score = highScore:GetPercentDP()
						stats.grade = ToEnumShortString(highScore:GetGrade())
						if bestPass == 0 and stats.grade ~= "Failed" then bestPass = 1 end
						if awards[highScore:GetStageAward()] and awards[highScore:GetStageAward()] > bestPass then
							bestPass = awards[highScore:GetStageAward()]
						end
						stats.dateTime = highScore:GetDate()
						if DateToMinutes(stats.dateTime) > DateToMinutes(lastPlayed) then lastPlayed = stats.dateTime end
						for i=1,#TapNoteScores.Types do
							local window = TapNoteScores.Types[i]
							local number = highScore:GetTapNoteScore( "TapNoteScore_"..window )
							stats[window] = number
						end
						--stats doesn't contain FA+ fantastics so just assume full white
						stats['W0'] = 0
						for _,RCType in ipairs(RadarCategories.Types) do
							local performance = highScore:GetRadarValues():GetValue( "RadarCategory_"..RCType )
							stats[RCType] = performance
						end
						if not SL[pn]['Scores'][hash] then SL[pn]['Scores'][hash] = {FirstPass='Unknown',NumTimesPlayed = 0} end
						if not SL[pn]['Scores'][hash]['HighScores'] then SL[pn]['Scores'][hash]['HighScores'] = {} end
						table.insert(SL[pn]['Scores'][hash]['HighScores'],stats)
					end
					SL[pn]['Scores'][hash].LastPlayed = lastPlayed
					SL[pn]['Scores'][hash].NumTimesPlayed = #PROFILEMAN:GetProfile(pn):GetHighScoreList(song,chart):GetHighScores() --TODO need to parse stats for real num
					SL[pn]['Scores'][hash].title = song:GetMainTitle()
					SL[pn]['Scores'][hash].Difficulty = difficulty
					SL[pn]['Scores'][hash].group = song:GetGroupName()
					SL[pn]['Scores'][hash].StepsType = stepsType
					SL[pn]['Scores'][hash].hash = hash
					SL[pn]['Scores'][hash].FirstPass = "Unknown" --TODO this can also be more accurate with NumTimesPlayed
					SL[pn]['Scores'][hash].BestPass = bestPass
			end
		end
	end
end

--- Crawl through stats.xml and add all scores found to a table with identical structure to SL[pn]['Scores'].
--- Also returns a list of hashes generated in a table with identical structure to the hash lookup table.
--- This function is only called when a scores txt file can't be found - usually the first time experiment 
--- mode runs.
local function LoadFromStats(pn)
	local profileDir
	if pn == 'P1' then profileDir = 'ProfileSlot_Player1' else profileDir = 'ProfileSlot_Player2' end
	local path = PROFILEMAN:GetProfileDir(profileDir)..'Stats.xml'
	local contents = ""
	local statsTable = {}
	local highScore = {}
	local hashLookup = {}
	if FILEMAN:DoesFileExist(path) then
		contents = GetFileContents(path)
		local group, song, title, groupSong, Difficulty, StepsType, numTimesPlayed, lastPlayed, firstPass, tempFirstPass, hash, stageAward
		local songDir = GetSongDirs()
		for line in ivalues(contents) do
			if string.find(line,"<Song Dir=") then
				groupSong = "/"..string.gsub(line,"<Song Dir='(Songs/[%w%p ]*/)'>","%1"):gsub("&apos;","'"):gsub("&amp;","&")
				group = Split(groupSong,"/")[2]
				if songDir[groupSong] then
					song = songDir[groupSong].song
					title = songDir[groupSong].title
					if not hashLookup[groupSong] then hashLookup[groupSong] = {} end
				else
					title = Split(groupSong,"/")[3]
					song = nil
				end
			elseif string.find(line,"<Steps Difficulty='") then
				local iterator = string.gmatch(line,"[%w%p]*='([%w%p]*)'")
				Difficulty = iterator()
				StepsType = iterator()
				if song then
					local fullStepsType = "StepsType_"..CapitalizeWords(StepsType):gsub("-","_")
					hash = GenerateHash(song:GetStepsByStepsType(fullStepsType)[1],StepsType,Difficulty)
					coroutine.yield() --resumed in ScreenLoadCustomScores.lua
					if not statsTable[hash] then statsTable[hash] = {} end
					if not hashLookup[groupSong][Difficulty] then hashLookup[groupSong][Difficulty] = {} end
					hashLookup[groupSong][Difficulty][StepsType] = hash
				end
				firstPass = "Never"
				tempFirstPass = DateToMinutes(GetCurrentDateTime())
				stageAward = 0
			elseif string.find(line,"<NumTimesPlayed>") then
				numTimesPlayed = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line, "<LastPlayed>") then
				lastPlayed = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<Grade>") then
				highScore.grade = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<PercentDP>") then
				highScore.score = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<StageAward>") then
				local tempStageAward = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
				if awards[tempStageAward] and stageAward <= tonumber(awards[tempStageAward]) then
					stageAward = awards[tempStageAward]
				end
			elseif string.find(line,"<Modifiers>") then
				highScore.rate = string.find(line, "xMusic") and string.gsub(line,".*(%d.%d+)xMusic.*","%1") or 1
			elseif string.find(line,"<DateTime>") then
				highScore.dateTime = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<Miss>") then
				highScore.Miss = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<W5>") then
				highScore.W5 = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<W4>") then
				highScore.W4 = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<W3>") then
				highScore.W3 = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<W2>") then
				highScore.W2 = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<W1>") then
				highScore.W1 = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<Holds>") then
				highScore.Holds = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<Mines>") then
				highScore.Mines = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<Hands>") then
				highScore.Hands = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"<Rolls>") then
				highScore.Rolls = string.gsub(line,"<[%w%p ]*>([%w%p ]*)</[%w%p ]*>","%1")
			elseif string.find(line,"</HighScore>") and song and #hash > 0 then
				--stats doesn't contain FA+ fantastics so just assume full white
				highScore.W0 = 0
				if not statsTable[hash]['HighScores'] then statsTable[hash]['HighScores'] = {} end
				table.insert(statsTable[hash]['HighScores'],highScore)
				if highScore.grade ~= "Failed" and DateToMinutes(highScore.dateTime) < tempFirstPass then
					tempFirstPass = DateToMinutes(highScore.dateTime)
					firstPass = highScore.dateTime
					if stageAward == 0 then stageAward = 1 end
				end
				highScore = {}
			elseif string.find(line,"</HighScoreList>") and song and #hash > 0 then
				local tempStepsType = CapitalizeWords(StepsType):gsub("-","_")
				local profileScores = PROFILEMAN:GetProfile(pn):GetHighScoreList(song,song:GetOneSteps(tempStepsType,Difficulty)):GetHighScores()
				 --if we've played it more times then there are scores and we've passed it at least once then we can't tell when the first time was
				 --but we know that it was passed at least once so we put "Unknown" as the firstPass date rather than "Never"
				if tonumber(numTimesPlayed) > #profileScores and firstPass ~= "Never" then firstPass = "Unknown" end
				--if we've played it more times than there are scores and all our scores are failures we can't tell if the song was
				--ever passed. we could try looking at the machine scores which save more by default to see if a player has a pass there.
				--but that involves more parsing, checking guid, and making sure the stats aren't duplicated from profile so i don't
				--want to right now. TODO
				--local machineScores = PROFILEMAN:GetMachineProfile():GetHighScoreList(song,song:GetOneSteps(tempStepsType,Difficulty)):GetHighScores()
				if #hash > 0 then
					statsTable[hash].group = group
					statsTable[hash].title = title
					statsTable[hash].Difficulty = Difficulty
					statsTable[hash].StepsType = StepsType
					statsTable[hash].LastPlayed = lastPlayed
					statsTable[hash].NumTimesPlayed = numTimesPlayed
					statsTable[hash].FirstPass = firstPass
					statsTable[hash].hash = hash
					statsTable[hash].BestPass = stageAward
				end
			end
		end
	end
	return statsTable, hashLookup
end

--- Read scores from disk if they exist. If they don't, then load our initial values with LoadFromStats
function LoadScores(pn)
	local profileDir
	if pn == 'P1' then profileDir = 'ProfileSlot_Player1' else profileDir = 'ProfileSlot_Player2' end
	local contents
	local Scores = {}
	local hashLookup = {}
	if FILEMAN:DoesFileExist(PROFILEMAN:GetProfileDir(profileDir).."/Scores.txt") then
		contents = GetFileContents(PROFILEMAN:GetProfileDir(profileDir).."/Scores.txt")
		local hash
		for line in ivalues(contents) do
			local score = Split(line,"\t")
			if #score == 9 then
				hash = nil
				hash = score[#score]
				if not Scores[hash] then Scores[hash] = {} end
				Scores[hash].title = score[1]
				Scores[hash].group = score[2]
				Scores[hash].Difficulty = score[3]
				Scores[hash].StepsType = score[4]
				Scores[hash].LastPlayed = score[5]
				Scores[hash].NumTimesPlayed = score[6]
				Scores[hash].FirstPass = score[7]
				Scores[hash].BestPass = score[8]
				Scores[hash].hash = hash
			elseif #score == 14 then
				if not Scores[hash]['HighScores'] then Scores[hash]['HighScores'] = {} end
				table.insert(Scores[hash]['HighScores'],{
					rate = score[1],
					score = score[2],
					W1 = score[3],
					W2 = score[4],
					W3 = score[5],
					W4 = score[6],
					W5 = score[7],
					Miss = score[8],
					Holds = score[9],
					Mines = score[10],
					Hands = score[11],
					Rolls = score[12],
					grade = score[13],
					dateTime = score[14],
					W0 = 0
					})
			elseif #score == 15 then
				if not Scores[hash]['HighScores'] then Scores[hash]['HighScores'] = {} end
				table.insert(Scores[hash]['HighScores'],{
					rate = score[1],
					score = score[2],
					W0 = score[3],
					W1 = score[4],
					W2 = score[5],
					W3 = score[6],
					W4 = score[7],
					W5 = score[8],
					Miss = score[9],
					Holds = score[10],
					Mines = score[11],
					Hands = score[12],
					Rolls = score[13],
					grade = score[14],
					dateTime = score[15],
					})
			end
		end
	--if there's no Scores.txt then import all the scores in Stats.xml to get started
	else
		if ThemePrefs.Get("LoadCustomScoresUpfront") then
			Scores, hashLookup = LoadFromStats(pn)
			SL.Global.HashLookup = hashLookup
		end
	end
	if SL[pn] then
		SL[pn]['Scores'] = Scores
		SaveScores(pn)
	end
end

--- Write rate scores to disk
function SaveScores(pn)
	if SL[pn]['Scores'] then
		local profileDir
		if pn == 'P1' then profileDir = 'ProfileSlot_Player1' else profileDir = 'ProfileSlot_Player2' end
		-- create a generic RageFile that we'll use to read the contents
		local file = RageFileUtil.CreateRageFile()
		-- the second argument here (the 2) signifies
		-- that we are opening the file in write mode
		if not file:Open(PROFILEMAN:GetProfileDir(profileDir).."/Scores.txt", 2) then SM("Could not open HashLookup.txt") return end
		for _,hash in pairs(SL[pn]['Scores']) do --TODO don't type this out manually
			if hash.hash then
				local toWrite = {
					hash.title,
					hash.group,
					hash.Difficulty,
					hash.StepsType,
					hash.LastPlayed,
					hash.NumTimesPlayed,
					hash.FirstPass,
					hash.BestPass,
					hash.hash
				}
				file:PutLine(table.concat(toWrite,"\t"))
				if hash["HighScores"] then
					for score in ivalues(hash["HighScores"]) do
						local add = {
							score.rate,
							score.score,
							score.W0,
							score.W1,
							score.W2,
							score.W3,
							score.W4,
							score.W5,
							score.Miss,
							score.Holds,
							score.Mines,
							score.Hands,
							score.Rolls,
							score.grade,
							score.dateTime
						}
						file:PutLine(table.concat(add,"\t"))
					end
				end
			end
		end
		file:Close()
		file:destroy()
	end
end

--- Add the latest score from PlayerStageStats to SL[pn][Scores]
function AddScore(player, hash)
	local pn = ToEnumShortString(player)
	local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
	local TapNoteScores = {
		Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' },
	}
	local RadarCategories = {
		Types = { 'Holds', 'Mines', 'Hands', 'Rolls' },
	}
	local stats = {}
	local stepsType = string.lower(ToEnumShortString(GetStepsType()):gsub("_","-"))
	stats.rate = SL.Global.ActiveModifiers.MusicRate
	stats.score = pss:GetPercentDancePoints()
	stats.grade = ToEnumShortString(pss:GetGrade())
	stats.dateTime = GetCurrentDateTime()
	for i=1,#TapNoteScores.Types do
		local window = TapNoteScores.Types[i]
		local number = pss:GetTapNoteScores( "TapNoteScore_"..window )
		stats[window] = number
	end
	--W0 are FA+ blue fantastics and will necessarily be <= W1 (Normal fantastics)
	stats['W0'] = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame].W0
	for _, RCType in ipairs(RadarCategories.Types) do
		local performance = pss:GetRadarActual():GetValue( "RadarCategory_"..RCType )
		stats[RCType] = performance
	end
	if #hash > 0 then
		if not SL[pn]['Scores'][hash] then SL[pn]['Scores'][hash] = {FirstPass='Never',NumTimesPlayed = 0, BestPass=0} end
		if not SL[pn]['Scores'][hash]['HighScores'] then SL[pn]['Scores'][hash]['HighScores'] = {} end
		table.insert(SL[pn]['Scores'][hash]['HighScores'],stats)
		SL[pn]['Scores'][hash].LastPlayed = stats.dateTime
		SL[pn]['Scores'][hash].NumTimesPlayed = tonumber(SL[pn]['Scores'][hash].NumTimesPlayed) + 1
		SL[pn]['Scores'][hash].title = GAMESTATE:GetCurrentSong():GetMainTitle()
		SL[pn]['Scores'][hash].Difficulty = ToEnumShortString(GAMESTATE:GetCurrentSteps(pn):GetDifficulty())
		SL[pn]['Scores'][hash].group = GAMESTATE:GetCurrentSong():GetGroupName()
		SL[pn]['Scores'][hash].StepsType = stepsType
		SL[pn]['Scores'][hash].hash = hash
		if SL[pn]['Scores'][hash].FirstPass == "Never" and stats.grade ~= 'Failed' then
			SL[pn]['Scores'][hash].FirstPass = stats.dateTime
			SL[pn]['Scores'][hash].BestPass = 1
		end
		if pss:GetStageAward() and awards[ToEnumShortString(pss:GetStageAward())] and tonumber(awards[ToEnumShortString(pss:GetStageAward())]) > tonumber(SL[pn]['Scores'][hash].BestPass) then
			SL[pn]['Scores'][hash].BestPass = awards[ToEnumShortString(pss:GetStageAward())]
		end
	else SM("WARNING: Could not generate hash for: "..GAMESTATE:GetCurrentSong():GetMainTitle()) end
end

---Returns an entry from the Custom Scores table if it exists
---@param player any
---@param hash any
function GetChartStats(player,hash)
	local pn = ToEnumShortString(player)
	if SL[pn]['Scores'][hash] then return SL[pn]['Scores'][hash] end
	return nil
end

---Returns a table of scores for a player given a hash or nil if there are no high scores
---@param checkRate boolean only returns scores with the same rate as the current song
---@param checkFailed boolean only returns passing scores
---both of these default to false if not explicitly set which will return all scores regardless
---of rate or fail status.
function GetScores(player, hash, checkRate, checkFailed)
	if not hash then return nil end
	local rate = SL.Global.ActiveModifiers.MusicRate
	local checkRate = checkRate or false
	local checkFailed = checkFailed or false
	local HighScores = {}
	local chartStats = GetChartStats(player,hash)
	if chartStats and chartStats['HighScores'] then
		for score in ivalues(chartStats['HighScores']) do
			if checkRate and not checkFailed then
				if tostring(score.rate) == tostring(rate) then HighScores[#HighScores+1] = score end
			elseif not checkRate and checkFailed then
				if score.grade ~= "Failed" then HighScores[#HighScores+1] = score end
			elseif checkRate and checkFailed then
				if tostring(score.rate) == tostring(rate) and score.grade ~= "Failed" then HighScores[#HighScores+1] = score end
			else
				HighScores[#HighScores+1] = score
			end
		end
	end
	if #HighScores > 0 then
		table.sort(HighScores,function(k1,k2) return tonumber(k1.score) > tonumber(k2.score) end)
		return HighScores
	else return nil end
end

--- Returns the best pass type for a chart (fail, pass, GFC, EFC, FFC)
function GetBestPass(player, songParam, chartParam)
	local pn = ToEnumShortString(player)
	local song = songParam or GAMESTATE:GetCurrentSong()
	local steps = chartParam or GAMESTATE:GetCurrentSteps(pn)
	local hash = GetHash(steps)
	local chartStats
	if hash then chartStats = GetChartStats(player,hash) end
	if chartStats and tonumber(chartStats.BestPass) then
		return tonumber(chartStats.BestPass)
	else
		local highScores = PROFILEMAN:GetProfile(pn):GetHighScoreList(song,steps):GetHighScores()
		local award = 0
		if highScores then
			for score in ivalues(highScores) do
				if award == 0 and score:GetGrade() ~= "Grade_Failed" then award = 1 end
				if score:GetStageAward() then
					local tempAward = tonumber(awards[ToEnumShortString(score:GetStageAward())])
					if tempAward > award then award = tempAward end
				end
			end
		end
		return award
	end
end

--- Returns the top grade for a given song and chart or nil if there isn't a high score. First tries to
--- use a custom score. If none is found it checks profile scores in stats.xml.
--- Respects rate if rateParam is true.
--- @param player Enum
--- @param songParam Song
--- @param chartParam Steps
--- @param rateParam boolean
function GetTopGrade(player, songParam, chartParam, rateParam)
	-- TODO only check if not course mode. should change this to check courses once they're added in
	if GAMESTATE:IsCourseMode() then return nil end
	local song = songParam or GAMESTATE:GetCurrentSong()
	local chart = chartParam or GAMESTATE:GetCurrentSteps(player)
	local grade
	local pn = ToEnumShortString(player)
	local hash = GetHash(chart)
	if hash then
		local scores = GetScores(player, hash, rateParam, true)
		if scores then
			grade = GetGradeFromPercent(scores[1].score)
		end
	end
	if not grade then
		local scores = PROFILEMAN:GetProfile(pn):GetHighScoreList(song,chart):GetHighScores()
		local rate
		if next(scores) then
			-- if we care about rate then look through all scores in stats.xml until we find one
			-- that has the correct rate. once we do, no need to look at the others
			if rateParam then
				for score in ivalues(scores) do
					if not grade then
						rate = score:GetModifiers()
						rate = string.find(rate, "xMusic") and string.gsub(rate,".*(%d.%d+)xMusic.*","%1") or 1
						if rate == SL.Global.ActiveModifiers.MusicRate then grade = score:GetGrade() end
					end
				end
			else grade = scores[1]:GetGrade() end
		end
	end
	if grade then
		local converted_grade = Grade:Reverse()[grade]
		if converted_grade > 17 then converted_grade = 17 end
		return converted_grade
	end
	return nil
end