--!strict
-- World interaction prompts: the eggs, the world portal, the item stands and
-- the admin egg. Every handler checks that the player really is in the arena
-- that owns the prompt.
-- A prop that is missing from the map is reported and skipped: the install
-- must never raise, or the whole server would start without a single session.
local Prompts = {}

export type Context = {
	states: { [Player]: any },
	Config: any,
	effect: RemoteEvent,
	publish: (Player, string?) -> (),
	stopTraining: (Player, boolean?) -> (),
	arenaFor: (Player) -> any,
	rootFor: (Player) -> (any, any),
}

function Prompts.install(context: Context, map: any, world2: any)
	for index, arena in { map, world2 } do
		local label = index == 1 and "World1" or "World2"
		local scenery = arena and arena:FindFirstChild("SkippingWorld")
		if not scenery then
			warn("[Ball] " .. label .. " has no SkippingWorld folder")
			continue
		end
		for _, egg in context.Config.Eggs do
			local eggModel = scenery:FindFirstChild("Egg_" .. egg.id)
			local shell = eggModel and eggModel:FindFirstChild("EggShell")
			local prompt = shell and shell:FindFirstChildWhichIsA("ProximityPrompt", true)
			if not prompt then
				warn("[Ball] " .. label .. " has no prompt for the egg " .. egg.id)
				continue
			end
			prompt.Triggered:Connect(function(player)
				if context.states[player] and context.arenaFor(player) == arena then
					context.effect:FireClient(player, "Egg", egg.id)
				end
			end)
		end
		local portal = scenery:FindFirstChild("World2Portal")
		local field = portal and portal:FindFirstChild("PortalField")
		local portalPrompt = field and field:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not portalPrompt then
			warn("[Ball] " .. label .. " has no world portal prompt")
		else
			portalPrompt.Triggered:Connect(function(player)
				local s = context.states[player]
				if not s or context.arenaFor(player) ~= arena then
					return
				end
				-- The prompt is looked up again on every use: the map can be
				-- rebuilt while the server runs.
				local current = field:FindFirstChildWhichIsA("ProximityPrompt", true)
				if not current then
					return
				end
				local portalPosition = current.Parent:IsA("Attachment") and current.Parent.WorldPosition
					or current.Parent.Position
				local root, hum = context.rootFor(player)
				if
					not root
					or not hum
					or (root.Position - portalPosition).Magnitude > 15
					or os.clock() < s.busyUntil
				then
					return
				end
				if index == 1 and not s.data.unlockedWorld2 then
					if s.data.wins < 100000 then
						context.publish(player, "World 2 needs 100K Wins")
						return
					end
					s.data.wins -= 100000
					s.data.unlockedWorld2 = true
				end
				context.stopTraining(player)
				s.blockedLane = nil
				s.data.world = index == 1 and 2 or 1
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				root.CFrame = context.Config.apronCharacterPose(context.arenaFor(player), root, hum, 3)
				context.publish(player, index == 1 and "WORLD 2 • ×3 SKILL & WINS" or "Welcome back to World 1")
				context.effect:FireClient(player, "World", s.data.world)
			end)
		end
		local stand = arena:FindFirstChild("EmptyItemStand")
		if not stand then
			warn("[Ball] " .. label .. " has no EmptyItemStand")
		else
			for _, p in stand:GetDescendants() do
				if p:IsA("ProximityPrompt") and p:GetAttribute("BallId") then
					p.Triggered:Connect(function(player)
						if context.states[player] and context.arenaFor(player) == arena then
							local root = context.rootFor(player)
							if root and (root.Position - p.Parent.Position).Magnitude <= 15 then
								context.effect:FireClient(player, "OpenBall", p:GetAttribute("BallId"))
							end
						end
					end)
				end
			end
		end
		local adminEgg = scenery:FindFirstChild("HackedAdminEgg")
		local adminPrompt = adminEgg and adminEgg:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not adminPrompt then
			warn("[Ball] " .. label .. " has no admin egg prompt")
		else
			adminPrompt.Triggered:Connect(function(player)
				if context.states[player] and context.arenaFor(player) == arena then
					context.effect:FireClient(player, "AdminEgg", {})
				end
			end)
		end
	end
end

return Prompts
