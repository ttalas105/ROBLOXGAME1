--[[
	CurrencyDisplay UI Module
	Displays Gems and Keys currency at middle right of screen.
	Only visible when player is in hub area, hidden in arenas.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local CurrencyDisplay = {}

local screenGui: ScreenGui?
local gemsLabel: TextLabel?
local keysLabel: TextLabel?
local currentGems = 0
local currentKeys = 0

-- Colors matching the image style
local COLORS = {
	background = Color3.fromRGB(100, 150, 255), -- Bright blue
	border = Color3.new(0, 0, 0), -- Black border
	text = Color3.new(1, 1, 1), -- White text
	plusButton = Color3.fromRGB(50, 200, 50), -- Green plus button
}

-- Format large numbers (e.g., 999999 -> "999K", 999999999 -> "999M")
local function formatCurrency(amount: number): string
	if amount >= 1000000000 then
		return string.format("%.1fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return tostring(amount)
	end
end

-- Create a currency module (Gems or Keys)
local function createCurrencyModule(name: string, icon: string, parent: Instance, yPosition: number): Frame
	local module = Instance.new("Frame")
	module.Name = name .. "Module"
	module.Size = UDim2.new(0, 200, 0, 50)
	module.Position = UDim2.new(1, -220, 0, yPosition)
	module.BackgroundColor3 = COLORS.background
	module.BorderSizePixel = 2
	module.BorderColor3 = COLORS.border
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = module
	module.Parent = parent
	
	-- Plus button (green circle with white plus)
	local plusButton = Instance.new("TextButton")
	plusButton.Name = "PlusButton"
	plusButton.Size = UDim2.new(0, 40, 0, 40)
	plusButton.Position = UDim2.new(0, 5, 0.5, -20)
	plusButton.BackgroundColor3 = COLORS.plusButton
	plusButton.BorderSizePixel = 0
	plusButton.Text = "+"
	plusButton.TextColor3 = Color3.new(1, 1, 1)
	plusButton.TextSize = 24
	plusButton.Font = Enum.Font.GothamBold
	plusButton.Parent = module
	
	local plusCorner = Instance.new("UICorner")
	plusCorner.CornerRadius = UDim.new(0, 20)
	plusCorner.Parent = plusButton
	
	-- Currency value label
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(1, -100, 1, 0)
	valueLabel.Position = UDim2.new(0, 50, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "0"
	valueLabel.TextColor3 = COLORS.text
	valueLabel.TextSize = 24
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.Parent = module
	
	-- Currency icon (right side)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 40, 0, 40)
	iconLabel.Position = UDim2.new(1, -50, 0.5, -20)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextSize = 32
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.Parent = module
	
	return module, valueLabel
end

function CurrencyDisplay.build(playerGui: PlayerGui)
	-- Clean up existing
	local existing = playerGui:FindFirstChild("CurrencyDisplayGui")
	if existing then existing:Destroy() end
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CurrencyDisplayGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 200, 0, 110)
	container.Position = UDim2.new(1, -220, 0.5, -55) -- Middle right
	container.BackgroundTransparency = 1
	container.Parent = screenGui
	
	-- Gems module (top)
	local gemsModule, gemsValue = createCurrencyModule("Gems", "💎", container, 0)
	gemsLabel = gemsValue
	
	-- Keys module (bottom)
	local keysModule, keysValue = createCurrencyModule("Keys", "🗝️", container, 60)
	keysLabel = keysValue
	
	print("[CurrencyDisplay] UI built")
end

-- Update currency values
function CurrencyDisplay.update(gems: number?, keys: number?)
	if gems ~= nil then
		currentGems = gems
		if gemsLabel then
			gemsLabel.Text = formatCurrency(gems)
		end
	end
	
	if keys ~= nil then
		currentKeys = keys
		if keysLabel then
			keysLabel.Text = formatCurrency(keys)
		end
	end
end

-- Check if player is in hub (not in any arena)
function CurrencyDisplay.isInHub(player: Player): boolean
	local char = player.Character
	if not char then return false end
	
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	
	-- Check if character is inside Arena1 model
	local arena1 = Workspace:FindFirstChild("Arena1")
	if arena1 and arena1:IsA("Model") then
		-- Check if rootPart is within Arena1's bounds
		local arenaOrigin = Vector3.new(2000, 0, 0) -- Arena1 origin
		local distance = (rootPart.Position - arenaOrigin).Magnitude
		if distance < 500 then -- Within arena bounds
			return false
		end
	end
	
	return true
end

-- Show currency display
function CurrencyDisplay.show()
	if screenGui then
		screenGui.Enabled = true
	end
end

-- Hide currency display
function CurrencyDisplay.hide()
	if screenGui then
		screenGui.Enabled = false
	end
end

-- Get current values
function CurrencyDisplay.getValues(): (number, number)
	return currentGems, currentKeys
end

return CurrencyDisplay
