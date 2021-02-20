--This pane is for per foot breakdowns

local args = ...
local player = args.player

local fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false

local af = Def.ActorFrame{
	--Name="Pane6_SideP1",
	InitCommand=function(self)
		self:visible(false)
	end,
	OnCommand=function(self)
		if player == PLAYER_2 then self:x(_screen.cx - 155) end
	end,

	LoadFont("Wendy/_wendy white")..{
		Name="NoShow",
		InitCommand=function(self)
			self:horizalign(0):zoom(0.25):xy( 30, 200)
			if not SL[ToEnumShortString(player)]["ParsedSteps"] then
				self:settext("Unable to parse chart")
			end
		end,
	}
}

--if tech parser isn't turned on we can't get per foot breakdowns
if not SL[ToEnumShortString(player)]["ParsedSteps"] then
	return af
end

-- Pane2 displays per-columnm judgment counts.
-- In "dance" the columns are left, down, up, right.
-- In "pump" the columns are downleft, upleft, center, upright, downright
-- etc.

-- sequential_offsets gathered in ./BGAnimations/ScreenGameplay overlay/JudgmentOffsetTracking.lua
local sequential_offsets = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].sequential_offsets
local ordered_offsets = {}
local heldTimes = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].heldTimes

-- heldTimes gathered in PerColumnJudgmentTracking (if track held misses is turned on)
local ordered_heldTimes = {}
for button,times in pairs(heldTimes) do
	for item in ivalues(times) do
		local toInsert = DeepCopy(item)
		toInsert[#toInsert+1] = button
		table.insert(ordered_heldTimes,toInsert)
	end
end
table.sort(ordered_heldTimes, function(k1,k2) return tonumber(k1[1]) < tonumber(k2[1]) end)

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
    if footStats.Foot and footStats.Stream == true and footStats.TechType ~= "Jump"
    and (footStats.Pattern == "repeated step" or footStats.Pattern == "candle D>U" or footStats.Pattern == "candle U>D")
    and (value.Judgment == 4 or value.Judgment == 5 or value.Judgment == "Miss")
    then
        --add to per foot breakdown
        local tempJudgment = value.Judgment
        if footStats.Pattern == "repeated step" then
            if tempJudgment ~= "Miss" then tempJudgment = tempJudgment - 3
            else tempJudgment = 3 end
        end
		if footBreakdown[footStats.Foot][footStats.Note][tempJudgment] then
			footBreakdown[footStats.Foot][footStats.Note][tempJudgment].count = footBreakdown[footStats.Foot][footStats.Note][tempJudgment].count + 1
			if value.Offset and value.Offset < 0 then
				footBreakdown[footStats.Foot][footStats.Note][tempJudgment].early = footBreakdown[footStats.Foot][footStats.Note][tempJudgment].early + 1
			end
		else
			footBreakdown[footStats.Foot][footStats.Note][tempJudgment] = {count = 1, early = 0}
			if value.Offset and value.Offset < 0 then footBreakdown[footStats.Foot][footStats.Note][tempJudgment].early = 1 end
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

af[#af+1] = LoadActor("./Percentage.lua", {player = player, side = "left"})..{InitCommand=function(self) self:visible(true) end}
af[#af+1] = LoadActor("./Percentage.lua", {player = player, side = "right"})..{InitCommand=function(self) self:visible(true):x(_screen.cx - 2) end}
af[#af+1] = LoadActor("./Arrows.lua", {player = player, side = "left", footBreakdown = convertedFootBreakdown})..{InitCommand=function(self) self:visible(true) end}
af[#af+1] = LoadActor("./Arrows.lua", {player = player, side = "right", footBreakdown = convertedFootBreakdown})..{InitCommand=function(self) self:visible(true):x(_screen.cx-305) end}
af[#af+1] = LoadActor("./JudgmentLabels.lua", {player = player, side = "left"})..{InitCommand=function(self) self:visible(true) end}
af[#af+1] = LoadActor("./JudgmentLabels.lua", {player = PLAYER_1, side = "right"})..{InitCommand=function(self) self:visible(true):x(_screen.cx+155) end}

af[#af+1] = Def.ActorFrame{
	InitCommand=function(self)
		if not IsUsingWideScreen() then
			self:addx(WideScale(107,0))
		end
	end,
	Def.Quad{
		InitCommand=function(self)
			self:diffuse( color("#101519") )
				:y(_screen.cy + 34 )
				:x(_screen.cx - 275)
				:zoomto(5, 180)
		end
	},
}

return af

