--!strict
-- The training loop runs ten times a second for every player in the server.
-- The lane models and their starting pads are cached in the player state when
-- the player joins, so the tick never builds a lane name and never walks the
-- arena tree again.
local TrainingMotion = require(game.ReplicatedStorage.Shared.TrainingMotion)

local Training = {}

export type Context = {
	states: { [Player]: any },
	Config: any,
	effect: RemoteEvent,
	publish: (Player, string?) -> (),
	startTraining: (Player, number) -> (),
	stopTraining: (Player, boolean?) -> (),
	throw: (Player, number?) -> (),
	inApron: (Player) -> boolean,
	arenaFor: (Player) -> any,
	rootFor: (Player) -> (any, any),
	multiplier: (any) -> number,
}

function Training.run(context: Context)
	task.spawn(function()
		while true do
			task.wait(0.1)
			for player, s in context.states do
				local pos, hum = context.rootFor(player)
				local laneIndex = nil
				if pos and hum and hum.Health > 0 and os.clock() >= s.busyUntil then
					local lanes = s.lanes and s.lanes[s.data.world == 2 and 2 or 1]
					for i, def in context.Config.Lanes do
						local entry = lanes and lanes[i]
						local pad = entry and entry.pad
						if pad then
							local point = pad.CFrame:PointToObjectSpace(pos.Position)
							if
								math.abs(point.X) <= pad.Size.X / 2 + 1
								and math.abs(point.Z) <= pad.Size.Z / 2 + 1
								and point.Y >= 0
								and point.Y < 9
							then
								if s.data.rebirths >= def.rebirths then
									laneIndex = i
								else
									if os.clock() > (s.lockNotice or 0) then
										context.publish(player, "Need " .. def.rebirths .. " rebirths for this lane")
										s.lockNotice = os.clock() + 4
									end
								end
								break
							end
						end
					end
				end
				if not laneIndex then
					s.blockedLane = nil
				end
				if s.lane and laneIndex ~= s.lane then
					context.stopTraining(player)
				end
				if laneIndex and laneIndex ~= s.blockedLane and not s.lane and os.clock() >= (s.stopUntil or 0) then
					context.startTraining(player, laneIndex)
				end
				local serverNow = workspace:GetServerTimeNow()
				local contacts = 0
				while s.lane and s.nextTraining and serverNow >= s.nextTraining and contacts < 8 do
					local cycleGain = context.Config.Lanes[s.lane].gain
						* context.multiplier(s)
						* 7
						* context.Config.TrainingCycle
						/ 0.8
					local gain, remainder = TrainingMotion.reward(cycleGain, s.lane, s.gainRemainder)
					s.gainRemainder = remainder
					s.data.skill += gain
					context.effect:FireClient(player, "Train", { gain = gain, lane = s.lane, hit = s.trainingHit })
					s.trainingHit += 1
					contacts += 1
					s.nextPublish = 0
					if s.trainingHit > TrainingMotion.hitCount(s.lane) then
						s.trainingHit = 1
						s.trainingCycle += 1
					end
					s.nextTraining = s.trainingStarted
						+ s.trainingCycle * context.Config.TrainingCycle
						+ TrainingMotion.hitTime(s.lane, s.trainingHit)
				end
				if s.auto and not laneIndex and context.inApron(player) and os.clock() >= s.busyUntil then
					context.throw(player)
				end
				if os.clock() >= (s.nextPublish or 0) then
					s.nextPublish = os.clock() + 0.4
					context.publish(player)
				end
			end
		end
	end)
end

return Training
