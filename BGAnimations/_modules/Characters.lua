local NewLinearFrames = function(start, stop, time)
	local delay = time / (stop - start)
	local t = {}
	for i = start, stop do
		t[#t+1] = {Frame=i,Delay=delay}
	end
	return t
end

local Character = {
    Quina = {
        XY = {0,0},
        winXY = {0,0},
        attack = NewLinearFrames(0,11, 1.5),
        idle = NewLinearFrames(12,27,1.5),
        limit = NewLinearFrames(28,70,1.5),
        magic = NewLinearFrames(71,78,0.75),
        magic2 = NewLinearFrames(79,85,0.75),
        standby = NewLinearFrames(86,96,1.5),
        win = NewLinearFrames(97,106,1.5),
        danger = NewLinearFrames(110,110,1),
        dead = NewLinearFrames(109,109,1),
        deadXY = {0,50},
        dangerXY = {0,30},
        attackXY = {-125,10},
        load = THEME:GetPathG("","Characters/Quina/quina 8x14.png"),
        icon = THEME:GetPathG("","Characters/Quina/unit_icon.png")
    },
    Steiner = {
        XY = {0,50},
        winXY = {-50,0},
        attack = NewLinearFrames(0,12, 1.5),
        idle = NewLinearFrames(13,16,1.5),
        limit = NewLinearFrames(0,12,1.5),
        magic = NewLinearFrames(17,20,0.75),
        magic2 = NewLinearFrames(21,23,0.75),
        standby = NewLinearFrames(24,27,1.5),
        win = NewLinearFrames(32,46,2),
        danger = NewLinearFrames(48,48,1),
        dead = NewLinearFrames(47,47,1),
        deadXY = {0,80},
        dangerXY = {0,70},
        attackXY = {-125,-75},
        load = THEME:GetPathG("","Characters/Steiner/Steiner 7x7.png"),
        icon = THEME:GetPathG("","Characters/Steiner/unit_icon.png")
    }
}

local Enemy = {
    x001 = {
        idle = NewLinearFrames(0,3,0.5),
        damage = NewLinearFrames(4,5,0.1),
        xy = {0,0},
        zoom = 1,
        load = THEME:GetPathG("","Characters/Enemies/001 2x3.png")
    },
    x002 = {
        idle = NewLinearFrames(0,5,0.5),
        damage = NewLinearFrames(6,7,0.1),
        xy = {-30,-50},
        zoom = 1
    },
    x004 = {
        idle = NewLinearFrames(2,5,0.5),
        damage = NewLinearFrames(0,1,0.1),
        xy = {-38,-50},
        zoom = .5
    },
    x003 = {
        idle = NewLinearFrames(0,3,0.5),
        damage = NewLinearFrames(4,5,0.1),
        xy = {-100,-90},
        zoom = .75,
        load = THEME:GetPathG("","Characters/Enemies/003 3x2.png")
    },
}

GetCharacter = function(char)
    if Character[char] then return Character[char] end
    return nil
end

GetEnemy = function(char)
    if Enemy[char] then return Enemy[char] end
    return nil
end