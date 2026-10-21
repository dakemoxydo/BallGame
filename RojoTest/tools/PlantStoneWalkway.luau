-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local map = workspace.ProgressionMap
local walk = assert(map:FindFirstChild("StoneGrassWalkway"), "Apply stone path first")
assert(not walk:FindFirstChild("PlantedBorders"), "Already planted")
local backup = walk:Clone()
backup.Name = "BeforeWalkwayPlanting"
assert(not game.ServerStorage.WorldBackups:FindFirstChild(backup.Name), "Backup exists")
backup.Parent = game.ServerStorage.WorldBackups
local plants = Instance.new("Model")
plants.Name = "PlantedBorders"
local baseY = 20.57
local green = Color3.fromRGB(39, 183, 44)
local source
for _, p in ipairs(map.SpawnGardenPolish.SideTerraces2Planting:GetChildren()) do
	if p:IsA("BasePart") and p.Name == "LayeredShrub" then
		source = p
		break
	end
end
assert(source, "Missing existing shrub sample")
local function block(name, size, pos, color, studs)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.Material = Enum.Material.Plastic
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if studs then
		local t = Instance.new("Texture")
		t.Face = Enum.NormalId.Top
		t.Texture = "rbxassetid://88156646156237"
		t.StudsPerTileU = 8
		t.StudsPerTileV = 8
		t.Parent = p
	end
	p.Parent = plants
	return p
end
local sites = { 172, 202, 231, 258, 281, 311 }
local removed = 0
for _, p in ipairs(walk:GetChildren()) do
	if p:IsA("BasePart") and p.Name == "StoneSlab" then
		local inBed = false
		for _, z in ipairs(sites) do
			if p.Position.X > 139 and math.abs(p.Position.Z - z) < 7 then
				inBed = true
			end
		end
		if inBed then
			p:Destroy()
			removed += 1
		else
			local n = math.floor(p.Position.Z)
			p.CFrame *= CFrame.new(0, 0, (n % 3 - 1) * 0.6) * CFrame.Angles(0, math.rad(n % 2 == 0 and 5 or -4), 0)
		end
	end
end
for i, z in ipairs(sites) do
	local x = 144.7
	block("GrassEdge", Vector3.new(4.8, 0.07, 9 + i % 3), Vector3.new(x, baseY, z), Color3.fromRGB(101, 214, 45), true)
	for j = 1, 3 do
		local p = source:Clone()
		p.Name = "PathShrub"
		p.Size = Vector3.new(2.4 + (j % 2) * 0.7, 1.4 + (j % 3) * 0.45, 2.2)
		p.CFrame = CFrame.new(x + (j == 2 and 0.7 or -0.4), baseY + p.Size.Y / 2, z + (j - 2) * 2.4)
		p.Color = j == 2 and Color3.fromRGB(87, 209, 36) or green
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Parent = plants
	end
	block(
		"GardenStone",
		Vector3.new(2.1, 2.7, 2.3),
		Vector3.new(x - 0.8, baseY + 1.35, z + 3.5),
		Color3.fromRGB(141, 162, 176),
		true
	)
	block(
		"SmallGardenStone",
		Vector3.new(1.4, 1.0, 1.5),
		Vector3.new(x - 1.8, baseY + 0.5, z + 2.9),
		Color3.fromRGB(155, 175, 184),
		true
	)
	for j = 1, 5 do
		local fx, fz = x - 1.7 + (j % 2) * 0.65, z - 4.1 + j * 1.3
		block("FlowerStem", Vector3.new(0.12, 0.8, 0.12), Vector3.new(fx, baseY + 0.4, fz), green, false)
		local color = j % 3 == 0 and Color3.fromRGB(255, 161, 207) or Color3.fromRGB(255, 253, 227)
		block("FlowerPetals", Vector3.new(1.15, 0.2, 0.45), Vector3.new(fx, baseY + 0.85, fz), color, false)
		block("FlowerPetals", Vector3.new(0.45, 0.2, 1.15), Vector3.new(fx, baseY + 0.86, fz), color, false)
		block(
			"FlowerCenter",
			Vector3.new(0.3, 0.2, 0.3),
			Vector3.new(fx, baseY + 1.0, fz),
			Color3.fromRGB(255, 214, 51),
			false
		)
	end
end
plants.WorldPivot = CFrame.new(144.7, baseY, 241)
plants.Parent = walk
walk:SetAttribute("PlantingVersion", 1)
game:GetService("Selection"):Set({ walk })
return "Added six planted groups, 18 shrubs and 30 flowers; replaced " .. removed .. " outer slabs. Backup retained."
