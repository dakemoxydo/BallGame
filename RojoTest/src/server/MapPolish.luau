--!strict
-- Additive visual pass for the existing v9 map. Never regenerates authored geometry.
local MapPolish = {}
local VERSION = 1
local TEXTURE = "rbxassetid://88156646156237"
local C, V = Color3.fromRGB, Vector3.new
local palettes = {
	{
		ground = C(119, 210, 65),
		leaf = C(63, 174, 65),
		light = C(135, 216, 71),
		rock = C(137, 148, 122),
		wall = C(160, 121, 80),
	},
	{
		ground = C(244, 217, 139),
		leaf = C(30, 158, 95),
		light = C(90, 204, 100),
		rock = C(190, 165, 112),
		wall = C(191, 151, 99),
	},
	{
		ground = C(207, 235, 248),
		leaf = C(114, 196, 224),
		light = C(204, 244, 255),
		rock = C(127, 170, 191),
		wall = C(133, 169, 191),
	},
	{
		ground = C(233, 154, 83),
		leaf = C(107, 159, 72),
		light = C(165, 197, 94),
		rock = C(172, 102, 67),
		wall = C(171, 112, 76),
	},
	{
		ground = C(117, 100, 172),
		leaf = C(163, 108, 223),
		light = C(210, 162, 250),
		rock = C(88, 76, 127),
		wall = C(105, 88, 142),
	},
}

local function texture(part, face)
	local name = "HDStuds_" .. face.Name
	if part:FindFirstChild(name) then
		return
	end
	local t = Instance.new("Texture")
	t.Name, t.Texture, t.Face = name, TEXTURE, face
	-- Reference contains four studs per axis; each stud has a two-stud pitch.
	t.StudsPerTileU, t.StudsPerTileV = 8, 8
	t.Color3 = part.Color
	if face == Enum.NormalId.Top then
		t.OffsetStudsU = (part.Position.X - part.Size.X / 2) % 8
		t.OffsetStudsV = (part.Position.Z - part.Size.Z / 2) % 8
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		t.OffsetStudsU = (part.Position.Z - part.Size.Z / 2) % 8
		t.OffsetStudsV = (part.Position.Y - part.Size.Y / 2) % 8
	end
	t.Parent = part
end

