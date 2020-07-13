if SL.Global.GameMode == "Casual" then return end

local args = ...
local player = args.player
local alternateGraph = args.graph or false								  

local GraphWidth = THEME:GetMetric("GraphDisplay", "BodyWidth")
local GraphHeight = THEME:GetMetric("GraphDisplay", "BodyHeight")

local graph
if not alternateGraph then
	graph = LoadActor("./ScatterPlot.lua", {player=player, GraphWidth=GraphWidth, GraphHeight=GraphHeight} )
else
	graph = NPS_Histogram(player, GraphWidth, GraphHeight)..{OnCommand = function(self) self:x(-GraphWidth/2):y(GraphHeight):playcommand("SetDensity") end}
end  
return Def.ActorFrame{
	InitCommand=function(self) self:y(_screen.cy + 124) end,

	-- Draw a Quad behind the GraphDisplay (lifebar graph) and Judgment ScatterPlot
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(GraphWidth, GraphHeight):diffuse(color("#101519")):vertalign(top)
		end
	},

	graph,

	-- The GraphDisplay provided by the engine provides us a solid color histogram detailing
	-- the player's lifemeter during gameplay capped by a white line.
	-- in normal gameplay (non-CourseMode), we hide the solid color but leave the white line.
	-- in CourseMode, we hide the white line (for aesthetic reasons) and leave the solid color
	-- as ScatterPlot.lua does not yet support CourseMode.
	Def.GraphDisplay{
		Name="GraphDisplay",
		InitCommand=function(self)
			self:vertalign(top)

			local ColorIndex = ((SL.Global.ActiveColorIndex + (player==PLAYER_1 and -1 or 1)) % #SL.Colors) + 1
			self:Load("GraphDisplay" .. ColorIndex )

			local playerStageStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
			local stageStats = STATSMAN:GetCurStageStats()
			self:Set(stageStats, playerStageStats)

			if GAMESTATE:IsCourseMode() then
				-- hide the GraphDisplay's stroke ("Line")
				self:GetChild("Line"):visible(false)
			else
			    -- hide the GraphDisplay's body (2nd unnamed child)
			    self:GetChild("")[2]:visible(false)
			end
		end
	},
}