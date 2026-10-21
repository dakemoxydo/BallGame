-- No currency/inventory changes. Run after native pet mesh preparation.
local shared = game.ReplicatedStorage.Shared
local source = shared.GameConfig:Clone()
source.Parent = shared
local Config = require(source)
source:Destroy()
local expected = { Shark = 45, CloudBird = 30, AngelCat = 20, IceCat = 5 }
local boosts = { Shark = 6, CloudBird = 7.5, AngelCat = 12.5, IceCat = 40 }
local egg = Config.find(Config.Eggs, "Rare")
assert(egg.cost == 5000 and egg.boost == 5 and #Config.eggPets("Rare") == 4)
local counts = {}
for roll = 1, 100 do
	local pet = Config.rollEggPet("Rare", roll)
	assert(expected[pet.id] and pet.visual == pet.id and Config.pet(pet.id) == pet, "Wrong blue-egg pet")
	assert(pet.boost * egg.boost == boosts[pet.id])
	counts[pet.id] = (counts[pet.id] or 0) + 1
end
for id, chance in expected do
	assert(counts[id] == chance, "Incorrect chance")
end
for _, id in
	{
		"Dog",
		"Cat",
		"Bunny",
		"Fox",
		"Dragon",
		"AdminDragon",
		"Cactus",
		"Frog",
		"Watermelon",
		"GreenDragon",
		"Butterfly",
		"MoonCat",
		"GalaxyCat",
		"CrystalCat",
	}
do
	assert(Config.pet(id), "Existing pet definition lost")
end
local pools = {
	Uncommon = { Cactus = 45, Frog = 30, Watermelon = 20, GreenDragon = 5 },
	Rainbow = { Butterfly = 45, MoonCat = 30, GalaxyCat = 20, CrystalCat = 5 },
	Common = { Dog = 40, Cat = 30, Bunny = 20, Fox = 9, Dragon = 1 },
}
for id, weights in pools do
	local outcomes = {}
	for roll = 1, 100 do
		local pet = Config.rollEggPet(id, roll)
		assert(weights[pet.id])
		outcomes[pet.id] = (outcomes[pet.id] or 0) + 1
	end
	for petId, chance in weights do
		assert(outcomes[petId] == chance, "Other egg changed")
	end
end
local module = shared.PetVisuals:Clone()
module.Parent = shared
local Visuals = require(module)
local meshes = {}
for id in expected do
	local model = assert(Visuals.create(id, 2.8), "Missing blue-egg preview")
	local cf, size = model:GetBoundingBox()
	assert(cf.Position.Magnitude < 0.001 and math.abs(math.max(size.X, size.Y, size.Z) - 2.8) < 0.001)
	local p = model:FindFirstChildWhichIsA("MeshPart", true)
	assert(p and p.MeshId ~= "" and p.MeshSize.Magnitude > 0 and not meshes[p.MeshId], "Unloaded/duplicate mesh")
	meshes[p.MeshId] = true
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
		end
	end
	model:Destroy()
	local follower = assert(Visuals.follower(id), "Missing follower")
	follower:Destroy()
end
module:Destroy()
return {
	pets = 4,
	price = 5000,
	chances = counts,
	boosts = boosts,
	otherEggs = "preserved",
	models = "four distinct hydrated meshes",
	savedPets = "preserved",
}
