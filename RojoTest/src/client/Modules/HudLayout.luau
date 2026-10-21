--!strict
-- Two HUD layouts share one set of instances.
-- Landscape keeps the original 1280x720 board that is scaled to the window.
-- Portrait rebuilds the same elements as a narrow column with touch sized
-- buttons at the bottom of the screen, because a scaled board would shrink the
-- captions below the readable size on a phone.
local HudLayout = {}

export type Child = {
	name: string,
	x: number,
	y: number,
	w: number,
	h: number,
	text: number?,
	visible: boolean?,
}

export type Overrides = {
	text: number?,
	caption: number?,
	captionFill: boolean?,
	visible: boolean?,
	hide: { string }?,
	children: { Child }?,
}

export type Entry = {
	x: number,
	y: number,
	w: number,
	h: number,
	text: number?,
	caption: number?,
	captionFill: boolean?,
	visible: boolean?,
	hide: { string }?,
	children: { Child }?,
}

export type Spec = {
	mode: string,
	width: number,
	height: number,
	scaled: boolean,
	elements: { [string]: Entry },
}

export type Pin = {
	node: GuiObject,
	side: string,
	offset: number,
}

-- One row of the portrait column. The gap is the free space above the row.
type Row = {
	name: string,
	height: number,
	gap: number,
}

-- One fallback step for a short portrait window: the gaps get tighter, the
-- secondary rows disappear and the hint at the bottom may go.
type Plan = {
	tight: number,
	drop: { [string]: boolean },
	hint: boolean,
}

-- The state a node was authored with. The board was built for the landscape
-- layout, so a portrait pass hides elements and rewrites captions. The next
-- pass has to put the authored values back before it applies the new spec,
-- otherwise a phone that rotates back keeps the portrait state for good.
type NodeState = {
	position: UDim2,
	size: UDim2,
	textSize: number?,
	limit: { max: number, min: number }?,
}

local BOARD_WIDTH, BOARD_HEIGHT = 1280, 720

local function entry(x: number, y: number, w: number, h: number, extra: Overrides?): Entry
	local value: Entry = { x = x, y = y, w = w, h = h }
	if extra then
		value.text = extra.text
		value.caption = extra.caption
		value.captionFill = extra.captionFill
		value.visible = extra.visible
		value.hide = extra.hide
		value.children = extra.children
	end
	return value
end

-- Landscape: the board as it was authored, one pixel per layout unit.
function HudLayout.landscape(): Spec
	local elements: { [string]: Entry } = {
		HUD = entry(0, 0, BOARD_WIDTH, BOARD_HEIGHT),
		Toast = entry(330, 185, 620, 44, { text = 27 }),
		AutoThrow = entry(564, 43, 152, 43),
		Settings = entry(160, 60, 29, 29),
		StarterPack = entry(1080, 201, 119, 83),
		DoubleSkill = entry(1080, 303, 125, 53),
		DoubleWins = entry(1080, 366, 125, 53),
		Throw = entry(577, 406, 126, 51),
		StopTraining = entry(533, 205, 214, 51),
		SkillIcon = entry(345, 479, 31, 39),
		Skill = entry(377, 482, 279, 30, { text = 22 }),
		Multiplier = entry(774, 482, 205, 30, { text = 22 }),
		LevelBar = entry(344, 528, 592, 61),
		["LevelBar/Level"] = entry(14, 4, 260, 50, { text = 29 }),
		["LevelBar/Maximum"] = entry(303, 8, 271, 43, { text = 23 }),
		Skill10M = entry(344, 600, 193, 53),
		Skill100M = entry(543, 600, 193, 53),
		Skill1B = entry(742, 600, 193, 53),
		RebirthIcon = entry(79, 554, 40, 40),
		RebirthCount = entry(128, 556, 110, 34, { text = 31 }),
		WinsIcon = entry(78, 601, 42, 43),
		WinsCount = entry(128, 601, 200, 44, { text = 34 }),
		FriendBoost = entry(74, 654, 183, 27, { text = 18 }),
		Distance = entry(414, 96, 452, 46, { text = 31 }),
		HitDistance = entry(425, 153, 430, 27, { text = 20 }),
		Best = entry(980, 666, 280, 26, { text = 16 }),
		Hint = entry(360, 680, 560, 24, { text = 16 }),
		RebirthProgress = entry(0, 0, 1, 1, { visible = false }),
	}
	return {
		mode = "landscape",
		width = BOARD_WIDTH,
		height = BOARD_HEIGHT,
		scaled = true,
		elements = elements,
	}
