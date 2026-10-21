--!strict
local Scenery = {}
function Scenery.apply(map)
	local zone = map.WaterCorridor:FindFirstChild("01_ЛУГА")
	assert(zone, "First biome missing")
	if zone:FindFirstChild("TropicalLanding") then
		return
	end
	local left, right, zmin, zmax = math.huge, -math.huge, math.huge, -math.huge
	local top, bottom = -math.huge, math.huge
	for _, p in ipairs(zone:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "GroundTile" then
			left = math.min(left, p.Position.X - p.Size.X / 2)
			right = math.max(right, p.Position.X + p.Size.X / 2)
			zmin = math.min(zmin, p.Position.Z - p.Size.Z / 2)
			zmax = math.max(zmax, p.Position.Z + p.Size.Z / 2)
			top = math.max(top, p.Position.Y + p.Size.Y / 2)
			bottom = math.min(bottom, p.Position.Y + p.Size.Y / 2)
		end
	end
	assert(math.abs(right - left - 208) < 1 and math.abs(zmax - zmin - 256) < 1, "Remeasure first biome")
	-- Visible biome overlays are shorter than the underlying legacy ground zone.
	local upper, lower
	for _, p in ipairs(map.SkippingWorld:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "BiomeBank1_2" then
			upper = p
		end
		if p:IsA("BasePart") and p.Name == "BiomeBank1_1" then
			lower = p
		end
	end
	assert(upper and lower, "Visible biome banks missing")
	zmin = upper.Position.Z - upper.Size.Z / 2
	zmax = upper.Position.Z + upper.Size.Z / 2
	top = upper.Position.Y + upper.Size.Y / 2
	bottom = lower.Position.Y + lower.Size.Y / 2
	local spacing = (zmax - zmin) / 256
	local root = Instance.new("Model")
	root.Name = "TropicalLanding"
	local parent = root
	local wood = Color3.fromRGB(143, 88, 44)
	local dark = Color3.fromRGB(91, 55, 32)
	local lightWood = Color3.fromRGB(185, 122, 64)
	local leaf = Color3.fromRGB(42, 153, 46)
	local lime = Color3.fromRGB(114, 199, 46)
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
	local function bar(name, a, b, width, color)
		return part(name, Vector3.new(width, width, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color, false)
	end
	local function model(name)
		local m = Instance.new("Model")
		m.Name = name
		parent = m
		return m
	end
	local function finish(m, pivot)
		m.WorldPivot = CFrame.new(pivot)
		m.Parent = root
		parent = root
	end
	local function lantern(pos)
		box("LanternFoot", Vector3.new(1.8, 0.25, 1.8), pos + Vector3.new(0, 0.125, 0), dark)
		box("LanternFrame", Vector3.new(1.35, 1.9, 1.35), pos + Vector3.new(0, 1.2, 0), dark)
		local glow = box(
			"LanternGlow",
			Vector3.new(1.42, 1.1, 1.05),
			pos + Vector3.new(0, 1.2, 0),
			Color3.fromRGB(255, 220, 145)
		)
		glow.Material = Enum.Material.Neon
		box("LanternCap", Vector3.new(1.8, 0.25, 1.8), pos + Vector3.new(0, 2.25, 0), dark)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 210, 130)
		l.Range = 13
		l.Brightness = 0.7
		l.Shadows = false
		l.Parent = glow
	end
	local function crate(pos, size)
		box("CrateBody", Vector3.new(size, size, size), pos + Vector3.new(0, size / 2, 0), wood, true)
		for _, x in ipairs({ -1, 1 }) do
			box(
				"CrateBrace",
				Vector3.new(0.2, size + 0.15, size + 0.15),
				pos + Vector3.new(x * size * 0.36, size / 2, 0),
				lightWood
			)
		end
		bar(
			"CrateCross",
			pos + Vector3.new(-size * 0.4, 0.2, size * 0.51),
			pos + Vector3.new(size * 0.4, size - 0.2, size * 0.51),
			0.23,
			dark
		)
	end
	local hutPos = Vector3.new(left + 9, top, zmin + 171 * spacing)
	local hut = model("PalmLeafHut")
	-- Hut front faces inward, with a ten-stud clear route along its front.
	local function hutBox(name, size, off, color, studs, rot)
		return box(name, size, hutPos + off, color, studs, rot)
	end
	for i = 0, 9 do
		hutBox("DeckPlank", Vector3.new(16, 0.35, 2.0), Vector3.new(1.5, 0.18, -9.2 + i * 2.05), lightWood, true)
	end
	for _, z in ipairs({ -9, 9 }) do
		for _, x in ipairs({ -5, 5 }) do
			hutBox("HutPost", Vector3.new(0.85, 10.6, 0.85), Vector3.new(x, 5.5, z), dark, true)
		end
	end
	for i = 0, 11 do
		hutBox(
			"BackWallPlank",
			Vector3.new(0.5, 8.5, 1.45),
			Vector3.new(-5.1, 4.7, -8.25 + i * 1.5),
			i % 3 == 0 and lightWood or wood,
			true
		)
	end
	for _, z in ipairs({ -9, 9 }) do
		for i = 0, 6 do
			hutBox("SideWallPlank", Vector3.new(1.4, 8.5, 0.5), Vector3.new(-4.2 + i * 1.4, 4.7, z), wood, true)
		end
		hutBox("RoofBeam", Vector3.new(14.3, 0.6, 0.75), Vector3.new(0, 10.8, z), dark)
	end
	hutBox("DoorLintel", Vector3.new(0.7, 1.1, 18.5), Vector3.new(5.2, 9.6, 0), wood, true)
	for _, z in ipairs({ -7.2, 7.2 }) do
		hutBox("DoorSide", Vector3.new(0.6, 8, 3.0), Vector3.new(5.2, 4.7, z), wood, true)
	end
	-- Broad overlapping palm fronds form the low hipped roof.
	for side = -1, 1, 2 do
		for i = 0, 7 do
			local z = -10.5 + i * 3.0
			hutBox(
				"RoofPalmLeaf",
				Vector3.new(6.6, 0.55, 3.35),
				Vector3.new(side * 3.1, 11.5, z),
				i % 3 == 0 and lime or leaf,
				true,
				CFrame.Angles(0, 0, math.rad(-side * 13))
			)
			hutBox(
				"PalmLeafTip",
				Vector3.new(2.2, 0.42, 2.7),
				Vector3.new(side * 6.6, 10.75, z),
				i % 3 == 0 and lime or leaf,
				true,
				CFrame.Angles(0, 0, math.rad(-side * 18))
			)
			hutBox(
				"PalmLeafPoint",
				Vector3.new(1.1, 0.3, 1.8),
				Vector3.new(side * 8.1, 10.3, z),
				i % 3 == 0 and lime or leaf,
				true,
				CFrame.Angles(0, 0, math.rad(-side * 18))
			)
		end
	end
	hutBox("RoofRidge", Vector3.new(2.3, 0.65, 24.4), Vector3.new(0, 12.6, 0), leaf, true)
	lantern(hutPos + Vector3.new(6.1, 5.5, 5.8))
	crate(hutPos + Vector3.new(2.8, 0.36, 12.5), 2.8)
	finish(hut, hutPos)
	local boatPos = Vector3.new(left + 10, top, zmin + 144 * spacing)
	local boat = model("BeachedRowboat")
	box("BoatFloor", Vector3.new(3.5, 0.45, 8.7), boatPos + Vector3.new(0, 0.4, 0), dark, true)
	for _, side in ipairs({ -1, 1 }) do
		box(
			"BoatSide",
			Vector3.new(0.6, 1.65, 8.5),
			boatPos + Vector3.new(side * 2.05, 1.0, 0),
			wood,
			true,
			CFrame.Angles(0, 0, math.rad(-side * 9))
		)
		for _, endSide in ipairs({ -1, 1 }) do
			bar(
				"BoatBow",
				boatPos + Vector3.new(side * 2, 1.1, endSide * 4),
				boatPos + Vector3.new(0, 1.1, endSide * 5.65),
				0.65,
				wood
			)
		end
	end
	for _, z in ipairs({ -2.3, 2.1 }) do
		box("BoatSeat", Vector3.new(3.7, 0.35, 1), boatPos + Vector3.new(0, 1.25, z), lightWood, true)
	end
	bar("OarHandle", boatPos + Vector3.new(4, 0.35, -5), boatPos + Vector3.new(3, 0.35, 3.5), 0.2, dark)
	box(
		"OarBlade",
		Vector3.new(0.85, 0.17, 2.3),
		boatPos + Vector3.new(4.12, 0.35, -5.65),
		lightWood,
		true,
		CFrame.Angles(0, -0.12, 0)
	)
	crate(boatPos + Vector3.new(-3.8, 0, -4), 2.6)
	crate(boatPos + Vector3.new(-4.0, 0, 0), 2.0)
	for i = 1, 12 do
		local a = i * math.pi * 2 / 12
		local b = (i + 1) * math.pi * 2 / 12
		bar(
			"RopeCoil",
			boatPos + Vector3.new(3.7 + math.cos(a), 0.3, 5 + math.sin(a)),
			boatPos + Vector3.new(3.7 + math.cos(b), 0.3, 5 + math.sin(b)),
			0.18,
			Color3.fromRGB(220, 196, 127)
		)
	end
	finish(boat, boatPos)
	local restPos = Vector3.new(right - 9, top, zmin + 158 * spacing)
	local shelter = model("PalmRestShelter")
	for _, x in ipairs({ -5, 5 }) do
		for _, z in ipairs({ -8, 8 }) do
			box("ShelterPost", Vector3.new(0.7, 9.2, 0.7), restPos + Vector3.new(x, 4.6, z), wood, true)
		end
	end
	for i = 0, 6 do
		for _, side in ipairs({ -1, 1 }) do
			box(
				"ShelterRoofLeaf",
				Vector3.new(7.8, 0.45, 3),
				restPos + Vector3.new(side * 3.0, 9.6, -9 + i * 3),
				i % 2 == 0 and leaf or lime,
				true,
				CFrame.Angles(0, 0, math.rad(-side * 9))
			)
		end
	end
	for _, z in ipairs({ -5.5, 5.5 }) do
		box("BenchSeat", Vector3.new(8.5, 0.45, 1.8), restPos + Vector3.new(0, 2.3, z), lightWood, true)
		for _, x in ipairs({ -3.2, 3.2 }) do
			box("BenchLeg", Vector3.new(0.55, 2.1, 1.3), restPos + Vector3.new(x, 1.05, z), dark)
		end
		box(
			"BenchBack",
			Vector3.new(8.5, 1.6, 0.4),
			restPos + Vector3.new(0, 3.45, z + (z < 0 and -0.65 or 0.65)),
			wood,
			true
		)
	end
	lantern(restPos + Vector3.new(-5, 4, 7.7))
	crate(restPos + Vector3.new(1.5, 0, 11.2), 2.5)
	local ring = restPos + Vector3.new(-5.3, 3.8, 10.5)
	box("LifebuoyPost", Vector3.new(0.5, 5.4, 0.5), restPos + Vector3.new(-5.3, 2.7, 10.8), dark)
	for i = 0, 11 do
		local a = i * math.pi / 6
		local b = (i + 1) * math.pi / 6
		bar(
			"Lifebuoy",
			ring + Vector3.new(math.cos(a) * 1.35, math.sin(a) * 1.35, 0),
			ring + Vector3.new(math.cos(b) * 1.35, math.sin(b) * 1.35, 0),
			0.5,
			i % 3 == 0 and Color3.fromRGB(255, 246, 221) or Color3.fromRGB(247, 126, 43)
		)
	end
	finish(shelter, restPos)
	root.WorldPivot = CFrame.new((left + right) / 2, top, (zmin + zmax) / 2)
	root.Parent = zone
	task.wait()
	local function plantPocket(pos, index, large)
		local m = model("TropicalPlanting")
		local s = large and 1.65 or 1.15
		for i = 1, 7 do
			local a = i * math.pi * 2 / 7 + index * 0.3
			local center = pos + Vector3.new(math.cos(a) * 1.25 * s, 0.55 * s, math.sin(a) * 1.25 * s)
			box(
				"BroadLeaf",
				Vector3.new(0.75 * s, 0.28 * s, 3.7 * s),
				center,
				i % 2 == 0 and leaf or lime,
				true,
				CFrame.Angles(0, -a + math.pi / 2, 0) * CFrame.Angles(math.rad(-18), 0, 0)
			)
		end
		for j = 1, 4 do
			local a = j * math.pi / 2 + index * 0.27
			box(
				"UprightLeaf",
				Vector3.new(0.85 * s, 0.27 * s, 3.3 * s),
				pos + Vector3.new(math.cos(a) * 0.5 * s, 1.25 * s, math.sin(a) * 0.5 * s),
				j % 2 == 0 and leaf or lime,
				true,
				CFrame.Angles(0, -a, 0) * CFrame.Angles(math.rad(-55), 0, 0)
			)
		end
		for j = 1, 3 do
			local x = (j - 2) * 1.25 * s
			local z = j % 2 * 1.2 * s
			local h = (0.9 + j % 2 * 0.35) * s
			local center = pos + Vector3.new(x, h, z)
			box("FlowerStem", Vector3.new(0.12, h, 0.12), pos + Vector3.new(x, h / 2, z), leaf)
			local color = j == 1 and Color3.fromRGB(255, 253, 223)
				or j == 2 and Color3.fromRGB(255, 207, 61)
				or Color3.fromRGB(255, 133, 135)
			for k = 1, 5 do
				local a = k * math.pi * 2 / 5
				part(
					"FlowerPetal",
					Vector3.new(0.16 * s, 0.8 * s, 0.8 * s),
					CFrame.new(center + Vector3.new(math.cos(a) * 0.38 * s, 0, math.sin(a) * 0.38 * s))
						* CFrame.Angles(0, 0, math.pi / 2),
					color,
					false,
					Enum.PartType.Cylinder
				)
			end
			part(
				"FlowerHeart",
				Vector3.new(0.22 * s, 0.4 * s, 0.4 * s),
				CFrame.new(center + Vector3.new(0, 0.11 * s, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				Color3.fromRGB(255, 224, 91),
				false,
				Enum.PartType.Cylinder
			)
		end
		finish(m, pos)
	end
	local index = 0
	-- Flowers group around the shoreline rocks, alternating with open lawn.
	for _, side in ipairs({ -1, 1 }) do
		for _, t in ipairs({ 20, 63, 106, 151, 199, 231 }) do
			index += 1
			plantPocket(Vector3.new(side < 0 and left + 35 or right - 35, bottom, zmin + t * spacing), index, false)
		end
		for _, t in ipairs({ 22, 62, 111, 204, 238 }) do
			index += 1
			plantPocket(Vector3.new(side < 0 and left + 4.5 or right - 4.5, top, zmin + t * spacing), index, true)
		end
		task.wait()
	end
	for _, pos in ipairs({
		hutPos + Vector3.new(-4, 0, -13),
		hutPos + Vector3.new(3, 0, 14),
		hutPos + Vector3.new(6, 0, -12),
		hutPos + Vector3.new(-4, 0, 12),
		boatPos + Vector3.new(4, 0, -8),
		boatPos + Vector3.new(-3, 0, 6),
		restPos + Vector3.new(1, 0, -11),
		restPos + Vector3.new(3, 0, 13),
		restPos + Vector3.new(-5, 0, -11),
	}) do
		index += 1
		plantPocket(pos, index, true)
	end
	for _, tree in ipairs(map.NativeEnvironment:GetDescendants()) do
		if tree:IsA("Model") and tree.Name == "RobloxPalm" then
			local c = tree:GetBoundingBox().Position
			if c.Z > zmin + 8 and c.Z < zmax - 8 and (c.X < left + 26 or c.X > right - 26) then
				for _, dz in ipairs({ -3, 3 }) do
					index += 1
					plantPocket(Vector3.new(left + right - c.X, top, c.Z + dz), index, true)
				end
			end
		end
	end
	local posts = model("ShoreMoorings")
	for i = 1, 3 do
		local pos = Vector3.new(left + 43, bottom, zmin + (156 + i * 9) * spacing)
		box("MooringPost", Vector3.new(1.0, 3.3, 1.0), pos + Vector3.new(0, 1.65, 0), wood, true)
		box("RopeBand", Vector3.new(1.08, 0.24, 1.08), pos + Vector3.new(0, 2.55, 0), Color3.fromRGB(220, 199, 143))
	end
	finish(posts, Vector3.new(left + 43, bottom, zmin + 174 * spacing))
	-- Match the reference viewed from the desert toward the lobby: hut on screen left.
	local centerX = (left + right) / 2
	local function mirror(cf)
		local x, y, z, a, b, c, d, e, f, g, h, i = cf:GetComponents()
		return CFrame.new(2 * centerX - x, y, z, a, -b, -c, -d, e, f, -g, h, i)
	end
	for _, p in ipairs(root:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CFrame = mirror(p.CFrame)
		end
	end
	for _, m in ipairs(root:GetDescendants()) do
		if m:IsA("Model") then
			m.WorldPivot = mirror(m:GetPivot())
		end
	end
	root:SetAttribute("Version", 1)
	root:SetAttribute("PlantPockets", index)
	return root
end
return Scenery
