-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Local preview placement only; no Roblox asset upload.
local trophy = assert(workspace:FindFirstChild("ImportedTrophy"))
if trophy:GetAttribute("GrassPlacementVersion") == 1 then
	return "Already placed"
end
local _, oldSize = trophy:GetBoundingBox()
assert(math.abs(oldSize.Y - 8) < 0.01, "Unexpected starting size")
local backups = assert(game.ServerStorage:FindFirstChild("WorldBackups"))
assert(not backups:FindFirstChild("BeforeTrophyPlacement_20261020"), "Inspect existing backup")
local backup = trophy:Clone()
backup.Name = "BeforeTrophyPlacement_20261020"
backup.Parent = backups
game:GetService("ChangeHistoryService"):SetWaypoint("Before trophy grass placement")
trophy:ScaleTo(trophy:GetScale() * 5)
-- The front faces the training pitches; the origin remains at the pedestal base.
trophy:PivotTo(CFrame.new(139, 20, 194.60003662109375) * CFrame.Angles(0, -math.pi / 2, 0))
local cf, size = trophy:GetBoundingBox()
assert(math.abs(size.Y - 40) < 0.01, "Incorrect height")
assert(math.abs(cf.Y - size.Y / 2 - 20) < 0.01, "Incorrect ground height")
-- GetBoundingBox sizes follow the model pivot's local axes.
assert(math.abs(size.X - oldSize.X * 5) < 0.01 and math.abs(size.Z - oldSize.Z * 5) < 0.01, "Incorrect scale")
for _, part in trophy:GetDescendants() do
	if part:IsA("BasePart") then
		assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
	end
end
trophy:SetAttribute("GrassPlacementVersion", 1)
game:GetService("Selection"):Set({ trophy })
game:GetService("ChangeHistoryService"):SetWaypoint("Trophy enlarged five times behind training lanes")
return {
	path = trophy:GetFullName(),
	height = size.Y,
	size = tostring(size),
	baseHeight = cf.Y - size.Y / 2,
	pendingUpload = trophy:GetAttribute("PendingMeshUpload"),
}
