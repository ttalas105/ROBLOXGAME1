--[[
	Upgrades Shop: Buy upgrades with XP.
	Modern redesigned UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ShopRemotes = require(script.Parent.ShopRemotes)
local UIHelper = require(script.Parent.UIHelper)

local COLORS = UIHelper.colors()

local UpgradesShop = {}
local screenGui: ScreenGui?
local mainFrame: Frame?
local xpBadge: Frame?
local upgradeScroll: ScrollingFrame?
local currentState: any = nil

local function updateXP(xp: number)
	if xpBadge then
		local label = xpBadge:FindFirstChild("Amount")
		if label then
			label.Text = "⚡ " .. tostring(xp)
			UIHelper.pulse(xpBadge)
		end
	end
end

-- Get icon for upgrade type
local function getUpgradeIcon(upgradeId: string): string
	local icons = {
		luck_boost = "🍀",
		key_magnet = "🧲",
		xp_boost = "⚡",
		inventory_expansion = "📦",
		double_roll = "🎲",
		reroll_token = "🔄",
	}
	return icons[upgradeId] or "✨"
end

local function buildUpgradeCard(upgradeId: string, upgradeDef: any, currentLevel: number, xp: number, parent: Instance)
	local atMax = upgradeDef.maxLevel and currentLevel >= upgradeDef.maxLevel
	local canAfford = xp >= upgradeDef.xpCost
	local isPermanent = upgradeDef.maxLevel ~= nil
	
	local card = UIHelper.card(parent, isPermanent and 115 or 100)
	card.Name = "Upgrade_" .. upgradeId
	
	-- Left icon
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 50, 0, 50)
	iconBg.Position = UDim2.new(0, 15, 0, isPermanent and 32 or 25)
	iconBg.BackgroundColor3 = atMax and COLORS.success or COLORS.purple
	iconBg.BackgroundTransparency = 0.7
	iconBg.BorderSizePixel = 0
	iconBg.Parent = card
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 12)
	iconCorner.Parent = iconBg
	
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = getUpgradeIcon(upgradeId)
	icon.TextSize = 26
	icon.Parent = iconBg
	
	-- Upgrade name
	local nameLabel = UIHelper.label(upgradeDef.name, UDim2.new(1, -180, 0, 24), card)
	nameLabel.Position = UDim2.new(0, 75, 0, 15)
	nameLabel.TextSize = 17
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = atMax and COLORS.success or COLORS.text
	
	-- Description
	local descLabel = UIHelper.label(upgradeDef.description, UDim2.new(1, -180, 0, 32), card)
	descLabel.Position = UDim2.new(0, 75, 0, 38)
	descLabel.TextSize = 13
	descLabel.TextColor3 = COLORS.textDim
	descLabel.TextWrapped = true
	
	-- Level/count indicator
	local levelBadge = Instance.new("Frame")
	levelBadge.Size = UDim2.new(0, isPermanent and 90 or 75, 0, 24)
	levelBadge.Position = UDim2.new(0, 75, 0, isPermanent and 75 or 72)
	levelBadge.BackgroundColor3 = atMax and COLORS.success or COLORS.purple
	levelBadge.BorderSizePixel = 0
	levelBadge.Parent = card
	
	local levelCorner = Instance.new("UICorner")
	levelCorner.CornerRadius = UDim.new(0, 12)
	levelCorner.Parent = levelBadge
	
	local levelText
	if isPermanent then
		levelText = "Lv " .. currentLevel .. "/" .. upgradeDef.maxLevel
	else
		levelText = "x" .. currentLevel
	end
	
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(1, 0, 1, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = levelText
	levelLabel.TextColor3 = Color3.new(1, 1, 1)
	levelLabel.TextSize = 13
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.Parent = levelBadge
	
	-- Cost badge
	if not atMax then
		local costBadge = Instance.new("Frame")
		costBadge.Size = UDim2.new(0, 80, 0, 24)
		costBadge.Position = UDim2.new(0, isPermanent and 175 or 160, 0, isPermanent and 75 or 72)
		costBadge.BackgroundColor3 = canAfford and COLORS.bgLight or COLORS.danger
		costBadge.BackgroundTransparency = canAfford and 0 or 0.5
		costBadge.BorderSizePixel = 0
		costBadge.Parent = card
		
		local costCorner = Instance.new("UICorner")
		costCorner.CornerRadius = UDim.new(0, 12)
		costCorner.Parent = costBadge
		
		local costLabel = Instance.new("TextLabel")
		costLabel.Size = UDim2.new(1, 0, 1, 0)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = "⚡ " .. upgradeDef.xpCost
		costLabel.TextColor3 = canAfford and COLORS.purple or COLORS.text
		costLabel.TextSize = 13
		costLabel.Font = Enum.Font.GothamBold
		costLabel.Parent = costBadge
	end
	
	-- Buy button
	local buttonText = atMax and "✓ MAX" or (canAfford and "Buy" or "Need XP")
	local buttonColor = atMax and COLORS.success or (canAfford and COLORS.purple or COLORS.disabled)
	
	local buyBtn = UIHelper.button(buttonText, function()
		if not atMax and canAfford then
			ShopRemotes.buyUpgrade():FireServer(upgradeId)
		end
	end, card, buttonColor)
	buyBtn.Size = UDim2.new(0, 90, 0, 42)
	buyBtn.Position = UDim2.new(1, -15, 0.5, -21)
	buyBtn.AnchorPoint = Vector2.new(1, 0)
	
	if atMax then
		buyBtn.TextSize = 14
	elseif not canAfford then
		buyBtn.TextSize = 13
	end
	
	return card
end

function UpgradesShop.refresh(state: any)
	currentState = state
	updateXP(state.xp)
	
	if not upgradeScroll then return end
	
	-- Clear existing (both Frames and TextLabels)
	for _, child in upgradeScroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end
	
	-- Separate permanent vs consumables
	local permanentUpgrades = {}
	local consumables = {}
	
	for upgradeId, upgradeDef in Config.Upgrades do
		if upgradeDef.maxLevel then
			table.insert(permanentUpgrades, {id = upgradeId, def = upgradeDef})
		else
			table.insert(consumables, {id = upgradeId, def = upgradeDef})
		end
	end
	
	-- Permanent Upgrades Section
	UIHelper.sectionHeader("Permanent Upgrades", "🔧", COLORS.accent, upgradeScroll)
	
	for _, upgrade in permanentUpgrades do
		local level = state.upgrades[upgrade.id] or 0
		buildUpgradeCard(upgrade.id, upgrade.def, level, state.xp, upgradeScroll)
	end
	
	-- Spacer
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1, 0, 0, 10)
	spacer.BackgroundTransparency = 1
	spacer.Parent = upgradeScroll
	
	-- Consumables Section
	UIHelper.sectionHeader("Consumables", "🧪", COLORS.gold, upgradeScroll)
	
	for _, upgrade in consumables do
		local count = state.upgrades[upgrade.id] or 0
		buildUpgradeCard(upgrade.id, upgrade.def, count, state.xp, upgradeScroll)
	end
