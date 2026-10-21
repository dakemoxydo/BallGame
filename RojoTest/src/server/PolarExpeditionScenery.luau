--!strict
local Polar = {}

function Polar.apply(map)
	local world = map.SkippingWorld
	if world:FindFirstChild("PolarExpedition") then
		return
	end
	local V, C = Vector3.new, Color3.fromRGB
	local left, right, upper, lower = math.huge, -math.huge, nil, nil
	for _, p in ipairs(world:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "BiomeBank7_2" then
			left = math.min(left, p.Position.X - p.Size.X / 2)
			right = math.max(right, p.Position.X + p.Size.X / 2)
			upper = p
		elseif p:IsA("BasePart") and p.Name == "BiomeBank7_1" then
			lower = p
		end
	end
	assert(upper and lower, "Polar banks missing")
	local high, low = upper.Position.Y + upper.Size.Y / 2, lower.Position.Y + lower.Size.Y / 2
	local front, back = upper.Position.Z + upper.Size.Z / 2, upper.Position.Z - upper.Size.Z / 2
	local template
	for _, p in ipairs(game.ServerStorage.ImportedPortalVisuals.RoseBlossom:GetChildren()) do
		if p:IsA("MeshPart") and p.Name:find("Large foot crystal") then
			template = p
			break
		end
	end
	assert(template, "Crystal template missing")
	local backups = game.ServerStorage.WorldBackups
	local old = backups:FindFirstChild("BeforePolarExpedition")
	if not old then
		old = Instance.new("Folder")
		old.Name = "BeforePolarExpedition"
		old.Parent = backups
	end
	local trees = {}
	for _, m in ipairs(map.NativeEnvironment:GetDescendants()) do
		if m:IsA("Model") and m.Name == "RobloxOak" then
			local trunk = m:FindFirstChild("TrunkBase")
			if trunk and trunk.Position.Z > back and trunk.Position.Z < front then
				m:Clone().Parent = old
				table.insert(trees, V(trunk.Position.X, high, trunk.Position.Z))
				for _, p in ipairs(m:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Transparency = 1
						p:SetAttribute("PolarTreeHidden", true)
					elseif p:IsA("Texture") or p:IsA("Decal") then
						p.Transparency = 1
					end
				end
			end
		end
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
			and (p.Name == "BiomeDecorStem" or p.Name == "CrystalSatellite" or p.Name == "CrystalPeak")
		then
			p:Clone().Parent = old
			p.Transparency = 1
			p:SetAttribute("PolarCrystalHidden", true)
			for _, l in ipairs(p:GetDescendants()) do
				if l:IsA("Light") then
					l.Enabled = false
				elseif l:IsA("Texture") or l:IsA("Decal") then
					l.Transparency = 1
				end
			end
		end
	end
	local root = Instance.new("Model")
	root.Name = "PolarExpedition"
	local parent = root
	local snow, ice, blue, stone, green, wood, dark, amber =
		C(231, 247, 253),
		C(154, 223, 243),
		C(67, 135, 180),
		C(122, 161, 187),
		C(37, 87, 76),
		C(139, 91, 49),
		C(65, 83, 105),
		C(255, 192, 81)
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
	local function crystal(pos, h, w, color, yaw)
		local p = template:Clone()
		p.Name = "FacetedIce"
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
	end
	local function lamp(pos, s)
		box("LampFoot", V(1.6 * s, 0.3 * s, 1.6 * s), pos + V(0, 0.15 * s, 0), wood, true)
		box("WoodLanternPost", V(0.5 * s, 4.8 * s, 0.5 * s), pos + V(0, 2.5 * s, 0), wood, true)
		box("LanternArm", V(1.8 * s, 0.4 * s, 0.45 * s), pos + V(0.6 * s, 4.6 * s, 0), wood)
		bar("HangingLink", pos + V(1.15 * s, 4.5 * s, 0), pos + V(1.15 * s, 3.9 * s, 0), 0.1 * s, dark)
		local c = pos + V(1.15 * s, 3.25 * s, 0)
		local glow = box("WarmLantern", V(0.65 * s, 1.0 * s, 0.65 * s), c, amber)
		glow.Material = Enum.Material.Neon
		glow.Transparency = 0.1
		for _, x in ipairs({ -0.43, 0.43 }) do
			for _, z in ipairs({ -0.43, 0.43 }) do
				box("LanternFrame", V(0.12 * s, 1.15 * s, 0.12 * s), c + V(x * s, 0, z * s), dark)
			end
		end
		for _, y in ipairs({ -0.65, 0.65 }) do
			box("LanternCap", V(1.05 * s, 0.2 * s, 1.05 * s), c + V(0, y * s, 0), dark)
		end
		local l = Instance.new("PointLight")
		l.Color = amber
		l.Brightness = 0.7
		l.Range = 12 * s
		l.Shadows = false
		l.Parent = glow
	end
	local function crate(pos, s)
		box("SupplyCrate", V(s, s, s), pos + V(0, s / 2, 0), wood, true)
		for _, side in ipairs({ -1, 1 }) do
			for _, y in ipairs({ 0.15, s - 0.15 }) do
				box("CrateRim", V(s + 0.1, 0.2, 0.15), pos + V(0, y, side * (s / 2 + 0.02)), C(179, 135, 77))
			end
			bar(
				"CrateBrace",
				pos + V(-s * 0.4, s * 0.1, side * (s / 2 + 0.04)),
				pos + V(s * 0.4, s * 0.9, side * (s / 2 + 0.04)),
				0.18,
				C(179, 135, 77)
			)
		end
	end
	local function frost(pos, s, index, tall)
		for j = 1, 4 do
			local a = j * math.pi / 2 + index
			local c = pos + V(math.cos(a) * 2 * s, 0.55 * s, math.sin(a) * 2 * s)
			box("BlueSnowRock", V(2.5 * s, 1.1 * s, 2.2 * s), c, stone, true, CFrame.Angles(0, a, 0))
			box("RockSnowCap", V(2.0 * s, 0.24 * s, 1.7 * s), c + V(0, 0.67 * s, 0), snow, true, CFrame.Angles(0, a, 0))
		end
		local h = tall and 7.2 or 3.2
		crystal(pos, h * s, 2 * s, ice, index)
		crystal(pos + V(2 * s, 0, 0.7 * s), h * 0.65 * s, 1.4 * s, snow, -index)
		crystal(pos + V(-1.5 * s, 0, -0.7 * s), h * 0.48 * s, 1.3 * s, blue, index * 0.7)
		for j = 1, 6 do
			local a = j * math.pi / 3
			box(
				"FrostLeaf",
				V(0.5 * s, 0.15 * s, 2.6 * s),
				pos + V(math.cos(a) * 0.5 * s, 0.85 * s, 2.8 * s + math.sin(a) * 0.5 * s),
				ice,
				false,
				CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-45), 0, 0)
			)
		end
	end
	local function fir(pos, s)
		box("FirTrunk", V(1.1 * s, 4.0 * s, 1.1 * s), pos + V(0, 2 * s, 0), wood, true)
		for j, w in ipairs({ 7.8, 6.4, 4.8, 2.8 }) do
			local y = (3.4 + j * 2.15) * s
			box("EvergreenBough", V(w * s, 1.7 * s, w * 0.7 * s), pos + V(0, y, 0), green, true)
			box("EvergreenBough", V(w * 0.7 * s, 1.7 * s, w * s), pos + V(0, y, 0), green:Lerp(blue, 0.12), true)
			for k = 1, 3 do
				local a = k * math.pi * 2 / 3 + j * 0.4
				box(
					"BoughSnow",
					V(w * 0.54 * s, 0.65 * s, w * 0.48 * s),
					pos + V(math.cos(a) * w * 0.22 * s, y + 1.18 * s, math.sin(a) * w * 0.22 * s),
					snow,
					true,
					CFrame.Angles(0, a, 0)
				)
			end
		end
		crystal(pos + V(0, 13.3 * s, 0), 2.1 * s, 1.6 * s, snow, 0)
	end
	local cabinPos = V(left + 12, high, front - 75)
	local cabin = begin("PolarCabin")
	box("CabinDeck", V(14.2, 0.35, 16.2), cabinPos + V(0, 0.175, 1.3), wood, true)
	local body = box("BlueCabinWalls", V(12, 7.8, 11), cabinPos + V(0, 4.25, 0), blue, true)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do
		local t = Instance.new("Texture")
		t.Texture = "rbxassetid://88156646156237"
		t.Face = face
		t.StudsPerTileU = 8
		t.StudsPerTileV = 8
		t.Parent = body
	end
	for _, x in ipairs({ -6.1, 6.1 }) do
		for _, z in ipairs({ -5.6, 5.6 }) do
			box("CabinCornerTimber", V(0.55, 8.3, 0.55), cabinPos + V(x, 4.45, z), wood, true)
		end
	end
	-- Paired right triangles close both gables. The roof ridge runs along Z.
	for _, side in ipairs({ -1, 1 }) do
		for _, half in ipairs({ -1, 1 }) do
			part(
				"BlueGable",
				V(0.3, 4.0, 6.0),
				CFrame.new(cabinPos + V(half * 3, 10.15, side * 5.5))
					* CFrame.Angles(0, half > 0 and -math.pi / 2 or math.pi / 2, 0),
				blue,
				false,
				nil,
				"WedgePart"
			)
		end
	end
	local angle = math.atan2(4, 7)
	for _, side in ipairs({ -1, 1 }) do
		local cf = CFrame.new(cabinPos + V(side * 3.5, 10.4, 0)) * CFrame.Angles(0, 0, -side * angle)
		part("WoodRoof", V(8.3, 0.5, 14.4), cf, wood, true)
		part("ThickRoofSnow", V(8.4, 0.55, 14.5), cf * CFrame.new(0, 0.5, 0), snow, true)
	end
	box("SnowRidge", V(0.7, 0.6, 14.5), cabinPos + V(0, 12.85, 0), snow, true)
	box("StoneChimney", V(2.0, 4.6, 2.2), cabinPos + V(-3.5, 12.6, -2.7), dark, true)
	box("ChimneySnow", V(2.5, 0.4, 2.7), cabinPos + V(-3.5, 15.1, -2.7), snow, true)
	box("ChimneyOpening", V(1.2, 0.04, 1.4), cabinPos + V(-3.5, 15.32, -2.7), C(35, 49, 63))
	box("FrontDoor", V(2.6, 5.5, 0.25), cabinPos + V(2.6, 3.1, 5.65), wood, true)
	box("DoorLatch", V(0.18, 0.3, 0.3), cabinPos + V(3.4, 3.2, 5.87), dark)
	local function window(cf)
		part("WindowTimber", V(3.2, 3.0, 0.25), cf, wood)
		local glow = part("WarmCabinWindow", V(2.65, 2.45, 0.12), cf * CFrame.new(0, 0, 0.18), amber)
		glow.Material = Enum.Material.Neon
		glow.Transparency = 0.1
		part("WindowCrossbar", V(0.16, 2.65, 0.17), cf * CFrame.new(0, 0, 0.28), wood)
		part("WindowCrossbar", V(2.8, 0.16, 0.17), cf * CFrame.new(0, 0, 0.28), wood)
		local l = Instance.new("PointLight")
		l.Color = amber
		l.Brightness = 0.7
		l.Range = 12
		l.Shadows = false
		l.Parent = glow
	end
	window(CFrame.new(cabinPos + V(-2.8, 4.8, 5.7)))
	window(CFrame.new(cabinPos + V(6.15, 4.8, 0)) * CFrame.Angles(0, math.pi / 2, 0))
	for _, x in ipairs({ -5.6, 5.6 }) do
		box("PorchPost", V(0.6, 4.0, 0.6), cabinPos + V(x, 2.35, 8.0), wood, true)
	end
	lamp(cabinPos + V(4.6, 0.35, 7.4), 0.7)
	for row = 0, 2 do
		for col = 0, 2 - row do
			part(
				"StackedFirewood",
				V(3.4, 0.85, 0.85),
				CFrame.new(cabinPos + V(8.4 + col * 0.85, 0.8 + row * 0.78, -2)) * CFrame.Angles(0, math.pi / 2, 0),
				wood,
				false,
				Enum.PartType.Cylinder
			)
		end
	end
	crate(cabinPos + V(8.7, 0, -5.3), 2.3)
	finish(cabin, cabinPos)
	root.WorldPivot = CFrame.new((left + right) / 2, high, (front + back) / 2)
	root.Parent = world
	task.wait()
	local sledPos = V(right - 12, high, front - 95)
	local sled = begin("ExpeditionSled")
	for _, side in ipairs({ -1, 1 }) do
		box("SledRunner", V(0.38, 0.35, 9.4), sledPos + V(side * 2.6, 0.28, 0), C(195, 158, 99), true)
		bar(
			"UpturnedRunner",
			sledPos + V(side * 2.6, 0.28, 4.6),
			sledPos + V(side * 2.6, 1.15, 5.5),
			0.38,
			C(195, 158, 99)
		)
		bar("RunnerTip", sledPos + V(side * 2.6, 1.15, 5.5), sledPos + V(side * 2.6, 1.6, 5.6), 0.38, C(195, 158, 99))
		for _, z in ipairs({ -3.2, 3.2 }) do
			box("SledUpright", V(0.45, 2.5, 0.45), sledPos + V(side * 2.6, 2.1, z), wood)
		end
		box("SledRail", V(0.4, 0.4, 7.3), sledPos + V(side * 2.6, 3.3, 0), wood, true)
	end
	for j = 1, 7 do
		box("SledBedPlank", V(5.4, 0.35, 0.8), sledPos + V(0, 1.5, -3.7 + j), wood, true)
	end
	crate(sledPos + V(-1.2, 1.7, 1.8), 2.4)
	crate(sledPos + V(1.25, 1.7, -0.4), 2.0)
	part(
		"RolledBlueBlanket",
		V(3.8, 1.5, 1.5),
		CFrame.new(sledPos + V(0, 2.6, -2.7)),
		C(54, 100, 155),
		false,
		Enum.PartType.Cylinder
	)
	for _, x in ipairs({ -1.2, 1.2 }) do
		part(
			"BlanketStrap",
			V(0.18, 1.58, 1.58),
			CFrame.new(sledPos + V(x, 2.6, -2.7)),
			wood,
			false,
			Enum.PartType.Cylinder
		)
	end
	local flag = sledPos + V(5.5, 0, -1)
	box("ExpeditionFlagpole", V(0.22, 9.2, 0.22), flag + V(0, 4.6, 0), wood)
	box("BlueExpeditionFlag", V(3.4, 2.7, 0.15), flag + V(1.7, 7.5, 0), blue)
	local c = flag + V(1.7, 7.5, 0.13)
	for i = 0, 2 do
		local a = i * math.pi / 3
		bar(
			"FlagSnowflake",
			c + V(math.cos(a) * 0.8, math.sin(a) * 0.8, 0),
			c - V(math.cos(a) * 0.8, math.sin(a) * 0.8, 0),
			0.12,
			snow
		)
	end
	finish(sled, sledPos)
	task.wait()
	local penguinPos = V(right - 11, high, front - 70)
	local penguin = begin("IcePenguinSculpture")
	for j = 1, 5 do
		local a = j * math.pi * 2 / 5
		box(
			"IcePedestalStone",
			V(3.6, 1.6, 3.4),
			penguinPos + V(math.cos(a) * 1.5, 0.8, math.sin(a) * 1.5),
			ice,
			true,
			CFrame.Angles(0, a, 0)
		)
	end
	box("SnowPedestalTop", V(6.2, 0.35, 5.6), penguinPos + V(0, 1.8, 0), snow, true)
	for _, x in ipairs({ -0.85, 0.85 }) do
		box("PenguinFoot", V(1.2, 0.4, 1.8), penguinPos + V(x, 2.15, 0.5), blue, true)
	end
	box("PenguinIceBody", V(3.3, 3.8, 2.6), penguinPos + V(0, 4.1, 0), blue, true)
	box("PenguinWhiteBelly", V(2.4, 2.9, 0.3), penguinPos + V(0, 4.0, 1.43), snow)
	box("PenguinIceHead", V(2.6, 2.5, 2.5), penguinPos + V(0, 6.5, 0), blue, true)
	for _, side in ipairs({ -1, 1 }) do
		box("WhiteEyePatch", V(0.9, 1.2, 0.2), penguinPos + V(side * 0.65, 6.7, 1.3), snow)
		box("PenguinEye", V(0.25, 0.3, 0.16), penguinPos + V(side * 0.65, 6.85, 1.48), C(34, 62, 85))
		box(
			"PenguinFlipper",
			V(0.65, 3.4, 1.25),
			penguinPos + V(side * 1.95, 4.2, 0),
			ice,
			false,
			CFrame.Angles(0, 0, math.rad(side * 22))
		)
	end
	box("PenguinIceBeak", V(0.65, 0.42, 0.6), penguinPos + V(0, 6.3, 1.65), ice)
	lamp(penguinPos + V(-4.5, 0, 3.6), 0.85)
	finish(penguin, penguinPos)
	-- Replacement firs share the original trunk positions; four new groups fill gaps.
	for _, side in ipairs({ -1, 1 }) do
		for _, t in ipairs({ 16, 163 }) do
			table.insert(trees, V(side < 0 and left + 12 or right - 12, high, front - t))
		end
	end
	for i, pos in ipairs(trees) do
		local m = begin("SnowyFirCluster")
		fir(pos, 0.95)
		fir(pos + V(pos.X < 0 and -4.2 or 4.2, 0, 4.7), 0.55)
		frost(pos + V(0, 0, -4.4), 0.65, i, true)
		lamp(pos + V(pos.X < 0 and 6 or -6, 0, 0), 0.8)
		finish(m, pos)
		task.wait()
	end
	for _, side in ipairs({ -1, 1 }) do
		for j, t in ipairs(side < 0 and { 36, 95, 133 } or { 36, 82, 132 }) do
			local pos = V(side < 0 and left + 6 or right - 6, high, front - t)
			local m = begin("PolarIceOutcrop")
			frost(pos, 1.0, j, true)
			finish(m, pos)
		end
		for j, t in ipairs({ 19, 47, 79, 110, 141, 165 }) do
			local pos = V(side < 0 and left + 35 or right - 35, low, front - t)
			local m = begin("LowFrostGarden")
			frost(pos, 0.65, j, false)
			finish(m, pos)
		end
		local path = begin("PolarSteppingPath")
		for j = 1, 12 do
			box(
				"FrostedSlab",
				V(3.0, 0.08, 2.5),
				V(side < 0 and left + 22 or right - 22, high + 0.05, front - 14 - j * 12.3),
				stone,
				true,
				CFrame.Angles(0, math.rad(j % 3 * 8 - 8), 0)
			)
		end
		finish(path, V(side < 0 and left + 22 or right - 22, high, front - 90))
		task.wait()
	end
	-- Thin caps follow existing flat rock crests instead of moving authored rocks.
	for _, p in ipairs(map.NativeEnvironment:GetDescendants()) do
		if
			p:IsA("BasePart")
			and p.Name == "RockCrest"
			and p.Transparency < 1
			and p.Position.Z > back
			and p.Position.Z < front
		then
			local cap = part(
				"AuthoredRockSnowCap",
				V(p.Size.X * 0.86, 0.24, p.Size.Z * 0.86),
				p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.12, 0),
				snow,
				true
			)
			cap:SetAttribute("SnowSupport", p:GetFullName())
			cap:SetAttribute("SnowSupportFrame", p.CFrame)
			cap:SetAttribute("SnowSupportSize", p.Size)
		end
	end
	root:SetAttribute("Version", 1)
	return root
end

return Polar
