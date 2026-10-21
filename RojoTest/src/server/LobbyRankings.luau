--!strict
local Rankings = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local C, V = Color3.fromRGB, Vector3.new
local categories = {
	{ key = "skill", title = "TOP SKILL", color = C(66, 219, 255) },
	{ key = "wins", title = "TOP WINS", color = C(255, 209, 65) },
	{ key = "best", title = "BEST THROW", color = C(184, 116, 255), suffix = " m" },
}
local stores, cached, names = {}, {}, {}
-- Every profile save would write three ordered data stores, but Roblox refuses
-- a second write to the same key within six seconds. The last written value is
-- remembered per user and category, so an unchanged board costs no write.
local written: { [number]: { [string]: number }? } = {}
local writtenOrder: { number } = {}
local WRITTEN_LIMIT = 200
local started = false

-- The cache has to stay small: the oldest user is dropped when it grows over
-- the limit, and a leaving player is removed right away.
local function forget(userId: number)
	if not written[userId] then
		return
	end
	written[userId] = nil
	for index, id in writtenOrder do
		if id == userId then
			table.remove(writtenOrder, index)
			break
		end
	end
end

local function remember(userId: number, category: string, value: number)
	local entry: { [string]: number } = written[userId] or {}
	if not written[userId] then
		table.insert(writtenOrder, userId)
		while #writtenOrder > WRITTEN_LIMIT do
			local oldest = table.remove(writtenOrder, 1)
			if oldest then
				written[oldest] = nil
			end
		end
	end
	written[userId] = entry
	entry[category] = value
end

Players.PlayerRemoving:Connect(function(player)
	forget(player.UserId)
end)

function Rankings.apply(map)
	if map:FindFirstChild("LobbyRankings") then
		return
	end
	local portal = assert(map.SkippingWorld:FindFirstChild("World2Portal"))
	local field = assert(portal:FindFirstChild("PortalField"))
	local frame = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
	local oldPosition = field.Position
	local target = frame:PointToWorldSpace(V(-155, 20, 60))
	portal:PivotTo(portal:GetPivot() + (target - field.Position))
	local facing = CFrame.new(field.Position) * CFrame.Angles(0, math.rad(-135), 0)
	portal:PivotTo(facing * field.CFrame:Inverse() * portal:GetPivot())
	local prompt = assert(field:FindFirstChildWhichIsA("ProximityPrompt", true))
	local attachment = prompt.Parent
	assert(attachment:IsA("Attachment"), "Portal needs its ground-level prompt")
	local promptPoint = frame:PointToWorldSpace(V(-155, 4, 60))
	attachment.Position = field.CFrame:PointToObjectSpace(promptPoint)
	local group = Instance.new("Model")
	group.Name = "LobbyRankings"
	local function part(parent, name, size, cf, color)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Material = Enum.Material.Plastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end
	local function text(parent, name, value, y, height, color, font: Enum.Font?)
		local label = Instance.new("TextLabel")
		label.Name, label.Text = name, value
		label.Position, label.Size = UDim2.fromScale(0.05, y), UDim2.fromScale(0.9, height)
		label.BackgroundTransparency = 1
		label.Font, label.TextColor3 = font or Enum.Font.GothamBold, color
		label.TextScaled = true
		label.Parent = parent
		return label
	end
	for index, category in categories do
		local board = Instance.new("Model")
		board.Name = category.key
		board.Parent = group
		local center = V(oldPosition.X + (index - 2) * 30, frame.Position.Y + 18, oldPosition.Z)
		local cf = CFrame.new(center) * frame.Rotation
		part(board, "Foot", V(27, 0.8, 7), cf * CFrame.new(0, -17.5, 0), C(35, 56, 105))
		for _, x in { -9, 9 } do
			part(board, "Support", V(1.8, 5, 2), cf * CFrame.new(x, -15, 0), category.color)
		end
		part(board, "Frame", V(26, 31, 2.2), cf, category.color)
		local panel = part(board, "Panel", V(24.8, 29.8, 2.4), cf * CFrame.new(0, 0, -0.1), C(21, 31, 64))
		local gui = Instance.new("SurfaceGui")
		gui.Name = "RankingGui"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(620, 745)
		gui.LightInfluence = 0
		gui.Active = false
		gui.Parent = panel
		text(gui, "Title", category.title, 0.025, 0.085, category.color, Enum.Font.GothamBlack)
		text(gui, "Scope", "GLOBAL TOP 10", 0.115, 0.035, C(178, 198, 225))
		for rank = 1, 10 do
			local row = Instance.new("Frame")
			row.Name = "Row" .. rank
			row.Position = UDim2.fromScale(0.04, 0.17 + (rank - 1) * 0.072)
			row.Size = UDim2.fromScale(0.92, 0.066)
			row.BackgroundColor3 = rank % 2 == 0 and C(31, 46, 84) or C(39, 57, 99)
			row.BorderSizePixel = 0
			row.Parent = gui
			local label =
				text(row, "Entry", rank .. ".   —", 0.08, 0.84, rank <= 3 and C(255, 224, 135) or C(235, 244, 255))
			label.TextXAlignment = Enum.TextXAlignment.Left
		end
		text(gui, "Status", "Waiting for players", 0.91, 0.055, C(170, 191, 224))
		local crown = part(board, "CrownBase", V(8, 1.2, 1.8), cf * CFrame.new(0, 16.3, 0), C(255, 208, 58))
		for _, x in { -3, 0, 3 } do
			part(
				board,
				"CrownPoint",
				V(1.6, x == 0 and 3 or 2.1, 1.8),
				crown.CFrame * CFrame.new(x, 1.6, 0),
				C(255, 208, 58)
			)
		end
		board.WorldPivot = cf
	end
	group.WorldPivot = CFrame.new(oldPosition)
	group.Parent = map
	return group
