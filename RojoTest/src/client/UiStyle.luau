--!strict
-- The single source of truth for the look of the whole interface.
-- The reference for the style is the "Rebirth" and "Balls" panels: brick
-- plates, fat white text with a dark outline and chunky ink borders.
-- The same numbers live in docs/ui-style.md.
local C = Color3.fromRGB
local Style = {}

-- Ink is the colour of every border and of every text outline.
Style.Ink = C(20, 22, 33)
-- The body of a window is translucent: the world stays visible behind it.
Style.Panel = C(55, 63, 79)
Style.PanelDeep = C(38, 44, 58)
Style.Slot = C(30, 36, 48)
Style.Text = C(255, 255, 255)
Style.Muted = C(206, 220, 240)
Style.Gold = C(255, 225, 66)

Style.Colors = {
	Pets = C(27, 183, 247),
	Eggs = C(171, 71, 255),
	Trails = C(14, 206, 229),
	Shop = C(255, 45, 137),
	Inventory = C(240, 140, 40),
	Rebirth = C(255, 60, 120),
	Gifts = C(255, 196, 56),
	Hatch = C(255, 196, 56),
	Green = C(85, 233, 19),
	Blue = C(22, 160, 248),
	Red = C(252, 24, 68),
	Purple = C(189, 128, 238),
	Gold = C(255, 225, 66),
	Slate = C(115, 127, 143),
}

Style.Rarity = {
	Common = C(139, 162, 190),
	Uncommon = C(87, 220, 129),
	Rare = C(43, 176, 255),
	Epic = C(181, 100, 255),
	Legendary = C(255, 197, 61),
	Mythic = C(255, 75, 158),
}

-- Shape of the plates.
Style.Stroke = 2
Style.WindowStroke = 2
Style.Radius = 9
Style.PanelRadius = 12
Style.StudTile = 64
Style.StudAlpha = 0.5

-- The window chrome comes from the Settings and Balls panels: the heading is
-- a 63 pixel label that floats over the top edge, the icon is 100 and
-- overlaps the top left corner, the game cross is 60 and overlaps the top
-- right one, and the plate carries a two pixel ink edge with squared corners.
Style.TitleSize = 63
Style.TitleMin = 24
Style.IconSize = 100
Style.CloseSize = 60

Style.Motion = {
	Frequency = 6,
	DampingRatio = 1,
	Lift = 4,
	PressDepth = 3,
	Brighten = 0.12,
	Darken = 0.1,
	CardLift = 3,
	WindowRise = 24,
	WindowFrequency = 4.5,
}

-- The colour of a plate that carries text: a little ink keeps the white
-- caption readable on a bright plate.
function Style.plateColor(color: Color3): Color3
	return color:Lerp(Style.Ink, 0.12)
end

-- The colour of a plate that sits inside a window and must not fight with
-- the text on it.
function Style.slotColor(color: Color3): Color3
	return color:Lerp(Style.Ink, 0.35)
end

return Style
