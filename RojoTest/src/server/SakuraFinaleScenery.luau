--!strict
local Finale = {}

function Finale.apply(map)
	local world = map.SkippingWorld
	if world:FindFirstChild("SakuraThreshold") then
		return
	end
	local V, C = Vector3.new, Color3.fromRGB
	local left, right, upper, lower = math.huge, -math.huge, nil, nil
	for _, p in ipairs(world:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "BiomeBank8_2" then
			left = math.min(left, p.Position.X - p.Size.X / 2)
			right = math.max(right, p.Position.X + p.Size.X / 2)
			upper = p
		elseif p:IsA("BasePart") and p.Name == "BiomeBank8_1" then
			lower = p
		end
	end
	assert(upper and lower, "Final biome banks missing")
	local high, low = upper.Position.Y + upper.Size.Y / 2, lower.Position.Y + lower.Size.Y / 2
	local front, back = upper.Position.Z + upper.Size.Z / 2, upper.Position.Z - upper.Size.Z / 2
	local garden = map.NativeEnvironment.ShoreGardens.BiomeGarden8
	local trees = {}
	for _, m in ipairs(garden:GetChildren()) do
		if m:IsA("Model") and m.Name == "RobloxOak" then
			table.insert(trees, m)
		end
	end
	assert(#trees > 0, "Authored tree templates missing")
	local backups = game.ServerStorage.WorldBackups
	local old = backups:FindFirstChild("BeforeSakuraThreshold")
	if not old then
		old = Instance.new("Folder")
		old.Name = "BeforeSakuraThreshold"
		old.Parent = backups
	end
	local function hide(object)
		object:Clone().Parent = old
		local list = object:GetDescendants()
		table.insert(list, object)
		for _, p in ipairs(list) do
			if p:IsA("BasePart") then
				p.Transparency = 1
				p:SetAttribute("FinaleVisualHidden", true)
			elseif p:IsA("Texture") or p:IsA("Decal") then
				p.Transparency = 1
			elseif p:IsA("Light") then
				p.Enabled = false
			end
		end
	end
	for _, m in ipairs(trees) do
		hide(m)
	end
	local legacyTrees = map.NativeEnvironment:FindFirstChild("Trees")
	if legacyTrees then
		for _, m in ipairs(legacyTrees:GetChildren()) do
			local trunk = m:FindFirstChild("TrunkBase")
			if trunk and trunk:IsA("BasePart") and trunk.Position.Z > back and trunk.Position.Z < front then
				hide(m)
			end
		end
	end
	for _, p in ipairs(world:GetChildren()) do
		if
			p:IsA("BasePart")
			and p.Position.Z > back
			and p.Position.Z < front
			and p.Transparency < 1
			and (p.Name == "BiomeDecorStem" or p.Name == "CandyCrown")
		then
			hide(p)
		end
	end
	local root = Instance.new("Model")
	root.Name = "SakuraThreshold"
	local parent = root
	local stone, dark, moss, wood, pink, rose, pearl, mint, cream, amber =
		C(143, 145, 155),
		C(105, 108, 124),
		C(145, 188, 111),
		C(130, 83, 49),
		C(244, 163, 211),
		C(220, 126, 183),
		C(255, 231, 236),
		C(213, 236, 191),
		C(250, 237, 210),
		C(255, 214, 135)
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
	local function _bar(name, a, b, w, color)
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
	local function blossom(pos, s, color, cf)
		cf = cf or CFrame.new(pos)
		for j = 1, 5 do
			local a = j * math.pi * 2 / 5
			part(
				"SakuraPetal",
				V(0.14 * s, 0.85 * s, 0.85 * s),
				cf * CFrame.new(math.cos(a) * 0.4 * s, 0, math.sin(a) * 0.4 * s) * CFrame.Angles(0, 0, math.pi / 2),
				color,
				false,
				Enum.PartType.Cylinder
			)
		end
		part(
			"SakuraHeart",
			V(0.18 * s, 0.36 * s, 0.36 * s),
			cf * CFrame.new(0, 0.09 * s, 0) * CFrame.Angles(0, 0, math.pi / 2),
			cream,
			false,
			Enum.PartType.Cylinder
		)
	end
	local function flowers(pos, s, index)
		for j = 1, 5 do
			local a = j * 1.26 + index
			local c = pos + V(math.cos(a) * 1.4 * s, 0.8 * s, math.sin(a) * 1.3 * s)
			box("FlowerStem", V(0.12 * s, 0.8 * s, 0.12 * s), c - V(0, 0.4 * s, 0), moss)
			box(
				"BroadFlowerLeaf",
				V(0.8 * s, 0.14 * s, 0.55 * s),
				c - V(0, 0.35 * s, 0),
				moss,
				false,
				CFrame.Angles(0, a, 0)
			)
			blossom(c, 0.8 * s, j % 2 == 0 and pearl or pink)
		end
	end
	local function rockGarden(pos, s, index)
		for j = 1, 4 do
			local a = j * math.pi / 2 + index
			local c = pos + V(math.cos(a) * 1.8 * s, 0.65 * s, math.sin(a) * 1.7 * s)
			box(
				"GardenStone",
				V(2.2 * s, 1.3 * s, 2.1 * s),
				c,
				j % 2 == 0 and stone or dark,
				true,
				CFrame.Angles(0, a, math.rad(j % 2 * 8))
			)
			box("StoneMoss", V(1.4 * s, 0.18 * s, 1.4 * s), c + V(0, 0.76 * s, 0), moss, true, CFrame.Angles(0, a, 0))
		end
		flowers(pos + V(0, 0, 1.7 * s), s, index)
	end
	local function sakura(source, pos, scale, index)
		local tree = source:Clone()
		tree.Name = "FloweringSakura"
		tree:ScaleTo(tree:GetScale() * scale)
		tree:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad((index % 3 - 1) * 12), 0))
		local phase = (front - pos.Z) / (front - back)
		local blossomPink, blossomRose, blossomPale = C(255, 145, 180), C(255, 124, 167), C(255, 211, 225)
		local colors = phase < 0.26 and { mint, cream, blossomPink, pearl }
			or { blossomPink, blossomRose, blossomPale, blossomPink }
		local crowns = {}
		for _, p in ipairs(tree:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.Transparency = 0
				p:SetAttribute("FinaleVisualHidden", nil)
				if p.Name == "LeafCrown" then
					table.insert(crowns, p)
				end
			elseif p:IsA("Texture") or p:IsA("Decal") then
				p.Transparency = 0
			end
		end
		parent = tree
		for j, p in ipairs(crowns) do
			local size = p.Size
			p.Color = colors[(j + index) % #colors + 1]
			p.Name = "BlossomCloudCore"
			p.Size = size * 0.82
			for _, t in ipairs(p:GetChildren()) do
				if t:IsA("Texture") then
					t.Color3 = C(255, 255, 255)
				end
			end
			for k = 1, 5 do
				local a = k * math.pi * 2 / 5 + j * 0.6
				part(
					"BlossomCloud",
					V(size.X * 0.4, size.Y * 0.65, size.Z * 0.4),
					p.CFrame
						* CFrame.new(
							math.cos(a) * size.X * 0.34,
							(k % 2 - 0.5) * size.Y * 0.23,
							math.sin(a) * size.Z * 0.34
						)
						* CFrame.Angles(0, a, 0),
					colors[(j + k + index) % #colors + 1],
					true
				)
			end
		end
		finish(tree, pos)
		local under = begin("SakuraTreeFlowers")
		flowers(pos + V(3.1, 0, 1.2), 1.1, index)
		finish(under, pos + V(3.1, 0, 1.2))
	end
	-- Authored trunks retain their invisible collision volumes; replacement visuals
	-- use their pivots. Extra crowns become pinker and fuller toward the end.
	for i, m in ipairs(trees) do
		local p = m:GetPivot().Position
		sakura(m, V(p.X, high, p.Z), 1, i)
	end
	root.WorldPivot = CFrame.new((left + right) / 2, high, (front + back) / 2)
	root.Parent = world
	task.wait()
	local n = 4
	for _, side in ipairs({ -1, 1 }) do
		for _, t in ipairs({ 24, 99, 157 }) do
			n += 1
			local pos = V(side < 0 and left + 12 or right - 12, high, front - t)
			sakura(trees[1], pos, t == 157 and 1.12 or 0.9, n)
			task.wait()
		end
	end
	local function stoneLantern(pos, s)
		box("LanternFoundation", V(3.6 * s, 0.45 * s, 3.6 * s), pos + V(0, 0.225 * s, 0), stone, true)
		box("LanternPlinth", V(2.8 * s, 0.5 * s, 2.8 * s), pos + V(0, 0.7 * s, 0), dark, true)
		box("StoneLanternStem", V(1.15 * s, 2.6 * s, 1.15 * s), pos + V(0, 2.2 * s, 0), stone, true)
		box("LanternChamberFloor", V(2.4 * s, 0.4 * s, 2.4 * s), pos + V(0, 3.6 * s, 0), stone, true)
		local glow = box("WarmGardenLantern", V(1.45 * s, 1.45 * s, 1.45 * s), pos + V(0, 4.5 * s, 0), amber)
		glow.Material = Enum.Material.Neon
		glow.Transparency = 0.1
		for _, x in ipairs({ -1, 1 }) do
			for _, z in ipairs({ -1, 1 }) do
				box("LanternStoneCorner", V(0.3 * s, 1.6 * s, 0.3 * s), pos + V(x * s, 4.5 * s, z * s), dark)
			end
		end
		box("LanternRoof", V(3.5 * s, 0.55 * s, 3.5 * s), pos + V(0, 5.5 * s, 0), stone, true)
		box("LanternRoofCap", V(2.5 * s, 0.5 * s, 2.5 * s), pos + V(0, 6.0 * s, 0), stone, true)
		box("LanternFinial", V(0.6 * s, 0.6 * s, 0.6 * s), pos + V(0, 6.5 * s, 0), dark)
		local light = Instance.new("PointLight")
		light.Color = amber
		light.Brightness = 0.65
		light.Range = 12 * s
		light.Shadows = false
		light.Parent = glow
	end
	local benchPos = V(left + 14, high, front - 68)
	local bench = begin("SakuraViewingBench")
	local cf = CFrame.new(benchPos) * CFrame.Angles(0, math.pi / 2, 0)
	for _, x in ipairs({ -3.2, 3.2 }) do
		part("BenchLeg", V(0.7, 2.0, 1.8), cf * CFrame.new(x, 1, 0), wood, true)
		part("BenchBackPost", V(0.45, 3.6, 0.45), cf * CFrame.new(x, 2, -1), wood)
	end
	for j = 0, 2 do
		part("BenchSeatSlat", V(8.3, 0.3, 0.55), cf * CFrame.new(0, 2.0, -0.6 + j * 0.6), wood, true)
	end
	for j = 0, 2 do
		part("BenchBackSlat", V(8.3, 0.55, 0.3), cf * CFrame.new(0, 2.6 + j * 0.7, -1), wood, true)
	end
	for _, x in ipairs({ -4, 4 }) do
		part("BenchArmrest", V(0.3, 0.3, 2.2), cf * CFrame.new(x, 3, 0), wood)
	end
	local planterPos = cf:PointToWorldSpace(V(-6.3, 0, 0))
	box("WoodFlowerPlanter", V(3.5, 1.0, 2.6), planterPos + V(0, 0.5, 0), wood, true)
	box("PlanterSoil", V(3.0, 0.15, 2.1), planterPos + V(0, 1.05, 0), dark)
	flowers(planterPos + V(0, 1.1, 0), 0.75, 10)
	finish(bench, benchPos)
	local bannerPos = V(right - 12, high, front - 79)
	local banners = begin("BlossomBannerGarden")
	rockGarden(bannerPos, 1.2, 11)
	for _, side in ipairs({ -1, 1 }) do
		local pos = bannerPos + V(0, 0, side * 5.0)
		box("BannerPost", V(0.35, 7.4, 0.35), pos + V(0, 3.7, 0), wood)
		box("BannerCrossbar", V(3.1, 0.3, 0.35), pos + V(0.8, 6.8, 0), wood)
		box("RoseBanner", V(2.6, 4.7, 0.16), pos + V(0.9, 4.3, 0), rose)
		blossom(nil, 0.95, pearl, CFrame.new(pos + V(0.9, 4.8, 0.15)) * CFrame.Angles(math.pi / 2, 0, 0))
	end
	stoneLantern(bannerPos + V(-4.6, 0, 0), 0.85)
	finish(banners, bannerPos)
	task.wait()
	for _, side in ipairs({ -1, 1 }) do
		for j, t in ipairs({ 36, 109, 150 }) do
			local pos = V(side < 0 and left + 18 or right - 18, high, front - t)
			local m = begin("SakuraLanternGarden")
			stoneLantern(pos, j == 3 and 1.0 or 0.85)
			flowers(pos + V(1.8, 0, 2.0), 0.9, j)
			finish(m, pos)
		end
		for j, t in ipairs({ 18, 48, 83, 117, 145 }) do
			local pos = V(side < 0 and left + 42 or right - 42, low, front - t)
			local m = begin("InnerBlossomRockGarden")
			rockGarden(pos, 0.85, j)
			finish(m, pos)
		end
		for j, t in ipairs({ 14, 64, 124, 151 }) do
			local pos = V(side < 0 and left + 6 or right - 6, high, front - t)
			local m = begin("OuterBlossomPocket")
			flowers(pos, 1.05, j + 8)
			finish(m, pos)
		end
		local path = begin("SakuraApproachPavers")
		for j = 1, 11 do
			box(
				"WarmGrayPaver",
				V(4.4, 0.08, 4.5),
				V(side < 0 and left + 30.5 or right - 30.5, low + 0.05, front - 10 - j * 12.5),
				stone,
				true,
				CFrame.Angles(0, math.rad(j % 3 * 5 - 5), 0)
			)
		end
		finish(path, V(side < 0 and left + 30.5 or right - 30.5, low, front - 12))
		local petals = begin("ScatteredSakuraPetals")
		for j = 1, 22 do
			local t = 15 + j * 6.2
			local x = side < 0 and left + 18 + j % 3 * 2.0 or right - 18 - j % 3 * 2.0
			box(
				"FallenPetal",
				V(0.4, 0.035, 0.65),
				V(x, high + 0.04, front - t),
				j % 3 == 0 and pearl or pink,
				false,
				CFrame.Angles(0, j * 0.7, 0)
			)
		end
		finish(petals, V(side < 0 and left + 20 or right - 20, high, front - 12))
		task.wait()
	end
	-- Moss uses actual authored rock crests, without moving their collision volumes.
	for _, p in ipairs(map.NativeEnvironment:GetDescendants()) do
		if
			p:IsA("BasePart")
			and p.Name == "RockCrest"
			and p.Transparency < 1
			and p.Position.Z > back
			and p.Position.Z < front
		then
			local cap = part(
				"AuthoredRockMoss",
				V(p.Size.X * 0.65, 0.16, p.Size.Z * 0.7),
				p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.08, 0),
				moss,
				true
			)
			cap:SetAttribute("MossSupportFrame", p.CFrame)
			cap:SetAttribute("MossSupportSize", p.Size)
		end
	end
	root:SetAttribute("Version", 1)
	root:SetAttribute("PortalNotBuilt", true)
	return root
end

return Finale
