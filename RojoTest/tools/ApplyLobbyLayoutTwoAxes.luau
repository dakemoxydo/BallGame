-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
-- Run once in Studio Edit through Studio MCP, after the full scene backup.
local server = game.ServerScriptService.Server
local module = server.LobbyLayoutTwoAxes:Clone()
module.Name = "LayoutTwoAxesEditRun"
module.Parent = server
local ok, result = pcall(function()
	return require(module).apply(workspace.ProgressionMap)
end)
module:Destroy()
assert(ok, result)
-- Refresh stand animation origins and prompts from the moved tiles.
local standModule = server.BallStand:Clone()
standModule.Name = "BallStandLayoutEditRun"
standModule.Parent = server
local standOk, standResult = pcall(function()
	return require(standModule).apply(workspace.ProgressionMap)
end)
standModule:Destroy()
assert(standOk, standResult)
return result:GetFullName()
