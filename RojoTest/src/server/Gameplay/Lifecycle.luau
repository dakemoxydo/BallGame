--!strict
-- The player lifecycle of the server: the join, the leave, the minute autosave
-- and the shutdown that flushes every session to the datastore.
local Players = game:GetService("Players")

local Lifecycle = {}

export type Context = {
	states: { [Player]: any },
	setup: (Player) -> (),
	save: (Player, boolean?, string?) -> boolean,
	stopTraining: (Player, boolean?) -> (),
	friends: (Player) -> number,
	admin: any,
	FlightStreaming: any,
}

function Lifecycle.install(context: Context)
	Players.PlayerAdded:Connect(function(p)
		task.spawn(context.setup, p)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(context.setup, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		context.FlightStreaming.stop(p)
		context.stopTraining(p)
		context.admin:restore(p, false)
		context.admin.last[p] = nil
		context.admin.counters[p] = nil
		local s = context.states[p]
		if s then
			while s.saving do
				task.wait(0.1)
			end
			context.save(p, true)
			context.states[p] = nil
		end
	end)
	task.spawn(function()
		while true do
			task.wait(60)
			-- The players are copied out of the state table before the walk:
			-- the friend lookup yields and a session that starts meanwhile
			-- would change the table that is being iterated.
			local players: { Player } = {}
			for p in context.states do
				table.insert(players, p)
			end
			for _, p in players do
				local count = context.friends(p)
				-- The player can leave while the lookup runs.
				local s = context.states[p]
				if s then
					s.friends = count
					task.spawn(context.save, p, false)
				end
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for p, s in context.states do
			pending += 1
			task.spawn(function()
				while s.saving do
					task.wait(0.1)
				end
				context.admin:restore(p, false)
				context.save(p, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return Lifecycle
