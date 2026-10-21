--!strict
local Economy = require("../src/shared/Core/Economy")
local function check(condition: any, message: string)
	assert(condition, "Economy invariant failed: " .. message)
end

local function pet(id: string, name: string, rarity: string, boost: number, weight: number)
	return { id = id, name = name, rarity = rarity, boost = boost, weight = weight }
end

local COMMON_POOL = {
	pet("Dog", "Dog", "Common", 1.2, 40),
	pet("Cat", "Cat", "Common", 1.5, 30),
	pet("Bunny", "Clover Bun", "Uncommon", 2.5, 20),
	pet("Fox", "Golden Fox", "Rare", 4, 9),
	pet("Dragon", "Crystal Dragon", "Legendary", 8, 1),
}

return {
	["levels and thresholds agree at every boundary"] = function()
		for _, rebirths in { 0, 1, 2, 4, 8 } do
			local previous = 0
			for level = 1, Economy.MaxLevel do
				local threshold = Economy.threshold(level, rebirths)
				check(threshold >= previous, "Level thresholds never fall")
				previous = threshold
				check(Economy.level(threshold, rebirths) == level, "Exact threshold reaches its level")
				if level > 1 then
					check(Economy.level(threshold - 1, rebirths) == level - 1, "No level before its threshold")
				end
			end
			check(Economy.threshold(1, rebirths) == 0, "Level 1 starts at zero")
			check(
				Economy.threshold(Economy.MaxLevel, rebirths) == Economy.rebirthRequirement(rebirths),
				"The last level uses the rebirth goal"
			)
		end
		check(Economy.level(0, 0) == 1, "No Skill means level 1")
		check(Economy.level(-500, 0) == 1, "Negative Skill never grants a level")
	end,
	["rebirth requirements grow and stay capped"] = function()
		local expected = { [0] = 50000, [1] = 80000, [2] = 128000, [3] = 204800 }
		for rebirths, value in expected do
			check(Economy.rebirthRequirement(rebirths) == value, "Early rebirth curve")
		end
		local previous = 0
		for rebirths = 0, 100 do
			local requirement = Economy.rebirthRequirement(rebirths)
			check(requirement <= 1e15, "The requirement stays inside the cap")
			if requirement < 1e15 then
				check(requirement > previous, "Every rebirth costs more Skill")
				previous = requirement
			else
				check(requirement == 1e15, "The cap is exact")
				break
			end
		end
		check(Economy.rebirthRequirement(10000) == 1e15, "Huge rebirth counts stay capped")
		check(Economy.rebirthRequirement(-5) == Economy.rebirthRequirement(0), "Negative rebirths are clamped")
		check(Economy.rebirthRequirement(nil) == Economy.rebirthRequirement(0), "A missing count is zero")
		check(Economy.threshold(80, 1) > Economy.threshold(80, 0), "The next rebirth needs more Skill")
	end,
	["rebirth progress spans the level range"] = function()
		local level, maxLevel, progress = Economy.rebirthProgress(0, 0)
		check(level == 1 and maxLevel == Economy.MaxLevel and progress == 0, "Level 1 starts empty")
		local requirement = Economy.rebirthRequirement(0)
		local lockedLevel, _, lockedProgress = Economy.rebirthProgress(requirement - 1, 0)
		check(lockedLevel == Economy.MaxLevel - 1 and lockedProgress < 1, "The last level stays locked")
		local readyLevel, readyGoal, readyProgress = Economy.rebirthProgress(requirement, 0)
		check(readyLevel == Economy.MaxLevel and readyGoal == Economy.MaxLevel and readyProgress == 1, "Max level")
		local resetLevel, _, resetProgress = Economy.rebirthProgress(0, 1)
		check(resetLevel == 1 and resetProgress == 0, "A rebirth resets the level")
	end,
	["large numbers are abbreviated"] = function()
		check(Economy.format(0) == "0", "Zero")
		check(Economy.format(999) == "999", "Below a thousand")
		check(Economy.format(1000) == "1K", "One thousand")
		check(Economy.format(1500) == "1.5K", "One and a half thousand")
		check(Economy.format(1e6) == "1M", "One million")
		check(Economy.format(1.25e9) == "1.25B", "One and a quarter billion")
		check(Economy.format(1e12) == "1T", "One trillion")
		check(Economy.format(999999) == "1000K", "The largest step still wins")
	end,
	["shot distance runs from the floor to the route limit"] = function()
		local limit = 9000
		check(Economy.shotDistance(0, limit) == Economy.ShotDistanceFloor, "The minimum launch distance")
		check(Economy.shotDistance(1, limit) == limit, "The maximum launch distance")
		local previous = Economy.ShotDistanceFloor
		for step = 0, 100 do
			local distance = Economy.shotDistance(step / 100, limit)
			check(distance >= previous, "The distance never falls")
			previous = distance
		end
		check(Economy.shotDistance(2, limit) == limit, "Ratios above one stay at the limit")
		check(Economy.shotDistance(-1, limit) == Economy.ShotDistanceFloor, "Ratios below zero stay at the floor")
		check(Economy.shotDistance(0.5, limit) > Economy.shotDistance(0.25, limit), "More power throws further")
		-- A route that is shorter than the floor does not shorten the throw
		-- below the floor.
		check(Economy.shotDistance(0, 10) == Economy.ShotDistanceFloor, "A short route keeps the floor")
		check(Economy.shotDistance(1, 10) == Economy.ShotDistanceFloor, "A short route keeps the floor at full power")
		check(Economy.shotDistance(0.5, 10) == Economy.ShotDistanceFloor, "A short route never dips below the floor")
	end,
	["shot power and ratio stay inside the curve"] = function()
		check(Economy.effectiveShotPower(1000, 2) == 2000, "Power multiplies Skill")
		check(Economy.effectiveShotPower(1000, nil) == 1000, "A missing power counts as one")
		check(Economy.effectiveShotPower(1000, 0) == 1000, "Zero power counts as one")
		check(Economy.effectiveShotPower(-10, 1) == 0, "Negative Skill counts as zero")
		check(Economy.shotRatio(0, 1, 1000) == 0, "No Skill means no ratio")
		check(Economy.shotRatio(500, 1, 1000) == 0.5, "Half the goal means half the ratio")
		check(Economy.shotRatio(5000, 1, 1000) == 1, "The ratio is capped")
		check(Economy.shotRatio(-100, 1, 1000) == 0, "Negative Skill means no ratio")
		-- A goal of zero has no ratio: the division would be an infinity that
		-- the clamp would turn into a full shot without a word.
		check(not pcall(function()
			return Economy.shotRatio(1000, 1, 0)
		end), "A zero goal fails")
		check(not pcall(function()
			return Economy.shotRatio(1000, 1, -5)
		end), "A negative goal fails")
		check(not pcall(function()
			return Economy.shotRatio(1000, 1, 0 / 0)
		end), "A broken goal fails")
	end,
	["egg rolls follow the cumulative weights"] = function()
		check(Economy.totalWeight(COMMON_POOL) == 100, "The common pool adds up to a hundred")
		check(Economy.rollPet(COMMON_POOL, 1).id == "Dog", "The first roll hits the first pet")
		check(Economy.rollPet(COMMON_POOL, 40).id == "Dog", "The last roll of a pet stays with it")
		check(Economy.rollPet(COMMON_POOL, 41).id == "Cat", "The next roll moves on")
		check(Economy.rollPet(COMMON_POOL, 70).id == "Cat", "The second pet ends at seventy")
		check(Economy.rollPet(COMMON_POOL, 71).id == "Bunny", "The third pet starts at seventy one")
		check(Economy.rollPet(COMMON_POOL, 90).id == "Bunny", "The third pet ends at ninety")
		check(Economy.rollPet(COMMON_POOL, 91).id == "Fox", "The fourth pet starts at ninety one")
		check(Economy.rollPet(COMMON_POOL, 99).id == "Fox", "The fourth pet ends at ninety nine")
		check(Economy.rollPet(COMMON_POOL, 100).id == "Dragon", "The last roll hits the last pet")
		local counts = {}
		for roll = 1, 100 do
			local id = Economy.rollPet(COMMON_POOL, roll).id
			counts[id] = (counts[id] or 0) + 1
		end
		check(counts.Dog == 40, "Dog weight")
		check(counts.Cat == 30, "Cat weight")
		check(counts.Bunny == 20, "Bunny weight")
		check(counts.Fox == 9, "Fox weight")
		check(counts.Dragon == 1, "Dragon weight")
		check(not pcall(function()
			return Economy.rollPet(COMMON_POOL, 0)
		end), "A roll below the range fails")
		check(not pcall(function()
			return Economy.rollPet(COMMON_POOL, 101)
		end), "A roll above the range fails")
	end,
	["egg pools are chosen by id"] = function()
		local pools = {
			Common = COMMON_POOL,
			Uncommon = { pet("Cactus", "Cactus", "Common", 1.2, 100) },
			Rare = { pet("Shark", "Shark", "Common", 1.2, 100) },
			Rainbow = { pet("Butterfly", "Butterfly", "Common", 1.2, 100) },
		}
		check(Economy.eggPoolKey("Uncommon") == "Uncommon", "The uncommon pool")
		check(Economy.eggPoolKey("Rare") == "Rare", "The rare pool")
		check(Economy.eggPoolKey("Rainbow") == "Rainbow", "The rainbow pool")
		check(Economy.eggPoolKey("Common") == "Common", "The common pool")
		check(Economy.eggPoolKey("Unknown") == "Common", "An unknown egg falls back")
		check(Economy.eggPoolKey(nil) == "Common", "A missing egg falls back")
		check(Economy.eggPets(pools, "Rare")[1].id == "Shark", "The rare pool is selected")
		check(Economy.eggPets(pools, "Rainbow")[1].id == "Butterfly", "The rainbow pool is selected")
		check(Economy.eggPets(pools, "Unknown")[1].id == "Dog", "An unknown egg uses the common pool")
	end,
	["descriptors drop the colour and the visual"] = function()
		local descriptor = Economy.petDescriptor({
			id = "Dog",
			name = "Dog",
			rarity = "Common",
			boost = 1.2,
			weight = 40,
			color = "red",
			visual = "Dog",
			eggBoost = 5,
		})
		check(descriptor.id == "Dog" and descriptor.weight == 40 and descriptor.eggBoost == 5, "Pure fields survive")
		local keys = 0
		for _ in descriptor do
			keys += 1
		end
		check(keys == 6, "Only the pure fields are kept")
		-- A pet without the optional field keeps it empty and not broken.
		local plain = Economy.petDescriptor(COMMON_POOL[1])
		check(plain.eggBoost == nil, "A pet without an egg boost has none")
		check(plain.id == "Dog" and plain.name == "Dog", "The plain fields survive")
		local descriptors = Economy.petDescriptors(COMMON_POOL)
		check(#descriptors == 5 and descriptors[1].id == "Dog" and descriptors[5].weight == 1, "Pool order is kept")
		check(Economy.totalWeight(descriptors) == 100, "The descriptors keep the weights")
		for index, source in COMMON_POOL do
			check(descriptors[index].id == source.id, "Every descriptor keeps its slot")
		end
	end,
	["pets are found by id and not by position"] = function()
		check(Economy.petById(COMMON_POOL, "Dog").id == "Dog", "The first pet is found")
		check(Economy.petById(COMMON_POOL, "Dragon").weight == 1, "The last pet is found")
		check(Economy.petById(COMMON_POOL, "Missing") == nil, "An unknown id has no pet")
		-- The order of a pool may change, the id of a pet may not.
		local shuffled = { COMMON_POOL[3], COMMON_POOL[1], COMMON_POOL[5], COMMON_POOL[2], COMMON_POOL[4] }
		for _, descriptor in Economy.petDescriptors(COMMON_POOL) do
			local found = Economy.petById(shuffled, descriptor.id)
			check(found ~= nil, "Every descriptor has a pet with the same id")
			check(found.id == descriptor.id, "The id is the identity of a pet")
			check(found.weight == descriptor.weight, "The descriptor keeps the weight of its pet")
		end
		local rolled = Economy.rollPet(Economy.petDescriptors(COMMON_POOL), 71)
		check(Economy.petById(shuffled, rolled.id).id == "Bunny", "A roll finds its pet in a reordered pool")
	end,
	["bounce gains floor the multiplier"] = function()
		check(Economy.shotBounceGain(1) == 7, "A plain bounce")
		check(Economy.shotBounceGain(1.5) == 10, "A fractional multiplier")
		check(Economy.shotBounceGain(0.5) == 3, "A small multiplier")
		check(Economy.shotBounceGain(2.25) == 15, "A large multiplier")
		check(Economy.shotBounceGain(0) == 0, "No multiplier means no Skill")
	end,
}
