--!strict
local Access = require(script.Parent.AdminAccess)
local Diagnostics = require(script.Parent.AdminDiagnostics)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Economy = require(game.ReplicatedStorage.Shared.Core.Economy)
local Net = require(game.ReplicatedStorage.Shared.Net)
local H = game:GetService("HttpService")
local Service = {}
Service.__index = Service
-- At most this many admin commands per player and per minute.
Service.CommandLimit = 60
Service.CommandWindow = 60
-- The messages of this game carry this prefix. It is a mark and not a
-- filter: a script error arrives as "<path>:<line>: <text>".
Service.LogPrefix = "[Ball"
local function copy(value)
	return H:JSONDecode(H:JSONEncode(value))
end

-- Only the identifiers of this game are secret: the user id of a player and
-- the key of his profile. Every other number is a detail of the log and stays
-- readable, a price of a million studs is no secret.
local function redact(text, secrets)
	local masked = text:gsub("Player_%d+", "Player_*")
	for id in pairs(secrets) do
		masked = masked:gsub(id, "*")
	end
	return masked
end

function Service.persistence(state)
	if state.adminOriginal then
		return state.adminOriginal.data, state.adminOriginal.sessionOnly
	end
	return state.data, state.sessionOnly
end

function Service.new(context)
	local self = setmetatable({ context = context, logs = {}, last = {}, counters = {}, secrets = {} }, Service)
	local remote: RemoteFunction? = nil
	-- The admin remote exists only while an authorized player is in the game.
	-- It is created with the first of them and stays for the session.
	local function ensureRemote(): RemoteFunction
		-- The remote is an upvalue of this function, and an upvalue is never
		-- narrowed: the value is read into a local first.
		local existing = remote
		if existing then
			return existing
		end
		local created = Net.admin(context.remotes)
		created.OnServerInvoke = function(player, command, value)
			return self:handle(player, command, value)
		end
		remote = created
		return created
	end
	-- The user ids of the players are the only numbers that leave the server
	-- masked, so they are remembered as soon as a player is seen.
	local players = game:GetService("Players")
	local function remember(player: Player)
		self.secrets[tostring(player.UserId)] = true
	end
	local function admit(player: Player)
		remember(player)
		if Access.isAuthorized(player.UserId) then
			ensureRemote()
		end
	end
	for _, player in ipairs(players:GetPlayers()) do
		admit(player)
	end
	players.PlayerAdded:Connect(admit)
	game:GetService("LogService").MessageOut:Connect(function(message, kind)
		if kind ~= Enum.MessageType.MessageError and kind ~= Enum.MessageType.MessageWarning then
			return
		end
		-- The messages of the game carry its prefix, the errors of the scripts
		-- do not. Both belong into the panel, so the prefix is only a mark.
		local own = string.sub(message, 1, #Service.LogPrefix) == Service.LogPrefix
		-- The buffer never keeps a raw identifier: the message is masked here,
		-- so nothing secret waits in the memory of the server until it is
		-- shown. The output masks once more, for the ids that were unknown
		-- when the message arrived.
		table.insert(self.logs, {
			time = os.date("%H:%M:%S"),
			kind = kind.Name,
			own = own,
			isError = kind.Name == "MessageError",
			message = redact(message:sub(1, 500), self.secrets),
		})
		if #self.logs > 40 then
			table.remove(self.logs, 1)
		end
	end)
	return self
end

function Service:status(player)
	local s = self.context.states[player]
	if not s then
		return nil
	end
	local d = s.data
	local errors = 0
	for _, entry in ipairs(self.logs) do
		if entry.isError then
			errors += 1
		end
	end
	return {
		testing = s.adminOriginal ~= nil,
		wins = d.wins,
		skill = d.skill,
		rebirths = d.rebirths,
		world = d.world,
		pets = #d.pets,
		equipped = #d.equipped,
		shot = Config.shotDistance(
			d.skill,
			require(game.ReplicatedStorage.Shared.BallPurchases).power(d),
			d.world,
			self.context.arenaFor(player)
		),
		studio = game:GetService("RunService"):IsStudio(),
		errors = errors,
	}
end

function Service:restore(player, move)
	local c = self.context
	local s: any = c.states[player]
	if not s or not s.adminOriginal then
		return
	end
	c.stopTraining(player)
	local old = s.adminOriginal
	s.data = old.data
	s.gifts = old.gifts
	s.joined = old.joined
	s.sessionOnly = old.sessionOnly
	s.adminOriginal = nil
	s.auto = false
	s.busyUntil = 0
	s.blockedLane = nil
	s.stopUntil = os.clock() + 0.6
	-- The original pets come back, so the client needs the inventory again.
	s.inventoryVersion += 1
	if move then
		c.effect:FireClient(player, "AdminResetView")
		local root, hum = c.rootFor(player)
		if root and hum and hum.Health > 0 then
			root.CFrame = old.pose or Config.apronCharacterPose(c.arenaFor(player), root, hum, 3)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
	c.publish(player, "Тест завершён. Исходный прогресс восстановлен.")
end

function Service:move(player, target)
	local c = self.context
	local s = c.states[player]
	c.stopTraining(player)
	s.auto = false
	s.busyUntil = 0
	s.blockedLane = nil
	s.stopUntil = os.clock() + 0.6
	local root, hum = c.rootFor(player)
	assert(root and hum and hum.Health > 0, "Персонаж ещё не готов")
	c.effect:FireClient(player, "AdminResetView")
	root.CFrame = target
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

function Service:dispatch(player, command, value)
	local c = self.context
	local s: any = c.states[player]
	assert(s, "Данные игрока ещё загружаются")
	if command == "Status" then
		return "Панель готова."
	elseif command == "Diagnostics" then
		return "Проверки завершены.", Diagnostics.run(c.map)
	elseif command == "Logs" then
		local rows = {}
		for i = #self.logs, 1, -1 do
			local l = self.logs[i]
			table.insert(
				rows,
				{ ok = false, title = l.time .. " · " .. l.kind, detail = redact(l.message, self.secrets) }
			)
		end
		if #rows == 0 then
			rows = {
				{
					ok = true,
					title = "Ошибок сервера нет",
					detail = "Журнал собирается с момента запуска сервера.",
				},
			}
		end
		return "Журнал сервера.", rows
	elseif command == "Begin" then
		assert(not s.adminOriginal, "Тест уже запущен")
		assert(not s.saving, "Идёт сохранение. Повтори через секунду.")
		assert(os.clock() >= s.busyUntil, "Дождись окончания броска.")
		c.stopTraining(player)
		local root = c.rootFor(player)
		s.adminOriginal = {
			data = s.data,
			gifts = s.gifts,
			joined = s.joined,
			sessionOnly = s.sessionOnly,
			pose = root and root.CFrame,
		}
		s.data = copy(s.data)
		s.gifts = table.clone(s.gifts)
		s.sessionOnly = true
		s.auto = false
		s.busyUntil = 0
		s.stopUntil = os.clock() + 0.6
		return "Тестовый режим включён. Изменения не попадут в основной прогресс."
	elseif command == "End" then
		self:restore(player, true)
		return "Исходный прогресс восстановлен."
	end
	assert(s.adminOriginal, "Сначала включи тестовый режим.")
	local d = s.data
	if command == "SetStat" then
		assert(
			type(value) == "table" and ({ wins = true, skill = true, rebirths = true })[value.key],
			"Неизвестный параметр"
		)
		local n = tonumber(value.amount)
		assert(n and n == n and n >= 0 and n <= 1e12, "Введи число от 0 до 1 триллиона")
		if value.key == "rebirths" then
			assert(n <= 10000, "Максимум 10000 rebirths")
		end
		c.stopTraining(player)
		d[value.key] = math.floor(n)
	elseif command == "Unlock" then
		for _, b in Config.Stones do
			d.stones[b.id] = true
		end
		for _, t in Config.Trails do
			d.trails[t.id] = true
		end
		d.rebirths = math.max(16, d.rebirths)
		d.unlockedWorld2 = true
		d.perks.AutoThrow = true
		d.perks.DoubleSkill = true
		d.perks.DoubleWins = true
	elseif command == "Reset" then
		c.stopTraining(player)
		s.data = c.fresh()
		s.gifts = {}
		s.joined = os.clock()
		s.auto = false
		s.busyUntil = 0
		-- A fresh profile has no pets at all.
		s.inventoryVersion += 1
		local root, hum = c.rootFor(player)
		if root and hum then
			self:move(player, Config.apronCharacterPose(c.map, root, hum, 3))
		end
	elseif command == "GivePet" or command == "GiveEggPets" or command == "GreenPets" then
		local pets, egg
		if command == "GiveEggPets" or command == "GreenPets" then
			egg = Config.find(Config.Eggs, command == "GreenPets" and "Uncommon" or value)
			assert(egg, "Неизвестное яйцо")
			pets = Config.eggPets(egg.id)
		elseif type(value) == "table" then
			egg = Config.find(Config.Eggs, value.egg)
			assert(egg, "Неизвестное яйцо")
			pets = { Config.find(Config.eggPets(egg.id), value.pet) }
		else
			pets = { Config.pet(value) }
		end
		assert(#pets > 0 and pets[1], "Неизвестный пет")
		assert(#d.pets + #pets <= 60, "Инвентарь петов заполнен")
		for _, p in pets do
			local boost = p.boost
				* (egg and egg.boost or p.eggBoost or (p.visual and 2 or 1))
				* (d.world == 2 and 3 or 1)
			table.insert(
				d.pets,
				{ uid = H:GenerateGUID(false), id = p.id, name = p.name, rarity = p.rarity, boost = boost }
			)
		end
		c.equipBest(s)
	elseif command == "Egg" then
		assert(Config.find(Config.Eggs, value), "Неизвестное яйцо")
		c.effect:FireClient(player, "Egg", value)
	elseif command == "Hatch" then
		local count = type(value) == "table" and value.count or value
		local egg = Config.find(Config.Eggs, type(value) == "table" and value.egg or "Uncommon")
		assert(egg, "Неизвестное яйцо")
		assert(count == 1 or count == 3, "Выбери 1 или 3 яйца")
		assert(#d.pets + count <= 60, "Инвентарь петов заполнен")
		assert(os.clock() >= s.busyUntil, "Дождись окончания броска")
		c.stopTraining(player)
		c.hatch(player, egg.id, count, true)
	elseif command == "Stone" then
		assert(Config.find(Config.Stones, value), "Неизвестный мяч")
		d.stones[value] = true
		d.stone = value
	elseif command == "Trail" then
		assert(Config.find(Config.Trails, value), "Неизвестный трейл")
		d.trails[value] = true
		d.trail = value
	elseif command == "Throw" then
		local limit = Config.shotLimit(d.world, c.arenaFor(player))
		local distance = value == "max" and limit or tonumber(value)
		assert(
			distance and distance == distance and distance >= Economy.ShotDistanceFloor and distance <= limit,
			"Неверная дальность"
		)
		local root, hum = c.rootFor(player)
		assert(root and hum, "Нет персонажа")
		self:move(player, Config.apronCharacterPose(c.arenaFor(player), root, hum, -11))
		c.throw(player, distance)
	elseif command == "Teleport" then
		local root, hum = c.rootFor(player)
		assert(root and hum, "Нет персонажа")
		if value == "World1" or value == "World2" then
			d.world = value == "World2" and 2 or 1
		end
		local map = c.arenaFor(player)
		if value == "Lobby" or value == "World1" or value == "World2" then
			self:move(player, Config.apronCharacterPose(map, root, hum, 3))
		elseif value == "Sakura" then
			d.world = 1
			map = c.map
			local bank
			for _, p in map.SkippingWorld:GetChildren() do
				if p.Name == "BiomeBank8_1" and p.Position.X < map.SkippingWorld.Water_8.Position.X then
					bank = p
					break
				end
			end
			assert(bank, "Нет берега сакуры")
			local h = root.Size.Y / 2 + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight)
			self:move(
				player,
				CFrame.new(
					bank.Position.X,
					bank.Position.Y + bank.Size.Y / 2 + h + 0.2,
					bank.Position.Z - bank.Size.Z / 2 + 35
				)
			)
		else
			local biome = tonumber(value)
			assert(biome and biome % 1 == 0 and biome >= 1 and biome <= 8, "Неизвестный биом")
			local bank
			local water = map.SkippingWorld["Water_" .. biome]
			for _, p in map.SkippingWorld:GetChildren() do
				if p.Name == "BiomeBank" .. biome .. "_2" and p.Position.X < water.Position.X then
					bank = p
					break
				end
			end
			assert(bank, "Нет берега биома")
			local h = root.Size.Y / 2 + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight)
			self:move(
				player,
				CFrame.new(bank.Position.X + 9, bank.Position.Y + bank.Size.Y / 2 + h + 0.2, bank.Position.Z)
			)
		end
	elseif command == "Training" then
		local n = tonumber(value)
		assert(n and n % 1 == 0 and n >= 1 and n <= 7, "Неизвестная площадка")
		local root, hum = c.rootFor(player)
		assert(root and hum, "Нет персонажа")
		local pad = c.arenaFor(player).TrainingZone["TrainingLane" .. n].StartingPad
		local h = root.Size.Y / 2 + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight)
		self:move(player, pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + h + 0.15, 0))
	else
		error("Неизвестная команда")
	end
	return "Готово. Изменена только тестовая сессия."
