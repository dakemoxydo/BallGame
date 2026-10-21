-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Transfer assets/trophy/trophy-geometry.json into _G.TrophyImportData first.
-- Local Edit preview only. Persistent Roblox mesh uploads require approval.
local data = assert(_G.TrophyImportData)
assert(not workspace:FindFirstChild("ImportedTrophy"), "Trophy already exists")
local asset = game:GetService("AssetService")
local model = Instance.new("Model")
model.Name = "ImportedTrophy"
local meshes = {}
local function srgb(v)
	return v <= 0.0031308 and 12.92 * v or 1.055 * v ^ (1 / 2.4) - 0.055
end
for _, group in data.groups do
	local mesh = assert(asset:CreateEditableMesh(), "EditableMesh unavailable")
	table.insert(meshes, mesh)
	local ids = {}
	for i, p in group.vertices do
		ids[i] = mesh:AddVertex(Vector3.new(p[1], p[2], p[3]))
	end
	for i, tri in group.triangles do
		local face = mesh:AddTriangle(ids[tri[1]], ids[tri[2]], ids[tri[3]])
		local normalIds = {}
		for _, n in group.normals[i] do
			table.insert(normalIds, mesh:AddNormal(Vector3.new(n[1], n[2], n[3])))
		end
		mesh:SetFaceNormals(face, normalIds)
		if i % 300 == 0 then
			task.wait()
		end
	end
	mesh:RemoveUnused()
	local part = asset:CreateMeshPartAsync(Content.fromObject(mesh), {
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Precise,
	})
	part.Name = group.name:gsub(" ", "")
	part.Color = Color3.new(srgb(group.color[1]), srgb(group.color[2]), srgb(group.color[3]))
	part.Material = Enum.Material.Metal
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	-- EditableMesh content retains the shared bottom-center geometry origin.
	part.CFrame = CFrame.identity
	part:SetAttribute("SourceMaterial", group.name)
	part:SetAttribute("PendingMeshUpload", true)
	part.Parent = model
	task.wait()
end
model.WorldPivot = CFrame.identity
model:SetAttribute("SourceFile", data.source)
model:SetAttribute("SourceObjects", data.objects)
model:SetAttribute("PendingMeshUpload", true)
model:PivotTo(CFrame.new(25, 20.26, 220))
model.Parent = workspace
local cf, size = model:GetBoundingBox()
assert(math.abs(cf.Position.Y - size.Y / 2 - 20.26) < 0.01, "Incorrect base height")
assert(math.abs(size.Y - 8) < 0.01, "Incorrect trophy height")
game:GetService("Selection"):Set({ model })
_G.ImportedTrophyEditableMeshes = meshes
game:GetService("ChangeHistoryService"):SetWaypoint("Imported Blender trophy")
return {
	path = model:GetFullName(),
	pendingMeshUpload = true,
	size = tostring(size),
	pivot = tostring(model:GetPivot()),
}
