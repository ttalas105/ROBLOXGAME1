--[[
	Stores and updates player data: keys, xp, weapons, crates, upgrades.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

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
local nextUid = 0

local function newUid(): string
	nextUid += 1
	return "w_" .. tostring(nextUid) .. "_" .. tostring(os.time())
end

local BASE_HEALTH = 100

-- Starting weapon for debugging
local STARTING_WEAPON_ID = "wooden_sword"

local function getOrCreate(player: Player): PlayerDataState
	if not dataByPlayer[player] then
		-- DEBUG: Add ALL weapons to inventory for testing
		local allWeapons = {}
		for weaponId, _ in Config.Weapons do
			table.insert(allWeapons, { weaponId = weaponId, uid = newUid() })
		end
		
		dataByPlayer[player] = {
			keys = Config.StartingKeys,
			gems = Config.StartingGems,
			xp = Config.StartingXP,
			weapons = allWeapons, -- DEBUG: All weapons for testing
			crates = {},
			upgrades = {},
			arenasCompleted = {},
			health = BASE_HEALTH,
			maxHealth = BASE_HEALTH,
			-- Home Base
			assignedBasePlot = nil,
			displayedWeapons = {},
		}
	end
	return dataByPlayer[player]
end

function PlayerData.get(player: Player): PlayerDataState
	return getOrCreate(player)
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
	-- Fixed at 10 slots, no upgrades
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
	
	-- Check if at max level (nil means no max)
	if upgradeDef.maxLevel and currentLevel >= upgradeDef.maxLevel then
		return false
	end
	
	-- Check if enough XP
	return PlayerData.getXP(player) >= upgradeDef.xpCost
end

-- Luck boost calculation (for crate opening)
function PlayerData.getLuckMultiplier(player: Player): number
	local d = getOrCreate(player)
	local luckLevel = d.upgrades["luck_boost"] or 0
	return 1 + (luckLevel * 0.05) -- 5% per level
end

-- Key magnet calculation (for selling)
function PlayerData.getKeyMagnetMultiplier(player: Player): number
	local d = getOrCreate(player)
	local magnetLevel = d.upgrades["key_magnet"] or 0
	return 1 + (magnetLevel * 0.10) -- 10% per level
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

-- Create leaderstats folder for a player
function PlayerData.createLeaderstats(player: Player)
	local d = getOrCreate(player)
	
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Keys stat
	local keysStat = Instance.new("IntValue")
	keysStat.Name = "Keys"
	keysStat.Value = d.keys
	keysStat.Parent = leaderstats
	
	-- XP stat
	local xpStat = Instance.new("IntValue")
	xpStat.Name = "XP"
	xpStat.Value = d.xp
	xpStat.Parent = leaderstats
	
	return leaderstats
end

-- Update leaderstats when data changes
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
	-- If current health exceeds new max, clamp it
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
			return false -- Pedestal already has a weapon
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
		return false -- Weapon not found in inventory
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
	
	-- Find displayed weapon on this pedestal
	for i, dw in d.displayedWeapons do
		if dw.pedestalIndex == pedestalIndex then
			-- Remove from displayed
			local removed = table.remove(d.displayedWeapons, i)
			
			-- Add back to inventory
			table.insert(d.weapons, {
				weaponId = removed.weaponId,
				uid = removed.weaponUid,
			})
			
			return true
		end
	end
	
	return false -- No weapon on this pedestal
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

-- Clean up when player leaves
game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	dataByPlayer[player] = nil
end)

return PlayerData
