
local OptionRows = {
	{
		Name = "GoToOptions",
		HelpText = THEME:GetString("ScreenSelectMusicExperiment", "GoToOptions"),
		Choices = function(self) return { "No", "Yes" } end,
		Values = function(self) return { false, true } end,
		OnLoad = function(actor, pn, choices, values)
			local index = 1
			actor:set_info_set(choices, index)
		end,
		OnSave=function(self, pn, choice, choices, values)
			local index = FindInTable(choice, choices)
			SL.Global.GoToOptions = self:Values()[index]
		end,
	},
}
-- ------------------------------------------------------
-- Option Panes
OptionRows[#OptionRows + 1] = {
	Name = "ChangeDisplay",
		HelpText = THEME:GetString("ScreenSelectMusicExperiment", "ChangeDisplay"),
		Choices = function()
			return {
				"Song Background",
				"BPM Helper",
				"Full Breakdown",
			}
		end,
		Values = function() return {1, 2, 3} end,
		OnLoad=function(actor, pn, choices, values)
			actor:set_info_set(choices, SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[pn]]+1)
		end,
		OnSave=function(self, pn, choice, choices, values)
			local index = FindInTable(choice, choices)
			SL.Global['ActivePlayerOptionsPane'..PlayerNumber:Reverse()[pn]] = self:Values()[index] - 1
		end,
}

local extraControl = {}
extraControl["rate"] = {
	Name = "Rate",
	HelpText = "Rate:",
	Choices = function(self) return range(.1, 2, .01) end,
	Values = function(self) return range(.1, 2, .01) end,
	ExportOnChange = true,
	LayoutType = "ShowOneInRow",
	OnLoad = function(actor, pn, choices, values)
		local needle = tostring(SL.Global.ActiveModifiers.MusicRate)
		for i = 1, #choices do
			if needle == tostring(choices[i]) then
				actor:set_info_set(choices, i)
				break
			end
		end
	end,
	OnSave=function(self, pn, choice, choices, values)
		local mods = SL.Global.ActiveModifiers
		local index = FindInTable(choice, choices)
		mods.MusicRate = self:Values()[index]
		GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate( mods.MusicRate )
		MESSAGEMAN:Broadcast("MusicRateChanged")
	end,
}
extraControl["scroll"] = {
	Name = "Scroll",
	HelpText = "Scroll:",
	Choices = function(self) return range(5, 2000, 5) end,
	Values = function(self) return range(5, 2000, 5) end,
	OnLoad = function(actor, pn, choices, values)
		--TODO this only works for MPN
		local player = GAMESTATE:GetMasterPlayerNumber()
		local mods = SL[ToEnumShortString(player)].ActiveModifiers
		local type  = mods.SpeedModType or "X"
		local speed = mods.SpeedMod or 1.00
		if type == "X" then
			local bpm = GetDisplayBPMs(player, GAMESTATE:GetCurrentSteps(player))
			speed = round(bpm[2] * speed / 5) * 5
		end
		local i = FindInTable(speed,choices) or 120
		actor:set_info_set(choices, i)
	end,
	OnSave=function(self, pn, choice, choices, values)
		local player = GAMESTATE:GetMasterPlayerNumber()
		local mods = SL[ToEnumShortString(player)].ActiveModifiers
		local playeroptions = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Preferred")
		local type  = mods.SpeedModType or "X"
		local index = FindInTable(choice, choices)
		if type ~= "X" then
			playeroptions[type.."Mod"](playeroptions, self:Values()[index])
			mods.SpeedMod = self:Values()[index]
		else
			local bpm = GetDisplayBPMs(player, GAMESTATE:GetCurrentSteps(player))
			local x = round(self:Values()[index] / bpm[2] / .05) * .05
			mods.SpeedMod = x
			MESSAGEMAN:Broadcast("ScrollSpeedChanged")
		end
	end,
	ExportOnChange = true,
	LayoutType = "ShowOneInRow",
}

if extraControl[ThemePrefs.Get("ShowExtraControl")] then
	OptionRows[#OptionRows+1] = extraControl[ThemePrefs.Get("ShowExtraControl")]
end

-- add Exit row last
OptionRows[#OptionRows + 1] = {
	Name = "Exit",
	HelpText = "",
}

return OptionRows