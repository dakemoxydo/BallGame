--!strict
local Style = {}
local C, V = Color3.fromRGB, Vector3.new
local navy = C(25, 43, 98)
local blue = C(38, 91, 186)
local cyan = C(67, 220, 255)
local gold = C(255, 196, 56)

function Style.apply(map)
	local stand = assert(map:FindFirstChild("EmptyItemStand"))
	if stand:FindFirstChild("BallShopDecor") then
		return
	end
	local lower = assert(stand:FindFirstChild("LowerTier"))
	local upper = assert(stand:FindFirstChild("UpperTier"))
	local decor = Instance.new("Model")
	decor.Name = "BallShopDecor"
	local function part(name, size, position, color, material)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position = name, size, position
		p.Color, p.Material = color, material or Enum.Material.Plastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = decor
		return p
	end
	local function sign(p, text, color, face)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "ShopSign"
		gui.Face = face or Enum.NormalId.Right
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud, gui.LightInfluence = 32, 0
		gui.Parent = p
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(0.94, 0.86)
		label.Position = UDim2.fromScale(0.03, 0.07)
		label.BackgroundTransparency = 1
		label.Font, label.TextScaled = Enum.Font.GothamBlack, true
		label.Text, label.TextColor3 = text, color
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Color, stroke.Thickness = navy, 2
		stroke.Parent = label
	end
	for _, p in { lower, upper } do
		p.Color, p.Material = blue, Enum.Material.Plastic
		for _, t in p:GetChildren() do
			if t:IsA("Texture") then
				t.Color3 = blue
			end
		end
		local front = p.Position.X + p.Size.X / 2
		part(
			p.Name .. "Fascia",
			V(0.25, p.Size.Y - 0.6, p.Size.Z - 0.6),
			V(front + 0.13, p.Position.Y, p.Position.Z),
			navy
		)
		part(
			p.Name .. "LightLine",
			V(0.32, 0.22, p.Size.Z - 1),
			V(front + 0.15, p.Position.Y + p.Size.Y / 2 - 0.25, p.Position.Z),
			cyan,
			Enum.Material.Neon
		)
		for _, side in { -1, 1 } do
			part(
				p.Name .. "EndCap",
				V(p.Size.X, 0.6, 0.45),
				p.Position + V(0, p.Size.Y / 2 - 0.4, side * (p.Size.Z / 2 + 0.15)),
				gold
			)
		end
	end
	local colors = {}
	for _, item in require(game:GetService("ReplicatedStorage").Shared.GameConfig).Stones do
		colors[item.displaySlot] = item.color
	end
	for slot = 1, 10 do
		local top = assert(stand:FindFirstChild("DisplayTop" .. slot))
		local pedestal = assert(stand:FindFirstChild("EmptyPedestal" .. slot))
		pedestal.Color, top.Color = navy, C(55, 76, 128)
		pedestal.Material, top.Material = Enum.Material.Plastic, Enum.Material.Plastic
		for _, p in { top, pedestal } do
			for _, t in p:GetChildren() do
				if t:IsA("Texture") then
					t.Color3 = p.Color
				end
			end
		end
		local y = top.Position.Y + top.Size.Y / 2 + 0.035
		local accent = colors[slot]
		for _, side in { -1, 1 } do
			part(
				"TileRim" .. slot,
				V(0.23, 0.12, top.Size.Z + 0.2),
				V(top.Position.X + side * top.Size.X / 2, y, top.Position.Z),
				accent,
				Enum.Material.Neon
			)
			part(
				"TileRim" .. slot,
				V(top.Size.X, 0.12, 0.23),
				V(top.Position.X, y, top.Position.Z + side * top.Size.Z / 2),
				accent,
				Enum.Material.Neon
			)
		end
		-- Broad corner blocks give the displays a toy-like, chunky silhouette.
		for _, side in { -1, 1 } do
			part(
				"Corner" .. slot,
				V(0.65, 0.32, 0.65),
				V(top.Position.X + top.Size.X / 2 - 0.1, y + 0.1, top.Position.Z + side * (top.Size.Z / 2 - 0.1)),
				gold
			)
		end
	end
	local backX = upper.Position.X - upper.Size.X / 2 + 0.7
	local z = upper.Position.Z
	local headerY = upper.Position.Y + upper.Size.Y / 2 + 22
	for _, side in { -1, 1 } do
		local postZ = z + side * (upper.Size.Z / 2 - 2.2)
		part("SignPost", V(2.2, 22, 2.2), V(backX, headerY - 10, postZ), navy)
		part("PostAccent", V(0.3, 18, 1.1), V(backX + 1.2, headerY - 10, postZ), cyan, Enum.Material.Neon)
		local jewel = part("GoldFinial", V(3.1, 3.1, 3.1), V(backX, headerY + 2, postZ), gold)
		jewel.CFrame *= CFrame.Angles(math.rad(45), 0, math.rad(45))
	end
	part("HeaderBorder", V(1.1, 8.4, 73), V(backX, headerY, z), gold)
	local header = part("Header", V(1.3, 7.3, 71.6), V(backX + 0.1, headerY, z), navy)
	sign(header, "BALL UPGRADES", C(255, 236, 145))
	local frontX = lower.Position.X + lower.Size.X / 2 + 0.35
	local badge = part("FrontBadge", V(0.7, 2.5, 30), V(frontX, lower.Position.Y, z), blue)
	sign(badge, "CHOOSE YOUR POWER", C(235, 250, 255))
	decor.WorldPivot = CFrame.new(lower.Position)
	decor.Parent = stand
	return decor
end

return Style
