--!strict
-- Small, non-interactive flower pockets on the current World 1 lawn and terraces.
local Flowers = {}
local V, C = Vector3.new, Color3.fromRGB

function Flowers.apply(map)
	if map:FindFirstChild("SmallMapFlowers") then
		return map.SmallMapFlowers
	end
	assert(map.Name == "ProgressionMap" and map:FindFirstChild("SpawnGarden"), "Missing lobby garden")
	local apron = map.Lobby.ThrowingApron
	local random = Random.new(18472)
	local surfaces, obstacles, protected = {}, {}, {}
	for _, p in map:GetDescendants() do
		if p:IsA("BasePart") then
			protected[p] = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
			if
				p.Name == "GroundTile" and p.Parent == map.Lobby
				or p.Name == "GrassShelf" and p:IsDescendantOf(map.SpawnGarden)
				or p.Name == "RearGrassLedge" and p:IsDescendantOf(map.SpawnGarden)
				or p.Name == "TunnelGrassRoof" and p:IsDescendantOf(map.SpawnGardenPolish)
			then
				table.insert(surfaces, p)
			end
			if
				p.Transparency < 0.95
				and math.abs(p.Position.X - apron.Position.X) < 190
				and p.Position.Z > apron.Position.Z - 60
				and p.Position.Z < apron.Position.Z + 260
			then
				table.insert(obstacles, p)
			end
		end
	end
	assert(#surfaces > 40, "Remeasure planting surfaces")
	table.sort(surfaces, function(a, b)
		if a.Position.Y ~= b.Position.Y then
			return a.Position.Y < b.Position.Y
		end
		if a.Position.X ~= b.Position.X then
			return a.Position.X < b.Position.X
		end
		return a.Position.Z < b.Position.Z
	end)
	local root = Instance.new("Model")
	root.Name, root.WorldPivot = "SmallMapFlowers", apron.CFrame
	root:SetAttribute("Version", 1)
	local colors = { C(255, 250, 228), C(255, 250, 228), C(255, 180, 205), C(255, 225, 117), C(207, 183, 255) }
	local planted, groups, bases = 0, 0, {}
	local function clear(base, surface)
		for _, p in obstacles do
			if p ~= surface then
				local q = p.CFrame:PointToObjectSpace(base + V(0, 0.8, 0))
				local h = p.Size / 2
				if math.abs(q.X) < h.X + 0.9 and math.abs(q.Y) < h.Y + 0.77 and math.abs(q.Z) < h.Z + 0.9 then
					return false
				end
			end
		end
		for _, other in bases do
			if (base - other).Magnitude < 1.6 then
				return false
			end
		end
		return true
	end
	local function part(parent, name, size, cf, color)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
	end
	local function pocket(surface, x, z)
		local batch = Instance.new("Model")
		batch.Name = "FlowerPocket"
		local origin = surface.CFrame * V(x, surface.Size.Y / 2, z)
		batch.WorldPivot = CFrame.new(origin)
		local count = random:NextInteger(3, 4)
		local tint = colors[random:NextInteger(1, #colors)]
		for i = 1, count do
			local angle = i * 2.399 + random:NextNumber(-0.25, 0.25)
			local offset = V(math.cos(angle) * 1.9, 0, math.sin(angle) * 1.6)
			local localBase = V(x + offset.X, surface.Size.Y / 2, z + offset.Z)
			local base = surface.CFrame * localBase
			if
				math.abs(localBase.X) < surface.Size.X / 2 - 1
				and math.abs(localBase.Z) < surface.Size.Z / 2 - 1
				and clear(base, surface)
			then
				local s = random:NextNumber(0.65, 0.9)
				local flower = Instance.new("Model")
				flower.Name, flower.WorldPivot = "SmallFlower", CFrame.new(base)
				local cf = CFrame.new(base) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0)
				part(flower, "Stem", V(0.14, 1.4, 0.14) * s, cf * CFrame.new(0, 0.7 * s, 0), C(49, 151, 58))
				part(
					flower,
					"Leaf",
					V(0.8, 0.13, 0.32) * s,
					cf * CFrame.new(0.24 * s, 0.55 * s, 0) * CFrame.Angles(0, 0, 0.3),
					C(94, 191, 62)
				)
				part(flower, "Petals", V(1.65, 0.23, 0.64) * s, cf * CFrame.new(0, 1.4 * s, 0), tint)
				part(flower, "Petals", V(0.64, 0.23, 1.65) * s, cf * CFrame.new(0, 1.41 * s, 0), tint)
				part(flower, "Pollen", V(0.44, 0.3, 0.44) * s, cf * CFrame.new(0, 1.55 * s, 0), C(255, 192, 48))
				flower.Parent = batch
				table.insert(bases, base)
				planted += 1
			end
		end
		if #batch:GetChildren() > 0 then
			batch.Parent = root
			groups += 1
		else
			batch:Destroy()
		end
	end
	root.Parent = map
	for index, surface in surfaces do
		if surface.Name == "GroundTile" then
			-- Sparse pockets; gameplay pads, paths and props are rejected by clearance.
			if index % 5 == 0 then
				pocket(surface, random:NextNumber(-3, 3), random:NextNumber(-3, 3))
			end
		elseif surface.Size.X > 100 then
			for x = -surface.Size.X / 2 + 12, surface.Size.X / 2 - 12, 29 do
				pocket(surface, x, -surface.Size.Z / 2 + 3.5)
			end
		else
			-- The exposed inner lip leaves the established shrubs and rocks intact.
			local inward = surface.Position.X < apron.Position.X and 1 or -1
			pocket(surface, inward * (surface.Size.X / 2 - 3.6), random:NextNumber(-7, 7))
		end
		if index % 12 == 0 then
			task.wait()
		end
	end
	local verified = 0
	for p, old in protected do
		assert(
			p.CFrame == old[1]
				and p.Size == old[2]
				and p.CanCollide == old[3]
				and p.CanTouch == old[4]
				and p.CanQuery == old[5],
			"Existing volume changed: " .. p:GetFullName()
		)
		verified += 1
	end
	root:SetAttribute("FlowerCount", planted)
	root:SetAttribute("PocketCount", groups)
	root:SetAttribute("OriginalPartsVerified", verified)
	return root
end

return Flowers
