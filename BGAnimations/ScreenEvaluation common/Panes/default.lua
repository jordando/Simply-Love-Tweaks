local args = ...
local NumPanes = args.NumPanes
local hash = args.hash

local players = GAMESTATE:GetHumanPlayers()

local af = Def.ActorFrame{}
af.Name="Panes"

local offset = {
	[PLAYER_1] = _screen.cx-155,
	[PLAYER_2] = _screen.cx+155
}

-- add available Panes to the ActorFrame via a loop
-- Note(teejusb): Some of these actors may be nil. This is not a bug, but
-- a feature for any panes we want to be conditional.

if #players == 2 or SL.Global.GameMode=="Casual" then
	for player in ivalues(players) do
		for i=1, NumPanes do
			local pn = ToEnumShortString(player)
			local player_pane = LoadActor("./Pane"..i, {player, player})

			if player_pane then
				af[#af+1] = Def.ActorFrame{
					Name="Pane"..i.."_".."Side"..pn,
					InitCommand=function(self) self:x(offset[player]) end,
					player_pane
				}
			end
		end
	end

elseif #players == 1 then
	-- When only one player is joined (single, double, solo, etc.), we end up loading each
	-- Pane twice, effectively doing the same work twice.
	--
	-- This approach (loading two of each Pane, even in single) was easier for me to write
	-- InputHandling for.  An approach I considered was loading one of each pane and then
	-- moving the panes around (between left and right sides of ScreenEval) via InputHandling.
	-- That was less computional work (not loading everything twice), but it was more work
	-- for my milquetoast mind.
	--
	-- Some of the Panes (QR code, timing histogram) contain expensive computation that can
	-- delay ScreenEvaluation's load time, *especially* when performed twice.  If only one
	-- player is joined, it's wasteful to do these identical calculations twice.
	--
	-- So, use ComputedData as a table local to this file (it won't persist past ScreenEvaluation)
	-- and pass it into Pane sub-files as a "reference" to achieve pointer-like behavior within
	-- the scoping contexts that exist within this file within ScreenEvaluation.  In this way, we can
	-- check if some expensive calculations have already been run, and refer to the ComputedData
	-- table to get the results.
	local ComputedData = {}
	local mpn = GAMESTATE:GetMasterPlayerNumber()

	for i=1, NumPanes do
		if SL.Global.GameMode == "Experiment" and GetStepsType() ~= "StepsType_Dance_Double" then
			af[#af+1] = LoadActor("./ExperimentPane"..i, {player = mpn, hash = hash})..{
				Name="Pane"..i.."_".."Side"..ToEnumShortString(mpn),
				InitCommand=function(self) self:x(offset[mpn]) end,
			}
		else
			-- left
			local left_pane  = LoadActor("./Pane"..i, {mpn, PLAYER_1, ComputedData})
			local right_pane = LoadActor("./Pane"..i, {mpn, PLAYER_2, ComputedData})

			-- these need to be wrapped in an extra AF to offset left and right
			-- panes can be nil, however, so don't add extra AFs with nil children
			if left_pane and right_pane then
				af[#af+1] = Def.ActorFrame{
					Name="Pane"..i.."_".."SideP1",
					InitCommand=function(self) self:x(offset.PlayerNumber_P1) end,
					left_pane
				}
				af[#af+1] = Def.ActorFrame{
					Name="Pane"..i.."_".."SideP2",
					InitCommand=function(self) self:x(offset.PlayerNumber_P2) end,
					right_pane
				}
			end
		end
	end
end

return af