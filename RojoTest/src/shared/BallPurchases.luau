--!strict
local Config = require(script.Parent.GameConfig)
local Purchases = {}

-- Prices and ownership are read from server-owned data, never from the client.
function Purchases.buyOrEquip(data, id)
	local item = Config.find(Config.Stones, id)
	if not item then
		return false, "Unknown ball"
	end
	local owned = data.stones[id] == true
	if not owned and data.wins < item.cost then
		return false, "Need " .. Config.format(item.cost) .. " Crowns"
	end
	if not owned then
		data.wins -= item.cost
		data.stones[id] = true
	end
	data.stone = id
	return true, item.name .. " equipped!"
end

function Purchases.power(data)
	local item = Config.find(Config.Stones, data.stone)
	return item and data.stones[item.id] == true and item.power or 1
end

return Purchases
