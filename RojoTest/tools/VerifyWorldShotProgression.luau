-- Read-only progression checks. Clone modules to avoid stale Studio require caches.
-- The clone stays next to the original: GameConfig requires ./Core/Economy, and a
-- relative require only resolves inside the folder of the shared package.
local module = game.ReplicatedStorage.Shared.GameConfig:Clone()
module.Name = "GameConfigShotCheck"
module.Parent = game.ReplicatedStorage.Shared
local Config = require(module)
module:Destroy()
local checks, examples = 0, {}
local function check(ok, message)
	assert(ok, message)
	checks += 1
end
for world = 1, 2 do
	local definition = Config.WorldShotProgression[world]
	local map = workspace[world == 1 and "ProgressionMap" or "World2Map"]
	local limit = Config.shotLimit(world, map)
	local previous = 0
	for _, fraction in { 0, 0.0001, 0.001, 0.01, 0.1, 0.5, 0.9, 1 } do
		local skill = definition.requiredPower * fraction
		local distance = Config.shotDistance(skill, 1, world, map)
		check(distance > previous, "Distance grows below the threshold")
		check(distance >= 60 and distance <= limit, "Distance stays within the route")
		previous = distance
	end
	check(Config.shotDistance(definition.requiredPower, 1, world, map) == limit, "Threshold reaches the endpoint")
	check(
		Config.shotDistance(definition.requiredPower / 10, 10, world, map) == limit,
		"Ball power contributes before the distance curve"
	)
	check(
		Config.shotDistance(definition.requiredPower / 100, 10, world, map)
			== Config.shotDistance(definition.requiredPower / 10, 1, world, map),
		"Equal effective power gives equal distance"
	)
	check(Config.shotDistance(43000000000, 10, world, map) == limit, "Existing high Skill remains valid")
	check(Config.shotDistance(-100, 1, world, map) == 60, "Minimum launch distance")
	local a = Config.shotDistance(definition.requiredPower * 0.01, 1, world, map)
	local b = Config.shotDistance(definition.requiredPower * 0.1, 1, world, map)
	check(b / a > 2.5 and b / a < 3, "Tenfold growth remains noticeable")
	local frame = Config.arenaFrame(map)
	local start = frame:PointToWorldSpace(Vector3.new(-115.35, 1.8, -0.3))
	local finish = start + frame.LookVector * (limit / Config.DistancePerStud)
	local last = map.SkippingWorld.Water_8
	local finale = map.SkippingWorld:FindFirstChild("SakuraJapaneseFinale")
	local gate = finale and finale:FindFirstChild("SakuraGatewayFrame")
	local goal = gate and gate:GetPivot().Position or last.Position + frame.LookVector * (last.Size.Z / 2 - 7)
	check(math.abs((goal - finish):Dot(frame.LookVector)) < 0.25, "Flight reaches the measured endpoint")
	-- A moved and rotated arena must retain the same travel distance.
	local sample = Instance.new("Model")
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	lobby.Parent = sample
	map.Lobby.ThrowingApron:Clone().Parent = lobby
	local scenery = Instance.new("Model")
	scenery.Name = "SkippingWorld"
	scenery.Parent = sample
	last:Clone().Parent = scenery
	if gate then
		local endGroup = Instance.new("Model")
		endGroup.Name = "SakuraJapaneseFinale"
		endGroup.Parent = scenery
		local marker = Instance.new("Model")
		marker.Name = "SakuraGatewayFrame"
		marker.WorldPivot = gate:GetPivot()
		marker.Parent = endGroup
		local anchor = Instance.new("Part")
		anchor.CFrame = gate:GetPivot()
		anchor.Parent = marker
	end
	sample:PivotTo(CFrame.new(100, 40, -200) * CFrame.Angles(0, 0.7, 0) * sample:GetPivot())
	check(math.abs(Config.shotLimit(world, sample) - limit) <= 1, "Moving or rotating the map preserves progression")
	sample:Destroy()
	table.insert(
		examples,
		{ world = world, requiredPower = definition.requiredPower, limit = limit, atOnePercent = a, atTenPercent = b }
	)
end
return { checks = checks, worlds = examples }
