--[[
	Shop logic: BuyCase (keys -> case), OpenCase (case -> weapon + odds), SellWeapon (weapon -> coins), BuyUpgrade (coins -> upgrade).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemotesModule = require(Shared:WaitForChild("Remotes"))
local ConfigWeapons = require(Shared.Config.Weapons)
local ConfigCases = require(Shared.Config.Cases)
local ConfigUpgrades = require(Shared.Config.Upgrades)
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local ShopService = {}
local remotesFolder = nil

-- Build weapon lookup by id and case weapon pools with weights (using oddsDenominator: higher = rarer, so weight = 1/oddsDenominator)
local weaponById: { [string]: any } = {}
for _, w in ConfigWeapons do
	weaponById[w.id] = w
end

local function rollWeaponFromPool(caseConfig): (string, number)
	-- Weight = 1 / oddsDenominator (so common has higher weight)
	local totalWeight = 0
	local entries = {}
	for _, weaponId in caseConfig.weaponPool do
		local w = weaponById[weaponId]
		if w then
			local weight = 1 / w.oddsDenominator
			totalWeight = totalWeight + weight
			table.insert(entries, { weaponId = weaponId, weight = weight, oddsDenominator = w.oddsDenominator })
		end
	end
	local r = math.random() * totalWeight
	for _, e in entries do
		r = r - e.weight
		if r <= 0 then
			return e.weaponId, e.oddsDenominator
		end
	end
	local last = entries[#entries]
	return last.weaponId, last.oddsDenominator
end

function ShopService.Init()
	remotesFolder = RemotesModule.Create()

	local buyCaseRF = remotesFolder:FindFirstChild("BuyCase") :: RemoteFunction
	local getPlayerDataRF = remotesFolder:FindFirstChild("GetPlayerData") :: RemoteFunction
	local openCaseRF = remotesFolder:FindFirstChild("OpenCase") :: RemoteFunction
	local sellWeaponRF = remotesFolder:FindFirstChild("SellWeapon") :: RemoteFunction
	local buyUpgradeRF = remotesFolder:FindFirstChild("BuyUpgrade") :: RemoteFunction

	buyCaseRF.OnServerInvoke = function(player: Player, caseId: string)
		local caseConfig = nil
		for _, c in ConfigCases do
			if c.id == caseId then caseConfig = c break end
		end
		if not caseConfig then return { success = false, error = "Invalid case" } end
		if caseConfig.unlockCondition then
			-- TODO: check player progress (arena completed)
			return { success = false, error = "Case locked" }
		end
		local ok, err = PlayerData.SpendKeys(player, caseConfig.keyCost)
		if not ok then return { success = false, error = err } end
		local instanceId = PlayerData.AddCase(player, caseId)
		return { success = true, caseInstanceId = instanceId, keysLeft = PlayerData.GetKeys(player) }
	end

	getPlayerDataRF.OnServerInvoke = function(player: Player)
		local data = PlayerData.Get(player)
		return {
			keys = data.Keys,
			coins = data.Coins,
			cases = data.Cases,
			weapons = data.Weapons,
			upgrades = data.Upgrades,
		}
	end

	openCaseRF.OnServerInvoke = function(player: Player, caseInstanceId: string)
		local caseEntry = PlayerData.FindCase(player, caseInstanceId)
		if not caseEntry then return { success = false, error = "Case not found" } end
		local caseConfig = nil
		for _, c in ConfigCases do
			if c.id == caseEntry.caseId then caseConfig = c break end
		end
		if not caseConfig then return { success = false, error = "Invalid case" } end
		local ok, _ = PlayerData.RemoveCase(player, caseInstanceId)
		if not ok then return { success = false, error = "Could not remove case" } end
		local weaponId, oddsDenominator = rollWeaponFromPool(caseConfig)
		local weaponInstanceId = PlayerData.AddWeapon(player, weaponId)
		local weaponDef = weaponById[weaponId]
		return {
			success = true,
			weaponId = weaponId,
			weaponName = weaponDef.name,
			rarity = weaponDef.rarity,
			oddsDenominator = oddsDenominator,
			weaponInstanceId = weaponInstanceId,
		}
	end

	sellWeaponRF.OnServerInvoke = function(player: Player, weaponInstanceId: string)
		local weaponEntry = PlayerData.FindWeapon(player, weaponInstanceId)
		if not weaponEntry then return { success = false, error = "Weapon not found" } end
		local weaponDef = weaponById[weaponEntry.weaponId]
		if not weaponDef then return { success = false, error = "Invalid weapon" } end
		local ok, _ = PlayerData.RemoveWeapon(player, weaponInstanceId)
		if not ok then return { success = false, error = "Could not remove weapon" } end
		PlayerData.AddCoins(player, weaponDef.sellPrice)
		return {
			success = true,
			coinsEarned = weaponDef.sellPrice,
			coinsLeft = PlayerData.GetCoins(player),
		}
	end

	buyUpgradeRF.OnServerInvoke = function(player: Player, upgradeId: string)
		local upgradeDef = nil
		for _, u in ConfigUpgrades do
			if u.id == upgradeId then upgradeDef = u break end
		end
		if not upgradeDef then return { success = false, error = "Invalid upgrade" } end
		local ok, err = PlayerData.SpendCoins(player, upgradeDef.coinCost)
		if not ok then return { success = false, error = err } end
		PlayerData.AddUpgrade(player, upgradeId)
		return {
			success = true,
			coinsLeft = PlayerData.GetCoins(player),
			upgradeCount = PlayerData.GetUpgradeCount(player, upgradeId),
		}
	end
end

return ShopService
