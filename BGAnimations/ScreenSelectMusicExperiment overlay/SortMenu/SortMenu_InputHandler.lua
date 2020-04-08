local sort_wheel = ...

-- this handles user input while in the SortMenu
local function input(event)
	SOUND:StopMusic()
	if not (event and event.PlayerNumber and event.button) then
		return false
	end

	local screen   = SCREENMAN:GetTopScreen()
	local overlay  = screen:GetChild("Overlay")
	local sortmenu = overlay:GetChild("SortMenu")

	if event.type ~= "InputEventType_Release" then

		if event.GameButton == "MenuRight" then
			sort_wheel:scroll_by_amount(1)
			sortmenu:GetChild("change_sound"):play()

		elseif event.GameButton == "MenuLeft" then
			sort_wheel:scroll_by_amount(-1)
			sortmenu:GetChild("change_sound"):play()

		elseif event.GameButton == "Start" then
			sortmenu:GetChild("start_sound"):play()
			local focus = sort_wheel:get_actor_item_at_focus_pos()

			if focus.kind == "SortBy" then
				SL.Global.GroupType = focus.sort_by
				MESSAGEMAN:Broadcast("GroupTypeChanged")
				overlay:queuecommand("DirectInputToEngine")
			-- the player wants to adjust filters
			elseif focus.kind == "Adjust" then
				--go to filters screen
				screen:SetNextScreenName("ScreenFilterOptions")
				screen:StartTransitioningScreen("SM_GoToNextScreen")
			elseif focus.kind == "Text" then
				overlay:queuecommand("DirectInputToSearchMenu")
			elseif focus.new_overlay then
				if focus.new_overlay == "TestInput" then
					sortmenu:queuecommand("DirectInputToTestInput")
				elseif focus.new_overlay == "Song Tags" then
					overlay:queuecommand("DirectInputToTagMenu")
				elseif focus.new_overlay == "Order" then
					overlay:queuecommand("DirectInputToOrderMenu")
				elseif focus.new_overlay == "Sort" then
					sortmenu:playcommand("SwitchToSort")
				elseif focus.new_overlay == "Player Stats" then
					overlay:queuecommand("DirectInputToPlayerStats")
				elseif focus.new_overlay == "Practice" then
					overlay:queuecommand("DirectInputToPractice")
				end
			end

		elseif event.GameButton == "Back" or event.GameButton == "Select" then
			overlay:queuecommand("DirectInputToEngine")
		end
	end

	return false
end

return input