local player = ...

local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)
local IsUltraWide = (GetScreenAspectRatio() > 21/9)

-- how wide (in visual pixels) the total time is, used to offset the label
local total_width

local text_table, marquee_index

local x_pos = 60
-- -----------------------------------------------------------------------

local af = Def.ActorFrame{}
af.InitCommand=function(self)
	self:x(WideScale(150,70) * (player==PLAYER_1 and -1 or 1))
	self:y(28)
	self:zoom(.8)

	if NoteFieldIsCentered and IsUsingWideScreen() then
		self:x( 200 * (player==PLAYER_1 and -1 or 1) )
	end

	-- flip alignment when ultrawide and both players joined
	if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
		self:x(self:GetX() * -1)
	end
end

-- -----------------------------------------------------------------------
-- Group label
af[#af+1] = LoadFont("Common Normal")..{
    InitCommand=function(self)
        self:settext(player == PLAYER_1 and "Location:" or ":Group")
		self:y(40)
		self:halign(PlayerNumber:Reverse()[player]):vertalign(bottom)

		-- flip alignment and adjust for smaller pane size
		-- when ultrawide and both players joined
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
			self:x(50 * (player==PLAYER_1 and -1 or 1))
		end
	end,
}

-- Group name
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand=function(self)
		self:halign(PlayerNumber:Reverse()[player]):vertalign(bottom)
		self:zoom(0.833):y(40)
		-- flip alignment and adjust for smaller pane size
		-- when ultrawide and both players joined
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
			self:x(50 * (player==PLAYER_1 and 1 or -1))
		end
	end,
	OnCommand=function(self)
		self:x(x_pos * (player==PLAYER_1 and 1 or -1))
		self:settext(GAMESTATE:GetCurrentSong():GetGroupName())
		-- flip offset when ultrawide and both players
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:x(104 * (player==PLAYER_1 and -1 or 1))
		end
	end,
	CurrentSongChangedMessageCommand=function(self,params)
		self:settext(GAMESTATE:GetCurrentSong():GetGroupName())
	end,
}

-- -----------------------------------------------------------------------
-- artist label
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand=function(self)
		self:y(20)
		self:halign(PlayerNumber:Reverse()[player]):vertalign(bottom)
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
			self:x(50 * (player==PLAYER_1 and -1 or 1))
		end

		self:settext(player == PLAYER_1 and "Target:" or ":Target") --TODO Language
	end
}

-- artist name
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand=function(self)
		self:zoom(0.833)
		self:halign(PlayerNumber:Reverse()[player]):vertalign(bottom)
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
		end
	end,
	OnCommand=function(self)
		self:x(x_pos * (player==PLAYER_1 and 1 or -1))
		self:y(20)
		self:settext(GAMESTATE:GetCurrentSong():GetDisplayArtist())
		-- flip offset when ultrawide and both players
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:x(104 * (player==PLAYER_1 and -1 or 1))
		end
	end,
	CurrentSongChangedMessageCommand=function(self,params)
		self:settext(GAMESTATE:GetCurrentSong():GetDisplayArtist())
	end,
}

-- -----------------------------------------------------------------------
-- Chart label
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand=function(self)
		self:settext(player == PLAYER_1 and "Info:" or ":Info") --TODO: language
		self:halign(PlayerNumber:Reverse()[player]):vertalign(bottom)

		-- flip alignment and adjust for smaller pane size
		-- when ultrawide and both players joined
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
			self:x(50 * (player==PLAYER_1 and -1 or 1))
		end
	end,
}

-- Stepartist text
af[#af+1] = LoadFont("Common Normal")..{
	InitCommand=function(self)
		self:horizalign(left):x(75):zoom(0.833):maxwidth(300)
		self:halign(PlayerNumber:Reverse()[player]):vertalign(bottom)
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
		end
	end,
	OnCommand=function(self)
		self:x(x_pos * (player==PLAYER_1 and 1 or -1))
		-- flip offset when ultrawide and both players
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:x(104 * (player==PLAYER_1 and -1 or 1))
		end
	end,
	CurrentSongChangedMessageCommand=function(self)
		local SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
		local StepsOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSteps(player)

		-- always stop tweening when steps change in case a MarqueeCommand is queued
		self:stoptweening()

		if SongOrCourse and StepsOrCourse then
			text_table = GetStepsCredit(player)
			marquee_index = 0

			-- only queue a marquee if there are things in the text_table to display
			if #text_table > 0 then
				self:queuecommand("Marquee")
			else
				-- no credit information was specified in the simfile for this stepchart, so just set to an empty string
				self:settext("")
			end
		else
			-- there wasn't a song/course or a steps object, so the MusicWheel is probably hovering
			-- on a group title, which means we want to set the stepartist text to an empty string for now
			self:settext("")
		end
	end,
	MarqueeCommand=function(self)
		-- increment the marquee_index, and keep it in bounds
		marquee_index = (marquee_index % #text_table) + 1
		-- retrieve the text we want to display
		local text = text_table[marquee_index]

		-- set this BitmapText actor to display that text
		self:settext( text )

		-- account for the possibility that emojis shouldn't be diffused to Color.Black
		DiffuseEmojis(self, text)

		-- sleep 2 seconds before queueing the next Marquee command to do this again
		if #text_table > 1 then
			self:sleep(2):queuecommand("Marquee")
		end
	end,
	OffCommand=function(self) self:stoptweening() end
}
-- -----------------------------------------------------------------------

return af