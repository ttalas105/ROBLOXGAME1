--[[
	Remotes: server creates folder + events/functions; client waits for them.
	Usage: Server calls Remotes.Create(), Client calls Remotes.WaitFor() then use Remotes.*
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}
local folderName = "ShopRemotes"

function Remotes.Create()
	local folder = ReplicatedStorage:FindFirstChild(folderName)
	if folder then return folder end

	folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = ReplicatedStorage

	-- Case shop: get cases list, get player keys, buy case
	local buyCase = Instance.new("RemoteFunction")
	buyCase.Name = "BuyCase"
	buyCase.Parent = folder

	local getPlayerData = Instance.new("RemoteFunction")
	getPlayerData.Name = "GetPlayerData"
	getPlayerData.Parent = folder

	-- Open case (consumes one case from inventory, returns weapon + odds text)
	local openCase = Instance.new("RemoteFunction")
	openCase.Name = "OpenCase"
	openCase.Parent = folder

	-- Sell weapon for coins
	local sellWeapon = Instance.new("RemoteFunction")
	sellWeapon.Name = "SellWeapon"
	sellWeapon.Parent = folder

	-- Buy upgrade (e.g. health potion)
	local buyUpgrade = Instance.new("RemoteFunction")
	buyUpgrade.Name = "BuyUpgrade"
	buyUpgrade.Parent = folder

	return folder
end

function Remotes.WaitFor()
	local folder = ReplicatedStorage:WaitForChild(folderName, 10)
	if not folder then error("ShopRemotes folder not found") end
	return {
		BuyCase = folder:WaitForChild("BuyCase", 5) :: RemoteFunction,
		GetPlayerData = folder:WaitForChild("GetPlayerData", 5) :: RemoteFunction,
		OpenCase = folder:WaitForChild("OpenCase", 5) :: RemoteFunction,
		SellWeapon = folder:WaitForChild("SellWeapon", 5) :: RemoteFunction,
		BuyUpgrade = folder:WaitForChild("BuyUpgrade", 5) :: RemoteFunction,
	}
end

return Remotes
