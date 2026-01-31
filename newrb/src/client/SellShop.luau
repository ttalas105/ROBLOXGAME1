--[[
	Sell Shop: Sell weapons from inventory for keys.
	Modern redesigned UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ShopRemotes = require(script.Parent.ShopRemotes)
local UIHelper = require(script.Parent.UIHelper)

local COLORS = UIHelper.colors()

local SellShop = {}
local screenGui: ScreenGui?
local mainFrame: Frame?
local keysBadge: Frame?
local weaponScroll: ScrollingFrame?
local statsLabel: TextLabel?
local currentState: any = nil

local function updateKeys(keys: number)
	if keysBadge then
		local label = keysBadge:FindFirstChild("Amount")
		if label then
			label.Text = "🔑 " .. tostring(keys)
			UIHelper.pulse(keysBadge)
		end
	end
end

local function getRarityColor(rarity: string): Color3
	local r = Config.Rarities[rarity]
	return r and r.color or COLORS.text
end

local function getSellValue(weaponId: string): number
	local def = Config.Weapons[weaponId]
	if not def then return 0 end
	return Config.SellValueByRarity[def.rarity] or 0
end

local function buildWeaponCard(weapon: any, parent: Instance)
	local def = Config.Weapons[weapon.weaponId]
	if not def then return end
	
	local value = getSellValue(weapon.weaponId)
	local rarityColor = getRarityColor(def.rarity)
	
	local card = UIHelper.card(parent, 85)
	card.Name = "Weapon_" .. weapon.uid
	
	-- Left color stripe (rarity indicator)
	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 5, 1, -10)
	stripe.Position = UDim2.new(0, 5, 0, 5)
	stripe.BackgroundColor3 = rarityColor
	stripe.BorderSizePixel = 0
	stripe.Parent = card
	
	local stripeCorner = Instance.new("UICorner")
	stripeCorner.CornerRadius = UDim.new(0, 3)
	stripeCorner.Parent = stripe
	
	-- Weapon name
	local nameLabel = UIHelper.label(def.name, UDim2.new(1, -140, 0, 24), card)
	nameLabel.Position = UDim2.new(0, 20, 0, 15)
	nameLabel.TextSize = 17
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = rarityColor
	
	-- Rarity badge
	local rarityBadge = UIHelper.rarityBadge(def.rarity, rarityColor, card)
	rarityBadge.Position = UDim2.new(0, 20, 0, 42)
	
	-- Value display
	local valueBadge = Instance.new("Frame")
	valueBadge.Size = UDim2.new(0, 70, 0, 24)
	valueBadge.Position = UDim2.new(0, 120, 0, 42)
	valueBadge.BackgroundColor3 = COLORS.bgLight
	valueBadge.BorderSizePixel = 0
	valueBadge.Parent = card
	
	local valueCorner = Instance.new("UICorner")
	valueCorner.CornerRadius = UDim.new(0, 12)
	valueCorner.Parent = valueBadge
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "+" .. value .. " 🔑"
	valueLabel.TextColor3 = COLORS.gold
	valueLabel.TextSize = 13
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Parent = valueBadge
	
	-- Sell button
	local sellBtn = UIHelper.button("💰 Sell", function()
		ShopRemotes.sellWeapon():FireServer(weapon.uid)
	end, card, COLORS.success)
	sellBtn.Size = UDim2.new(0, 85, 0, 40)
	sellBtn.Position = UDim2.new(1, -15, 0.5, -20)
	sellBtn.AnchorPoint = Vector2.new(1, 0)
	
	return card
end

local function buildSellAllCard(rarity: string, count: number, totalValue: number, parent: Instance)
	local rarityColor = getRarityColor(rarity)
	
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 55)
	card.BackgroundColor3 = rarityColor
	card.BackgroundTransparency = 0.7
	card.BorderSizePixel = 0
	card.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarityColor
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = card
	
	-- Label
	local label = UIHelper.label("Sell All " .. rarity .. " (" .. count .. ")", UDim2.new(0, 200, 0, 24), card)
	label.Position = UDim2.new(0, 15, 0.5, -18)
	label.TextSize = 15
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = COLORS.text
	
	local valueLabel = UIHelper.label("+" .. totalValue .. " 🔑", UDim2.new(0, 100, 0, 20), card)
	valueLabel.Position = UDim2.new(0, 15, 0.5, 5)
	valueLabel.TextSize = 14
	valueLabel.TextColor3 = COLORS.gold
	valueLabel.Font = Enum.Font.GothamBold
	
	-- Sell All button
	local sellBtn = UIHelper.button("Sell All", function()
		ShopRemotes.sellAllByRarity():FireServer(rarity)
	end, card, COLORS.gold)
	sellBtn.Size = UDim2.new(0, 85, 0, 36)
	sellBtn.Position = UDim2.new(1, -15, 0.5, -18)
	sellBtn.AnchorPoint = Vector2.new(1, 0)
	
	return card
