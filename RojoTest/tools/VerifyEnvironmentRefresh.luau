local reports = {}
for _, map in { workspace.ProgressionMap, workspace.World2Map } do
	local frame = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }
	params.RespectCanCollide = true
	local rays = 0
	for _, point in
		{
			Vector3.new(-116, 0, 16),
			Vector3.new(-106, 0, 45),
			Vector3.new(-106, 0, 90),
			Vector3.new(-106, 0, 170),
			Vector3.new(-183, 4, -45),
			Vector3.new(-49, 4, -100),
		}
	do
		local position = frame:PointToWorldSpace(point)
		local hit = workspace:Raycast(position + Vector3.new(0, 30, 0), Vector3.new(0, -40, 0), params)
		assert(hit and hit.Instance.CanCollide, "Missing physical floor")
		assert(math.abs(hit.Position.Y - position.Y) < 1.3, "Unexpected floor height")
		rays += 1
	end
	for _, lane in map.TrainingZone:GetChildren() do
		if lane:IsA("Model") and lane.Name:match("^TrainingLane") then
			local strip = lane.TrainingStrip
			local hit = workspace:Raycast(strip.Position + Vector3.new(0, 8, 0), Vector3.new(0, -12, 0), params)
			assert(hit and hit.Instance.CanCollide, "Lane floor missing")
			rays += 1
		end
	end
	local parts = 0
	local meshParts = 0
	local riverIntrusions = 0
	for _, p in map.NativeEnvironment:GetDescendants() do
		if p:IsA("BasePart") then
			assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Decor changes physics")
			parts += 1
			if p:IsA("MeshPart") then
				meshParts += 1
			end
			local localPos = frame:PointToObjectSpace(p.Position)
			if localPos.Z < 0 then
				for _, signX in { -1, 1 } do
					for _, signY in { -1, 1 } do
						for _, signZ in { -1, 1 } do
							local corner = frame:PointToObjectSpace(
								p.CFrame:PointToWorldSpace(p.Size * Vector3.new(signX, signY, signZ) / 2)
							)
							if math.abs(corner.X + 116) < 55.8 and corner.Z < 0 then
								riverIntrusions += 1
							end
						end
					end
				end
			end
		end
	end
	assert(meshParts == 0, "External meshes added")
	assert(riverIntrusions == 0, "Decoration intrudes into river")
	table.insert(reports, {
		map = map.Name,
		nativeParts = parts,
		physicalFloorRays = rays,
		riverIntrusions = riverIntrusions,
		externalMeshes = meshParts,
	})
end
return reports
