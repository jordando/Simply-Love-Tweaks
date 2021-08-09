--------------------------------------------------------------------------------------------------------------------------
-- TABLES
--------------------------------------------------------------------------------------------------------------------------

-- A table of the possible sort groups and what the group names are
local SortGroups = {
	Title = {
		"A","B","C","D","E","F",
		"G","H","I","J","K","L",
		"M","N","O","P","Q","R",
		"S","T","U","V","W","X",
		"Y","Z","Num","Other"
	},
	BPM = {
		100,110,120,130,140,
		150,160,170,180,190,
		200,210,220,230,240,
		250,260,270,280,290,
		300,
	},
	Length = {
		1,2,3,4,5,
		6,7,8,9,10
	},
	Difficulty = {
		1,2,3,4,5,
		6,7,8,9,10,
		11,12,13,14,15,
		16,17,18,19,20,
		21,22,23,24,25,
	},
	Grade = {
		"Grade_Tier01","Grade_Tier02",
		"Grade_Tier03","Grade_Tier04",
		"Grade_Tier05","Grade_Tier06",
		"Grade_Tier07","Grade_Tier08",
		"Grade_Tier09","Grade_Tier10",
		"Grade_Tier11","Grade_Tier12",
		"Grade_Tier13","Grade_Tier14",
		"Grade_Tier15","Grade_Tier16",
		"Grade_Tier17","Grade_Tier18",
		"Grade_Tier19","Grade_Tier20",
		"Grade_Failed","No_Grade",
	},
	Group = {},
	Tag = {"No Tags Set"},
	Courses = {"Courses"},
}
SortGroups.Artist = SortGroups.Title

local GroupNames = {
	Grade = {
		Grade_Tier01="100%",
		Grade_Tier02="99%",
		Grade_Tier03="98%",
		Grade_Tier04="96%",
		Grade_Tier05="Grade: S+",
		Grade_Tier06="Grade: S",
		Grade_Tier07="Grade: S-",
		Grade_Tier08="Grade: A+",
		Grade_Tier09="Grade: A",
		Grade_Tier10="Grade: A-",
		Grade_Tier11="Grade: B+",
		Grade_Tier12="Grade: B",
		Grade_Tier13="Grade: B-",
		Grade_Tier14="Grade: C+",
		Grade_Tier15="Grade: C",
		Grade_Tier16="Grade: C-",
		Grade_Tier17="Grade: D",
		Grade_Tier18="Grade: F",
		Grade_Tier19="Grade: F",
		Grade_Tier20="Grade: F",
		Grade_Failed="Grade: F",
		No_Grade="No Grade",
	},
}

-- To keep load times down we only want to create groups once. The structure is PreloadedGroups[SortType][GroupName] -> {table of songs}
-- For example: PreloadedGroups["Title"]["A"] contains an indexed table of all songs starting with A
local PreloadedGroups = {}

-- When songs should be ordered by something special keep track of them in this table since we need to split
-- songs depending on the number of charts
SpecialOrder = {}

-- A table of tagged songs loaded from Other/TaggedSongs.txt
-- Each item in the table is a table with the following items: customGroup, title, actualGroup
local TaggedSongs = {}

--------------------------------------------------------------------------------------------------------------------------
-- Tagging
--------------------------------------------------------------------------------------------------------------------------

