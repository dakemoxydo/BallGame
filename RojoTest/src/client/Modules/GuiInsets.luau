--!strict
-- Device safe area helpers.
-- Roblox insets ScreenGui contents from the camera notch and the rounded
-- corners when ScreenInsets is DeviceSafeInsets. The measurements below
-- describe the same rectangle, so the HUD can lay out inside it even when the
-- engine does not move the GUI origin on its own.
local GuiService = game:GetService("GuiService")
local GuiInsets = {}

export type Insets = {
	top: number,
	bottom: number,
	left: number,
	right: number,
}

export type Area = {
	size: Vector2,
	offset: Vector2,
}

type Rect = {
	x: number,
	y: number,
	width: number,
	height: number,
}

local function insetRect(kind: Enum.ScreenInsets): Rect?
	local ok, area = pcall(function()
		return GuiService:GetInsetArea(kind)
	end)
	if not ok or not area then
		return nil
	end
	return { x = area.Min.X, y = area.Min.Y, width = area.Width, height = area.Height }
end

-- The part that both rectangles leave: the cutouts of the device and the bar
-- of the core UI do not overlap, so the usable rectangle is their crossing.
local function crossing(a: Rect, b: Rect): Rect
	local x = math.max(a.x, b.x)
	local y = math.max(a.y, b.y)
	local right = math.min(a.x + a.width, b.x + b.width)
	local bottom = math.min(a.y + a.height, b.y + b.height)
	return { x = x, y = y, width = math.max(0, right - x), height = math.max(0, bottom - y) }
end

-- The rectangle of the screen that the player really sees: the device area
-- knows the notch and the gesture bar, the core UI area knows the top bar.
-- The engine only insets the content by the device area, so the top bar is
-- closed here.
function GuiInsets.granted(): Rect
	local device = insetRect(Enum.ScreenInsets.DeviceSafeInsets)
	local core = insetRect(Enum.ScreenInsets.CoreUISafeInsets)
	if not device or device.width <= 0 or device.height <= 0 then
		return { x = 0, y = 0, width = 0, height = 0 }
	end
	if not core or core.width <= 0 or core.height <= 0 then
		return device
	end
	return crossing(device, core)
end

-- Only the cutouts of the device are reported here: the notch, the rounded
-- corners and the gesture bar.
local function deviceInsets(): Insets
	local none = insetRect(Enum.ScreenInsets.None)
	local device = insetRect(Enum.ScreenInsets.DeviceSafeInsets)
	if not none or not device then
		return { top = 0, bottom = 0, left = 0, right = 0 }
	end
	return {
		left = math.max(0, device.x - none.x),
		top = math.max(0, device.y - none.y),
		right = math.max(0, (none.x + none.width) - (device.x + device.width)),
		bottom = math.max(0, (none.y + none.height) - (device.y + device.height)),
	}
end

-- Every client ScreenGui uses the same policy: cover the screen, keep the
-- interactive parts out of the cutouts.
function GuiInsets.prepare(screenGui: ScreenGui)
	screenGui.IgnoreGuiInset = true
	screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end

-- The usable rectangle in probe coordinates. `probe` is a full size frame
-- inside the ScreenGui: it reports the area the engine really granted, so the
-- notch and the gesture bar are already outside of it. The offset is relative
-- to the probe, so the caller can place its content inside the rectangle.
function GuiInsets.area(viewport: Vector2, probe: GuiObject?): Area
	local granted = GuiInsets.granted()
	if granted.width <= 0 or granted.height <= 0 then
		-- The engine does not report the insets: the whole screen is used.
		granted = { x = 0, y = 0, width = viewport.X, height = viewport.Y }
	end
	if probe then
		local measured = probe.AbsoluteSize
		if measured.X > 0 and measured.Y > 0 then
			local origin = probe.AbsolutePosition
			return {
				size = Vector2.new(granted.width, granted.height),
				offset = Vector2.new(granted.x - origin.X, granted.y - origin.Y),
			}
		end
	end
	-- The probe is not measured yet: fall back to the granted rectangle.
	return {
		size = Vector2.new(granted.width, granted.height),
		offset = Vector2.new(granted.x, granted.y),
	}
end

function GuiInsets.insets(): Insets
	return deviceInsets()
end

return GuiInsets
