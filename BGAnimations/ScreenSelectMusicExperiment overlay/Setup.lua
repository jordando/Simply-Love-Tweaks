-- You know that spot under the rug where you sweep away all the dirty
-- details and then hope no one finds them?  This file is that spot.
--
-- The idea is basically to just throw setup-related stuff
-- in here that we don't want cluttering up default.lua
---------------------------------------------------------------------------
-- because no one wants "Invalid PlayMode 7"
GAMESTATE:SetCurrentPlayMode(0)

---------------------------------------------------------------------------
-- local junk
local margin = {
	w = WideScale(54,72),
	h = 30
}

-- TODO: figure out what's using these and what for
local numCols = 3
local numRows = 5

---------------------------------------------------------------------------
-- variables that are to be passed between files
local OptionsWheel = {}
local GroupWheel = setmetatable({}, sick_wheel_mt)
local SongWheel = setmetatable({}, sick_wheel_mt)

-- simple option definitions
local OptionRows = LoadActor("./OptionRows.lua")

for player in ivalues( {PLAYER_1, PLAYER_2} ) do
	-- create the optionwheel for this player
	OptionsWheel[player] = setmetatable({disable_wrapping = true}, sick_wheel_mt)

	-- set up each optionrow for each optionwheel
	for i=1,#OptionRows do
		OptionsWheel[player][i] = setmetatable({}, sick_wheel_mt)
	end
end

local col = {
	how_many = numCols,
	w = (_screen.w/numCols) - margin.w,
}
local row = {
	how_many = numRows,
	h = ((_screen.h - (margin.h*(numRows-2))) / (numRows-2)),
}



---------------------------------------------------------------------------
-- initializes sick_wheel OptionRows for the CurrentSong with needed information
-- this function is called when choosing a song, either actively (pressing START)
-- or passively (MenuTimer running out)

local InitOptionRowsForSingleSong = function()
	for pn in ivalues( {PLAYER_1, PLAYER_2} ) do
		OptionsWheel[pn]:set_info_set(OptionRows, 1)
		for i,row in ipairs(OptionRows) do
			if row.OnLoad then
				row.OnLoad(OptionsWheel[pn][i], pn, row:Choices(), row.Values())
			end
		end
	end
end

---------------------------------------------------------------------------
-- default song when ScreenSelectMusicExperiment first loads
-- returns a song object

local GetDefaultSong = function()
	--TODO If there are two songs with the same name in the same group it'll pick the first - does this ever happen?
	--Try to grab the last played song on the profile for master player
	local profile = PROFILEMAN:GetProfile(GAMESTATE:GetMasterPlayerNumber())
	--if they haven't used Experiment mode before than last song won't be set so default to the first song
	if profile and SL.Global.LastSongPlayedName then
		local t = SONGMAN:GetSongsInGroup(SL.Global.LastSongPlayedGroup)
		for song in ivalues(t) do
			if song:GetMainTitle() == SL.Global.LastSongPlayedName then
				return song
			end
		end
	end
	-- fall back on first song from all songs if needed
	return SONGMAN:GetAllSongs()[1]
end

---------------------------------------------------------------------------
-- initializes sick_wheel groups
-- this function is called as a result of GroupTypeChangedMessageCommand broadcast by SortMenu_InputHandler.lua and
-- heard by default.lua (for ScreenSelectMusicExperiment overlay)

local InitGroups = function()
	local groups = PruneGroups(GetGroups())
	if #groups == 0 then
		SM("WARNING: ALL SONGS WERE FILTERED. RESETTING FILTERS")
		ResetFilters()
		groups = GetGroups()
	end
	local group_index = GetGroupIndex(groups)
	GroupWheel:set_info_set(groups, group_index)
end

---------------------------------------------------------------------------
-- Info used on the group wheel about each group
-- Structure:
-- info[group].num_songs = number of songs in a group
-- info[group].max_num = highest number of charts in any difficulty
-- info[group].filtered_charts = number of charts hidden due to filters
-- info[group]['UnsortedLevel'][{difficultyBlock}] = number of charts in each difficulty block
-- info[group]['UnsortedPassedLevel'][difficultyBlock] = number of charts with the given difficulty passed by master player
-- info[group]['Level'][difficultyBlock][{difficulty,num_songs}] = sorted list of number of passed songs in each difficulty block
-- info[group]['PassedLevel'][difficultyBlock][{difficulty,num_songs}] = sorted list of number of passed songs in each difficulty block
-- info[group].charts = String listing number of charts per difficulty level

