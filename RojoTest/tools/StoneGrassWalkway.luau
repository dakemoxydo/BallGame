-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Edit-time visual replacement of the right lobby strip; keep physical floor.
local map = assert(workspace:FindFirstChild("ProgressionMap"), "Missing map")
assert(not map:FindFirstChild("StoneGrassWalkway"), "Already applied")
local floor = map.Lobby.CentralWalkway
assert((floor.Size - Vector3.new(16, 0.4, 202)).Magnitude < 0.01, "Remeasure walkway")
local snapshot = {}
for _, p in ipairs(map:GetDescendants()) do
	if p:IsA("BasePart") then
		snapshot[p] = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
	end
end
local backups = game.ServerStorage:FindFirstChild("WorldBackups")
if not backups then
	backups = Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = game.ServerStorage
end
assert(not backups:FindFirstChild("BeforeStoneGrassWalkway"), "Backup exists")
local backup = Instance.new("Folder")
backup.Name = "BeforeStoneGrassWalkway"
floor:Clone().Parent = backup
backup.Parent = backups
local model = Instance.new("Model")
model.Name = "StoneGrassWalkway"
local sample
for _, p in ipairs(map.Lobby:GetChildren()) do
	if p.Name == "GroundTile" and p:IsA("BasePart") then
		sample = p
		break
	end
end
assert(sample, "Missing grass sample")
local function make(name, size, cf, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local t = Instance.new("Texture")
	t.Texture = "rbxassetid://88156646156237"
	t.Face = Enum.NormalId.Top
	t.StudsPerTileU = 8
	t.StudsPerTileV = 8
	t.Parent = p
	p.Parent = model
	return p
end
-- Thin cap also covers the crossing's visual overlap without changing its floor.
make("GrassCover", Vector3.new(16, 0.08, 202), floor.CFrame + Vector3.new(0, 0.32, 0), sample.Color)
local x = floor.Position.X
local start = floor.Position.Z - 91
local colors = { Color3.fromRGB(139, 162, 174), Color3.fromRGB(153, 174, 181), Color3.fromRGB(128, 153, 166) }
local slabs = 0
for i = 0, 21 do
	local z = start + i * 8.3
	for lane = 1, 2 do
		local px = x + (lane == 1 and -3.8 or 3.0)
		local pz = z + (lane == 2 and 2.0 or 0)
		local nearWater = lane == 2 and pz > 130 and pz < 164
		local nearSpawn = pz > map.Lobby.MapSpawn.Position.Z - 9 and pz < map.Lobby.MapSpawn.Position.Z + 9
		if not nearWater and not nearSpawn and not (i % 5 == 3 and lane == 2) then
			local width = lane == 1 and (i % 3 == 0 and 6.2 or 4.6) or (i % 3 == 1 and 5.1 or 3.7)
			local depth = i % 4 == 0 and 6.1 or (i % 4 == 1 and 4.0 or 5.2)
			make(
				"StoneSlab",
				Vector3.new(width, 0.1, depth),
				CFrame.new(px, floor.Position.Y + 0.4, pz),
				colors[(i + lane) % 3 + 1]
			)
			slabs += 1
		end
	end
end
model.WorldPivot = floor.CFrame
model:SetAttribute("Version", 1)
model:SetAttribute("StoneSlabs", slabs)
floor.Transparency = 1
for _, t in ipairs(floor:GetChildren()) do
	if t:IsA("Texture") or t:IsA("Decal") then
		t.Transparency = 1
	end
end
model.Parent = map
local verified = 0
for p, old in pairs(snapshot) do
	assert(
		p.CFrame == old[1]
			and p.Size == old[2]
			and p.CanCollide == old[3]
			and p.CanTouch == old[4]
			and p.CanQuery == old[5],
		"Existing volume changed: " .. p:GetFullName()
	)
	verified += 1
end
model:SetAttribute("OriginalPartsVerified", verified)
game:GetService("Selection"):Set({ model })
return string.format("Created %d stone slabs; preserved %d original physical volumes", slabs, verified)
