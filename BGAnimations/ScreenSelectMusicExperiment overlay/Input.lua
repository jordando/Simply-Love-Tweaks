local args = ...
local GroupWheel = args.GroupWheel
local SongWheel = args.SongWheel
local OptionsWheel = args.OptionsWheel
local OptionRows = args.OptionRows

-- initialize Players to be any HumanPlayers at screen init
-- we'll update this later via latejoin if needed
local Players = GAMESTATE:GetHumanPlayers()

local ActiveOptionRow = 1

-----------------------------------------------------
-- input handler
local Handler = {}
Handler['OptionsWheel'] = {}
-----------------------------------------------------


local SwitchInputFocus = function(button, params)

	if button == "Start" then

		if Handler.WheelWithFocus == GroupWheel then
			Handler.WheelWithFocus = SongWheel
			SL.Global.GroupToSong = true
			MESSAGEMAN:Broadcast("SwitchFocusToSongs", {"GroupWheel"})
		elseif Handler.WheelWithFocus == SongWheel then
			Handler.WheelWithFocus = OptionsWheel
			MESSAGEMAN:Broadcast("SetOptionPanes")
			for pn in ivalues(Players) do
				Handler.WheelWithFocus[pn].container:GetChild("item"..#OptionRows):GetChild("Cursor"):playcommand("ExitRow", {PlayerNumber=pn})
				MESSAGEMAN:Broadcast("ShowPlayerOptionsPane"..SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[pn]]+1, {PlayerNumber=pn})
			end
			MESSAGEMAN:Broadcast("SwitchFocusToSingleSong")
		end

	elseif button == "Select" or button == "Back" then

		if Handler.WheelWithFocus == SongWheel then
			Handler.WheelWithFocus = GroupWheel

		elseif Handler.WheelWithFocus == OptionsWheel then
			Handler.WheelWithFocus = SongWheel
			MESSAGEMAN:Broadcast("SwitchFocusToSongs", {"OptionsWheel"})
		end

	end
end

-- determine whether all human players are done selecting song options
-- and have their cursors at the glowing green START button
Handler.AllPlayersAreAtLastRow = function()
	for player in ivalues(Players) do
		if ActiveOptionRow[player] ~= #OptionRows then
			return false
		end
	end
	return true
end

-- calls needed to close the current group folder and return to choosing a group
local CloseCurrentFolder = function()
	-- if focus is already on the GroupWheel, we don't need to do anything more
	if Handler.WheelWithFocus == GroupWheel then return end

	-- otherwise...
	Handler.Enabled = false
	Handler.WheelWithFocus.container:queuecommand("Hide")
	Handler.WheelWithFocus = GroupWheel
	Handler.WheelWithFocus.container:queuecommand("Unhide")
end

local UnhideOptionRows = function(pn)
	-- unhide optionrows for this player
	Handler.WheelWithFocus[pn].container:queuecommand("Unhide")

	-- unhide optionrowitems for this player
	for i=1,#OptionRows do
		Handler.WheelWithFocus[pn][i].container:queuecommand("Unhide")
	end
end

Handler.AllowLateJoin = function()
	if GAMESTATE:GetCurrentStyle():GetName() ~= "single" then return false end
	if PREFSMAN:GetPreference("EventMode") then return true end
	if GAMESTATE:GetCoinMode() ~= "CoinMode_Pay" then return true end
	if GAMESTATE:GetCoinMode() == "CoinMode_Pay" and PREFSMAN:GetPreference("Premium") == "Premium_2PlayersFor1Credit" then return true end
	return false
end

GetCourseTrails = function(course)
	local StepsToShow = {}
	local stepsType = GetStepsType()
	for stepchart in ivalues(GAMESTATE:GetCurrentCourse():GetAllTrails()) do
		if stepchart:GetStepsType() == stepsType then
			local diff = stepchart:GetDifficulty()
			if diff ~= "Difficulty_Edit" then
				-- use the reverse lookup functionality available to all SM enums
				-- to map a difficulty string to a number
				-- SM's enums are 0 indexed, so Beginner is 0, Challenge is 4, and Edit is 5
				-- for our purposes, increment by 1 here
				StepsToShow[ Difficulty:Reverse()[diff]  ] = stepchart
				-- assigning a stepchart directly to numerical index like this^
				-- can leave "holes" in the indexing, or indexing might not start at 1
				-- so be sure to use pairs() instead of ipairs() if iterating over later
			end
		end
	end
	return StepsToShow
