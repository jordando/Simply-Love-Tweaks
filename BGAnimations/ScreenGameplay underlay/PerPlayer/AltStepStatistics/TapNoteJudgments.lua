local player = ...

local pn = ToEnumShortString(player)
local fapping

if SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP and SL.Global.GameMode == "Experiment" then
	fapping = true
else 
	fapping = false
end

local track_missbcheld = SL[pn].ActiveModifiers.MissBecauseHeld

local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local NoteFieldIsCentered = (GetNotefieldX(player) == _screen.cx)

local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
local total_tapnotes = StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Notes" )

-- a string representing the NoteSkin the player was using
local noteskin = GAMESTATE:GetPlayerState(player):GetCurrentPlayerOptions():NoteSkin()
-- NOTESKIN:LoadActorForNoteSkin() expects the noteskin name to be all lowercase(?)
-- so transform the string to be lowercase
noteskin = noteskin:lower()

-- determine how many digits are needed to express the number of notes in base-10
local digits = (math.floor(math.log10(total_tapnotes)) + 1)
-- display a minimum 4 digits for aesthetic reasons
digits = math.max(4, digits)

-- generate a Lua string pattern that will be used to leftpad with 0s
local pattern = ("%%0%dd"):format(digits)

local TNS = {
	Judgments = { W1=0, W2=0, W3=0, W4=0, W5=0, Miss=0 },
	Names = {},
}

