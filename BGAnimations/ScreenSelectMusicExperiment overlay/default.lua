---------------------------------------------------------------------------
-- do as much setup work as possible in another file to keep default.lua
-- from becoming overly cluttered
local setup = LoadActor("./Setup.lua")
if setup == nil then
	return LoadActor(THEME:GetPathB("ScreenSelectMusicCasual", "overlay/NoValidSongs.lua"))
end
-- Used to keep track of when we're changing songs
local timeToGo = 0
local scroll = 0

local group_info = setup.group_info

local OptionRows = setup.OptionRows
local OptionsWheel = setup.OptionsWheel
local GroupWheel = setup.GroupWheel
local SongWheel = setup.SongWheel
local row = setup.row
local col = setup.col

local TransitionTime = 0.5
local songwheel_y_offset = -13

local EnteringSong=false

---------------------------------------------------------------------------
-- a table of params from this file that we pass into the InputHandler file
-- so that the code there can work with them easily
local params_for_input = { GroupWheel=GroupWheel, SongWheel=SongWheel, OptionsWheel=OptionsWheel, OptionRows=OptionRows, EnteringSong=EnteringSong,DifficultyIndex0=4,DifficultyIndex1=4}

---------------------------------------------------------------------------
-- load the InputHandler and pass it the table of params
local Input = LoadActor( "./Input.lua", params_for_input )

-- metatables
local group_mt = LoadActor("./GroupMT.lua", {GroupWheel,SongWheel,col,Input})
local song_mt = LoadActor("./SongMT.lua", {SongWheel,row})
local optionrow_mt = LoadActor("./OptionRowMT.lua")
local optionrow_item_mt = LoadActor("./OptionRowItemMT.lua")

---------------------------------------------------------------------------
-- Setup and enable input
---------------------------------------------------------------------------

