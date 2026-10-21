-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local model = assert(workspace:FindFirstChild("sakura-split-colors"), "Split sakura missing")
assert(not model:GetAttribute("SakuraColorVersion"), "Already colored")
local backups = game.ServerStorage:FindFirstChild("WorldBackups")
if not backups then
	backups = Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = game.ServerStorage
end
assert(not backups:FindFirstChild("BeforeSplitSakuraColoring"), "Backup exists")
local copy = model:Clone()
copy.Name = "BeforeSplitSakuraColoring"
copy.Parent = backups
local wood, blossoms, petals = 0, 0, 0
local pinks = {
	Color3.fromRGB(255, 178, 211),
	Color3.fromRGB(247, 145, 191),
	Color3.fromRGB(255, 210, 228),
	Color3.fromRGB(239, 126, 178),
}
for _, p in ipairs(model:GetDescendants()) do
	if p:IsA("BasePart") then
		local cf, size = p.CFrame, p.Size
		local collision = { p.CanCollide, p.CanTouch, p.CanQuery }
		if p.Name:find("SakuraWood") then
			p.Color = Color3.fromRGB(107, 62, 46)
			wood += 1
		elseif p.Name:find("SakuraBlossoms") then
			blossoms += 1
			p.Color = pinks[blossoms]
		elseif p.Name:find("SakuraPetal") then
			petals += 1
			p.Color = pinks[(petals - 1) % #pinks + 1]
		else
			error("Unexpected sakura part: " .. p.Name)
		end
		p.Material = Enum.Material.SmoothPlastic
		assert(
			p.CFrame == cf
				and p.Size == size
				and p.CanCollide == collision[1]
				and p.CanTouch == collision[2]
				and p.CanQuery == collision[3],
			"Geometry changed"
		)
	end
end
assert(wood == 1 and blossoms == 4 and petals == 65, "Unexpected part counts")
model:SetAttribute("SakuraColorVersion", 1)
game:GetService("Selection"):Set({ model })
return string.format(
	"Colored wood %d, canopy sections %d, petals %d; geometry and collisions unchanged",
	wood,
	blossoms,
	petals
)