end

function UpgradesShop.build(parent: Instance): ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "UpgradesShopGui"
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
	
	mainFrame = UIHelper.frame("UpgradesShop", UDim2.new(0, 480, 0, 600), screenGui)
	mainFrame.Position = UDim2.new(0.5, -240, 0.5, -300)
	
	-- Title
	local title = UIHelper.title("⚡ Upgrades Shop", mainFrame)
	title.Position = UDim2.new(0, 0, 0, 20)
	
	-- Close button
	UIHelper.closeButton(mainFrame, function()
		UpgradesShop.hide()
	end)
	
	-- XP badge
	xpBadge = UIHelper.currencyBadge("⚡", 0, COLORS.purple, mainFrame)
	xpBadge.Position = UDim2.new(0.5, -70, 0, 65)
	
	-- Subtitle
	local subtitle = UIHelper.label("Spend XP to power up your gameplay!", UDim2.new(1, 0, 0, 20), mainFrame)
	subtitle.Position = UDim2.new(0, 0, 0, 110)
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.TextColor3 = COLORS.textDim
	subtitle.TextSize = 14
	
	-- Upgrade scroll
	upgradeScroll = UIHelper.scroll(mainFrame)
	upgradeScroll.Position = UDim2.new(0, 15, 0, 140)
	upgradeScroll.Size = UDim2.new(1, -30, 1, -160)
	
	return screenGui
end

function UpgradesShop.show()
	if screenGui then
		screenGui.Enabled = true
		if mainFrame then
			UIHelper.fadeIn(mainFrame, 0.2)
		end
	end
end

function UpgradesShop.hide()
	if screenGui then
		screenGui.Enabled = false
	end
end

function UpgradesShop.isVisible(): boolean
	return screenGui ~= nil and screenGui.Enabled
end

function UpgradesShop.getGui()
	return screenGui
end

return UpgradesShop
