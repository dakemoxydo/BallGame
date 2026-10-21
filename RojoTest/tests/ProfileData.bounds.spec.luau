--!strict
-- The rounding rules of ProfileData. Saved progress is floored and clamped
-- before it reaches the live profile, so a corrupted or fractional save can
-- never inflate a counter.
local Data = require("../src/shared/Core/ProfileData")

local function check(condition: any, message: string)
	assert(condition, "ProfileData invariant failed: " .. message)
end

local catalog = {
	stones = { Pebble = true, Smooth = true },
	trails = { None = true, White = true },
	pets = { Dog = { name = "Dog", rarity = "Common" } },
}

return {
	["fractional progress is floored and never rounded up"] = function()
		local result = Data.normalize({ skill = 10.9, wins = 20.5, rebirths = 7.9, best = 3.2, daily = 1.5 }, catalog)
		check(result.skill == 10, "Skill is floored")
		check(result.wins == 20, "Wins are floored")
		check(result.rebirths == 7, "Rebirths are floored")
		check(result.best == 3, "The best score is floored")
		check(result.daily == 1, "The daily counter is floored")
	end,
	["a fractional counter never grows past the whole number below it"] = function()
		for _, value in { 0.1, 1.9, 12.5, 99.999, 1234.75 } do
			local result = Data.normalize({ skill = value }, catalog)
			check(result.skill <= value, "Skill never grows")
			check(result.skill == math.floor(value), "Skill is the floor of the saved value")
		end
	end,
	["the floor keeps the cap and the bottom of the range"] = function()
		local capped = Data.normalize({ skill = 1e15 + 0.5, wins = 1e15 + 0.9 }, catalog)
		check(capped.skill == 1e15, "The skill cap survives a fractional overflow")
		check(capped.wins == 1e15, "The win cap survives a fractional overflow")
		local negative = Data.normalize({ skill = -0.5, wins = -3.7 }, catalog)
		check(negative.skill == 0, "A negative skill stays at zero")
		check(negative.wins == 0, "Negative wins stay at zero")
	end,
	["the volume settings are floored and clamped to the slider range"] = function()
		local result = Data.normalize({ settings = { sound = 55.7, music = 99.9 } }, catalog)
		check(result.settings.sound == 55, "The sound volume is floored")
		check(result.settings.music == 99, "The music volume is floored")
		local loud = Data.normalize({ settings = { sound = 150.5, music = 1e9 } }, catalog)
		check(loud.settings.sound == 100, "The sound volume never leaves the slider range")
		check(loud.settings.music == 100, "The music volume never leaves the slider range")
	end,
	["a broken volume falls back to the default"] = function()
		local result = Data.normalize({ settings = { sound = 0 / 0, music = math.huge } }, catalog)
		check(result.settings.sound == 100, "A broken sound volume falls back")
		check(result.settings.music == 100, "A broken music volume falls back")
	end,
	["a toggle survives only as a boolean"] = function()
		local result = Data.normalize({ settings = { shake = false, effects = true, hideHUD = true } }, catalog)
		check(not result.settings.shake, "The shake toggle is kept")
		check(result.settings.effects, "The effects toggle is kept")
		check(result.settings.hideHUD, "The hide HUD toggle is kept")
		local broken = Data.normalize({ settings = { shake = "no", effects = 1, hideHUD = nil } }, catalog)
		check(broken.settings.shake == true, "A broken shake toggle keeps the default")
		check(broken.settings.effects == true, "A broken effects toggle keeps the default")
		check(broken.settings.hideHUD == false, "A missing hide HUD toggle keeps the default")
	end,
}
