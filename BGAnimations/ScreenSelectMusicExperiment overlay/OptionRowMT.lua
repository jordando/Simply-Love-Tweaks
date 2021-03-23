local height = 200
local count
if ThemePrefs.Get("ShowExtraControl") ~= "none" then count = 4 else count = 3 end

local optionrow_mt = {
	__index = {
		create_actors = function(self, name)
			self.name=name
			-- this is a terrible way to do this
			local item_index = name:gsub("item", "")
			self.index = item_index

			local af = Def.ActorFrame{
				Name=name,
				InitCommand=function(subself)
					self.container = subself
					subself:diffusealpha(0):queuecommand("Hide2")
				end,
				OnCommand=function(subself) subself:y(-10 + item_index * height/count):sleep(.1) end, --this is where the first option row is
				
				SendBroadcastCommand=function(subself) MESSAGEMAN:Broadcast("BothPlayersAreReady") end,

				HideCommand=function(subself) subself:linear(0.2):diffusealpha(0):queuecommand("Hide2") end,
				Hide2Command=function(subself) subself:visible(false) end,

				UnhideCommand=function(subself) subself:visible(true):queuecommand("Unhide2") end,
				Unhide2Command=function(subself) subself:sleep(0.3):linear(0.2):diffusealpha(1):queuecommand("SendBroadcast") end,

				-- helptext
				Def.BitmapText{
					Font="Common Normal",
					InitCommand=function(subself)
						self.helptext = subself
						subself:horizalign(left):zoom(0.9)
							:diffuse(Color.White):diffusealpha(0.5)
					end,
					GainFocusCommand=function(subself) subself:diffusealpha(0.85) end,
					LoseFocusCommand=function(subself) subself:diffusealpha(0.5) end
				},

				-- bg quad
				Def.Quad{
					InitCommand=function(subself)
						self.bgQuad = subself
						subself:horizalign(left):zoomto(200, 28):diffuse(Color.White):diffusealpha(0.5)
					end,
					OnCommand=function(subself) subself:y(26) end,
					GainFocusCommand=function(subself) subself:diffusealpha(1) end,
					LoseFocusCommand=function(subself) subself:diffusealpha(0.5) end,
				},

				Def.ActorFrame{
					Name="Cursor",
					InitCommand=function(subself) self.cursor = subself end,
					OnCommand=function(self) self:y(26) end,
					LoseFocusCommand=function(subself) subself:diffusealpha(0) end,
					GainFocusCommand=function(subself) subself:diffusealpha(1) end,

					-- right arrow
					Def.ActorFrame{
						Name="RightArrow",
						OnCommand=function(subself) subself:x(216) end,
						PressCommand=function(subself)
							subself:decelerate(0.05):zoom(0.7):glow(1,1,1,0.086)
							       :accelerate(0.05):zoom(  1):glow(1,1,1,0)
						end,
						ExitRowCommand=function(subself, params)
							subself:y(-15) --45 if there's only "GO TO OPTIONS?"
							if params.PlayerNumber == PLAYER_2 then subself:x(20)
							elseif params.PlayerNumber == PLAYER_1 then subself:x(300) end
							
						end,
						SingleSongCanceledMessageCommand=function(subself) subself:rotationz(0) end,
						--BothPlayersAreReadyMessageCommand=function(subself) subself:sleep(0.2):linear(0.2):rotationz(180) end,
						CancelBothPlayersAreReadyMessageCommand=function(subself) subself:rotationz(0) end,

						LoadActor("./img/arrow.png")..{
							Name="RightArrow",
							InitCommand=function(subself) subself:zoom(0.15):diffuse(Color.White):visible(false) end,
						}
					},

					-- left arrow
					Def.ActorFrame{
						Name="LeftArrow",
						OnCommand=function(subself) subself:x(-16) end,
						PressCommand=function(subself)
							subself:decelerate(0.05):zoom(0.7):glow(1,1,1,0.086)
							       :accelerate(0.05):zoom(  1):glow(1,1,1,0)
						end,
						ExitRowCommand=function(subself, params)
							subself:y(-20) --45 if there's only "GO TO OPTIONS?"
							if params.PlayerNumber == PLAYER_1 then subself:x(WideScale(230,180))
							else subself:x(WideScale(55,15)):rotationy(180) end
						end,
						SingleSongCanceledMessageCommand=function(subself) subself:rotationz(0) end,
						--BothPlayersAreReadyMessageCommand=function(subself) subself:sleep(0.2):linear(0.2):rotationz(180) end,
						CancelBothPlayersAreReadyMessageCommand=function(subself) subself:rotationz(0) end,

						Def.Sprite{
							Name="LeftArrow",
							Texture=THEME:GetPathG("FF","finger.png"),
							InitCommand=function(subself)
								subself:zoom(0.10):diffuse(Color.White)
								subself:bounce():effectclock("beatnooffset"):effectmagnitude(-3,0,0)
								subself:effectperiod(1):effectoffset( -10 * PREFSMAN:GetPreference("GlobalOffsetSeconds"))

							end,

						}
					}
				}
			}

			return af
		end,

		transform = function(self, item_index, num_items, has_focus)

			self.container:finishtweening()
			if has_focus then
				self.container:playcommand("GainFocus")
			else
				self.container:playcommand("LoseFocus")
			end
		end,

		set = function(self, optionrow)
			if not optionrow then return end
			self.helptext:settext( optionrow.HelpText )
			if optionrow.HelpText == "" then
				self.bgQuad:visible(false)
			end
		end
	}
}

return optionrow_mt