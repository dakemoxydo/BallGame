--!strict
-- Keep authorization on the server. Usernames and client attributes are not trusted.
local Access = {}
local owners = {
	[11792184677] = true,
	-- The account of the machine that builds and tests the game.
	[11789507527] = true,
}
function Access.isAuthorized(userId)
	return type(userId) == "number" and owners[userId] == true
end
return Access
