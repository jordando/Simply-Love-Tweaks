local player = ...

local profile = PROFILEMAN:GetProfile(player)

local totalTime = 0
local songsPlayedThisGame = 0
local notesHitThisGame = 0

-- Use pairs here (instead of ipairs) because this player might have late-joined
-- which will result in nil entries in the the Stats table, which halts ipairs.
-- We're just summing total time anyway, so order doesn't matter.
for _,stats in pairs( SL[ToEnumShortString(player)].Stages.Stats ) do
	totalTime = totalTime + (stats and stats.duration or 0)
	songsPlayedThisGame = songsPlayedThisGame + (stats and 1 or 0)
	if stats and stats.column_judgments then
		-- increment notesHitThisGame by the total number of tapnotes hit in this particular stepchart by using the per-column data
		-- don't rely on the engine's non-Miss judgment counts here for two reasons:
		-- 1. we want jumps/hands to count as more than 1 here
		-- 2. stepcharts can have non-1 #COMBOS parameters set which would artbitraily inflate notesHitThisGame

		for _, judgments in ipairs(stats.column_judgments) do
			for judgment, judgment_count in pairs(judgments) do
				if judgment ~= "Miss" then
					notesHitThisGame = notesHitThisGame + judgment_count
				end
			end
		end
	end
end

local hours = math.floor(totalTime/3600)
local minutes = math.floor((totalTime-(hours*3600))/60)
local seconds = round(totalTime%60)
local gametime =  minutes .. THEME:GetString("ScreenGameOver", "Minutes") .. " " .. seconds .. THEME:GetString("ScreenGameOver", "Seconds")

if hours > 0 then
	gametime = hours .. ScreenString("Hours") .. " " ..
	minutes .. ScreenString("Minutes") .. " " ..
	seconds .. ScreenString("Seconds")
end

gametime = THEME:GetString("ScreenSelectMusicExperiment", "Gametime").." "..gametime
if player ~= GAMESTATE:GetMasterPlayerNumber() then gametime = "" end

