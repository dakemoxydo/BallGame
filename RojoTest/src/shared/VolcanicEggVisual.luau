--!strict
local Visual = {}
local AssetService = game:GetService("AssetService")

-- Content.fromObject consumes the mesh it is built from, so a shared
-- EditableMesh would leave the second world without the custom egg. Every
-- world builds its own mesh from the shared source data instead.
local function buildMesh()
	local data = require(script.Parent.VolcanicEggData)
	local editable = assert(AssetService:CreateEditableMesh(), "Egg mesh memory unavailable")
	local vertices, colors = {}, {}
	for i, v in data.vertices do
		vertices[i] = editable:AddVertex(Vector3.new(v[1], v[2], v[3]))
	end
	for i, c in data.colors do
		colors[i] = editable:AddColor(Color3.new(c[1], c[2], c[3]), 1)
	end
	for i, t in data.triangles do
		local face = editable:AddTriangle(vertices[t[1]], vertices[t[2]], vertices[t[3]])
		editable:SetFaceColors(face, { colors[t[4]], colors[t[4]], colors[t[4]] })
		if i % 500 == 0 then
			task.wait()
		end
	end
	editable:RemoveUnused()
	return editable
end
function Visual.create(map)
	local world = map:FindFirstChild("SkippingWorld")
	local anchor = world and world:FindFirstChild("HackedAdminEgg")
	local stand = world and world:FindFirstChild("HackedEggStand")
	if not world or not anchor or not stand then
		return
	end
	if world:FindFirstChild("VolcanicEggVisual") then
		return
	end
	local part = AssetService:CreateMeshPartAsync(Content.fromObject(buildMesh()), {
		CollisionFidelity = Enum.CollisionFidelity.Box,
	})
	part.Name = "VolcanicEggVisual"
	part.Color = Color3.new(1, 1, 1)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	local data = require(script.Parent.VolcanicEggData)
	local scale = 12.5 / data.size[2]
	part.Size = Vector3.new(data.size[1], data.size[2], data.size[3]) * scale
	local centerY = stand.Position.Y + stand.Size.Y / 2 + 0.3 + part.Size.Y / 2
	part.CFrame = anchor.CFrame + Vector3.new(0, centerY - anchor.Position.Y, 0)
	part:SetAttribute("SourceEgg", "02 Volcanic Inferno")
	part.Parent = world
	local fallback = world:FindFirstChild("VolcanicEggFallback")
	if fallback then
		fallback.LocalTransparencyModifier = 1
	end
	return part
end
function Visual.start()
	-- Render locally so EditableMesh contents need no asset upload or replication.
	local watched, busy, failed = {}, {}, {}
	local function watch(map)
		if watched[map] or (map.Name ~= "ProgressionMap" and map.Name ~= "World2Map") then
			return
		end
		watched[map] = true
		local function attempt()
			if busy[map] or failed[map] then
				return
			end
			busy[map] = true
			task.spawn(function()
				local ok, err = pcall(Visual.create, map)
				busy[map] = nil
				if not ok then
					failed[map] = true
					warn("Volcanic egg visual: " .. tostring(err))
				end
			end)
		end
		map.DescendantAdded:Connect(function(child)
			if child.Name == "SkippingWorld" or child.Name == "HackedAdminEgg" or child.Name == "HackedEggStand" then
				attempt()
			end
		end)
		attempt()
	end
	workspace.ChildAdded:Connect(watch)
	for _, map in workspace:GetChildren() do
		watch(map)
	end
end
return Visual
