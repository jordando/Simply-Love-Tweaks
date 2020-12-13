return function(SongNumberInCourse)
	for player in ivalues(GAMESTATE:GetHumanPlayers()) do

		-- get the PlayerOptions string for any human players and store it now
		-- we'll retrieve it the next time ScreenSelectMusic loads and re-apply those same mods
		-- in this way, we can override the effects of songs that forced modifiers during gameplay
		-- the old-school (ie. ITG) way of GAMESTATE:ApplyGameCommand()
		local pn = ToEnumShortString(player)
		SL[pn].PlayerOptionsString = GAMESTATE:GetPlayerState(player):GetPlayerOptionsString("ModsLevel_Preferred")

		-- Check if MeasureCounter is turned on.  We may need to parse the chart.
		local mods = SL[pn].ActiveModifiers
		if mods.MeasureCounter and mods.MeasureCounter ~= "None" then
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
				local notes_per_measure = tonumber(mods.MeasureCounter:match("%d+"))
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
					SL[pn].Streams.TotalStreams = totalStreams
					SL[pn].Streams.Segments = segments
					SL[pn].Streams.Breakdown1 = breakdown
					if totalStreams ~= 0 then
						SL[pn].Streams.TotalMeasures = streamsTable.Measures[lastSequence].streamEnd
						local percent = totalStreams / streamsTable.Measures[lastSequence].streamEnd
						percent = math.floor(percent*100)
						SL[pn].Streams.Percent = percent
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
end