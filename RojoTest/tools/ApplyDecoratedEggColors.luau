-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Load one source JSON into _G.EggColorData before running. Edit mode only.
local data = assert(_G.EggColorData)
local target = assert(workspace.DecoratedEggs15:FindFirstChild(data.name))
local state = assert(_G.EggColorRestore)
local saved = assert(state.saved[data.name])
local asset = game:GetService("AssetService")
local mesh = assert(asset:CreateEditableMesh(), "EditableMesh budget unavailable")
local vertices, colors = {}, {}
for i, v in data.vertices do
	vertices[i] = mesh:AddVertex(Vector3.new(v[1], v[2], v[3]))
end
for i, color in data.colors do
	colors[i] = mesh:AddColor(Color3.new(color[1], color[2], color[3]), 1)
end
for i, tri in data.triangles do
	local face = mesh:AddTriangle(vertices[tri[1]], vertices[tri[2]], vertices[tri[3]])
	mesh:SetFaceColors(face, { colors[tri[4]], colors[tri[4]], colors[tri[4]] })
	if i % 500 == 0 then
		task.wait()
	end
end
mesh:RemoveUnused()
local preview = asset:CreateMeshPartAsync(Content.fromObject(mesh), { CollisionFidelity = Enum.CollisionFidelity.Box })
target:SetAttribute("OriginalMeshId", target:GetAttribute("OriginalMeshId") or target.MeshId)
target:ApplyMesh(preview)
target.Size = saved.size
target.CFrame = saved.cf
target.Color = Color3.new(1, 1, 1)
target.Material = Enum.Material.SmoothPlastic
target:SetAttribute("OriginalMaterialColors", true)
target:SetAttribute("PendingColorMeshUpload", true)
for _, child in target:GetChildren() do
	if child:IsA("SurfaceAppearance") then
		child:Destroy()
	end
end
preview:Destroy()
state.meshes[data.name] = mesh
assert(target.Size == saved.size and target.CFrame == saved.cf, "Placement changed")
assert(
	target.CanCollide == saved.collide and target.CanTouch == saved.touch and target.CanQuery == saved.query,
	"Collision changed"
)
return { name = data.name, materials = #data.colors, faces = #data.triangles }
