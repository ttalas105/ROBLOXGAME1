--[[
	In-memory player data: Keys, Coins, Cases (list of { caseId, id }), Weapons (list of { weaponId, id }), Upgrades (map id -> count).
	Later can be swapped for DataStoreService.
]]
local Players = game:GetService("Players")

local ConfigWeapons = require(game.ReplicatedStorage.Shared.Config.Weapons)
local ConfigCases = require(game.ReplicatedStorage.Shared.Config.Cases)
local ConfigUpgrades = require(game.ReplicatedStorage.Shared.Config.Upgrades)

local PlayerData = {}
local dataByPlayer: { [Player]: any } = {}

local function newId()
	return string.format("%s_%s", os.time(), math.random(1, 999999))
end

local function getWeaponById(weaponId)
	for _, w in ConfigWeapons do
		if w.id == weaponId then return w end
	end
	return nil
end

local function getCaseById(caseId)
	for _, c in ConfigCases do
		if c.id == caseId then return c end
	end
	return nil
end

local function getUpgradeById(upgradeId)
	for _, u in ConfigUpgrades do
		if u.id == upgradeId then return u end
	end
	return nil
end

function PlayerData.Get(player: Player)
	if not dataByPlayer[player] then
		dataByPlayer[player] = {
			Keys = 25, -- starter keys for testing
			Coins = 50, -- starter coins
			Cases = {},
			Weapons = {},
			Upgrades = {},
		}
	end
	return dataByPlayer[player]
end

function PlayerData.GetKeys(player: Player)
	return PlayerData.Get(player).Keys
end

function PlayerData.GetCoins(player: Player)
	return PlayerData.Get(player).Coins
end

function PlayerData.GetCases(player: Player)
	return PlayerData.Get(player).Cases
end

function PlayerData.GetWeapons(player: Player)
	return PlayerData.Get(player).Weapons
end

function PlayerData.GetUpgrades(player: Player)
	return PlayerData.Get(player).Upgrades
end

function PlayerData.AddKeys(player: Player, amount: number)
	local data = PlayerData.Get(player)
	data.Keys = data.Keys + amount
	return data.Keys
end

function PlayerData.SpendKeys(player: Player, amount: number): (boolean, string?)
	local data = PlayerData.Get(player)
	if data.Keys < amount then
		return false, "Not enough keys"
	end
	data.Keys = data.Keys - amount
	return true
end

function PlayerData.AddCoins(player: Player, amount: number)
	local data = PlayerData.Get(player)
	data.Coins = data.Coins + amount
	return data.Coins
end

function PlayerData.SpendCoins(player: Player, amount: number): (boolean, string?)
	local data = PlayerData.Get(player)
	if data.Coins < amount then
		return false, "Not enough coins"
	end
	data.Coins = data.Coins - amount
	return true
end

function PlayerData.AddCase(player: Player, caseId: string)
	local data = PlayerData.Get(player)
	local id = newId()
	table.insert(data.Cases, { caseId = caseId, id = id })
	return id
end

function PlayerData.RemoveCase(player: Player, caseInstanceId: string): (boolean, string?)
	local data = PlayerData.Get(player)
	for i, c in data.Cases do
		if c.id == caseInstanceId then
			table.remove(data.Cases, i)
			return true, c.caseId
		end
	end
	return false, "Case not found"
end

function PlayerData.FindCase(player: Player, caseInstanceId: string)
	local data = PlayerData.Get(player)
	for _, c in data.Cases do
		if c.id == caseInstanceId then return c end
	end
	return nil
end

function PlayerData.AddWeapon(player: Player, weaponId: string)
	local data = PlayerData.Get(player)
	local id = newId()
	table.insert(data.Weapons, { weaponId = weaponId, id = id })
	return id
end

function PlayerData.RemoveWeapon(player: Player, weaponInstanceId: string): (boolean, string?)
	local data = PlayerData.Get(player)
	for i, w in data.Weapons do
		if w.id == weaponInstanceId then
			local weaponId = w.weaponId
			table.remove(data.Weapons, i)
			return true, weaponId
		end
	end
	return false, nil
end

function PlayerData.FindWeapon(player: Player, weaponInstanceId: string)
	local data = PlayerData.Get(player)
	for _, w in data.Weapons do
		if w.id == weaponInstanceId then return w end
	end
	return nil
end

function PlayerData.AddUpgrade(player: Player, upgradeId: string, count: number?)
	local data = PlayerData.Get(player)
	data.Upgrades[upgradeId] = (data.Upgrades[upgradeId] or 0) + (count or 1)
	return data.Upgrades[upgradeId]
end

function PlayerData.GetUpgradeCount(player: Player, upgradeId: string)
	local data = PlayerData.Get(player)
	return data.Upgrades[upgradeId] or 0
end

-- Clean up on leave
Players.PlayerRemoving:Connect(function(player)
	dataByPlayer[player] = nil
end)

return PlayerData
