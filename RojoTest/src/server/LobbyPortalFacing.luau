--!strict
-- Face the existing portal opening toward its flat approach from the avenue.
local Facing = {}

function Facing.apply(map)
	local portal = map.SkippingWorld.World2Portal
	local version = portal:GetAttribute("TwoAxesFacingVersion")
	if version == 2 then
		return
	end
	local field = portal.PortalField
	local frame = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
	local target = CFrame.new(field.Position) * frame.Rotation * CFrame.Angles(0, -math.pi / 2, 0)
	if version == 1 then
		-- Migrate the earlier ring-only turn: align the remaining composition.
		local previous = CFrame.new(field.Position) * frame.Rotation
		local delta = target * previous:Inverse()
		local court = portal.SakuraCourtyard
		court:PivotTo(delta * court:GetPivot())
	else
		local delta = target * field.CFrame:Inverse()
		portal:PivotTo(delta * portal:GetPivot())
	end
	-- Reconnect the six original flat approach stones to the avenue. Their
	-- positions had been arranged independently during the lobby relocation.
	local slabs = {}
	for _, p in ipairs(portal.SakuraCourtyard:GetChildren()) do
		if p:IsA("BasePart") and p.Name == "ApproachSlab" then
			table.insert(slabs, p)
		end
	end
	assert(#slabs == 6, "Unexpected portal approach")
	table.sort(slabs, function(a, b)
		if math.abs(a.Position.Z - b.Position.Z) > 0.01 then
			return a.Position.Z < b.Position.Z
		end
		return a.Position.X < b.Position.X
	end)
	local distances = { 20, 28, 36, 44, 52, 58 }
	local ground = CFrame.new(field.Position.X, frame.Position.Y, field.Position.Z) * target.Rotation
	for i, p in ipairs(slabs) do
		p.CFrame = ground * CFrame.new(0, 0.09, -distances[i])
	end
	portal.SakuraCourtyard.WorldPivot = ground
	if not portal.PrimaryPart then
		portal.WorldPivot = portal:GetBoundingBox()
	end
	portal:SetAttribute("TwoAxesFacingVersion", 2)
end

return Facing
