local path = "/"..THEME:GetCurrentThemeDirectory().."Graphics/_FallbackBanners/"..ThemePrefs.Get("VisualStyle")
local banner_directory = FILEMAN:DoesFileExist(path) and path or THEME:GetPathG("","_FallbackBanners/Arrows")

local SongOrCourse

local t = Def.ActorFrame{
	OnCommand=function(self)
		if IsUsingWideScreen() then
			self:zoom(0.7655)
			self:xy(_screen.cx - 170, 112)
		else
			self:zoom(0.75)
			self:xy(_screen.cx - 166, 112)
		end
		--self:xy(_screen.cx + 205,300)
	end,
	SwitchFocusToSingleSongMessageCommand=function(self)
		self:finishtweening():linear(0.3):xy(_screen.cx - 122, _screen.cy - 130/1.6):rotationy(360):sleep(.1):rotationy(0)
	end,
	SwitchFocusToSongsMessageCommand=function(self)
		if self:GetDiffuseAlpha() == 0 then self:linear(.3):diffusealpha(1)
		else
			if IsUsingWideScreen() then
				--self:zoom(0.7655)
				self:finishtweening():linear(.3):xy(_screen.cx - 170, 112):rotationy(360):sleep(.1):rotationy(0)
			else
				--self:zoom(0.75)
				self:finishtweening():linear(.3):xy(_screen.cx - 166, 112):rotationy(360):sleep(.1):rotationy(0)
			end
		end
	end,
	SwitchFocusToGroupsMessageCommand=function(self) self:linear(0.3):diffusealpha(0) end,
	
	Def.ActorFrame{
		CurrentSongChangedMessageCommand=function(self,params) if params.song then self:playcommand("SetBanner") end end,
		CurrentCourseChangedMessageCommand=function(self) self:playcommand("SetBanner") end,
		CloseThisFolderHasFocusMessageCommand=function(self)
			self:GetChild("Banner"):LoadFromSongGroup(SL.Global.CurrentGroup)
			:stoptweening():zoom(.5):linear(.125):zoomto(418,164)
			if SL.Global.Debug then Trace("Banner setting current song: nil") end
			GAMESTATE:SetCurrentSong(nil) -- TODO This is a bad place to put this. But we want to clear out the current song and need to set the banner first
		end,
		SetBannerCommand=function(self)
			SongOrCourse = GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentCourse() or GAMESTATE:GetCurrentSong()
			if SongOrCourse and SongOrCourse:HasBanner() then
				self:GetChild("Banner"):visible(true)
				if GAMESTATE:IsCourseMode() then
					self:GetChild("Banner"):LoadFromCourse(GAMESTATE:GetCurrentCourse())
				else
					self:GetChild("Banner"):LoadFromSong(GAMESTATE:GetCurrentSong())
				end
				self:GetChild("Banner"):setsize(418,164)
				if IsUsingWideScreen() then
					self:GetChild("Banner"):stoptweening():zoom(.5):linear(.125):zoomto(418,164)
				else
					self:GetChild("Banner"):stoptweening():zoom(.5):linear(.125):zoomto(418,164)
				end
			elseif SongOrCourse and SongOrCourse:HasJacket() then
				self:GetChild("Banner"):visible(true)
				self:GetChild("Banner"):LoadBanner(SongOrCourse:GetJacketPath())
				self:GetChild("Banner"):scaletoclipped(418,164)
			elseif SongOrCourse then
				self:GetChild("Banner"):LoadFromSongGroup(SongOrCourse:GetGroupName())
				self:GetChild("Banner"):scaletoclipped(418,165)
			else
				self:GetChild("Banner"):visible(false)
			end
		end,
		LoadActor(banner_directory.."/banner"..SL.Global.ActiveColorIndex.." (doubleres).png" )..{
			Name="FallbackBanner",
			OnCommand=function(self) 
				self:rotationy(180):setsize(418,164):diffuseshift():effectoffset(3):effectperiod(6):effectcolor1(1,1,1,0):effectcolor2(1,1,1,1)
			end,
		},

		LoadActor(banner_directory.."/banner"..SL.Global.ActiveColorIndex.." (doubleres).png" )..{
			Name="FallbackBanner",
			OnCommand=function(self) self:diffuseshift():effectperiod(6):effectcolor1(1,1,1,0):effectcolor2(1,1,1,1):setsize(418,164) end,
		},
		-- a lightly styled png asset that is not so different than a Quad
		LoadActor( THEME:GetPathG("FF","CardEdge.png") )..{
			InitCommand=function(self)
				self:diffuse(Color.White)
				self:zoomto(458,180)
				--self:visible(false)
			end,
		},
		Def.Banner{
			Name="Banner",
			BeginCommand=function(self)
				if GAMESTATE:IsCourseMode() then
					self:LoadFromCourse( GAMESTATE:GetCurrentCourse() )
				else 
					self:LoadFromSong( GAMESTATE:GetCurrentSong() )
				end
				self:setsize(418,164)
			end,
		},
	},

	-- the MusicRate Quad and text
	Def.ActorFrame{
		InitCommand=function(self)
			self:visible( tostring(SL.Global.ActiveModifiers.MusicRate) ~= tostring(1) ):y(75)
		end,
		MusicRateChangedMessageCommand = function(self)
			self:visible(tostring(SL.Global.ActiveModifiers.MusicRate) ~= tostring(1) )
		end,
		--quad behind the music rate text
		Def.Quad{
			InitCommand=function(self) self:diffuse( color("#1E282FCC") ):zoomto(418,14) end
		},

		--the music rate text
		LoadFont("Common Normal")..{
			InitCommand=function(self) self:shadowlength(1):zoom(0.85) end,
			OnCommand=function(self)
				self:settext(("%g"):format(SL.Global.ActiveModifiers.MusicRate) .. "x " .. THEME:GetString("OptionTitles", "MusicRate"))
			end,
			MusicRateChangedMessageCommand=function(self)
				self:settext(("%g"):format(SL.Global.ActiveModifiers.MusicRate) .. "x " .. THEME:GetString("OptionTitles", "MusicRate"))
			end
		}
	}
}

return t