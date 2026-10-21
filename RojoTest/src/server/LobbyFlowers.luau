--!strict
local Flowers = {}
function Flowers.apply(map)
	local world = map.SkippingWorld
	if world:FindFirstChild("ImprovedLobbyFlowers") then
		return
	end
	local stems, heads = {}, {}
	for _, p in ipairs(world:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "FlowerStem" then
			table.insert(stems, p)
		elseif p:IsA("BasePart") and p.Name == "Flower" then
			table.insert(heads, p)
		end
	end
	local group = Instance.new("Model")
	group.Name = "ImprovedLobbyFlowers"
	local backup = Instance.new("Folder")
	backup.Name = map.Name .. "_BeforeLobbyFlowers"
	backup.Parent = game.ServerStorage.WorldBackups
	local function part(parent, name, size, cf, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		p.Parent = parent
		return p
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map.Lobby }
	for i, stem in ipairs(stems) do
		local head
		for _, h in ipairs(heads) do
			if
				(Vector2.new(h.Position.X, h.Position.Z) - Vector2.new(stem.Position.X, stem.Position.Z)).Magnitude
				< 0.05
			then
				head = h
				break
			end
		end
		assert(head, "Flower head missing")
		local ray = workspace:Raycast(stem.Position + Vector3.new(0, 5, 0), Vector3.new(0, -12, 0), params)
		local base =
			Vector3.new(stem.Position.X, ray and ray.Position.Y or stem.Position.Y - stem.Size.Y / 2, stem.Position.Z)
		local flower = Instance.new("Model")
		flower.Name = "Flower"
		flower.Parent = group
		local height = 1.55 + (i % 3) * 0.12
		local green = Color3.fromRGB(47, 154, 55)
		part(flower, "Stem", Vector3.new(0.2, height, 0.2), CFrame.new(base + Vector3.new(0, height / 2, 0)), green)
		for leaf = 1, 2 do
			local side = leaf == 1 and -1 or 1
			part(
				flower,
				"Leaf",
				Vector3.new(0.82, 0.17, 0.4),
				CFrame.new(base + Vector3.new(side * 0.37, 0.55 + leaf * 0.2, 0))
					* CFrame.Angles(0, math.rad(side * 25), math.rad(side * 24)),
				Color3.fromRGB(74, 186, 65)
			)
		end
		for petal = 1, 5 do
			local angle = petal * math.pi * 2 / 5
			local offset = Vector3.new(math.cos(angle) * 0.38, height, math.sin(angle) * 0.38)
			part(
				flower,
				"Petal",
				Vector3.new(0.22, 0.85, 0.85),
				CFrame.new(base + offset) * CFrame.Angles(0, 0, math.pi / 2),
				head.Color,
				Enum.PartType.Cylinder
			)
		end
		part(
			flower,
			"Center",
			Vector3.new(0.26, 0.6, 0.6),
			CFrame.new(base + Vector3.new(0, height + 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(255, 218, 66),
			Enum.PartType.Cylinder
		)
		flower.WorldPivot = CFrame.new(base)
		stem.Parent = backup
		head.Parent = backup
	end
	group.WorldPivot = map.Lobby.ThrowingApron.CFrame
	group.Parent = world
	group:SetAttribute("FlowerCount", #stems)
	return #stems
end
return Flowers
