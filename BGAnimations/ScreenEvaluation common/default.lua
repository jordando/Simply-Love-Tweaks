local Players = GAMESTATE:GetHumanPlayers()
local NumPanes = SL.Global.GameMode=="Casual" and 1 or 6

if SL.Global.GameMode == "Experiment" then
	if GetStepsType() == "StepsType_Dance_Double" or GAMESTATE:IsCourseMode() then
		NumPanes = 4
	elseif #GAMESTATE:GetHumanPlayers() == 1 then
		NumPanes = 5
	end
end

local altPanes = {'ExperimentPane1_Alt','ExperimentPane5_Alt'}

local hash

local t = Def.ActorFrame{}

if SL.Global.GameMode ~= "Casual" then
	-- add a lua-based InputCallback to this screen so that we can navigate
	-- through multiple panes of information; pass a reference to this ActorFrame
	-- and the number of panes there are to InputHandler.lua
	t.OnCommand=function(self)
		if SL.Global.GameMode ~= "Casual" then
			SCREENMAN:GetTopScreen():AddInputCallback( LoadActor("./InputHandler.lua", {self, NumPanes, altPanes}) )
		end
	end
	t.OffCommand=function(self)
		for player in ivalues(GAMESTATE:GetHumanPlayers()) do
			if SL.Global.GameMode == "Experiment" then AddScore(player, hash) end
		end
	end
end

-- -----------------------------------------------------------------------
-- Player-specific actors.

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
		if hash ~= GetCurrentHash(player) then AddCurrentHash() end

		if not SL[ToEnumShortString(player)]["ParsedSteps"] then
			TechParser = LoadActor(THEME:GetPathB("","_modules/TechParser.lua"))
			local tech = TechParser(GAMESTATE:GetCurrentSteps(player),"dance-single",ToEnumShortString(GAMESTATE:GetCurrentSteps(player):GetDifficulty()))
			if tech then SL[ToEnumShortString(player)]["ParsedSteps"] = tech.parsedSteps end
		end
	end
end

-- -----------------------------------------------------------------------
-- Shared actors

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
-- Character if there's only one player
if #GAMESTATE:GetHumanPlayers() == 1 then
	t[#t+1] = LoadActor("./Character.lua", GAMESTATE:GetMasterPlayerNumber())
end

t[#t+1] = LoadActor("./Panes/default.lua", {NumPanes = NumPanes,hash = hash, AltPanes = altPanes})

t[#t+1] = Def.Sprite{
	Name="cursor",
	Texture=THEME:GetPathG("FF","finger.png"),
	InitCommand=function(self) self:xy(_screen.cx-10, _screen.cy+110):zoom(.15):visible(false) end,
}

return t