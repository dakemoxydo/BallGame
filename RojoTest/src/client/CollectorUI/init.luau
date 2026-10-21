--!strict
local Players = game:GetService("Players")
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local _Config = require(game.ReplicatedStorage.Shared.GameConfig)
local U = require(script.Components)
local T = require(script.Theme)
local Screens = require(script.Screens)
local GuiInsets = require(script.Parent.Modules.GuiInsets)
local e = React.createElement
local UI = {}
-- ReactRoblox mounts the children of an element in the hash order of the
-- props table, so the stacking of the canvas must never depend on the order
-- of the keys: every layer carries its own ZIndex. The dim behind the window
-- stays below the window, the window stays below the tab bar.
local LAYER_BLOCKER = 25
local LAYER_WINDOW = 30
local LAYER_NAVIGATION = 50
local navigation = {
	{ "Shop", "Shop" },
	{ "Pets", "Pets" },
	{ "Eggs", "Egg" },
	{ "Trails", "Trails" },
	-- The third name is the short one under the icon: the screen of the balls
	-- is called "Balls" in the game itself.
	{ "Inventory", "Inventory", "Balls" },
	{ "Rebirth", "Rebirth" },
	{ "Gifts", "Gifts" },
}
-- The windows of the collector are copies of the Settings and Balls panels:
-- a translucent slate plate of a fixed size in the 1280x720 design space of
-- the HUD, with the heading floating over the upper edge, the icon over the
-- left corner and the red cross of the game over the right one.
local WINDOW_WIDTH = 680
local WINDOW_HEIGHT = 470
local WINDOW_MARGIN = 70

type WindowProps = {
	Kind: string,
	Title: string,
	Width: number,
	Height: number,
	DesignScale: number,
	CenterX: number,
	CenterY: number,
	Visible: boolean,
	Reduced: boolean,
	Close: () -> (),
	Settled: () -> (),
	Children: { [string]: any },
}

