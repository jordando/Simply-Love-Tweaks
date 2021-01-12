local player = ...
local pn = ToEnumShortString(player)
local rv
local zoom_factor = WideScale(0.8, 0.85)

local dataX_col1 = WideScale(-75, -96)
local highscoreX = WideScale(56, 80)
local row_height = 154


local GetNameAndScoreAndDate = function(profile)
	local song = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()
	local steps = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player) or GAMESTATE:GetCurrentSteps(player)
	local score = ""
	local name = ""
	local scoredate = ""
	if profile and song and steps then
		local scorelist = profile:GetHighScoreList(song, steps)
		local scores = scorelist:GetHighScores()
		local topscore = scores[1]

		if topscore then
			score = string.format("%.2f%%", topscore:GetPercentDP() * 100.0)
			name = topscore:GetName()
			scoredate = topscore:GetDate()
		else
			score = string.format("%.2f%%", 0)
			name = "????"
			scoredate = ""
		end
	end

	return score, name, scoredate
end

local af =
	Def.ActorFrame {
	InitCommand = function(self)
		self:visible(GAMESTATE:IsHumanPlayer(player))
		--TODO for now if there's only one player their pane display is on the left. We only put things on the right if two people are joined
	end,
	PlayerJoinedMessageCommand = function(self)
		self:visible(true)
	end,
	-- These playcommand("Set") need to apply to the ENTIRE panedisplay
	-- (all its children) so declare each here
	OnCommand = function(self) self:queuecommand("Set") end,
	CurrentCourseChangedMessageCommand = function(self) self:queuecommand("Set") end,
	StepsHaveChangedMessageCommand = function(self) self:queuecommand("Set") end,
	SetCommand = function(self)
		-- Don't bother if not a human player
		if not GAMESTATE:IsHumanPlayer(player) then return end
		local player_score, player_date, first_pass, last_played, times_played
		if GAMESTATE:GetCurrentSong() then --if there's no song there won't be a hash
			local hash = GetCurrentHash(player)
			if hash and SL[pn].Scores[hash] then
				local scores = GetScores(player, hash)
				if scores then
					player_score = FormatPercentScore(scores[1].score)
					player_date = FormatDate(Split(scores[1].dateTime)[1])
				else
					player_score = string.format("%.2f%%", 0)
					player_date = "Never"
				end
				first_pass = FormatDate(Split(SL[pn].Scores[hash].FirstPass)[1])
				last_played = FormatDate(Split(SL[pn].Scores[hash].LastPlayed)[1])
				times_played = SL[pn].Scores[hash].NumTimesPlayed
			else
				player_score, _ , player_date = GetNameAndScoreAndDate(PROFILEMAN:GetProfile(player))
				--if there's a player_score/date then the song is in stats.xml but we can't make a hash for whatever reason
				if #player_date > 0 then
					player_date = FormatDate(Split(player_date)[1])
					--TODO last_played and times_played are both in stats but i don't feel like parsing it just for that.
					first_pass = "Unknown"
					last_played = "Unknown"
					times_played = "Unknown"
				--otherwise it's a song we haven't played yet so
				else
					first_pass = "Never"
					player_date = "Never Played"
					last_played = "Never"
					times_played = "0"
				end
			end
			self:GetChild("LastPlayedDate"):settext("Last Played: "..last_played)
			self:GetChild("PlayerHighScore"):settext("High Score: "..player_score)
			self:GetChild("PlayerHighScoreDate"):settext("Date: "..player_date)
			self:GetChild("FirstPass"):settext("First Pass: "..first_pass)
			self:GetChild("TimesPlayed"):settext("Times Played: "..times_played)

			local SongOrCourse = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()
			if not SongOrCourse then
				self:settext("?")
				return
			end

			local steps = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
			if steps then
				rv = steps:GetRadarValues(player)
				local val = rv:GetValue("RadarCategory_TapsAndHolds")

				-- the engine will return -1 as the value for autogenerated content; show a question mark instead if so
				self:GetChild("Steps"):settext("Steps: "..(val >= 0 and val or "?"))
			else
				self:GetChild("Steps"):settext("Steps: ")
			end
		end
	end
}

