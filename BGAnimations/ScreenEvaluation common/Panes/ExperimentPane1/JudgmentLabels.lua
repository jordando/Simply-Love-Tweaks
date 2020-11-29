local player, score, controller = unpack(...)

local tns_string = "TapNoteScore" .. (SL.Global.GameMode=="ITG" and "" or SL.Global.GameMode)

--if we have FA+ tracking enabled then we need to add an extra timing window and shrink everything
local fapping = SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and true or false

local GetTNSStringFromTheme = function( arg )
	return THEME:GetString(tns_string, arg)
end

-- iterating through the TapNoteScore enum directly isn't helpful because the
-- sequencing is strange, so make our own data structures for this purpose
local TapNoteScores = {}
if SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP  and SL.Global.GameMode == "Experiment" then
	TapNoteScores.Types = { 'W0','W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
else
	TapNoteScores.Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
end
TapNoteScores.Names = map(GetTNSStringFromTheme, TapNoteScores.Types)

local RadarCategories = {
	THEME:GetString("ScreenEvaluation", 'Holds'),
	THEME:GetString("ScreenEvaluation", 'Mines'),
	THEME:GetString("ScreenEvaluation", 'Hands'),
	THEME:GetString("ScreenEvaluation", 'Rolls')
}

local t = Def.ActorFrame{
	InitCommand=function(self)
		self:xy(50 * (controller=="left" and 1 or -1), _screen.cy-24)
	end,
}

local windows = DeepCopy(SL.Global.ActiveModifiers.TimingWindows)
local judgmentColors = DeepCopy( SL.JudgmentColors[SL.Global.GameMode] )

if fapping then
	table.insert(windows,2,windows[1])
	table.insert(judgmentColors,2,Color.White)
end
--  labels: W1, W2, W3, W4, W5, Miss
for i=1, #TapNoteScores.Types do
	-- no need to add BitmapText actors for TimingWindows that were turned off
	if windows[i] or i==#TapNoteScores.Types then

		t[#t+1] = LoadFont("Common Normal")..{
			Text=TapNoteScores.Names[i]:upper(),
			InitCommand=function(self) self:zoom(0.833):horizalign(right):maxwidth(76) end,
			BeginCommand=function(self)
				self:x( controller == "left" and 28 or -28 )
				self:halign( controller == "left" and 1 or 0)
				self:y((i-1)* (fapping and 25 or 28) -16)
				-- diffuse the JudgmentLabels the appropriate colors for the current GameMode
				self:diffuse(judgmentColors[i] )
			end
		}
	end
end

-- labels: holds, mines, hands, rolls
for index, label in ipairs(RadarCategories) do

	t[#t+1] = LoadFont("Common Normal")..{
		Text=label,
		InitCommand=function(self) self:zoom(0.833):horizalign(right) end,
		BeginCommand=function(self)
			self:x( (controller == "left" and -160) or 85 )
			self:y((index-1)*28 + 41)
		end
	}
end

return t