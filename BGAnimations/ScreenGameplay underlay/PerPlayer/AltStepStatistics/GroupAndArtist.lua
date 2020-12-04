local player = ...

local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)
local IsUltraWide = (GetScreenAspectRatio() > 21/9)

-- how wide (in visual pixels) the total time is, used to offset the label
local total_width

-- -----------------------------------------------------------------------

local af = Def.ActorFrame{}
af.InitCommand=function(self)
	self:x(SL_WideScale(150,202) * (player==PLAYER_1 and -1 or 1))
	self:y(10)

	if NoteFieldIsCentered and IsUsingWideScreen() then
		self:x( 154 * (player==PLAYER_1 and -1 or 1) )
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
        self:settext("Group: ")
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
		self:zoom(0.833)
		-- flip alignment and adjust for smaller pane size
		-- when ultrawide and both players joined
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
			self:x(50 * (player==PLAYER_1 and -1 or 1))
		end
	end,
	OnCommand=function(self)
		if player==PLAYER_1 then
			self:x( 32 + (total_width-28))
		else
			self:x(-32 - (total_width-28))
		end
		self:settext(GAMESTATE:GetCurrentSong():GetGroupName())
		-- flip offset when ultrawide and both players
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			if player==PLAYER_1 then
				self:x(-86 - (total_width-28))
			else
				self:x( 86 + (total_width-28))
			end
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
		self:xy(0,20)
		self:halign(PlayerNumber:Reverse()[player]):vertalign(bottom)
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
			self:x(50 * (player==PLAYER_1 and -1 or 1))
		end

		self:settext("Artist: ")
		total_width = self:GetWidth()
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
		if player==PLAYER_1 then
			self:x(32 + (total_width-28))
		else
			self:x(-32 - (total_width-28))
		end
		self:y(20)
		self:settext(GAMESTATE:GetCurrentSong():GetDisplayArtist())
		-- flip offset when ultrawide and both players
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			if player==PLAYER_1 then
				self:x(-86 - (total_width-28))
			else
				self:x( 86 + (total_width-28))
			end
		end
	end,
	CurrentSongChangedMessageCommand=function(self,params)
		self:settext(GAMESTATE:GetCurrentSong():GetDisplayArtist())
	end,
}

-- -----------------------------------------------------------------------

return af