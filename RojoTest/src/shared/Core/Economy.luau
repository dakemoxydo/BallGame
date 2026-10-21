--!strict
-- Pure progression and economy maths.
-- No engine types are used here, so Lune can exercise every number without Roblox.
-- GameConfig owns the visual data and delegates all arithmetic to this module.

export type PetDescriptor = {
	id: string,
	name: string,
	rarity: string,
	boost: number,
	weight: number,
	eggBoost: number?,
}

-- A pet of the configuration: the descriptor plus the fields of the scene
-- that the roll does not need. The type names the fields the descriptor
-- reads, so a typo in a field name is a type error and not a silent nil.
export type PetSource = {
	id: string,
	name: string,
	rarity: string,
	boost: number,
	weight: number,
	eggBoost: number?,
}

type FormatStep = {
	amount: number,
	suffix: string,
}

local Economy = {}

Economy.MaxLevel = 80
Economy.RebirthBaseSkill = 50000
Economy.RebirthSkillGrowth = 1.6
Economy.LevelCurveExponent = 2
Economy.ShotDistanceExponent = 0.45
Economy.ShotDistanceFloor = 60
Economy.ShotBounceBaseSkill = 7
Economy.RebirthSkillCap = 1e15

local FORMAT_STEPS: { FormatStep } = {
	{ amount = 1e12, suffix = "T" },
	{ amount = 1e9, suffix = "B" },
	{ amount = 1e6, suffix = "M" },
	{ amount = 1e3, suffix = "K" },
}

function Economy.effectiveShotPower(skill: number, power: number?): number
	return math.max(0, skill) * math.max(1, power or 1)
end

function Economy.rebirthRequirement(rebirths: number?): number
	local completed = math.max(0, math.floor(rebirths or 0))
	return math.min(
		Economy.RebirthSkillCap,
		math.floor(Economy.RebirthBaseSkill * Economy.RebirthSkillGrowth ^ completed)
	)
end

function Economy.threshold(level: number, rebirths: number?): number
	local step = math.clamp(math.floor(level), 1, Economy.MaxLevel)
	local goal = Economy.rebirthRequirement(rebirths)
	return math.ceil(goal * ((step - 1) / (Economy.MaxLevel - 1)) ^ Economy.LevelCurveExponent)
end

function Economy.level(skill: number, rebirths: number?): number
	-- Search integer thresholds so the server and HUD agree at every boundary.
	local low, high = 1, Economy.MaxLevel
	while low < high do
		local middle = math.floor((low + high + 1) / 2)
		if math.max(0, skill) >= Economy.threshold(middle, rebirths) then
			low = middle
		else
			high = middle - 1
		end
	end
	return low
end

function Economy.rebirthProgress(skill: number, rebirths: number?): (number, number, number)
	local level = Economy.level(skill, rebirths)
	return level, Economy.MaxLevel, (level - 1) / (Economy.MaxLevel - 1)
end

-- Pure part of the shot distance: the scene only supplies the route limit.
function Economy.shotRatio(skill: number, power: number?, requiredPower: number): number
	-- A goal of zero has no ratio. Without the guard the division would be an
	-- infinity that the clamp would turn into a full shot without a word.
	assert(requiredPower > 0, "The required shot power must be positive")
	return math.clamp(Economy.effectiveShotPower(skill, power) / requiredPower, 0, 1)
end

function Economy.shotDistance(ratio: number, limit: number): number
	local factor = math.clamp(ratio, 0, 1)
	-- The floor is the shortest throw of the game: a route that is shorter
	-- than the floor does not shorten the throw below it.
	local top = math.max(Economy.ShotDistanceFloor, limit)
	return math.floor(
		Economy.ShotDistanceFloor + (top - Economy.ShotDistanceFloor) * factor ^ Economy.ShotDistanceExponent
	)
end

function Economy.shotBounceGain(multiplier: number): number
	return math.floor(Economy.ShotBounceBaseSkill * multiplier)
end

function Economy.format(value: number): string
	for _, item in FORMAT_STEPS do
		if value >= item.amount then
			return string.format("%.2f", value / item.amount):gsub("0+$", ""):gsub("%.$", "") .. item.suffix
		end
	end
	return tostring(math.floor(value))
end

-- Egg ids map to a pool name; unknown eggs fall back to the common pool.
function Economy.eggPoolKey(eggId: string?): string
	if eggId == "Uncommon" or eggId == "Rare" or eggId == "Rainbow" then
		return eggId
	end
	return "Common"
end

-- Drops the colour and the visual so the roll can be tested without the engine.
function Economy.petDescriptor(pet: PetSource): PetDescriptor
	return {
		id = pet.id,
		name = pet.name,
		rarity = pet.rarity,
		boost = pet.boost,
		weight = pet.weight,
		eggBoost = pet.eggBoost,
	}
end

function Economy.petDescriptors(pets: { PetSource }): { PetDescriptor }
	local descriptors: { PetDescriptor } = {}
	for _, pet in pets do
		table.insert(descriptors, Economy.petDescriptor(pet))
	end
	return descriptors
end

-- Finds a pet by its id. The id is the identity of a pet, the position in a
-- pool is not: a pool that is reordered must still hand out the same pet.
function Economy.petById(pool: { any }, id: string): any
	for _, pet in pool do
		if pet.id == id then
			return pet
		end
	end
	return nil
end

function Economy.eggPets(pools: { [string]: { PetDescriptor } }, eggId: string?): { PetDescriptor }
	local key = Economy.eggPoolKey(eggId)
	local pool = pools[key]
	-- A missing pool is a broken configuration and says so, instead of
	-- failing later with "attempt to index nil".
	assert(pool, "The egg pool " .. key .. " is missing")
	return pool
end

function Economy.totalWeight(pool: { PetDescriptor }): number
	local total = 0
	for _, pet in pool do
		total += pet.weight
	end
	return total
end

-- Weighted roll over the cumulative pool weights. The roll is one based.
function Economy.rollPet(pool: { PetDescriptor }, roll: number?): PetDescriptor
	local total = Economy.totalWeight(pool)
	-- An empty pool has no weight to roll, so it fails with a clear message
	-- instead of the "interval is empty" of math.random.
	assert(total > 0, "The egg pool is empty")
	local value = roll or math.random(1, total)
	assert(value >= 1 and value <= total, "Egg roll out of range")
	local cumulative = 0
	for _, pet in pool do
		cumulative += pet.weight
		if value <= cumulative then
			return pet
		end
	end
	error("Empty egg pool")
end

return Economy
