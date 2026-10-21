--!strict
local Violet = {}
function Violet.apply(map)
	local world = map.SkippingWorld
	if world:FindFirstChild("CrystalObservatory") then
		return
	end
	local left, right, upper, lower = math.huge, -math.huge, nil, nil
	for _, p in ipairs(world:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "BiomeBank4_2" then
			left = math.min(left, p.Position.X - p.Size.X / 2)
			right = math.max(right, p.Position.X + p.Size.X / 2)
			upper = p
		end
		if p:IsA("BasePart") and p.Name == "BiomeBank4_1" then
			lower = p
		end
	end
	assert(upper and lower, "Violet banks missing")
	local high = upper.Position.Y + upper.Size.Y / 2
	local low = lower.Position.Y + lower.Size.Y / 2
	local front = upper.Position.Z + upper.Size.Z / 2
	local back = upper.Position.Z - upper.Size.Z / 2
	local template
	for _, p in ipairs(game.ServerStorage.ImportedPortalVisuals.RoseBlossom:GetChildren()) do
		if p:IsA("MeshPart") and p.Name:find("Large foot crystal") then
			template = p
			break
		end
	end
	assert(template, "Faceted crystal template missing")
	local backups = game.ServerStorage.WorldBackups
	local old = backups:FindFirstChild("BeforeVioletCrystalReplacement")
	if not old then
		old = Instance.new("Folder")
		old.Name = "BeforeVioletCrystalReplacement"
		old.Parent = backups
	end
	local candidates = world:GetChildren()
	for _, p in ipairs(map.NativeEnvironment:GetDescendants()) do
		if p:IsA("BasePart") and p.Name == "CrystalPeak" then
			table.insert(candidates, p)
		end
	end
	for _, p in ipairs(candidates) do
		if
			p:IsA("BasePart")
			and p.Transparency < 1
			and ((p.Name == "BiomeDecorStem" or p.Name == "CrystalSatellite") and p.Material == Enum.Material.Neon or p.Name == "CrystalPeak")
			and p.Position.Z > back
			and p.Position.Z < front
		then
			p:Clone().Parent = old
			p.Transparency = 1
			p:SetAttribute("VioletCrystalHidden", true)
		end
	end
	local root = Instance.new("Model")
	root.Name = "CrystalObservatory"
	local parent = root
	local stone = Color3.fromRGB(130, 116, 169)
	local dark = Color3.fromRGB(91, 77, 134)
	local purple = Color3.fromRGB(178, 107, 235)
	local pink = Color3.fromRGB(224, 162, 244)
	local cyan = Color3.fromRGB(104, 209, 229)
	local function part(name, size, cf, color, studs, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		if studs then
			local t = Instance.new("Texture")
			t.Texture = "rbxassetid://88156646156237"
			t.Face = Enum.NormalId.Top
			t.StudsPerTileU = 8
			t.StudsPerTileV = 8
			t.Parent = p
		end
		p.Parent = parent
		return p
	end
	local function box(name, size, pos, color, studs, rot)
		return part(name, size, CFrame.new(pos) * (rot or CFrame.identity), color, studs)
	end
	local function bar(name, a, b, w, color)
		return part(name, Vector3.new(w, w, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
	end
	local function tube(name, a, b, w, color)
		return part(
			name,
			Vector3.new((a - b).Magnitude, w, w),
			CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0),
			color,
			false,
			Enum.PartType.Cylinder
		)
	end
	local function begin(name)
		local m = Instance.new("Model")
		m.Name = name
		parent = m
		return m
	end
	local function finish(m, pos)
		m.WorldPivot = CFrame.new(pos)
		m.Parent = root
		parent = root
	end
	local function crystal(pos, h, w, color, yaw, glow)
		local p = template:Clone()
		p.Name = "FacetedAmethyst"
		p.Size = Vector3.new(w, h, w * 0.8)
		p.CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, yaw or 0, 0)
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Transparency = 0
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		for _, v in ipairs(p:GetChildren()) do
			if v:IsA("Texture") or v:IsA("SurfaceAppearance") then
				v:Destroy()
			end
		end
		p.Parent = parent
		if glow then
			local l = Instance.new("PointLight")
			l.Color = color
			l.Brightness = 0.3
			l.Range = 11
			l.Shadows = false
			l.Parent = p
		end
		return p
	end
	local function plants(pos, index, s)
		s = s or 1
		for i = 1, 6 do
			local a = i * math.pi / 3 + index * 0.27
			box(
				"LavenderLeaf",
				Vector3.new(0.5 * s, 0.2 * s, 2.8 * s),
				pos + Vector3.new(math.cos(a) * 0.7 * s, 0.7 * s, math.sin(a) * 0.7 * s),
				i % 2 == 0 and pink or stone,
				true,
				CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-35), 0, 0)
			)
		end
		for j = 1, 2 do
			local c = pos + Vector3.new(j == 1 and -1.1 * s or 1.2 * s, 1.0 * s, j % 2 * s)
			box(
				"FlowerStem",
				Vector3.new(0.1, 0.8 * s, 0.1),
				c - Vector3.new(0, 0.4 * s, 0),
				Color3.fromRGB(111, 138, 156)
			)
			for k = 1, 5 do
				local a = k * math.pi * 2 / 5
				part(
					"FlowerPetal",
					Vector3.new(0.14 * s, 0.7 * s, 0.7 * s),
					CFrame.new(c + Vector3.new(math.cos(a) * 0.33 * s, 0, math.sin(a) * 0.33 * s))
						* CFrame.Angles(0, 0, math.pi / 2),
					j == 1 and Color3.fromRGB(251, 236, 255) or pink,
					false,
					Enum.PartType.Cylinder
				)
			end
			part(
				"FlowerCenter",
				Vector3.new(0.18 * s, 0.32 * s, 0.32 * s),
				CFrame.new(c + Vector3.new(0, 0.1 * s, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				cyan,
				false,
				Enum.PartType.Cylinder
			)
		end
	end
	local archPos = Vector3.new(right - 12, high, front - 63)
	local arch = begin("AmethystStoneArch")
	for _, side in ipairs({ -1, 1 }) do
		for j = 0, 2 do
			box(
				"ArchColumn",
				Vector3.new(3.2, 2.5, 4),
				archPos + Vector3.new(side * 7, 1.25 + j * 2.5, 0),
				j % 2 == 0 and stone or stone:Lerp(dark, 0.2),
				true
			)
		end
	end
	for i = 0, 8 do
		local a = i * math.pi / 8
		box(
			"ArchVoussoir",
			Vector3.new(2.9, 3.0, 4),
			archPos + Vector3.new(math.cos(a) * 7, 7.5 + math.sin(a) * 7, 0),
			i % 2 == 0 and stone or Color3.fromRGB(144, 127, 182),
			true,
			CFrame.Angles(0, 0, a - math.pi / 2)
		)
	end
	box("CrystalPlinth", Vector3.new(4.2, 1.2, 4.2), archPos + Vector3.new(0, 0.6, 0), dark, true)
	crystal(archPos + Vector3.new(0, 1.2, 0), 7.4, 2.9, purple, 0.2, true)
	plants(archPos + Vector3.new(7.9, 0, -3.0), 2, 1.1)
	finish(arch, archPos)
	local stationPos = Vector3.new(left + 12, high, front - 105)
	local station = begin("VioletObservationDais")
	part(
		"LowDais",
		Vector3.new(0.22, 14, 14),
		CFrame.new(stationPos + Vector3.new(0, 0.11, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		stone,
		false,
		Enum.PartType.Cylinder
	)
	for i = 0, 9 do
		local a = i * math.pi / 5
		box(
			"DaisRimStone",
			Vector3.new(2.2, 0.4, 2.1),
			stationPos + Vector3.new(math.cos(a) * 6.1, 0.2, math.sin(a) * 6.1),
			stone,
			true,
			CFrame.Angles(0, -a, 0)
		)
	end
	local top = stationPos + Vector3.new(1, 4.7, 0)
	for i = 1, 3 do
		local a = i * math.pi * 2 / 3
		bar(
			"TelescopeTripod",
			stationPos + Vector3.new(1 + math.cos(a) * 1.9, 0.3, math.sin(a) * 1.9),
			top,
			0.28,
			Color3.fromRGB(174, 130, 71)
		)
	end
	local direction = Vector3.new(0.2, 0.32, -1).Unit
	local a, b = top - direction * 2.3, top + direction * 3.0
	tube("PurpleTelescope", a, b, 1.05, dark)
	tube("BrassEyepiece", a - direction * 0.5, a, 0.6, Color3.fromRGB(218, 174, 88))
	for _, t in ipairs({ 0.12, 0.85 }) do
		local c = a:Lerp(b, t)
		tube("BrassTelescopeRing", c - direction * 0.13, c + direction * 0.13, 1.13, Color3.fromRGB(225, 179, 86))
	end
	tube("TelescopeLens", b, b + direction * 0.15, 0.9, cyan)
	box("ChartPedestal", Vector3.new(1.8, 3, 1.8), stationPos + Vector3.new(-4, 1.6, 1.8), dark, true)
	local board = box(
		"StarChart",
		Vector3.new(4.3, 4.4, 0.4),
		stationPos + Vector3.new(-4, 4.7, 1.8),
		dark,
		true,
		CFrame.Angles(0, math.rad(-60), 0) * CFrame.Angles(math.rad(-12), 0, 0)
	)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Constellation"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(400, 400)
	gui.LightInfluence = 1
	gui.AlwaysOnTop = false
	gui.Parent = board
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(0.86, 0.86)
	bg.Position = UDim2.fromScale(0.07, 0.07)
	bg.BackgroundColor3 = Color3.fromRGB(55, 40, 113)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local points = {
		Vector2.new(0.2, 0.25),
		Vector2.new(0.5, 0.16),
		Vector2.new(0.77, 0.38),
		Vector2.new(0.57, 0.67),
		Vector2.new(0.3, 0.77),
	}
	for i, pos in ipairs(points) do
		local star = Instance.new("Frame")
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.Size = UDim2.fromOffset(9, 9)
		star.Position = UDim2.fromScale(pos.X, pos.Y)
		star.Rotation = 45
		star.BackgroundColor3 = Color3.fromRGB(227, 229, 255)
		star.BorderSizePixel = 0
		star.ZIndex = 2
		star.Parent = bg
		if i > 1 then
			local from = points[i - 1]
			local delta = pos - from
			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.Position = UDim2.fromScale((from.X + pos.X) / 2, (from.Y + pos.Y) / 2)
			line.Size = UDim2.fromScale(delta.Magnitude, 0.006)
			line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			line.BackgroundColor3 = Color3.fromRGB(145, 154, 220)
			line.BorderSizePixel = 0
			line.Parent = bg
		end
	end
	finish(station, stationPos)
	root.WorldPivot = CFrame.new((left + right) / 2, high, (front + back) / 2)
	root.Parent = world
	task.wait()
	local index = 0
	local function garden(pos, scale)
		index += 1
		local m = begin("CrystalGarden")
		for j = 1, 4 do
			local angle = j * math.pi / 2 + index
			box(
				"GeodeRock",
				Vector3.new(2.5 * scale, (1 + j % 2 * 0.6) * scale, 2.4 * scale),
				pos + Vector3.new(math.cos(angle) * 2 * scale, (0.5 + j % 2 * 0.3) * scale, math.sin(angle) * 2 * scale),
				stone,
				true,
				CFrame.Angles(0, angle, 0)
			)
		end
		crystal(pos, 7.6 * scale, 2.1 * scale, purple, index * 0.6, index % 3 == 0)
		crystal(pos + Vector3.new(2.1 * scale, 0, 1.5 * scale), 4.2 * scale, 1.5 * scale, cyan, -index * 0.8, false)
		crystal(pos + Vector3.new(-1.5 * scale, 0, -0.8 * scale), 3.5 * scale, 1.3 * scale, pink, index, false)
		plants(pos + Vector3.new(0, 0, -2.3 * scale), index, scale)
		finish(m, pos)
	end
	for _, side in ipairs({ -1, 1 }) do
		for _, t in ipairs({ 18, 38, 79, 142, 166 }) do
			garden(Vector3.new(side < 0 and left + 6 or right - 6, high, front - t), 1.3)
		end
		for _, t in ipairs({ 22, 51, 88, 124, 159 }) do
			garden(Vector3.new(side < 0 and left + 35 or right - 35, low, front - t), 0.65)
		end
		local path = begin("VioletSteppingPath")
		for i = 1, 6 do
			box(
				"PaleVioletSlab",
				Vector3.new(3.6, 0.08, 3.5),
				Vector3.new(side < 0 and left + 22 or right - 22, high + 0.05, front - 40 - i * 17),
				Color3.fromRGB(199, 185, 223),
				true
			)
		end
		finish(path, Vector3.new(side < 0 and left + 22 or right - 22, high, front - 100))
		task.wait()
	end
	root:SetAttribute("Version", 1)
	return root
end
return Violet
