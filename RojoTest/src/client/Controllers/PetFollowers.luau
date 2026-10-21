--!strict
-- Equipped pets follow the player as small world models.
-- The follower list is rebuilt only when the equipped set changes, so the
-- render loop never allocates a model.
local PetVisuals = require(game.ReplicatedStorage.Shared.PetVisuals)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)

local Followers = {}
local C = Color3.fromRGB
local white, dark = C(255, 255, 255), C(20, 22, 33)

export type Context = {
	effectsFolder: Folder,
}

export type Handle = {
	refresh: ({ string }, { any }) -> (),
	update: (BasePart?, number) -> (),
	destroy: () -> (),
}

function Followers.mount(context: Context): Handle
	local followers: { Model } = {}
	local signature = ""
	local rowWidth = 0

	local function makePart(name: string, size: Vector3, color: Color3, parent: Instance): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = parent
		return p
	end

	local function petModel(def: any): Model
		local imported = PetVisuals.follower(def.visual or def.id)
		if imported then
			imported.Parent = context.effectsFolder
			return imported
		end
		local m = Instance.new("Model")
		m.Name = "Pet_" .. def.id
		local body = makePart("Body", Vector3.new(2.4, 2.2, 2.2), def.color, m)
		local function piece(name: string, size: Vector3, pos: Vector3, color: Color3)
			local p = makePart(name, size, color, m)
			p.Position = pos
			return p
		end
		local earHeight = def.id == "Bunny" and 2.2 or 0.7
		for _, side in { -1, 1 } do
			piece("Ear", Vector3.new(0.6, earHeight, 0.6), Vector3.new(side * 0.8, 1 + earHeight / 2, 0), def.color)
			local eye = piece("Eye", Vector3.new(0.55, 0.7, 0.13), Vector3.new(side * 0.55, 0.22, -1.13), white)
			eye.Shape = Enum.PartType.Ball
			local pupil = piece("Pupil", Vector3.new(0.24, 0.4, 0.12), Vector3.new(side * 0.55, 0.16, -1.22), dark)
			pupil.Shape = Enum.PartType.Ball
		end
		piece("Nose", Vector3.new(0.3, 0.2, 0.14), Vector3.new(0, -0.3, -1.16), C(105, 66, 59))
		if def.id == "Dragon" then
			for _, side in { -1, 1 } do
				local wing = piece(
					"Wing",
					Vector3.new(1.5, 0.2, 1.8),
					Vector3.new(side * 1.8, 0.3, 0.4),
					def.color:Lerp(white, 0.25)
				)
				wing.CFrame *= CFrame.Angles(0, 0, side * 0.4)
			end
		end
		m.PrimaryPart = body
		m:ScaleTo(PetVisuals.FollowerBodyWidth / body.Size.X)
		m.Parent = context.effectsFolder
		return m
	end

	local function clear()
		for _, model in followers do
			model:Destroy()
		end
		followers = {}
		rowWidth = 0
	end

	return {
		refresh = function(equipped: { string }, pets: { any })
			local parts = {}
			for _, id in equipped do
				table.insert(parts, id)
			end
			local key = table.concat(parts, ",")
			if key == signature then
				return
			end
			signature = key
			clear()
			for _, id in equipped do
				for _, pet in pets do
					if pet.uid == id then
						local def = Config.pet(pet.id)
						if def then
							table.insert(followers, petModel(def))
						end
						break
					end
				end
			end
			rowWidth = math.max(0, #followers - 1) * 0.65
			for _, model in followers do
				local _, size = model:GetBoundingBox()
				model:SetAttribute("FollowerWidth", size.X)
				model:SetAttribute("FollowerHeight", size.Y)
				rowWidth += size.X
			end
		end,
		update = function(root: BasePart?, now: number)
			if not root then
				return
			end
			local edge = -rowWidth / 2
			for i, model in followers do
				local width = model:GetAttribute("FollowerWidth") or 2
				local x = edge + width / 2
				edge += width + 0.65
				local height = model:GetAttribute("FollowerHeight") or 2.8
				local y = math.sin(now * 3 + i) * 0.25 - 0.9 + (height - 2.8) / 2
				local target = root.CFrame * CFrame.new(x, y, 4.5)
				model:PivotTo(model:GetPivot():Lerp(target, 0.13))
			end
		end,
		destroy = clear,
	}
end

return Followers
