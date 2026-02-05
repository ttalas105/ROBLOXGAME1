--[[
	InventoryWindow: Window that shows all player weapons when bag button is clicked
	Displays weapons in a neat grid layout
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIHelper = require(script.Parent.UIHelper)

local ShopRemotes = require(script.Parent.ShopRemotes)

local InventoryWindow = {}

local screenGui: ScreenGui?
local windowFrame: Frame?
local weaponsContainer: Frame?
local currentState: any = nil
local equippedWeaponUid: string? = nil -- Track currently equipped weapon
local COLORS = UIHelper.colors()

-- Weapon slot size
local SLOT_SIZE = 80
local SLOTS_PER_ROW = 8
local MAX_SLOTS = 64 -- DEBUG: Increased for testing all weapons

-- Get weapon models folder from ReplicatedStorage
local function getWeaponModelsFolder(): Folder?
	return ReplicatedStorage:FindFirstChild("WeaponModels")
end

-- Create a ViewportFrame with the weapon model
local function createWeaponViewport(parent: Frame, weaponId: string): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "WeaponViewport"
	viewport.Size = UDim2.new(1, -10, 1, -30)
	viewport.Position = UDim2.new(0, 5, 0, 5)
	viewport.BackgroundTransparency = 1
	viewport.Parent = parent
	
	-- Add camera
	local camera = Instance.new("Camera")
	camera.CameraType = Enum.CameraType.Scriptable
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	
	-- Clone weapon model
	local folder = getWeaponModelsFolder()
	if folder then
		local template = folder:FindFirstChild(weaponId)
		if template then
			local model = template:Clone()
			model.Parent = viewport
			
			-- Get model bounds for camera positioning
			local cf, size = model:GetBoundingBox()
			local maxSize = math.max(size.X, size.Y, size.Z)
			
			-- Position camera to frame the weapon nicely
			local cameraDistance = maxSize * 1.8
			camera.CFrame = CFrame.new(cf.Position + Vector3.new(cameraDistance * 0.7, cameraDistance * 0.3, cameraDistance * 0.7), cf.Position)
		end
	end
	
	return viewport
end

-- Create a weapon slot
local function createWeaponSlot(index: number, parent: Frame): Frame
	-- Use TextButton for clickability
	local slot = Instance.new("TextButton")
	slot.Name = "WeaponSlot_" .. index
	slot.Size = UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE)
	slot.BackgroundColor3 = COLORS.bgDark
	slot.BackgroundTransparency = 0.3
	slot.BorderSizePixel = 0
	slot.Text = ""
	slot.AutoButtonColor = false
	slot.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = slot
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.border
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = slot
	
	-- Equipped indicator (green glow)
	local equippedIndicator = Instance.new("Frame")
	equippedIndicator.Name = "EquippedIndicator"
	equippedIndicator.Size = UDim2.new(1, 6, 1, 6)
	equippedIndicator.Position = UDim2.new(0, -3, 0, -3)
	equippedIndicator.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
	equippedIndicator.BackgroundTransparency = 1 -- Hidden by default
	equippedIndicator.BorderSizePixel = 0
	equippedIndicator.ZIndex = 0
	equippedIndicator.Parent = slot
	
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0, 10)
	indicatorCorner.Parent = equippedIndicator
	
	-- Equipped badge
	local equippedBadge = Instance.new("TextLabel")
	equippedBadge.Name = "EquippedBadge"
	equippedBadge.Size = UDim2.new(0, 20, 0, 20)
	equippedBadge.Position = UDim2.new(1, -18, 0, -2)
	equippedBadge.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	equippedBadge.BackgroundTransparency = 1 -- Hidden by default
	equippedBadge.TextTransparency = 1 -- Hidden by default
	equippedBadge.Text = "✓"
	equippedBadge.TextColor3 = Color3.new(1, 1, 1)
	equippedBadge.TextSize = 14
	equippedBadge.Font = Enum.Font.GothamBold
	equippedBadge.ZIndex = 10
	equippedBadge.Parent = slot
	
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(1, 0)
	badgeCorner.Parent = equippedBadge
	
	-- Weapon viewport (will be populated when weapon is set)
	local viewportHolder = Instance.new("Frame")
	viewportHolder.Name = "ViewportHolder"
	viewportHolder.Size = UDim2.new(1, -10, 1, -30)
	viewportHolder.Position = UDim2.new(0, 5, 0, 5)
	viewportHolder.BackgroundTransparency = 1
	viewportHolder.Parent = slot
	
	-- Fallback icon (shown if no model)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "⚔️"
	icon.TextSize = 40
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = viewportHolder
	
	-- Weapon name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -4, 0, 20)
	nameLabel.Position = UDim2.new(0, 2, 1, -22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ""
	nameLabel.TextSize = 10
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = COLORS.text
	nameLabel.TextWrapped = true
	nameLabel.Parent = slot
	
	-- Rarity stripe
	local rarityStripe = Instance.new("Frame")
	rarityStripe.Name = "RarityStripe"
	rarityStripe.Size = UDim2.new(1, 0, 0, 4)
	rarityStripe.Position = UDim2.new(0, 0, 0, 0)
	rarityStripe.BackgroundTransparency = 1
	rarityStripe.BorderSizePixel = 0
	rarityStripe.Parent = slot
	
	local stripeCorner = Instance.new("UICorner")
	stripeCorner.CornerRadius = UDim.new(0, 8)
	stripeCorner.Parent = rarityStripe
	
	-- Store weapon data
	slot:SetAttribute("WeaponId", "")
	slot:SetAttribute("WeaponUid", "")
	
	-- Click to equip
	slot.MouseButton1Click:Connect(function()
		local weaponUid = slot:GetAttribute("WeaponUid")
		if weaponUid and weaponUid ~= "" then
			-- Toggle equip/unequip
			if equippedWeaponUid == weaponUid then
				-- Unequip
				ShopRemotes.unequipWeapon():FireServer()
			else
				-- Equip
				ShopRemotes.equipWeapon():FireServer(weaponUid)
			end
		end
	end)
	
	-- Hover effect
	slot.MouseEnter:Connect(function()
		if slot:GetAttribute("WeaponUid") ~= "" then
			TweenService:Create(slot, TweenInfo.new(0.1), {
				BackgroundTransparency = 0.1
			}):Play()
		end
	end)
	
	slot.MouseLeave:Connect(function()
		TweenService:Create(slot, TweenInfo.new(0.1), {
			BackgroundTransparency = 0.3
		}):Play()
	end)
	
	return slot
end

-- Clear a slot
local function clearSlot(slot: Frame)
	slot:SetAttribute("WeaponId", "")
	slot:SetAttribute("WeaponUid", "")
	
	local viewportHolder = slot:FindFirstChild("ViewportHolder") :: Frame?
	local nameLabel = slot:FindFirstChild("Name") :: TextLabel?
	local stripe = slot:FindFirstChild("RarityStripe") :: Frame?
	local stroke = slot:FindFirstChildOfClass("UIStroke")
	local equippedIndicator = slot:FindFirstChild("EquippedIndicator") :: Frame?
	local equippedBadge = slot:FindFirstChild("EquippedBadge") :: TextLabel?
	
	if viewportHolder then
		-- Remove any existing viewport
		local existingViewport = viewportHolder:FindFirstChild("WeaponViewport")
		if existingViewport then existingViewport:Destroy() end
		
		-- Hide fallback icon
		local icon = viewportHolder:FindFirstChild("Icon") :: TextLabel?
		if icon then
			icon.Text = ""
			icon.TextColor3 = Color3.new(1, 1, 1)
		end
	end
	if nameLabel then nameLabel.Text = "" end
	if stripe then stripe.BackgroundTransparency = 1 end
	if stroke then stroke.Color = COLORS.border end
	if equippedIndicator then equippedIndicator.BackgroundTransparency = 1 end
	if equippedBadge then 
		equippedBadge.BackgroundTransparency = 1 
		equippedBadge.TextTransparency = 1
	end
end

-- Fill a slot with weapon data
local function fillSlot(slot: Frame, weaponId: string, uid: string, rarity: string?)
	local weaponDef = Config.Weapons[weaponId]
	if not weaponDef then return end
	
	local weaponRarity = rarity or weaponDef.rarity or "Common"
	local rarityData = Config.Rarities[weaponRarity]
	local rarityColor = rarityData and rarityData.color or Color3.new(1, 1, 1)
	
	slot:SetAttribute("WeaponId", weaponId)
	slot:SetAttribute("WeaponUid", uid)
	
	local viewportHolder = slot:FindFirstChild("ViewportHolder") :: Frame?
	local nameLabel = slot:FindFirstChild("Name") :: TextLabel?
	local stripe = slot:FindFirstChild("RarityStripe") :: Frame?
	local stroke = slot:FindFirstChildOfClass("UIStroke")
	local equippedIndicator = slot:FindFirstChild("EquippedIndicator") :: Frame?
	local equippedBadge = slot:FindFirstChild("EquippedBadge") :: TextLabel?
	
	if viewportHolder then
		-- Remove any existing viewport
		local existingViewport = viewportHolder:FindFirstChild("WeaponViewport")
		if existingViewport then existingViewport:Destroy() end
		
		local icon = viewportHolder:FindFirstChild("Icon") :: TextLabel?
		
		-- Try to create viewport with weapon model
		local folder = getWeaponModelsFolder()
		local hasModel = folder and folder:FindFirstChild(weaponId)
		
		if hasModel then
			-- Create viewport with 3D model
			local viewport = Instance.new("ViewportFrame")
			viewport.Name = "WeaponViewport"
			viewport.Size = UDim2.new(1, 0, 1, 0)
			viewport.BackgroundTransparency = 1
			viewport.Parent = viewportHolder
			
			local camera = Instance.new("Camera")
			camera.CameraType = Enum.CameraType.Scriptable
			camera.Parent = viewport
			viewport.CurrentCamera = camera
			
			local model = hasModel:Clone()
			model.Parent = viewport
			
			-- Get model bounds for camera positioning (closer = bigger)
			local cf, size = model:GetBoundingBox()
			local maxSize = math.max(size.X, size.Y, size.Z)
			local cameraDistance = maxSize * 0.9
			camera.CFrame = CFrame.new(cf.Position + Vector3.new(cameraDistance * 0.7, cameraDistance * 0.3, cameraDistance * 0.7), cf.Position)
			
			-- Hide fallback icon
			if icon then icon.Text = "" end
		else
			-- Show fallback icon
			if icon then
				icon.Text = "⚔️"
				icon.TextColor3 = rarityColor
			end
		end
	end
	
	if nameLabel then
		local name = weaponDef.name or weaponId
		-- Truncate if too long
		if #name > 12 then
			name = string.sub(name, 1, 11) .. ".."
		end
		nameLabel.Text = name
		nameLabel.TextColor3 = rarityColor
	end
	
	if stripe then
		stripe.BackgroundTransparency = 0
		stripe.BackgroundColor3 = rarityColor
	end
	
	if stroke then
		stroke.Color = rarityColor
	end
	
	-- Show equipped indicator if this weapon is equipped
	local isEquipped = (equippedWeaponUid == uid)
	if equippedIndicator then
		equippedIndicator.BackgroundTransparency = isEquipped and 0.7 or 1
	end
	if equippedBadge then
		equippedBadge.BackgroundTransparency = isEquipped and 0 or 1
		equippedBadge.TextTransparency = isEquipped and 0 or 1
	end
end

function InventoryWindow.build(playerGui: PlayerGui)
	-- Clean up existing
	local existing = playerGui:FindFirstChild("InventoryWindowGui")
	if existing then existing:Destroy() end
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryWindowGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false -- Hidden by default
	screenGui.Parent = playerGui
	
	-- Main window frame (centered)
	local numRows = math.ceil(MAX_SLOTS / SLOTS_PER_ROW)
	local windowWidth = (SLOT_SIZE * SLOTS_PER_ROW) + 60
	local windowHeight = math.min((SLOT_SIZE * numRows) + 100, 600) -- Cap height, will scroll
	
	windowFrame = Instance.new("Frame")
	windowFrame.Name = "Window"
	windowFrame.Size = UDim2.new(0, windowWidth, 0, windowHeight)
	windowFrame.Position = UDim2.new(0.5, -windowWidth/2, 0.5, -windowHeight/2)
	windowFrame.BackgroundColor3 = COLORS.bgDark
	windowFrame.BackgroundTransparency = 0.1
	windowFrame.BorderSizePixel = 0
	windowFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = windowFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.border
	stroke.Thickness = 3
	stroke.Parent = windowFrame
	
	UIHelper.addShadow(windowFrame)
	
	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = COLORS.bgDark
	titleBar.BackgroundTransparency = 0.5
	titleBar.BorderSizePixel = 0
	titleBar.Parent = windowFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Inventory"
	titleLabel.TextColor3 = COLORS.text
	titleLabel.TextSize = 20
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -35, 0.5, -15)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "×"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextSize = 24
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		InventoryWindow.hide()
	end)
	
	-- Scrolling frame for weapons
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -70)
	scrollFrame.Position = UDim2.new(0, 10, 0, 50)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = COLORS.accent
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be set by UIGridLayout
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = windowFrame
	
	-- Weapons container (grid) inside scroll frame
	weaponsContainer = Instance.new("Frame")
	weaponsContainer.Name = "WeaponsContainer"
	weaponsContainer.Size = UDim2.new(1, -10, 0, 0) -- Height auto from layout
	weaponsContainer.BackgroundTransparency = 1
	weaponsContainer.AutomaticSize = Enum.AutomaticSize.Y
	weaponsContainer.Parent = scrollFrame
	
	-- Grid layout
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = weaponsContainer
	
	-- Create weapon slots
	for i = 1, MAX_SLOTS do
		local slot = createWeaponSlot(i, weaponsContainer)
		slot.LayoutOrder = i
	end
	
	-- Slot counter
	local counterLabel = Instance.new("TextLabel")
	counterLabel.Name = "Counter"
	counterLabel.Size = UDim2.new(1, -20, 0, 20)
	counterLabel.Position = UDim2.new(0, 10, 1, -25)
	counterLabel.BackgroundTransparency = 1
	counterLabel.Text = "0 / 10"
	counterLabel.TextColor3 = COLORS.textDim
	counterLabel.TextSize = 14
	counterLabel.Font = Enum.Font.GothamBold
	counterLabel.TextXAlignment = Enum.TextXAlignment.Center
	counterLabel.Parent = windowFrame
	
	-- Connect to weapon events
	InventoryWindow.connectEvents()
	
	print("[InventoryWindow] UI built")