local t = Def.ActorFrame {
	InitCommand=function(self)
		if SL.Global.GroupType == "Courses" then GAMESTATE:SetCurrentPlayMode('PlayMode_Nonstop') end
		SL.Global.ExperimentScreen = true
		SL.Global.GoToOptions = false
		SL.Global.GameplayReloadCheck = false
		setup.InitGroups()
		self:GetChild("GroupWheel"):SetDrawByZPosition(true)
		local mpn = GAMESTATE:GetMasterPlayerNumber()
		--SongMT only broadcasts this message when the song is different from the previous one (ie ignores changing steps)
		--But this won't work when we first enter ScreenSelectMusicExperiment so we broadcast here once.
		params_for_input['DifficultyIndex'..PlayerNumber:Reverse()[mpn]] = Difficulty:Reverse()[GAMESTATE:GetCurrentSteps(mpn):GetDifficulty()]
		MESSAGEMAN:Broadcast("CurrentSongChanged",{song=GAMESTATE:GetCurrentSong()})
		--if we had to reset everything because filters killed it then update group info for the group shared wheel here
		group_info = setup.GetGroupInfo()
		MESSAGEMAN:Broadcast("UpdateGroupInfo", {group_info, GroupWheel:get_actor_item_at_focus_pos().groupName})
		MESSAGEMAN:Broadcast("LessLag")
	end,

	OnCommand=function(self)
		self:queuecommand("Capture")
		if PREFSMAN:GetPreference("MenuTimer") then self:queuecommand("Listen") end
	end,

	ListenCommand=function(self)
		local topscreen = SCREENMAN:GetTopScreen()
		local seconds = topscreen:GetChild("Timer"):GetSeconds()
		-- if necessary, force the players into Gameplay because the MenuTimer has run out
		if not Input.AllPlayersAreAtLastRow() and seconds <= 0 then

			-- if we we're not currently in the optionrows,
			-- we'll need to initialize them for the current song, first
			if Input.WheelWithFocus ~= OptionsWheel then
				setup.InitOptionRowsForSingleSong()
			end

			for player in ivalues(GAMESTATE:GetHumanPlayers()) do

				for index=1, #OptionRows-1 do
					local choice = OptionsWheel[player][index]:get_info_at_focus_pos()
					local choices= OptionRows[index]:Choices()
					local values = OptionRows[index].Values()

					OptionRows[index]:OnSave(player, choice, choices, values)
				end
			end
			topscreen:StartTransitioningScreen("SM_GoToNextScreen")
		else
			self:sleep(0.5):queuecommand("Listen")
		end
	end,

	CaptureCommand=function(self)
		-- One element of the Input table is an internal function, Handler
		SCREENMAN:GetTopScreen():AddInputCallback( Input.Handler )
		-- set up initial variable states and the players' OptionRows
		Input:Init()
		-- It should be safe to enable input for players now
		self:queuecommand("EnableMainInput")
	end,

	EnableMainInputCommand=function(self)
		Input.Enabled = true
	end,

	-- Apply player modifiers from profile
	LoadActor("./PlayerModifiers.lua"),

---------------------------------------------------------------------------
-- Commands controlling behavior
---------------------------------------------------------------------------

	-- a hackish solution to prevent users from button-spamming and breaking input :O
	SwitchFocusToSongsMessageCommand=function(self)
		self:stoptweening():sleep(TransitionTime):queuecommand("EnableMainInput")
	end,

	SwitchFocusToGroupsMessageCommand=function(self)
		self:stoptweening():sleep(TransitionTime):queuecommand("EnableMainInput")
	end,

	SwitchFocusToSingleSongMessageCommand=function(self)
		setup.InitOptionRowsForSingleSong()
		self:stoptweening():sleep(TransitionTime):queuecommand("EnableMainInput")
	end,

	-- Broadcast by SortMenu_InputHandler when a player chooses a sort type
	GroupTypeChangedMessageCommand=function(self)
		if SL.Global.Debug then Trace("Running GroupTypeChangedMessageCommand") end
		if SL.Global.GroupType == "Courses" then
			local course = SONGMAN:GetAllCourses(false)[1]
			GAMESTATE:SetCurrentCourse(course)
			GAMESTATE:SetCurrentTrail(PLAYER_1,course:GetAllTrails()[1])
			GAMESTATE:SetCurrentTrail(PLAYER_2,course:GetAllTrails()[1])
			GAMESTATE:SetCurrentPlayMode('PlayMode_Nonstop')
		else 
			GAMESTATE:SetCurrentPlayMode('PlayMode_Regular')
			group_info = setup.GetGroupInfo()
		end
		-- we have to figure out what group we're supposed to be in now depending on the current song
		-- if they entered the sort menu while on "Close This Folder" then GetCurrentSong() will return nil
		-- in that case grab the last seen song (set by SongMT)
		local current_song = GAMESTATE:GetCurrentSong() or SL.Global.LastSeenSong
		local mpn = GAMESTATE:GetMasterPlayerNumber()
		--set global variables for the difficulty group and grade group so we can keep the scroll on the correct one when CurrentSongChangedMessageCommand is called
		SL.Global.DifficultyGroup = GAMESTATE:GetCurrentSteps(mpn):GetMeter()
		local highScore = PROFILEMAN:GetProfile(mpn):GetHighScoreList(current_song,GAMESTATE:GetCurrentSteps(mpn)):GetHighScores()[1] --TODO this only works for master player
		if highScore then SL.Global.GradeGroup = highScore:GetGrade()
		else SL.Global.GradeGroup = "No_Grade" end
		setup.InitGroups() --this prunes out groups with no songs in them (or resets filters if we have 0 songs) and resets GroupWheel
		-- Broadcast to GroupWheelShared letting it know to reset all its information
		MESSAGEMAN:Broadcast("UpdateGroupInfo", {group_info, GroupWheel:get_actor_item_at_focus_pos().groupName})
	end,

	--tells the songwheel to transform itself without changing songs to update the
	--pass type and grades on the song wheel. Used when players switch difficulties
	--Broadcast from ./PerPlayer/SongSelect.lua.
	Transform0MessageCommand = function(self)
		if Input.WheelWithFocus then Input.WheelWithFocus:scroll_by_amount(0) end
	end,

	--if we choose a song in Search then we want to jump straight to it even if we're on the group wheel
	SetSongViaSearchMessageCommand=function(self)
		if SL.Global.Debug then Trace("Running SetSongViaSearchMessageCommand") end
		if Input.WheelWithFocus == GroupWheel then --going from group to song
			SOUND:PlayOnce( THEME:GetPathS("MusicWheel", "expand.ogg") )
			Input.WheelWithFocus = SongWheel
			MESSAGEMAN:Broadcast("SwitchFocusToSongs", {"GroupWheel"})
			SL.Global.GroupToSong = true
		end
		setup.InitGroups() --this prunes out groups with no songs in them (or resets filters if we have 0 songs) and resets GroupWheel
		MESSAGEMAN:Broadcast("UpdateGroupInfo", {group_info, GroupWheel:get_actor_item_at_focus_pos().groupName})
		MESSAGEMAN:Broadcast("LessLag")
	end,

	-- Code for exiting the game for those without a back button.
	-- If the player decides not to, then EscapeFromEventMode.lua
	-- will broadcast DirectInputToEngine
	CodeMessageCommand=function(self, params)
		if params.Name == "EscapeFromEventMode" then
			Input.Enabled = false
		end
	end,

	-- Broadcast when we enter the Sort Menu. Don't want to let input touch the normal screen
	DirectInputToSortMenuMessageCommand=function(self)
		Input.Enabled = false
	end,

	-- Broadcast when coming out of other menus that disabled main input
	DirectInputToEngineMessageCommand=function(self)
		self:queuecommand("EnableMainInput")
		if Input.WheelWithFocus == SongWheel then
			play_sample_music()
		end
	end,

	-- Anti lag measures while scrolling through song wheel
	--Wrap this in an actor so stoptweening doesn't affect everything else
	Def.Actor{
		-- Called by SongMT when changing songs. Updating the histogram and the stream breakdown lags SM if players hold down left or right
		-- and the wheel scrolls too quickly. To alleviate this, instead of using CurrentSongChanged, we wait for .06 seconds to have
		-- passed without changing songs before broadcasting "LessLag" which PaneDisplay receives.
		BeginSongTransitionMessageCommand=function(self)
			self:stoptweening()	--TODO if you press enter while holding left or right you can break input
			scroll = scroll + 1
			if scroll > 3 then
				if not SL.Global.Scrolling then SL.Global.Scrolling = true MESSAGEMAN:Broadcast("BeginScrolling") end
			end
			timeToGo = GetTimeSinceStart() - SL.Global.TimeAtSessionStart + .06
			self:sleep(.15):queuecommand("FinishSongTransition")
		end,
		FinishSongTransitionMessageCommand=function(self)
			if (GetTimeSinceStart() - SL.Global.TimeAtSessionStart) > timeToGo and SL.Global.SongTransition then
				self:stoptweening()
				scroll = 0
				SL.Global.Scrolling = false
				SL.Global.SongTransition=false
				MESSAGEMAN:Broadcast("LessLag")
			end
		end
	},

---------------------------------------------------------------------------
-- Screen Transition Commands
---------------------------------------------------------------------------

	-- This command is broadcast by input.handler when it tries to start a song.
	-- Emulates the "Press START for options that native screenselectmusic has
	-- if we're allowing it (set in prefs)
	ScreenTransitionMessageCommand=function(self)
		if ThemePrefs.Get("AllowTwoTap") then
			self:playcommand("TransitionQuadOff")
			self:queuecommand("ShowPressStartForOptions")
			params_for_input.EnteringSong = true
			self:sleep(2):queuecommand("GoToNextScreen")

		else
			Input.Enabled = false
			self:playcommand("TransitionQuadOff")
			self:sleep(.3):queuecommand("GoToNextScreen")
		end
	end,

	-- ScreenTransitionMessageCommand waits two seconds for the user to hit start again - then goes to either options or gameplay
	GoToNextScreenCommand=function(self)
		SL.Global.ExperimentScreen = false
		local topscreen = SCREENMAN:GetTopScreen()
		if topscreen then
			topscreen:StartTransitioningScreen("SM_GoToNextScreen")
		end
	end,

	-- If someone presses start then we set a flag telling us where to go next and change from "Press Start..." to "Entering Options"
	GoToOptionsMessageCommand=function(self)
		SL.Global.GoToOptions = true
		self:playcommand("ShowEnteringOptions")
	end,
}

