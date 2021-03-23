--This pane is for per foot breakdowns

local args = ...
local player = args.player
local noteAnalysis = args.noteAnalysis

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
local footBreakdown, ordered_offsets, heldTimes = noteAnalysis.GetFootBreakdownCommand()

af[#af+1] = LoadActor("./Percentage.lua", {player = player, side = "left"})..{InitCommand=function(self) self:visible(true) end}
af[#af+1] = LoadActor("./JudgmentLabels.lua", {player = player, side = "left"})..{InitCommand=function(self) self:visible(true) end}
af[#af+1] = LoadActor("./Arrows.lua", {player = player, side = "left", footBreakdown = footBreakdown})..{InitCommand=function(self) self:visible(true) end}

local xOffset = IsUsingWideScreen() and WideScale(105,0) or 0

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
				:x(_screen.cx - 275 + xOffset)
				:zoomto(5, 180)
		end
	},
	LoadActor("./Percentage.lua", {player = player, side = "right"})..{
		InitCommand=function(self) self:visible(true):x(_screen.cx - 2 + xOffset) end
	},
	LoadActor("./JudgmentLabels.lua", {player = PLAYER_1, side = "right"})..{
		InitCommand=function(self) self:visible(true):x(_screen.cx+155 + xOffset) end
	},
	LoadActor("./Arrows.lua", {player = player, side = "right", footBreakdown = footBreakdown})..{
		InitCommand=function(self) self:visible(true):x(_screen.cx-305 + xOffset) end
	}
}

if heldTimes then
	af[#af+1] = LoadActor("./HeldAnalysis.lua", {footBreakdown, ordered_offsets, heldTimes})
end

return af