af[#af+1] = LoadActor( THEME:GetPathG("FF","CardEdge.png") )..{
	InitCommand=function(self)
		self:diffuse(Color.White)
		self:zoomto(450, 450)
		self:MaskDest():xy(0,350)
		--self:visible(false)
	end,
}

-- colored background for chart statistics
af[#af + 1] = Def.Quad {
	Name = "BackgroundQuad",
	InitCommand = function(self)
		self:zoomto(_screen.w / 2 - 18, _screen.h / 8 + 1):y(_screen.h / 2 - 67)
	end,
	SetCommand = function(self)
		if GAMESTATE:IsHumanPlayer(player) then
			local StepsOrTrail = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player) or GAMESTATE:GetCurrentSteps(player)

			if StepsOrTrail then
				local difficulty = StepsOrTrail:GetDifficulty()
				self:diffuse(DifficultyColor(difficulty))
			else
				self:diffuse(PlayerColor(player))
			end
			self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
		end
	end
}


-- chart difficulty meter
af[#af + 1] =
	LoadFont("Wendy/_wendy small") ..
	{
		Name = "DifficultyMeter",
		InitCommand = function(self)
			self:horizalign(right):diffuse(Color.White)
				:xy(_screen.w / 4 - 10, _screen.h / 2 - 65):queuecommand("Set")
		end,
		SetCommand = function(self)
			local SongOrCourse = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()
			if not SongOrCourse then
				self:settext("")
				return
			end

			local StepsOrTrail = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player) or GAMESTATE:GetCurrentSteps(player)
			local meter = StepsOrTrail and StepsOrTrail:GetMeter() or "?"
			self:settext(meter)
		end
	}

-- steps label
af[#af +1] =
	LoadFont("Common Normal") ..
		{
			Name = "Steps",
			InitCommand = function(self)
				self:zoom(zoom_factor):xy(-_screen.w / 10 + dataX_col1, row_height):diffuse(Color.White):halign(0)
			end
		}

--PLAYER PROFILE high score
af[#af + 1] =
	LoadFont("Common Normal") ..
	{
		Name = "PlayerHighScore",
		InitCommand = function(self)
			self:xy(-_screen.w / 10 + highscoreX, row_height):zoom(zoom_factor):diffuse(Color.White):halign(0)
		end
	}

--Last Played
af[#af + 1] =
	LoadFont("Common Normal") ..
	{
		Name = "LastPlayedDate",
		InitCommand = function(self)
			self:xy(-_screen.w / 10 + dataX_col1, row_height + 18):zoom(zoom_factor):diffuse(Color.White):halign(0)
		end
	}

--Times Played
af[#af + 1] =
	LoadFont("Common Normal") ..
	{
		Name = "TimesPlayed",
		InitCommand = function(self)
			self:xy(-_screen.w / 10 + dataX_col1, row_height + 18 * 2):zoom(zoom_factor):diffuse(Color.White):halign(0)
		end
	}
--PlayerHighScoreDate
af[#af + 1] =
	LoadFont("Common Normal") ..
	{
		Name = "PlayerHighScoreDate",
		InitCommand = function(self)
			self:xy(-_screen.w / 10 + highscoreX, row_height + 18):zoom(zoom_factor):diffuse(Color.White):halign(0)
		end
	}

--First Passed Date
af[#af + 1] =
	LoadFont("Common Normal") ..
	{
		Name = "FirstPass",
		InitCommand = function(self)
			self:xy(-_screen.w / 10 + highscoreX, row_height + 18 * 2):zoom(zoom_factor):diffuse(Color.White):halign(0)
		end
	}
return af
