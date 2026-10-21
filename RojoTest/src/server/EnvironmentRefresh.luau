--!strict
-- A native-part art pass. Scene anchors, authored floors and gameplay markers stay intact.
local Refresh = {}
local VERSION = 1
local C, V = Color3.fromRGB, Vector3.new
local STUDS = "rbxassetid://88156646156237"
local palettes = {
	{ rock = C(114, 140, 148), leaf = C(53, 174, 77), light = C(134, 218, 77), flower = C(255, 116, 100) },
	{ rock = C(194, 145, 88), leaf = C(56, 164, 101), light = C(137, 207, 106), flower = C(255, 195, 76) },
	{ rock = C(175, 127, 153), leaf = C(236, 125, 188), light = C(255, 178, 211), flower = C(115, 232, 171) },
	{ rock = C(114, 96, 158), leaf = C(159, 103, 214), light = C(211, 154, 248), flower = C(112, 231, 245) },
	{ rock = C(107, 78, 69), leaf = C(196, 98, 67), light = C(249, 164, 83), flower = C(255, 206, 100) },
	{ rock = C(109, 129, 173), leaf = C(114, 163, 209), light = C(181, 216, 246), flower = C(249, 230, 163) },
	{ rock = C(158, 196, 214), leaf = C(107, 178, 192), light = C(224, 248, 255), flower = C(142, 229, 255) },
	{ rock = C(141, 134, 179), leaf = C(89, 198, 130), light = C(187, 230, 111), flower = C(255, 135, 215) },
}

local function studs(part, face)
	local name = "RefreshStuds_" .. face.Name
	if part:FindFirstChild(name) then
		return
	end
	local texture = Instance.new("Texture")
	texture.Name = name
	texture.Texture = STUDS
	texture.Face = face
	texture.StudsPerTileU = 8
	texture.StudsPerTileV = 8
	texture.Color3 = part.Color
	texture.Transparency = 0.22
	texture.Parent = part
end

