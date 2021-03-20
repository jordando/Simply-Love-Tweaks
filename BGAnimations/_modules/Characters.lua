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
        name = "Quina",
        displayName = "Quina",
        attack = NewLinearFrames(0,11, 1.5),
        idle = NewLinearFrames(12,27,1.5),
        limit = NewLinearFrames(28,70,1.5),
        magic = NewLinearFrames(71,78,0.75),
        magic2 = NewLinearFrames(79,85,0.75),
        standby = NewLinearFrames(86,96,1.5),
        winIntro = NewLinearFrames(97,106,1.5),
        win = NewLinearFrames(97,106,1.5),
        still = NewLinearFrames(108,108,1),
        danger = NewLinearFrames(110,110,1),
        dead = NewLinearFrames(109,109,1),
        stillXY = {75,10,73,-1},
        idleXY = {0,0},
        magic2XY = {0,-10},
        winIntroXY = {-20,0},
        winXY = {-20,0},
        deadXY = {0,50},
        dangerXY = {0,30},
        attackXY = {-125,10},
        load = THEME:GetPathG("","Characters/Quina/quina 8x14.png"),
        icon = THEME:GetPathG("","Characters/Quina/unit_icon.png"),
        ills = THEME:GetPathG("","Characters/Quina/unit_ills.png"),
        splash = THEME:GetPathG("","Characters/Quina/splash.png"),
        text = "That French bougie who only eats frogs. Young Thug's fashion inspiration.",
        game = "FF9",
    },
    Steiner = {
        name = "Steiner",
        displayName = "Steiner",
        attack = NewLinearFrames(0,12, 1.5),
        idle = NewLinearFrames(13,16,.75),
        limit = NewLinearFrames(0,12,1.5),
        magic = NewLinearFrames(17,20,0.75),
        magic2 = NewLinearFrames(21,23,0.75),
        standby = NewLinearFrames(24,27,1.5),
        win = NewLinearFrames(29,32,.5),
        winIntro = NewLinearFrames(33,50,2),
        still = NewLinearFrames(53,53,1),
        danger = NewLinearFrames(52,52,1),
        dead = NewLinearFrames(51,51,1),
        stillXY = {60,45,60,50},
        idleXY = {0,50},
        magic2XY = {0,40},
        winIntroXY = {-40,0},
        winXY = {6,0},
        deadXY = {0,80},
        dangerXY = {0,70},
        attackXY = {-125,-75},
        load = THEME:GetPathG("","Characters/Steiner/Steiner 9x6.png"),
        icon = THEME:GetPathG("","Characters/Steiner/unit_icon.png"),
        ills = THEME:GetPathG("","Characters/Steiner/unit_ills.png"),
        splash = THEME:GetPathG("","Characters/Steiner/splash.jpg"),
        text = "Probably wears makeup.",
        game = "FF9",

    },
    Beatrix = {
        name = "Beatrix",
        displayName = "Beatrix",
        attack = NewLinearFrames(4,17, 1.5),
        idle = NewLinearFrames(0,3,.75),
        limit = NewLinearFrames(4,18, 1.5),
        magic = NewLinearFrames(20,23,0.75),
        magic2 = NewLinearFrames(24,27,0.75),
        standby = NewLinearFrames(28,31,1.5),
        win = NewLinearFrames(32,35,.5),
        winIntro = NewLinearFrames(36,49,2),
        still = NewLinearFrames(50,50,1),
        danger = NewLinearFrames(19,19,1),
        dead = NewLinearFrames(18,18,1),
        stillXY = {60,35,65,40},
        idleXY = {0,30},
        magic2XY = {0,10},
        winIntroXY = {-10,0},
        winXY = {19,22},
        deadXY = {0,70},
        dangerXY = {0,50},
        attackXY = {-125,-45},
        load = THEME:GetPathG("","Characters/Beatrix/Beatrix 4x13.png"),
        icon = THEME:GetPathG("","Characters/Beatrix/unit_icon.png"),
        ills = THEME:GetPathG("","Characters/Beatrix/unit_ills.png"),
        splash = THEME:GetPathG("","Characters/Beatrix/splash.jpg"),
        text = "Female Steiner.",
        game = "FF9",

    },
    TwoB = {
        name = "TwoB",
        displayName = "2B",
        attack = THEME:GetPathG("","Characters/2B/attack 6x8.png"),
        attackFrames = {48,1.5},
        attackTime = 1.5,
        idle = NewLinearFrames(2,5,.75),
        --limit = NewLinearFrames(0,43, 1.5),
        magic = NewLinearFrames(6,9,0.75),
        magic2 = NewLinearFrames(10,13,0.75),
        standby = NewLinearFrames(14,17,1.5),
        win = NewLinearFrames(18,41,3),
        winIntro = NewLinearFrames(42,61,3),
        still = NewLinearFrames(62,62,1),
        danger = NewLinearFrames(1,1,1),
        dead = NewLinearFrames(0,0,1),
        stillXY = {0,-10,5,-7},
        idleXY = {0,-10},
        magic2XY = {0,-10},
        winIntroXY = {-10,0},
        winXY = {0,1},
        deadXY = {10,30},
        dangerXY = {10,0},
        attackXY = {-250,-45},
        load = THEME:GetPathG("","Characters/2B/2B 21x3.png"),
        icon = THEME:GetPathG("","Characters/2B/unit_icon.png"),
        ills = THEME:GetPathG("","Characters/2B/unit_ills.png"),
        splash = THEME:GetPathG("","Characters/2B/splash.jpg"),
        text = "It always ends like this...",
        game = "Nier",

    },
    Orlandeau = {
        name = "Orlandeau",
        displayName = "Orlandeau",
        attack = NewLinearFrames(0,8, 1.5),
        idle = NewLinearFrames(11,14,.75),
        limit = NewLinearFrames(0,8,1.5),
        magic = NewLinearFrames(15,18,0.75),
        magic2 = NewLinearFrames(19,26,0.75),
        standby = NewLinearFrames(27,30,1.5),
        win = NewLinearFrames(31,34,.5),
        winIntro = NewLinearFrames(35,46,2),
        still = NewLinearFrames(47,47,1),
        danger = NewLinearFrames(10,10,1),
        dead = NewLinearFrames(9,9,1),
        stillXY = {40,10,45,15},
        idleXY = {0,0},
        magic2XY = {0,-30},
        winIntroXY = {-40,0},
        winXY = {-12.5,13},
        deadXY = {0,25},
        dangerXY = {0,20},
        attackXY = {-75,-20},
        load = THEME:GetPathG("","Characters/Orlandeau/Orlandeau 12x4.png"),
        icon = THEME:GetPathG("","Characters/Orlandeau/unit_icon.png"),
        ills = THEME:GetPathG("","Characters/Orlandeau/unit_ills.png"),
        splash = THEME:GetPathG("","Characters/Orlandeau/splash.png"),
        text = "Also known as Cid. Much weaker once he joins your team. Dresses like a jedi.",
        game = "FFT",
    },
    CaitSith = {
        name = "CaitSith",
        displayName = "Cait Sith",
        attack = NewLinearFrames(0,6, 1.5),
        idle = NewLinearFrames(9,12,1.5),
        limit = NewLinearFrames(14,46,1.5),
        magic = NewLinearFrames(47,50,0.75),
        magic2 = NewLinearFrames(51,54,0.75),
        standby = NewLinearFrames(55,82,1.5),
        win = NewLinearFrames(83,90,1.5),
        winIntro = NewLinearFrames(83,90,1.5),
        still = NewLinearFrames(13,13,1),
        danger = NewLinearFrames(8,8,1),
        dead = NewLinearFrames(7,7,1),
        stillXY = {25,0,24,3},
        idleXY = {0,0},
        magic2XY = {0,0},
        winIntroXY = {0,-25},
        winXY = {0,-25},
        deadXY = {0,25},
        dangerXY = {0,20},
        attackXY = {0,-20},
        load = THEME:GetPathG("","Characters/Cait Sith/Cait Sith 13x7.png"),
        icon = THEME:GetPathG("","Characters/Cait Sith/unit_icon.png"),
        ills = THEME:GetPathG("","Characters/Cait Sith/unit_ills.png"),
        splash = THEME:GetPathG("","Characters/Cait Sith/splash.jpg"),
        text = "DJ Yoshitaka.",
        game = "FF7",
    },
    Sora = {
        name = "Sora",
        displayName = "Sora",
        attack = NewLinearFrames(6,24, 1.5),
        idle = NewLinearFrames(0,3,1),
        limit = NewLinearFrames(6,24, 1.5),
        magic = NewLinearFrames(25,28,0.75),
        magic2 = NewLinearFrames(29,32,0.75),
        standby = NewLinearFrames(33,36,1.5),
        win = NewLinearFrames(37,42,1),
        winIntro = NewLinearFrames(43,75,3),
        still = NewLinearFrames(76,76,1),
        danger = NewLinearFrames(5,5,1),
        dead = NewLinearFrames(4,4,1),
        stillXY = {85,30,97,35}, --second set is for when character is idling in Select a character
        idleXY = {10,25},
        magic2XY = {-7,-23},
        winIntroXY = {0,0},
        winXY = {18,18},
        deadXY = {25,55},
        dangerXY = {25,45},
        attackXY = {-175,-20},
        load = THEME:GetPathG("","Characters/Sora/Sora 7x11.png"),
        icon = THEME:GetPathG("","Characters/Sora/unit_icon.png"),
        ills = THEME:GetPathG("","Characters/Sora/unit_ills.png"),
        splash = THEME:GetPathG("","Characters/Sora/splash4.png"),
        text = "Seems to really like popsicles. Not even from Final Fantasy.",
        game = "KH",
    },
    Cloud1 = {
        name = "Cloud1",
        displayName = "Cloud",
        attack = NewLinearFrames(0,11, 1.5),
        idle = NewLinearFrames(14,17,.75),
        limit = NewLinearFrames(0,11, 1.5),
        magic = NewLinearFrames(18,21,0.75),
        magic2 = NewLinearFrames(22,25,0.75),
        standby = NewLinearFrames(26,29,1.5),
        win = NewLinearFrames(30,49,2),
        winIntro = NewLinearFrames(50,74,3),
        still = NewLinearFrames(75,75,1),
        danger = NewLinearFrames(13,13,1),
        dead = NewLinearFrames(12,12,1),
        stillXY = {55,15,60,20}, --second set is for when character is idling in Select a character
        idleXY = {5,10},
        magic2XY = {13,2},
        winIntroXY = {-15,-30},
        winXY = {30,4},
        deadXY = {-20,50},
        dangerXY = {3,23},
        attackXY = {-100,-20},
        load = THEME:GetPathG("","Characters/Cloud/Cloud1 7x11.png"),
        icon = THEME:GetPathG("","Characters/Cloud/unit_icon_1.png"),
        ills = THEME:GetPathG("","Characters/Cloud/unit_ills_1.png"),
        splash = THEME:GetPathG("","Characters/Cloud/splash2.png"),
        text = "'Uh...... aaa......? A...... Gurk......?' - Cloud Strife",
        game = "FF7",
    },
        poog = {
        name = "poog",
        displayName = "poog",
        zoom = .4,
        stillZoom = .3,
        attack = NewLinearFrames(15,26, .5),
        idle = NewLinearFrames(8,14,2),
        limit = NewLinearFrames(0,6, 1.5),
        magic = NewLinearFrames(27,33,0.75),
        magic2 = NewLinearFrames(27,33,.4),
        standby = NewLinearFrames(27,33,1.5),
        win = NewLinearFrames(34,35,.5),
        winIntro = NewLinearFrames(34,35,.5),
        still = NewLinearFrames(15,15,1),
        danger = NewLinearFrames(0,6,1),
        dead = NewLinearFrames(7,7,1),
        stillXY = {0,-10,9.5,-10}, --second set is for when character is idling in Select a character
        idleXY = {0,-35},
        magic2XY = {0,-35},
        winIntroXY = {0,-35},
        winXY = {0,-35},
        deadXY = {0,-35},
        dangerXY = {0,-35},
        attackXY = {-13,-35},
        load = THEME:GetPathG("","Characters/poog/poog 9x4.png"),
        icon = THEME:GetPathG("","Characters/poog/unit_icon.png"),
        splash = THEME:GetPathG("","Characters/poog/splash1.png"),
        text = "I'm gonna take it easy today.",
        game = "ITG",
    },
    nanami = {
        name = "nanami",
        displayName = "Nanami",
        zoom = .4,
        stillZoom = .3,
        attack = NewLinearFrames(22,26, .5),
        idle = NewLinearFrames(9,13,.5),
        limit = NewLinearFrames(0,6, 1.5),
        magic = NewLinearFrames(14,21, .5),
        magic2 = NewLinearFrames(14,21, .5),
        standby = NewLinearFrames(14,21, .5),
        win = NewLinearFrames(27,32,2),
        winIntro = NewLinearFrames(27,32,2),
        still = NewLinearFrames(9,9,1),
        danger = NewLinearFrames(0,7,1),
        dead = NewLinearFrames(8,8,1),
        stillXY = {10,-10,10,-10}, --second set is for when character is idling in Select a character
        idleXY = {0,-35},
        magic2XY = {0,-35},
        winIntroXY = {-5,-30},
        winXY = {-25,-30},
        deadXY = {-20,0},
        dangerXY = {0,-35},
        attackXY = {-13,-35},
        load = THEME:GetPathG("","Characters/Nanami/nanami 7x5.png"),
        icon = THEME:GetPathG("","Characters/Nanami/unit_icon.png"),
        splash = THEME:GetPathG("","Characters/Nanami/splash.png"),
        text = "Happy. Lucky. Smile. Yay!",
        game = "ITG",
    },
    zarzob = {
        name = "zarzob",
        displayName = "zarzob",
        zoom = .4,
        stillZoom = .3,
        attack = NewLinearFrames(16,23, .5),
        idle = NewLinearFrames(8,15,2),
        limit = NewLinearFrames(0,6, 1.5),
        magic = NewLinearFrames(27,33,0.75),
        magic2 = NewLinearFrames(24,31,.7),
        standby = NewLinearFrames(27,33,1.5),
        win = NewLinearFrames(32,33,.5),
        winIntro = NewLinearFrames(32,33,.5),
        still = NewLinearFrames(24,24,1),
        danger = NewLinearFrames(0,7,1),
        dead = NewLinearFrames(34,34,1),
        stillXY = {10,-10,10,-10}, --second set is for when character is idling in Select a character
        idleXY = {0,-35},
        magic2XY = {0,-35},
        winIntroXY = {0,-35},
        winXY = {0,-35},
        deadXY = {0,-35},
        dangerXY = {0,-35},
        attackXY = {0,-35},
        load = THEME:GetPathG("","Characters/zarzob/zarzob 7x5.png"),
        icon = THEME:GetPathG("","Characters/zarzob/unit_icon.png"),
        splash = THEME:GetPathG("","Characters/zarzob/splash.png"),
        text = "Ooh yis. This's one of my favorite songs.",
        game = "ITG",
    }
}