end

function Service:handle(player, command, value)
	if not Access.isAuthorized(player.UserId) then
		return { ok = false, message = "Нет доступа." }
	end
	if type(command) ~= "string" or #command > 30 then
		return { ok = false, message = "Неверная команда." }
	end
	local now = os.clock()
	-- The short delay is checked first: a command that arrives too early is
	-- dropped anyway, so it must not spend the minute budget of the player.
	if now - (self.last[player] or -math.huge) < 0.18 then
		return { ok = false, message = "Подожди завершения команды." }
	end
	-- The minute budget counts the commands that are really executed. A
	-- spammer still meets the limit, he only has to keep the delay.
	local counter = self.counters[player]
	if not counter or now - counter.window >= Service.CommandWindow then
		counter = { count = 0, window = now }
		self.counters[player] = counter
	end
	if counter.count >= Service.CommandLimit then
		return { ok = false, message = "Слишком много команд. Подожди минуту." }
	end
	counter.count += 1
	self.last[player] = now
	local ok, message, rows = pcall(self.dispatch, self, player, command, value)
	if ok then
		self.context.publish(player)
	end
	return {
		ok = ok,
		message = ok and message or tostring(message):gsub("^.-:%d+: ", ""),
		status = self:status(player),
		rows = rows,
	}
end

return Service
