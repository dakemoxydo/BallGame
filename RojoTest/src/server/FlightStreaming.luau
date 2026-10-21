--!strict
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.ShotMotion)
local Streaming = {}
local active = {}

function Streaming.stop(player)
	local stop = active[player]
	if stop then
		stop()
	end
end

-- The character stays at the apron while its camera follows a client-only ball.
-- Keep the character's normal focus and add one temporary focus on the ball, so
-- the region it flies through stays streamed for everybody who watches it.
function Streaming.start(player, info, isActive)
	Streaming.stop(player)
	if not workspace.StreamingEnabled then
		return
	end
	local focus = Instance.new("Part")
	focus.Name = "FlightStreaming_" .. player.UserId
	focus.Size = Vector3.one
	focus.Anchored = true
	focus.Transparency = 1
	focus.CanCollide = false
	focus.CanTouch = false
	focus.CanQuery = false
	focus.CastShadow = false
	focus.Archivable = false
	local function position()
		local elapsed = workspace:GetServerTimeNow() - info.startedAt
		-- The focus has to sit on the ball, not ahead of it: the client and the
		-- shot contacts use the same alpha, so the streamed region is the one
		-- the ball is really in.
		local alpha = math.clamp((elapsed - Config.KickWindup) / info.duration, 0, 1)
		return Motion.position(info.startPosition, info.distance, alpha, info.direction)
	end
	focus.Position = position()
	focus.Parent = workspace
	player:AddReplicationFocus(focus)
	local connection
	local function stop()
		if active[player] ~= stop then
			return
		end
		active[player] = nil
		connection:Disconnect()
		if player.Parent then
			player:RemoveReplicationFocus(focus)
		end
		focus:Destroy()
	end
	active[player] = stop
	local sinceUpdate = 0
	connection = RunService.Heartbeat:Connect(function(dt)
		sinceUpdate += dt
		if sinceUpdate < 0.2 then
			return
		end
		sinceUpdate = 0
		if
			not player.Parent
			or not isActive()
			or workspace:GetServerTimeNow() >= info.startedAt + Config.KickWindup + info.duration + 0.65
		then
			stop()
		else
			focus.Position = position()
		end
	end)
end

return Streaming
