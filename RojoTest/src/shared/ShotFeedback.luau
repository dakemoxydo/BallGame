--!strict
local Config = require(script.Parent.GameConfig)
local Feedback = {}

function Feedback.profile(skill, power, world)
	local target = Config.WorldShotProgression[world == 2 and 2 or 1].requiredPower
	local ratio = math.clamp(Config.effectiveShotPower(skill, power) / target, 0, 1)
	local intensity = ratio ^ 0.22
	return {
		intensity = intensity,
		fieldOfView = 68 + 14 * intensity,
		trailLifetime = 0.18 + 0.42 * intensity,
		rippleScale = 0.65 + 1.3 * intensity,
		kickVolume = 0.18 + 0.27 * intensity,
		kickPlayback = 1 + 0.35 * intensity,
		shakeAmplitude = 0.015 + 0.045 * intensity,
	}
end

return Feedback
