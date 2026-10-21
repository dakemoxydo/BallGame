--!strict
-- Separates coincident render faces without changing the original gameplay volumes.
local MapSurfaceFix = {}
local V = Vector3.new

function MapSurfaceFix.apply(root)
	assert(root and root:GetAttribute("Version") == 9, "Surface repair requires map version 9")
	if root:GetAttribute("SurfaceRepairVersion") == 1 then
		return root
	end
	assert(root:FindFirstChild("EnvironmentPolish"), "Apply MapPolish before surface repairs")
	assert(not root:FindFirstChild("SurfaceRepairs"), "Review incomplete surface repairs first")
	local original = {}
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") then
			original[p] = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
		end
	end
	local storage = game:GetService("ServerStorage")
	local backups = storage:FindFirstChild("WorldBackups") or Instance.new("Folder")
	backups.Name, backups.Parent = "WorldBackups", storage
	local backup = root:Clone()
	backup.Name = "ProgressionMap_BeforeSurfaceRepair_" .. os.date("%Y%m%d_%H%M%S")
	backup.Parent = backups
	local skins = Instance.new("Model")
	skins.Name, skins.Parent = "SurfaceRepairs", root
	local changed = 0
	local function skin(p, size, cf, suffix)
		local render = p:Clone()
		render.Name = p.Name .. (suffix or "_Surface")
		render.Size, render.CFrame = size, cf or p.CFrame
		render.CanCollide, render.CanTouch, render.CanQuery = false, false, false
		render:SetAttribute("SurfaceSource", p:GetFullName())
		render.Parent = skins
		changed += 1
		return render
	end
	local function hide(p)
		p:SetAttribute("SurfaceRepairOriginalTransparency", p.Transparency)
		p.Transparency = 1
		for _, t in p:GetChildren() do
			if t:IsA("Texture") or t:IsA("Decal") then
				t:SetAttribute("SurfaceRepairOriginalTransparency", t.Transparency)
				t.Transparency = 1
			end
		end
	end
	-- All source collision parts keep their exact transforms, sizes and flags.
	for p in original do
		if p.Name == "InnerBankEarth" or p.Name == "OuterBankEarth" then
			skin(p, p.Size - V(0.32, 0, 0.16))
			hide(p)
		elseif p.Name == "WallPanel" or p.Name == "BackWallPanel" then
			local size = if p.Name == "WallPanel" then p.Size - V(0, 0.24, 0.24) else p.Size - V(0.32, 0.32, 0)
			skin(p, size)
			hide(p)
		elseif p.Name == "CrossWalkway" then
			skin(p, p.Size - V(0.32, 0, 0), p.CFrame + V(0, 0.08, 0))
			hide(p)
		elseif p.Name == "ApronTrim" or p.Name == "RiverBed" then
			skin(p, p.Size - V(0, 0, 0.16))
			hide(p)
		elseif p.Name == "LaneEdge" or p.Name == "CliffShoulder" then
			skin(p, p.Size - V(0.16, 0, 0))
			hide(p)
		elseif p.Name == "MesaCap" then
			skin(p, p.Size - V(0, 0.16, 0))
			hide(p)
		elseif p.Name == "EntranceBarrier" then
			-- Keep the full-width blocker, render its forcefield clear of bank/wall end faces.
			skin(p, V(207.8, p.Size.Y, 0.12), CFrame.new(-116, p.Position.Y, 0.12))
			hide(p)
		elseif p.Name == "FrontLeft" then
			-- The removed render volume is already occupied by CorridorLeft.
			skin(p, V(2, p.Size.Y, p.Size.Z - 0.32), CFrame.new(-219, p.Position.Y, p.Position.Z))
			hide(p)
		elseif p.Name == "FrontRight" then
			-- CorridorRight supplies the middle six studs; avoid three coincident wall faces.
			skin(p, V(10, p.Size.Y, p.Size.Z - 0.32), CFrame.new(-17, p.Position.Y, p.Position.Z), "_InnerSurface")
			skin(p, V(14, p.Size.Y, p.Size.Z - 0.32), CFrame.new(1, p.Position.Y, p.Position.Z), "_OuterSurface")
			hide(p)
		end
	end
	for _, lane in root.TrainingZone:GetChildren() do
		if lane:IsA("Model") then
			local first = true
			for _, p in lane:GetChildren() do
				if p:IsA("BasePart") and p.Name == "Arrow" then
					if first then
						skin(p, p.Size - V(0.1, 0, 0.1), p.CFrame + V(0, 0.06, 0))
						hide(p)
						first = false
					end
				end
			end
		end
	end
	skins.WorldPivot = CFrame.new(-116, 0, -528)
	for p, saved in original do
		assert(p.CFrame == saved[1] and p.Size == saved[2], "Source geometry changed: " .. p:GetFullName())
		assert(
			p.CanCollide == saved[3] and p.CanTouch == saved[4] and p.CanQuery == saved[5],
			"Source collision changed: " .. p:GetFullName()
		)
	end
	root:SetAttribute("SurfaceRepairVersion", 1)
	root:SetAttribute("RepairedRenderParts", changed)
	return root
end

return MapSurfaceFix
