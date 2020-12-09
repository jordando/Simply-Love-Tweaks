local player, score, side = unpack(...)

assert(player and score and side, "HighScoreDisplay module requires a player, score, and side")

return Def.ActorFrame{
    -- labels like "FANTASTIC", "MISS", "holds", "rolls", etc.
	LoadActor("./JudgmentLabels.lua",  {player, score, side}),

	-- score displayed as a percentage
	LoadActor("./Percentage.lua",  {score, side}),

	-- numbers (How many Fantastics? How many Misses? etc.)
    LoadActor("./JudgmentNumbers.lua",  {player, score, side}),

}