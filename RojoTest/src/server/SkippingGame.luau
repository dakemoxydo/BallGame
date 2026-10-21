--!strict
-- Entry point of the gameplay server.
-- This module owns the remotes, the player states and the shared helpers and
-- hands an explicit context to every gameplay module in the Gameplay folder.
-- The modules never keep state of their own: everything they need is passed
-- in, so the flow of the data stays readable from here.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Shared.GameConfig)
local BallPurchases = require(ReplicatedStorage.Shared.BallPurchases)
local TrainingMotion = require(ReplicatedStorage.Shared.TrainingMotion)
local Net = require(ReplicatedStorage.Shared.Net)
local LobbyRankings = require(script.Parent.LobbyRankings)
local AdminService = require(script.Parent.AdminService)
local FlightStreaming = require(script.Parent.FlightStreaming)
local Profiles = require(script.Parent.Services.ProfileService)
local ProfileData = require(ReplicatedStorage.Shared.Core.ProfileData)
local Snapshot = require(script.Parent.Gameplay.Snapshot)
local Commands = require(script.Parent.Gameplay.Commands)
local Receipts = require(script.Parent.Gameplay.Receipts)
local Training = require(script.Parent.Gameplay.Training)
local Session = require(script.Parent.Gameplay.Session)
local Throw = require(script.Parent.Gameplay.Throw)
local Prompts = require(script.Parent.Gameplay.Prompts)
local Lifecycle = require(script.Parent.Gameplay.Lifecycle)

local Game: any = {}
local started = false

