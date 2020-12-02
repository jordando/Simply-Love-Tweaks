--Different BPM conversions

local player = ...

local pane = Def.ActorFrame{
	Name="Pane2",
	InitCommand = function(self) self:visible(false) end,
	ShowPlayerOptionsPane2MessageCommand = function(self, params)
		if params.PlayerNumber == player then self:visible(true) end
	end,
	HidePlayerOptionsPane2MessageCommand = function(self, params) 
		if params.PlayerNumber == player then self:visible(false) end
	end,
}

local labelX_col1 = WideScale(-120,-130)
local dataX_col1 = WideScale(0,-10)

PaneItems = {}

PaneItems["12TH"] = {
	note = 12,
	label = { x = labelX_col1, y = -20 },
	data = { x = dataX_col1, y = -20 }
}
PaneItems["16TH"] = {
	note = 16,
	label = { x = labelX_col1, y = 10 },
	data = { x = dataX_col1, y = 10 }
}
PaneItems["24TH"] = {
	note = 24,
	label = { x = labelX_col1, y = 40 },
	data = { x = dataX_col1, y = 40 }
}

for key, item in pairs(PaneItems) do

	pane[#pane+1] = Def.ActorFrame{

		Name=key,

		-- label
		LoadFont("Common Normal")..{
			Text=key.." NOTES:",
			InitCommand=function(self) self:xy(item.label.x, item.label.y):diffuse(Color.White):halign(0) end,
		},
		--  numerical value
		LoadFont("Common Normal")..{
			InitCommand=function(self) self:xy(item.data.x,item.data.y):diffuse(Color.White):halign(0) end,
			OnCommand=function(self) self:playcommand("Set") end,
			SetOptionPanesMessageCommand=function(self)
				local bpm = GetDisplayBPMs(player,GAMESTATE:GetCurrentSteps(player))[2]
				if item.note == 16 then
					self:settext( math.floor((16 * bpm / 240)*100)/100 .." NPS")
				else
					self:settext(math.floor((item.note * bpm / 16)*100)/100 .." BPM 16ths")
				end
			end
		}
	}
end

	pane[#pane+1] = LoadFont("Wendy/_wendy small")..{
		InitCommand=function(self)
			self:xy(labelX_col1, -55):zoom(.5):diffuse(Color.White):halign(0):zoom(.5)
		end,
		SetOptionPanesMessageCommand=function(self)
			self:settext(StringifyDisplayBPMs().." BPM")
		end,
	}
return pane