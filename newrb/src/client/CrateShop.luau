--[[
	Crate Shop: Buy crates with keys, view owned crates, open them.
	Modern redesigned UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ShopRemotes = require(script.Parent.ShopRemotes)
local UIHelper = require(script.Parent.UIHelper)

local COLORS = UIHelper.colors()

local CrateShop = {}
local screenGui: ScreenGui?
local mainFrame: Frame?
local keysBadge: Frame?
local buyScroll: ScrollingFrame?
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

local function buildCrateCard(crateId: string, crateDef: any, keys: number, inventorySlots: number, maxSlots: number, arenasCompleted: any, parent: Instance)
	local canAfford1 = keys >= crateDef.keyCost
	local canAfford5 = keys >= (crateDef.keyCost * 5)
	local inventoryFull = inventorySlots >= maxSlots
	
	-- Check if crate is locked (requires arena completion)
	local isLocked = false
	if crateDef.requiresArena then
		local arenaNum = crateDef.requiresArena
		isLocked = not (arenasCompleted and arenasCompleted[arenaNum])
	end
	
	local card = UIHelper.card(parent, 100)
	card.Name = "Crate_" .. crateId
	
	-- Left side: Crate info
	local infoContainer = Instance.new("Frame")
	infoContainer.Size = UDim2.new(0, 200, 1, 0)
	infoContainer.Position = UDim2.new(0, 15, 0, 0)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = card
	
	-- Crate icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 45, 0, 45)
	icon.Position = UDim2.new(0, 0, 0.5, -22)
	icon.BackgroundColor3 = isLocked and Color3.fromRGB(60, 60, 60) or COLORS.bgLight
	icon.Text = isLocked and "🔒" or "📦"
	icon.TextSize = 24
	icon.Font = Enum.Font.GothamBold
	icon.Parent = infoContainer
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 10)
	iconCorner.Parent = icon
	
	-- Crate name
	local nameLabel = UIHelper.label(crateDef.name, UDim2.new(0, 140, 0, 22), infoContainer)
	nameLabel.Position = UDim2.new(0, 55, 0, 15)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = isLocked and Color3.fromRGB(100, 100, 100) or COLORS.text
	
	-- Cost per crate
	local costLabel = UIHelper.label("🔑 " .. crateDef.keyCost .. " each", UDim2.new(0, 140, 0, 18), infoContainer)
	costLabel.Position = UDim2.new(0, 55, 0, 38)
	costLabel.TextSize = 13
	costLabel.TextColor3 = isLocked and Color3.fromRGB(80, 80, 80) or COLORS.gold
	
	-- Description
	local descLabel = UIHelper.label(crateDef.description, UDim2.new(0, 140, 0, 18), infoContainer)
	descLabel.Position = UDim2.new(0, 55, 0, 58)
	descLabel.TextSize = 11
	descLabel.TextColor3 = isLocked and Color3.fromRGB(180, 80, 80) or COLORS.textDim
	
	-- Buttons container (right side)
	local btnContainer = Instance.new("Frame")
	btnContainer.Size = UDim2.new(0, 200, 1, -10)
	btnContainer.Position = UDim2.new(1, -210, 0, 5)
	btnContainer.BackgroundTransparency = 1
	btnContainer.Parent = card
	
	if isLocked then
		-- Show locked state with chains
		local lockedFrame = Instance.new("Frame")
		lockedFrame.Size = UDim2.new(1, 0, 0, 50)
		lockedFrame.Position = UDim2.new(0, 0, 0.5, -25)
		lockedFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		lockedFrame.Parent = btnContainer
		
		local lockedCorner = Instance.new("UICorner")
		lockedCorner.CornerRadius = UDim.new(0, 8)
		lockedCorner.Parent = lockedFrame
		
		local lockedBorder = Instance.new("UIStroke")
		lockedBorder.Color = Color3.fromRGB(80, 80, 90)
		lockedBorder.Thickness = 2
		lockedBorder.Parent = lockedFrame
		
		-- Chain and lock icon
		local lockIcon = Instance.new("TextLabel")
		lockIcon.Size = UDim2.new(1, 0, 0, 30)
		lockIcon.Position = UDim2.new(0, 0, 0, 2)
		lockIcon.BackgroundTransparency = 1
		lockIcon.Text = "⛓️🔒⛓️"
		lockIcon.TextSize = 20
		lockIcon.Font = Enum.Font.GothamBold
		lockIcon.TextColor3 = Color3.fromRGB(120, 120, 130)
		lockIcon.Parent = lockedFrame
		
		-- Locked text
		local lockedText = Instance.new("TextLabel")
		lockedText.Size = UDim2.new(1, 0, 0, 16)
		lockedText.Position = UDim2.new(0, 0, 0, 30)
		lockedText.BackgroundTransparency = 1
		lockedText.Text = "LOCKED"
		lockedText.TextSize = 12
		lockedText.Font = Enum.Font.GothamBlack
		lockedText.TextColor3 = Color3.fromRGB(150, 60, 60)
		lockedText.Parent = lockedFrame
	else
		-- Normal buy buttons
		local btn1Color = (canAfford1 and not inventoryFull) and COLORS.success or COLORS.disabled
		local btn1 = UIHelper.button("Open x1", function()
			if canAfford1 then
				ShopRemotes.buyCrate():FireServer(crateId, 1)
			end
		end, btnContainer, btn1Color)
		btn1.Size = UDim2.new(0, 90, 0, 38)
		btn1.Position = UDim2.new(0, 0, 0.5, -19)
		btn1.TextSize = 14
		
		local btn5Color = (canAfford5 and not inventoryFull) and COLORS.accent or COLORS.disabled
		local btn5 = UIHelper.button("Open x5", function()
			if canAfford5 then
				ShopRemotes.buyCrate():FireServer(crateId, 5)
			end
		end, btnContainer, btn5Color)
		btn5.Size = UDim2.new(0, 90, 0, 38)
		btn5.Position = UDim2.new(0, 100, 0.5, -19)
		btn5.TextSize = 14
		
		-- Cost labels under buttons
		local cost1Label = Instance.new("TextLabel")
		cost1Label.Size = UDim2.new(0, 90, 0, 14)
		cost1Label.Position = UDim2.new(0, 0, 0.5, 22)
		cost1Label.BackgroundTransparency = 1
		cost1Label.Text = "🔑 " .. crateDef.keyCost
		cost1Label.TextSize = 11
		cost1Label.Font = Enum.Font.GothamBold
		cost1Label.TextColor3 = canAfford1 and COLORS.gold or COLORS.textMuted
		cost1Label.Parent = btnContainer
		
		local cost5Label = Instance.new("TextLabel")
		cost5Label.Size = UDim2.new(0, 90, 0, 14)
		cost5Label.Position = UDim2.new(0, 100, 0.5, 22)
		cost5Label.BackgroundTransparency = 1
		cost5Label.Text = "🔑 " .. (crateDef.keyCost * 5)
		cost5Label.TextSize = 11
		cost5Label.Font = Enum.Font.GothamBold
		cost5Label.TextColor3 = canAfford5 and COLORS.gold or COLORS.textMuted
		cost5Label.Parent = btnContainer
		
		-- Warning if inventory full
		if inventoryFull then
			local warnLabel = Instance.new("TextLabel")
			warnLabel.Size = UDim2.new(1, 0, 0, 14)
			warnLabel.Position = UDim2.new(0, 0, 1, -16)
			warnLabel.BackgroundTransparency = 1
			warnLabel.Text = "⚠️ Inventory full - sell weapons first!"
			warnLabel.TextSize = 11
			warnLabel.Font = Enum.Font.GothamBold
			warnLabel.TextColor3 = COLORS.danger
			warnLabel.Parent = card
		end
	end
	
	return card
