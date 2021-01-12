local args = ...
local af = args.af
local scrollers = args.Scrollers

local mpn = GAMESTATE:GetMasterPlayerNumber()

local Handle = {}

Handle.Start = function(event)
	local topscreen = SCREENMAN:GetTopScreen()
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
		MESSAGEMAN:Broadcast("PlayStartSound")
		-- first figure out which group we're dealing with
		local info = scrollers[mpn]:get_info_at_focus_pos()
		SL.Global.Order = info.displayname
		MESSAGEMAN:Broadcast("GroupTypeChanged") --the order of songs in a group may have changed so reset it
		-- and queue the Finish for the menu
		topscreen:queuecommand("Off")
	end
end

Handle.Center = Handle.Start


Handle.MenuLeft = function(event)
	if GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
		local info = scrollers[mpn]:get_info_at_focus_pos()
		-- We add a bunch of empty rows to the table so that the first custom group is the default
		-- and it's centered on the screen. We don't want to be able to scroll to them however.
		-- To get around that, each actual group has an index parameter that we set to be non zero
		-- and then just don't scroll to 0 or lower
		local index = type(info)=="table" and info.index or 0
		if index - 1 > 0 then
			MESSAGEMAN:Broadcast("PlayMove2Sound")
			scrollers[mpn]:scroll_by_amount(-1)
			local frame = af:GetChild(ToEnumShortString(mpn) .. 'Frame')
			frame:playcommand("Set", {index=index-1})
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
		-- To get around that, each actual group has an index parameter that we set to be non zero
		-- and then just don't scroll to 0 or lower
		local index = type(info)=="table" and info.index or 0
		if index + 1 <= SL.Global.OrderOptions then
			MESSAGEMAN:Broadcast("PlayMove2Sound")
			scrollers[mpn]:scroll_by_amount(1)
			local frame = af:GetChild(ToEnumShortString(mpn) .. 'Frame')
			frame:playcommand("Set", {index=index+1})
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
		topscreen:queuecommand("Off")
	end
end
Handle.Select = Handle.Back

local InputHandler = function(event)
	if not event or not event.button then return false end
	if event.type ~= "InputEventType_Release" then
		if Handle[event.GameButton] then Handle[event.GameButton](event) end
	end
end

return InputHandler