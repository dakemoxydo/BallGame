--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
player:SetAttribute("MapIntroActive", true)

-- The palette of the interface. The numbers mirror src/client/UiStyle.luau:
-- the intro lives in ReplicatedFirst and cannot reach the modules of the
-- client tree, so the shared sheet is repeated here.
local INK = Color3.fromRGB(20, 22, 33)
local TEXT = Color3.fromRGB(255, 255, 255)
local GOLD = Color3.fromRGB(255, 225, 66)
local RED = Color3.fromRGB(252, 24, 68)
local SLATE = Color3.fromRGB(115, 127, 143)

-- The stud texture of a brick plate. The shared config holds the same id; it
-- is the fallback for the moment the config is not replicated yet.
local STUD_TEXTURE = "rbxassetid://88156646156237"

-- The idle motion of the intro. The settings snapshot is not available while
-- the intro runs, so the flag of the module is the switch: the settings
-- system sets it to false when the player turned the effects off.
local effectsEnabled = true

local playerGui = player:WaitForChild("PlayerGui")
local screen = Instance.new("ScreenGui")
screen.Name = "MapIntro"
screen.IgnoreGuiInset = true
screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screen.ResetOnSpawn = false
screen.DisplayOrder = 10000
-- The layers of the intro are ordered by ZIndex, so the behaviour is fixed.
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

-- Keep the caption and the skip button out of the notch and the gesture bar.
local function safeInsets()
	local okNone, none = pcall(function()
		return GuiService:GetInsetArea(Enum.ScreenInsets.None)
	end)
	local okDevice, device = pcall(function()
		return GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
	end)
	if not okNone or not okDevice then
		return Vector2.zero, Vector2.zero
	end
	local left = math.max(0, device.Min.X - none.Min.X)
	local top = math.max(0, device.Min.Y - none.Min.Y)
	local right = math.max(0, (none.Min.X + none.Width) - (device.Min.X + device.Width))
	local bottom = math.max(0, (none.Min.Y + none.Height) - (device.Min.Y + device.Height))
	return Vector2.new(left, top), Vector2.new(right, bottom)
end
local insetTop, insetBottom = safeInsets()

local hidden, connections, coreStates = {}, {}, {}
local function hideGui(gui)
	if not gui:IsA("ScreenGui") or gui == screen or hidden[gui] ~= nil then
		return
	end
	hidden[gui] = gui.Enabled
	gui.Enabled = false
	table.insert(
		connections,
		gui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if gui.Enabled then
				hidden[gui] = true
				gui.Enabled = false
			end
		end)
	)
end
for _, gui in playerGui:GetChildren() do
	hideGui(gui)
end
table.insert(connections, playerGui.ChildAdded:Connect(hideGui))
for _, kind in
	{ Enum.CoreGuiType.Backpack, Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Chat, Enum.CoreGuiType.Health }
do
	pcall(function()
		coreStates[kind] = StarterGui:GetCoreGuiEnabled(kind)
		StarterGui:SetCoreGuiEnabled(kind, false)
	end)
end
ContextActionService:BindActionAtPriority(
	"MapIntroMovement",
	function()
		return Enum.ContextActionResult.Sink
	end,
	false,
	3000,
	Enum.PlayerActions.CharacterForward,
	Enum.PlayerActions.CharacterBackward,
	Enum.PlayerActions.CharacterLeft,
	Enum.PlayerActions.CharacterRight,
	Enum.PlayerActions.CharacterJump
)

local cameraState, root, cancelled, finished, streamingRemote

-- The character can spawn long after the intro started. The camera then
-- watches for it for a few seconds and attaches the subject as soon as it
-- exists. The watch runs in the background and never blocks the intro.
local CAMERA_ATTACH_TIMEOUT = 4
local CAMERA_POLL_INTERVAL = 0.1
local cameraWatchActive = false

local function characterHumanoid(): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid:IsA("Humanoid") then
		return humanoid
	end
	return nil
end

