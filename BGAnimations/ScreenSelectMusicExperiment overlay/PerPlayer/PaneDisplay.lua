local player = ...
local pn = ToEnumShortString(player)

local zoom_factor = WideScale(0.8,0.9)

local labelX_col1 = WideScale(-130,-70)

local highscoreX = WideScale(56, 80)

local InitializeMeasureCounterAndModsLevel = LoadActor("./MeasureCounterAndModsLevel.lua")
local TechParser
if ThemePrefs.Get("EnableTechParser") then TechParser = LoadActor("TechParser.lua") end

--TODO figure out how to change this if a second player joins
local histogramHeight = 40
if not ThemePrefs.Get("ShowExtraSongInfo") then histogramHeight = 30 end --the grid takes a little more space so shrink the histogram a bit

local InitializeDensity = NPS_Histogram(player, 275, histogramHeight)..{
	OnCommand=function(self)
		self:x(labelX_col1)
			:y( _screen.h/3.5+6)
	end
}

local af = Def.ActorFrame{
	Name="PaneDisplay"..ToEnumShortString(player),
	InitCommand=function(self)
		self:visible(GAMESTATE:IsHumanPlayer(player))
		--TODO for now if there's only one player the pane display is on the left. We only put things on the right if two people are joined
		if GAMESTATE:GetNumSidesJoined() ~= 2 then
			self:x(_screen.w * 0.25 - 5)
		else
			if player == PLAYER_1 then
				self:x(_screen.w * 0.25 - 5)
			elseif player == PLAYER_2 then
				self:x( _screen.w * 0.75 + 5)
			end
		end

		self:y(_screen.cy + 5)
	end,
	--we want to set both players when someone joins because we might need to bring the grid back and hide the stream info
	--TODO change this if we can get both players to see stream info
	PlayerJoinedMessageCommand=function(self)
		if player == PLAYER_1 then
			self:x(_screen.w * 0.25 - 5)
		elseif player == PLAYER_2 then
			self:x( _screen.w * 0.75 + 5)
		end
		self:visible(true)
			:zoom(0):croptop(0):bounceend(0.3):zoom(1)
			:playcommand("Set")
		self:GetChild("Measures"):settext("")
		self:GetChild("TotalStream"):settext("")
		self:GetChild("PeakNPS"):settext("")
		self:GetChild("AvgNpsLabel"):settext("")
		self:GetChild("AvgNps"):settext("")
	end,
	PlayerUnjoinedMessageCommand=function(self, params)
		if player==params.Player then
			self:accelerate(0.3):croptop(1):sleep(0.01):zoom(0)
		end
	end,
	--hide everything when left or right is held down for more than a couple songs
	BeginScrollingMessageCommand=function(self)
		self:stoptweening():linear(.3):diffusealpha(0)
	end,
	-- This is set separately because it lags SM if players hold down left or right (to scroll quickly). LessLag will trigger after .15 seconds
	-- with no new song changes.
	LessLagMessageCommand=function(self)
		-- ---------------------Extra Song Information------------------------------------------
		if not GAMESTATE:IsHumanPlayer(player) then return end
		--TODO right now we don't show any of this if two players are joined. I'd like to find a way for both to see it
		self:stoptweening():linear(.3):diffusealpha(1)
		local song = GAMESTATE:GetCurrentSong()
		if not GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentSteps(player) and song and ThemePrefs.Get("ShowExtraSongInfo") and GAMESTATE:GetNumSidesJoined() < 2 then
			InitializeMeasureCounterAndModsLevel(player)
			if SL[pn].Streams.Measures then --used to be working without this... not sure what changed but don't run any of this stuff if measures is not filled in
				if SL[pn].Streams.TotalStreams == 0 then
					self:GetChild("Measures"):settext(THEME:GetString("ScreenSelectMusicExperiment", "NoStream"))
					self:GetChild("TotalStream"):settext("")
				else
					local toWrite = THEME:GetString("ScreenSelectMusicExperiment", "Total").." :"
					local measureType = SL[pn].ActiveModifiers.MeasureCounter
					toWrite = toWrite..SL[pn].Streams.TotalStreams.." ("..SL[pn].Streams.Percent.."%) (>="..measureType
					toWrite = toWrite.." "..THEME:GetString("ScreenSelectMusicExperiment", "NoteStream")..")"
					self:GetChild("Measures"):settext(toWrite)
					if SL[pn].Streams.Segments > 15 then self:GetChild("TotalStream"):settext(SL[pn].Streams.Breakdown3)
					else self:GetChild("TotalStream"):settext(SL[pn].Streams.Breakdown2) end
				end
				local duration = song:MusicLengthSeconds() / SL.Global.ActiveModifiers.MusicRate
				local totalSteps = GAMESTATE:GetCurrentSteps(player):GetRadarValues(player):GetValue('RadarCategory_TapsAndHolds')
				local finalText = totalSteps / duration
				finalText = math.floor(finalText*100)/100 --truncate to two decimals
				self:GetChild("AvgNps"):settext(THEME:GetString("ScreenSelectMusicExperiment", "AvgNps")..": "..finalText)
			else
				if SL[pn].ActiveModifiers.MeasureCounter == "None" then 
					self:GetChild("Measures"):settext(THEME:GetString("ScreenSelectMusicExperiment", "StreamCounterOff"))
				else
					self:GetChild("Measures"):settext(THEME:GetString("ScreenSelectMusicExperiment", "UnableToParse"))
				end
				self:GetChild("TotalStream"):settext("")
				self:GetChild("PeakNPS"):settext("")
				self:GetChild("AvgNps"):settext("")
			end
		else
			self:GetChild("Measures"):settext("")
			self:GetChild("TotalStream"):settext("")
			self:GetChild("PeakNPS"):settext("")
			self:GetChild("AvgNps"):settext("")
			self:GetChild("Tech"):settext("")
		end
	end,
	--TODO part of the pane that gets hidden if two players are joined. i'd like to display this somewhere though
	PeakNPSUpdatedMessageCommand=function(self)
		if not GAMESTATE:IsHumanPlayer(player) then return end
		if GAMESTATE:GetCurrentSong() and
		GAMESTATE:Env()[pn.."PeakNPS"] and
		ThemePrefs.Get("ShowExtraSongInfo") and
		GAMESTATE:GetNumSidesJoined() < 2 and
		GAMESTATE:Env()[pn.."CurrentSteps"] == GAMESTATE:GetCurrentSteps(player)
		then
			self:GetChild("PeakNPS"):settext( THEME:GetString("ScreenGameplay", "PeakNPS") .. ": " .. round(GAMESTATE:Env()[pn.."PeakNPS"] * SL.Global.ActiveModifiers.MusicRate,2))
		else
			self:GetChild("PeakNPS"):settext( "" )
		end
		--make sure we have peaknps set before checking for tech
		if ThemePrefs.Get("EnableTechParser") then
			local tech = TechParser(GAMESTATE:GetCurrentSteps(player),"dance-single",ToEnumShortString(GAMESTATE:GetCurrentSteps(player):GetDifficulty()))
			if tech then 
				self:GetChild("Tech"):settext("XO:"..tech.crossover.." DS:"..tech.doublestep.." FS:"..tech.footswitch)
			else
				self:GetChild("Tech"):settext(THEME:GetString("ScreenSelectMusicExperiment", "UnableToParse"))
			end
		end
	end,
}

