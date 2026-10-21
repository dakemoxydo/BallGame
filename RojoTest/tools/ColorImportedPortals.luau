-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local model = assert(workspace:FindFirstChild("portals-v6-no-textures"), "Imported portals missing")
assert(not model:GetAttribute("PortalColorsVersion"), "Already colored")
local defs = {
	{ "Arcane Violet", { 132, 91, 167 }, { 51, 27, 78 }, { 221, 174, 255 }, { 191, 114, 250 } },
	{ "Verdant Nature", { 80, 148, 83 }, { 29, 67, 40 }, { 191, 255, 167 }, { 104, 228, 114 } },
	{ "Blazing Fire", { 169, 98, 71 }, { 74, 39, 30 }, { 255, 192, 151 }, { 255, 135, 74 } },
	{ "Frozen Ice", { 67, 140, 165 }, { 20, 66, 88 }, { 181, 243, 255 }, { 100, 220, 255 } },
	{ "Solar Gold", { 166, 147, 58 }, { 73, 62, 23 }, { 255, 241, 167 }, { 255, 212, 86 } },
	{ "Rose Blossom", { 163, 76, 120 }, { 74, 26, 54 }, { 255, 192, 231 }, { 255, 116, 188 } },
}
local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end
local anchors = {}
for _, d in ipairs(defs) do
	local core = assert(model:FindFirstChild(d[1] .. " altar core"), "Missing theme")
	table.insert(anchors, { pos = core.Position, theme = d })
end
local backups = game.ServerStorage:FindFirstChild("WorldBackups")
if not backups then
	backups = Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = game.ServerStorage
end
assert(not backups:FindFirstChild("BeforePortalColoring"), "Backup exists")
local backup = model:Clone()
backup.Name = "BeforePortalColoring"
backup.Parent = backups
local counts = {}
local verified = 0
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		local old = { p.CFrame, p.Size, p.CanCollide, p.CanTouch, p.CanQuery }
		local nearest, dist
		for _, a in ipairs(anchors) do
			local delta = p.Position - a.pos
			local d = delta.X * delta.X + delta.Z * delta.Z
			if not dist or d < dist then
				nearest = a.theme
				dist = d
			end
		end
		local n = p.Name:lower()
		local color = rgb(nearest[2])
		local material = Enum.Material.SmoothPlastic
		if n:find("altar core") or n:find("cross") then
			color = rgb(nearest[3])
		elseif
			n:find("fissure")
			or n:find("rune")
			or n:find("aperture")
			or n:find("emblem")
			or n:find("moon")
			or n:find("snowflake")
			or n:find("sun ray")
			or n:find("star seal")
			or n:find("solar centre")
			or n:find("pedestal sun")
		then
			color = rgb(nearest[4])
			material = Enum.Material.Neon
		elseif n:find("animated spiral") then
			color = rgb(nearest[5]):Lerp(rgb(nearest[4]), 0.12)
		elseif
			n:find("crystal")
			or n:find("gem")
			or n:find("amethyst")
			or n:find("facet")
			or n:find("shard")
			or n:find("ice shoulder")
			or n:find("fire crown")
			or n:find("magic star")
		then
			color = rgb(nearest[5]):Lerp(rgb(nearest[4]), 0.35)
		elseif n:find("flower heart") then
			color = Color3.fromRGB(255, 219, 111)
			material = Enum.Material.Neon
		elseif n:find("petal") or n:find("butterfly wing") then
			color = Color3.fromRGB(255, 161, 211)
		elseif n:find("vine") or n:find("leaf") or n:find("butterfly body") then
			color = Color3.fromRGB(91, 174, 68)
		elseif n:find("segmented altar") then
			color = rgb(nearest[2]):Lerp(rgb(nearest[3]), 0.22)
		end
		p.Color = color
		p.Material = material
		p:SetAttribute("PortalTheme", nearest[1])
		counts[nearest[1]] = (counts[nearest[1]] or 0) + 1
		assert(
			p.CFrame == old[1]
				and p.Size == old[2]
				and p.CanCollide == old[3]
				and p.CanTouch == old[4]
				and p.CanQuery == old[5],
			"Geometry changed"
		)
		verified += 1
	end
end
model:SetAttribute("PortalColorsVersion", 1)
game:GetService("Selection"):Set({ model })
return game:GetService("HttpService"):JSONEncode({ colored = verified, themes = counts, geometryUnchanged = true })
