--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IntroStreaming = {}
function IntroStreaming.start()
	local remote = Instance.new("RemoteEvent")
	remote.Name = "MapIntroStreaming"
	remote.Parent = ReplicatedStorage
	local sessions, used = {}, {}
	local function release(player)
		local anchors = sessions[player]
		sessions[player] = nil
		if not anchors then
			return
		end
		for _, anchor in anchors do
			pcall(function()
				player:RemoveReplicationFocus(anchor)
			end)
			anchor:Destroy()
		end
	end
	remote.OnServerEvent:Connect(function(player, command)
		if command == "Finish" then
			release(player)
			return
		end
		if command ~= "Prepare" or used[player] then
			return
		end
		used[player] = true
		local anchors = {}
		sessions[player] = anchors
		-- Server-owned positions; the client cannot request arbitrary map regions.
		local positions = { Vector3.new(48, 30, 200) }
		for i = 0, 7 do
			table.insert(positions, Vector3.new(48, 30, -10.399963 - i * 270))
		end
		table.insert(positions, Vector3.new(48, 70, -2029))
		for _, position in positions do
			local anchor = Instance.new("Part")
			anchor.Name = "IntroStreamingFocus"
			anchor.Size = Vector3.one
			anchor.Anchored = true
			anchor.Transparency = 1
			anchor.CanCollide = false
			anchor.CanTouch = false
			anchor.CanQuery = false
			anchor.Position = position
			anchor.Parent = workspace
			table.insert(anchors, anchor)
			player:AddReplicationFocus(anchor)
		end
		-- Also release if a client disconnects or never sends completion.
		task.delay(45, function()
			if sessions[player] == anchors then
				release(player)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		release(player)
		used[player] = nil
	end)
end
return IntroStreaming
