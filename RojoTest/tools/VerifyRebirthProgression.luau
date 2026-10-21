-- Pure progression checks, no player state or currency changes.
-- The clone stays next to the original: GameConfig requires ./Core/Economy, and a
-- relative require only resolves inside the folder of the shared package.
local source = game.ReplicatedStorage.Shared.GameConfig:Clone()
source.Name = "GameConfigRebirthCheck"
source.Parent = game.ReplicatedStorage.Shared
local Config = require(source)
source:Destroy()
local checks, examples = 0, {}
local function check(ok, message)
	assert(ok, message)
	checks += 1
end
for rebirths, expected in { [0] = 50000, [1] = 80000, [2] = 128000, [3] = 204800 } do
	check(Config.rebirthRequirement(rebirths) == expected, "Early rebirth curve")
end
for _, rebirths in { 0, 1, 2, 3, 6, 9, 16, 10000 } do
	local requirement = Config.rebirthRequirement(rebirths)
	check(Config.threshold(1, rebirths) == 0, "Level 1 starts at zero")
	check(Config.threshold(Config.MaxLevel, rebirths) == requirement, "Level 80 uses the balanced Skill goal")
	local previous = 0
	for level = 2, Config.MaxLevel do
		local threshold = Config.threshold(level, rebirths)
		check(threshold > previous, "Level thresholds strictly increase")
		previous = threshold
		check(Config.level(threshold, rebirths) == level, "Exact threshold reaches its level")
		check(Config.level(threshold - 1, rebirths) == level - 1, "Never gain a level before its threshold")
	end
	local below, maxLevel, progress = Config.rebirthProgress(requirement - 1, rebirths)
	check(below == 79 and maxLevel == 80 and progress < 1, "Rebirth stays locked at level 79")
	local current, goal, readyProgress = Config.rebirthProgress(requirement, rebirths)
	check(current == 80 and goal == 80 and readyProgress == 1, "Level 80 unlocks rebirth")
	if rebirths <= 3 then
		table.insert(
			examples,
			{ rebirth = rebirths + 1, level80Skill = requirement, level2Skill = Config.threshold(2, rebirths) }
		)
	end
end
local level, _, small = Config.rebirthProgress(1000, 0)
check(level < 80 and small < 1, "A tiny amount must not grant a rebirth")
local current, required, progress = Config.rebirthProgress(999999, 0)
check(current == 80 and required == 80 and progress == 1, "Reported 999999 case reaches level 80")
local resetLevel, _, resetProgress = Config.rebirthProgress(0, 1)
check(resetLevel == 1 and resetProgress == 0, "Rebirth resets to level 1")
local huge = Config.rebirthRequirement(10000)
check(huge == 1e15 and huge < math.huge, "Large existing rebirth counts remain finite")
check(
	Config.level(10000, 0) < 80 and Config.effectiveShotPower(10000, 10) == 100000,
	"Ball power alone cannot skip levels"
)
check(Config.threshold(80, 1) > Config.threshold(80, 0), "Next rebirth requires more Skill")
return {
	checks = checks,
	examples = examples,
	requiredLevel = required,
	reportedCase = "level 80",
	firstGoal = Config.threshold(80),
}
