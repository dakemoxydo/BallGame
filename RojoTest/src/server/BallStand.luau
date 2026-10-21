--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Visuals = require(Shared.BallVisuals)
local Tags = game:GetService("CollectionService")
local Stand = {}

function Stand.apply(map)
	require(script.Parent.BallStandStyle).apply(map)
	local stand = assert(map:FindFirstChild("EmptyItemStand"))
	local displayScale = stand:GetAttribute("BallDisplayScale") or 1
	local root = assert(map:FindFirstChild("SkippingWorld"))
	local imported = map.Name == "ProgressionMap" and workspace:FindFirstChild("AllBalls_NoTextures")
	local container = imported or stand:FindFirstChild("DisplayBalls")
	if not container then
		container = Instance.new("Folder")
		container.Name = "DisplayBalls"
		container.Parent = stand
	end
	local anchors = {}
	for _, anchor in root:GetChildren() do
		if
			anchor:IsA("BasePart")
			and anchor:FindFirstChildWhichIsA("BillboardGui")
			and (anchor.Name == "LabelAnchor" or anchor:GetAttribute("BallDisplayLabelSlot"))
		then
			for slot = 1, 10 do
				local top = stand:FindFirstChild("DisplayTop" .. slot)
				if
					top
					and math.abs(anchor.Position.X - top.Position.X) < 0.1
					and math.abs(anchor.Position.Z - top.Position.Z) < 0.1
				then
					anchors[slot] = anchor
				end
			end
		end
	end
	for _, item in Config.Stones do
		local top = assert(stand:FindFirstChild("DisplayTop" .. item.displaySlot))
		local model
		for _, candidate in container:GetChildren() do
			if
				candidate:GetAttribute("DisplaySlot") == item.displaySlot
				or candidate:GetAttribute("BallId") == item.id
			then
				model = candidate
				break
			end
		end
		if not model then
			model = Visuals.create(item.id, 6 * displayScale)
			model:PivotTo(CFrame.Angles(0, -math.pi / 2, 0))
			model.Parent = container
		end
		-- Recompute placement when the stand moves, including the animation origin.
		do
			local cf, size = model:GetBoundingBox()
			model.WorldPivot = cf
			local center = Vector3.new(
				top.Position.X,
				top.Position.Y + top.Size.Y / 2 + size.Y / 2 + 0.9 * displayScale,
				top.Position.Z
			)
			model:PivotTo(model:GetPivot() + (center - cf.Position))
			model:SetAttribute("DisplayBasePivot", model:GetPivot())
		end
		model:SetAttribute("BallId", item.id)
		model:SetAttribute("DisplaySlot", item.displaySlot)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
			end
		end
		local cf, size = model:GetBoundingBox()
		local anchor = anchors[item.displaySlot]
		if not anchor then
			anchor = Instance.new("Part")
			anchor.Name = "BallLabelAnchor" .. item.displaySlot
			anchor.Size = Vector3.new(0.1, 0.1, 0.1)
			anchor.Transparency = 1
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanTouch = false
			anchor.CanQuery = false
			anchor.Parent = root
			local gui = Instance.new("BillboardGui")
			gui.Name = "BallLabel"
			gui.MaxDistance = 450
			gui.LightInfluence = 0
			gui.Parent = anchor
			local title = Instance.new("TextLabel")
			title.Size = UDim2.fromScale(1, 1)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBlack
			title.TextScaled = true
			title.Parent = gui
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Color = Color3.fromRGB(20, 24, 40)
			stroke.Parent = title
		end
		local gui = anchor:FindFirstChildWhichIsA("BillboardGui")
		anchors[item.displaySlot] = anchor
		gui.Size = UDim2.fromScale(12 * displayScale, 5.4 * displayScale)
		gui.Enabled = true
		local title = assert(gui:FindFirstChildWhichIsA("TextLabel", true))
		title.Text = item.name
			.. "\n×"
			.. item.power
			.. "\n"
			.. (item.cost == 0 and "FREE" or Config.format(item.cost) .. " Crowns")
		title.TextColor3 = item.color
		anchor.Position =
			Vector3.new(cf.Position.X, cf.Position.Y + size.Y / 2 + (0.75 + 2.7) * displayScale, cf.Position.Z)
		anchor:SetAttribute("BallDisplayLabelSlot", item.displaySlot)
		model:SetAttribute("DisplayLabelBase", anchor.Position)
		local link = model:FindFirstChild("DisplayLabel") or Instance.new("ObjectValue")
		link.Name = "DisplayLabel"
		link.Value = anchor
		link.Parent = model
		Tags:AddTag(model, "BallStandPreview")
		local promptAnchor = stand:FindFirstChild("BallPurchase" .. item.displaySlot)
		if not promptAnchor then
			promptAnchor = Instance.new("Part")
			promptAnchor.Name = "BallPurchase" .. item.displaySlot
			promptAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
			promptAnchor.Transparency = 1
			promptAnchor.Anchored = true
			promptAnchor.CanCollide = false
			promptAnchor.CanTouch = false
			promptAnchor.CanQuery = false
			promptAnchor.Parent = stand
		end
		-- Follow the display's facing when the authored stand is turned in Studio.
		promptAnchor.Position =
			top.CFrame:PointToWorldSpace(Vector3.new(top.Size.X / 2 + displayScale, 0.6 * displayScale, 0))
		local pp = promptAnchor:FindFirstChildWhichIsA("ProximityPrompt") or Instance.new("ProximityPrompt")
		pp.Name = "BallPurchasePrompt"
		pp.ObjectText = item.name
		pp.ActionText = "View ball"
		pp.MaxActivationDistance = 13
		pp.RequiresLineOfSight = false
		pp.HoldDuration = 0
		pp:SetAttribute("BallId", item.id)
		pp.Parent = promptAnchor
	end
	for _, part in root:GetChildren() do
		if part:IsA("BasePart") and part:GetAttribute("BallDisplayLabelSlot") then
			local slot = part:GetAttribute("BallDisplayLabelSlot")
			local gui = part:FindFirstChildWhichIsA("BillboardGui")
			if gui and anchors[slot] ~= part then
				gui.Enabled = false
			end
		end
		if part:IsA("BasePart") and part.Name:match("^DisplayStone_") then
			part.Transparency = 1
			local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then
				prompt.Enabled = false
			end
		end
	end
	if container:IsA("Model") and not container.PrimaryPart then
		local bounds = container:GetBoundingBox()
		container.WorldPivot = bounds
	end
	return container
end

return Stand
