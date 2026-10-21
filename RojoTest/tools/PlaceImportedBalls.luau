-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local map = assert(workspace:FindFirstChild("ProgressionMap"), "Missing map")
local stand = assert(map:FindFirstChild("EmptyItemStand"), "Missing stand")
local balls = assert(workspace:FindFirstChild("AllBalls_NoTextures"), "Missing imported balls")
if balls:GetAttribute("StandPlacementVersion") == 1 then
	return "Already placed"
end
local order = {
	"Ball_01_RubberRookie.001",
	"Ball_02_SteelImpact.001",
	"Ball_03_CrystalIce.001",
	"Ball_04_VolcanoHeart.001",
	"Ball_05_MechanicalReactor.001",
	"Ball_06_PlasmaSatellite.001",
	"Ball_07_ThunderSplit.001",
	"Ball_08_DragonSun.001",
	"Ball_09_BlackHole.001",
	"Ball_10_WorldCreator.001",
}
local jobs = {}
for i, name in order do
	local model = assert(balls:FindFirstChild(name), name)
	local slot = if i <= 5 then 6 - i else 16 - i
	local top = assert(stand:FindFirstChild("DisplayTop" .. slot), "Missing display top")
	assert(model:IsA("Model") and not model.PrimaryPart, "Expected model without PrimaryPart")
	table.insert(jobs, { model = model, top = top, slot = slot })
end
local storage = game:GetService("ServerStorage")
local backups = storage:FindFirstChild("WorldBackups")
if not backups then
	backups = Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = storage
end
assert(not backups:FindFirstChild("BeforeBallStandPlacement"), "Backup exists; inspect before retry")
local backup = Instance.new("Folder")
backup.Name = "BeforeBallStandPlacement"
balls:Clone().Parent = backup
stand:Clone().Parent = backup
local rocks = Instance.new("Folder")
rocks.Name = "DisplayStones"
rocks.Parent = backup
local root = map:FindFirstChild("SkippingWorld")
if root then
	for _, p in root:GetChildren() do
		if p:IsA("BasePart") and p.Name:match("^DisplayStone_") then
			p:Clone().Parent = rocks
		end
	end
end
backup.Parent = backups
local results = {}
for _, job in jobs do
	local model, top = job.model, job.top
	local bounds = model:GetBoundingBox()
	model.WorldPivot = bounds
	model:ScaleTo(model:GetScale() * 2.5)
	local pivot = model:GetPivot()
	model:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, -math.pi / 2, 0) * pivot.Rotation)
	local cf, size = model:GetBoundingBox()
	local destination =
		Vector3.new(top.Position.X, top.Position.Y + top.Size.Y / 2 + size.Y / 2 + 0.025, top.Position.Z)
	model:PivotTo(model:GetPivot() + (destination - cf.Position))
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
	end
	model:SetAttribute("DisplaySlot", job.slot)
	local final, finalSize = model:GetBoundingBox()
	assert((model:GetPivot().Position - final.Position).Magnitude < 0.02, "Pivot off center")
	assert(
		math.abs(final.Position.Y - finalSize.Y / 2 - (top.Position.Y + top.Size.Y / 2) - 0.025) < 0.02,
		"Contact failed"
	)
	assert(finalSize.X < top.Size.X and finalSize.Z < top.Size.Z, "Ball exceeds tile")
	table.insert(
		results,
		{ ball = model.Name, slot = job.slot, center = tostring(final.Position), size = tostring(finalSize) }
	)
end
if root then
	for _, p in root:GetChildren() do
		if p:IsA("BasePart") and p.Name:match("^DisplayStone_") then
			p:SetAttribute("BeforeBallDisplayTransparency", p.Transparency)
			p.Transparency = 1
		end
	end
end
local overall = balls:GetBoundingBox()
balls.WorldPivot = overall
balls:SetAttribute("StandPlacementVersion", 1)
return results