end
-- See if the current song has a chart for a given difficulty
-- If no difficulty is given it uses the last seen difficulty
DifficultyExists = function(player, validate, difficulty)
	local pn = player or GAMESTATE:GetMasterPlayerNumber()
	local diff = difficulty or args['DifficultyIndex'..PlayerNumber:Reverse()[pn]] --use DifficultyIndex from params_for_input if no difficulty is supplied

	if SL.Global.GroupType == "Courses" then
		local trails = GetCourseTrails(GAMESTATE:GetCurrentCourse())
		if trails and trails[diff] then return trails[diff] end
		return false
	else
		local validate = validate or false
		local song = GAMESTATE:GetCurrentSong()
		if song then
			if validate then if song:GetOneSteps(GetStepsType(),diff) and ValidateChart(song,song:GetOneSteps(GetStepsType(),diff)) then
				return true end
			elseif song:GetOneSteps(GetStepsType(),diff) then
				return true
			else return false end
		end
		return false
	end
end

-- Looks for the next easiest difficulty. Returns nil if none can be found
-- If validate is true then it checks that the chart also passes all filters
-- (used to automatically select a valid chart when switching songs if filters are enabled)
NextEasiest = function(player, val, difficulty)
	local pn = player
	local validate = val or false
	local songOrCourse = SL.Global.GroupType == "Courses" and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
	local diff = difficulty or args['DifficultyIndex'..PlayerNumber:Reverse()[pn]] --use DifficultyIndex from params_for_input if no difficulty is supplied
	diff = diff - 1 --the current difficulty will always be there so we want to start from the next lowest
	if songOrCourse then
		if SL.Global.GroupType == "Courses" then
			local trails = GetCourseTrails(GAMESTATE:GetCurrentCourse())
			for i=diff,0,-1 do
				if trails[i] then return trails[i] end
			end
		else
			for i=diff,0,-1 do
				if validate then if songOrCourse:GetOneSteps(GetStepsType(),i) and ValidateChart(songOrCourse,songOrCourse:GetOneSteps(GetStepsType(),i)) then
					return songOrCourse:GetOneSteps(GetStepsType(),i) end
				elseif songOrCourse:GetOneSteps(GetStepsType(),i) then
					return songOrCourse:GetOneSteps(GetStepsType(),i)
				end
			end
		end
	end
	return nil
end

-- Looks for the next hardest difficulty. Returns nil if none can be found
-- If validate is true then it checks that the chart also passes all filters
-- (used to automatically select a valid chart when switching songs if filters are enabled)
NextHardest = function(player, val, difficulty)
	local pn = player
	local validate = val or false
	local songOrCourse = SL.Global.GroupType == "Courses" and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
	local diff = difficulty or args['DifficultyIndex'..PlayerNumber:Reverse()[pn]] --use DifficultyIndex from params_for_input if no difficulty is supplied
	diff = diff + 1 --the current difficulty will always be there so we want to start from the next highest
	if songOrCourse then
		if SL.Global.GroupType == "Courses" then
			local trails = GetCourseTrails(GAMESTATE:GetCurrentCourse())
			for i=diff,5 do
				if trails[i] then return trails[i] end
			end
		else
			for i=diff,5 do
				if validate then if songOrCourse:GetOneSteps(GetStepsType(),i) and ValidateChart(songOrCourse,songOrCourse:GetOneSteps(GetStepsType(),i)) then
					return songOrCourse:GetOneSteps(GetStepsType(),i) end
				elseif songOrCourse:GetOneSteps(GetStepsType(),i) then
					return songOrCourse:GetOneSteps(GetStepsType(),i)
				end
			end
		end
	end
	return nil
end

Handler.ResetHeldButtons = function()
	HeldButtons["MenuLeft"] = false
	HeldButtons["MenuRight"] = false
	HeldButtons["MenuUp"] = false
	HeldButtons["MenuDown"] = false
	HeldButtons["Ctrl"] = false
	HeldButtons["Start"] = false
	HeldButtons["Select"] = false
end

local saveOption = function(event)
	local index = ActiveOptionRow[event.PlayerNumber]
	local choice = Handler.WheelWithFocus[event.PlayerNumber][index]:get_info_at_focus_pos()
	local choices= OptionRows[index]:Choices()
	local values = OptionRows[index].Values()
	OptionRows[index]:OnSave(event.PlayerNumber, choice, choices, values)
end
-----------------------------------------------------
-- start internal functions

