local group_info = ...

--variables needed for both the legend and the bargraph
local minDif, maxDif, num_dif, adjusted_num_dif, x, y, w, h

CreateBarGraph = function(_w, _h)
	w, h = _w, _h
	local legend = LoadFont("Wendy/_wendy small")..{
		Name="Legend_BMT",
		Initialize=function(self, actor)
			local toPrint = ""
			for i = 0, num_dif do
				if minDif + i > 25 then break end
				if string.find(i, '1') then toPrint = toPrint.." " end --1 is 18 pixels. everything else is 30 so add an extra space here
				if i < 10 then toPrint = toPrint.."  " end --double digits are 60 or 62 (1+space+other digit) so add an extra space if single digit
				if i == 11 then toPrint = toPrint.." " end --11 has two ones so add another space
				toPrint = toPrint.. " " .. tostring(minDif + i) .. " "
			end
			toPrint = string.sub(toPrint,1,-1)
			actor:settext(toPrint)
			actor:zoom((x*math.min(num_dif,adjusted_num_dif)+(x-5))/actor:GetWidth())
			if tonumber(maxDif) >= 25 then actor:settext(toPrint.."+") end
			actor:Draw()
		end,
	}
	legend.InitCommand=function(self)
		self:zoom(1):halign(0):y(10)
	end

	local amv = Def.ActorMultiVertex{
		Name="BarGraph_AMV",

		Initialize=function(self, actor, params)
			local verts = {}
			local group = params.group or GetCurrentGroup()
			local over25, over25Passed = 0,0
			for i = 0, num_dif do
				local num_songs = group_info[group]['UnsortedLevel'][tostring(minDif + i)]
				--we clump all the 25+ charts together so don't add a bar yet. just record how many we have
				if num_songs and minDif + i >= 25 then
					over25 = over25 + 1
					local num_passed = group_info[group]['UnsortedPassedLevel'][tostring(minDif + i)]
					if num_passed then over25Passed = over25Passed + 1 end
				elseif num_songs then
					table.insert(verts,{{i*x,0,0}, Color.Red})
					table.insert(verts,{{i*x,y*num_songs*-1,0}, Color.Blue})
					table.insert(verts,{{i*x+(x-5),y*num_songs*-1,0}, Color.Green})
					table.insert(verts,{{i*x+(x-5),0,0}, Color.Yellow})
					local num_passed = group_info[group]['UnsortedPassedLevel'][tostring(minDif + i)]
					if num_passed then --make another bar right on top of the last one showing how many of each level were passed
						table.insert(verts,{{i*x,0,0}, Color.Green})
						table.insert(verts,{{i*x,y*num_passed*-1,0}, Color.White})
						table.insert(verts,{{i*x+(x-5),y*num_passed*-1,0}, Color.White})
						table.insert(verts,{{i*x+(x-5),0,0}, Color.Green})
					end
				end
			end
			if over25 > 0 then
				local finalBar = math.min(num_dif,adjusted_num_dif)
				table.insert(verts,{{finalBar*x,0,0}, Color.Red})
				table.insert(verts,{{finalBar*x,y*over25*-1,0}, Color.Blue})
				table.insert(verts,{{finalBar*x+(x-5),y*over25*-1,0}, Color.Green})
				table.insert(verts,{{finalBar*x+(x-5),0,0}, Color.Yellow})
				if over25Passed > 0 then
					table.insert(verts,{{finalBar*x,0,0}, Color.Green})
					table.insert(verts,{{finalBar*x,y*over25Passed*-1,0}, Color.White})
					table.insert(verts,{{finalBar*x+(x-5),y*over25Passed*-1,0}, Color.White})
					table.insert(verts,{{finalBar*x+(x-5),0,0}, Color.Green})
				end
			end
			actor:SetNumVertices(#verts):SetVertices(verts)
		end
	}
	amv.InitCommand=function(self)
		self:SetDrawState({Mode="DrawMode_Quads"})
	end

	local af=Def.ActorFrame{InitCommand=function(self) self:visible(false) end}
	af[#af+1]=amv
	af[#af+1]=legend
	af.UpdateGroupInfoMessageCommand=function(self, params) group_info = params[1] end
	af.CurrentGroupChangedMessageCommand=function(self, params)
		local group = nil
		--see if we were passed a group
		if params and params.group and group_info[params.group] then group = params.group
		--the first time we run we won't have params.group passed so we set based on the current group
		elseif group_info[GetCurrentGroup()] then group = GetCurrentGroup() end
		--if UpdateGroupInfoMessageCommand needs to be called then we won't have the correct group in group_info. only run if we have good group info
		if group then
			--these are local variables that the legend and bargraph both need to use
			minDif = group_info[group]['Level'][1]['difficulty']
			maxDif = group_info[group]['Level'][#group_info[group]['Level']]['difficulty']
			num_dif = maxDif - minDif
			--if there's a joke chart with an absurd difficulty we want things to scale at the
			--max difficulty displayed which is 25 right now. we can't change num_dif outright
			--because then the 25+ difficulty charts won't get bars
			adjusted_num_dif = math.min(num_dif,(math.min(25,maxDif)-minDif)+2)
			x = w / math.min(num_dif,adjusted_num_dif)
			if x < 10 then x = 10 --this will produce a minimum bar size of 15. smaller than that and number are very hard to read (consequence is that we can overflow)
			elseif x > 20 then x = 20 end --don't want our graph to get too fat, this maxes out at 35
			y = h / group_info[group].max_num
			amv:Initialize(self:GetChild("BarGraph_AMV"), params)
			legend:Initialize(self:GetChild("Legend_BMT"), params)
		end
	end
	af.SwitchFocusToGroupsMessageCommand=function(self) self:visible(true):diffusealpha(0):sleep(0.4):linear(0.15):diffusealpha(1) end
	af.SwitchFocusToSongsMessageCommand=function(self) self:visible(false):diffusealpha(0) end
	return af
end