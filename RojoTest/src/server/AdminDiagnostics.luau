--!strict
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Diagnostics = {}
function Diagnostics.run(map)
	local rows = {}
	local function check(title, callback)
		local ok, result = pcall(callback)
		local detail
		if ok then
			detail = result or "Готово"
		else
			-- An empty message has no last line: keep the whole text instead of
			-- indexing nil, which would abort the whole panel.
			local message = tostring(result)
			local lastLine = message:match("[^\n]+$") or message
			detail = (lastLine:gsub("^.-:%d+: ", ""))
		end
		table.insert(rows, {
			ok = ok,
			title = title,
			detail = detail,
		})
	end
	check("Длина и стыки 8 биомов", function()
		local front = map:GetAttribute("RouteFrontZ")
		assert(front, "Нет начала маршрута")
		for i = 1, 8 do
			local p = map.SkippingWorld:FindFirstChild("Water_" .. i)
			assert(p and math.abs(p.Size.Z - 270) < 0.02, "Биом " .. i .. ": неверная длина")
			assert(math.abs(p.Position.Z - (front - (i - 0.5) * 270)) < 0.02, "Щель у биома " .. i)
		end
		return "8 × 270 studs; весь маршрут 2160 studs"
	end)
	check("Опоры берегов", function()
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { map.WaterCorridor, map.SkippingWorld }
		local count = 0
		for _, p in map.SkippingWorld:GetChildren() do
			if p.Name:match("^BiomeBank%d_[12]$") then
				local top = p.Position.Y + p.Size.Y / 2
				for _, t in { -0.44, 0, 0.44 } do
					local hit = workspace:Raycast(
						Vector3.new(p.Position.X, top + 0.05, p.Position.Z + p.Size.Z * t),
						Vector3.new(0, -2, 0),
						rp
					)
					assert(hit and math.abs(hit.Position.Y - top) < 0.4, "Нет опоры: " .. p.Name)
					count += 1
				end
			end
		end
		assert(count == 96, "Не все берега найдены")
		return "96 точек без провалов"
	end)
	check("Состав всех яиц", function()
		for _, egg in Config.Eggs do
			local pool = Config.eggPets(egg.id)
			assert(#pool > 0, "Нет петов в " .. egg.name)
			local total, counts = 0, {}
			for _, p in pool do
				total += p.weight
				assert(not counts[p.id], "Повтор пета")
				counts[p.id] = 0
			end
			assert(total == 100, "Шансы не равны 100%")
			for roll = 1, 100 do
				local id = Config.rollEggPet(egg.id, roll).id
				assert(counts[id] ~= nil, "Unknown egg outcome")
				counts[id] += 1
			end
			for _, p in pool do
				assert(counts[p.id] == p.weight, "Неверный шанс " .. p.id)
			end
		end
		return #Config.Eggs .. " яйца; все исходы проверены"
	end)
	check("Модели петов", function()
		local folder = game.ReplicatedStorage.Shared.PetTemplates
		local seen, count = {}, 0
		for _, egg in Config.Eggs do
			for _, pet in Config.eggPets(egg.id) do
				if pet.visual and not seen[pet.visual] then
					seen[pet.visual] = true
					count += 1
					local m = folder:FindFirstChild(pet.visual)
					local p = m and m:FindFirstChildWhichIsA("MeshPart", true)
					assert(p and p.MeshId ~= "" and p.MeshSize.Magnitude > 0, "Не загружен " .. pet.id)
					assert(not p.CanCollide and not p.CanTouch and not p.CanQuery, "Коллизии " .. pet.id)
				end
			end
		end
		return "Загружено мешей: " .. count .. "; коллизии выключены"
	end)
	check("7 тренировочных площадок", function()
		for i = 1, 7 do
			local lane = map.TrainingZone:FindFirstChild("TrainingLane" .. i)
			assert(
				lane and lane:FindFirstChild("StartingPad") and lane:FindFirstChild("TrainingStrip"),
				"Площадка " .. i .. " неполная"
			)
		end
		return "Маркеры и полосы на месте"
	end)
	check("Мячи и трейлы", function()
		for _, ball in Config.Stones do
			assert(game.ReplicatedStorage.Shared.BallTemplates:FindFirstChild(ball.id), "Нет мяча " .. ball.id)
		end
		return #Config.Stones .. " мячей; " .. #Config.Trails .. " трейлов"
	end)
	check("Финальная арка сакуры", function()
		local root = map.SkippingWorld:FindFirstChild("SakuraJapaneseFinale")
		assert(
			root and root:FindFirstChild("SakuraGatewayFrame") and root:FindFirstChild("SakuraPortalPanorama"),
			"Нет арки или панорамы"
		)
		return "Декор на месте; телепортация пока не подключена"
	end)
	check("Дальность броска", function()
		local limit = Config.shotLimit(1, map)
		assert(Config.shotDistance(1000000, 1, 1, map) == limit, "World 1 endpoint mismatch")
		assert(
			Config.shotDistance(100000, 1, 1, map) > Config.shotDistance(10000, 1, 1, map) * 2.5,
			"Shot progression mismatch"
		)
		assert(Config.shotDistance(100000000, 1, 2) == Config.shotLimit(2), "World 2 endpoint mismatch")
		return "Пороги: 1 млн / 100 млн силы; World 1: " .. limit .. " м"
	end)
	check("Платные продукты", function()
		local missing = 0
		for _, p in Config.Products do
			if p.id == 0 then
				missing += 1
			end
		end
		assert(missing == 0, "Не настроены ID продуктов: " .. missing)
		return "ID продуктов заданы"
	end)
	return rows
end
return Diagnostics
