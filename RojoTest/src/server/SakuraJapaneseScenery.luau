--!strict
local Japanese = {}

function Japanese.apply(map)
	local world = map.SkippingWorld
	if world:FindFirstChild("SakuraJapaneseFinale") then
		return
	end
	local base = world:FindFirstChild("SakuraThreshold")
	assert(base, "Sakura finale missing")
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
	assert(upper and lower, "Final banks missing")
	local high, low = upper.Position.Y + upper.Size.Y / 2, lower.Position.Y + lower.Size.Y / 2
	local back = upper.Position.Z - upper.Size.Z / 2
	local cx = (left + right) / 2
	local crystalSource
	for _, p in ipairs(game.ServerStorage.ImportedPortalVisuals.RoseBlossom:GetChildren()) do
		if p:IsA("MeshPart") and p.Name:find("Large foot crystal") then
			crystalSource = p
			break
		end
	end
	assert(crystalSource, "Crystal mesh missing")
	local backups = game.ServerStorage.WorldBackups
	local old = backups:FindFirstChild("BeforeJapaneseFinale")
	if not old then
		old = Instance.new("Folder")
		old.Name = "BeforeJapaneseFinale"
		old.Parent = backups
	end
	local banner = base.BlossomBannerGarden
	local bannerBack = banner:GetPivot().Position.Z - 5
	for _, p in ipairs(banner:GetDescendants()) do
		if
			p:IsA("BasePart")
			and p.Transparency < 1
			and math.abs(p.Position.Z - bannerBack) < 1
			and (
				p.Name == "BannerPost"
				or p.Name == "BannerCrossbar"
				or p.Name == "RoseBanner"
				or p.Name == "SakuraPetal"
				or p.Name == "SakuraHeart"
			)
		then
			p:Clone().Parent = old
			p.Transparency = 1
			p:SetAttribute("JapaneseBannerHidden", true)
			for _, t in ipairs(p:GetChildren()) do
				if t:IsA("Texture") or t:IsA("Decal") then
					t.Transparency = 1
				end
			end
		end
	end
	local root = Instance.new("Model")
	root.Name = "SakuraJapaneseFinale"
	local parent = root
	local wood, dark, red, gold, stone, stone2, pink, pearl =
		C(119, 72, 43),
		C(72, 51, 66),
		C(173, 67, 51),
		C(222, 172, 73),
		C(163, 151, 158),
		C(184, 170, 176),
		C(255, 151, 192),
		C(255, 219, 233)
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
		if m.Name == "SakuraGatewayFrame" or m.Name == "GatewaySakuraBough" then
			for _, p in ipairs(m:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CastShadow = false
				end
			end
		end
		m.WorldPivot = CFrame.new(pos)
		m.Parent = root
		parent = root
	end
	local function triangle(name, a, b, c, color, thickness, studs)
		local ab, ac, bc = b - a, c - a, c - b
		if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then
			c, a = a, c
		elseif ac:Dot(ac) > bc:Dot(bc) then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local r = ac:Cross(ab).Unit
		local backAxis = bc.Unit
		local u = bc:Cross(r).Unit
		local h = math.abs(ab:Dot(u))
		local pieces = {
			part(
				name,
				V(thickness, h, math.abs(ab:Dot(backAxis))),
				CFrame.fromMatrix((a + b) / 2, r, u, backAxis),
				color,
				false,
				nil,
				"WedgePart"
			),
			part(
				name,
				V(thickness, h, math.abs(ac:Dot(backAxis))),
				CFrame.fromMatrix((a + c) / 2, -r, u, -backAxis),
				color,
				false,
				nil,
				"WedgePart"
			),
		}
		if studs then
			for _, p in ipairs(pieces) do
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
	end
	local function blossom(cf, r, border)
		for j = 1, 5 do
			local a = j * math.pi * 2 / 5
			local offset = V(math.cos(a) * r * 0.72, math.sin(a) * r * 0.72, 0)
			if border then
				part(
					"FlowerGoldOutline",
					V(0.55, r * 1.5, r * 1.5),
					cf * CFrame.new(offset) * CFrame.Angles(0, math.pi / 2, 0),
					gold,
					false,
					Enum.PartType.Cylinder
				)
			end
			part(
				"SakuraPortalPetal",
				V(border and 0.36 or 0.12, r * 1.32, r * 1.32),
				cf * CFrame.new(offset + V(0, 0, border and 0.35 or 0)) * CFrame.Angles(0, math.pi / 2, 0),
				j % 2 == 0 and pearl or pink,
				false,
				Enum.PartType.Cylinder
			)
		end
		part(
			"GoldenFlowerHeart",
			V(border and 0.65 or 0.16, r * 0.62, r * 0.62),
			cf * CFrame.new(0, 0, border and 0.6 or 0.12) * CFrame.Angles(0, math.pi / 2, 0),
			gold,
			false,
			Enum.PartType.Cylinder
		)
	end
	local function glow(p, color, brightness, range)
		local l = Instance.new("PointLight")
		l.Color = color
		l.Brightness = brightness
		l.Range = range
		l.Shadows = false
		l.Parent = p
	end
	local pavilionPos = base.SakuraViewingBench:GetPivot().Position
	local pavilion = begin("SakuraTeaPavilion")
	box("TeaDeck", V(14.3, 0.12, 14.3), pavilionPos + V(0, 0.06, 0), wood, true)
	for _, x in ipairs({ -5.8, 5.8 }) do
		for _, z in ipairs({ -5.8, 5.8 }) do
			box("PavilionPostFoot", V(1.7, 0.5, 1.7), pavilionPos + V(x, 0.3, z), dark, true)
			box("PavilionTimber", V(1.0, 8.8, 1.0), pavilionPos + V(x, 4.8, z), wood, true)
			bar(
				"PavilionCornerBrace",
				pavilionPos + V(x, 6.8, z),
				pavilionPos + V(x - (x > 0 and 1.8 or -1.8), 8.6, z),
				0.45,
				wood
			)
		end
	end
	local apex = pavilionPos + V(0, 13, 0)
	local corners = { V(-7.7, 9.3, -7.7), V(7.7, 9.3, -7.7), V(7.7, 9.3, 7.7), V(-7.7, 9.3, 7.7) }
	for i = 1, 4 do
		local a, b = pavilionPos + corners[i], pavilionPos + corners[i % 4 + 1]
		triangle("TeaRoofTile", apex, a, b, dark, 0.24, true)
		bar("TeaRoofHip", apex, a, 0.35, dark)
		bar("TeaRoofEave", a, b, 0.42, dark)
		local v = corners[i] * V(1, 0, 1)
		bar("UpturnedTeaEave", a, a + v.Unit * 0.8 + V(0, 0.5, 0), 0.4, dark)
	end
	box("TeaRoofFinial", V(0.7, 0.6, 0.7), apex + V(0, 0.3, 0), dark)
	local tablePos = pavilionPos + V(3.6, 0, 0)
	box("LowTeaTable", V(2.2, 0.25, 3.5), tablePos + V(0, 2.1, 0), wood, true)
	for _, x in ipairs({ -0.7, 0.7 }) do
		for _, z in ipairs({ -1.1, 1.1 }) do
			box("TeaTableLeg", V(0.25, 2, 0.25), tablePos + V(x, 1, z), wood)
		end
	end
	for j = 1, 3 do
		part(
			"TeaCup",
			V(0.38, 0.6, 0.6),
			CFrame.new(tablePos + V(0, 2.45, (j - 2) * 0.9)) * CFrame.Angles(0, 0, math.pi / 2),
			pearl,
			false,
			Enum.PartType.Cylinder
		)
	end
	finish(pavilion, pavilionPos)
	root.WorldPivot = CFrame.new(cx, low, back + 90)
	root.Parent = world
	task.wait()
	local railing = begin("VermilionGardenRails")
	for _, zOffset in ipairs({ -8.8, 8.8 }) do
		local pos = V(left + 2, high, pavilionPos.Z + zOffset)
		for _, z in ipairs({ -2.5, 2.5 }) do
			box("RedRailPost", V(0.6, 3.2, 0.6), pos + V(0, 1.6, z), red, true)
			box("BlackPostCap", V(0.85, 0.25, 0.85), pos + V(0, 3.25, z), dark)
		end
		for _, y in ipairs({ 1.5, 2.8 }) do
			box("RedRailBeam", V(0.35, 0.35, 5.5), pos + V(0, y, 0), red)
		end
	end
	finish(railing, V(left + 2, high, pavilionPos.Z))
	local emaPos = banner:GetPivot().Position + V(1.5, 0, -3)
	local ema = begin("EmaWishPlaqueRack")
	local ecf = CFrame.new(emaPos) * CFrame.Angles(0, -math.pi / 2, 0)
	for _, x in ipairs({ -3.6, 3.6 }) do
		part("EmaWoodPost", V(0.65, 7.5, 0.65), ecf * CFrame.new(x, 3.75, 0), wood, true)
		part("EmaPostFoot", V(1.2, 0.4, 1.2), ecf * CFrame.new(x, 0.2, 0), stone, true)
	end
	for _, y in ipairs({ 4.8, 6.95, 7.6 }) do
		part("EmaCrossbar", V(8.0, 0.35, 0.45), ecf * CFrame.new(0, y, 0), wood)
	end
	for _, side in ipairs({ -1, 1 }) do
		part(
			"EmaRoof",
			V(9.2, 0.3, 2.4),
			ecf * CFrame.new(0, 8.3, side * 0.85) * CFrame.Angles(math.rad(side * 30), 0, 0),
			dark,
			true
		)
	end
	for row, y in ipairs({ 5.75, 3.55 }) do
		for _, x in ipairs({ -2.25, 0, 2.25 }) do
			local cf = ecf * CFrame.new(x, y, 0.35)
			part("PentagonalEmaBoard", V(1.65, 1.2, 0.16), cf, C(206, 159, 99), true)
			triangle(
				"EmaBoardPeak",
				cf:PointToWorldSpace(V(-0.825, 0.6, 0)),
				cf:PointToWorldSpace(V(0.825, 0.6, 0)),
				cf:PointToWorldSpace(V(0, 1.0, 0)),
				C(206, 159, 99),
				0.16,
				false
			)
			bar(
				"PlaqueHangingCord",
				cf:PointToWorldSpace(V(0, 1.0, 0)),
				ecf:PointToWorldSpace(V(x, row == 1 and 6.95 or 4.8, 0.35)),
				0.06,
				pearl
			)
			blossom(cf * CFrame.new(0, 0.05, 0.16), 0.38, false)
		end
	end
	finish(ema, emaPos)
	task.wait()
	for _i, pos in ipairs({ V(left + 5.2, high, pavilionPos.Z - 15), emaPos + V(2.6, 0, 8) }) do
		local m = begin("SmallRakedSandGarden")
		box("SandPatch", V(4.2, 0.06, 5.4), pos + V(0, 0.03, 0), C(225, 209, 172), true)
		for ring = 1, 3 do
			local radius = ring * 0.5
			for j = 0, 23 do
				local a, b = j * math.pi / 12, (j + 1) * math.pi / 12
				bar(
					"RakedSandLine",
					pos + V(math.cos(a) * radius, 0.075, math.sin(a) * radius),
					pos + V(math.cos(b) * radius, 0.075, math.sin(b) * radius),
					0.045,
					C(197, 178, 140)
				)
			end
		end
		finish(m, pos)
	end
	-- Portal is a visual landmark at the endpoint; all its parts exclude gameplay queries.
	local gatePos = V(cx, low, back + 7)
	local frame = begin("SakuraGatewayFrame")
	for _, side in ipairs({ -1, 1 }) do
		local pos = gatePos + V(side * 66.5, 0, 0)
		box("GatewayBankFooting", V(18, 1.0, 12), pos + V(0, 0.5, 0), stone, true)
		box("GatewayPlinth", V(15.5, 1.2, 10.3), pos + V(0, 1.6, 0), stone2, true)
		for j = 0, 3 do
			box(
				"GatewayColumnStone",
				V(9.5, 2.5, 8.5),
				pos + V(0, 3.5 + j * 2.5, 0),
				j % 2 == 0 and stone or stone2,
				true
			)
		end
	end
	for j = 0, 20 do
		local a = j * math.pi / 20
		local tangent = math.atan2(70 * math.cos(a), -66.5 * math.sin(a))
		box(
			"SakuraArchStone",
			V(11.5, 9.0, 8.5),
			gatePos + V(math.cos(a) * 66.5, 12 + math.sin(a) * 70, 0),
			j % 2 == 0 and stone or stone2,
			true,
			CFrame.Angles(0, 0, tangent)
		)
	end
	for j = 0, 55 do
		local a, b = j * math.pi / 56, (j + 1) * math.pi / 56
		local p = bar(
			"BlushInnerRim",
			gatePos + V(math.cos(a) * 61.7, 12 + math.sin(a) * 65.4, 4.45),
			gatePos + V(math.cos(b) * 61.7, 12 + math.sin(b) * 65.4, 4.45),
			0.45,
			pink
		)
		p.Material = Enum.Material.Neon
		p.Transparency = 0.2
	end
	box("GatewayThreshold", V(128, 0.3, 7), V(cx, low + 0.15, back + 3.5), stone, true)
	for _, x in ipairs({ -42, 42 }) do
		box("ToriiRoofSupport", V(3.2, 23, 4.5), gatePos + V(x, 82, 0), red, true)
		box("ToriiGoldCollar", V(4.1, 2.0, 5.1), gatePos + V(x, 85, 0), gold, true)
	end
	box("ToriiLowerLintel", V(126, 2.5, 5.5), gatePos + V(0, 87, 0), red, true)
	for j = -5, 5 do
		local x = j * 14
		local y = 92 + (x / 70) ^ 2 * 4.5
		local slope = math.atan(9 * x / 4900)
		box("UpsweptVermilionLintel", V(14.4, 3.8, 8), gatePos + V(x, y, 0), red, true, CFrame.Angles(0, 0, slope))
		box(
			"VermilionLintelLip",
			V(14.4, 0.7, 8.4),
			gatePos + V(x, y + 2.1, 0),
			red:Lerp(dark, 0.2),
			true,
			CFrame.Angles(0, 0, slope)
		)
	end
	for _, side in ipairs({ -1, 1 }) do
		box(
			"GoldenToriiTip",
			V(3, 3, 8.6),
			gatePos + V(side * 77, 98.6, 0),
			gold,
			true,
			CFrame.Angles(0, 0, side * 0.3)
		)
	end
	for j = 0, 23 do
		local x1, x2 = -42 + j * 3.5, -42 + (j + 1) * 3.5
		local y1, y2 = 83 - 6 * (1 - (x1 / 42) ^ 2), 83 - 6 * (1 - (x2 / 42) ^ 2)
		bar("SacredDecorativeRope", gatePos + V(x1, y1, 5.1), gatePos + V(x2, y2, 5.1), 0.3, C(213, 174, 112))
	end
	for _, x in ipairs({ -32, -15, 15, 32 }) do
		local y = 83 - 6 * (1 - (x / 42) ^ 2)
		for j = 1, 3 do
			box(
				"WhitePaperShide",
				V(0.9, 2.2, 0.14),
				gatePos + V(x + (j % 2 == 0 and 0.55 or 0), y - 1.5 - j * 1.4, 5.3),
				pearl,
				false,
				CFrame.Angles(0, 0, math.rad(j % 2 == 0 and -25 or 25))
			)
		end
	end
	for _, a in ipairs({ math.rad(23), math.rad(51), math.rad(129), math.rad(157) }) do
		blossom(CFrame.new(gatePos + V(math.cos(a) * 66.5, 12 + math.sin(a) * 70, 5.0)), 3.4, true)
	end
	for _, x in ipairs({ -66.5, 66.5 }) do
		blossom(CFrame.new(gatePos + V(x, 16, 5.0)), 3.7, true)
	end
	blossom(CFrame.new(gatePos + V(0, 92, 4.5)), 4.1, true)
	local crystal = crystalSource:Clone()
	crystal.Name = "SakuraKeystoneCrystal"
	crystal.Size = V(4, 9, 3.4)
	crystal.CFrame = CFrame.new(gatePos + V(0, 102, 0))
	crystal.Color = pink
	crystal.Material = Enum.Material.SmoothPlastic
	crystal.Transparency = 0
	crystal.Anchored = true
	crystal.CanCollide = false
	crystal.CanTouch = false
	crystal.CanQuery = false
	for _, t in ipairs(crystal:GetChildren()) do
		if t:IsA("Texture") or t:IsA("SurfaceAppearance") then
			t:Destroy()
		end
	end
	crystal.Parent = parent
	glow(crystal, pink, 0.4, 20)
	finish(frame, gatePos)
	task.wait()
	-- Two mature boughs grow from the existing outer banks alongside the gateway.
	for _, side in ipairs({ -1, 1 }) do
		local origin = V(cx + side * 85, high, gatePos.Z + 1)
		local m = begin("GatewaySakuraBough")
		local nodes =
			{ origin, gatePos + V(side * 88, 27, 1), gatePos + V(side * 82, 48, 0), gatePos + V(side * 74, 66, -1) }
		for j = 1, 3 do
			bar("MatureSakuraTrunk", nodes[j], nodes[j + 1], 4.5 - j * 0.6, wood)
		end
		local crownHeights = { 32, 41, 52, 62, 72, 80 }
		local crownOffsets = { 82, 93, 78, 90, 76, 86 }
		for j = 1, 6 do
			local target = gatePos + V(side * crownOffsets[j], crownHeights[j], ((j % 2) * 2 - 1) * 3)
			bar("SakuraClimbingBranch", nodes[j % 2 + 2], target, 1.4, wood)
			box("LargeBlossomCloud", V(13.5, 8.0, 11), target, pink, true)
			for k = 1, 10 do
				local a = k * math.pi * 2 / 10 + j
				box(
					"GatewayBlossomCluster",
					V(4.8, 4.4, 4.8),
					target + V(math.cos(a) * 6.6, (k % 2 - 0.5) * 4.2, math.sin(a) * 5.2),
					k % 3 == 0 and pearl or (k % 2 == 0 and C(255, 126, 173) or pink),
					true,
					CFrame.Angles(0, a, 0)
				)
			end
			if j % 2 == 0 then
				blossom(CFrame.new(target + V(0, -1, 5)), 1.2, false)
			end
		end
		finish(m, origin)
		task.wait()
	end
	-- A static arch-shaped panorama hints at the next world without teleport logic.
	local vista = begin("SakuraPortalPanorama")
	local plane = box("InvisiblePanoramaSupport", V(123.4, 77.4, 0.1), gatePos + V(0, 38.7, 0.2), pearl)
	plane.Transparency = 1
	plane.CastShadow = false
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PortalInteriorView"
	gui.Face = Enum.NormalId.Back
	gui.Adornee = plane
	gui.CanvasSize = Vector2.new(1234, 774)
	gui.LightInfluence = 0.15
	gui.AlwaysOnTop = false
	gui.MaxDistance = 2000
	gui.Parent = plane
	local image = Instance.new("ImageLabel")
	image.Name = "SakuraAvenue"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Size = UDim2.fromScale(1.04, 1.04)
	image.Position = UDim2.fromScale(-0.02, -0.02)
	image.Image = "rbxassetid://72399615078966"
	image.Active = false
	image.Parent = gui
	finish(vista, gatePos)
	root:SetAttribute("Version", 1)
	root:SetAttribute("VisualGatewayOnly", true)
	root:SetAttribute("TeleportEnabled", false)
	root:SetAttribute("PortalPanoramaAsset", "rbxassetid://72399615078966")
	base:SetAttribute("PortalNotBuilt", false)
	return root
end

return Japanese
