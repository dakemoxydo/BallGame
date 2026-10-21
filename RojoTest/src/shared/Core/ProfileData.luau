--!strict
-- Save data contains only JSON values. This module has no engine dependencies.
local Data = {}

-- Every runtime path assumes at most 60 pets, so a stored profile with more
-- is trimmed on load instead of breaking the inventory limits later.
local MAX_PETS = 60

function Data.fresh(): any
	return {
		skill = 0,
		wins = 0,
		rebirths = 0,
		best = 0,
		stone = "Pebble",
		stones = { Pebble = true },
		trail = "None",
		trails = { None = true },
		pets = {},
		equipped = {},
		world = 1,
		unlockedWorld2 = false,
		perks = {},
		receipts = {},
		settings = { sound = 100, music = 100, shake = true, effects = true, hideHUD = false },
		daily = 0,
	}
end

function Data.finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function bounded(value: any, fallback: number, maximum: number): number
	return if Data.finite(value) then math.clamp(math.floor(value), 0, maximum) else fallback
end

local function flags(value: any): any
	local result = {}
	if type(value) == "table" then
		for key, enabled in value do
			if type(key) == "string" and #key <= 200 and enabled == true then
				result[key] = true
			end
		end
	end
	return result
end

function Data.normalize(input: any, catalog: any): any
	local data = Data.fresh()
	if type(input) ~= "table" then
		return data
	end
	for _, key in { "skill", "wins", "rebirths", "best", "daily" } do
		data[key] = bounded(input[key], 0, 1e15)
	end
	data.stones = flags(input.stones)
	data.trails = flags(input.trails)
	data.stones.Pebble, data.trails.None = true, true
	if type(input.stone) == "string" and catalog.stones[input.stone] and data.stones[input.stone] then
		data.stone = input.stone
	end
	if type(input.trail) == "string" and catalog.trails[input.trail] and data.trails[input.trail] then
		data.trail = input.trail
	end
	data.perks, data.receipts = flags(input.perks), flags(input.receipts)
	data.world = if input.world == 2 then 2 else 1
	data.unlockedWorld2 = input.unlockedWorld2 == true or data.world == 2
	local seen = {}
	if type(input.pets) == "table" then
		for _, pet in ipairs(input.pets) do
			if #data.pets >= MAX_PETS then
				break
			end
			if
				type(pet) == "table"
				and type(pet.uid) == "string"
				and #pet.uid <= 100
				and not seen[pet.uid]
				and type(pet.id) == "string"
				and catalog.pets[pet.id]
			then
				local definition = catalog.pets[pet.id]
				seen[pet.uid] = true
				table.insert(data.pets, {
					uid = pet.uid,
					id = pet.id,
					name = definition.name,
					rarity = definition.rarity,
					boost = if Data.finite(pet.boost) then math.clamp(pet.boost, 1, 1e9) else 1,
				})
			end
		end
	end
	if type(input.equipped) == "table" then
		local equipped = {}
		for _, uid in ipairs(input.equipped) do
			if type(uid) == "string" and seen[uid] and not equipped[uid] and #data.equipped < 3 then
				equipped[uid] = true
				table.insert(data.equipped, uid)
			end
		end
	end
	if type(input.settings) == "table" then
		for _, key in { "sound", "music" } do
			data.settings[key] = bounded(input.settings[key], 100, 100)
		end
		for _, key in { "shake", "effects", "hideHUD" } do
			if type(input.settings[key]) == "boolean" then
				data.settings[key] = input.settings[key]
			end
		end
	end
	return data
end

-- The old store is read only. Never import a profile still leased by an old server.
function Data.legacy(record: any, now: number): (any, string?)
	if record == nil then
		return nil, nil
	end
	if type(record) ~= "table" or type(record.data) ~= "table" then
		return nil, "Malformed legacy profile"
	end
	if record.owner ~= nil and (not Data.finite(record.expires) or record.expires > now) then
		return nil, "Legacy profile still has an active session"
	end
	return record.data, nil
end

return Data
