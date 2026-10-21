--!strict
local Packages = game.ReplicatedStorage.Packages
local React = require(Packages.React)
local Ripple = require(Packages.Ripple)
local Input = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Theme = require(script.Parent.Theme)
local Art = require(script.Parent.Art)
local OldArt = require(script.Parent.Parent.UIAssets)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Visuals = require(game.ReplicatedStorage.Shared.PetVisuals)
local Hooks = require(script.Parent.createHooks)(React, Ripple, Input)
local e, C = React.createElement, Color3.fromRGB
local U = { Hooks = Hooks }

-- One primitive of a pet glyph. The box is 0..1 of the glyph, a round of 1
-- is a circle, the shade moves the pet colour darker (-1) or lighter (1) and
-- a back part is drawn in the colour of the disc behind it.
type Part = {
	x: number,
	y: number,
	w: number,
	h: number,
	round: number?,
	rot: number?,
	shade: number?,
	color: Color3?,
	back: boolean?,
}
U.MotionContext = React.createContext(false)
local WHITE = Color3.new(1, 1, 1)
function U.corner(r)
	return e("UICorner", { CornerRadius = UDim.new(0, r or Theme.Radius) })
end
-- The style of the reference panels: a heavy font and a white caption that
-- keeps its dark outline on any brick. The outline is the darkest element of
-- the palette and it is what makes a bright plate readable.
function U.Label(p)
	local size = p.TextSize or 22
	local thickness = 2
	if size >= 40 then
		thickness = 3.5
	elseif p.Small or size < 18 then
		thickness = 1.5
	end
	return e("TextLabel", {
		Name = p.Name or "Label",
		BackgroundTransparency = 1,
		Position = p.Position,
		Size = p.Size or UDim2.fromScale(1, 1),
		AnchorPoint = p.AnchorPoint,
		Text = p.Text or "",
		Font = Enum.Font.GothamBlack,
		TextSize = size,
		TextScaled = p.Scaled == true,
		TextColor3 = p.Color or Theme.Text,
		TextWrapped = p.Wrap == true,
		TextTruncate = p.Wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
		TextXAlignment = p.Align or Enum.TextXAlignment.Center,
		-- The built in stroke stays off: the contextual one below draws it.
		TextStrokeTransparency = 1,
		ZIndex = p.ZIndex or 12,
	}, {
		Stroke = e("UIStroke", {
			Color = p.OutlineColor or Theme.Outline,
			Thickness = thickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}),
		Limit = p.Scaled and e("UITextSizeConstraint", {
			MinTextSize = p.MinTextSize or 12,
			MaxTextSize = p.MaxTextSize or size,
		}) or nil,
	})
end
function U.Icon(p)
	local slot = Art.Slots[p.Kind]
	local image, offset, size = Art.Image, nil, nil
	if slot then
		offset, size = Vector2.new(slot % 4 * 256, math.floor(slot / 4) * 256), Vector2.new(256, 256)
	else
		local rect = OldArt.Rects[p.Kind]
		image = OldArt.Image
		if rect then
			offset, size =
				Vector2.new(rect[1] * OldArt.Width, rect[2] * OldArt.Height),
				Vector2.new(rect[3] * OldArt.Width, rect[4] * OldArt.Height)
		end
	end
	return e("ImageLabel", {
		Name = p.Name or (p.Kind .. "Art"),
		BackgroundTransparency = 1,
		Position = p.Position,
		Size = p.Size or UDim2.fromScale(1, 1),
		AnchorPoint = p.AnchorPoint,
		Image = image,
		ImageRectOffset = offset,
		ImageRectSize = size,
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = p.Color or Color3.new(1, 1, 1),
		Rotation = p.Rotation or 0,
		Active = false,
		ZIndex = p.ZIndex or 14,
	})
