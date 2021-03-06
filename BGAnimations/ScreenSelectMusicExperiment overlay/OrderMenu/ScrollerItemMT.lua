-- the metatable for an item in ScreenSelectProfile's sick_wheel scroller
-- this is just a given profile's DisplayName
return {
	__index = {
		create_actors = function(self, name)
			self.name=name

			return Def.ActorFrame{
				Name=name,
				InitCommand=function(subself)
					self.container = subself
					subself:diffusealpha(0):visible(false)
				end,
				OffCommand=function(subself) subself:sleep(.2):queuecommand("Disappear") end,
				ShowOrderMenuCommand=function(subself) subself:sleep(.2):queuecommand("Appear") end,
				AppearCommand=function(subself) subself:visible(true):linear(0.15):diffusealpha(1) end,
				DisappearCommand=function(subself) subself:linear(.2):diffusealpha(0):visible(false) end,
				
				LoadFont("Common Normal")..{
					InitCommand=function(subself)
						self.bmt = subself
						subself:maxwidth(115):MaskDest()
					end,
				}
			}
		end,
		transform = function(self, item_index, num_items, has_focus)
			self.container:finishtweening()
			if has_focus then self.container:diffuse(1,0,0,1)
			else self.container:diffuse(1,1,1,1) end
			if item_index <= 1 or item_index >= num_items then
				self.container:diffusealpha(0)
			else
				self.container:diffusealpha(1)
			end

			self.container:linear(0.15):y(35 * item_index)
		end,
		set = function(self, info)
			if not info then self.bmt:settext(""); return end
			self.info = info
			self.bmt:settext(info.displayname or "")
		end
	}
}