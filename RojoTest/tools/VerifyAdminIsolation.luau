-- Run in Edit. Uses plain mock state; never touches player saves or currency.
local source = game.ServerScriptService.Server.AdminService:Clone()
source.Name = "AdminIsolationCheck"
source.Parent = game.ServerScriptService.Server
local Service = require(source)
source:Destroy()
local Access = require(game.ServerScriptService.Server.AdminAccess)
local H = game:GetService("HttpService")
local owner = { UserId = 11792184677 }
local original = {
	wins = 17,
	skill = 23,
	rebirths = 1,
	pets = {},
	equipped = {},
	world = 1,
	stone = "Pebble",
	stones = { Pebble = true },
	trail = "None",
	trails = { None = true },
	perks = {},
	receipts = {},
	settings = {},
}
local gifts = { [2] = true }
local state = {
	data = original,
	gifts = gifts,
	joined = 12,
	sessionOnly = false,
	saving = false,
	busyUntil = 0,
	-- The service counts the version of the inventory, the mock has to carry it.
	inventoryVersion = 0,
}
local states = { [owner] = state }
local context = {
	states = states,
	stopTraining = function() end,
	rootFor = function()
		return nil
	end,
	publish = function() end,
	effect = { FireClient = function() end },
}
-- The mock carries the same fields as the real service: without the
-- counters the rate limiter of the handle path has nothing to count, and
-- without the secrets the log of the service has nothing to mask.
local service = setmetatable({ context = context, logs = {}, last = {}, counters = {}, secrets = {} }, Service)
local before = H:JSONEncode(original)
assert(Access.isAuthorized(owner.UserId))
assert(not Access.isAuthorized(0) and not Access.isAuthorized("11792184677"))
-- The handle path of an authorised player: the command is counted by the
-- rate limiter and the answer carries the message of the service.
local answered = service:handle(owner, "Status")
assert(answered.ok, "The admin service must answer an authorised player")
assert(answered.message == "Панель готова.", "Unexpected message of the admin status")
assert(
	service.counters[owner] and service.counters[owner].count == 1,
	"The rate limiter must count the command of the player"
)
assert(not service:handle({ UserId = 1234 }, "Begin").ok)
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "wins", amount = 99 }))
service:dispatch(owner, "Begin")
assert(state.data ~= original and state.gifts ~= gifts)
service:dispatch(owner, "SetStat", { key = "wins", amount = 1000000 })
assert(state.data.wins == 1000000 and original.wins == 17)
state.data.receipts.fakeReceipt = true
state.gifts[1] = true
local persisted, sessionOnly = Service.persistence(state)
assert(persisted == original and sessionOnly == false, "Live saves must refresh the original lease, not test data")
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "wins", amount = math.huge }))
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "wins", amount = 0 / 0 }))
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "wins", amount = -1 }))
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "adminOriginal", amount = 1 }))
service:restore(owner, false)
assert(state.data == original and state.gifts == gifts and state.joined == 12 and state.sessionOnly == false)
assert(not state.adminOriginal and not state.data.receipts.fakeReceipt and not state.gifts[1])
assert(H:JSONEncode(original) == before)
return {
	unauthorizedDenied = true,
	authorisedStatus = true,
	mutationRequiresSandbox = true,
	invalidStatsDenied = true,
	originalPersistence = true,
	rollback = true,
}
