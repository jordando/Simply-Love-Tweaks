local function gen_vertices(player, width, height, upColor, lowColor, peak, density)
	local Song, Steps
	local first_step_has_occurred = false

	if GAMESTATE:IsCourseMode() then
		local TrailEntry = GAMESTATE:GetCurrentTrail(player):GetTrailEntry(GAMESTATE:GetCourseSongIndex())
		Steps = TrailEntry:GetSteps()
		Song = TrailEntry:GetSong()
	else
		Steps = GAMESTATE:GetCurrentSteps(player)
		Song = GAMESTATE:GetCurrentSong()
	end
	--if we have peakNPS and density given use those instead of parsing
	local PeakNPS, NPSperMeasure
	if peak and density then
		PeakNPS = peak
		NPSperMeasure = density
	else
		PeakNPS, NPSperMeasure = GetNPSperMeasure(Song, Steps) end

	-- store the PeakNPS in GAMESTATE:Env()[pn.."PeakNPS"] in case both players are joined
	-- their charts may have different peak densities, and if they both want histograms,
	-- we'll need to be able to compare densities and scale one of the graphs vertically
	GAMESTATE:Env()[ToEnumShortString(player).."PeakNPS"] = PeakNPS
	GAMESTATE:Env()[ToEnumShortString(player).."CurrentSteps"] = Steps

	-- broadcast this for any other actors on the current screen that rely on knowing the peak nps
	MESSAGEMAN:Broadcast("PeakNPSUpdated", {PeakNPS=PeakNPS})
	local verts = {}
	local x, y, t

	if (PeakNPS and NPSperMeasure and #NPSperMeasure > 1) then

		local TimingData = Steps:GetTimingData()
		local FirstSecond = math.min(TimingData:GetElapsedTimeFromBeat(0), 0)
		local LastSecond = Song:GetLastSecond()

		-- magic numbers obtained from Photoshop's Eyedrop tool in rgba percentage form (0 to 1)
		local graphColor = {Blue = {}, Yellow = {}}	 
		graphColor.Blue[1]= {0,    0.678, 0.753, 1} --blue
		graphColor.Blue[2]= {0.51, 0,     0.631, 1} --purple
		graphColor.Yellow[1]= {0.968, 0.953, 0.2, 1} --yellow
		graphColor.Yellow[2]= {0.863, 0.353, 0.2, 1} --orange
		
		local lowerColor, upperColor, chosenColor
		if upColor and lowColor then
			lowerColor = lowColor
			upperColor = upColor
		else
			chosenColor = ThemePrefs.Get("DensityGraphColor")

			lowerColor=graphColor[chosenColor][1]
			upperColor=graphColor[chosenColor][2]
		end

		local upper
		for i, nps in ipairs(NPSperMeasure) do

			if tonumber(nps) > 0 then first_step_has_occurred = true end

			if first_step_has_occurred then
				-- i will represent the current measure number but will be 1 larger than
				-- it should be (measures in SM start at 0; indexed Lua tables start at 1)
				-- subtract 1 from i now to get the actual measure number to calculate time
				t = TimingData:GetElapsedTimeFromBeat((i-1)*4)

				x = scale(t, FirstSecond, LastSecond, 0, width)
				y = round(-1 * scale(nps, 0, PeakNPS, 0, height))

				-- if the height of this measure is the same as the previous two measures
				-- we don't need to add two more points (bottom and top) to the verts table,
				-- we can just "extend" the previous two points by updating their x position
				-- to that of the current measure.  For songs with long streams, this should
				-- cut down on the overall size of the verts table significantly.
				if #verts > 2 and verts[#verts][1][2] == y and verts[#verts-2][1][2] == y then
					verts[#verts][1][1] = x
					verts[#verts-1][1][1] = x
				else
					-- lerp_color() is a global function defined by the SM engine that takes three arguments:
					--    a float between [0,1]
					--    color1
					--    color2
					-- and returns a color that has been linearly interpolated by that percent between the two colors provided
					-- for example, lerp_color(0.5, yellow, orange) will return the color that is halfway between yellow and orange
					upper = lerp_color(math.abs(y/height), lowerColor, upperColor )

					verts[#verts+1] = {{x, 0, 0}, lowerColor} -- bottom of graph (blue)
					verts[#verts+1] = {{x, y, 0}, upper}  -- top of graph (somewhere between blue and purple)
				end
			end
		end
	end

	return verts
end

-- FIXME: add inline comments explaining the intent/purpose of this code
function interpolate_vert(v1, v2, offset)
	local ratio = (offset - v1[1][1]) / (v2[1][1] - v1[1][1])
	local y = v1[1][2] * (1 - ratio) + v2[1][2] * ratio
	local color = lerp_color(ratio, v1[2], v2[2])

	return {{offset, y, 0}, color}
end


function NPS_Histogram(player, width, height, upColor, lowColor)
	local amv = Def.ActorMultiVertex{
		Name="DensityGraph_AMV",
		InitCommand=function(self)
			self:SetDrawState({Mode="DrawMode_QuadStrip"})
		end,
		CurrentSongChangedMessageCommand=function(self)
			-- we've reached a new song, so reset the vertices for the density graph
			-- this will occur at the start of each new song in CourseMode
			-- and at the start of "normal" gameplay
			if not SL.Global.ExperimentScreen then
				self:playcommand("SetDensity")
			end
		end,
		LessLagMessageCommand=function(self)
			--ScreenSelectMusic density graph should only display if we're not in course mode
			if GAMESTATE:IsCourseMode() then return end
			if GAMESTATE:IsHumanPlayer(player) and GAMESTATE:GetCurrentSong() then
				--check to see if we have the stream info for this song saved already
				local hash = GetCurrentHash(player)
				local streams = GetStreamData(hash)
				if streams and streams.PeakNPS and streams.Density then
					self:playcommand("SetDensity", {streams.PeakNPS, streams.Density})
				else
					self:playcommand("SetDensity")
				end
			end
		end,
		SetDensityCommand=function(self, params)
			local verts
			if params then
				verts = gen_vertices(player, width, height, upColor, lowColor, params[1], params[2])
			else
				verts = gen_vertices(player, width, height, upColor, lowColor)
			end
			self:SetNumVertices(#verts):SetVertices(verts)
		end
	}

	return amv
end


function Scrolling_NPS_Histogram(player, width, height)
	local verts, visible_verts
	local left_idx, right_idx

	local amv = Def.ActorMultiVertex{
		Name="ScrollingDensityGraph_AMV",
		InitCommand=function(self)
			self:SetDrawState({Mode="DrawMode_QuadStrip"})
		end,
		UpdateCommand=function(self)
			--This is called by [ScreenGameplay underlay/PerPlayer/StepStatistics/DensityGraph.lua]
			--Don't need to scale or scroll if we're on SelectMusicExperiment
			if not SL.Global.ExperimentScreen then
				if visible_verts ~= nil then
					self:SetNumVertices(#visible_verts):SetVertices(visible_verts)
					visible_verts = nil
				end
			end
		end,

		LoadCurrentSong=function(self, scaled_width)
			--This is called by [ScreenGameplay underlay/PerPlayer/StepStatistics/DensityGraph.lua]
			--Don't need to scale or scroll if we're on SelectMusicExperiment
			if not SL.Global.ExperimentScreen then
				verts = gen_vertices(player, scaled_width, height)
				left_idx = 1
				right_idx = 2
				self:SetScrollOffset(0)
			end
		end,
		SetScrollOffset=function(self, offset)
			local left_offset = offset
			local right_offset = offset + width

			for i = left_idx, #verts, 2 do
				if verts[i][1][1] >= left_offset then
					left_idx = i
					break
				end
			end

			for i = right_idx, #verts, 2 do
				if verts[i][1][1] <= right_offset then
					right_idx = i
				else
					break
				end
			end

			visible_verts = {unpack(verts, left_idx, right_idx)}

			if left_idx > 1 then
				local prev1, prev2, cur1, cur2 = unpack(verts, left_idx-2, left_idx+1)
				table.insert(visible_verts, 1, interpolate_vert(prev1, cur1, left_offset))
				table.insert(visible_verts, 2, interpolate_vert(prev2, cur2, left_offset))
			end

			if right_idx < #verts then
				local cur1, cur2, next1, next2 = unpack(verts, right_idx-1, right_idx+2)
				table.insert(visible_verts, interpolate_vert(cur1, next1, right_offset))
				table.insert(visible_verts, interpolate_vert(cur2, next2, right_offset))
			end
		end
	}

	return amv
end