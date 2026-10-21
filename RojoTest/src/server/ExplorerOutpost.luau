--!strict
local Outpost = {}
function Outpost.apply(map)
	local tunnel = map.SpawnGardenPolish.EntranceTunnel
	if tunnel:FindFirstChild("ExplorerOutpost") then
		return
	end
	local group = Instance.new("Model")
	group.Name = "ExplorerOutpost"
	local offset = map.Lobby.ThrowingApron.Position - Vector3.new(24.240257, 20.3, 115.847107)
	local wood = Color3.fromRGB(112, 67, 42)
	local dark = Color3.fromRGB(64, 40, 30)
	local gold = Color3.fromRGB(219, 170, 66)
	local function part(name, size, pos, color, rotation, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(pos + offset) * (rotation or CFrame.identity)
		p.Color = color
		p.Anchored = true
		p.Material = Enum.Material.Plastic
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		p.Parent = group
		return p
	end
	local function bar(name, a, b, width, color)
		return part(
			name,
			Vector3.new(width, width, (b - a).Magnitude),
			(a + b) / 2,
			color,
			CFrame.lookAt(a, b).Rotation
		)
	end
	-- A readable silhouette on the right bank, outside the watercourse.
	for _, x in ipairs({ 108, 122 }) do
		part("MapPost", Vector3.new(0.9, 14, 0.9), Vector3.new(x, 36, 83), wood)
	end
	local board = part("MapBoard", Vector3.new(15.6, 10, 0.7), Vector3.new(115, 38, 83), Color3.fromRGB(220, 187, 119))
	for _, y in ipairs({ 32.7, 43.3 }) do
		part("MapFrame", Vector3.new(17, 0.7, 1), Vector3.new(115, y, 83), wood)
	end
	for _, x in ipairs({ 106.8, 123.2 }) do
		part("MapFrame", Vector3.new(0.7, 11.3, 1), Vector3.new(x, 38, 83), wood)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BiomeMap"
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(640, 400)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 1
	gui.Parent = board
	local function shape(name, pos, size, color, rotation)
		local f = Instance.new("Frame")
		f.Name = name
		f.Position = UDim2.fromScale(pos.X, pos.Y)
		f.Size = UDim2.fromScale(size.X, size.Y)
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Rotation = rotation or 0
		f.Parent = gui
		return f
	end
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.16)
	title.Text = "RIVER EXPEDITION"
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = dark
	title.Parent = gui
	for i = 0, 5 do
		shape(
			"River",
			Vector2.new(0.46 + math.sin(i) * 0.07, 0.21 + i * 0.11),
			Vector2.new(0.065, 0.15),
			Color3.fromRGB(48, 173, 214),
			math.sin(i + 1) * 23
		)
	end
	local colors = {
		Color3.fromRGB(65, 155, 67),
		Color3.fromRGB(225, 175, 82),
		Color3.fromRGB(126, 211, 229),
		Color3.fromRGB(235, 139, 192),
		Color3.fromRGB(152, 114, 211),
		Color3.fromRGB(85, 173, 94),
	}
	for i, c in ipairs(colors) do
		local x = i % 2 == 0 and 0.73 or 0.16
		local y = 0.22 + math.floor((i - 1) / 2) * 0.23
		shape("BiomeSymbol", Vector2.new(x, y), Vector2.new(0.11, 0.14), c, 45)
		shape("MapTrail", Vector2.new(x - 0.025, y + 0.19), Vector2.new(0.17, 0.018), Color3.fromRGB(139, 106, 67))
	end
	-- Supply chest with bands and a latch.
	part("SupplyChest", Vector3.new(5.3, 3.0, 3.4), Vector3.new(109, 30.5, 92), wood)
	part("ChestLid", Vector3.new(5.5, 0.55, 3.6), Vector3.new(109, 32.275, 92), Color3.fromRGB(140, 85, 48))
	for _, x in ipairs({ 107.4, 110.6 }) do
		part("ChestBand", Vector3.new(0.3, 3.6, 3.7), Vector3.new(x, 30.8, 92), dark)
	end
	part("ChestLatch", Vector3.new(0.7, 0.9, 0.18), Vector3.new(109, 31.25, 93.85), gold)
	-- Brass telescope points downriver; it is a decorative prop.
	local top = Vector3.new(105, 35, 87)
	for i = 1, 3 do
		local a = i * math.pi * 2 / 3
		bar("TelescopeTripod", Vector3.new(105 + math.cos(a) * 2.1, 29.1, 87 + math.sin(a) * 2.1), top, 0.35, wood)
	end
	local axis = Vector3.new(-0.15, 0.22, -1).Unit
	local a, b = top - axis * 1.8, top + axis * 3.5
	bar("TelescopeBody", a, b, 1.15, gold)
	bar("TelescopeLens", b, b + axis * 0.4, 1.4, dark)
	bar("TelescopeGlass", b + axis * 0.42, b + axis * 0.45, 0.95, Color3.fromRGB(91, 201, 221))
	for _, z in ipairs({ 71, 99 }) do
		for _, x in ipairs({ 110, 122 }) do
			part("RailPost", Vector3.new(0.7, 3.4, 0.7), Vector3.new(x, 30.7, z), wood)
		end
		part("RailBeam", Vector3.new(13, 0.55, 0.6), Vector3.new(116, 31.5, z), wood)
	end
	-- Small wind chime on the opposite wall.
	part("ChimeWallBracket", Vector3.new(4.5, 0.6, 0.7), Vector3.new(-71.5, 60, 98), wood)
	bar("ChimeBrace", Vector3.new(-73.5, 57, 98), Vector3.new(-69.5, 60, 98), 0.4, wood)
	part("ChimeCord", Vector3.new(0.08, 2.8, 0.08), Vector3.new(-69.6, 58.4, 98), dark)
	part("ChimeCap", Vector3.new(2.5, 0.35, 1.1), Vector3.new(-69.6, 56.9, 98), wood)
	for i = 1, 4 do
		part("ChimeTube", Vector3.new(0.2, 3.3 + i % 2 * 0.7, 0.2), Vector3.new(-71.1 + i * 0.6, 54.7, 98), gold)
	end
	part(
		"ChimeCharm",
		Vector3.new(0.8, 1.3, 0.15),
		Vector3.new(-69.6, 51.5, 98),
		Color3.fromRGB(245, 184, 102),
		CFrame.Angles(0, 0, math.pi / 4)
	)
	-- Local lighting only; the map's daylight settings stay intact.
	for _, x in ipairs({ -40, 23, 86 }) do
		part("CeilingLampHousing", Vector3.new(5.5, 0.35, 3.5), Vector3.new(x, 76.8, 84), dark)
		local lamp =
			part("CeilingLamp", Vector3.new(4.4, 0.12, 2.5), Vector3.new(x, 76.56, 84), Color3.fromRGB(255, 222, 157))
		lamp.Material = Enum.Material.Neon
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Color = Color3.fromRGB(255, 218, 169)
		light.Brightness = 1.7
		light.Range = 55
		light.Angle = 115
		light.Shadows = false
		light.Parent = lamp
	end
	for _, x in ipairs({ -73, 123 }) do
		local p = part("WallWashMount", Vector3.new(0.15, 0.15, 0.15), Vector3.new(x, 45, 87), wood)
		p.Transparency = 1
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 211, 150)
		light.Brightness = 0.8
		light.Range = 35
		light.Shadows = false
		light.Parent = p
	end
	-- Keep the board in front of the existing stone outcrop.
	for _, p in ipairs(group:GetChildren()) do
		if p:IsA("BasePart") then
			if p.Name == "MapPost" or p.Name == "MapBoard" or p.Name == "MapFrame" then
				p.CFrame += Vector3.new(0, 0, 17)
			elseif p.Name:find("Chest") then
				p.CFrame += Vector3.new(0, 0, 10)
			end
		end
	end
	group.WorldPivot = CFrame.new(Vector3.new(23.24, 29, 84) + offset)
	group:SetAttribute("Version", 1)
	group.Parent = tunnel
	return #group:GetChildren()
end
return Outpost
