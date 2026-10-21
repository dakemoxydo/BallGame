--!strict
-- World side visuals: the portal beams, the water caustics, the ball stands
-- and the training camera.
-- Every value here is written per frame, so the collections are cached and the
-- transparency and the camera state only change when they really change.
local CollectionService = game:GetService("CollectionService")
local BallVisuals = require(game.ReplicatedStorage.Shared.BallVisuals)
local TrainingCamera = require(game.ReplicatedStorage.Shared.TrainingCamera)
local FlightVisuals = require(script.Parent.Parent.FlightVisuals)

local World = {}

export type Context = {
	player: Player,
	world: () -> number,
	training: () -> number?,
	blocked: () -> boolean,
	effects: () -> boolean,
}

export type Handle = {
	frame: (number) -> (),
	lane: (number, number) -> any,
	captureCamera: () -> (),
	restoreCamera: () -> (),
	destroy: () -> (),
}

function World.mount(context: Context): Handle
	local player = context.player
	local portalBeams: { BasePart } = {}
	local waterTextures: { Texture } = {}
	local standPreviews: { Instance } = CollectionService:GetTagged("BallStandPreview")
	local mapCache: { [number]: any } = {}
	local laneCache: { [string]: { instance: any, found: boolean, retryAt: number } } = {}
	local trainingCamera: any = nil

	local standAdded = CollectionService:GetInstanceAddedSignal("BallStandPreview"):Connect(function(instance: Instance)
		table.insert(standPreviews, instance)
	end)
	local standRemoved = CollectionService:GetInstanceRemovedSignal("BallStandPreview")
		:Connect(function(instance: Instance)
			for i, item in standPreviews do
				if item == instance then
					table.remove(standPreviews, i)
					break
				end
			end
		end)

	task.spawn(function()
		for _, name in { "ProgressionMap", "World2Map" } do
			local map: any = workspace:WaitForChild(name)
			local world: any = map:WaitForChild("SkippingWorld")
			for _, part in world.World2Portal:GetChildren() do
				if part:IsA("BasePart") and part:GetAttribute("AnimatedPortal") then
					table.insert(portalBeams, part)
				end
			end
			for _, part in world:GetChildren() do
				local texture = part:FindFirstChild("WaterCaustics")
				if texture and texture:IsA("Texture") and not part:GetAttribute("FootballPitch") then
					table.insert(waterTextures, texture)
				end
			end
		end
	end)

	-- The lane is looked up once per world and lane number: the string
	-- concatenation and the tree search do not belong in the frame loop.
	-- A miss is not final: the map or the zone can still be streaming in, so
	-- a negative result is kept only until the next retry.
	local LANE_RETRY = 1

	local function trainingLane(world: number, index: number): any
		local key = world .. ":" .. index
		local cached = laneCache[key]
		if cached then
			if cached.found and cached.instance and cached.instance.Parent then
				return cached.instance
			end
			if not cached.found and cached.retryAt > os.clock() then
				return nil
			end
			-- The lane left the tree or the miss is stale, look it up again.
			laneCache[key] = nil
		end
		local map = mapCache[world]
		if map == nil or not map.Parent then
			map = workspace:FindFirstChild(world == 2 and "World2Map" or "ProgressionMap")
			mapCache[world] = map
		end
		local found: any = nil
		if map then
			local zone = map:FindFirstChild("TrainingZone")
			found = zone and zone:FindFirstChild("TrainingLane" .. index)
		end
		if found == nil then
			laneCache[key] = { instance = nil, found = false, retryAt = os.clock() + LANE_RETRY }
		else
			laneCache[key] = { instance = found, found = true, retryAt = 0 }
		end
		return found
	end

	local function captureCamera()
		local cam = workspace.CurrentCamera
		-- The subject is never restored from here: the camera always goes
		-- back to the character's Humanoid.
		trainingCamera = { cameraType = cam.CameraType, cframe = cam.CFrame, fov = cam.FieldOfView }
		FlightVisuals.claimCamera()
	end

	local function restoreCamera()
		if not trainingCamera then
			return
		end
		local saved = trainingCamera
		trainingCamera = nil
		FlightVisuals.releaseCamera(player, saved, saved.fov)
	end

	local function updateStands()
		local camera = workspace.CurrentCamera
		for _, model in standPreviews do
			if model:IsA("Model") and model:IsDescendantOf(workspace) then
				local base = model:GetAttribute("DisplayBasePivot")
				if base and camera and (camera.CFrame.Position - base.Position).Magnitude < 250 then
					local pose, bob = BallVisuals.standPose(
						base,
						workspace:GetServerTimeNow(),
						(model:GetAttribute("DisplaySlot") or 1) * 0.55
					)
					model:PivotTo(pose)
					local link = model:FindFirstChild("DisplayLabel")
					local labelBase = model:GetAttribute("DisplayLabelBase")
					if link and link:IsA("ObjectValue") and link.Value and labelBase then
						link.Value.Position = labelBase + Vector3.new(0, bob, 0)
					end
				end
			end
		end
	end

	return {
		frame = function(dt: number)
			local now = os.clock()
			local effectsOn = context.effects()
			for i, beam in portalBeams do
				beam.Transparency = effectsOn and (0.2 + 0.5 * (0.5 + 0.5 * math.sin(now * 4 + i))) or 0.7
			end
			for _, texture in waterTextures do
				texture.OffsetStudsU = now * 0.45
				texture.OffsetStudsV = now * 0.25
			end
			updateStands()
			local training = context.training()
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if training and root and hum and hum.Health > 0 and not context.blocked() then
				local cam = workspace.CurrentCamera
				if not trainingCamera then
					captureCamera()
				end
				cam.CameraType = Enum.CameraType.Scriptable
				local lane = trainingLane(context.world(), training)
				if lane then
					local target = TrainingCamera.pose(lane, root.Position, cam.ViewportSize)
					local blend = 1 - math.exp(-dt * 7)
					cam.CFrame = cam.CFrame:Lerp(target, blend)
					cam.FieldOfView += (TrainingCamera.FieldOfView - cam.FieldOfView) * blend
				end
			elseif trainingCamera then
				restoreCamera()
			end
		end,
		lane = trainingLane,
		captureCamera = captureCamera,
		restoreCamera = restoreCamera,
		destroy = function()
			standAdded:Disconnect()
			standRemoved:Disconnect()
			portalBeams = {}
			waterTextures = {}
			standPreviews = {}
			restoreCamera()
		end,
	}
end

return World
