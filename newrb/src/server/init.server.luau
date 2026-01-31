--[[
	Server Entry Point
	Initializes all server-side shop systems.
]]

print("[Server] Starting shop systems...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to be available
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
	warn("[Server] Shared folder not found!")
	return
end

local Config = Shared:WaitForChild("Config", 5)
if not Config then
	warn("[Server] Config module not found!")
	return
end

-- Initialize server modules
-- In Rojo, init.server.luau IS the folder, so child modules are under `script`
local function safeRequire(name: string)
	local mod = script:FindFirstChild(name)
	if not mod or not mod:IsA("ModuleScript") then
		warn("[Server] Module not found:", name)
		return nil
	end
	
	local ok, result = pcall(require, mod)
	if not ok then
		warn("[Server] Failed to load", name, ":", result)
		return nil
	end
	
	return result
end

-- Start services in order
local Remotes = safeRequire("Remotes")
if not Remotes then return end

local PlayerData = safeRequire("PlayerData")
if not PlayerData then return end

local ShopService = safeRequire("ShopService")
if not ShopService then return end

local KingdomBuilder = safeRequire("KingdomBuilder")
if not KingdomBuilder then return end

-- Start the shop service (creates remotes and connects handlers)
ShopService.start()
print("[Server] ShopService started")

-- Build the Dark Fantasy Kingdom environment
KingdomBuilder.build(Remotes)
print("[Server] Dark Fantasy Kingdom built")

-- Setup players when they join
local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(player)
	print("[Server] Player joined:", player.Name)
	
	-- Create player data with starting keys/xp
	local data = PlayerData.get(player)
	
	-- Create leaderstats (shows Keys and XP on leaderboard)
	PlayerData.createLeaderstats(player)
	
	print("[Server]", player.Name, "has", data.keys, "keys and", data.xp, "XP")
end)

-- Handle players already in game (in case script loads late)
for _, player in Players:GetPlayers() do
	task.spawn(function()
		local data = PlayerData.get(player)
		if not player:FindFirstChild("leaderstats") then
			PlayerData.createLeaderstats(player)
		end
	end)
end

print("[Server] ✅ All systems ready!")
print("[Server] Walk to one of the 3 shop squares and press E to open!")
