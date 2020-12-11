local scrollers = {}
scrollers[PLAYER_1] = setmetatable({disable_wrapping=true}, sick_wheel_mt)
scrollers[PLAYER_2] = setmetatable({disable_wrapping=true}, sick_wheel_mt)

local mpn = GAMESTATE:GetMasterPlayerNumber()

local firstToUpper = function(str)
    return (str:gsub("^%l", string.upper))
end

local conversions = {
	min = "Min",
	max = "Max",
	jumps = "Jumps",
	bpm = "BPM",
	diff = "Difficulty",
	steps = "Steps"
}
conversions["="] = function(type,result)
	return "both", result
end
conversions["<="] = function(type,result)
	return "Max", result
end
conversions["<"] = function(type,result)
	return "Max", result - 1
end
conversions[">="] = function(type,result)
	return "Min", result
end
conversions[">"] = function(type,result)
	return "Min", result + 1
end
local QuickFilter = function(input)
	local filters = {"jumps","steps","bpm","diff"}
	local category, result, type
	for filter in ivalues(filters) do
		category = filter
		type, result = string.lower(input):match("^"..filter.."%s*([<>]?=)%s*(%d+)$")
		if type then
			type, result = conversions[type](type, result)
			break
		end
		type, result = string.lower(input):match("^"..filter.."%s*([<>])%s*(%d+)$")
		if type then
			type, result = conversions[type](type, result)
			break
		end
		type, result = string.lower(input):match("^(min)"..filter.."%s*=%s*(%d*)$")
		if result then type = firstToUpper(type) break end
		type, result = string.lower(input):match("^(max)"..filter.."%s*=%s*(%d*)$")
		if result then type = firstToUpper(type) break end
	end
	if result then
		if type == "both" then
			SL.Global.ActiveFilters["Max"..conversions[category]] = tostring(result)
			SL.Global.ActiveFilters["Min"..conversions[category]] = tostring(result)
		else
			SL.Global.ActiveFilters[type..conversions[category]] = tostring(result)
		end
		return true
	end
	return nil
end
local searchMenu_input

local TextEntrySettings = {
	-- ScreenMessage to send on pop (optional, "SM_None" if omitted)
	--SendOnPop = "",

	-- The question to display
	Question = "Search:",
	
	-- Initial answer text
	InitialAnswer = "",
	
	-- Maximum amount of characters
	MaxInputLength = 30,
	
	--Password = false,
	
	-- Validation function; function(answer, errorOut), must return boolean, string.
	Validate = function(answer, errorOut)
		return true, answer
	end,
	
	-- On OK; function(answer)
	OnOK = function(answer)
		if answer == "" then MESSAGEMAN:Broadcast("FinishText") --if players who don't have a keyboard get here they can just hit enter to cancel out
		else
			local filter = QuickFilter(answer)
			if filter then
				MESSAGEMAN:Broadcast("GroupTypeChanged")
				MESSAGEMAN:Broadcast("FinishText")
			else
				MESSAGEMAN:Broadcast("SetSearchWheel",{searchTerm=answer})
			end
		end
	end,
	
	-- On Cancel; function()
	OnCancel = function()
		MESSAGEMAN:Broadcast("FinishText")
	end,
	
	-- Validate appending a character; function(answer,append), must return boolean
	ValidateAppend = nil,
	
	-- Format answer for display; function(answer), must return string
	FormatAnswerForDisplay = nil,
}

-- ----------------------------------------------------
local invalid_count = 0
local ready = false
local t = Def.ActorFrame {

	ShowCustomSongMenuCommand=function(self) self:visible(true) end,
	HideCustomSongMenuCommand=function(self) self:visible(false) end,
	-- FIXME: stall for 0.5 seconds so that the Lua InputCallback doesn't get immediately added to the screen.
	-- It's otherwise possible to enter the screen with MenuLeft/MenuRight already held and firing off events,
	-- which causes the sick_wheel of profile names to not display.  I don't have time to debug it right now.
	InitCommand=function(self)
		self:visible(false)
		searchMenu_input = LoadActor("./Input.lua", {af=self, Scrollers=scrollers})
	end,
	SetSearchWheelMessageCommand=function(self)
		--self:visible(true):sleep(.5):queuecommand("CaptureTest")
		--Tentative fix for computers take more than .3 seconds to load search.
		--Test on slow computer
		self:visible(true):sleep(.8):queuecommand("WaitForSearch")
	end,
	WaitForSearchCommand = function(self)
		if ready then self:queuecommand("CaptureTest")
		else self:sleep(.1):queuecommand("WaitForSearch")
		end
	end,
	CaptureTestCommand=function(self)
		SCREENMAN:GetTopScreen():AddInputCallback( searchMenu_input )
	end,
	SearchCaptureReadyMessageCommand=function()
		ready = true
	end,
	DirectInputToSearchMenuCommand=function(self)
		SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
		SCREENMAN:GetTopScreen():Load(TextEntrySettings)
	end,
	-- the OffCommand will have been queued, when it is appropriate, from ./Input.lua
	-- sleep for 0.5 seconds to give the PlayerFrames time to tween out
	-- and queue a call to Finish() so that the engine can wrap things up
	OffCommand=function(self)
		self:sleep(0.5):queuecommand("Finish")
	end,
	FinishTextMessageCommand=function(self)
		self:sleep(0.5):queuecommand("Finish")
	end,
	FinishCommand=function(self)
		self:visible(false)
		local screen   = SCREENMAN:GetTopScreen()
		local overlay  = screen:GetChild("Overlay")
		screen:RemoveInputCallback( searchMenu_input)
		overlay:queuecommand("DirectInputToEngine")
	end,
	WhatMessageCommand=function(self) self:runcommandsonleaves(function(subself) if subself.distort then subself:distort(0.5) end end):sleep(4):queuecommand("Undistort") end,
	UndistortCommand=function(self) self:runcommandsonleaves(function(subself) if subself.distort then subself:distort(0) end end) end,
	-- sounds
	LoadActor( THEME:GetPathS("Common", "start") )..{
		StartButtonMessageCommand=function(self) self:play() end
	},
	LoadActor( THEME:GetPathS("ScreenSelectMusic", "select down") )..{
		BackButtonMessageCommand=function(self) self:play() end
	},
	LoadActor( THEME:GetPathS("ScreenSelectMaster", "change") )..{
		DirectionButtonMessageCommand=function(self)
			self:play()
			if invalid_count then invalid_count = 0 end
		end
	},
	LoadActor( THEME:GetPathS("Common", "invalid") )..{
		InvalidChoiceMessageCommand=function(self)
			self:play()
			if invalid_count then
				invalid_count = invalid_count + 1
				if invalid_count >= 10 then MESSAGEMAN:Broadcast("What"); invalid_count = nil end
			end
		end
	},
	-- slightly darken the entire screen
	Def.Quad {
		InitCommand=function(self) self:FullScreen():diffuse(Color.Black):diffusealpha(0.8) end
	},
}

-- top mask
t[#t+1] = Def.Quad{
	InitCommand=function(self) self:horizalign(left):vertalign(bottom):setsize(580,50):xy(_screen.cx-self:GetWidth()/2, _screen.cy-110):MaskSource() end
}
-- bottom mask
t[#t+1] = Def.Quad{
	InitCommand=function(self) self:horizalign(left):vertalign(top):setsize(580,120):xy(_screen.cx-self:GetWidth()/2, _screen.cy+111):MaskSource() end
}

-- Both players will share this so just set it based on master player number
t[#t+1] = LoadActor("PlayerFrame.lua", {Player=mpn, Scroller=scrollers[mpn]})

return t