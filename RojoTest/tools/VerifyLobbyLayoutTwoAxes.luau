-- Read-only checks in Studio Edit or Server; never touches player progression.
local map = workspace.ProgressionMap
local f = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
local n = 0
local function check(ok, message)
	assert(ok, message)
	n += 1
end
check(map:GetAttribute("LobbyLayoutVersion") == 1, "Approved layout is missing")
local layout = map.TwoAxesLayout
check(layout:GetAttribute("CentralClearWidth") == 16, "Central walking width changed")
local old = game.ServerStorage.WorldBackups.BeforeLobbyLayoutTwoAxes_20261018.ProgressionMap
check(map.Lobby.ThrowingApron.CFrame == old.Lobby.ThrowingApron.CFrame, "Throwing corridor anchor moved")
check(map.Lobby.ThrowingApron.Size == old.Lobby.ThrowingApron.Size, "Throwing apron resized")
local last = math.huge
for i = 1, 7 do
	local lane = map.TrainingZone["TrainingLane" .. i]
	local previous = old.TrainingZone["TrainingLane" .. i]
	local q = f:PointToObjectSpace(lane.StartingPad.Position)
	check(math.abs(q.X + 91) < 0.001 and math.abs(q.Z - (155 - (i - 1) * 17)) < 0.001, "Lane arrangement " .. i)
	check(q.Z < last, "Training sequence")
	last = q.Z
	check(lane.TrainingStrip.Size == previous.TrainingStrip.Size, "Training lengths preserved " .. i)
	check(
		#lane.ImportedField:GetDescendants() == #previous.ImportedField:GetDescendants(),
		"Imported field preserved " .. i
	)
	local delta = lane.TrainingStrip.CFrame * previous.TrainingStrip.CFrame:Inverse()
	check(
		(lane.StartingPad.Position - (delta * previous.StartingPad.CFrame).Position).Magnitude < 0.001,
		"Trigger follows field " .. i
	)
	check(lane.StartingPad.CanTouch == previous.StartingPad.CanTouch, "Training trigger properties")
end
for _, id in ipairs({ "Common", "Uncommon", "Rare", "Rainbow" }) do
	local egg = map.SkippingWorld["Egg_" .. id]
	check(egg:FindFirstChild("ImportedVisual") ~= nil, "Imported egg " .. id)
	local p = f:PointToObjectSpace(egg.EggPedestal.Position)
	check(p.X >= -181 and p.X <= -140 and p.Z >= 133 and p.Z <= 169, "Eggs grouped on shared pad")
	local pp = egg.EggShell:FindFirstChildWhichIsA("ProximityPrompt")
	check(pp and pp.Enabled, "Egg prompt preserved")
end
local donor = f:PointToObjectSpace(map.SkippingWorld.HackedAdminEgg.Position)
check(math.abs(donor.X + 200) < 0.01 and math.abs(donor.Z - 151) < 0.01, "Donation egg shares egg court")
local stand = map.EmptyItemStand
check(stand.UpperTier and stand.LowerTier, "Both original tiers preserved")
local labels = {}
for i = 1, 10 do
	local top = stand["DisplayTop" .. i]
	local pp = stand["BallPurchase" .. i]
	local expected = top.CFrame:PointToWorldSpace(Vector3.new(top.Size.X / 2 + 1, 0.6, 0))
	check((pp.Position - expected).Magnitude < 0.001, "Rotated purchase prompt " .. i)
	check(pp.BallPurchasePrompt.Enabled, "Ball prompt enabled " .. i)
end
local balls = workspace:FindFirstChild("AllBalls_NoTextures") or stand:FindFirstChild("DisplayBalls")
check(balls ~= nil, "Imported ball display retained")
for _, ball in ipairs(balls:GetChildren()) do
	if ball:IsA("Model") and ball:GetAttribute("DisplaySlot") then
		local slot = ball:GetAttribute("DisplaySlot")
		local top = stand["DisplayTop" .. slot]
		local base = ball:GetAttribute("DisplayBasePivot")
		check(typeof(base) == "CFrame", "Animated display origin")
		check(
			(Vector2.new(base.X, base.Z) - Vector2.new(top.Position.X, top.Position.Z)).Magnitude < 0.01,
			"Ball follows moved tile"
		)
		local link = ball:FindFirstChild("DisplayLabel")
		check(link and link.Value and link.Value:FindFirstChildWhichIsA("BillboardGui").Enabled, "Active ball label")
		labels[link.Value] = true
	end
