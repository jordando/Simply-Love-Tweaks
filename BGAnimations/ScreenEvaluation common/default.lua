local Players = GAMESTATE:GetHumanPlayers()
local NumPanes = SL.Global.GameMode=="Casual" and 1 or 6
if GAMESTATE:GetCurrentStyle():GetStyleType() ~= "StyleType_OnePlayerTwoSides" and SL.Global.GameMode == "Experiment" then
	NumPanes = 5
end
-- Start by loading actors that would be the same whether 1 or 2 players are joined.
local t = Def.ActorFrame{

	-- add a lua-based InputCalllback to this screen so that we can navigate
	-- through multiple panes of information; pass a reference to this ActorFrame
	-- and the number of panes there are to InputHandler.lua
	OnCommand=function(self)								
		SCREENMAN:GetTopScreen():AddInputCallback( LoadActor("./InputHandler.lua", {af=self, num_panes=NumPanes}) )
	end,
	OffCommand=function(self)
		for player in ivalues(GAMESTATE:GetHumanPlayers()) do
			if SL.Global.GameMode == "Experiment" then AddScore(player) end
		end
	end,

	-- code for triggering a screenshot and animating a "screenshot" texture
	LoadActor("./ScreenshotHandler.lua"),

	-- the title of the song and its graphical banner, if there is one
	LoadActor("./TitleAndBanner.lua"),

	-- text to display BPM range (and ratemod if ~= 1.0) immediately under the banner
	LoadActor("./BPM_RateMod.lua"),

	-- store some attributes of this playthrough of this song in the global SL table
	-- for later retrieval on ScreenEvaluationSummary
	LoadActor("./GlobalStorage.lua"),

	-- help text that appears if we're in Casual gamemode
	LoadActor("./CasualHelpText.lua")
}



-- Then, load the player-specific actors.
for player in ivalues(Players) do
	local side = player == PLAYER_1 and -1 or 1
	-- the upper half of ScreenEvaluation
	t[#t+1] = Def.ActorFrame{
		Name=ToEnumShortString(player).."_AF_Upper",
		OnCommand=function(self)
			self:x(_screen.cx + 155 * side)
		end,

		-- store player stats for later retrieval on EvaluationSummary and NameEntryTraditional
		LoadActor("./PerPlayer/Storage.lua", player),

		-- letter grade
		LoadActor("./PerPlayer/LetterGrade.lua", player),

		-- nice
		LoadActor("./PerPlayer/nice.lua", player),

		-- stepartist
		LoadActor("./PerPlayer/StepArtist.lua", player),

		-- difficulty text and meter
		LoadActor("./PerPlayer/Difficulty.lua", player),

		-- Record Texts (Machine and/or Personal)
		LoadActor("./PerPlayer/RecordTexts.lua", player)
	}

	-- the lower half of ScreenEvaluation
	local lower = Def.ActorFrame{
		Name=ToEnumShortString(player).."_AF_Lower",
		OnCommand=function(self)
			-- if double style, center the gameplay stats
			if GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides" and SL.Global.GameMode ~= "Experiment" then
				self:x(_screen.cx)
			else
				self:x(_screen.cx + (player==PLAYER_1 and -155 or 155))--GAMESTATE:GetNumSidesJoined()==2 and 155 or -155))
			end
		end,

		-- background quad for player stats
		Def.Quad{
			Name="LowerQuad",
			InitCommand=function(self)
				self:diffuse(color("#1E282F")):y(_screen.cy+34):zoomto( 300,180 )
				if ThemePrefs.Get("RainbowMode") then
					self:diffusealpha(0.9)
				end
			end,
			-- this background Quad may need to shrink and expand if we're playing double
			-- and need more space to accommodate more columns of arrows;  these commands
			-- are queued as needed from the InputHandler
			ShrinkCommand=function(self)
				self:zoomto(300,180):x(0)
			end,
			ExpandCommand=function(self)
				self:zoomto(520,180):x(3)
			end
		},

		-- "Look at this graph."  –Some sort of meme on The Internet
		LoadActor("./PerPlayer/Graphs.lua", {player = player}),

		-- list of modifiers used by this player for this song
		LoadActor("./PerPlayer/PlayerModifiers.lua", player),

		-- was this player disqualified from ranking?
		LoadActor("./PerPlayer/Disqualified.lua", player),
	}
	
	local experimentLower = Def.ActorFrame{
		OnCommand=function(self)
			-- if double style, center the gameplay stats
			if GAMESTATE:GetCurrentStyle():GetStyleType() == "StyleType_OnePlayerTwoSides" and SL.Global.GameMode ~= "Experiment" then
				self:x(_screen.cx)
			else
				self:x(_screen.cx + (player==PLAYER_1 and 155 or -155))--GAMESTATE:GetNumSidesJoined()==2 and 155 or -155))
			end
		end,
	}

	--background quad for additional stats if we're in Experiment mode
	if SL.Global.GameMode == "Experiment" then

		experimentLower[#experimentLower+1] = Def.Quad{
			InitCommand = function(self)
				self:diffuse(color("#1E282F")):y(_screen.cy+34):zoomto( 300,180 )
				if GAMESTATE:GetNumSidesJoined() == 2 then self:diffusealpha(0)
				elseif ThemePrefs.Get("RainbowMode") then
					self:diffusealpha(0.9)
				end
			end,
		}
		if GAMESTATE:GetNumSidesJoined() == 1 then
			experimentLower[#experimentLower+1] = LoadActor("./PerPlayer/Graphs.lua", {player = player, graph = 'density'})..{InitCommand = function(self) end}
		end
	end
	-- Generate a hash once here if we're in Experiment mode and use it for any pane that needs it.
	-- If it doesn't match with what we think it should be then the steps have changed and old scores
	-- are invalid.
	local hash
	if SL.Global.GameMode == "Experiment" then
		local pn = ToEnumShortString(player)
		local stepsType = ToEnumShortString(GetStepsType()):gsub("_","-"):lower()
		local difficulty = ToEnumShortString(GAMESTATE:GetCurrentSteps(pn):GetDifficulty())
		if ThemePrefs.Get("UseCustomScores") then 
			hash = GenerateHash(GAMESTATE:GetCurrentSteps(player),stepsType, difficulty)
			if hash ~= GetHash(player) then AddCurrentHash() end
		end
	end
	
	-- add available Panes to the lower ActorFrame via a loop
	-- Note(teejusb): Some of these actors may be nil. This is not a bug, but
	-- a feature for any panes we want to be conditional (e.g. the QR code).
	for i=1, NumPanes do
		if SL.Global.GameMode == "Experiment" and GAMESTATE:GetNumSidesJoined() == 1 then
			lower[#lower+1] = LoadActor("./PerPlayer/ExperimentPane"..i, {player = player, hash = hash})
		else
			lower[#lower+1] = LoadActor("./PerPlayer/Pane"..i, player)
		end
	end
	-- add lower ActorFrame to the primary ActorFrame
	t[#t+1] = experimentLower
	t[#t+1] = lower
end


return t