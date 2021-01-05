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
        load = THEME:GetPathG("","Characters/Quina2/quina 8x14.png"),
        icon = THEME:GetPathG("","Characters/Quina2/unit_icon.png")
    }
}

local Enemy = {
    x001 = {
        idle = NewLinearFrames(0,3,0.5),
        damage = NewLinearFrames(4,5,0.1),
        xy = {0,0},
        zoom = 1
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