end

function InventoryWindow.refresh(state: any)
	currentState = state
	if not weaponsContainer then return end
	
	-- Clear all slots
	for _, slot in weaponsContainer:GetChildren() do
		if slot:IsA("TextButton") and slot.Name:match("^WeaponSlot_") then
			clearSlot(slot)
		end
	end
	
	-- Get weapons from state
	local weapons = {}
	if state and state.weapons then
		for _, w in state.weapons do
			if type(w) == "table" and w.weaponId then
				table.insert(weapons, {
					weaponId = w.weaponId,
					uid = w.uid,
					rarity = w.rarity
				})
			end
		end
	end
	
	-- Fill slots with weapons (max 10)
	local slots = {}
	for _, slot in weaponsContainer:GetChildren() do
		if slot:IsA("TextButton") and slot.Name:match("^WeaponSlot_") then
			table.insert(slots, slot)
		end
	end
	
	table.sort(slots, function(a, b)
		return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
	end)
	
	for i = 1, math.min(#weapons, MAX_SLOTS) do
		local w = weapons[i]
		if slots[i] then
			fillSlot(slots[i], w.weaponId, w.uid, w.rarity)
		end
	end
	
	-- Update counter
	local counter = windowFrame and windowFrame:FindFirstChild("Counter") :: TextLabel?
	if counter then
		counter.Text = string.format("%d / %d", #weapons, MAX_SLOTS)
		if #weapons >= MAX_SLOTS then
			counter.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red when full
		else
			counter.TextColor3 = COLORS.textDim
		end
	end
end

function InventoryWindow.show()
	if screenGui then
		screenGui.Enabled = true
		if windowFrame then
			local numRows = math.ceil(MAX_SLOTS / SLOTS_PER_ROW)
			local targetWidth = (SLOT_SIZE * SLOTS_PER_ROW) + 60
			local targetHeight = math.min((SLOT_SIZE * numRows) + 100, 600)
			
			windowFrame.Size = UDim2.new(0, 0, 0, 0)
			TweenService:Create(windowFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, targetWidth, 0, targetHeight)
			}):Play()
		end
	end
