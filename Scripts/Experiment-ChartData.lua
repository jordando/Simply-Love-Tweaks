

-- helper functions ---------------------------------------------------------------------

local function GetSongDirs()
	local songs = SONGMAN:GetAllSongs()
	local list = {}
	for item in ivalues(songs) do
		list[item:GetSongDir()]={title = item:GetMainTitle(), song = item}
	end
	return list
end

--- Get the mode of a table.  Returns a table of values.
--- Works on anything (not just numbers).
local function GetMode( t )
local counts={}

	for k, v in pairs( t ) do
		if v ~= 0 then
			if counts[v] == nil then
			counts[v] = 1
			else
			counts[v] = counts[v] + 1
			end
		end
	end

	local biggestCount = 0

	for k, v  in pairs( counts ) do
		if v > biggestCount then
		biggestCount = v
		end
	end

	local temp={}

	for k,v in pairs( counts ) do
		if v == biggestCount then
		table.insert( temp, k )
		end
	end

	return temp
end

--- Add StreamData to the global table. If PeakNPS can't be determined it's set as -1
--- If a density table can't be made it's set to {0} and NpsMode is set to -1
local function AddToStreamData(steps, stepsType, difficulty, notesPerMeasure)
    local song = SONGMAN:GetSongFromSteps(steps)
    local hash = GetHash(steps)
    --exit out if we don't have a hash
	if not hash then return false end
	local streamData = {}
	local peakNPS, densityT = GetNPSperMeasure(song,steps) --returns nil if it can't get it
	if not peakNPS then peakNPS = -1 end
	if not densityT then
		streamData.Density = {0}
		streamData.NpsMode = -1
	else
		streamData.Density = densityT
		local modeT = GetMode(densityT)
		if next(modeT) then --GetMode() ignores 0 so if densityT is a table with just 0 in it (happened before...) GetMode will return an empty table
			if #modeT and #modeT > 1 then table.sort(modeT) end
			streamData.NpsMode = modeT[#modeT]
		else streamData.NpsMode = -1 end
	end
	streamData.Name = song:GetMainTitle()
	streamData.Difficulty = difficulty
	streamData.StepsType = stepsType
    streamData.PeakNPS = peakNPS
	local measures = GetStreams(steps, stepsType, difficulty, notesPerMeasure)
	if measures and next(measures) then
		streamData.TotalMeasures = measures[#measures].streamEnd
        local lastSequence = #measures
		local totalStreams = 0
		local previousSequence = 0
        local segments = 0
        local breakdown = "" --breakdown tries to display the full streams including rest measures
        local breakdown2 = "" --breakdown2 tries to display the streams without rest measures
        local breakdown3 = "" --breakdown3 combines streams that would normally be separated with a -
        for _, sequence in ipairs(measures) do
            if not sequence.isBreak then
                totalStreams = totalStreams + sequence.streamEnd - sequence.streamStart
                breakdown = breakdown..sequence.streamEnd - sequence.streamStart.." "
                if previousSequence < 2 then
                    breakdown2 = breakdown2.."-"..sequence.streamEnd - sequence.streamStart
                elseif previousSequence >= 2 then
                    breakdown2 = breakdown2.."/"..sequence.streamEnd - sequence.streamStart
                    previousSequence = 0
                end
                segments = segments + 1
            else
                breakdown = breakdown.."("..sequence.streamEnd - sequence.streamStart..") "
                previousSequence = previousSequence + sequence.streamEnd - sequence.streamStart
            end
        end
		streamData.TotalStreams = totalStreams
        streamData.Segments = segments
        streamData.Breakdown1 = breakdown
        if totalStreams ~= 0 then
            local percent = totalStreams / measures[lastSequence].streamEnd
            percent = math.floor(percent*100)
			streamData.Percent = percent
			--trim off break at the beginning and end of the song to get a more accurate density percent
			local extraMeasures = 0
			if measures[1].isBreak then
				extraMeasures = measures[1].streamEnd - measures[1].streamStart
			end
			if measures[#measures].isBreak then
				extraMeasures = extraMeasures + measures[#measures].streamEnd - measures[#measures].streamStart
			end
			if extraMeasures > 0 then
				local adjustedPercent = totalStreams / (measures[lastSequence].streamEnd - extraMeasures)
				adjustedPercent = math.floor(adjustedPercent*100)
				streamData.AdjustedPercent = adjustedPercent
			else
				streamData.AdjustedPercent = percent
			end
            for stream in ivalues(Split(breakdown2,"/")) do
                local combine = 0
                local multiple = false
                for part in ivalues(Split(stream,"-")) do
                    if combine ~= 0 then multiple = true end
                    combine = combine + tonumber(part)
                end
                breakdown3 = breakdown3.."/"..combine..(multiple and "*" or "")
            end
            streamData.Breakdown2 = string.sub(breakdown2,2)
            streamData.Breakdown3 = string.sub(breakdown3,2)
        end
        SL.Global.StreamData[hash] = streamData
        return true
	else
		streamData.Percent, streamData.AdjustedPercent, streamData.TotalStreams,
		streamData.TotalMeasures, streamData.Breakdown1, streamData.Breakdown2,
		streamData.Breakdown3 = 0, 0, 0, 0, 0, 0, 0
		SL.Global.StreamData[hash] = streamData
        return false
    end
end

--- Returns a table of StreamData given a hash or nil if there's nothing.
--- Converts any fields we weren't able to parse to nil instead of the fake
--- values stored for the sake of the load function.
function GetStreamData(hash)
	if not hash then return nil end
	if not SL.Global.StreamData[hash] then return nil end
	local results = DeepCopy(SL.Global.StreamData[hash])
	if results.PeakNPS == "-1" then results.PeakNPS = nil end
	if results.NpsMode == "-1" then results.NpsMode = nil end
	if not next(results.Density) or #results.Density == 1 then
		results.Density = nil
	end
	--if we don't have total measures then everything will be empty 0s
	if results.TotalMeasures == "0" then
		results.Percent, results.AdjustedPercent, results.TotalStreams,
		results.TotalMeasures, results.Breakdown1, results.Breakdown2,
		results.Breakdown3 = nil, nil, nil, nil, nil, nil, nil
	end
	return results
end

--- Looks through each song currently loaded in Stepmania and checks that we have an entry in the
---  hash lookup. If we don't we make a hash and add it to the lookup. On the first run this will be
--- every song
local function AddToHashLookup()
	local songs = GetSongDirs()
	local newChartsFound = false
	for dir,song in pairs(songs) do
		if not SL.Global.HashLookup[dir] then SL.Global.HashLookup[dir] = {} end
		local allSteps = song.song:GetAllSteps()
		for _,steps in pairs(allSteps) do
			if string.find(SONGMAN:GetSongFromSteps(steps):GetSongFilePath(),".dwi$") then
				Trace("Hashes can't be generated for .DWI files")
				Trace("Could not generate hash for "..dir)
			else
				local stepsType = ToEnumShortString(steps:GetStepsType())
				stepsType = string.lower(stepsType):gsub("_","-")
				local difficulty = ToEnumShortString(steps:GetDifficulty())
				if not SL.Global.HashLookup[dir][difficulty] or not SL.Global.HashLookup[dir][difficulty][stepsType] then
					Trace("Adding hash for "..dir.."("..difficulty..")")
					local hash = GenerateHash(steps,stepsType,difficulty)
					if #hash > 0 then
						Trace("Successly generated hash")
						if not SL.Global.HashLookup[dir][difficulty] then SL.Global.HashLookup[dir][difficulty] = {} end
						SL.Global.HashLookup[dir][difficulty][stepsType] = hash
						newChartsFound = true
						Trace("Adding stream data for "..dir.."("..difficulty..")")
						AddToStreamData(steps, stepsType, difficulty, 16)
					else
						SM("WARNING: Could not generate hash for "..dir)
					end
					coroutine.yield() --resumed in ScreenLoadCustomScores.lua
				end
			end
		end
	end
	if newChartsFound then SaveHashLookup() SaveStreamData() end
end

--- Looks for a file in the "Other" folder of the theme called HashLookup.txt to load from.
--- The file should be tab delimited and each line should be either a song directory
--- or the difficulty, step type, and hash of the next highest song directory
--- Creates a table of the form:
---		--> {song directory
---			-->difficulty
---				-->step type = hash
---							  }
function LoadHashLookup()
	local contents
	local hashLookup = SL.Global.HashLookup
	local path = THEME:GetCurrentThemeDirectory() .. "Other/HashLookup.txt"
	if FILEMAN:DoesFileExist(path) then
		contents = GetFileContents(path)
		local dir
		for line in ivalues(contents) do
			local item = Split(line,"\t")
			if #item == 1 then
				dir = item[1]
				if not hashLookup[dir] then hashLookup[dir] = {} end
			elseif #item == 3 then
				if not hashLookup[dir][item[1]] then hashLookup[dir][item[1]] = {} end
				hashLookup[dir][item[1]][item[2]] = item[3]
			end
		end
	end
	if ThemePrefs.Get("LoadCustomScoresUpfront") then AddToHashLookup() end
end

--- Writes the hash lookup to disk.
function SaveHashLookup()
	local path = THEME:GetCurrentThemeDirectory() .. "Other/HashLookup.txt"
	if SL.Global.HashLookup then
		-- create a generic RageFile that we'll use to read the contents
		local file = RageFileUtil.CreateRageFile()
		-- the second argument here (the 2) signifies
		-- that we are opening the file in write mode
		if not file:Open(path, 2) then SM("Could not open HashLookup.txt") return end
		for dir,charts in pairs(SL.Global.HashLookup) do
			file:PutLine(dir)
			for diff,stepTypes in pairs(charts) do
				for stepType, hash in pairs(stepTypes) do
					file:PutLine(diff.."\t"..stepType.."\t"..hash)
				end
			end
		end
		file:Close()
		file:destroy()
	end
end

--- Returns a hash for the given steps from the lookup table or nil if none is found.
---@param inputSteps Steps
function GetHash(inputSteps)
	if GAMESTATE:IsCourseMode() then return nil end --TODO: right now this only works for non course stuff
	local song = SONGMAN:GetSongFromSteps(inputSteps)
	local difficulty = ToEnumShortString(inputSteps:GetDifficulty())
	local stepsType = ToEnumShortString(GetStepsType()):gsub("_","-"):lower()
	--if hashes aren't loaded up front there may not be a table.
	if SL.Global.HashLookup[song:GetSongDir()] and
	--if there's a table but we couldn't generate a hash it'll be empty. use next to make sure there's something there
	next(SL.Global.HashLookup[song:GetSongDir()]) and
	SL.Global.HashLookup[song:GetSongDir()][difficulty] then
		return SL.Global.HashLookup[song:GetSongDir()][difficulty][stepsType]
	else
		return nil
	end
end

--- Returns a hash from the lookup table or nil if none is found. Uses the current song/steps for the given player
function GetCurrentHash(player)
	local pn = assert(player,"GetCurrentHash requires a player") and ToEnumShortString(player)
	local song = GAMESTATE:GetCurrentSong()
	local steps = GAMESTATE:GetCurrentSteps(pn)
	local difficulty = ToEnumShortString(steps:GetDifficulty())
	local stepsType = ToEnumShortString(GetStepsType()):gsub("_","-"):lower()
	--if hashes aren't loaded up front there may not be a table.
	if SL.Global.HashLookup[song:GetSongDir()] and
	--if there's a table but we couldn't generate a hash it'll be empty. use next to make sure there's something there
	next(SL.Global.HashLookup[song:GetSongDir()]) and
	SL.Global.HashLookup[song:GetSongDir()][difficulty] then
		return SL.Global.HashLookup[song:GetSongDir()][difficulty][stepsType]
	else
		return nil
	end
end

--- Overwrite the HashLookup table for the current song. Also redo StreamData for the song
--- This is called in ScreenEvaluation Common when GenerateHash doesn't match the HashLookup
--- (indicates that the chart itself was changed while leaving the name/directory alone)
function AddCurrentHash()
	local song = GAMESTATE:GetCurrentSong()
	local dir = song:GetSongDir()
	SL.Global.HashLookup[dir] = {}
	local allSteps = song:GetAllSteps()
	for _,steps in pairs(allSteps) do
		local stepsType = ToEnumShortString(steps:GetStepsType()):gsub("_","-"):lower()
		local difficulty = ToEnumShortString(steps:GetDifficulty())
		if not SL.Global.HashLookup[dir][difficulty] or not SL.Global.HashLookup[dir][difficulty][stepsType] then
			Trace("Adding hash for "..dir.."("..difficulty..")")
			local hash = GenerateHash(steps,stepsType,difficulty)
			if #hash > 0 then
				Trace("Success")
				if not SL.Global.HashLookup[dir][difficulty] then SL.Global.HashLookup[dir][difficulty] = {} end
				SL.Global.HashLookup[dir][difficulty][stepsType] = hash
				Trace("Adding stream data for "..dir.."("..difficulty..")")
				AddToStreamData(steps, stepsType, difficulty, 16)
			end
		end
	end
	SaveHashLookup()
	SaveStreamData()
end

--- Full density tables are saved for the graph but it takes up a lot of space since each measure
--- has a line. Convert the table so consecutive measures of the same density are combined.
--- The result will be something like 5x10.15 indicating 5 consecutive measures of 10.15
local function CompressDensity( t )
	local previous = round(t[1],2)
	local count = 0
	local results = {}
	for density in ivalues(t) do
		local current = round(density,2)
		if current ~= previous then
			table.insert(results,count.."x"..previous)
			count = 1
			previous = current
		else
			count = count + 1
		end
	end
	table.insert(results, count.."x"..previous)
	return results
end


--- Uncompress the density so that each item in the table corresponds to a single measure.
--- Takes the 5x10.15 format from CompressDensity() and undoes it.
local function UncompressDensity( t )
	local results = {}
	for density in ivalues(t) do
		local count, value  = density:match("(%d+)x(%d+.?%d?%d?)")
		for i=1, tonumber(count) do
			table.insert(results,value)
		end
	end
	return results
end

--- Writes the stream data table to disk.
function SaveStreamData()
	Trace("Saving StreamData")
	local path = THEME:GetCurrentThemeDirectory() .. "Other/StreamData.txt"
	if SL.Global.StreamData then
		-- create a generic RageFile that we'll use to read the contents
		local file = RageFileUtil.CreateRageFile()
		-- the second argument here (the 2) signifies
		-- that we are opening the file in write mode
		if not file:Open(path, 2) then SM("Could not open StreamData.txt") return end
		for hash,data in pairs(SL.Global.StreamData) do
			file:PutLine(data.Name.."\t"..data.Difficulty.."\t"..data.StepsType.."\t"..hash)
			file:PutLine(
				data.PeakNPS.."\t"..data.NpsMode.."\t"..data.Percent.."\t"..
				data.AdjustedPercent.."\t"..data.TotalStreams.."\t"..
				data.TotalMeasures.."\t"..data.Breakdown1.."\t"..
				data.Breakdown2.."\t"..data.Breakdown3
			)
			file:PutLine(table.concat(CompressDensity(data.Density), " "))
		end
		file:Close()
		file:destroy()
	end
end

local function ParseLoad(results, input)
	local name, difficulty, stepsType, hash = unpack(Split(input[1], "\t"))
	if not results[hash] then results[hash] = {} end
	results[hash].Name = name
	results[hash].Difficulty = difficulty
	results[hash].StepsType = stepsType

	results[hash].PeakNPS, results[hash].NpsMode, results[hash].Percent,
	results[hash].AdjustedPercent, results[hash].TotalStreams,
	results[hash].TotalMeasures, results[hash].Breakdown1, results[hash].Breakdown2,
	results[hash].Breakdown3 = unpack(Split(input[2],"\t"))

	results[hash].Density = UncompressDensity(Split(input[3]," "))
	--return results
end

function LoadStreamData()
	local contents
	local streamData = {}
	local path = THEME:GetCurrentThemeDirectory() .. "Other/StreamData.txt"
	if FILEMAN:DoesFileExist(path) then
		contents = GetFileContents(path)
		for i = 0, (#contents / 3) - 1 do
			local index = (i * 3) + 1
			ParseLoad(streamData,{contents[index],contents[index+1],contents[index+2]})
		end
		SL.Global.StreamData = streamData
	end
end

--- Check if the NpsMode for a song is 1.25, 1.5, 1.75, or 2x higher than the display bpm.
--- If it is, return the multiplier so we can use 16th stream equivalent numbers.
function GetNoteQuantization(steps)
	local bpm = steps:GetDisplayBpms()[2]
	local hash = GetHash(steps)
	local streamData = hash and GetStreamData(hash) or nil
	if not streamData or not streamData.NpsMode then return 1 end

	local convert = {}
	convert["1.25"] = bpm * 1.25
	convert["1.5"] = bpm * 1.5
	convert["1.75"] = bpm * 1.75
	convert["2"] = bpm * 2
	if streamData.NpsMode then
		for k,v in pairs(convert) do
			if math.abs( (streamData.NpsMode * 240 / 16) - v) < 1 then
				return tonumber(k)
			end
		end
	end
	return 1
end