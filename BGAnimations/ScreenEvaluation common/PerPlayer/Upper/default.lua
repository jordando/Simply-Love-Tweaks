-- per-player upper half of ScreenEvaluation

local player = ...

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

if SL.Global.GameMode == "Experiment" then
	af[#af+1] = Def.Sprite{
		Texture=THEME:GetPathG("FF","CardEdge.png"),
		InitCommand=function(self)
			self:horizalign(left):zoomto(666,135):xy(-178,118)
		end
	}

	af[#af+1] = Def.Quad{
		InitCommand=function(self)
			self:horizalign(left):zoomto(610,125):xy(-150,118)
			self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
		end
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

return af