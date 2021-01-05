-- the best way to spread holiday cheer is singing loud for all to hear
if HolidayCheer() then
	return LoadActor( THEME:GetPathB("", "_shared background/Snow.lua") )
end

return Def.Sprite{
	Texture=THEME:GetPathG("", "videos/dots.mp4"),
	InitCommand=function(self) self:FullScreen() end
}
--[[
local af = Def.ActorFrame{}

-- use the "VisualStyle" ThemePrefs value to generate a proper filepath to the appropriate
-- SharedBackground texture and pass it to Normal.lua and RainbowMode.lua now as this file
-- is being initialized.

-- if the player chooses a different VisualStyle during runtime, MESSAGEMAN will broadcast
-- "BackgroundImageChanged" which we can use in Normal.lua and RainbowMode.lua to Load() the
-- newly-appropriate texture from disk into each Sprite; see also: ./BGAnimations/ScreenOptionsService overlay.lua
local file = THEME:GetPathG("", "_VisualStyles/" .. ThemePrefs.Get("VisualStyle") .. "/SharedBackground.png")

-- a simple Quad to serve as the backdrop
af[#af+1] = Def.Quad{
	InitCommand=function(self) self:FullScreen():Center():diffuse( ThemePrefs.Get("RainbowMode") and Color.White or Color.Black ) end,
	BackgroundImageChangedMessageCommand=function(self)
		THEME:ReloadMetrics() -- is this needed here?  -quietly
		SL.Global.ActiveColorIndex = ThemePrefs.Get("RainbowMode") and 3 or ThemePrefs.Get("SimplyLoveColor")
		self:linear(1):diffuse( ThemePrefs.Get("RainbowMode") and Color.White or Color.Black )
	end
}

af[#af+1] = LoadActor("./Normal.lua", file)
af[#af+1] = LoadActor("./RainbowMode.lua", file)

return af
]]--