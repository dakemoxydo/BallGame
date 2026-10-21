--!strict
local Ember = {}

local function faceLobby(root)
	if root:GetAttribute("FrontFacesLobby") then
		return
	end
	for _, name in ipairs({ "AmberMineEntrance", "RiversideForge" }) do
		local m = root:FindFirstChild(name)
		assert(m and m:IsA("Model"), name .. " missing")
		m:PivotTo(m:GetPivot() * CFrame.Angles(0, math.pi, 0))
	end
	root:SetAttribute("FrontFacesLobby", true)
end

function Ember.apply(map)
	local world = map.SkippingWorld
	local existing = world:FindFirstChild("AmberMineAndForge")
	if existing then
		faceLobby(existing)
		return existing
	end
	local V, C = Vector3.new, Color3.fromRGB
	local left, right, upper, lower = math.huge, -math.huge, nil, nil
	for _, p in ipairs(world:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "BiomeBank5_2" then
			left = math.min(left, p.Position.X - p.Size.X / 2)
			right = math.max(right, p.Position.X + p.Size.X / 2)
			upper = p
		elseif p:IsA("BasePart") and p.Name == "BiomeBank5_1" then
			lower = p
		end
	end
	assert(upper and lower, "Ember River banks missing")
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
	local old = backups:FindFirstChild("BeforeEmberCrystalReplacement")
	if not old then
		old = Instance.new("Folder")
		old.Name = "BeforeEmberCrystalReplacement"
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
			and (
				((p.Name == "BiomeDecorStem" or p.Name == "CrystalSatellite") and p.Material == Enum.Material.Neon)
				or p.Name == "CrystalPeak"
			)
		then
			p:Clone().Parent = old
			p.Transparency = 1
			p:SetAttribute("EmberCrystalHidden", true)
		end
	end
	local root = Instance.new("Model")
	root.Name = "AmberMineAndForge"
	local parent = root
	local coal, rust, copper, wood, timber, iron =
		C(76, 66, 65), C(155, 79, 45), C(190, 108, 50), C(110, 65, 31), C(155, 99, 47), C(75, 80, 81)
	local amber, honey = C(255, 159, 32), C(255, 202, 73)
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
		return part(name, V(w, w, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
	end
	local function cylinder(name, pos, h, d, color, vertical)
		return part(
			name,
			V(h, d, d),
			CFrame.new(pos) * (vertical and CFrame.Angles(0, 0, math.pi / 2) or CFrame.identity),
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
	local function crystal(pos, h, w, color, yaw, light)
		local p = template:Clone()
		p.Name = "FacetedAmber"
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
		if light then
			local l = Instance.new("PointLight")
			l.Color = amber
			l.Brightness = 0.4
			l.Range = 11
			l.Shadows = false
			l.Parent = p
		end
		return p
	end
	local function rocks(pos, s, index)
		for j = 1, 5 do
			local a = j * 1.26 + index * 0.45
			local h = (1.5 + j % 3) * s
			box(
				"OreBearingRock",
				V((2.6 + j % 2) * s, h, 2.7 * s),
				pos + V(math.cos(a) * 2.6 * s, h / 2, math.sin(a) * 2.6 * s),
				j % 2 == 0 and coal or rust,
				true,
				CFrame.Angles(0, a, 0) * CFrame.Angles(0, 0, math.rad(j % 2 == 0 and 9 or -7))
			)
		end
	end
	local function grass(pos, s, index)
		for j = 1, 7 do
			local a = j * math.pi * 2 / 7 + index * 0.31
			box(
				"CopperGrass",
				V(0.45 * s, 0.22 * s, 3.7 * s),
				pos + V(math.cos(a) * 0.55 * s, 1.35 * s, math.sin(a) * 0.55 * s),
				j % 2 == 0 and copper or rust,
				false,
				CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-55), 0, 0)
			)
		end
	end
	local function crate(pos, s)
		box("SupplyCrate", V(s, s, s), pos + V(0, s / 2, 0), wood, true)
		for _, side in ipairs({ -1, 1 }) do
			for _, k in ipairs({ -1, 1 }) do
				box(
					"CrateRim",
					V(s + 0.12, 0.2, 0.16),
					pos + V(0, s / 2 + k * (s / 2 - 0.15), side * (s / 2 + 0.02)),
					timber
				)
			end
			bar(
				"CrateBrace",
				pos + V(-s * 0.4, s * 0.1, side * (s / 2 + 0.06)),
				pos + V(s * 0.4, s * 0.9, side * (s / 2 + 0.06)),
				0.16,
				timber
			)
		end
	end
	local function lantern(pos)
		box("LanternBase", V(1.1, 0.2, 1.1), pos, iron)
		local glow = box("WarmLantern", V(0.7, 1.1, 0.7), pos + V(0, 0.65, 0), honey)
		glow.Material = Enum.Material.Neon
		box("LanternCap", V(1.1, 0.25, 1.1), pos + V(0, 1.3, 0), iron)
		for _, x in ipairs({ -0.43, 0.43 }) do
			for _, z in ipairs({ -0.43, 0.43 }) do
				box("LanternFrame", V(0.12, 1.2, 0.12), pos + V(x, 0.65, z), wood)
			end
		end
		local l = Instance.new("PointLight")
		l.Color = amber
		l.Brightness = 1.1
		l.Range = 14
		l.Shadows = false
		l.Parent = glow
	end
	local minePos = V(right - 12, high, front - 65)
	for _, p in ipairs(map.SurfaceRepairs:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "CliffShoulder_Surface" and (p.Position - minePos).Magnitude < 16 then
			p:Clone().Parent = old
			p.Color = coal
			p:SetAttribute("EmberOutcropTint", true)
		end
	end
	local mine = begin("AmberMineEntrance")
	-- A compact rock facade with an intentionally recessed, dark mine opening.
	box("MineRecess", V(9.2, 9.6, 0.8), minePos + V(0, 4.8, 3.0), C(37, 28, 23))
	box("MineFloor", V(10, 0.2, 7.5), minePos + V(0, 0.1, 0.3), coal, true)
	for _, side in ipairs({ -1, 1 }) do
		for j = 0, 2 do
			box(
				"OutcropShoulder",
				V(4.3 - j * 0.5, 4.1, 7 - j * 0.4),
				minePos + V(side * (7.0 - j * 0.65), 2.0 + j * 3.3, 2.0),
				j % 2 == 0 and rust or coal,
				true,
				CFrame.Angles(0, side * 0.2, side * 0.12)
			)
		end
		box("MineTimberPost", V(1.3, 9.8, 1.6), minePos + V(side * 4.6, 4.9, -1.0), wood, true)
		bar("MineCornerBrace", minePos + V(side * 4.5, 6.4, -1.2), minePos + V(side * 2.6, 9.2, -1.2), 0.55, timber)
	end
	for j = -1, 1 do
		box(
			"OutcropCrown",
			V(5.0, 3.5, 6.0),
			minePos + V(j * 4.0, 11.1 - math.abs(j), 2.2),
			j == 0 and coal or rust,
			true,
			CFrame.Angles(0, j * 0.16, j * 0.1)
		)
	end
	for j = 1, 5 do
		local side = j % 2 == 0 and -1 or 1
		local p = Instance.new("WedgePart")
		p.Name = "OutcropFacet"
		p.Size = V(3.5, 3.2, 4.5)
		p.CFrame = CFrame.new(minePos + V(side * (6.8 + j % 2), 1.6 + j % 3 * 3.3, -0.8))
			* CFrame.Angles(0, side * math.pi / 2, 0)
		p.Color = j % 2 == 0 and coal or rust
		p.Material = Enum.Material.Plastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Parent = parent
	end
	box("MineLintel", V(11.8, 1.7, 2.0), minePos + V(0, 9.8, -1.0), timber, true)
	lantern(minePos + V(3.3, 6.4, -1.6))
	for _, side in ipairs({ -1, 1 }) do
		box("MinecartRail", V(0.22, 0.2, 16), minePos + V(side * 1.7, 0.34, -8.7), iron)
	end
	for j = 1, 8 do
		box("RailSleeper", V(4.4, 0.18, 0.55), minePos + V(0, 0.12, -1.5 - j * 1.9), wood, true)
	end
	local cart = minePos + V(0, 0, -10.4)
	box("CartChassis", V(4.6, 0.45, 4.8), cart + V(0, 1.25, 0), iron)
	for _, x in ipairs({ -2.15, 2.15 }) do
		for _, z in ipairs({ -1.65, 1.65 }) do
			cylinder("MinecartWheel", cart + V(x, 0.85, z), 0.45, 1.35, coal, false)
		end
	end
	box("CartOreBed", V(4.2, 0.3, 4.3), cart + V(0, 1.6, 0), rust, true)
	for _, side in ipairs({ -1, 1 }) do
		box("CartSide", V(0.25, 2.0, 4.6), cart + V(side * 2.2, 2.45, 0), copper, true)
		box("CartEnd", V(4.4, 2.0, 0.25), cart + V(0, 2.45, side * 2.25), copper, true)
	end
	for j = 1, 7 do
		local a = j * 2.4
		crystal(cart + V(math.cos(a) * 1.1, 1.9, math.sin(a) * 1.3), 1.8 + j % 3 * 0.5, 0.8, honey, a, false)
	end
	crate(minePos + V(-6.2, 0, -6.5), 2.8)
	crate(minePos + V(-6.0, 2.8, -6.5), 2.1)
	crystal(minePos + V(7, 0, -4.7), 6.8, 2.3, amber, 0.5, true)
	finish(mine, minePos)
	root.WorldPivot = CFrame.new((left + right) / 2, high, (front + back) / 2)
	root.Parent = world
	task.wait()
	local forgePos = V(left + 12, high, front - 95)
	local forge = begin("RiversideForge")
	local furnace = forgePos + V(-2, 0, 2)
	box("ForgeHearth", V(7, 1, 5), furnace + V(0, 0.5, 0), coal, true)
	box("FireboxDark", V(4.6, 3, 0.3), furnace + V(0, 2.5, 0.2), C(35, 24, 23))
	for _, side in ipairs({ -1, 1 }) do
		for j = 0, 2 do
			box(
				"FurnaceMasonry",
				V(1.5, 1.4, 4.5),
				furnace + V(side * 2.8, 1.7 + j * 1.4, 0.8),
				j % 2 == 0 and coal or coal:Lerp(rust, 0.25),
				true
			)
		end
	end
	box("FurnaceCrown", V(7, 1.2, 4.5), furnace + V(0, 5.9, 0.8), coal, true)
	for j = 1, 3 do
		box(
			"ShortChimney",
			V(2.3, 1.8, 2.4),
			furnace + V(1.5, 6.5 + j * 1.7, 1.6),
			j % 2 == 0 and coal or C(97, 80, 71),
			true
		)
	end
	box("ChimneyMouth", V(1.7, 0.05, 1.8), furnace + V(1.5, 12.53, 1.6), C(29, 25, 26))
	for j = 1, 5 do
		local p = box(
			"GlowingCoal",
			V(0.8, 0.65, 1.1),
			furnace + V(-1.6 + j * 0.55, 1.3, -0.9),
			j % 2 == 0 and amber or C(255, 94, 18),
			false,
			CFrame.Angles(0, j, 0)
		)
		p.Material = Enum.Material.Neon
	end
	for j = 1, 4 do
		crystal(
			furnace + V(-1.7 + j * 0.65, 1.55, -0.6),
			1.3 + j % 2 * 0.65,
			0.6,
			j % 2 == 0 and honey or amber,
			j,
			true
		)
	end
	for _, x in ipairs({ -8, 8 }) do
		box("ForgeCanopyPost", V(0.85, 8.3, 0.85), forgePos + V(x, 4.15, -0.8), wood, true)
		bar("CanopyBrace", forgePos + V(x, 5.8, -0.8), forgePos + V(x - (x > 0 and 2 or -2), 7.7, -0.8), 0.45, timber)
	end
	box("ForgeOverheadBeam", V(18, 1, 1.2), forgePos + V(0, 8.3, -0.8), timber, true)
	lantern(forgePos + V(6.5, 5.4, -0.8))
	local anvil = forgePos + V(4.6, 0, -5.6)
	cylinder("AnvilStump", anvil + V(0, 1.15, 0), 2.3, 2.8, wood, true)
	box("AnvilFoot", V(2.8, 0.4, 2), anvil + V(0, 2.5, 0), iron)
	box("AnvilWaist", V(1.4, 1.1, 1.25), anvil + V(0, 3.2, 0), iron)
	box("AnvilFace", V(3.5, 0.55, 1.6), anvil + V(0, 4.0, 0), C(114, 120, 121))
	local horn = Instance.new("WedgePart")
	horn.Name = "AnvilHorn"
	horn.Size = V(1.5, 0.55, 1.6)
	horn.CFrame = CFrame.new(anvil + V(2.5, 4, 0)) * CFrame.Angles(0, math.pi / 2, 0)
	horn.Color = iron
	horn.Anchored = true
	horn.CanCollide = false
	horn.CanTouch = false
	horn.CanQuery = false
	horn.Parent = parent
	bar("HammerHandle", anvil + V(-1.2, 4.35, -0.35), anvil + V(0.2, 4.35, 0.4), 0.18, wood)
	box("HammerHead", V(0.65, 0.5, 0.8), anvil + V(-1.2, 4.35, -0.35), iron)
	cylinder("WaterBucket", forgePos + V(-6, 0.8, -4.3), 1.6, 2.0, wood, true)
	cylinder("BucketWater", forgePos + V(-6, 1.62, -4.3), 0.05, 1.6, C(83, 145, 158), true)
	for j = 1, 3 do
		cylinder("BucketBand", forgePos + V(-6, 0.2 + j * 0.42, -4.3), 0.12, 2.03, iron, true)
	end
	crate(forgePos + V(7, 0, 4), 2.5)
	for j = 1, 4 do
		box(
			"StackedIronBar",
			V(3.4, 0.4, 0.65),
			forgePos + V(4.0, 0.3 + math.floor((j - 1) / 2) * 0.45, 3.5 + j % 2 * 0.8),
			iron,
			true
		)
	end
	finish(forge, forgePos)
	task.wait()
	local index = 0
	local function garden(pos, s, tall)
		index += 1
		local m = begin(tall and "AmberOutcrop" or "EmberShorePocket")
		rocks(pos, s, index)
		if tall then
			crystal(pos, 11.8 * s, 3.0 * s, amber, index * 0.6, true)
			crystal(pos + V(2.2 * s, 0, 1.5 * s), 7.5 * s, 2.1 * s, honey, -index, false)
			crystal(pos + V(-2 * s, 0, -0.5 * s), 5.8 * s, 1.9 * s, copper, index, false)
		else
			crystal(pos + V(1.5 * s, 0, 0), 1.5 * s, 0.8 * s, amber, index, false)
		end
		grass(pos + V(0, 0, -3 * s), s, index)
		finish(m, pos)
	end
	for sideIndex, side in ipairs({ -1, 1 }) do
		local times = side < 0 and { 16, 47, 68, 141, 166 } or { 18, 36, 106, 145, 168 }
		for _, t in ipairs(times) do
			garden(V(side < 0 and left + 7 or right - 7, high, front - t), 1.05, true)
		end
		for _j, t in ipairs({ 16, 40, 72, 96, 142, 159 }) do
			garden(V(side < 0 and left + 35 or right - 35, low, front - t), 0.55, false)
		end
		for j, t in ipairs({ 26, 85, 126, 155 }) do
			local pos = V(side < 0 and left + 4 or right - 4, high, front - t)
			local m = begin("RustPlantPocket")
			grass(pos, 1.1, j + sideIndex)
			finish(m, pos)
		end
		local path = begin("WarmStoneSteppingPath")
		for j = 1, 8 do
			box(
				"WeatheredSlab",
				V(3.5, 0.08, 3.0),
				V(side < 0 and left + 22 or right - 22, high + 0.05, front - 38 - j * 12),
				C(143, 127, 106),
				true,
				CFrame.Angles(0, math.rad(j % 3 * 8 - 8), 0)
			)
		end
		finish(path, V(side < 0 and left + 22 or right - 22, high, front - 90))
		task.wait()
	end
	faceLobby(root)
	root:SetAttribute("Version", 2)
	return root
end

return Ember