end

function InventoryWindow.hide()
	if screenGui then
		if windowFrame then
			TweenService:Create(windowFrame, TweenInfo.new(0.2), {
				Size = UDim2.new(0, 0, 0, 0)
			}):Play()
			task.wait(0.2)
		end
		screenGui.Enabled = false
	end
end

function InventoryWindow.isVisible(): boolean
	return screenGui and screenGui.Enabled or false
end

-- Update equipped weapon state and refresh visuals
function InventoryWindow.setEquippedWeapon(weaponUid: string?)
	equippedWeaponUid = weaponUid
	
	-- Update all slot visuals
	if weaponsContainer then
		for _, slot in weaponsContainer:GetChildren() do
			if slot:IsA("TextButton") and slot.Name:match("^WeaponSlot_") then
				local uid = slot:GetAttribute("WeaponUid")
				local isEquipped = (uid and uid ~= "" and uid == equippedWeaponUid)
				
				local equippedIndicator = slot:FindFirstChild("EquippedIndicator") :: Frame?
				local equippedBadge = slot:FindFirstChild("EquippedBadge") :: TextLabel?
				
				if equippedIndicator then
					TweenService:Create(equippedIndicator, TweenInfo.new(0.2), {
						BackgroundTransparency = isEquipped and 0.7 or 1
					}):Play()
				end
				if equippedBadge then
					TweenService:Create(equippedBadge, TweenInfo.new(0.2), {
						BackgroundTransparency = isEquipped and 0 or 1,
						TextTransparency = isEquipped and 0 or 1
					}):Play()
				end
			end
		end
	end
end

function InventoryWindow.getEquippedWeaponUid(): string?
	return equippedWeaponUid
end

-- Connect to weapon equipped event
function InventoryWindow.connectEvents()
	ShopRemotes.weaponEquipped().OnClientEvent:Connect(function(data)
		if data and data.success then
			InventoryWindow.setEquippedWeapon(data.uid)
			print("[InventoryWindow] Weapon equipped:", data.weaponId or "none")
		end
	end)
end

return InventoryWindow
