--!strict
-- The admin panel only exists for an authorized player.
-- Nothing is created, no log listener is attached and no input is captured
-- until a snapshot says `isAdmin`, and every subscription is released when the
-- panel goes away.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Kit = require(script.Parent.Controllers.HudKit)
local Style = require(script.Parent.UiStyle)
local GuiInsets = require(script.Parent.Modules.GuiInsets)
local Net = require(game.ReplicatedStorage.Shared.Net)

local Panel = {}
local C = Color3.fromRGB
local white = C(255, 255, 255)
local TIMEOUT = 10
-- The window, the launcher and the test indicator are siblings of the
-- ScreenGui. Their layer is fixed by ZIndex, not by the order they were
-- created in: the window is always above the launcher.
local LAYER_WINDOW = 20
-- The window opens with a short scale and a short fade.
local OPEN_TIME = 0.18
local OPEN_SCALE = 0.94

-- The light of a brick: the gradient multiplies the fill of the plate, so the
-- bright end keeps the colour of the plate and the dark end deepens it.
local function topLight(plate: GuiObject, color: Color3)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(white, color)
	gradient.Parent = plate
end

-- A brick plate: a flat fill, the light from the top, the stud texture and
-- the chunky ink border of the style.
local function brick(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	radius: number?,
	studs: Color3?
): Frame
	local plate = Kit.frame(parent, name, x, y, w, h, color)
	Kit.corner(plate, radius or Style.Radius)
	topLight(plate, color)
	Kit.pattern(plate, studs or color)
	Kit.stroke(plate, Style.Stroke, Style.Ink)
	return plate
end

-- Kit.button builds the brick of the legacy HUD with a 7 px corner. The panel
-- uses the 9 px of the bricks of the style, so the corner is set afterwards.
local function brickButton(
	parent: Instance,
	name: string,
	value: string,
	x: number,
	y: number,
	w: number,
	h: number,
	color: Color3,
	size: number?,
	callback: (() -> ())?
): TextButton
	local button = Kit.button(parent, name, value, x, y, w, h, color, size, callback)
	local corner = Kit.cornerOf(button)
	if corner then
		corner.CornerRadius = UDim.new(0, Style.Radius)
	end
	local shadow = parent:FindFirstChild(name .. "Shadow")
	if shadow and shadow:IsA("GuiObject") then
		local shadowCorner = Kit.cornerOf(shadow)
		if shadowCorner then
			shadowCorner.CornerRadius = UDim.new(0, Style.Radius)
		end
	end
	return button
end

export type Context = {
	closePanel: () -> (),
	activate: () -> (),
}