function Game.start(map, world2)
	if started then
		return
	end
	started = true
	local remote = Net.server()
	local action: any = remote.Action
	local update: any = remote.Update
	local effect: any = remote.Effect
	local states: { [Player]: any } = {}
	local admin
	-- The training lanes are cached once per arena: the hot loop then reads a
	-- ready reference instead of walking the arena tree on every tick. A lane
	-- that is missing is reported, because the training would stay silent
	-- otherwise.
	local function laneSet(arena, label: string)
		local set = {}
		local zone = arena:FindFirstChild("TrainingZone")
		for index = 1, 7 do
			local lane = zone and zone:FindFirstChild("TrainingLane" .. index)
			local pad = lane and lane:FindFirstChild("StartingPad")
			if not lane then
				warn("[Ball] " .. label .. " has no training lane " .. index)
			elseif not pad then
				warn("[Ball] " .. label .. " training lane " .. index .. " has no starting pad")
			else
				set[index] = { lane = lane, pad = pad }
			end
		end
		return set
	end
	local lanes = { [1] = laneSet(map, "World1"), [2] = laneSet(world2, "World2") }
	local function arenaFor(player: Player)
		local state = states[player]
		return state and state.data.world == 2 and world2 or map
	end
	local function frameFor(player: Player)
		return Config.arenaFrame(arenaFor(player))
	end
	local function pointFor(player: Player, point: Vector3)
		return frameFor(player):PointToWorldSpace(point)
	end
	if RunService:IsStudio() then
		Game.studioState = function(player)
			return states[player]
		end
	end
	local fresh = ProfileData.fresh
	local function rootFor(player: Player): (BasePart?, Humanoid?)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		return root :: BasePart?, hum :: Humanoid?
	end
	local function standingHeight(root: BasePart, hum: Humanoid)
		return root.Size.Y / 2 + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight)
	end
	local function releasePose(s: any)
		local pose = s.pose
		if pose then
			if pose.root.Parent then
				pose.root.Anchored = pose.anchored
			end
			if pose.hum.Parent then
				pose.hum.AutoRotate = pose.autoRotate
			end
			s.pose = nil
		end
	end
	local function stopTraining(player: Player, block: boolean?)
		local s = states[player]
		if not s then
			return
		end
		if s.activeShot then
			s.activeShot = nil
			s.busyUntil = 0
			FlightStreaming.stop(player)
			effect:FireClient(player, "ShotCancelled")
		end
		if block then
			s.blockedLane = s.lane
		end
		s.lane = nil
		s.trainingStarted = nil
		s.nextTraining = nil
		s.trainingHit = nil
		s.trainingCycle = nil
		local char = player.Character
		if char then
			char:SetAttribute("TrainingLane", nil)
			char:SetAttribute("TrainingStarted", nil)
		end
		releasePose(s)
	end
	local function lockPose(s: any, root: BasePart, hum: Humanoid, cf: CFrame)
		releasePose(s)
		s.pose = { root = root, hum = hum, anchored = root.Anchored, autoRotate = hum.AutoRotate }
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = cf
		root.Anchored = true
		hum.AutoRotate = false
	end
	local function laneEntry(s: any, index: number)
		local set = s.lanes and s.lanes[s.data.world == 2 and 2 or 1]
		return set and set[index]
	end
	local function startTraining(player: Player, index: number)
		local s = states[player]
		local root, hum = rootFor(player)
		if not s or not root or not hum then
			return
		end
		local entry = laneEntry(s, index)
		local lane = entry and entry.lane
		local pad = entry and entry.pad
		if not lane or not pad then
			return
		end
		local position =
			Vector3.new(pad.Position.X - 1, Config.trainingSurface(lane) + standingHeight(root, hum), pad.Position.Z)
		lockPose(s, root, hum, CFrame.lookAt(position, position + Vector3.xAxis))
		s.lane = index
		s.trainingStarted = workspace:GetServerTimeNow()
		s.trainingHit = 1
		s.trainingCycle = 0
		s.nextTraining = s.trainingStarted + TrainingMotion.hitTime(index, 1)
		s.nextPublish = 0
		local character = player.Character :: Model
		character:SetAttribute("TrainingLane", index)
		character:SetAttribute("TrainingStarted", s.trainingStarted)
	end
	local function petBoost(data: any)
		local bonus = 0
		for _, id in data.equipped do
			for _, pet in data.pets do
				if pet.uid == id then
					bonus += math.max(0, (pet.boost or 1) - 1)
					break
				end
			end
		end
		return 1 + bonus
	end
	-- The friend counts live for a minute: every lookup is a web request and
	-- Roblox throttles them, so the same pair is not asked twice in a minute
	-- and the count of a player is reused while it is fresh.
	local FRIEND_TTL = 60
	local friendCounts: { [number]: { count: number, at: number } } = {}
	local friendPairs: { [string]: { friend: boolean, at: number } } = {}

	local function friends(player: Player): number
		local cachedCount = friendCounts[player.UserId]
		if cachedCount and os.clock() - cachedCount.at < FRIEND_TTL then
			return cachedCount.count
		end
		-- The stale entries are dropped here: a player that left must not keep
		-- a row in the cache forever.
		for staleKey, staleEntry in friendCounts do
			if os.clock() - staleEntry.at >= FRIEND_TTL then
				friendCounts[staleKey] = nil
			end
		end
		for staleKey, staleEntry in friendPairs do
			if os.clock() - staleEntry.at >= FRIEND_TTL then
				friendPairs[staleKey] = nil
			end
		end
		local count = 0
		local failed = 0
		for _, p in Players:GetPlayers() do
			if p ~= player then
				-- The pair is keyed by the two user ids in a fixed order: a
				-- friendship is the same from both sides.
				local key = player.UserId < p.UserId and (player.UserId .. ":" .. p.UserId)
					or (p.UserId .. ":" .. player.UserId)
				local pair = friendPairs[key]
				local friend = false
				if pair and os.clock() - pair.at < FRIEND_TTL then
					friend = pair.friend
				else
					local ok, result = pcall(player.IsFriendsWith, player, p.UserId)
					if ok then
						friend = result
						friendPairs[key] = { friend = friend, at = os.clock() }
					else
						-- The request was throttled: the pair is not counted
						-- and the refresh says so once.
						failed += 1
					end
				end
				if friend then
					count += 1
				end
			end
		end
		if failed > 0 then
			warn("[Ball] the friend check of " .. player.Name .. " failed for " .. failed .. " player(s)")
		end
		friendCounts[player.UserId] = { count = count, at = os.clock() }
		return count
	end
	local function multiplier(state: any)
		local d = state.data
		return (1 + d.rebirths)
			* petBoost(d)
			* BallPurchases.power(d)
			* (d.perks.DoubleSkill and 2 or 1)
			* (1 + state.friends * 0.1)
			* (d.world == 2 and 3 or 1)
	end
	local function inApron(player)
		local p, h = rootFor(player)
		if not p or not h or h.Health <= 0 then
			return false
		end
		local apron = arenaFor(player).Lobby.ThrowingApron
		local point = apron.CFrame:PointToObjectSpace(p.Position)
		return math.abs(point.X) <= apron.Size.X / 2
			and math.abs(point.Z) <= apron.Size.Z / 2 + 1
			and point.Y >= 0
			and point.Y < 12
	end
	local snapshotContext = {
		states = states,
		multiplier = multiplier,
		inApron = inApron,
		arenaFor = arenaFor,
	}
	local function publish(player: Player, notice: string?, forceInventory: boolean?)
		local s = states[player]
		if not s or not player.Parent then
			return
		end
		local payload = Snapshot.build(snapshotContext, player, notice, forceInventory)
		update:FireClient(player, payload)
		if payload.inventory then
			s.sentInventoryVersion = s.inventoryVersion
		end
		local d = s.data
		local leader: any = player:FindFirstChild("leaderstats")
		if leader then
			leader.Skill.Value = math.floor(d.skill)
			leader.Wins.Value = math.floor(d.wins)
			leader.Rebirths.Value = d.rebirths
		end
		player:SetAttribute("SkippingWorld", d.world)
	end
	local function save(player: Player, release: boolean?, receiptId: string?)
		local s = states[player]
		if not s then
			return false
		end
		if release then
			Profiles:Release(player, s)
			return true
		end
		return Profiles:Save(player, s, receiptId)
	end
	-- The pet list and the equipped slots travel to the client only when they
	-- changed, so the version is bumped by everything that touches them.
	local function equipBest(s: any)
		local d = s.data
		local sorted = table.clone(d.pets)
		table.sort(sorted, function(a, b)
			return a.boost > b.boost
		end)
		d.equipped = {}
		for i = 1, math.min(3, #sorted) do
			table.insert(d.equipped, sorted[i].uid)
		end
		s.inventoryVersion += 1
	end
	local function hatch(player: Player, id: string, count: number?, testing: boolean?)
		local s = states[player]
		local d = s.data
		local egg = Config.find(Config.Eggs, id)
		if not egg then
			return
		end
		local amount = count == 3 and 3 or 1
		if testing then
			assert(s.adminOriginal, "Test hatching requires an admin test session")
		end
		local pos = rootFor(player)
		if
			not testing and (not pos or (pos.Position - pointFor(player, Vector3.new(egg.x, 4, egg.z))).Magnitude > 19)
		then
			publish(player, "Walk to the " .. egg.name)
			return
		end
		if os.clock() < s.busyUntil then
			publish(player, "Wait for your throw to finish")
			return
		end
		if #d.pets + amount > 60 then
			publish(player, "Pet storage full (60). Delete a pet first.")
			return
		end
		local cost = testing and 0 or egg.cost * (d.world == 2 and 10 or 1)
		if d.wins < cost * amount then
			publish(player, "Need " .. Config.format(cost * amount) .. " Wins")
			return
		end
		d.wins -= cost * amount
		local hatched = {}
		for _ = 1, amount do
			local chosen = Config.rollEggPet(id)
			local pet = {
				uid = HttpService:GenerateGUID(false),
				id = chosen.id,
				name = chosen.name,
				boost = chosen.boost * egg.boost * (d.world == 2 and 3 or 1),
				rarity = chosen.rarity,
			}
			table.insert(d.pets, pet)
			table.insert(hatched, pet)
		end
		equipBest(s)
		effect:FireClient(player, "Hatch", hatched)
		publish(player)
	end
	local function purchaseItem(player: Player, list: any, ownedKey: string, equippedKey: string, id: string)
		local s = states[player]
		local d = s.data
		local item = Config.find(list, id)
		if not item then
			return
		end
		if not d[ownedKey][id] then
			if d.wins < item.cost then
				publish(player, "Need " .. Config.format(item.cost) .. " Wins")
				return
			end
			d.wins -= item.cost
			d[ownedKey][id] = true
		end
		d[equippedKey] = id
		publish(player, item.name .. " equipped!")
	end
	local function rebirth(player: Player, skip: boolean?)
		local s = states[player]
		if os.clock() < s.busyUntil then
			publish(player, "Wait for your throw to finish")
			return false
		end
		local level = Config.level(s.data.skill, s.data.rebirths)
		if not skip and level < Config.MaxLevel then
			publish(player, "Reach Level " .. Config.MaxLevel .. " to rebirth (Level " .. level .. " now)")
			return false
		end
		stopTraining(player, true)
		s.data.skill = 0
		s.data.rebirths += 1
		effect:FireClient(player, "Rebirth", {})
		publish(player, "REBIRTH! ×" .. (s.data.rebirths + 1) .. " SKILL")
		return true
	end
	local throw = Throw.build({
		states = states,
		effect = effect,
		FlightStreaming = FlightStreaming,
		publish = publish,
		stopTraining = stopTraining,
		lockPose = lockPose,
		releasePose = releasePose,
		rootFor = rootFor,
		arenaFor = arenaFor,
		frameFor = frameFor,
		inApron = inApron,
		multiplier = multiplier,
	})
	if RunService:IsStudio() then
		Game.studioThrow = throw
		Game.studioPublish = publish
	end
	Commands.install({
		action = action,
		states = states,
		publish = publish,
		throw = throw,
		hatch = hatch,
		purchaseItem = purchaseItem,
		rebirth = rebirth,
		equipBest = equipBest,
		stopTraining = stopTraining,
	})
	Receipts.install({
		states = states,
		Config = Config,
		save = save,
		publish = publish,
		effect = effect,
		equipBest = equipBest,
	})
	Prompts.install({
		states = states,
		Config = Config,
		effect = effect,
		publish = publish,
		stopTraining = stopTraining,
		arenaFor = arenaFor,
		rootFor = rootFor,
	}, map, world2)
	-- The training lanes are cached once per arena: the hot loop then reads a
	-- ready reference instead of walking the arena tree on every tick.
	Training.run({
		states = states,
		Config = Config,
		effect = effect,
		publish = publish,
		startTraining = startTraining,
		stopTraining = stopTraining,
		throw = throw,
		inApron = inApron,
		arenaFor = arenaFor,
		rootFor = rootFor,
		multiplier = multiplier,
	})
	local sessionContext = {
		states = states,
		Config = Config,
		publish = publish,
		stopTraining = stopTraining,
		rootFor = rootFor,
		arenaFor = arenaFor,
		friends = friends,
		Profiles = Profiles,
		LobbyRankings = LobbyRankings,
		FlightStreaming = FlightStreaming,
		isStudio = RunService:IsStudio(),
		lanes = lanes,
	}
	local function setup(player)
		Session.setup(sessionContext, player)
	end
	admin = AdminService.new({
		states = states,
		map = map,
		remotes = remote,
		effect = effect,
		publish = publish,
		stopTraining = stopTraining,
		rootFor = rootFor,
		arenaFor = arenaFor,
		fresh = fresh,
		equipBest = equipBest,
		hatch = hatch,
		throw = throw,
	})
	if RunService:IsStudio() then
		Game.admin = admin
	end
	Lifecycle.install({
		states = states,
		setup = setup,
		save = save,
		stopTraining = stopTraining,
		friends = friends,
		admin = admin,
		FlightStreaming = FlightStreaming,
	})
	LobbyRankings.start(map, states)
	print("StoneSkipping ready: 7 lanes, 8 biomes, pets, trails, gifts, rebirths")
end

return Game
