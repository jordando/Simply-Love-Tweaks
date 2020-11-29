local player = Var "Player"
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers
local sprite, text

------------------------------------------------------------
-- A profile might ask for a judgment graphic that doesn't exist in the current GameMode
-- If so, use the first available Judgment graphic
-- If that fails too, fail gracefully and do nothing
local mode = SL.Global.GameMode
if mode == "Casual" then mode = "ITG" end
local available_judgments = GetJudgmentGraphics(SL.Global.GameMode)

local file_to_load = (FindInTable(mods.JudgmentGraphic, available_judgments) ~= nil and mods.JudgmentGraphic or available_judgments[1]) or "None"

if file_to_load == "None" then
	return Def.Actor{ InitCommand=function(self) self:visible(false) end }
end

------------------------------------------------------------

local TNSFrames = {
	TapNoteScore_W1 = 0,
	TapNoteScore_W2 = 1,
	TapNoteScore_W3 = 2,
	TapNoteScore_W4 = 3,
	TapNoteScore_W5 = 4,
	TapNoteScore_Miss = 5
}

return Def.ActorFrame{
	Name="Player Judgment",
	InitCommand=function(self)
		local kids = self:GetChildren()
		sprite = kids.JudgmentWithOffsets
		text = kids.EarlyLate
	end,
	JudgmentMessageCommand=function(self, param)
		if param.Player ~= player then return end
		if not param.TapNoteScore then return end
		if param.HoldNoteScore then return end
		-- "frame" is the number we'll use to display the proper portion of the judgment sprite sheet
		-- Sprite actors expect frames to be 0-indexed when using setstate() (not 1-indexed as is more common in Lua)
		-- an early W1 judgment would be frame 0, a late W2 judgment would be frame 3, and so on
		local frame = TNSFrames[ param.TapNoteScore ]
		if not frame then return end

		-- most judgment sprite sheets have 12 frames; 6 for early judgments, 6 for late judgments
		-- some (the original 3.9 judgment sprite sheet for example) do not visibly distinguish
		-- early/late judgments, and thus only have 6 frames
		if sprite:GetNumStates() == 12 then
			frame = frame * 2
			if not param.Early then frame = frame + 1 end
		end
		self:playcommand("Reset")
		-- if we want to use FA+ timing check which of two windows a fantastic is in
		if mods.EnableFAP then
			if param.TapNoteScore == 'TapNoteScore_W1' and math.abs(param.TapNoteOffset) > 0.011000 then
				-- make it slightly darker if lower fantastic. it should be white or whatever
				-- but this should work for now
				sprite:diffuse(.5,.5,.5,1)
				-- current judments don't have an early late for fantastic so we hack one
				-- in with text. doesn't look great but i don't want to require new judgments
				text:x(self:GetX() + sprite:GetWidth()/3 * (param.Early and -1 or 1))
				text:visible(true)
				text:zoom(1.5):decelerate(0.1):zoom(1.25):sleep(0.6):accelerate(0.2):zoom(0)
			else
				sprite:diffuse(Color.White)
			end
		end
		sprite:visible(true):setstate(frame)
		-- this should match the custom JudgmentTween() from SL for 3.95
		sprite:zoom(0.8):decelerate(0.1):zoom(0.75):sleep(0.6):accelerate(0.2):zoom(0)

	end,

	LoadFont("Common Normal")..{
		Name = "EarlyLate",
		Text = "-",
		InitCommand = function(self)
			self:visible(false)
		end,
		ResetCommand = function(self)
			self:finishtweening():stopeffect():visible(false)
		end
	},

	Def.Sprite{
		Name="JudgmentWithOffsets",
		InitCommand=function(self)
			-- animate(false) is needed so that this Sprite does not automatically
			-- animate its way through all available frames; we want to control which
			-- frame displays based on what judgment the player earns
			self:animate(false):visible(false)

			-- if we are on ScreenEdit, judgment graphic is always "Love"
			-- because ScreenEdit is a mess and not worth bothering with.
			if string.match(tostring(SCREENMAN:GetTopScreen()), "ScreenEdit") then
				self:Load( THEME:GetPathG("", "_judgments/ITG/Love") )

			else
				self:Load( THEME:GetPathG("", "_judgments/" .. mode .. "/" .. file_to_load) )
			end
		end,
		ResetCommand=function(self) self:finishtweening():stopeffect():visible(false) end
	}
}
