local af, num_panes, altPaneNames = unpack(...)

if not af
or type(num_panes) ~= "number"
then
	return
end

-- -----------------------------------------------------------------------

local panes, active_pane = {}, {}

local style = ToEnumShortString(GAMESTATE:GetCurrentStyle():GetStyleType())
local players = GAMESTATE:GetHumanPlayers()

local mpn = GAMESTATE:GetMasterPlayerNumber()

-- since we're potentially retrieving from player profile
-- perform some rudimentary validation by clamping both
-- values to be within permitted ranges
-- FIXME: num_panes won't be accurate if any panes were nil,
--        so this is more like "validation" than validation

local primary_i   = clamp(SL[ToEnumShortString(mpn)].EvalPanePrimary,   1, num_panes)
local secondary_i = clamp(SL[ToEnumShortString(mpn)].EvalPaneSecondary, 1, num_panes)
if SL.Global.GameMode == "Experiment" then secondary_i = 1 end

local altPanes = {}

local position = {}

local row, col = 6,8
for y = 1, row do
	for x = 1, col do
		position[#position+1] = {130 + (57 * x), 205 + (25 * y)}
		if x <= (col/2) then table.insert(position[#position],"left")
		else table.insert(position[#position],"right") end

	end
end
local cursor_index = 1
-- -----------------------------------------------------------------------
-- initialize local tables (panes, active_pane) for the the input handling function to use
for controller=1,2 do

	panes[controller] = {}
	-- Iterate through all potential panes, and only add the non-nil ones to the
	-- list of panes we want to consider.
	for i = 1, #altPaneNames do
		altPanes[altPaneNames[i]] = af:GetChild("Panes"):GetChild(altPaneNames[i])
	end
	for i=1,num_panes do
		local pane = af:GetChild("Panes"):GetChild( ("Pane%i_SideP%i"):format(i, controller) )


		if pane ~= nil then
			-- single, double
			-- initialize the side ("controller") the player is joined as to their profile's EvalPanePrimary
			-- and the other side as their profile's EvalPaneSecondary
			if #players==1 then
				if ("P"..controller)==ToEnumShortString(mpn) then
					pane:visible(i == primary_i)
					active_pane[controller] = primary_i
				elseif ("P"..controller)==ToEnumShortString(OtherPlayer[mpn]) then
					pane:visible(i == secondary_i)
					active_pane[controller] = secondary_i

				end

			-- versus
			else
				-- initialize this player's active_pane to their profile's EvalPanePrimary
				-- will be 1 if no profile/"Guest" profile
				local p = clamp(SL["P"..controller].EvalPanePrimary, 1, num_panes)
				pane:visible(i == p)
				active_pane[controller] = p
			end

		 	table.insert(panes[controller], pane)
		end
	end
end
-- -----------------------------------------------------------------------
-- don't allow double to initialize into a configuration like
-- EvalPanePrimary=2
-- EvalPaneSecondary=4
-- because Pane2 is full-width in double and the other pane is supposed to be hidden when it is visible

if style == "OnePlayerTwoSides" then
	local cn  = PlayerNumber:Reverse()[mpn] + 1
	local ocn = (cn % 2) + 1

	-- if the player wanted their primary pane to be something that is full-width in double
	if panes[cn][active_pane[cn]]:GetChild(""):GetCommand("ExpandForDouble") then
		-- hide all panes for the other controller
		for pane in ivalues(panes[ocn]) do
			pane:visible(false)
		end
		-- and only show the one full-width pane
		panes[cn][active_pane[cn]]:visible(true)
	end

	-- if the player wanted their secondary pane to be something that is full-width in double
	if panes[cn][active_pane[ocn]]:GetChild(""):GetCommand("ExpandForDouble") then
		-- arbitrarily opt to hide the secondary pane
		panes[ocn][active_pane[ocn]]:visible(false)

		-- and show the next available pane that doesn't match primary and isn't also full-width
		for i=1,#panes[ocn] do
			active_pane[ocn] = (active_pane[ocn] % #panes[ocn]) + 1

			if active_pane[ocn] ~= active_pane[cn]
			and not panes[cn][active_pane[ocn]]:GetChild(""):GetCommand("ExpandForDouble")
			then
				panes[ocn][active_pane[ocn]]:visible(true)
				break
			end
		end
	end
end

-- for use with ExperimentPane 5: when a player wants to look at the static replay for
-- a certain judgment we use this to figure out what foot/arrow they're looking at
local noteInfo = function(index)
	local judgment = math.floor((index-.5) / 8) + 1
	local arrows = {'left', 'down', 'up', 'right'}
	local tempArrow = index % 8
	local foot = 'left'
	if tempArrow > 4 then
		tempArrow = tempArrow - 4
		foot = 'right'
	end
	if tempArrow == 0 then
		tempArrow = 4
		foot = 'right'
	end
	local arrow = arrows[tempArrow]
	return {Foot = foot, Arrow = arrow, Judgment = judgment}
end
-- -----------------------------------------------------------------------
-- input handling function

local OtherController = {
	GameController_1 = "GameController_2",
	GameController_2 = "GameController_1"
}

local judgmentMode = false --when input handler is used for choosing a judgment
local popupMode = false --when input handler is used for choosing a specific note

return function(event)
	if not (event and event.PlayerNumber and event.button) then return false end
	if not GAMESTATE:IsHumanPlayer(event.PlayerNumber) then return false end

	-- get a "controller number" and an "other controller number"
	-- if the input event came from GameController_1, cn will be 1 and ocn will be 2
	-- if the input event came from GameController_2, cn will be 2 and ocn will be 1
	--
	-- we'll use these integers to index the active_pane table, which keeps track
	-- of which pane is currently showing on each side
	local  cn = tonumber(ToEnumShortString(event.controller))
	local ocn = tonumber(ToEnumShortString(OtherController[event.controller]))

	local defaultBehavior = function(event)
		if event.GameButton == "Select" and #players == 1 and active_pane[cn] == 5 then
			if SL[ToEnumShortString(GAMESTATE:GetMasterPlayerNumber())].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].heldTimes then
				judgmentMode = true
				af:GetChild("cursor"):visible(true)
				af:GetChild("cursor"):xy(position[cursor_index][1], position[cursor_index][2])
				SM("STATIC REPLAY")
				for player in ivalues(PlayerNumber) do
					SCREENMAN:set_input_redirected(player, judgmentMode)
				end
			else
				SM("Enable held miss tracking to use this feature.")
			end
		elseif event.GameButton == "MenuRight" or event.GameButton == "MenuLeft" then
			SOUND:PlayOnce( THEME:GetPathS("FF", "select.ogg") )
			if event.GameButton == "MenuRight" then
				active_pane[cn] = (active_pane[cn] % #panes[cn]) + 1
				-- don't allow duplicate panes to show in single/double
				-- if the above change would result in duplicate panes, increment again
				if #players==1 and active_pane[cn] == active_pane[ocn] then
					active_pane[cn] = (active_pane[cn] % #panes[cn]) + 1
				end

			elseif event.GameButton == "MenuLeft" then
				active_pane[cn] = ((active_pane[cn] - 2) % #panes[cn]) + 1
				-- don't allow duplicate panes to show in single/double
				-- if the above change would result in duplicate panes, decrement again
				if #players==1 and active_pane[cn] == active_pane[ocn] then
					active_pane[cn] = ((active_pane[cn] - 2) % #panes[cn]) + 1
				end
			end

			-- double
			if style == "OnePlayerTwoSides" then
				-- if this controller is switching to Pane2 or Pane5, both of which take over both pane widths
				if panes[cn][active_pane[cn]]:GetChild(""):GetCommand("ExpandForDouble") then

					-- hide all panes for both controllers
					for controller=1,2 do
						for pane in ivalues(panes[controller]) do
							pane:visible(false)
						end
					end
					-- and only show the one full-width pane
					panes[cn][active_pane[cn]]:visible(true)

				-- if this controller is switching panes while the OTHER controller was viewing Pane2 or Pane5
				elseif panes[ocn][active_pane[ocn]]:GetChild(""):GetCommand("ExpandForDouble") then
					panes[ocn][active_pane[ocn]]:visible(false)
					panes[cn][active_pane[cn]]:visible(true)
					-- atribitarily choose to decrement other controller pane
					active_pane[ocn] = ((active_pane[ocn] - 2) % #panes[ocn]) + 1
					if active_pane[cn] == active_pane[ocn] then
						active_pane[ocn] = ((active_pane[ocn] - 2) % #panes[ocn]) + 1
					end
					panes[ocn][active_pane[ocn]]:visible(true)

				else
					-- hide all panes for this side
					for i=1,#panes[cn] do
						panes[cn][i]:visible(false)
					end
					-- show the panes we want on both sides
					panes[cn][active_pane[cn]]:visible(true)
					panes[ocn][active_pane[ocn]]:visible(true)
				end

			-- single, versus
			else
				-- hide all panes for this side
				for i=1,#panes[cn] do
					panes[cn][i]:visible(false)
				end
				-- only show the pane we want on this side
				panes[cn][active_pane[cn]]:visible(true)
			end
			-- hide all the alt panes
			if next(altPanes) then
				for i = 1,#altPaneNames do
					altPanes[altPaneNames[i]]:visible(false)
				end
			end
			af:queuecommand("PaneSwitch")
		elseif event.GameButton == "MenuUp" and #players == 1 then
			SOUND:PlayOnce( THEME:GetPathS("FF", "select.ogg") )
			if altPanes['ExperimentPane'..active_pane[cn]..'_Alt'] then
				altPanes['ExperimentPane'..active_pane[cn]..'_Alt']:visible(true)
				for i=1,#panes[cn] do
					panes[cn][i]:visible(false)
				end
			end
		elseif event.GameButton == "MenuDown" and #players == 1 then
			SOUND:PlayOnce( THEME:GetPathS("FF", "select.ogg") )
			if altPanes['ExperimentPane'..active_pane[cn]..'_Alt'] then
				altPanes['ExperimentPane'..active_pane[cn]..'_Alt']:visible(false)
				panes[cn][active_pane[cn]]:visible(true)
			end
		end
	end

	local popupBehavior = function(event)
		if event.GameButton == "Select" and #players == 1 and active_pane[cn] == 5 then
			popupMode = false
			af:GetChild("cursor"):visible(true)
			MESSAGEMAN:Broadcast("EndPopup")
		--input for the popup window
		elseif event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
			MESSAGEMAN:Broadcast("ScrollPopUpRight")
		elseif event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
			MESSAGEMAN:Broadcast("ScrollPopUpLeft")
		elseif event.GameButton == "Start" then
			popupMode = false
			af:GetChild("cursor"):visible(true)
			MESSAGEMAN:Broadcast("EndPopup")
		end
	end

	local choosingJudgmentBehavior = function(event)
		if event.GameButton == "Select" and #players == 1 and active_pane[cn] == 5 then
			judgmentMode = false
			af:GetChild("cursor"):visible(false)
			MESSAGEMAN:Broadcast("EndAnalyzeJudgment")
			SM("Normal Mode")
			for player in ivalues(PlayerNumber) do
				SCREENMAN:set_input_redirected(player, judgmentMode)
			end
		elseif event.GameButton == "MenuRight" then
			if cursor_index < (row * col) then 
				SOUND:PlayOnce( THEME:GetPathS("FF", "move.ogg") )
				cursor_index = cursor_index + 1 
			end
		elseif event.GameButton == "MenuLeft" then
			if cursor_index > 1 then 
				SOUND:PlayOnce( THEME:GetPathS("FF", "move.ogg") )
				cursor_index = cursor_index - 1
			end
		elseif event.GameButton == "MenuDown" then
			if cursor_index <= ((row-1) * col) then 
				SOUND:PlayOnce( THEME:GetPathS("FF", "move.ogg") )
				cursor_index = cursor_index + col
			end
		elseif event.GameButton == "MenuUp" then
			if cursor_index > col then
				SOUND:PlayOnce( THEME:GetPathS("FF", "move.ogg") )
				cursor_index = cursor_index - col
			end
		elseif event.GameButton == "Start" then
			SOUND:PlayOnce( THEME:GetPathS("FF", "select.ogg") )
			popupMode = true
			af:GetChild("cursor"):visible(false)
			MESSAGEMAN:Broadcast("AnalyzeJudgment",noteInfo(cursor_index))
		end
		af:GetChild("cursor"):smooth(.1):xy(position[cursor_index][1], position[cursor_index][2])
	end

	if event.type == "InputEventType_FirstPress" and panes[cn] then
		if popupMode then
			popupBehavior(event)
		elseif judgmentMode then
			choosingJudgmentBehavior(event)
		else
			defaultBehavior(event)
		end
	end

	if PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") and event.type ~= "InputEventType_Repeat" then
		MESSAGEMAN:Broadcast("TestInputEvent", event)
	end

	return false
end