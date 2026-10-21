--!strict
-- Adds dense planted terrace pockets and seals the lobby/corridor corner junction.
local Polish = {}
local V, C = Vector3.new, Color3.fromRGB
local STUDS = "rbxassetid://88156646156237"
local leaf, lime, grass = C(42, 156, 58), C(124, 211, 65), C(92, 205, 48)
local earth, stone = C(159, 111, 72), C(137, 153, 155)

function Polish.apply(map)
	if map:FindFirstChild("SpawnGardenPolish") then
		return map.SpawnGardenPolish
	end
	assert(map.Name == "ProgressionMap" and map:FindFirstChild("SpawnGarden"), "Spawn garden is missing")
	local frame = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
	local protected = {}
	for _, p in map:GetDescendants() do
		if p:IsA("BasePart") then
			protected[p] = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
		end
	end
	local backups = assert(game.ServerStorage:FindFirstChild("WorldBackups"))
	if not backups:FindFirstChild("BeforeSpawnGardenPolish") then
		local backup = Instance.new("Model")
		backup.Name, backup.Parent = "BeforeSpawnGardenPolish", backups
		for _, child in map.SpawnGarden:GetChildren() do
			child:Clone().Parent = backup
			task.wait()
		end
	end
	local root = Instance.new("Model")
	root.Name, root.WorldPivot, root.Parent = "SpawnGardenPolish", frame, map
	root:SetAttribute("Version", 1)
	local function group(name, origin)
		local m = Instance.new("Model")
		m.Name, m.WorldPivot, m.Parent = name, frame * CFrame.new(origin), root
		return m
	end
	local function studs(p, face)
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "HDGardenStuds", STUDS, face
		t.StudsPerTileU, t.StudsPerTileV, t.Transparency = 8, 8, 0.35
		t.Parent = p
	end
	local function part(parent, name, size, position, color, yaw, collide, wedge)
		local p = Instance.new(wedge and "WedgePart" or "Part")
		p.Name, p.Size, p.Color = name, size, color
		p.CFrame = frame * CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, collide == true, false, collide == true
		p.Material = Enum.Material.Plastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end
	local function shrub(parent, base, scale)
		for i, offset in { V(0, 0, 0), V(2.8, 0, 1.5), V(-2, 0, 2.2) } do
			local size = V(i == 1 and 4.6 or 3.4, i == 1 and 3.3 or 2.5, i == 1 and 4.3 or 3.5) * scale
			local p = part(
				parent,
				"LayeredShrub",
				size,
				base + offset * scale + V(0, size.Y / 2, 0),
				i == 2 and lime or leaf,
				(i - 2) * 0.12
			)
			studs(p, Enum.NormalId.Top)
		end
	end
	local function flower(parent, base, variant, scale)
		local tint = ({ C(255, 240, 184), C(255, 167, 191), C(246, 254, 236) })[variant % 3 + 1]
		part(parent, "Stem", V(0.2, 1.6, 0.2) * scale, base + V(0, 0.8, 0) * scale, leaf)
		part(parent, "Petals", V(2.25, 0.36, 0.95) * scale, base + V(0, 1.65, 0) * scale, tint)
		part(parent, "Petals", V(0.95, 0.36, 2.25) * scale, base + V(0, 1.67, 0) * scale, tint)
		part(parent, "Pollen", V(0.65, 0.45, 0.65) * scale, base + V(0, 1.77, 0) * scale, C(255, 194, 51))
	end
	local function rocks(parent, base, scale, variant)
		local p = part(parent, "StoneMass", V(5.2, 7, 5) * scale, base + V(0, 3.5, 0) * scale, stone, variant * 0.14)
		studs(p, Enum.NormalId.Top)
		p = part(
			parent,
			"StoneShoulder",
			V(5, 4.5, 5.5) * scale,
			base + V(2.8, 2.25, 1.5) * scale,
			C(163, 173, 172),
			math.pi / 2,
			false,
			true
		)
		studs(p, Enum.NormalId.Top)
		part(parent, "SmallStone", V(2.7, 2.2, 3) * scale, base + V(-3.1, 1.1, 2) * scale, stone, -0.15)
	end
	local function lantern(parent, base)
		part(parent, "LanternPlinth", V(2.8, 1, 2.8), base + V(0, 0.5, 0), stone)
		part(parent, "LanternFrame", V(2.3, 3, 2.3), base + V(0, 2.5, 0), C(117, 77, 43))
		local pane = part(parent, "LanternLight", V(2.4, 1.8, 1.8), base + V(0, 2.5, 0), C(255, 229, 145))
		pane.Material = Enum.Material.Neon
		part(parent, "LanternCap", V(2.9, 0.5, 2.9), base + V(0, 4.25, 0), C(117, 77, 43))
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = C(255, 229, 174), 12, 0.6, false
		l.Parent = pane
	end
	-- Work from actual cap surfaces, including the authored variations in shelf height.
	for _, sideName in { "SideTerraces1", "SideTerraces2", "RearTerraces" } do
		local source = assert(map.SpawnGarden:FindFirstChild(sideName))
		local side = sideName == "SideTerraces1" and 1 or -1
		local rear = sideName == "RearTerraces"
		local planted = group(sideName .. "Planting", V(0, 0, 0))
		local index = 0
		for _, cap in source:GetChildren() do
			if not cap:IsA("BasePart") or (cap.Name ~= "GrassShelf" and cap.Name ~= "RearGrassLedge") then
				continue
			end
			local q = frame:PointToObjectSpace(cap.Position)
			local top = q.Y + cap.Size.Y / 2
			local edge = rear and q.Z - cap.Size.Z / 2 or q.X + side * cap.Size.X / 2
			local length = rear and cap.Size.X or cap.Size.Z
			local start = rear and q.X - length / 2 or q.Z - length / 2
			for along = 8, length - 5, 13 do
				index += 1
				local base = rear and V(start + along, top, edge + 3.7) or V(edge - side * 3.7, top, start + along)
				local offset = rear and V(4.7, 0, -1.8) or V(side * 1.8, 0, 4.7)
				shrub(planted, base, index % 3 == 0 and 0.7 or 0.9)
				for j = 1, 3 do
					flower(planted, base + offset + (rear and V(j * 1.8, 0, 0) or V(0, 0, j * 1.8)), index + j, 0.8)
				end
				if index % 4 == 0 then
					rocks(planted, base + (rear and V(-4, 0, 0.8) or V(-side * 0.8, 0, -4)), 0.7, index)
				end
				if index % 9 == 0 then
					lantern(planted, base + (rear and V(0, 0, 0.5) or V(-side * 0.5, 0, 0)))
				end
			end
			task.wait()
		end
		task.wait()
	end
	-- Add clustered stone outcrops at the base of the formerly uniform tall columns.
	for sideIndex, x in { -228.5, 16.5 } do
		local m = group("StoneOutcrops" .. sideIndex, V(x, 22, 0))
		for i, z in { 22, 179, 213 } do
			rocks(m, V(x, 22, z), 1.2, i)
			shrub(m, V(x + (sideIndex == 1 and 2 or -2), 22, z + 5), 0.75)
		end
	end
	local tunnel = group("EntranceTunnel", V(-116, 0, -19))
	-- These physical abutments overlap both original wall ends by at least two studs.
	part(tunnel, "LeftAbutment", V(42, 69, 46), V(-240, 28.5, -20), earth, 0, true)
	part(tunnel, "RightAbutment", V(62, 69, 46), V(18, 28.5, -20), earth, 0, true)
	local roof = part(tunnel, "TunnelRoof", V(310, 6, 46), V(-106, 60, -20), earth, 0, true)
	studs(roof, Enum.NormalId.Front)
	local turf = part(tunnel, "TunnelGrassRoof", V(310, 1.6, 46), V(-106, 63.8, -20), grass)
	studs(turf, Enum.NormalId.Top)
	-- The existing entrance barrier remains intact; the roof clears the walkable banks.
	for _, z in { 3.4, -43.4 } do
		part(tunnel, "StoneLintel", V(211, 3.2, 2), V(-116, 55.4, z), stone)
		for _, x in { -216, -16 } do
			part(tunnel, "StoneArchLeg", V(5.5, 47, 2.2), V(x, 31.9, z), stone)
			part(
				tunnel,
				"ArchShoulder",
				V(9, 10, 2.3),
				V(x + (x < -116 and 4 or -4), 49, z),
				stone,
				x < -116 and math.pi / 2 or -math.pi / 2,
				false,
				true
			)
		end
	end
	-- Hidden foundation catches a slip at a seam without raising the authored bank surfaces.
	for i, span in { { x = -196, width = 48 }, { x = -36, width = 48 } } do
		local floor = part(tunnel, "BankSafetyFloor" .. i, V(span.width, 4, 50), V(span.x, -3, -21), earth, 0, true)
		floor.Transparency = 1
	end
	for i, x in { -245, -215, -185, -155, -125, -95, -65, -35, -5, 25 } do
		shrub(tunnel, V(x, 64.6, -8), 1.2)
		for j = 1, 3 do
			flower(tunnel, V(x + j * 2, 64.6, -5), i + j, 1)
		end
		if i % 3 == 0 then
			rocks(tunnel, V(x, 64.6, -31), 1.2, i)
		end
	end
	local treeTemplate = map.SpawnGarden.SideTerraces1:FindFirstChild("TerraceTree")
	if treeTemplate then
		for _, x in { -244, -190, -28, 33 } do
			local tree = treeTemplate:Clone()
			tree.Name = "TunnelRoofTree"
			tree:ScaleTo(tree:GetScale() * 0.78)
			tree:PivotTo(frame * CFrame.new(x, 64.6, -23))
			tree.Parent = tunnel
		end
	end
	for _, x in { -211, -21 } do
		lantern(tunnel, V(x, 9.1, -10))
		lantern(tunnel, V(x, 9.1, -35))
	end
	-- Continual exterior backstops prevent jumping over a decorative terrace into the void.
	for _, span in
		{
			{ name = "LeftOuterGuard", size = V(4, 125, 312), position = V(-263, 55, 109) },
			{ name = "RightOuterGuard", size = V(4, 125, 312), position = V(51, 55, 109) },
			{ name = "RearOuterGuard", size = V(318, 125, 4), position = V(-106, 55, 267) },
		}
	do
		local p = part(tunnel, span.name, span.size, span.position, earth, 0, true)
		p.Transparency = 1
	end
	local checked = 0
	for p, state in protected do
		assert(p.CFrame == state[1] and p.Size == state[2], "Polish moved an authored object")
		assert(
			p.CanCollide == state[3] and p.CanTouch == state[4] and p.CanQuery == state[5],
			"Polish changed authored collisions"
		)
		checked += 1
	end
	root:SetAttribute("ProtectedPartsChecked", checked)
	return root
end

return Polish
