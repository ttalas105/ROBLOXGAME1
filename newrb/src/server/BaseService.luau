--[[
	BaseService: Handles home base logic including:
	- Auto-claim when player enters unclaimed base
	- Weapon placement from equipped weapon
	- Passive income accumulation per pedestal
	- Key collection from pedestals
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))
local BaseBuilder = require(script.Parent:WaitForChild("BaseBuilder"))
local WeaponService = require(script.Parent:WaitForChild("WeaponService"))

local BaseService = {}

-- Track which plots are claimed by which player
local plotOwners: { [number]: number } = {} -- plotNumber -> userId

-- Track accumulated keys per pedestal (plotNumber -> pedestalIndex -> keys)
local accumulatedKeys: { [number]: { [number]: number } } = {}

-- Initialize the base system
function BaseService.init()
	-- Build the bases
	BaseBuilder.build()
	
	-- Set up remote handlers
	BaseService.setupRemotes()
	
	-- Connect auto-claim zones
	BaseService.connectAutoClaimZones()
	
	-- Connect pedestal prompts
	BaseService.connectPedestalPrompts()
	
	-- Start income accumulation loop
	BaseService.startIncomeLoop()
	
	print("[BaseService] Initialized")
end

-- Set up remote event handlers
function BaseService.setupRemotes()
	-- Get base data
	Remotes.GetBaseData.OnServerInvoke = function(player: Player)
		return BaseService.getBaseData(player)
	end
end

-- Connect auto-claim zones for all plots
function BaseService.connectAutoClaimZones()
	local basesFolder = Workspace:FindFirstChild("HomeBases")
	if not basesFolder then return end
	
	local plotsFolder = basesFolder:FindFirstChild("Plots")
	if not plotsFolder then return end
	
	for _, plot in plotsFolder:GetChildren() do
		local plotNumber = plot:GetAttribute("PlotNumber")
		local claimZone = plot:FindFirstChild("ClaimZone")
		if not claimZone then continue end
		
		claimZone.Touched:Connect(function(otherPart: BasePart)
			local character = otherPart.Parent
			if not character or not character:IsA("Model") then return end
			
			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoid then return end
			
			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end
			
			-- Check if plot is unclaimed
			if plotOwners[plotNumber] then return end
			
			-- Check if player already has a plot
			local currentPlot = PlayerData.getAssignedBasePlot(player)
			if currentPlot then return end
			
			-- Auto-claim the plot
			BaseService.claimPlot(player, plotNumber)
		end)
	end
end

-- Claim a plot for a player
function BaseService.claimPlot(player: Player, plotNumber: number): boolean
	-- Validate plot number
	if plotNumber < 1 or plotNumber > Config.TotalBasePlots then
		return false
	end
	
	-- Check if player already has a plot
	local currentPlot = PlayerData.getAssignedBasePlot(player)
	if currentPlot then
		return false
	end
	
	-- Check if plot is already claimed
	if plotOwners[plotNumber] then
		return false
	end
	
	-- Claim the plot
	plotOwners[plotNumber] = player.UserId
	PlayerData.assignBasePlot(player, plotNumber)
	
	-- Initialize accumulated keys for this plot
	accumulatedKeys[plotNumber] = {}
	for i = 1, Config.PedestalsPerBase do
		accumulatedKeys[plotNumber][i] = 0
	end
	
	-- Update the visual sign
	BaseBuilder.updateOwnerSign(plotNumber, player.DisplayName)
	
	-- Notify all clients
	Remotes.BaseClaimed:FireAllClients(plotNumber, player.UserId, player.DisplayName)
	
	-- Update player data
	Remotes.PlayerDataUpdated:FireClient(player, PlayerData.get(player))
	
	print("[BaseService]", player.Name, "auto-claimed plot", plotNumber)
	return true
end

