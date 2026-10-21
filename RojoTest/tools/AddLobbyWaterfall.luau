-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Additive, edit-time scenery. Run through Studio MCP; never rebuild the map.
local map = workspace:FindFirstChild("ProgressionMap")
assert(map and map:FindFirstChild("SpawnGarden"), "Expected authored lobby")
assert(not map:FindFirstChild("LobbyWaterfallGarden"), "Waterfall already exists")
local apron = map.Lobby.ThrowingApron
local origin = apron.Position
assert(math.abs(origin.X - 24.240257) < 0.1 and math.abs(origin.Y - 20.3) < 0.1, "Map moved; remeasure site")
local before = {}
for _, p in ipairs(map:GetDescendants()) do
	if p:IsA("BasePart") then
		before[p] = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
	end
end
local model = Instance.new("Model")
model.Name = "LobbyWaterfallGarden"
local base = Vector3.new(147.240264, 20.4, 152.847107)
local stone = Color3.fromRGB(136, 158, 169)
local green = Color3.fromRGB(65, 201, 36)
local water = Color3.fromRGB(22, 220, 234)
local function part(name, size, offset, color, studs)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(base + offset)
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
local function rock(x, z, w, h, d, bottom)
	local y = bottom or 0
	part("BankRock", Vector3.new(w, h, d), Vector3.new(x, y + h / 2, z), stone, true)
	part("MossCap", Vector3.new(w + 0.06, 0.32, d + 0.06), Vector3.new(x, y + h + 0.16, z), green, true)
end
-- The inner edge stays at X=140.6, leaving 9.36 studs of the original path.
part("PondBed", Vector3.new(6.2, 0.28, 22), Vector3.new(-3.1, 0.15, 0), Color3.fromRGB(41, 133, 157), false)
local pool = part("PondWater", Vector3.new(5.9, 0.12, 21.6), Vector3.new(-3.1, 0.37, 0), water, false)
pool.Transparency = 0.16
for _, z in ipairs({ -10.8, -7, 7, 10.8 }) do
	rock(-4.9, z, 3, z == -10.8 and 3.8 or 2.1, 3.1)
end
rock(-1.5, -11, 3.1, 5.8, 3.6)
rock(-1.5, 11, 3.1, 4.1, 3.8)
-- Water follows the two existing terrace faces, joined across the lower shelf.
local lower = part("LowerCascade", Vector3.new(0.72, 21.45, 7.3), Vector3.new(-0.5, 11.1, 0), water, false)
lower.Transparency = 0.14
local upper = part("UpperCascade", Vector3.new(0.7, 21.5, 6), Vector3.new(8.45, 32.2, 0), water, false)
upper.Transparency = 0.14
part("ShelfStream", Vector3.new(9.3, 0.2, 7.3), Vector3.new(4.0, 21.8, 0), water, false)
part("SpringPool", Vector3.new(3.4, 0.18, 6), Vector3.new(10, 43.0, 0), water, false)
for _, z in ipairs({ -4.7, 4.7 }) do
	rock(0.8, z, 3.1, z < 0 and 17 or 13, 3.3)
	rock(1.5, z, 2.5, 7.5, 3.8, 15)
	rock(10, z, 3.1, z < 0 and 13 or 10, 3.2, 21.6)
	rock(10.4, z, 2.5, 6.4, 3.6, 37)
end
for i, z in ipairs({ -2.6, -0.9, 1.1, 2.7 }) do
	local c = Color3.fromRGB(142, 250, 252)
	local p = part("LowerFlowStripe", Vector3.new(0.06, 18.5 - i, 0.13), Vector3.new(-0.9, 11.3, z), c, false)
	p.Transparency = 0.43
	p = part("UpperFlowStripe", Vector3.new(0.06, 18.7 - i, 0.13), Vector3.new(8.06, 32.4, z * 0.8), c, false)
	p.Transparency = 0.43
end
for _, z in ipairs({ -2.5, 0, 2.5 }) do
	part("SplashStep", Vector3.new(1.7, 0.42, 1.7), Vector3.new(-1.3, 0.6, z), Color3.fromRGB(180, 255, 251), false)
end
for _, site in ipairs({ { -4.5, -8.8 }, { -3, 9 }, { -1.5, 7.6 } }) do
	for i = 1, 3 do
		local h = 1.5 + i * 0.55
		part(
			"Reed",
			Vector3.new(0.28, h, 0.28),
			Vector3.new(site[1] + i * 0.38, h / 2 + 0.4, site[2] + (i % 2) * 0.6),
			Color3.fromRGB(139, 216, 55),
			false
		)
	end
end
for _, site in ipairs({ { 0.9, -7, 20.8 }, { 9.1, 6, 42.6 } }) do
	for i = 1, 6 do
		part(
			"TrailingVine",
			Vector3.new(0.35, 1.7, 1.1),
			Vector3.new(site[1] - 1.8, site[3] - i * 1.5, site[2] + math.sin(i) * 0.5),
			i % 2 == 0 and green or Color3.fromRGB(112, 220, 48),
			true
		)
	end
end
for _, site in ipairs({ { -4.8, -13 }, { -3.4, 13.4 }, { 1.8, -6.4, 21.6 }, { 10.9, 6, 42.6 } }) do
	local y = site[3] or 0
	for i = 1, 3 do
		local x, z = site[1] + i * 0.6, site[2] + (i % 2) * 0.6
		part("FlowerStem", Vector3.new(0.12, 0.85, 0.12), Vector3.new(x, y + 0.43, z), green, false)
		local petals = i == 2 and Color3.fromRGB(255, 171, 215) or Color3.fromRGB(255, 251, 228)
		part("FlowerPetals", Vector3.new(0.85, 0.17, 0.85), Vector3.new(x, y + 0.93, z), petals, false)
		part(
			"FlowerCenter",
			Vector3.new(0.28, 0.18, 0.28),
			Vector3.new(x, y + 1.1, z),
			Color3.fromRGB(255, 221, 67),
			false
		)
	end
end
model.WorldPivot = CFrame.new(base)
-- Clear authored planting without changing existing objects.
model:PivotTo(model:GetPivot() + Vector3.new(0, 0, -5.5))
model.ShelfStream.Size = Vector3.new(9.3, 0.2, 2.6)
model.UpperCascade.Size = Vector3.new(0.7, 21.5, 3.2)
model.SpringPool.Size = Vector3.new(3.4, 0.18, 3.2)
for _, p in ipairs(model:GetChildren()) do
	if p.Name == "UpperFlowStripe" then
		local c = model:GetPivot():PointToObjectSpace(p.Position)
		p.Position = model:GetPivot():PointToWorldSpace(Vector3.new(c.X, c.Y, c.Z * 0.5))
	end
end
model:SetAttribute("Version", 1)
model:SetAttribute("ClearWalkwayWidth", 9.36)
model.Parent = map
local changed = 0
for p, old in pairs(before) do
	if
		p.CFrame ~= old[1]
		or p.Size ~= old[2]
		or p.CanCollide ~= old[3]
		or p.CanTouch ~= old[4]
		or p.CanQuery ~= old[5]
	then
		changed += 1
	end
end
assert(changed == 0, "Existing geometry changed")
model:SetAttribute(
	"OriginalPartsVerified",
	(function()
		local n = 0
		for _ in pairs(before) do
			n += 1
		end
		return n
	end)()
)
game:GetService("Selection"):Set({ model })
return "Added " .. #model:GetChildren() .. " decorative parts; existing transforms and collision flags unchanged."
