local player = GAMESTATE:GetMasterPlayerNumber()

local fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false
local trackHeld = SL[ToEnumShortString(player)].ActiveModifiers.MissBecauseHeld
-- sequential_offsets gathered in ./BGAnimations/ScreenGameplay overlay/JudgmentOffsetTracking.lua
local sequential_offsets = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].sequential_offsets
local ordered_offsets = {}

-- heldTimes gathered in PerColumnJudgmentTracking (if track held misses is turned on)
local ordered_heldTimes, ordered_streamHeldTimes
if trackHeld then
	ordered_heldTimes = {}
	local heldTimes = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].heldTimes
	for button,times in pairs(heldTimes) do
		for item in ivalues(times) do
			local toInsert = DeepCopy(item)
			toInsert[#toInsert+1] = button
			table.insert(ordered_heldTimes,toInsert)
		end
	end
	table.sort(ordered_heldTimes, function(k1,k2) return tonumber(k1[1]) < tonumber(k2[1]) end)
end

-- ---------------------------------------------
-- if players have disabled W4 or W4+W5, there will be a smaller pool
-- of judgments that could have possibly been earned
local worst_window = PREFSMAN:GetPreference("TimingWindowSecondsW5")
local windows = SL.Global.ActiveModifiers.TimingWindows
for i=5,1,-1 do
	if windows[i] then
		worst_window = PREFSMAN:GetPreference("TimingWindowSecondsW"..i)
		break
	end
end

local CurrentSecond, TimingWindow
for t in ivalues(sequential_offsets) do
	CurrentSecond = t[1]
	Offset = t[2]

	if Offset ~= "Miss" then
		CurrentSecond = CurrentSecond - Offset
		TimingWindow = DetermineTimingWindow(Offset)
		if fapping then
			if math.abs(Offset) > SL.Global.TimingWindowSecondsW0 * PREFSMAN:GetPreference("TimingWindowScale") + SL.Preferences[SL.Global.GameMode]["TimingWindowAdd"] then
				TimingWindow = TimingWindow + 1
			end
		end
		ordered_offsets[#ordered_offsets+1] = {Time = CurrentSecond, Judgment = TimingWindow, Offset = Offset}
	else
		CurrentSecond = CurrentSecond - worst_window
		ordered_offsets[#ordered_offsets+1] = {Time = CurrentSecond, Judgment = "Miss"}
	end
end
table.sort(ordered_offsets, function(k1,k2) return tonumber(k1.Time) < tonumber(k2.Time) end)

-- add which foot got which judgment and if it was early or late
-- also make a table of the stream times to check against heldTimes
local streamTimes = {}
local footBreakdown = {left = {}, right = {} }
footBreakdown.left["left"] = {}
footBreakdown.left["down"] = {}
footBreakdown.left["up"] = {}
footBreakdown.left["right"] = {}
footBreakdown.right["left"] = {}
footBreakdown.right["down"] = {}
footBreakdown.right["up"] = {}
footBreakdown.right["right"] = {}

local streaming = false
for i, value in ipairs(ordered_offsets) do
	local footStats = SL[ToEnumShortString(player)]["ParsedSteps"][i]
	--check if we should add this to per foot breakdown
	if footStats.Foot and footStats.Stream == true and footStats.TechType ~= "Jump" then
		--check if we should consider this for stream
		--TODO for now we don't care about length of stream - something to consider for the future
		if not streaming then
			streaming = true
			streamTimes[#streamTimes+1] = { {value.Time-worst_window, i } }
		end
		--add to per foot breakdown
		if footBreakdown[footStats.Foot][footStats.Note][value.Judgment] then
			footBreakdown[footStats.Foot][footStats.Note][value.Judgment].count = footBreakdown[footStats.Foot][footStats.Note][value.Judgment].count + 1
			if value.Offset and value.Offset < 0 then
				footBreakdown[footStats.Foot][footStats.Note][value.Judgment].early = footBreakdown[footStats.Foot][footStats.Note][value.Judgment].early + 1
			end
		else
			footBreakdown[footStats.Foot][footStats.Note][value.Judgment] = {count = 1, early = 0}
			if value.Offset and value.Offset < 0 then footBreakdown[footStats.Foot][footStats.Note][value.Judgment].early = 1 end
		end
	elseif not footStats.Stream then
		if streaming then
			-- a stream section just ended so figure out if we should add it to our time tables
			-- we cut off the last two notes because they may get held on purpose so if the stream
			-- isn't at least three notes long than don't count it.
			streaming = false
			if i > 3 then
				local prevFootStats = SL[ToEnumShortString(player)]["ParsedSteps"][i-3]
				if prevFootStats.Stream == true then
					table.insert(streamTimes[#streamTimes], {value.Time+worst_window, i - 3})
				else
					table.remove(streamTimes,#streamTimes)
				end
			end
		end
	end
end
-- if last note was stream then figure out if we need to add an end time or remove the section
if #streamTimes[#streamTimes] == 1 then
	if #ordered_offsets > 3 then
		local prevFootStats = SL[ToEnumShortString(player)]["ParsedSteps"][#ordered_offsets-3]
		if prevFootStats.Stream == true then
			table.insert(streamTimes[#streamTimes], {ordered_offsets[#ordered_offsets-3].Time+worst_window,#ordered_offsets-3} )
		else
			table.remove(streamTimes,#streamTimes)
		end
	end
end

if trackHeld then
	ordered_streamHeldTimes = {}
	local startNote = 1
	for streamTime in ivalues(streamTimes) do
		local start = streamTime[1][1]
		local finish = streamTime[2][1]
		for i = startNote, #ordered_heldTimes do
			if ordered_heldTimes[i][1] > finish then startNote = i break end
			if ordered_heldTimes[i][1] > start then ordered_streamHeldTimes[#ordered_streamHeldTimes+1] = DeepCopy(ordered_heldTimes[i]) end
		end
	end
end

-- change to an indexed table for ease of use with Arrows.lua
local convertedFootBreakdown = {}
convertedFootBreakdown["left"] = {
	footBreakdown.left.left,
	footBreakdown.left.down,
	footBreakdown.left.up,
	footBreakdown.left.right
}
convertedFootBreakdown["right"] = {
	footBreakdown.right.left,
	footBreakdown.right.down,
	footBreakdown.right.up,
	footBreakdown.right.right
}

local af = Def.ActorFrame{
    Name="Analysis",
    GetFootBreakdownCommand = function(self)
        return convertedFootBreakdown, ordered_offsets, ordered_heldTimes, ordered_streamHeldTimes
    end,
}

return af