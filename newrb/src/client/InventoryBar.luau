--[[
	Inventory Bar: Bottom screen inventory showing crates and weapons (max 10 slots)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIHelper = require(script.Parent.UIHelper)

local COLORS = UIHelper.colors()
local MAX_SLOTS = 10
local SLOT_SIZE = 60
local SLOT_PADDING = 6

local InventoryBar = {}
local screenGui: ScreenGui?
local barFrame: Frame?
local slots: {Frame} = {}
local currentState: any = nil

-- Reference to CrateOpener for checking pending weapons
local CrateOpener: any = nil

-- Callback when an item is clicked
local onItemClick: ((itemType: string, itemId: string) -> ())?

local function createSlot(index: number, parent: Frame): Frame
	local slot = Instance.new("Frame")
	slot.Name = "Slot_" .. index
	slot.LayoutOrder = index -- Important for UIListLayout ordering
	slot.Size = UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE)
	slot.BackgroundColor3 = COLORS.bgDark
	slot.BackgroundTransparency = 0.3
	slot.BorderSizePixel = 0
	slot.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = slot
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.border
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = slot
	
	-- Icon label
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, 0, 1, -18)
	icon.Position = UDim2.new(0, 0, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = ""
	icon.TextSize = 28
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = COLORS.text
	icon.Parent = slot
	
	-- Count label
	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.Size = UDim2.new(1, -4, 0, 16)
	count.Position = UDim2.new(0, 2, 1, -18)
	count.BackgroundTransparency = 1
	count.Text = ""
	count.TextSize = 12
	count.Font = Enum.Font.GothamBold
	count.TextColor3 = COLORS.textDim
	count.Parent = slot
	
	-- Rarity stripe (for weapons)
	local rarityStripe = Instance.new("Frame")
	rarityStripe.Name = "RarityStripe"
	rarityStripe.Size = UDim2.new(1, 0, 0, 4)
	rarityStripe.Position = UDim2.new(0, 0, 0, 0)
	rarityStripe.BackgroundColor3 = Color3.new(1, 1, 1)
	rarityStripe.BackgroundTransparency = 1
	rarityStripe.BorderSizePixel = 0
	rarityStripe.Parent = slot
	
	local stripeCorner = Instance.new("UICorner")
	stripeCorner.CornerRadius = UDim.new(0, 10)
	stripeCorner.Parent = rarityStripe
	
	-- Click detection
	local button = Instance.new("TextButton")
	button.Name = "ClickArea"
	button.Size = UDim2.fromScale(1, 1)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = slot
	
	-- Store item data on the slot
	slot:SetAttribute("ItemType", "")
	slot:SetAttribute("ItemId", "")
	slot:SetAttribute("ItemUid", "")
	
	button.MouseButton1Click:Connect(function()
		local itemType = slot:GetAttribute("ItemType")
		local itemId = slot:GetAttribute("ItemId")
		local itemUid = slot:GetAttribute("ItemUid")
		if itemType ~= "" and itemId ~= "" and onItemClick then
			onItemClick(itemType, itemId, itemUid)
		end
	end)
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		if slot:GetAttribute("ItemType") ~= "" then
			TweenService:Create(slot, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.1), {Transparency = 0}):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(slot, TweenInfo.new(0.1), {BackgroundTransparency = 0.3}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.1), {Transparency = 0.5}):Play()
	end)
	
	return slot
end

local function clearSlot(slot: Frame)
	slot:SetAttribute("ItemType", "")
	slot:SetAttribute("ItemId", "")
	
	local icon = slot:FindFirstChild("Icon") :: TextLabel?
	local count = slot:FindFirstChild("Count") :: TextLabel?
	local stripe = slot:FindFirstChild("RarityStripe") :: Frame?
	local stroke = slot:FindFirstChildOfClass("UIStroke")
	
	if icon then icon.Text = "" end
	if count then count.Text = "" end
	if stripe then stripe.BackgroundTransparency = 1 end
	if stroke then stroke.Color = COLORS.border end
end

local function fillSlot(slot: Frame, itemType: string, itemId: string, itemCount: number, rarity: string?, uid: string?)
	slot:SetAttribute("ItemType", itemType)
	slot:SetAttribute("ItemId", itemId)
	slot:SetAttribute("ItemUid", uid or "")
	
	local icon = slot:FindFirstChild("Icon") :: TextLabel?
	local nameLabel = slot:FindFirstChild("Count") :: TextLabel?
	local stripe = slot:FindFirstChild("RarityStripe") :: Frame?
	local stroke = slot:FindFirstChildOfClass("UIStroke")
	
	if itemType == "weapon" then
		local weaponDef = Config.Weapons[itemId]
		local weaponRarity = rarity or (weaponDef and weaponDef.rarity) or "Common"
		local rarityData = Config.Rarities[weaponRarity]
		local rarityColor = rarityData and rarityData.color or Color3.new(1, 1, 1)
		
		-- Show weapon icon based on rarity
		if icon then 
			icon.Text = "⚔️"
			icon.TextColor3 = rarityColor
		end
		
		-- Show weapon name
		if nameLabel then
			local name = weaponDef and weaponDef.name or itemId
			-- Truncate long names
			if #name > 8 then
				name = string.sub(name, 1, 7) .. ".."
			end
			nameLabel.Text = name
			nameLabel.TextColor3 = rarityColor
		end
		
		-- Show rarity stripe
		if stripe then 
			stripe.BackgroundTransparency = 0
			stripe.BackgroundColor3 = rarityColor
		end
		if stroke then stroke.Color = rarityColor end
	end
