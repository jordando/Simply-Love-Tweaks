local player = ...
local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)
local IsUltraWide = (GetScreenAspectRatio() > 21/9)

return Def.Banner{
	CurrentSongChangedMessageCommand=function(self)
		self:LoadFromSong( GAMESTATE:GetCurrentSong() )
		self:setsize(418,164):zoom(0.31)
		self:xy(313, -139)

		-- offset a bit more when NoteFieldIsCentered
		if NoteFieldIsCentered and IsUsingWideScreen() then
			self:x( player==PLAYER_1 and 205 or 60 ):addy(48)
		end

		-- ultrawide and both players joined
		if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
			self:x(self:GetX() * -1)
		end
	end
}