local function Window(p: WindowProps)
	-- The window remembers whether it was ever on screen: a spring that gets
	-- the goal it already has never moves and never reports a rest.
	local wasVisible = React.useRef(false)
	local progress, goal = U.Hooks.useSpringBinding(0, { Frequency = 4.5, DampingRatio = 1 }, p.Reduced, function(value)
		if value == 0 and not p.Visible then
			p.Settled()
		end
	end)
	React.useEffect(function()
		if p.Visible then
			wasVisible.current = true
			goal(1)
		elseif wasVisible.current then
			-- The window is closing: the spring animates it out and reports
			-- the rest, so the state is cleared by the callback.
			goal(0)
		else
			-- The window mounts already closed. A spring whose goal does not
			-- change never reports a rest, so the state is cleared here.
			goal(0)
			p.Settled()
		end
	end, { p.Visible })
	local w, h = p.Width, p.Height
	local margin = WINDOW_MARGIN
	local chrome = {
		Icon = e(U.Icon, {
			-- The corner icon of the reference panels: it hangs over the top
			-- left corner of the plate.
			Kind = (p.Kind == "Eggs" or p.Kind == "Hatch") and "Egg" or p.Kind,
			Position = UDim2.fromOffset(WINDOW_MARGIN - 15, WINDOW_MARGIN - 54),
			Size = UDim2.fromOffset(100, 100),
			ZIndex = 20,
		}),
		Title = e(U.Label, {
			Name = "Title",
			Text = p.Title,
			-- The heading of the reference panels stands half above the upper
			-- edge of the plate and keeps the corners clear for the icon and
			-- the cross.
			Position = UDim2.fromOffset(WINDOW_MARGIN + 85, WINDOW_MARGIN - 50),
			Size = UDim2.fromOffset(w - 170, 66),
			TextSize = T.TitleSize,
			Scaled = true,
			MinTextSize = T.TitleMin,
			MaxTextSize = T.TitleSize,
			ZIndex = 20,
		}),
		Close = e(U.CloseButton, {
			-- The cross of the reference panels hangs half above the top right
			-- corner of the plate.
			Position = UDim2.fromOffset(WINDOW_MARGIN + w - 32, WINDOW_MARGIN - 31),
			Size = UDim2.fromOffset(60, 60),
			OnActivated = p.Close,
			ZIndex = 20,
		}),
	}
	-- The plate inside the group carries a margin, so the chrome can hang over
	-- the plate edges without being clipped by the group.
	local frameW, frameH = w + margin * 2, h + margin * 2
	local realW = math.round(frameW * p.DesignScale)
	local realH = math.round(frameH * p.DesignScale)
	local rise = math.max(6, math.round(24 * p.DesignScale))
	return e("CanvasGroup", {
		Name = "CollectorWindow",
		Size = UDim2.fromOffset(realW, realH),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = progress:map(function(value)
			return UDim2.fromOffset(math.round(p.CenterX), math.round(p.CenterY + (1 - math.clamp(value, 0, 1)) * rise))
		end),
		GroupTransparency = progress:map(function(value)
			return 1 - math.clamp(value, 0, 1)
		end),
		Interactable = p.Visible,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = LAYER_WINDOW,
	}, {
		Design = e("Frame", {
			Name = "Design",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(frameW, frameH),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = LAYER_WINDOW,
		}, {
			-- The design pixels of the reference panels become real ones at
			-- the same factor the HUD board uses.
			Fit = e("UIScale", { Scale = p.DesignScale }),
			Zoom = e("Frame", {
				Name = "Zoom",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(frameW, frameH),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = LAYER_WINDOW,
			}, {
				ZoomScale = e("UIScale", {
					Scale = progress:map(function(value)
						return 0.92 + 0.08 * math.clamp(value, 0, 1)
					end),
				}),
				-- The plate of the reference panels: a translucent slate fill
				-- with a two pixel ink edge and squared corners.
				Shell = e("Frame", {
					Name = "WindowShell",
					Position = UDim2.fromOffset(margin, margin),
					Size = UDim2.fromOffset(w, h),
					BackgroundColor3 = T.Body,
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					ZIndex = 1,
				}, {
					Edge = e("UIStroke", {
						Thickness = T.WindowStroke,
						Color = T.Outline,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
					Content = e("Frame", {
						Name = "ScreenContent",
						Position = UDim2.fromOffset(12, 68),
						Size = UDim2.fromOffset(w - 24, h - 80),
						BackgroundTransparency = 1,
						ZIndex = 10,
					}, p.Children),
				}),
				-- The chrome hangs over the shell: the icon over the top left
				-- corner, the heading over the top edge and the cross over the
				-- top right one. A table of children has to be spread over the
				-- parent: a nested table is not a valid child.
				Icon = chrome.Icon,
				Title = chrome.Title,
				Close = chrome.Close,
			}),
		}),
	})
end
function UI.mount(context)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CollectorUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	GuiInsets.prepare(gui)
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer.PlayerGui
	local root = ReactRoblox.createRoot(gui)
	local handle =
		{ Snapshot = nil, Active = nil, View = nil, Serial = 0, Pending = nil, EggId = "Common", Hidden = false }
	local render
	local function request(command, value, extra)
		if handle.Pending then
			return
		end
		handle.Pending = command
		handle.PendingAt = os.clock()
		context.send(command, value, extra)
		render()
		local requestAt = handle.PendingAt
		task.delay(5, function()
			if handle.PendingAt == requestAt and handle.Pending then
				handle.Pending = nil
				render()
			end
		end)
	end
	local function App()
		local area, setArea = React.useState(Vector2.zero)
		local inset, setInset = React.useState(Vector2.zero)
		local data = handle.Snapshot and handle.Snapshot.data
		local inventory = handle.Snapshot and handle.Snapshot.inventory
		local view = handle.View
		local children = {}
		local function open(name)
			context.open(name)
		end
		local portrait = area.X > 0 and area.X < area.Y
		local compact = area.Y < 520 or area.X < 750
		local navSize = compact and 60 or 74
		-- The upper edge of the tab row. The window of an open screen ends
		-- above it, so the two never touch.
		local navTop = area.Y
		local navVisible = not handle.Hidden
			and (view == nil or handle.Active ~= nil)
			and (not data or not data.settings.hideHUD)
		if navVisible and area.X > 0 then
			local size = navSize
			local navItems = {}
			local entries = view and { navigation[1], navigation[2], navigation[3], navigation[4] } or navigation
			-- The navigation has to fit the width of the screen. The buttons
			-- shrink to the width that is left and the gap tightens with them,
			-- but a touch target never goes below 44 pixels. A screen that is
			-- too narrow for that keeps the scrolling row.
			local count = #entries
			local available = area.X - 24
			local gap = 10
			local fitted = math.floor((available - (count - 1) * gap) / count)
			if fitted < size then
				for _, tight in { 6, 4 } do
					local candidate = math.floor((available - (count - 1) * tight) / count)
					if candidate > fitted then
						fitted = candidate
						gap = tight
					end
					if candidate >= size then
						break
					end
				end
			end
			local scrollable = fitted < 44
			if scrollable then
				fitted = 44
				gap = 10
			else
				size = math.min(size, fitted)
			end
			-- A narrow button cannot carry the long name of a tab.
			local narrow = size < 54
			for i, item in entries do
				local x, y
				if compact or view or portrait then
					x, y = (i - 1) * (size + gap), 0
				else
					x, y = ((i - 1) % 2) * (size + gap), math.floor((i - 1) / 2) * (size + 12)
				end
				navItems[item[1]] = e(U.Button, {
					Name = "Nav" .. item[1],
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(size, size),
					Color = T.Colors[item[1]] or T.Colors.Blue,
					Studs = true,
					OnActivated = function()
						open(item[1])
					end,
					Children = {
						Art = e(U.Icon, {
							Kind = item[2],
							Position = UDim2.fromOffset(5, -2),
							Size = UDim2.fromOffset(size - 10, size - 18),
							ZIndex = 30,
						}),
						Caption = e(U.Label, {
							-- The long name of a tab does not fit under its
							-- icon: the short one is the name of the screen.
							Text = item[3] or item[1],
							TextSize = narrow and 11 or math.max(15, math.floor(size * 0.25)),
							Position = UDim2.fromOffset(2, size - 26),
							Size = UDim2.fromOffset(size - 4, 24),
							ZIndex = 30,
						}),
					},
				})
			end
			local horizontal = compact or view ~= nil or portrait
			local nw = horizontal and (count * (size + gap) - gap) or size * 2 + gap
			local navY
			if view or portrait then
				-- An open screen owns the top of the window: its title floats
				-- over the upper edge, so the tab row moves to the bottom of
				-- the screen and the window is placed above it.
				navY = area.Y - size - 16
			elseif compact then
				navY = 4
			else
				navY = math.max(85, math.floor(area.Y * 0.30))
			end
			navTop = navY
			if scrollable then
				children.Navigation = e("ScrollingFrame", {
					Name = "Navigation",
					Position = UDim2.fromOffset(12, navY),
					Size = UDim2.fromOffset(area.X - 24, size + 10),
					CanvasSize = UDim2.fromOffset(nw, 0),
					ScrollingDirection = Enum.ScrollingDirection.X,
					ScrollBarThickness = 3,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = LAYER_NAVIGATION,
				}, navItems)
			else
				children.Navigation = e("Frame", {
					Name = "Navigation",
					Position = UDim2.new(horizontal and 0.5 or 0, horizontal and -math.floor(nw / 2) or 16, 0, navY),
					Size = UDim2.fromOffset(nw, horizontal and size or (size + 12) * 4),
					BackgroundTransparency = 1,
					ZIndex = LAYER_NAVIGATION,
				}, navItems)
			end
		end
		if view and data and area.X > 120 and area.Y > 160 then
			-- The window is built in the design space of the reference panels:
			-- the plate is 680x470 and the HUD board scales it to the screen.
			local designScale = math.max(0.05, math.min(area.X / 1280, area.Y / 720))
			local w = WINDOW_WIDTH
			local h = WINDOW_HEIGHT
			-- The plate half stands below the middle of the screen. The chrome
			-- hangs 54 pixels above the upper edge, so the plate itself starts
			-- under the safe top; when a screen is open the tab row owns the
			-- bottom and the plate has to end above it.
			local halfH = h / 2 * designScale
			local navBottom = (navVisible and navTop > 0) and (navTop - 10) or (area.Y - 12)
			local topLimit = 56 * designScale
			local factor = 1
			if navBottom - topLimit < halfH * 2 then
				-- The reference panels are never rebuilt for a smaller screen:
				-- the whole modal keeps its proportions and scales down.
				factor = math.max(0.45, (navBottom - topLimit) / (halfH * 2))
			end
			local fitH = halfH * factor
			local centerY = math.clamp(area.Y / 2, topLimit + fitH, math.max(topLimit + fitH, navBottom - fitH))
			-- The screen fills the plate. Only the collection grid asks for
			-- more room than it gets: its rows have a height of their own.
			local baseH = h - 80
			local contentHeight = baseH
			local short = baseH < 420
			local pets = inventory and inventory.pets or {}
			if view.Kind == "Pets" and short then
				local columns = w - 24 < 380 and 2 or 3
				contentHeight = math.ceil(math.max(9, #pets) / columns) * 152 + 86
			end
			local props = {
				Data = data,
				Inventory = inventory or { pets = {}, equipped = {} },
				Width = w - 24,
				Height = contentHeight,
				Request = request,
				Busy = handle.Pending ~= nil,
				Reduced = data.settings.effects == false,
				Short = short,
				EggId = handle.EggId,
				Open = open,
				Close = context.close,
				SelectEgg = function(id)
					handle.EggId = id
					context.selectEgg(id)
					render()
				end,
				Hatched = view.Hatched,
			}
			local kind = view.Kind
			local title = kind == "Hatch" and "Your new pets!" or kind
			local serial = view.Serial
			-- The blocker lives only while a screen is open: a modal dim that
			-- outlives the close would swallow every click of the game.
			if handle.Active ~= nil then
				children.Blocker = e("TextButton", {
					Name = "ModalBlocker",
					Text = "",
					AutoButtonColor = false,
					-- The reference panels do not dim the world: the blur and the
					-- translucent plate do the work, the blocker only swallows
					-- the clicks around the window.
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					-- Below the window: a modal dim in front of the window would
					-- swallow every click on the content underneath it.
					ZIndex = LAYER_BLOCKER,
					Modal = true,
				})
			end
			children.Window = e(Window, {
				key = kind .. serial,
				Kind = kind,
				Title = title,
				Width = w,
				Height = h,
				DesignScale = designScale * factor,
				CenterX = area.X / 2,
				CenterY = centerY,
				Visible = handle.Active ~= nil,
				Reduced = props.Reduced,
				Close = context.close,
				Settled = function()
					if handle.Serial == serial and handle.Active == nil then
						handle.View = nil
						render()
					end
				end,
				Children = {
					Screen = contentHeight > baseH and e(U.Scroll, {
						Name = "CompactScreenScroll",
						Size = UDim2.fromOffset(w - 24, baseH),
						Height = contentHeight + 6,
						Children = { Screen = e(Screens[kind], props) },
					}) or e(Screens[kind], props),
				},
			})
		end
		return e(U.MotionContext.Provider, { value = data and data.settings.effects == false }, {
			Area = e("Frame", {
				Name = "SafeArea",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				[React.Change.AbsoluteSize] = function(instance)
					local viewport = workspace.CurrentCamera.ViewportSize
					local safe = GuiInsets.area(viewport, instance)
					setArea(safe.size)
					setInset(safe.offset)
				end,
			}, {
				Inset = e("Frame", {
					Name = "Inset",
					Position = UDim2.fromOffset(inset.X, inset.Y),
					Size = UDim2.fromOffset(math.max(1, area.X), math.max(1, area.Y)),
					BackgroundTransparency = 1,
				}, children),
			}),
		})
	end
	render = function()
		if not handle.Destroyed and gui.Parent then
			root:render(e(App))
		end
	end
	function handle:update(snapshot)
		self.Snapshot = snapshot
		self.Pending = nil
		render()
	end
	function handle:request(command, value, extra)
		request(command, value, extra)
	end
	function handle:setHidden(hidden)
		if self.Hidden == hidden then
			return
		end
		self.Hidden = hidden
		render()
	end
	function handle:open(kind, eggId)
		self.Serial += 1
		self.Active = kind
		self.Pending = nil
		if eggId then
			self.EggId = eggId
		end
		self.View = { Kind = kind, Serial = self.Serial }
		render()
	end
	function handle:close()
		-- The view is cleared by the settle callback of the window, not here:
		-- clearing it now would skip the close animation.
		self.Active = nil
		self.Pending = nil
		render()
	end
	function handle:hatch(pets)
		self.Serial += 1
		self.Active = "Hatch"
		self.Pending = nil
		self.View = { Kind = "Hatch", Serial = self.Serial, Hatched = pets }
		render()
	end
	function handle:destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		self.Pending = nil
		root:unmount()
		gui:Destroy()
	end
	render()
	return handle
end
return UI