return Def.ActorFrame {
	PlayerJoinedMessageCommand=function(self)
		self:playcommand("Set")
	end,
	-- Unit icon
	Def.Sprite{
		Texture=THEME:GetPathG("","Characters/Quina2/unit_icon.png"),
		InitCommand=function(self) self:align(0,1):zoomto(47,32)
			if not GAMESTATE:IsHumanPlayer(player) then self:visible(false) end
			if player == PLAYER_1 then
				self:xy(_screen.w/15+20, _screen.h)
			else
				self:xy(_screen.w - (_screen.w/15) - 75,_screen.h)
			end
		end,
		SetCommand=function(self)
			if GAMESTATE:IsHumanPlayer(player) then self:visible(true) end
		end
	},

	-- Profile name
	LoadFont("Common Normal")..{
		Text=PROFILEMAN:GetPlayerName(player),
		InitCommand=function(self)
			self:horizalign(right)
			if PROFILEMAN:GetPlayerName(player) == "" then self:settext("Guest") end
			if player == PLAYER_1 then self:xy(_screen.w/15, _screen.h - 16):zoom(1)
			elseif player == PLAYER_2 then self:horizalign(left):xy(_screen.w - (_screen.w/15), _screen.h - 16):zoom(1) end
			if not GAMESTATE:IsHumanPlayer(player) then self:visible(false) end
		end,
		SetCommand=function(self)
			if PROFILEMAN:GetPlayerName(player) == "" then self:settext("Guest")
			else self:settext(PROFILEMAN:GetPlayerName(player)) end
			if GAMESTATE:IsHumanPlayer(player) then self:visible(true) end
		end,
	},

	-- Songs Played Label
	LoadFont("Common Normal")..{
		Text=THEME:GetString("ScreenSelectMusicExperiment", "SongsPlayed"),
		InitCommand=function(self)
			if player == PLAYER_1 then self:xy(_screen.w/5+75,  _screen.h - 24):zoom(0.6):halign(1)
			elseif player == PLAYER_2 then self:xy(_screen.w - (_screen.w/3),  _screen.h - 24):zoom(0.6):halign(1) end
			if not GAMESTATE:IsHumanPlayer(player) then self:visible(false) end
		end,
		SetCommand=function(self)
			if GAMESTATE:IsHumanPlayer(player) then self:visible(true) end
		end
	},

	--Songs Played
	LoadFont("Common Normal")..{
		Text=songsPlayedThisGame,
		InitCommand=function(self)
			if player == PLAYER_1 then self:xy(_screen.w/5+80,  _screen.h - 24):zoom(0.6):halign(0)
			elseif player == PLAYER_2 then self:xy(_screen.w - (_screen.w/3) + 5,  _screen.h - 24):zoom(0.6):halign(0) end
			if not GAMESTATE:IsHumanPlayer(player) then self:visible(false) end
		end,
		SetCommand=function(self)
			self:settext(songsPlayedThisGame)
			if GAMESTATE:IsHumanPlayer(player) then self:visible(true) end
		end,
	},
	--Calories Label
	LoadFont("Common Normal")..{
		Text=THEME:GetString("ScreenSelectMusicExperiment", "Calories"),
		InitCommand=function(self)
			if player == PLAYER_1 then self:xy(_screen.w/10+75, _screen.h - 8):zoom(0.6):halign(1)
			elseif player == PLAYER_2 then self:xy(_screen.w - (_screen.w/5), _screen.h - 8):zoom(0.6):halign(1) end
			if not GAMESTATE:IsHumanPlayer(player) then self:visible(false) end
		end,
		SetCommand=function(self)
			if GAMESTATE:IsHumanPlayer(player) then self:visible(true) end
		end,
	},
	--Calories
	LoadFont("Common Normal")..{
		Text=round(profile:GetCaloriesBurnedToday()),
		InitCommand=function(self)
			if player == PLAYER_1 then self:xy(_screen.w/10+80, _screen.h - 8):zoom(0.6):halign(0)
			elseif player == PLAYER_2 then self:xy(_screen.w - (_screen.w/10+80) + WideScale(20,0), _screen.h - 8):zoom(0.6):halign(0) end
			if not GAMESTATE:IsHumanPlayer(player) then self:visible(false) end
		end,
		SetCommand=function(self)
			self:settext(round(profile:GetCaloriesBurnedToday()))
			if GAMESTATE:IsHumanPlayer(player) then self:visible(true) end
		end
	},
	-- Total Taps Label
	LoadFont("Common Normal")..{
		Text=THEME:GetString("ScreenSelectMusicExperiment", "NotesHitThisGame"),
		InitCommand=function(self)
			if player == PLAYER_1 then self:xy(_screen.w/10+75, _screen.h - 24):zoom(0.6):halign(1)
			elseif player == PLAYER_2 then self:xy(_screen.w - (_screen.w/5), _screen.h - 24):zoom(.6):halign(1) end
			if not GAMESTATE:IsHumanPlayer(player) then self:visible(false) end
		end,
		SetCommand=function(self)
			if GAMESTATE:IsHumanPlayer(player) then self:visible(true) end
		end,
	},
	--Total Taps
	LoadFont("Common Normal")..{
		Text=profile:GetTotalTapsAndHolds(),
		InitCommand=function(self)
			if player == PLAYER_1 then self:xy(_screen.w/10+80,  _screen.h - 24):zoom(0.6):halign(0)
			elseif player == PLAYER_2 then self:xy(_screen.w - (_screen.w/10+80) + WideScale(20,0),  _screen.h - 24):zoom(0.6):halign(0) end
			if not GAMESTATE:IsHumanPlayer(player) then self:visible(false) end
			self:settext(notesHitThisGame)
		end,
		SetCommand=function(self)
			self:settext(notesHitThisGame)
			if GAMESTATE:IsHumanPlayer(player) then self:visible(true) end
		end
	},
	--Game Time
	LoadFont("Common Normal")..{
		InitCommand=function(self) self:xy(_screen.cx, _screen.h - 16):zoom(0.7):diffusealpha(1) end,
		Text = gametime
	}
}
