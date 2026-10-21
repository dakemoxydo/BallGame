-- Run through Studio MCP in Edit or Play; no player data is changed.
local Shared = game.ReplicatedStorage.Shared
local Motion = require(Shared.TrainingMotion)
local Camera = require(Shared.TrainingCamera)
local Config = require(Shared.GameConfig)
local checks = 0
local function check(ok, message)
	assert(ok, message)
	checks += 1
end
local origin, finish = Vector3.new(0, 0.8, 0), Vector3.new(48, 0.8, 0)
for lane = 1, 7 do
	local count = Motion.hitCount(lane)
	check(count == (lane <= 3 and 3 or 4), "Lane contact count")
	check(Motion.position(origin, finish, Config.KickContact, lane) == origin, "No travel before kick")
	local previous = Config.KickContact
	for hit = 1, count do
		local t = Motion.hitTime(lane, hit)
		check(t > previous and t < Config.TrainingCycle, "Ordered contacts inside cycle")
		local p = Motion.position(origin, finish, t, lane)
		check(math.abs(p.Y - origin.Y) < 1e-5, "Reward coincides with ground contact")
		check(
			Motion.position(origin, finish, (previous + t) / 2, lane).Y > origin.Y + 0.2,
			"Ball rises between contacts"
		)
		previous = t
	end
	for _, multiplier in { 1, 1.15, 2.75, 10 } do
		local remainder, total = 0, 0
		local perCycle = Config.Lanes[lane].gain * multiplier * 7 * Config.TrainingCycle / 0.8
		for _ = 1, 100 do
			for _ = 1, count do
				local gain, nextRemainder = Motion.reward(perCycle, lane, remainder)
				total += gain
				remainder = nextRemainder
				check(gain > 0, "Every contact gives visible skill")
			end
		end
		check(math.abs(total + remainder - perCycle * 100) < 1e-5, "Total training rate preserved")
	end
end
local oldCF, oldFov = workspace.CurrentCamera.CFrame, workspace.CurrentCamera.FieldOfView
local camera = workspace.CurrentCamera
local sizes = { Vector2.new(1920, 1080), Vector2.new(1280, 720), Vector2.new(844, 390), Vector2.new(390, 844) }
for _, name in { "ProgressionMap", "World2Map" } do
	local map = workspace:FindFirstChild(name)
	if map then
		local previousLength = 0
		for i = 1, 7 do
			local lane = map.TrainingZone["TrainingLane" .. i]
			check(lane.TrainingStrip.Size.X > previousLength, "Lanes grow with rebirth requirement")
			previousLength = lane.TrainingStrip.Size.X
			local bounds, size = lane:GetBoundingBox()
			for _, viewport in sizes do
				local pose = Camera.pose(lane, lane.StartingPad.Position + Vector3.new(0, 3, 0), viewport)
				local tanV = math.tan(math.rad(Camera.FieldOfView / 2))
				for _, x in { -1, 1 } do
					for _, y in { -1, 1 } do
						for _, z in { -1, 1 } do
							local p = pose:PointToObjectSpace(
								bounds * Vector3.new(x * size.X / 2, y * size.Y / 2, z * size.Z / 2)
							)
							check(
								p.Z < 0
									and math.abs(p.Y / -p.Z) < tanV * 0.97
									and math.abs(p.X / -p.Z) < tanV * viewport.X / viewport.Y * 0.97,
								"Whole field inside camera margins"
							)
						end
					end
				end
			end
		end
	end
end
check(camera.CFrame == oldCF and camera.FieldOfView == oldFov, "Verification leaves camera unchanged")
return { checks = checks, contacts = "3 / 4", cameraSizes = #sizes }
