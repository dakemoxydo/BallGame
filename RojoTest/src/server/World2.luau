--!strict
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local World2 = {}
local C = Color3.fromRGB
function World2.build(original)
	local existing = workspace:FindFirstChild("World2Map")
	if existing then
		assert(existing:GetAttribute("GameplayWorld2Version") == 1, "Review existing World2Map before replacing it")
		if existing:GetAttribute("ArenaOffsetX") ~= Config.WorldOffset.X then
			local oldRiverX = existing.SkippingWorld.Water_1.Position.X
			existing:PivotTo(original:GetPivot() + Config.WorldOffset)
			workspace.Terrain:FillBlock(CFrame.new(oldRiverX, -8, -720), Vector3.new(112, 16, 1440), Enum.Material.Air)
			workspace.Terrain:FillBlock(
				CFrame.new(Config.RiverX + Config.WorldOffset.X, -8, -720),
				Vector3.new(112, 16, 1440),
				Enum.Material.Water
			)
			existing:SetAttribute("ArenaOffsetX", Config.WorldOffset.X)
		end
		return existing
	end
	local world = original:Clone()
	world.Name = "World2Map"
	world:PivotTo(original:GetPivot() + Config.WorldOffset)
	world.Lobby.MapSpawn.Enabled = false
	-- Give the advanced arena its own sky-garden palette while retaining its layout.
	for _, p in world:GetDescendants() do
		if p:IsA("BasePart") then
			if
				p.Name == "GroundTile"
				or p.Name == "Crown"
				or p.Name == "CrownTop"
				or p.Name == "Shrub"
				or p.Name == "LeafBlock"
			then
				p.Color = p.Color:Lerp(C(168, 126, 246), 0.7)
				for _, t in p:GetChildren() do
					if t:IsA("Texture") then
						t.Color3 = p.Color
					end
				end
			end
		elseif p:IsA("Frame") and p.Parent:IsA("SurfaceGui") and p.Parent.Name == "ReferenceCheckerWall" then
			if p.BackgroundColor3.G > 0.6 then
				p.BackgroundColor3 = p.BackgroundColor3:Lerp(C(177, 127, 247), 0.85)
			end
		end
	end
	for i = 1, 8 do
		local water = world.SkippingWorld["Water_" .. i]
		water.Color = water.Color:Lerp(C(142, 119, 252), 0.3)
		water.WaterCaustics.Color3 = water.Color:Lerp(C(255, 255, 255), 0.5)
	end
	for _, egg in Config.Eggs do
		local model = world.SkippingWorld["Egg_" .. egg.id]
		for _, l in model:GetDescendants() do
			if l:IsA("TextLabel") then
				l.Text = egg.name .. "\n" .. Config.format(egg.cost * 10) .. " Wins • ×3 Pets"
			end
		end
	end
	for _, l in world.SkippingWorld.World2Portal:GetDescendants() do
		if l:IsA("TextLabel") then
			l.Text = "WORLD 1\nRETURN"
		end
	end
	local prompt = world.SkippingWorld.World2Portal.PortalField:FindFirstChildWhichIsA("ProximityPrompt", true)
	prompt.ObjectText = "Return to World 1"
	world:SetAttribute("GameplayWorld2Version", 1)
	world:SetAttribute("ArenaOffsetX", Config.WorldOffset.X)
	world.Parent = workspace
	workspace.Terrain:FillBlock(
		CFrame.new(Config.RiverX + Config.WorldOffset.X, -8, -720),
		Vector3.new(112, 16, 1440),
		Enum.Material.Water
	)
	return world
end
return World2
