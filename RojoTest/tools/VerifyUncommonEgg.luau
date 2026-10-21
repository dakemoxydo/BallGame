-- Deterministic checks; no currency, inventory, purchases or DataStore changes.
local shared = game.ReplicatedStorage.Shared
local module = shared.GameConfig:Clone()
module.Name = "UncommonEggConfigCheck"
module.Parent = shared
local Config = require(module)
module:Destroy()
local expected = { Cactus = 45, Frog = 30, Watermelon = 20, GreenDragon = 5 }
assert(#Config.eggPets("Uncommon") == 4)
local counts = {}
for roll = 1, 100 do
	local pet = Config.rollEggPet("Uncommon", roll)
	assert(expected[pet.id], "Unexpected pet in the green egg")
	counts[pet.id] = (counts[pet.id] or 0) + 1
end
for id, chance in expected do
	assert(counts[id] == chance)
end
assert(Config.find(Config.Eggs, "Uncommon").cost == 500)
for _, id in { "Dog", "Cat", "Bunny", "Fox", "Dragon", "AdminDragon", "Cactus", "Frog", "Watermelon", "GreenDragon" } do
	assert(Config.pet(id), "Saved pet definition missing: " .. id)
end
for _, egg in { "Common" } do
	assert(#Config.eggPets(egg) == 5)
	for roll = 1, 100 do
		assert(table.find({ "Dog", "Cat", "Bunny", "Fox", "Dragon" }, Config.rollEggPet(egg, roll).id))
	end
end
local visuals = shared.PetVisuals:Clone()
visuals.Name = "UncommonEggVisualCheck"
visuals.Parent = shared
local Visuals = require(visuals)
local meshIds = {}
for id in expected do
	local model = Visuals.create(id, 2.8)
	assert(model, "Pet template missing")
	local cf, size = model:GetBoundingBox()
	assert(cf.Position.Magnitude < 0.001)
	assert(math.abs(math.max(size.X, size.Y, size.Z) - 2.8) < 0.001)
	local body = model:FindFirstChildWhichIsA("MeshPart", true)
	assert(body and body.MeshId ~= "" and body.MeshSize.Magnitude > 0, "Pet mesh not hydrated")
	assert(not meshIds[body.MeshId], "Duplicate pet visual")
	meshIds[body.MeshId] = true
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery)
		end
	end
	model:Destroy()
end
visuals:Destroy()
return {
	pets = 4,
	chances = counts,
	price = 500,
	otherEggs = "Common unchanged; Rare/Rainbow checked separately",
	savedPetIds = "preserved",
	models = "four distinct hydrated meshes",
}
