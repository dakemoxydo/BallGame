--!strict
-- The Action remote carries player intents only. Every price, reward and
-- requirement is decided here on the server from the authoritative state.
local MarketplaceService = game:GetService("MarketplaceService")
local Net = require(game.ReplicatedStorage.Shared.Net)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallPurchases = require(game.ReplicatedStorage.Shared.BallPurchases)

local Commands = {}

export type Context = {
	action: RemoteEvent,
	states: { [Player]: any },
	publish: (Player, string?, boolean?) -> (),
	throw: (Player, number?) -> (),
	hatch: (Player, string, number?, boolean?) -> (),
	purchaseItem: (Player, any, string, string, string) -> (),
	rebirth: (Player, boolean?) -> boolean,
	equipBest: (any) -> (),
	stopTraining: (Player, boolean?) -> (),
}

function Commands.install(context: Context)
	context.action.OnServerEvent:Connect(function(player, command, value, extra)
		local s = context.states[player]
		if not s or not Net.validAction(command, value, extra) then
			return
		end
		local now = os.clock()
		s.tokens = math.min(12, s.tokens + (now - s.lastAction) * 8)
		s.lastAction = now
		if s.tokens < 1 then
			return
		end
		s.tokens -= 1
		if command == "Snapshot" then
			-- The client asks for the state it lost, so the inventory travels
			-- with it even when nothing changed.
			context.publish(player, nil, true)
		elseif command == "Throw" then
			context.throw(player)
		elseif command == "Auto" then
			if s.data.perks.AutoThrow then
				s.auto = not s.auto
				context.publish(player)
			else
				context.publish(player, "Auto Throw unlocks from the shop")
			end
		elseif command == "StopTraining" then
			context.stopTraining(player, true)
			s.stopUntil = now + 0.5
			context.publish(player)
		elseif command == "Rebirth" then
			context.rebirth(player, false)
		elseif command == "Stone" and type(value) == "string" then
			if now < s.busyUntil then
				context.publish(player, "Wait for your throw to finish")
			else
				local _, message = BallPurchases.buyOrEquip(s.data, value)
				context.publish(player, message)
			end
		elseif command == "Trail" and type(value) == "string" then
			context.purchaseItem(player, Config.Trails, "trails", "trail", value)
		elseif command == "Hatch" and type(value) == "string" then
			context.hatch(player, value, extra)
		elseif command == "EquipBest" then
			context.equipBest(s)
			context.publish(player)
		elseif command == "UnequipAll" then
			s.data.equipped = {}
			s.inventoryVersion += 1
			context.publish(player)
		elseif (command == "Pet" or command == "DeletePet") and type(value) == "string" then
			-- The pet is looked up first and removed afterwards: a list that
			-- is changed while it is read would skip a pet.
			local index: number? = nil
			for position, pet in s.data.pets do
				if pet.uid == value then
					index = position
					break
				end
			end
			if index then
				local slot = table.find(s.data.equipped, value)
				if command == "DeletePet" then
					if slot then
						table.remove(s.data.equipped, slot)
					end
					table.remove(s.data.pets, index)
				elseif slot then
					table.remove(s.data.equipped, slot)
				elseif #s.data.equipped < 3 then
					table.insert(s.data.equipped, value)
				else
					context.publish(player, "Equip up to 3 pets")
					return
				end
				s.inventoryVersion += 1
				context.publish(player)
			else
				context.publish(player, "That pet is not in your inventory")
			end
		elseif command == "Gift" and type(value) == "number" and value == math.floor(value) then
			local gift = Config.Gifts[value]
			if not gift then
				context.publish(player, "Unknown gift")
			elseif s.gifts[value] then
				context.publish(player, "Gift already claimed")
			elseif now - s.joined < gift.time then
				context.publish(player, "That gift is not available yet")
			else
				s.gifts[value] = true
				s.data.wins += gift.wins
				s.data.skill += gift.skill
				context.publish(player, "Gift claimed!")
			end
		elseif command == "Daily" then
			local day = math.floor(os.time() / 86400)
			if s.data.daily < day then
				s.data.daily = day
				s.data.wins += 500
				s.data.skill += 100
				context.publish(player, "Daily gift: +500 Wins +100 Skill")
			else
				context.publish(player, "Daily gift already claimed")
			end
		elseif command == "Setting" and type(value) == "string" then
			if (value == "sound" or value == "music") and type(extra) == "number" and extra == extra then
				s.data.settings[value] = math.clamp(math.floor(extra), 0, 100)
			elseif (value == "shake" or value == "effects" or value == "hideHUD") and type(extra) == "boolean" then
				s.data.settings[value] = extra
			end
			context.publish(player)
		elseif command == "Product" and type(value) == "string" then
			if s.adminOriginal then
				context.publish(
					player,
					"Заверши тестовый режим перед покупкой за Robux."
				)
				return
			end
			local product = Config.Products[value]
			if not product then
				context.publish(player, "Unknown product")
				return
			end
			if s.data.perks[value] then
				context.publish(player, "Already owned")
				return
			end
			if product.id == 0 then
				context.publish(player, "This purchase is not available yet")
			else
				MarketplaceService:PromptProductPurchase(player, product.id)
			end
		elseif command == "UnlockAuto" then
			if s.data.perks.AutoThrow then
				s.auto = not s.auto
			elseif s.data.wins >= 2500 then
				s.data.wins -= 2500
				s.data.perks.AutoThrow = true
				s.auto = true
			else
				context.publish(player, "Need 2.5K Wins for Auto Throw")
				return
			end
			context.publish(player)
		end
	end)
end

return Commands
