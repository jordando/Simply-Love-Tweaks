local Players = GAMESTATE:GetHumanPlayers()
local NumPanes = SL.Global.GameMode=="Casual" and 1 or 6

local hash

local t = Def.ActorFrame{}

if SL.Global.GameMode ~= "Casual" then
	-- add a lua-based InputCallback to this screen so that we can navigate
	-- through multiple panes of information; pass a reference to this ActorFrame
	-- and the number of panes there are to InputHandler.lua
	t.OnCommand=function(self)
		if SL.Global.GameMode ~= "Casual" then
			SCREENMAN:GetTopScreen():AddInputCallback( LoadActor("./InputHandler.lua", {self, NumPanes}) )											  
		end
	end
	t.OffCommand=function(self)
		for player in ivalues(GAMESTATE:GetHumanPlayers()) do
			if SL.Global.GameMode == "Experiment" then AddScore(player, hash) end
		end
	end
end

-- -----------------------------------------------------------------------
-- First, add actors that would be the same whether 1 or 2 players are joined.

-- code for triggering a screenshot and animating a "screenshot" texture
t[#t+1] = LoadActor("./Shared/ScreenshotHandler.lua")

-- the title of the song and its graphical banner, if there is one
t[#t+1] = LoadActor("./Shared/TitleAndBanner.lua")

-- text to display BPM range (and ratemod if ~= 1.0) immediately under the banner
t[#t+1] = LoadActor("./Shared/BPM_RateMod.lua")

-- store some attributes of this playthrough of this song in the global SL table
-- for later retrieval on ScreenEvaluationSummary
t[#t+1] = LoadActor("./Shared/GlobalStorage.lua")

-- help text that appears if we're in Casual gamemode
t[#t+1] = LoadActor("./Shared/CasualHelpText.lua")

-- -----------------------------------------------------------------------
-- Then, load player-specific actors.

for player in ivalues(Players) do

	-- store player stats for later retrieval on EvaluationSummary and NameEntryTraditional
	-- this doesn't draw anything to the screen, it just runs some code
	t[#t+1] = LoadActor("./PerPlayer/Storage.lua", player)

	-- the per-player upper half of ScreenEvaluation, including: letter grade, nice
	-- stepartist, difficulty text, difficulty meter, machine/personal HighScore text
	t[#t+1] = LoadActor("./PerPlayer/Upper/default.lua", player)

	-- the per-player lower half of ScreenEvaluation, including: judgment scatterplot,
	-- modifier list, disqualified text, and panes 1-6
	t[#t+1] = LoadActor("./PerPlayer/Lower/default.lua", player)

	-- Generate a hash once here if we're in Experiment mode and use it for any pane that needs it.
	-- If it doesn't match with what we think it should be then the steps have changed and old scores
	-- are invalid.
	if SL.Global.GameMode == "Experiment" then
		local pn = ToEnumShortString(player)
		local stepsType = ToEnumShortString(GetStepsType()):gsub("_","-"):lower()
		local difficulty = ToEnumShortString(GAMESTATE:GetCurrentSteps(pn):GetDifficulty())
		hash = GenerateHash(GAMESTATE:GetCurrentSteps(player),stepsType, difficulty)
		if hash ~= GetHash(player) then AddCurrentHash() end
	end
end

-- -----------------------------------------------------------------------

t[#t+1] = LoadActor("./Panes/default.lua", {NumPanes = NumPanes,hash = hash})

return t