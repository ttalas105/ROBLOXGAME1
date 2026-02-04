--[[
	WeaponService: Handles weapon equipping and combat on the server.
	- Tracks which weapon each player has equipped
	- Validates attacks and applies damage
	- Spawns weapon models on characters
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Remotes = require(script.Parent:WaitForChild("Remotes"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local WeaponService = {}

-- Track equipped weapon per player: { [Player]: { weaponId: string, uid: string, model: Model? } }
local equippedWeapons: { [Player]: { weaponId: string, uid: string, model: Model? } } = {}

-- Attack cooldown per player
local attackCooldowns: { [Player]: number } = {}
local ATTACK_COOLDOWN = 0.5 -- seconds between attacks
local ATTACK_RANGE = 8 -- studs

-- Get weapon models folder (created in ReplicatedStorage for client access)
local function getWeaponModelsFolder(): Folder?
	return ReplicatedStorage:FindFirstChild("WeaponModels")
end

-- Clone weapon model from WeaponModels folder
local function cloneWeaponModel(weaponId: string): Model?
	local folder = getWeaponModelsFolder()
	if not folder then
		warn("[WeaponService] WeaponModels folder not found in ReplicatedStorage")
		return nil
	end
	local template = folder:FindFirstChild(weaponId)
	if not template then
		warn("[WeaponService] Weapon model not found:", weaponId)
		return nil
	end
	return template:Clone()
end

-- Attach weapon model to character's right hand
local function attachWeaponToCharacter(player: Player, weaponModel: Model)
	local character = player.Character
	if not character then return end
	
	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not rightHand then
		warn("[WeaponService] RightHand not found on character")
		return
	end
	
	-- Set weapon's primary part and position
	local handle = weaponModel:FindFirstChild("Handle", true) or weaponModel.PrimaryPart
	if not handle then
		-- Use first BasePart as handle
		for _, part in weaponModel:GetDescendants() do
			if part:IsA("BasePart") then
				handle = part
				break
			end
		end
	end
	
	if not handle then
		warn("[WeaponService] No handle found in weapon model")
		return
	end
	
	-- Scale up the weapon (5x bigger - adjust as needed)
	local WEAPON_SCALE = 5
	for _, part in weaponModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.Size = part.Size * WEAPON_SCALE
		end
	end
	
	-- Weld weapon to hand
	weaponModel.Parent = character
	weaponModel.Name = "EquippedWeapon"
	
	-- Create weld - sword pointing up/forward from hand
	local weld = Instance.new("Weld")
	weld.Part0 = rightHand
	weld.Part1 = handle
	-- Position: hilt at hand level, rotated 180
	weld.C0 = CFrame.new(0, 1, -1.7) * CFrame.Angles(math.rad(-12), math.rad(270), math.rad(0))
	weld.Parent = handle
	
	-- Make all parts non-collidable
	for _, part in weaponModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
		end
	end
end

-- Remove equipped weapon from character
local function removeWeaponFromCharacter(player: Player)
	local character = player.Character
	if not character then return end
	
	local existingWeapon = character:FindFirstChild("EquippedWeapon")
	if existingWeapon then
		existingWeapon:Destroy()
	end
end

-- Equip a weapon for a player
function WeaponService.equipWeapon(player: Player, weaponUid: string): boolean
	-- Verify player owns this weapon
	local weaponInstance = PlayerData.getWeaponByUid(player, weaponUid)
	if not weaponInstance then
		warn("[WeaponService] Player doesn't own weapon:", weaponUid)
		return false
	end
	
	local weaponDef = Config.getWeapon(weaponInstance.weaponId)
	if not weaponDef then
		warn("[WeaponService] Invalid weapon ID:", weaponInstance.weaponId)
		return false
	end
	
	-- Unequip current weapon first
	WeaponService.unequipWeapon(player)
	
	-- Clone and attach weapon model
	local weaponModel = cloneWeaponModel(weaponInstance.weaponId)
	if weaponModel then
		attachWeaponToCharacter(player, weaponModel)
	end
	
	-- Track equipped weapon
	equippedWeapons[player] = {
		weaponId = weaponInstance.weaponId,
		uid = weaponUid,
		model = weaponModel,
	}
	
	-- Notify client
	Remotes.WeaponEquipped:FireClient(player, {
		success = true,
		weaponId = weaponInstance.weaponId,
		uid = weaponUid,
		damage = weaponDef.damage or 1,
	})
	
	print("[WeaponService]", player.Name, "equipped", weaponDef.name)
	return true
end

-- Unequip current weapon
function WeaponService.unequipWeapon(player: Player)
	local equipped = equippedWeapons[player]
	if not equipped then return end
	
	removeWeaponFromCharacter(player)
	equippedWeapons[player] = nil
	
	Remotes.WeaponEquipped:FireClient(player, {
		success = true,
		weaponId = nil,
		uid = nil,
		damage = 0,
	})
end

-- Get equipped weapon for a player
function WeaponService.getEquippedWeapon(player: Player): { weaponId: string, uid: string, model: Model? }?
	return equippedWeapons[player]
end

-- Process attack from player
function WeaponService.processAttack(player: Player, targetPosition: Vector3?)
	local equipped = equippedWeapons[player]
	if not equipped then
		return -- No weapon equipped
	end
	
	-- Check cooldown
	local now = tick()
	local lastAttack = attackCooldowns[player] or 0
	if now - lastAttack < ATTACK_COOLDOWN then
		return -- Still on cooldown
	end
	attackCooldowns[player] = now
	
	local character = player.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local weaponDef = Config.getWeapon(equipped.weaponId)
	local damage = (weaponDef and weaponDef.damage) or 1
	
	-- Find enemies in range (NPCs with Humanoid)
	local attackOrigin = humanoidRootPart.Position
	local hitSomething = false
	
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("Humanoid") and obj.Health > 0 then
			local objCharacter = obj.Parent
			if objCharacter and objCharacter ~= character then
				-- Check if it's an NPC (not a player)
				local objPlayer = Players:GetPlayerFromCharacter(objCharacter)
				if not objPlayer then -- It's an NPC
					local objRoot = objCharacter:FindFirstChild("HumanoidRootPart") 
						or objCharacter:FindFirstChild("Torso")
						or objCharacter:FindFirstChild("UpperTorso")
					
					if objRoot then
						local distance = (objRoot.Position - attackOrigin).Magnitude
						if distance <= ATTACK_RANGE then
							-- Deal damage
							obj:TakeDamage(damage)
							hitSomething = true
							
							-- Notify all clients of hit for effects
							Remotes.AttackHit:FireAllClients({
								attacker = player,
								targetPosition = objRoot.Position,
								damage = damage,
							})
							
							print("[WeaponService]", player.Name, "hit NPC for", damage, "damage")
						end
					end
				end
			end
		end
	end
	
	return hitSomething
end

-- Initialize remotes
function WeaponService.init()
	-- Equip weapon request
	Remotes.EquipWeapon.OnServerEvent:Connect(function(player: Player, weaponUid: string)
		WeaponService.equipWeapon(player, weaponUid)
	end)
	
	-- Unequip weapon request
	Remotes.UnequipWeapon.OnServerEvent:Connect(function(player: Player)
		WeaponService.unequipWeapon(player)
	end)
	
	-- Attack request
	Remotes.Attack.OnServerEvent:Connect(function(player: Player, targetPosition: Vector3?)
		WeaponService.processAttack(player, targetPosition)
	end)
	
	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		equippedWeapons[player] = nil
		attackCooldowns[player] = nil
	end)
	
	-- Re-equip weapon when character respawns
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5) -- Wait for character to fully load
			local equipped = equippedWeapons[player]
			if equipped then
				-- Re-attach weapon model
				local weaponModel = cloneWeaponModel(equipped.weaponId)
				if weaponModel then
					attachWeaponToCharacter(player, weaponModel)
					equipped.model = weaponModel
				end
			end
		end)
	end)
	
	-- Handle existing players
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			local equipped = equippedWeapons[player]
			if equipped then
				local weaponModel = cloneWeaponModel(equipped.weaponId)
				if weaponModel then
					attachWeaponToCharacter(player, weaponModel)
					equipped.model = weaponModel
				end
			end
		end)
	end
	
	print("[WeaponService] Initialized")
end

return WeaponService