-- Attaches the character to the camera as soon as it exists.
local function watchForCharacter(camera: Camera)
	if cameraWatchActive then
		return
	end
	cameraWatchActive = true
	local function attach(): boolean
		local humanoid = characterHumanoid()
		if humanoid then
			camera.CameraSubject = humanoid
			return true
		end
		return false
	end
	local connection = player.CharacterAdded:Connect(function()
		attach()
	end)
	task.spawn(function()
		local deadline = os.clock() + CAMERA_ATTACH_TIMEOUT
		while os.clock() < deadline do
			if attach() then
				break
			end
			task.wait(CAMERA_POLL_INTERVAL)
		end
		cameraWatchActive = false
		connection:Disconnect()
	end)
end

-- Restores the camera after the fly-through. The camera controller owns the
-- position as soon as a subject is set, so the saved CFrame is restored only
-- while there is no subject at all.
local function restoreCamera(waitForCharacter: boolean)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local saved = cameraState
	if saved then
		camera.CameraType = saved.Type
		camera.FieldOfView = saved.FOV
	end
	local humanoid = characterHumanoid()
	if humanoid then
		camera.CameraSubject = humanoid
		return
	end
	if saved then
		-- The character has not spawned yet: keep the camera out of the last
		-- shot and attach the subject as soon as the character appears.
		camera.CameraSubject = saved.Subject
		if saved.Subject == nil then
			camera.CFrame = saved.CFrame
		end
	end
	if waitForCharacter then
		watchForCharacter(camera)
	end
end

local function cleanup()
	if finished then
		return
	end
	finished = true
	RunService:UnbindFromRenderStep("MapIntroCamera")
	ContextActionService:UnbindAction("MapIntroMovement")
	for _, connection in connections do
		connection:Disconnect()
	end
	for gui, enabled in hidden do
		if gui.Parent then
			gui.Enabled = enabled
		end
	end
	for kind, enabled in coreStates do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(kind, enabled)
		end)
	end
	-- The camera may still be scriptable from the fly-through.
	restoreCamera(true)
	player:SetAttribute("MapIntroActive", false)
	if streamingRemote then
		streamingRemote:FireServer("Finish")
	end
	if root then
		root:unmount()
	end
	screen:Destroy()
end