Handler.Init = function()
	-- flag used to determine whether input is permitted
	-- false at initialization
	Handler.Enabled = false

	-- initialize which wheel gets focus to start based on whether or not
	-- GAMESTATE has a CurrentSong (it always should at screen init)
	Handler.WheelWithFocus = GAMESTATE:GetCurrentSong() and SongWheel or GroupWheel
	
	-- table that stores P1 and P2's currently active optionrow
	ActiveOptionRow = {
		[PLAYER_1] = #OptionRows,
		[PLAYER_2] = #OptionRows
	}
	
	Handler.CancelSongChoice = function(event)
		Handler.Enabled = false
		for pn in ivalues(Players) do
			--if we're focusing on the extra options pane then we want to save every time we move over it
			if ActiveOptionRow[event.PlayerNumber] == 3 and ActiveOptionRow[pn] ~= #OptionRows then
				saveOption(event)
			end
			-- reset the ActiveOptionRow for this player
			ActiveOptionRow[pn] = #OptionRows
			-- hide this player's OptionsWheel
			Handler.WheelWithFocus[pn].container:playcommand("Hide")
			-- hide this player's OptionRows
			for i=1,#OptionRows do
				Handler.WheelWithFocus[pn][i].container:queuecommand("Hide")
			end
			-- ensure that this player's OptionsWheel understands it has been reset
			Handler.WheelWithFocus[pn]:scroll_to_pos(#OptionRows)
		end
		if SL.Global.QuickRateChanged then MESSAGEMAN:Broadcast("PeakNPSUpdated") end
		MESSAGEMAN:Broadcast("SingleSongCanceled")
		Handler.WheelWithFocus = SongWheel
		Handler.WheelWithFocus.container:queuecommand("Unhide")
		MESSAGEMAN:Broadcast("SwitchFocusToSongs", {"OptionsWheel"})
	end

	-- table that stores what buttons are held down to look for multi-button input
	HeldButtons = {
		["MenuLeft"] = false,
		["MenuRight"] = false,
		["MenuUp"] = false,
		["MenuDown"] = false
	}
end

-----------------------------------------------------------------------------------------------
-- Input on SongWheel and GroupWheel
-----------------------------------------------------------------------------------------------

Handler.MenuRight=function(event)
	-- Scroll right with MenuRight
	Handler.WheelWithFocus:scroll_by_amount(1)
	if HeldButtons["MenuLeft"] == true then --left and right are held at the same time so open the sort menu
		MESSAGEMAN:Broadcast("DirectInputToSortMenu")
		Handler.Enabled = false
		Handler.ResetHeldButtons()
	else --navigate the wheel right
		MESSAGEMAN:Broadcast("PlayMove1Sound")
	end
	return false
end

Handler.MenuLeft=function(event)
	Handler.WheelWithFocus:scroll_by_amount(-1)
	if HeldButtons["MenuRight"] == true then --left and right are held at the same time so open the sort menu
		MESSAGEMAN:Broadcast("DirectInputToSortMenu")
		Handler.Enabled = false
		Handler.ResetHeldButtons()
	else -- navigate the wheel left
		MESSAGEMAN:Broadcast("PlayMove1Sound")
	end
	return false
end

Handler.MenuUp=function(event)
	if HeldButtons["MenuDown"] == true then --Start and Select are held at the same time so open the sort menu
		MESSAGEMAN:Broadcast("PlayCancelSound")
		Handler.ResetHeldButtons()
		CloseCurrentFolder()
		return false
	else
	-- change difficulty with MenuUp
		local song = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong() -- don't do anything if we're on Close This Folder
		-- don't do anything if there's no easier difficulty or we're not on the songwheel or we're on Close This Folder
		if Handler.WheelWithFocus==SongWheel and song and NextEasiest(event.PlayerNumber) then
			MESSAGEMAN:Broadcast("PlayMove2Sound")
			if GAMESTATE:IsCourseMode() then
				GAMESTATE:SetCurrentTrail( event.PlayerNumber, NextEasiest(event.PlayerNumber) )
				args['DifficultyIndex'..PlayerNumber:Reverse()[event.PlayerNumber]] = Difficulty:Reverse()[GAMESTATE:GetCurrentTrail(event.PlayerNumber):GetDifficulty()]
			else
				GAMESTATE:SetCurrentSteps( event.PlayerNumber, NextEasiest(event.PlayerNumber) )
				args['DifficultyIndex'..PlayerNumber:Reverse()[event.PlayerNumber]] = Difficulty:Reverse()[GAMESTATE:GetCurrentSteps(event.PlayerNumber):GetDifficulty()]
			end
			-- if we change the difficulty we want to update things like grades we show on the music wheel and
			-- the song information in \PerPlayer\PaneDisplay. These are controlled by StepsHaveChangedMessageCommand which
			-- SongMT broadcasts. We can indirectly call it by using scroll_by_amount(0) which will go nowhere
			-- but still call transform and therefore StepsHaveChangedMessageCommand
			Handler.WheelWithFocus:scroll_by_amount(0)
			MESSAGEMAN:Broadcast("LessLag")
		end
	end
	return false
end

Handler.MenuDown=function(event)
--change difficulty with down
--TODO doesn't work well with edits
	if HeldButtons["MenuUp"] == true then --Start and Select are held at the same time so open the sort menu
		MESSAGEMAN:Broadcast("PlayCancelSound")
		Handler.ResetHeldButtons()
		CloseCurrentFolder()
		return false
	else
		local song = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong() -- don't do anything if we're on Close This Folder
		-- do nothing if there's no harder difficulty or we're not on the songwheel or we're on Close This Folder
		if Handler.WheelWithFocus==SongWheel and song and NextHardest(event.PlayerNumber) then
			MESSAGEMAN:Broadcast("PlayMove2Sound")
			if GAMESTATE:IsCourseMode() then
				GAMESTATE:SetCurrentTrail( event.PlayerNumber, NextHardest(event.PlayerNumber) )
				args['DifficultyIndex'..PlayerNumber:Reverse()[event.PlayerNumber]] = Difficulty:Reverse()[GAMESTATE:GetCurrentTrail(event.PlayerNumber):GetDifficulty()]
			else
				GAMESTATE:SetCurrentSteps( event.PlayerNumber, NextHardest(event.PlayerNumber) )
				args['DifficultyIndex'..PlayerNumber:Reverse()[event.PlayerNumber]] = Difficulty:Reverse()[GAMESTATE:GetCurrentSteps(event.PlayerNumber):GetDifficulty()]
			end
				-- if we change the difficulty we want to update things like grades we show on the music wheel and
			-- the song information in \PerPlayer\PaneDisplay. These are controlled by StepsHaveChangedMessageCommand which
			-- SongMT broadcasts. We can indirectly call it by using scroll_by_amount(0) which will go nowhere 
			-- but still call transform and therefore StepsHaveChangedMessageCommand
			Handler.WheelWithFocus:scroll_by_amount(0)
			MESSAGEMAN:Broadcast("LessLag")
		end
	end
	return false
end

Handler.Start=function(event)
	if HeldButtons["Select"] == true then --Start and Select are held at the same time so open the sort menu
		MESSAGEMAN:Broadcast("DirectInputToSortMenu")
		Handler.Enabled = false
		Handler.ResetHeldButtons()
	else
		-- proceed to the next wheel
		if Handler.WheelWithFocus == SongWheel and Handler.WheelWithFocus:get_info_at_focus_pos().song == "CloseThisFolder" then
			MESSAGEMAN:Broadcast("PlayCancelSound")
			CloseCurrentFolder()
			return false
		end
		Handler.Enabled = false
		Handler.WheelWithFocus.container:queuecommand("Start")
		SwitchInputFocus(event.GameButton,{PlayerNumber=event.PlayerNumber})
		if Handler.WheelWithFocus.container then --going from group to song
			Handler.WheelWithFocus.container:queuecommand("Unhide")
		else --going from song to options
			for pn in ivalues(Players) do
				UnhideOptionRows(pn)
			end
		end
		MESSAGEMAN:Broadcast("PlayMove2Sound")
	end
	return false
end

Handler.Select=function(event)
	if HeldButtons["Start"] == true then --Start and Select are held at the same time so open the sort menu
		MESSAGEMAN:Broadcast("DirectInputToSortMenu")
		Handler.Enabled = false
		Handler.ResetHeldButtons()
	else
		-- back out of the current wheel to the previous wheel if we're on the songwheel. if we're on the groupwheel then back out to main menu
		if Handler.WheelWithFocus == SongWheel then
			CloseCurrentFolder()
			MESSAGEMAN:Broadcast("PlayCancelSound")
		elseif event.GameButton == "Back" then
			SCREENMAN:GetTopScreen():SetNextScreenName( Branch.SSMCancel() ):StartTransitioningScreen("SM_GoToNextScreen") 
		end
	end
	return false
end
Handler.Back = Handler.Select

-----------------------------------------------------------------------------------------------
-- Input on OptionsWheel
-----------------------------------------------------------------------------------------------

Handler['OptionsWheel'].MenuRight = function(event)
	if not args.EnteringSong then
		-- get the index of the active optionrow for this player
		local index = ActiveOptionRow[event.PlayerNumber]
		if index ~= #OptionRows then
			MESSAGEMAN:Broadcast("PlayMove2Sound")
			-- The OptionRowItem for changing display doesn't do anything. So we broadcast a message with which pane to display.
			-- Then we increment the wheel normally so the option displays what pane we're looking at. Can't use the save/load
			-- thing because that only saves when you go to start instead of with every change. Maybe look in to this. 
			-- Probably not a good idea to assume this will be in row 2 all the time. TODO
			if ActiveOptionRow[event.PlayerNumber] == 2 then
				MESSAGEMAN:Broadcast("HidePlayerOptionsPane"..SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[event.PlayerNumber]]+1,{PlayerNumber=event.PlayerNumber})
				SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[event.PlayerNumber]] = (SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[event.PlayerNumber]] + 1) % 3
				MESSAGEMAN:Broadcast("ShowPlayerOptionsPane"..SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[event.PlayerNumber]]+1,{PlayerNumber=event.PlayerNumber})
			end
			-- scroll to the next optionrow_item in this optionrow
			Handler.WheelWithFocus[event.PlayerNumber][index]:scroll_by_amount(1)
			--if we're focusing on the extra options pane then we want to save every time we move over it
			if ActiveOptionRow[event.PlayerNumber] == 3 and ActiveOptionRow[event.PlayerNumber] ~= #OptionRows then
				saveOption(event)
			end
			-- animate the right cursor
			Handler.WheelWithFocus[event.PlayerNumber].container:GetChild("item"..index):GetChild("Cursor"):GetChild("RightArrow"):finishtweening():playcommand("Press")
		end
	end
	return false