function MapPolish.apply(root)
	assert(root and root:IsA("Model"), "ProgressionMap model required")
	assert(root:GetAttribute("Version") == 9, "Visual pass requires the authored v9 layout")
	if root:GetAttribute("VisualPolishVersion") == VERSION then
		return root
	end
	assert(not root:FindFirstChild("EnvironmentPolish"), "Existing visual pass needs review before replacement")
	for _, name in { "Lobby", "WaterCorridor", "TrainingZone", "PerimeterWalls", "EmptyItemStand", "CorridorBarriers" } do
		assert(root:FindFirstChild(name), "Missing map group: " .. name)
	end
	local protected = {}
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") then
			protected[p] = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
		end
	end
	if root:IsDescendantOf(workspace) then
		local storage = game:GetService("ServerStorage")
		local backups = storage:FindFirstChild("WorldBackups") or Instance.new("Folder")
		backups.Name, backups.Parent = "WorldBackups", storage
		local backup = root:Clone()
		backup.Name = "ProgressionMap_BeforeVisualPolish_" .. os.date("%Y%m%d_%H%M%S")
		backup.Parent = backups
	end
	local decor = Instance.new("Model")
	decor.Name, decor.Parent = "EnvironmentPolish", root
	local function model(parent, name)
		local m = Instance.new("Model")
		m.Name, m.Parent = name, parent
		return m
	end
	local function part(parent, name, size, pos, color, yaw, wedge)
		local p = Instance.new(if wedge then "WedgePart" else "Part")
		p.Name, p.Size, p.Color = name, size, color
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw or 0, 0)
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Material = Enum.Material.Plastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		texture(p, Enum.NormalId.Top)
		if size.Y > 3 then
			texture(p, Enum.NormalId.Front)
			texture(p, Enum.NormalId.Right)
			texture(p, Enum.NormalId.Back)
			texture(p, Enum.NormalId.Left)
		end
		return p
	end
	local function bush(parent, x, z, y, s, palette)
		local m = model(parent, "ShrubCluster")
		part(m, "Shrub", V(7 * s, 4 * s, 6 * s), V(x, y + 2 * s, z), palette.leaf, 0.1)
		part(m, "Shrub", V(5 * s, 3 * s, 5 * s), V(x + 3 * s, y + 1.5 * s, z + 2 * s), palette.light, -0.2)
		part(m, "Shrub", V(4 * s, 3 * s, 4 * s), V(x - 2.5 * s, y + 1.5 * s, z + 2 * s), palette.leaf, 0.3)
		m.WorldPivot = CFrame.new(x, y, z)
	end
	local function rocks(parent, x, z, y, s, palette)
		local m = model(parent, "RockCluster")
		part(m, "RockMass", V(8 * s, 7 * s, 7 * s), V(x, y + 3.5 * s, z), palette.rock, 0.12)
		part(
			m,
			"RockSlope",
			V(6 * s, 5 * s, 8 * s),
			V(x - 4 * s, y + 2.5 * s, z + 1 * s),
			palette.rock:Lerp(palette.ground, 0.15),
			math.pi / 2,
			true
		)
		part(
			m,
			"SmallRock",
			V(4 * s, 2 * s, 5 * s),
			V(x + 5 * s, y + s, z + 3 * s),
			palette.rock:Lerp(palette.ground, 0.28),
			-0.2
		)
		m.WorldPivot = CFrame.new(x, y, z)
	end
	local function tree(parent, x, z, y, scale, palette)
		local m = model(parent, "BlockTree")
		part(m, "Trunk", V(2.4 * scale, 11 * scale, 2.4 * scale), V(x, y + 5.5 * scale, z), C(134, 88, 49))
		part(m, "Crown", V(12 * scale, 7 * scale, 11 * scale), V(x, y + 12 * scale, z), palette.leaf)
		part(
			m,
			"CrownTop",
			V(8 * scale, 4 * scale, 8 * scale),
			V(x - 1.5 * scale, y + 17.5 * scale, z + scale),
			palette.light
		)
		m.WorldPivot = CFrame.new(x, y, z)
	end
	-- Preserve floor geometry and all gameplay markers while removing accidental patchwork.
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and not p:IsDescendantOf(decor) then
			local zone = p.Parent
			local biome = zone and tonumber(string.sub(zone.Name, 1, 2))
			local palette = palettes[biome or 1]
			if p.Name == "GroundTile" then
				p.Color, p.Material, p.TopSurface = palette.ground, Enum.Material.Plastic, Enum.SurfaceType.Smooth
				texture(p, Enum.NormalId.Top)
			elseif p.Name == "WallPanel" or p.Name == "BackWallPanel" then
				local index = math.clamp(math.floor(-p.Position.Z / 256) + 1, 1, 5)
				p.Color, p.Material, p.TopSurface = palettes[index].wall, Enum.Material.Plastic, Enum.SurfaceType.Smooth
				texture(
					p,
					if p.Name == "BackWallPanel"
						then Enum.NormalId.Front
						elseif p.Position.X < -100 then Enum.NormalId.Right
						else Enum.NormalId.Left
				)
			elseif p.Name == "Crown" or p.Name == "CrownTop" or p.Name == "PalmLeaf" or p.Name == "MesaCap" then
				p.Material, p.TopSurface = Enum.Material.Plastic, Enum.SurfaceType.Smooth
				texture(p, Enum.NormalId.Top)
			elseif p.Name == "InnerBankEarth" or p.Name == "OuterBankEarth" then
				p.Material, p.TopSurface = Enum.Material.Plastic, Enum.SurfaceType.Smooth
				texture(p, Enum.NormalId.Right)
				texture(p, Enum.NormalId.Left)
			end
		end
	end
	local lobby = model(decor, "LobbyGardens")
	for _, point in { { -164, 149, 1.1 }, { -134, 85, 1.15 }, { -169, 40, 0.85 }, { -35, 205, 0.95 } } do
		tree(lobby, point[1], point[2], 0, point[3], palettes[1])
		bush(lobby, point[1] + 8, point[2] + 5, 0, 0.9, palettes[1])
		rocks(lobby, point[1] - 7, point[2] + 7, 0, 0.6, palettes[1])
	end
	bush(lobby, -121, 134, 0, 1.15, palettes[1])
	rocks(lobby, -117, 139, 0, 0.7, palettes[1])
	bush(lobby, -92, 202, 0, 1, palettes[1])
	-- Back-wall cornice and intermittent top gardens enrich the vertical silhouette.
	part(lobby, "BackCornice", V(228, 2, 7), V(-106, 63, 227), C(199, 162, 105))
	for _, x in { -197, -140, -64 } do
		bush(lobby, x, 227, 64, 0.85, palettes[1])
	end
	for index, palette in palettes do
		local zone = model(decor, "Biome" .. index)
		local startZ = -(index - 1) * 256
		for _, side in { -1, 1 } do
			local bankX = -116 + side * 67
			local wallX = if side == -1 then -217 else -15
			local capX = if side == -1 then -223 else -9
			part(zone, "WallCornice", V(8, 2, 256), V(capX, 63, startZ - 128), palette.ground)
			for j, offset in { 43, 99, 173, 221 } do
				local z = startZ - offset + (if side == 1 then 12 else 0)
				local height = ({ 19, 31, 23, 37 })[j] + (if side == 1 then -5 else 0)
				local width = ({ 17, 23, 14, 20 })[j]
				part(zone, "CliffMass", V(5, height, width), V(wallX, 9 + height / 2, z), palette.rock)
				part(
					zone,
					"CliffShoulder",
					V(5, height * 0.6, width * 0.65),
					V(wallX, 9 + height * 0.3, z + width * 0.7),
					palette.rock:Lerp(palette.wall, 0.4)
				)
				part(zone, "CliffShelf", V(6, 1.4, width + 1), V(wallX, 9 + height + 0.7, z), palette.ground)
				if j == 2 or j == 4 then
					bush(zone, wallX, z, 10.4 + height, 0.45, palette)
				end
				if j ~= 3 then
					bush(zone, bankX, z, 4, if index == 3 then 0.65 else 0.8, palette)
					rocks(zone, bankX, z + 12, 4, 0.55, palette)
				else
					rocks(zone, bankX, z, 4, 0.85, palette)
				end
			end
			for _j, offset in { 66, 191 } do
				local z = startZ - offset + (if side == 1 then 20 else 0)
				bush(zone, capX, z, 64, 0.62, palette)
				rocks(zone, capX, z + 11, 64, 0.45, palette)
			end
		end
		zone.WorldPivot = CFrame.new(-116, 4, startZ - 128)
	end
	lobby.WorldPivot = CFrame.new(-106, 0, 112)
	decor.WorldPivot = CFrame.new(-116, 0, -528)
	-- Fail immediately if this visual pass changes gameplay geometry or collision flags.
	for p, saved in protected do
		assert(p.CFrame == saved[1] and p.Size == saved[2], "Geometry changed: " .. p:GetFullName())
		assert(
			p.CanCollide == saved[3] and p.CanTouch == saved[4] and p.CanQuery == saved[5],
			"Collision changed: " .. p:GetFullName()
		)
	end
	root:SetAttribute("VisualPolishVersion", VERSION)
	root:SetAttribute("HDStudsTexture", TEXTURE)
	return root
end

return MapPolish