local BigEnemy = {
    {
        idle = NewLinearFrames(0,3,0.5),
        damage = NewLinearFrames(4,5,0.1),
        xy = {0,0},
        zoom = 1,
        load = THEME:GetPathG("","Characters/Enemies/001 2x3.png")
    },
    {
        idle = NewLinearFrames(0,5,0.5),
        damage = NewLinearFrames(6,7,0.1),
        xy = {-30,-50},
        zoom = 1,
        load = THEME:GetPathG("","Characters/Enemies/002 1x8.png")
    },
    {
        idle = NewLinearFrames(0,3,0.5),
        damage = NewLinearFrames(4,5,0.1),
        xy = {-100,-90},
        zoom = .75,
        load = THEME:GetPathG("","Characters/Enemies/003 3x2.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),
        damage = NewLinearFrames(0,1,0.1),
        xy = {-38,-50},
        zoom = .5,
        load = THEME:GetPathG("","Characters/Enemies/004 6x1.png")
    },
}

local Enemy = {
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,0},
        load = THEME:GetPathG("","Characters/Enemies/e001 6x1.png")
    },
    {
        idle = NewLinearFrames(2,9,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,0},
        load = THEME:GetPathG("","Characters/Enemies/e002 10x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,0},
        load = THEME:GetPathG("","Characters/Enemies/e003 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e004 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e005 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,10},
        zoom = .8,
        load = THEME:GetPathG("","Characters/Enemies/e006 1x6.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,0},
        load = THEME:GetPathG("","Characters/Enemies/e007 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e008 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e009 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {-30,-30},
        load = THEME:GetPathG("","Characters/Enemies/e010 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e011 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e012 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,0},
        load = THEME:GetPathG("","Characters/Enemies/e013 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e014 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,0},
        load = THEME:GetPathG("","Characters/Enemies/e015 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e016 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-20},
        load = THEME:GetPathG("","Characters/Enemies/e017 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-10},
        load = THEME:GetPathG("","Characters/Enemies/e018 6x1.png")
    },
    {
        idle = NewLinearFrames(2,7,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e019 8x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-25},
        load = THEME:GetPathG("","Characters/Enemies/e020 6x1.png")
    },
    {
        idle = NewLinearFrames(2,9,1),damage = NewLinearFrames(0,1,0.1),
        xy = {-10,-20},
        load = THEME:GetPathG("","Characters/Enemies/e021 10x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-25},
        load = THEME:GetPathG("","Characters/Enemies/e022 6x1.png")
    },    {
        idle = NewLinearFrames(2,9,1),damage = NewLinearFrames(0,1,0.1),
        xy = {-10,-20},
        load = THEME:GetPathG("","Characters/Enemies/e023 10x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {00,-15},
        load = THEME:GetPathG("","Characters/Enemies/e024 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,10},
        zoom = .8,
        load = THEME:GetPathG("","Characters/Enemies/e025 6x1.png")
    },
    {
        --TODO SUPER DUMB ENEMY???
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-20},
        load = THEME:GetPathG("","Characters/Enemies/e026 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-20},
        load = THEME:GetPathG("","Characters/Enemies/e027 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-10},
        load = THEME:GetPathG("","Characters/Enemies/e028 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-10,-20},
        load = THEME:GetPathG("","Characters/Enemies/e029 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {0,0},
        load = THEME:GetPathG("","Characters/Enemies/e030 6x1.png")
    },
    {
        idle = NewLinearFrames(2,7,0.75),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-10},
        load = THEME:GetPathG("","Characters/Enemies/e031 8x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {00,-30},
        load = THEME:GetPathG("","Characters/Enemies/e032 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.6),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-10},
        load = THEME:GetPathG("","Characters/Enemies/e033 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.6),damage = NewLinearFrames(0,1,0.1),
        xy = {0,-10},
        load = THEME:GetPathG("","Characters/Enemies/e034 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-10},
        load = THEME:GetPathG("","Characters/Enemies/e035 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-20},
        load = THEME:GetPathG("","Characters/Enemies/e036 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-10,-20},
        load = THEME:GetPathG("","Characters/Enemies/e037 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {-35,-10},
        load = THEME:GetPathG("","Characters/Enemies/e038 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,1),damage = NewLinearFrames(0,1,0.1),
        xy = {-40,-30},
        load = THEME:GetPathG("","Characters/Enemies/e039 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {-30,-50},
        load = THEME:GetPathG("","Characters/Enemies/e040 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-25},
        load = THEME:GetPathG("","Characters/Enemies/e041 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,00},
        load = THEME:GetPathG("","Characters/Enemies/e042 6x1.png")
    },
    {
        --BIG?
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-40,-50},
        load = THEME:GetPathG("","Characters/Enemies/e043 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-10},
        load = THEME:GetPathG("","Characters/Enemies/e044 6x1.png")
    },
    {
        idle = NewLinearFrames(2,5,0.5),damage = NewLinearFrames(0,1,0.1),
        xy = {-20,-30},
        load = THEME:GetPathG("","Characters/Enemies/e045 6x1.png")
    },
    {
        --BIG?
        idle = NewLinearFrames(2,5,0.7),damage = NewLinearFrames(0,1,0.1),
        xy = {-30,-30},
        zoom = .9,
        load = THEME:GetPathG("","Characters/Enemies/e046 6x1.png")
    },
}

local backgrounds = {}
for i=1, 5 do
    backgrounds[#backgrounds+1] = THEME:GetPathG("","Characters/BGs/bg ("..i..").jpg")
end

GetBackground = function(bg)
    if backgrounds[bg] then return backgrounds[bg] end
    return nil
end

GetRandomBG = function()
    return backgrounds[math.random(#backgrounds)]
end

GetCharacter = function(char)
    if Character[char] then return Character[char] end
    return nil
end

GetAllCharacters = function()
    local ret = {}
    for _, value in pairs(Character) do
        ret[#ret+1] = value
    end
    return ret
end

GetEnemy = function(char)
    if Enemy[char] then return Enemy[char] end
    return nil
end

GetRandomEnemy = function()
    return Enemy[math.random(#Enemy)]
end

GetBigEnemy = function(char)
    if BigEnemy[char] then return BigEnemy[char] end
    return nil
end

GetRandomBigEnemy = function()
    return BigEnemy[math.random(#BigEnemy)]
end