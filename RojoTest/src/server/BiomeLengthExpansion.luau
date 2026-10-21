--!strict
-- Extend the authored World 1 route after its scenery passes, without scaling props.
local Expansion = {}
local V = Vector3.new
local SCALE = 1.5

-- The attributes describe the route of the scene. The scene is edited after
-- the expansion, so they are read from the water blocks themselves: an
-- attribute that does not match the geometry would report a gap that is not
-- there.
function Expansion.refresh(map): { front: number, back: number }?
	local world = map.SkippingWorld
	local first = world:FindFirstChild("Water_1") :: BasePart?
	local last = world:FindFirstChild("Water_8") :: BasePart?
	if not first or not last then
		return nil
	end
	local front = first.Position.Z + first.Size.Z / 2
	local back = last.Position.Z - last.Size.Z / 2
	map:SetAttribute("RouteFrontZ", front)
	map:SetAttribute("RouteEndZ", back)
	map:SetAttribute("RouteLengthStuds", front - back)
	return { front = front, back = back }
end

function Expansion.apply(map, dryRun)
	if map:GetAttribute("BiomeLengthScale") == SCALE then
		if not dryRun then
			Expansion.refresh(map)
		end
		return { alreadyApplied = true }
	end
	assert(map:GetAttribute("BiomeLengthScale") == nil, "Review the existing route scale")
	local world = map.SkippingWorld
	local first = world.Water_1
	assert(math.abs(first.Size.Z - 180) < 0.01, "Expected eight authored 180-stud biomes")
	local front = first.Position.Z + first.Size.Z / 2
	local oldBack, newBack = front - 1440, front - 2160
	local function zmap(z)
		return front + (z - front) * SCALE
	end
	local function delta(z)
		return V(0, 0, zmap(z) - z)
	end
	local originals, plan, pivots, rigid, attributes = {}, {}, {}, {}, {}
	for _, p in map:GetDescendants() do
		if p:IsA("BasePart") then
			originals[p] =
				{ cf = p.CFrame, size = p.Size, collide = p.CanCollide, touch = p.CanTouch, query = p.CanQuery }
		end
	end
	local function movePart(p, d, size)
		assert(not plan[p], "Overlapping expansion operations: " .. p:GetFullName())
		plan[p] = { cf = p.CFrame + d, size = size or p.Size }
	end
	local function stretch(p)
		assert(math.abs(p.CFrame.LookVector.Z) > 0.999, "Structural part must follow the river: " .. p:GetFullName())
		movePart(p, delta(p.Position.Z), V(p.Size.X, p.Size.Y, p.Size.Z * SCALE))
	end
	local function moveModel(m, anchorZ)
		local d = delta(anchorZ or m:GetPivot().Position.Z)
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				movePart(p, d)
			elseif p:IsA("Model") then
				pivots[p] = p:GetPivot() + d
			end
		end
		pivots[m] = m:GetPivot() + d
		table.insert(rigid, { model = m, delta = d })
	end
	local function spreadPath(m)
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				movePart(p, delta(p.Position.Z))
			end
		end
		pivots[m] = m:GetPivot() + delta(m:GetPivot().Position.Z)
	end
	local function scenery(root)
		for _, m in root:GetChildren() do
			if m:IsA("Model") then
				if
					m.Name:find("Path")
					or m.Name:find("Pavers")
					or m.Name == "ScatteredSakuraPetals"
					or m.Name == "ShoreMoorings"
				then
					spreadPath(m)
				else
					moveModel(m)
				end
			end
		end
		pivots[root] = root:GetPivot() + delta(root:GetPivot().Position.Z)
	end
	-- Continuous ground, water skins and the legacy underlay remain continuous.
	for _, p in world:GetChildren() do
		if p:IsA("BasePart") then
			if
				p.Name:match("^Water_%d$")
				or p.Name:match("^BiomeBank%d_[12]$")
				or p.Name == "BankExtension"
				or p.Name == "BankSafetyExtension"
			then
				stretch(p)
			elseif p.Name == "RiverEndSafety" then
				movePart(p, V(0, 0, newBack - oldBack))
			elseif
				p.Position.Z < front - 0.1
				and (
					p.Name == "LabelAnchor" and math.abs(p.Position.X - first.Position.X) < 1
					or p.Name == "BiomeDecorStem"
					or p.Name == "PalmFrond"
					or p.Name == "CactusArm"
					or p.Name == "CrystalSatellite"
					or p.Name == "CandyCrown"
					or p.Name == "MoonOrb"
				)
			then
				movePart(p, delta(p.Position.Z))
			end
		end
	end
	for _, zone in map.WaterCorridor:GetChildren() do
		if zone:IsA("Model") then
			local trunks = {}
			for _, p in zone:GetChildren() do
				if p:IsA("BasePart") and p.Name == "Trunk" then
					table.insert(trunks, p)
				end
			end
			for _, p in zone:GetChildren() do
				if p:IsA("BasePart") then
					if p.Name == "GroundTile" or p.Name == "InnerBankEarth" or p.Name == "OuterBankEarth" then
						stretch(p)
					else
						local anchor = p.Position.Z
						if p.Name == "Trunk" or p.Name == "Crown" or p.Name == "CrownTop" or p.Name == "PalmLeaf" then
							local best = math.huge
							for _, t in trunks do
								local dist = (V(t.Position.X, 0, t.Position.Z) - V(p.Position.X, 0, p.Position.Z)).Magnitude
								if dist < best then
									best = dist
									anchor = t.Position.Z
								end
							end
						end
						movePart(p, delta(anchor))
					end
				end
			end
			pivots[zone] = zone:GetPivot() + delta(zone:GetPivot().Position.Z)
		end
	end
	stretch(map.WaterCorridor.RiverBed)
	for _, p in map.PerimeterWalls:GetChildren() do
		if p:IsA("BasePart") then
			if p.Name == "CorridorLeft" or p.Name == "CorridorRight" then
				-- Roblox caps one Part at 2048 studs; retain the first 1920 here
				-- and add the final 240-stud wall section after the transform.
				movePart(p, V(0, 0, front - 960 - p.Position.Z), V(p.Size.X, p.Size.Y, 1920))
			elseif p.Name == "CorridorEnd" then
				movePart(p, V(0, 0, newBack - 3 - p.Position.Z))
			elseif p.Name == "WallPanel" and p.Position.Z < front then
				stretch(p)
			end
		end
	end
	for _, p in map.CorridorBarriers:GetChildren() do
		if p.Name == "SideBarrier" then
			stretch(p)
		end
	end
	for _, p in map.SurfaceRepairs:GetChildren() do
		if p:IsA("BasePart") then
			if
				p.Name == "InnerBankEarth_Surface"
				or p.Name == "OuterBankEarth_Surface"
				or p.Name == "RiverBed_Surface"
				or p.Name == "WallPanel_Surface" and p.Position.Z < front
			then
				stretch(p)
			elseif p.Position.Z < front and (p.Name == "CliffShoulder_Surface" or p.Name == "MesaCap_Surface") then
				movePart(p, delta(p.Position.Z))
			end
		end
	end
	for _, zone in map.EnvironmentPolish:GetChildren() do
		if zone.Name:match("^Biome%d$") then
			for _, p in zone:GetChildren() do
				if p:IsA("Model") then
					moveModel(p)
				elseif p:IsA("BasePart") then
					if p.Name == "WallCornice" then
						stretch(p)
					else
						movePart(p, delta(p.Position.Z))
					end
				end
			end
			pivots[zone] = zone:GetPivot() + delta(zone:GetPivot().Position.Z)
		end
	end
	local native = map.NativeEnvironment
	for _, tree in native.Trees:GetChildren() do
		if tree:IsA("Model") and tree:GetPivot().Position.Z < front then
			moveModel(tree)
		end
	end
	for _, garden in native.ShoreGardens:GetChildren() do
		if garden:IsA("Model") then
			if garden.Name:match("^BiomeGarden%d$") then
				for _, c in garden:GetChildren() do
					if c:IsA("Model") then
						moveModel(c)
					elseif c:IsA("BasePart") then
						local anchor = c.Position.Z
						for _, pillar in garden:GetChildren() do
							if pillar.Name == "CliffPillar" and math.abs(pillar.Position.X - c.Position.X) < 8 then
								anchor = pillar.Position.Z
								break
							end
						end
						movePart(c, delta(anchor))
					end
				end
				pivots[garden] = garden:GetPivot() + delta(garden:GetPivot().Position.Z)
			else
				moveModel(garden)
			end
		end
	end
	scenery(map.WaterCorridor["01_ЛУГА"].TropicalLanding)
	for _, name in
		{
			"DesertArchaeology",
			"CandyPromenade",
			"CrystalObservatory",
			"AmberMineAndForge",
			"MoonlightPromenade",
			"PolarExpedition",
			"SakuraThreshold",
		}
	do
		scenery(world[name])
	end
	-- The pavilion and the original bench are one composition, as are the ema rack
	-- and banner. Gate, panorama and flowering boughs move together to the new end.
	local japanese = world.SakuraJapaneseFinale
	local benchZ = world.SakuraThreshold.SakuraViewingBench:GetPivot().Position.Z
	local bannerZ = world.SakuraThreshold.BlossomBannerGarden:GetPivot().Position.Z
	for _, m in japanese:GetChildren() do
		if m:IsA("Model") then
			if m.Name == "SakuraGatewayFrame" or m.Name == "SakuraPortalPanorama" or m.Name == "GatewaySakuraBough" then
				moveModel(m, front - 1440)
			elseif m.Name == "SakuraTeaPavilion" or m.Name == "VermilionGardenRails" then
				moveModel(m, benchZ)
			elseif m.Name == "EmaWishPlaqueRack" then
				moveModel(m, bannerZ)
			elseif m.Name == "SmallRakedSandGarden" then
				moveModel(m, m:GetPivot().Position.X < first.Position.X and benchZ or bannerZ)
			else
				moveModel(m)
			end
		end
	end
	pivots[japanese] = japanese:GetPivot() + delta(japanese:GetPivot().Position.Z)
	-- Thin moss/snow caps follow their actual rock, not an independent stretched Z.
	for p in originals do
		for _, key in { "SnowSupportFrame", "MossSupportFrame" } do
			local cf = p:GetAttribute(key)
			if cf then
				local support, near = nil, 0.02
				for q, old in originals do
					if q ~= p and plan[q] then
						local dist = (old.cf.Position - cf.Position).Magnitude
						if dist < near then
							near = dist
							support = q
						end
					end
				end
				assert(support, "Missing authored rock support")
				local d = plan[support].cf.Position - originals[support].cf.Position
				movePart(p, d)
				attributes[p] = { key = key, value = cf + d }
			end
		end
	end
	if dryRun then
		local count = 0
		for _ in plan do
			count += 1
		end
		return { plannedParts = count, rigidGroups = #rigid, front = front, back = newBack }
	end
	-- Preserve a complete pre-expansion Edit snapshot, including hand placement.
	local backups = game.ServerStorage:FindFirstChild("WorldBackups") or Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = game.ServerStorage
	local backup = Instance.new("Model")
	backup.Name = "BeforeBiomeLengthExpansion_" .. os.date("%Y%m%d_%H%M%S")
	backup.Parent = backups
	for key, value in map:GetAttributes() do
		backup:SetAttribute(key, value)
	end
	for _, child in map:GetChildren() do
		child:Clone().Parent = backup
		task.wait()
	end
	backup.WorldPivot = map:GetPivot()
	-- Move complete prop models via PivotTo; resize only structural surfaces.
	local moved = {}
	for _, entry in rigid do
		for _, p in entry.model:GetDescendants() do
			if p:IsA("BasePart") then
				moved[p] = true
			end
		end
		entry.model:PivotTo(entry.model:GetPivot() + entry.delta)
	end
	local count = 0
	for p, new in plan do
		if not moved[p] then
			p.Size = new.size
			p.CFrame = new.cf
		end
		count += 1
		if count % 400 == 0 then
			task.wait()
		end
	end
	for m, cf in pivots do
		if not m.PrimaryPart then
			m.WorldPivot = cf
		end
	end
	for p, a in attributes do
		p:SetAttribute(a.key, a.value)
	end
	local Config = require(game.ReplicatedStorage.Shared.GameConfig)
	for _, p in world:GetChildren() do
		if p.Name == "LabelAnchor" and math.abs(p.Position.X - first.Position.X) < 1 and p.Position.Z < front then
			local gui = p:FindFirstChildWhichIsA("BillboardGui")
			local label = gui and gui:FindFirstChildWhichIsA("TextLabel")
			if label then
				local index = math.clamp(math.floor((front - p.Position.Z) / 270) + 1, 1, 8)
				label.Text = Config.Biomes[index].name .. "\n" .. Config.format((index - 1) * 1125) .. " m"
			end
		end
	end
	local preserved = 0
	for p, old in originals do
		local expected = plan[p]
		assert(
			(p.CFrame.Position - (expected and expected.cf or old.cf).Position).Magnitude < 0.02,
			"Unexpected part movement"
		)
		assert(
			(p.Size - (expected and expected.size or old.size)).Magnitude < 0.01,
			"Unexpected size change: " .. p:GetFullName()
		)
		assert(
			p.CanCollide == old.collide and p.CanTouch == old.touch and p.CanQuery == old.query,
			"Collision flag changed"
		)
		if not expected then
			preserved += 1
		end
	end
	for _, name in { "CorridorLeft", "CorridorRight" } do
		local wall = map.PerimeterWalls[name]:Clone()
		wall.Name = name .. "FinalExtension"
		wall.Size = V(wall.Size.X, wall.Size.Y, 240)
		wall.Position = V(wall.Position.X, wall.Position.Y, newBack + 120)
		wall.Parent = map.PerimeterWalls
	end
	map:SetAttribute("BiomeLengthScale", SCALE)
	map:SetAttribute("BiomeLengthStuds", 270)
	map:SetAttribute("RouteLengthStuds", 2160)
	map:SetAttribute("RouteDistanceMetres", 9000)
	map:SetAttribute("RouteFrontZ", front)
	map:SetAttribute("RouteEndZ", newBack)
	return {
		changed = count,
		unchanged = preserved,
		rigidGroups = #rigid,
		front = front,
		back = newBack,
		backup = backup.Name,
	}
end

return Expansion
