--!strict
-- Shared by the Studio build and the server bootstrap.
local MapBuilder = {}
local VERSION = 9
local C = Color3.fromRGB
local V = Vector3.new
local rng = Random.new(41)

function MapBuilder.build()
	local existing = workspace:FindFirstChild("ProgressionMap")
	if existing and existing:GetAttribute("Version") == VERSION then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "ProgressionMap"
	local function group(name)
		local model = Instance.new("Model")
		model.Name = name
		model.Parent = root
		return model
	end
	local function part(parent, name, size, pos, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.Position = pos
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Studs
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end
	local function sign(parent, text, pos, width, color)
		local anchor = part(parent, "UIAnchor", V(1, 1, 1), pos, C(255, 255, 255))
		anchor.Transparency = 1
		anchor.CanCollide = false
		anchor.CanTouch = false
		anchor.CanQuery = false
		anchor.CastShadow = false
		local gui = Instance.new("BillboardGui")
		gui.Name = "MapLabel"
		gui.Adornee = anchor
		gui.Size = UDim2.fromScale(width, 7)
		gui.MaxDistance = 350
		gui.AlwaysOnTop = false
		gui.LightInfluence = 0
		gui.Parent = anchor
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color or C(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		local stroke = Instance.new("UIStroke")
		stroke.Color = C(24, 30, 43)
		stroke.Thickness = 2
		stroke.Parent = label
		label.Parent = gui
		return anchor
	end
	local function tiles(parent, x, z, width, length, y, a, b)
		local unit = 16
		for ix = 0, math.ceil(width / unit) - 1 do
			for iz = 0, math.ceil(length / unit) - 1 do
				local sx = math.min(unit, width - ix * unit)
				local sz = math.min(unit, length - iz * unit)
				part(
					parent,
					"GroundTile",
					V(sx, 2, sz),
					V(x - width / 2 + ix * unit + sx / 2, y - 1, z - length / 2 + iz * unit + sz / 2),
					if (ix + iz) % 2 == 0 then a else b
				)
			end
		end
	end
	local function tree(parent, x, z, y, leaf, palm)
		local height = if palm then 18 else 12
		local trunk =
			part(parent, "Trunk", V(3, height, 3), V(x, y + height / 2, z), C(139, 91, 48), Enum.Material.Wood)
		trunk.TopSurface = Enum.SurfaceType.Smooth
		if palm then
			for i = 0, 5 do
				local angle = i * math.pi / 3
				local frond = part(
					parent,
					"PalmLeaf",
					V(4, 2, 16),
					V(x + math.sin(angle) * 6, y + height, z + math.cos(angle) * 6),
					leaf
				)
				frond.CFrame = CFrame.new(frond.Position) * CFrame.Angles(0, angle, 0.22)
				frond.CanCollide = false
			end
		else
			part(parent, "Crown", V(15, 10, 14), V(x, y + height + 2, z), leaf)
			part(parent, "CrownTop", V(10, 5, 10), V(x - 2, y + height + 8, z), leaf:Lerp(C(255, 255, 255), 0.12))
		end
	end
	local lobby = group("Lobby")
	tiles(lobby, -106, 112, 228, 224, 0, C(115, 215, 65), C(145, 232, 86))
	part(lobby, "CentralWalkway", V(16, 0.4, 202), V(0, 0.2, 111), C(185, 205, 224))
	part(lobby, "CrossWalkway", V(223, 0.4, 12), V(-103.5, 0.2, 175), C(185, 205, 224))
	part(lobby, "ThrowingApron", V(150, 0.6, 24), V(-115, 0.3, 13), C(255, 215, 70))
	for _, x in { -182, -48 } do
		part(lobby, "ApronTrim", V(2, 0.8, 24), V(x, 0.4, 13), C(255, 248, 186))
	end
	sign(lobby, "ЗОНА БРОСКОВ", V(-115, 10, 24), 68, C(255, 221, 73))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MapSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = V(12, 1, 12)
	spawn.Position = V(0, 0.7, 194)
	spawn.Color = C(78, 165, 249)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = lobby
	for _, position in { V(-165, 0, 200) } do
		tree(lobby, position.X, position.Z, 0, C(80, 196, 49), false)
	end

	local corridor = group("WaterCorridor")
	local biomes = {
		{ name = "ЛУГА", a = C(121, 218, 69), b = C(153, 233, 91), earth = C(155, 105, 64), leaf = C(83, 195, 48) },
		{
			name = "ТРОПИКИ",
			a = C(245, 217, 131),
			b = C(255, 234, 163),
			earth = C(191, 153, 89),
			leaf = C(37, 166, 84),
		},
		{
			name = "ЛЕДНИК",
			a = C(221, 244, 255),
			b = C(180, 220, 240),
			earth = C(111, 156, 185),
			leaf = C(160, 218, 255),
		},
		{
			name = "КАНЬОН",
			a = C(231, 141, 74),
			b = C(249, 171, 87),
			earth = C(148, 75, 47),
			leaf = C(180, 89, 44),
		},
		{
			name = "КРИСТАЛЛЫ",
			a = C(98, 83, 155),
			b = C(124, 104, 186),
			earth = C(54, 44, 92),
			leaf = C(178, 112, 255),
		},
	}
	-- Terrain water occupies only this map's river bounds.
	workspace.Terrain:FillBlock(CFrame.new(-116, -8, -640), V(112, 16, 1280), Enum.Material.Water)
	workspace.Terrain.WaterColor = C(20, 180, 220)
	workspace.Terrain.WaterTransparency = 0.22
	workspace.Terrain.WaterWaveSize = 0.12
	workspace.Terrain.WaterWaveSpeed = 8
	part(corridor, "RiverBed", V(112, 2, 1280), V(-116, -17, -640), C(44, 139, 161), Enum.Material.Sand)
	for index, biome in biomes do
		local z = -(index - 0.5) * 256
		local zone = Instance.new("Model")
		zone.Name = string.format("%02d_%s", index, biome.name)
		zone:SetAttribute("StartDistance", (index - 1) * 256)
		zone:SetAttribute("EndDistance", index * 256)
		zone.Parent = corridor
		for _, side in { -1, 1 } do
			local innerX = -116 + side * 67
			local outerX = -116 + side * 91
			part(zone, "InnerBankEarth", V(22, 9, 256), V(innerX, -1.5, z), biome.earth)
			tiles(zone, innerX, z, 22, 256, 4, biome.a, biome.b)
			part(zone, "OuterBankEarth", V(26, 14, 256), V(outerX, 1, z), biome.earth)
			tiles(zone, outerX, z, 26, 256, 9, biome.a, biome.b)
			for j = 1, 6 do
				local objectZ = z - 112 + j * 34 + rng:NextNumber(-5, 5)
				if index <= 3 then
					tree(zone, outerX, objectZ, 9, biome.leaf, index == 2)
				elseif index == 4 then
					part(zone, "Mesa", V(13, 19, 14), V(outerX, 18.5, objectZ), biome.earth, Enum.Material.Sandstone)
					part(zone, "MesaCap", V(16, 3, 17), V(outerX, 29.5, objectZ), biome.b)
				else
					local crystal =
						part(zone, "Crystal", V(6, 18, 6), V(outerX, 18, objectZ), biome.leaf, Enum.Material.Neon)
					crystal.CFrame *= CFrame.Angles(0.15, math.pi / 4, side * 0.25)
				end
				local rock = part(
					zone,
					"Rock",
					V(6, 5, 7),
					V(innerX, 6, objectZ + 14),
					biome.earth:Lerp(C(180, 190, 190), 0.5),
					Enum.Material.Slate
				)
				rock.Shape = Enum.PartType.Ball
			end
		end
		local distance = (index - 1) * 256
		sign(zone, biome.name .. " • " .. distance .. " м", V(-116, 32, -distance - 12), 78, biome.b)
		for _, x in { -174, -58 } do
			part(zone, "GatewayPillar", V(3, 23, 3), V(x, 12, -distance - 12), biome.earth)
		end
		part(zone, "GatewayTop", V(120, 3, 3), V(-116, 25, -distance - 12), biome.a)
	end

	local barriers = group("CorridorBarriers")
	-- Span both banks and overlap the perimeter walls so the entrance cannot be bypassed.
	local entrance =
		part(barriers, "EntranceBarrier", V(220, 120, 2), V(-116, 40, -1), C(114, 234, 255), Enum.Material.ForceField)
	entrance.Transparency = 0.83
	entrance.TopSurface = Enum.SurfaceType.Smooth
	for _, x in { -175, -57 } do
		local barrier = part(barriers, "SideBarrier", V(2, 100, 1280), V(x, 49, -640), C(114, 234, 255))
		barrier.Transparency = 1
	end
	part(barriers, "BarrierGlow", V(208, 0.4, 1), V(-116, 0.8, 0.5), C(91, 232, 255), Enum.Material.Neon)
	sign(barriers, "БАРЬЕР • ВХОД ЗАКРЫТ", V(-116, 4.5, 1), 54, C(144, 240, 255))

	local training = group("TrainingZone")
	sign(training, "ЗОНА ПРОКАЧКИ", V(-42, 12, 39), 56, C(255, 224, 96))
	local colors = {
		C(68, 209, 137),
		C(36, 204, 215),
		C(149, 102, 246),
		C(99, 195, 250),
		C(246, 161, 74),
		C(250, 212, 42),
		C(86, 246, 131),
	}
	for i = 1, 7 do
		local length = 34 + (i - 1) * 4
		local x = -72 + length / 2
		local z = 55 + (i - 1) * 17
		local lane = Instance.new("Model")
		lane.Name = "TrainingLane" .. i
		lane:SetAttribute("LaneLength", length)
		lane.Parent = training
		part(lane, "Foundation", V(length + 4, 1, 15), V(x, 0.6, z), C(183, 202, 217))
		part(lane, "TrainingStrip", V(length, 0.6, 13), V(x, 1.4, z), colors[i])
		for _, side in { -1, 1 } do
			part(
				lane,
				"LaneEdge",
				V(length, 0.9, 0.3),
				V(x, 1.7, z + side * 6.5),
				colors[i]:Lerp(C(255, 255, 255), 0.5),
				Enum.Material.Neon
			)
		end
		for step = 1, math.floor((length - 2) / 10) do
			part(
				lane,
				"DistanceMark",
				V(0.3, 0.1, 12),
				V(-72 + step * 10, 1.76, z),
				colors[i]:Lerp(C(255, 255, 255), 0.4)
			)
		end
		part(lane, "StartingPad", V(8, 0.5, 10), V(-66, 1.95, z), colors[i]:Lerp(C(40, 47, 65), 0.35))
		for side = -1, 1, 2 do
			local arrow =
				part(lane, "Arrow", V(0.3, 0.12, 4), V(-65, 2.27, z + side * 1.3), C(255, 255, 255), Enum.Material.Neon)
			arrow.CFrame *= CFrame.Angles(0, -side * math.pi / 4, 0)
		end
		local laneSign = sign(lane, string.format("%dx", i), V(-71 + length, 5.4, z), 12, colors[i])
		laneSign.CFrame *= CFrame.Angles(0, -math.pi / 2, 0)
	end

	local stand = group("EmptyItemStand")
	-- Solid stepped display: each row remains visible from the plaza.
	part(stand, "LowerTier", V(26, 4, 88), V(-205, 2, 87), C(185, 207, 228))
	part(stand, "UpperTier", V(13, 5, 88), V(-211.5, 6.5, 87), C(199, 219, 237))
	sign(stand, "ПРЕДМЕТЫ", V(-205, 16, 87), 68, C(245, 250, 255))
	for row = 0, 1 do
		for column = 1, 5 do
			local i = row * 5 + column
			local z = 47 + (column - 0.5) * 16
			local x = if row == 0 then -198.5 else -211.5
			local y = if row == 0 then 4.2 else 9.2
			local slot = part(stand, "EmptyPedestal" .. i, V(10.5, 0.4, 12.5), V(x, y, z), C(243, 248, 252))
			slot:SetAttribute("Row", row + 1)
			slot:SetAttribute("Column", column)
			part(stand, "DisplayTop" .. i, V(9, 0.15, 11), V(x, y + 0.275, z), C(216, 232, 244))
		end
	end

	local walls = group("PerimeterWalls")
	local function wall(name, size, pos)
		part(walls, name, size, pos, C(145, 97, 62))
	end
	wall("LobbyLeft", V(6, 64, 224), V(-223, 30, 112))
	wall("LobbyRight", V(6, 64, 224), V(11, 30, 112))
	wall("LobbyBack", V(240, 64, 6), V(-106, 30, 227))
	wall("FrontRight", V(30, 64, 6), V(-7, 30, -3))
	wall("FrontLeft", V(4, 64, 6), V(-220, 30, -3))
	wall("CorridorLeft", V(6, 64, 1280), V(-223, 30, -640))
	wall("CorridorRight", V(6, 64, 1280), V(-9, 30, -640))
	wall("CorridorEnd", V(220, 64, 6), V(-116, 30, -1283))
	-- Broad alternating masonry panels echo the reference without tiny parts.
	for z = -1264, 208, 32 do
		for row = 0, 3 do
			for _, x in { -219.8, if z < 0 then -12.2 else 7.8 } do
				part(
					walls,
					"WallPanel",
					V(0.3, 16, 32),
					V(x, row * 16 + 6, z),
					if (row + math.floor(z / 32)) % 2 == 0 then C(175, 123, 78) else C(158, 107, 68)
				)
			end
		end
	end
	for left = -224, 7, 32 do
		local width = math.min(32, 8 - left)
		local x = left + width / 2
		for row = 0, 3 do
			part(
				walls,
				"BackWallPanel",
				V(width, 16, 0.3),
				V(x, row * 16 + 6, 223.8),
				if (row + math.floor(x / 32)) % 2 == 0 then C(175, 123, 78) else C(158, 107, 68)
			)
		end
	end
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
	end
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 13
	lighting.Brightness = 2
	lighting.Ambient = C(125, 145, 170)
	lighting.OutdoorAmbient = C(155, 172, 190)
	lighting.GlobalShadows = true
	root:SetAttribute("Version", VERSION)
	root.Parent = workspace
	return root
end

return MapBuilder
