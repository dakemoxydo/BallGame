--!strict
local C = Color3.fromRGB
-- The pure economy lives in Core/Economy so it can be tested without the engine.
local Economy = require("./Core/Economy")
local Config = {}
Config.DataVersion = 1
Config.MaxLevel = Economy.MaxLevel
Config.CharacterWalkSpeed = 24
Config.TrainingCycle = 1.2
Config.KickContact = 0.42
-- The training contact and the shot windup are the same moment of the kick.
Config.KickWindup = Config.KickContact
Config.DistancePerStud = 750 / 180
Config.WorldShotProgression = {
	[1] = { requiredPower = 1000000, routeStuds = 2160 },
	[2] = { requiredPower = 100000000, routeStuds = 1440 },
}
Config.RebirthBaseSkill = Economy.RebirthBaseSkill
Config.RebirthSkillGrowth = Economy.RebirthSkillGrowth
function Config.effectiveShotPower(skill, power)
	return Economy.effectiveShotPower(skill, power)
end
function Config.rebirthRequirement(rebirths)
	return Economy.rebirthRequirement(rebirths)
end
function Config.rebirthProgress(skill, rebirths)
	return Economy.rebirthProgress(skill, rebirths)
end
-- The apron is a live scene anchor; map movement must also move gameplay coordinates.
function Config.arenaFrame(arena)
	return arena.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
end
function Config.apronCharacterPose(arena, root, humanoid, localZ)
	local apron = arena.Lobby.ThrowingApron
	local height = root.Size.Y / 2 + (humanoid.RigType == Enum.HumanoidRigType.R6 and 2 or humanoid.HipHeight)
	return apron.CFrame * CFrame.new(-1, apron.Size.Y / 2 + height + 0.15, localZ)
end
function Config.trainingSurface(lane)
	local strip = lane.TrainingStrip
	return strip.Position.Y + strip.Size.Y / 2 + (lane:FindFirstChild("ImportedField") and 0.08 or 0)
end
function Config.shotLimit(world, arena)
	local definition = Config.WorldShotProgression[world == 2 and 2 or 1]
	arena = arena or workspace:FindFirstChild(world == 2 and "World2Map" or "ProgressionMap")
	local scenery = arena and arena:FindFirstChild("SkippingWorld")
	local water = scenery and scenery:FindFirstChild("Water_8")
	if water then
		local frame = Config.arenaFrame(arena)
		local start = frame:PointToWorldSpace(Vector3.new(-115.35, 1.8, -0.3))
		local finale = scenery:FindFirstChild("SakuraJapaneseFinale")
		local gate = finale and finale:FindFirstChild("SakuraGatewayFrame")
		local goal = gate and gate:GetPivot().Position or water.Position + frame.LookVector * (water.Size.Z / 2 - 7)
		return math.max(
			Economy.ShotDistanceFloor,
			math.floor((goal - start):Dot(frame.LookVector) * Config.DistancePerStud)
		)
	end
	-- Seven studs of endpoint setback and the existing launch offset of 0.3 studs.
	return math.floor((definition.routeStuds - 7 - 0.3) * Config.DistancePerStud)
end
function Config.shotDistance(skill, power, world, arena)
	local definition = Config.WorldShotProgression[world == 2 and 2 or 1]
	-- Rebirths and pets already increase earned Skill; do not multiply them again.
	local ratio = Economy.shotRatio(skill, power, definition.requiredPower)
	local limit = Config.shotLimit(world, arena)
	return Economy.shotDistance(ratio, limit)
end
function Config.shotDuration(distance, world, intensity)
	local duration = math.clamp(3.2 + distance / 850, 3.2, world == 2 and 10 or 14)
	return duration / (1 + 0.8 * math.clamp(intensity or 0, 0, 1))
end
function Config.shotBounceGain(multiplier)
	return Economy.shotBounceGain(multiplier)
