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

-- ---------------------------------------------
-- if players have disabled W4 or W4+W5, there will be a smaller pool
-- of judgments that could have possibly been earned
local worst_window = PREFSMAN:GetPreference("TimingWindowSecondsW5")
local windows = SL.Global.ActiveModifiers.TimingWindows
for i=5,1 do
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
			if math.abs(Offset) > SL.Preferences[SL.Global.GameMode]["TimingWindowSecondsW0"] * PREFSMAN:GetPreference("TimingWindowScale") + SL.Preferences[SL.Global.GameMode]["TimingWindowAdd"] then
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

local footBreakdown = {left = {}, right = {} }
footBreakdown.left["left"] = {}
footBreakdown.left["down"] = {}
footBreakdown.left["up"] = {}
footBreakdown.left["right"] = {}
footBreakdown.right["left"] = {}
footBreakdown.right["down"] = {}
footBreakdown.right["up"] = {}
footBreakdown.right["right"] = {}
for i, value in ipairs(ordered_offsets) do
	local footStats = SL[ToEnumShortString(player)]["ParsedSteps"][i]
	if footStats.Foot and footStats.Stream == true and footStats.TechType ~= "Jump" then
		if footBreakdown[footStats.Foot][footStats.Note][value.Judgment] then
			footBreakdown[footStats.Foot][footStats.Note][value.Judgment].count = footBreakdown[footStats.Foot][footStats.Note][value.Judgment].count + 1
			if value.Offset and value.Offset < 0 then 
				footBreakdown[footStats.Foot][footStats.Note][value.Judgment].early = footBreakdown[footStats.Foot][footStats.Note][value.Judgment].early + 1
			end
		else
			footBreakdown[footStats.Foot][footStats.Note][value.Judgment] = {count = 1, early = 0}
			if value.Offset and value.Offset < 0 then footBreakdown[footStats.Foot][footStats.Note][value.Judgment].early = 1 end
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
af[#af+1] = LoadActor("./JudgmentLabels.lua", {player = player, side = "left"})..{InitCommand=function(self) self:visible(true) end}
af[#af+1] = LoadActor("./Arrows.lua", {player = player, side = "left", footBreakdown = convertedFootBreakdown})..{InitCommand=function(self) self:visible(true) end}

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
	LoadActor("./Percentage.lua", {player = player, side = "right"})..{InitCommand=function(self) self:visible(true):x(_screen.cx - 2) end},
	LoadActor("./JudgmentLabels.lua", {player = PLAYER_1, side = "right"})..{InitCommand=function(self) self:visible(true):x(_screen.cx+155) end},
	LoadActor("./Arrows.lua", {player = player, side = "right", footBreakdown = convertedFootBreakdown})..{InitCommand=function(self) self:visible(true):x(_screen.cx-305) end}
}

return af