end
for _, p in ipairs(map.SkippingWorld:GetChildren()) do
	if p:IsA("BasePart") and p:GetAttribute("BallDisplayLabelSlot") then
		local gui = p:FindFirstChildWhichIsA("BillboardGui")
		check(not gui or not gui.Enabled or labels[p], "No detached duplicate price label")
	end
end
local boards = map.LobbyRankings
check(#boards:GetChildren() == 4, "Four-board courtyard")
for _, board in ipairs(boards:GetChildren()) do
	local toward = f:PointToWorldSpace(Vector3.new(-106, 18, 193)) - board.Frame.Position
	check(board.Frame.CFrame.LookVector:Dot(toward) > 0, "Board faces courtyard")
end
check(boards.ReservedFourthBoard:GetAttribute("LayoutPlaceholder"), "Fourth ranking reserved; data logic untouched")
local portal = map.SkippingWorld.World2Portal
check(
	portal.SakuraVisual
		and (
			portal.SakuraCourtyard:FindFirstChild("SakuraTree") or portal.SakuraCourtyard:GetAttribute("HideSakuraTree")
		),
	"Portal visual and requested tree visibility"
)
local prompt = portal.PortalField:FindFirstChildWhichIsA("ProximityPrompt", true)
check(prompt and prompt.Enabled and prompt.Parent:IsA("Attachment"), "Portal interaction retained")
local ground = f:PointToObjectSpace(prompt.Parent.WorldPosition)
check(
	math.abs(ground.X + 174) < 0.01 and math.abs(ground.Z - 48) < 0.01 and ground.Y < 7,
	"Portal prompt at reachable height"
)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { map.Lobby }
local floors = 0
for _, p in ipairs(layout.Paving:GetChildren()) do
	check(not p.CanCollide and not p.CanTouch and not p.CanQuery, "Walking overlay has no blocking volume")
	for _, uv in ipairs({ { 0, 0 }, { -0.4, -0.4 }, { -0.4, 0.4 }, { 0.4, -0.4 }, { 0.4, 0.4 } }) do
		local origin = p.Position + f:VectorToWorldSpace(Vector3.new(p.Size.X * uv[1], 5, p.Size.Z * uv[2]))
		local hit = workspace:Raycast(origin, Vector3.new(0, -12, 0), params)
		check(hit ~= nil, "Physical floor under walking overlay")
		check(math.abs(hit.Position.Y - f.Position.Y) < 0.1, "Flat authored lobby floor")
		floors += 1
	end
end
local baseline = _G.LobbyLayoutBaseline
local originalParts = 0
if baseline then
	for p, v in pairs(baseline.parts) do
		local archivedTree = game.ServerStorage.WorldBackups:FindFirstChild("RemovedLobbyPortalSakura_20261018")
		check(
			p:IsDescendantOf(map) or (archivedTree and p:IsDescendantOf(archivedTree)),
			"An original part was removed"
		)
		check((p.Size - v.size).Magnitude < 0.001, "Original part resized: " .. p:GetFullName())
		check(
			p.CanCollide == v.collide and p.CanTouch == v.touch and p.CanQuery == v.query,
			"Original collision flags changed"
		)
		if v.mesh then
			check(p.MeshId == v.mesh, "Imported mesh replaced")
		end
		if f:PointToObjectSpace(v.cf.Position).Z < 0 then
			check(p.CFrame == v.cf, "Unrelated river scenery moved")
		end
		originalParts += 1
		if originalParts % 1000 == 0 then
			task.wait()
		end
	end
	for asset, count in pairs(baseline.assets) do
		check(asset.Parent == workspace and #asset:GetDescendants() == count, "Imported source asset altered")
	end
end
return {
	checks = n,
	floorSamples = floors,
	preservedOriginalParts = originalParts,
	layout = "Two Axes",
	rankings = "Three existing rankings plus one reserved board; metrics unchanged",
}
