-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local V = Vector3.new
local reports = {}
for _, map in { workspace.ProgressionMap, workspace.World2Map } do
	local decor = map.NativeEnvironment
	local frame = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
	assert(not decor:GetAttribute("ShapeRefinementVersion"), "Refinement already applied")
	local rocks, leaves = 0, 0
	for _, m in decor:GetDescendants() do
		if m:IsA("Model") and m.Name == "FacetedRockGarden" then
			local core = m.RockCore
			local scale = core.Size.X / 6.2
			local base = m:GetPivot()
			local rotation = core.CFrame.Rotation
			core.Size = V(5.6, 3.8, 5.1) * scale
			core.CFrame = CFrame.new(base:PointToWorldSpace(V(0, 1.9 * scale, 0))) * rotation
			local crest = Instance.new("WedgePart")
			crest.Name = "RockCrest"
			crest.Size = V(5.8, 1.8, 5.2) * scale
			crest.CFrame = CFrame.new(base:PointToWorldSpace(V(0, 4.05 * scale, 0))) * rotation
			crest.Color = core.Color:Lerp(Color3.fromRGB(230, 237, 235), 0.10)
			crest.Material = Enum.Material.Plastic
			crest.Anchored = true
			crest.CanCollide = false
			crest.CanTouch = false
			crest.CanQuery = false
			crest.Parent = m
			for _, t in core:GetChildren() do
				if t:IsA("Texture") then
					t:Clone().Parent = crest
				end
			end
			if math.abs(frame:PointToObjectSpace(base.Position).Y - 4.24) < 0.1 then
				local factor = ({ 0.86, 0.99, 1.11, 1.24 })[(rocks % 4) + 1]
				m:ScaleTo(m:GetScale() * factor)
			end
			rocks += 1
		elseif m:IsA("Model") and m.Name == "RobloxOak" then
			local base = m:GetPivot()
			local height = 0
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") then
					height = math.max(height, base:PointToObjectSpace(p.Position).Y + p.Size.Y / 2)
				end
			end
			for _, p in m:GetChildren() do
				if p:IsA("Part") and p.Name == "LeafCrown" then
					local pos = base:PointToObjectSpace(p.Position)
					if math.abs(pos.X) > height * 0.17 then
						local wedge = Instance.new("WedgePart")
						wedge.Name = p.Name
						wedge.Size = p.Size
						wedge.Color = p.Color
						wedge.Material = p.Material
						wedge.Anchored = true
						wedge.CanCollide = false
						wedge.CanTouch = false
						wedge.CanQuery = false
						wedge.CFrame = CFrame.new(p.Position)
							* frame.Rotation
							* CFrame.Angles(0, pos.X < 0 and math.pi / 2 or -math.pi / 2, 0)
						for _, t in p:GetChildren() do
							if t:IsA("Texture") then
								t:Clone().Parent = wedge
							end
						end
						wedge.Parent = m
						p:Destroy()
						leaves += 1
					end
				end
			end
		end
	end
	for _, t in decor:GetDescendants() do
		if t:IsA("Texture") and t.Name:find("RefreshStuds_", 1, true) then
			t.Transparency = 0.22
		end
	end
	decor:SetAttribute("ShapeRefinementVersion", 1)
	table.insert(reports, { map = map.Name, rockGardens = rocks, facetedLeafChunks = leaves })
end
return reports