function Refresh.apply(map)
	assert(map and map:GetAttribute("Version") == 9, "Authored map v9 required")
	if map:GetAttribute("EnvironmentRefreshVersion") == VERSION then
		return map.NativeEnvironment
	end
	assert(not map:FindFirstChild("NativeEnvironment"), "Review incomplete environment refresh")
	local frame = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
	local originals = map:GetDescendants()
	local protected = {}
	for _, p in originals do
		if p:IsA("BasePart") then
			protected[p] =
				{ cf = p.CFrame, size = p.Size, collide = p.CanCollide, touch = p.CanTouch, query = p.CanQuery }
		end
	end
	local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = game.ServerStorage
	local backup = Instance.new("Folder")
	backup.Name = map.Name .. "_BeforeEnvironmentRefresh"
	backup.Parent = backups
	local native = Instance.new("Model")
	native.Name = "NativeEnvironment"
	native.Parent = map
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = native
	local shores = Instance.new("Folder")
	shores.Name = "ShoreGardens"
	shores.Parent = native
	local lobby = Instance.new("Folder")
	lobby.Name = "LobbyAccents"
	lobby.Parent = native
	local saved, changed = {}, {}
	local function remember(p)
		if saved[p] then
			return
		end
		saved[p] = true
		local copy = p:Clone()
		copy:SetAttribute("OriginalPath", p:GetFullName())
		local link = Instance.new("ObjectValue")
		link.Name = "OriginalPart"
		link.Value = p
		link.Parent = copy
		copy.Parent = backup
	end
	local function hide(p, keepCollision)
		remember(p)
		changed[p] = true
		p.Transparency = 1
		for _, t in p:GetChildren() do
			if t:IsA("Texture") or t:IsA("Decal") then
				t.Transparency = 1
			end
		end
		if not keepCollision then
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
	end
	local function part(parent, name, size, position, color, yaw, wedge, texture)
		local p = Instance.new(wedge and "WedgePart" or "Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.CFrame = frame * CFrame.new(position) * CFrame.Angles(0, yaw or 0, 0)
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
		if texture ~= false then
			studs(p, Enum.NormalId.Top)
			if size.Y > 2 then
				studs(p, Enum.NormalId.Front)
			end
		end
		return p
	end
	local function model(parent, name, base)
		local m = Instance.new("Model")
		m.Name = name
		m.WorldPivot = frame * CFrame.new(base)
		m.Parent = parent
		return m
	end
	local function beam(parent, name, a, b, width, color)
		local p = part(parent, name, V(width, (b - a).Magnitude, width), (a + b) / 2, color, 0, false, false)
		p.CFrame = frame * CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(math.pi / 2, 0, 0)
		studs(p, Enum.NormalId.Front)
		return p
	end
	local function broadTree(parent, base, height, palette, variant, palm)
		local m = model(parent, palm and "RobloxPalm" or "RobloxOak", base)
		local h = height
		local wood = C(143, 101, 63)
		local a = base
		local b = base + V(h * 0.04, h * 0.28, 0)
		local c = base + V(-h * 0.045, h * 0.53, h * 0.035)
		local top = base + V(h * 0.02, h * 0.72, 0)
		beam(m, "TrunkBase", a, b, h * 0.085, wood)
		beam(m, "TrunkBend", b, c, h * 0.075, wood:Lerp(C(189, 141, 91), 0.18))
		beam(m, "TrunkTop", c, top, h * 0.065, wood)
		if palm then
			for i = 0, 5 do
				local angle = i * math.pi / 3 + variant * 0.17
				local center = top + V(math.sin(angle) * h * 0.19, h * 0.045, math.cos(angle) * h * 0.19)
				part(
					m,
					"PalmBlade",
					V(h * 0.12, h * 0.05, h * 0.43),
					center,
					i % 2 == 0 and palette.leaf or palette.light,
					angle,
					true
				)
			end
			part(m, "PalmHeart", V(h * 0.16, h * 0.12, h * 0.16), top + V(0, h * 0.05, 0), palette.light, 0)
		else
			for _i, side in { -1, 1 } do
				beam(m, "CrownBranch", c, base + V(side * h * 0.23, h * 0.77, side * h * 0.07), h * 0.045, wood)
			end
			for i, v in
				{
					{ -0.23, 0.77, 0.02, 0.40, 0.22, 0.40 },
					{ 0.20, 0.79, 0.05, 0.43, 0.24, 0.38 },
					{ 0.01, 0.87, -0.18, 0.42, 0.23, 0.37 },
					{ -0.03, 0.93, 0.06, 0.38, 0.19, 0.36 },
					{ -0.10, 0.74, 0.24, 0.34, 0.18, 0.30 },
				}
			do
				local yaw = i <= 2 and (i == 1 and math.pi / 2 or -math.pi / 2) or ((i % 3 - 1) * 0.16 + variant * 0.04)
				part(
					m,
					"LeafCrown",
					V(v[4] * h, v[5] * h, v[6] * h),
					base + V(v[1] * h, v[2] * h, v[3] * h),
					i % 2 == 0 and palette.light or palette.leaf,
					yaw,
					i <= 2
				)
			end
		end
		for i = 0, 2 do
			local angle = i * math.pi * 2 / 3 + variant * 0.2
			part(
				m,
				"RootFoot",
				V(h * 0.10, h * 0.06, h * 0.23),
				base + V(math.sin(angle) * h * 0.10, h * 0.025, math.cos(angle) * h * 0.10),
				wood,
				angle,
				true
			)
		end
		return m
	end
	local function rockGarden(parent, base, scale, palette, variant)
		local m = model(parent, "FacetedRockGarden", base)
		part(m, "RockCore", V(5.6, 3.8, 5.1) * scale, base + V(0, 1.9, 0) * scale, palette.rock, variant * 0.17)
		part(
			m,
			"RockCrest",
			V(5.8, 1.8, 5.2) * scale,
			base + V(0, 4.05, 0) * scale,
			palette.rock:Lerp(C(230, 237, 235), 0.10),
			variant * 0.17,
			true
		)
		part(
			m,
			"RockShoulder",
			V(4.5, 4.0, 5.8) * scale,
			base + V(-3.1, 2.0, 0.3) * scale,
			palette.rock:Lerp(C(227, 235, 238), 0.18),
			math.pi / 2 + variant * 0.1,
			true
		)
		part(
			m,
			"SmallStone",
			V(3.2, 2.4, 3.6) * scale,
			base + V(4.0, 1.2, 1.6) * scale,
			palette.rock:Lerp(C(244, 237, 214), 0.13),
			-0.23
		)
		part(
			m,
			"StoneChip",
			V(2.2, 1.1, 2.9) * scale,
			base + V(2.1, 0.55, -3.2) * scale,
			palette.rock:Lerp(palette.light, 0.12),
			0.45,
			true
		)
		return m
	end
	local function plants(parent, base, scale, palette, flower)
		local m = model(parent, "PlantPocket", base)
		for i, v in
			{ { 0, 1.2, 0, 3.7, 2.4, 3.2 }, { 2.1, 0.8, 1.0, 2.6, 1.6, 2.9 }, { -1.6, 0.7, 1.4, 2.5, 1.4, 2.4 } }
		do
			part(
				m,
				"LeafBlock",
				V(v[4], v[5], v[6]) * scale,
				base + V(v[1], v[2], v[3]) * scale,
				i % 2 == 0 and palette.light or palette.leaf,
				i * 0.24
			)
		end
		if flower then
			for i = 1, 3 do
				local pos = base + V(-1.5 + i * 1.15, 0, -1.6) * scale
				part(
					m,
					"FlowerStem",
					V(0.22, 1.8, 0.22) * scale,
					pos + V(0, 0.9, 0) * scale,
					palette.leaf,
					0,
					false,
					false
				)
				part(
					m,
					"FlowerPetals",
					V(1.35, 0.36, 0.75) * scale,
					pos + V(0, 1.9, 0) * scale,
					palette.flower,
					i * 0.5,
					false,
					false
				)
				part(
					m,
					"FlowerCenter",
					V(0.45, 0.40, 0.45) * scale,
					pos + V(0, 2.05, 0) * scale,
					C(255, 231, 117),
					0,
					false,
					false
				)
			end
		end
		return m
	end
	local function biomeAt(z)
		return math.clamp(math.floor(-z / 180) + 1, 1, 8)
	end
	local roots = {}
	for _, root in originals do
		if root:IsA("BasePart") then
			if root.Name == "Trunk" then
				local pieces = { root }
				local visible = root.Transparency < 0.99
				local palm = false
				for _, p in root.Parent:GetChildren() do
					if
						p:IsA("BasePart")
						and p ~= root
						and (p.Name == "Crown" or p.Name == "CrownTop" or p.Name == "PalmLeaf")
						and math.abs(p.Position.X - root.Position.X) < 12
						and math.abs(p.Position.Z - root.Position.Z) < 12
					then
						table.insert(pieces, p)
						visible = visible or p.Transparency < 0.99
						palm = palm or p.Name == "PalmLeaf"
					end
				end
				if visible then
					table.insert(roots, { root = root, pieces = pieces, palm = palm })
				end
			elseif root.Name == "BiomeDecorStem" and root.Transparency < 0.99 then
				local pieces = { root }
				local palm = false
				for _, p in root.Parent:GetChildren() do
					if
						p:IsA("BasePart")
						and (p.Name == "CandyCrown" or p.Name == "PalmFrond")
						and math.abs(p.Position.X - root.Position.X) < 9
						and math.abs(p.Position.Z - root.Position.Z) < 9
					then
						table.insert(pieces, p)
						palm = palm or p.Name == "PalmFrond"
					end
				end
				if #pieces > 1 then
					table.insert(roots, { root = root, pieces = pieces, palm = palm })
				end
			end
		end
	end
	local treeCount = 0
	for i, entry in roots do
		local root = entry.root
		local baseWorld = root.Position - V(0, root.Size.Y / 2, 0)
		local base = frame:PointToObjectSpace(baseWorld) + V(0, 0.05, 0)
		local top = baseWorld.Y
		for _, p in entry.pieces do
			if p.Transparency < 0.99 then
				top = math.max(top, p.Position.Y + p.Size.Y / 2)
			end
		end
		local h = math.clamp(top - baseWorld.Y, 18, 24)
		local palette = palettes[base.Z > 0 and 1 or biomeAt(base.Z)]
		broadTree(trees, base, h, palette, i, entry.palm)
		for _, p in entry.pieces do
			hide(p, p == root)
		end
		treeCount += 1
		if i % 10 == 0 then
			task.wait()
		end
	end
	local rockCount = 0
	for _, p in originals do
		if p:IsA("BasePart") and p.Name == "Rock" and p.Transparency < 0.99 then
			local pos = frame:PointToObjectSpace(p.Position)
			if pos.Z < 0 then
				local base = V(pos.X, 4.24, pos.Z)
				rockGarden(shores, base, 0.62 + (rockCount % 4) * 0.09, palettes[biomeAt(pos.Z)], rockCount % 5)
				hide(p, true)
				rockCount += 1
			end
		end
	end
	-- Give existing stone and shrub groups the neighbouring biome's palette.
	for _, p in originals do
		if p:IsA("BasePart") and p.Transparency < 0.99 then
			local pos = frame:PointToObjectSpace(p.Position)
			local pal = palettes[pos.Z > 0 and 1 or biomeAt(pos.Z)]
			if p.Name == "RockMass" or p.Name == "RockSlope" or p.Name == "SmallRock" then
				remember(p)
				p.Color = pal.rock:Lerp(C(225, 232, 235), p.Name == "SmallRock" and 0.18 or 0)
				p.Material = Enum.Material.Plastic
				for _, t in p:GetChildren() do
					if t:IsA("Texture") then
						t.Color3 = p.Color
						t.Transparency = 0.32
					end
				end
			elseif p.Name == "Shrub" or p.Name == "LeafBlock" then
				remember(p)
				p.Color = pal.leaf:Lerp(pal.light, p.Name == "LeafBlock" and 0.3 or 0.1)
				for _, t in p:GetChildren() do
					if t:IsA("Texture") then
						t.Color3 = p.Color
						t.Transparency = 0.32
					end
				end
			end
		end
	end
	-- Stagger two scenic pockets on each upper bank; leave the inner tier and river open.
	for biome = 1, 8 do
		local palette = palettes[biome]
		local start = -(biome - 1) * 180
		local zone = model(shores, "BiomeGarden" .. biome, V(-116, 9.24, start - 90))
		for _, side in { -1, 1 } do
			for group, offset in { 43, 125 } do
				local z = start - offset + (side == 1 and 12 or 0)
				local base = V(-116 + side * 94, 9.24, z)
				rockGarden(zone, base, group == 1 and 1.05 or 0.78, palette, biome + group)
				plants(zone, base + V(-side * 6.5, 0, 6), 0.9, palette, true)
				if biome == 1 or biome == 3 or biome == 7 or biome == 8 then
					broadTree(
						zone,
						base + V(-side * 3.5, 0, -13),
						group == 1 and 19 or 16,
						palette,
						biome + group,
						biome == 1
					)
				end
				-- Large, readable landmarks supply height without filling the play corridor.
				if group == 1 then
					local feature = base + V(side * 0.5, 0, 20)
					if biome == 4 or biome == 5 or biome == 6 or biome == 7 then
						for j = 1, 3 do
							local h = ({ 9, 15, 7 })[j]
							local p = part(
								zone,
								"CrystalPeak",
								V(3.2, h, 3.5),
								feature + V((j - 2) * 4, h / 2, (j % 2) * 2),
								j == 2 and palette.flower or palette.light,
								j * 0.45,
								true
							)
							if biome == 5 or biome == 6 then
								p.Material = Enum.Material.Neon
							end
						end
					else
						part(zone, "CliffPillar", V(6, 13, 6), feature + V(0, 6.5, 0), palette.rock, 0.12)
						part(zone, "CliffCap", V(7, 1.3, 7), feature + V(0, 13.65, 0), palette.light, 0.12)
						part(
							zone,
							"CliffShoulder",
							V(5, 8, 7),
							feature + V(side * 3.4, 4, 1),
							palette.rock:Lerp(C(226, 227, 203), 0.2),
							side * math.pi / 2,
							true
						)
					end
				end
			end
		end
		task.wait()
	end
	-- Small lobby pockets frame existing trees and shops, clear of training pads and paths.
	for i, pos in { V(-173, 0.04, 202), V(-143, 0.04, 87), V(-176, 0.04, 42), V(-29, 0.04, 195) } do
		plants(lobby, pos, 0.85, palettes[1], true)
		rockGarden(lobby, pos + V(4, 0, 5), 0.45, palettes[1], i)
	end
	local protectedChecks = 0
	for p, savedState in protected do
		assert(p.CFrame == savedState.cf and p.Size == savedState.size, "Authored geometry moved: " .. p:GetFullName())
		if not changed[p] then
			assert(
				p.CanCollide == savedState.collide and p.CanTouch == savedState.touch and p.CanQuery == savedState.query,
				"Collision changed: " .. p:GetFullName()
			)
		end
		protectedChecks += 1
	end
	native.WorldPivot = frame * CFrame.new(-116, 0, -600)
	native:SetAttribute("RebuiltTrees", treeCount)
	native:SetAttribute("RebuiltRocks", rockCount)
	native:SetAttribute("ProtectedGeometryChecks", protectedChecks)
	map:SetAttribute("EnvironmentRefreshVersion", VERSION)
	return native
end

function Refresh.lighting()
	local lighting = game.Lighting
	if lighting:GetAttribute("EnvironmentRefreshLighting") == VERSION then
		return
	end
	local backup = Instance.new("Folder")
	backup.Name = "Lighting_BeforeEnvironmentRefresh"
	backup.Parent = game.ServerStorage.WorldBackups
	for _, key in { "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "ShadowSoftness" } do
		backup:SetAttribute(key, lighting[key])
	end
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere:Clone().Parent = backup
		atmosphere.Density = 0.15
		atmosphere.Haze = 0.6
		atmosphere.Color = C(204, 232, 249)
		atmosphere.Decay = C(153, 176, 201)
	end
	lighting.Ambient = C(109, 125, 141)
	lighting.OutdoorAmbient = C(164, 179, 195)
	lighting.Brightness = 2.35
	lighting.ClockTime = 13.5
	lighting.ShadowSoftness = 0.25
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "EnvironmentColorGrade"
	grade.Saturation = 0.055
	grade.Contrast = 0.025
	grade.Brightness = 0
	grade.Parent = lighting
	lighting:SetAttribute("EnvironmentRefreshLighting", VERSION)
end

return Refresh