local GetGroupInfo = function()
	local groups = PruneGroups(GetGroups())
	local info = {}
	local songs
	local mpn = GAMESTATE:GetMasterPlayerNumber()
	for group in ivalues(groups) do
		songs = GetSongList(group)
		info[group] = {}
		info[group].num_songs = #songs
		info[group]['UnsortedLevel'] = {}
		info[group]['UnsortedPassedLevel'] = {}
		info[group]['PassedLevel'] = {}
		info[group].filtered_charts = 0
		info[group].all_charts = 0
		info[group].duration = 0
		for song in ivalues(songs) do
			if song:HasStepsType(GetStepsType()) then
				info[group].duration = info[group].duration + song:MusicLengthSeconds()
				for steps in ivalues(song:GetStepsByStepsType(GetStepsType())) do
					info[group].all_charts = info[group].all_charts + 1
					--if the chart passes filters, add to our list of charts
					if ValidateChart(song, steps, mpn) then
						--add chart to info[group][difficultyBlock]
						info[group]['UnsortedLevel'][tostring(steps:GetMeter())] = 1 + (tonumber(info[group]['UnsortedLevel'][tostring(steps:GetMeter())]) or 0)
						local hash = GetHash(mpn,song,steps)
						if hash then
							local highScore = GetScores(mpn,hash,false,true)
							if highScore and highScore[1].grade ~= "Failed" then
								info[group]['UnsortedPassedLevel'][tostring(steps:GetMeter())] = 1 + (tonumber(info[group]['UnsortedPassedLevel'][tostring(steps:GetMeter())]) or 0)
							end
						else
							local highScore = PROFILEMAN:GetProfile(GAMESTATE:GetMasterPlayerNumber()):GetHighScoreList(song,steps):GetHighScores()[1]
							if highScore then --TODO this only shows stats for the master player. Maybe it should show for both players?
								if highScore:GetGrade() and Grade:Reverse()[highScore:GetGrade()] < 17 then
									info[group]['UnsortedPassedLevel'][tostring(steps:GetMeter())] = 1 + (tonumber(info[group]['UnsortedPassedLevel'][tostring(steps:GetMeter())]) or 0)
								end
							end
						end
					else info[group].filtered_charts = info[group].filtered_charts + 1 end
				end
			end
		end
		info[group]['Level'] = info[group]['UnsortedLevel']
		info[group]['PassedLevel'] = info[group]['UnsortedPassedLevel']

		local sortTable = { }
		for k, v in pairs(info[group]['Level']) do table.insert(sortTable, { difficulty = k, num_songs = v }) end
		table.sort(sortTable, function(k1,k2) return tonumber(k1.difficulty) < tonumber(k2.difficulty) end)
		info[group]['Level'] = sortTable
		sortTable = {}
		for k, v in pairs(info[group]['PassedLevel']) do table.insert(sortTable, { difficulty = k, num_songs = v }) end
		table.sort(sortTable, function(k1,k2) return tonumber(k1.difficulty) < tonumber(k2.difficulty) end)
		info[group]['PassedLevel'] = sortTable
		local max_num = 0
		info[group].charts = ""
		for item in ivalues(info[group]['Level']) do
			info[group].charts = info[group].charts .. " Level " .. item.difficulty .. ": " .. item.num_songs .. "\n"
			if item.num_songs > max_num then max_num = item.num_songs end
		end
		info[group].max_num = max_num
	end
	return info
end


---------------------------------------------------------------------------
-- If there's no song set that means we're entering the screen for the first time, grab the default song and set up the groups
if not GAMESTATE:GetCurrentSong() then
	SL.Preferences.Experiment.TimingWindowSecondsW0=0.011000 --Set the extra window for FAP
	local current_song = GetDefaultSong()
	GAMESTATE:SetCurrentSong(current_song)
	InitPreloadedGroups()
	for player in ivalues(GAMESTATE:GetHumanPlayers()) do
		GAMESTATE:SetCurrentSteps(player,GAMESTATE:GetCurrentSong():GetStepsByStepsType(GetStepsType())[1])
		-- if we're loading custom scores upfront and there's a non guest profile loaded then load any new
		-- scores from stats. If we're not loading upfront then don't worry about it until we play each song
		if ThemePrefs.Get("LoadCustomScoresUpfront") then LoadNewFromStats(player) end
	end
else
-- Otherwise if the player got a new high grade then we need to remake the relevant grade groups
-- TODO right now this doesn't check if they got a highscore, it just makes new groups.
	UpdateGradeGroups(GAMESTATE:GetCurrentSong())
end

return {
	group_info=GetGroupInfo(),
	OptionsWheel=OptionsWheel,
	GroupWheel=GroupWheel,
	SongWheel=SongWheel,
	OptionRows=OptionRows,
	row=row,
	col=col,
	InitOptionRowsForSingleSong=InitOptionRowsForSingleSong,
	InitGroups=InitGroups,
	GetGroupInfo=GetGroupInfo,
}