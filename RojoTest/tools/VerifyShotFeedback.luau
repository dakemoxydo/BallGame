-- Run in Edit or Play with fresh shared modules; never changes player state.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Feedback = require(game.ReplicatedStorage.Shared.ShotFeedback)
local Motion = require(game.ReplicatedStorage.Shared.ShotMotion)
local checks, examples = 0, {}
local function check(value, message)
	assert(value, message)
	checks += 1
end
for world = 1, 2 do
	local target = Config.WorldShotProgression[world].requiredPower
	local previousSpeed, previousFov, previousTrail = 0, 0, 0
	for _, fraction in { 0, 0.01, 0.1, 1 } do
		local skill = target * fraction
		local profile = Feedback.profile(skill, 1, world)
		local distance = Config.shotDistance(skill, 1, world)
		local duration = Config.shotDuration(distance, world, profile.intensity)
		local speed = distance / duration
		check(speed > previousSpeed, "More force gives more travel speed")
		check(profile.fieldOfView > previousFov and profile.fieldOfView <= 82, "FOV conveys power within limits")
		check(profile.trailLifetime > previousTrail and profile.trailLifetime <= 0.61, "Trail grows with power")
		check(duration > 1.7 and duration <= 14, "Shot duration remains readable")
		for contact = 1, Motion.BounceCount do
			local elapsed = Motion.contactTime(contact, duration)
			local alpha = (elapsed - Config.KickWindup) / duration
			local p = Motion.position(Vector3.zero, distance, alpha)
			check(math.abs(p.Y) < 1e-5, "Skill timing matches visible ground contact")
		end
		previousSpeed, previousFov, previousTrail = speed, profile.fieldOfView, profile.trailLifetime
		table.insert(
			examples,
			{ world = world, skill = skill, distance = distance, duration = duration, speed = speed }
		)
	end
	check(
		Feedback.profile(target / 10, 10, world).intensity == Feedback.profile(target, 1, world).intensity,
		"Equipped ball power changes feedback"
	)
	check(Feedback.profile(43000000000, 10, world).intensity == 1, "Large saved power stays bounded")
end
for _, multiplier in { 1, 1.15, 2.75, 34, 1000 } do
	local total = 0
	for _ = 1, Motion.BounceCount do
		local gain = Config.shotBounceGain(multiplier)
		check(gain == math.floor(7 * multiplier), "Every landing awards the full fixed reward")
		total += gain
	end
	check(total == Motion.BounceCount * math.floor(7 * multiplier), "Each bounce independently earns the full reward")
end
return { checks = checks, examples = examples }
