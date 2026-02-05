--[[
	Stores and updates player data: keys, xp, weapons, crates, upgrades.
	Persists data using DataStore (when available).
	Falls back to session-only storage in Studio without API access.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- DataStore setup with Studio fallback
local DATA_STORE_NAME = "PlayerDataV1"
local playerDataStore = nil
local useDataStore = false

-- Try to get DataStore (will fail in Studio without API access enabled)
local success, result = pcall(function()
	return DataStoreService:GetDataStore(DATA_STORE_NAME)
end)

if success and result then
	playerDataStore = result
	useDataStore = true
	print("[PlayerData] DataStore enabled")
else
	warn("[PlayerData] DataStore not available (Studio mode) - using session storage only")
	useDataStore = false
end

export type WeaponInstance = { weaponId: string, uid: string }

-- Displayed weapon on a pedestal: tracks which weapon uid is on which pedestal slot
export type DisplayedWeapon = { pedestalIndex: number, weaponUid: string, weaponId: string }

export type PlayerDataState = {
	keys: number,
	gems: number,
	xp: number,
	weapons: { WeaponInstance },
	crates: { [string]: number }, -- crateId -> count
	upgrades: { [string]: number }, -- upgradeId -> level/count
	arenasCompleted: { [number]: boolean }, -- arenaNumber -> completed
	health: number, -- current health
	maxHealth: number, -- max health (base 100, can be increased)
	-- Home Base
	assignedBasePlot: number?, -- which plot (1-7) this player owns, nil if none
	displayedWeapons: { DisplayedWeapon }, -- weapons on pedestals
}

local PlayerData = {}
local dataByPlayer: { [Player]: PlayerDataState } = {}
local dataLoadedByPlayer: { [Player]: boolean } = {}
local nextUid = 0

local function newUid(): string
	nextUid += 1
	return "w_" .. tostring(nextUid) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

local BASE_HEALTH = 100

-- Starting weapon
local STARTING_WEAPON_ID = "wooden_sword"

-- Convert data to saveable format (no metatables, simple types)
local function serializeData(data: PlayerDataState): { [string]: any }
	local serialized = {
		keys = data.keys,
		gems = data.gems,
		xp = data.xp,
		weapons = {},
		crates = data.crates,
		upgrades = data.upgrades,
		arenasCompleted = {},
		health = data.health,
		maxHealth = data.maxHealth,
		assignedBasePlot = data.assignedBasePlot,
		displayedWeapons = {},
	}
	
	-- Serialize weapons
	for _, w in data.weapons do
		table.insert(serialized.weapons, { weaponId = w.weaponId, uid = w.uid })
	end
	
	-- Serialize arenasCompleted (convert number keys to strings for DataStore)
	for arenaNum, completed in data.arenasCompleted do
		serialized.arenasCompleted[tostring(arenaNum)] = completed
	end
	
	-- Serialize displayed weapons
	for _, dw in data.displayedWeapons do
		table.insert(serialized.displayedWeapons, {
			pedestalIndex = dw.pedestalIndex,
			weaponUid = dw.weaponUid,
			weaponId = dw.weaponId,
		})
	end
	
	return serialized
end

-- Convert loaded data back to PlayerDataState
local function deserializeData(saved: { [string]: any }): PlayerDataState
	local data: PlayerDataState = {
		keys = saved.keys or Config.StartingKeys,
		gems = saved.gems or Config.StartingGems,
		xp = saved.xp or Config.StartingXP,
		weapons = {},
		crates = saved.crates or {},
		upgrades = saved.upgrades or {},
		arenasCompleted = {},
		health = saved.health or BASE_HEALTH,
		maxHealth = saved.maxHealth or BASE_HEALTH,
		assignedBasePlot = saved.assignedBasePlot,
		displayedWeapons = {},
	}
	
	-- Deserialize weapons
	if saved.weapons then
		for _, w in saved.weapons do
			table.insert(data.weapons, { weaponId = w.weaponId, uid = w.uid })
		end
	end
	
	-- Deserialize arenasCompleted (convert string keys back to numbers)
	if saved.arenasCompleted then
		for arenaStr, completed in saved.arenasCompleted do
			local arenaNum = tonumber(arenaStr)
			if arenaNum then
				data.arenasCompleted[arenaNum] = completed
			end
		end
	end
	
	-- Deserialize displayed weapons
	if saved.displayedWeapons then
		for _, dw in saved.displayedWeapons do
			table.insert(data.displayedWeapons, {
				pedestalIndex = dw.pedestalIndex,
				weaponUid = dw.weaponUid,
				weaponId = dw.weaponId,
			})
		end
	end
	
	return data
end

-- Create default data for new players
local function createDefaultData(): PlayerDataState
	return {
		keys = Config.StartingKeys,
		gems = Config.StartingGems,
		xp = Config.StartingXP,
		weapons = {
			{ weaponId = STARTING_WEAPON_ID, uid = newUid() }, -- Starting weapon
		},
		crates = {},
		upgrades = {},
		arenasCompleted = {},
		health = BASE_HEALTH,
		maxHealth = BASE_HEALTH,
		assignedBasePlot = nil, -- Will be assigned by BaseService
		displayedWeapons = {},
	}
end

-- Load player data from DataStore (or create new if not available)
function PlayerData.load(player: Player): PlayerDataState
	local userId = player.UserId
	local key = "Player_" .. tostring(userId)
	
	-- If DataStore is available, try to load
	if useDataStore and playerDataStore then
		local success, result = pcall(function()
			return playerDataStore:GetAsync(key)
		end)
		
		if success and result then
			print("[PlayerData] Loaded data for", player.Name)
			local data = deserializeData(result)
			dataByPlayer[player] = data
			dataLoadedByPlayer[player] = true
			return data
		elseif not success then
			warn("[PlayerData] Failed to load data for", player.Name, ":", result)
		end
	end
	
	-- Create new data (DataStore not available or no saved data)
	print("[PlayerData] Creating new data for", player.Name)
	local data = createDefaultData()
	dataByPlayer[player] = data
	dataLoadedByPlayer[player] = true
	return data
end

-- Save player data to DataStore
function PlayerData.save(player: Player): boolean
	-- Skip if DataStore not available
	if not useDataStore or not playerDataStore then
		return false
	end
	
	if not dataLoadedByPlayer[player] then
		return false -- Don't save if data wasn't loaded
	end
	
	local data = dataByPlayer[player]
	if not data then return false end
	
	local userId = player.UserId
	local key = "Player_" .. tostring(userId)
	
	local serialized = serializeData(data)
	
	local success, err = pcall(function()
		playerDataStore:SetAsync(key, serialized)
	end)
	
	if success then
		print("[PlayerData] Saved data for", player.Name)
	else
		warn("[PlayerData] Failed to save data for", player.Name, ":", err)
	end
	
	return success
end

-- Check if data is loaded
function PlayerData.isLoaded(player: Player): boolean
	return dataLoadedByPlayer[player] == true
end

local function getOrCreate(player: Player): PlayerDataState
	if not dataByPlayer[player] then
		-- Data should be loaded via PlayerData.load() first
		-- This is a fallback for edge cases
		return PlayerData.load(player)
	end
	return dataByPlayer[player]
end

function PlayerData.get(player: Player): PlayerDataState
	return getOrCreate(player)
end

-- Get weapons list
function PlayerData.getWeapons(player: Player): { WeaponInstance }
	return getOrCreate(player).weapons
end

-- Keys
function PlayerData.getKeys(player: Player): number
	return getOrCreate(player).keys
end

function PlayerData.addKeys(player: Player, amount: number): number
	local d = getOrCreate(player)
	d.keys += amount
	return d.keys
end

function PlayerData.spendKeys(player: Player, amount: number): boolean
	local d = getOrCreate(player)
	if d.keys < amount then return false end
	d.keys -= amount
	return true
end

-- Gems
function PlayerData.getGems(player: Player): number
	return getOrCreate(player).gems
end

function PlayerData.addGems(player: Player, amount: number): number
	local d = getOrCreate(player)
	d.gems += amount
	return d.gems
end

function PlayerData.spendGems(player: Player, amount: number): boolean
	local d = getOrCreate(player)
	if d.gems < amount then return false end
	d.gems -= amount
	return true
end

-- XP
function PlayerData.getXP(player: Player): number
	return getOrCreate(player).xp
end

function PlayerData.addXP(player: Player, amount: number): number
	local d = getOrCreate(player)
	-- Apply XP boost upgrade
	local xpBoostLevel = d.upgrades["xp_boost"] or 0
	local multiplier = 1 + (xpBoostLevel * 0.15)
	d.xp += math.floor(amount * multiplier)
	return d.xp
end

function PlayerData.spendXP(player: Player, amount: number): boolean
	local d = getOrCreate(player)
	if d.xp < amount then return false end
	d.xp -= amount
	return true
end

-- Crates
function PlayerData.addCrate(player: Player, crateId: string, count: number?): number
	local d = getOrCreate(player)
	d.crates[crateId] = (d.crates[crateId] or 0) + (count or 1)
	return d.crates[crateId]
end

function PlayerData.hasCrate(player: Player, crateId: string): boolean
	local d = getOrCreate(player)
	return (d.crates[crateId] or 0) > 0
end

function PlayerData.consumeCrate(player: Player, crateId: string): boolean
	local d = getOrCreate(player)
	local count = d.crates[crateId] or 0
	if count < 1 then return false end
	d.crates[crateId] = count - 1
	return true
end

function PlayerData.getCrateCount(player: Player, crateId: string): number
	local d = getOrCreate(player)
	return d.crates[crateId] or 0
end

-- Weapons
function PlayerData.addWeapon(player: Player, weaponId: string): WeaponInstance
	local d = getOrCreate(player)
	local inst = { weaponId = weaponId, uid = newUid() }
	table.insert(d.weapons, inst)
	return inst
end

function PlayerData.removeWeaponByUid(player: Player, uid: string)
	local d = getOrCreate(player)
	for i, w in d.weapons do
		if w.uid == uid then
			table.remove(d.weapons, i)
			return w
		end
	end
	return nil
end

function PlayerData.getWeaponByUid(player: Player, uid: string)
	local d = getOrCreate(player)
	for _, w in d.weapons do
		if w.uid == uid then return w end
	end
	return nil
end

function PlayerData.getWeaponCount(player: Player): number
	local d = getOrCreate(player)
	return #d.weapons
end

function PlayerData.getMaxInventorySlots(player: Player): number
	return Config.BaseInventorySlots
end

function PlayerData.hasInventorySpace(player: Player): boolean
	return PlayerData.getWeaponCount(player) < PlayerData.getMaxInventorySlots(player)
end

-- Upgrades
function PlayerData.getUpgradeLevel(player: Player, upgradeId: string): number
	local d = getOrCreate(player)
	return d.upgrades[upgradeId] or 0
end

function PlayerData.addUpgrade(player: Player, upgradeId: string, count: number?): number
	local d = getOrCreate(player)
	d.upgrades[upgradeId] = (d.upgrades[upgradeId] or 0) + (count or 1)
	return d.upgrades[upgradeId]
end

function PlayerData.canBuyUpgrade(player: Player, upgradeId: string): boolean
	local upgradeDef = Config.Upgrades[upgradeId]
	if not upgradeDef then return false end
	
	local currentLevel = PlayerData.getUpgradeLevel(player, upgradeId)
	
	if upgradeDef.maxLevel and currentLevel >= upgradeDef.maxLevel then
		return false
	end
	
	return PlayerData.getXP(player) >= upgradeDef.xpCost
end

-- Luck boost calculation
function PlayerData.getLuckMultiplier(player: Player): number
	local d = getOrCreate(player)
	local luckLevel = d.upgrades["luck_boost"] or 0
	return 1 + (luckLevel * 0.05)
end

-- Key magnet calculation
function PlayerData.getKeyMagnetMultiplier(player: Player): number
	local d = getOrCreate(player)
	local magnetLevel = d.upgrades["key_magnet"] or 0
	return 1 + (magnetLevel * 0.10)
end

-- Double roll token
function PlayerData.hasDoubleRoll(player: Player): boolean
	return PlayerData.getUpgradeLevel(player, "double_roll") > 0
end

function PlayerData.consumeDoubleRoll(player: Player): boolean
	local d = getOrCreate(player)
	local count = d.upgrades["double_roll"] or 0
	if count < 1 then return false end
	d.upgrades["double_roll"] = count - 1
	return true
end

-- Create leaderstats folder
function PlayerData.createLeaderstats(player: Player)
	local d = getOrCreate(player)
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local keysStat = Instance.new("IntValue")
	keysStat.Name = "Keys"
	keysStat.Value = d.keys
	keysStat.Parent = leaderstats
	
	local xpStat = Instance.new("IntValue")
	xpStat.Name = "XP"
	xpStat.Value = d.xp
	xpStat.Parent = leaderstats
	
	return leaderstats
end

-- Update leaderstats
function PlayerData.updateLeaderstats(player: Player)
	local d = getOrCreate(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local keysStat = leaderstats:FindFirstChild("Keys")
	if keysStat then keysStat.Value = d.keys end
	
	local xpStat = leaderstats:FindFirstChild("XP")
	if xpStat then xpStat.Value = d.xp end
end

-- Health
function PlayerData.getHealth(player: Player): number
	return getOrCreate(player).health
end

function PlayerData.getMaxHealth(player: Player): number
	return getOrCreate(player).maxHealth
end

function PlayerData.setHealth(player: Player, amount: number): number
	local d = getOrCreate(player)
	d.health = math.clamp(amount, 0, d.maxHealth)
	return d.health
end

function PlayerData.damage(player: Player, amount: number): number
	local d = getOrCreate(player)
	d.health = math.max(0, d.health - amount)
	return d.health
end

function PlayerData.heal(player: Player, amount: number): number
	local d = getOrCreate(player)
	d.health = math.min(d.maxHealth, d.health + amount)
	return d.health
end

function PlayerData.resetHealth(player: Player): number
	local d = getOrCreate(player)
	d.health = d.maxHealth
	return d.health
end

function PlayerData.setMaxHealth(player: Player, amount: number): number
	local d = getOrCreate(player)
	d.maxHealth = math.max(1, amount)
	if d.health > d.maxHealth then
		d.health = d.maxHealth
	end
	return d.maxHealth
end

function PlayerData.increaseMaxHealth(player: Player, amount: number): number
	local d = getOrCreate(player)
	d.maxHealth = d.maxHealth + amount
	return d.maxHealth
end

function PlayerData.isDead(player: Player): boolean
	return getOrCreate(player).health <= 0
end

-- Arenas
function PlayerData.hasCompletedArena(player: Player, arenaNumber: number): boolean
	local d = getOrCreate(player)
	return d.arenasCompleted[arenaNumber] == true
end

function PlayerData.completeArena(player: Player, arenaNumber: number)
	local d = getOrCreate(player)
	d.arenasCompleted[arenaNumber] = true
end

function PlayerData.getArenasCompleted(player: Player): { [number]: boolean }
	local d = getOrCreate(player)
	return d.arenasCompleted
end

-- ========== HOME BASE FUNCTIONS ==========

-- Get assigned base plot (nil if none)
function PlayerData.getAssignedBasePlot(player: Player): number?
	return getOrCreate(player).assignedBasePlot
end

-- Assign a base plot to a player
function PlayerData.assignBasePlot(player: Player, plotNumber: number)
	local d = getOrCreate(player)
	d.assignedBasePlot = plotNumber
end

-- Get displayed weapons on base
function PlayerData.getDisplayedWeapons(player: Player): { DisplayedWeapon }
	return getOrCreate(player).displayedWeapons
end

-- Display a weapon on a pedestal (removes from inventory)
function PlayerData.displayWeaponOnPedestal(player: Player, weaponUid: string, pedestalIndex: number): boolean
	local d = getOrCreate(player)
	
	-- Check if pedestal is already occupied
	for _, dw in d.displayedWeapons do
		if dw.pedestalIndex == pedestalIndex then
			return false
		end
	end
	
	-- Find and remove weapon from inventory
	local weaponData = nil
	for i, w in d.weapons do
		if w.uid == weaponUid then
			weaponData = table.remove(d.weapons, i)
			break
		end
	end
	
	if not weaponData then
		return false
	end
	
	-- Add to displayed weapons
	table.insert(d.displayedWeapons, {
		pedestalIndex = pedestalIndex,
		weaponUid = weaponUid,
		weaponId = weaponData.weaponId,
	})
	
	return true
end

-- Retrieve a weapon from a pedestal (adds back to inventory)
function PlayerData.retrieveWeaponFromPedestal(player: Player, pedestalIndex: number): boolean
	local d = getOrCreate(player)
	
	for i, dw in d.displayedWeapons do
		if dw.pedestalIndex == pedestalIndex then
			local removed = table.remove(d.displayedWeapons, i)
			
			table.insert(d.weapons, {
				weaponId = removed.weaponId,
				uid = removed.weaponUid,
			})
			
			return true
		end
	end
	
	return false
end

-- Get weapon displayed on a specific pedestal
function PlayerData.getWeaponOnPedestal(player: Player, pedestalIndex: number): DisplayedWeapon?
	local d = getOrCreate(player)
	for _, dw in d.displayedWeapons do
		if dw.pedestalIndex == pedestalIndex then
			return dw
		end
	end
	return nil
end

-- Calculate total passive income per second from all displayed weapons
function PlayerData.calculateBaseIncome(player: Player): number
	local d = getOrCreate(player)
	local totalIncome = 0
	
	for _, dw in d.displayedWeapons do
		local weaponDef = Config.Weapons[dw.weaponId]
		if weaponDef then
			local rarity = weaponDef.rarity
			local incomeRate = Config.BaseIncomePerRarity[rarity] or 0
			totalIncome += incomeRate
		end
	end
	
	return totalIncome
end

-- Save on player leave
Players.PlayerRemoving:Connect(function(player: Player)
	PlayerData.save(player)
	dataByPlayer[player] = nil
	dataLoadedByPlayer[player] = nil
end)

-- Save all on server shutdown
game:BindToClose(function()
	for player, _ in dataByPlayer do
		PlayerData.save(player)
	end
end)

return PlayerData