end
-- A brick plate. It is the only surface of the interface: a saturated face
-- with the stud texture, a bright top edge and a dark ink border. A quiet
-- plate drops the texture and the top light and is used for the recesses.
function U.Surface(p)
	local color = p.Color or Theme.Body
	local radius, z = p.Radius or Theme.Radius, p.ZIndex or 2
	local decoration = {
		Corner = U.corner(radius),
		Outline = e("UIStroke", {
			Thickness = p.Outline or Theme.Stroke,
			Color = Theme.Outline,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}
	if not p.Quiet then
		decoration.Gradient = e("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(color:Lerp(WHITE, 0.22), color),
		})
	end
	if p.Studs ~= false and not p.Quiet then
		decoration.Studs = e("ImageLabel", {
			Name = "Studs",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = Config.StudTexture,
			ImageColor3 = WHITE,
			ImageTransparency = Theme.StudAlpha,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(Theme.StudTile, Theme.StudTile),
			Active = false,
		}, { Corner = U.corner(radius) })
	end
	if p.Shine then
		decoration.Shine = e("Frame", {
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.9,
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			ZIndex = 4,
		}, {
			Corner = U.corner(radius),
			Fade = e("UIGradient", {
				Rotation = 25,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.18, 1),
					NumberSequenceKeypoint.new(0.19, 0),
					NumberSequenceKeypoint.new(0.36, 0),
					NumberSequenceKeypoint.new(0.37, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
	end
	if p.Motion then
		decoration.Tint = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = p.Motion:map(function(t)
				return t >= 0 and WHITE or Color3.new()
			end),
			BackgroundTransparency = p.Motion:map(function(t)
				return 1 - math.abs(t) * 0.12
			end),
			ZIndex = 5,
		}, { Corner = U.corner(radius) })
	end
	-- The content lives inside the moving plate: when the button lifts or dips,
	-- its caption and its icon travel with it. A content frame outside the
	-- plate would stand still while the brick under it moves.
	decoration.Content = e(
		"Frame",
		{ Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z + 6 },
		p.Children
	)
	return e("Frame", {
		Name = p.Name or "Surface",
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		BackgroundTransparency = 1,
		ZIndex = z,
	}, {
		Shadow = not p.NoShadow and e("Frame", {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(0, 5),
			BackgroundColor3 = Theme.Outline,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			ZIndex = z,
		}, { Corner = U.corner(radius) }),
		Body = e("Frame", {
			Name = "Body",
			Size = UDim2.fromScale(1, 1),
			Position = p.Motion and p.Motion:map(function(t)
				return UDim2.fromOffset(0, math.round(-t * (t > 0 and Theme.Motion.Lift or Theme.Motion.PressDepth)))
			end) or nil,
			BackgroundColor3 = color,
			BackgroundTransparency = p.Transparency or 0,
			BorderSizePixel = 0,
			ZIndex = z + 1,
		}, decoration),
	})
end
-- A recessed plate: no texture, no top light, only the ink border. It holds
-- the content that must not look like a brick.
function U.Slot(p)
	return e(U.Surface, {
		Name = p.Name or "Slot",
		Color = p.Color or Theme.Recess,
		Radius = p.Radius,
		Outline = p.Outline,
		Transparency = p.Transparency,
		Position = p.Position,
		Size = p.Size,
		AnchorPoint = p.AnchorPoint,
		ZIndex = p.ZIndex,
		NoShadow = p.NoShadow,
		Quiet = true,
		Children = p.Children,
	})
end
function U.Button(p)
	local reduced = React.useContext(U.MotionContext)
	local motionProps = table.clone(p)
	motionProps.ReducedMotion = reduced or p.ReducedMotion
	local progress, events = Hooks.useButtonMotion(motionProps, Theme)
	local props = {
		Name = p.Name or "Button",
		Text = "",
		BackgroundTransparency = 1,
		Size = p.Size,
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		AutoButtonColor = false,
		Active = not p.Disabled,
		Selectable = not p.Disabled,
		ZIndex = p.ZIndex or 20,
		[React.Event.Activated] = function()
			if not p.Disabled and p.OnActivated then
				p.OnActivated()
			end
		end,
	}
	for key, value in events do
		props[key] = value
	end
	local children = table.clone(p.Children or {})
	if p.Text then
		children.Caption = e(U.Label, {
			Name = "Caption",
			Text = p.Text,
			Position = p.Centered and UDim2.fromOffset(0, 0) or UDim2.fromOffset(p.Icon and 42 or 8, 3),
			Size = p.Centered and UDim2.fromScale(1, 1) or UDim2.new(1, p.Icon and -50 or -16, 1, -6),
			TextSize = p.TextSize or 22,
			Small = p.Small,
			ZIndex = 30,
		})
	end
	if p.Icon then
		children.Icon = e(
			U.Icon,
			{ Kind = p.Icon, Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(32, 32), ZIndex = 30 }
		)
	end
	return e("TextButton", props, {
		Visual = e(U.Surface, {
			Color = p.Disabled and Theme.Colors.Slate or (p.Color or Theme.Colors.Green),
			Radius = p.Radius or Theme.Radius,
			Shine = p.Shine,
			Motion = progress,
			Children = children,
			Studs = p.Studs,
			ZIndex = p.ZIndex or 20,
		}),
	})
end
-- A tile that can be pressed. It is the same plate as a button, but the
-- content is given by the caller: the cards of the collection grids are
-- tiles, not buttons.
function U.Tile(p)
	local reduced = React.useContext(U.MotionContext)
	local motionProps = table.clone(p)
	motionProps.ReducedMotion = reduced or p.ReducedMotion
	local progress, events = Hooks.useButtonMotion(motionProps, Theme)
	local props = {
		Name = p.Name or "Tile",
		Text = "",
		BackgroundTransparency = 1,
		Size = p.Size,
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		AutoButtonColor = false,
		Active = not p.Disabled,
		Selectable = not p.Disabled,
		ZIndex = p.ZIndex or 20,
		[React.Event.Activated] = function()
			if not p.Disabled and p.OnActivated then
				p.OnActivated()
			end
		end,
	}
	for key, value in events do
		props[key] = value
	end
	return e("TextButton", props, {
		Visual = e(U.Surface, {
			Color = p.Color or Theme.Body,
			Radius = p.Radius or Theme.Radius,
			Studs = p.Studs,
			Quiet = p.Quiet,
			Selected = p.Selected,
			Outline = p.Outline,
			Motion = progress,
			Children = p.Children,
			ZIndex = p.ZIndex or 20,
		}),
	})
end
-- The red cross of the reference windows: the drawing from the shared atlas
-- hangs over the corner of the window, exactly like on the Settings and
-- Balls panels. A transparent plate carries it, so only the picture of the
-- game is on screen.
function U.CloseButton(p)
	local reduced = React.useContext(U.MotionContext)
	local motionProps = table.clone(p)
	motionProps.ReducedMotion = reduced or p.ReducedMotion
	local progress, events = Hooks.useButtonMotion(motionProps, Theme)
	local props = {
		Name = p.Name or "Close",
		Text = "",
		BackgroundTransparency = 1,
		Size = p.Size or UDim2.fromOffset(Theme.CloseSize, Theme.CloseSize),
		Position = p.Position,
		AnchorPoint = p.AnchorPoint,
		AutoButtonColor = false,
		Selectable = false,
		ZIndex = p.ZIndex or 20,
		[React.Event.Activated] = function()
			if p.OnActivated then
				p.OnActivated()
			end
		end,
	}
	for key, value in events do
		props[key] = value
	end
	return e("TextButton", props, {
		Visual = e(U.Surface, {
			Color = Theme.Colors.Red,
			Radius = p.Radius or 12,
			Transparency = 1,
			Quiet = true,
			NoShadow = true,
			Studs = false,
			Motion = progress,
			ZIndex = p.ZIndex or 20,
			Children = {
				X = e(U.Icon, {
					Kind = "Close",
					Position = UDim2.fromOffset(0, 0),
					Size = UDim2.fromScale(1, 1),
					ZIndex = 30,
				}),
			},
		}),
	})
end
function U.FloatingIcon(p)
	local time, updateTime = React.useBinding(0)
	React.useEffect(function()
		if p.Reduced then
			updateTime(0)
			return
		end
		local start = os.clock()
		local connection = Run.RenderStepped:Connect(function()
			updateTime(os.clock() - start)
		end)
		return function()
			connection:Disconnect()
		end
	end, { p.Reduced == true })
	return e(U.Icon, {
		Kind = p.Kind,
		Size = p.Size,
		AnchorPoint = p.AnchorPoint,
		Position = time:map(function(t)
			return (p.Position or UDim2.new()) + UDim2.fromOffset(0, math.round(math.sin(t * 1.4) * 4))
		end),
		Rotation = time:map(function(t)
			return math.sin(t * 0.8) * 3
		end),
	})
end
local function fallbackPet(def)
	local m = Instance.new("Model")
	local function part(name, size, pos, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Color = color
		p.Anchored = true
		p.CanCollide = false
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = m
		return p
	end
	local fur = def.color or C(255, 203, 71)
	part("Body", Vector3.new(2.4, 2.1, 2), Vector3.zero, fur)
	for _, side in { -1, 1 } do
		part("Ear", Vector3.new(0.65, def.id == "Bunny" and 1.8 or 0.8, 0.7), Vector3.new(side * 0.8, 1.2, 0), fur)
		part("Eye", Vector3.new(0.45, 0.6, 0.1), Vector3.new(side * 0.52, 0.2, -1.04), C(18, 23, 38))
		part("Highlight", Vector3.new(0.13, 0.18, 0.04), Vector3.new(side * 0.52 - 0.08, 0.35, -1.1), C(255, 255, 255))
		part("Foot", Vector3.new(0.65, 0.35, 0.7), Vector3.new(side * 0.65, -1.15, -0.4), fur)
		if def.id == "Dragon" then
			local wing = part("Wing", Vector3.new(1, 0.15, 1.4), Vector3.new(side * 1.55, 0.2, 0.2), fur)
			wing.CFrame *= CFrame.Angles(0, 0, side * 0.5)
		end
	end
	part("Nose", Vector3.new(0.3, 0.2, 0.1), Vector3.new(0, -0.35, -1.08), C(110, 70, 59))
	m.WorldPivot = CFrame.identity
	return m
end
function U.PetView(p)
	local ref = React.useRef(nil)
	React.useEffect(function()
		local viewport = ref.current
		local model = Visuals.create(p.Def.visual or p.Def.id, 2.8) or fallbackPet(p.Def)
		local world = Instance.new("WorldModel")
		world.Parent = viewport
		model.Parent = world
		local cf, size = model:GetBoundingBox()
		model.WorldPivot = cf
		model:PivotTo(CFrame.identity)
		local camera = Instance.new("Camera")
		camera.FieldOfView = 34
		local radius = math.max(size.X, size.Y, size.Z) * 0.54
		camera.CFrame =
			CFrame.lookAt(Vector3.new(0.7, 0.4, -1).Unit * radius / math.tan(math.rad(17)) * 1.3, Vector3.zero)
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		local connection
		if p.Animated and not p.ReducedMotion then
			local start = os.clock()
			connection = Run.RenderStepped:Connect(function()
				local t = os.clock() - start
				model:PivotTo(
					CFrame.new(0, math.sin(t * 1.7) * 0.07, 0) * CFrame.Angles(0, math.sin(t * 0.65) * 0.16, 0)
				)
			end)
		end
		return function()
			if connection then
				connection:Disconnect()
			end
			world:Destroy()
			camera:Destroy()
		end
	end, { p.Def.id, p.Def.visual or "", p.Key or "", p.Animated == true, p.ReducedMotion == true })
	return e("ViewportFrame", {
		ref = ref,
		Name = "PetPreview",
		BackgroundTransparency = 1,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position,
		ZIndex = p.ZIndex or 15,
		Ambient = C(210, 216, 235),
		LightColor = C(255, 245, 225),
		LightDirection = Vector3.new(-1, -1, -1),
		Active = false,
	})
end
-- Flat stand ins for the 3D pet previews. The collection grid holds sixty
-- pets, so sixty render targets are out of the question: every card draws
-- this vector glyph instead. The shape belongs to the pet, the colour comes
-- from the pet itself.
local EYE = C(26, 30, 44)
local GOLD = C(255, 214, 92)
local BEAK = C(255, 196, 70)
local BLOSSOM = C(255, 96, 128)
local GLITCH = C(111, 255, 20)

local function join(first: { Part }, second: { Part }): { Part }
	local all: { Part } = {}
	for _, item in first do
		table.insert(all, item)
	end
	for _, item in second do
		table.insert(all, item)
	end
	return all
end

-- The shared silhouettes. The pets that only differ by their element reuse
-- the shape of their family and add their own mark.
local CAT: { Part } = {
	{ x = 0.28, y = 0.26, w = 0.18, h = 0.26, round = 0.25, rot = -20, shade = -0.15 },
	{ x = 0.72, y = 0.26, w = 0.18, h = 0.26, round = 0.25, rot = 20, shade = -0.15 },
	{ x = 0.5, y = 0.56, w = 0.5, h = 0.5, round = 1 },
	{ x = 0.39, y = 0.52, w = 0.1, h = 0.12, round = 1, color = EYE },
	{ x = 0.61, y = 0.52, w = 0.1, h = 0.12, round = 1, color = EYE },
	{ x = 0.5, y = 0.68, w = 0.09, h = 0.07, round = 1, color = EYE },
}

local DRAGON: { Part } = {
	{ x = 0.18, y = 0.5, w = 0.28, h = 0.16, round = 0.6, rot = -28, shade = -0.2 },
	{ x = 0.82, y = 0.5, w = 0.28, h = 0.16, round = 0.6, rot = 28, shade = -0.2 },
	{ x = 0.36, y = 0.22, w = 0.11, h = 0.2, round = 0.2, rot = -14, shade = 0.45 },
	{ x = 0.64, y = 0.22, w = 0.11, h = 0.2, round = 0.2, rot = 14, shade = 0.45 },
	{ x = 0.5, y = 0.56, w = 0.46, h = 0.46, round = 1 },
	{ x = 0.4, y = 0.53, w = 0.09, h = 0.09, round = 1, color = EYE },
	{ x = 0.6, y = 0.53, w = 0.09, h = 0.09, round = 1, color = EYE },
	{ x = 0.5, y = 0.72, w = 0.2, h = 0.13, round = 0.6, shade = 0.35 },
}

local PET_GLYPHS: { [string]: { Part } } = {
	Dog = {
		{ x = 0.2, y = 0.42, w = 0.16, h = 0.4, round = 1, rot = -22, shade = -0.2 },
		{ x = 0.8, y = 0.42, w = 0.16, h = 0.4, round = 1, rot = 22, shade = -0.2 },
		{ x = 0.5, y = 0.56, w = 0.52, h = 0.52, round = 1 },
		{ x = 0.5, y = 0.74, w = 0.24, h = 0.18, round = 1, shade = 0.35 },
		{ x = 0.5, y = 0.7, w = 0.11, h = 0.09, round = 1, color = EYE },
		{ x = 0.38, y = 0.5, w = 0.08, h = 0.08, round = 1, color = EYE },
		{ x = 0.62, y = 0.5, w = 0.08, h = 0.08, round = 1, color = EYE },
	},
	Cat = CAT,
	Bunny = {
		{ x = 0.34, y = 0.22, w = 0.14, h = 0.4, round = 1, rot = -8 },
		{ x = 0.66, y = 0.22, w = 0.14, h = 0.4, round = 1, rot = 8 },
		{ x = 0.34, y = 0.24, w = 0.06, h = 0.28, round = 1, rot = -8, shade = 0.4 },
		{ x = 0.66, y = 0.24, w = 0.06, h = 0.28, round = 1, rot = 8, shade = 0.4 },
		{ x = 0.5, y = 0.62, w = 0.5, h = 0.5, round = 1 },
		{ x = 0.4, y = 0.6, w = 0.08, h = 0.08, round = 1, color = EYE },
		{ x = 0.6, y = 0.6, w = 0.08, h = 0.08, round = 1, color = EYE },
		{ x = 0.5, y = 0.74, w = 0.08, h = 0.06, round = 1, color = EYE },
	},
	Fox = {
		{ x = 0.27, y = 0.24, w = 0.2, h = 0.28, round = 0.2, rot = -24, shade = -0.2 },
		{ x = 0.73, y = 0.24, w = 0.2, h = 0.28, round = 0.2, rot = 24, shade = -0.2 },
		{ x = 0.5, y = 0.54, w = 0.5, h = 0.5, round = 1 },
		{ x = 0.5, y = 0.74, w = 0.22, h = 0.2, round = 1, shade = 0.45 },
		{ x = 0.5, y = 0.68, w = 0.1, h = 0.08, round = 1, color = EYE },
		{ x = 0.38, y = 0.5, w = 0.09, h = 0.09, round = 1, color = EYE },
		{ x = 0.62, y = 0.5, w = 0.09, h = 0.09, round = 1, color = EYE },
	},
	Dragon = DRAGON,
	Cactus = {
		{ x = 0.27, y = 0.52, w = 0.13, h = 0.32, round = 1, shade = -0.08 },
		{ x = 0.73, y = 0.52, w = 0.13, h = 0.32, round = 1, shade = -0.08 },
		{ x = 0.5, y = 0.56, w = 0.28, h = 0.72, round = 1 },
		{ x = 0.44, y = 0.52, w = 0.07, h = 0.07, round = 1, color = EYE },
		{ x = 0.56, y = 0.52, w = 0.07, h = 0.07, round = 1, color = EYE },
		{ x = 0.5, y = 0.16, w = 0.16, h = 0.16, round = 1, color = BLOSSOM },
	},
	Frog = {
		{ x = 0.5, y = 0.64, w = 0.68, h = 0.46, round = 1 },
		{ x = 0.34, y = 0.28, w = 0.24, h = 0.24, round = 1, shade = 0.2 },
		{ x = 0.66, y = 0.28, w = 0.24, h = 0.24, round = 1, shade = 0.2 },
		{ x = 0.34, y = 0.3, w = 0.11, h = 0.11, round = 1, color = EYE },
		{ x = 0.66, y = 0.3, w = 0.11, h = 0.11, round = 1, color = EYE },
		{ x = 0.5, y = 0.8, w = 0.26, h = 0.08, round = 1, shade = -0.3 },
	},
	Watermelon = {
		{ x = 0.5, y = 0.58, w = 0.64, h = 0.64, round = 1 },
		{ x = 0.38, y = 0.58, w = 0.07, h = 0.58, round = 1, shade = -0.35 },
		{ x = 0.5, y = 0.58, w = 0.07, h = 0.62, round = 1, shade = -0.35 },
		{ x = 0.62, y = 0.58, w = 0.07, h = 0.58, round = 1, shade = -0.35 },
		{ x = 0.5, y = 0.22, w = 0.07, h = 0.16, round = 0.3, rot = 10, shade = -0.45 },
	},
	GreenDragon = join({ { x = 0.5, y = 0.16, w = 0.12, h = 0.18, round = 0.2, shade = -0.2 } }, DRAGON),
	Shark = {
		{ x = 0.5, y = 0.18, w = 0.16, h = 0.24, round = 0.2, shade = -0.2 },
		{ x = 0.16, y = 0.62, w = 0.2, h = 0.13, round = 0.5, rot = -22, shade = -0.15 },
		{ x = 0.84, y = 0.62, w = 0.2, h = 0.13, round = 0.5, rot = 22, shade = -0.15 },
		{ x = 0.5, y = 0.58, w = 0.58, h = 0.5, round = 1 },
		{ x = 0.5, y = 0.76, w = 0.3, h = 0.1, round = 0.5, shade = -0.35 },
		{ x = 0.38, y = 0.52, w = 0.08, h = 0.08, round = 1, color = EYE },
		{ x = 0.62, y = 0.52, w = 0.08, h = 0.08, round = 1, color = EYE },
	},
	CloudBird = {
		{ x = 0.2, y = 0.5, w = 0.24, h = 0.32, round = 1, rot = -22, shade = 0.25 },
		{ x = 0.8, y = 0.5, w = 0.24, h = 0.32, round = 1, rot = 22, shade = 0.25 },
		{ x = 0.5, y = 0.54, w = 0.46, h = 0.46, round = 1 },
		{ x = 0.5, y = 0.72, w = 0.13, h = 0.11, round = 0.3, color = BEAK },
		{ x = 0.4, y = 0.5, w = 0.08, h = 0.08, round = 1, color = EYE },
		{ x = 0.6, y = 0.5, w = 0.08, h = 0.08, round = 1, color = EYE },
	},
	Butterfly = {
		{ x = 0.26, y = 0.44, w = 0.34, h = 0.42, round = 1, rot = -16, shade = 0.2 },
		{ x = 0.74, y = 0.44, w = 0.34, h = 0.42, round = 1, rot = 16, shade = 0.2 },
		{ x = 0.22, y = 0.4, w = 0.12, h = 0.12, round = 1, color = WHITE },
		{ x = 0.78, y = 0.4, w = 0.12, h = 0.12, round = 1, color = WHITE },
		{ x = 0.5, y = 0.56, w = 0.11, h = 0.48, round = 1, shade = -0.35 },
	},
	AngelCat = join({ { x = 0.5, y = 0.1, w = 0.38, h = 0.13, round = 1, color = GOLD } }, CAT),
	IceCat = join({
		{ x = 0.2, y = 0.34, w = 0.11, h = 0.26, round = 0.15, rot = -18, shade = 0.45 },
		{ x = 0.8, y = 0.34, w = 0.11, h = 0.26, round = 0.15, rot = 18, shade = 0.45 },
	}, CAT),
	MoonCat = join({
		{ x = 0.78, y = 0.2, w = 0.26, h = 0.26, round = 1, shade = 0.55 },
		{ x = 0.85, y = 0.15, w = 0.22, h = 0.22, round = 1, back = true },
	}, CAT),
	GalaxyCat = join({
		{ x = 0.2, y = 0.2, w = 0.12, h = 0.12, rot = 45, shade = 0.6 },
		{ x = 0.85, y = 0.3, w = 0.09, h = 0.09, rot = 45, shade = 0.6 },
		{ x = 0.3, y = 0.09, w = 0.07, h = 0.07, rot = 45, shade = 0.5 },
	}, CAT),
	CrystalCat = join({
		{ x = 0.22, y = 0.32, w = 0.1, h = 0.24, round = 0.15, rot = -16, shade = 0.5 },
		{ x = 0.78, y = 0.32, w = 0.1, h = 0.24, round = 0.15, rot = 16, shade = 0.5 },
	}, CAT),
	AdminDragon = join({ { x = 0.5, y = 0.56, w = 0.62, h = 0.1, rot = -8, color = GLITCH } }, DRAGON),
	Default = {
		{ x = 0.24, y = 0.3, w = 0.18, h = 0.22, round = 0.3, rot = -18, shade = -0.15 },
		{ x = 0.76, y = 0.3, w = 0.18, h = 0.22, round = 0.3, rot = 18, shade = -0.15 },
		{ x = 0.5, y = 0.58, w = 0.52, h = 0.52, round = 1 },
		{ x = 0.39, y = 0.54, w = 0.09, h = 0.09, round = 1, color = EYE },
		{ x = 0.61, y = 0.54, w = 0.09, h = 0.09, round = 1, color = EYE },
		{ x = 0.5, y = 0.7, w = 0.09, h = 0.07, round = 1, color = EYE },
	},
}

local function glyphColor(item: Part, base: Color3): Color3
	if item.color then
		return item.color
	end
	local shade = item.shade or 0
	if shade < 0 then
		return base:Lerp(Color3.new(0, 0, 0), -shade)
	end
	if shade > 0 then
		return base:Lerp(Color3.new(1, 1, 1), shade)
	end
	return base
end

-- The flat shape of a pet, drawn from a handful of primitives.
function U.PetGlyph(p)
	local base = p.Color or Theme.Colors.Pets
	local back = p.Background or base
	local recipe = PET_GLYPHS[p.Key or ""] or PET_GLYPHS.Default
	local children = {}
	for index, item in recipe do
		children["Shape" .. index] = e("Frame", {
			Name = "Shape" .. index,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(item.x, item.y),
			Size = UDim2.fromScale(item.w, item.h),
			BackgroundColor3 = if item.back then back else glyphColor(item, base),
			BorderSizePixel = 0,
			Rotation = item.rot or 0,
			ZIndex = (p.ZIndex or 15) + 1,
		}, { Corner = e("UICorner", { CornerRadius = UDim.new(item.round or 0, 0) }) })
	end
	return e("Frame", {
		Name = "PetGlyph",
		BackgroundTransparency = 1,
		Position = p.Position,
		Size = p.Size or UDim2.fromScale(1, 1),
		ZIndex = p.ZIndex or 15,
	}, children)
end

-- A cheap two dimensional stand in for the 3D preview. The collection grid
-- uses it so sixty pets cost sixty labels instead of sixty render targets.
function U.PetBadge(p)
	local def = p.Def
	local color = def and def.color or Theme.Colors.Pets
	-- The disc is a dark medallion: the glyph of the pet has to read on it.
	local disc = color:Lerp(Theme.Outline, 0.62)
	local z = p.ZIndex or 15
	local key = (def and (def.visual or def.id)) or "Default"
	local rarity = p.Rarity or (def and def.rarity) or "Common"
	local rarityColor = Theme.Rarity[rarity] or Theme.Colors.Pets
	return e("Frame", {
		Name = "PetBadge",
		Position = p.Position,
		Size = p.Size or UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = z,
	}, {
		Disc = e("Frame", {
			Name = "Disc",
			Position = UDim2.fromOffset(4, 4),
			Size = UDim2.new(1, -8, 1, -8),
			BackgroundColor3 = disc,
			BorderSizePixel = 0,
			ZIndex = z + 1,
		}, { Corner = U.corner(999) }),
		Art = e(U.PetGlyph, {
			Key = key,
			Color = color,
			Background = disc,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.66, 0.66),
			ZIndex = z + 2,
		}),
		Rarity = e("Frame", {
			Name = "Rarity",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromScale(0.26, 0.26),
			BackgroundColor3 = rarityColor,
			BorderSizePixel = 0,
			ZIndex = z + 3,
		}, {
			Corner = U.corner(999),
			Outline = e("UIStroke", {
				Thickness = 2,
				Color = Theme.Outline,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Letter = e("TextLabel", {
				Name = "Letter",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = string.sub(rarity, 1, 1),
				Font = Enum.Font.FredokaOne,
				TextScaled = true,
				TextColor3 = Theme.Outline,
				ZIndex = z + 4,
			}, { Limit = e("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 8 }) }),
		}),
	})
end
function U.Scroll(p)
	return e("ScrollingFrame", {
		Name = p.Name or "Scroll",
		Size = p.Size,
		Position = p.Position,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = Theme.Gold,
		ScrollBarImageTransparency = 0.15,
		CanvasSize = UDim2.fromOffset(0, p.Height or 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 10,
		ClipsDescendants = true,
	}, p.Children)
end
function U.TrailPreview(p)
	local ref = React.useRef(nil)
	React.useEffect(function()
		local viewport = ref.current
		local world = Instance.new("WorldModel")
		world.Parent = viewport
		local function part(size, cf, color)
			local piece = Instance.new("Part")
			piece.Size = size
			piece.CFrame = cf
			piece.Color = color
			piece.Anchored = true
			piece.CanCollide = false
			piece.Material = Enum.Material.SmoothPlastic
			piece.Parent = world
			return piece
		end
		part(Vector3.new(1, 1, 1), CFrame.new(1.8, 1.7, 0), C(255, 210, 71))
		part(Vector3.new(1.4, 1.4, 0.75), CFrame.new(1.8, 0.5, 0) * CFrame.Angles(0, 0, -0.15), C(39, 148, 244))
		for _, side in { -1, 1 } do
			part(
				Vector3.new(0.5, 1.2, 0.5),
				CFrame.new(1.8 + side * 0.47, -0.65, 0) * CFrame.Angles(0, 0, side * 0.45),
				C(44, 78, 123)
			)
			part(
				Vector3.new(0.5, 1.2, 0.5),
				CFrame.new(1.8 + side * 0.93, 0.5, 0) * CFrame.Angles(0, 0, -side * 0.7),
				C(255, 210, 71)
			)
		end
		for strand = 1, 3 do
			for i = 1, 10 do
				local t = i / 10
				local color = p.Rainbow and Color3.fromHSV((t + strand / 5) % 1, 0.7, 1) or p.Color
				local v = Vector3.new(1.1 - t * 5, 0.1 + math.sin(t * 3.5 + strand) * 0.22, (strand - 2) * 0.38)
				local piece = part(Vector3.new(0.75, 0.08 + (1 - t) * 0.13, 0.25), CFrame.new(v), color)
				piece.Material = Enum.Material.Neon
				piece.Transparency = t * 0.4
			end
		end
		local camera = Instance.new("Camera")
		camera.FieldOfView = 34
		camera.CFrame = CFrame.lookAt(Vector3.new(1, 4, -12), Vector3.new(-0.5, 0.3, 0))
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		return function()
			world:Destroy()
			camera:Destroy()
		end
	end, { p.Color, p.Rainbow == true })
	return e("ViewportFrame", {
		Name = "TrailPreview",
		ref = ref,
		BackgroundTransparency = 1,
		Size = p.Size,
		Position = p.Position,
		ZIndex = 16,
		Ambient = C(210, 220, 235),
		LightColor = Color3.new(1, 1, 1),
		Active = false,
	})
end
return U
