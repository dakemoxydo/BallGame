--!strict
-- The Update payload has two independent parts.
-- `data` carries the progress that changes on every tick and travels with it.
-- `inventory` carries the pet list and the equipped slots and is sent only when
-- the inventory changed, so sixty pets are not re-sent twice a second.
-- The client keeps the last known inventory and replaces it as soon as a
-- payload carries a fresh one, so every reader sees one stable shape.
local Snapshot = {}

export type Inventory = {
	pets: { any },
	equipped: { string },
}

local inventory: Inventory = { pets = {}, equipped = {} }
local current: any = nil

local function adopt(pets: any, equipped: any)
	if type(pets) == "table" then
		inventory.pets = pets
	end
	if type(equipped) == "table" then
		inventory.equipped = equipped
	end
end

function Snapshot.apply(payload: any): any
	assert(type(payload) == "table", "Update payload must be a table")
	local data = payload.data
	if type(data) == "table" then
		-- Older servers carried the inventory inside the progress table.
		adopt(data.pets, data.equipped)
		data.pets = nil
		data.equipped = nil
	end
	local incoming = payload.inventory
	if type(incoming) == "table" then
		adopt(incoming.pets, incoming.equipped)
	end
	payload.inventory = inventory
	current = payload
	return payload
end

function Snapshot.inventory(): Inventory
	return inventory
end

function Snapshot.pets(): { any }
	return inventory.pets
end

function Snapshot.equipped(): { string }
	return inventory.equipped
end

function Snapshot.current(): any
	return current
end

return Snapshot
