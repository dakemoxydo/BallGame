--!strict
local Cleanup = {}
function Cleanup.apply(map)
	local targets = {
		Vector2.new(-36.923, 150.415),
		Vector2.new(-32.887, 149.562),
		Vector2.new(-36.508, 145.168),
		Vector2.new(-21.334, 148.573),
		Vector2.new(-1.923, 195.415),
		Vector2.new(0.146, 194.562),
		Vector2.new(-3.508, 190.168),
		Vector2.new(13.666, 193.573),
		Vector2.new(-16.334, 257.573),
		Vector2.new(18.784, 237.774),
		Vector2.new(22.050, 242.510),
	}
	local offset = map.Lobby.ThrowingApron.Position - Vector3.new(24.240257, 20.3, 115.847107)
	local backup = game.ServerStorage.WorldBackups:FindFirstChild("RemovedMarkedLobbyDecor")
	if not backup then
		backup = Instance.new("Folder")
		backup.Name = "RemovedMarkedLobbyDecor"
		backup.Parent = game.ServerStorage.WorldBackups
	end
	local groups = { map.EnvironmentPolish.LobbyGardens, map.NativeEnvironment.LobbyAccents }
	local removed = 0
	for _, group in ipairs(groups) do
		for _, m in ipairs(group:GetChildren()) do
			if m:IsA("Model") then
				local p = m:GetBoundingBox().Position - offset
				for _, target in ipairs(targets) do
					if (Vector2.new(p.X, p.Z) - target).Magnitude < 0.15 then
						m.Parent = backup
						removed += 1
						break
					end
				end
			end
		end
	end
	return removed
end
return Cleanup