end

function CrateShop.refresh(state: any)
	currentState = state
	updateKeys(state.keys)
	
	if not buyScroll then return end
	
	-- Clear existing (both Frames and TextLabels)
	for _, child in buyScroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end
	
	-- Count inventory slots used (weapons only now)
	local inventoryUsed = 0
	if state.weapons then
		for _ in state.weapons do
			inventoryUsed += 1
		end
	end
	local maxSlots = state.maxSlots or 10
	
	-- Build buy section (sorted by keyCost, cheapest first)
	local sortedCrates = {}
	for crateId, crateDef in Config.Crates do
		table.insert(sortedCrates, { id = crateId, def = crateDef })
	end
	table.sort(sortedCrates, function(a, b)
		return a.def.keyCost < b.def.keyCost
	end)
	
	for _, crate in sortedCrates do
		buildCrateCard(crate.id, crate.def, state.keys, inventoryUsed, maxSlots, state.arenasCompleted, buyScroll)
	end
end

function CrateShop.build(parent: Instance): ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CrateShopGui"
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
	
	mainFrame = UIHelper.frame("CrateShop", UDim2.new(0, 480, 0, 420), screenGui)
	mainFrame.Position = UDim2.new(0.5, -240, 0.5, -210)
	
	-- Title
	local title = UIHelper.title("🎁 Crate Shop", mainFrame)
	title.Position = UDim2.new(0, 0, 0, 20)
	
	-- Close button
	UIHelper.closeButton(mainFrame, function()
		CrateShop.hide()
	end)
	
	-- Keys badge (centered)
	keysBadge = UIHelper.currencyBadge("🔑", 0, COLORS.gold, mainFrame)
	keysBadge.Position = UDim2.new(0.5, -70, 0, 65)
	
	-- Buy section header
	local buyHeader = UIHelper.sectionHeader("Available Crates", "💎", COLORS.accent, mainFrame)
	buyHeader.Position = UDim2.new(0, 20, 0, 115)
	
	-- Tip text
	local tipLabel = UIHelper.label("Crates open instantly! Weapons go to your inventory below.", UDim2.new(1, -40, 0, 20), mainFrame)
	tipLabel.Position = UDim2.new(0, 20, 0, 145)
	tipLabel.TextSize = 12
	tipLabel.TextColor3 = COLORS.textMuted
	tipLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Buy scroll area (taller now)
	buyScroll = UIHelper.scroll(mainFrame)
	buyScroll.Position = UDim2.new(0, 15, 0, 170)
	buyScroll.Size = UDim2.new(1, -30, 0, 230)
	
	return screenGui
end

function CrateShop.show()
	if screenGui then
		screenGui.Enabled = true
		if mainFrame then
			UIHelper.fadeIn(mainFrame, 0.2)
		end
	end
end

function CrateShop.hide()
	if screenGui then
		screenGui.Enabled = false
	end
end

function CrateShop.isVisible(): boolean
	return screenGui ~= nil and screenGui.Enabled
end

function CrateShop.getGui()
	return screenGui
end

return CrateShop
