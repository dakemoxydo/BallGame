--!strict
local Shared = script.Parent
local _Config = require(Shared.GameConfig)
local Visuals = {}

function Visuals.create(id, diameter)
	local templates = Shared:WaitForChild("BallTemplates")
	local template = templates:FindFirstChild(id) or templates:FindFirstChild("Pebble")
	assert(template, "Missing ball template")
	local model = template:Clone()
	model.Name = "Ball_" .. id
	model:SetAttribute("BallId", id)
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = cf
	model:ScaleTo(model:GetScale() * diameter / math.max(size.X, size.Y, size.Z))
	model:PivotTo(CFrame.new())
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	return model
end

function Visuals.visible(model, visible)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = visible and 0 or 1
		end
	end
end

function Visuals.preview(parent, id)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "BallPreview"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromOffset(105, 83)
	viewport.Position = UDim2.fromOffset(10, 3)
	viewport.Ambient = Color3.new(1, 1, 1)
	viewport.LightColor = Color3.new(1, 1, 1)
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local ball = Visuals.create(id, 2.4)
	ball.Parent = world
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.5, -5), Vector3.zero)
	camera.FieldOfView = 35
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = parent
	return viewport
end

-- Deterministic cosmetic motion; never accumulates position error.
function Visuals.standPose(base, time, phase)
	local bob = 0.45 * math.sin((time % 2.5) * math.pi * 2 / 2.5 + phase)
	return (base + Vector3.new(0, bob, 0)) * CFrame.Angles(0, (time % 22.5) * math.pi * 2 / 22.5, 0), bob
end

return Visuals
