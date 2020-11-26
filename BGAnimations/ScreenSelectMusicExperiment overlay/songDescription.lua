--expand the box size to make room for a group label if we're not in course mode
local courseOffset
if GAMESTATE:IsCourseMode() then
	courseOffset = 12
else
	courseOffset = 0
end

-- Wheel to display the current tags a song has----------------------------------------
local tagItemMT = LoadActor("./TagItemMT.lua")
local tagItems = setmetatable({disable_wrapping=true}, sick_wheel_mt)
---------------------------------------------------------------------
local t = Def.ActorFrame{
	
	InitCommand=function(self)
		-- A sickwheel to display all the tags the song is part of. TODO: don't really need wheel because we never touch it but don't know how to do dynamic additions to an actor frame
		local toInsert = {}
		for groupName in ivalues(GetGroups("Tag")) do
			table.insert(toInsert, {displayname = groupName})
		end
		tagItems:set_info_set(toInsert, 0)
	end,
	OnCommand=function(self)
		self:xy(_screen.cx - (IsUsingWideScreen() and 170 or 165), _screen.cy - 28)
	end,

	-- ----------------------------------------
	-- Actorframe for Artist, BPM, and Song length
	Def.ActorFrame{
		CurrentSongChangedMessageCommand=function(self) self:queuecommand("Set") end,
		CurrentCourseChangedMessageCommand=function(self) self:queuecommand("Set") end,
		CurrentTrailP2ChangedMessageCommand=function(self) self:queuecommand("Set") end,
		UpdateTagsMessageCommand=function(self) self:queuecommand("Set") end, --Called by ./TagMenu/Input when changing the tags.
		-- Update the tags for the current song
		SetCommand = function(self)
			local currentTags = {}
			local song = GAMESTATE:GetCurrentSong()
			if song then --no song if we're on "Close This Folder"
				if GetActiveFilters() then table.insert(currentTags, {displayName = "Filters Active"}) end
				if song:HasSignificantBPMChangesOrStops() then table.insert(currentTags,{displayName = "BPM Changes"}) end
				local tagList = GetTags(song)
				if tagList then
					for tag in ivalues(tagList) do
						table.insert(currentTags,{displayName = tag})
					end
				end
				if #currentTags == 0 then table.insert(currentTags,{displayName = "No Tags Set"}) end
				tagItems:set_info_set(currentTags,0)
			end
		end,
		
		-- background for Artist, BPM, and Song Length
		Def.Quad{
			InitCommand=function(self)
				self:diffuse(color("#1e282f"))
					:zoomto( IsUsingWideScreen() and 320 or 310, 67 - (courseOffset*1.5)) --48 if we're in course mode, 67 in normal mode

				if ThemePrefs.Get("RainbowMode") then
					self:diffusealpha(0.75)
				end
			end
		},

		Def.ActorFrame{

			InitCommand=function(self) self:x(-110) end,

			-- Artist Label
			LoadFont("Common Normal")..{
				InitCommand=function(self)
					local text = GAMESTATE:IsCourseMode() and "NumSongs" or "Artist"
					self:settext( THEME:GetString("SongDescription", text) )
						:horizalign(right):y(-24 + courseOffset) -- -12 in course mode, 24 in normal
						:maxwidth(44)
				end,
				OnCommand=function(self) self:diffuse(0.5,0.5,0.5,1) end
			},

			-- Song Artist
			LoadFont("Common Normal")..{
				InitCommand=function(self) self:horizalign(left):xy(5,-24 + courseOffset):maxwidth(WideScale(225,260)) end,
				SetCommand=function(self)
					if GAMESTATE:IsCourseMode() then
						local course = GAMESTATE:GetCurrentCourse()
						self:settext( course and #course:GetCourseEntries() or "" )
					else
						local song = GAMESTATE:GetCurrentSong()
						self:settext( song and song:GetDisplayArtist() or "" )
					end
				end
			},
			
			-- Song Group Label only matters if you're not in course mode
			LoadFont("Common Normal")..{
				InitCommand=function(self)
					if GAMESTATE:IsCourseMode() then self:settext("")
					else
						self:settext( THEME:GetString("SongDescription", "Group") )
							:horizalign(right):y(-3)
							:maxwidth(44)
					end
				end,
				OnCommand=function(self) self:diffuse(0.5,0.5,0.5,1) end
			},

			-- Song Group only matters if you're not in course mode
			LoadFont("Common Normal")..{
				InitCommand=function(self) self:horizalign(left):xy(5,-3):maxwidth(WideScale(225,260)) end,
				SetCommand=function(self)
					if GAMESTATE:IsCourseMode() then
						self:settext("")
					else
						local song = GAMESTATE:GetCurrentSong()
						if song and song:GetGroupName() then
							self:settext( song:GetGroupName() )
						else
							self:settext("")
						end
					end
				end
			},

			-- BPM Label
			LoadFont("Common Normal")..{
				Text=THEME:GetString("SongDescription", "BPM"),
				InitCommand=function(self)
					self:horizalign(right):y(20 - courseOffset)
						:diffuse(0.5,0.5,0.5,1)
				end
			},

			-- BPM value
			LoadFont("Common Normal")..{
				InitCommand=function(self) self:horizalign(left):xy(5,20 - courseOffset):diffuse(1,1,1,1) end,
				--if songs have split bpms then they may change as we change the difficulty so redo bpm every time steps change
				StepsHaveChangedMessageCommand=function(self) self:queuecommand("Set") end,
				SetCommand=function(self)
					-- if only one player is joined, stringify the DisplayBPMs and return early
					if #GAMESTATE:GetHumanPlayers() == 1 then
						local player = GAMESTATE:GetMasterPlayerNumber()
						-- StringifyDisplayBPMs() is defined in ./Scipts/SL-BPMDisplayHelpers.lua
						self:settext(StringifyDisplayBPMs(player,GAMESTATE:GetCurrentSteps(player)) or ""):zoom(1)
						return
					end
					-- otherwise there is more than one player joined and the possibility of split BPMs
					local p1bpm = StringifyDisplayBPMs(PLAYER_1, GAMESTATE:GetCurrentSteps(PLAYER_1))
					local p2bpm = StringifyDisplayBPMs(PLAYER_2, GAMESTATE:GetCurrentSteps(PLAYER_2))

					-- it's likely that BPM range is the same for both charts
					-- no need to show BPM ranges for both players if so
					if p1bpm == p2bpm then
						self:settext(p1bpm):zoom(1)

					-- different BPM ranges for the two players
					else
						-- show the range for both P1 and P2 split by a newline characters, shrunk slightly to fit the space
						self:settext( "P1 ".. p1bpm .. "\n" .. "P2 " .. p2bpm ):zoom(0.8)
						-- the "P1 " and "P2 " segments of the string should be grey
						self:AddAttribute(0,             {Length=3, Diffuse={0.60,0.60,0.60,1}})
						self:AddAttribute(3+p1bpm:len(), {Length=3, Diffuse={0.60,0.60,0.60,1}})

						if GAMESTATE:IsCourseMode() then
							-- P1 and P2's BPM text in CourseMode is white until I have time to figure CourseMode out
							self:AddAttribute(3,             {Length=p1bpm:len(), Diffuse={1,1,1,1}})
							self:AddAttribute(7+p1bpm:len(), {Length=p2bpm:len(), Diffuse={1,1,1,1}})

						else
							-- P1 and P2's BPM text is the color of their difficulty
							if GAMESTATE:GetCurrentSteps(PLAYER_1) then
								self:AddAttribute(3,             {Length=p1bpm:len(), Diffuse=DifficultyColor(GAMESTATE:GetCurrentSteps(PLAYER_1):GetDifficulty())})
							end
							if GAMESTATE:GetCurrentSteps(PLAYER_2) then
								self:AddAttribute(7+p1bpm:len(), {Length=p2bpm:len(), Diffuse=DifficultyColor(GAMESTATE:GetCurrentSteps(PLAYER_2):GetDifficulty())})
							end
						end
					end
				end
			},

			-- Song Duration Label
			LoadFont("Common Normal")..{
				Text=THEME:GetString("SongDescription", "Length"),
				InitCommand=function(self)
					self:horizalign(right)
						:x(_screen.w/4.5):y(20 - courseOffset)
						:diffuse(0.5,0.5,0.5,1)
				end
			},

			-- Song Duration Value
			LoadFont("Common Normal")..{
				InitCommand=function(self) self:horizalign(left):xy(_screen.w/4.5 + 5, 20 - courseOffset) end,
				SetCommand=function(self)
					local duration

					if GAMESTATE:IsCourseMode() then
						local Players = GAMESTATE:GetHumanPlayers()
						local player = Players[1]
						local trail = GAMESTATE:GetCurrentTrail(player)

						if trail then
							duration = TrailUtil.GetTotalSeconds(trail)
						end
					else
						local song = GAMESTATE:GetCurrentSong()
						if song then
							duration = song:MusicLengthSeconds()
						end
					end


					if duration then
						duration = duration / SL.Global.ActiveModifiers.MusicRate
						if duration == 105.0 then
							-- r21 lol
							self:settext( THEME:GetString("SongDescription", "r21") )
						else
							local hours = 0
							if duration > 3600 then
								hours = math.floor(duration / 3600)
								duration = duration % 3600
							end

							local finalText
							if hours > 0 then
								-- where's HMMSS when you need it?
								finalText = hours .. ":" .. SecondsToMMSS(duration)
							else
								finalText = SecondsToMSS(duration)
							end

							self:settext( finalText )
						end
					else
						self:settext("")
					end
				end
			}
		},

		-- long/marathon version bubble graphic and text
		Def.ActorFrame{
			OnCommand=function(self)
				self:x( IsUsingWideScreen() and 102 or 97 )
			end,
			SetCommand=function(self)
				local song = GAMESTATE:GetCurrentSong()
				self:visible( song and (song:IsLong() or song:IsMarathon()) or false )
			end,

			LoadActor("bubble")..{
				InitCommand=function(self) self:diffuse(GetCurrentColor()):zoom(0.455):y(41-courseOffset) end
			},

			LoadFont("Common Normal")..{
				InitCommand=function(self) self:diffuse(Color.Black):zoom(0.8):y(46-courseOffset) end,
				SetCommand=function(self)
					local song = GAMESTATE:GetCurrentSong()
					if not song then self:settext(""); return end

					if song:IsMarathon() then
						self:settext(THEME:GetString("SongDescription", "IsMarathon"))
					elseif song:IsLong() then
						self:settext(THEME:GetString("SongDescription", "IsLong"))
					else
						self:settext("")
					end
				end
			},
		},	
	}
}
t[#t+1] = tagItems:create_actors( "tagItems", 8, tagItemMT, -210,-48) --TODO get rid of magic numbers

return t
