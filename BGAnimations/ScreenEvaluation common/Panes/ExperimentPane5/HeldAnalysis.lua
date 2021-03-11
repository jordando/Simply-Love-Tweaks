local footBreakdown, ordered_offsets, heldTimes = unpack(...)

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
            self.bmt:settext(info.note or "")
        end
    }
}

return Def.ActorFrame{
    InitCommand = function(self)
    end,
    AnalyzeJudgmentMessageCommand = function(self, noteInfo)
        local relevantNotes = {}
        local footStats = SL[ToEnumShortString(GAMESTATE:GetMasterPlayerNumber())]["ParsedSteps"]
        local num = 1
        for i, footStat in pairs(footStats) do
            if footStat.Stream
            and (noteInfo.Judgment == ordered_offsets[i].Judgment or (noteInfo.Judgment == 6 and ordered_offsets[i].Judgment == "Miss"))
            and noteInfo.Arrow == footStat.Note
            and (footStat.Foot and footStat.Foot == noteInfo.Foot) then
                table.insert(relevantNotes,{note = i,index = num})
                num = num + 1
            end
        end
        wheel:set_info_set(relevantNotes, 1)
    end,
    -- a lightly styled png asset that is not so different than a Quad
    -- currently inherited from _fallback
    LoadActor( THEME:GetPathG("ScreenSelectProfile","CardBackground") )..{
        InitCommand=function(self)
            self:diffuse(PlayerColor(GAMESTATE:GetMasterPlayerNumber())):cropbottom(1)
            :xy(_screen.cx - 325,_screen.cy - 10)
        end,
        AnalyzeJudgmentMessageCommand=function(self) self:smooth(0.3):cropbottom(0) end,
        EndPopupMessageCommand=function(self)
            self:smooth(0.3):cropbottom(1)
        end
    },

    -- a png asset that gives the colored frame (above) a lightly frosted feel
    -- currently inherited from _fallback
    LoadActor( THEME:GetPathG("ScreenSelectProfile","CardFrame") )..{
        InitCommand=function(self)
            self:cropbottom(1)
            :xy(_screen.cx - 325,_screen.cy - 10)
        end,
        AnalyzeJudgmentMessageCommand=function(self) self:smooth(0.3):cropbottom(0) end,
        EndPopupMessageCommand=function(self)
            self:smooth(0.3):cropbottom(1)
        end
    },
    LoadFont("Common Normal")..{
        InitCommand=function(self)
            self:visible(false)
            :diffuse( Color.Black):zoom(1):halign(0)
            :xy(_screen.cx - 375,_screen.cy - 80)
        end,
        AnalyzeJudgmentMessageCommand=function(self, noteInfo)
            self:visible(true)
            self:settext("Foot:" .. noteInfo.Foot .. "\nJudgment: " ..  TapNoteScores.Names[noteInfo.Judgment] .. "\nArrow: ".. noteInfo.Arrow)
        end,
        EndPopupMessageCommand=function(self)
            self:visible(false)
        end,
    },
    wheel:create_actors( "Scroller", 12, wheel_item_mt, _screen.cx - 385, _screen.cy - 140 ),
    ScrollPopUpRightMessageCommand=function(self)
        wheel:scroll_by_amount(1)
    end,
    ScrollPopUpLeftMessageCommand=function(self)
        wheel:scroll_by_amount(-1)
    end,
}