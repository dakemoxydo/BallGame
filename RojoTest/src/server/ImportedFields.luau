--!strict
-- Applies imported Blender visuals to existing gameplay lane footprints.
local Fields = {}
local V = Vector3.new
local turn = CFrame.Angles(0, math.pi / 2, 0)
local names = { "Backyard", "Club", "Royal", "Diamond", "Mythic", "Cosmic", "Divine" }

local function hide(part, keepCollision)
	part.Transparency = 1
	part.CanCollide = keepCollision
	part.CanTouch = false
	part.CanQuery = keepCollision
	part.CastShadow = false
	for _, child in part:GetDescendants() do
		if child:IsA("Texture") or child:IsA("Decal") then
			child.Transparency = 1
		end
		if child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
			child.Enabled = false
		end
	end
end

local function scaledFrame(source, scale, origin)
	local function stretch(v)
		return V(v.X * scale.X, v.Y * scale.Y, v.Z * scale.Z)
	end
	local sx = stretch(source.CFrame.RightVector)
	local sy = stretch(source.CFrame.UpVector)
	local sz = stretch(-source.CFrame.LookVector)
	local size = source.Size * V(sx.Magnitude, sy.Magnitude, sz.Magnitude)
	local x, y, z
	if size.Y >= size.X and size.Y >= size.Z then
		y = sy.Unit
		z = (sz - y * sz:Dot(y)).Unit
		x = y:Cross(z).Unit
	elseif size.Z >= size.X then
		z = sz.Unit
		x = (sx - z * sx:Dot(z)).Unit
		y = z:Cross(x).Unit
	else
		x = sx.Unit
		y = (sy - x * sy:Dot(x)).Unit
		z = x:Cross(y).Unit
	end
	local localPosition = source.Position - V(0, 0.62, 0)
	return CFrame.fromMatrix(
		origin + turn:VectorToWorldSpace(stretch(localPosition)),
		turn:VectorToWorldSpace(x),
		turn:VectorToWorldSpace(y),
		turn:VectorToWorldSpace(z)
	),
		size
end

function Fields.apply(map)
	local repairs = map:FindFirstChild("SurfaceRepairs")
	if repairs then
		for _, overlay in repairs:GetChildren() do
			if overlay:IsA("BasePart") and overlay.Name == "Arrow_Surface" then
				hide(overlay, false)
			end
		end
	end
	if map:GetAttribute("ImportedFieldsVersion") == 1 then
		return
	end
	local templates = game:GetService("ServerStorage"):FindFirstChild("ImportedTrainingFields")
	assert(templates, "ImportedTrainingFields templates are missing")
	local zone = map:WaitForChild("TrainingZone")
	local skipping = map:FindFirstChild("SkippingWorld")
	for i = 1, 7 do
		local lane = zone:FindFirstChild("TrainingLane" .. i)
		local template = templates:FindFirstChild("Field" .. i)
		assert(lane and template and #template:GetChildren() > 0, "Missing imported lane " .. i)
		assert(not lane:FindFirstChild("ImportedField"), "Partial previous field application")
	end
	for i = 1, 7 do
		local lane = zone["TrainingLane" .. i]
		local strip, foundation = lane.TrainingStrip, lane.Foundation
		local top = strip.Position.Y + strip.Size.Y / 2
		local origin = V(strip.Position.X, top, strip.Position.Z)
		local scale = V(strip.Size.Z / 8, strip.Size.Z / 8, strip.Size.X / 20)
		local visual = Instance.new("Model")
		visual.Name = "ImportedField"
		visual:SetAttribute("Theme", names[i])
		visual.Parent = lane
		for _, source in templates["Field" .. i]:GetChildren() do
			local part = source:Clone()
			part.CFrame, part.Size = scaledFrame(source, scale, origin)
			if source.Name:find("_Earth_Base", 1, true) then
				part.CFrame = CFrame.new(foundation.Position) * turn
				part.Size = V(foundation.Size.Z, foundation.Size.Y, foundation.Size.X)
			elseif source.Name:find("_Grass_Bed", 1, true) then
				part.CFrame = CFrame.new(strip.Position) * turn
				part.Size = V(strip.Size.Z, strip.Size.Y, strip.Size.X)
			elseif source.Name:find("_Penalty_Spot", 1, true) then
				-- Keep the new spot at the original training trigger.
				part.Position = V(lane.StartingPad.Position.X, part.Position.Y, lane.StartingPad.Position.Z)
			end
			part.Anchored = true
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part.Parent = visual
		end
		visual.WorldPivot = CFrame.new(strip.Position)
		for _, part in lane:GetChildren() do
			if part:IsA("BasePart") and part.Name ~= "UIAnchor" then
				hide(part, part == strip or part == foundation)
			end
		end
		if skipping then
			local stone = skipping:FindFirstChild("TrainingStone" .. i)
			if stone then
				hide(stone, false)
			end
			local board = skipping:FindFirstChild("LaneBoard" .. i)
			if board then
				hide(board, false)
			end
			local _, bounds = visual:GetBoundingBox()
			local cf = visual:GetBoundingBox()
			local labelY = cf.Position.Y + bounds.Y / 2 + 3.8
			for _, anchor in skipping:GetChildren() do
				if
					anchor:IsA("BasePart")
					and anchor.Name == "LabelAnchor"
					and math.abs(anchor.Position.Z - strip.Position.Z) < 0.1
					and board
					and math.abs(anchor.Position.X - board.Position.X) < 0.1
				then
					anchor.Position = V(anchor.Position.X, labelY, anchor.Position.Z)
				end
			end
		end
	end
	map:SetAttribute("ImportedFieldsVersion", 1)
end
return Fields