if SL[ToEnumShortString(player)].ActiveModifiers.EnableFAP  and SL.Global.GameMode == "Experiment" then
	TNS.Types = { 'W0','W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
else
	TNS.Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
end

local tns_string = "TapNoteScore" .. (SL.Global.GameMode=="ITG" and "" or SL.Global.GameMode)

local GetTNSStringFromTheme = function( arg )
	return THEME:GetString(tns_string, arg)
end

local judgments = {}
for i=1,GAMESTATE:GetCurrentStyle():ColumnsPerPlayer() do
	judgments[#judgments+1] = { W0=0, W1=0, W2=0, W3=0, W4=0, W5=0, Miss=0 }
end

-- get TNS names appropriate for the current GameMode, localized to the current language
for i, judgment in ipairs(TNS.Types) do
	TNS.Names[#TNS.Names+1] = THEME:GetString(tns_string, judgment)
end
TNS.Names = map(GetTNSStringFromTheme, TNS.Types)
local leadingZeroAttr

local style = GAMESTATE:GetCurrentStyle()
local num_columns = style:ColumnsPerPlayer()

local rows 
if fapping then rows = { "W0", "W1", "W2", "W3", "W4", "W5", "Miss" }
else rows = { "W1", "W2", "W3", "W4", "W5", "Miss" } end

local windows = DeepCopy(SL.Global.ActiveModifiers.TimingWindows)
local judgmentColors = DeepCopy( SL.JudgmentColors[SL.Global.GameMode] )

if fapping then
	table.insert(windows,2,windows[1])
	table.insert(judgmentColors,2,Color.White)
end

local cols = {}

-- loop num_columns number of time to fill the cols table with
-- info about each column for this game
-- each game (dance, pump, techno, etc.) and each style (single, double, routine, etc.)
-- within each game will have its own unique columns
for i=1,num_columns do
	table.insert(cols, style:GetColumnInfo(player, i))
end

local box_width  = 325
local box_height = 150

-- more space for double and routine
local styletype = ToEnumShortString(style:GetStyleType())
if not (styletype == "OnePlayerOneSide" or styletype == "TwoPlayersTwoSides") then
	box_width = 520
end

local col_width  = box_width/num_columns
local row_height = box_height/#rows
-- -----------------------------------------------------------------------

local af = Def.ActorFrame{}
af.Name="TapNoteJudgments"
af.InitCommand=function(self)
	self:zoom(0.8)
	self:x( SL_WideScale(130,150) * -1)

	if NoteFieldIsCentered and IsUsingWideScreen() then
		self:x( -125 )
	end

	-- adjust for smaller panes when ultrawide and both players joined
	if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
		self:x( 154 * (player==PLAYER_1 and 1 or -1))
	end
end

for y, judgment in ipairs(rows) do
	-- TNS label
	-- no need to add BitmapText actors for TimingWindows that were turned off
	if windows[y] or y==#TNS.Names then

		af[#af+1] = LoadFont("Common Normal")..{
			Text=TNS.Names[y]:upper(),
			InitCommand=function(self)
				self:zoom(0.833):maxwidth(72)
				self:halign( PlayerNumber:Reverse()[player] )
				self:x( 30 )
				self:y((y-1) * row_height - 240)
				self:diffuse( judgmentColors[y] )
				self:horizalign(right)

				-- flip alignment when ultrawide and both players joined
				if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
					self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
					self:x(self:GetX() * -1)
				end
			end,
		}
	end
end
for i, column in ipairs( cols ) do

	local _x = col_width * i

	-- Calculating column positioning like this in techno game results in each column
	-- being ~10px too far left; this does not happen in any other game I've tested.
	-- There's probably a cleaner fix involving scaling column.XOffset to fit within
	-- the bounds of box_width but this is easer for now.
	if GAMESTATE:GetCurrentGame():GetName() == "techno" then
		_x = _x + 10
	end

	-- GetNoteSkinActor() is defined in ./Scripts/SL-Helpers.lua, and performs some
	-- rudimentary error handling because NoteSkins From The Internet™ may contain Lua errors
	af[#af+1] = LoadActor(THEME:GetPathB("","_modules/NoteSkinPreview.lua"), {noteskin_name=noteskin, column=column.Name})..{
		OnCommand=function(self)
			self:xy( _x , row_height - 300):zoom(0.4):visible(true)
		end
	}

	local miss_bmt = nil
	-- for each possible judgment
	for j, judgment in ipairs(rows) do
		-- don't add rows for TimingWindows that were turned off, but always add Miss
		if windows[j] or j==#rows then
			-- add a BitmapText actor to be the number for this column
			af[#af+1] = LoadFont("Common Normal")..{
				Text=(pattern):format(0),
				InitCommand=function(self)
					self:xy(_x, (j-1)*row_height - 240)
						:zoom(1)
					if windows[j] or j==#TNS.Types then
						self:diffuse( judgmentColors[j] )
						leadingZeroAttr = { Length=(digits-1), Diffuse=Brightness(self:GetDiffuse(), 0.35) }
						self:AddAttribute(0, leadingZeroAttr )
					else
						self:diffuse(Brightness({1,1,1,1},0.25))
					end
					if j == #rows then miss_bmt = self end
								-- flip alignment when ultrawide and both players joined
					if IsUltraWide and #GAMESTATE:GetHumanPlayers() > 1 then
						self:halign( PlayerNumber:Reverse()[OtherPlayer[player]] )
					end
				end,
				JudgmentMessageCommand=function(self, params)
					if params.Player ~= player then return end
					if params.HoldNoteScore then return end
					if not params.Notes then return end
					for z = 1, 4 do
						if fapping then
							local updateZero = false
							if params.Notes[z] and z == i then
								local fapWindow = SL.Preferences.Experiment["TimingWindowSecondsW0"] * PREFSMAN:GetPreference("TimingWindowScale") + SL.Preferences[SL.Global.GameMode]["TimingWindowAdd"]
								if ToEnumShortString(params.TapNoteScore) == 'W1' then
									if judgment == "W0" and math.abs(params.TapNoteOffset) <= fapWindow then
										judgments[z][judgment] = judgments[z][judgment] + 1
										self:settext( (pattern):format(judgments[z][judgment]) )
										updateZero = true
									elseif judgment == 'W1' and math.abs(params.TapNoteOffset) > fapWindow then
										judgments[z][judgment] = judgments[z][judgment] + 1
										self:settext( (pattern):format(judgments[z][judgment]) )
										updateZero = true
									end
								elseif ToEnumShortString(params.TapNoteScore) == judgment then
									judgments[z][judgment] = judgments[z][judgment] + 1
									self:settext( (pattern):format(judgments[z][judgment]) )
									updateZero = true
								end
								if updateZero then
									leadingZeroAttr = {
										Length=(digits - (math.floor(math.log10(judgments[z][judgment]))+1)),
										Diffuse=Brightness(judgmentColors[j], 0.35)
									}
									self:AddAttribute(0, leadingZeroAttr )
								end
							end
						else
							if params.Notes[z] and z == i and ToEnumShortString(params.TapNoteScore) == judgment then
								judgments[z][judgment] = judgments[z][judgment] + 1
								self:settext( (pattern):format(judgments[z][judgment]) )
				
								leadingZeroAttr = {
									Length=(digits - (math.floor(math.log10(judgments[z][judgment]))+1)),
									Diffuse=Brightness(judgmentColors[j], 0.35)
								}
								self:AddAttribute(0, leadingZeroAttr )
							end
						end
					end
				end
			}
		end
	end

	--[[
	if track_missbcheld then
		-- the number of MissBecauseHeld judgments for this column
		af[#af+1] = LoadFont("Common Normal")..{
			Text=(pattern):format(0),
			InitCommand=function(self)
				self:xy(_x - 1, (#rows-1)*row_height - 5 - 250):zoom(0.65):halign(1)
				self:diffuse(judgmentColors[#judgmentColors])
			end,
			OnCommand=function(self)
				self:x( self:GetX() - miss_bmt:GetWidth()/2 )
			end
		}
	end
	--]]
end

return af