end

-- Update the inventory slot counter
local function updateSlotCount(count: number)
	if not barFrame then return end
	
	local counter = barFrame:FindFirstChild("SlotCounter") :: TextLabel?
	if counter then
		counter.Text = count .. "/" .. MAX_SLOTS
		if count >= MAX_SLOTS then
			counter.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red when full
		else
			counter.TextColor3 = COLORS.textDim
		end
	end
end

function InventoryBar.refresh(state: any)
	currentState = state
	if not barFrame then return end
	
	-- Clear all slots
	for _, slot in slots do
		clearSlot(slot)
	end
	
	-- Get pending weapon UIDs (weapons still being animated)
	local pendingUids: {[string]: boolean} = {}
	if CrateOpener then
		local pending = CrateOpener.getPendingWeaponUids()
		if pending then
			for _, uid in pending do
				pendingUids[uid] = true
			end
		end
	end
	
	-- Collect weapons only (crates open instantly now), excluding pending ones
	local weapons: {{uid: string, weaponId: string, rarity: string}} = {}
	
	if state.weapons then
		-- Weapons are stored as array of {uid, weaponId, rarity}
		if type(state.weapons) == "table" then
			for _, w in state.weapons do
				if type(w) == "table" and w.weaponId then
					-- Only show if not pending animation
					if not pendingUids[w.uid] then
						table.insert(weapons, w)
					end
				end
			end
		end
	end
	
	-- Fill slots with weapons (max 10)
	for i = 1, math.min(#weapons, MAX_SLOTS) do
		local w = weapons[i]
		fillSlot(slots[i], "weapon", w.weaponId, 1, w.rarity, w.uid)
	end
	
	-- Update slot count indicator (show total including pending for accuracy)
	local totalWeapons = 0
	if state.weapons then
		for _ in state.weapons do
			totalWeapons += 1
		end
	end
	updateSlotCount(totalWeapons)
end

function InventoryBar.build(parent: Instance): ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryBarGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = parent
	
	-- Main bar container
	local totalWidth = (SLOT_SIZE * MAX_SLOTS) + (SLOT_PADDING * (MAX_SLOTS + 1))
	
	barFrame = Instance.new("Frame")
	barFrame.Name = "InventoryBar"
	barFrame.Size = UDim2.new(0, totalWidth, 0, SLOT_SIZE + 20)
	barFrame.Position = UDim2.new(0.5, -totalWidth/2, 1, -SLOT_SIZE - 30)
	barFrame.BackgroundColor3 = COLORS.bgDark
	barFrame.BackgroundTransparency = 0.2
	barFrame.BorderSizePixel = 0
	barFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = barFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.border
	stroke.Thickness = 2
	stroke.Parent = barFrame
	
	-- Add shadow
	UIHelper.addShadow(barFrame)
	
	-- Slots container
	local slotsContainer = Instance.new("Frame")
	slotsContainer.Name = "Slots"
	slotsContainer.Size = UDim2.new(1, -SLOT_PADDING*2, 0, SLOT_SIZE)
	slotsContainer.Position = UDim2.new(0, SLOT_PADDING, 0.5, -SLOT_SIZE/2)
	slotsContainer.BackgroundTransparency = 1
	slotsContainer.Parent = barFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder -- Use LayoutOrder for proper slot ordering
	listLayout.Padding = UDim.new(0, SLOT_PADDING)
	listLayout.Parent = slotsContainer
	
	-- Create slots
	slots = {}
	for i = 1, MAX_SLOTS do
		local slot = createSlot(i, slotsContainer)
		table.insert(slots, slot)
	end
	
	-- Slot counter (shows X/10)
	local counter = Instance.new("TextLabel")
	counter.Name = "SlotCounter"
	counter.Size = UDim2.new(0, 60, 0, 20)
	counter.Position = UDim2.new(1, -65, 0, 3)
	counter.BackgroundTransparency = 1
	counter.Text = "0/" .. MAX_SLOTS
	counter.TextSize = 14
	counter.Font = Enum.Font.GothamBold
	counter.TextColor3 = COLORS.textDim
	counter.TextXAlignment = Enum.TextXAlignment.Right
	counter.Parent = barFrame
	
	return screenGui
end

function InventoryBar.setClickCallback(callback: (itemType: string, itemId: string, uid: string?) -> ())
	onItemClick = callback
end

function InventoryBar.setCrateOpener(opener: any)
	CrateOpener = opener
end

function InventoryBar.show()
	if screenGui then
		screenGui.Enabled = true
	end
end

function InventoryBar.hide()
	if screenGui then
		screenGui.Enabled = false
	end
end

function InventoryBar.getGui()
	return screenGui
end

return InventoryBar