end
Config.StudTexture = "rbxassetid://88156646156237"
Config.Music = "rbxassetid://1836105470"
Config.WaterTexture = "rbxassetid://6757160733"
Config.RiverX = -116
Config.WorldOffset = Vector3.new(2000, 0, 0)
Config.Biomes = {
	{ name = "Palm Beach", distance = 0, color = C(29, 207, 227), bank = C(126, 229, 72), kind = "palm" },
	{ name = "Desert Dunes", distance = 750, color = C(245, 188, 64), bank = C(244, 209, 103), kind = "desert" },
	{ name = "Candy Beach", distance = 1500, color = C(127, 231, 118), bank = C(151, 231, 105), kind = "candy" },
	{ name = "Violet Valley", distance = 2250, color = C(181, 132, 237), bank = C(186, 156, 245), kind = "crystal" },
	{ name = "Ember River", distance = 3000, color = C(255, 137, 48), bank = C(245, 157, 86), kind = "lava" },
	{ name = "Moonlight", distance = 3750, color = C(106, 155, 250), bank = C(165, 187, 248), kind = "moon" },
	{ name = "Frozen Falls", distance = 4500, color = C(129, 225, 255), bank = C(215, 246, 255), kind = "ice" },
	{ name = "Rainbow Paradise", distance = 5250, color = C(238, 124, 230), bank = C(166, 242, 121), kind = "rainbow" },
}
Config.Lanes = {
	{ gain = 1, rebirths = 0, color = C(90, 222, 153) },
	{ gain = 4, rebirths = 2, color = C(40, 220, 210) },
	{ gain = 10, rebirths = 4, color = C(175, 108, 245) },
	{ gain = 25, rebirths = 6, color = C(66, 175, 255) },
	{ gain = 60, rebirths = 9, color = C(245, 167, 76) },
	{ gain = 150, rebirths = 12, color = C(255, 220, 44) },
	{ gain = 400, rebirths = 16, color = C(109, 244, 96) },
}
Config.Trails = {
	{ id = "None", name = "No Trail", boost = 1, cost = 0, color = C(180, 185, 193) },
	{ id = "White", name = "White Trail", boost = 1.2, cost = 10000, color = C(244, 247, 255) },
	{ id = "Red", name = "Red Trail", boost = 1.3, cost = 750000, color = C(255, 48, 84) },
	{ id = "Blue", name = "Blue Trail", boost = 1.5, cost = 5000000, color = C(30, 191, 255) },
	{ id = "Purple", name = "Purple Trail", boost = 1.8, cost = 25000000, color = C(181, 75, 255) },
	{ id = "Rainbow", name = "Rainbow Trail", boost = 2.5, cost = 100000000, color = C(255, 184, 62) },
}
Config.Stones = {
	{ id = "Pebble", name = "Rubber Rookie", power = 1, cost = 0, color = C(233, 91, 31), displaySlot = 5 },
	{ id = "Smooth", name = "Steel Impact", power = 1.15, cost = 250, color = C(223, 232, 243), displaySlot = 4 },
	{ id = "Golden", name = "Crystal Ice", power = 1.35, cost = 2500, color = C(78, 209, 255), displaySlot = 3 },
	{ id = "Ruby", name = "Volcano Heart", power = 1.6, cost = 15000, color = C(255, 115, 41), displaySlot = 2 },
	{
		id = "Emerald",
		name = "Mechanical Reactor",
		power = 1.9,
		cost = 75000,
		color = C(44, 209, 236),
		displaySlot = 1,
	},
	{ id = "Galaxy", name = "Plasma Satellite", power = 2.5, cost = 350000, color = C(174, 91, 255), displaySlot = 10 },
	{ id = "Rainbow", name = "Thunder Split", power = 3.5, cost = 2000000, color = C(255, 218, 63), displaySlot = 9 },
	{ id = "DragonSun", name = "Dragon Sun", power = 5, cost = 8000000, color = C(255, 169, 46), displaySlot = 8 },
	{ id = "BlackHole", name = "Black Hole", power = 7.5, cost = 25000000, color = C(171, 104, 255), displaySlot = 7 },
	{
		id = "WorldCreator",
		name = "World Creator",
		power = 10,
		cost = 75000000,
		color = C(79, 195, 255),
		displaySlot = 6,
	},
}
Config.Pets = {
	{ id = "Dog", name = "Dog", boost = 1.2, color = C(193, 126, 69), rarity = "Common", weight = 40 },
	{ id = "Cat", name = "Cat", boost = 1.5, color = C(240, 190, 120), rarity = "Common", weight = 30 },
	{ id = "Bunny", name = "Clover Bun", boost = 2.5, color = C(180, 236, 146), rarity = "Uncommon", weight = 20 },
	{ id = "Fox", name = "Golden Fox", boost = 4, color = C(255, 177, 50), rarity = "Rare", weight = 9 },
	{ id = "Dragon", name = "Crystal Dragon", boost = 8, color = C(171, 99, 249), rarity = "Legendary", weight = 1 },
}
-- Dedicated green-egg pool. Legacy pet IDs remain valid for saved inventories.
Config.UncommonPets = {
	{
		id = "Cactus",
		name = "Cactus",
		boost = 1.2,
		color = C(180, 236, 146),
		rarity = "Common",
		weight = 45,
		visual = "Cactus",
	},
	{
		id = "Frog",
		name = "Frog",
		boost = 1.5,
		color = C(133, 221, 99),
		rarity = "Uncommon",
		weight = 30,
		visual = "Frog",
	},
	{
		id = "Watermelon",
		name = "Watermelon",
		boost = 2.5,
		color = C(255, 177, 50),
		rarity = "Rare",
		weight = 20,
		visual = "Watermelon",
	},
	{
		id = "GreenDragon",
		name = "Green Dragon",
		boost = 8,
		color = C(171, 99, 249),
		rarity = "Legendary",
		weight = 5,
		visual = "GreenDragon",
	},
}
Config.RarePets = {
	{
		id = "Shark",
		name = "Shark",
		boost = 1.2,
		color = C(58, 174, 237),
		rarity = "Common",
		weight = 45,
		visual = "Shark",
		eggBoost = 5,
	},
	{
		id = "CloudBird",
		name = "Cloud Bird",
		boost = 1.5,
		color = C(81, 205, 241),
		rarity = "Uncommon",
		weight = 30,
		visual = "CloudBird",
		eggBoost = 5,
	},
	{
		id = "AngelCat",
		name = "Angel Cat",
		boost = 2.5,
		color = C(184, 217, 246),
		rarity = "Rare",
		weight = 20,
		visual = "AngelCat",
		eggBoost = 5,
	},
	{
		id = "IceCat",
		name = "Ice Cat",
		boost = 8,
		color = C(62, 193, 241),
		rarity = "Legendary",
		weight = 5,
		visual = "IceCat",
		eggBoost = 5,
	},
}
Config.RainbowPets = {
	{
		id = "Butterfly",
		name = "Butterfly",
		boost = 1.2,
		color = C(193, 83, 245),
		rarity = "Common",
		weight = 45,
		visual = "Butterfly",
		eggBoost = 15,
	},
	{
		id = "MoonCat",
		name = "Moon Cat",
		boost = 1.5,
		color = C(126, 83, 219),
		rarity = "Uncommon",
		weight = 30,
		visual = "MoonCat",
		eggBoost = 15,
	},
	{
		id = "GalaxyCat",
		name = "Galaxy Cat",
		boost = 2.5,
		color = C(185, 74, 244),
		rarity = "Rare",
		weight = 20,
		visual = "GalaxyCat",
		eggBoost = 15,
	},
	{
		id = "CrystalCat",
		name = "Crystal Cat",
		boost = 8,
		color = C(159, 94, 228),
		rarity = "Legendary",
		weight = 5,
		visual = "CrystalCat",
		eggBoost = 15,
	},
}
-- Descriptor pools without colour or visuals: the egg roll stays engine free.
local PetPools: { [string]: { Economy.PetDescriptor } } = {
	Common = Economy.petDescriptors(Config.Pets),
	Uncommon = Economy.petDescriptors(Config.UncommonPets),
	Rare = Economy.petDescriptors(Config.RarePets),
	Rainbow = Economy.petDescriptors(Config.RainbowPets),
}
function Config.eggPets(eggId)
	if eggId == "Uncommon" then
		return Config.UncommonPets
	end
	if eggId == "Rare" then
		return Config.RarePets
	end
	if eggId == "Rainbow" then
		return Config.RainbowPets
	end
	return Config.Pets
