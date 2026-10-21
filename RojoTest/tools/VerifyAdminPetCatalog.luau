-- Mock test session; never touches real player data or currency.
local server = game.ServerScriptService.Server
local source = server.AdminService:Clone()
source.Parent = server
local Service = require(source)
source:Destroy()
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local owner = { UserId = 11792184677 }
local original = {
	wins = 123,
	skill = 0,
	rebirths = 0,
	pets = {},
	equipped = {},
	world = 1,
	stone = "Pebble",
	stones = { Pebble = true },
	trail = "None",
	trails = { None = true },
	perks = {},
	settings = {},
}
local state = {
	data = original,
	gifts = {},
	joined = 0,
	sessionOnly = false,
	saving = false,
	busyUntil = 0,
	-- The service counts the version of the inventory, the mock has to carry it.
	inventoryVersion = 0,
}
local hatchCalls, opened = {}, {}
local context = {
	states = { [owner] = state },
	stopTraining = function() end,
	rootFor = function()
		return nil
	end,
	publish = function() end,
	equipBest = function() end,
	effect = {
		FireClient = function(_, _, kind, value)
			if kind == "Egg" then
				table.insert(opened, value)
			end
		end,
	},
	hatch = function(_, egg, count, testing)
		assert(testing)
		table.insert(hatchCalls, { egg = egg, count = count })
	end,
}
local service = setmetatable({ context = context, logs = {}, last = {}, busy = {} }, Service)
local checks = 0
local function check(ok, message)
	assert(ok, message)
	checks += 1
end
check(not pcall(service.dispatch, service, owner, "GiveEggPets", "Rainbow"), "Requires test mode")
service:dispatch(owner, "Begin")
for world = 1, 2 do
	state.data.world = world
	state.data.pets = {}
	for _, egg in Config.Eggs do
		local pool = Config.eggPets(egg.id)
		local first = #state.data.pets
		service:dispatch(owner, "GiveEggPets", egg.id)
		check(#state.data.pets == first + #pool, "Full pool grant count")
		for i, p in pool do
			local granted = state.data.pets[first + i]
			check(
				granted.id == p.id and granted.boost == p.boost * egg.boost * (world == 2 and 3 or 1),
				"Pool grant matches hatch boost"
			)
		end
		service:dispatch(owner, "GivePet", { egg = egg.id, pet = pool[1].id })
		check(
			state.data.pets[#state.data.pets].boost == pool[1].boost * egg.boost * (world == 2 and 3 or 1),
			"Individual grant matches selected egg"
		)
		for _, count in { 1, 3 } do
			service:dispatch(owner, "Hatch", { egg = egg.id, count = count })
			local call = hatchCalls[#hatchCalls]
			check(call.egg == egg.id and call.count == count, "Selected egg used for test hatching")
		end
		service:dispatch(owner, "Egg", egg.id)
		check(opened[#opened] == egg.id, "Selected egg preview")
	end
end
local before = #state.data.pets
for _, entry in
	{
		{ "GivePet", { egg = "Common", pet = "CrystalCat" } },
		{ "GiveEggPets", "Unknown" },
		{ "Hatch", { egg = "Rainbow", count = 2 } },
		{ "Hatch", { egg = "Unknown", count = 1 } },
	}
do
	check(not pcall(service.dispatch, service, owner, entry[1], entry[2]), "Invalid catalog request rejected")
	check(#state.data.pets == before, "Invalid request leaves inventory unchanged")
end
state.data.pets = {}
for _ = 1, 59 do
	table.insert(state.data.pets, { id = "Dog" })
end
check(not pcall(service.dispatch, service, owner, "GiveEggPets", "Rainbow"), "Reject a whole batch beyond capacity")
check(#state.data.pets == 59, "Capacity failure does not partially grant a pool")
state.data.pets = {}
service:dispatch(owner, "GivePet", "AdminDragon")
check(state.data.pets[1].id == "AdminDragon" and state.data.pets[1].boost == 75, "Special pet remains grantable")
service:restore(owner, false)
check(state.data == original and #original.pets == 0 and original.wins == 123, "Original progress restored")
return { checks = checks, eggs = #Config.Eggs, worlds = 2, hatchCalls = #hatchCalls, rollback = true }
