--!strict
local Egg = {}
function Egg.apply(map)
	local world = map.SkippingWorld
	local anchor = assert(world:FindFirstChild("HackedAdminEgg"))
	local old = world:FindFirstChild("VolcanicEggVisual")
	if old then
		old:Destroy()
	end
	local fallback = world:FindFirstChild("VolcanicEggFallback")
	if not fallback then
		fallback = game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri("rbxassetid://137723316390315"))
		fallback.Name = "VolcanicEggFallback"
		fallback.Color = Color3.fromRGB(100, 20, 14)
		fallback.Material = Enum.Material.SmoothPlastic
		fallback.Anchored = true
		fallback.CanCollide, fallback.CanTouch, fallback.CanQuery = false, false, false
		fallback.Parent = world
	end
	local stand = assert(world:FindFirstChild("HackedEggStand"))
	local height = 12.5
	local centerY = stand.Position.Y + stand.Size.Y / 2 + 0.3 + height / 2
	fallback.Size = Vector3.new(4.978106, 7, 4.978202) * (height / 7)
	fallback.CFrame = anchor.CFrame + Vector3.new(0, centerY - anchor.Position.Y, 0)
	anchor.Transparency = 1
	anchor.CastShadow = false
	anchor.ProximityPrompt.ObjectText = "Volcanic Inferno Egg • 175 Robux"
	for _, node in world:GetChildren() do
		if node.Name == "HackedPixel" then
			node.Transparency = 1
			node.CastShadow = false
		end
		if node.Name == "LabelAnchor" then
			local text = node:FindFirstChildWhichIsA("TextLabel", true)
			if
				text
				and (text.Text:find("Hacked Admin Egg", 1, true) or text.Text:find("Volcanic Inferno Egg", 1, true))
			then
				text.Text = "Volcanic Inferno Egg\n175 ROBUX"
				text.TextColor3 = Color3.fromRGB(255, 160, 48)
				node.CFrame += Vector3.new(0, centerY + height / 2 + 5.5 - node.Position.Y, 0)
			end
		end
	end
end
return Egg
