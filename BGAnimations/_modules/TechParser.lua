local doublestep
local crossover
local footswitch
local jumpstream
local parsedSteps
local ambiguousStartPosition
local ambiguousDoublestepPosition

local debug = false
local safe = true --if there are no warps or negative bpms we can easily calculate time at beat manually
local bpms
local stops

local function GetBeatAtTime(beat, bpmTable, stopsTable)
    local cur_bpm = bpmTable[1][2] --initializes to whatever the song starts at
    local cur_beat = 0
    local bpm_index = 0
    local stop_index = 0
    local cur_time = 0
    local finalBeat = beat

    while bpm_index + 1 < #bpmTable and bpmTable[bpm_index + 1][1] < finalBeat do
        cur_time = cur_time + 60.0/cur_bpm * (bpmTable[bpm_index + 1][1] - cur_beat)
        bpm_index = bpm_index + 1
        cur_beat = bpmTable[bpm_index][1]
        cur_bpm = bpmTable[bpm_index][2]
    end
    -- Add all the stops strictly before the this beat since the last row
    -- we've evaluated.
    while stop_index + 1 < #stopsTable and stopsTable[stop_index + 1][1] < finalBeat do
        cur_time = cur_time + stopsTable[stop_index + 1][2]
        stop_index = stop_index + 1
     end

     cur_time = cur_time + 60.0/cur_bpm * (finalBeat - cur_beat)

     --Use milliseconds
     return cur_time
end