-- Connect pedestal prompts (place weapon and collect)
function BaseService.connectPedestalPrompts()
	local basesFolder = Workspace:FindFirstChild("HomeBases")
	if not basesFolder then return end
	
	local plotsFolder = basesFolder:FindFirstChild("Plots")
	if not plotsFolder then return end
	
	for _, plot in plotsFolder:GetChildren() do
		local plotNumber = plot:GetAttribute("PlotNumber")
		local pedestals = plot:FindFirstChild("Pedestals")
		if not pedestals then continue end
		
		for _, pedestal in pedestals:GetChildren() do
			local pedestalIndex = pedestal:GetAttribute("PedestalIndex")
			local top = pedestal:FindFirstChild("Top")
			local collectionPad = pedestal:FindFirstChild("CollectionPad")
			
			-- Place weapon prompt
			if top then
				local placePrompt = top:FindFirstChild("PlacePrompt")
				if placePrompt then
					-- Only show prompt to base owner with equipped weapon
					placePrompt.PromptShown:Connect(function(player: Player)
						local playerPlot = PlayerData.getAssignedBasePlot(player)
						local hasEquipped = WeaponService.getEquippedWeapon(player) ~= nil
						local hasWeapon = pedestal:GetAttribute("HasWeapon")
						
						-- Hide if not owner, no weapon equipped, or slot already has weapon
						if playerPlot ~= plotNumber or not hasEquipped or hasWeapon then
							placePrompt.Enabled = false
							task.delay(0.1, function()
								if not pedestal:GetAttribute("HasWeapon") then
									placePrompt.Enabled = true
								end
							end)
						end
					end)
					
					placePrompt.Triggered:Connect(function(player: Player)
						BaseService.handlePlaceWeapon(player, plotNumber, pedestalIndex)
					end)
				end
			end
			
			-- Remove weapon prompt (on the pedestal top)
			if top then
				local removePrompt = top:FindFirstChild("RemovePrompt")
				if removePrompt then
					-- Only show prompt to base owner
					removePrompt.PromptShown:Connect(function(player: Player)
						local playerPlot = PlayerData.getAssignedBasePlot(player)
						
						if playerPlot ~= plotNumber then
							removePrompt.Enabled = false
							task.delay(0.1, function()
								if pedestal:GetAttribute("HasWeapon") then
									removePrompt.Enabled = true
								end
							end)
						end
					end)
					
					removePrompt.Triggered:Connect(function(player: Player)
						BaseService.handleRemoveWeapon(player, plotNumber, pedestalIndex)
					end)
				end
			end
			
			-- Collection pad - auto-collect on touch
			if collectionPad then
				-- Debounce for auto-collection
				local lastCollect: { [number]: number } = {}
				
				-- Auto-collect keys when stepping on the pad
				collectionPad.Touched:Connect(function(otherPart: BasePart)
					local character = otherPart.Parent
					if not character or not character:IsA("Model") then return end
					
					local humanoid = character:FindFirstChild("Humanoid")
					if not humanoid then return end
					
					local player = Players:GetPlayerFromCharacter(character)
					if not player then return end
					
					-- Debounce (1 second between collections)
					local now = tick()
					if lastCollect[player.UserId] and (now - lastCollect[player.UserId]) < 1 then
						return
					end
					lastCollect[player.UserId] = now
					
					-- Only collect for base owner
					local playerPlot = PlayerData.getAssignedBasePlot(player)
					if playerPlot ~= plotNumber then return end
					
					-- Auto-collect accumulated keys
					BaseService.handleCollectKeys(player, plotNumber, pedestalIndex)
				end)
			end
		end
	end
end

-- Handle placing a weapon on a pedestal
function BaseService.handlePlaceWeapon(player: Player, plotNumber: number, pedestalIndex: number)
	-- Check if this is the player's base
	local playerPlot = PlayerData.getAssignedBasePlot(player)
	if playerPlot ~= plotNumber then
		return -- Not their base
	end
	
	-- Check if pedestal already has a weapon
	local pedestal = BaseBuilder.getPedestal(plotNumber, pedestalIndex)
	if not pedestal then return end
	
	if pedestal:GetAttribute("HasWeapon") then
		return -- Already has weapon
	end
	
	-- Get player's equipped weapon from WeaponService
	local equipped = WeaponService.getEquippedWeapon(player)
	if not equipped then
		return -- No weapon equipped
	end
	
	local equippedUid = equipped.uid
	local weaponId = equipped.weaponId
	
	local weaponDef = Config.Weapons[weaponId]
	if not weaponDef then return end
	
	-- Unequip the weapon first
	WeaponService.unequipWeapon(player)
	Remotes.WeaponEquipped:FireClient(player, { success = true, uid = nil, weaponId = nil })
	
	-- Remove weapon from inventory and place on pedestal
	local success = PlayerData.displayWeaponOnPedestal(player, equippedUid, pedestalIndex)
	if not success then return end
	
	-- Store weapon info on pedestal
	pedestal:SetAttribute("WeaponUid", equippedUid)
	pedestal:SetAttribute("WeaponId", weaponId)
	
	-- Get income rate
	local rarity = weaponDef.rarity or "Common"
	local incomeRate = Config.BaseIncomePerRarity[rarity] or 1
	
	-- Update pedestal visuals
	BaseBuilder.updatePedestalVisuals(plotNumber, pedestalIndex, weaponId, rarity, incomeRate)
	
	-- Spawn weapon model on pedestal
	BaseService.spawnWeaponOnPedestal(plotNumber, pedestalIndex, weaponId)
	
	-- Update player data
	Remotes.PlayerDataUpdated:FireClient(player, PlayerData.get(player))
	
	print("[BaseService]", player.Name, "placed", weaponId, "on pedestal", pedestalIndex)
