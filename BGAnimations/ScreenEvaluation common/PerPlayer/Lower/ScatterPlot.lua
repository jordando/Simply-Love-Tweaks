-- if we're in CourseMode, bail now
-- the normal LifeMeter graph (Def.GraphDisplay) will be drawn
if GAMESTATE:IsCourseMode() then return end

-- arguments passed in from Graphs.lua
local args = ...
local player = args.player

if not GAMESTATE:IsHumanPlayer(player) then return end

--if we have FA+ tracking enabled then we need to add an extra timing window and shrink everything
local fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false

local GraphWidth  = THEME:GetMetric("GraphDisplay", "BodyWidth")
local GraphHeight = THEME:GetMetric("GraphDisplay", "BodyHeight")

-- sequential_offsets gathered in ./BGAnimations/ScreenGameplay overlay/JudgmentOffsetTracking.lua
local sequential_offsets = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].sequential_offsets

-- ---------------------------------------------
-- if players have disabled W4 or W4+W5, there will be a smaller pool
-- of judgments that could have possibly been earned
local worst_window = PREFSMAN:GetPreference("TimingWindowSecondsW5")
local windows = DeepCopy(SL.Global.ActiveModifiers.TimingWindows)
for i=5,1,-1 do
	if windows[i] then
		worst_window = PREFSMAN:GetPreference("TimingWindowSecondsW"..i)
		break
	end
end

-- ---------------------------------------------

local colors = {}
for w=5,1,-1 do
	if windows[w]==true then
		colors[w] = DeepCopy(SL.JudgmentColors[SL.Global.GameMode][w])
	else
		colors[w] = DeepCopy(colors[w+1] or SL.JudgmentColors[SL.Global.GameMode][w+1])
	end
end

if fapping then
	table.insert(colors,2,Color.White)
	table.insert(windows,2,windows[1])
end

--TODO this is duplicated in NoteAnalysis. refactor
local CurrentSecond, TimingWindow
local ordered_offsets = {}
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

-- TotalSeconds is used in scaling the x-coordinates of the AMV's vertices
local FirstSecond = SL.Global.GameMode == "Experiment" and 0 or GAMESTATE:GetCurrentSong():GetFirstSecond()
local TotalSeconds = GAMESTATE:GetCurrentSong():GetLastSecond()

-- variables that will be used and re-used in the loop while calculating the AMV's vertices
local x, y, c, r, g, b

-- ---------------------------------------------
-- will color everything in the scatterplot normally if no parameters are passed,
-- otherwise it will only color what's being looked at in static replay
local setVerts = function(specific)
	local footStats
	if specific then footStats = SL[ToEnumShortString(player)]["ParsedSteps"] end
	local verts = {}
	for i,t in pairs(ordered_offsets) do
		-- pad the right end because the time measured seems to lag a little...
		x = scale(t.Time, FirstSecond, TotalSeconds + 0.05, 0, GraphWidth)

		if t.Judgment ~= "Miss" then
			y = scale(t.Offset, worst_window, -worst_window, 0, GraphHeight)

			-- get the appropriate color from the global SL table
			c = colors[t.Judgment]
			-- get the red, green, and blue values from that color
			r = c[1]
			g = c[2]
			b = c[3]
			-- we may have to color it gray if we're looking at specific steps
			if specific and specific.Judgment ~= 6 then --TODO: check if this breaks with judgments off
				if not footStats[i].Stream
				or specific.Judgment ~= t.Judgment
				or specific.Arrow ~= footStats[i].Note
				or (footStats[i].Foot and footStats[i].Foot ~= specific.Foot) then
					r,g,b = .7,.7,.7
				end
			end

			-- insert four datapoints into the verts tables, effectively generating a single quadrilateral
			-- top left,  top right,  bottom right,  bottom left
			table.insert( verts, {{x,y,0}, {r,g,b,0.666}} )
			table.insert( verts, {{x+1.5,y,0}, {r,g,b,0.666}} )
			table.insert( verts, {{x+1.5,y+1.5,0}, {r,g,b,0.666}} )
			table.insert( verts, {{x,y+1.5,0}, {r,g,b,0.666}} )
		else
			-- else, a miss should be a quadrilateral that is the height of the entire graph and red
			local color = color("#ff000077")
			if specific and specific.Judgment == 6 then
				if not footStats[i].Stream
				or specific.Arrow ~= footStats[i].Note
				or (footStats[i].Foot and footStats[i].Foot ~= specific.Foot) then
					color = {.7,.7,.7,0.666}
				end
			end
			table.insert( verts, {{x, 0, 0}, color} )
			table.insert( verts, {{x+1, 0, 0}, color} )
			table.insert( verts, {{x+1, GraphHeight, 0}, color} )
			table.insert( verts, {{x, GraphHeight, 0}, color} )
		end
	end
	return verts
end

-- the scatter plot will use an ActorMultiVertex in "Quads" mode
-- this is more efficient than drawing n Def.Quads (one for each judgment)
-- because the entire AMV will be a single Actor rather than n Actors with n unique Draw() calls.
local amv = Def.ActorMultiVertex{
	InitCommand=function(self) self:x(-GraphWidth/2) end,
	OnCommand=function(self)
		self:SetDrawState({Mode="DrawMode_Quads"})
			:SetVertices(setVerts())
	end,
	AnalyzeJudgmentMessageCommand=function(self, params)
		self:SetVertices(setVerts(params))
	end,
	EndPopupMessageCommand=function(self)
		self:SetVertices(setVerts())
	end,
	EndAnalyzeJudgmentMessageCommand=function(self)
		self:SetVertices(setVerts())
	end,
}
--points to the individual point on the scatterplot when looking at the static replay
local cursor = Def.Sprite{
	Name="cursor",
	Texture=THEME:GetPathG("FF","finger.png"),
	InitCommand=function(self) self:zoom(.15):xy(-GraphWidth/2,GraphHeight/2):visible(false) end,
	UpdateScatterplotMessageCommand=function(self, time)
		self:smooth(.1)
		self:x(scale(time[1].Time, FirstSecond, TotalSeconds + 0.05, -GraphWidth/2, GraphWidth/2) - 19)
		if time[1].Offset then
			self:y(scale(time[1].Offset,worst_window, -worst_window, 0, GraphHeight) + 8)
		else
			self:y(scale(0,worst_window, -worst_window, 0, GraphHeight) + 8)
		end
	end,
	AnalyzeJudgmentMessageCommand=function(self)
		self:diffusealpha(0):visible(true):smooth(.1):diffusealpha(1)
	end,
	EndPopupMessageCommand=function(self)
		self:smooth(.2):diffusealpha(0):visible(false)
	end,
}

local af = Def.ActorFrame{
	amv,
	cursor
}

return af