end

function SellShop.refresh(state: any)
	currentState = state
	updateKeys(state.keys)
	
	if not weaponScroll then return end
	
	-- Clear existing (both Frames and TextLabels)
	for _, child in weaponScroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end
	
	-- Update stats
	if statsLabel then
		local totalWeapons = #state.weapons
		local maxSlots = state.maxSlots or 50
		statsLabel.Text = "Inventory: " .. totalWeapons .. "/" .. maxSlots .. " weapons"
	end
	
	-- Count weapons by rarity
	local rarityCount: { [string]: number } = {}
	local rarityValue: { [string]: number } = {}
	
	for _, weapon in state.weapons do
		local def = Config.Weapons[weapon.weaponId]
		if def then
			rarityCount[def.rarity] = (rarityCount[def.rarity] or 0) + 1
			local value = Config.SellValueByRarity[def.rarity] or 0
			rarityValue[def.rarity] = (rarityValue[def.rarity] or 0) + value
		end
	end
	
	-- Build "Sell All" buttons for rarities with 2+ weapons
	local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
	for _, rarity in rarityOrder do
		local count = rarityCount[rarity]
		if count and count >= 2 then
			buildSellAllCard(rarity, count, rarityValue[rarity], weaponScroll)
		end
	end
	
	-- Build individual weapon cards
	if #state.weapons == 0 then
		local emptyLabel = UIHelper.label("No weapons in inventory.\nOpen some crates to get weapons!", UDim2.new(1, -20, 0, 60), weaponScroll)
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
		emptyLabel.TextColor3 = COLORS.textMuted
		emptyLabel.TextSize = 15
	else
		-- Sort by rarity (rarest first)
		local sorted = table.clone(state.weapons)
		table.sort(sorted, function(a, b)
			local defA = Config.Weapons[a.weaponId]
			local defB = Config.Weapons[b.weaponId]
			if not defA or not defB then return false end
			local orderA = Config.Rarities[defA.rarity] and Config.Rarities[defA.rarity].order or 0
			local orderB = Config.Rarities[defB.rarity] and Config.Rarities[defB.rarity].order or 0
			return orderA > orderB
		end)
		
		for _, weapon in sorted do
			buildWeaponCard(weapon, weaponScroll)
		end
	end
end

function SellShop.build(parent: Instance): ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SellShopGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.Enabled = false
	screenGui.Parent = parent
	
	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui
	
	mainFrame = UIHelper.frame("SellShop", UDim2.new(0, 460, 0, 580), screenGui)
	mainFrame.Position = UDim2.new(0.5, -230, 0.5, -290)
	
	-- Title
	local title = UIHelper.title("💰 Sell Weapons", mainFrame)
	title.Position = UDim2.new(0, 0, 0, 20)
	
	-- Close button
	UIHelper.closeButton(mainFrame, function()
		SellShop.hide()
	end)
	
	-- Keys badge
	keysBadge = UIHelper.currencyBadge("🔑", 0, COLORS.gold, mainFrame)
	keysBadge.Position = UDim2.new(0.5, -70, 0, 65)
	
	-- Inventory stats
	statsLabel = UIHelper.label("Inventory: 0/50 weapons", UDim2.new(1, 0, 0, 20), mainFrame)
	statsLabel.Position = UDim2.new(0, 0, 0, 110)
	statsLabel.TextXAlignment = Enum.TextXAlignment.Center
	statsLabel.TextColor3 = COLORS.textDim
	statsLabel.TextSize = 14
	
	-- Section header
	local header = UIHelper.sectionHeader("Your Weapons", "⚔️", COLORS.accent, mainFrame)
	header.Position = UDim2.new(0, 20, 0, 135)
	
	-- Weapon scroll
	weaponScroll = UIHelper.scroll(mainFrame)
	weaponScroll.Position = UDim2.new(0, 15, 0, 170)
	weaponScroll.Size = UDim2.new(1, -30, 1, -190)
	
	return screenGui
end

function SellShop.show()
	if screenGui then
		screenGui.Enabled = true
		if mainFrame then
			UIHelper.fadeIn(mainFrame, 0.2)
		end
	end
end

function SellShop.hide()
	if screenGui then
		screenGui.Enabled = false
	end
end

function SellShop.isVisible(): boolean
	return screenGui ~= nil and screenGui.Enabled
end

function SellShop.getGui()
	return screenGui
end

return SellShop
