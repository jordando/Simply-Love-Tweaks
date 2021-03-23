local num_rows    = 5
local num_columns = 20
local GridZoomX = IsUsingWideScreen() and 0.435 or 0.39
local BlockZoomY = 0.275
local StepsToDisplay, SongOrCourse, StepsOrTrails

local GetStepsToDisplay = LoadActor("./StepsToDisplay.lua")
local xOffset = IsUsingWideScreen() and WideScale(-75,-170) or -150
local t = Def.ActorFrame{
	Name="StepsDisplayList",
	InitCommand=function(self) self:vertalign(top):xy(_screen.cx + xOffset, _screen.cy + 70) end,
	-- - - - - - - - - - - - - -

	OnCommand=function(self) self:queuecommand("RedrawStepsDisplay") end,
	CurrentSongChangedMessageCommand=function(self) self:queuecommand("RedrawStepsDisplay") end,
	CurrentCourseChangedMessageCommand=function(self) self:queuecommand("RedrawStepsDisplay") end,
	StepsHaveChangedCommand=function(self) self:queuecommand("RedrawStepsDisplay") end,
	PlayerJoinedMessageCommand=function(self) self:queuecommand("RedrawStepsDisplay") end,
	-- - - - - - - - - - - - - -

	RedrawStepsDisplayCommand=function(self)

		SongOrCourse = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse()) or GAMESTATE:GetCurrentSong()

		if SongOrCourse then
			StepsOrTrails = (GAMESTATE:IsCourseMode() and SongOrCourse:GetAllTrails()) or SongUtil.GetPlayableSteps( SongOrCourse )

			if StepsOrTrails then

				StepsToDisplay = GetStepsToDisplay(StepsOrTrails)

				for RowNumber=1,num_rows do
					if StepsToDisplay[RowNumber] then
						-- if this particular song has a stepchart for this row, update the Meter
						-- and BlockRow coloring appropriately
						local chart = StepsToDisplay[RowNumber]
						local meter = chart:GetMeter()
						local difficulty = chart:GetDifficulty()
						self:GetChild("Grid"):GetChild("Meter_"..RowNumber):playcommand("Set", {Meter=meter, Difficulty=difficulty, Chart=chart})
						if not ThemePrefs.Get("ShowExtraSongInfo") or GAMESTATE:GetNumSidesJoined() == 2 then
							self:GetChild("Grid"):GetChild("Blocks_"..RowNumber):playcommand("Set", {Meter=meter, Difficulty=difficulty, Chart=chart})
						end
					else
						-- otherwise, set the meter to an empty string and hide this particular colored BlockRow
						self:GetChild("Grid"):GetChild("Meter_"..RowNumber):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Blocks_"..RowNumber):playcommand("Unset")

					end
				end
			end
		else
			StepsOrTrails, StepsToDisplay = nil, nil
			self:playcommand("Unset")
		end
	end,

	-- - - - - - - - - - - - - -

	-- background
	Def.Quad{
		Name="Background",
		InitCommand=function(self)
			self:diffuse(color("#1e282f")):zoomto(31, 96):halign(0):x(WideScale(-148,-160))
			if ThemePrefs.Get("RainbowMode") then
				self:diffusealpha(0.75)
			end
		end
	},
}


local Grid = Def.ActorFrame{
	Name="Grid",
	InitCommand=function(self) self:horizalign(left):vertalign(top):xy(WideScale(25,8), -52 ) end,
}

-- A grid of decorative faux-blocks that will exist
-- behind the changing difficulty blocks.
Grid[#Grid+1] = Def.Sprite{
	Name="BackgroundBlocks",
	Texture=THEME:GetPathB("ScreenSelectMusic", "overlay/StepsDisplayList/_block.png"),

	InitCommand=function(self) self:diffuse(color("#182025") ) end,
	OnCommand=function(self)
		local width = self:GetWidth()
		local height= self:GetHeight()
		self:zoomto(width * num_columns * GridZoomX, height * num_rows * BlockZoomY)
		self:y( 3 * height * BlockZoomY )
		self:customtexturerect(0, 0, num_columns, num_rows)
		if ThemePrefs.Get("ShowExtraSongInfo") then
			self:diffusealpha(0)
		end
	end,
	RedrawStepsDisplayCommand=function(self)
		if not  ThemePrefs.Get("ShowExtraSongInfo") or GAMESTATE:GetNumSidesJoined() == 2 then
			self:diffusealpha(1)
		end
	end,
}

for RowNumber=1,num_rows do

	Grid[#Grid+1] =	Def.Sprite{
		Name="Blocks_"..RowNumber,
		Texture=THEME:GetPathB("ScreenSelectMusic", "overlay/StepsDisplayList/_block.png"),

		InitCommand=function(self) self:diffusealpha(0) end,
		OnCommand=function(self)
			local width = self:GetWidth()
			local height= self:GetHeight()
			self:y( RowNumber * height * BlockZoomY)
			self:zoomto(width * num_columns * GridZoomX, height * BlockZoomY)
		end,
		SetCommand=function(self, params)
			-- our grid only supports charts with up to a 20-block difficulty meter
			-- but charts can have higher difficulties
			-- handle that here by clamping the value to be between 1 and, at most, 20
			local meter = clamp( params.Meter, 1, num_columns )

			self:customtexturerect(0, 0, num_columns, 1)
			self:cropright( 1 - (meter * (1/num_columns)) )

			-- diffuse and set each chart's difficulty meter
			if ValidateChart(GAMESTATE:GetCurrentSong(),params.Chart) then self:diffuse( DifficultyColor(params.Difficulty) )
			else self:diffuse(.5,.5,.5,1) end
		end,
		UnsetCommand=function(self)
			self:customtexturerect(0,0,0,0)
		end
	}

	Grid[#Grid+1] = Def.BitmapText{
		Name="Meter_"..RowNumber,
		Font="Wendy/_wendy small",

		InitCommand=function(self)
			local height = self:GetParent():GetChild("Blocks_"..RowNumber):GetHeight()
			self:horizalign(right)
			self:y(RowNumber * height * BlockZoomY)
			self:x( -146 )
			self:zoom(0.3)
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			if GAMESTATE:IsCourseMode() then self:diffuse( DifficultyColor(params.Difficulty) )
			elseif ValidateChart(GAMESTATE:GetCurrentSong(),params.Chart) then self:diffuse( DifficultyColor(params.Difficulty) )
			else self:diffuse(.5,.5,.5,1) end
			self:settext(params.Meter)
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
	}
end

t[#t+1] = Grid

return t