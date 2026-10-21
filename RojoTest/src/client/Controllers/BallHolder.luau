--!strict
-- The ball in the player's hand and the practice ball on the training lane.
-- Both are rebuilt only when the equipped stone changes, and their
-- transparency is written only when the visibility actually changes.
local BallVisuals = require(game.ReplicatedStorage.Shared.BallVisuals)

local Holder = {}

export type Handle = {
	setStone: (string) -> (),
	setPractice: (string?) -> (),
	held: () -> Model,
	practice: () -> Model?,
	showHeld: (boolean) -> (),
	showPractice: (boolean) -> (),
	destroy: () -> (),
}

function Holder.mount(): Handle
	local held = BallVisuals.create("Pebble", 1.1)
	held.Name = "HeldBall"
	held.Parent = workspace
	local heldId = "Pebble"
	local heldVisible: boolean? = nil
	local practice: Model? = nil
	local practiceVisible: boolean? = nil

	local function showHeld(visible: boolean)
		if heldVisible == visible then
			return
		end
		heldVisible = visible
		BallVisuals.visible(held, visible)
	end

	local function showPractice(visible: boolean)
		if practiceVisible == visible or not practice then
			return
		end
		practiceVisible = visible
		BallVisuals.visible(practice, visible)
	end

	return {
		setStone = function(id: string)
			if heldId == id then
				return
			end
			held:Destroy()
			held = BallVisuals.create(id, 1.1)
			held.Name = "HeldBall"
			held.Parent = workspace
			heldId = id
			heldVisible = nil
		end,
		setPractice = function(id: string?)
			if id == nil then
				if practice then
					practice:Destroy()
				end
				practice = nil
				practiceVisible = nil
				return
			end
			if practice and practice:GetAttribute("BallId") == id then
				return
			end
			if practice then
				practice:Destroy()
			end
			practice = BallVisuals.create(id, 1.6)
			practice.Name = "PracticeBall"
			practice.Parent = workspace
			practiceVisible = nil
		end,
		held = function(): Model
			return held
		end,
		practice = function(): Model?
			return practice
		end,
		showHeld = showHeld,
		showPractice = showPractice,
		destroy = function()
			held:Destroy()
			if practice then
				practice:Destroy()
			end
		end,
	}
end

return Holder
