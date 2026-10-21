--!strict
-- Client sound and short lived world effects.
-- The music and the effect bus live here so the render loop only writes a
-- volume when the setting actually changed.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Kit = require(script.Parent.HudKit)

local Effects = {}
local C = Color3.fromRGB
local yellow = C(255, 225, 66)

export type Context = {
	canvas: Frame,
	effectsFolder: Folder,
	snapshot: () -> any?,
	panelOpen: () -> boolean,
}

export type Handle = {
	playSound: (string, number?, number?) -> (),
	ripple: (Vector3, Color3?, number?) -> (),
	floatingGain: (number) -> (),
	applyVolumes: (number, number) -> (),
	destroy: () -> (),
}

function Effects.mount(context: Context): Handle
	local canvas = context.canvas
	local musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "SkippingMusic"
	musicGroup.Parent = SoundService
	local effectsGroup = Instance.new("SoundGroup")
	effectsGroup.Name = "SkippingSounds"
	effectsGroup.Parent = SoundService
	local music = Instance.new("Sound")
	music.Name = "PlayfulTropicalHouse"
	music.SoundId = Config.Music
	music.Volume = 0.12
	music.Looped = true
	music.SoundGroup = musicGroup
	music.Parent = SoundService
	music:Play()

	local function playSound(id: string, volume: number?, speed: number?)
		local snapshot = context.snapshot()
		if snapshot and snapshot.data.settings.sound == 0 then
			return
		end
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = volume or 0.3
		sound.PlaybackSpeed = speed or 1
		sound.SoundGroup = effectsGroup
		sound.Parent = SoundService
		sound:Play()
		Debris:AddItem(sound, 3)
	end

	local function makePart(name: string, size: Vector3, color: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = context.effectsFolder
		return p
	end

	local function ripple(pos: Vector3, color: Color3?, splashScale: number?)
		local snapshot = context.snapshot()
		if snapshot and not snapshot.data.settings.effects then
			return
		end
		splashScale = splashScale or 1
		local p = makePart("Splash", Vector3.new(0.1, 1, 1), color or C(220, 255, 255))
		p.Shape = Enum.PartType.Cylinder
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
		p.Transparency = 0.4
		TweenService
			:Create(
				p,
				TweenInfo.new(0.5),
				{ Size = Vector3.new(0.02, 7 * splashScale, 7 * splashScale), Transparency = 1 }
			)
			:Play()
		Debris:AddItem(p, 0.6)
	end

	local function floatingGain(gain: number)
		local snapshot = context.snapshot()
		if context.panelOpen() or (snapshot and snapshot.data.settings.hideHUD) then
			return
		end
		local t = Kit.text(
			canvas,
			"SkillGain",
			"+" .. Config.format(gain),
			560 + math.random(-100, 100),
			340,
			160,
			45,
			30,
			yellow
		)
		t.ZIndex = 25
		Kit.icon(t, "Skill", -22, 4, 30, 36)
		TweenService
			:Create(t, TweenInfo.new(0.9), { Position = t.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 })
			:Play()
		Debris:AddItem(t, 1)
	end

	return {
		playSound = playSound,
		ripple = ripple,
		floatingGain = floatingGain,
		applyVolumes = function(sound: number, musicVolume: number)
			effectsGroup.Volume = sound
			musicGroup.Volume = musicVolume
		end,
		destroy = function()
			music:Stop()
			music:Destroy()
			musicGroup:Destroy()
			effectsGroup:Destroy()
		end,
	}
end

return Effects
