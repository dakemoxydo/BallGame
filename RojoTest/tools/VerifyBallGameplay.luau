local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Buy = require(Shared.BallPurchases)
local Visuals = require(Shared.BallVisuals)
local assertions = 0
local function check(value, message)
	assert(value, message)
	assertions += 1
end
check(#Config.Stones == 10, "10 tiers")
for i, item in Config.Stones do
	if i > 1 then
		check(item.power > Config.Stones[i - 1].power and item.cost > Config.Stones[i - 1].cost, "Increasing tiers")
	end
	local m = Visuals.create(item.id, 1.6)
	local cf, size = m:GetBoundingBox()
	check((m:GetPivot().Position - cf.Position).Magnitude < 0.01, "Centered gameplay ball")
	check(math.abs(math.max(size.X, size.Y, size.Z) - 1.6) < 0.01, "Gameplay size")
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			check(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Cosmetic physics")
		end
	end
	m:Destroy()
end
local d = { wins = 249, stone = "Pebble", stones = { Pebble = true } }
check(
	not Buy.buyOrEquip(d, "Smooth") and d.wins == 249 and d.stone == "Pebble" and not d.stones.Smooth,
	"Insufficient crowns no change"
)
d.wins = 250
check(Buy.buyOrEquip(d, "Smooth") and d.wins == 0 and d.stone == "Smooth" and d.stones.Smooth, "Buy and equip")
check(Buy.buyOrEquip(d, "Pebble") and Buy.buyOrEquip(d, "Smooth") and d.wins == 0, "Owned re-equip free")
check(not Buy.buyOrEquip(d, "InjectedId") and d.wins == 0 and d.stone == "Smooth", "Reject unknown")
check(Buy.power(d) == 1.15, "Selected power")
d.stone = "WorldCreator"
check(Buy.power(d) == 1, "Reject unowned bonus")
d.wins = 75000000
check(Buy.buyOrEquip(d, "WorldCreator") and d.wins == 0 and Buy.power(d) == 10, "Final tier")
for _, map in { workspace.ProgressionMap, workspace.World2Map } do
	local found = 0
	for _, p in map.EmptyItemStand:GetDescendants() do
		if p:IsA("ProximityPrompt") and p:GetAttribute("BallId") then
			found += 1
		end
	end
	check(found == 10, "Ten purchase prompts each world")
end
local base = CFrame.new(1, 10, 2)
local low, high = math.huge, -math.huge
for i = 0, 100 do
	local pose = Visuals.standPose(base, i / 20, 0)
	low = math.min(low, pose.Position.Y)
	high = math.max(high, pose.Position.Y)
	check(math.abs(pose.Position.X - 1) < 0.001 and math.abs(pose.Position.Z - 2) < 0.001, "No animation drift")
end
check(math.abs(low - 9.55) < 0.01 and math.abs(high - 10.45) < 0.01, "Bob range")
local a = Visuals.standPose(base, 1800000000, 0)
local b = Visuals.standPose(base, 1800000001, 0)
check((a.LookVector - b.LookVector).Magnitude > 0.13, "Smooth rotation with Unix timestamps")
return {
	assertions = assertions,
	crownsTransactions = "passed",
	tiers = "passed",
	templates = "passed",
	animation = "passed",
}
