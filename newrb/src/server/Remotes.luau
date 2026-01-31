--[[
	Creates and returns the Remotes folder under ReplicatedStorage.
	Server creates these; client reads from ReplicatedStorage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}
local folder: Folder

local function ensureFolder()
	if folder then return folder end
	folder = Instance.new("Folder")
	folder.Name = "ShopRemotes"
	folder.Parent = ReplicatedStorage
	return folder
end

function Remotes.getFolder(): Folder
	return ensureFolder()
end

function Remotes.createRemoteEvent(name: string): RemoteEvent
	ensureFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing :: RemoteEvent
	end
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = folder
	return re
end

function Remotes.createRemoteFunction(name: string): RemoteFunction
	ensureFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing :: RemoteFunction
	end
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = folder
	return rf
end

-- Create all shop remotes (call once from init.server)
function Remotes.createAll()
	ensureFolder()
	
	-- Crate shop
	Remotes.BuyCrate = Remotes.createRemoteEvent("BuyCrate")
	Remotes.OpenCrate = Remotes.createRemoteEvent("OpenCrate")
	Remotes.OpenCrateResult = Remotes.createRemoteEvent("OpenCrateResult")
	
	-- Sell shop
	Remotes.SellWeapon = Remotes.createRemoteEvent("SellWeapon")
	Remotes.SellAllByRarity = Remotes.createRemoteEvent("SellAllByRarity")
	
	-- Upgrades shop
	Remotes.BuyUpgrade = Remotes.createRemoteEvent("BuyUpgrade")
	
	-- Player data
	Remotes.GetPlayerData = Remotes.createRemoteFunction("GetPlayerData")
	Remotes.PlayerDataUpdated = Remotes.createRemoteEvent("PlayerDataUpdated")
	
	-- Shop opening (from ProximityPrompt)
	Remotes.OpenCrateShop = Remotes.createRemoteEvent("OpenCrateShop")
	Remotes.OpenSellShop = Remotes.createRemoteEvent("OpenSellShop")
	Remotes.OpenUpgradesShop = Remotes.createRemoteEvent("OpenUpgradesShop")
	
	return Remotes
end

return Remotes
