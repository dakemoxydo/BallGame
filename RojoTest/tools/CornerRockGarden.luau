-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local map = assert(workspace:FindFirstChild("ProgressionMap"))
assert(not map:FindFirstChild("CornerRockGarden"), "Garden already exists")
local apron = map.Lobby.ThrowingApron
assert((apron.Position - Vector3.new(24.240257, 20.3, 115.847107)).Magnitude < 0.1, "Remeasure map")
local before = {}
for _, p in ipairs(map:GetDescendants()) do
	if p:IsA("BasePart") then
		before[p] = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
	end
end
local model = Instance.new("Model")
model.Name = "CornerRockGarden"
local origin = Vector3.new(-77.3, 20, 120)
local stone = Color3.fromRGB(136, 157, 171)
local moss = Color3.fromRGB(83, 207, 38)
local function block(name, size, off, color, studs)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(origin + off)
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if studs then
		local t = Instance.new("Texture")
		t.Texture = "rbxassetid://88156646156237"
		t.Face = Enum.NormalId.Top
		t.StudsPerTileU = 8
		t.StudsPerTileV = 8
		t.Parent = p
	end
	p.Parent = model
	return p
end
local rocks = {
	{ 0, -1, 4.5, 12.5, 4.8 },
	{ 0.7, -5.1, 4.0, 6.8, 3.8 },
	{ 0.4, 4.1, 4.3, 4.6, 4.0 },
	{ 2.9, 0.2, 2.7, 3.1, 3.0 },
	{ 1.3, -8.1, 3.6, 2.9, 2.9 },
	{ 2.6, 7.1, 2.9, 2.0, 3.0 },
	{ 4.4, -4.5, 1.9, 1.3, 2.0 },
	{ 4.3, 3.4, 2.0, 1.0, 1.6 },
}
for _, r in ipairs(rocks) do
	block("RockMass", Vector3.new(r[3], r[4], r[5]), Vector3.new(r[1], r[4] / 2, r[2]), stone, true)
	block("MossCap", Vector3.new(r[3] + 0.08, 0.4, r[5] + 0.08), Vector3.new(r[1], r[4] + 0.2, r[2]), moss, true)
end
local source
for _, p in ipairs(map.SpawnGardenPolish.SideTerraces2Planting:GetChildren()) do
	if p:IsA("BasePart") and p.Name == "LayeredShrub" then
		source = p
		break
	end
end
assert(source, "Missing current shrubs")
for i, site in ipairs({ { 2, -10 }, { 3.9, -8 }, { 3.4, 5.7 }, { 2.4, 9.2 }, { 4.3, 8.1 } }) do
	local p = source:Clone()
	p.Name = "GardenShrub"
	p.Size = Vector3.new(i % 2 == 0 and 2.4 or 3.1, i % 2 == 0 and 1.7 or 2.2, 2.7)
	p.CFrame = CFrame.new(origin + Vector3.new(site[1], p.Size.Y / 2, site[2]))
	p.Color = i % 2 == 0 and moss or Color3.fromRGB(32, 177, 42)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = model
end
for i = 1, 10 do
	local z = i <= 5 and (-11 + i * 0.9) or (4.9 + (i - 5) * 0.95)
	local x = i % 2 == 0 and 4.2 or 5.1
	block("FlowerStem", Vector3.new(0.12, 0.95, 0.12), Vector3.new(x, 0.48, z), moss, false)
	local c = i % 3 == 0 and Color3.fromRGB(255, 167, 207) or Color3.fromRGB(255, 253, 231)
	block("FlowerPetals", Vector3.new(1.15, 0.18, 0.45), Vector3.new(x, 1.01, z), c, false)
	block("FlowerPetals", Vector3.new(0.45, 0.18, 1.15), Vector3.new(x, 1.02, z), c, false)
	block("FlowerCenter", Vector3.new(0.3, 0.2, 0.3), Vector3.new(x, 1.18, z), Color3.fromRGB(255, 218, 50), false)
end
-- Short vines attached to the wall lip and the tallest moss cap.
for _, site in ipairs({ { -3.18, -5.9, 21.7, 5 }, { -3.18, 5.6, 21.7, 4 }, { 2.4, -1.8, 12.7, 3 } }) do
	for i = 1, site[4] do
		block(
			"TrailingVine",
			Vector3.new(0.32, 1.45, 0.9),
			Vector3.new(site[1], site[3] - i * 1.25, site[2] + math.sin(i) * 0.35),
			i % 2 == 0 and moss or Color3.fromRGB(48, 179, 36),
			true
		)
	end
end
block("SummitFlowerStem", Vector3.new(0.12, 1, 0.12), Vector3.new(0, 13.4, -1), moss, false)
block("SummitFlower", Vector3.new(0.95, 0.18, 0.95), Vector3.new(0, 13.95, -1), Color3.fromRGB(255, 253, 231), false)
block("SummitPollen", Vector3.new(0.3, 0.18, 0.3), Vector3.new(0, 14.1, -1), Color3.fromRGB(255, 218, 50), false)
model.WorldPivot = CFrame.new(origin)
model:SetAttribute("Version", 1)
model.Parent = map
local verified = 0
for p, o in pairs(before) do
	assert(
		p.CFrame == o[1] and p.Size == o[2] and p.CanCollide == o[3] and p.CanTouch == o[4] and p.CanQuery == o[5],
		"Existing object changed"
	)
	verified += 1
end
model:SetAttribute("OriginalPartsVerified", verified)
game:GetService("Selection"):Set({ model })
return "Added " .. #model:GetChildren() .. " decorative parts; preserved " .. verified .. " original volumes"
