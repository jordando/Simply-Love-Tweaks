local args = ...
local af = args.af
local scrollers = args.Scrollers

local mpn = GAMESTATE:GetMasterPlayerNumber()

local Handle = {}

-- When the player hits start on the searchResults menu they want to jump to the song/group or exit
-- TODO Right now this will always jump to the song wheel. If we're on the group wheel I'd prefer it stays there
Handle.Start = function(event)
	local topscreen = SCREENMAN:GetTopScreen()
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
		local info = scrollers[mpn]:get_info_at_focus_pos()
		if SL.Global.Debug then  Trace("Search.Start: "..info.type) end
		if info.type == "group" then 
			if SL.Global.Debug then Trace("Search setting current song according to group") end
			GAMESTATE:SetCurrentSong(PruneSongList(GetSongList(info.group))[1])
		elseif info.type == "song" and GAMESTATE:GetCurrentSong() ~= info.song then
			if SL.Global.Debug then  Trace("Search setting current song: "..info.song:GetMainTitle()) end
			GAMESTATE:SetCurrentSong(info.song) end
		if info.type ~= "exit" then
			SL.Global.CurrentGroup = info.group
			if SL.Global.Debug then
				Trace("Broadcast SetSongViaSearch")
				Trace("Group: "..SL.Global.CurrentGroup)
				Trace("Song: "..GAMESTATE:GetCurrentSong():GetMainTitle())
			end
			MESSAGEMAN:Broadcast("SetSongViaSearch") --heard by ScreenSelectMusicExperiment default.lua. Jumps straight into the song folder
		end
		MESSAGEMAN:Broadcast("PlayStartSound")
		topscreen:sleep(.2):queuecommand("Off"):sleep(0.4)
	end
end

Handle.Center = Handle.Start


Handle.MenuLeft = function(event)
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
		local info = scrollers[mpn]:get_info_at_focus_pos()
		-- We add a bunch of empty rows to the table so that the first custom group is the default
		-- and it's centered on the screen. We don't want to be able to scroll to them however.
		-- To get around that, each actual group has an index parameter
		-- and then just don't scroll to to the first 3 filler rows
		local index = type(info)=="table" and info.index or 0
		if index - 1 >= 4 then
			MESSAGEMAN:Broadcast("PlayMove2Sound")
			scrollers[mpn]:scroll_by_amount(-1)
			local frame = af:GetChild(ToEnumShortString(mpn) .. 'Frame')
			frame:playcommand("Set", {index=index})
		end
	end
end

Handle.MenuUp = Handle.MenuLeft
Handle.DownLeft = Handle.MenuLeft

Handle.MenuRight = function(event)
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
		local info = scrollers[mpn]:get_info_at_focus_pos()
		-- We add a bunch of empty rows to the table so that the first custom group is the default
		-- and it's centered on the screen. We don't want to be able to scroll to them however.
		-- To get around that, each actual item has an index parameter
		-- and then just don't scroll to 0 or lower
		local index = type(info)=="table" and info.index or 0
		if info.type ~= "exit" then
			MESSAGEMAN:Broadcast("PlayMove2Sound")
			scrollers[mpn]:scroll_by_amount(1)
			local frame = af:GetChild(ToEnumShortString(mpn) .. 'Frame')
			frame:playcommand("Set", {index=index+2})
		end
	end
end
Handle.MenuDown = Handle.MenuRight
Handle.DownRight = Handle.MenuRight


Handle.Back = function(event)
	local topscreen = SCREENMAN:GetTopScreen()

	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
		MESSAGEMAN:Broadcast("PlayCancelSound")
		-- queue the Finish for the entire screen
		topscreen:queuecommand("Off"):sleep(0.4)
	end
end
Handle.Select = Handle.Back

local InputHandler = function(event)
	--this is always on so only accept input when SL.Global.SearchReady
	if not event or not event.button or not SL.Global.SearchReady then return false end
	if event.type ~= "InputEventType_Release" then
		if Handle[event.GameButton] then Handle[event.GameButton](event) end
	end
end

return InputHandler