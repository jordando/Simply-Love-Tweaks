-- assume that all human players failed
local img = "failed text.png"

-- loop through all available human players
for player in ivalues(GAMESTATE:GetHumanPlayers()) do
	-- if any of them passed, we want to display the "cleared" graphic
	if not STATSMAN:GetCurStageStats():GetPlayerStageStats(player):GetFailed() then
		img = "vic.png"
	end
end

local af = Def.ActorFrame {
	Def.Quad{
		InitCommand=function(self) self:FullScreen():diffuse(Color.Black) end,
		OnCommand=function(self) self:sleep(0.2):linear(0.5):diffusealpha(0) end,
	},
	LoadActor(img)..{
		InitCommand=function(self)
			self:Center():diffusealpha(0)
			if img=="vic.png" then self:zoom(.4):addy(-50):shadowlength(2):diffusetopedge(Color.Yellow) else self:zoom(.8) end
		end,
		OnCommand=function(self) self:accelerate(0.4):diffusealpha(1):sleep(0.6):decelerate(0.4):diffusealpha(0) end
	},
	OffCommand=function(self)
		SOUND:StopMusic()
	end,
}

local audio
if img == "vic.png" then
	audio = THEME:GetPathS("FF","fanfare.ogg")
	if SL.Global.Character and SL.Global.Character.name == "nanami" then
		audio = THEME:GetPathS("FF", "bang clear.ogg")
	end
else
	if SL.Global.Character and SL.Global.Character.name == "nanami" then
		audio = THEME:GetPathS("FF","bang fail.ogg")
	end
end
if audio then
	af[#af+1] = Def.Sound{
		File=audio,
		OnCommand=function(self) self:play() end,
		OffCommand=function(self) self:stop() end
	}
end

return af