end

Handler['OptionsWheel'].MenuLeft = function(event)
	if not args.EnteringSong then
		local index = ActiveOptionRow[event.PlayerNumber]
		if index ~= #OptionRows then
			MESSAGEMAN:Broadcast("PlayMove2Sound")
			if ActiveOptionRow[event.PlayerNumber] == 2 then
				MESSAGEMAN:Broadcast("HidePlayerOptionsPane"..SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[event.PlayerNumber]]+1,{PlayerNumber=event.PlayerNumber})
				SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[event.PlayerNumber]] = (SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[event.PlayerNumber]] - 1) % 3
				MESSAGEMAN:Broadcast("ShowPlayerOptionsPane"..SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[event.PlayerNumber]]+1,{PlayerNumber=event.PlayerNumber})
			end
			-- scroll to the previous optionrow_item in this optionrow
			Handler.WheelWithFocus[event.PlayerNumber][index]:scroll_by_amount(-1)
			--if we're focusing on the extra options pane then we want to save every time we move over it
			if ActiveOptionRow[event.PlayerNumber] == 3  and ActiveOptionRow[event.PlayerNumber] ~= #OptionRows then
				saveOption(event)
			end
			-- animate the left cursor
			Handler.WheelWithFocus[event.PlayerNumber].container:GetChild("item"..index):GetChild("Cursor"):GetChild("LeftArrow"):finishtweening():playcommand("Press")
		end
	end
	return false
