local args = ...
local player = args.Player or GAMESTATE:GetMasterPlayerNumber()
local show_menu_buttons = args.ShowMenuButtons
local show_player_label = args.ShowPlayerLabel

local pad_img = GAMESTATE:GetCurrentGame():GetName()

-- this handles user input while in SelectMusic's TestInput overlay
local function input(event)
	if not (event and event.PlayerNumber and event.button) then
		return false
	end
	-- don't handle input for a non-joined player
	if not GAMESTATE:IsSideJoined(event.PlayerNumber) then
		return false
	end

	-- broadcast event data using MESSAGEMAN for the TestInput overlay to listen for
	if event.type ~= "InputEventType_Repeat" then
		MESSAGEMAN:Broadcast("TestInputEvent", event)
	end
	return false
end

if pad_img == "dance" and ThemePrefs.Get("AllowDanceSolo") then
	local style = GAMESTATE:GetCurrentStyle()
	-- style will be nil in ScreenTestInput within the operator menu
	if style==nil or style:GetName()=="solo" then
		pad_img = "dance-solo"
	end
end

local Highlights = {
	UpLeft={    x=-67, y=-148, rotationz=0, zoom=0.8, graphic="highlight.png" },
	Up={        x=0,   y=-148, rotationz=0, zoom=0.8, graphic="highlight.png" },
	UpRight={   x=67,  y=-148, rotationz=0, zoom=0.8, graphic="highlight.png" },

	Left={      x=-67, y=-80,  rotationz=0, zoom=0.8, graphic="highlight.png" },
	Center={    x=0,   y=-80,  rotationz=0, zoom=0.8, graphic="highlight.png" },
	Right={     x=67,  y=-80,  rotationz=0, zoom=0.8, graphic="highlight.png" },

	DownLeft={  x=-67, y=-12,  rotationz=0, zoom=0.8, graphic="highlight.png" },
	Down={      x=0,   y=-12,  rotationz=0, zoom=0.8, graphic="highlight.png" },
	DownRight={ x=67,  y=-12,  rotationz=0, zoom=0.8, graphic="highlight.png" }
}

if show_menu_buttons then
	Highlights.Start={     x=0,   y=66, rotationz=0,   zoom=0.5, graphic="highlightgreen.png" }
	Highlights.Select={    x=0,   y=95, rotationz=180, zoom=0.5, graphic="highlightred.png" }
	Highlights.MenuRight={ x=37,  y=80, rotationz=0,   zoom=0.5, graphic="highlightarrow.png" }
	Highlights.MenuLeft={  x=-37, y=80, rotationz=180, zoom=0.5, graphic="highlightarrow.png" }
end

local af = Def.ActorFrame{
	OnCommand = function(self)
		local screen = SCREENMAN:GetTopScreen()
		if screen then screen:AddInputCallback(input) end
	end,
	OffCommand = function(self)
		local screen = SCREENMAN:GetTopScreen()
		if screen then screen:RemoveInputCallback(input) end
	end
}

local pad = Def.ActorFrame{}

if show_player_label then
	pad[#pad+1] = LoadFont("Common Bold")..{
		Text=("%s %i"):format(THEME:GetString("ScreenTestInput", "Player"), PlayerNumber:Reverse()[player]+1),
		InitCommand=function(self) self:y(-210):zoom(0.7):visible(false) end,
		OnCommand=function(self)
			local screenname =  SCREENMAN:GetTopScreen():GetName()
			local screenclass = THEME:GetMetric(screenname, "Class")
			self:visible( screenclass == "ScreenTestInput" )
		end
	}
end

pad[#pad+1] = LoadActor(pad_img..".png")..{  InitCommand=function(self) self:y(-80):zoom(0.8) end }

if show_menu_buttons then
	pad[#pad+1] = LoadActor("buttons.png")..{
		InitCommand=function(self) self:y(80):zoom(0.5) end
	}
end

local conversion = {
	"Left",
	"Down",
	"Up",
	"Right"
}
local jdgT = {
	TapNoteScore_W1 = SL.JudgmentColors[SL.Global.GameMode][1],
	TapNoteScore_W2 = SL.JudgmentColors[SL.Global.GameMode][2],
	TapNoteScore_W3 = SL.JudgmentColors[SL.Global.GameMode][3],
	TapNoteScore_W4 = SL.JudgmentColors[SL.Global.GameMode][4],
	TapNoteScore_W5 = SL.JudgmentColors[SL.Global.GameMode][5],
	TapNoteScore_Miss = SL.JudgmentColors[SL.Global.GameMode][6],
}
for panel,values in pairs(Highlights) do
	pad[#pad+1] = LoadActor( values.graphic )..{
		InitCommand=function(self) self:xy(values.x, values.y):rotationz(values.rotationz):zoom(values.zoom):visible(false) end,
		TestInputEventMessageCommand=function(self, event)
			local style = GAMESTATE:GetCurrentStyle()
			local styletype = style and style:GetStyleType() or nil

			-- if double or routine
			if styletype == "StyleType_OnePlayerTwoSides" or styletype == "StyleType_TwoPlayersSharedSides" then

				-- in double, we can't rely on checking the input event's "PlayerNumber" key (only one human player is joined)
				-- so instead, compared the input event's "controller" key from the engine's GameController enum
				-- "GameController_1" is indexed at 0, and "GameController_2" is indexed at 1, conveniently just like how
				--  "PlayerNumber_P1" is indexed at 0, and  "PlayerNumber_P2" is indexed at 1
				if GameController:Reverse()[event.controller]==PlayerNumber:Reverse()[player]
				and event.button == panel then
					self:visible(event.type == "InputEventType_FirstPress")
				end

			-- else single or versus (or style is nil because we're actually on ScreenTestInput)
			else
				if event.PlayerNumber == player and event.button == panel then
					self:visible(event.type == "InputEventType_FirstPress")
				end
			end
		end
	}
	pad[#pad+1] = Def.Quad{
		InitCommand=function(self)
			self:xy(values.x, values.y):rotationz(values.rotationz):zoom(40)
			:visible(false):diffuse(Color.Red)
		end,
		JudgmentMessageCommand=function(self, params)
			if not params.Player == player or not params.Notes then return end
			for col, val in pairs(params.Notes) do
				if tostring(conversion[col]) == tostring(panel) then
					self:stoptweening()
					self:visible(true):diffuse(jdgT[params.TapNoteScore]):diffusealpha(1):linear(.1):diffusealpha(0)
				end
			end
		end,
	}
end

af[#af+1] = pad

return af