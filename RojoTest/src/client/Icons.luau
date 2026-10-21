--!strict
local Assets = require(script.Parent.UIAssets)
local Native = require(script.Parent.NativeIcons)
local CollectorArt = require(script.Parent.CollectorUI.Art)
local Icons = {}
local C = Color3.fromRGB
function Icons.draw(parent, kind, color)
	local key = kind
	if kind == "Trails" then
		if color == C(244, 247, 255) then
			key = "WhiteTrail"
		elseif color == C(255, 48, 84) then
			key = "RedTrail"
		elseif color == C(30, 191, 255) then
			key = "BlueTrail"
		end
	end
	local slot = Assets.Slots[key]
	local collectorSlot = CollectorArt.Slots[key]
	if collectorSlot ~= nil then
		-- The tint is part of the draw request: the caller passes the colour
		-- of the thing the icon belongs to, like the admin egg or the starter
		-- pack purple, and the icon is drawn in it. An icon without a colour
		-- keeps its native atlas look.
		local image = Instance.new("ImageLabel")
		image.Name = "Icon_" .. key
		image.BackgroundTransparency = 1
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.Size = UDim2.fromScale(1, 1)
		image.Image = CollectorArt.Image
		image.ScaleType = Enum.ScaleType.Fit
		image.ImageRectOffset = Vector2.new((collectorSlot % 4) * 256, math.floor(collectorSlot / 4) * 256)
		image.ImageRectSize = Vector2.new(256, 256)
		if color then
			image.ImageColor3 = color
		end
		image.Parent = parent
		return image
	end
	if Assets.Image == "" or slot == nil then
		return Native.draw(parent, kind, color)
	end
	local image = Instance.new("ImageLabel")
	image.Name = "Icon_" .. key
	image.BackgroundTransparency = 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(1, 1)
	image.Image = Assets.Image
	image.ScaleType = kind == "Trails" and color ~= nil and Enum.ScaleType.Stretch or Enum.ScaleType.Fit
	local w, h = Assets.Width / Assets.Columns, Assets.Height / Assets.Rows
	local rect = Assets.Rects[key]
	image.ImageRectOffset = rect and Vector2.new(rect[1] * Assets.Width, rect[2] * Assets.Height)
		or Vector2.new((slot % Assets.Columns) * w, math.floor(slot / Assets.Columns) * h)
	image.ImageRectSize = rect and Vector2.new(rect[3] * Assets.Width, rect[4] * Assets.Height) or Vector2.new(w, h)
	if color then
		image.ImageColor3 = color
	end
	image.Parent = parent
	return image
end
return Icons
