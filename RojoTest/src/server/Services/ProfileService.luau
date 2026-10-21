--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local AdminService = require(script.Parent.Parent.AdminService)
local Service: any = { profiles = {}, loading = {} }

-- The datastore key and the user id must never reach the log.
local function redact(text: string, player: Player): string
	local result = string.gsub(text, "u_" .. player.UserId, "<key>")
	return (string.gsub(result, tostring(player.UserId), "<user>"))
end

function Service:Init(context: any)
	self.ProfileStore = context.ProfileStore
	self.catalog = { stones = {}, trails = {}, pets = {} }
	for _, item in Config.Stones do
		self.catalog.stones[item.id] = item
	end
	for _, item in Config.Trails do
		self.catalog.trails[item.id] = item
	end
	for _, list in { Config.Pets, Config.UncommonPets, Config.RarePets, Config.RainbowPets, { Config.AdminPet } } do
		for _, item in list do
			self.catalog.pets[item.id] = item
		end
	end
	local store =
		context.ProfileStore.New("BallProfiles_v" .. Config.DataVersion, { version = 0, progress = Data.fresh() })
	self.store = if RunService:IsStudio() then store.Mock else store
	self.legacyStore = if RunService:IsStudio()
		then nil
		else DataStoreService:GetDataStore("StoneSkipping_" .. Config.DataVersion)
end

function Service:Start()
	self.ProfileStore.OnError:Connect(function(message, store, key)
		warn(string.format("[Ball profiles] %s / %s: %s", store, key, message))
	end)
end

function Service:Load(player: Player): any
	if self.loading[player] or self.profiles[player] then
		return nil
	end
	-- The guard is held until the profile is published: the migration below
	-- yields, and a second session for the same key would be rejected by
	-- ProfileStore, so the player would be kicked with a good profile loaded.
	self.loading[player] = true
	local ok, result = pcall(function()
		return self:loadSession(player)
	end)
	self.loading[player] = nil
	if not ok then
		warn("[Ball profiles] Load failed: " .. tostring(result))
		if player.Parent == Players then
			player:Kick("Your data could not be loaded. Please rejoin.")
		end
		return nil
	end
	return result
end

-- Starts the session, migrates the data and publishes the profile. The caller
-- holds the loading guard, so the profile is registered while it is still set.
function Service:loadSession(player: Player): any
	local ok, profile = pcall(function()
		return self.store:StartSessionAsync("Player_" .. player.UserId, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)
	if not ok then
		warn("[Ball profiles] Load failed: " .. tostring(profile))
		profile = nil
	end
	if not profile then
		if player.Parent == Players then
			player:Kick("Your data could not be loaded. Please rejoin.")
		end
		return nil
	end
	if player.UserId > 0 then
		profile:AddUserId(player.UserId)
	end
	profile:Reconcile()
	local initialized, reason = pcall(function()
		assert(profile.Data.version == 0 or profile.Data.version == 1, "Unsupported profile version")
		if profile.Data.version == 0 and self.legacyStore then
			self:importLegacy(player, profile)
		end
		profile.Data.progress = Data.normalize(profile.Data.progress, self.catalog)
		profile.Data.version = 1
	end)
	if not initialized or player.Parent ~= Players or not profile:IsActive() then
		profile:EndSession()
		if not initialized then
			warn("[Ball profiles] Migration failed: " .. tostring(reason))
		end
		if player.Parent == Players then
			player:Kick("Your saved data is unavailable. Please rejoin shortly.")
		end
		return nil
	end
	self.profiles[player] = profile
	player:SetAttribute("ProfileStorage", if RunService:IsStudio() then "ProfileStore.Mock" else "ProfileStore")
	return profile
end

-- A broken legacy record must not lock the player out: the import is skipped
-- and the session continues with a fresh profile instead of kicking the player.
function Service:importLegacy(player: Player, profile: any)
	local ok, record = pcall(function()
		return self.legacyStore:GetAsync("u_" .. player.UserId)
	end)
	if not ok then
		warn("[Ball profiles] Legacy store read failed, starting fresh: " .. redact(tostring(record), player))
		return
	end
	local progress, err = Data.legacy(record, os.time())
	if err then
		warn("[Ball profiles] Legacy import skipped, starting fresh: " .. err)
		return
	end
	if progress then
		profile.Data.progress = progress
	end
end

function Service:Attach(player: Player, state: any, onLost: () -> ())
	local profile = assert(self.profiles[player], "Profile session is missing")
	local function sync()
		local original = AdminService.persistence(state)
		profile.Data.progress = original
	end
	profile.OnSave:Connect(sync)
	profile.OnLastSave:Connect(sync)
	profile.OnSessionEnd:Connect(function()
		if self.profiles[player] == profile then
			self.profiles[player] = nil
			onLost()
			if player.Parent == Players then
				player:Kick("Your data session ended. Please rejoin.")
			end
		end
	end)
end

function Service:Save(player: Player, state: any, receiptId: string?): boolean
	local profile = self.profiles[player]
	if not profile or not profile:IsActive() or state.saving then
		return false
	end
	profile.Data.progress = AdminService.persistence(state)
	if receiptId and profile.LastSavedData.progress.receipts[receiptId] then
		return true
	end
	state.saving = true
	profile:Save()
	-- The save runs in the background, so the guard is released right away:
	-- the leave path and the autosave must not wait for the receipt.
	state.saving = false
	if receiptId then
		local id: string = receiptId
		state.awaitingReceipt = true
		local deadline = os.clock() + 15
		local ok, saved = pcall(function()
			while profile:IsActive() and os.clock() < deadline and not profile.LastSavedData.progress.receipts[id] do
				task.wait(0.1)
			end
			return profile.LastSavedData.progress.receipts[id] == true
		end)
		state.awaitingReceipt = false
		if not ok then
			warn("[Ball profiles] Receipt wait failed: " .. tostring(saved))
			return false
		end
		return profile:IsActive() and saved
	end
	return profile:IsActive()
end

function Service:Release(player: Player, state: any)
	local profile = self.profiles[player]
	if not profile then
		return
	end
	profile.Data.progress = AdminService.persistence(state)
	self.profiles[player] = nil
	profile:EndSession()
	player:SetAttribute("ProfileStorage", nil)
end

return Service
