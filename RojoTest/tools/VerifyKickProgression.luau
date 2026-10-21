-- Run in a Studio server Script during play. No persistent player data is changed.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Motion = require(game.ReplicatedStorage.Shared.ShotMotion)
local checks = 0
local function check(value, message)
	assert(value, message)
	checks += 1
end
local previous = 0
local distances = {}
for _, skill in { 0, 100, 1000, 10000, 100000, 1000000 } do
	local distance = Config.shotDistance(skill, 1)
	check(distance > previous, "Training must increase distance before the map limit")
	previous = distance
	table.insert(distances, { skill = skill, distance = distance })
end
check(Config.shotDistance(100000, 1) > Config.shotDistance(10000, 1) * 2.5, "Tenfold Skill visibly increases distance")
check(Config.shotDistance(1000, 1.9) > Config.shotDistance(1000, 1), "Equipped ball increases power")
check(Config.shotDistance(1e15, 10, 1) == Config.shotLimit(1), "Shot reaches the World 1 endpoint")
check(Config.shotDistance(1e15, 10, 2) == Config.shotLimit(2), "World 2 retains its shorter route")
local origin = Vector3.new(0, 2, 0)
for bounce = 0, 7 do
	local position = Motion.position(origin, 629, bounce / 7)
	check(math.abs(position.Y - origin.Y) < 0.001, "All bounce contacts return to the surface")
end
local finish = Motion.position(origin, 629, 1)
check(math.abs(-finish.Z * Config.DistancePerStud - 629) < 0.001, "Flight and reward distances agree")
check(Config.KickContact == Config.KickWindup, "Kick contact launches the ball")
check(Config.shotDuration(5800) > Config.shotDuration(60), "Longer shots allow more viewing time")
return { checks = checks, distances = distances }
