--!strict
-- Player session: the profile is loaded, the authoritative state is created
-- and the character hook keeps the pose and the training lane in sync.
-- The state is created with the inventory versions the snapshot contract needs:
-- `inventoryVersion` counts the changes, `sentInventoryVersion` counts what
-- the client already received.
local Session = {}

export type Context = {
	states: { [Player]: any },
	Config: any,
	publish: (Player, string?) -> (),
	stopTraining: (Player, boolean?) -> (),
	rootFor: (Player) -> (any, any),
	arenaFor: (Player) -> any,
	friends: (Player) -> number,
	Profiles: any,
	LobbyRankings: any,
	FlightStreaming: any,
	isStudio: boolean,
	lanes: { [number]: any },
}

function Session.setup(context: Context, player: Player)
	local Profiles = context.Profiles
	local profile = Profiles:Load(player)
	if not profile then
		return
	end
	local friendCount = context.friends(player)
	if not player.Parent or not profile:IsActive() then
		Profiles:Release(player, { data = profile.Data.progress })
		return
	end
	local state = {
		data = profile.Data.progress,
		joined = os.clock(),
		gifts = {},
		busyUntil = 0,
		lastAction = 0,
		tokens = 12,
		lane = nil,
		auto = false,
		friends = friendCount,
		sessionOnly = context.isStudio,
		inventoryVersion = 1,
		sentInventoryVersion = 0,
		lanes = context.lanes,
	}
	context.states[player] = state
	Profiles:Attach(player, state, function()
		context.stopTraining(player)
		context.FlightStreaming.stop(player)
		context.states[player] = nil
	end)
	profile.OnAfterSave:Connect(function(snapshot)
		task.spawn(context.LobbyRankings.record, player.UserId, snapshot.progress)
	end)
	local leader = Instance.new("Folder")
	leader.Name = "leaderstats"
	leader.Parent = player
	for _, name in { "Skill", "Wins", "Rebirths" } do
		local value = Instance.new("NumberValue")
		value.Name = name
		value.Parent = leader
	end
	local handledCharacter: Model? = nil
	local function spawn(char: Model)
		-- The same character can reach the hook twice: the signal can fire
		-- while the character that already exists is spawned.
		if char == handledCharacter then
			return
		end
		handledCharacter = char
		context.FlightStreaming.stop(player)
		local r: any = char:WaitForChild("HumanoidRootPart", 10)
		local hum: any = char:WaitForChild("Humanoid", 10)
		if r and hum then
			hum.WalkSpeed = context.Config.CharacterWalkSpeed
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			r.CFrame = context.Config.apronCharacterPose(context.arenaFor(player), r, hum, 3)
		end
		local s = context.states[player]
		if s then
			context.stopTraining(player)
			s.blockedLane = nil
			s.busyUntil = 0
		end
		if hum then
			hum.Died:Connect(function()
				context.stopTraining(player)
				context.FlightStreaming.stop(player)
			end)
		end
		context.publish(player)
	end
	player.CharacterAdded:Connect(spawn)
	local character = player.Character
	if character then
		task.spawn(spawn, character)
	end
	context.publish(player, "Train on a pad, then THROW your stone!")
end

return Session
