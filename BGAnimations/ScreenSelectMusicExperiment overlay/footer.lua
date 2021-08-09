local af = Def.ActorFrame {
	Def.Sprite{
		Texture=THEME:GetPathG("FF","SkinnyCard.png"),
		InitCommand=function(self) self:align(0,1):zoomto(_screen.w+105,275):xy(-45,_screen.h+218) end
	},
	Def.Quad{
		Name="Footer",
		InitCommand=function(self)
			self:zoomto(_screen.w, 32):vertalign(bottom):halign(0):y(_screen.h)
			self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
		end,
	},

	
}
for player in ivalues({PLAYER_1, PLAYER_2}) do
	af[#af+1] = LoadActor("./PerPlayer/FooterHelpText.lua", player)
end

return af