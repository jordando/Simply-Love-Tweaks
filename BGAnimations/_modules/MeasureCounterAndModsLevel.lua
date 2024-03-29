local startTime, endTime

return function(SongNumberInCourse)
	startTime = GetTimeSinceStart() - SL.Global.TimeAtSessionStart
	if SL.Global.Debug then  Trace("Running MeasureCounterAndModsLevel") end
	for player in ivalues(GAMESTATE:GetHumanPlayers()) do
		-- get the PlayerOptions string for any human players and store it now
		-- we'll retrieve it the next time ScreenSelectMusic loads and re-apply those same mods
		-- in this way, we can override the effects of songs that forced modifiers during gameplay
		-- the old-school (ie. ITG) way of GAMESTATE:ApplyGameCommand()
		local pn = ToEnumShortString(player)
		SL[pn].PlayerOptionsString = GAMESTATE:GetPlayerState(player):GetPlayerOptionsString("ModsLevel_Preferred")
		-- If measure counter or battle statistics is on then we need
		-- parse the chart. If measure counter is off but battle statistics
		-- is on then just use 16 notes per measure as the cutoff of stream
		local mods = SL[pn].ActiveModifiers
		if mods.MeasureCounter and (mods.MeasureCounter ~= "None" or (mods.MeasureCounter == "None" and mods.DataVisualizations=="Battle Statistics")) then
			local song_dir, steps
			if GAMESTATE:GetCurrentSong() or GAMESTATE:IsCourseMode() then --if it's not these then we're not currently on a song
				if GAMESTATE:IsCourseMode() then
					local trail = GAMESTATE:GetCurrentTrail(player):GetTrailEntries()[SongNumberInCourse+1]
					song_dir = trail:GetSong():GetSongDir()
					steps = trail:GetSteps()
				else
					song_dir = GAMESTATE:GetCurrentSong():GetSongDir()
					steps = GAMESTATE:GetCurrentSteps(player)
				end

				local steps_type = ToEnumShortString( steps:GetStepsType() ):gsub("_", "-"):lower()
				local difficulty = ToEnumShortString( steps:GetDifficulty() )
				local npm = mods.MeasureCounter ~= "None" and mods.MeasureCounter:match("%d+") or 16
				local notes_per_measure = tonumber(npm)
				local threshold_to_be_stream = 2

				-- if any of these don't match what we're currently looking for...
				if SL[pn].Streams.SongDir ~= song_dir or SL[pn].Streams.StepsType ~= steps_type or SL[pn].Streams.Difficulty ~= difficulty then
					-- ...then parse the simfile, given the current parameters
					SL[pn].Streams.Measures = GetStreams(steps, steps_type, difficulty, notes_per_measure, threshold_to_be_stream)
					-- and set these so we can check again next time.
					SL[pn].Streams.SongDir = song_dir
					SL[pn].Streams.StepsType = steps_type
					SL[pn].Streams.Difficulty = difficulty
				end
				-- if we have measures (which means the stream was parsed) then we can get breakdowns and stuff
				if SL[pn].Streams.Measures then
					--if we don't have anything in the measures table that means there's no stream
					--set some totals to let PaneDisplay know we parsed successfully then don't
					--bother with everything else
					if not next(SL[pn].Streams.Measures) then
						SL[pn].Streams.TotalMeasures = 0
						SL[pn].Streams.TotalStreams = 0
						return
					end
					local lastSequence = #SL[pn].Streams.Measures
					local streamsTable = SL[pn].Streams
					local totalStreams = 0
					local previousSequence = 0
					local segments = 0
					local breakdown = "" --breakdown tries to display the full streams including rest measures
					local breakdown2 = "" --breakdown2 tries to display the streams without rest measures
					local breakdown3 = "" --breakdown3 combines streams that would normally be separated with a -
					for _, sequence in ipairs(streamsTable.Measures) do
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
					local totalMeasures = SL[pn].Streams.Measures[lastSequence].streamEnd
					SL[pn].Streams.TotalMeasures = totalMeasures
					SL[pn].Streams.TotalStreams = totalStreams
					SL[pn].Streams.Segments = segments
					SL[pn].Streams.Breakdown1 = breakdown
					if totalStreams ~= 0 then
						local percent = totalStreams / totalMeasures
						percent = math.floor(percent*100)
						SL[pn].Streams.Percent = percent
						local extraMeasures = 0
						if streamsTable.Measures[1].isBreak then
							extraMeasures = streamsTable.Measures[1].streamEnd - streamsTable.Measures[1].streamStart
						end
						if streamsTable.Measures[#streamsTable.Measures].isBreak then
							extraMeasures = extraMeasures + totalMeasures - streamsTable.Measures[lastSequence].streamStart
						end
						if extraMeasures > 0 then
							local adjustedPercent = totalStreams / (totalMeasures - extraMeasures)
							adjustedPercent = math.floor(adjustedPercent*100)
							SL[pn].Streams.AdjustedPercent = adjustedPercent
						else
							SL[pn].Streams.AdjustedPercent = percent
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
						SL[pn].Streams.Breakdown2 = string.sub(breakdown2,2)
						SL[pn].Streams.Breakdown3 = string.sub(breakdown3,2)
					end
				end
			end
		end
	end
	endTime = GetTimeSinceStart() - SL.Global.TimeAtSessionStart
	if SL.Global.Debug then Trace("Finish MeasureCounterAndModsLevel") end
	if SL.Global.Debug then Trace("Runtime: "..endTime - startTime) end
end