------------------------------------------------------------
-- set up the SortMenu's choices first, prior to Actor initialization

-- sick_wheel_mt is a metatable with global scope defined in ./Scripts/Consensual-sick_wheel.lua
local sort_wheel = setmetatable({}, sick_wheel_mt)

-- the logic that handles navigating the SortMenu
-- (scrolling through choices, choosing one, canceling)
-- is large enough that I moved it to its own file
local sortmenu_input = LoadActor("SortMenu_InputHandler.lua", sort_wheel)
local testinput_input = LoadActor("TestInput_InputHandler.lua")


-- WheelItemMT is a generic definition of an choice within the SortMenu
-- "mt" is my personal means of denoting that it (the file, the variable, whatever)
-- has something to do with a Lua metatable.
--
-- metatables in Lua are a useful construct when designing reusable components,
-- but many online tutorials and guides are incredibly obtuse and unhelpful
-- for non-computer-science people (like me). https://lua.org/pil/13.html is just frustratingly scant.
--
-- http://phrogz.net/lua/LearningLua_ValuesAndMetatables.html is less bad than most.
-- I get immediately lost in the criss-crossing diagrams, and I'll continue to
-- argue that naming things foo, bar, and baz abstract programming tutorials right
-- out of practical reality, but I found its prose to be practical, applicable, and concise,
-- so I guess I'll recommend that tutorial until I find a more helpful one.
local wheel_item_mt = LoadActor("WheelItemMT.lua")

local sortmenu = { w=210, h=160 }

------------------------------------------------------------