---------------------------------------------------------------------------
-- Visual elements
---------------------------------------------------------------------------

-- If the players want a black background, set it here. TODO: would be better to disable the actual background
if ThemePrefs.Get("BlackBackground") then
	t[#t+1] = table.insert(t,1,LoadActor( THEME:GetPathB("", "_black")))
end
-- right now this just has the black rectangle going across the screen.
-- there's also a different style of text that are disabled
t[#t+1] = LoadActor("./SongWheelShared.lua", {row, col, songwheel_y_offset})
-- Shared items on the OptionWheel GUI
t[#t+1] = LoadActor("./PlayerOptionsShared.lua", {row, col, Input})
-- Songwheel
t[#t+1] = SongWheel:create_actors( "SongWheel", 14, song_mt, WideScale(25,50), songwheel_y_offset - 40)
--Information about the song - including the grid/stream info, nps histogram, and step information
--Shows on song select screen but not invididual song or group menus so add them in to an actor
--frame so we can hide/show them all at once.
t[#t+1] = Def.ActorFrame{
	SwitchFocusToGroupsMessageCommand=function(self) self:stoptweening():queuecommand("Hide") end,
	SwitchFocusToSingleSongMessageCommand=function(self) self:stoptweening():queuecommand("Hide") end,
	SwitchFocusToSongsMessageCommand = function(self) self:stoptweening():queuecommand("Show") end,
	CloseThisFolderHasFocusMessageCommand = function(self) self:stoptweening():queuecommand("Hide") end, --don't display any of this when we're on the close folder item
	CurrentSongChangedMessageCommand = function(self, params) --brings things back after CloseThisFolderHasFocusMessageCommand runs
		if params.song and self:GetDiffuseAlpha() == 0 and Input.WheelWithFocus == SongWheel then self:stoptweening():queuecommand("Show") end end,
	HideCommand = function(self) self:linear(.3):diffusealpha(0):visible(false) end,
	ShowCommand = function(self) self:visible(true):linear(.3):diffusealpha(1) end,

	-- elements we need two of (one for each player) that draw underneath the StepsDisplayList
	-- this includes the stepartist boxes and the PaneDisplays (number of steps, jumps, holds, etc.)
	LoadActor("./PerPlayer/Under.lua"),
	-- grid of Difficulty Blocks (normal)
	LoadActor("./StepsDisplayList/Grid.lua"),
	-- elements we need two of that draw over the StepsDisplayList (cursor and function to automatically jump to a valid chart when changing songs)
	LoadActor("./PerPlayer/Over.lua", params_for_input),
	-- Song Artist, BPM, Duration (Referred to in other themes as "PaneDisplay")
	LoadActor("./songDescription.lua"),
	-- Scroll bar
	Def.Quad{
		InitCommand=function(self)
			self:x(_screen.w-10):valign(0):visible(false)
		end,
		CurrentSongChangedMessageCommand=function(self,params)
			-- if we're coming here because the sort changed then we need to pull the current group
			-- otherwise we can use group_info to figure out how many songs there are
			if GAMESTATE:IsCourseMode() then self:visible(false) return end
			local num_songs
			if IsSpecialOrder() then num_songs = #SpecialOrder
			elseif not group_info[GetCurrentGroup()] then
				num_songs = #PruneSongList(GetSongList(SL.Global.CurrentGroup))
			else
				num_songs = group_info[GetCurrentGroup()].num_songs
			end
			local size = (_screen.h-64) / num_songs --header and footer are each 32
			local position = params.index and params.index or 0
			if position == 0 then self:visible(false) --if we're on the close folder option
			else self:visible(true):zoomto(20,size):y(position*size-size+32) end
		end
	},
}

-- this has information about the groups - number of songs/charts/filters/# of passed charts
t[#t+1] = LoadActor("./GroupWheelShared.lua", {row, col, group_info})
-- elements we need two of - panes for the OptionWheel GUI
t[#t+1] = LoadActor("./PerPlayer/PlayerOptionsPanes/default.lua")

-- the bar at the top as well as total time since start
-- we want these after the songwheel so they cut off the songs but before the group wheel
-- so you can see the group name
t[#t+1] = LoadActor("./Header.lua", row)
-- Groupwheel
t[#t+1] = GroupWheel:create_actors( "GroupWheel", row.how_many * col.how_many, group_mt, 25, 200, true)

-- Add player options ActorFrames to our primary ActorFrame
for pn in ivalues( {PLAYER_1, PLAYER_2} ) do
	local x_offset = (pn==PLAYER_1 and -1) or 1

	-- Optionwheels that have enough items to handle the number of optionrows necessary
	t[#t+1] = OptionsWheel[pn]:create_actors("OptionsWheel"..ToEnumShortString(pn), #OptionRows, optionrow_mt, _screen.cx - 100 + 140 * x_offset, _screen.cy - 30)

	local height = 200
	local count
	if ThemePrefs.Get("ShowExtraControl") ~= "none" then count = 4 else count = 3 end
	for i=1,#OptionRows do
		-- Create sub-wheels for each optionrow with 2 items each.
		-- Regardless of how many items are actually in that row,
		-- we only display 1 at a time.
		t[#t+1] = OptionsWheel[pn][i]:create_actors(ToEnumShortString(pn).."OptionWheel"..i, 2, optionrow_item_mt, WideScale(30, 130) + 140 * x_offset, _screen.cy - 15 + i * height/count)
	end
	OptionsWheel[pn].focus_pos = #OptionRows --start with the bottom (Start) selected
end

-- profile information and time spent in game
-- note that this covers the footer in graphics
t[#t+1] = LoadActor("Footer.lua")
-- the big banner above song information
t[#t+1] = LoadActor("./Banner.lua")
-- CD Title
t[#t+1] = LoadActor("./CdTitle.lua")
-- finally, load the additional menus used for sorting the MusicWheel (and more)
--hidden by default
t[#t+1] = LoadActor("./SortMenu/default.lua")
-- a Test Input overlay can (maybe) be accessed from the SortMenu
t[#t+1] = LoadActor("./TestInput.lua")
-- The menu for adding/removing tags
t[#t+1] = LoadActor("./TagMenu/default.lua")
-- The menu for changing the order songs display in
t[#t+1] = LoadActor("./OrderMenu/default.lua")
--Stuff related to searching
t[#t+1] = LoadActor("./Search/default.lua")
--Panel showing player stats
t[#t+1] = LoadActor("./PlayerStats/default.lua")
-- a yes/no prompt overlay for backing out of SelectMusic when in EventMode can be
-- activated via "CodeEscapeFromEventMode" under [ScreenSelectMusic] in Metrics.ini
t[#t+1] = LoadActor("./EscapeFromEventMode.lua")

-- FIXME: This is dumb.  Add the player option StartButton visual last so it
--  draws over everything else and we can hide cusors behind it when needed...
t[#t+1] = LoadActor("./StartButton.lua")
-- course contents
t[#t+1] = LoadActor("./StepsDisplayList/CourseContentsList.lua")..{
	InitCommand=function(self) self:addx(25) end,
	SwitchFocusToGroupsMessageCommand=function(self) self:stoptweening():queuecommand("Hide") end,
	CloseThisFolderHasFocusMessageCommand = function(self) self:stoptweening():queuecommand("Hide") end,
	SwitchFocusToSingleSongMessageCommand=function(self) self:stoptweening():queuecommand("Hide") end,
	SwitchFocusToSongsMessageCommand = function(self) self:stoptweening():queuecommand("Show") end,
	CurrentSongChangedMessageCommand = function(self, params) --brings things back after CloseThisFolderHasFocusMessageCommand runs
		if params.song and self:GetDiffuseAlpha() == 0 and Input.WheelWithFocus == SongWheel then self:stoptweening():queuecommand("Show") end end,
	DirectInputToSortMenuMessageCommand = function(self) self:stoptweening():queuecommand("Hide") end,
	DirectInputToEngineMessageCommand = function(self) 
		if Input.WheelWithFocus == SongWheel then self:stoptweening():queuecommand("Show") end end,
	GroupTypeChangedMessageCommand = function(self)
		if Input.WheelWithFocus == SongWheel then self:stoptweening():queuecommand("Show")
		else self:stoptweening():queuecommand("Hide") end
	end,
	HideCommand = function(self) self:linear(.3):diffusealpha(0):visible(false) end,
	ShowCommand = function(self)
		if SL.Global.GroupType == "Courses" then self:visible(true):linear(.3):diffusealpha(1) end end,
}
---------------------------------------------------------------------------
-- More Screen Transition
---------------------------------------------------------------------------

--This quad is added last so it covers everything
t[#t+1] = Def.Quad{
	InitCommand=function(self) self:diffuse(0,0,0,0):FullScreen():cropbottom(1) end,
	TransitionQuadOffCommand=function(self)
		self:linear(0.3):cropbottom(0):diffusealpha(1)
	end
}

-- If two tap is enabled have some text helpers letting people know what to do
t[#t+1] = LoadFont("Common Normal")..{
		Name="TextDisplay",
		Text=THEME:GetString("ScreenSelectMusicExperiment", "Press Start for Options"),
		InitCommand=function(self) self:visible(false):Center():zoom(1):diffusealpha(0) end,
		ShowPressStartForOptionsCommand=function(self) self:hibernate(.3):visible(true):linear(0.3):diffusealpha(1) end,
		ShowEnteringOptionsCommand=function(self) self:linear(0.125):diffusealpha(0):queuecommand("NewText") end,
		NewTextCommand=function(self) self:hibernate(0.1):settext(THEME:GetString("ScreenSelectMusicExperiment", "Entering Options...")):linear(0.125):diffusealpha(1):sleep(1) end
}

-- Sounds used on the various menus for this screen
t[#t+1] = Def.ActorFrame{
	Name="sounds",
	Def.Sound{
		Name="accept",
		File=THEME:GetPathS("FF","accept.ogg"),
		PlayStartSoundMessageCommand=function(self) self:play() end,
	},
	Def.Sound{
		Name="move",
		File=THEME:GetPathS("FF","move.ogg"),
		PlayMove1SoundMessageCommand=function(self) self:play() end,
	},
	Def.Sound{
		Name="select",
		File=THEME:GetPathS("FF", "select.ogg"),
		PlayMove2SoundMessageCommand=function(self) self:play() end,
	},
	Def.Sound{
		Name="cancel",
		File=THEME:GetPathS("FF","cancel.ogg"),
		PlayCancelSoundMessageCommand=function(self) self:play() end,
	},
}

return t