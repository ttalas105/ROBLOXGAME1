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

local Arena1Builder = safeRequire("Arena1Builder")
if not Arena1Builder then return end

-- Start the shop service (creates remotes and connects handlers)
ShopService.start()
print("[Server] ShopService started")

-- Build the Dark Fantasy Kingdom environment
KingdomBuilder.build(Remotes)
print("[Server] Dark Fantasy Kingdom built")

-- Build Arena 1 (farmland) and wire teleports
Arena1Builder.build()
-- Force hub nighttime on start (daylight only when in Arena 1)
Arena1Builder.setDaylight(false)
local hubReturnPos = Vector3.new(0, 5, 0)

-- Arena 1 door: walk-through trigger teleports to farmland
local Players = game:GetService("Players")
local lastArena1Teleport: { [Player]: number } = {}
local TELEPORT_DEBOUNCE = 2
local arenaDoors = workspace:WaitForChild("ArenaDoors", 5)
if arenaDoors then
	local arena1Door = arenaDoors:FindFirstChild("Arena1_Door")
	if arena1Door then
		local trigger = arena1Door:FindFirstChild("Arena1Trigger")
		if trigger and trigger:IsA("BasePart") then
			trigger.Touched:Connect(function(otherPart: BasePart)
				local char = otherPart.Parent
				if not char or not char:IsA("Model") then return end
				local humanoid = char:FindFirstChild("Humanoid")
				if not humanoid then return end
				local player = Players:GetPlayerFromCharacter(char)
				if not player then return end
				local now = tick()
				if lastArena1Teleport[player] and (now - lastArena1Teleport[player]) < TELEPORT_DEBOUNCE then return end
				lastArena1Teleport[player] = now
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					-- Teleport to arena spawn platform (guaranteed solid)
					local arena1 = workspace:FindFirstChild("Arena1")
					local spawnPart = arena1 and arena1:FindFirstChild("SpawnPoint")
					local targetPos = if spawnPart and spawnPart:IsA("BasePart")
						then (spawnPart.Position + Vector3.new(0, spawnPart.Size.Y/2 + 2, 0))
						else Arena1Builder.getSpawnPosition()
					root.CFrame = CFrame.new(targetPos)
					Arena1Builder.setDaylight(true)
					print("[Server] Teleported", player.Name, "to Arena 1")
				end
			end)
		end
	end
end

-- Arena 1 return pad: teleport back to hub
local arena1 = workspace:WaitForChild("Arena1", 5)
if arena1 then
	local returnPad = arena1:FindFirstChild("ReturnToHubPad")
	if returnPad then
		local prompt = returnPad:FindFirstChild("ReturnPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Triggered:Connect(function(player: Player)
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					char.HumanoidRootPart.CFrame = CFrame.new(hubReturnPos)
					Arena1Builder.setDaylight(false)
					print("[Server] Teleported", player.Name, "back to hub")
				end
			end)
		end
	end
end

-- Setup players when they join
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
