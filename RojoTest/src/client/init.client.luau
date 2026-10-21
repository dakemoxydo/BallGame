--!strict
local controllers = { require(script.Controllers.GameplayController) }
for _, controller in controllers do
	controller:Init({})
end
for _, controller in controllers do
	controller:Start()
end
print("[Ball] Client started - BUILD stack-1")
