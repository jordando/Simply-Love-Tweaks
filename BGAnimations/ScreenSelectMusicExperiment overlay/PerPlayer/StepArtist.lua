local player = ...
local pn = ToEnumShortString(player)
local p = #GAMESTATE:GetHumanPlayers() == 1 and 0 or PlayerNumber:Reverse()[player]
local text_table, marquee_index

return Def.ActorFrame{
	Name="StepArtistAF_" .. pn,

	-- song and course changes
	OnCommand=function(self) self:queuecommand("StepsHaveChanged") end,
	CurrentSongChangedMessageCommand=function(self, params) if params.song then self:queuecommand("StepsHaveChanged") end end,
	CurrentCourseChangedMessageCommand=function(self) self:queuecommand("StepsHaveChanged") end,

	PlayerJoinedMessageCommand=function(self, params)
		p = PlayerNumber:Reverse()[player]
		self:queuecommand("Appear" .. pn)
	end,
	PlayerUnjoinedMessageCommand=function(self, params)
		if params.Player == player then
			self:ease(0.5, 275):addy(scale(p,0,1,1,-1) * 30):diffusealpha(0)
		end
	end,

	-- depending on the value of pn, this will either become
	-- an AppearP1Command or an AppearP2Command when the screen initializes
	["Appear"..pn.."Command"]=function(self)
		self:visible(true):halign( p ):ease(0.5, 275)
		if #GAMESTATE:GetHumanPlayers() ~= 2 then
			self:y(_screen.cy + 14)
			self:x( _screen.cx - (IsUsingWideScreen() and WideScale(250,356) or 346))
		elseif player == PLAYER_1 then
			self:y(_screen.cy + 14)
			self:x( _screen.cx - (IsUsingWideScreen() and 356 or 346))

		elseif player == PLAYER_2 then
			self:y(_screen.cy + 127)
			self:x( _screen.cx - 210)
		end
	end,

	InitCommand=function(self)
		self:visible(false)
		if GAMESTATE:IsHumanPlayer(player) then
			self:queuecommand("Appear" .. pn)
		end
	end,

	-- colored background quad
	Def.Quad{
		Name="BackgroundQuad",
		InitCommand=function(self) self:zoomto(175, _screen.h/28):x(113) end,
		StepsHaveChangedMessageCommand=function(self)
			local StepsOrTrail = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player) or GAMESTATE:GetCurrentSteps(player)

			if StepsOrTrail then
				local difficulty = StepsOrTrail:GetDifficulty()
				self:diffuse( DifficultyColor(difficulty) )
			else
				self:diffuse( PlayerColor(player) )
			end
		end
	},

	--STEPS label
	LoadFont("Common Normal")..{
		OnCommand=function(self) self:diffuse(0,0,0,1):horizalign(left):x(30):settext(Screen.String("STEPS")) end
	},

	--stepartist text
	LoadFont("Common Normal")..{
		InitCommand=function(self) self:diffuse(color("#1e282f")):horizalign(left):x(75):maxwidth(115) end,
		StepsHaveChangedMessageCommand=function(self)
			-- don't bother if not a human player
			if not GAMESTATE:IsHumanPlayer(player) then return end
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
			if text then
				-- set this BitmapText actor to display that text
				self:settext( text )

				-- account for the possibility that emojis shouldn't be diffused to Color.Black
				DiffuseEmojis(self, text)
			end
			-- sleep 2 seconds before queueing the next Marquee command to do this again
			if #text_table > 1 then
				self:sleep(2):queuecommand("Marquee")
			end
		end,
		OffCommand=function(self) self:stoptweening() end
	}
}