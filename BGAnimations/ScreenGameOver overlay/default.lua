local Players = GAMESTATE:GetHumanPlayers();

local t = Def.ActorFrame{
	LoadActor("end.png")..{
		InitCommand=function(self) self:xy(_screen.cx,_screen.cy):cropbottom(1):fadetop(1):zoom(.7):shadowlength(1) end,
		OnCommand=function(self) self:decelerate(0.5):cropbottom(0):fadetop(0):glow(1,1,1,1):decelerate(1):glow(1,1,1,1) end,
		OffCommand=function(self) self:accelerate(0.5):fadeleft(1):cropleft(1) end
	},

	--Player 1 Stats BG
	Def.Sprite{
		Texture=THEME:GetPathG("FF","CardEdge.png"),
		InitCommand=function(self) self:align(0,1):xy(-7,_screen.h+17):zoomto(175,513) end
	},
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(160,_screen.h-5):xy(80, _screen.h/2):diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
		end,
	},
	--Player 2 Stats BG
	Def.Sprite{
		Texture=THEME:GetPathG("FF","CardEdge.png"),
		InitCommand=function(self) self:align(1,1):xy(_screen.w+7,_screen.h+17):zoomto(175,513) end
	},
	Def.Quad{
		InitCommand=function(self)
			self:zoomto(160,_screen.h-5):xy(_screen.w-80, _screen.h/2):diffusetopedge(color("#23279e")):diffusebottomedge(Color.Black)
		end,
	},

}

local line_height = 58
local profilestats_y = 138
local horiz_line_y   = 288
local normalstats_y  = 268

for player in ivalues(Players) do

	local stats
	local x_pos = player==PLAYER_1 and 80 or _screen.w-80
	local PlayerStatsAF = Def.ActorFrame{ Name="PlayerStatsAF_"..ToEnumShortString(player) }


	-- first, check if this player is using a profile (local or MemoryCard)
	if PROFILEMAN:IsPersistentProfile(player) then

		-- if a profile is in use, grab gameplay stats for this session that are pertinent
		-- to this specific player's profile (highscore name, calories burned, total songs played)
		local profile_stats = LoadActor("PlayerStatsWithProfile.lua", player)

		-- loop through those stats, adding them to the ActorFrame for this player as BitmapText actors
		for i,stat in ipairs(profile_stats) do
			PlayerStatsAF[#PlayerStatsAF+1] = LoadFont("Common Normal")..{
				Text=stat,
				InitCommand=function(self)
					self:diffuse(PlayerColor(player)):zoom(0.95)
						:xy(x_pos, (line_height*(i-1)) + profilestats_y)
						:maxwidth(150):vertspacing(-1)

					DiffuseEmojis(self)
				end
			}
		end

		PlayerStatsAF[#PlayerStatsAF+1] = LoadActor("./ProfileAvatar", {player, x_pos})
	end

	-- horizontal line separating upper stats (profile) from the lower stats (general)
	PlayerStatsAF[#PlayerStatsAF+1] = Def.Quad{
		InitCommand=function(self)
			self:zoomto(120,1):xy(x_pos, horiz_line_y)
				:diffuse( PlayerColor(player) )
		end
	}

	-- retrieve general gameplay session stats for which a profile is not needed
	stats = LoadActor("PlayerStatsWithoutProfile.lua", player)

	-- loop through those stats, adding them to the ActorFrame for this player as BitmapText actors
	for i,stat in ipairs(stats) do
		PlayerStatsAF[#PlayerStatsAF+1] = LoadFont("Common Normal")..{
			Text=stat,
			InitCommand=function(self)
				self:diffuse(PlayerColor(player)):zoom(0.95)
					:xy(x_pos, (line_height*i) + normalstats_y)
					:maxwidth(150):vertspacing(-1)
			end
		}
	end

	t[#t+1] = PlayerStatsAF
end

return t