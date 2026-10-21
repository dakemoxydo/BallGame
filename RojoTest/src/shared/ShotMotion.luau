--!strict
local Config = require(script.Parent.GameConfig)
local Motion = {}
Motion.BounceCount = 7
function Motion.contactTime(contact, duration)
	return Config.KickWindup + duration * contact / Motion.BounceCount
end
function Motion.position(startPosition, distance, alpha, direction)
	alpha = math.clamp(alpha, 0, 1)
	local segment = alpha * Motion.BounceCount
	local bounce = math.min(Motion.BounceCount - 1, math.floor(segment))
	local phase = segment - bounce
	local height = math.max(1.2, 8 - bounce * 1.05)
	direction = direction or -Vector3.zAxis
	return startPosition
		+ Vector3.new(0, math.sin(phase * math.pi) * height, 0)
		+ direction * (distance / Config.DistancePerStud * alpha),
		bounce
end
return Motion
