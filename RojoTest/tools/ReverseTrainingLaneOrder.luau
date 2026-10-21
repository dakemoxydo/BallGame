-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Run once in Studio Edit via Studio MCP. Preserve lane IDs and progression.
local map = workspace.ProgressionMap
assert(map:GetAttribute("LobbyLayoutVersion") == 1, "Unexpected authored lobby")
if map:GetAttribute("TrainingLaneOrderVersion") == 1 then
	return "Already reversed"
end
local zone, skip = map.TrainingZone, map.SkippingWorld
local lanes, slots, shifts, detached, affected = {}, {}, {}, {}, {}
local before, pivots, attributes = {}, {}, {}
for i = 1, 7 do
	local lane = assert(zone:FindFirstChild("TrainingLane" .. i))
	lanes[i] = lane
	slots[i] = lane.StartingPad.Position.Z
	attributes[lane] = lane:GetAttributes()
	assert(lane.StartingPad:GetAttribute("LaneIndex") == i, "Unexpected lane index")
	assert(math.abs(lane.TrainingStrip.Size.X - (30 + 4 * i)) < 0.01, "Unexpected lane length")
	if i > 1 then
		assert(slots[i] < slots[i - 1], "Unexpected current order")
	end
	detached[i] = {}
	local board = assert(skip:FindFirstChild("LaneBoard" .. i))
	table.insert(detached[i], board)
	table.insert(detached[i], assert(skip:FindFirstChild("TrainingStone" .. i)))
	local labelCount = 0
	for _, part in skip:GetChildren() do
		if
			part:IsA("BasePart")
			and part.Name == "LabelAnchor"
			and math.abs(part.Position.X - board.Position.X) < 0.1
			and math.abs(part.Position.Z - slots[i]) < 0.1
		then
			table.insert(detached[i], part)
			labelCount += 1
		end
	end
	assert(labelCount == 1, "Expected one linked lane label")
	for _, part in map.SurfaceRepairs:GetChildren() do
		local source = part:GetAttribute("SurfaceSource")
		if
			part:IsA("BasePart")
			and type(source) == "string"
			and source:find("TrainingZone.TrainingLane" .. i .. ".", 1, true)
		then
			table.insert(detached[i], part)
		end
	end
end
for i, lane in lanes do
	shifts[i] = Vector3.new(0, 0, slots[8 - i] - slots[i])
	for _, item in lane:GetDescendants() do
		if item:IsA("BasePart") then
			affected[item] = shifts[i]
		end
		if item:IsA("Model") then
			pivots[item] = { item:GetPivot(), shifts[i] }
		end
	end
	pivots[lane] = { lane:GetPivot(), shifts[i] }
	for _, part in detached[i] do
		affected[part] = shifts[i]
	end
end
for i, part in map:GetDescendants() do
	if part:IsA("BasePart") then
		before[part] = { part.CFrame, part.Size, part.CanCollide, part.CanTouch, part.CanQuery }
	end
	if i % 1000 == 0 then
		task.wait()
	end
end
local backups = assert(game.ServerStorage:FindFirstChild("WorldBackups"))
assert(not backups:FindFirstChild("BeforeTrainingLaneOrder_20261020"), "Inspect existing backup before retry")
local backup = Instance.new("Folder")
backup.Name = "BeforeTrainingLaneOrder_20261020"
for i, lane in lanes do
	local group = Instance.new("Folder")
	group.Name = "Lane" .. i
	lane:Clone().Parent = group
	for _, part in detached[i] do
		part:Clone().Parent = group
	end
	group.Parent = backup
end
backup.Parent = backups
game:GetService("ChangeHistoryService"):SetWaypoint("Before training lane reversal")
for i, lane in lanes do
	lane:PivotTo(lane:GetPivot() + shifts[i])
	for _, part in detached[i] do
		part.CFrame += shifts[i]
	end
end
local checked, moved = 0, 0
for part, state in before do
	local shift = affected[part] or Vector3.zero
	local expected = state[1] + shift
	assert((part.Position - expected.Position).Magnitude < 0.001, "Unexpected position: " .. part:GetFullName())
	assert(
		part.CFrame.RightVector:Dot(expected.RightVector) > 0.99999
			and part.CFrame.UpVector:Dot(expected.UpVector) > 0.99999,
		"Orientation changed"
	)
	assert(part.Size == state[2], "Size changed")
	assert(
		part.CanCollide == state[3] and part.CanTouch == state[4] and part.CanQuery == state[5],
		"Collision flags changed"
	)
	if affected[part] then
		moved += 1
	end
	checked += 1
	if checked % 1000 == 0 then
		task.wait()
	end
end
for model, state in pivots do
	assert((model:GetPivot().Position - state[1].Position - state[2]).Magnitude < 0.001, "Nested pivot did not follow")
end
for i, lane in lanes do
	assert(math.abs(lane.StartingPad.Position.Z - slots[8 - i]) < 0.001)
	for key, value in attributes[lane] do
		assert(lane:GetAttribute(key) == value, "Gameplay attribute changed")
	end
	assert(lane.StartingPad:GetAttribute("LaneIndex") == i)
end
zone.WorldPivot = zone:GetBoundingBox()
map:SetAttribute("TrainingLaneOrderVersion", 1)
game:GetService("ChangeHistoryService"):SetWaypoint("Training lanes longest to shortest")
return string.format(
	"Reversed seven lanes with labels, pads and overlays; verified %d parts (%d affected), original sizes and collision flags preserved",
	checked,
	moved
)
