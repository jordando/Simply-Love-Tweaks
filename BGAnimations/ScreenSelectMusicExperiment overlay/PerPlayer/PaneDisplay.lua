local player = ...
local pn = ToEnumShortString(player)

local zoom_factor = WideScale(0.8,0.9)

local labelX_col1 = IsUsingWideScreen() and WideScale(-100,-90) or -170

local InitializeMeasureCounterAndModsLevel = LoadActor(THEME:GetPathB("","_modules/MeasureCounterAndModsLevel.lua"))
local TechParser
if ThemePrefs.Get("EnableTechParser") then TechParser = LoadActor(THEME:GetPathB("","_modules/TechParser.lua")) end

--TODO figure out how to change this if a second player joins
local histogramHeight = 40
if not ThemePrefs.Get("ShowExtraSongInfo") then histogramHeight = 30 end --the grid takes a little more space so shrink the histogram a bit

local InitializeDensity = NPS_Histogram(player, 275, histogramHeight)..{
	OnCommand=function(self)
		self:x(labelX_col1+20)
			:y( _screen.h/3.5+3)
	end,
	GroupTypeChangedMessageCommand=function(self)
		if SL.Global.GroupType == "Courses" then self:visible(false)
		else self:visible(true) end
	end
}

local af = Def.ActorFrame{
	Name="PaneDisplay"..ToEnumShortString(player),
	InitCommand=function(self)
		self:visible(GAMESTATE:IsHumanPlayer(player))
		--TODO for now if there's only one player the pane display is on the left. We only put things on the right if two people are joined
		if GAMESTATE:GetNumSidesJoined() ~= 2 then
			self:x(_screen.w * 0.25 - WideScale(-50,5))
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
		self:GetChild("Breakdown"):settext("")
		self:GetChild("PeakNPS"):settext("")
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
		if SL.Global.Debug then Trace("Running LessLagMessageCommand") end
		--TODO right now we don't show any of this if two players are joined. I'd like to find a way for both to see it
		self:stoptweening():linear(.3):diffusealpha(1)
		local song = GAMESTATE:GetCurrentSong()
		local steps = GAMESTATE:GetCurrentSteps(player)
		if not GAMESTATE:IsCourseMode() and steps and song and ThemePrefs.Get("ShowExtraSongInfo") and GAMESTATE:GetNumSidesJoined() < 2 then
			local hash = GetCurrentHash(player)
			local streamData = GetStreamData(hash)
			local non16thMeasureCounter = true
			-- Saved data is in 16ths so check here that we're not trying to use 12ths or 24ths or anything
			if SL[pn].ActiveModifiers.MeasureCounter == "None" or SL[pn].ActiveModifiers.MeasureCounter == "16th" then
				non16thMeasureCounter = false
			end
			-- If we have stream data saved then we don't need to parse the chart to get it.
			if streamData and streamData.TotalMeasures and not non16thMeasureCounter then
				SL[pn].Streams = streamData
			else
				--clear out whatever might have been in Streams and try to parse the chart
				SL[pn].Streams = {}
				InitializeMeasureCounterAndModsLevel()
			end
			self:GetChild("Measures"):ClearAttributes()
			self:GetChild("Breakdown"):diffuse(Color.White)
			if SL[pn].Streams.TotalMeasures then --used to be working without this... not sure what changed but don't run any of this stuff if measures is not filled in
				if SL[pn].Streams.TotalStreams == 0 then
					self:GetChild("Measures"):settext(THEME:GetString("ScreenSelectMusicExperiment", "NoStream").." ("..SL[pn].ActiveModifiers.MeasureCounter..")")
					self:GetChild("Breakdown"):settext("")
				else
					-- check if streams are at a higher quantization. right now we're just doing
					-- basic testing. if the mode NPS is 1.25, 1.5, 1.75, or 2x higher than display
					-- then we'll assume it's 20ths, 24ths, etc etc. and adjust the stream data
					-- to reflect that.
					local multiplier = GetNoteQuantization(steps)
					local toWrite = THEME:GetString("ScreenSelectMusicExperiment", "Total").." :"
					local begin = toWrite:len()
					local begin2
					local length = tostring(round(SL[pn].Streams.TotalStreams * multiplier,0)):len()
					local measureType = SL[pn].ActiveModifiers.MeasureCounter == "None" and "16th" or SL[pn].ActiveModifiers.MeasureCounter
					local breakdown
					toWrite = toWrite..(round(SL[pn].Streams.TotalStreams * multiplier, 0))
					if SL[pn].Streams.TotalStreams ~= "0" then
							toWrite = toWrite.." ("..SL[pn].Streams.Percent.."%)"
						if SL[pn].Streams.Percent ~=  SL[pn].Streams.AdjustedPercent then
							toWrite = toWrite.. " (adj. "..SL[pn].Streams.AdjustedPercent.."%)"
						end
						begin2 = toWrite:len()
						toWrite = toWrite.." ("..(measureType:match("%d+") * multiplier).."th "..THEME:GetString("ScreenSelectMusicExperiment", "Stream")..")"
						breakdown = SL[pn].Streams.Breakdown2
						if string.len(breakdown) > 35 then breakdown = SL[pn].Streams.Breakdown3 end
						self:GetChild("Breakdown"):settext(breakdown)
					else
						self:GetChild("Breakdown"):settext("")
					end
					self:GetChild("Measures"):settext(toWrite)
					if multiplier > 1 then
						self:GetChild("Measures"):AddAttribute(begin, { Length = length; Diffuse = Color.Red })
						self:GetChild("Measures"):AddAttribute(begin2,{ Length = -1,Diffuse = Color.Red })
						breakdown = breakdown:gsub("(%d+)",function(x) return round(x * multiplier,0) end)
						self:GetChild("Breakdown"):settext(breakdown):diffuse(Color.Red)
					end
				end
			else
				if SL[pn].ActiveModifiers.MeasureCounter == "None" then
					self:GetChild("Measures"):settext(THEME:GetString("ScreenSelectMusicExperiment", "StreamCounterOff"))
				else
					self:GetChild("Measures"):settext(THEME:GetString("ScreenSelectMusicExperiment", "UnableToParse"))
				end
				self:GetChild("Breakdown"):settext("")
				self:GetChild("PeakNPS"):settext("")
			end
		else
			self:GetChild("Measures"):settext("")
			self:GetChild("Breakdown"):settext("")
			self:GetChild("PeakNPS"):settext("")
			self:GetChild("Tech"):settext("")
		end
	end,
	--TODO part of the pane that gets hidden if two players are joined. i'd like to display this somewhere though
	PeakNPSUpdatedMessageCommand=function(self)
		if not GAMESTATE:IsHumanPlayer(player) then return end
		if SL.Global.Debug then Trace("Running PeakNPSUpdatedMessageCommand") end
		if GAMESTATE:GetCurrentSong() and
		GAMESTATE:Env()[pn.."PeakNPS"] and
		ThemePrefs.Get("ShowExtraSongInfo") and
		GAMESTATE:GetNumSidesJoined() < 2 and
		GAMESTATE:Env()[pn.."CurrentSteps"] == GAMESTATE:GetCurrentSteps(player)
		then
			local hash = GetCurrentHash(player)
			local streamData = GetStreamData(hash)
			local mode
			if streamData and streamData.NpsMode then mode = tonumber(streamData.NpsMode) * SL.Global.ActiveModifiers.MusicRate end
			local peak = GAMESTATE:Env()[pn.."PeakNPS"] * SL.Global.ActiveModifiers.MusicRate
			local conversion = peak / 16 * 240
			if mode and round(peak,2) ~= round(mode,2) then
				local modeConversion = mode / 16 * 240
				self:GetChild("PeakNPS"):settext( "Peak Speed: " .. round(conversion,0) .." BPM / Mode Speed: "..round(modeConversion,0).. " BPM")
			else
				self:GetChild("PeakNPS"):settext("Peak Speed: " .. round(conversion,0) .. " BPM 16ths")
			end
			if ThemePrefs.Get("EnableTechParser") then
				local tech = TechParser(GAMESTATE:GetCurrentSteps(player),"dance-single",ToEnumShortString(GAMESTATE:GetCurrentSteps(player):GetDifficulty()))
				if tech then
					self:GetChild("Tech"):settext("XO:"..tech.crossover.." DS:"..tech.doublestep.." FS:"..tech.footswitch.." JS:"..tech.jumpstream)
					SL[ToEnumShortString(player)]["ParsedSteps"] = tech.parsedSteps
				else
					SL[ToEnumShortString(player)]["ParsedSteps"] = nil
					self:GetChild("Tech"):settext(THEME:GetString("ScreenSelectMusicExperiment", "UnableToParse"))
				end
			--even if tech is turned off we want to clear out the steps so screeneval regenerates per song
			else
				SL[ToEnumShortString(player)]["ParsedSteps"] = nil
			end
		else
			SL[ToEnumShortString(player)]["ParsedSteps"] = nil
			self:GetChild("PeakNPS"):settext( "" )
			self:GetChild("Tech"):settext( "" )
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

--Breakdown
af[#af+1] = LoadFont("Common Normal")..{
	Name="Breakdown",
	InitCommand=function(self) self:xy(labelX_col1+20, _screen.h/8 + 10):zoom(zoom_factor):diffuse(Color.White):halign(0) end,
}

--Measures
af[#af+1] = LoadFont("Common Normal")..{
	Name="Measures",
	InitCommand=function(self) self:xy(labelX_col1+20, _screen.h/8 - 10):zoom(zoom_factor):diffuse(Color.White):halign(0):maxwidth(315) end,
}

--frame for chart statistics
af[#af+1] = LoadActor( THEME:GetPathG("FF","CardEdge.png") )..{
	InitCommand=function(self)
		self:diffuse(Color.White)
		self:zoomto(450, 450)
		self:MaskDest():xy(IsUsingWideScreen() and 0 or -75,350)
	end,
}
-- colored background for chart statistics
af[#af+1] = Def.Quad {
	Name = "BackgroundQuad",
	InitCommand = function(self)
		self:zoomto(_screen.w / 2 - WideScale(-87,18), _screen.h / 8 + 1)
		:xy(IsUsingWideScreen() and 0 or -75,_screen.h / 2 - 67):visible(false)
		if GAMESTATE:IsHumanPlayer(player) then
			self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black):visible(true)
		end
	end
}

if ThemePrefs.Get("OriginalPaneDisplay") then 
	af[#af+1] = LoadActor("./PaneDisplayOriginal.lua", player)..{
		InitCommand = function(self)
			if not IsUsingWideScreen() then self:x(-50) end
		end,
	}
else
	af[#af+1] = LoadActor("./PaneDisplayAlternative.lua", player)..{
		InitCommand = function(self)
			if not IsUsingWideScreen() then self:x(-50) end
		end,
	}
end

if not GAMESTATE:IsCourseMode() then af[#af+1] =  InitializeDensity end

return af