end
function Config.rollEggPet(eggId, roll)
	local pool = Config.eggPets(eggId)
	local descriptors = Economy.eggPets(PetPools, eggId)
	local chosen = Economy.rollPet(descriptors, roll)
	-- The pet is looked up by its id, not by the position of the descriptor:
	-- a reordered pool must still hand out the pet that was rolled.
	local pet = Economy.petById(pool, chosen.id)
	assert(pet, "The egg pool does not know the pet " .. tostring(chosen.id))
	return pet
end
Config.AdminPet =
	{ id = "AdminDragon", name = "Glitched Dragon", boost = 25, color = C(111, 255, 20), rarity = "Mythic" }
Config.Eggs = {
	{ id = "Common", name = "Common Egg", cost = 50, boost = 1, color = C(255, 55, 55), x = -130, z = 123 },
	{ id = "Uncommon", name = "Uncommon Egg", cost = 500, boost = 2, color = C(75, 245, 98), x = -155, z = 123 },
	{ id = "Rare", name = "Rare Egg", cost = 5000, boost = 5, color = C(81, 195, 255), x = -130, z = 160 },
	{ id = "Rainbow", name = "Rainbow Egg", cost = 40000, boost = 15, color = C(255, 130, 231), x = -155, z = 160 },
}
Config.Gifts = {
	{ time = 60, wins = 100, skill = 50 },
	{ time = 180, wins = 500, skill = 150 },
	{ time = 300, wins = 1000, skill = 500 },
	{ time = 600, wins = 2500, skill = 1500 },
	{ time = 900, wins = 10000, skill = 5000 },
	{ time = 1800, wins = 50000, skill = 25000 },
}
-- Set actual IDs after creating products in this experience's Creator Dashboard.
Config.Products = {
	AutoThrow = { id = 0, price = 25 },
	DoubleSkill = { id = 0, price = 5 },
	DoubleWins = { id = 0, price = 59 },
	Skill10M = { id = 0, price = 25, skill = 10000000 },
	Skill100M = { id = 0, price = 95, skill = 100000000 },
	Skill1B = { id = 0, price = 185, skill = 1000000000 },
	StarterPack = { id = 0, price = 99 },
	SkipRebirth = { id = 0, price = 49 },
	AdminEgg = { id = 0, price = 175 },
}
function Config.find(list, id)
	for _, item in list do
		if item.id == id then
			return item
		end
	end
	return nil
end
function Config.pet(id)
	return id == Config.AdminPet.id and Config.AdminPet
		or Config.find(Config.RarePets, id)
		or Config.find(Config.RainbowPets, id)
		or Config.find(Config.UncommonPets, id)
		or Config.find(Config.Pets, id)
end
function Config.level(skill, rebirths)
	return Economy.level(skill, rebirths)
end
function Config.threshold(level, rebirths)
	return Economy.threshold(level, rebirths)
end
function Config.format(value)
	return Economy.format(value)
end
return Config
