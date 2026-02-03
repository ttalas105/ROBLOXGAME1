--[[
	InventoryButton: Bag icon button on left side of screen
	Opens inventory window when clicked
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local InventoryButton = {}

local screenGui: ScreenGui?
local bagButton: TextButton?
local InventoryWindow: any = nil

-- Colors matching currency display style
local COLORS = {
	background = Color3.fromRGB(100, 150, 255), -- Bright blue
	border = Color3.new(0, 0, 0), -- Black border
	text = Color3.new(1, 1, 1), -- White text
}

function InventoryButton.build(playerGui: PlayerGui, inventoryWindowModule: any)
	-- Store reference to inventory window module
	InventoryWindow = inventoryWindowModule
	
	-- Clean up existing
	local existing = playerGui:FindFirstChild("InventoryButtonGui")
	if existing then existing:Destroy() end
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryButtonGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Bag button container - left side, middle
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 60, 0, 60)
	container.Position = UDim2.new(0, 20, 0.5, -30) -- Middle left
	container.BackgroundTransparency = 1
	container.Parent = screenGui
	
	-- Bag button (similar style to currency modules)
	bagButton = Instance.new("TextButton")
	bagButton.Name = "BagButton"
	bagButton.Size = UDim2.new(1, 0, 1, 0)
	bagButton.BackgroundColor3 = COLORS.background
	bagButton.BorderSizePixel = 2
	bagButton.BorderColor3 = COLORS.border
	bagButton.Text = "🎒"
	bagButton.TextColor3 = COLORS.text
	bagButton.TextSize = 36
	bagButton.Font = Enum.Font.GothamBold
	bagButton.Parent = container
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bagButton
	
	-- Hover effect
	bagButton.MouseEnter:Connect(function()
		TweenService:Create(bagButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(120, 170, 255)
		}):Play()
	end)
	
	bagButton.MouseLeave:Connect(function()
		TweenService:Create(bagButton, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.background
		}):Play()
	end)
	
	-- Click to open inventory
	bagButton.MouseButton1Click:Connect(function()
		if InventoryWindow then
			if InventoryWindow.isVisible() then
				InventoryWindow.hide()
			else
				InventoryWindow.show()
			end
		end
	end)
	
	print("[InventoryButton] UI built")
end

-- Check if player is in hub (not in any arena)
function InventoryButton.isInHub(player: Player): boolean
	local char = player.Character
	if not char then return false end
	
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	
	-- Check if character is inside Arena1 model
	local arena1 = Workspace:FindFirstChild("Arena1")
	if arena1 and arena1:IsA("Model") then
		local arenaOrigin = Vector3.new(2000, 0, 0) -- Arena1 origin
		local distance = (rootPart.Position - arenaOrigin).Magnitude
		if distance < 500 then -- Within arena bounds
			return false
		end
	end
	
	return true
end

-- Show/hide button
function InventoryButton.show()
	if screenGui then
		screenGui.Enabled = true
	end
end

function InventoryButton.hide()
	if screenGui then
		screenGui.Enabled = false
	end
end

return InventoryButton
