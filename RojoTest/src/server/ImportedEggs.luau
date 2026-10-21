--!strict
local Eggs = {}
local meshIds = require(script.Parent.ImportedEggMeshIds)

function Eggs.apply(map)
	local templates = game.ServerStorage:WaitForChild("ImportedEggVisuals")
	for _, part in templates:GetDescendants() do
		if part:IsA("MeshPart") and part.MeshId == "" then
			local size = part.Size
			local mesh = game:GetService("AssetService"):CreateMeshPartAsync(
				Content.fromUri(assert(meshIds[part.Name], "Missing egg mesh ID: " .. part.Name))
			)
			part:ApplyMesh(mesh)
			part.Size = size
			mesh:Destroy()
		end
	end
	for _, id in { "Common", "Uncommon", "Rare", "Rainbow" } do
		local stand = assert(map.SkippingWorld:FindFirstChild("Egg_" .. id))
		if stand:FindFirstChild("ImportedVisual") then
			continue
		end
		local shell = assert(stand:FindFirstChild("EggShell"))
		local ring = assert(stand:FindFirstChild("EggRing"))
		local visual = assert(templates:FindFirstChild(id)):Clone()
		visual.Name = "ImportedVisual"
		visual.WorldPivot = CFrame.identity
		local _, size = visual:GetBoundingBox()
		visual:ScaleTo(visual:GetScale() * shell.Size.Y * 1.5625 / size.Y)
		local bounds, scaledSize = visual:GetBoundingBox()
		local bottom = bounds.Position.Y - scaledSize.Y / 2
		local targetBottom = ring.Position.Y + ring.Size.Y / 2 + 0.3
		visual:PivotTo(CFrame.new(shell.Position.X, targetBottom - bottom, shell.Position.Z))
		for _, part in stand:GetChildren() do
			if part:IsA("BasePart") and (part.Name == "EggShell" or part.Name == "EggSpot") then
				part.Transparency = 1
				part.CastShadow = false
			end
		end
		visual.Parent = stand
		local labelAnchor = assert(stand:FindFirstChild("LabelAnchor"))
		local labelY = targetBottom + scaledSize.Y + 5.5
		labelAnchor.CFrame = labelAnchor.CFrame + Vector3.new(0, labelY - labelAnchor.Position.Y, 0)
	end
end

return Eggs
