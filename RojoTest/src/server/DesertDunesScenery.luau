--!strict
local Desert = {}
function Desert.apply(map)
	local world = map.SkippingWorld
	if world:FindFirstChild("DesertArchaeology") then
		return
	end
	local left, right, upper, lower = math.huge, -math.huge, nil, nil
	for _, p in ipairs(world:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "BiomeBank2_2" then
			left = math.min(left, p.Position.X - p.Size.X / 2)
			right = math.max(right, p.Position.X + p.Size.X / 2)
			upper = p
		end
		if p:IsA("BasePart") and p.Name == "BiomeBank2_1" then
			lower = p
		end
	end
	assert(upper and lower, "Visible desert banks missing")
	local ymin = upper.Position.Y + upper.Size.Y / 2
	local lowY = lower.Position.Y + lower.Size.Y / 2
	local front = upper.Position.Z + upper.Size.Z / 2
	local back = upper.Position.Z - upper.Size.Z / 2
	local root = Instance.new("Model")
	root.Name = "DesertArchaeology"
	local parent = root
	local sand = Color3.fromRGB(215, 175, 91)
	local pale = Color3.fromRGB(235, 202, 136)
	local ochre = Color3.fromRGB(193, 145, 66)
	local wood = Color3.fromRGB(123, 78, 42)
	local clay = Color3.fromRGB(178, 109, 56)
	local green = Color3.fromRGB(63, 159, 64)
	local function part(name, size, cf, color, studs, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
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
	local function box(name, size, pos, color, studs, rotation)
		return part(name, size, CFrame.new(pos) * (rotation or CFrame.identity), color, studs)
	end
	local function bar(name, a, b, width, color)
		return part(name, Vector3.new(width, width, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color, false)
	end
	local function cylinder(name, pos, height, diameter, color)
		return part(
			name,
			Vector3.new(height, diameter, diameter),
			CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2),
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
	local function pot(pos, s)
		cylinder("ClayPotBase", pos + Vector3.new(0, 0.25 * s, 0), 0.5 * s, 1.1 * s, clay)
		cylinder("ClayPotBody", pos + Vector3.new(0, 0.95 * s, 0), 1.2 * s, 1.75 * s, clay)
		cylinder("ClayPotNeck", pos + Vector3.new(0, 1.65 * s, 0), 0.4 * s, 1.2 * s, clay)
		cylinder("ClayPotOpening", pos + Vector3.new(0, 1.86 * s, 0), 0.06 * s, 0.85 * s, Color3.fromRGB(76, 47, 27))
	end
	-- The landmark sits on the screen-left bank when looking toward Palm Beach.
	local archPos = Vector3.new(right - 12, ymin, front - 66)
	local ruins = begin("SandstoneArchRuins")
	for _, side in ipairs({ -1, 1 }) do
		for j = 0, 3 do
			box(
				"ArchMasonry",
				Vector3.new(4.6, 3.0, 4.0),
				archPos + Vector3.new(j % 2 * 0.18, 1.5 + j * 3, side * 6.5),
				j % 2 == 0 and sand or pale,
				true
			)
		end
		box("ArchShoulder", Vector3.new(4.8, 2.9, 4.6), archPos + Vector3.new(0, 12.1, side * 5.1), ochre, true)
	end
	for i = -1, 1 do
		box(
			"ArchCrown",
			Vector3.new(5.0, 3.1, 4.1),
			archPos + Vector3.new(0, 14.1, i * 3.6),
			i == 0 and pale or sand,
			true
		)
	end
	local turn = CFrame.new(archPos) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(-archPos)
	for _, p in ipairs(ruins:GetChildren()) do
		p.CFrame = turn * p.CFrame
	end
	for i = 1, 3 do
		local pos = archPos + Vector3.new((i % 2 == 0 and 3 or -2), 0, -13 - i * 2.4)
		box(
			"RuinFragment",
			Vector3.new(2.8, 1.2 + i % 2, 2.4),
			pos + Vector3.new(0, 0.6 + i % 2 * 0.5, 0),
			i % 2 == 0 and pale or ochre,
			true,
			CFrame.Angles(0, i * 0.4, 0)
		)
	end
	pot(archPos + Vector3.new(-1, 0, 0), 1.3)
	pot(archPos + Vector3.new(-3.2, 0, 10.5), 0.8)
	for i, pos in ipairs({ archPos + Vector3.new(0, 0, -15), archPos + Vector3.new(4.0, 0, -22) }) do
		cylinder("BrokenColumnFoot", pos + Vector3.new(0, 0.3, 0), 0.6, 3.4, pale)
		cylinder("BrokenColumn", pos + Vector3.new(0, 2.3, 0), 3.5 + i, 2.5, sand)
		cylinder("ColumnCap", pos + Vector3.new(0, 4.1 + i * 0.5, 0), 0.4, 3, pale)
	end
	finish(ruins, archPos)
	local campPos = Vector3.new(left + 12, ymin, front - 72)
	local camp = begin("ArchaeologistTent")
	local canvas = Color3.fromRGB(241, 224, 180)
	for _, side in ipairs({ -1, 1 }) do
		box(
			"CanvasRoof",
			Vector3.new(17.5, 0.22, 11.4),
			campPos + Vector3.new(0, 5.4, side * 3.5),
			canvas,
			false,
			CFrame.Angles(math.rad(side * 51), 0, 0)
		)
		bar("CanvasEdge", campPos + Vector3.new(-9, 1, side * 7), campPos + Vector3.new(9, 1, side * 7), 0.15, wood)
	end
	bar("TentRidge", campPos + Vector3.new(-10, 9.8, 0), campPos + Vector3.new(10, 9.8, 0), 0.3, wood)
	for _, x in ipairs({ -8.4, 8.4 }) do
		bar("TentPole", campPos + Vector3.new(x, 0, 0), campPos + Vector3.new(x, 10.1, 0), 0.32, wood)
		for _, z in ipairs({ -1, 1 }) do
			bar(
				"GuyRope",
				campPos + Vector3.new(x, 9.4, 0),
				campPos + Vector3.new(x + 0.4, 0.2, z * 9.2),
				0.07,
				Color3.fromRGB(193, 164, 111)
			)
			box("TentPeg", Vector3.new(0.3, 0.65, 0.3), campPos + Vector3.new(x + 0.4, 0.33, z * 9.2), wood)
		end
	end
	box(
		"TentBedroll",
		Vector3.new(5.4, 0.25, 2.8),
		campPos + Vector3.new(-3, 0.2, 0),
		Color3.fromRGB(159, 134, 89),
		true
	)
	local lampPos = campPos + Vector3.new(8, 0, -9)
	box("LanternFoot", Vector3.new(1.6, 0.25, 1.6), lampPos + Vector3.new(0, 0.13, 0), wood)
	box("LanternBody", Vector3.new(1.1, 2, 1.1), lampPos + Vector3.new(0, 1.2, 0), wood)
	local glow = box(
		"LanternGlow",
		Vector3.new(1.18, 1.25, 0.85),
		lampPos + Vector3.new(0, 1.2, 0),
		Color3.fromRGB(255, 217, 137)
	)
	glow.Material = Enum.Material.Neon
	box("LanternRoof", Vector3.new(1.7, 0.25, 1.7), lampPos + Vector3.new(0, 2.35, 0), wood)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 209, 135)
	light.Brightness = 0.8
	light.Range = 13
	light.Shadows = false
	light.Parent = glow
	box("SupplyCrate", Vector3.new(2.9, 2.9, 2.9), campPos + Vector3.new(-3, 1.45, 12), wood, true)
	for _, z in ipairs({ 11, 13 }) do
		box("CrateBand", Vector3.new(3.0, 3.05, 0.2), campPos + Vector3.new(-3, 1.5, z), ochre)
	end
	pot(campPos + Vector3.new(2, 0, 12), 0.8)
	finish(camp, campPos)
	local workPos = Vector3.new(left + 12, ymin, front - 101)
	local work = begin("ArchaeologyWorktable")
	for _, x in ipairs({ -3, 3 }) do
		for _, z in ipairs({ -1.5, 1.5 }) do
			box("TableLeg", Vector3.new(0.45, 2.8, 0.45), workPos + Vector3.new(x, 1.4, z), wood)
		end
	end
	box("TableTop", Vector3.new(7.4, 0.4, 4.4), workPos + Vector3.new(0, 3.0, 0), wood, true)
	box("UnrolledMap", Vector3.new(3.2, 0.05, 2.7), workPos + Vector3.new(0.7, 3.23, 0), canvas)
	for i = 1, 4 do
		box(
			"MapMark",
			Vector3.new(0.16, 0.03, 0.6),
			workPos + Vector3.new(i * 0.5 - 0.7, 3.27, math.sin(i) * 0.6),
			ochre,
			false,
			CFrame.Angles(0, i * 0.5, 0)
		)
	end
	cylinder("RolledScroll", workPos + Vector3.new(-2.4, 3.48, 0), 1.5, 0.48, canvas).CFrame = CFrame.new(
		workPos + Vector3.new(-2.4, 3.48, 0)
	) * CFrame.Angles(0, 0, math.pi / 2)
	finish(work, workPos)
	local digPos = Vector3.new(left + 19, ymin, front - 126)
	local dig = begin("TabletExcavation")
	box("ExcavatedSand", Vector3.new(9.2, 0.06, 10.5), digPos + Vector3.new(0, 0.04, 0), ochre, true)
	for _, x in ipairs({ -4.6, 4.6 }) do
		box("DigFrame", Vector3.new(0.5, 0.6, 11.2), digPos + Vector3.new(x, 0.3, 0), wood)
	end
	for _, z in ipairs({ -5.4, 5.4 }) do
		box("DigFrame", Vector3.new(9.6, 0.6, 0.5), digPos + Vector3.new(0, 0.3, z), wood)
	end
	box(
		"AncientTablet",
		Vector3.new(4.5, 0.25, 5.5),
		digPos + Vector3.new(0, 0.23, -0.7),
		pale,
		true,
		CFrame.Angles(0, 0.12, 0)
	)
	for i = 1, 6 do
		box(
			"TabletGlyph",
			Vector3.new(i % 2 == 0 and 0.7 or 0.24, 0.08, 0.75),
			digPos + Vector3.new(i % 3 * 1.0 - 1.1, 0.4, math.floor((i - 1) / 3) * 1.7 - 1.7),
			sand
		)
	end
	for i = 1, 4 do
		box(
			"DigSandPile",
			Vector3.new(1.7, 0.6, 1.8),
			digPos + Vector3.new(i % 2 == 0 and 4.8 or -4.8, 0.3, i * 2.2 - 5),
			pale,
			true
		)
	end
	finish(dig, digPos)
	dig:ScaleTo(0.8)
	root.WorldPivot = CFrame.new((left + right) / 2, ymin, (front + back) / 2)
	root.Parent = world
	task.wait()
	local function cactus(pos, h, _variant)
		local m = begin("SaguaroCluster")
		box("CactusTrunk", Vector3.new(1.55, h, 1.55), pos + Vector3.new(0, h / 2, 0), green, true)
		for _, s in ipairs({ -1, 1 }) do
			local a = h * (s < 0 and 0.43 or 0.62)
			box("CactusArm", Vector3.new(2.4, 1.05, 1.05), pos + Vector3.new(s * 1.6, a, 0), green, true)
			box(
				"CactusTip",
				Vector3.new(1.05, h * 0.28, 1.05),
				pos + Vector3.new(s * 2.2, a + h * 0.14, 0),
				Color3.fromRGB(81, 174, 67),
				true
			)
		end
		box(
			"YoungCactus",
			Vector3.new(1, h * 0.4, 1),
			pos + Vector3.new(2.5, h * 0.2, 2.0),
			Color3.fromRGB(102, 179, 70),
			true
		)
		finish(m, pos)
	end
	local function planting(pos, index)
		local m = begin("DesertPlantPocket")
		for i = 1, 5 do
			local a = i * math.pi * 2 / 5 + index * 0.5
			box(
				"AloeLeaf",
				Vector3.new(0.5, 0.25, 2.6),
				pos + Vector3.new(math.cos(a) * 0.55, 0.85, math.sin(a) * 0.55),
				i % 2 == 0 and Color3.fromRGB(63, 137, 97) or Color3.fromRGB(101, 164, 103),
				true,
				CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-47), 0, 0)
			)
		end
		for i = 1, 5 do
			box(
				"DryGrass",
				Vector3.new(0.12, 1.2 + i % 3 * 0.3, 0.24),
				pos + Vector3.new(2.0 + i * 0.12, 0.7, 0.5),
				i % 2 == 0 and pale or sand,
				false,
				CFrame.Angles(0, i * 0.5, math.rad((i - 3) * 13))
			)
		end
		if index % 3 == 0 then
			local c = pos + Vector3.new(-1.1, 0.9, 0.8)
			box("FlowerStem", Vector3.new(0.1, 0.9, 0.1), c - Vector3.new(0, 0.45, 0), green)
			for i = 1, 5 do
				local a = i * math.pi * 2 / 5
				part(
					"DesertPetal",
					Vector3.new(0.14, 0.65, 0.65),
					CFrame.new(c + Vector3.new(math.cos(a) * 0.28, 0, math.sin(a) * 0.28))
						* CFrame.Angles(0, 0, math.pi / 2),
					index % 2 == 0 and Color3.fromRGB(255, 248, 214) or Color3.fromRGB(255, 210, 68),
					false,
					Enum.PartType.Cylinder
				)
			end
			cylinder("FlowerHeart", c + Vector3.new(0, 0.1, 0), 0.17, 0.3, Color3.fromRGB(249, 189, 44))
		end
		finish(m, pos)
	end
	local index = 0
	for _, side in ipairs({ -1, 1 }) do
		for _i, t in ipairs({ 16, 45, 85, 121, 158 }) do
			local x = side < 0 and left + 34 or right - 34
			index += 1
			planting(Vector3.new(x, lowY, front - t), index)
		end
		for _i, t in ipairs({ 18, 35, 112, 165 }) do
			local x = side < 0 and left + 5 or right - 5
			index += 1
			planting(Vector3.new(x, ymin, front - t), index)
		end
		for i, t in ipairs({ 23, 118, 164 }) do
			cactus(Vector3.new(side < 0 and left + 6 or right - 6, ymin, front - t), 5.5 + i * 1.0, i)
		end
		task.wait()
	end
	for _, p in ipairs({
		archPos + Vector3.new(-4, 0, -10),
		archPos + Vector3.new(3, 0, 10),
		campPos + Vector3.new(0, 0, -12),
		digPos + Vector3.new(0, 0, 8),
	}) do
		index += 1
		planting(p, index)
	end
	root:SetAttribute("Version", 1)
	return root
end
return Desert