function Panel.mount(context: Context)
	local authorized, testing, busy = false, false, false
	local window: any = nil
	local windowGroup: any = nil
	local statusLabel: any = nil
	local summary: any = nil
	local modeButton: any = nil
	local body: any = nil
	local launcher: any = nil
	local indicator: any = nil
	local status: any = {}
	local rows: any = nil
	local tab = "Проверки"
	local selectedEgg = "Uncommon"
	local clientLogs: { { ok: boolean, title: string, detail: string } } = {}
	local gui: ScreenGui? = nil
	local probe: Frame? = nil
	local connections: { RBXScriptConnection } = {}
	local pending: any = nil
	local remote: RemoteFunction? = nil
	local width, height, bodyWidth = 980, 620, 948
	local build, renderPage, request, open

	local function showStatus(message: string, color: Color3)
		if statusLabel and statusLabel.Parent then
			statusLabel.Text = message
			statusLabel.TextColor3 = color
		end
	end

	-- The gameplay remotes are the single source of truth for the contract.
	local function resolveRemote(): RemoteFunction?
		if remote then
			return remote
		end
		local ok, folder = pcall(function()
			return Net.client()
		end)
		if not ok then
			return nil
		end
		-- The server creates the admin remote when an authorized player
		-- enters, so it can still be on its way.
		local node = Net.adminClient(folder, 5)
		if node then
			remote = node
			return node
		end
		return nil
	end

	local function close()
		if window then
			window:Destroy()
			window = nil
		end
		if windowGroup then
			windowGroup:Destroy()
			windowGroup = nil
		end
		if launcher then
			launcher.Visible = authorized
			local shadow = probe and probe:FindFirstChild("AdminLauncherShadow")
			if shadow and shadow:IsA("GuiObject") then
				shadow.Visible = authorized
			end
		end
	end

	local function refreshSummary()
		if indicator then
			indicator.Visible = authorized and testing
		end
		if not window then
			return
		end
		local modeCaption = Kit.captionOf(modeButton)
		if modeCaption then
			modeCaption.Text = testing and "Завершить тест" or "Начать тест"
		end
		local mode = window:FindFirstChild("Mode")
		if mode and mode:IsA("TextLabel") then
			mode.Text = testing and "Тестовая копия прогресса"
				or "Основной прогресс защищён"
		end
		summary.Text = string.format(
			"Мир %s · Wins %s · Skill %s · RB %s · Петов %s/60",
			status.world or 1,
			Config.format(status.wins or 0),
			Config.format(status.skill or 0),
			status.rebirths or 0,
			status.pets or 0
		)
	end

	local function applyResult(result: any, command: string)
		if result.status then
			status = result.status
			testing = status.testing
		end
		if result.rows then
			rows = result.rows
		end
		refreshSummary()
		if window and window.Parent then
			showStatus(result.message or "Готово.", result.ok and Style.Colors.Green or Style.Colors.Red)
			if command == "Diagnostics" or command == "Logs" then
				renderPage()
			end
		end
	end

	request = function(command: string, value: any?)
		if command == "ClientLogs" then
			rows = {}
			for i = #clientLogs, 1, -1 do
				table.insert(rows, clientLogs[i])
			end
			if #rows == 0 then
				rows = {
					{
						ok = true,
						title = "Ошибок клиента нет",
						detail = "Журнал собирается с момента загрузки панели.",
					},
				}
			end
			renderPage()
			showStatus("Журнал клиента.", Style.Muted)
			return
		end
		if busy then
			return
		end
		busy = true
		showStatus("Выполняется…", Style.Muted)
		local token = {}
		pending = token
		-- The remote is looked up inside the thread: waiting for it must not
		-- hold the interface of the panel.
		local thread = task.spawn(function()
			local target = resolveRemote()
			if not target then
				if pending ~= token then
					return
				end
				pending = nil
				busy = false
				showStatus("Сервер недоступен. Повтори команду.", Style.Colors.Red)
				return
			end
			local ok, result = pcall(function()
				return target:InvokeServer(command, value)
			end)
			if pending ~= token then
				return
			end
			pending = nil
			busy = false
			if not ok or type(result) ~= "table" then
				result = { ok = false, message = "Нет ответа сервера. Повтори команду." }
			end
			applyResult(result, command)
		end)
		task.delay(TIMEOUT, function()
			if pending ~= token then
				return
			end
			pending = nil
			busy = false
			-- The server never answered: the waiting thread is stopped, so it
			-- does not hang until the answer arrives after the timeout.
			task.cancel(thread)
			showStatus(
				"Сервер не ответил за " .. TIMEOUT .. " с. Повтори команду.",
				Style.Colors.Red
			)
		end)
	end

	local function grid(items: any, y: number, minWidth: number, cellHeight: number): number
		local columns = math.max(1, math.floor((bodyWidth + 10) / (minWidth + 10)))
		local cellWidth = (bodyWidth - (columns - 1) * 10) / columns
		for i, item in items do
			local x = ((i - 1) % columns) * (cellWidth + 10)
			local row = math.floor((i - 1) / columns)
			brickButton(
				body,
				"Action" .. i .. "_" .. y,
				item.label,
				x,
				y + row * (cellHeight + 10),
				cellWidth,
				cellHeight,
				item.color or Style.Colors.Blue,
				18,
				function()
					request(item.command, item.value)
				end
			)
		end
		return y + math.ceil(#items / columns) * (cellHeight + 10)
	end

	-- A caption of a section is a gold heading of the window.
	local function label(value: string, y: number): number
		Kit.text(body, "Section" .. y, value, 2, y, bodyWidth - 4, 28, 20, Style.Gold).TextXAlignment =
			Enum.TextXAlignment.Left
		return y + 36
	end

	renderPage = function()
		if not body or not body.Parent then
			return
		end
		for _, child in body:GetChildren() do
			child:Destroy()
		end
		local y = 4
		if tab == "Проверки" then
			y = grid({
				{ label = "Запустить проверки", command = "Diagnostics", color = Style.Colors.Green },
				{ label = "Обновить данные", command = "Status" },
				{ label = "Ошибки сервера", command = "Logs", color = Style.Colors.Purple },
				{ label = "Ошибки клиента", command = "ClientLogs", color = Style.Colors.Purple },
			}, y, 210, 42)
			if not rows then
				rows = {
					{
						ok = true,
						title = "Проверяй изменения в тестовой копии",
						detail = "Включи тестовый режим. Валюта, питомцы, открытия и результаты бросков вернутся к исходным после завершения теста.",
					},
					{
						ok = true,
						title = "Что проверяет панель",
						detail = "Стыки и опоры биомов, состав яиц, модели петов, тренировочные площадки, мячи, арку, дальность и ID покупок.",
					},
				}
			end
			for i, row in rows do
				local title = (row.ok and "ОК · " or "ВНИМАНИЕ · ") .. row.title
				-- The stripe on the left of the plate takes 30 px, the text keeps
				-- 8 px away from it.
				local textWidth = bodyWidth - 30
				local th = TextService:GetTextSize(title, 18, Enum.Font.GothamBlack, Vector2.new(textWidth, 10000)).Y
				local dh =
					TextService:GetTextSize(row.detail, 16, Enum.Font.GothamBlack, Vector2.new(textWidth, 10000)).Y
				local h = th + dh + 28
				local card = brick(
					body,
					"Check" .. i,
					0,
					y,
					bodyWidth,
					h,
					Style.plateColor(Style.Colors.Slate),
					Style.Radius,
					white
				)
				-- The state of the row is a stripe on the left of the plate.
				local stripe = Kit.frame(card, "State", 6, 8, 6, h - 16, row.ok and Style.Colors.Green or Style.Gold)
				Kit.corner(stripe, 3)
				Kit.stroke(stripe, Style.Stroke, Style.Ink)
				local heading = Kit.text(
					card,
					"Title",
					title,
					20,
					5,
					textWidth,
					th + 3,
					18,
					row.ok and Style.Colors.Green or Style.Gold
				)
				heading.TextWrapped = true
				heading.TextXAlignment = Enum.TextXAlignment.Left
				local detail = Kit.text(card, "Detail", row.detail, 20, th + 16, textWidth, dh + 3, 16, Style.Muted)
				detail.TextWrapped = true
				detail.TextXAlignment = Enum.TextXAlignment.Left
				y += h + 9
			end
		elseif tab == "Прогресс" then
			local columns = bodyWidth >= 700 and 3 or 1
			local cw = (bodyWidth - (columns - 1) * 12) / columns
			for i, field in { { "wins", "Wins" }, { "skill", "Skill" }, { "rebirths", "Rebirths" } } do
				local x = ((i - 1) % columns) * (cw + 12)
				local top = y + math.floor((i - 1) / columns) * 101
				Kit.text(body, "Stat" .. field[1], field[2], x, top, cw, 27, 21).TextXAlignment =
					Enum.TextXAlignment.Left
				local input = Instance.new("TextBox")
				input.Name = "Input_" .. field[1]
				input.Position = UDim2.fromOffset(x, top + 33)
				input.Size = UDim2.fromOffset(cw - 112, 40)
				input.BackgroundColor3 = Style.Slot
				input.TextColor3 = Style.Text
				input.Text = tostring(status[field[1]] or 0)
				input.Font = Enum.Font.GothamBlack
				input.TextSize = 18
				input.TextStrokeColor3 = Style.Ink
				input.TextStrokeTransparency = 0.3
				input.TextXAlignment = Enum.TextXAlignment.Left
				input.ClearTextOnFocus = false
				input.Parent = body
				Kit.corner(input, Style.Radius)
				Kit.stroke(input, Style.Stroke, Style.Ink)
				brickButton(
					body,
					"Set" .. field[1],
					"Задать",
					x + cw - 104,
					top + 33,
					104,
					40,
					Style.Colors.Blue,
					17,
					function()
						request("SetStat", { key = field[1], amount = input.Text })
					end
				)
			end
			y += math.ceil(3 / columns) * 101
			y = grid({
				{ label = "Wins: 100K", command = "SetStat", value = { key = "wins", amount = 100000 } },
				{ label = "Skill: 1M", command = "SetStat", value = { key = "skill", amount = 1000000 } },
				{ label = "Rebirths: 16", command = "SetStat", value = { key = "rebirths", amount = 16 } },
				{ label = "Открыть всё", command = "Unlock", color = Style.Colors.Green },
				{ label = "Сбросить тест", command = "Reset", color = Style.Colors.Purple },
			}, y, 170, 42)
			y = label("Проверка броска", y + 8)
			y = grid({
				{ label = "Бросок: 60 м", command = "Throw", value = 60 },
				{ label = "Бросок: 629 м", command = "Throw", value = 629 },
				{
					label = "Максимальный бросок",
					command = "Throw",
					value = "max",
					color = Style.Colors.Green,
				},
			}, y, 210, 42)
		elseif tab == "Петы / яйца" then
			local egg = Config.find(Config.Eggs, selectedEgg) or Config.Eggs[1]
			selectedEgg = egg.id
			local eggColumns = math.max(1, math.min(#Config.Eggs, math.floor((bodyWidth + 10) / 155)))
			local eggWidth = (bodyWidth - (eggColumns - 1) * 10) / eggColumns
			for i, option in Config.Eggs do
				brickButton(
					body,
					"SelectEgg_" .. option.id,
					option.name,
					((i - 1) % eggColumns) * (eggWidth + 10),
					y + math.floor((i - 1) / eggColumns) * 48,
					eggWidth,
					38,
					option.id == selectedEgg and Style.Colors.Purple or Style.Colors.Slate,
					18,
					function()
						selectedEgg = option.id
						renderPage()
					end
				)
			end
			y += math.ceil(#Config.Eggs / eggColumns) * 48
			local worldBoost = status.world == 2 and 3 or 1
			y = label(egg.name .. " · " .. Config.format(egg.cost * (status.world == 2 and 10 or 1)) .. " Wins", y + 4)
			local pool = Config.eggPets(egg.id)
			local columns = math.max(1, math.floor((bodyWidth + 10) / 220))
			local cw = (bodyWidth - (columns - 1) * 10) / columns
			for i, pet in pool do
				local x = ((i - 1) % columns) * (cw + 10)
				local top = y + math.floor((i - 1) / columns) * 204
				local card = brick(body, "AdminPet_" .. pet.id, x, top, cw, 192, pet.color, Style.Radius)
				card:SetAttribute("EggId", egg.id)
				Kit.text(card, "Name", pet.name, 6, 3, cw - 12, 26, 19)
				Kit.petIcon(card, pet, 10, 32, cw - 20, 88)
				Kit.text(
					card,
					"Chance",
					pet.weight .. "% · ×" .. pet.boost * egg.boost * worldBoost,
					5,
					120,
					cw - 10,
					25,
					18
				)
				brickButton(
					card,
					"Give_" .. pet.id,
					"Выдать",
					12,
					151,
					cw - 24,
					32,
					Style.Colors.Green,
					18,
					function()
						request("GivePet", { egg = egg.id, pet = pet.id })
					end
				)
			end
			y += math.ceil(#pool / columns) * 204
			y = grid({
				{ label = "Открыть яйцо", command = "Egg", value = egg.id },
				{
					label = "Тест: 1 яйцо",
					command = "Hatch",
					value = { egg = egg.id, count = 1 },
					color = Style.Colors.Green,
				},
				{
					label = "Тест: 3 яйца",
					command = "Hatch",
					value = { egg = egg.id, count = 3 },
					color = Style.Colors.Green,
				},
				{
					label = "Выдать всех: " .. #pool,
					command = "GiveEggPets",
					value = egg.id,
					color = Style.Colors.Purple,
				},
			}, y, 200, 42)
			y = label("Особый питомец", y + 8)
			y = grid({
				{
					label = "Выдать " .. Config.AdminPet.name,
					command = "GivePet",
					value = Config.AdminPet.id,
					color = Style.Colors.Purple,
				},
			}, y, 260, 42)
		elseif tab == "Карта" then
			local items = {}
			for i, biome in Config.Biomes do
				table.insert(items, {
					label = i .. " · " .. (i == 8 and "Сакура" or biome.name),
					command = "Teleport",
					value = i,
				})
			end
			y = grid(items, y, 210, 42)
			y = grid({
				{
					label = "Вернуться в лобби",
					command = "Teleport",
					value = "Lobby",
					color = Style.Colors.Green,
				},
				{
					label = "К финальной арке",
					command = "Teleport",
					value = "Sakura",
					color = Style.Colors.Purple,
				},
				{ label = "Мир 1", command = "Teleport", value = "World1" },
				{ label = "Мир 2", command = "Teleport", value = "World2" },
			}, y + 10, 210, 42)
			y = label("Тренировочные площадки", y + 8)
			local lanes = {}
			for i = 1, 7 do
				table.insert(lanes, { label = "Площадка " .. i, command = "Training", value = i })
			end
			y = grid(lanes, y, 125, 40)
		elseif tab == "Мячи / трейлы" then
			y = label("Экипировать тестовый мяч", y)
			local items = {}
			for _, ball in Config.Stones do
				table.insert(
					items,
					{ label = ball.name, command = "Stone", value = ball.id, color = Style.Colors.Blue }
				)
			end
			y = grid(items, y, 210, 42)
			y = label("Экипировать тестовый трейл", y + 8)
			items = {}
			for _, trail in Config.Trails do
				table.insert(
					items,
					{ label = trail.name, command = "Trail", value = trail.id, color = Style.Colors.Purple }
				)
			end
			y = grid(items, y, 210, 42)
		end
		body.CanvasSize = UDim2.fromOffset(0, y + 14)
		body.CanvasPosition = Vector2.zero
	end

	build = function(animate: boolean)
		close()
		local viewport = workspace.CurrentCamera.ViewportSize
		-- The chrome of the reference panels hangs 54 pixels above the upper
		-- edge of the plate, so the plate starts below it.
		width = math.min(980, viewport.X - 24)
		height = math.min(620, viewport.Y - 124)
		bodyWidth = width - 42
		local container = gui
		if not container then
			return
		end
		-- The window lives in a canvas group: the group carries the scale and
		-- the fade of the opening. The plate and its chrome are copies of the
		-- reference panels: a translucent slate plate of two pixel ink edge and
		-- the heading, the icon and the game cross hanging over its edges. The
		-- margin of the group leaves room for the hanging chrome.
		local group = Instance.new("CanvasGroup")
		group.Name = "AdminWindowGroup"
		group.Size = UDim2.fromOffset(width + 140, height + 140)
		group.AnchorPoint = Vector2.new(0.5, 0.5)
		-- The granted area of the probe does not always start at the top of
		-- the screen, so the plate is centred on the visible screen itself
		-- and its chrome hangs over the upper edge without being cut.
		local grantedProbe = probe
		if not grantedProbe then
			return
		end
		group.Position = UDim2.fromOffset(
			viewport.X / 2 - grantedProbe.AbsolutePosition.X,
			viewport.Y / 2 - grantedProbe.AbsolutePosition.Y
		)
		group.BackgroundTransparency = 1
		group.BorderSizePixel = 0
		group.ZIndex = LAYER_WINDOW
		group.Parent = container
		windowGroup = group
		window = Kit.frame(group, "AdminWindow", 70, 70, width, height, Style.Panel)
		window.BackgroundTransparency = 0.3
		window.ZIndex = LAYER_WINDOW
		Kit.stroke(window, Style.Stroke, Style.Ink)
		local heading = Kit.text(window, "Title", "Панель проверок", 85, -50, width - 170, 66, 63)
		heading.ZIndex = 10
		heading.TextScaled = true
		local headingLimit = Instance.new("UITextSizeConstraint")
		headingLimit.MinTextSize = 24
		headingLimit.MaxTextSize = 63
		headingLimit.Parent = heading
		Kit.icon(window, "Settings", -15, -54, 100, 100)
		local cross = Kit.button(window, "Close", "", width - 32, -31, 60, 60, Style.Colors.Red)
		cross.ZIndex = 12
		cross.BackgroundTransparency = 1
		Kit.hide(cross, "Studs")
		Kit.hide(cross, "UIStroke")
		Kit.hide(window, "CloseShadow")
		Kit.icon(cross, "Close", 0, 0, 60, 60)
		cross.Activated:Connect(function()
			context.closePanel()
		end)
		Kit.text(window, "Mode", "", 16, 24, width - 32, 27, 21, Style.Gold).TextXAlignment = Enum.TextXAlignment.Left
		summary = Kit.text(window, "Summary", "", 16, 55, width - 32, 24, 16, Style.Muted)
		summary.TextXAlignment = Enum.TextXAlignment.Left
		modeButton = brickButton(
			window,
			"TestMode",
			"Начать тест",
			16,
			88,
			math.min(300, width - 32),
			36,
			Style.Colors.Green,
			20,
			function()
				request(testing and "End" or "Begin")
			end
		)
		local tabs = Instance.new("ScrollingFrame")
		tabs.Name = "Tabs"
		tabs.Position = UDim2.fromOffset(16, 140)
		tabs.Size = UDim2.fromOffset(width - 32, 46)
		tabs.BackgroundTransparency = 1
		tabs.BorderSizePixel = 0
		tabs.ScrollBarThickness = 3
		tabs.ScrollingDirection = Enum.ScrollingDirection.X
		tabs.CanvasSize = UDim2.fromOffset(920, 0)
		tabs.Parent = window
		for i, name in
			{ "Проверки", "Прогресс", "Петы / яйца", "Карта", "Мячи / трейлы" }
		do
			local selected = name == tab
			local tabButton = brickButton(
				tabs,
				"Tab" .. i,
				name,
				(i - 1) * 184,
				0,
				174,
				36,
				selected and Style.Colors.Purple or Style.Colors.Slate,
				18,
				function()
					tab = name
					rows = tab == "Проверки" and rows or nil
					build(false)
				end
			)
			if selected then
				-- The open tab carries a gold border, so it is read at once.
				local stroke = tabButton:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = Style.Gold
					stroke.Thickness = 3
				end
			end
		end
		body = Instance.new("ScrollingFrame")
		body.Name = "Body"
		body.Position = UDim2.fromOffset(16, 200)
		body.Size = UDim2.fromOffset(width - 32, height - 252)
		body.BackgroundTransparency = 1
		body.BorderSizePixel = 0
		body.ScrollBarThickness = 5
		body.ScrollBarImageColor3 = Style.Gold
		body.Parent = window
		statusLabel = Kit.text(
			window,
			"Status",
			"Тестовые изменения можно отменить кнопкой «Завершить тест».",
			16,
			height - 48,
			width - 32,
			40,
			16,
			Style.Muted
		)
		statusLabel.TextWrapped = true
		statusLabel.TextXAlignment = Enum.TextXAlignment.Left
		if launcher then
			launcher.Visible = false
		end
		local launcherShadow = probe and probe:FindFirstChild("AdminLauncherShadow")
		if launcherShadow and launcherShadow:IsA("GuiObject") then
			launcherShadow.Visible = false
		end
		-- The window opens with a short scale and a short fade. A rebuild (a
		-- new tab or a new viewport) keeps the plate where it is.
		local zoom = Instance.new("UIScale")
		zoom.Scale = animate and OPEN_SCALE or 1
		zoom.Parent = group
		if animate then
			group.GroupTransparency = 1
			TweenService
				:Create(zoom, TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
				:Play()
			TweenService:Create(
				group,
				TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ GroupTransparency = 0 }
			):Play()
		end
		refreshSummary()
		renderPage()
	end

	open = function()
		if not authorized then
			return
		end
		if window then
			context.closePanel()
			return
		end
		context.activate()
		build(true)
		request("Status")
	end

	-- The panel is created for an authorized player only.
	local unmounting = false
	local function unmount()
		-- The ScreenGui fires Destroying when it is destroyed and unmount
		-- destroys it: the second call has to do nothing.
		if unmounting then
			return
		end
		unmounting = true
		local created = gui
		gui = nil
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		window = nil
		windowGroup = nil
		launcher = nil
		indicator = nil
		probe = nil
		statusLabel = nil
		summary = nil
		modeButton = nil
		body = nil
		pending = nil
		busy = false
		if created and created.Parent then
			created:Destroy()
		end
		unmounting = false
	end

	-- The panel is created for an authorized player only.
	local function mount()
		if gui then
			return
		end
		local created = Instance.new("ScreenGui")
		created.Name = "AdminTools"
		created.ResetOnSpawn = false
		created.IgnoreGuiInset = true
		created.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
		created.DisplayOrder = 35
		created.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		created.Parent = Players.LocalPlayer.PlayerGui
		gui = created
		-- The probe reports the rectangle the engine granted, so the launcher
		-- can stand in the part of the screen that the HUD does not use.
		local area = Instance.new("Frame")
		area.Name = "SafeArea"
		area.Size = UDim2.fromScale(1, 1)
		area.BackgroundTransparency = 1
		area.Parent = created
		probe = area
		launcher = brickButton(
			area,
			"AdminLauncher",
			"ADMIN · F2",
			16,
			112,
			150,
			38,
			Style.Colors.Purple,
			19,
			function()
				open()
			end
		)
		launcher.Visible = false
		Kit.hide(area, "AdminLauncherShadow")
		-- The shadow of the launcher is the ink of the style.
		local launcherShadow = area:FindFirstChild("AdminLauncherShadow")
		if launcherShadow and launcherShadow:IsA("GuiObject") then
			launcherShadow.BackgroundColor3 = Style.Ink
			launcherShadow.BackgroundTransparency = 0.28
		end
		-- The HUD owns the top of the screen in portrait: the launcher stands
		-- in the middle of the left edge, where nothing else is drawn.
		local function placeLauncher()
			if not launcher then
				return
			end
			local viewport = workspace.CurrentCamera.ViewportSize
			local granted = GuiInsets.area(viewport, area)
			if granted.size.Y > granted.size.X then
				launcher.AnchorPoint = Vector2.new(0, 0.5)
				launcher.Position = UDim2.fromOffset(16, granted.offset.Y + granted.size.Y / 2)
			else
				launcher.AnchorPoint = Vector2.new(0, 0)
				launcher.Position = UDim2.fromOffset(16, granted.offset.Y + 112)
			end
			-- The shadow of a button is a separate frame: it has to follow the
			-- button, or it stays behind as a dark plate.
			local shadow = area:FindFirstChild("AdminLauncherShadow")
			if shadow and shadow:IsA("GuiObject") then
				local anchor = launcher.AnchorPoint
				local size = launcher.Size
				shadow.Position = UDim2.new(
					launcher.Position.X.Scale,
					launcher.Position.X.Offset - anchor.X * size.X.Offset,
					launcher.Position.Y.Scale,
					launcher.Position.Y.Offset - anchor.Y * size.Y.Offset + 4
				)
			end
			if indicator then
				-- The badge stands in the free left margin: the title of an
				-- open window floats over the middle of the upper edge and
				-- must not be covered.
				indicator.Position = UDim2.fromOffset(16, granted.offset.Y + 6)
			end
		end
		placeLauncher()
		table.insert(
			connections,
			area:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				placeLauncher()
			end)
		)
		indicator = Kit.text(area, "TestIndicator", "● ТЕСТ", 0, 6, 130, 30, 19, Style.Gold)
		indicator.AnchorPoint = Vector2.new(0, 0)
		indicator.TextXAlignment = Enum.TextXAlignment.Left
		indicator.Visible = false
		placeLauncher()
		table.insert(
			connections,
			LogService.MessageOut:Connect(function(message: string, kind: Enum.MessageType)
				if kind == Enum.MessageType.MessageError or kind == Enum.MessageType.MessageWarning then
					table.insert(
						clientLogs,
						{ ok = false, title = os.date("%H:%M:%S") .. " · " .. kind.Name, detail = message:sub(1, 500) }
					)
					if #clientLogs > 30 then
						table.remove(clientLogs, 1)
					end
				end
			end)
		)
		table.insert(
			connections,
			Input.InputBegan:Connect(function(input: InputObject, processed: boolean)
				if input.KeyCode == Enum.KeyCode.F2 and not processed and not Input:GetFocusedTextBox() then
					open()
				end
			end)
		)
		table.insert(
			connections,
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				if window then
					build(false)
				end
			end)
		)
		created.Destroying:Connect(function()
			unmount()
		end)
	end

	local function update(info: any)
		authorized = info.isAdmin == true
		testing = info.adminTest == true
		if authorized then
			mount()
		elseif gui then
			unmount()
		end
		if not gui then
			return
		end
		if launcher then
			launcher.Visible = authorized and not window
		end
		local shadow = probe and probe:FindFirstChild("AdminLauncherShadow")
		if shadow and shadow:IsA("GuiObject") then
			shadow.Visible = launcher and launcher.Visible or false
		end
		local data = info.data
		if data then
			status.wins = data.wins
			status.skill = data.skill
			status.rebirths = data.rebirths
			status.world = data.world
			local inventory = info.inventory
			status.pets = inventory and inventory.pets and #inventory.pets or 0
		end
		refreshSummary()
	end

	return {
		close = close,
		open = open,
		update = update,
		destroy = unmount,
	}
end
return Panel
