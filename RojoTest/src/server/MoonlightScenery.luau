--!strict
local Moonlight = {}

function Moonlight.apply(map)
	local world = map.SkippingWorld
	if world:FindFirstChild("MoonlightPromenade") then
		return
	end
	local V, C = Vector3.new, Color3.fromRGB
	local left, right, upper, lower = math.huge, -math.huge, nil, nil
	for _, p in ipairs(world:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "BiomeBank6_2" then
			left = math.min(left, p.Position.X - p.Size.X / 2)
			right = math.max(right, p.Position.X + p.Size.X / 2)
			upper = p
		elseif p:IsA("BasePart") and p.Name == "BiomeBank6_1" then
			lower = p
		end
	end
	assert(upper and lower, "Moonlight banks missing")
	local high, low = upper.Position.Y + upper.Size.Y / 2, lower.Position.Y + lower.Size.Y / 2
	local front, back = upper.Position.Z + upper.Size.Z / 2, upper.Position.Z - upper.Size.Z / 2
	local template
	for _, p in ipairs(game.ServerStorage.ImportedPortalVisuals.RoseBlossom:GetChildren()) do
		if p:IsA("MeshPart") and p.Name:find("Large foot crystal") then
			template = p
			break
		end
	end
	assert(template, "Uploaded crystal template missing")
	local backups = game.ServerStorage:FindFirstChild("WorldBackups")
	if not backups then
		backups = Instance.new("Folder")
		backups.Name = "WorldBackups"
		backups.Parent = game.ServerStorage
	end
	local old = backups:FindFirstChild("BeforeMoonlightPromenade")
	if not old then
		old = Instance.new("Folder")
		old.Name = "BeforeMoonlightPromenade"
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
			and p.Position.Z > back
			and p.Position.Z < front
			and (p.Name == "MoonOrb" or p.Name == "BiomeDecorStem" or p.Name == "CrystalPeak")
		then
			p:Clone().Parent = old
			p.Transparency = 1
			p:SetAttribute("MoonlightVisualHidden", true)
			for _, l in ipairs(p:GetDescendants()) do
				if l:IsA("Light") then
					l.Enabled = false
				end
			end
		end
	end
	local root = Instance.new("Model")
	root.Name = "MoonlightPromenade"
	local parent = root
	local indigo, roofBlue, stone, pale, pearl =
		C(69, 75, 135), C(83, 100, 169), C(127, 149, 180), C(172, 199, 221), C(227, 246, 255)
	local ice, cyan, lavender, leaf, wood =
		C(166, 226, 252), C(83, 178, 229), C(179, 153, 218), C(129, 170, 192), C(152, 120, 100)
	local function part(name, size, cf, color, studs, shape, class)
		local p = Instance.new(class or "Part")
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
		return part(name, V(w, w, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
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
	local function light(p, brightness, range)
		local l = Instance.new("PointLight")
		l.Color = ice
		l.Brightness = brightness
		l.Range = range
		l.Shadows = false
		l.Parent = p
	end
	local function crystal(pos, h, w, color, yaw)
		local p = template:Clone()
		p.Name = "MoonstoneCrystal"
		p.Size = V(w, h, w * 0.8)
		p.CFrame = CFrame.new(pos + V(0, h / 2, 0)) * CFrame.Angles(0, yaw or 0, 0)
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Transparency = 0
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		for _, c in ipairs(p:GetChildren()) do
			if c:IsA("Texture") or c:IsA("SurfaceAppearance") then
				c:Destroy()
			end
		end
		p.Parent = parent
		return p
	end
	local function flowers(pos, s, index)
		for j = 1, 5 do
			local a = j * math.pi * 2 / 5 + index
			box(
				"SilverBlueLeaf",
				V(0.65 * s, 0.2 * s, 3 * s),
				pos + V(math.cos(a) * 0.5 * s, 0.95 * s, math.sin(a) * 0.5 * s),
				leaf,
				false,
				CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-43), 0, 0)
			)
		end
		for j = 1, 3 do
			local c = pos + V((j - 2) * 1.15 * s, 1.5 * s, (j % 2 == 0 and -0.7 or 0.5) * s)
			box("FlowerStem", V(0.12 * s, 1.4 * s, 0.12 * s), c - V(0, 0.7 * s, 0), leaf)
			for k = 1, 5 do
				local a = k * math.pi * 2 / 5
				part(
					"MoonflowerPetal",
					V(0.14 * s, 0.78 * s, 0.78 * s),
					CFrame.new(c + V(math.cos(a) * 0.37 * s, 0, math.sin(a) * 0.37 * s))
						* CFrame.Angles(0, 0, math.pi / 2),
					j % 2 == 0 and pearl or lavender,
					false,
					Enum.PartType.Cylinder
				)
			end
			part(
				"MoonflowerHeart",
				V(0.18 * s, 0.34 * s, 0.34 * s),
				CFrame.new(c + V(0, 0.08 * s, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				ice,
				false,
				Enum.PartType.Cylinder
			)
		end
		-- Small lavender flower spikes provide a different vertical silhouette.
		for j = 1, 2 do
			local c = pos + V((j == 1 and -1.7 or 1.8) * s, 0, -1.0 * s)
			box("LavenderStalk", V(0.13 * s, 2.5 * s, 0.13 * s), c + V(0, 1.25 * s, 0), leaf)
			for k = 1, 4 do
				box(
					"LavenderBloom",
					V((0.72 - k * 0.1) * s, 0.38 * s, (0.72 - k * 0.1) * s),
					c + V(0, (0.8 + k * 0.45) * s, 0),
					k % 2 == 0 and pearl or lavender,
					false,
					CFrame.Angles(0, k * 0.5, 0)
				)
			end
		end
	end
	local function garden(pos, s, index, tall)
		for j = 1, 5 do
			local a = j * 1.26 + index * 0.33
			local h = (0.65 + j % 2 * 0.55) * s
			box(
				"MoonstoneRock",
				V(2.7 * s, h, 2.3 * s),
				pos + V(math.cos(a) * 2.1 * s, h / 2, math.sin(a) * 2.1 * s),
				j % 2 == 0 and stone or indigo:Lerp(stone, 0.6),
				true,
				CFrame.Angles(0, a, 0)
			)
		end
		local h = tall and 7.8 or 4.4
		crystal(pos + V(-0.7 * s, 0, 0), h * s, 2.0 * s, ice, index)
		crystal(pos + V(1.5 * s, 0, 0.8 * s), h * 0.7 * s, 1.5 * s, cyan, -index * 0.4)
		crystal(pos + V(-1.4 * s, 0, -1.3 * s), h * 0.46 * s, 1.1 * s, pearl, index * 0.6)
		flowers(pos + V(0, 0, 2.7 * s), 0.85 * s, index)
	end
	local function lantern(pos, s)
		local c = pos + V(0, 1.35 * s, 0)
		local orb =
			part("FrostedLanternGlobe", V(1.8 * s, 1.8 * s, 1.8 * s), CFrame.new(c), pearl, false, Enum.PartType.Ball)
		orb.Material = Enum.Material.Neon
		orb.Transparency = 0.12
		light(orb, 0.55, 12 * s)
		for _, x in ipairs({ -1.2, 1.2 }) do
			for _, z in ipairs({ -1.2, 1.2 }) do
				box("LanternVerticalFrame", V(0.16 * s, 2.5 * s, 0.16 * s), c + V(x * s, 0, z * s), indigo)
			end
		end
		for _, y in ipairs({ -1.25, 1.25 }) do
			for _, k in ipairs({ -1, 1 }) do
				box("LanternHorizontalFrame", V(2.56 * s, 0.16 * s, 0.16 * s), c + V(0, y * s, k * 1.2 * s), indigo)
				box("LanternHorizontalFrame", V(0.16 * s, 0.16 * s, 2.56 * s), c + V(k * 1.2 * s, y * s, 0), indigo)
			end
		end
		box("LanternFoot", V(1.5 * s, 0.22 * s, 1.5 * s), pos + V(0, 0.05 * s, 0), indigo)
	end
	-- Four triangular roof faces form a closed hipped roof, without oversized slabs.
	local function roofTriangle(a, b, c)
		local ab, ac, bc = b - a, c - a, c - b
		if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then
			c, a = a, c
		elseif ac:Dot(ac) > bc:Dot(bc) then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local rightAxis = ac:Cross(ab).Unit
		local backAxis = bc.Unit
		local upAxis = bc:Cross(rightAxis).Unit
		local h = math.abs(ab:Dot(upAxis))
		local faces = {
			part(
				"HippedRoofFace",
				V(0.24, h, math.abs(ab:Dot(backAxis))),
				CFrame.fromMatrix((a + b) / 2, rightAxis, upAxis, backAxis),
				roofBlue,
				false,
				nil,
				"WedgePart"
			),
			part(
				"HippedRoofFace",
				V(0.24, h, math.abs(ac:Dot(backAxis))),
				CFrame.fromMatrix((a + c) / 2, -rightAxis, upAxis, -backAxis),
				roofBlue,
				false,
				nil,
				"WedgePart"
			),
		}
		for _, p in ipairs(faces) do
			for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
				local t = Instance.new("Texture")
				t.Texture = "rbxassetid://88156646156237"
				t.Face = face
				t.StudsPerTileU = 8
				t.StudsPerTileV = 8
				t.Parent = p
			end
		end
	end
	local pavilionPos = V(left + 11, high, front - 65)
	local pavilion = begin("CrescentMoonPavilion")
	box("PavilionDeck", V(14.5, 0.24, 14.5), pavilionPos + V(0, 0.12, 0), stone, true)
	for _, x in ipairs({ -5.8, 5.8 }) do
		for _, z in ipairs({ -5.8, 5.8 }) do
			box("PostFoot", V(2, 0.45, 2), pavilionPos + V(x, 0.45, z), indigo, true)
			box("PavilionColumn", V(1.0, 8.6, 1.0), pavilionPos + V(x, 4.7, z), indigo, true)
			box("ColumnCapital", V(1.6, 0.4, 1.6), pavilionPos + V(x, 8.9, z), pale, true)
		end
	end
	local apex = pavilionPos + V(0, 13.7, 0)
	local corners = { V(-8, 9.5, -8), V(8, 9.5, -8), V(8, 9.5, 8), V(-8, 9.5, 8) }
	for i = 1, 4 do
		local a, b = pavilionPos + corners[i], pavilionPos + corners[i % 4 + 1]
		roofTriangle(apex, a, b)
		bar("RoofHipRidge", apex, a, 0.35, indigo)
		bar("RoofEave", a, b, 0.42, indigo)
		local radial = corners[i] * V(1, 0, 1)
		bar("UpturnedEaveTip", a, a + radial.Unit * 0.65 + V(0, 0.55, 0), 0.38, indigo)
	end
	box("RoofFinial", V(0.8, 0.7, 0.8), apex + V(0, 0.4, 0), indigo)
	-- Crescent emblem rests just above the sloped roof facing the lobby (+Z).
	local moonCF = CFrame.new(pavilionPos + V(0, 11.55, 4.9)) * CFrame.Angles(math.rad(-62), 0, 0)
	for i = 0, 15 do
		local t = i / 15
		local a = math.rad(58 + 244 * t)
		local thickness = 0.1 + 0.66 * math.sin(t * math.pi)
		part(
			"PearlCrescent",
			V(thickness, 0.43, 0.22),
			moonCF * CFrame.new(math.cos(a) * 1.25, math.sin(a) * 1.25, 0.24) * CFrame.Angles(0, 0, a),
			pearl
		)
	end
	for _, side in ipairs({ -1, 1 }) do
		for _, y in ipairs({ 1.8, 3.6 }) do
			box("SideRailing", V(0.28, 0.28, 10.5), pavilionPos + V(side * 5.8, y, 0), pale)
		end
		for z = -4, 4, 2 do
			box("RailingBaluster", V(0.2, 1.8, 0.2), pavilionPos + V(side * 5.8, 2.7, z), indigo)
		end
	end
	box("BenchSeat", V(8.6, 0.45, 2.1), pavilionPos + V(0, 2.15, -3.8), wood, true)
	box("BenchBack", V(8.6, 2.1, 0.35), pavilionPos + V(0, 3.3, -4.8), wood, true)
	for _, x in ipairs({ -3.2, 3.2 }) do
		box("BenchLeg", V(0.55, 1.8, 1.4), pavilionPos + V(x, 1.1, -3.8), indigo)
	end
	for _, x in ipairs({ -3.8, 3.8 }) do
		bar("HangingLanternChain", pavilionPos + V(x, 8.9, 2.5), pavilionPos + V(x, 7.4, 2.5), 0.1, pale)
		lantern(pavilionPos + V(x, 5.6, 2.5), 0.65)
	end
	finish(pavilion, pavilionPos)
	root.WorldPivot = CFrame.new((left + right) / 2, high, (front + back) / 2)
	root.Parent = world
	task.wait()
	local globePos = V(right - 12, high, front - 46)
	local globe = begin("CelestialGlobe")
	box("GlobeFoundation", V(8.6, 0.3, 8.6), globePos + V(0, 0.15, 0), stone, true)
	box("GlobePedestalFoot", V(6.2, 0.7, 6.2), globePos + V(0, 0.65, 0), indigo, true)
	box("GlobePedestal", V(4.6, 2.4, 4.6), globePos + V(0, 2.2, 0), stone, true)
	box("GlobePedestalCap", V(5.9, 0.55, 5.9), globePos + V(0, 3.6, 0), pale, true)
	bar("GlobeSpindle", globePos + V(0, 3.8, 0), globePos + V(0, 5.1, 0), 0.55, indigo)
	local center = globePos + V(0, 8.2, 0)
	local sphere =
		part("BlueCelestialSphere", V(6.0, 6.0, 6.0), CFrame.new(center), C(59, 99, 183), false, Enum.PartType.Ball)
	sphere.Material = Enum.Material.SmoothPlastic
	light(sphere, 0.3, 12)
	for _, tilt in ipairs({ -38, 48 }) do
		local cf = CFrame.new(center) * CFrame.Angles(math.rad(tilt), math.rad(tilt == 48 and 68 or -12), math.rad(10))
		for i = 0, 39 do
			local a, b = i * math.pi / 20, (i + 1) * math.pi / 20
			bar(
				"SilverOrbitRing",
				cf:PointToWorldSpace(V(math.cos(a) * 4.3, math.sin(a) * 4.3, 0)),
				cf:PointToWorldSpace(V(math.cos(b) * 4.3, math.sin(b) * 4.3, 0)),
				0.23,
				pearl
			)
		end
	end
	for i = 1, 6 do
		local a = i * 2.3
		local pos = center + V(math.cos(a) * 5.3, (i % 3 - 1) * 2.6, math.sin(a) * 4.5)
		local star = part("SmallMoonMote", V(0.19, 0.19, 0.19), CFrame.new(pos), pearl, false, Enum.PartType.Ball)
		star.Material = Enum.Material.Neon
	end
	finish(globe, globePos)
	task.wait()
	local index = 0
	for _, side in ipairs({ -1, 1 }) do
		local x = side < 0 and left + 8 or right - 8
		local times = side < 0 and { 18, 105, 137, 166 } or { 16, 76, 122, 154 }
		for _, t in ipairs(times) do
			index += 1
			local pos = V(x, high, front - t)
			local m = begin("FramedMoonLampGarden")
			box("LampBase", V(2.2, 0.55, 2.2), pos + V(0, 0.275, 0), indigo, true)
			box("IndigoLampPost", V(0.95, 7.9, 0.95), pos + V(0, 4.45, 0), indigo, true)
			lantern(pos + V(0, 8.45, 0), 1.0)
			garden(pos + V(side * 1.2, 0, 2.7), 1.15, index, true)
			finish(m, pos)
			task.wait()
		end
		for _, t in ipairs(side < 0 and { 40, 151 } or { 98, 143 }) do
			index += 1
			local pos = V(side < 0 and left + 7 or right - 7, high, front - t)
			local m = begin("OuterMoonstoneGarden")
			garden(pos, 1.3, index, true)
			finish(m, pos)
		end
		for _, t in ipairs({ 18, 47, 76, 107, 139, 166 }) do
			index += 1
			local pos = V(side < 0 and left + 35 or right - 35, low, front - t)
			local m = begin("InnerMoonflowerGarden")
			garden(pos, 1.05, index, false)
			finish(m, pos)
		end
		local path = begin("MoonstoneSteppingPath")
		for i = 1, 12 do
			box(
				"BlueGraySlab",
				V(3.3, 0.08, 2.6),
				V(side < 0 and left + 22 or right - 22, high + 0.05, front - 14 - i * 12.3),
				stone,
				true,
				CFrame.Angles(0, math.rad(i % 3 * 7 - 7), 0)
			)
		end
		finish(path, V(side < 0 and left + 22 or right - 22, high, front - 90))
		task.wait()
	end
	for i, pos in ipairs({ pavilionPos + V(-4.0, 0, 9.6), globePos + V(5.8, 0, 1.4), globePos + V(-3.2, 0, 7.0) }) do
		local m = begin("LandmarkMoonflowers")
		garden(pos, 0.9, 30 + i, false)
		finish(m, pos)
	end
	root:SetAttribute("Version", 1)
	return root
end

return Moonlight
