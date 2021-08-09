local args = ...
local row = args[1]
local col = args[2]
local y_offset = args[3]

local af = Def.ActorFrame{
	Name="SongWheelShared",
	InitCommand=function(self) self:y(y_offset) end,
	SwitchFocusToGroupsMessageCommand=function(self) self:smooth(0.3):diffusealpha(0) end,
	SwitchFocusToSongsMessageCommand=function(self) 	self:smooth(.3):diffusealpha(1) end,
	SwitchFocusToSingleSongMessageCommand=function(self) self:smooth(0.3):diffusealpha(0) end
}

local test = false
-----------------------------------------------------------------
-- black background quad
-- this is useful when the background is very light but kinda unnecessary when it's dark
-- so if holiday cheer is on just turn it off
af[#af+1] = Def.Quad{
	Name="SongWheelBackground",
	InitCommand=function(self)
		if HolidayCheer() then self:visible(false) end
		self:zoomto(_screen.w, _screen.h/2.25 - 3):diffuse(0,0,0,1):cropbottom(1)
	end,
	OnCommand=function(self)
		self:xy(_screen.cx, math.ceil((row.how_many-2)/2) * row.h + 36):finishtweening()
		    :accelerate(0.2):cropbottom(0)
			:diffusealpha(.75)
	end,
	SwitchFocusToGroupsMessageCommand=function(self) self:smooth(0.3):cropright(1) end,
	SwitchFocusToSongsMessageCommand=function(self) 	self:smooth(.3):cropright(0) end,
	SwitchFocusToSingleSongMessageCommand=function(self) self:smooth(0.3):cropright(1) end
}

af[#af+1] = Def.Quad{
	InitCommand=function(self)
		self:align(0,0):xy(IsUsingWideScreen() and 0 or 20,240):zoomto(_screen.w / 2 + 50,_screen.h / 8)
		self:diffuseleftedge(color("#23279e")):diffuserightedge(Color.Black)
	end,
		SwitchFocusToGroupsMessageCommand=function(self) self:smooth(0.3):cropright(1) end,
		SwitchFocusToSongsMessageCommand=function(self) 	self:smooth(.3):cropright(0) end,
		SwitchFocusToSingleSongMessageCommand=function(self) self:smooth(0.3):cropright(1) end
}

-- a lightly styled png asset that is not so different than a Quad
af[#af+1] = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(IsUsingWideScreen() and 257 or 180,295)
	end,
	CloseThisFolderHasFocusMessageCommand = function(self) self:stoptweening():smooth(0.3):diffusealpha(0) end, --don't display any of this when we're on the close folder item
	CurrentSongChangedMessageCommand = function(self, params) --brings things back after CloseThisFolderHasFocusMessageCommand runs
		if params.song and self:GetDiffuseAlpha() == 0 then self:stoptweening():smooth(0.3):diffusealpha(1) end end,
	Def.Quad { InitCommand=function(self) self:zoomto(319,205):MaskSource(true) end },
	LoadActor( THEME:GetPathG("FF","CardEdge.png") )..{
		InitCommand=function(self)
			self:diffuse(Color.White)
			self:zoomto(352,227)
			self:MaskDest()
			--if not test then self:visible(false) end
	end,
	},
}

-- rainbow glowing border top
af[#af+1] = Def.Quad{
	InitCommand=function(self) self:zoomto(_screen.w, 1):diffuse(1,1,1,0):xy(_screen.cx, _screen.cy+30 + _screen.h/(row.how_many-2)*-0.5):faderight(10):rainbow() end,
	OnCommand=function(self) self:sleep(0.3):diffusealpha(0.75):queuecommand("FadeMe") end,
	FadeMeCommand=function(self) self:accelerate(1.5):faderight(0):accelerate(1.5):fadeleft(10):sleep(0):diffusealpha(0):fadeleft(0):sleep(1.5):faderight(10):diffusealpha(0.75):queuecommand("FadeMe") end,
	SwitchFocusToGroupsMessageCommand=function(self) self:visible(false) end,
	SwitchFocusToSingleSongMessageCommand=function(self) self:visible(false) end,
	SwitchFocusToSongsMessageCommand=function(self) self:visible(true) end
}

-- rainbow glowing border bottom
af[#af+1] = Def.Quad{
	InitCommand=function(self) self:zoomto(_screen.w, 1):diffuse(1,1,1,0):xy(_screen.cx, _screen.cy+30 + _screen.h/(row.how_many-2) * 0.5):faderight(10):rainbow() end,
	OnCommand=function(self) self:sleep(0.3):diffusealpha(0.75):queuecommand("FadeMe") end,
	FadeMeCommand=function(self) self:accelerate(1.5):faderight(0):accelerate(1.5):fadeleft(10):sleep(0):diffusealpha(0):fadeleft(0):sleep(1.5):faderight(10):diffusealpha(0.75):queuecommand("FadeMe") end,
	SwitchFocusToGroupsMessageCommand=function(self) self:visible(false) end,
	SwitchFocusToSingleSongMessageCommand=function(self) self:visible(false) end,
	SwitchFocusToSongsMessageCommand=function(self) self:visible(true) end
}

return af