local t = Def.ActorFrame {
	Name="SortMenu",

	-- Always ensure player input is directed back to the engine when initializing SelectMusic.
	InitCommand=function(self) self:visible(false):queuecommand("DirectInputToEngine") end,
	-- Always ensure player input is directed back to the engine when leaving SelectMusic.
	OffCommand=function(self) self:playcommand("DirectInputToEngine") end,

	-- Figure out which choices to put in the SortWheel based on various current conditions.
	OnCommand=function(self) self:playcommand("AssessAvailableChoices") end,
	-- We'll want to (re)assess available choices in the SortMenu if a player late-joins
	PlayerJoinedMessageCommand=function(self, params) self:queuecommand("AssessAvailableChoices") end,
	-- Load the custom song menu

	ShowSortMenuCommand=function(self) self:diffusealpha(0):visible(true):linear(.2):diffusealpha(1) end,
	HideSortMenuCommand=function(self) self:visible(false) end,

	DirectInputToSortMenuMessageCommand=function(self)
		self:playcommand("ShowSortMenu")
		self:queuecommand("Stall")
	end,
	StallCommand=function(self)
		self:playcommand("AssessAvailableChoices")
		self:visible(true):sleep(0.4):queuecommand("CaptureTest")
	end,
	CaptureTestCommand=function(self)
		SOUND:StopMusic() --TODO stops music in the sort menu but that .35 second gap means a tiny bit plays
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()
		overlay:playcommand("HideTestInput")
		screen:AddInputCallback(sortmenu_input)
	end,
	-- this returns input back to the engine and its ScreenSelectMusic
	DirectInputToEngineCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()
		self:playcommand("FinishSort")
		screen:RemoveInputCallback(testinput_input)
		overlay:playcommand("HideTestInput")
	end,
	DirectInputToTagMenuCommand=function(self) self:playcommand("FinishSort") end,
	DirectInputToOrderMenuCommand=function(self) self:playcommand("FinishSort") end,
	DirectInputToSearchMenuCommand=function(self) self:playcommand("FinishSort") end,
	DirectInputToPlayerStatsCommand=function(self) self:playcommand("FinishSort") end,
	DirectInputToPracticeCommand=function(self)
		--TODO this should probably go back to main music select screen instead of the sort menu
		SCREENMAN:AddNewScreenToTop("ScreenPractice")
	end,
	DirectInputToTestInputCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()
		self:playcommand("FinishSort")
		screen:AddInputCallback(testinput_input)
		overlay:playcommand("ShowTestInput")
	end,
	FinishSortCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		screen:RemoveInputCallback(sortmenu_input)
		self:playcommand("HideSortMenu")
	end,
	SwitchToSortCommand=function(self)
		self:sleep(.2):queuecommand("Wait")
	end,
	WaitCommand=function(self)
		local wheel_options = {
			{"SortBy", "Group"},
			{"SortBy", "Title"},
			{"SortBy", "Artist"},
			{"SortBy", "BPM"},
			{"SortBy", "Length"},
			{"SortBy", "Difficulty"},
			{"SortBy", "Grade"},
			{"SortBy", "Tag"},
		}
		-- get the currently active SortOrder
		local current_sort_order = SL.Global.GroupType
		local current_sort_order_index = 1

		-- find the sick_wheel index of the item we want to display first when the player activates this SortMenu
		for i=1, #wheel_options do
			if wheel_options[i][1] == "SortBy" and wheel_options[i][2] == current_sort_order then
				current_sort_order_index = i
				break
			end
		end
		-- the second argument passed to set_info_set is the index of the item in wheel_options
		-- that we want to have focus when the wheel is displayed
		sort_wheel:set_info_set(wheel_options, current_sort_order_index)
	end,
	AssessAvailableChoicesCommand=function(self)
		self:visible(false)
		local wheel_options = {}
		table.insert(wheel_options, {"Text", "Search"})
		table.insert(wheel_options, {"Change", "Sort"})
		table.insert(wheel_options, {"Change", "Order"})
		table.insert(wheel_options, {"Adjust", "Filters"})
		table.insert(wheel_options, {"Modify", "Song Tags"})

		if #GAMESTATE:GetHumanPlayers() == 1 then
			table.insert(wheel_options, {"View", "Player Stats"})
			-- From source: Edit mode DOES NOT WORK if the master player is not player 1. -Kyz
			if GAMESTATE:GetMasterPlayerNumber() == "PlayerNumber_P1" then
				table.insert(wheel_options, {"Song", "Practice"})
			end
		end
		--table.insert(wheel_options, {"SortBy", "Popularity"})
		--table.insert(wheel_options, {"SortBy", "Recent"})

		-- allow players to switch to a TestInput overlay if the current game has visual assets to support it
		local game = GAMESTATE:GetCurrentGame():GetName()
		if (game=="dance" or game=="pump" or game=="techno") then
			table.insert(wheel_options, {"FeelingSalty", "TestInput"})
		end

		-- Override sick_wheel's default focus_pos, which is math.floor(num_items / 2)
		--
		-- keep in mind that num_items is the number of Actors in the wheel (here, 7)
		-- NOT the total number of things you can eventually scroll through (#wheel_options = 14)
		--
		-- so, math.floor(7/2) gives focus to the third item in the wheel, which looks weird
		-- in this particular usage.  Thus, set the focus to the wheel's current 4th Actor.
		sort_wheel.focus_pos = 4

		-- the second argument passed to set_info_set is the index of the item in wheel_options
		-- that we want to have focus when the wheel is displayed
		sort_wheel:set_info_set(wheel_options,1)
	end,

	-- slightly darken the entire screen
	Def.Quad {
		InitCommand=function(self) self:FullScreen():diffuse(Color.Black):diffusealpha(0.8) end
	},

	Def.ActorFrame{
		SwitchToSortCommand=function(self)
			self:smooth(.2):diffusealpha(0):smooth(.2):diffusealpha(1)
		end,
		-- OptionsList Header Quad
		Def.Quad {
			InitCommand=function(self) self:Center():zoomto(sortmenu.w+2,22):xy(_screen.cx, _screen.cy-92):diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black) end
		},
		-- "Options" text
		Def.BitmapText{
			Font="Wendy/_wendy small",
			Text=ScreenString("Options"),
			InitCommand=function(self)
				self:xy(_screen.cx, _screen.cy-92):zoom(0.4)
					:diffuse( Color.White )
			end
		},

		-- white border
		Def.Quad {
			InitCommand=function(self) self:Center():zoomto(sortmenu.w+2,sortmenu.h+2):diffuse({.5,.5,.5,1}) end
		},
		Def.Sprite{
			Texture=THEME:GetPathG("FF","CardEdge"),
			InitCommand=function(self) self:zoomto(sortmenu.w+2+23,sortmenu.h+2+40):xy(427,230) end,
		},
		-- BG of the sortmenu box
		Def.Quad {
			InitCommand=function(self) self:Center():zoomto(sortmenu.w,sortmenu.h):diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black) end
		},
		-- top mask
		Def.Quad {
			InitCommand=function(self) self:Center():zoomto(sortmenu.w,_screen.h/2):y(40):MaskSource() end
		},
		-- bottom mask
		Def.Quad {
			InitCommand=function(self) self:zoomto(sortmenu.w,_screen.h/2):xy(_screen.cx,_screen.cy+200):MaskSource() end
		},
	},
	-- "Press SELECT To Cancel" text
	Def.BitmapText{
		Font="Wendy/_wendy small",
		Text=ScreenString("Cancel"),
		InitCommand=function(self)
			if PREFSMAN:GetPreference("ThreeKeyNavigation") then
				self:visible(false)
			else
				self:xy(_screen.cx, _screen.cy+100):zoom(0.3):diffuse(0.9,0.9,0.9,1)
			end
		end
	},

	-- this returns an ActorFrame ( see: ./Scripts/Consensual-sick_wheel.lua )
	sort_wheel:create_actors( "Sort Menu", 7, wheel_item_mt, _screen.cx, _screen.cy )
}

t[#t+1] = LoadActor( THEME:GetPathS("FF", "move.wav") )..{ Name="change_sound", SupportPan = false }
t[#t+1] = LoadActor( THEME:GetPathS("common", "start") )..{ Name="start_sound", SupportPan = false }

return t