--Tech
af[#af+1] = LoadFont("Common Normal")..{
	Name="Tech",
	InitCommand=function(self) self:xy(labelX_col1+20, _screen.h/8 + 30):zoom(zoom_factor):diffuse(Color.White):halign(0):maxwidth(315) end,
}

--PeakNPS
af[#af+1] = LoadFont("Common Normal")..{
	Name="PeakNPS",
	InitCommand=function(self) self:xy(labelX_col1+20, _screen.h/8 - 30):zoom(zoom_factor):diffuse(Color.White):halign(0) end,
}

--AVG NPS
af[#af+1] = LoadFont("Common Normal")..{
	Name="AvgNps",
	InitCommand=function(self) self:xy(highscoreX,_screen.h/8 - 30):zoom(zoom_factor):diffuse(Color.White):halign(0) end,
}

--Total Stream
af[#af+1] = LoadFont("Common Normal")..{
	Name="TotalStream",
	InitCommand=function(self) self:xy(labelX_col1+20, _screen.h/8 + 10):zoom(zoom_factor):diffuse(Color.White):halign(0) end,
}

--Measures
af[#af+1] = LoadFont("Common Normal")..{
	Name="Measures",
	InitCommand=function(self) self:xy(labelX_col1+20, _screen.h/8 - 10):zoom(zoom_factor):diffuse(Color.White):halign(0):maxwidth(315) end,
}

if ThemePrefs.Get("OriginalPaneDisplay") then af[#af+1] = LoadActor("./PaneDisplayOriginal.lua", player)
else af[#af+1] = LoadActor("./PaneDisplayAlternative.lua", player) end

if not GAMESTATE:IsCourseMode() then af[#af+1] =  InitializeDensity end

return af