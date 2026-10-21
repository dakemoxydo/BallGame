--!strict
-- Net.validAction is the only door into the server command handler, so every
-- command family has to be pinned here. A loosened guard turns into a remote
-- that buys, hatches or gifts without paying.
local Net = require("../src/shared/Net")

local function check(condition: any, message: string)
	assert(condition, "Net invariant failed: " .. message)
end

-- The command tables of Net.luau: nine payload free commands, five commands
-- that carry a single identifier and the three special ones.
local SIMPLE = {
	"Snapshot",
	"Throw",
	"Auto",
	"StopTraining",
	"Rebirth",
	"EquipBest",
	"UnequipAll",
	"Daily",
	"UnlockAuto",
}
local IDENTIFIERS = { "Stone", "Trail", "Pet", "DeletePet", "Product" }

local function dummy() end

return {
	["a command has to be a short string"] = function()
		for _, bad in { 1, true, {}, dummy } do
			local ok, result = pcall(Net.validAction, bad, nil, nil)
			check(ok and result == false, "A command that is not a string is rejected")
		end
		local ok, result = pcall(Net.validAction, nil, nil, nil)
		check(ok and result == false, "A missing command is rejected")
		check(not Net.validAction("", nil, nil), "An empty command is rejected")
		check(not Net.validAction(string.rep("a", 33), nil, nil), "A command over 32 characters is rejected")
		check(not Net.validAction(string.rep("a", 32) .. "Throw", nil, nil), "A padded command is rejected")
	end,
	["payload free commands accept an empty request only"] = function()
		for _, command in SIMPLE do
			check(Net.validAction(command, nil, nil), command .. " is accepted without a payload")
			check(not Net.validAction(command, false, nil), command .. " rejects false as a value")
			check(not Net.validAction(command, 0, nil), command .. " rejects zero as a value")
			check(not Net.validAction(command, "", nil), command .. " rejects an empty string")
			check(not Net.validAction(command, {}, nil), command .. " rejects a table")
			check(not Net.validAction(command, nil, 0), command .. " rejects zero as an extra")
			check(not Net.validAction(command, nil, false), command .. " rejects false as an extra")
			check(not Net.validAction(command, nil, "1"), command .. " rejects a string as an extra")
			check(not Net.validAction(command, "x", "y"), command .. " rejects a payload")
		end
	end,
	["identifier commands accept one bounded string and nothing else"] = function()
		for _, command in IDENTIFIERS do
			check(Net.validAction(command, "Pebble", nil), command .. " accepts a plain identifier")
			check(Net.validAction(command, string.rep("x", 100), nil), command .. " accepts the longest identifier")
			check(not Net.validAction(command, string.rep("x", 101), nil), command .. " rejects a longer identifier")
			check(not Net.validAction(command, 1, nil), command .. " rejects a number")
			check(not Net.validAction(command, true, nil), command .. " rejects a boolean")
			check(not Net.validAction(command, {}, nil), command .. " rejects a table")
			check(not Net.validAction(command, nil, nil), command .. " needs an identifier")
			check(not Net.validAction(command, "Pebble", 1), command .. " rejects an extra")
			check(not Net.validAction(command, "Pebble", false), command .. " rejects false as an extra")
			check(not Net.validAction(command, "Pebble", {}), command .. " rejects a table as an extra")
		end
	end,
	["hatch accepts an egg id and the allowed multipliers"] = function()
		check(Net.validAction("Hatch", "Rare", nil), "A hatch without a multiplier is accepted")
		check(Net.validAction("Hatch", "Rare", 1), "A single hatch is accepted")
		check(Net.validAction("Hatch", "Rare", 3), "A triple hatch is accepted")
		check(not Net.validAction("Hatch", "Rare", 0), "A zero multiplier is rejected")
		check(not Net.validAction("Hatch", "Rare", 2), "A double multiplier is rejected")
		check(not Net.validAction("Hatch", "Rare", 4), "A quadruple multiplier is rejected")
		check(not Net.validAction("Hatch", "Rare", -1), "A negative multiplier is rejected")
		check(not Net.validAction("Hatch", "Rare", "1"), "A string multiplier is rejected")
		check(not Net.validAction("Hatch", "Rare", true), "A boolean multiplier is rejected")
		check(not Net.validAction("Hatch", "Rare", {}), "A table multiplier is rejected")
		check(Net.validAction("Hatch", string.rep("x", 100), 1), "The longest egg id is accepted")
		check(not Net.validAction("Hatch", string.rep("x", 101), 1), "A longer egg id is rejected")
		check(not Net.validAction("Hatch", 1, 1), "A numeric egg id is rejected")
		check(not Net.validAction("Hatch", nil, 1), "A missing egg id is rejected")
	end,
	["gift accepts whole gift counts from one to six"] = function()
		for count = 1, 6 do
			check(Net.validAction("Gift", count, nil), "The gift " .. count .. " is accepted")
		end
		check(not Net.validAction("Gift", 0, nil), "The gift zero is rejected")
		check(not Net.validAction("Gift", 7, nil), "The gift seven is rejected")
		check(not Net.validAction("Gift", -1, nil), "A negative gift is rejected")
		check(not Net.validAction("Gift", 1.5, nil), "A fractional gift is rejected")
		check(not Net.validAction("Gift", 3.5, nil), "A fractional gift is rejected")
		check(not Net.validAction("Gift", 0 / 0, nil), "A broken gift count is rejected")
		check(not Net.validAction("Gift", math.huge, nil), "An infinite gift count is rejected")
		check(not Net.validAction("Gift", "3", nil), "A string gift count is rejected")
		check(not Net.validAction("Gift", nil, nil), "A missing gift count is rejected")
		check(not Net.validAction("Gift", 3, 1), "A gift with an extra is rejected")
		check(not Net.validAction("Gift", 3, false), "A gift with a false extra is rejected")
	end,
	["volume settings accept a finite number"] = function()
		check(Net.validAction("Setting", "sound", 100), "The loudest sound volume is accepted")
		check(Net.validAction("Setting", "sound", 0), "The silent sound volume is accepted")
		check(Net.validAction("Setting", "music", 50), "The music volume is accepted")
		check(Net.validAction("Setting", "music", 100), "The loudest music volume is accepted")
		check(not Net.validAction("Setting", "sound", 0 / 0), "A broken sound volume is rejected")
		check(not Net.validAction("Setting", "music", 0 / 0), "A broken music volume is rejected")
		check(not Net.validAction("Setting", "sound", math.huge), "An infinite sound volume is rejected")
		check(not Net.validAction("Setting", "music", -math.huge), "An endless music volume is rejected")
		check(not Net.validAction("Setting", "sound", true), "A boolean sound volume is rejected")
		check(not Net.validAction("Setting", "music", "50"), "A string music volume is rejected")
		check(not Net.validAction("Setting", "sound", nil), "A missing sound volume is rejected")
		check(not Net.validAction("Setting", "music", {}), "A table music volume is rejected")
	end,
	["toggle settings accept a boolean"] = function()
		check(Net.validAction("Setting", "shake", true), "The shake toggle is accepted")
		check(Net.validAction("Setting", "shake", false), "The shake toggle is accepted when it is off")
		check(Net.validAction("Setting", "effects", true), "The effects toggle is accepted")
		check(Net.validAction("Setting", "effects", false), "The effects toggle is accepted when it is off")
		check(Net.validAction("Setting", "hideHUD", true), "The hide HUD toggle is accepted")
		check(Net.validAction("Setting", "hideHUD", false), "The hide HUD toggle is accepted when it is off")
		check(not Net.validAction("Setting", "shake", 1), "A number is not a shake toggle")
		check(not Net.validAction("Setting", "shake", 0), "A zero is not a shake toggle")
		check(not Net.validAction("Setting", "effects", "true"), "A string is not an effects toggle")
		check(not Net.validAction("Setting", "hideHUD", 1), "A number is not a hide HUD toggle")
		check(not Net.validAction("Setting", "hideHUD", nil), "A missing hide HUD value is rejected")
	end,
	["unknown settings keys and unknown commands are rejected"] = function()
		check(not Net.validAction("Setting", "volume", 50), "An unknown volume key is rejected")
		check(not Net.validAction("Setting", "Sound", 50), "The setting keys are case sensitive")
		check(not Net.validAction("Setting", "hidehud", true), "The setting keys are case sensitive")
		check(not Net.validAction("Setting", nil, false), "A missing setting key is rejected")
		check(not Net.validAction("Setting", 1, false), "A numeric setting key is rejected")
		local unknown = {
			"throw",
			"THROW",
			"Throws",
			"throw ",
			"Snapshot ",
			"Pet ",
			"Pets",
			"DeletePets",
			"Products",
			"Gifts",
			"Hatches",
			"Settings",
			"Setting ",
			"UnlockAutoThrow",
			"StopTraining2",
		}
		for _, command in unknown do
			check(not Net.validAction(command, nil, nil), "The unknown command " .. command .. " is rejected")
		end
	end,
	["every command of the protocol has a valid request"] = function()
		for _, command in SIMPLE do
			check(Net.validAction(command, nil, nil), command .. " has a valid request")
		end
		for _, command in IDENTIFIERS do
			check(Net.validAction(command, "Pebble", nil), command .. " has a valid request")
		end
		check(Net.validAction("Hatch", "Rare", 1), "Hatch has a valid request")
		check(Net.validAction("Gift", 1, nil), "Gift has a valid request")
		check(Net.validAction("Setting", "sound", 50), "Setting has a valid request")
	end,
}
