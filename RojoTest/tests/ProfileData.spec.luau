--!strict
local Data = require("../src/shared/Core/ProfileData")
local Net = require("../src/shared/Net")
local function check(condition: any)
	assert(condition, "Profile/network invariant failed")
end
local catalog = {
	stones = { Pebble = true, Smooth = true },
	trails = { None = true, White = true },
	pets = { Dog = { name = "Dog", rarity = "Common" } },
}

return {
	["legacy progress, fractional boosts and receipts survive normalization"] = function()
		local old = Data.fresh()
		old.skill, old.wins, old.rebirths, old.best = 98453, 100000, 7, 8969
		old.stones.Smooth, old.stone, old.trails.White, old.trail = true, "Smooth", true, "White"
		old.world, old.unlockedWorld2 = 2, true
		old.pets = { { uid = "one", id = "Dog", boost = 1.2 } }
		old.equipped, old.receipts = { "one" }, { paid = true }
		local progress, err = Data.legacy({ data = old, expires = 0 }, 1000)
		check(not err)
		local result = Data.normalize(progress, catalog)
		check(result.skill == 98453 and result.wins == 100000 and result.rebirths == 7 and result.best == 8969)
		check(result.stone == "Smooth" and result.trail == "White" and result.world == 2 and result.unlockedWorld2)
		check(result.pets[1].boost == 1.2 and result.equipped[1] == "one" and result.receipts.paid)
		check(result ~= old and result.pets ~= old.pets and old.pets[1].boost == 1.2)
	end,
	["active and malformed legacy records cannot become fresh live profiles"] = function()
		local _, active = Data.legacy({ data = {}, owner = "old-server", expires = 1001 }, 1000)
		local _, malformed = Data.legacy({ wrong = true }, 1000)
		check(active and malformed)
		local record, err = Data.legacy(nil, 1000)
		check(record == nil and err == nil)
	end,
	["corrupt values cannot poison progression or equipment"] = function()
		local input = {
			skill = 0 / 0,
			wins = math.huge,
			best = -3,
			stone = "Smooth",
			stones = { Smooth = false },
			pets = { false, { uid = "a", id = "Dog", boost = 0 / 0 }, { uid = "a", id = "Dog", boost = 99 } },
			equipped = { "a", "a", "missing" },
			settings = { sound = -20, music = math.huge, shake = false },
		}
		local result = Data.normalize(input, catalog)
		check(result.skill == 0 and result.wins == 0 and result.best == 0 and result.stone == "Pebble")
		check(#result.pets == 1 and result.pets[1].boost == 1 and #result.equipped == 1)
		check(result.settings.sound == 0 and result.settings.music == 100 and not result.settings.shake)
	end,
	["separate fresh profiles do not share inventory or settings tables"] = function()
		local first, second = Data.fresh(), Data.fresh()
		first.stones.Smooth = true
		first.settings.sound = 0
		check(not second.stones.Smooth and second.settings.sound == 100)
	end,
	["network rejects unknown commands, invalid types, NaN and nested payloads"] = function()
		check(Net.validAction("Throw", nil, nil) and Net.validAction("Hatch", "Rare", 3))
		check(Net.validAction("Setting", "effects", false) and Net.validAction("Gift", 6, nil))
		check(not Net.validAction("GiveWins", nil, nil) and not Net.validAction("Throw", {}, nil))
		check(not Net.validAction("Gift", 0 / 0, nil) and not Net.validAction("Gift", 1.5, nil))
		check(not Net.validAction("Hatch", "Rare", 100) and not Net.validAction("Pet", {}, nil))
		check(not Net.validAction("Setting", "sound", math.huge))
	end,
}
