--!strict
local Courtyard = {}
function Courtyard.apply(map)
	local portal = map.SkippingWorld.World2Portal
	if portal:FindFirstChild("SakuraCourtyard") then
		return
	end
	assert(portal:FindFirstChild("SakuraVisual"), "Sakura portal required")
	local visual = portal.SakuraVisual
	local pivot = visual:GetPivot()
	local frame = CFrame.new(portal.PortalField.Position.X, pivot.Position.Y, portal.PortalField.Position.Z)
		* portal.PortalField.CFrame.Rotation
	local model = Instance.new("Model")
	model.Name = "SakuraCourtyard"
	local pink = Color3.fromRGB(255, 183, 215)
	local stone = Color3.fromRGB(158, 173, 183)
	local green = Color3.fromRGB(79, 179, 72)
	local function part(name, size, pos, color, studs, rotation)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = frame * CFrame.new(pos) * (rotation or CFrame.identity)
		p.Color = color
		p.Material = Enum.Material.Plastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if studs then
			local t = Instance.new("Texture")
			t.Texture = "rbxassetid://88156646156237"
			t.Face = Enum.NormalId.Top
			t.StudsPerTileU = 8
			t.StudsPerTileV = 8
			t.Parent = p
		end
		p.Parent = model
		return p
	end
	-- Adjacent bands form one flat, stepped outline, with no overlapping faces.
	for _, r in ipairs({ { 34, -14, 8 }, { 44, -6, 8 }, { 44, 2, 8 }, { 34, 9, 6 } }) do
		part("PinkGround", Vector3.new(r[1], 0.08, r[3]), Vector3.new(0, 0.04, r[2]), pink, true)
	end
	for _, z in ipairs({ -20, -28, -36, -44, -52, -58 }) do
		part("ApproachSlab", Vector3.new(8, 0.12, 6.2), Vector3.new(0, 0.09, z), Color3.fromRGB(197, 205, 211), true)
	end
	for _, side in ipairs({ -1, 1 }) do
		local x = side * 15
		local z = -15
		part("LanternFoot", Vector3.new(4.7, 0.4, 4.7), Vector3.new(x, 0.3, z), stone, true)
		part("LanternPlinth", Vector3.new(3.2, 0.7, 3.2), Vector3.new(x, 0.85, z), stone, true)
		part("LanternColumn", Vector3.new(1.7, 2.2, 1.7), Vector3.new(x, 2.3, z), Color3.fromRGB(134, 151, 165), false)
		part("LanternHousing", Vector3.new(3.3, 1.8, 3.3), Vector3.new(x, 4.0, z), stone, false)
		local window = part(
			"WarmLanternWindow",
			Vector3.new(2.25, 0.8, 3.38),
			Vector3.new(x, 4.0, z),
			Color3.fromRGB(255, 213, 122),
			false
		)
		window.Material = Enum.Material.Neon
		part(
			"LanternSideWindow",
			Vector3.new(3.38, 0.8, 2.25),
			Vector3.new(x, 4.0, z),
			Color3.fromRGB(255, 213, 122),
			false
		).Material =
			Enum.Material.Neon
		part("LanternRoof", Vector3.new(4.4, 0.45, 4.4), Vector3.new(x, 5.05, z), stone, true)
		part(
			"LanternRoofTop",
			Vector3.new(2.8, 0.6, 2.8),
			Vector3.new(x, 5.575, z),
			Color3.fromRGB(143, 161, 175),
			true
		)
		part("LanternFinial", Vector3.new(1.1, 0.8, 1.1), Vector3.new(x, 6.2, z), stone, true)
		for _, lx in ipairs({ side * 12, side * 20 }) do
			part("WoodPost", Vector3.new(0.65, 3.3, 0.65), Vector3.new(lx, 1.73, 7), Color3.fromRGB(97, 56, 41), true)
		end
		part("WoodRail", Vector3.new(9, 0.9, 0.85), Vector3.new(side * 16, 3.3, 7), Color3.fromRGB(111, 65, 47), true)
		for _i, site in ipairs({ { side * 19, -5 }, { side * 20, 3 } }) do
			local bx, bz = site[1], site[2]
			part(
				"FlowerBedStone",
				Vector3.new(2.3, 2.5, 2.5),
				Vector3.new(bx + side * 1.1, 1.33, bz + 1.5),
				stone,
				true
			)
			part("SakuraShrub", Vector3.new(3.6, 1.5, 3.2), Vector3.new(bx, 0.83, bz), green, true)
			for j = 1, 4 do
				local fx = bx + (j % 2 == 0 and 0.9 or -0.8)
				local fz = bz + (j < 3 and -0.8 or 0.8)
				local color = j % 2 == 0 and Color3.fromRGB(255, 218, 234) or Color3.fromRGB(247, 136, 188)
				for k = 1, 5 do
					local a = k * math.pi * 2 / 5
					local p = part(
						"SakuraPetal",
						Vector3.new(0.16, 0.9, 0.9),
						Vector3.new(fx + math.cos(a) * 0.4, 1.76, fz + math.sin(a) * 0.4),
						color,
						false,
						CFrame.Angles(0, 0, math.pi / 2)
					)
					p.Shape = Enum.PartType.Cylinder
				end
				local center = part(
					"FlowerHeart",
					Vector3.new(0.2, 0.4, 0.4),
					Vector3.new(fx, 1.87, fz),
					Color3.fromRGB(255, 220, 111),
					false,
					CFrame.Angles(0, 0, math.pi / 2)
				)
				center.Shape = Enum.PartType.Cylinder
			end
		end
	end
	for i = 1, 18 do
		local side = i % 2 == 0 and -1 or 1
		local x = side * (7 + i % 5 * 2.3)
		local z = -17 + (i * 7 % 28)
		part(
			"FallenPetal",
			Vector3.new(0.42, 0.05, 0.65),
			Vector3.new(x, 0.12, z),
			i % 3 == 0 and Color3.fromRGB(255, 228, 239) or Color3.fromRGB(245, 140, 189),
			false,
			CFrame.Angles(0, i * 1.3, 0)
		)
	end
	model.WorldPivot = frame
	model:SetAttribute("Version", 1)
	model.Parent = portal
	return #model:GetChildren()
end
return Courtyard
