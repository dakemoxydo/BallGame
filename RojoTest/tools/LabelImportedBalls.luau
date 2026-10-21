-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local map = assert(workspace:FindFirstChild("ProgressionMap"))
local root = assert(map:FindFirstChild("SkippingWorld"))
local balls = assert(workspace:FindFirstChild("AllBalls_NoTextures"))
if balls:GetAttribute("StandLabelsVersion") == 1 then
	return "Already labelled"
end
local labels, models = {}, {}
for _, p in root:GetChildren() do
	if
		p:IsA("BasePart")
		and p.Name == "LabelAnchor"
		and p.Position.X < -190
		and p.Position.Z > 45
		and p.Position.Z < 130
	then
		local gui = p:FindFirstChildWhichIsA("BillboardGui")
		if gui then
			local row = if p.Position.X < -205 then 1 else 0
			local column = math.floor((p.Position.Z - 55) / 16 + 0.5) + 1
			labels[row * 5 + column] = p
		end
	end
end
for _, model in balls:GetChildren() do
	local slot = model:GetAttribute("DisplaySlot")
	if slot then
		models[slot] = model
	end
end
for slot = 1, 10 do
	assert(models[slot], "Missing ball slot " .. slot)
end
for slot = 1, 7 do
	assert(labels[slot], "Missing label slot " .. slot)
end
local backups = assert(game.ServerStorage:FindFirstChild("WorldBackups"))
assert(not backups:FindFirstChild("BeforeBallStandLabels"), "Existing backup; inspect before retry")
local backup = Instance.new("Folder")
backup.Name = "BeforeBallStandLabels"
for slot = 1, 7 do
	local copy = labels[slot]:Clone()
	copy.Name = "Slot" .. slot
	copy.Parent = backup
end
backup.Parent = backups
local names = { [8] = "Dragon Stone", [9] = "Thunder Stone", [10] = "Plasma Stone" }
local colors =
	{ [8] = Color3.fromRGB(255, 169, 46), [9] = Color3.fromRGB(255, 218, 63), [10] = Color3.fromRGB(177, 103, 255) }
local modelNames = {
	[5] = "Rubber Rookie",
	[4] = "Steel Impact",
	[3] = "Crystal Ice",
	[2] = "Volcano Heart",
	[1] = "Mechanical Reactor",
	[7] = "Black Hole",
	[6] = "World Creator",
}
local results = {}
for slot = 1, 10 do
	local anchor = labels[slot]
	if not anchor then
		anchor = labels[7]:Clone()
		anchor.Name = "BallLabelAnchor" .. slot
		local text = assert(anchor:FindFirstChildWhichIsA("TextLabel", true))
		text.Text = names[slot]
		text.TextColor3 = colors[slot]
		anchor.Parent = root
	end
	local gui = assert(anchor:FindFirstChildWhichIsA("BillboardGui"))
	local title = assert(gui:FindFirstChildWhichIsA("TextLabel", true))
	if modelNames[slot] then
		local multiplier = title.Text:match("\n(×.*)$")
		title.Text = modelNames[slot] .. (multiplier and "\n" .. multiplier or "")
	end
	gui.Size = UDim2.fromScale(12, 4.5)
	gui.StudsOffset = Vector3.zero
	gui.StudsOffsetWorldSpace = Vector3.zero
	gui.Enabled = true
	local cf, size = models[slot]:GetBoundingBox()
	anchor.Position = Vector3.new(cf.Position.X, cf.Position.Y + size.Y / 2 + 0.65 + 2.25, cf.Position.Z)
	anchor:SetAttribute("BallDisplayLabelSlot", slot)
	table.insert(
		results,
		{ slot = slot, text = gui:FindFirstChildWhichIsA("TextLabel", true).Text, position = tostring(anchor.Position) }
	)
end
balls:SetAttribute("StandLabelsVersion", 1)
return results
