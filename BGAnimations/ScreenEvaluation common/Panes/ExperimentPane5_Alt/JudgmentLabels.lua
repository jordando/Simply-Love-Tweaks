local args = ...
local player = args.player
local pn = ToEnumShortString(player)

local tns_string = "TapNoteScore" .. (SL.Global.GameMode=="ITG" and "" or SL.Global.GameMode)

-- iterating through the TapNoteScore enum directly isn't helpful because the
-- sequencing is strange, so make our own data structures for this purpose
local TapNoteScores = {}
TapNoteScores.Types = { 'W4', 'W5', 'Miss', 'W4', 'W5', 'Miss' }
TapNoteScores.Names = {'Repeated DECENT', 'Repeated WAY OFF', 'Repeated MISS', 'Candle DECENT', 'Candle WAY OFF', 'Candle MISS'}

-- get TNS names appropriate for the current GameMode, localized to the current language
for i, judgment in ipairs(TapNoteScores.Types) do
	TapNoteScores.Names[#TapNoteScores.Names+1] = THEME:GetString(tns_string, judgment)
end

local box_height = 146
local row_height = box_height/#TapNoteScores.Types

local t = Def.ActorFrame{
	InitCommand=function(self) self:xy(50 * (player==PLAYER_2 and -1 or 1), _screen.cy-36) end
}

local windows = DeepCopy(SL.Global.ActiveModifiers.TimingWindows)
local judgmentColors = DeepCopy( SL.JudgmentColors[SL.Global.GameMode] )

--  labels: W1 ---> Miss
for i=1, #TapNoteScores.Types do
	-- no need to add BitmapText actors for TimingWindows that were turned off
	if windows[i] or i==#TapNoteScores.Types then

		local label = TapNoteScores.Names[i]

		t[#t+1] = LoadFont("Common Normal")..{
			Text=label:upper(),
			InitCommand=function(self)
				self:zoom(0.8):horizalign(right):maxwidth(65/self:GetZoom())
					:x( (player == PLAYER_1 and -130) or -28 )
					:y( i * row_height )
					:diffuse( judgmentColors[i < 4 and i+3 or i] )
			end
		}
	end
end

return t