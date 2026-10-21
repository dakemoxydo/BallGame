-- Read-only route checks in Edit or Server. Does not modify player progression.
local map = workspace.ProgressionMap
local world = map.SkippingWorld
-- The front of the route is the front edge of the first biome: the scene is
-- the truth, the attribute of the map only describes it.
local front = world.Water_1.Position.Z + world.Water_1.Size.Z / 2
assert(map:GetAttribute("BiomeLengthScale") == 1.5)
assert(map:GetAttribute("RouteLengthStuds") == 2160)
local checks = 0
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { map.WaterCorridor, world }
-- The banks are the walkable ground beside the river. Their edges are read
-- from the scene: the river was moved after this check was written, so the
-- columns are derived and not hard coded.
local river = world.Water_1
local riverLeft = river.Position.X - river.Size.X / 2
local riverRight = river.Position.X + river.Size.X / 2
local leftWall = map.PerimeterWalls.CorridorLeft
local rightWall = map.PerimeterWalls.CorridorRight
local leftEdge = leftWall.Position.X + leftWall.Size.X / 2
local rightEdge = rightWall.Position.X - rightWall.Size.X / 2
local columns = {
	leftEdge + 6,
	(leftEdge + riverLeft) / 2,
	(riverRight + rightEdge) / 2,
	rightEdge - 6,
}
for i = 1, 8 do
	local water = world["Water_" .. i]
	assert(math.abs(water.Size.Z - 270) < 0.01)
	assert(math.abs(water.Position.Z - (front - (i - 0.5) * 270)) < 0.01)
	assert(math.abs(water.Size.X - 111.6) < 0.01)
	local banks = 0
	for _, b in world:GetChildren() do
		if b.Name:match("^BiomeBank" .. i .. "_[12]$") then
			banks += 1
			assert(math.abs(b.Size.Z - 270) < 0.01 and math.abs(b.Position.Z - water.Position.Z) < 0.01)
		end
	end
	assert(banks == 4)
	for _, t in { 1, 45, 135, 225, 269 } do
		local z = front - (i - 1) * 270 - t
		-- The river carries a surface over the whole biome.
		local surface = workspace:Raycast(Vector3.new((riverLeft + riverRight) / 2, 40, z), Vector3.new(0, -60, 0), rp)
		assert(surface and surface.Instance == water, "No river surface at " .. z)
		-- The banks carry a floor, and the floor of the corridor has two
		-- levels: the inner one and the outer one.
		for _, x in columns do
			local hit = workspace:Raycast(Vector3.new(x, 40, z), Vector3.new(0, -60, 0), rp)
			assert(hit, "Floor gap at " .. x .. ", " .. z)
			if hit.Instance.Name:match("^Ground") then
				assert(
					math.abs(hit.Position.Y - 24) < 0.31 or math.abs(hit.Position.Y - 29) < 0.31,
					"Unexpected floor height at " .. x .. ", " .. z
				)
			end
			checks += 1
		end
	end
end
local back = front - 2160
assert(math.abs(world.SakuraJapaneseFinale.SakuraGatewayFrame:GetPivot().Position.Z - (back + 7)) < 0.01)
assert(math.abs(world.RiverEndSafety.Position.Z - (back - 2)) < 0.01)
assert(math.abs(map.PerimeterWalls.CorridorEnd.Position.Z - (back - 3)) < 0.01)
for _, name in { "CorridorLeft", "CorridorRight" } do
	local a, b = map.PerimeterWalls[name], map.PerimeterWalls[name .. "FinalExtension"]
	assert(math.abs((a.Position.Z - a.Size.Z / 2) - (b.Position.Z + b.Size.Z / 2)) < 0.01)
	assert(math.abs(b.Position.Z - b.Size.Z / 2 - back) < 0.01)
end
-- Clone only the module to avoid Edit require caches after a Rojo source update.
-- The clone stays next to the original: GameConfig requires ./Core/Economy, and a
-- relative require only resolves inside the folder of the shared package.
local module = game.ReplicatedStorage.Shared.GameConfig:Clone()
module.Name = "GameConfigBiomeCheck"
module.Parent = game.ReplicatedStorage.Shared
local Config = require(module)
module:Destroy()
local limit = Config.shotLimit(1, map)
assert(Config.shotDistance(1000000, 1, 1, map) == limit)
assert(Config.shotDistance(100000, 1, 1, map) > Config.shotDistance(10000, 1, 1, map) * 2.5)
assert(Config.shotDistance(1e15, 10, 2) == Config.shotLimit(2))
assert(Config.shotDuration(limit, 1) > 13)
assert(Config.shotDuration(Config.shotLimit(2), 2) == 10)
local frame = Config.arenaFrame(map)
local start = frame:PointToWorldSpace(Vector3.new(-115.35, 1.8, -0.3))
local finish = start + frame.LookVector * (limit / Config.DistancePerStud)
assert(finish.Z > back and finish.Z < back + 270, "Maximum flight must finish in Sakura")
assert(
	math.abs(finish.Z - world.SakuraJapaneseFinale.SakuraGatewayFrame:GetPivot().Position.Z) < 0.25,
	"Maximum shot reaches the gateway plane"
)
return {
	biomes = 8,
	lengthPerBiome = 270,
	totalLength = 2160,
	floorChecks = checks,
	maxShot = limit,
	finish = tostring(finish),
}
