local player = ...
local pn = ToEnumShortString(player)

local pane = Def.ActorFrame{
	Name="Pane3",
	InitCommand = function(self) self:visible(false) end,
	ShowPlayerOptionsPane3MessageCommand = function(self, params)
		if params.PlayerNumber == player then self:visible(true) end
	end,
	HidePlayerOptionsPane3MessageCommand = function(self, params) 
		if params.PlayerNumber == player then self:visible(false) end
	end,
	SetOptionPanesMessageCommand=function(self)
		if SL[pn].Streams.TotalStreams == 0 then 
			self:GetChild("FullBreakdown"):settext("No stream or counter turned off")
		else
			self:GetChild("FullBreakdown"):settext(SL[pn].Streams.Breakdown1)
			local zoomFactor = 1
			if string.len(SL[pn].Streams.Breakdown1) > 500 then zoomFactor = .6
			elseif string.len(SL[pn].Streams.Breakdown1) > 350 then zoomFactor = .75 end
			self:GetChild("FullBreakdown"):zoom(zoomFactor):wrapwidthpixels(250/zoomFactor)
		end
	end
}


pane[#pane+1] = LoadFont("Common Normal")..{
	Name="FullBreakdown",
	InitCommand=function(self)
		self:xy(WideScale(15,0),5)
	end,
}

return pane