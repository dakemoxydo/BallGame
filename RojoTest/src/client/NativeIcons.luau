--!strict
-- Scalable artwork constructed from native Roblox GUI shapes.
local Icons = {}
local C = Color3.fromRGB
local dark = C(19, 22, 48)
function Icons.draw(parent, kind, color)
	local canvas = Instance.new("Frame")
	canvas.Name = "Icon_" .. kind
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundTransparency = 1
	canvas.Parent = parent
	local function shape(x, y, w, h, fill, rotation, round, outline)
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = UDim2.fromScale(x, y)
		p.Size = UDim2.fromScale(w, h)
		p.BackgroundColor3 = fill
		p.BorderSizePixel = 0
		p.Rotation = rotation or 0
		p.Parent = canvas
		if round then
			local r = Instance.new("UICorner")
			r.CornerRadius = UDim.new(round, 0)
			r.Parent = p
		end
		if outline ~= false then
			local s = Instance.new("UIStroke")
			s.Thickness = 2
			s.Color = dark
			s.Parent = p
		end
		return p
	end
	local function text(t, x, y, w, h, fill)
		local l = Instance.new("TextLabel")
		l.Text = t
		l.Position = UDim2.fromScale(x - w / 2, y - h / 2)
		l.Size = UDim2.fromScale(w, h)
		l.BackgroundTransparency = 1
		l.TextColor3 = fill
		l.Font = Enum.Font.GothamBlack
		l.TextScaled = true
		l.TextStrokeTransparency = 0
		l.TextStrokeColor3 = dark
		l.Parent = canvas
		return l
	end
	if kind == "Close" then
		shape(0.5, 0.5, 0.9, 0.9, C(250, 30, 62), 0, 0.12)
		text("×", 0.5, 0.48, 0.85, 0.85, C(255, 255, 255))
	elseif kind == "Arrow" then
		text(">", 0.5, 0.5, 0.9, 0.9, C(255, 255, 255))
	elseif kind == "Skill" then
		shape(0.48, 0.31, 0.25, 0.52, C(255, 210, 35), 28, 0.05)
		shape(0.55, 0.52, 0.44, 0.19, C(255, 188, 28), -12, 0.05)
		shape(0.45, 0.74, 0.19, 0.49, C(255, 168, 18), 31, 0.05)
		shape(0.45, 0.27, 0.07, 0.28, C(255, 249, 155), 28, 0.01, false)
	elseif kind == "Rebirth" then
		shape(0.5, 0.5, 0.78, 0.78, C(29, 190, 243), -18, 0.5)
		shape(0.5, 0.28, 0.77, 0.38, C(255, 43, 147), -18, 0.4)
		shape(0.49, 0.5, 0.35, 0.35, C(38, 51, 75), 0, 0.5, false)
		shape(0.8, 0.26, 0.24, 0.24, C(255, 133, 208), 28, 0.03)
		shape(0.2, 0.76, 0.24, 0.24, C(147, 238, 255), 28, 0.03)
	elseif kind == "Trails" or kind == "Stone" then
		if kind == "Trails" then
			shape(0.32, 0.65, 0.28, 0.63, color or C(192, 48, 255), 37, 0.4)
			shape(0.28, 0.73, 0.15, 0.58, (color or C(192, 48, 255)):Lerp(C(255, 255, 255), 0.4), 39, 0.4)
			shape(0.13, 0.68, 0.14, 0.14, C(255, 238, 60), 45, 0.02)
			shape(0.46, 0.79, 0.12, 0.12, C(255, 238, 60), 45, 0.02)
		end
		shape(0.61, 0.33, 0.58, 0.43, C(114, 124, 146), -26, 0.5)
		shape(0.59, 0.28, 0.49, 0.31, color or C(178, 187, 207), -26, 0.5, false)
		shape(0.71, 0.22, 0.15, 0.08, C(246, 250, 255), 22, 0.5, false)
	elseif kind == "Pets" then
		local fur = color or C(202, 126, 68)
		shape(0.22, 0.27, 0.22, 0.37, fur, -14, 0.2)
		shape(0.78, 0.27, 0.22, 0.37, fur, 14, 0.2)
		shape(0.5, 0.53, 0.74, 0.7, fur, 0, 0.2)
		shape(0.32, 0.47, 0.2, 0.28, C(255, 255, 255), 0, 0.5, false)
		shape(0.68, 0.47, 0.2, 0.28, C(255, 255, 255), 0, 0.5, false)
		shape(0.35, 0.48, 0.09, 0.17, dark, 0, 0.5, false)
		shape(0.65, 0.48, 0.09, 0.17, dark, 0, 0.5, false)
		shape(0.5, 0.68, 0.13, 0.1, dark, 0, 0.4, false)
		text("ᴗ", 0.5, 0.77, 0.3, 0.18, C(255, 244, 231))
	elseif kind == "Gifts" then
		shape(0.5, 0.59, 0.7, 0.62, C(22, 183, 249), 0, 0.08)
		shape(0.5, 0.33, 0.82, 0.22, C(102, 226, 255), 0, 0.07)
		shape(0.5, 0.58, 0.17, 0.63, C(255, 191, 36), 0, 0.01, false)
		shape(0.36, 0.17, 0.28, 0.2, C(255, 200, 41), 30, 0.5)
		shape(0.64, 0.17, 0.28, 0.2, C(255, 200, 41), -30, 0.5)
	elseif kind == "Inventory" then
		shape(0.5, 0.19, 0.34, 0.22, C(112, 65, 34), 0, 0.3)
		shape(0.5, 0.59, 0.63, 0.74, C(174, 102, 48), 0, 0.2)
		shape(0.5, 0.65, 0.51, 0.33, C(127, 72, 38), 0, 0.15)
		shape(0.5, 0.64, 0.11, 0.17, C(255, 201, 80), 0, 0.1)
	elseif kind == "Shop" then
		shape(0.5, 0.54, 0.7, 0.65, C(255, 46, 112), -7, 0.06)
		shape(0.5, 0.31, 0.85, 0.23, C(255, 117, 165), -7, 0.06)
		shape(0.51, 0.34, 0.32, 0.59, C(53, 192, 255), 16, 0.06)
		shape(0.51, 0.3, 0.24, 0.43, C(155, 239, 255), 16, 0.05, false)
	elseif kind == "Settings" then
		for i = 0, 7 do
			local a = i * math.pi / 4
			shape(0.5 + math.sin(a) * 0.29, 0.5 + math.cos(a) * 0.29, 0.2, 0.29, C(121, 197, 238), -i * 45, 0.03)
		end
		shape(0.5, 0.5, 0.68, 0.68, C(135, 217, 255), 0, 0.5)
		shape(0.5, 0.5, 0.38, 0.38, C(24, 159, 234), 0, 0.5)
		shape(0.46, 0.44, 0.19, 0.14, C(83, 235, 255), -25, 0.5, false)
	elseif kind == "Wins" then
		shape(0.2, 0.29, 0.27, 0.33, C(255, 180, 31), 0, 0.4)
		shape(0.8, 0.29, 0.27, 0.33, C(255, 180, 31), 0, 0.4)
		shape(0.5, 0.29, 0.53, 0.48, C(255, 214, 54), 0, 0.25)
		shape(0.5, 0.58, 0.12, 0.32, C(255, 180, 31), 0, 0.1)
		shape(0.5, 0.78, 0.48, 0.16, C(255, 213, 47), 0, 0.08)
		shape(0.44, 0.2, 0.1, 0.2, C(255, 247, 165), 0, 0.1, false)
	elseif kind == "Egg" then
		shape(0.5, 0.53, 0.64, 0.84, color or C(217, 238, 255), 0, 0.5)
		shape(0.36, 0.37, 0.17, 0.21, C(255, 255, 255), -15, 0.5, false)
		shape(0.63, 0.59, 0.15, 0.19, (color or C(130, 193, 242)):Lerp(dark, 0.2), 15, 0.5, false)
	end
	return canvas
end
return Icons
