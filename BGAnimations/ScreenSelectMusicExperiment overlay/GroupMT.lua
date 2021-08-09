local args = ...
local GroupWheel = args[1]
local SongWheel = args[2]
local col = args[3]
local Input = args[4]

local max_chars = 64

local path = "/"..THEME:GetCurrentThemeDirectory().."Graphics/_FallbackBanners/"..ThemePrefs.Get("VisualStyle")
local banner_directory = FILEMAN:DoesFileExist(path) and path or THEME:GetPathG("","_FallbackBanners/Arrows")

local startTime, endTime

function Switch_to_songs(group)
	local group_name = group
	if GAMESTATE:IsCourseMode() then group_name = "Courses" end
	startTime = GetTimeSinceStart() - SL.Global.TimeAtSessionStart
	if SL.Global.Debug then  Trace("Running Switch_to_songs: "..group_name) end
	local songs = GetSongList(group_name)
	if SL.Global.GroupType ~= "Courses" then songs = PruneSongList(songs) end
	if #songs > 0 then --it's possible that filters can cause us to try and enter a group with no songs
		if IsSpecialOrder() then --If we're using a special order than we need to further split the song list
			songs = CreateSpecialSongList(songs)
		end
		songs[#songs+1] = "CloseThisFolder"
		local toAdd = {}
		for k,song in pairs(songs) do
			toAdd[#toAdd+1] = {song = song, index = k}
		end
		local current_song = GAMESTATE:GetCurrentSong() or SL.Global.LastSeenSong
		local index = SL.Global.LastSeenIndex
		if SL.Global.Debug then
			if GAMESTATE:IsCourseMode() then
				Trace("Current course is: "..current_song:GetDisplayFullTitle())
			else
				Trace("Current song is: "..current_song:GetMainTitle())
			end
		end
		--since each song can show up multiple times in special orders we can't rely just on songs being the same
		--however, when we first switch order the indexes won't match up so rather than get a random song we
		--go to the first instance of the song.
		--TODO: jump to correct difficulty
		if IsSpecialOrder()
		and SpecialOrder[SL.Global.LastSeenIndex]
		and GAMESTATE:GetCurrentSong() == SpecialOrder[SL.Global.LastSeenIndex].song then
			index = SL.Global.LastSeenIndex
		else
			for k,song in pairs(songs) do
				if song == current_song then
					index = k
					if SL.Global.Debug then		
						if GAMESTATE:IsCourseMode() then
							Trace("Current course is: "..current_song:GetDisplayFullTitle())
						else
							Trace("Current song is: "..current_song:GetMainTitle())
						end
					end
					break
				end
			end
		end
		if index == nil then index = 1 end --TODO if songs are no longer in a folder then go to groupwheel not songwheel
		SL.Global.DifficultyGroup = group_name
		SL.Global.GradeGroup = group_name
		SongWheel:set_info_set(toAdd, index)
	else
		-- if there are no songs in the current group then switch to the first available group/first song
		-- TODO it should put you on the groupwheel instead
		local groups = PruneGroups(GetGroups())
		-- if there's at least one group then jump in
		if #groups >= 1 then
			Switch_to_songs(groups[1])
		end
	end
	endTime = GetTimeSinceStart() - SL.Global.TimeAtSessionStart
	if SL.Global.Debug then Trace("Finish Switch_to_songs: "..group_name) end
	if SL.Global.Debug then Trace("Runtime: "..endTime - startTime) end
end

local item_mt = {
	__index = {
		create_actors = function(self, name)
			self.name=name

			-- this is a terrible way to do this
			local item_index = name:gsub("item", "")
			self.index = item_index

			local af = Def.ActorFrame{
				Name=name,

				InitCommand=function(subself)
					self.container = subself

					subself:xy(_screen.cx, _screen.cy-100)

					local current_song = GAMESTATE:GetCurrentSong() or SL.Global.LastSeenSong
					if current_song then
						if self.index ~= GroupWheel:get_actor_item_at_focus_pos().index then
							subself:playcommand("LoseFocus"):diffusealpha(0)
						else
							-- position this folder in the header and switch to the songwheel
							subself:playcommand("SlideToTop")
							local starting_group = GetCurrentGroup()
							Switch_to_songs(starting_group)
							MESSAGEMAN:Broadcast("CurrentGroupChanged", {group=self.groupName})
						end
					end
				end,
				OnCommand=function(subself)
					subself:finishtweening()
				end,
				StartCommand=function(subself)
					if self.index == GroupWheel:get_actor_item_at_focus_pos().index then
						-- slide the chosen Actor into place
						subself:queuecommand("SlideToTop")
					else
						-- hide everything else
						subself:linear(0.2):diffusealpha(0)
					end
				end,
				-- if we come straight here because of a search run start to get into songs
				SetSongViaSearchMessageCommand=function(self)
					self:playcommand("Start")
				end,
				-- we're going back to group selection
				-- slide the chosen group Actor back into grid position
				UnhideCommand=function(subself)
					if self.index == GroupWheel:get_actor_item_at_focus_pos().index then
						subself:playcommand("SlideBackIntoGrid")
						MESSAGEMAN:Broadcast("SwitchFocusToGroups")
					else
						subself:sleep(0.25):linear(0.2):diffusealpha(1)
					end
				end,
				GainFocusCommand=function(subself) subself:linear(0.2):zoom(0.8) end,
				LoseFocusCommand=function(subself) subself:linear(0.2):zoom(0.6) end,
				SlideToTopCommand=function(subself)
					subself:linear(0.12):y(28 - 200):zoom(0.35)
					       :linear(0.2 ):x(70 - 25):queuecommand("Switch")
				end,
				SlideBackIntoGridCommand=function(subself)
					subself:linear( 0.2 ):x(_screen.w/1.5 )
						   :linear( 0.12 ):zoom( 0.8 ):y( 0 )
				end,
				SwitchCommand=function(subself) Switch_to_songs(self.groupName) end,

				--card frame
				Def.Sprite{
					Texture=THEME:GetPathG("FF", "CardEdge.png"),
					InitCommand=function(self)
						self:horizalign(left):zoomto(385,85):xy(-68,-15)
					end,
					OnCommand=function(subself)
						if self.index == GroupWheel:get_actor_item_at_focus_pos().index then
							subself:zoomto(926,92):x(-88)
						end
					end,
					SlideToTopCommand=function(subself) subself:sleep(0.2):queuecommand("SlideToTop2") end,
					SlideToTop2Command = function(subself)
						subself:linear(.3):zoomto(926,92):x(-88)
					end,
					SlideBackIntoGridCommand = function(subself)
						subself:zoomto(385,85):x(-68)
					end,
				},
				--blue box behind banner
				Def.Quad{
					InitCommand=function(self)
						self:horizalign(left):zoomto(350,75):xy(-50,-15):diffuseleftedge(color("#23279e")):diffuserightedge(Color.Black)
					end,
					OnCommand=function(subself)
						if self.index == GroupWheel:get_actor_item_at_focus_pos().index then
							subself:zoomto(850,75)
						end
					end,
					SlideToTopCommand=function(subself) subself:sleep(0.3):queuecommand("SlideToTop2") end,
					SlideToTop2Command = function(self)
						self:linear(.2):zoomto(850,75)
					end,
					SlideBackIntoGridCommand = function(self)
						self:zoomto(350,75)
					end,
				},
				
				Def.Sprite{
					Texture=THEME:GetPathG("FF", "SkinnyCard.png"),
					InitCommand=function(self)
						self:zoomto(228,625):xy(1,190):visible(false)
					end,
				},
				-- group banner
				LoadActor(banner_directory.."/banner"..SL.Global.ActiveColorIndex.." (doubleres).png" )..{
					Name="FallbackBanner",
					OnCommand=function(subself) subself:y(-30):setsize(418,164):zoom(0.48) end,
				},

				Def.Banner{
					Name="Banner",
					InitCommand=function(subself) self.banner = subself end,
					OnCommand=function(subself) subself:y(-30):setsize(418,164):zoom(0.48) end,
				},

				-- group title bmt
				Def.BitmapText{
					Font="Common Normal",
					InitCommand=function(subself)
						self.bmt = subself:maxwidth(225)
						subself:_wrapwidthpixels(150):vertspacing(-4):shadowlength(0.5):horizalign(left):xy(125,-18)
					end,
					OnCommand=function(subself)
						if self.index == GroupWheel:get_actor_item_at_focus_pos().index then
							subself:horizalign(left):zoom(3):diffuse(Color.White):_wrapwidthpixels(480):shadowlength(0):playcommand("Untruncate")
						end
					end,
					--when the sort changes we may need to change the group text to whatever it becomes
					GroupTypeChangedMessageCommand=function(subself)
						if self.index == GroupWheel:get_actor_item_at_focus_pos().index and Input.WheelWithFocus ~= GroupWheel and GAMESTATE:GetCurrentSong() and self.groupName then --only if we're not on group wheel
							subself:horizalign(left):zoom(3):diffuse(Color.White):_wrapwidthpixels(480):shadowlength(0):playcommand("Untruncate")
						end
					end,
					UntruncateCommand=function(subself) --group name to display is not necessarily the same so check in SL-SortHelpers
						self.bmt:settext(GetGroupDisplayName(self.groupName)):maxwidth(220)
					end,
					TruncateCommand=function(subself) --group name to display is not necessarily the same so check in SL-SortHelpers
						self.bmt:settext(GetGroupDisplayName(self.groupName)):Truncate(max_chars)
					end,

					GainFocusCommand=function(subself) subself:decelerate(0.33):zoom(1.1) end,
					LoseFocusCommand=function(subself) subself:linear(0.15):zoom(1):diffuse(Color.White) end,

					SlideToTopCommand=function(subself) subself:sleep(0.3):diffuse(Color.White):queuecommand("SlideToTop2") end,
					SlideToTop2Command=function(subself) subself:linear(0.2):zoom(3):_wrapwidthpixels(480):shadowlength(0):playcommand("Untruncate") end,
					SlideBackIntoGridCommand=function(subself) subself:decelerate(0.33):zoom(1.1):diffuse(Color.White):_wrapwidthpixels(150):shadowlength(0.5):playcommand("Truncate") end,
				}
			}

			return af
		end,

		transform = function(self, item_index, num_items, has_focus)

			local offset = item_index - math.floor(num_items/2)
			local zm = scale(math.abs(offset),0,math.floor(num_items/2),0.9,0.05 )
			local ry = offset > 0 and 25 or (offset < 0 and -25 or 0)
			self.container:finishtweening()

			--handle row hiding
			if item_index == 1 or item_index > 12 then
				self.container:visible(false)
			else
				self.container:visible(true)
			end

			-- if we are initializing the screen, the focus starts (should start) on the SongWheel
			-- so we want to position all the folders "behind the scenes", and then call Init
			-- on the group folder with focus so that it is positioned correctly at the top
			if Input.WheelWithFocus ~= GroupWheel then
				--self.container:x( offset * col.w * zm + _screen.cx ):z( -1 * math.abs(offset) ):zoom( zm ):rotationy( ry )
				self.container:y( 70*offset ):x( _screen.w/1.5 )
				if has_focus then self.container:playcommand("Init") end

			-- otherwise, we are performing a normal transform
			else
				if has_focus then
					self.container:playcommand("GainFocus")
					SL.Global.CurrentGroup = self.groupName
					MESSAGEMAN:Broadcast("CurrentGroupChanged", {group=self.groupName})
				else
					self.container:playcommand("LoseFocus")
				end
				--self.container:x( offset * col.w * zm + _screen.cx ):z( -1 * math.abs(offset) ):zoom( zm ):rotationy( ry )
				self.container:y( 70*offset ):x( _screen.w/1.5 )
			end
		end,

		set = function(self, groupName)

			self.groupName = groupName
			-- handle text
			-- group name to display is not necessarily the same so check in SL-GroupHelpers
			self.bmt:settext(GetGroupDisplayName(self.groupName)):Truncate(max_chars)

			-- handle banner
			self.banner:LoadFromSongGroup(self.groupName):playcommand("On")
		end
	}
}

return item_mt