end

local function getStore(key)
	if not stores[key] then
		stores[key] = DataStoreService:GetOrderedDataStore("StoneSkipping_Top_" .. Config.DataVersion .. "_" .. key)
	end
	return stores[key]
end

function Rankings.record(userId, data)
	if RunService:IsStudio() or userId <= 0 then
		return
	end
	for _, category in categories do
		local value = math.floor(math.clamp(data[category.key] or 0, 0, 1e15))
		local entry = written[userId]
		if entry and entry[category.key] == value then
			continue
		end
		local ok, err = pcall(function()
			getStore(category.key):SetAsync(tostring(userId), value)
		end)
		if not ok then
			warn("Leaderboard save failed for " .. category.key .. ": " .. tostring(err))
		else
			-- Only a write that reached the store counts as written, so a
			-- refused write is retried on the next save.
			remember(userId, category.key, value)
		end
	end
end

function Rankings.render(map, states)
	local group = assert(map:FindFirstChild("LobbyRankings"))
	for _, category in categories do
		local entries = {}
		for _, entry in cached[category.key] or {} do
			entries[entry.userId] = table.clone(entry)
		end
		for player, state in states do
			local data = state.adminOriginal and state.adminOriginal.data or state.data
			if player.Parent then
				entries[player.UserId] =
					{ userId = player.UserId, name = player.DisplayName, value = math.floor(data[category.key] or 0) }
			end
		end
		local sorted = {}
		for _, entry in entries do
			table.insert(sorted, entry)
		end
		table.sort(sorted, function(a, b)
			if a.value == b.value then
				return a.userId < b.userId
			end
			return a.value > b.value
		end)
		local gui = group[category.key].Panel.RankingGui
		gui.Scope.Text = RunService:IsStudio() and "STUDIO • LIVE TOP 10" or "GLOBAL TOP 10"
		for rank = 1, 10 do
			local entry = sorted[rank]
			gui["Row" .. rank].Entry.Text = entry
					and (rank .. ".  " .. (entry.name or names[entry.userId] or ("User " .. entry.userId)) .. "   " .. Config.format(
						entry.value
					) .. (category.suffix or ""))
				or (rank .. ".   —")
		end
		gui.Status.Text = #sorted == 0 and "Be the first to reach the top!"
			or (
				RunService:IsStudio() and "Live session • updates every 10s"
				or (
					cached[category.key] and "Global rankings • refresh every 2 min"
					or "Live server • global rankings loading"
				)
			)
	end
end

function Rankings.start(map, states)
	if started then
		return
	end
	started = true
	Rankings.render(map, states)
	task.spawn(function()
		while map.Parent do
			if not RunService:IsStudio() then
				for _, category in categories do
					local ok, page = pcall(function()
						return getStore(category.key):GetSortedAsync(false, 10, 1)
					end)
					if ok then
						local entries = {}
						for _, record in page:GetCurrentPage() do
							local id = tonumber(record.key)
							if id then
								if not names[id] then
									local found, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
									if found then
										names[id] = name
									end
								end
								table.insert(entries, { userId = id, value = record.value })
							end
						end
						cached[category.key] = entries
					else
						warn("Leaderboard read failed for " .. category.key .. ": " .. tostring(page))
					end
				end
			end
			Rankings.render(map, states)
			task.wait(120)
		end
	end)
	task.spawn(function()
		while map.Parent do
			task.wait(10)
			Rankings.render(map, states)
		end
	end)
end

return Rankings