end

-- Handle collecting keys from a pedestal
function BaseService.handleCollectKeys(player: Player, plotNumber: number, pedestalIndex: number)
	-- Check if this is the player's base
	local playerPlot = PlayerData.getAssignedBasePlot(player)
	if playerPlot ~= plotNumber then
		return -- Not their base
	end
	
	-- Check accumulated keys
	if not accumulatedKeys[plotNumber] then return end
	local keys = accumulatedKeys[plotNumber][pedestalIndex] or 0
	
	if keys <= 0 then return end
	
	-- Give keys to player
	PlayerData.addKeys(player, keys)
	PlayerData.updateLeaderstats(player)
	
	-- Reset accumulated keys
	accumulatedKeys[plotNumber][pedestalIndex] = 0
	BaseBuilder.updateAccumulatedKeys(plotNumber, pedestalIndex, 0)
	
	-- Notify player
	Remotes.BaseIncomeEarned:FireClient(player, keys)
	Remotes.PlayerDataUpdated:FireClient(player, PlayerData.get(player))
	
	print("[BaseService]", player.Name, "collected", keys, "keys from pedestal", pedestalIndex)
end

-- Handle removing a weapon from a pedestal (returns to inventory)
function BaseService.handleRemoveWeapon(player: Player, plotNumber: number, pedestalIndex: number)
	-- Check if this is the player's base
	local playerPlot = PlayerData.getAssignedBasePlot(player)
	if playerPlot ~= plotNumber then
		return -- Not their base
	end
	
	-- Check if pedestal has a weapon
	local pedestal = BaseBuilder.getPedestal(plotNumber, pedestalIndex)
	if not pedestal then return end
	
	if not pedestal:GetAttribute("HasWeapon") then
		return -- No weapon to remove
	end
	
	-- Collect any remaining keys first
	BaseService.handleCollectKeys(player, plotNumber, pedestalIndex)
	
	-- Retrieve weapon from pedestal (adds back to inventory)
	local success = PlayerData.retrieveWeaponFromPedestal(player, pedestalIndex)
	if not success then return end
	
	-- Remove weapon model from pedestal
	BaseService.removeWeaponFromPedestal(plotNumber, pedestalIndex)
	
	-- Update pedestal visuals
	BaseBuilder.updatePedestalVisuals(plotNumber, pedestalIndex, nil, nil, nil)
	
	-- Update player data
	Remotes.PlayerDataUpdated:FireClient(player, PlayerData.get(player))
	
	print("[BaseService]", player.Name, "removed weapon from pedestal", pedestalIndex)
end