end

-- Portrait: one column, real pixels, nothing below a 44 pixel touch target.
function HudLayout.portrait(width: number, height: number): Spec
	local half = width * 0.5
	-- The touch buttons are anchored to the bottom edge and the hint sits
	-- above them. The column on top has to fit into what is left, so a short
	-- window tightens the gaps and drops the secondary rows instead of
	-- letting the two blocks overlap.
	local throwHeight, hintHeight = 76, 22
	-- The column needs at least the header, the distance and the level bar.
	local minimumColumn = 8 + 48 + 12 + 40 + 8 + 60
	-- The margin under the touch buttons is a design choice. A short window
	-- gives it up so the column and the buttons still fit.
	local bottomMargin = math.clamp(height - minimumColumn - 16 - throwHeight, 0, 92)
	local throwTop = math.max(0, height - bottomMargin - throwHeight)
	local hintTop = throwTop - 8 - hintHeight
	local rows: { Row } = {
		{ name = "head", height = 48, gap = 0 },
		{ name = "distance", height = 40, gap = 12 },
		{ name = "hit", height = 26, gap = 0 },
		{ name = "level", height = 60, gap = 8 },
		{ name = "skill", height = 26, gap = 12 },
		{ name = "rebirth", height = 28, gap = 12 },
		{ name = "boost", height = 22, gap = 14 },
	}
	-- The fallbacks for a short window, from the tightest gaps to the hidden
	-- rows. The first step that fits into the window wins.
	local plans: { Plan } = {
		{ tight = 0, drop = {}, hint = true },
		{ tight = 3, drop = {}, hint = true },
		{ tight = 6, drop = {}, hint = true },
		{ tight = 3, drop = { boost = true }, hint = true },
		{ tight = 6, drop = { boost = true }, hint = true },
		{ tight = 9, drop = { boost = true }, hint = true },
		{ tight = 6, drop = { boost = true, hit = true }, hint = true },
		{ tight = 9, drop = { boost = true, hit = true }, hint = true },
		{ tight = 0, drop = { boost = true, hit = true }, hint = false },
		{ tight = 0, drop = { boost = true, hit = true, skill = true }, hint = false },
		{ tight = 0, drop = { boost = true, hit = true, skill = true, rebirth = true }, hint = false },
	}
	-- The height the column needs with a given plan.
	local function columnHeight(plan: Plan): number
		local total, first = 8, true
		for _, row in rows do
			if not plan.drop[row.name] then
				if not first then
					total += math.max(0, row.gap - plan.tight)
				end
				total += row.height
				first = false
			end
		end
		return total
	end
	-- The room the column may use above the bottom block.
	local function room(plan: Plan): number
		return (if plan.hint then hintTop else throwTop - 8) - 8
	end
	local plan = plans[#plans]
	for _, candidate in plans do
		plan = candidate
		if columnHeight(candidate) <= room(candidate) then
			break
		end
	end
	local rowTop: { [string]: number } = {}
	local y, first = 8, true
	for _, row in rows do
		if not plan.drop[row.name] then
			if not first then
				y += math.max(0, row.gap - plan.tight)
			end
			rowTop[row.name] = y
			y += row.height
			first = false
		end
	end
	local function top(name: string): number
		return rowTop[name] or 0
	end
	local elements: { [string]: Entry } = {
		HUD = entry(0, 0, width, height),
		Settings = entry(8, top("head"), 48, 48, {
			children = {
				{ name = "SettingsIcon", x = 12, y = 12, w = 24, h = 24 },
			},
		}),
		AutoThrow = entry(64, top("head"), width - 72, 48, {
			caption = 18,
			captionFill = true,
			hide = { "WinsIcon", "Price" },
		}),
		Distance = entry(8, top("distance"), width - 16, 40, { text = 26 }),
		HitDistance = entry(8, top("hit"), width - 16, 26, { text = 18, visible = not plan.drop["hit"] }),
		LevelBar = entry(8, top("level"), width - 16, 60),
		["LevelBar/Level"] = entry(14, 6, half - 40, 48, { text = 24 }),
		["LevelBar/Maximum"] = entry(half - 16, 8, half - 40, 44, { text = 18 }),
		SkillIcon = entry(8, top("skill"), 28, 34, { visible = not plan.drop["skill"] }),
		Skill = entry(42, top("skill") + 2, half - 50, 26, { text = 20, visible = not plan.drop["skill"] }),
		Multiplier = entry(half, top("skill") + 2, half - 8, 26, { text = 20, visible = not plan.drop["skill"] }),
		RebirthIcon = entry(8, top("rebirth"), 32, 32, { visible = not plan.drop["rebirth"] }),
		RebirthCount = entry(44, top("rebirth") + 2, half - 60, 28, { text = 22, visible = not plan.drop["rebirth"] }),
		WinsIcon = entry(half + 8, top("rebirth"), 32, 32, { visible = not plan.drop["rebirth"] }),
		WinsCount = entry(
			half + 44,
			top("rebirth") + 2,
			half - 52,
			28,
			{ text = 22, visible = not plan.drop["rebirth"] }
		),
		FriendBoost = entry(8, top("boost"), width * 0.6 - 8, 22, { text = 15, visible = not plan.drop["boost"] }),
		Best = entry(width * 0.6, top("boost"), width * 0.4 - 8, 22, { text = 14, visible = not plan.drop["boost"] }),
		Throw = entry(8, throwTop, width - 16, throwHeight, { caption = 30, captionFill = true }),
		StopTraining = entry(8, throwTop, width - 16, throwHeight, { caption = 24, captionFill = true }),
		Hint = entry(8, hintTop, width - 16, hintHeight, { text = 14, visible = plan.hint }),
		Toast = entry(8, height * 0.4, width - 16, 40, { text = 20 }),
		RebirthProgress = entry(0, 0, 1, 1, { visible = false }),
		-- The shop screen owns the paid offers on narrow screens.
		StarterPack = entry(1080, 201, 119, 83, { visible = false }),
		DoubleSkill = entry(1080, 303, 125, 53, { visible = false }),
		DoubleWins = entry(1080, 366, 125, 53, { visible = false }),
		Skill10M = entry(344, 600, 193, 53, { visible = false }),
		Skill100M = entry(543, 600, 193, 53, { visible = false }),
		Skill1B = entry(742, 600, 193, 53, { visible = false }),
	}
	return {
		mode = "portrait",
		width = width,
		height = height,
		scaled = false,
		elements = elements,
	}
end

local function findChild(roots: { Instance }, name: string): Instance?
	for _, root in roots do
		local node = root:FindFirstChild(name)
		if node then
			return node
		end
	end
	return nil
end

-- Authored values of every node the layout has touched, plus the nodes it
-- hid. Both are needed to undo a layout pass before the next one is applied.
local authored: { [Instance]: NodeState } = {}
local touched: { [Instance]: true } = {}
local hidden: { [Instance]: boolean } = {}

-- Remembers a node in its authored state and marks it for the next restore.
local function stateOf(node: GuiObject): NodeState
	local state = authored[node]
	if not state then
		state = {
			position = node.Position,
			size = node.Size,
			textSize = if node:IsA("TextLabel") then node.TextSize else nil,
		}
		authored[node] = state
	end
	touched[node] = true
	return state
end

-- Puts a node back into the state the scene was built with.
local function restore(node: Instance)
	local state = authored[node]
	if not state or not node.Parent or not node:IsA("GuiObject") then
		return
	end
	node.Position = state.position
	node.Size = state.size
	if state.textSize and node:IsA("TextLabel") then
		node.TextSize = state.textSize
	end
	if state.limit then
		local limit = node:FindFirstChildOfClass("UITextSizeConstraint")
		if limit then
			limit.MaxTextSize = state.limit.max
			limit.MinTextSize = state.limit.min
		end
	end
end

-- Hides a node and remembers how it looked before, so the next layout pass
-- can show it again.
local function hideNode(node: Instance)
	if not node:IsA("GuiObject") then
		return
	end
	if hidden[node] == nil then
		hidden[node] = node.Visible
	end
	node.Visible = false
end

-- Shows a node again. The spec asked for it, so the node leaves the hidden
-- list and stays visible until another spec hides it.
local function showNode(node: Instance)
	if not node:IsA("GuiObject") then
		return
	end
	hidden[node] = nil
	node.Visible = true
end

local function applyCaption(target: GuiObject, item: Entry)
	local caption = target:FindFirstChild("Caption")
	if not caption or not caption:IsA("TextLabel") then
		return
	end
	local state = stateOf(caption)
	local limit = caption:FindFirstChildOfClass("UITextSizeConstraint")
	if item.caption then
		caption.TextSize = item.caption
		if limit then
			if not state.limit then
				state.limit = { max = limit.MaxTextSize, min = limit.MinTextSize }
			end
			limit.MaxTextSize = item.caption
			limit.MinTextSize = math.min(10, item.caption)
		end
	end
	if item.captionFill then
		caption.Position = UDim2.fromOffset(8, 3)
		caption.Size = UDim2.fromOffset(math.max(1, item.w - 16), math.max(1, item.h - 6))
	end
end

local function applyChildren(target: GuiObject, children: { Child })
	for _, child in children do
		local node = target:FindFirstChild(child.name)
		if node and node:IsA("GuiObject") then
			stateOf(node)
			node.Position = UDim2.fromOffset(child.x, child.y)
			node.Size = UDim2.fromOffset(child.w, child.h)
			if child.text and node:IsA("TextLabel") then
				node.TextSize = child.text
			end
			if child.visible ~= nil then
				if child.visible then
					showNode(node)
				else
					hideNode(node)
				end
			end
		end
	end
end

-- Moves every named element of a layout onto its instance.
function HudLayout.apply(spec: Spec, roots: { Instance })
	-- Undo the previous pass first. Without this a phone that rotates back to
	-- landscape keeps the portrait visibility, the portrait caption overrides
	-- and the portrait child positions.
	for node in pairs(hidden) do
		if node.Parent and node:IsA("GuiObject") then
			node.Visible = hidden[node]
		end
	end
	table.clear(hidden)
	for node in pairs(touched) do
		restore(node)
	end
	table.clear(touched)

	for path, item in spec.elements do
		local parentPath, name = path:match("^(.-)/([^/]+)$")
		local target: Instance? = nil
		if parentPath and name then
			local container = findChild(roots, parentPath)
			if container then
				target = container:FindFirstChild(name)
			end
		else
			target = findChild(roots, path)
		end
		if target and target:IsA("GuiObject") then
			stateOf(target)
			target.Position = UDim2.fromOffset(item.x, item.y)
			target.Size = UDim2.fromOffset(item.w, item.h)
			if item.text and target:IsA("TextLabel") then
				target.TextSize = item.text
			end
			if item.visible ~= nil then
				if item.visible then
					showNode(target)
				else
					hideNode(target)
				end
			end
			if item.hide then
				for _, childName in item.hide do
					local node = target:FindFirstChild(childName)
					if node then
						hideNode(node)
					end
				end
			end
			if item.children then
				applyChildren(target, item.children)
			end
			applyCaption(target, item)
			local shadow = target.Parent and target.Parent:FindFirstChild(target.Name .. "Shadow")
			if shadow and shadow:IsA("GuiObject") then
				stateOf(shadow)
				shadow.Position = UDim2.fromOffset(item.x, item.y + 4)
				shadow.Size = UDim2.fromOffset(item.w, item.h)
				if item.visible ~= nil then
					if item.visible then
						showNode(shadow)
					else
						hideNode(shadow)
					end
				end
			end
		end
	end
end

-- The side columns leave the board and hug the window edges in landscape.
local PIN_SOURCES: { { name: string, side: string, offset: number? } } = {
	{ name = "Shop", side = "left" },
	{ name = "Rebirth", side = "left" },
	{ name = "Pets", side = "left" },
	{ name = "Trails", side = "left" },
	{ name = "Inventory", side = "left" },
	{ name = "Gifts", side = "left" },
	{ name = "RebirthIcon", side = "left" },
	{ name = "WinsIcon", side = "left" },
	{ name = "RebirthCount", side = "left" },
	{ name = "WinsCount", side = "left" },
	{ name = "FriendBoost", side = "left" },
	{ name = "StarterPack", side = "right" },
	{ name = "DoubleSkill", side = "right" },
	{ name = "DoubleWins", side = "right" },
	{ name = "Best", side = "right", offset = -280 },
}

function HudLayout.pins(spec: Spec, hud: Instance): { Pin }
	local pins: { Pin } = {}
	for _, source in PIN_SOURCES do
		local node = hud:FindFirstChild(source.name)
		local item = spec.elements[source.name]
		if node and node:IsA("GuiObject") and item then
			local offset = source.offset
			if offset == nil then
				offset = if source.side == "left" then item.x - 75 else item.x - 1205
			end
			table.insert(pins, { node = node, side = source.side, offset = offset })
			local shadow = hud:FindFirstChild(source.name .. "Shadow")
			if shadow and shadow:IsA("GuiObject") then
				table.insert(pins, { node = shadow, side = source.side, offset = offset })
			end
		end
	end
	return pins
end

HudLayout.boardWidth = BOARD_WIDTH
HudLayout.boardHeight = BOARD_HEIGHT

return HudLayout
