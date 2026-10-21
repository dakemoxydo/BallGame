--!strict
-- The Update payload has two independent parts.
-- `data` carries the progress that changes on every tick and travels with it.
-- `inventory` carries the pet list and the equipped slots and is sent only
-- when the inventory changed, so 60 pets are not re-sent 2.5 times a second.
-- This module reads the state it is given and never mutates it: the caller
-- owns the inventory versions.
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallPurchases = require(game.ReplicatedStorage.Shared.BallPurchases)
local AdminAccess = require(script.Parent.Parent.AdminAccess)

local Snapshot = {}

export type Context = {
	states: { [Player]: any },
	multiplier: (any) -> number,
	inApron: (Player) -> boolean,
	arenaFor: (Player) -> any,
}

function Snapshot.build(context: Context, player: Player, notice: string?, forceInventory: boolean?): any
	local s = context.states[player]
	local d = s.data
	local level, rebirthRequiredLevel, rebirthProgress = Config.rebirthProgress(d.skill, d.rebirths)
	local view = table.clone(d)
	view.receipts = nil
	view.pets = nil
	view.equipped = nil
	local payload: any = {
		data = view,
		level = level,
		multiplier = context.multiplier(s),
		canThrow = context.inApron(player) and os.clock() >= s.busyUntil,
		rebirthRequiredLevel = rebirthRequiredLevel,
		rebirthProgress = rebirthProgress,
		rebirthReady = level >= rebirthRequiredLevel,
		training = s.lane,
		trainingStarted = s.trainingStarted,
		shotDistance = Config.shotDistance(d.skill, BallPurchases.power(d), d.world, context.arenaFor(player)),
		auto = s.auto,
		friendBoost = s.friends * 10,
		elapsed = math.floor(os.clock() - s.joined),
		gifts = s.gifts,
		notice = notice,
		nextLevel = Config.threshold(math.min(level + 1, Config.MaxLevel), d.rebirths),
		levelStart = Config.threshold(level, d.rebirths),
		isAdmin = AdminAccess.isAuthorized(player.UserId),
		adminTest = s.adminOriginal ~= nil,
	}
	-- The inventory travels only when it changed. A forced snapshot sends it
	-- anyway, so a client that lost its cache can ask for the pets again.
	if forceInventory or s.inventoryVersion ~= s.sentInventoryVersion then
		payload.inventory = { pets = d.pets, equipped = d.equipped }
	end
	return payload
end

return Snapshot
