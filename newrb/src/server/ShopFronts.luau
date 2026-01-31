--[[
	Creates the 3 physical shop squares in the world with ProximityPrompts.
	Each square opens a different shop when pressing E.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(script.Parent.Remotes)

local ShopFronts = {}

local SHOP_CONFIGS = {
	{
		name = "CrateShop",
		displayName = "🎁 CRATE SHOP",
		subtitle = "Buy Crates",
		color = Color3.fromRGB(0, 162, 255), -- Blue
		glowColor = Color3.fromRGB(100, 200, 255),
		remoteName = "OpenCrateShop",
	},
	{
		name = "SellShop", 
		displayName = "💰 SELL SHOP",
		subtitle = "Sell for Keys",
		color = Color3.fromRGB(255, 215, 0), -- Gold
		glowColor = Color3.fromRGB(255, 255, 100),
		remoteName = "OpenSellShop",
	},
	{
		name = "UpgradesShop",
		displayName = "⚡ UPGRADES",
		subtitle = "Spend XP",
		color = Color3.fromRGB(150, 50, 255), -- Purple
		glowColor = Color3.fromRGB(200, 100, 255),
		remoteName = "OpenUpgradesShop",
	},
}

local function createShopSquare(config)
	local position = Config.ShopPositions[config.name]
	local size = Config.ShopSquareSize
	
	local model = Instance.new("Model")
	model.Name = config.name
	
	-- Main platform/square
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = size
	platform.Position = position
	platform.Anchored = true
	platform.CanCollide = true
	platform.Color = config.color
	platform.Material = Enum.Material.Neon
	platform.Transparency = 0.3
	platform.Parent = model
	
	-- Glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = config.glowColor
	pointLight.Brightness = 5
	pointLight.Range = 40
	pointLight.Parent = platform
	
	-- BIG Floating sign above
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(size.X + 4, 5, 0.5) -- Much bigger sign
	sign.Position = position + Vector3.new(0, size.Y + 5, 0) -- Higher up
	sign.Anchored = true
	sign.CanCollide = false
	sign.Color = config.color
	sign.Material = Enum.Material.Neon
	sign.Parent = model
	
	-- Strong sign glow
	local signLight = Instance.new("PointLight")
	signLight.Color = config.glowColor
	signLight.Brightness = 4
	signLight.Range = 30
	signLight.Parent = sign
	
	-- Sign text (front)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 50
	signGui.Parent = sign
	
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 0.65, 0)
	signText.Position = UDim2.new(0, 0, 0.05, 0)
	signText.BackgroundTransparency = 1
	signText.Text = config.displayName
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBlack
	signText.TextStrokeTransparency = 0.3
	signText.TextStrokeColor3 = Color3.new(0, 0, 0)
	signText.Parent = signGui
	
	local subText = Instance.new("TextLabel")
	subText.Size = UDim2.new(1, 0, 0.3, 0)
	subText.Position = UDim2.new(0, 0, 0.68, 0)
	subText.BackgroundTransparency = 1
	subText.Text = "[ Press E to " .. config.subtitle .. " ]"
	subText.TextColor3 = Color3.fromRGB(255, 255, 200)
	subText.TextScaled = true
	subText.Font = Enum.Font.GothamBold
	subText.TextStrokeTransparency = 0.5
	subText.TextStrokeColor3 = Color3.new(0, 0, 0)
	subText.Parent = signGui
	
	-- Sign text (back)
	local signGuiBack = Instance.new("SurfaceGui")
	signGuiBack.Face = Enum.NormalId.Back
	signGuiBack.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGuiBack.PixelsPerStud = 50
	signGuiBack.Parent = sign
	
	local signTextBack = signText:Clone()
	signTextBack.Parent = signGuiBack
	
	local subTextBack = subText:Clone()
	subTextBack.Parent = signGuiBack
	
	-- Add floating billboard above for even more visibility
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FloatingLabel"
	billboard.Size = UDim2.new(0, 300, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = platform
	
	local billboardText = Instance.new("TextLabel")
	billboardText.Size = UDim2.new(1, 0, 1, 0)
	billboardText.BackgroundTransparency = 1
	billboardText.Text = config.displayName
	billboardText.TextColor3 = config.color
	billboardText.TextSize = 36
	billboardText.Font = Enum.Font.GothamBlack
	billboardText.TextStrokeTransparency = 0
	billboardText.TextStrokeColor3 = Color3.new(0, 0, 0)
	billboardText.Parent = billboard
	
	-- ProximityPrompt for E interaction
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Open " .. config.subtitle
	prompt.ObjectText = config.displayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = platform
	
	-- Connect to remote
	prompt.Triggered:Connect(function(player: Player)
		local folder = Remotes.getFolder()
		local ev = folder:FindFirstChild(config.remoteName)
		if ev and ev:IsA("RemoteEvent") then
			(ev :: RemoteEvent):FireClient(player)
			print("[ShopFronts]", player.Name, "opened", config.name)
		end
	end)
	
	model.Parent = workspace
	return model
end

function ShopFronts.create()
	local shops = {}
	
	for _, config in SHOP_CONFIGS do
		local shop = createShopSquare(config)
		shops[config.name] = shop
		print("[ShopFronts] Created", config.name, "at", Config.ShopPositions[config.name])
	end
	
	print("[ShopFronts] All 3 shop squares created!")
	return shops
end

return ShopFronts
