local args = ...
local row = args[1]
local col = args[2]
local Input = args[3]

local bg_color = {0,0,0,0.9}
local divider_color = {1,1,1,0.75}

local af = Def.ActorFrame{
	InitCommand=function(self) self:diffusealpha(0) end,
	SwitchFocusToSongsMessageCommand=function(self) self:linear(0.1):diffusealpha(0) end,
	SwitchFocusToGroupsMessageCommand=function(self) self:linear(0.1):diffusealpha(0) end,
	SwitchFocusToSingleSongMessageCommand=function(self) self:sleep(0.3):linear(0.1):diffusealpha(1) end,

	Def.Quad{
		Name="SongInfoBG",
		InitCommand=function(self) self:diffuse(bg_color):zoomto(_screen.w/WideScale(1.15,1.5), row.h) end,
		OnCommand=function(self) self:xy(_screen.cx, _screen.cy - row.h/1.6 ) end,
	},

	Def.Quad{
		Name="PlayerOptionsBG",
		InitCommand=function(self) self:diffuse(bg_color):zoomto(_screen.w/WideScale(1.15,1.5), row.h*1.5) end,
		OnCommand=function(self) self:xy(_screen.cx, _screen.cy + row.h/1.5 ) end,
	},

	Def.Quad{
		Name="PlayerOptionsDivider",
		InitCommand=function(self) self:diffuse(divider_color):zoomto(2, row.h*1.25) end,
		OnCommand=function(self) self:xy(_screen.cx, _screen.cy + row.h/1.5 ) end,
	},
}
local position = GAMESTATE:GetMasterPlayerNumber() == PLAYER_1 and 17 or 440

local extraControl = {}

extraControl["rate"] = LoadFont("Common Normal")..{
	InitCommand=function(self) self:xy(position +_screen.cx / 2.5, _screen.cy + 155 ):zoom(1):diffuse(.6,.6,.6,1):halign(0):valign(0):maxwidth(315) end,
	MusicRateChangedMessageCommand=function(self) self:playcommand("SetText") end,
	StepsHaveChangedMessageCommand=function(self) self:playcommand("SetText") end,
	SetTextCommand = function(self)
		self:settext("BPM: "..StringifyDisplayBPMs())
	end,
}

extraControl["scroll"] = LoadFont("Common Normal")..{
	InitCommand=function(self) 
		self:xy(SL_WideScale(position +_screen.cx / 5, position +_screen.cx / 2.5), _screen.cy + 155 ):zoom(1):diffuse(.6,.6,.6,1):valign(0):maxwidth(315) 
		self:halign(GAMESTATE:GetMasterPlayerNumber() == PLAYER_1 and 0 or 1)
	end,
	StepsHaveChangedMessageCommand=function(self) self:playcommand("SetText") end,
	ScrollSpeedChangedMessageCommand=function(self) self:playcommand("SetText") end,
	SetTextCommand = function(self)
		local player = GAMESTATE:GetMasterPlayerNumber()
		local mods = SL[ToEnumShortString(player)].ActiveModifiers
		local type  = mods.SpeedModType or "X"
		local speed = mods.SpeedMod or 1.00
		if type == "X" then
			local bpms = StringifyDisplayBPMs(player,GAMESTATE:GetCurrentSteps(player), speed)
			self:settext("Speed: "..bpms.." ("..speed.."x)")
		else
			self:settext(type.."mod")
		end
	end,
}

if extraControl[ThemePrefs.Get("ShowExtraControl")] then
	af[#af+1] = extraControl[ThemePrefs.Get("ShowExtraControl")]
end

return af