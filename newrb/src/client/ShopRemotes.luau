--[[
	Client-side access to shop remotes. Waits for server to create them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopRemotes = {}
local folder: Folder?

local function getFolder(): Folder
	if folder then return folder end
	folder = ReplicatedStorage:WaitForChild("ShopRemotes", 30) :: Folder
	return folder
end

function ShopRemotes.getFolder(): Folder
	return getFolder()
end

-- Crate shop
function ShopRemotes.buyCrate(): RemoteEvent
	return getFolder():WaitForChild("BuyCrate") :: RemoteEvent
end

function ShopRemotes.openCrate(): RemoteEvent
	return getFolder():WaitForChild("OpenCrate") :: RemoteEvent
end

function ShopRemotes.openCrateResult(): RemoteEvent
	return getFolder():WaitForChild("OpenCrateResult") :: RemoteEvent
end

-- Sell shop
function ShopRemotes.sellWeapon(): RemoteEvent
	return getFolder():WaitForChild("SellWeapon") :: RemoteEvent
end

function ShopRemotes.sellAllByRarity(): RemoteEvent
	return getFolder():WaitForChild("SellAllByRarity") :: RemoteEvent
end

-- Upgrades shop
function ShopRemotes.buyUpgrade(): RemoteEvent
	return getFolder():WaitForChild("BuyUpgrade") :: RemoteEvent
end

-- Player data
function ShopRemotes.getPlayerData(): RemoteFunction
	return getFolder():WaitForChild("GetPlayerData") :: RemoteFunction
end

function ShopRemotes.playerDataUpdated(): RemoteEvent
	return getFolder():WaitForChild("PlayerDataUpdated") :: RemoteEvent
end

-- Shop opening remotes
function ShopRemotes.openCrateShop(): RemoteEvent
	return getFolder():WaitForChild("OpenCrateShop") :: RemoteEvent
end

function ShopRemotes.openSellShop(): RemoteEvent
	return getFolder():WaitForChild("OpenSellShop") :: RemoteEvent
end

function ShopRemotes.openUpgradesShop(): RemoteEvent
	return getFolder():WaitForChild("OpenUpgradesShop") :: RemoteEvent
end

return ShopRemotes