local ok, failure = xpcall(function()
	local packages = ReplicatedStorage:WaitForChild("Packages", 30)
	assert(packages, "UI packages unavailable")
	local React = require(packages:WaitForChild("React"))
	local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))
	local Ripple = require(packages:WaitForChild("Ripple"))
	local e = React.createElement
	local fade, setFade = React.createBinding(1)
	local progress, setProgress = React.createBinding(0)
	local caption, setCaption = React.createBinding("Preparing your adventure…")
	local phase, setPhase = React.createBinding("LOADING")
	local breathing, setBreathing = React.createBinding(1)
	local spring = Ripple.createSpring(1, { frequency = 7, dampingRatio = 1, start = true })
	local disconnect = spring:onChange(setFade)
	table.insert(connections, {
		Disconnect = function()
			disconnect()
			spring:destroy()
		end,
	})
	-- The stud texture of the plates. The shared config holds the id, the
	-- constant of the module is the fallback for the moment the config is
	-- not replicated yet.
	local studTexture = STUD_TEXTURE
	local okConfig, config = pcall(function()
		return require(game.ReplicatedStorage.Shared.GameConfig)
	end)
	if okConfig and config then
		local id = config.StudTexture
		if typeof(id) == "string" then
			studTexture = id
		end
	end
	-- The stud texture of a brick plate, tiled like the rest of the interface.
	local function studs(radius: number)
		return e("ImageLabel", {
			Name = "Studs",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = studTexture,
			ImageColor3 = Color3.new(1, 1, 1),
			ImageTransparency = 0.5,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(64, 64),
			ZIndex = 0,
		}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, radius) }) })
	end
	-- The light of a brick plate: the top of the plate catches the sun.
	local function topLight(color: Color3)
		return e("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), color) })
	end
	-- The text of the interface: white with a dark outline, gold for the
	-- accents. The caption of the biome keeps the white of the default.
	local function label(text, position, size, textSize, color)
		return e("TextLabel", {
			BackgroundTransparency = 1,
			Text = text,
			Position = position,
			Size = size,
			Font = Enum.Font.GothamBlack,
			TextSize = textSize,
			TextScaled = true,
			TextColor3 = color or TEXT,
			TextWrapped = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 2,
		}, {
			Stroke = e("UIStroke", {
				Color = INK,
				Thickness = textSize >= 40 and 3.5 or 2,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				LineJoinMode = Enum.LineJoinMode.Round,
			}),
			Limit = e("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = textSize }),
		})
	end
	root = ReactRoblox.createRoot(screen)
	-- ReactRoblox renders the children in the hash order of the props table,
	-- so the order is fixed with explicit ZIndex values. The screen uses the
	-- Sibling behaviour: a child is drawn at the ZIndex of its parent plus
	-- its own. Blocker is the lowest layer, the fade covers it, the safe area
	-- covers the fade and the skip button covers everything inside it.
	root:render(e("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1 }, {
		Blocker = e("TextButton", {
			Size = UDim2.fromScale(1, 1),
			Text = "",
			BackgroundTransparency = 1,
			Modal = true,
			AutoButtonColor = false,
			ZIndex = 1,
		}),
		Fade = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = INK,
			BackgroundTransparency = fade:map(function(v)
				return 1 - math.clamp(v, 0, 1)
			end),
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
		Safe = e("Frame", {
			Name = "SafeArea",
			Position = UDim2.fromOffset(insetTop.X, insetTop.Y),
			Size = UDim2.new(1, -insetTop.X - insetBottom.X, 1, -insetTop.Y - insetBottom.Y),
			BackgroundTransparency = 1,
			ZIndex = 3,
		}, {
			Top = e("Frame", {
				Size = UDim2.fromScale(1, 0.075),
				BackgroundColor3 = INK,
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, {
				-- The gold edge under the bar: the frame of the screen is a
				-- designed line and not a black stripe.
				Edge = e("Frame", {
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.new(1, 0, 0, 3),
					BackgroundColor3 = GOLD,
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					ZIndex = 0,
				}),
			}),
			Bottom = e("Frame", {
				Position = UDim2.fromScale(0, 0.82),
				Size = UDim2.fromScale(1, 0.18),
				BackgroundColor3 = INK,
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
				Edge = e("Frame", {
					Position = UDim2.fromOffset(12, 0),
					Size = UDim2.new(1, -24, 0, 3),
					BackgroundColor3 = GOLD,
					BackgroundTransparency = 0.45,
					BorderSizePixel = 0,
					ZIndex = 0,
				}),
				-- The foot squares the lower edge of the bar, so the rounded
				-- corners do not cut the world at the bottom of the screen.
				Foot = e("Frame", {
					Position = UDim2.new(0, 0, 1, -14),
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundColor3 = INK,
					BackgroundTransparency = 0.08,
					BorderSizePixel = 0,
					ZIndex = 0,
				}),
				Wordmark = e("Frame", {
					Position = UDim2.fromScale(0.022, 0.06),
					Size = UDim2.fromScale(0.22, 0.88),
					BackgroundTransparency = 1,
					ZIndex = 2,
				}, {
					Title = e("TextLabel", {
						BackgroundTransparency = 1,
						Text = "BALL",
						Position = UDim2.fromScale(0, 0),
						Size = UDim2.fromScale(1, 0.7),
						Font = Enum.Font.GothamBlack,
						TextSize = 64,
						TextScaled = true,
						TextColor3 = TEXT,
						TextWrapped = false,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
						ZIndex = 0,
					}, {
						Stroke = e("UIStroke", {
							Color = INK,
							Thickness = 3.5,
							ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
							LineJoinMode = Enum.LineJoinMode.Round,
						}),
						Limit = e("UITextSizeConstraint", { MinTextSize = 20, MaxTextSize = 64 }),
					}),
					Subtitle = e("TextLabel", {
						BackgroundTransparency = 1,
						Text = "STONE SKIPPING",
						Position = UDim2.fromScale(0, 0.72),
						Size = UDim2.fromScale(1, 0.28),
						Font = Enum.Font.GothamBlack,
						TextSize = 20,
						TextScaled = true,
						TextColor3 = GOLD,
						TextWrapped = false,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
						ZIndex = 0,
					}, {
						Stroke = e("UIStroke", {
							Color = INK,
							Thickness = 2,
							ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
							LineJoinMode = Enum.LineJoinMode.Round,
						}),
						Limit = e("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 20 }),
					}),
				}),
				Phase = label(phase, UDim2.fromScale(0.267, 0.07), UDim2.fromScale(0.365, 0.23), 20, GOLD),
				Caption = label(caption, UDim2.fromScale(0.267, 0.37), UDim2.fromScale(0.365, 0.32), 30),
				Track = e("Frame", {
					Position = UDim2.fromScale(0.657, 0.45),
					Size = UDim2.fromScale(0.2, 0.16),
					BackgroundColor3 = SLATE,
					BorderSizePixel = 0,
					ZIndex = 2,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Fill = e("Frame", {
						Position = UDim2.fromOffset(0, 3),
						Size = progress:map(function(v)
							return UDim2.new(math.clamp(v, 0, 1), 0, 1, -6)
						end),
						BackgroundColor3 = GOLD,
						BorderSizePixel = 0,
						ZIndex = 0,
					}, {
						Corner = e("UICorner", { CornerRadius = UDim.new(0, 9) }),
						Studs = studs(9),
						Stroke = e("UIStroke", {
							Color = INK,
							Thickness = 2,
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							ZIndex = 1,
						}),
						Gradient = topLight(GOLD),
					}),
					Stroke = e("UIStroke", {
						Color = INK,
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						ZIndex = 2,
					}),
				}),
				Percent = e("TextLabel", {
					BackgroundTransparency = 1,
					Text = progress:map(function(v: number)
						return math.floor(v * 100) .. "%"
					end),
					Position = UDim2.fromScale(0.882, 0.43),
					Size = UDim2.fromScale(0.096, 0.2),
					Font = Enum.Font.GothamBlack,
					TextSize = 18,
					TextScaled = true,
					TextColor3 = TEXT,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 2,
				}, {
					Stroke = e("UIStroke", {
						Color = INK,
						Thickness = 1.5,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
						LineJoinMode = Enum.LineJoinMode.Round,
					}),
					Limit = e("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 18 }),
				}),
			}),
			SkipShadow = e("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -20, 0.09, 4),
				Size = UDim2.fromOffset(136, 44),
				BackgroundColor3 = INK,
				BackgroundTransparency = 0.28,
				BorderSizePixel = 0,
				ZIndex = 4,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 9) }),
				Scale = e("UIScale", { Scale = breathing }),
			}),
			Skip = e("TextButton", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -20, 0.09, 0),
				Size = UDim2.fromOffset(136, 44),
				Text = "",
				Font = Enum.Font.GothamBlack,
				BackgroundColor3 = RED,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				-- Above the whole safe area, so the input blocker below can
				-- never swallow the click on the skip button.
				ZIndex = 5,
				[React.Event.Activated] = function()
					cancelled = true
				end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 9) }),
				Studs = studs(9),
				Stroke = e("UIStroke", {
					Color = INK,
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					ZIndex = 1,
				}),
				Gradient = topLight(RED),
				Caption = e("TextLabel", {
					BackgroundTransparency = 1,
					Text = "Skip ›",
					Size = UDim2.fromScale(1, 1),
					Font = Enum.Font.GothamBlack,
					TextSize = 21,
					TextColor3 = TEXT,
					TextWrapped = false,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 2,
				}, {
					Stroke = e("UIStroke", {
						Color = INK,
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
						LineJoinMode = Enum.LineJoinMode.Round,
					}),
				}),
				Scale = e("UIScale", { Scale = breathing }),
			}),
		}),
	}))
	-- The idle breath of the skip button. The connection lives in the list
	-- of the cleanup, so the intro leaves nothing behind.
	if effectsEnabled then
		local started = os.clock()
		table.insert(
			connections,
			RunService.RenderStepped:Connect(function()
				setBreathing(1 + math.sin((os.clock() - started) * 1.6) * 0.03)
			end)
		)
	end
	RunService.Heartbeat:Wait()
	game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
	streamingRemote = ReplicatedStorage:WaitForChild("MapIntroStreaming", 20)
	assert(streamingRemote, "Streaming service unavailable")
	streamingRemote:FireServer("Prepare")
	local map = workspace:WaitForChild("ProgressionMap", 30)
	assert(map, "Map unavailable")
	local shots = {
		{
			Name = "Lobby",
			A = Vector3.new(95, 110, 185),
			B = Vector3.new(80, 100, 225),
			TA = Vector3.new(30, 28, 240),
			TB = Vector3.new(15, 28, 245),
			Duration = 1.43,
		},
	}
	for i, name in
		{
			"Palm Beach",
			"Desert Dunes",
			"Candy Beach",
			"Violet Valley",
			"Ember River",
			"Moonlight",
			"Frozen Falls",
			"Rainbow Paradise",
		}
	do
		local z = -10.399963 - (i - 1) * 270
		table.insert(shots, {
			Name = name,
			A = Vector3.new(135, 105, z + 45),
			B = Vector3.new(115, 95, z + 5),
			TA = Vector3.new(30, 28, z - 15),
			TB = Vector3.new(20, 29, z - 45),
			Duration = 1.43,
		})
	end
	table.insert(shots, {
		Name = "Final Portal",
		A = Vector3.new(95, 92, -1845),
		B = Vector3.new(48, 78, -1895),
		TA = Vector3.new(48, 73, -2029),
		TB = Vector3.new(48, 73, -2029),
		Duration = 2.13,
	})
	-- Prefetch the remote biomes before flying there. Each request is bounded.
	local ready = 0
	for _, shot in shots do
		task.spawn(function()
			if workspace.StreamingEnabled then
				pcall(function()
					player:RequestStreamAroundAsync(shot.TB, 6)
				end)
			end
			ready += 1
		end)
	end
	local waitStarted = os.clock()
	local function routeReady()
		local world = map:FindFirstChild("SkippingWorld")
		return world and world:FindFirstChild("Water_8") and world:FindFirstChild("SakuraGatewayFrame", true)
	end
	while
		(ready < #shots or not routeReady() or os.clock() - waitStarted < 1)
		and os.clock() - waitStarted < 12
		and not cancelled
	do
		setProgress(ready / #shots)
		RunService.Heartbeat:Wait()
	end
	if cancelled or not routeReady() then
		return
	end
	local camera = workspace.CurrentCamera
	cameraState =
		{ Type = camera.CameraType, Subject = camera.CameraSubject, FOV = camera.FieldOfView, CFrame = camera.CFrame }
	-- Hide only world captions; restore their exact local state afterwards.
	for _, node in map:GetDescendants() do
		if node:IsA("BillboardGui") and node.Enabled then
			node.Enabled = false
			table.insert(connections, {
				Disconnect = function()
					if node.Parent then
						node.Enabled = true
					end
				end,
			})
		end
	end
	local elapsed = 0
	setPhase("EXPLORE THE WORLD")
	RunService:BindToRenderStep("MapIntroCamera", Enum.RenderPriority.Camera.Value + 10, function(dt)
		elapsed = math.min(15, elapsed + dt)
		local localTime, index = elapsed, 1
		while index < #shots and localTime > shots[index].Duration do
			localTime -= shots[index].Duration
			index += 1
		end
		local shot = shots[index]
		local t = math.clamp(localTime / shot.Duration, 0, 1)
		local eased = t * t * (3 - 2 * t)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 58
		camera.CFrame = CFrame.lookAt(shot.A:Lerp(shot.B, eased), shot.TA:Lerp(shot.TB, eased))
		camera.Focus = CFrame.new(shot.TA:Lerp(shot.TB, eased))
		setProgress(elapsed / 15)
		if caption:getValue() ~= shot.Name then
			setCaption(shot.Name)
		end
		-- Mask the edits instead of racing the camera over 2,000 studs.
		local opacity = math.max(1 - localTime / 0.14, 1 - (shot.Duration - localTime) / 0.14, 0)
		setFade(math.clamp(opacity, 0, 1))
	end)
	while elapsed < 15 and not cancelled do
		RunService.Heartbeat:Wait()
	end
	RunService:UnbindFromRenderStep("MapIntroCamera")
	spring:setPosition(1)
	setFade(1)
	-- Camera and controls are restored before revealing the character.
	restoreCamera(true)
	spring:setGoal(0)
	task.wait(0.35)
end, debug.traceback)
cleanup()
if not ok then
	warn("Map intro ended safely: " .. tostring(failure))
end
