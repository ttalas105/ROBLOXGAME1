--[[
	Client Entry Point
	Initializes all shop UIs and connects to server events.
]]

print("[Client] Starting shop client...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
	warn("[Client] Shared folder not found!")
	return
end

-- Wait for remotes folder from server
local remotesFolder = ReplicatedStorage:WaitForChild("ShopRemotes", 30)
if not remotesFolder then
	warn("[Client] ShopRemotes folder not found - is server running?")
	return
end

print("[Client] Server remotes found, loading UI modules...")

-- Load client modules
-- In Rojo, init.client.luau IS the folder, so child modules are under `script`
local function safeRequire(name: string)
	local mod = script:FindFirstChild(name)
	if not mod or not mod:IsA("ModuleScript") then
		warn("[Client] Module not found:", name)
		return nil
	end
	
	local ok, result = pcall(require, mod)
	if not ok then
		warn("[Client] Failed to load", name, ":", result)
		return nil
	end
	
	return result
end

local ShopRemotes = safeRequire("ShopRemotes")
if not ShopRemotes then return end

local UIHelper = safeRequire("UIHelper")
if not UIHelper then return end

local CrateShop = safeRequire("CrateShop")
if not CrateShop then return end

local SellShop = safeRequire("SellShop")
if not SellShop then return end

local UpgradesShop = safeRequire("UpgradesShop")
if not UpgradesShop then return end

local CrateOpener = safeRequire("CrateOpener")
if not CrateOpener then return end

local InventoryBar = safeRequire("InventoryBar")
if not InventoryBar then return end

local HealthBar = safeRequire("HealthBar")
if not HealthBar then return end

print("[Client] All modules loaded, building UIs...")

-- Build all shop UIs (hidden by default)
CrateShop.build(playerGui)
SellShop.build(playerGui)
UpgradesShop.build(playerGui)
CrateOpener.build(playerGui)
InventoryBar.build(playerGui)
HealthBar.build(playerGui)

-- Connect inventory bar to crate opener (to hide pending weapons)
InventoryBar.setCrateOpener(CrateOpener)

-- Inventory bar click callback disabled - use Sell Shop to sell weapons
-- InventoryBar.setClickCallback(function(itemType: string, itemId: string, uid: string?)
-- 	-- Disabled: selling now only through Sell Shop
-- end)

-- Default state for initial refresh
local DEFAULT_STATE = {
	keys = 0,
	xp = 0,
	weapons = {},
	crates = {},
	upgrades = {},
	maxSlots = 50,
}

local currentState = DEFAULT_STATE

-- Refresh all shops with current state
local function refreshAllShops(state: any)
	currentState = state
	CrateShop.refresh(state)
	SellShop.refresh(state)
	UpgradesShop.refresh(state)
	InventoryBar.refresh(state)
end

-- Refresh inventory when a weapon is revealed from crate opening
CrateOpener.setOnWeaponRevealed(function()
	InventoryBar.refresh(currentState)
end)

-- Close all shops
local function closeAllShops()
	CrateShop.hide()
	SellShop.hide()
	UpgradesShop.hide()
end

-- Connect to shop opening remotes (triggered by ProximityPrompt on squares)
ShopRemotes.openCrateShop().OnClientEvent:Connect(function()
	closeAllShops()
	CrateShop.show()
	print("[Client] Opened Crate Shop")
end)

ShopRemotes.openSellShop().OnClientEvent:Connect(function()
	closeAllShops()
	SellShop.show()
	print("[Client] Opened Sell Shop")
end)

ShopRemotes.openUpgradesShop().OnClientEvent:Connect(function()
	closeAllShops()
	UpgradesShop.show()
	print("[Client] Opened Upgrades Shop")
end)

-- Listen for player data updates from server
ShopRemotes.playerDataUpdated().OnClientEvent:Connect(function(newState)
	print("[Client] Player data updated")
	refreshAllShops(newState)
	-- Update health bar if health data is included
	if newState.health and newState.maxHealth then
		HealthBar.update(newState.health, newState.maxHealth)
	end
end)

-- Listen for health updates specifically (for combat damage/healing)
ShopRemotes.healthUpdated().OnClientEvent:Connect(function(health: number, maxHealth: number)
	HealthBar.update(health, maxHealth)
end)

-- Fetch initial player data from server
task.spawn(function()
	local ok, state = pcall(function()
		return ShopRemotes.getPlayerData():InvokeServer()
	end)
	
	if ok and state then
		print("[Client] Got player data from server")
		refreshAllShops(state)
		-- Set initial health
		if state.health and state.maxHealth then
			HealthBar.setHealth(state.health, state.maxHealth)
		else
			HealthBar.setHealth(100, 100) -- Default
		end
	else
		warn("[Client] Could not fetch player data, using defaults")
		refreshAllShops(DEFAULT_STATE)
		HealthBar.setHealth(100, 100)
	end
end)

-- ESC key to close all shops
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Escape then
		if CrateShop.isVisible() or SellShop.isVisible() or UpgradesShop.isVisible() then
			closeAllShops()
		end
	end
end)

print("[Client] ✅ Shop client ready!")
print("[Client] Walk to a shop square and press E to open!")
