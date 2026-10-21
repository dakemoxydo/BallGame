-- Run this read-only audit in Studio Edit mode after applying SkippingWorld.
local map = assert(workspace:FindFirstChild("ProgressionMap"), "Missing map")
local backup = game.ServerStorage:FindFirstChild("WorldBackups")
backup = backup and backup:FindFirstChild("BeforeSkippingGame")
backup = backup and backup:FindFirstChild("ProgressionMap")
local checked, changes = 0, {}
local function compare(old, current)
	local groups = {}
	for _, child in current:GetChildren() do
		local key = child.Name .. "|" .. child.ClassName
		groups[key] = groups[key] or {}
		table.insert(groups[key], child)
	end
	local offsets = {}
	for _, child in old:GetChildren() do
		local key = child.Name .. "|" .. child.ClassName
		offsets[key] = (offsets[key] or 0) + 1
		local match = groups[key] and groups[key][offsets[key]]
		assert(match, "Missing original object: " .. child:GetFullName())
		if child:IsA("BasePart") then
			checked += 1
			if
				match.CFrame ~= child.CFrame
				or match.Size ~= child.Size
				or match.CanCollide ~= child.CanCollide
				or match.CanTouch ~= child.CanTouch
				or match.CanQuery ~= child.CanQuery
			then
				table.insert(changes, child:GetFullName())
			end
		end
		compare(child, match)
	end
end
if backup then
	compare(backup, map)
end
assert(#changes == 0, "Original volumes changed: " .. table.concat(changes, ", "))
local world = assert(map:FindFirstChild("SkippingWorld"))
assert(world:FindFirstChild("MainPlazaPath"), "Missing central walkway")
local lanes = 0
for i = 1, 7 do
	local lane = assert(map.TrainingZone:FindFirstChild("TrainingLane" .. i))
	assert(lane.StartingPad.Size.X >= 8 and lane.TrainingStrip.Size.Z >= 13, "Training lane too narrow")
	assert(lane:GetAttribute("RequiredRebirths") ~= nil, "Missing lane requirement")
	lanes += 1
end
local water = 0
for i = 1, 8 do
	local p = assert(world:FindFirstChild("Water_" .. i))
	assert(not p.CanCollide and not p.CanTouch and not p.CanQuery, "Water visual blocks gameplay")
	water += 1
end
local prompt = assert(world.World2Portal.PortalField:FindFirstChildWhichIsA("ProximityPrompt", true))
assert(
	prompt.Parent:IsA("Attachment") and math.abs(prompt.Parent.WorldPosition.Y - 4) < 0.01,
	"Portal prompt above player reach"
)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { map }
local samples = 0
for x = -170, -60, 11 do
	for z = 6, 20, 7 do
		local hit = workspace:Raycast(Vector3.new(x, 15, z), Vector3.new(0, -20, 0), params)
		assert(hit, "Throwing floor gap")
		samples += 1
	end
end
local advanced = workspace:FindFirstChild("World2Map")
local advancedSamples = 0
if advanced then
	assert(advanced:GetAttribute("GameplayWorld2Version") == 1, "Incomplete advanced arena")
	assert(not advanced.Lobby.MapSpawn.Enabled, "Advanced spawn overrides the first world")
	local offset = advanced:GetAttribute("ArenaOffsetX")
	assert(
		offset
			and math.abs(advanced.Lobby.ThrowingApron.Position.X - map.Lobby.ThrowingApron.Position.X - offset)
				< 0.001,
		"Incorrect world offset"
	)
	params.FilterDescendantsInstances = { advanced }
	for x = -170, -60, 11 do
		for z = 6, 20, 7 do
			assert(
				workspace:Raycast(Vector3.new(x + offset, 15, z), Vector3.new(0, -20, 0), params),
				"Advanced throwing floor gap"
			)
			advancedSamples += 1
		end
	end
end
return game:GetService("HttpService"):JSONEncode({
	originalVolumesChecked = checked,
	volumeChanges = #changes,
	lanes = lanes,
	biomes = water,
	throwFloorSamples = samples,
	portalHeight = prompt.Parent.WorldPosition.Y,
	advancedFloorSamples = advancedSamples,
})
