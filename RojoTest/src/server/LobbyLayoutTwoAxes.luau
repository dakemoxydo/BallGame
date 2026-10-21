--!strict
-- Rearranges the authored World 1 lobby; never regenerates imported scenery.
local Layout = {}
local V, CF, C = Vector3.new, CFrame.new, Color3.fromRGB
local VERSION = 1
local TEXTURE = "rbxassetid://88156646156237"

function Layout.apply(map)
	if map:GetAttribute("LobbyLayoutVersion") == VERSION then
		return map:FindFirstChild("TwoAxesLayout")
	end
	assert(map.Name == "ProgressionMap" and map:GetAttribute("Version") == 9, "Unexpected authored map")
	local lobby, skip, training = map.Lobby, map.SkippingWorld, map.TrainingZone
	local frame = lobby.ThrowingApron.CFrame * CF(115, -0.3, -13)
	local function localPoint(p)
		return frame:PointToObjectSpace(p)
	end
	local function _point(x, y, z)
		return frame:PointToWorldSpace(V(x, y, z))
	end
	for i = 1, 7 do
		assert(training:FindFirstChild("TrainingLane" .. i), "Missing training lane")
	end
	assert(map.LobbyRankings.skill and map.LobbyRankings.wins and map.LobbyRankings.best, "Missing original rankings")
	assert(not map:FindFirstChild("TwoAxesLayout"), "Partial layout needs inspection")
	if game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() then
		assert(
			game.ServerStorage.WorldBackups:FindFirstChild("BeforeLobbyLayoutTwoAxes_20261018"),
			"Create scene backup first"
		)
	end

	local root = Instance.new("Model")
	root.Name = "TwoAxesLayout"
	root.Parent = map
	local paving = Instance.new("Model")
	paving.Name = "Paving"
	paving.Parent = root
	local borders = Instance.new("Model")
	borders.Name = "Borders"
	borders.Parent = root
	local pale, edge = C(205, 218, 231), C(115, 135, 156)
	local function part(parent, name, x0, x1, z0, z1, color, y, height)
		local p = Instance.new("Part")
		p.Name, p.Size = name, V(x1 - x0, height or 0.14, z1 - z0)
		p.CFrame = frame * CF((x0 + x1) / 2, y or 0.19, (z0 + z1) / 2)
		p.Color, p.Material = color, Enum.Material.Plastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local t = Instance.new("Texture")
		t.Name, t.Texture, t.Face = "HDStuds_Top", TEXTURE, Enum.NormalId.Top
		t.StudsPerTileU, t.StudsPerTileV, t.Transparency = 8, 8, 0.45
		t.Color3 = color
		-- Keep the world-aligned pattern continuous across all paving modules.
		t.OffsetStudsU, t.OffsetStudsV = x0 % 8, z0 % 8
		t.Parent = p
		p.Parent = parent
		return p
	end
	local function moveModel(model, delta)
		model:PivotTo(delta * model:GetPivot())
	end
	local function movePart(p, delta)
		p.CFrame = delta * p.CFrame
	end
	local function hide(p)
		p.Transparency = 1
		for _, t in ipairs(p:GetDescendants()) do
			if t:IsA("Texture") or t:IsA("Decal") then
				t.Transparency = 1
			end
		end
	end

	-- Capture detached legacy labels before changing their original positions.
	local laneLabels, donorParts, donorLabel, bestLabel = {}, {}, nil, nil
	for i = 1, 7 do
		laneLabels[i] = {}
	end
	for _, o in ipairs(skip:GetChildren()) do
		if not o:IsA("BasePart") then
			continue
		end
		if o.Name == "HackedAdminEgg" or o.Name == "HackedEggStand" or o.Name == "HackedPixel" then
			table.insert(donorParts, o)
		end
		if o.Name == "LabelAnchor" then
			local text = o:FindFirstChildWhichIsA("TextLabel", true)
			if text then
				if text.Text:find("Hacked Admin Egg", 1, true) then
					donorLabel = o
				end
				if text.Text:find("BEST IN GAME", 1, true) then
					bestLabel = o
				end
			end
			for i = 1, 7 do
				local lane = training["TrainingLane" .. i]
				local board = skip:FindFirstChild("LaneBoard" .. i)
				if
					board
					and math.abs(o.Position.Z - lane.TrainingStrip.Position.Z) < 0.1
					and math.abs(o.Position.X - board.Position.X) < 0.1
				then
					table.insert(laneLabels[i], o)
				end
			end
		end
	end
	assert(donorLabel and #donorParts == 8, "Unexpected donation egg assembly")

	-- Keep the imported training meshes, triggers, lengths and lane IDs intact.
	for i = 1, 7 do
		local lane = training["TrainingLane" .. i]
		local old = localPoint(lane.StartingPad.Position)
		local shift = frame:VectorToWorldSpace(V(-91 - old.X, 0, 155 - (i - 1) * 17 - old.Z))
		local delta = CF(shift)
		moveModel(lane, delta)
		for _, name in ipairs({ "TrainingStone" .. i, "LaneBoard" .. i }) do
			local o = skip:FindFirstChild(name)
			if o then
				movePart(o, delta)
			end
		end
		for _, label in ipairs(laneLabels[i]) do
			movePart(label, delta)
		end
		for _, overlay in ipairs(map.SurfaceRepairs:GetChildren()) do
			local source = overlay:GetAttribute("SurfaceSource")
			if
				overlay:IsA("BasePart")
				and type(source) == "string"
				and source:find("TrainingZone.TrainingLane" .. i .. ".", 1, true)
			then
				movePart(overlay, delta)
			end
		end
		local cf = lane:GetBoundingBox()
		if not lane.PrimaryPart then
			lane.WorldPivot = cf
		end
	end
	local trainingTitle = training:FindFirstChild("UIAnchor")
	if trainingTitle then
		trainingTitle.CFrame = frame * CF(-56, 12, 169)
	end

	local eggs = { Common = { -148, 141 }, Uncommon = { -173, 141 }, Rare = { -148, 161 }, Rainbow = { -173, 161 } }
	for id, site in pairs(eggs) do
		local model = skip["Egg_" .. id]
		local p = localPoint(model.EggPedestal.Position)
		moveModel(model, CF(frame:VectorToWorldSpace(V(site[1] - p.X, 0, site[2] - p.Z))))
		if not model.PrimaryPart then
			model.WorldPivot = model:GetBoundingBox()
		end
	end
	local donorDelta = CF(frame:VectorToWorldSpace(V(-200 + 90, 0, 151 - 39)))
	for _, o in ipairs(donorParts) do
		movePart(o, donorDelta)
	end
	movePart(donorLabel, donorDelta)
	if bestLabel then
		bestLabel.CFrame = frame * CF(-200, 20, 151)
	end

	-- The existing stand already has two tiers. Rotate the complete model intact.
	local stand = map.EmptyItemStand
	local lower = stand.LowerTier
	local desired = frame * CF(-171.5, localPoint(lower.Position).Y, 94) * CFrame.Angles(0, math.pi / 2, 0)
	local standDelta = desired * lower.CFrame:Inverse()
	moveModel(stand, standDelta)
	-- These are separate imported workspace models, not children of the stand.
	local balls = workspace:FindFirstChild("AllBalls_NoTextures")
	if balls then
		moveModel(balls, standDelta)
		for _, o in ipairs(balls:GetChildren()) do
			if o:IsA("Model") then
				local base = o:GetAttribute("DisplayBasePivot")
				if typeof(base) == "CFrame" then
					o:SetAttribute("DisplayBasePivot", standDelta * base)
				end
				local label = o:GetAttribute("DisplayLabelBase")
				if typeof(label) == "Vector3" then
					o:SetAttribute("DisplayLabelBase", standDelta:PointToWorldSpace(label))
				end
			end
		end
	end
	for _, o in ipairs(skip:GetChildren()) do
		if o:IsA("BasePart") and o:GetAttribute("BallDisplayLabelSlot") then
			local top = stand:FindFirstChild("DisplayTop" .. o:GetAttribute("BallDisplayLabelSlot"))
			local oldTop = top and (standDelta:Inverse() * top.CFrame).Position
			if oldTop and math.abs(o.Position.X - oldTop.X) < 0.1 and math.abs(o.Position.Z - oldTop.Z) < 0.1 then
				movePart(o, standDelta)
			end
		end
	end
	if not stand.PrimaryPart then
		stand.WorldPivot = stand:GetBoundingBox()
	end

	-- Retain the sakura portal, tree, flowers and lanterns in a front-side pocket.
	local portal = skip.World2Portal
	local portalDelta = frame * CF(-174, 20, 48) * portal.PortalField.CFrame:Inverse()
	moveModel(portal, portalDelta)
	local slabs = {}
	for _, o in ipairs(portal.SakuraCourtyard:GetChildren()) do
		if o:IsA("BasePart") and o.Name == "ApproachSlab" then
			table.insert(slabs, o)
		end
	end
	table.sort(slabs, function(a, b)
		return localPoint(a.Position).Z < localPoint(b.Position).Z
	end)
	for i, o in ipairs(slabs) do
		o.CFrame = frame * CF(-149 + (i - 1) * 6, 0.09, 48)
	end
	if not portal.PrimaryPart then
		portal.WorldPivot = portal:GetBoundingBox()
	end

	-- A four-sided visual capacity, with existing rankings retaining their logic.
	local rankings = map.LobbyRankings
	local function boardAt(board, x, z, yaw)
		local old = board.Frame.CFrame
		local target = frame * CF(x, 18, z) * CFrame.Angles(0, yaw or 0, 0)
		moveModel(board, target * old:Inverse())
		board.WorldPivot = board:GetBoundingBox()
	end
	boardAt(rankings.skill, -122, 212, 0)
	boardAt(rankings.wins, -90, 212, 0)
	boardAt(rankings.best, -53, 195, math.pi / 2)
	local future = rankings.best:Clone()
	future.Name = "ReservedFourthBoard"
	future:SetAttribute("LayoutPlaceholder", true)
	local gui = future.Panel.RankingGui
	gui.Title.Text = "ДОНАТ"
	gui.Scope.Text = "РЕЙТИНГ БУДЕТ НАСТРОЕН ПОЗЖЕ"
	gui.Status.Text = "Место для четвёртого рейтинга"
	for i = 1, 10 do
		gui["Row" .. i].Entry.Text = i .. ".   —"
	end
	boardAt(future, -159, 195, -math.pi / 2)
	future.Parent = rankings
	rankings.WorldPivot = frame * CF(-106, 0, 195)

	-- The floor and throwing corridor remain at their authored positions.
	-- Replace only old walking overlays, retaining their instances for rollback.
	for _, o in ipairs(lobby:GetChildren()) do
		if o:IsA("BasePart") and (o.Name == "CentralWalkway" or o.Name == "CrossWalkway") then
			hide(o)
		end
		if o:IsA("BasePart") and o.Name == "CrossWalkway" then
			local q = localPoint(o.Position)
			o.CFrame += frame:VectorToWorldSpace(V(0, -q.Y - o.Size.Y / 2, 0))
		end
	end
	for _, o in ipairs(skip:GetChildren()) do
		if o:IsA("BasePart") and (o.Name == "MainPlazaPath" or o.Name == "EggWalkway") then
			hide(o)
		end
	end
	for _, o in ipairs(map.SurfaceRepairs:GetChildren()) do
		if o:IsA("BasePart") and o.Name == "CrossWalkway_Surface" then
			hide(o)
		end
	end
	-- Preserve the planted stone walkway, now an outer-side route.
	local stoneWalk = map:FindFirstChild("StoneGrassWalkway")
	if stoneWalk then
		moveModel(stoneWalk, CF(frame:VectorToWorldSpace(V(-3, 0, 0))))
	end
	local spawn = lobby.MapSpawn
	-- Keep the invisible spawn plate below the continuous walking floor.
	spawn.CFrame = frame * CF(-106, -0.6, 72)
	spawn.Transparency = 1
	-- Existing directional arrows remain useful on the central approach.
	for _, o in ipairs(skip:GetChildren()) do
		if o:IsA("BasePart") and (o.Name == "ArrowStem" or o.Name == "ArrowArm") then
			local _q = localPoint(o.Position)
			o.CFrame += frame:VectorToWorldSpace(V(-1, 0, -12))
		end
	end
	-- Keep the bare original lobby tree together, away from the new court.
	for _, o in ipairs(lobby:GetChildren()) do
		if o:IsA("BasePart") and (o.Name == "Trunk" or o.Name == "Crown" or o.Name == "CrownTop") then
			movePart(o, CF(frame:VectorToWorldSpace(V(-39, 0, -16))))
		end
	end

	local rectangles = {
		{ -114, -98, 25, 180 }, -- central avenue
		{ -120, -92, 137, 157 }, -- upper junction
		{ -120, -92, 88, 108 }, -- lower junction
		{ -132, -120, 141, 153 }, -- eggs branch
		{ -125, -120, 92, 104 }, -- balls branch
		{ -163, -49, 176, 219 }, -- separate flat hall of fame
		{ -218, -132, 130, 171 }, -- shared egg plaza
		{ -218, -125, 76, 118 }, -- existing two-tier shop pad
		{ -151, -114, 42, 54 }, -- flat sakura approach
		{ -98, -3, 29, 37 }, -- front outer-route link
		{ -98, -3, 167, 175 }, -- rear outer-route link
	}
	local function contains(x, z, padding)
		for _, r in ipairs(rectangles) do
			if
				x > r[1] - (padding or 0)
				and x < r[2] + (padding or 0)
				and z > r[3] - (padding or 0)
				and z < r[4] + (padding or 0)
			then
				return true
			end
		end
		return false
	end
	-- Rectangle union: large continuous slabs, no intersecting layers at junctions.
	local xs, zs = {}, {}
	for _, r in ipairs(rectangles) do
		xs[r[1]] = true
		xs[r[2]] = true
		zs[r[3]] = true
		zs[r[4]] = true
	end
	local function keys(t)
		local a = {}
		for k in pairs(t) do
			table.insert(a, k)
		end
		table.sort(a)
		return a
	end
	xs, zs = keys(xs), keys(zs)
	local slabsOut, open = {}, {}
	for zi = 1, #zs - 1 do
		local spans = {}
		local begin
		for xi = 1, #xs - 1 do
			local inside = contains((xs[xi] + xs[xi + 1]) / 2, (zs[zi] + zs[zi + 1]) / 2)
			if inside and not begin then
				begin = xs[xi]
			end
			if begin and (not inside or xi == #xs - 1) then
				local ending = inside and xs[xi + 1] or xs[xi]
				table.insert(spans, { begin, ending })
				begin = nil
			end
		end
		local nextOpen = {}
		for _, span in ipairs(spans) do
			local k = span[1] .. ":" .. span[2]
			local r = open[k]
			if r then
				r[4] = zs[zi + 1]
			else
				r = { span[1], span[2], zs[zi], zs[zi + 1] }
				table.insert(slabsOut, r)
			end
			nextOpen[k] = r
		end
		open = nextOpen
	end
	for i, r in ipairs(slabsOut) do
		part(paving, "Path" .. i, r[1], r[2], r[3], r[4], pale)
	end
	-- Thin dark edges only on the true outer silhouette of the paving union.
	for _, x in ipairs(xs) do
		local begin
		for zi = 1, #zs - 1 do
			local z = (zs[zi] + zs[zi + 1]) / 2
			local boundary = contains(x - 0.05, z) ~= contains(x + 0.05, z)
			if boundary and not begin then
				begin = zs[zi]
			end
			if begin and (not boundary or zi == #zs - 1) then
				local finish = boundary and zs[zi + 1] or zs[zi]
				part(borders, "CurbX", x - 0.22, x + 0.22, begin, finish, edge, 0.20, 0.16)
				begin = nil
			end
		end
	end
	for _, z in ipairs(zs) do
		local begin
		for xi = 1, #xs - 1 do
			local x = (xs[xi] + xs[xi + 1]) / 2
			local boundary = contains(x, z - 0.05) ~= contains(x, z + 0.05)
			if boundary and not begin then
				begin = xs[xi]
			end
			if begin and (not boundary or xi == #xs - 1) then
				local finish = boundary and xs[xi + 1] or xs[xi]
				part(borders, "CurbZ", begin, finish, z - 0.22, z + 0.22, edge, 0.20, 0.16)
				begin = nil
			end
		end
	end
	-- Replant existing small ground pockets that the new paths pass through.
	local replanted = 0
	local plantingGroups = {
		map:FindFirstChild("SmallMapFlowers"),
		skip:FindFirstChild("ImprovedLobbyFlowers"),
		map.EnvironmentPolish:FindFirstChild("LobbyGardens"),
	}
	local occupied = {}
	for _, flowers in ipairs(plantingGroups) do
		for _, model in ipairs(flowers:GetChildren()) do
			if not model:IsA("Model") then
				continue
			end
			local cf, size = model:GetBoundingBox()
			local q = localPoint(cf.Position)
			if
				q.Y - size.Y / 2 > 3
				or q.Z < 25
				or q.Z > 220
				or not contains(q.X, q.Z, math.max(size.X, size.Z) / 2)
			then
				continue
			end
			local best, distance
			for _, x in ipairs({ -122, -90, -17, -213, -186 }) do
				for z = 35, 210, 7 do
					local laneArea = x > -102 and x < -20 and z > 43 and z < 164
					local portalArea = x < -146 and z < 70
					local occupiedSite = false
					for _, site in ipairs(occupied) do
						if (site - V(x, 0, z)).Magnitude < 5 then
							occupiedSite = true
							break
						end
					end
					if
						not laneArea
						and not portalArea
						and not occupiedSite
						and not contains(x, z, math.max(size.X, size.Z) / 2 + 1)
					then
						local d = (V(x, 0, z) - V(q.X, 0, q.Z)).Magnitude
						if not distance or d < distance then
							best = V(x, q.Y, z)
							distance = d
						end
					end
				end
			end
			if best then
				moveModel(model, CF(frame:VectorToWorldSpace(best - q)))
				table.insert(occupied, V(best.X, 0, best.Z))
				replanted += 1
			end
		end
	end
	root.WorldPivot = frame * CF(-106, 0, 112)
	training.WorldPivot = training:GetBoundingBox()
	root:SetAttribute("Reference", "Approved concept 3: Two Axes")
	root:SetAttribute("ReplantedExistingPockets", replanted)
	root:SetAttribute("PavingHeight", 0.26)
	root:SetAttribute("CentralClearWidth", 16)
	map:SetAttribute("LobbyLayoutVersion", VERSION)
	return root
end

return Layout
