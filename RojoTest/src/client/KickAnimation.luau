--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Kick = {}
local shots = {}
local active = {}

local function envelope(phase)
	local windupEnd = Config.KickContact - 0.14
	if phase < windupEnd then
		return -0.8 * math.sin(phase / windupEnd * math.pi / 2), 0.7 * phase / windupEnd
	elseif phase < Config.KickContact then
		local alpha = (phase - windupEnd) / 0.14
		return -0.8 + 2.05 * math.sin(alpha * math.pi / 2), 0.7 * (1 - alpha)
	elseif phase < 0.85 then
		return 1.25 * (1 - (phase - Config.KickContact) / (0.85 - Config.KickContact)) ^ 2, 0
	end
	return 0, 0
end

function Kick.play(userId, started)
	shots[userId] = started
end

local function reset(character)
	local joints = active[character]
	if joints then
		for joint, base in joints do
			if joint.Parent then
				joint.Transform = base
			end
		end
		active[character] = nil
	end
end

-- Support classic Motor6D and upgraded AnimationConstraint rigs after Animator evaluation.
RunService.PreSimulation:Connect(function()
	local now = workspace:GetServerTimeNow()
	local seen = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not hum or hum.Health <= 0 then
			continue
		end
		local phase
		local started = character:GetAttribute("TrainingStarted")
		if character:GetAttribute("TrainingLane") and started then
			phase = (now - started) % Config.TrainingCycle
		elseif shots[player.UserId] then
			phase = now - shots[player.UserId]
			if phase >= 0.9 then
				shots[player.UserId] = nil
				phase = nil
			end
		end
		if not phase then
			reset(character)
			continue
		end
		seen[character] = true
		if not active[character] then
			local joints = {}
			for _, joint in character:GetDescendants() do
				if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
					joints[joint] = CFrame.identity
				end
			end
			active[character] = joints
		end
		local angle, knee = envelope(phase)
		for joint, base in active[character] do
			if not joint.Parent then
				continue
			end
			local name = joint.Name
			if name == "RightHip" then
				joint.Transform = base * CFrame.Angles(angle, 0, -0.06)
			elseif name == "Right Hip" then
				joint.Transform = base * CFrame.Angles(0, 0, angle)
			elseif name == "RightKnee" then
				joint.Transform = base * CFrame.Angles(-knee, 0, 0)
			elseif name == "Waist" or name == "RootJoint" then
				joint.Transform = base * CFrame.Angles(-angle * 0.12, -angle * 0.08, 0)
			elseif name == "LeftShoulder" then
				joint.Transform = base * CFrame.Angles(-angle * 0.4, 0, -0.2)
			elseif name == "RightShoulder" then
				joint.Transform = base * CFrame.Angles(angle * 0.35, 0, 0.2)
			elseif name == "Left Shoulder" then
				joint.Transform = base * CFrame.Angles(0, 0, angle * 0.3)
			elseif name == "Right Shoulder" then
				joint.Transform = base * CFrame.Angles(0, 0, -angle * 0.3)
			end
		end
	end
	for character in active do
		if not seen[character] then
			reset(character)
		end
	end
end)
return Kick