end

Handler['OptionsWheel'].MenuUp = function(event)
	if not args.EnteringSong then
		if ActiveOptionRow[event.PlayerNumber] > 1 then
			MESSAGEMAN:Broadcast("PlayMove1Sound")
			--if we're focusing on the extra options pane then we want to save every time we move over it
			if ActiveOptionRow[event.PlayerNumber] == 3  and ActiveOptionRow[event.PlayerNumber] ~= #OptionRows then
				saveOption(event)
			end
			local index = ActiveOptionRow[event.PlayerNumber]
			-- set the currently active option row, bounding it to not go below 1
			ActiveOptionRow[event.PlayerNumber] = math.max(index-1, 1)
			-- scroll up to previous optionrow for this player
			Handler.WheelWithFocus[event.PlayerNumber]:scroll_by_amount( -1 )
			MESSAGEMAN:Broadcast("CancelBothPlayersAreReady")
		end
	end
	return false
end

Handler['OptionsWheel'].MenuDown = function(event)
	if not args.EnteringSong then
		local index = ActiveOptionRow[event.PlayerNumber]
		-- we want to proceed linearly to the last optionrow and then stop there
		if ActiveOptionRow[event.PlayerNumber] < #OptionRows then
			saveOption(event)
			Handler.WheelWithFocus[event.PlayerNumber]:scroll_by_amount(1)
			MESSAGEMAN:Broadcast("PlayMove1Sound")
		end

		-- update the index, bounding it to not exceed the number of rows
		index = math.min(index+1, #OptionRows)

		-- set the currently active option row to the updated index
		ActiveOptionRow[event.PlayerNumber] = index

		-- if all available players are now at the final row (start icon), animate cursors spinning
		if Handler.AllPlayersAreAtLastRow() then
			MESSAGEMAN:Broadcast("BothPlayersAreReady")
		end
	end
	return false
end

Handler['OptionsWheel'].Start = function(event)
	local index = ActiveOptionRow[event.PlayerNumber]
	-- if both players are ALREADY here (before changing the row)
	-- it means it's time to start gameplay
	if event.GameButton == "Start" and Handler.AllPlayersAreAtLastRow() then
		MESSAGEMAN:Broadcast("PlayStartSound")
		local topscreen = SCREENMAN:GetTopScreen()
		if topscreen then
			--ScreenTransition goes on for two seconds. If we get another Start in that time they want to go to options
			if args.EnteringSong == false then
				MESSAGEMAN:Broadcast("ScreenTransition")
			else
				MESSAGEMAN:Broadcast("GoToOptions")
			end
		end
		return false
	else Handler['OptionsWheel'].MenuDown(event) end --if we're not entering a song then Start does the same thing as Down
	return false
end

Handler['OptionsWheel'].Select = function(event)
	if args.EnteringSong == false then
			MESSAGEMAN:Broadcast("PlayCancelSound")
			Handler.CancelSongChoice(event)
	end
	return false
end
Handler['OptionsWheel'].Back = Handler['OptionsWheel'].Select

Handler.Handler = function(event)
	--Keep track of when Control is held down for the alphabet sorting
	if event.DeviceInput.button == "DeviceButton_left ctrl" or event.DeviceInput.button == "DeviceButton_right ctrl" then
		if ToEnumShortString(event.type) == "Release" then
			HeldButtons['Ctrl'] = false
		else
			HeldButtons['Ctrl'] = true
		end
	else
		-- Ctrl-Alpha character switches sort to Title and jumps straight to that letter
		-- Don't allow it if we're on the optionswheel
		local button = ToEnumShortString(event.DeviceInput.button)
		if string.find(button,"^(%a)$") then
			if Handler.WheelWithFocus ~= OptionsWheel and HeldButtons['Ctrl'] then
				SL.Global.GroupType = "Title"
				MESSAGEMAN:Broadcast("GroupTypeChanged")
				Switch_to_songs(string.upper(button))
				MESSAGEMAN:Broadcast("SetSongViaSearch")
				Handler.WheelWithFocus = SongWheel
				MESSAGEMAN:Broadcast("SwitchFocusToSongs", {"OptionsWheel"})
			end
		end
	end	
	if event.type == "InputEventType_Release" then
		HeldButtons[event.GameButton] = false
	end
	if Handler.Enabled == false or not event or not event.PlayerNumber or not event.button then return false end
	if not GAMESTATE:IsSideJoined(event.PlayerNumber) then
		if not Handler.AllowLateJoin() then return false end
		-- latejoin
		if event.GameButton == "Start" then
			GAMESTATE:JoinPlayer( event.PlayerNumber )
			Players = GAMESTATE:GetHumanPlayers()
			if Handler.WheelWithFocus == OptionsWheel then
				UnhideOptionRows(event.PlayerNumber)
				MESSAGEMAN:Broadcast("SwitchFocusToSingleSong")
			end
			MESSAGEMAN:Broadcast("PlayerJoined",{player=event.PlayerNumber})
		end
		return false
	end
	if event.type ~= "InputEventType_Release" then
		HeldButtons[event.GameButton] = true
		if Handler[event.GameButton] then
			if Handler.WheelWithFocus ~= OptionsWheel then Handler[event.GameButton](event)
			else Handler['OptionsWheel'][event.GameButton](event) end
		end
	end
	return false
end

return Handler