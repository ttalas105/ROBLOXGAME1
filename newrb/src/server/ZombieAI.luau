--[[
	ZombieAI: Spawns and controls zombie NPCs in Arena 1.
	- Zombies follow players at slow walking pace
	- Attack when close, dealing 5 damage
	- Uses asset ID 5310368287 for the zombie model
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local ZombieAI = {}

-- Config
local ZOMBIE_WALK_SPEED = 8 -- Slow walking pace
local ZOMBIE_ATTACK_RANGE = 5 -- Studs to trigger attack
local ZOMBIE_ATTACK_DAMAGE = 5
local ZOMBIE_ATTACK_COOLDOWN = 1.5 -- Seconds between attacks
local ZOMBIE_DETECTION_RANGE = 100 -- How far zombie can detect players
local ZOMBIE_HEALTH = 50
local SPAWN_COUNT = 5 -- Number of zombies to spawn

-- Track active zombies
local activeZombies: { [Model]: { 
	humanoid: Humanoid, 
	lastAttack: number,
	target: Player?,
} } = {}

local arenaOrigin = Vector3.new(2000, 0, 0) -- From Arena1Builder
local isRunning = false

-- Load zombie model from ReplicatedStorage
local function loadZombieModel(): Model?
	local template = ReplicatedStorage:FindFirstChild("ZombieTemplate")
	if template and template:IsA("Model") then
		return template:Clone()
	else
		warn("[ZombieAI] ZombieTemplate not found in ReplicatedStorage, using fallback")
		return nil
	end
end

-- Create a simple zombie if asset fails to load
local function createFallbackZombie(): Model
	local zombie = Instance.new("Model")
	zombie.Name = "Zombie"
	
	-- Use R6 rig style
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(80, 120, 80) -- Green zombie color
	torso.Material = Enum.Material.Plastic
	torso.Anchored = false
	torso.CanCollide = true
	torso.Parent = zombie
	
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Color = Color3.fromRGB(80, 120, 80)
	head.Material = Enum.Material.Plastic
	head.Parent = zombie
	
	local headWeld = Instance.new("Weld")
	headWeld.Part0 = torso
	headWeld.Part1 = head
	headWeld.C0 = CFrame.new(0, 1.75, 0)
	headWeld.Parent = head
	
	-- Arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Color = Color3.fromRGB(80, 120, 80)
	leftArm.Parent = zombie
	local laWeld = Instance.new("Weld")
	laWeld.Part0 = torso
	laWeld.Part1 = leftArm
	laWeld.C0 = CFrame.new(-1.5, 0, 0)
	laWeld.Parent = leftArm
	
	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Color = Color3.fromRGB(80, 120, 80)
	rightArm.Parent = zombie
	local raWeld = Instance.new("Weld")
	raWeld.Part0 = torso
	raWeld.Part1 = rightArm
	raWeld.C0 = CFrame.new(1.5, 0, 0)
	raWeld.Parent = rightArm
	
	-- Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Color = Color3.fromRGB(60, 90, 60)
	leftLeg.Parent = zombie
	local llWeld = Instance.new("Weld")
	llWeld.Part0 = torso
	llWeld.Part1 = leftLeg
	llWeld.C0 = CFrame.new(-0.5, -2, 0)
	llWeld.Parent = leftLeg
	
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Color = Color3.fromRGB(60, 90, 60)
	rightLeg.Parent = zombie
	local rlWeld = Instance.new("Weld")
	rlWeld.Part0 = torso
	rlWeld.Part1 = rightLeg
	rlWeld.C0 = CFrame.new(0.5, -2, 0)
	rlWeld.Parent = rightLeg
	
	-- HumanoidRootPart (required for MoveTo)
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Parent = zombie
	local hrpWeld = Instance.new("Weld")
	hrpWeld.Part0 = torso
	hrpWeld.Part1 = hrp
	hrpWeld.C0 = CFrame.new(0, 0, 0)
	hrpWeld.Parent = hrp
	
	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = ZOMBIE_HEALTH
	humanoid.Health = ZOMBIE_HEALTH
	humanoid.WalkSpeed = ZOMBIE_WALK_SPEED
	humanoid.Parent = zombie
	
	-- Health bar above head
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthDisplay"
	billboard.Size = UDim2.new(0, 80, 0, 20)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head
	
	local healthBar = Instance.new("Frame")
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = billboard
	
	local healthFill = Instance.new("Frame")
	healthFill.Name = "Fill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBar
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 15)
	nameLabel.Position = UDim2.new(0, 0, -1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Zombie"
	nameLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard
	
	zombie.PrimaryPart = hrp
	
	-- Update health bar when damaged
	humanoid.HealthChanged:Connect(function(health)
		if healthFill then
			healthFill.Size = UDim2.new(health / humanoid.MaxHealth, 0, 1, 0)
		end
	end)
	
	return zombie
end

-- Spawn a zombie at a position
local function spawnZombie(position: Vector3): Model?
	local zombieTemplate = loadZombieModel()
	local zombie: Model
	
	if zombieTemplate then
		zombie = zombieTemplate:Clone()
		zombieTemplate:Destroy()
	else
		zombie = createFallbackZombie()
	end
	
	zombie.Name = "Zombie_" .. tostring(math.random(1000, 9999))
	
	-- Ensure humanoid exists
	local humanoid = zombie:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = zombie
	end
	
	humanoid.MaxHealth = ZOMBIE_HEALTH
	humanoid.Health = ZOMBIE_HEALTH
	humanoid.WalkSpeed = ZOMBIE_WALK_SPEED
	
	-- Find or create root part
	local root = zombie:FindFirstChild("HumanoidRootPart") 
		or zombie:FindFirstChild("Torso")
		or zombie:FindFirstChild("UpperTorso")
	
	if not root then
		root = zombie:FindFirstChildWhichIsA("BasePart")
	end
	
	if root then
		zombie:SetPrimaryPartCFrame(CFrame.new(position + Vector3.new(0, 5, 0)))
	end
	
	-- Parent to arena
	local arena = workspace:FindFirstChild("Arena1")
	if arena then
		zombie.Parent = arena
	else
		zombie.Parent = workspace
	end
	
	-- Track zombie
	activeZombies[zombie] = {
		humanoid = humanoid,
		lastAttack = 0,
		target = nil,
	}
	
	-- Handle zombie death
	humanoid.Died:Connect(function()
		task.delay(3, function()
			activeZombies[zombie] = nil
			zombie:Destroy()
		end)
	end)
	
	print("[ZombieAI] Spawned zombie at", position)
	return zombie
end

-- Find nearest player in arena
local function findNearestPlayer(zombiePosition: Vector3): Player?
	local nearestPlayer: Player? = nil
	local nearestDistance = ZOMBIE_DETECTION_RANGE
	
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and humanoid.Health > 0 and root then
				-- Check if player is in arena area
				local distance = (root.Position - zombiePosition).Magnitude
				local distanceFromArena = (root.Position - arenaOrigin).Magnitude
				
				if distanceFromArena < 250 and distance < nearestDistance then
					nearestDistance = distance
					nearestPlayer = player
				end
			end
		end
	end
	
	return nearestPlayer
end

-- Move zombie toward target
local function moveZombieToward(zombie: Model, targetPosition: Vector3)
	local data = activeZombies[zombie]
	if not data then return end
	
	local humanoid = data.humanoid
	if not humanoid or humanoid.Health <= 0 then return end
	
	humanoid:MoveTo(targetPosition)
end

-- Attack player (deal damage)
local function attackPlayer(zombie: Model, player: Player)
	local data = activeZombies[zombie]
	if not data then return end
	
	local now = tick()
	if now - data.lastAttack < ZOMBIE_ATTACK_COOLDOWN then
		return -- Still on cooldown
	end
	
	data.lastAttack = now
	
	-- Deal damage to player
	local newHealth = PlayerData.damage(player, ZOMBIE_ATTACK_DAMAGE)
	
	-- Notify client of health change
	local remotesFolder = ReplicatedStorage:FindFirstChild("ShopRemotes")
	local healthEvent = remotesFolder and remotesFolder:FindFirstChild("HealthUpdated")
	if healthEvent then
		healthEvent:FireClient(player, newHealth, PlayerData.getMaxHealth(player))
	end
	
	print("[ZombieAI] Zombie attacked", player.Name, "for", ZOMBIE_ATTACK_DAMAGE, "damage. Health:", newHealth)
	
	-- Check if player died
	if newHealth <= 0 then
		-- Respawn player back to hub
		task.delay(2, function()
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				-- Teleport to hub
				character.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
				
				-- Reset our tracked health
				PlayerData.resetHealth(player)
				local newHp = PlayerData.getHealth(player)
				local maxHp = PlayerData.getMaxHealth(player)
				
				-- Also reset the character's Humanoid health
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = humanoid.MaxHealth
				end
				
				-- Send health reset to client UI
				local remotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
				local hpEvent = remotes and remotes:FindFirstChild("HealthUpdated")
				if hpEvent then
					hpEvent:FireClient(player, newHp, maxHp)
					print("[ZombieAI] Reset health for", player.Name, "to", newHp)
				end
			end
		end)
	end
end

-- Main AI loop
local function updateZombies()
	for zombie, data in pairs(activeZombies) do
		if not zombie.Parent then
			activeZombies[zombie] = nil
			continue
		end
		
		local humanoid = data.humanoid
		if not humanoid or humanoid.Health <= 0 then
			continue
		end
		
		local root = zombie:FindFirstChild("HumanoidRootPart") 
			or zombie:FindFirstChild("Torso")
			or zombie:FindFirstChild("UpperTorso")
			or zombie.PrimaryPart
		
		if not root then continue end
		
		local zombiePos = root.Position
		
		-- Find target
		local target = findNearestPlayer(zombiePos)
		data.target = target
		
		if target then
			local character = target.Character
			if character then
				local playerRoot = character:FindFirstChild("HumanoidRootPart")
				if playerRoot then
					local distance = (playerRoot.Position - zombiePos).Magnitude
					
					if distance <= ZOMBIE_ATTACK_RANGE then
						-- Attack!
						attackPlayer(zombie, target)
					else
						-- Move toward player
						moveZombieToward(zombie, playerRoot.Position)
					end
				end
			end
		end
	end
end

-- Spawn zombies in arena
function ZombieAI.spawnZombiesInArena(count: number?)
	local spawnCount = count or SPAWN_COUNT
	
	-- Spawn positions around the arena
	local spawnPositions = {
		arenaOrigin + Vector3.new(50, 0, 50),
		arenaOrigin + Vector3.new(-50, 0, 50),
		arenaOrigin + Vector3.new(50, 0, -50),
		arenaOrigin + Vector3.new(-50, 0, -50),
		arenaOrigin + Vector3.new(100, 0, 0),
		arenaOrigin + Vector3.new(-100, 0, 0),
		arenaOrigin + Vector3.new(0, 0, 100),
		arenaOrigin + Vector3.new(0, 0, -100),
		arenaOrigin + Vector3.new(80, 0, 80),
		arenaOrigin + Vector3.new(-80, 0, -80),
	}
	
	for i = 1, spawnCount do
		local pos = spawnPositions[((i - 1) % #spawnPositions) + 1]
		-- Add some randomness
		pos = pos + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
		spawnZombie(pos)
	end
	
	print("[ZombieAI] Spawned", spawnCount, "zombies in Arena 1")
end

-- Clear all zombies
function ZombieAI.clearZombies()
	for zombie, _ in pairs(activeZombies) do
		if zombie and zombie.Parent then
			zombie:Destroy()
		end
	end
	activeZombies = {}
	print("[ZombieAI] Cleared all zombies")
end

-- Start AI loop
function ZombieAI.start()
	if isRunning then return end
	isRunning = true
	
	RunService.Heartbeat:Connect(function()
		if isRunning then
			updateZombies()
		end
	end)
	
	print("[ZombieAI] Started")
end

-- Stop AI loop
function ZombieAI.stop()
	isRunning = false
	print("[ZombieAI] Stopped")
end

-- Initialize (just starts the AI loop, doesn't spawn zombies)
function ZombieAI.init()
	ZombieAI.start()
	print("[ZombieAI] Initialized - zombies will spawn when players enter arena")
end

-- Called when a player enters Arena 1
function ZombieAI.onPlayerEnterArena(player: Player)
	-- Only spawn if no zombies exist yet
	local zombieCount = 0
	for _ in pairs(activeZombies) do
		zombieCount = zombieCount + 1
	end
	
	if zombieCount == 0 then
		ZombieAI.spawnZombiesInArena(SPAWN_COUNT)
	end
	
	print("[ZombieAI]", player.Name, "entered arena, zombie count:", zombieCount)
end

-- Called when a player leaves Arena 1
function ZombieAI.onPlayerLeaveArena(player: Player)
	-- Check if any players are still in arena
	local playersInArena = 0
	local arenaOriginCheck = arenaOrigin
	
	for _, p in Players:GetPlayers() do
		if p ~= player then
			local character = p.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root then
					local dist = (root.Position - arenaOriginCheck).Magnitude
					if dist < 250 then
						playersInArena = playersInArena + 1
					end
				end
			end
		end
	end
	
	-- If no players left in arena, clear zombies
	if playersInArena == 0 then
		ZombieAI.clearZombies()
		print("[ZombieAI] No players in arena, cleared zombies")
	end
end

return ZombieAI
