local footBreakdown, ordered_offsets, heldTimes = unpack(...)
local footStats = SL[ToEnumShortString(GAMESTATE:GetMasterPlayerNumber())]["ParsedSteps"]

-- the metatable for an item in the wheel
local wheel = setmetatable({disable_wrapping = true}, sick_wheel_mt)

local tns_string = "TapNoteScore" .. (SL.Global.GameMode=="ITG" and "" or SL.Global.GameMode)

local GetTNSStringFromTheme = function( arg )
	return THEME:GetString(tns_string, arg)
end

local TapNoteScores = {}
if SL[ToEnumShortString(GAMESTATE:GetMasterPlayerNumber())].ActiveModifiers.EnableFAP  and SL.Global.GameMode == "Experiment" then
	TapNoteScores.Types = { 'W0','W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
else
	TapNoteScores.Types = { 'W1', 'W2', 'W3', 'W4', 'W5', 'Miss' }
end
TapNoteScores.Names = map(GetTNSStringFromTheme, TapNoteScores.Types)

-- sick wheel for the notes to examine
local wheel_item_mt = {
    __index = {
        create_actors = function(self, name)
            self.name=name

            return Def.ActorFrame{
                Name=name,
                InitCommand=function(subself)
                    self.container = subself
                    subself:diffusealpha(1):visible(true)
                end,
                AnalyzeJudgmentMessageCommand=function(self, noteInfo)
                    self:visible(true)
                end,
                EndPopupMessageCommand=function(self)
                    self:visible(false)
                end,
                LoadFont("Common Normal")..{
                    InitCommand=function(subself)
                        self.bmt = subself
                        subself:x(-12):maxwidth(130):zoom(1)
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

            self.container:linear(0.15):y(20 * item_index)
        end,

        set = function(self, info)
            if not info then self.bmt:settext(""); return end
            self.index = info.index
            self.bmt:settext(info.note ~= 0 and info.note or "")
        end
    }
}


local colors = {}
for w=5,1,-1 do
	colors[w] = DeepCopy(SL.JudgmentColors[SL.Global.GameMode][w])
end

-- variables that will be used and re-used in the loop while calculating the AMV's vertices
local x, yStart, yEnd
local interval = 1 --number of seconds to display at a time in the AMV (if 1 it's .5 sec before and after)
local xSpacing, GraphHeight = 35, 200
-- ---------------------------------------------
local setVerts = function(middleTime, items)
    -- TotalSeconds is used in scaling the x-coordinates of the AMV's vertices
    local firstSecond = middleTime - (interval/2)
    local totalSeconds = middleTime + (interval/2)
    local xPosition = {left = 0, down = 1, up = 2, right = 3}
	local verts = {}
    local color
	for item in ivalues(items) do
		x = xPosition[string.lower(item[2])] * xSpacing
		yStart = scale(item[3], firstSecond, totalSeconds, 0, GraphHeight)
        if item[1] == "hold" then
            color = {.5,.5,.5,1}
            yEnd = scale(item[3] + item[4], firstSecond, totalSeconds, 0, GraphHeight)

        else
            local perfectTime = yStart
            yEnd = yStart
            local perfectBarColor = {1,1,1,.9}
            if item[4] then
                perfectTime = scale(item[3] - item[4],firstSecond, totalSeconds, 0, GraphHeight)
                --insert a line showing what perfect timing for the judgment would be
                table.insert( verts, {{x-7, perfectTime - 1, 0}, perfectBarColor} )
                table.insert( verts, {{x+7, perfectTime - 1, 0}, perfectBarColor} )
                table.insert( verts, {{x+7,perfectTime + 1, 0}, perfectBarColor} )
                table.insert( verts, {{x-7, perfectTime + 1, 0}, perfectBarColor} )
                color = colors[DetermineTimingWindow(item[4])]
            else
                table.insert( verts, {{x-7, perfectTime - 1, 0}, perfectBarColor} )
                table.insert( verts, {{x+7, perfectTime - 1, 0}, perfectBarColor} )
                table.insert( verts, {{x+7,perfectTime + 1, 0}, perfectBarColor} )
                table.insert( verts, {{x-7, perfectTime + 1, 0}, perfectBarColor} )
                color = Color.Red
            end
        end
        --insert a bar showing held length or a line showing where you got a judgment
        table.insert( verts, {{x-5, yStart - 1, 0}, color} )
        table.insert( verts, {{x+5, yStart - 1, 0}, color} )
        table.insert( verts, {{x+5,yEnd + 1, 0}, color} )
        table.insert( verts, {{x-5, yEnd + 1, 0}, color} )
	end
	return verts
end

local getHeldTimes = function(time, note)
    local relevantNotes = {}
    for heldTime in ivalues(heldTimes) do
        if math.abs(heldTime[1] - time.Time) < (interval/2) then
            relevantNotes[#relevantNotes+1] = {"hold",heldTime[3],heldTime[1],heldTime[2]}
        end
        if heldTime[1] - time.Time > (interval/2) then break end
    end
    for i = note - 15, note + 15 do
        if ordered_offsets[i] and math.abs(ordered_offsets[i].Time - time.Time) < (interval/2) then
            local time = ordered_offsets[i].Time
            local offset = ordered_offsets[i].Offset
            if offset then time = time + offset end
            relevantNotes[#relevantNotes+1] = {"note", footStats[i].Note,time,offset}
        end
    end
    table.sort(relevantNotes,function(k1,k2) return k1[3] < k2[3] end)
    MESSAGEMAN:Broadcast("DrawHoldTable", setVerts(time.Time, relevantNotes))
    MESSAGEMAN:Broadcast("UpdateScatterplot",{ordered_offsets[note]})
end

-- a string representing the NoteSkin the player was using
local noteskin = GAMESTATE:GetPlayerState(GAMESTATE:GetMasterPlayerNumber()):GetCurrentPlayerOptions():NoteSkin()
-- NOTESKIN:LoadActorForNoteSkin() expects the noteskin name to be all lowercase(?)
-- so transform the string to be lowercase
noteskin = noteskin:lower()

local noteHeaders = Def.ActorFrame{
    InitCommand=function(self) self:xy(40, _screen.cy-125):visible(false) end,
    AnalyzeJudgmentMessageCommand=function(self)
        self:visible(true)
    end,
    EndPopupMessageCommand=function(self)
        self:visible(false)
    end,
}

local cols = {}
local style = GAMESTATE:GetCurrentStyle()
local num_columns = style:ColumnsPerPlayer()

-- loop num_columns number of time to fill the cols table with
-- info about each column for this game
-- each game (dance, pump, techno, etc.) and each style (single, double, routine, etc.)
-- within each game will have its own unique columns
for i=1,num_columns do
	table.insert(cols, style:GetColumnInfo(GAMESTATE:GetMasterPlayerNumber(), i))
end
for i, column in ipairs( cols ) do

	local _x = xSpacing * i

	-- GetNoteSkinActor() is defined in ./Scripts/SL-Helpers.lua, and performs some
	-- rudimentary error handling because NoteSkins From The Internet™ may contain Lua errors
	noteHeaders[#noteHeaders+1] = LoadActor(THEME:GetPathB("","_modules/NoteSkinPreview.lua"), {noteskin_name=noteskin, column=column.Name})..{
		OnCommand=function(self)
			self:x( _x ):zoom(0.4):visible(true)
		end
	}
    noteHeaders[#noteHeaders+1] = Def.Quad{
        OnCommand=function(self)
            self:xy( _x,148):zoomto(3, 270):diffuse({.5,.5,.5,.5})
        end,
    }
end

-- visual for replay stuff
local amv = Def.ActorMultiVertex{
    InitCommand=function(self) self:xy(75,135) end,
    OnCommand=function(self)
        self:SetDrawState({Mode="DrawMode_Quads"})
    end,
    DrawHoldTableMessageCommand=function(self, verts)
        self:finishtweening()
        if verts then --numverts needs to be the same as #verts or it'll draw anything extra as well
            self:SetNumVertices(#verts)
        else self:SetNumVertices(0) end --don't draw anything if the wheel is empty
        self:SetVertices(verts)
    end,
    AnalyzeJudgmentMessageCommand=function(self, noteInfo)
        self:visible(true)
    end,
    EndPopupMessageCommand=function(self)
        self:visible(false)
    end,
}

local num = 0 --number of actual items in our current wheel
local af = Def.ActorFrame{
    InitCommand = function(self)
        self:y(-30)
    end,
    AnalyzeJudgmentMessageCommand = function(self, noteInfo)
        local relevantNotes = {}
        num = 0
        --padding for the wheel
        for i = 1, 5 - #relevantNotes do
            table.insert(relevantNotes,1, {note = 0, index = 0})
        end
        for i, step in pairs(ordered_offsets) do
            if footStats[i].Stream
            and (noteInfo.Judgment == step.Judgment or (noteInfo.Judgment == 6 and step.Judgment == "Miss"))
            and noteInfo.Arrow == footStats[i].Note
            and (footStats[i].Foot and footStats[i].Foot == noteInfo.Foot) then
                num = num + 1
                table.insert(relevantNotes,{note = i,index = num})
            end
        end
        wheel.focus_pos = 6
        wheel:set_info_set(relevantNotes, 0)
        if #relevantNotes > 5 then
            getHeldTimes(ordered_offsets[wheel:get_info_at_focus_pos().note], wheel:get_info_at_focus_pos().note)
        else
            MESSAGEMAN:Broadcast("DrawHoldTable")
        end
    end,
    -- a png asset that gives the colored frame (above) a lightly frosted feel
    -- currently inherited from _fallback
    LoadActor( THEME:GetPathG("ScreenSelectProfile","CardFrame") )..{
        InitCommand=function(self)
            self:cropbottom(1)
            :zoomy(1.51):zoomx(1.01)
            :xy(_screen.cx - 325,_screen.cy - 10)
        end,
        AnalyzeJudgmentMessageCommand=function(self) self:smooth(0.3):cropbottom(0) end,
        EndPopupMessageCommand=function(self)
            self:smooth(0.3):cropbottom(1)
        end
    },
    -- a lightly styled png asset that is not so different than a Quad
    -- currently inherited from _fallback
    LoadActor( THEME:GetPathG("ScreenSelectProfile","CardBackground") )..{
        InitCommand=function(self)
            self:diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black):cropbottom(1)
            :xy(_screen.cx - 325,_screen.cy - 10):zoomy(1.5)
        end,
        AnalyzeJudgmentMessageCommand=function(self) self:smooth(0.3):cropbottom(0) end,
        EndPopupMessageCommand=function(self)
            self:smooth(0.3):cropbottom(1)
        end
    },
    -- white bar separating the wheel and the amv
    Def.Quad{
		InitCommand=function(self)
			self:diffuse( Color.White )
				:y(_screen.cy - 10)
				:x(_screen.cx - 375)
				:zoomto(3, 335)
                :cropbottom(1)
		end,
        AnalyzeJudgmentMessageCommand=function(self)
            self:smooth(0.3):cropbottom(0)
        end,
        EndPopupMessageCommand=function(self)
            self:smooth(0.3):cropbottom(1)
        end
	},
    -- Header
    LoadFont("Common Normal")..{
        InitCommand=function(self)
            self:visible(false)
            :diffuse( Color.White):zoom(1):halign(0)
            :xy(_screen.cx - 360,_screen.cy - 155)
        end,
        AnalyzeJudgmentMessageCommand=function(self, noteInfo)
            self:visible(true)
            self:settext(string.upper(noteInfo.Arrow) .. ": " .. TapNoteScores.Names[noteInfo.Judgment])
        end,
        EndPopupMessageCommand=function(self)
            self:visible(false)
        end,
    },
    noteHeaders,
    wheel:create_actors( "Scroller", 17, wheel_item_mt, _screen.cx - 387, _screen.cy - 190 ),
    ScrollPopUpRightMessageCommand=function(self)
        --don't scroll past the last item (or at all if the wheel is empty)
        if num > 0 and wheel:get_info_at_focus_pos().index < num then
            wheel:scroll_by_amount(1)
            getHeldTimes(ordered_offsets[wheel:get_info_at_focus_pos().note], wheel:get_info_at_focus_pos().note)
        end
    end,
    ScrollPopUpLeftMessageCommand=function(self)
        --don't scroll before the first item (or at all if the wheel is empty)
        if num > 0 and wheel:get_info_at_focus_pos().index > 1 then
            wheel:scroll_by_amount(-1)
           getHeldTimes(ordered_offsets[wheel:get_info_at_focus_pos().note], wheel:get_info_at_focus_pos().note)

        end
    end,

    amv,
}

return af