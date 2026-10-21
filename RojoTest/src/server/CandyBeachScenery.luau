--!strict
local Candy = {}
function Candy.apply(map)
	local world = map.SkippingWorld
	if world:FindFirstChild("CandyPromenade") then
		return
	end
	local left, right, upper, lower = math.huge, -math.huge, nil, nil
	for _, p in ipairs(world:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "BiomeBank3_2" then
			left = math.min(left, p.Position.X - p.Size.X / 2)
			right = math.max(right, p.Position.X + p.Size.X / 2)
			upper = p
		end
		if p:IsA("BasePart") and p.Name == "BiomeBank3_1" then
			lower = p
		end
	end
	assert(upper and lower, "Candy banks missing")
	local high = upper.Position.Y + upper.Size.Y / 2
	local low = lower.Position.Y + lower.Size.Y / 2
	local front = upper.Position.Z + upper.Size.Z / 2
	local back = upper.Position.Z - upper.Size.Z / 2
	local pink = Color3.fromRGB(245, 165, 203)
	local cream = Color3.fromRGB(255, 239, 198)
	local mint = Color3.fromRGB(132, 208, 176)
	local lavender = Color3.fromRGB(191, 160, 222)
	local wood = Color3.fromRGB(159, 113, 68)
	local palette = { pink, cream, mint, lavender, Color3.fromRGB(251, 211, 115) }
	local root = Instance.new("Model")
	root.Name = "CandyPromenade"
	local parent = root
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
		return part(name, Vector3.new(w, w, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
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
	local function cylinder(name, pos, h, d, color, rot)
		return part(
			name,
			Vector3.new(h, d, d),
			CFrame.new(pos) * (rot or CFrame.Angles(0, 0, math.pi / 2)),
			color,
			false,
			Enum.PartType.Cylinder
		)
	end
	local function lollipop(pos, color, radius)
		local old = {}
		for _, p in ipairs(parent:GetChildren()) do
			old[p] = true
		end
		box("LollipopStick", Vector3.new(0.23, 5.8, 0.23), pos + Vector3.new(0, 2.9, 0), wood)
		local center = pos + Vector3.new(0, 6.8, 0)
		cylinder("CandyDisk", center, 0.35, radius * 2, color, CFrame.Angles(0, math.pi / 2, 0))
		local last = center + Vector3.new(0, 0, -0.24)
		for i = 1, 44 do
			local t = i / 44
			local a = t * math.pi * 4.5
			local point = center + Vector3.new(math.cos(a) * radius * 0.88 * t, math.sin(a) * radius * 0.88 * t, -0.24)
			bar("CandySwirl", last, point, 0.19, Color3.fromRGB(255, 248, 231))
			last = point
		end
		local turn = CFrame.new(pos)
			* CFrame.Angles(0, pos.X > (left + right) / 2 and math.pi / 2 or -math.pi / 2, 0)
			* CFrame.new(-pos)
		for _, p in ipairs(parent:GetChildren()) do
			if p:IsA("BasePart") and not old[p] then
				p.CFrame = turn * p.CFrame
			end
		end
	end
	local cartPos = Vector3.new(right - 8, high, front - 80)
	local cart = begin("CandyCart")
	box("CartBody", Vector3.new(6.8, 2.7, 9.6), cartPos + Vector3.new(0, 2.5, 0), cream, true)
	box("CartCounter", Vector3.new(8, 0.4, 10.6), cartPos + Vector3.new(0, 4.05, 0), wood, true)
	box("CartPinkPanel", Vector3.new(0.12, 1.8, 7.8), cartPos + Vector3.new(-3.47, 2.7, 0), pink, true)
	for _, z in ipairs({ -3.3, 3.3 }) do
		for _, side in ipairs({ -1, 1 }) do
			cylinder("CartWheel", cartPos + Vector3.new(side * 3.75, 1.5, z), 0.5, 3, wood, CFrame.identity)
			cylinder("WheelHub", cartPos + Vector3.new(side * 4.02, 1.5, z), 0.08, 1.7, cream, CFrame.identity)
			cylinder("WheelAxle", cartPos + Vector3.new(side * 4.1, 1.5, z), 0.13, 0.55, wood, CFrame.identity)
		end
	end
	for _, x in ipairs({ -3, 3 }) do
		for _, z in ipairs({ -4.3, 4.3 }) do
			box("CanopyPost", Vector3.new(0.35, 5, 0.35), cartPos + Vector3.new(x, 6.2, z), wood)
		end
	end
	for i = 0, 6 do
		local z = -5 + i * 1.65
		local color = i % 2 == 0 and pink or cream
		box("StripedCanopyTop", Vector3.new(2.6, 0.2, 1.66), cartPos + Vector3.new(0, 9, z), color)
		for _, s in ipairs({ -1, 1 }) do
			box(
				"StripedCanopyWing",
				Vector3.new(3.5, 0.2, 1.66),
				cartPos + Vector3.new(s * 2.75, 8.6, z),
				color,
				false,
				CFrame.Angles(0, 0, math.rad(-s * 16))
			)
		end
	end
	for j = 1, 3 do
		local pos = cartPos + Vector3.new(-1.8, 4.3, (j - 2) * 3.0)
		local jar = cylinder("CandyJar", pos + Vector3.new(0, 0.85, 0), 1.7, 1.5, Color3.fromRGB(221, 248, 247))
		jar.Transparency = 0.55
		cylinder("JarLid", pos + Vector3.new(0, 1.8, 0), 0.2, 1.7, palette[j])
		for k = 1, 7 do
			local a = k * 2.2
			part(
				"JarSweet",
				Vector3.new(0.42, 0.42, 0.42),
				CFrame.new(pos + Vector3.new(math.cos(a) * 0.4, 0.35 + k % 3 * 0.35, math.sin(a) * 0.4)),
				palette[(k + j) % #palette + 1],
				false,
				Enum.PartType.Ball
			)
		end
	end
	lollipop(cartPos + Vector3.new(0, 0, 7.6), Color3.fromRGB(249, 211, 117), 1.5)
	finish(cart, cartPos)
	local shadePos = Vector3.new(left + 8, high, front - 116)
	local shade = begin("MintBenchShade")
	for _, z in ipairs({ -5.8, 5.8 }) do
		box("ShadePost", Vector3.new(0.5, 7.8, 0.5), shadePos + Vector3.new(-2.8, 3.9, z), wood)
	end
	for i = 0, 6 do
		local z = -6 + i * 2
		box(
			"ShadeCanopy",
			Vector3.new(8.5, 0.22, 2.0),
			shadePos + Vector3.new(0, 8.0, z),
			i % 2 == 0 and pink or cream,
			false,
			CFrame.Angles(0, 0, math.rad(-8))
		)
	end
	box("BenchSeat", Vector3.new(3.1, 0.45, 9), shadePos + Vector3.new(0, 2.1, 0), mint, true)
	box("BenchBack", Vector3.new(0.45, 2.0, 9), shadePos + Vector3.new(-1.4, 3.4, 0), mint, true)
	for _, z in ipairs({ -3.5, 3.5 }) do
		for _, x in ipairs({ -1, 1 }) do
			box("BenchLeg", Vector3.new(0.5, 1.9, 0.5), shadePos + Vector3.new(x, 0.95, z), wood)
		end
	end
	for i = 1, 5 do
		part(
			"Gumdrop",
			Vector3.new(1.2, 1.2, 1.2),
			CFrame.new(shadePos + Vector3.new(2.5 + i % 2, 0.6, i * 1.5 - 4.5)),
			palette[i],
			false,
			Enum.PartType.Ball
		)
	end
	finish(shade, shadePos)
	root.WorldPivot = CFrame.new((left + right) / 2, high, (front + back) / 2)
	root.Parent = world
	task.wait()
	for _, side in ipairs({ -1, 1 }) do
		for i, t in ipairs({ 32, 105, 158 }) do
			local pos = Vector3.new(side < 0 and left + 4.0 or right - 4.0, high, front - t)
			local m = begin("SwirlLollipop")
			lollipop(pos, i % 2 == 0 and pink or Color3.fromRGB(246, 208, 109), 1.9)
			finish(m, pos)
		end
	end
	local function flowers(pos, _index, scale)
		local m = begin("PastelFlowerPocket")
		local s = scale or 1
		for j = 1, 3 do
			box(
				"MintShrub",
				Vector3.new(2.1 * s, (1.1 + j % 2 * 0.4) * s, 2.1 * s),
				pos + Vector3.new((j - 2) * 1.25 * s, 0.6 * s, j % 2 * s),
				j % 2 == 0 and Color3.fromRGB(103, 177, 151) or Color3.fromRGB(143, 214, 177),
				true
			)
		end
		for j = 1, 4 do
			local c = pos
				+ Vector3.new((j % 2 == 0 and 1.2 or -1.1) * s, (1.4 + j % 2 * 0.2) * s, (j < 3 and -0.7 or 1.5) * s)
			local color = j == 1 and cream
				or j == 2 and Color3.fromRGB(255, 211, 116)
				or j == 3 and Color3.fromRGB(255, 247, 234)
				or pink
			for k = 1, 5 do
				local a = k * math.pi * 2 / 5
				part(
					"Petal",
					Vector3.new(0.15 * s, 0.82 * s, 0.82 * s),
					CFrame.new(c + Vector3.new(math.cos(a) * 0.4 * s, 0, math.sin(a) * 0.4 * s))
						* CFrame.Angles(0, 0, math.pi / 2),
					color,
					false,
					Enum.PartType.Cylinder
				)
			end
			cylinder("FlowerHeart", c + Vector3.new(0, 0.1 * s, 0), 0.2 * s, 0.4 * s, Color3.fromRGB(250, 210, 95))
		end
		finish(m, pos)
	end
	local index = 0
	for _, side in ipairs({ -1, 1 }) do
		for _i, t in ipairs({ 15, 46, 79, 112, 146, 168 }) do
			index += 1
			flowers(Vector3.new(side < 0 and left + 34 or right - 34, low, front - t), index, 1.2)
		end
		for _i, t in ipairs({ 16, 58, 95, 145, 168 }) do
			index += 1
			flowers(Vector3.new(side < 0 and left + 4.3 or right - 4.3, high, front - t), index, 1.2)
		end
		local path = begin("CreamAndBlushPath")
		for i = 1, 9 do
			box(
				"PastelStep",
				Vector3.new(3.7, 0.08, 4),
				Vector3.new(side < 0 and left + 22 or right - 22, high + 0.05, front - 10 - i * 17),
				i % 2 == 0 and cream or Color3.fromRGB(244, 204, 214),
				true
			)
		end
		finish(path, Vector3.new(side < 0 and left + 22 or right - 22, high, front - 90))
		task.wait()
	end
	-- Tie the scenery to the existing hand-placed pink trees.
	for _, tree in ipairs(map.NativeEnvironment:GetDescendants()) do
		if tree:IsA("Model") and (tree.Name == "RobloxOak" or tree.Name == "RobloxPalm") then
			local c = tree:GetBoundingBox().Position
			if c.Z > back + 7 and c.Z < front - 7 and (c.X < left + 26 or c.X > right - 26) then
				index += 1
				flowers(Vector3.new(c.X, high, c.Z - 2), index, 1.15)
			end
		end
	end
	root:SetAttribute("Version", 1)
	root:SetAttribute("FlowerPockets", index)
	return root
end
return Candy
