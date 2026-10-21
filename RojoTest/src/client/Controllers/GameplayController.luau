--!strict
local Controller = {}
function Controller:Init(_context: any) end
function Controller:Start()
	local clientRoot = script.Parent.Parent
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local Lighting = game:GetService("Lighting")
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
	local TrainingMotion = require(ReplicatedStorage.Shared:WaitForChild("TrainingMotion"))
	local KickAnimation = require(clientRoot:WaitForChild("KickAnimation"))
	local FlightVisuals = require(clientRoot:WaitForChild("FlightVisuals"))
	local Snapshot = require(clientRoot.Modules:WaitForChild("Snapshot"))
	local GuiInsets = require(clientRoot.Modules:WaitForChild("GuiInsets"))
	local HudLayout = require(clientRoot.Modules:WaitForChild("HudLayout"))
	local Kit = require(clientRoot.Controllers:WaitForChild("HudKit"))
	local HudBuilder = require(clientRoot.Controllers:WaitForChild("HudBuilder"))
	local HudPanels = require(clientRoot.Controllers:WaitForChild("HudPanels"))
	local PetFollowers = require(clientRoot.Controllers:WaitForChild("PetFollowers"))
	local InputController = require(clientRoot.Controllers:WaitForChild("InputController"))
	local AudioEffects = require(clientRoot.Controllers:WaitForChild("AudioEffects"))
	local BallHolder = require(clientRoot.Controllers:WaitForChild("BallHolder"))
	local WorldVisuals = require(clientRoot.Controllers:WaitForChild("WorldVisuals"))
	task.spawn(function()
		require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VolcanicEggVisual")).start()
	end)
	task.spawn(function()
		game:GetService("ContentProvider"):PreloadAsync({ ReplicatedStorage.Shared:WaitForChild("PetTemplates") })
	end)
	local player = Players.LocalPlayer
	local remotes = require(ReplicatedStorage.Shared:WaitForChild("Net")).client()
	local function remote(name: string): RemoteEvent
		local node = remotes:WaitForChild(name)
		if node and node:IsA("RemoteEvent") then
			return node
		end
		error("Missing gameplay remote: " .. name)
	end
	local action = remote("Action")
	local update = remote("Update")
	local effect = remote("Effect")
	local C = Color3.fromRGB
	local yellow = C(255, 225, 66)
	local latest: any = nil
	local currentPanel: string? = nil
	local flight: any = nil
	local hatchBusy = false
	local activeEgg = "Common"
	local collectorUI: any = nil
	local adminUI: any = nil
	local panels: any = nil
	local openPanel: (string) -> () = function() end

	local function send(command: string, value: any?, extra: any?)
		if player:GetAttribute("MapIntroActive") and command ~= "Snapshot" then
			return
		end
		action:FireServer(command, value, extra)
	end

	-- The HUD lives on a probe frame that reports the area the engine really
	-- granted, so the board never reaches into the notch or the gesture bar.
	local gui = Instance.new("ScreenGui")
	gui.Name = "SkippingHUD"
	GuiInsets.prepare(gui)
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local probe = Instance.new("Frame")
	probe.Name = "SafeArea"
	probe.Size = UDim2.fromScale(1, 1)
	probe.BackgroundTransparency = 1
	probe.Parent = gui
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.AnchorPoint = Vector2.new(0.5, 0.5)
	canvas.Position = UDim2.fromScale(0.5, 0.5)
	canvas.Size = UDim2.fromOffset(1280, 720)
	canvas.BackgroundTransparency = 1
	canvas.Parent = probe
	local scale = Instance.new("UIScale")
	scale.Parent = canvas
	local blur = Instance.new("BlurEffect")
	blur.Name = "SkippingMenuBlur"
	blur.Size = 0
	blur.Parent = Lighting

	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "SkippingClientEffects"
	effectsFolder.Parent = workspace

	local hudRefs = HudBuilder.build({
		canvas = canvas,
		send = send,
		openPanel = function(name: string)
			openPanel(name)
		end,
		snapshot = function()
			return latest
		end,
	})
	local hud = hudRefs.hud

	local layout =
		{ mode = "landscape", portrait = false, width = 1280, height = 720, levelWidth = 592, levelHeight = 61 }
	local pins = HudLayout.pins(HudLayout.landscape(), hud)
	local measured = Vector2.zero
	-- The probe reports the granted rectangle only after the engine runs its
	-- first layout pass. The first real measurement therefore only sets the
	-- orientation, it never switches it, so no panel is closed on startup.
	local orientationKnown = false

	local function closePanel()
		if collectorUI then
			collectorUI:close()
			collectorUI:setHidden(false)
		end
		if adminUI then
			adminUI.close()
		end
		currentPanel = nil
		panels.reset()
		hatchBusy = false
		-- The panel leaves the screen instead of vanishing: it shrinks a little
		-- and the world behind it comes back into focus.
		for _, child in ipairs(canvas:GetChildren()) do
			if child:IsA("Frame") and child.Name == "Modal" then
				local shrink = child:FindFirstChildOfClass("UIScale")
				if shrink then
					TweenService:Create(shrink, TweenInfo.new(0.14), { Scale = shrink.Scale * 0.86 }):Play()
				end
				task.delay(0.15, function()
					if child.Parent then
						child:Destroy()
					end
				end)
			end
		end
		TweenService:Create(blur, TweenInfo.new(0.18), { Size = 0 }):Play()
		if latest then
			hud.Visible = not latest.data.settings.hideHUD
		end
	end

	-- The tab row of the collector belongs to the collector: the legacy
	-- panels are modal and hide it while they are open.
	local function navAllowed(panel: string?): boolean
		if panel == nil then
			return true
		end
		return panel == "Pets"
			or panel == "Trails"
			or panel == "Shop"
			or panel == "Hatch"
			or panel == Config.find(Config.Eggs, activeEgg).name
	end

	panels = HudPanels.mount({
		canvas = canvas,
		send = send,
		snapshot = function()
			return latest
		end,
		portrait = function()
			return layout.portrait
		end,
		closePanel = closePanel,
		showPanel = function(name: string)
			currentPanel = name
			hud.Visible = false
			if collectorUI then
				collectorUI:setHidden(not navAllowed(name))
			end
		end,
		blur = function(size: number)
			TweenService:Create(blur, TweenInfo.new(0.18), { Size = size }):Play()
		end,
	})

	-- Landscape keeps the wide board, portrait rebuilds the same elements as a
	-- narrow column with the primary buttons at the bottom of the screen.
	local function applyLayout()
		local camera = workspace.CurrentCamera
		local viewport = camera.ViewportSize
		local area = GuiInsets.area(viewport, probe)
		local granted = probe.AbsoluteSize
		local portrait = area.size.X < area.size.Y
		if not orientationKnown then
			layout.portrait = portrait
			if granted.X > 0 and granted.Y > 0 then
				orientationKnown = true
			end
		elseif portrait ~= layout.portrait then
			layout.portrait = portrait
			closePanel()
		end
		layout.mode = if portrait then "portrait" else "landscape"
		layout.width = area.size.X
		layout.height = area.size.Y
		local spec = if portrait then HudLayout.portrait(area.size.X, area.size.Y) else HudLayout.landscape()
		HudLayout.apply(spec, { hud, canvas })
		local level = spec.elements["LevelBar"]
		layout.levelWidth = level.w
		layout.levelHeight = level.h
		if portrait then
			scale.Scale = 1
			canvas.Size = UDim2.fromOffset(area.size.X, area.size.Y)
			canvas.Position = UDim2.fromOffset(area.offset.X + area.size.X / 2, area.offset.Y + area.size.Y / 2)
		else
			local factor = math.max(0.01, math.min(area.size.X / 1280, area.size.Y / 720))
			scale.Scale = factor
			canvas.Size = UDim2.fromOffset(1280, 720)
			-- The canvas is anchored in its middle, so the board is centred
			-- inside the granted rectangle.
			canvas.Position = UDim2.fromOffset(area.offset.X + area.size.X / 2, area.offset.Y + area.size.Y / 2)
			local gutter = (area.size.X / factor - 1280) / 2
			local margin = 16 / factor
			for _, pin in pins do
				local x = pin.side == "left" and (-gutter + margin + pin.offset)
					or (1280 + gutter - margin + pin.offset)
				local position = pin.node.Position
				pin.node.Position = UDim2.new(0, x, position.Y.Scale, position.Y.Offset)
			end
		end
	end

	local toastId = 0
	-- The toast fades in over the world and fades out again: the message is
	-- the only thing that moves when nothing else happens.
	local function notice(message: string?)
		if not message or message == "" then
			return
		end
		-- The legacy toast lives under the collector windows: its gui sits
		-- on DisplayOrder 20 while the collector mounts at 30, so while a
		-- collector screen owns the panel the answer has to be drawn inside
		-- its window as well. Legacy panels keep the plain toast on top.
		if currentPanel ~= nil and navAllowed(currentPanel) and collectorUI then
			collectorUI:notice(message)
		end
		toastId += 1
		local id = toastId
		local toast = hudRefs.toast
		local stroke = toast:FindFirstChildOfClass("UIStroke")
		toast.Text = message
		toast.Visible = true
		hudRefs.toastPlate.Visible = true
		TweenService:Create(toast, TweenInfo.new(0.16), { TextTransparency = 0 }):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.16), { Transparency = 0 }):Play()
		end
		task.delay(2.6, function()
			if toastId ~= id then
				return
			end
			local fade = TweenService:Create(toast, TweenInfo.new(0.32), { TextTransparency = 1 })
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.32), { Transparency = 1 }):Play()
			end
			fade.Completed:Once(function()
				if toastId == id then
					toast.Visible = false
					hudRefs.toastPlate.Visible = false
				end
			end)
			fade:Play()
		end)
	end

	local function openCollector(name: string, kind: string, eggId: string?)
		closePanel()
		currentPanel = name
		hud.Visible = false
		-- The world behind an open screen is blurred like the legacy panels:
		-- the window is translucent and the world must not fight with it.
		TweenService:Create(blur, TweenInfo.new(0.18), { Size = 22 }):Play()
		collectorUI:setHidden(false)
		collectorUI:open(kind, eggId)
	end

	local function openEgg(id: string)
		local egg = Config.find(Config.Eggs, id)
		if not egg then
			return
		end
		activeEgg = id
		openCollector(egg.name, "Eggs", id)
	end

	collectorUI = require(clientRoot.CollectorUI).mount({
		send = send,
		close = closePanel,
		open = function(name: string)
			if name == "Eggs" and currentPanel == Config.find(Config.Eggs, activeEgg).name then
				closePanel()
			else
				openPanel(name)
			end
		end,
		selectEgg = function(id: string)
			activeEgg = id
			currentPanel = Config.find(Config.Eggs, id).name
		end,
	})

	openPanel = function(name: string)
		if currentPanel == name then
			closePanel()
			return
		end
		if name == "Eggs" then
			openEgg(activeEgg)
			return
		end
		if name == "Trails" then
			openCollector("Trails", "Trails")
		elseif name == "Settings" then
			panels.open("Settings")
		elseif name == "Rebirth" then
			panels.open("Rebirth")
		elseif name == "Inventory" then
			panels.open("Inventory")
		elseif name == "Pets" then
			openCollector("Pets", "Pets")
		elseif name == "Gifts" then
			panels.open("Gifts")
		elseif name == "Shop" then
			openCollector("Shop", "Shop")
		end
	end

	applyLayout()
	local viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
	probe:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)

	local effects = AudioEffects.mount({
		canvas = canvas,
		effectsFolder = effectsFolder,
		snapshot = function()
			return latest
		end,
		panelOpen = function()
			return currentPanel ~= nil
		end,
	})
	local followers = PetFollowers.mount({ effectsFolder = effectsFolder })
	local balls = BallHolder.mount()
	local world = WorldVisuals.mount({
		player = player,
		world = function()
			return latest and latest.data.world or 1
		end,
		training = function()
			return latest and latest.training
		end,
		blocked = function()
			return flight ~= nil
		end,
		effects = function()
			return latest == nil or latest.data.settings.effects
		end,
	})
	local input = InputController.mount({
		player = player,
		send = send,
		openPanel = function(name: string)
			openPanel(name)
		end,
		closePanel = closePanel,
		panel = function()
			return currentPanel
		end,
		clearHatch = function()
			hatchBusy = false
		end,
		snapshot = function()
			return latest
		end,
		activeEgg = function()
			return activeEgg
		end,
		eggName = function(id: string)
			local egg = Config.find(Config.Eggs, id)
			return egg and egg.name or ""
		end,
		hatch = function(id: string, count: number)
			collectorUI:request("Hatch", id, count)
		end,
	})

	local function beginThrow(info: any)
		KickAnimation.play(info.userId, info.startedAt or workspace:GetServerTimeNow())
		local me = info.userId == player.UserId
		local token = {}
		if me then
			world.restoreCamera()
			closePanel()
			flight = token
			hudRefs.powerText.Visible = false
			collectorUI:setHidden(true)
		end
		local saved = FlightVisuals.start(info, {
			me = me,
			player = player,
			active = function()
				return flight == token
			end,
			effects = function()
				return not latest or latest.data.settings.effects
			end,
			shake = function()
				return latest and latest.data.settings.shake
			end,
			ripple = effects.ripple,
			distance = function(value: string)
				hudRefs.distanceText.Text = value
			end,
			kick = function(feedback: any)
				effects.playSound("rbxasset://sounds/action_jump.mp3", feedback.kickVolume, feedback.kickPlayback)
			end,
			finish = function()
				flight = nil
				hudRefs.distanceText.Text = ""
				hudRefs.powerText.Visible = true
			end,
		})
		token.saved = saved
	end

	local function hatchAnimation(pets: any)
		if hatchBusy then
			return
		end
		closePanel()
		hatchBusy = true
		currentPanel = "Hatch"
		hud.Visible = false
		TweenService:Create(blur, TweenInfo.new(0.2), { Size = 18 }):Play()
		collectorUI:setHidden(false)
		collectorUI:hatch(pets)
	end

	effect.OnClientEvent:Connect(function(kind: string, info: any)
		if kind == "Throw" then
			beginThrow(info)
		elseif kind == "ShotBounce" then
			effects.floatingGain(info.gain)
		elseif kind == "Train" then
			effects.floatingGain(info.gain)
			balls.setPractice(latest and latest.data.stone or "Pebble")
		elseif kind == "Result" then
			notice("+" .. Config.format(info.wins) .. " WINS • " .. Config.format(info.distance) .. " m")
		elseif kind == "Hatch" then
			task.spawn(hatchAnimation, info)
		elseif kind == "Egg" then
			openEgg(info)
		elseif kind == "AdminEgg" then
			local modal = panels.shell("Volcanic Inferno Egg", "Egg", 620, 385)
			Kit.icon(modal, "Pets", 210, 65, 200, 195, Config.AdminPet.color)
			Kit.text(modal, "PetName", "Glitched Dragon • MYTHIC", 20, 30, 580, 37, 27, Config.AdminPet.color)
			Kit.text(modal, "Boost", "×25 Skill", 180, 252, 260, 41, 29, yellow)
			Kit.button(modal, "BuyAdmin", "Hatch • 175 Robux", 143, 312, 334, 49, C(94, 238, 22), 27, function()
				send("Product", "AdminEgg")
			end)
		elseif kind == "Open" then
			openPanel(info)
		elseif kind == "OpenBall" then
			panels.open("Inventory", info)
		elseif kind == "Rebirth" then
			notice("REBIRTH! Your skill multiplier increased!")
			closePanel()
		elseif kind == "AdminResetView" or kind == "ShotCancelled" then
			world.restoreCamera()
			if flight then
				local saved = flight.saved
				if saved and saved.cancel then
					saved.cancel()
				end
				flight = nil
				-- The camera goes back to the character, the stale frame of the
				-- cancelled shot is dropped.
				FlightVisuals.releaseCamera(player, saved, saved and saved.fov or 70)
				hudRefs.distanceText.Text = ""
				hudRefs.powerText.Visible = true
			end
		elseif kind == "World" then
			notice(info == 2 and "WORLD 2 • ×3 SKILL & WINS" or "Welcome back to World 1")
		end
	end)

	update.OnClientEvent:Connect(function(payload: any)
		local info = Snapshot.apply(payload)
		if not info.training then
			world.restoreCamera()
		end
		latest = info
		if adminUI then
			adminUI.update(info)
		end
		collectorUI:update(info)
		collectorUI:setHidden(flight ~= nil or not navAllowed(currentPanel))
		local d = info.data
		hudRefs.skillText.Text = Config.format(d.skill) .. " SKILL"
		hudRefs.multiText.Text = "×" .. string.format("%.2f", info.multiplier) .. " Multiplier"
		hudRefs.levelText.Text = "Level " .. info.level
		hudRefs.maxText.Text = info.level == Config.MaxLevel and "MAX LEVEL"
			or Config.format(d.skill - info.levelStart) .. " / " .. Config.format(info.nextLevel - info.levelStart)
		local progress = info.level == Config.MaxLevel and 1
			or math.clamp((d.skill - info.levelStart) / math.max(1, info.nextLevel - info.levelStart), 0, 1)
		TweenService:Create(hudRefs.levelFill, TweenInfo.new(0.3), {
			Size = UDim2.fromOffset(math.max(4, layout.levelWidth * progress), layout.levelHeight),
		}):Play()
		hudRefs.rebirthText.Text = tostring(d.rebirths)
		hudRefs.winsText.Text = Config.format(d.wins)
		hudRefs.friendText.Text = "Friend Boost +" .. info.friendBoost .. "%"
		hudRefs.powerText.Text = "HIT: "
			.. Config.format(info.shotDistance or Config.shotDistance(d.skill, 1, d.world))
			.. " m"
		hudRefs.powerText.Visible = not flight
		hudRefs.bestText.Text = d.best > 0 and "BEST: " .. Config.format(d.best) .. " m" or ""
		hudRefs.rebirthPercent.Text = math.floor((info.rebirthProgress or 0) * 100) .. "%"
		hudRefs.throwButton.Visible = info.canThrow and not flight and not info.training
		hudRefs.stopButton.Visible = info.training ~= nil
		local throwShadow = hud:FindFirstChild("ThrowShadow")
		if throwShadow and throwShadow:IsA("GuiObject") then
			throwShadow.Visible = hudRefs.throwButton.Visible
		end
		local stopShadow = hud:FindFirstChild("StopTrainingShadow")
		if stopShadow and stopShadow:IsA("GuiObject") then
			stopShadow.Visible = hudRefs.stopButton.Visible
		end
		local autoCaption = Kit.captionOf(hudRefs.auto)
		if autoCaption then
			autoCaption.Text = info.auto and "AUTO: ON" or "AUTO THROW"
		end
		hud.Visible = currentPanel == nil and not d.settings.hideHUD
		hudRefs.tutorial.Visible = not flight
		hudRefs.tutorial.Text = info.training and "Training! STOP TRAINING or jump to leave"
			or (
				info.canThrow and "Press E to kick • Train to increase hit distance"
				or "Walk onto a training pad to gain Skill"
			)
		if not info.training then
			balls.setPractice(nil)
		else
			balls.setPractice(d.stone)
		end
		balls.setStone(d.stone)
		panels.refresh()
		followers.refresh(Snapshot.equipped(), Snapshot.pets())
		notice(info.notice)
	end)

	effect.OnClientEvent:Connect(function(kind: string)
		if kind == "Result" or kind == "Hatch" or kind == "Rebirth" then
			effects.playSound("rbxasset://sounds/volume_slider.ogg", 0.25, 1.4)
		end
	end)

	adminUI = require(clientRoot.AdminPanel).mount({
		closePanel = closePanel,
		activate = function()
			closePanel()
			currentPanel = "Admin"
			hud.Visible = false
			collectorUI:setHidden(true)
			TweenService:Create(blur, TweenInfo.new(0.18), { Size = 16 }):Play()
		end,
	})

	local appliedSoundVolume = -1
	local appliedMusicVolume = -1

	RunService.RenderStepped:Connect(function(dt: number)
		local now = os.clock()
		-- The safe area is only known after the first layout pass, so the
		-- board is rebuilt whenever the granted rectangle changes. A zero
		-- measurement means the probe is not laid out yet, it is ignored.
		local granted = probe.AbsoluteSize
		if granted.X > 0 and granted.Y > 0 and granted ~= measured then
			measured = granted
			applyLayout()
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		world.frame(dt)
		local hand = player.Character
			and (player.Character:FindFirstChild("RightHand") or player.Character:FindFirstChild("Right Arm"))
		if hand and latest then
			balls.held():PivotTo(hand.CFrame * CFrame.new(0, -0.4, -0.2))
		end
		balls.showHeld(hand ~= nil and latest ~= nil and not flight and not latest.training)
		followers.update(root, now)
		local practice = balls.practice()
		if practice and latest and latest.training and root then
			local lane = world.lane(latest.data.world, latest.training)
			local started = player.Character:GetAttribute("TrainingStarted") or latest.trainingStarted
			if lane and started then
				local phase = (workspace:GetServerTimeNow() - started) % Config.TrainingCycle
				local radius = 0.8
				local start =
					Vector3.new(root.Position.X + 2.2, Config.trainingSurface(lane) + radius, root.Position.Z + 0.65)
				local target =
					Vector3.new(lane.TrainingStrip.Position.X + lane.TrainingStrip.Size.X / 2 - 2, start.Y, start.Z)
				local position = TrainingMotion.position(start, target, phase, latest.training)
				practice:PivotTo(CFrame.new(position) * CFrame.Angles(0, 0, -(position.X - start.X) / radius))
				balls.showPractice(phase < 1.15)
			end
		end
		if latest then
			local soundVolume = latest.data.settings.sound / 100
			local musicVolume = latest.data.settings.music / 100
			if soundVolume ~= appliedSoundVolume or musicVolume ~= appliedMusicVolume then
				appliedSoundVolume = soundVolume
				appliedMusicVolume = musicVolume
				effects.applyVolumes(soundVolume, musicVolume)
			end
		end
	end)

	player.CharacterAdded:Connect(function()
		world.restoreCamera()
		if flight then
			local saved = flight.saved
			flight = nil
			-- The character respawned during the shot: the camera follows the
			-- new one instead of staying at the ball.
			FlightVisuals.releaseCamera(player, saved, saved and saved.fov or 70)
			hudRefs.distanceText.Text = ""
		end
	end)

	clientRoot.Destroying:Connect(function()
		viewportConnection:Disconnect()
		input.destroy()
		followers.destroy()
		effects.destroy()
		balls.destroy()
		world.destroy()
		if adminUI then
			adminUI.destroy()
		end
		collectorUI:destroy()
	end)

	send("Snapshot")
	print("StoneSkipping HUD ready")
end
return Controller
