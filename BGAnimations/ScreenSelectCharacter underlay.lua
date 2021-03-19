LoadActor(THEME:GetPathB("", "_modules/Characters.lua"))

local wheel = setmetatable({disable_wrapping = true}, sick_wheel_mt)

local row, col = 3,4
local row_height, col_height = 100, 100
local grid_offsetX = 0

local characters = GetAllCharacters()

-- the count of actual characters. total count will be different after due to empty frames
local num_items = #characters

-- if we can't fill out a row completely then add extra empty frames so the wheel doesn't break
if num_items % col ~= 0 then
	for i = 1,(col - (num_items % col)) do
		characters[#characters+1] = {}
	end
end

-- pad the wheel by one
table.insert(characters,1,{})

--the number of items for the wheel to draw - either the size of the wheel or total number of characters
local NumCharactersToDraw = math.min(row * col + 1,#characters)

-- keep track of what item we're looking at (can't use sick wheel because we're not updating it all the time)
local item_index = 1

-- keep track of where the finger cursor should be
local position = {}
for x = 0, row-1 do
	for y = 0, col-1 do
		position[#position+1] = {grid_offsetX + (col_height * y), -row_height + (row_height * x)}
	end
end

local cursor_index = 1

-- this handles user input
-- need to split declaration and assignment up across two lines
-- so that the reference to "input" in RemoveInputCallback(input)
-- is scoped properly (i.e. so that "input" isn't nil)
local input
input = function(event)
	if not event.PlayerNumber or not event.button then
		return false
	end

	if event.type == "InputEventType_FirstPress" then
		local topscreen = SCREENMAN:GetTopScreen()
		local underlay = topscreen:GetChild("Underlay")
		if event.GameButton == "MenuRight" then
			cursor_index = cursor_index + 1
			-- if our cursor isn't at the last position and we still have more characters to show
			if cursor_index < NumCharactersToDraw and item_index < num_items then
				item_index = item_index + 1
				underlay:GetChild("change_sound"):play()
			else
				cursor_index = cursor_index - 1
				-- if we're at the last position but there's still more characters then show
				-- the next row
				if item_index < num_items then
					cursor_index = NumCharactersToDraw - col
					item_index = item_index + 1
					wheel:scroll_by_amount(col)
					underlay:GetChild("change_sound"):play()
				else
					underlay:GetChild("cancel_sound"):play()
				end
			end
			underlay:GetChild("cursor"):xy(_screen.cx - 50 + position[cursor_index][1],_screen.cy + position[cursor_index][2])


		elseif event.GameButton == "MenuLeft" then
			cursor_index = cursor_index - 1
			-- if our cursor isn't at the first position
			if cursor_index > 0 then
				item_index = item_index - 1
				underlay:GetChild("change_sound"):play()
			else
				cursor_index = 1
				-- if our cursor is at the first position but we're not looking at the
				-- first character then show the previous row
				if item_index ~= 1 then
					item_index = item_index - 1
					wheel:scroll_by_amount(-col)
					cursor_index = cursor_index + col - 1
					underlay:GetChild("change_sound"):play()
				else
					underlay:GetChild("cancel_sound"):play()
				end
			end
			underlay:GetChild("cursor"):xy(_screen.cx - 50 + position[cursor_index][1],_screen.cy + position[cursor_index][2])

		elseif event.GameButton == "MenuUp" then
			cursor_index = cursor_index - col
			-- if there's room to move the cursor up a row then do so
			if cursor_index > 0 then
				item_index = item_index - col
				underlay:GetChild("cursor"):xy(_screen.cx - 50 + position[cursor_index][1],_screen.cy + position[cursor_index][2])
				underlay:GetChild("change_sound"):play()
			else
				cursor_index = cursor_index + col
				-- otherwise if there's a previous row not shown then move to that
				-- cursor doesn't move here because it rows move around the cursor
				if item_index > col then
					wheel:scroll_by_amount(-col)
					item_index = item_index - col
					underlay:GetChild("change_sound"):play()
				else
					underlay:GetChild("cancel_sound"):play()
				end
			end

		elseif event.GameButton == "MenuDown" then
			cursor_index = cursor_index + col
			-- if there's room to move the cursor down then no problem
			if cursor_index < NumCharactersToDraw then
				item_index = item_index + col
				underlay:GetChild("change_sound"):play()
			else
				cursor_index = cursor_index - col
				-- if there are enough characters to fill out the last row then
				-- we just check if we're on the bottom row or not
				if num_items % col == 0 then
					if item_index <= num_items - col then
						wheel:scroll_by_amount(col)
						item_index = item_index + col
						underlay:GetChild("change_sound"):play()
					else
						underlay:GetChild("cancel_sound"):play()
					end
				-- if the last row isn't completely filled then we have to account
				-- for that when checking to see if there's room to scroll down
				else
					if item_index <= (num_items - (num_items % col)) then
						wheel:scroll_by_amount(col)
						item_index = item_index + col
						underlay:GetChild("change_sound"):play()
					else
						underlay:GetChild("cancel_sound"):play()
					end
				end
			end
			-- if we ended up trying to scroll past the last item then reset
			-- item_index to the last item
			if item_index > num_items then
				item_index = num_items
				cursor_index = NumCharactersToDraw - 1 - (col - num_items % col)
			end
			underlay:GetChild("cursor"):xy(_screen.cx - 50 + position[cursor_index][1],_screen.cy + position[cursor_index][2])

		elseif event.GameButton == "Start" then
			underlay:playcommand("Finish")

		elseif event.GameButton == "Back" then
			topscreen:RemoveInputCallback(input)
			topscreen:Cancel()
		end
		underlay:queuecommand("SetInfo")
		underlay:playcommand("Animate", {characters[item_index+1].name})
	end

	return false
end


-- the metatable for an item in the wheel
local wheel_item_mt = {
	__index = {
		create_actors = function(self, name)
			self.name=name
			local af = Def.ActorFrame{
				Name=name,
				InitCommand=function(subself)
					self.container = subself
				end,
				Def.Sprite{
					Name="graphic",
					InitCommand=function(subself)
						self.graphic = subself
						subself:diffusealpha(0)
					end,
					OnCommand=function(subself)
						subself:sleep(0.2)
						subself:sleep(0.04 * self.index)
						subself:linear(0.2)
						subself:diffusealpha(1)
						if self.character and self.character.stillZoom then subself:zoom(self.character.stillZoom) end
						if self.name == "item2" and self.charName then
							subself:SetStateProperties(self.character.idle)
							subself:xy(self.character.stillXY[3],self.character.stillXY[4])
						end
					end,
					AnimateCommand=function(subself, param)
						if self.character then
							if self.charName == param[1] then
								subself:SetStateProperties(self.character.idle)
								subself:xy(self.character.stillXY[3],self.character.stillXY[4])
							else
								subself:SetStateProperties(self.character.still)
								subself:xy(self.character.stillXY[1],self.character.stillXY[2])
							end
						end
					end,
				},
			}
			return af
		end,

		transform = function(self, item_index, num_items, has_focus)
			self.container:finishtweening()
			self.container:linear(0.2)
			self.index=item_index

			if item_index <= 1 or item_index > NumCharactersToDraw then
				self.container:visible(false)
			else
				self.container:visible(true)
			end
			local index = self.index - 1
			local y = (index + (col - (index % col))) / col
			if index % col == 0 then y = y - 1 end
			local offset = (1) % col
			local x = (index - offset) % col
			self.container:xy( x * col_height,y*row_height )
		end,

		set = function(self, item)
			if item and item.load then
				self.charName = item.name
				self.character = item
				self.graphic:Load(item.load):SetStateProperties(item.still)
				self.graphic:xy(item.stillXY[1],item.stillXY[2])
			else
				self.graphic:Load(nil)
			end
		end
	}
}

local t = Def.ActorFrame{
	InitCommand=function(self)
		wheel:set_info_set(characters, 0)
		self:queuecommand("Capture")
		self:GetChild("CharacterWheel"):SetDrawByZPosition(true)
	end,
	OnCommand=function(self)
		if PREFSMAN:GetPreference("MenuTimer") then
			self:queuecommand("Listen")
		end
	end,
	OffCommand=function(subself)
		subself:sleep(0.04)
		subself:linear(0.2)
		subself:diffusealpha(0)
	end,
	ListenCommand=function(self)
		local topscreen = SCREENMAN:GetTopScreen()
		local seconds = topscreen:GetChild("Timer"):GetSeconds()
		if seconds <= 0 and not ColorSelected then
			ColorSelected = true
			self:playcommand("Finish")
		else
			self:sleep(0.25)
			self:queuecommand("Listen")
		end
	end,
	CaptureCommand=function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	FinishCommand=function(self)
		self:GetChild("start_sound"):play()

		ThemePrefs.Set("Character", characters[item_index+1].name)
		ThemePrefs.Save()
		SCREENMAN:GetTopScreen():RemoveInputCallback(input)
		SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
	end,

	wheel:create_actors( "CharacterWheel", NumCharactersToDraw, wheel_item_mt, _screen.cx-grid_offsetX, _screen.cy-200 ),

	--Info BG
	Def.Sprite{
		Texture=THEME:GetPathG("FF","CardEdge.png"),
		InitCommand=function(self) self:align(0,1):xy(-7,_screen.h+17):zoomto(300,513) end
	},
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(400,_screen.h-5):xy(80, _screen.h/2):diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
		end,
	},
	-- character name
	LoadFont("Common normal")..{
		InitCommand=function(self)
			self:horizalign(left):xy(25,65):zoom(2):diffusealpha(0)
		end,
		OnCommand=function(self)
			self:settext(characters[item_index+1].displayName):linear(.5):diffusealpha(1)
		end,
		SetInfoCommand=function(self)
			self:settext(characters[item_index+1].displayName)
		end,
	},
	Def.Sprite{
		Name="splash",
		InitCommand=function(self)
			self:xy(140,275):scaletoclipped(250,300):diffusealpha(0)
			self:diffusebottomedge({.1,.1,.1,.5})
		end,
		OnCommand=function(self)
			self:Load(characters[item_index+1].splash):linear(.5)
			self:diffusetopedge({1,1,1,.5})

		end,
		SetInfoCommand=function(self)
			self:Load(characters[item_index+1].splash)
		end,
	},
	Def.Quad{
		InitCommand = function(self)
			self:xy(140,100):zoomto(250,3):diffusealpha(0)
		end,
		OnCommand=function(self)
			self:linear(1):diffusealpha(1)
		end
	},
	-- helper text
	LoadFont("Common normal")..{
		InitCommand=function(self)
			self:horizalign(left):vertalign(top):xy(25,130):zoom(1):_wrapwidthpixels(200):diffusealpha(0)
		end,
		OnCommand=function(self)
			self:settext(characters[item_index+1].text):linear(1):diffusealpha(1)
		end,
		SetInfoCommand=function(self)
			self:settext(characters[item_index+1].text)
		end,
	},
	Def.Sprite{
		Name="cursor",
		Texture=THEME:GetPathG("FF","finger.png"),
		InitCommand=function(self) self:xy(_screen.cx-50-grid_offsetX, _screen.cy-100 ):zoom(.15) end,
	},
}

t[#t+1] = LoadActor( THEME:GetPathS("FF", "move.ogg") )..{ Name="change_sound", SupportPan = false }
t[#t+1] = LoadActor( THEME:GetPathS("FF", "accept.ogg") )..{ Name="start_sound", SupportPan = false }
t[#t+1] = LoadActor( THEME:GetPathS("FF", "cancel.ogg") )..{ Name="cancel_sound", SupportPan = false }

return t