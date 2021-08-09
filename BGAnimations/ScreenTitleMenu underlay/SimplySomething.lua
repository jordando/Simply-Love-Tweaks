-- use the current game (dance, pump, etc.) to load the apporopriate logo
-- SL currently has logo assets for: dance, pump, techno
--   use the techno logo asset for less common games (para, kb7, etc.)
local game = GAMESTATE:GetCurrentGame():GetName()
if game ~= "dance" and game ~= "pump" then
	game = "techno"
end


-- -----------------------------------------------------------------------
local style = ThemePrefs.Get("VisualStyle")
local image = "TitleMenu"

-- see: watch?v=wxBO6KX9qTA etc.
if FILEMAN:DoesFileExist("/Themes/"..THEME:GetCurThemeName().."/Graphics/_VisualStyles/"..ThemePrefs.Get("VisualStyle").."/TitleMenuAlt (doubleres).png") then
	if math.random(1,100) <= 10 then image="TitleMenuAlt" end
end

-- -----------------------------------------------------------------------
local af = Def.ActorFrame{}
-- Fantasy label
af[#af+1] = LoadActor(THEME:GetPathG("FF", "9logo.png"))..{
	Name="Fantasy",
	InitCommand=function(self)
		self:zoom(0.30):vertalign(top)
		self:y(-200):x(-150):shadowlength(0.75)
	end,
	OffCommand=function(self) self:linear(0.5):shadowlength(0) end
}

-- Fantasy label
af[#af+1] = LoadActor(THEME:GetPathG("FF", "Fantasy.png"))..{
	Name="Fantasy",
	InitCommand=function(self)
		self:zoom(0.30):vertalign(top)
		self:y(-0):shadowlength(0.75)
	end,
	OffCommand=function(self) self:linear(0.5):shadowlength(0) end
}

-- SIMPLY [something]
af[#af+1] = LoadActor(THEME:GetPathG("", "_VisualStyles/"..style.."/"..image.." (doubleres).png"))..{
	Name="Simply Text",
	InitCommand=function(self)
		self:zoom(0.7):vertalign(top)
		self:y(-102):shadowlength(0.75):cropbottom(.5)
	end,
	OffCommand=function(self) self:linear(0.5):shadowlength(0) end
}

-- decorative arrows
af[#af+1] = LoadActor(THEME:GetPathG("", "_logos/" .. game))..{
	InitCommand=function(self)
		self:y(-16)

		-- get a reference to the SIMPLY [something] graphic
		-- it's rasterized text in the Wendy font like "SIMPLY LOVE" or "SIMPLY THONK" or etc.
		local simply = self:GetParent():GetChild("Simply Text")

		-- zoom the logo's width to match the width of the text graphic
		-- zoomtowidth() performs a "horizontal" zoom (on the x-axis) to meet a provided pixel quantity
		--    and leaves the y-axis zoom as-is, potentially skewing/squishing the appearance of the asset
		self:zoomtowidth( simply:GetZoomedWidth() )

		-- so, get the horizontal zoom factor of these decorative arrows
		-- and apply it to the y-axis as well to maintain proportions
		self:zoomy( self:GetZoomX() )
	end
}

return af