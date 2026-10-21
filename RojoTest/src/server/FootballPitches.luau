--!strict
local Pitches = {}
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local WHITE = Color3.fromRGB(245, 248, 235)

function Pitches.apply(map)
	local world = assert(map:FindFirstChild("SkippingWorld"))
	local old = world:FindFirstChild("FootballPitchMarkings")
	if old then
		old:Destroy()
	end
	local container = Instance.new("Folder")
	container.Name = "FootballPitchMarkings"
	container.Parent = world
	for i = 1, 8 do
		local surface = assert(world:FindFirstChild("Water_" .. i))
		-- Keep the authored plane and all route/gameplay coordinates unchanged.
		local originalColor = surface:GetAttribute("OriginalPitchColor")
		if not originalColor then
			originalColor = surface:GetAttribute("FootballPitch") and Config.Biomes[i].color or surface.Color
			if surface:GetAttribute("FootballPitch") and map.Name == "World2Map" then
				originalColor = originalColor:Lerp(Color3.fromRGB(142, 119, 252), 0.3)
			end
			surface:SetAttribute("OriginalPitchColor", originalColor)
		end
		surface.Color = originalColor
		surface.Material = Enum.Material.Grass
		surface.Transparency = 0
		surface.Reflectance = 0
		surface.CanCollide = true
		surface:SetAttribute("FootballPitch", true)
		for _, texture in surface:GetChildren() do
			if texture:IsA("Texture") or texture:IsA("Decal") then
				texture.Transparency = 1
			end
		end
		local field = Instance.new("Model")
		field.Name = "Pitch" .. i
		local width, length = surface.Size.X, surface.Size.Z
		local top = surface.Size.Y / 2
		local function part(name, x, z, sx, sz, color, height)
			local p = Instance.new("Part")
			p.Name = name
			p.Size = Vector3.new(sx, 0.025, sz)
			p.CFrame = surface.CFrame * CFrame.new(x, top + (height or 0.03), z)
			p.Anchored = true
			p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
			p.CastShadow = false
			p.Color = color
			p.Material = color == WHITE and Enum.Material.SmoothPlastic or Enum.Material.Grass
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Parent = field
			return p
		end
		local stripeCount = math.max(8, math.round(length / 18))
		local stripeLength = length / stripeCount
		for stripe = 0, stripeCount - 1 do
			if stripe % 2 == 0 then
				part(
					"MownGrassStripe",
					0,
					-length / 2 + (stripe + 0.5) * stripeLength,
					width,
					stripeLength,
					originalColor:Lerp(Color3.new(0, 0, 0), 0.1),
					0.005
				)
			end
		end
		local halfWidth, halfLength = width / 2 - 2, length / 2 - 2
		local lineWidth = 0.45
		for _, x in { -halfWidth, halfWidth } do
			part("Touchline", x, 0, lineWidth, halfLength * 2, WHITE)
		end
		for _, z in { -halfLength, 0, halfLength } do
			part(z == 0 and "HalfwayLine" or "GoalLine", 0, z, halfWidth * 2, lineWidth, WHITE)
		end
		local radius, segments = 14, 48
		for segment = 0, segments - 1 do
			local a, b = segment * 2 * math.pi / segments, (segment + 1) * 2 * math.pi / segments
			local p1 = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
			local p2 = Vector3.new(math.cos(b) * radius, 0, math.sin(b) * radius)
			local mid = (p1 + p2) / 2
			local p = part("CentreCircle", mid.X, mid.Z, lineWidth, (p2 - p1).Magnitude + 0.025, WHITE)
			p.CFrame = surface.CFrame
				* CFrame.lookAt(Vector3.new(mid.X, top + 0.03, mid.Z), Vector3.new(p2.X, top + 0.03, p2.Z))
		end
		part("CentreSpot", 0, 0, 0.9, 0.9, WHITE)
		for _, direction in { -1, 1 } do
			for _, box in { { Width = 58, Depth = 30 }, { Width = 28, Depth = 12 } } do
				local edge = direction * halfLength
				local inner = edge - direction * box.Depth
				part("PenaltyArea", 0, inner, box.Width, lineWidth, WHITE)
				for _, x in { -box.Width / 2, box.Width / 2 } do
					part("PenaltyAreaSide", x, (edge + inner) / 2, lineWidth, box.Depth, WHITE)
				end
			end
			part("PenaltySpot", 0, direction * (halfLength - 22), 0.8, 0.8, WHITE)
		end
		field.WorldPivot = surface.CFrame
		field.Parent = container
		task.wait()
	end
	map:SetAttribute("FootballPitchVersion", 1)
end
return Pitches
