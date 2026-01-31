--[[
	Shop logic: buy crate, open crate (RNG + odds), sell weapon, buy upgrade.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

local ShopService = {}
local Random = Random.new()

-- Weighted roll: pick weapon from crate pool
-- Weight = 1/odds, so "1 in 100000" has weight 0.00001
-- Luck multiplier decreases the odds (makes rare items more likely)
local function rollWeaponFromCrate(crateId: string, luckMultiplier: number)
	local crateDef = Config.Crates[crateId]
	if not crateDef then return nil end
	
	local pool = crateDef.weaponPool
	local totalWeight = 0
	local weights: { number } = {}
	
	for _, weaponId in pool do
		local def = Config.Weapons[weaponId]
		if def then
			-- Apply luck: divide odds by luck multiplier (higher luck = lower odds = more weight)
			local adjustedOdds = math.max(1, def.odds / luckMultiplier)
			local w = 1 / adjustedOdds
			totalWeight += w
			table.insert(weights, w)
		else
			table.insert(weights, 0)
		end
	end
	
	if totalWeight <= 0 then return nil end
	
	local r = Random:NextNumber(0, totalWeight)
	for i, weaponId in pool do
		local w = weights[i] or 0
		if r <= w then
			local def = Config.Weapons[weaponId]
			return weaponId, def and def.odds or 1
		end
		r -= w
	end
	
	-- Fallback to last item
	local lastId = pool[#pool]
	local def = Config.Weapons[lastId]
	return lastId, def and def.odds or 1
end

local function stateForClient(player: Player)
	local d = PlayerData.get(player)
	return {
		keys = d.keys,
		xp = d.xp,
		weapons = d.weapons,
		crates = d.crates,
		upgrades = d.upgrades,
		maxSlots = PlayerData.getMaxInventorySlots(player),
	}
end

local function fireUpdate(player: Player)
	-- Update leaderstats
	PlayerData.updateLeaderstats(player)
	
	-- Fire client update
	local folder = Remotes.getFolder()
	local ev = folder:FindFirstChild("PlayerDataUpdated")
	if ev and ev:IsA("RemoteEvent") then
		(ev :: RemoteEvent):FireClient(player, stateForClient(player))
	end
end

-- Buy and instantly open a crate
local function onBuyCrate(player: Player, crateId: string, quantity: number?)
	local count = quantity or 1
	count = math.clamp(count, 1, 5) -- Max 5 at once
	
	local crateDef = Config.Crates[crateId]
	if not crateDef then 
		warn("[ShopService] Invalid crate:", crateId)
		return 
	end
	
	local totalCost = crateDef.keyCost * count
	if not PlayerData.spendKeys(player, totalCost) then 
		warn("[ShopService] Not enough keys for", count, "crates")
		return 
	end
	
	-- Open each crate immediately
	local results = {}
	local luckMultiplier = PlayerData.getLuckMultiplier(player)
	
	for i = 1, count do
		-- Check inventory space
		if not PlayerData.hasInventorySpace(player) then
			-- Inventory full - no weapon awarded
			table.insert(results, {
				success = false,
				weaponId = nil,
				odds = nil,
				uid = nil,
				inventoryFull = true,
			})
			print("[ShopService]", player.Name, "inventory full - crate wasted!")
		else
			-- Roll and add weapon
			local weaponId, odds = rollWeaponFromCrate(crateId, luckMultiplier)
			if weaponId then
				local inst = PlayerData.addWeapon(player, weaponId)
				table.insert(results, {
					success = true,
					weaponId = weaponId,
					odds = odds,
					uid = inst.uid,
					inventoryFull = false,
				})
				print("[ShopService]", player.Name, "opened crate:", crateId, "got:", weaponId, "(1 in " .. odds .. ")")
				
				-- Check for double roll bonus
				if PlayerData.hasDoubleRoll(player) and PlayerData.hasInventorySpace(player) then
					PlayerData.consumeDoubleRoll(player)
					local w2, o2 = rollWeaponFromCrate(crateId, luckMultiplier)
					if w2 then
						local inst2 = PlayerData.addWeapon(player, w2)
						table.insert(results, {
							success = true,
							weaponId = w2,
							odds = o2,
							uid = inst2.uid,
							inventoryFull = false,
							isBonus = true,
						})
						print("[ShopService]", player.Name, "BONUS roll got:", w2)
					end
				end
			end
		end
	end
	
	-- Fire results for UI animation FIRST (so client can set up pending UIDs before inventory refresh)
	if #results == 1 then
		local r = results[1]
		Remotes.OpenCrateResult:FireClient(player, r.success, r.weaponId, r.odds, r.uid, r.inventoryFull and "Inventory full!" or nil)
	elseif #results > 1 then
		-- For multiple crates, send the array
		Remotes.OpenCrateResult:FireClient(player, true, results, nil, nil, nil)
	end
	
	-- Small delay to ensure client processes OpenCrateResult before inventory update
	task.defer(function()
		fireUpdate(player)
	end)
end

-- Legacy open crate (for clicking inventory - but crates no longer go to inventory)
local function onOpenCrate(player: Player, crateId: string)
	-- Just redirect to buy (but free since they shouldn't have crates anymore)
	-- This is kept for backwards compatibility but shouldn't be used
	warn("[ShopService] Legacy onOpenCrate called - crates should open instantly now")
end

-- Sell weapon for keys (by uid)
local function onSellWeapon(player: Player, weaponUid: string)
	local w = PlayerData.removeWeaponByUid(player, weaponUid)
	if not w then return end
	
	local def = Config.Weapons[w.weaponId]
	if not def then return end
	
	local baseValue = Config.SellValueByRarity[def.rarity] or 0
	local magnetMultiplier = PlayerData.getKeyMagnetMultiplier(player)
	local finalValue = math.floor(baseValue * magnetMultiplier)
	
	PlayerData.addKeys(player, finalValue)
	print("[ShopService]", player.Name, "sold", def.name, "for", finalValue, "keys")
	fireUpdate(player)
end

-- Sell all weapons of a specific rarity
local function onSellAllByRarity(player: Player, rarity: string)
	local d = PlayerData.get(player)
	local toRemove = {}
	local totalValue = 0
	local magnetMultiplier = PlayerData.getKeyMagnetMultiplier(player)
	
	for _, w in d.weapons do
		local def = Config.Weapons[w.weaponId]
		if def and def.rarity == rarity then
			table.insert(toRemove, w.uid)
			local baseValue = Config.SellValueByRarity[rarity] or 0
			totalValue += math.floor(baseValue * magnetMultiplier)
		end
	end
	
	for _, uid in toRemove do
		PlayerData.removeWeaponByUid(player, uid)
	end
	
	if totalValue > 0 then
		PlayerData.addKeys(player, totalValue)
		print("[ShopService]", player.Name, "sold all", rarity, "weapons for", totalValue, "keys")
	end
	
	fireUpdate(player)
end

-- Buy upgrade with XP
local function onBuyUpgrade(player: Player, upgradeId: string)
	local upgradeDef = Config.Upgrades[upgradeId]
	if not upgradeDef then return end
	
	if not PlayerData.canBuyUpgrade(player, upgradeId) then
		warn("[ShopService] Cannot buy upgrade:", upgradeId)
		return
	end
	
	if not PlayerData.spendXP(player, upgradeDef.xpCost) then return end
	
	PlayerData.addUpgrade(player, upgradeId, 1)
	print("[ShopService]", player.Name, "bought upgrade:", upgradeId)
	fireUpdate(player)
end

local function onGetPlayerData(player: Player)
	return stateForClient(player)
end

function ShopService.start()
	Remotes.createAll()
	
	Remotes.BuyCrate.OnServerEvent:Connect(onBuyCrate)
	Remotes.OpenCrate.OnServerEvent:Connect(onOpenCrate)
	Remotes.SellWeapon.OnServerEvent:Connect(onSellWeapon)
	Remotes.SellAllByRarity.OnServerEvent:Connect(onSellAllByRarity)
	Remotes.BuyUpgrade.OnServerEvent:Connect(onBuyUpgrade)
	Remotes.GetPlayerData.OnServerInvoke = onGetPlayerData
	
	print("[ShopService] Started")
end

return ShopService
