-- No currency, inventory or DataStore changes. Run after PetVisuals.prepare.
local shared = game.ReplicatedStorage.Shared
local module = shared.GameConfig:Clone()
module.Parent = shared
local Config = require(module)
module:Destroy()
local expected = { Butterfly = 45, MoonCat = 30, GalaxyCat = 20, CrystalCat = 5 }
local boosts = { Butterfly = 18, MoonCat = 22.5, GalaxyCat = 37.5, CrystalCat = 120 }
local egg = Config.find(Config.Eggs, "Rainbow")
assert(egg.cost == 40000 and egg.boost == 15)
assert(#Config.eggPets("Rainbow") == 4)
local counts = {}
for roll = 1, 100 do
	local pet = Config.rollEggPet("Rainbow", roll)
	assert(expected[pet.id], "Unexpected Rainbow pet")
	assert(pet.visual == pet.id and Config.pet(pet.id) == pet)
	assert(pet.boost * egg.boost == boosts[pet.id])
	counts[pet.id] = (counts[pet.id] or 0) + 1
end
for id, chance in expected do
	assert(counts[id] == chance, "Wrong hatch chance")
end
for _, id in { "Dog", "Cat", "Bunny", "Fox", "Dragon", "AdminDragon", "Cactus", "Frog", "Watermelon", "GreenDragon" } do
	assert(Config.pet(id), "Saved pet definition lost")
end
for _, eggId in { "Common" } do
	assert(#Config.eggPets(eggId) == 5)
	for roll = 1, 100 do
		assert(table.find({ "Dog", "Cat", "Bunny", "Fox", "Dragon" }, Config.rollEggPet(eggId, roll).id))
	end
end
local green = { Cactus = 45, Frog = 30, Watermelon = 20, GreenDragon = 5 }
local greenCounts = {}
for roll = 1, 100 do
	local pet = Config.rollEggPet("Uncommon", roll)
	assert(green[pet.id])
	greenCounts[pet.id] = (greenCounts[pet.id] or 0) + 1
end
for id, chance in green do
	assert(greenCounts[id] == chance)
end
local source = shared.PetVisuals:Clone()
source.Parent = shared
local Visuals = require(source)
local meshes = {}
for id in expected do
	local m = assert(Visuals.create(id, 2.8), "Missing preview template")
	local cf, size = m:GetBoundingBox()
	assert(cf.Position.Magnitude < 0.001 and math.abs(math.max(size.X, size.Y, size.Z) - 2.8) < 0.001)
	local p = m:FindFirstChildWhichIsA("MeshPart", true)
	assert(p and p.MeshId ~= "" and p.MeshSize.Magnitude > 0, "Mesh not hydrated")
	assert(not meshes[p.MeshId], "Duplicate mesh")
	meshes[p.MeshId] = true
	for _, part in m:GetDescendants() do
		if part:IsA("BasePart") then
			assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
		end
	end
	m:Destroy()
	local follower = assert(Visuals.follower(id), "Missing follower")
	follower:Destroy()
end
source:Destroy()
return {
	pets = 4,
	chances = counts,
	boosts = boosts,
	price = egg.cost,
	otherEggs = "preserved",
	savedPetIds = "preserved",
	meshes = "four distinct hydrated assets",
}
