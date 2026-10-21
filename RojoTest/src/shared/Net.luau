--!strict
-- Action: client -> server, command:string, value?, extra?. Requests never carry rewards.
-- Update: server -> owner, authoritative snapshot table; receipts are removed.
-- Effect: server -> owner/all, effect name:string and server-authored payload.
-- Admin: client -> server RemoteFunction, command:string/value?; authorized and rate-limited server-side.
local Net = {}
Net.Folder = "SkippingRemotes"
-- The gameplay remotes exist for every player. The admin remote is created
-- by the server only when an authorized player is in the game, so the admin
-- surface is not part of the world a regular client sees.
Net.Classes = { Action = "RemoteEvent", Update = "RemoteEvent", Effect = "RemoteEvent" }
Net.AdminName = "Admin"
local simple = {
	Snapshot = true,
	Throw = true,
	Auto = true,
	StopTraining = true,
	Rebirth = true,
	EquipBest = true,
	UnequipAll = true,
	Daily = true,
	UnlockAuto = true,
}
local identifiers = { Stone = true, Trail = true, Pet = true, DeletePet = true, Product = true }

function Net.validAction(command: any, value: any, extra: any): boolean
	if typeof(command) ~= "string" or #command > 32 then
		return false
	end
	if simple[command] then
		return value == nil and extra == nil
	end
	if identifiers[command] then
		return typeof(value) == "string" and #value <= 100 and extra == nil
	end
	if command == "Hatch" then
		return typeof(value) == "string" and #value <= 100 and (extra == nil or extra == 1 or extra == 3)
	end
	if command == "Gift" then
		return typeof(value) == "number" and value >= 1 and value <= 6 and value % 1 == 0 and extra == nil
	end
	if command == "Setting" then
		if value == "sound" or value == "music" then
			return typeof(extra) == "number" and extra == extra and math.abs(extra) < math.huge
		end
		return (value == "shake" or value == "effects" or value == "hideHUD") and typeof(extra) == "boolean"
	end
	return false
end

function Net.server(): Folder
	local storage = game:GetService("ReplicatedStorage")
	assert(not storage:FindFirstChild(Net.Folder), "Duplicate gameplay bootstrap")
	local folder = Instance.new("Folder")
	folder.Name = Net.Folder
	for name, class in Net.Classes do
		local remote = Instance.new(class)
		remote.Name, remote.Parent = name, folder
	end
	folder.Parent = storage
	return folder
end

-- The admin remote belongs to the server and appears with the first
-- authorized player. Calling it twice returns the same remote.
function Net.admin(folder: Folder): RemoteFunction
	local existing = folder:FindFirstChild(Net.AdminName)
	if existing then
		assert(existing:IsA("RemoteFunction"), "The admin remote has the wrong class")
		return existing
	end
	local remote = Instance.new("RemoteFunction")
	remote.Name = Net.AdminName
	remote.Parent = folder
	return remote
end

-- The client waits for the admin remote: the server creates it when an
-- authorized player enters, so it can still be on its way.
function Net.adminClient(folder: Folder, timeout: number?): RemoteFunction?
	local node = folder:WaitForChild(Net.AdminName, timeout or 5)
	if node and node:IsA("RemoteFunction") then
		return node
	end
	return nil
end

function Net.client(): Folder
	local folder = game:GetService("ReplicatedStorage"):WaitForChild(Net.Folder, 60)
	assert(folder and folder:IsA("Folder"), "Gameplay remotes unavailable after 60 seconds")
	return folder
end

return Net
