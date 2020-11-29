local player, score, controller = unpack(...)

--if we have FA+ tracking enabled then we need to add an extra timing window and shrink everything
local fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false

local TapNoteScores = {}

TapNoteScores.x = { left=64, right=0 }
if fapping  and SL.Global.GameMode == "Experiment" then
	TapNoteScores.Types = { 'W0','W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
else
	TapNoteScores.Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
end


local RadarCategories = {
	Types = { 'Holds', 'Mines', 'Hands', 'Rolls' },
	-- x values for P1 and P2
	x = { left=-180, right=218 }
}


local t = Def.ActorFrame{
	InitCommand=function(self)self:zoom(0.8):xy(90,_screen.cy-24) end,
	OnCommand=function(self)
		-- shift the x position of this ActorFrame to -90 for PLAYER_2
		if controller == "right" then
			self:x( self:GetX() * -1 )
		end
	end,
}

-- we might have to edit the judgement colors/windows if fapping so make a copy to make
-- sure we don't mess with the actual tables
local judgmentColors = DeepCopy( SL.JudgmentColors[SL.Global.GameMode] )
local windows = DeepCopy(SL.Global.ActiveModifiers.TimingWindows)

if fapping then
	table.insert(windows,2,windows[1])
	table.insert(judgmentColors,2,Color.White)
end

-- do "regular" TapNotes first
for i=1,#TapNoteScores.Types do
	local window = TapNoteScores.Types[i]
	local number = score[window]

	-- actual numbers
	t[#t+1] = Def.RollingNumbers{
		Font="Wendy/_ScreenEvaluation numbers",
		InitCommand=function(self)
			self:zoom(0.5):horizalign(right)
			if SL.Global.GameMode ~= "ITG" then
				self:diffuse( judgmentColors[i] )
			end

			-- if some TimingWindows were turned off, the leading 0s should not
			-- be colored any differently than the (lack of) JudgmentNumber,
			-- so load a unique Metric group.
			if windows[i]==false and i ~= #TapNoteScores.Types then
				self:Load("RollingNumbersEvaluationNoDecentsWayOffs")
				self:diffuse(color("#444444"))

			-- Otherwise, We want leading 0s to be dimmed, so load the Metrics
			-- group "RollingNumberEvaluationA"	which does that for us.
			else
				self:Load("RollingNumbersEvaluationA")
			end
		end,
		BeginCommand=function(self)
			self:x( TapNoteScores.x[controller] )
			self:y((i-1)* (fapping and 31 or 35) -20)
			self:targetnumber(number)
		end
	}

end


-- then handle holds, mines, hands, rolls
for index, RCType in ipairs(RadarCategories.Types) do

	local performance = score[RCType]
	local possible = score['possible'..RCType]

	-- player performance value
	t[#t+1] = Def.RollingNumbers{
		Font="Wendy/_ScreenEvaluation numbers",
		InitCommand=function(self) self:zoom(0.5):horizalign(right):Load("RollingNumbersEvaluationB") end,
		BeginCommand=function(self)
			self:y((index-1)*35 + 53)
			self:x( RadarCategories.x[controller] )
			self:targetnumber(performance)
		end
	}

	--  slash
	t[#t+1] = LoadFont("Common Normal")..{
		Text="/",
		InitCommand=function(self) self:diffuse(color("#5A6166")):zoom(1.25):horizalign(right) end,
		BeginCommand=function(self)
			self:y((index-1)*35 + 53)
			self:x( ((controller == "left") and -168) or 230 )
		end
	}

	-- possible value
	t[#t+1] = LoadFont("Wendy/_ScreenEvaluation numbers")..{
		InitCommand=function(self) self:zoom(0.5):horizalign(right) end,
		BeginCommand=function(self)
			self:y((index-1)*35 + 53)
			self:x( ((controller == "left") and -114) or 286 )
			self:settext(("%03.0f"):format(possible))
			local leadingZeroAttr = { Length=3-tonumber(tostring(possible):len()), Diffuse=color("#5A6166") }
			self:AddAttribute(0, leadingZeroAttr )
		end
	}
end

return t