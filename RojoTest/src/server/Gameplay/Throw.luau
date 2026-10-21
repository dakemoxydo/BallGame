--!strict
-- The shot: aim, kick, fly the stone through the bounces and pay the reward
-- on the last contact. The distance, the award and the skill gain are all
-- computed here, never taken from the client.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallPurchases = require(game.ReplicatedStorage.Shared.BallPurchases)
local ShotFeedback = require(game.ReplicatedStorage.Shared.ShotFeedback)
local ShotMotion = require(game.ReplicatedStorage.Shared.ShotMotion)

local Throw = {}

export type Context = {
	states: { [Player]: any },
	effect: RemoteEvent,
	FlightStreaming: any,
	publish: (Player, string?) -> (),
	stopTraining: (Player, boolean?) -> (),
	lockPose: (any, any, any, CFrame) -> (),
	releasePose: (any) -> (),
	rootFor: (Player) -> (any, any),
	arenaFor: (Player) -> any,
	frameFor: (Player) -> any,
	inApron: (Player) -> boolean,
	multiplier: (any) -> number,
}

function Throw.build(context: Context): (Player, number?) -> ()
	return function(player: Player, adminDistance: number?)
		local s = context.states[player]
		if not s or os.clock() < s.busyUntil then
			return
		end
		if not context.inApron(player) then
			context.publish(player, "Go to the yellow THROW ZONE")
			return
		end
		local d = s.data
		local trail = Config.find(Config.Trails, d.trail)
		if adminDistance then
			assert(s.adminOriginal, "Test throw requires an admin test session")
		end
		local distance = adminDistance
			or Config.shotDistance(d.skill, BallPurchases.power(d), d.world, context.arenaFor(player))
		local feedback = ShotFeedback.profile(d.skill, BallPurchases.power(d), d.world)
		local duration = Config.shotDuration(distance, d.world, feedback.intensity)
		context.stopTraining(player)
		local root, hum = context.rootFor(player)
		if not root or not hum then
			return
		end
		local frame = context.frameFor(player)
		context.lockPose(s, root, hum, Config.apronCharacterPose(context.arenaFor(player), root, hum, -11))
		local startedAt = workspace:GetServerTimeNow()
		local shot = {}
		s.activeShot = shot
		s.busyUntil = os.clock() + Config.KickWindup + duration + 0.7
		task.delay(0.9, function()
			if
				context.states[player] == s
				and s.activeShot == shot
				and s.pose
				and s.pose.root == root
				and not s.lane
			then
				context.releasePose(s)
			end
		end)
		local award = math.max(1, math.floor(distance / 8))
		award = math.floor(
			award * trail.boost * (d.perks.DoubleWins and 2 or 1) * (1 + s.friends * 0.1) * (d.world == 2 and 3 or 1)
		)
		local info = {
			userId = player.UserId,
			distance = distance,
			duration = duration,
			feedback = feedback,
			stone = d.stone,
			trail = d.trail,
			world = d.world,
			startedAt = startedAt,
			startPosition = frame:PointToWorldSpace(Vector3.new(-115.35, 1.8, -0.3)),
			direction = frame.LookVector,
			waterY = frame:PointToWorldSpace(Vector3.new(-116, 0.82, 0)).Y,
		}
		local character = player.Character
		local skillMultiplier = context.multiplier(s)
		context.FlightStreaming.start(player, info, function()
			return context.states[player] == s
				and s.data == d
				and player.Character == character
				and hum.Health > 0
				and os.clock() < s.busyUntil
		end)
		context.effect:FireAllClients("Throw", info)
		context.publish(player)
		for contact = 1, ShotMotion.BounceCount do
			task.delay(ShotMotion.contactTime(contact, duration), function()
				if
					context.states[player] ~= s
					or s.data ~= d
					or s.activeShot ~= shot
					or player.Character ~= character
					or hum.Health <= 0
				then
					return
				end
				local gain = Config.shotBounceGain(skillMultiplier)
				d.skill += gain
				context.effect:FireClient(
					player,
					"ShotBounce",
					{ gain = gain, contact = contact, distance = distance * contact / ShotMotion.BounceCount }
				)
				if contact == ShotMotion.BounceCount then
					s.activeShot = nil
					d.wins += award
					d.best = math.max(d.best, distance)
					context.effect:FireClient(player, "Result", { wins = award, distance = distance })
					context.publish(
						player,
						"+" .. Config.format(award) .. " WINS • " .. Config.format(distance) .. " m"
					)
				else
					context.publish(player)
				end
			end)
		end
	end
end

return Throw
