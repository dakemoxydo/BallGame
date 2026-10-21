-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local template = game.ServerStorage.Assets.Environment.Oak
local backup = game.ServerStorage.WorldBackups.BeforeOakTreeReplacement
local added = {}
local index = 38
for _, map in { workspace.ProgressionMap, workspace.World2Map } do
	assert(not map:GetAttribute("OakPalmLeftoversVersion"), "Palm pass already applied")
	local roots = {}
	local all = map:GetDescendants()
	for _, root in all do
		if root:IsA("BasePart") and root.Name == "Trunk" and root.Transparency >= 0.99 then
			local visible = false
			for _, p in root.Parent:GetChildren() do
				if
					p:IsA("BasePart")
					and p.Name == "PalmLeaf"
					and p.Transparency < 0.99
					and math.abs(p.Position.X - root.Position.X) < 12
					and math.abs(p.Position.Z - root.Position.Z) < 12
				then
					visible = true
					break
				end
			end
			if visible then
				table.insert(roots, root)
			end
		end
	end
	for _, root in roots do
		index += 1
		local parent = root.Parent
		local pieces = { root }
		for _, p in parent:GetChildren() do
			if
				p:IsA("BasePart")
				and p.Name == "PalmLeaf"
				and math.abs(p.Position.X - root.Position.X) < 12
				and math.abs(p.Position.Z - root.Position.Z) < 12
			then
				table.insert(pieces, p)
			end
		end
		local base = root.Position - Vector3.new(0, root.Size.Y / 2, 0)
		local oak = template:Clone()
		oak.Name = string.format("Oak_%02d", index)
		oak:ScaleTo(19 / 24)
		oak:PivotTo(CFrame.new(base + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, index * 0.618, 0))
		if root.CanCollide then
			local collision = root:Clone()
			collision:ClearAllChildren()
			collision.Name = "TrunkCollision"
			collision.Transparency = 1
			collision.Parent = oak
		end
		oak.Parent = map.ImportedOakTrees
		local snapshot = Instance.new("Model")
		snapshot.Name = oak.Name .. "_Original"
		snapshot:SetAttribute("OriginalParentPath", parent:GetFullName())
		local link = Instance.new("ObjectValue")
		link.Name = "OriginalParent"
		link.Value = parent
		link.Parent = snapshot
		snapshot.Parent = backup
		for _, p in pieces do
			p.Parent = snapshot
		end
		table.insert(added, {
			name = oak.Name,
			map = map.Name,
			base = { base.X, base.Y + 0.03, base.Z },
			height = 19,
			collision = root.CanCollide,
		})
	end
	map:SetAttribute("OakPalmLeftoversVersion", 1)
end
return { added = #added, total = index, manifest = added }
