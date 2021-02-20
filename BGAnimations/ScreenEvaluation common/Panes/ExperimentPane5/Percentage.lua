local args = ...
local player = args.player
local pn = ToEnumShortString(player)

local percent
if args.side then percent = args.side else
	local stats = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
	local PercentDP = stats:GetPercentDancePoints()
	percent = FormatPercentScore(PercentDP)
	-- Format the Percentage string, removing the % symbol
	percent = percent:gsub("%%", "")
end

return Def.ActorFrame{
	Name="PercentageContainer"..pn,
	InitCommand=function(self)
		self:x( -115 )
		self:y( _screen.cy-40 )
	end,

	-- dark background quad behind player percent score
	Def.Quad{
		InitCommand=function(self)
			self:diffuse( color("#101519") )
				:y(-2)
				:zoomto(70, 28)
		end
	},

	LoadFont("Wendy/_wendy white")..{
		Text=percent,
		Name="Percent",
		InitCommand=function(self) self:horizalign(right):zoom(0.25):xy( 30, -2) end,
	}
}