-- Spawn weapon model on pedestal
function BaseService.spawnWeaponOnPedestal(plotNumber: number, pedestalIndex: number, weaponId: string)
	local pedestal = BaseBuilder.getPedestal(plotNumber, pedestalIndex)
	if not pedestal then return end
	
	local top = pedestal:FindFirstChild("Top")
	if not top then return end
	
	-- Remove existing weapon model
	local existing = top:FindFirstChild("DisplayedWeapon")
	if existing then existing:Destroy() end
	
	-- Find weapon model
	local weaponModelsFolder = ReplicatedStorage:FindFirstChild("WeaponModels")
	if not weaponModelsFolder then return end
	
	local template = weaponModelsFolder:FindFirstChild(weaponId)
	if not template then return end
	
	-- Clone and set up
	local weaponModel = template:Clone()
	weaponModel.Name = "DisplayedWeapon"
	
	-- Position above pedestal
	local displayPos = top.Position + Vector3.new(0, 2.5, 0)
	
	-- Make all parts non-collidable and anchored
	for _, part in weaponModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
	
	-- Scale up for visibility
	local scaleFactor = 4
	for _, part in weaponModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.Size = part.Size * scaleFactor
		end
	end
	
	-- Position
	if weaponModel.PrimaryPart then
		weaponModel:SetPrimaryPartCFrame(CFrame.new(displayPos) * CFrame.Angles(0, 0, math.rad(45)))
	else
		for _, part in weaponModel:GetDescendants() do
			if part:IsA("BasePart") then
				part.Position = displayPos
				break
			end
		end
	end
	
	-- Add rarity glow
	local weaponDef = Config.Weapons[weaponId]
	if weaponDef then
		local glow = Instance.new("PointLight")
		glow.Name = "RarityGlow"
		glow.Color = BaseBuilder.RARITY_COLORS and BaseBuilder.RARITY_COLORS[weaponDef.rarity] or Color3.new(1, 1, 1)
		glow.Brightness = 2
		glow.Range = 10
		
		for _, part in weaponModel:GetDescendants() do
			if part:IsA("BasePart") then
				glow.Parent = part
				break
			end
		end
	end
	
	weaponModel.Parent = top
end

-- Remove weapon from pedestal
function BaseService.removeWeaponFromPedestal(plotNumber: number, pedestalIndex: number)
	local pedestal = BaseBuilder.getPedestal(plotNumber, pedestalIndex)
	if not pedestal then return end
	
	local top = pedestal:FindFirstChild("Top")
	if not top then return end
	
	local existing = top:FindFirstChild("DisplayedWeapon")
	if existing then existing:Destroy() end
end

-- Income accumulation loop
function BaseService.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(Config.BaseIncomeInterval)
			
			-- For each claimed plot
			for plotNumber, userId in plotOwners do
				local player = Players:GetPlayerByUserId(userId)
				if not player then continue end
				
				-- Get displayed weapons
				local displayedWeapons = PlayerData.getDisplayedWeapons(player)
				
				-- Accumulate income for each displayed weapon
				for _, dw in displayedWeapons do
					local weaponDef = Config.Weapons[dw.weaponId]
					if not weaponDef then continue end
					
					local rarity = weaponDef.rarity or "Common"
					local incomeRate = Config.BaseIncomePerRarity[rarity] or 1
					
					-- Add to accumulated keys
					if not accumulatedKeys[plotNumber] then
						accumulatedKeys[plotNumber] = {}
					end
					
					local current = accumulatedKeys[plotNumber][dw.pedestalIndex] or 0
					accumulatedKeys[plotNumber][dw.pedestalIndex] = current + incomeRate
					
					-- Update visual
					BaseBuilder.updateAccumulatedKeys(plotNumber, dw.pedestalIndex, current + incomeRate)
				end
			end
		end
	end)
end

-- Get base data for a player
function BaseService.getBaseData(player: Player): {
	assignedPlot: number?,
	displayedWeapons: { any },
	allPlotOwners: { [number]: string },
}
	local allPlotOwners = {}
	for plotNumber, userId in plotOwners do
		local owner = Players:GetPlayerByUserId(userId)
		if owner then
			allPlotOwners[plotNumber] = owner.DisplayName
		end
	end
	
	return {
		assignedPlot = PlayerData.getAssignedBasePlot(player),
		displayedWeapons = PlayerData.getDisplayedWeapons(player),
		allPlotOwners = allPlotOwners,
	}
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player: Player)
	-- Note: In a real game with persistence, you'd keep the plot claimed
	-- For now, we release the plot when player leaves
	local plotNumber = PlayerData.getAssignedBasePlot(player)
	if plotNumber then
		plotOwners[plotNumber] = nil
		accumulatedKeys[plotNumber] = nil
		
		-- Clear displayed weapons visually
		for i = 1, Config.PedestalsPerBase do
			BaseBuilder.updatePedestalVisuals(plotNumber, i, nil, nil, nil)
			BaseService.removeWeaponFromPedestal(plotNumber, i)
		end
		
		-- Reset sign
		BaseBuilder.updateOwnerSign(plotNumber, nil)
	end
end)

return BaseService
