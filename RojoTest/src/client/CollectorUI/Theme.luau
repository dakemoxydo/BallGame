--!strict
-- The colours and the motion of the collector interface. The values come
-- from the shared style sheet so that the React screens and the legacy
-- panels speak the same visual language.
local Style = require(script.Parent.Parent.UiStyle)
local Theme = {
	Outline = Style.Ink,
	Body = Style.Panel,
	Recess = Style.PanelDeep,
	Slot = Style.Slot,
	Text = Style.Text,
	Muted = Style.Muted,
	Gold = Style.Gold,
	Colors = Style.Colors,
	Rarity = Style.Rarity,
	Motion = Style.Motion,
	Stroke = Style.Stroke,
	WindowStroke = Style.WindowStroke,
	Radius = Style.Radius,
	PanelRadius = Style.PanelRadius,
	StudTile = Style.StudTile,
	StudAlpha = Style.StudAlpha,
	TitleSize = Style.TitleSize,
	TitleMin = Style.TitleMin,
	IconSize = Style.IconSize,
	CloseSize = Style.CloseSize,
}
-- The colour of a plate that carries text: a little ink keeps the white
-- caption readable on a bright brick.
function Theme.plate(color: Color3): Color3
	return color:Lerp(Style.Ink, 0.14)
end

-- The colour of a plate that sits inside a window and must not fight with
-- the text on it.
function Theme.slot(color: Color3): Color3
	return color:Lerp(Style.Ink, 0.35)
end

return Theme
