local t = ...

local mode = SL.Global.GameMode
if mode == "Experiment" then mode = "ITG" end

for judgment_filename in ivalues( GetJudgmentGraphics(mode) ) do
	if judgment_filename ~= "None" and judgment_filename ~= "ErrorBar" then
		t[#t+1] = LoadActor( THEME:GetPathG("", "_judgments/" .. mode .. "/" .. judgment_filename) )..{
			Name="JudgmentGraphic_"..StripSpriteHints(judgment_filename),
			InitCommand=function(self)
				self:visible(false):animate(false)
				local num_frames = self:GetNumStates()

				for i,window in ipairs(SL.Global.ActiveModifiers.TimingWindows) do
					if window then
						if num_frames == 12 then
							self:setstate((i-1)*2)
						else
							self:setstate(i-1)
						end
						break
					end
				end
			end
		}
	end
end
t[#t+1] = Def.Actor{ Name="JudgmentGraphic_ErrorBar", InitCommand=function(self) self:visible(false) end }
t[#t+1] = Def.Actor{ Name="JudgmentGraphic_None", InitCommand=function(self) self:visible(false) end }
