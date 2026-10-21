-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Run once in Edit through Studio MCP. The source mesh must already be imported.
-- EditableMesh references remain previews until the FBX is uploaded as a Mesh asset.
local asset = game:GetService("AssetService")
local storage = game.ServerStorage
local backups = storage:FindFirstChild("WorldBackups") or Instance.new("Folder")
backups.Name = "WorldBackups"
backups.Parent = storage
assert(not backups:FindFirstChild("BeforeOakTreeReplacement"), "Replacement already applied")
local backup = Instance.new("Folder")
backup.Name = "BeforeOakTreeReplacement"
backup.Parent = backups
local source = workspace.ImportPreviews.Oak_ImportPreview
local original = source.OakGeometry
local mesh = assert(_G.NormalizedOakMesh, "Missing normalized copy of oak geometry")
local geometry = asset:CreateMeshPartAsync(Content.fromObject(mesh), {
	CollisionFidelity = Enum.CollisionFidelity.Box,
	RenderFidelity = Enum.RenderFidelity.Precise,
})
geometry.Name = "OakGeometry"
geometry.Anchored = true
geometry.CanCollide = false
geometry.CanTouch = false
geometry.CanQuery = false
geometry.Color = original.Color
geometry.Material = original.Material
geometry.CFrame = CFrame.new(0, geometry.Size.Y / 2, 0)
local template = Instance.new("Model")
template.Name = "Oak"
geometry.Parent = template
template.WorldPivot = CFrame.identity
template:SetAttribute("SourceFile", "дуб.blend")
template:SetAttribute("PendingMeshUpload", original.MeshContent.SourceType == Enum.ContentSourceType.Object)
local assets = storage:FindFirstChild("Assets") or Instance.new("Folder")
assets.Name = "Assets"
assets.Parent = storage
local environment = assets:FindFirstChild("Environment") or Instance.new("Folder")
environment.Name = "Environment"
environment.Parent = assets
assert(not environment:FindFirstChild("Oak"), "Oak template already exists")
template.Parent = environment

local manifest = {}
local index = 0
for _, map in { workspace.ProgressionMap, workspace.World2Map } do
	local roots = {}
	for _, part in map:GetDescendants() do
		if not part:IsA("BasePart") or part.Transparency >= 0.99 then
			continue
		end
		if part.Name == "Trunk" then
			table.insert(roots, part)
		elseif part.Name == "BiomeDecorStem" then
			for _, other in part.Parent:GetChildren() do
				if
					other:IsA("BasePart")
					and other.Transparency < 0.99
					and (other.Name == "CandyCrown" or other.Name == "PalmFrond")
					and math.abs(other.Position.X - part.Position.X) < 9
					and math.abs(other.Position.Z - part.Position.Z) < 9
				then
					table.insert(roots, part)
					break
				end
			end
		end
	end
	local replacementFolder = Instance.new("Folder")
	replacementFolder.Name = "ImportedOakTrees"
	replacementFolder.Parent = map
	for _, root in roots do
		index += 1
		local parent = root.Parent
		local base = root.Position - Vector3.new(0, root.Size.Y / 2, 0)
		local pieces = { root }
		local oldModel = parent:IsA("Model") and parent.Name == "BlockTree" and parent or nil
		if oldModel then
			pieces = {}
			for _, part in oldModel:GetDescendants() do
				if part:IsA("BasePart") then
					table.insert(pieces, part)
				end
			end
		else
			for _, other in parent:GetChildren() do
				if other:IsA("BasePart") and other ~= root and other.Transparency < 0.99 then
					local crown = other.Name == "Crown"
						or other.Name == "CrownTop"
						or other.Name == "CandyCrown"
						or other.Name == "PalmLeaf"
						or other.Name == "PalmFrond"
					if
						crown
						and math.abs(other.Position.X - root.Position.X) < 12
						and math.abs(other.Position.Z - root.Position.Z) < 12
					then
						table.insert(pieces, other)
					end
				end
			end
		end
		local highest = base.Y
		for _, piece in pieces do
			highest = math.max(highest, piece.Position.Y + piece.Size.Y / 2)
		end
		local height = math.clamp(highest - base.Y, 18, 26)
		local oak = template:Clone()
		oak.Name = string.format("Oak_%02d", index)
		oak:ScaleTo(height / 24)
		local pose = CFrame.new(base + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, index * 0.618, 0)
		oak:PivotTo(pose)
		if root.CanCollide then
			local collision = root:Clone()
			collision:ClearAllChildren()
			collision.Name = "TrunkCollision"
			collision.Transparency = 1
			collision.Anchored = true
			collision.Parent = oak
		end
		oak.Parent = replacementFolder
		local snapshot = Instance.new("Model")
		snapshot.Name = oak.Name .. "_Original"
		snapshot:SetAttribute("OriginalParentPath", parent:GetFullName())
		local parentLink = Instance.new("ObjectValue")
		parentLink.Name = "OriginalParent"
		parentLink.Value = parent
		parentLink.Parent = snapshot
		snapshot.Parent = backup
		if oldModel then
			oldModel.Parent = snapshot
		else
			for _, piece in pieces do
				piece.Parent = snapshot
			end
		end
		table.insert(manifest, {
			name = oak.Name,
			map = map.Name,
			base = { base.X, base.Y + 0.03, base.Z },
			height = height,
			collision = root.CanCollide,
		})
		if index % 12 == 0 then
			task.wait()
		end
	end
	map:SetAttribute("OakTreeReplacementVersion", 1)
end

-- Normalize the reference display too, using the lobby's existing ground height.
local referenceBase = source:GetPivot().Position
local floorY = workspace.ProgressionMap.Lobby.ThrowingApron.Position.Y
	- workspace.ProgressionMap.Lobby.ThrowingApron.Size.Y / 2
local referenceCopy = template:Clone()
referenceCopy.Name = "Oak_ImportPreview"
referenceCopy:PivotTo(CFrame.new(referenceBase.X, floorY + 0.03, referenceBase.Z))
referenceCopy.Parent = source.Parent
source.Name = "OriginalOakPreview"
source.Parent = backup
game:GetService("Selection"):Set({ workspace.ProgressionMap.ImportedOakTrees })
return {
	replaced = index,
	backup = backup:GetFullName(),
	template = template:GetFullName(),
	manifest = manifest,
	pendingMeshUpload = template:GetAttribute("PendingMeshUpload"),
}
