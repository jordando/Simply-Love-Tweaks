--provides the difference in each judgment between your best/previous best and your current score

local player, currentScore, comparisonScore, controller = unpack(...)

local deltaPosition = controller == "right" and -250 or 175
local fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false

local deltaT = Def.ActorFrame{
	InitCommand=function(self) self:y(_screen.cy-92):zoom(.55) end,
}

local TapNoteScores = {}
if fapping  and SL.Global.GameMode == "Experiment" then
	TapNoteScores.Types = { 'W0','W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
else
	TapNoteScores.Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
end

local windows = DeepCopy(SL.Global.ActiveModifiers.TimingWindows)

if fapping then
	table.insert(windows,2,windows[1])
end

-- do "regular" TapNotes first
for i=1,#TapNoteScores.Types do
    if windows[i] or i==#TapNoteScores.Types then
        local window = TapNoteScores.Types[i]
        --delta between current stats and highscore stats
        deltaT[#deltaT+1] = LoadFont("Wendy/_wendy small")..{
            InitCommand=function(self)
                local toPrint
                toPrint = currentScore[window] - comparisonScore[window]
                if toPrint >= 0 then self:settext("+"..toPrint)
                else self:settext(toPrint) end
                self:horizalign(left)
                self:y((i-1)* (fapping and 61 or 69) )
                
                if toPrint > 0 then
                    if window == "Miss" then self:diffuse(Color.Red)
                    else
                        if fapping then
                            if window == "W0" then self:diffuse(Color.Green) end
                        elseif window == "W1" then self:diffuse(Color.Green) end
                    end
                elseif toPrint < 0 and window == "Miss" then self:diffuse(Color.Green)
                elseif fapping and window == "W0" and toPrint ~= 0 then self:diffuse(Color.Red)
                elseif not fapping and window == "W1" and toPrint ~= 0 then self:diffuse(Color.Red)
                else self:diffuse(Color.White) end
            end,
        }
    end
end

return deltaT