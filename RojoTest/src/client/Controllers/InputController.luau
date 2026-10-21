--!strict
-- Keyboard and gamepad input for the legacy HUD.
-- The module owns its connections so the controller can drop them on teardown.
local UserInputService = game:GetService("UserInputService")

local Input = {}

export type Context = {
	player: Player,
	send: (string, any?, any?) -> (),
	openPanel: (string) -> (),
	closePanel: () -> (),
	panel: () -> string?,
	clearHatch: () -> (),
	snapshot: () -> any?,
	activeEgg: () -> string,
	eggName: (string) -> string,
	hatch: (string, number) -> (),
}

export type Handle = {
	destroy: () -> (),
}

function Input.mount(context: Context): Handle
	local player = context.player
	local began = UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or player:GetAttribute("MapIntroActive") then
			return
		end
		local panel = context.panel()
		local egg = context.activeEgg()
		local eggName = context.eggName(egg)
		local snapshot = context.snapshot()
		if input.KeyCode == Enum.KeyCode.Escape and panel then
			context.clearHatch()
			context.closePanel()
		elseif panel == "Volcanic Inferno Egg" and input.KeyCode == Enum.KeyCode.E then
			context.send("Product", "AdminEgg")
		elseif panel == eggName and input.KeyCode == Enum.KeyCode.E then
			context.hatch(egg, 1)
		elseif panel == eggName and input.KeyCode == Enum.KeyCode.R then
			context.hatch(egg, 3)
		elseif
			not panel
			and snapshot
			and snapshot.canThrow
			and (input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX)
		then
			context.send("Throw")
		elseif not panel and input.KeyCode == Enum.KeyCode.G then
			context.openPanel("Gifts")
		end
	end)
	local jump = UserInputService.JumpRequest:Connect(function()
		local snapshot = context.snapshot()
		if snapshot and snapshot.training then
			context.send("StopTraining")
		end
	end)
	return {
		destroy = function()
			began:Disconnect()
			jump:Disconnect()
		end,
	}
end

return Input
