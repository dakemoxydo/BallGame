--!strict
local Placement = {}
function Placement.apply(map)
	local garden = map.SkippingWorld.World2Portal.SakuraCourtyard
	if garden:GetAttribute("HideSakuraTree") then
		return
	end
	if garden:FindFirstChild("SakuraTree") then
		return
	end
	local tree = game.ServerStorage.ImportedSakuraVisuals.SakuraTree:Clone()
	tree.WorldPivot = CFrame.identity
	tree:ScaleTo(4.1)
	tree:PivotTo(garden:GetPivot() * CFrame.new(-28, 0, 5) * CFrame.Angles(0, math.rad(18), 0))
	tree.Parent = garden
end
return Placement
