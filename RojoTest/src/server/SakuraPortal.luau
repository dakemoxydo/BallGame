--!strict
local Sakura = {}
local function clearMarkedTrees(map)
	local gardens = map.EnvironmentPolish:FindFirstChild("LobbyGardens")
	if not gardens then
		return
	end
	local positions = {
		Vector3.new(-49, 0, 136),
		Vector3.new(-19, 0, 72),
		Vector3.new(-54, 0, 27),
	}
	local backups = game.ServerStorage:FindFirstChild("WorldBackups")
	if not backups then
		backups = Instance.new("Folder")
		backups.Name = "WorldBackups"
		backups.Parent = game.ServerStorage
	end
	local removed = backups:FindFirstChild("RemovedLobbyTreesForSakura")
	if not removed then
		removed = Instance.new("Folder")
		removed.Name = "RemovedLobbyTreesForSakura"
		removed.Parent = backups
	end
	local candidates = gardens:GetChildren()
	local native = map:FindFirstChild("NativeEnvironment")
	if native and native:FindFirstChild("Trees") then
		for _, tree in ipairs(native.Trees:GetChildren()) do
			table.insert(candidates, tree)
		end
	end
	for _, tree in ipairs(candidates) do
		if tree:IsA("Model") and (tree.Name == "BlockTree" or tree.Name == "RobloxOak") then
			local center = tree:GetBoundingBox().Position
			local delta = center - map.Lobby.ThrowingApron.Position
			for _, pos in ipairs(positions) do
				if (Vector2.new(delta.X, delta.Z) - Vector2.new(pos.X, pos.Z)).Magnitude < 2 then
					tree.Parent = removed
					break
				end
			end
		end
	end
end
function Sakura.apply(map)
	clearMarkedTrees(map)
	local portal = map.SkippingWorld.World2Portal
	if portal:FindFirstChild("SakuraVisual") then
		return
	end
	local templates = game.ServerStorage:FindFirstChild("ImportedPortalVisuals")
	local template = templates and templates:FindFirstChild("RoseBlossom")
	assert(template, "Imported sakura portal template missing")
	local field = portal.PortalField
	local floorY = math.huge
	for _, p in ipairs(portal:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "PortalPillar" then
			floorY = math.min(floorY, p.Position.Y - p.Size.Y / 2)
		end
	end
	assert(floorY < math.huge, "Portal floor missing")
	local visual = template:Clone()
	visual.Name = "SakuraVisual"
	visual.WorldPivot = CFrame.identity
	local _, size = visual:GetBoundingBox()
	visual:ScaleTo(30 / size.X)
	visual:PivotTo(CFrame.new(field.Position.X, floorY, field.Position.Z) * field.CFrame.Rotation)
	for _, p in ipairs(visual:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
	end
	for _, p in ipairs(portal:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "LabelAnchor" then
			p.Transparency = 1
			if p:GetAttribute("AnimatedPortal") then
				p:SetAttribute("AnimatedPortal", false)
			end
		end
	end
	visual.Parent = portal
	local bounds, bsize = visual:GetBoundingBox()
	local label = portal:FindFirstChild("LabelAnchor")
	if label then
		label.Position = Vector3.new(field.Position.X, bounds.Position.Y + bsize.Y / 2 + 4, field.Position.Z)
	end
	portal:SetAttribute("SakuraPortalVersion", 1)
end
return Sakura
