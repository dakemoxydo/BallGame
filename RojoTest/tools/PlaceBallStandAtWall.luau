-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Run in Studio Edit through Studio MCP. Only the authored World 1 display moves.
local map = workspace.ProgressionMap
local stand = map.EmptyItemStand
local balls = workspace.AllBalls_NoTextures
assert(map:GetAttribute("LobbyLayoutVersion") == 1, "Unexpected lobby")
if stand:GetAttribute("WallPlacementVersion") == 1 then
	return "Already applied"
end
assert(math.abs(stand.LowerTier.Size.Z - 88) < 0.01, "Unexpected stand dimensions")
local server = game.ServerScriptService.Server
assert(server.BallStand.Source:find("BallDisplayScale", 1, true), "Wait for Rojo sync")
local scale = 2 / 3
local origin = stand.LowerTier.CFrame * CFrame.new(0, -stand.LowerTier.Size.Y / 2, 0)
local target = CFrame.new(-43, origin.Position.Y, stand.LowerTier.Position.Z)
local labels = {}
for _, ball in balls:GetChildren() do
	assert(ball:IsA("Model") and ball:GetAttribute("DisplaySlot"), "Unexpected ball container")
	local link = assert(ball:FindFirstChild("DisplayLabel"), "Missing label link")
	labels[assert(link.Value)] = true
end
local protected = {}
for i, part in map:GetDescendants() do
	if part:IsA("BasePart") and not part:IsDescendantOf(stand) and not labels[part] then
		protected[part] = { part.CFrame, part.Size, part.CanCollide, part.CanTouch, part.CanQuery }
	end
	if i % 1000 == 0 then
		task.wait()
	end
end
local backups = game.ServerStorage:FindFirstChild("WorldBackups")
if not backups then
	backups = Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = game.ServerStorage
end
local backup = Instance.new("Folder")
backup.Name = "BeforeBallStandWall_20261020"
assert(not backups:FindFirstChild(backup.Name), "Inspect existing backup before retry")
stand:Clone().Parent = backup
balls:Clone().Parent = backup
local labelCopies = Instance.new("Folder")
labelCopies.Name = "LinkedLabels"
labelCopies.Parent = backup
for label in labels do
	label:Clone().Parent = labelCopies
end
backup.Parent = backups
game:GetService("ChangeHistoryService"):SetWaypoint("Before ball stand wall placement")
local function transformed(cf)
	local relative = origin:ToObjectSpace(cf)
	return target * CFrame.new(relative.Position * scale) * relative.Rotation
end
for _, model in { stand, balls } do
	local destination = transformed(model:GetPivot())
	model:ScaleTo(model:GetScale() * scale)
	model:PivotTo(destination)
end
for label in labels do
	label.CFrame = transformed(label.CFrame)
	label.Size *= scale
end
stand:SetAttribute("BallDisplayScale", scale)
-- Reload only this module so the Edit run uses the newly synced source.
local refresh = server.BallStand:Clone()
refresh.Name = "BallStandWallEditRun"
refresh.Parent = server
local ok, result = pcall(function()
	return require(refresh).apply(map)
end)
refresh:Destroy()
assert(ok, result)
local checked = 0
for part, before in protected do
	assert(part.CFrame == before[1] and part.Size == before[2], "Unrelated geometry moved: " .. part:GetFullName())
	assert(
		part.CanCollide == before[3] and part.CanTouch == before[4] and part.CanQuery == before[5],
		"Unrelated collision changed"
	)
	checked += 1
	if checked % 1000 == 0 then
		task.wait()
	end
end
assert(math.abs(stand.LowerTier.Size.Z - 88 * scale) < 0.001)
assert(math.abs(stand.LowerTier.Position.Y - stand.LowerTier.Size.Y / 2 - origin.Position.Y) < 0.001)
assert(stand.LowerTier.CFrame.RightVector:Dot(Vector3.xAxis) > 0.999)
local slots = 0
for _, ball in balls:GetChildren() do
	local top = stand["DisplayTop" .. ball:GetAttribute("DisplaySlot")]
	local cf, size = ball:GetBoundingBox()
	assert((Vector3.new(cf.X, 0, cf.Z) - Vector3.new(top.Position.X, 0, top.Position.Z)).Magnitude < 0.01)
	assert(math.abs(cf.Y - size.Y / 2 - top.Position.Y - top.Size.Y / 2 - 0.9 * scale) < 0.01)
	assert(ball:GetAttribute("DisplayBasePivot") == ball:GetPivot())
	assert(ball.DisplayLabel.Value.Position == ball:GetAttribute("DisplayLabelBase"))
	slots += 1
end
assert(slots == 10, "Expected ten balls")
stand:SetAttribute("WallPlacementVersion", 1)
game:GetService("ChangeHistoryService"):SetWaypoint("Ball stand reduced and placed at wall")
return string.format("Applied: scale %.6f; ten balls and labels aligned; %d unrelated parts unchanged", scale, checked)
