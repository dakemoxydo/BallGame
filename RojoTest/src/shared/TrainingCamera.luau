--!strict
-- Fit the complete live field and player inside the HUD's central viewing area.
local Camera = {}
Camera.FieldOfView = 60

function Camera.pose(lane, characterPosition, viewport)
	local cf, size = lane:GetBoundingBox()
	local points = { characterPosition + Vector3.new(0, 3, 0), characterPosition - Vector3.new(0, 3, 0) }
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				table.insert(points, cf * Vector3.new(x * size.X / 2, y * size.Y / 2, z * size.Z / 2))
			end
		end
	end
	local center = cf.Position + Vector3.new(0, 1, 0)
	local direction = Vector3.new(0, 0.38, 1).Unit
	local basis = CFrame.lookAt(center + direction, center)
	local tanV = math.tan(math.rad(Camera.FieldOfView / 2)) * 0.94
	local tanH = tanV * math.max(0.2, viewport.X / math.max(1, viewport.Y)) * 0.98
	local distance = 20
	for _, point in points do
		local p = basis:VectorToObjectSpace(point - center)
		distance = math.max(distance, p.Z + math.abs(p.X) / tanH, p.Z + math.abs(p.Y) / tanV)
	end
	return CFrame.lookAt(center + direction * distance, center)
end

return Camera
