-- The background for the song

local player = ...

local pane = Def.ActorFrame{
	Name="Pane1",
	InitCommand = function(self) self:visible(false) end,
	ShowPlayerOptionsPane1MessageCommand = function(self, params)
		if params.PlayerNumber == player then self:visible(true) end
	end,
	HidePlayerOptionsPane1MessageCommand = function(self, params) 
		if params.PlayerNumber == player then self:visible(false) end
	end,
	SetOptionPanesMessageCommand=function(self)
		if GAMESTATE:GetCurrentSong():HasBackground() then
			self:GetChild("Background"):visible(true):LoadFromCurrentSongBackground()
		else
			self:GetChild("Background"):visible(false)
		end
	end
}
	
pane[#pane+1] = LoadFont("Wendy/_wendy small")..{
	InitCommand=function(self)
		self:zoom(.5)
		self:settext("NO BACKGROUND")
	end,
}	
	
pane[#pane+1] = Def.Sprite{
	Name="Background",
	InitCommand=function(self)
		self:xy(WideScale(7,-7),5):scaletoclipped(250,175)
	end
}
	
return pane