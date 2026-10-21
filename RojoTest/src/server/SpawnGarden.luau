--!strict
-- Terraced spawn perimeter. Gameplay geometry and manually placed activities stay intact.
local Garden = {}
local C, V = Color3.fromRGB, Vector3.new
local STUDS = "rbxassetid://88156646156237"
local earth, grass = C(159, 111, 72), C(92, 205, 48)
local leaf, lightLeaf = C(47, 166, 55), C(125, 217, 62)
local stone, wood = C(135, 151, 157), C(135, 89, 49)

function Garden.apply(map)
	if map:FindFirstChild("SpawnGarden") then
		return map.SpawnGarden
	end
	assert(map.Name == "ProgressionMap", "Spawn garden is scoped to World 1")
	local frame = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
	local protected = {}
	for _, p in map:GetDescendants() do
		if p:IsA("BasePart") then
			protected[p] = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
		end
	end
	local storage = game.ServerStorage
	local backups = storage:FindFirstChild("WorldBackups") or Instance.new("Folder")
	backups.Name, backups.Parent = "WorldBackups", storage
	local backup = backups:FindFirstChild("BeforeSpawnGarden")
	if not backup then
		backup = Instance.new("Folder")
		backup.Name, backup.Parent = "BeforeSpawnGarden", backups
		for _, name in { "PerimeterWalls", "SurfaceRepairs", "EnvironmentPolish" } do
			local source = map:FindFirstChild(name)
			if source then
				-- Keep insertions bounded; avoid parenting one very large backup tree.
				local group = Instance.new("Model")
				group.Name, group.Parent = name, backup
				for i, item in source:GetChildren() do
					item:Clone().Parent = group
					if i % 40 == 0 then
						task.wait()
					end
				end
			end
		end
	end
	local root = Instance.new("Model")
	root.Name, root.WorldPivot, root.Parent = "SpawnGarden", frame, map
	root:SetAttribute("Version", 1)
	local function studs(p, face)
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "GardenStuds", STUDS, face
		t.StudsPerTileU, t.StudsPerTileV = 8, 8
		t.Transparency = 0.28
		-- Tile phase follows the shared world grid instead of restarting on each block.
		if face == Enum.NormalId.Top then
			t.OffsetStudsU = (p.Position.X - p.Size.X / 2) % 8
			t.OffsetStudsV = (p.Position.Z - p.Size.Z / 2) % 8
		else
			t.OffsetStudsU = (p.Position.X + p.Position.Z) % 8
			t.OffsetStudsV = (p.Position.Y - p.Size.Y / 2) % 8
		end
		t.Parent = p
	end
	local function model(name, base)
		local m = Instance.new("Model")
		m.Name, m.WorldPivot, m.Parent = name, frame * CFrame.new(base), root
		return m
	end
	local function part(parent, name, size, pos, color, yaw, textured, wedge)
		local p = Instance.new(wedge and "WedgePart" or "Part")
		p.Name, p.Size, p.Color = name, size, color
		p.CFrame = frame * CFrame.new(pos) * CFrame.Angles(0, yaw or 0, 0)
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Material = Enum.Material.Plastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		if textured then
			studs(p, Enum.NormalId.Top)
			if size.Y > 3 then
				studs(p, Enum.NormalId.Front)
			end
		end
		return p
	end
	local function rock(parent, base, scale, variant)
		part(parent, "Rock", V(5, 5.5, 4.8) * scale, base + V(0, 2.75, 0) * scale, stone, variant * 0.18, true)
		part(
			parent,
			"RockShoulder",
			V(4, 3.4, 4) * scale,
			base + V(3.1, 1.7, 0.7) * scale,
			stone:Lerp(C(192, 200, 185), 0.3),
			math.pi / 2,
			true,
			true
		)
		part(parent, "Pebble", V(2.8, 1.7, 3) * scale, base + V(-3, 0.85, 1) * scale, stone, -0.2, true)
	end
	local function bush(parent, base, scale)
		for i, a in { { 0, 1.8, 0, 5, 3.6, 4.5 }, { 3, 1.25, 1, 3.4, 2.5, 3.4 }, { -2.5, 1, 1.5, 3, 2, 3 } } do
			part(
				parent,
				"Bush",
				V(a[4], a[5], a[6]) * scale,
				base + V(a[1], a[2], a[3]) * scale,
				i == 2 and lightLeaf or leaf,
				(i - 2) * 0.1,
				true
			)
		end
	end
	local function flowers(parent, base, variant)
		local colors = { C(255, 236, 134), C(255, 143, 164), C(244, 251, 228) }
		for i = 1, 3 do
			local p = base + V((i - 2) * 1.5, 0, (i % 2) * 1.2)
			part(parent, "FlowerStem", V(0.18, 1.3, 0.18), p + V(0, 0.65, 0), leaf)
			part(parent, "FlowerPetals", V(0.95, 0.3, 0.95), p + V(0, 1.4, 0), colors[(variant + i) % 3 + 1])
			part(parent, "FlowerCenter", V(0.32, 0.15, 0.32), p + V(0, 1.62, 0), C(255, 206, 64))
		end
	end
	local function tree(parent, base, height, variant)
		local m = Instance.new("Model")
		m.Name, m.WorldPivot, m.Parent = "TerraceTree", frame * CFrame.new(base), parent
		part(m, "Trunk", V(1.8, height * 0.66, 1.8), base + V(0, height * 0.33, 0), wood, 0, true)
		for i, a in
			{
				{ -0.17, 0.73, 0, 0.55, 0.35, 0.52 },
				{ 0.19, 0.77, 0.08, 0.50, 0.32, 0.47 },
				{ 0, 0.96, -0.05, 0.43, 0.28, 0.43 },
			}
		do
			part(
				m,
				"Crown",
				V(a[4], a[5], a[6]) * height,
				base + V(a[1], a[2], a[3]) * height,
				i == 3 and lightLeaf or leaf,
				variant * 0.04,
				true
			)
		end
	end
	local function lantern(parent, base)
		part(parent, "LanternFoot", V(2.6, 0.7, 2.6), base + V(0, 0.35, 0), stone)
		part(parent, "LanternPost", V(0.6, 3.6, 0.6), base + V(0, 2.3, 0), wood)
		part(parent, "LanternFrame", V(2, 2.5, 2), base + V(0, 4.6, 0), wood)
		local pane = part(parent, "LanternGlass", V(2.05, 1.7, 1.65), base + V(0, 4.6, 0), C(255, 227, 138))
		pane.Material = Enum.Material.Neon
		part(parent, "LanternRoof", V(2.6, 0.4, 2.6), base + V(0, 6, 0), wood)
		local l = Instance.new("PointLight")
		l.Color, l.Brightness, l.Range, l.Shadows = C(255, 227, 167), 0.45, 11, false
		l.Parent = pane
	end
	local function vines(parent, base, side)
		for i = 1, 4 do
			local y = base.Y - i * 1.45
			local pos = V(base.X + math.sin(i * 1.7) * 0.7, y, base.Z)
			if side then
				pos = V(base.X, y, base.Z + math.sin(i * 1.7) * 0.7)
			end
			part(
				parent,
				"TrailingVine",
				V(side and 0.45 or 1.1, 1.75, side and 1.1 or 0.45),
				pos,
				i % 2 == 0 and leaf or lightLeaf
			)
		end
	end
	-- Disable only the old lobby checker treatment; keep the original boundary blockers.
	for _, name in { "LobbyLeft", "LobbyRight", "LobbyBack" } do
		local p = assert(map.PerimeterWalls:FindFirstChild(name))
		for _, d in p:GetDescendants() do
			if d:IsA("SurfaceGui") then
				d.Enabled = false
			end
			if d:IsA("Texture") or d:IsA("Decal") then
				d.Transparency = 1
			end
		end
		p.Color, p.Material = earth, Enum.Material.Plastic
		p.Transparency = 1
	end
	-- Existing panel skins are kept invisible in this perimeter, also on rebuilt maps.
	local oldGardens = map.EnvironmentPolish:FindFirstChild("LobbyGardens")
	if oldGardens then
		for _, p in oldGardens:GetDescendants() do
			if p:IsA("BasePart") then
				local pos = frame:PointToObjectSpace(p.Position)
				if pos.Y > 60 and pos.Z > 220 then
					p.Transparency = 1
					for _, t in p:GetChildren() do
						if t:IsA("Texture") or t:IsA("Decal") then
							t.Transparency = 1
						end
					end
				end
			end
		end
	end
	for _, container in { map.PerimeterWalls, map.SurfaceRepairs } do
		for _, p in container:GetChildren() do
			if p:IsA("BasePart") and p.Name:find("WallPanel") then
				local pos = frame:PointToObjectSpace(p.Position)
				if pos.Z > 0 then
					p.Transparency = 1
					for _, t in p:GetDescendants() do
						if t:IsA("Texture") or t:IsA("Decal") then
							t.Transparency = 1
						end
					end
				end
			end
		end
	end
	local shelfHeights = { 22, 43, 63 }
	for sideIndex, side in { { x = -220, inward = 1 }, { x = 8, inward = -1 } } do
		local group = model("SideTerraces" .. sideIndex, V(side.x, 0, 112))
		-- Short spans produce deliberate shifts in terrace silhouette without checker colouring.
		for level, y in shelfHeights do
			for segment = 1, 7 do
				local setback = (level - 1) * 9
				local span = segment == 7 and 32 + setback or 32
				local z = (segment - 0.5) * 32 + (segment == 7 and setback / 2 or 0)
				local depth = 40 - setback
				local rise = (segment % 3 == 0 and level ~= 3) and 2 or 0
				local top = y + rise
				local x = side.x - side.inward * (setback + depth / 2)
				local below = level == 1 and -2 or shelfHeights[level - 1] - 2
				local height = top - 1.6 - below
				part(group, "TerraceEarth", V(depth, height, span), V(x, below + height / 2, z), earth, 0, true)
				part(group, "GrassShelf", V(depth, 1.6, span), V(x, top - 0.8, z), grass, 0, true)
				local gardenX = side.x - side.inward * (setback + 4.5)
				if level == 3 or (depth >= 8 and segment % 2 == 1) then
					bush(group, V(gardenX, top, z - 8), 0.95)
					flowers(group, V(gardenX + side.inward * 1.5, top, z + 5), segment)
					if segment % 2 == 0 then
						rock(group, V(gardenX, top, z + 8), 0.75, segment)
					end
				end
				if level == 3 and segment % 2 == 1 then
					tree(group, V(gardenX - side.inward * 3, top, z), 18 + segment % 3 * 2, segment)
				elseif level == 2 and (segment == 2 or segment == 6) then
					tree(group, V(gardenX - side.inward * 1.5, top, z), 14, segment)
				end
				if level == 1 and (segment == 1 or segment == 6) then
					lantern(group, V(gardenX, top, z + 4))
				end
				if level > 1 and segment % 2 == 0 then
					vines(group, V(side.x - side.inward * setback + side.inward * 0.25, top - 0.5, z - 7), true)
				end
			end
		end
		for i, z in { 22, 179, 213 } do
			local x = side.x - side.inward * 8.5
			part(group, "RockColumn", V(6, 27, 7), V(x, 35.5, z), stone, 0, true)
			part(
				group,
				"RockSlope",
				V(6, 17, 8),
				V(x - side.inward * 2.5, 30.5, z + 3),
				stone:Lerp(earth, 0.15),
				side.inward * math.pi / 2,
				true,
				true
			)
			rock(group, V(x, 49, z), 0.8, i)
		end
		task.wait()
	end
	local rear = model("RearTerraces", V(-106, 0, 224))
	for level, y in shelfHeights do
		local setback = (level - 1) * 9
		local depth = 40 - setback
		local z = 224 + setback + depth / 2
		local below = level == 1 and -2 or shelfHeights[level - 1] - 2
		local height = y - 1.6 - below
		local width = 308
		part(rear, "RearEarthLedge", V(width, height, depth), V(-106, below + height / 2, z), earth, 0, true)
		part(rear, "RearGrassLedge", V(width, 1.6, depth), V(-106, y - 0.8, z), grass, 0, true)
		local gardenZ = 224 + setback + 4.5
		for i, x in { -204, -170, -42, -8 } do
			bush(rear, V(x, y, gardenZ), 1.05)
			flowers(rear, V(x + 5, y, gardenZ - 2), i)
			if level == 3 then
				tree(rear, V(x, y, gardenZ + 3), 18 + i % 2 * 3, i)
			end
		end
		if level == 2 then
			for i, x in { -140, -108, -76 } do
				bush(rear, V(x, y, gardenZ), 0.9)
				flowers(rear, V(x + 4, y, gardenZ), i)
			end
		end
		for _, x in { -183, -154, -55, -16 } do
			vines(rear, V(x, y - 0.5, 224 + setback - 0.2), false)
		end
	end
	-- Waterfalls flank the leaderboards, leaving the rear activity approach unobstructed.
	for i, x in { -194, -24 } do
		local base = V(x, 0.1, 214)
		local m = model("CornerWaterfall" .. i, base)
		for _, dx in { -8, 8 } do
			part(m, "WaterfallRock", V(5, 42, 8), V(x + dx, 21, 219), stone, 0, true)
			part(m, "RockGrassCap", V(5.8, 1.2, 8.8), V(x + dx, 42.6, 219), grass, 0, true)
		end
		local water = part(m, "WaterCurtain", V(10, 41, 0.7), V(x, 21.3, 214.1), C(37, 211, 238))
		water.Material, water.Transparency = Enum.Material.Glass, 0.22
		for j = -2, 2 do
			local streak = part(m, "WaterStreak", V(0.16, 39, 0.12), V(x + j * 1.6, 21.3, 213.68), C(176, 247, 250))
			streak.Material, streak.Transparency = Enum.Material.Neon, 0.42
		end
		part(m, "PoolBasin", V(17, 0.55, 9), V(x, 0.3, 210), stone)
		local pool = part(m, "PoolWater", V(15, 0.22, 7), V(x, 0.7, 210), C(40, 209, 226))
		pool.Material, pool.Transparency = Enum.Material.Glass, 0.15
		for _, dx in { -8, 8 } do
			part(m, "PoolRim", V(1, 0.9, 9), V(x + dx, 0.5, 210), stone, 0, true)
		end
		for _, dz in { -4, 4 } do
			part(m, "PoolRim", V(17, 0.9, 1), V(x, 0.5, 210 + dz), stone, 0, true)
		end
		bush(m, V(x + 12, 0.05, 213), 0.85)
		flowers(m, V(x + 11, 0.05, 208), i)
		lantern(m, V(x - 12, 0.05, 209))
		task.wait()
	end
	-- Compact planted pockets enhance empty corners without moving the author's trees.
	for i, pos in { V(-199, 0.05, 24), V(-187, 0.05, 178), V(-30, 0.05, 209), V(-15, 0.05, 35) } do
		local m = model("GroundGarden" .. i, pos)
		bush(m, pos, 1)
		rock(m, pos + V(5, 0, 3), 0.6, i)
		flowers(m, pos + V(-4, 0, -4), i)
		if i <= 2 then
			lantern(m, pos + V(4, 0, -6))
		end
	end
	local checks = 0
	for p, state in protected do
		assert(p.CFrame == state[1] and p.Size == state[2], "Garden moved original geometry: " .. p:GetFullName())
		assert(
			p.CanCollide == state[3] and p.CanTouch == state[4] and p.CanQuery == state[5],
			"Garden changed collision: " .. p:GetFullName()
		)
		checks += 1
	end
	root:SetAttribute("ProtectedPartsChecked", checks)
	return root
end

return Garden