local function ParseTech(lines)
    local chart = {}
	for line in lines:gmatch("[^\r\n]+") do
		chart[#chart+1] = line
    end
    --TODO: for now this only works for master player
    local player = GAMESTATE:GetMasterPlayerNumber()
    local pn = ToEnumShortString(player)
    local peak = GAMESTATE:Env()[pn.."PeakNPS"]
    if not peak then return false end
    if GAMESTATE:GetCurrentSteps(player) ~= GAMESTATE:Env()[pn.."CurrentSteps"] then
        SM("peak doesn't match up!")
        SM({GAMESTATE:GetCurrentSteps(player),GAMESTATE:Env()[pn.."CurrentSteps"]})
    end
    if debug then Trace("Peak is:") end
    if debug then Trace(peak) end
    local timingData = GAMESTATE:GetCurrentSteps(player):GetTimingData()
    if timingData:HasWarps() or timingData:HasNegativeBPMs() then
        safe = false
    else
        bpms = timingData:GetBPMsAndTimes(true)
        stops = timingData:GetStops(true)
    end
    local peakTimeBetweenLines = round((1/peak) * 2,5)
    local beatBetweenLines = 0
    local beat = {old = 0, new = 0}
    local linesInMeasure
    local timeSinceLastNote = 0
    local measure = 0
    local checkingPattern = false
    local note
    local ambiguousStart --nil if no, int i: the line where the ambiguity starts otherwise
    local potentialFootswitch --nil if no, int i: the line of the second step in the potential footswitch otherwise
    local conversion = {"left","down","up","right"}
    local i = 1
    local currentFoot = {right = nil, left = nil}
    parsedSteps = {}
    doublestep, crossover, footswitch, jumpstream = 0, 0, 0, 0
    ambiguousStartPosition, ambiguousDoublestepPosition = 0, 0
    currentFoot.SetrightFoot = function(panel) currentFoot.right = panel currentFoot.left = nil end
    currentFoot.SetleftFoot = function(panel) currentFoot.left = panel currentFoot.right = nil end

    local validSteps = {right = {}, left = {}}
    validSteps.right = {
        left={left=false,down=true,up=true,right=true},
        down={left=false,down=false,up=true,right=true},
        up={left=false,down=true,up=false,right=true},
        right={left=false,down=true,up=true,right=false},
    }
    validSteps.left = {
        left={left=false,down=true,up=true,right=false},
        down={left=true,down=false,up=true,right=false},
        up={left=true,down=true,up=false,right=false},
        right={left=true,down=true,up=true,right=false},
    }

    --- Returns number of lines in a measure. Input is the line with the , preceding a measure
    local function GetLinesInMeasure(i)
        local linesInMeasure = 0
        for line = i + 1, #chart do
            if (chart[line]:match("^[,;]%s*")) then
                return linesInMeasure
            else
                linesInMeasure = linesInMeasure + 1
            end
        end
        return linesInMeasure --not sure if every chart will have a ; at the end of the last measure
    end

    --- Returns the time between lines based on the current bpm and linesInMeasure rounded to five decimal places
    local function GetTimeBetweenLines()
        local raw
        if safe then
            raw = GetBeatAtTime(beat.new,bpms,stops) - GetBeatAtTime(beat.old,bpms,stops)
        else
             raw = timingData:GetElapsedTimeFromBeat(beat.new) - timingData:GetElapsedTimeFromBeat(beat.old)
        end
        
        return round(raw,5)
    end

    local function GetBeatBetweenLines()
        return 4 / linesInMeasure
    end

    --- A note can be in position 1,2,3,4 corresponding to Left, Down, Up, Right
    --- We're only looking at normal notes for now
    local function GetNote(line)
        note = conversion[line:find(1)]
    end

    --- Returns the foot that's currently on a panel
    local function GetPreviousFoot()
        return currentFoot.left and "left" or "right"
    end

    --- Returns the foot that's not on a panel
    local function GetNextFoot()
        return currentFoot.left and "right" or "left"
    end

    local function ReverseFeet(position, footswitch)
        for x=position,#parsedSteps do
             parsedSteps[x].Foot = parsedSteps[x].Foot == "left" and "right" or "left"
        end
        if footswitch then parsedSteps[position].TechType = "footswitch" end
    end
    ---Figures out if the next foot is a crossover, doublestep, footswitch, or normal
    local function CheckNextFoot(foot)
        local previousFoot = GetPreviousFoot()
        local techType
        if currentFoot[previousFoot] == note then
            techType = "doublestep"
            doublestep = doublestep + 1
            ambiguousDoublestepPosition = #parsedSteps+1
            potentialFootswitch = i
            if debug then Trace("Potential footswitch at line "..i) end
            if debug then Trace("Doublestep. Keeping "..previousFoot.." on "..note) end
        else
            --validSteps is a table of what panels [foot] can hit depending on where the [previousFoot] is 
            if validSteps[foot][currentFoot[previousFoot]][note] then
                techType = "none"
            else
            --if we hit a crossover
                if potentialFootswitch or ambiguousStart then
                    -- if there's a doublestep we were unsure about and we get to a crossover we assume
                    -- the player was supposed to footswitch to avoid the crossover.
                    if potentialFootswitch then
                        footswitch = footswitch + 1
                        doublestep = doublestep - 1
                        potentialFootswitch = nil
                        ReverseFeet(ambiguousDoublestepPosition, true)
                        if debug then Trace("Footswitch: switching feet and erasing Doublestep") end
                    -- if the pattern started on up or down we default to left but sometimes that leads to
                    -- a ton of crossovers if we were supposed to start right. assume the player was supposed
                    -- to start with right
                    elseif ambiguousStart then
                        ambiguousStart = nil
                        ReverseFeet(ambiguousStartPosition)
                        if debug then Trace("AmbiguousStart: switching feet") end
                    end
                    -- switch the current feet (as if we had done the footswitch or right start) and try again
                    currentFoot["Set"..foot.."Foot"](currentFoot[previousFoot])
                    return CheckNextFoot(previousFoot)
                end
                -- if there were no possible footswitches or ambiguous starts we could try then it's just a
                -- crossover
                crossover = crossover + 1
                techType = "crossover"
                if debug then Trace("This is a crossover") end
            end
        end
        if techType ~= "doublestep" then
            currentFoot["Set"..foot.."Foot"](note)
            if debug then Trace("Moving "..foot.." to "..note) end
        end
        return techType
    end

    local function BeginNewSegment()
        if debug then Trace("New Pattern") end
        potentialFootswitch = nil
        checkingPattern = true
        -- (probably wrongly) assume we never purposefully start in a crossover so
        -- left note start with left foot and right note with right
        if note == "left" or note == "right" then
            if debug then Trace("Starting with "..note.." foot".." on "..note) end
            currentFoot["Set"..note.."Foot"](note)
        -- if we're starting with up or down it's ambiguous so just default to left. mark that there was an
        -- ambiguous start in case we later find we could avoid a crossover by starting right.
        else
            if debug then Trace("Ambiguous, starting with left foot on "..note.." (saving line "..i..")") end
            currentFoot.SetleftFoot(note)
            ambiguousStart = i
            ambiguousStartPosition = #parsedSteps+1
            if debug then Trace("ambiguousStart - "..ambiguousStart) end
        end
    end

    if debug then Trace("Begin parsing chart") end
    if debug then Trace("Peak to check against is:") end
    if debug then Trace(peakTimeBetweenLines) end
    linesInMeasure = GetLinesInMeasure(0)
    beatBetweenLines = GetBeatBetweenLines()
    --since we're keeping track of where streams are we may need to retroactively classify the first
    --step in a stream as stream since normally it wouldn't be considered as the time since the previous
    --note is high
    local possibleStart = 0

    while i < #chart+1 do
        -- If we hit a comma or a semi-colon, then we've hit the end of our measure
        -- For the upcoming measure, calculate how much of a beat each line represents
        -- (Each measure is 4 beats evenly divided by the number of lines in the measure)
        if (chart[i]:match("^[,;]%s*")) then
            measure = measure + 1
            if debug then Trace("New Measure: "..measure) end
            if debug then Trace("Beat is: "..beat.new) end
            linesInMeasure = GetLinesInMeasure(i)
            beatBetweenLines = GetBeatBetweenLines()
        else
            -- If we see a 1 (tap), 2 (start of hold), or 4 (start of roll) there's a note we're interested in
            if chart[i]:match("[124]") then
                timeSinceLastNote = GetTimeBetweenLines()
                beat.old = beat.new
                if debug then Trace("Time since last note is: "..timeSinceLastNote) end
                if debug then Trace("(Beat "..beat.old..")") end
                --Ignore anything that's not a step (end of holds, fakes, mines, lifts) and convert all steps to taps
                local sanitizedLine = chart[i]:gsub( "[3MKLF]", "0"):gsub("[24]","1")
                -- we only care about patterns if they're greater than half the peak speed
                -- (if the chart peaks at 200bpm 16ths then 8th note crossovers are kinda whatever)
                if timeSinceLastNote >= peakTimeBetweenLines then
                    if debug then Trace("Time since last note is: "..timeSinceLastNote.." which is greater than "..peakTimeBetweenLines) end
                    checkingPattern = false
                    if debug then Trace("resetting ambiguousStart because of time") end
                    ambiguousStart = nil
                end
                -- there's a new note so reset timeSinceLastNote
                timeSinceLastNote = 0
                -- ignore jumps/hands for now regarding tech so if there's a single tap note
                -- we'll check for crossovers/doublesteps
                if select(2, string.gsub(sanitizedLine, "0", "")) == 3 then
                    GetNote(sanitizedLine)
                    if debug then Trace("Note is: "..note.. "(Line "..i..")") end
                    --if we're not currently checking a pattern then pick a foot to start with
                    if not checkingPattern then
                        if debug then Trace("Begin new segment") end
                        possibleStart = #parsedSteps+1
                        BeginNewSegment()
                        parsedSteps[#parsedSteps+1] = {Stream = false, Note = note, Foot = GetPreviousFoot(), TechType = "none"}
                    --if we're in the middle of a pattern then check to see what the next step is like
                    else
                        --the note before this was the actual start of the stream
                        if possibleStart > 0 then
                            parsedSteps[possibleStart].Stream = true
                        end
                        local techType = CheckNextFoot(GetNextFoot())
                        parsedSteps[#parsedSteps+1] = {Stream = checkingPattern,Foot = GetPreviousFoot(), TechType = techType, Note = note}
                    end
                else
                    if debug then Trace("Jump") end
                    parsedSteps[#parsedSteps+1] = {Stream = checkingPattern,Note = sanitizedLine, TechType = "Jump"}
                    if checkingPattern then jumpstream = jumpstream + 1 end
                end
            end
            beat.new = beat.new + beatBetweenLines
        end
        i = i + 1
    end
    return true
end

local function NormalizeFloatDigits(param)
	-- V2, uses string.format to round all the decimals to 3 decimal places.
	local function NormalizeDecimal(decimal)
		-- Remove any control characters from the string to prevent conversion failures.
		decimal = decimal:gsub("%c", "")
		return string.format("%.3f", tonumber(decimal))
	end
	local paramParts = {}
	for beat_bpm in param:gmatch('[^,]+') do
		local beat, bpm = beat_bpm:match('(.+)=(.+)')
		table.insert(paramParts, NormalizeDecimal(beat) .. '=' .. NormalizeDecimal(bpm))
	end
	return table.concat(paramParts, ',')
end

return function (steps, stepsType, difficulty)
        local msdFile = ParseMsdFile(steps)
        if #msdFile == 0 then return nil	end
        local songBpms = ''
        local stepBpms
        local stepData = false --for SSC. until we get to the first 'Notes' anything we find is for the overall song
        local sscSteps = ''
        local sscDifficulty = ''
        local allNotes = {}
        for value in ivalues(msdFile) do
            if value[1] == 'BPMS' then
                --if we get to BPMS before we see a chart than it's the song bpms
                --in SM files we expect to only see BPMS once but SSC can have a different
                --bpms for each chart. If an SSC chart doesn't have a bpms itself it will
                --fall back on the song bpms so we need to keep track of what that is
                if not stepData then songBpms = NormalizeFloatDigits(value[2])
                else stepBpms = NormalizeFloatDigits(value[2]) end
            --in SSCs each chart needs NOTEDATA or Stepmania won't even try to load it
            --so if we see NOTEDATA we know we're past the overall values and any new
            --bpms values we see will be chart specific
            --https://github.com/stepmania/stepmania/blob/master/src/NotesLoaderSSC.cpp#L933
            elseif value[1] == 'NOTEDATA' then stepData = true
            elseif value[1] == 'STEPSTYPE' then sscSteps = value[2]
            elseif value[1] == 'DIFFICULTY' then sscDifficulty = value[2]
            elseif value[1] == 'NOTES' then
                --SSC files don't have 7 fields in notes so it would normally fail to generate hashes
                --We can make a temporary table mimicking what it would look like in a .SM file
                if string.find(SONGMAN:GetSongFromSteps(steps):GetSongFilePath(),".ssc$") then
                    local sscTable = {}
                    sscTable[2] = sscSteps
                    sscTable[4] = sscDifficulty
                    sscTable[7] = value[2]
                    for i = 1,4 do table.insert(sscTable,i) end --filler so #notes >= 7
                    --To determine Bpms for SSC files first we check if there's a steps specific value.
                    --If no, then we check for an overall song value. If that doesn't exist either,
                    --Stepmania sets the Bpms to 60. SM files will also get set to 60 if there's no overall Bpms
                    --https://github.com/stepmania/stepmania/blob/master/src/TimingData.cpp#L1198
                    sscTable['bpms'] = stepBpms and stepBpms or songBpms and songBpms or '0.000=60.000'
                    stepBpms = nil --reset the stepBpms. If the next chart doesn't have bpms then we'll use the songBpms
                    table.insert(allNotes,sscTable)
                else
                    value['bpms'] = songBpms and songBpms or '0.000=60.000'
                    table.insert(allNotes, value)
                end
            end
        end
        
        local success = false
        for notes in ivalues(allNotes) do
            -- StepMania considers NOTES sections with greater than 7 sections valid.
            -- https://github.com/stepmania/stepmania/blob/master/src/NotesLoaderSM.cpp#L1072-L1079
            if #notes >= 7 and notes[2] == stepsType and difficulty == ToEnumShortString(OldStyleStringToDifficulty(notes[4])) then
                if debug then Trace("PARSE TEST") end
                success = ParseTech(notes[7])
            end
        end

        if success then return {
            doublestep = doublestep,
            crossover = crossover,
            footswitch = footswitch,
            jumpstream = jumpstream,
            parsedSteps = parsedSteps
        }
        else return nil end
    end