--- Returns nil if the song has no tags or the name of the first tag it finds
--- If given a tagName parameter it will only return something if the song has that specific tag
--- Since tags are done by song rather than by chart we don't use the hashes. Should tags go by chart instead?
function GetTags(song, tagName)
	local current_song = song
	local tags = {}
	for taggedSong in ivalues(TaggedSongs) do
		if current_song:GetMainTitle() ==  taggedSong['title'] and current_song:GetGroupName() == taggedSong['actualGroup'] then
			if tagName then
				if tagName == taggedSong['customGroup'] then tags[#tags+1] = taggedSong['customGroup'] end
			else
				tags[#tags+1] = taggedSong['customGroup']
			end
		end
	end
	if #tags > 0 then return tags
	else return nil end
end

--- Add any tags we find in Tags.txt to the sort groups
--- 'No Tags Set' and 'BPM Changes' are automatically generated
local function LoadTags()
	local tagTable = {}
	local path = THEME:GetCurrentThemeDirectory() .. "Other/Tags.txt"
	for name in ivalues(GetFileContents(path)) do
		table.insert(tagTable, name)
	end
	--if there aren't any tags add a generic "Favorites" tag to get people started
	if not next(tagTable) then
		table.insert(tagTable,"Favorites")
	end
	table.insert(tagTable, "No Tags Set")
	table.insert(tagTable, "BPM Changes")
	return tagTable
end

--- Write whatever is in SortGroups.Tag to Tags.txt
--- Don't add 'No Tags Set' or 'BPM Changes'
local function SaveTags()
	local toWrite = ""
	for _,v in pairs(SortGroups.Tag) do
		if v ~= "No Tags Set" and v~= "BPM Changes" then
			toWrite = toWrite..v.."\n"
		end
	end
	local path = THEME:GetCurrentThemeDirectory() .. "Other/Tags.txt"
	WriteFileContents(path,toWrite,true)
end

--- Add whatever tagged songs we find in TaggedSongs.txt. They're needed to populate the tag groups
local function LoadTaggedSongs()
	local songs = {}
	local path = THEME:GetCurrentThemeDirectory() .. "Other/TaggedSongs.txt"
	for line in ivalues(GetFileContents(path)) do
		local toAdd = Split(line, '\t')
		table.insert(songs, {customGroup=toAdd[1], title=toAdd[2], actualGroup=toAdd[3]})
	end
	return songs
end

--- Write whatever is in TaggedSongs to TaggedSongs.txt
local function SaveTaggedSongs()
	-- Overwrite CustomGroups-Songs.txt with the current Custom Songs table
	local toWrite = ""
	for _,v in pairs(TaggedSongs) do
		toWrite = toWrite..v['customGroup'].."\t"..v['title'].."\t"..v['actualGroup'].."\n"
	end
	local path = THEME:GetCurrentThemeDirectory() .. "Other/TaggedSongs.txt"
	WriteFileContents(path,toWrite,true)
end

--- Adds a tag to the SortGroups table, saves it to disk, and creates loads the group with songs
-- Called in ScreenSelectMusicExperiment/TagMenu/Input.lua
function AddTag(toAdd)
	table.insert(SortGroups.Tag, #SortGroups.Tag-1, toAdd)
	SaveTags()
	PreloadedGroups["Tag"][tostring(toAdd)] = CreateSongList(tostring(toAdd), "Tag")
end

--- Called by ScreenSelectMusicExperiment overlay/TagMenu/Input.lua when the player wants to add a tag to a song.
--- Adds a line to TaggedSongs, saves it, and then recreates the group so we can sort properly.
function AddTaggedSong(toAdd, song)
	-- Add the song to the CustomSong table
	local add = Split(toAdd, '\t')
	table.insert(TaggedSongs, {customGroup=add[1], title=add[2], actualGroup=add[3]})
	SaveTaggedSongs()
	PreloadedGroups["Tag"][tostring(add[1])] = CreateSongList(tostring(add[1]),"Tag")
	-- If this song used to be in No Tags Set then remove it. TODO find out if it's faster to remove the song from the group or just recreate the group
	local index = FindInTable(song,PreloadedGroups["Tag"]["No Tags Set"])
	if index then table.remove(PreloadedGroups["Tag"]["No Tags Set"],index) end
end

--- Called by ScreenSelectMusicExperiment overlay/TagMenu/Input.lua when the player wants to remove a tag to a song.
--- Removes a line to TaggedSongs, saves it, and then recreates the group so we can sort properly.
function RemoveTaggedSong(toRemove, song)
	local index = 1
	local remove = Split(toRemove, '\t')
	for k,v in pairs(TaggedSongs) do
		if v['customGroup'] == remove[1] and v['title'] == remove[2] and v['actualGroup'] == remove[3] then
			index = k
			break
		end
	end
	table.remove(TaggedSongs,index)
	SaveTaggedSongs()
	PreloadedGroups["Tag"][tostring(remove[1])] = CreateSongList(tostring(remove[1]),"Tag")
	--if this song no longer has any tags then add it to "No Tags Set"
	if not GetTags(song) then table.insert(PreloadedGroups["Tag"]["No Tags Set"],song) end
end

--------------------------------------------------------------------------------------------------------------------------
-- Grouping
--------------------------------------------------------------------------------------------------------------------------

--- To keep load times down we only want to create groups once. However, tag groups and grade groups are not static.
--- This function is called by Setup.lua each time we go back to ScreenSelectMusicExperiment with a song set (aka not the first time).
--- Remove the current song from whatever grade groups it was in and add it to whatever grade groups it should be in now
function UpdateGradeGroups(song)
	local current_song = song
	--first remove the song from all current grade groups it's in
	--if the current song is in no grade we don't need to bother checking everything else
	local index = FindInTable(current_song,GetSongList("No_Grade","Grade"))
	if index then
		table.remove(PreloadedGroups["Grade"]["No_Grade"],index)
	else
		for group in ivalues(GetGroups("Grade")) do
			if group ~= "No_Grade" then --don't need to check no grade twice
				index = FindInTable(current_song,GetSongList(group,"Grade"))
				if index then
					table.remove(PreloadedGroups["Grade"][tostring(group)],index)
				end
			end
		end
	end
	-- next add it to all relevant groups
	local isPlayed = false
	for steps in ivalues(current_song:GetStepsByStepsType(GetStepsType())) do
		local highScore = PROFILEMAN:GetProfile(GAMESTATE:GetMasterPlayerNumber()):GetHighScoreList(current_song,steps):GetHighScores()[1]
		if highScore then --TODO this only checks for the master player. Maybe it should set both groups?
			if highScore:GetGrade() then
				table.insert(PreloadedGroups["Grade"][tostring(highScore:GetGrade())],current_song)
				isPlayed = true
			end
		end
	end
	--if we didn't find any charts with high scores than isPlayed will stay false and we can add it to No_Grade
	if not isPlayed then table.insert(PreloadedGroups["Grade"]["No_Grade"],current_song) end
end

--- prune out groups that have no valid steps.
--- passed an indexed table of strings representing potential group names.
--- returns an indexed table of group names as strings.
function PruneGroups(_groups)
	local groups = {}
	local songs
	for group in ivalues( _groups ) do
		songs = PruneSongList(GetSongList(group))
		if #songs > 0 then
			groups[#groups+1] = group
		end
	end
	return groups
end

--- Prunes a list of songs using SL.Global.ActiveFilters. As long as at least one chart for a song is valid
--- the song will be added.
function PruneSongList(song_list)
	local songs = {}
	for song in ivalues(song_list) do
		-- this should be guaranteed by this point, but better safe than segfault
		if song:HasStepsType(GetStepsType()) then
			for chart in ivalues(song:GetStepsByStepsType(GetStepsType())) do
				if ValidateChart(song, chart) then songs[#songs+1] = song break end
			end
		end
	end
	return songs
end

--- For the groups that are just numbers (Length, BPM) or ugly enums (Grade) we want to give a more descriptive name.
--- Called by GroupMT.lua
function GetGroupDisplayName(groupName)
	local name
	if SL.Global.GroupType == "Length" then
		if groupName == 1 then name = groupName.." Minute"
		else name = groupName.." Minutes" end
		if groupName == 10 then name = groupName.."+" end
	elseif SL.Global.GroupType == "BPM" then
		name = groupName.." BPM"
	elseif SL.Global.GroupType == "Difficulty" then
		name = "Level "..groupName
		if tonumber(groupName) == 25 then name = name.."+" end
	elseif SL.Global.GroupType == "Grade" then
		name = GroupNames["Grade"][groupName]
	elseif SL.Global.GroupType == "Artist" then
		name = "Artist: "..groupName
	end
	return name and name or groupName
end

--- returns an indexed table of group names as strings.
--- uses the current sort type if no parameter is given.
function GetGroups(inputGroup)
	local group = inputGroup or SL.Global.GroupType
	if group == "Group" then
		return SONGMAN:GetSongGroupNames()
	else return SortGroups[group] end
end

--- Called by __index InitCommand in GroupMT.lua (ScreenSelectMusicExperiment overlay)
--- Returns a string containing the group a song is part of. If no params are given then it uses the current song
--- (or the last song seen if we're on "CloseThisFolder" or the groupwheel).
--- For grade group it uses the MasterPlayer's scores (and completely ignores the other player)
function GetCurrentGroup(song)
	if SL.Global.GroupType == "Courses" then return "Courses" end
	local mpn = GAMESTATE:GetMasterPlayerNumber()
	--no song if we're on Close This Folder so use the last seen song
	local current_song = song and song or GAMESTATE:GetCurrentSong() or SL.Global.LastSeenSong
	local starting_group = current_song:GetMainTitle()
	if SL.Global.GroupType == "Title" then
		if string.find(starting_group, "^%d") then
			starting_group = "Num"
		elseif string.find(starting_group, "^%W") then
			starting_group = "Other"
		else
			starting_group = string.sub(starting_group, 1, 1)
		end
	elseif SL.Global.GroupType == "Artist" then
		local artist = current_song:GetDisplayArtist()
			if string.find(artist, "^%d") then
				starting_group = "Num"
			elseif string.find(artist, "^%W") then
				starting_group = "Other"
			else
				starting_group = string.sub(artist, 1, 1)
			end
	elseif SL.Global.GroupType == "Tag" then starting_group = GetTags(current_song) and GetTags(current_song)[1] or "No Tags Set" --TODO if song is in multiple tags this just grabs the first
	elseif SL.Global.GroupType == "Group" then starting_group = current_song:GetGroupName()
	elseif SL.Global.GroupType == "BPM" then
		local speed = current_song:GetDisplayBpms()[2]
		starting_group = speed - (speed % 10)
		if starting_group > 300 then starting_group = 300
		elseif starting_group < 110 then starting_group = 100
		end
	elseif SL.Global.GroupType == "Length" then
		local length = current_song:MusicLengthSeconds()
		starting_group = math.floor(length/60)
		if starting_group < 1 then starting_group = 10
		elseif starting_group > 10 then starting_group = 10
		end
	elseif SL.Global.GroupType == "Difficulty" then
		starting_group = GAMESTATE:GetCurrentSteps(mpn):GetMeter() --TODO this only works for the master player.
	elseif SL.Global.GroupType == "Grade" then
		local highScore = PROFILEMAN:GetProfile(mpn):GetHighScoreList(current_song,GAMESTATE:GetCurrentSteps(mpn)):GetHighScores()[1]
		if highScore then starting_group = highScore:GetGrade()
		else starting_group = "No_Grade" end
	else starting_group = current_song:GetGroupName() end
	SL.Global.CurrentGroup = starting_group
	return starting_group
end

--- given a table of all possible groups, return the index of the group that the current song is part of or 1 if it can't find the group
-- Used in setup when creating groups to make sure we stay focused on the correct group.
function GetGroupIndex(groups)
	local group_index = 1
	local current_song = GAMESTATE:GetCurrentSong() or SL.Global.LastSeenSong
	local mpn = GAMESTATE:GetMasterPlayerNumber()
	for k,group in ipairs(groups) do
		if SL.Global.GroupType == "Tag" then
			if GetTags(current_song, group) then group_index = k
			elseif group == "No Tags Set" and not GetTags(current_song) then group_index = k end
		elseif SL.Global.GroupType == "Group" then
			if current_song:GetGroupName() == group then
				group_index = k
				break
			end
		elseif SL.Global.GroupType == "Title" then
			if group == "Num" then
				 if string.find(current_song:GetMainTitle(), "^%d") then group_index = k end
			elseif group == "Other" then
				if string.find(current_song:GetMainTitle(), "^%W") then group_index = k end
			elseif string.sub(current_song:GetMainTitle(), 1, 1) == string.sub(group, 1, 1) then group_index = k end
		elseif SL.Global.GroupType == "Artist" then
			if group == "Num" then
				 if string.find(current_song:GetDisplayArtist(), "^%d") then group_index = k end
			elseif group == "Other" then
				if string.find(current_song:GetDisplayArtist(), "^%W") then group_index = k end
			elseif string.sub(current_song:GetDisplayArtist(), 1, 1) == string.sub(group, 1, 1) then group_index = k end
		elseif SL.Global.GroupType == "BPM" then
			if tonumber(group) == 100 then
				 if current_song:GetDisplayBpms()[2] < 110 then
					group_index = k
				end
			elseif tonumber(group) == 300 then
				if current_song:GetDisplayBpms()[2] >= 300 then
					group_index = k
				end
			elseif current_song:GetDisplayBpms()[2] < tonumber(group) + 10 and current_song:GetDisplayBpms()[2] >= tonumber(group) then
				group_index = k
			end
		elseif SL.Global.GroupType == "Length" then
			if tonumber(group) == 10 then
				if current_song:MusicLengthSeconds() >= 600 then group_index = k end
			elseif tonumber(group) == 1 then
				if current_song:MusicLengthSeconds() < 120 then group_index = k end
			elseif current_song:MusicLengthSeconds() >= tonumber(group) * 60 and current_song:MusicLengthSeconds() < ((tonumber(group) * 60) + 60) then
				group_index = k
			end
		elseif SL.Global.GroupType == "Difficulty" then
			if tonumber(group) == GAMESTATE:GetCurrentSteps(mpn):GetMeter() then --TODO this only works for the master player.
				group_index = k
			elseif tonumber(group) > 25 and GAMESTATE:GetCurrentSteps(mpn):GetMeter() > 25 then
				group_index = k
			end
		elseif SL.Global.GroupType == "Grade" then
			local highScore = PROFILEMAN:GetProfile(mpn):GetHighScoreList(current_song,GAMESTATE:GetCurrentSteps(mpn)):GetHighScores()[1]
			if highScore then
				if group == highScore:GetGrade() then --TODO this only works for the master player.
					group_index = k
				end
			else
				if group == "No_Grade" then
					group_index = k
				end
			end
		end
	end
	return group_index
end

local CreateGroup = Def.ActorFrame{
	--------------------------------------------------------------------------------------
	-- provided a group title as a string, make a list of songs that fit that group
	-- returns an indexed table of song objects
	
	-- TODO songs are currently tracked separately from groups so if you go in later
	-- and delete the group, when creating the "No Tags Set" folder it won't populate
	-- things that are in custom groups that no longer exist.
	Tag = function(group)
		local songs = {}
		for song in ivalues(SONGMAN:GetAllSongs()) do
			-- this should be guaranteed by this point, but better safe than segfault
			if song:HasStepsType(GetStepsType()) then
				if group == "BPM Changes" then
					if song:HasSignificantBPMChangesOrStops() then songs[#songs+1] = song end
				elseif group == "No Tags Set" then 
					if not GetTags(song) and not song:HasSignificantBPMChangesOrStops() then songs[#songs+1] = song end
				else
					if GetTags(song, group) then
						songs[#songs+1] = song
					end
				end
			end
		end
		return songs
	end,

	--------------------------------------------------------------------------------------
	-- provided a group title as a string, make a list of songs that fit that group
	-- returns an indexed table of song objects
	Grade = function(group)
		local mpn = GAMESTATE:GetMasterPlayerNumber()
		local songs = {}
		for song in ivalues(SONGMAN:GetAllSongs()) do
			local played = false
			-- this should be guaranteed by this point, but better safe than segfault
			if song:HasStepsType(GetStepsType()) then
				for steps in ivalues(song:GetStepsByStepsType(GetStepsType())) do
					local highScore = PROFILEMAN:GetProfile(mpn):GetHighScoreList(song,steps):GetHighScores()[1]
					if highScore then
						played = true
						if highScore:GetGrade() == group then --TODO this only works for the master player.
							songs[#songs+1] = song
							break
						end
					end
				end
				if not played then if group == "No_Grade" then songs[#songs+1] = song end end
			end	
		end
		return songs
	end,
	--------------------------------------------------------------------------------------
	--provided a group title as a string, make a list of songs that fit that group
	--returns an indexed table of song objects
	Difficulty = function(group)
		local songs = {}
		for song in ivalues(SONGMAN:GetAllSongs()) do
			-- this should be guaranteed by this point, but better safe than segfault
			if song:HasStepsType(GetStepsType()) then
				for steps in ivalues(song:GetStepsByStepsType(GetStepsType())) do
					if steps:GetMeter() == tonumber(group) then
						songs[#songs+1] = song
						break
					elseif tonumber(group) == 25 and steps:GetMeter() > 25 then
						songs[#songs+1] = song
						break
					end
				end
			end
		end
		return songs
	end,
	--------------------------------------------------------------------------------------
	--provided a group title as a string, make a list of songs that fit that group
	--returns an indexed table of song objects
	Length = function(group)
		local songs = {}
		for song in ivalues(SONGMAN:GetAllSongs()) do
			-- this should be guaranteed by this point, but better safe than segfault
			if song:HasStepsType(GetStepsType()) then
				if tonumber(group) == 10 then
					if song:MusicLengthSeconds() >= 600 then
						songs[#songs+1] = song
					end
				elseif tonumber(group) == 1 then
					if song:MusicLengthSeconds() < 120 then
						songs[#songs+1] = song
					end
				elseif song:MusicLengthSeconds() >= tonumber(group) * 60 and song:MusicLengthSeconds() < ((tonumber(group) * 60) + 60) then
					songs[#songs+1] = song
				end
			end
		end

		return songs
	end,

	--------------------------------------------------------------------------------------
	--provided a group title as a string, make a list of songs that fit that group
	--returns an indexed table of song objects
	Artist = function(group)
		local songs = {}
		for song in ivalues(SONGMAN:GetAllSongs()) do
			-- this should be guaranteed by this point, but better safe than segfault
			if song:HasStepsType(GetStepsType()) then
				if group == "Num" then
					 if string.find(song:GetDisplayArtist(), "^%d") then
						songs[#songs+1] = song
					end
				elseif group == "Other" then
					if string.find(song:GetDisplayArtist(), "^%W") then
						songs[#songs+1] = song
					end
				elseif group == string.sub(song:GetDisplayArtist(), 1, 1) then
					songs[#songs+1] = song
				end
			end
		end

		return songs
	end,

	--------------------------------------------------------------------------------------
	--provided a group title as a string, make a list of songs that fit that group
	--returns an indexed table of song objects
	Title = function(group)
		local songs = {}
		for song in ivalues(SONGMAN:GetAllSongs()) do
			-- this should be guaranteed by this point, but better safe than segfault
			if song:HasStepsType(GetStepsType()) then
				if group == "Num" then
					 if string.find(song:GetMainTitle(), "^%d") then
						songs[#songs+1] = song
					end
				elseif group == "Other" then
					if string.find(song:GetMainTitle(), "^%W") then
						songs[#songs+1] = song
					end
				elseif group == string.sub(song:GetMainTitle(), 1, 1) then
					songs[#songs+1] = song
				end
			end
		end

		return songs
	end,
	--------------------------------------------------------------------------------------
	--provided a group title as a string, make a list of songs that fit that group
	--returns an indexed table of song objects
	BPM = function(group)
		local songs = {}
		for song in ivalues(SONGMAN:GetAllSongs()) do
			-- this should be guaranteed by this point, but better safe than segfault
			if song:HasStepsType(GetStepsType()) then
				if tonumber(group) == 100 then
					 if song:GetDisplayBpms()[2] < 110 then
						songs[#songs+1] = song
					end
				elseif tonumber(group) == 300 then
					if song:GetDisplayBpms()[2] >= 300 then
						songs[#songs+1] = song
					end
				elseif song:GetDisplayBpms()[2] < tonumber(group) + 10 and song:GetDisplayBpms()[2] >= tonumber(group) then
						songs[#songs+1] = song
				end
			end
		end

		return songs
	end,

	--------------------------------------------------------------------------------------
	--provided a group title as a string, make a list of songs that fit that group
	--returns an indexed table of song objects
	Group = function(group)
		local songs = {}

		for i,song in ipairs(SONGMAN:GetSongsInGroup(group)) do
			-- this should be guaranteed by this point, but better safe than segfault
			if song:HasStepsType(GetStepsType()) then
				songs[#songs+1] = song
			end
		end
		
		return songs
	end,

	--------------------------------------------------------------------------------------
	--provided a group title as a string, make a list of songs that fit that group
	--returns an indexed table of song objects
	Courses = function(group)
		local courses = {}
		for course in ivalues(SONGMAN:GetAllCourses(false)) do
			if next(course:GetAllTrails()) then courses[#courses+1] = course end
		end
		return courses
	end,
}

----------------------------------------------------------------------------------------------
-- Ordering how songs are displayed within groups
----------------------------------------------------------------------------------------------
local speed
local conversion = {}
conversion["Difficulty/Speed"] = {"difficulty",speed}
conversion["Difficulty/BPM"] = {"difficulty", "bpm"}
conversion["BPM/Stream Total"] = {"bpm", "totalStreams"}
conversion["Speed/Stream Total"] = {speed, "totalStreams"}

--- If ordering by two things return a table of the first and second sorts. Otherwise return nil
function IsSpecialOrder()
	speed = ThemePrefs.Get("StreamSpeed")
	conversion["Difficulty/Speed"] = {"difficulty", speed}
	conversion["Speed/Stream Total"] = {speed, "totalStreams"}
	return conversion[SL.Global.Order]
end

--- Controls the order songs should be displayed from within a group.
--- Default is alphabetical
function GetSortFunction()
	if SL.Global.Order == "Alphabetical" then
		return function(k1,k2)
			return string.lower(k1:GetMainTitle()) < string.lower(k2:GetMainTitle())
		end
	elseif SL.Global.Order == "Artist" then
		return function(k1,k2)
			return string.lower(k1:GetDisplayArtist()) < string.lower(k2:GetDisplayArtist())
		end
	elseif SL.Global.Order == "BPM" then
		return function(k1,k2)
			if k1:GetDisplayBpms()[2] == k2:GetDisplayBpms()[2] then
				return string.lower(k1:GetMainTitle()) < string.lower(k2:GetMainTitle())
			else
				return k1:GetDisplayBpms()[2] < k2:GetDisplayBpms()[2]
			end
		end
	elseif IsSpecialOrder() then
		local sortType = IsSpecialOrder()
		return function(k1,k2)
			--Special orders take a normal songlist before adding additional params and sorting again
			--So if there are no additional params set then just return a normal alphabetical sorted list
			--Sort by sortType[1] then sortType[2] and finally by alphabet
			if not k1.song then return string.lower(k1:GetMainTitle()) < string.lower(k2:GetMainTitle()) end
			if k1[sortType[1]] and not k2[sortType[1]] then
				return true
			elseif not k1[sortType[1]] and k2[sortType[1]] then
				return false
			elseif not k1[sortType[1]] and not k2[sortType[1]] then
				return string.lower(k1.song:GetMainTitle()) < string.lower(k2.song:GetMainTitle())
			elseif k1[sortType[1]] == k2[sortType[1]] then
				if not k1[sortType[2]] and k2[sortType[2]] then
					return true
				elseif k1[sortType[2]] and not k2[sortType[2]] then
					return false
				elseif not k1[sortType[2]] and not k2[sortType[2]] then
					return string.lower(k1.song:GetMainTitle()) < string.lower(k2.song:GetMainTitle())
				elseif k1[sortType[2]] == k2[sortType[2]] then
					return string.lower(k1.song:GetMainTitle()) < string.lower(k2.song:GetMainTitle())
				else
					return k1[sortType[2]] < k2[sortType[2]]
				end
			else
				return k1[sortType[1]] < k2[sortType[1]]
			end
		end
	else
		return function(k1,k2)
			return string.lower(k1:GetMainTitle()) < string.lower(k2:GetMainTitle())
		end
	end
end

-------------------------------------------------------------------------------------
--Song lists
-------------------------------------------------------------------------------------

--- Returns an indexed table of song objects depending on the group name supplied.
--- If groupType isn't given it will use whatever the current sort is.
--- cycles through every song loaded so can take a while if you have too many songs
function CreateSongList(group_name, groupType)
	local groupType = groupType or SL.Global.GroupType
	local songList = CreateGroup[groupType](group_name)
	return songList
end

--- Instead of cycling through every song to create a group uses the preloaded groups
--- that were created when ScreenSelectMusicExperiment first runs
function GetSongList(group_name, group_type)
	local group_type = group_type or SL.Global.GroupType
	local songList = DeepCopy(PreloadedGroups[group_type][tostring(group_name)])
	if SL.Global.GroupType == "Courses" then return songList end -- TODO: for now no sorting with course mode
	table.sort(songList, GetSortFunction())
	return songList
end

--- Currently only used when we want to order by Difficulty/BPM. This requires splitting songs so each chart gets its own song.
--- After splitting, GetSongList won't match up so we have to do something else. There's also a special table we put this in.
function CreateSpecialSongList(inputSongList)
	local startTime = GetTimeSinceStart() - SL.Global.TimeAtSessionStart
	if SL.Global.Debug then  Trace("CreateSpecialSongList") end
	local songList = inputSongList
	SpecialOrder = {}
	for song in ivalues(songList) do
		for i = 1,#song:GetStepsByStepsType(GetStepsType()) do
			if ValidateChart(song,song:GetStepsByStepsType(GetStepsType())[i]) then
				local steps = song:GetStepsByStepsType(GetStepsType())[i]
				local hash = GetHash(steps)
				local streamData
				if hash then streamData = GetStreamData(hash) end
				local toAdd = {
					song=song,
					difficulty=song:GetStepsByStepsType(GetStepsType())[i]:GetMeter(),
					bpm=steps:GetDisplayBpms()[2]
				}
				if streamData then
					local multiplier = GetNoteQuantization(steps)
					if streamData.PeakNPS then toAdd["peak"] = tonumber(round(streamData.PeakNPS/16*240,0)) end
					if streamData.TotalStreams then
						toAdd["totalStreams"] = tonumber(streamData.TotalStreams) * multiplier
					else toAdd["totalStreams"] = 0 end
					if streamData.NpsMode then toAdd["mode"] = tonumber(round(streamData.NpsMode/16*240,0)) end
					if streamData.Percent then toAdd["percent"] = tonumber(streamData.Percent) end
					if streamData.AdjustedPercent then toAdd["adjustedPercent"] = tonumber(streamData.AdjustedPercent) end
					if streamData.NpsMode and streamData.PeakNPS then
						if round(streamData.NpsMode/16*240,0) < (steps:GetDisplayBpms()[2] *.9) then
							toAdd["smart"] = round(streamData.PeakNPS/16*240,0)
						else toAdd["smart"] = round(streamData.NpsMode/16*240,0) end
					end
				end
				table.insert(SpecialOrder, toAdd)
			end
		end
	end
	table.sort(SpecialOrder, GetSortFunction())
	local specialList = {}
	for item in ivalues(SpecialOrder) do
		specialList[#specialList+1] = item.song
	end
	local endTime = GetTimeSinceStart() - SL.Global.TimeAtSessionStart
	if SL.Global.Debug then  Trace("Finish CreateSpecialSonglist") end
	if SL.Global.Debug then Trace("Runtime: "..endTime - startTime) end
	return specialList
end

function GetSpecialOrder(index)
	return SpecialOrder[index]
end

--- Create groups for every possible group in the SortGroups table
function InitPreloadedGroups()
	-- Add normal groups to SortGroups. I'd like to do this earlier but I guess the game needs to load for SONGMAN to become available
	SortGroups["Group"] = SONGMAN:GetSongGroupNames()
	-- Add song lists to PreloadedGroups
	for sortType,groupList in pairs(SortGroups) do
		PreloadedGroups[tostring(sortType)] = {}
		for groupName in ivalues(groupList) do
			PreloadedGroups[tostring(sortType)][tostring(groupName)] = CreateSongList(groupName, sortType)
		end
	end
end

-- Get custom songs ready --
TaggedSongs = LoadTaggedSongs()
SortGroups.Tag = LoadTags()
