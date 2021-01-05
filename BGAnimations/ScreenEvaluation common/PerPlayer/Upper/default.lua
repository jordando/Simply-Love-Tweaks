-- per-player upper half of ScreenEvaluation

local player = ...

local toReturn = Def.ActorFrame{}

local af = Def.ActorFrame{
	Name=ToEnumShortString(player).."_AF_Upper",
	OnCommand=function(self)
		if player == PLAYER_1 then
			self:x(_screen.cx - 155)
		elseif player == PLAYER_2 then
			self:x(_screen.cx + 155)
		end
	end,
}
-- this will always be in the same place regardless of player number
-- TODO should probably move it somewhere into shared...
if SL.Global.GameMode == "Experiment" then
	toReturn[#toReturn+1] = Def.ActorFrame{
		InitCommand=function(self) self:x(_screen.cx - 155) end,
		Def.Sprite{
			Texture=THEME:GetPathG("FF","CardEdge.png"),
			InitCommand=function(self)
				self:align(0,0):zoomto(666,157):xy(-178,30)
			end
		},
		Def.Quad{
			InitCommand=function(self)
				self:align(0,0):zoomto(610,145):xy(-150,36)
				self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
			end
		}
	}
end

-- letter grade
af[#af+1] = LoadActor("./LetterGrade.lua", player)

-- nice
af[#af+1] = LoadActor("./nice.lua", player)

af[#af+1] = Def.ActorFrame{
	InitCommand=function(self)
		if SL.Global.GameMode == "Experiment" then
			self:y(-5)
		end
	end,
	-- stepartist
	LoadActor("./StepArtist.lua", player),

	-- difficulty text and meter
	LoadActor("./Difficulty.lua", player),
}

-- Record Texts (Machine and/or Personal)
af[#af+1] = LoadActor("./RecordTexts.lua", player)

toReturn[#toReturn+1] = af
return toReturn