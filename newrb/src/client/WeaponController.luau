--[[
	WeaponController: Client-side weapon handling.
	- Click to attack (with animation)
	- Number keys 1-9 to equip weapons from inventory
	- Visual hit effects
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local ShopRemotes = require(script.Parent:WaitForChild("ShopRemotes"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local WeaponController = {}

local equippedWeapon: { weaponId: string?, uid: string?, damage: number } = {
	weaponId = nil,
	uid = nil,
	damage = 0,
}

local isAttacking = false
local ATTACK_COOLDOWN = 0.5
local lastAttackTime = 0

-- Current inventory reference (set by init)
local currentInventory: { { weaponId: string, uid: string } } = {}

-- Attack animation ID (Roblox catalog swing animation)
local ATTACK_ANIMATION_ID = "rbxassetid://522635514" -- Sword swing animation
local attackAnimTrack: AnimationTrack? = nil

-- Load attack animation
local function loadAttackAnimation()
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	
	if attackAnimTrack then return attackAnimTrack end
	
	local anim = Instance.new("Animation")
	anim.AnimationId = ATTACK_ANIMATION_ID
	attackAnimTrack = humanoid:LoadAnimation(anim)
	attackAnimTrack.Priority = Enum.AnimationPriority.Action
	return attackAnimTrack
end

-- Clear animation on respawn
player.CharacterAdded:Connect(function()
	attackAnimTrack = nil
end)

-- Perform attack (server applies damage)
local function performAttack()
	if not equippedWeapon.weaponId then
		return -- No weapon equipped
	end
	
	local now = tick()
	if now - lastAttackTime < ATTACK_COOLDOWN then
		return -- Cooldown
	end
	
	if isAttacking then return end
	isAttacking = true
	lastAttackTime = now
	
	-- Play attack animation
	local track = loadAttackAnimation()
	if track then
		track:Play()
	end
	
	-- Get target position (where mouse is pointing)
	local mouse = player:GetMouse()
	local targetPosition = mouse.Hit and mouse.Hit.Position or nil
	
	-- Send attack to server
	ShopRemotes.attack():FireServer(targetPosition)
	
	-- Reset attacking state after animation
	task.delay(0.3, function()
		isAttacking = false
	end)
end

-- Equip weapon by inventory slot (1-9)
local function equipBySlot(slot: number)
	if slot < 1 or slot > #currentInventory then
		return
	end
	
	local weapon = currentInventory[slot]
	if weapon then
		ShopRemotes.equipWeapon():FireServer(weapon.uid)
	end
end

-- Equip weapon by UID (called from inventory UI)
function WeaponController.equipWeapon(uid: string)
	ShopRemotes.equipWeapon():FireServer(uid)
end

-- Unequip current weapon
function WeaponController.unequipWeapon()
	ShopRemotes.unequipWeapon():FireServer()
end

-- Get currently equipped weapon
function WeaponController.getEquipped()
	return equippedWeapon
end

-- Update inventory reference
function WeaponController.updateInventory(weapons: { { weaponId: string, uid: string } })
	currentInventory = weapons or {}
end

-- Create hit effect at position
local function createHitEffect(position: Vector3, damage: number)
	-- Create a quick flash/particle effect
	local part = Instance.new("Part")
	part.Name = "HitEffect"
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.5
	part.Color = Color3.fromRGB(255, 100, 100)
	part.Material = Enum.Material.Neon
	part.Shape = Enum.PartType.Ball
	part.Parent = workspace
	
	-- Damage number
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part
	
	local damageLabel = Instance.new("TextLabel")
	damageLabel.Size = UDim2.new(1, 0, 1, 0)
	damageLabel.BackgroundTransparency = 1
	damageLabel.Text = tostring(damage)
	damageLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	damageLabel.TextStrokeTransparency = 0
	damageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	damageLabel.Font = Enum.Font.GothamBold
	damageLabel.TextSize = 24
	damageLabel.TextScaled = true
	damageLabel.Parent = billboard
	
	-- Animate and destroy
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(part, tweenInfo, { 
		Size = Vector3.new(2, 2, 2), 
		Transparency = 1 
	}):Play()
	TweenService:Create(billboard, tweenInfo, {
		StudsOffset = Vector3.new(0, 4, 0)
	}):Play()
	
	task.delay(0.5, function()
		part:Destroy()
	end)
end

-- Initialize
function WeaponController.init()
	-- Listen for weapon equipped confirmation
	ShopRemotes.weaponEquipped().OnClientEvent:Connect(function(data)
		if data.success then
			equippedWeapon.weaponId = data.weaponId
			equippedWeapon.uid = data.uid
			equippedWeapon.damage = data.damage or 0
			
			if data.weaponId then
				local weaponDef = Config.getWeapon(data.weaponId)
				local name = weaponDef and weaponDef.name or data.weaponId
				print("[WeaponController] Equipped:", name, "| Damage:", data.damage)
			else
				print("[WeaponController] Weapon unequipped")
			end
		end
	end)
	
	-- Listen for attack hit effects
	ShopRemotes.attackHit().OnClientEvent:Connect(function(data)
		if data.targetPosition then
			createHitEffect(data.targetPosition, data.damage or 0)
		end
	end)
	
	-- Input handling
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Click to attack
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			performAttack()
		end
		
		-- Number keys 1-9 to equip from inventory
		local keyNumber = nil
		if input.KeyCode == Enum.KeyCode.One then keyNumber = 1
		elseif input.KeyCode == Enum.KeyCode.Two then keyNumber = 2
		elseif input.KeyCode == Enum.KeyCode.Three then keyNumber = 3
		elseif input.KeyCode == Enum.KeyCode.Four then keyNumber = 4
		elseif input.KeyCode == Enum.KeyCode.Five then keyNumber = 5
		elseif input.KeyCode == Enum.KeyCode.Six then keyNumber = 6
		elseif input.KeyCode == Enum.KeyCode.Seven then keyNumber = 7
		elseif input.KeyCode == Enum.KeyCode.Eight then keyNumber = 8
		elseif input.KeyCode == Enum.KeyCode.Nine then keyNumber = 9
		end
		
		if keyNumber then
			equipBySlot(keyNumber)
		end
		
		-- X to unequip
		if input.KeyCode == Enum.KeyCode.X then
			WeaponController.unequipWeapon()
		end
	end)
	
	print("[WeaponController] Initialized")
	print("  - Click to attack")
	print("  - Press 1-9 to equip weapons from inventory")
	print("  - Press X to unequip")
end

return WeaponController
