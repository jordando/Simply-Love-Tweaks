-- In this file, we're storing the extra fantastic window if a player has it enabled
--
-- Similar to PerColumnJudgmentTracking.lua, this file doesn't override or recreate the engine's
-- judgment system in any way. It just allows transient judgment data to persist beyond ScreenGameplay.
------------------------------------------------------------

local player = ...
local W0 = 0

return Def.Actor{
	JudgmentMessageCommand=function(self, params)
		if params.Player ~= player then return end
		if params.HoldNoteScore then return end

        if params.TapNoteOffset then
            local tns = ToEnumShortString(params.TapNoteScore)
            if tns == 'W1' and math.abs(params.TapNoteOffset) < SL.Preferences.Experiment["TimingWindowSecondsW0"] * PREFSMAN:GetPreference("TimingWindowScale") + SL.Preferences[SL.Global.GameMode]["TimingWindowAdd"] then
                W0 = W0 + 1
            end
		end
	end,
	OffCommand=function(self)
		local storage = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1]
		storage.W0 = W0
	end
}