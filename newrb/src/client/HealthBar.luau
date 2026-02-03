--[[
	HealthBar UI Module
	Displays a pixel art style health bar at the bottom right of the screen.
	Health bar fills/drains based on current HP percentage.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HealthBar = {}

local screenGui: ScreenGui?
local healthFill: Frame?
local healthText: TextLabel?
local currentHealth = 100
local maxHealth = 100

-- Colors
local COLORS = {
	frameDark = Color3.fromRGB(30, 20, 40),      -- Dark purple/black for frame
	frameAccent = Color3.fromRGB(60, 40, 80),    -- Slightly lighter purple accent
	healthFull = Color3.fromRGB(220, 50, 50),    -- Bright red when healthy
	healthLow = Color3.fromRGB(180, 30, 30),     -- Darker red when low
	healthCritical = Color3.fromRGB(255, 80, 80), -- Flashing red when critical
	heart = Color3.fromRGB(200, 40, 60),         -- Heart icon color
	textWhite = Color3.fromRGB(255, 255, 255),
	textShadow = Color3.fromRGB(20, 10, 30),
}

-- Create a pixel-style border piece
local function createBorderPiece(name: string, size: UDim2, position: UDim2, color: Color3, parent: Instance): Frame
	local piece = Instance.new("Frame")
	piece.Name = name
	piece.Size = size
	piece.Position = position
	piece.BackgroundColor3 = color
	piece.BorderSizePixel = 0
	piece.Parent = parent
	return piece
end

-- Create heart icon (simple pixel heart, scaled down)
local function createHeart(name: string, position: UDim2, parent: Instance): Frame
	local heart = Instance.new("Frame")
	heart.Name = name
	heart.Size = UDim2.new(0, 15, 0, 13)
	heart.Position = position
	heart.BackgroundTransparency = 1
	heart.Parent = parent
	
	-- Pixel heart shape (simplified)
	local pixels = {
		{x=6, y=0, w=3, h=3}, {x=11, y=0, w=3, h=3},  -- Top bumps
		{x=3, y=3, w=14, h=3},                         -- Upper middle
		{x=3, y=6, w=14, h=3},                         -- Middle
		{x=6, y=9, w=8, h=3},                          -- Lower middle
		{x=8, y=12, w=4, h=3},                         -- Bottom point
		{x=9, y=15, w=2, h=2},                         -- Very bottom
	}
	
	for i, p in pixels do
		local px = Instance.new("Frame")
		px.Name = "Pixel" .. i
		px.Size = UDim2.new(0, p.w, 0, p.h)
		px.Position = UDim2.new(0, p.x, 0, p.y)
		px.BackgroundColor3 = COLORS.heart
		px.BorderSizePixel = 0
		px.Parent = heart
	end
	
	return heart
end

function HealthBar.build(playerGui: PlayerGui)
	-- Clean up existing
	local existing = playerGui:FindFirstChild("HealthBarGui")
	if existing then existing:Destroy() end
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HealthBarGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Main container - all the way top right (smaller)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 240, 0, 45)
	container.Position = UDim2.new(1, -250, 0, 5)
	container.BackgroundTransparency = 1
	container.Parent = screenGui
	
	-- Outer frame (dark border)
	local outerFrame = Instance.new("Frame")
	outerFrame.Name = "OuterFrame"
	outerFrame.Size = UDim2.new(1, 0, 1, 0)
	outerFrame.Position = UDim2.new(0, 0, 0, 0)
	outerFrame.BackgroundColor3 = COLORS.frameDark
	outerFrame.BorderSizePixel = 0
	outerFrame.Parent = container
	
	-- Create jagged/ornate edge effect with multiple border pieces (scaled down)
	-- Top edge decorations
	for i = 0, 6 do
		local spike = createBorderPiece(
			"TopSpike" .. i,
			UDim2.new(0, 6, 0, 4),
			UDim2.new(0, 15 + i * 35, 0, -3),
			COLORS.frameDark,
			outerFrame
		)
	end
	
	-- Bottom edge decorations
	for i = 0, 6 do
		local spike = createBorderPiece(
			"BottomSpike" .. i,
			UDim2.new(0, 6, 0, 4),
			UDim2.new(0, 15 + i * 35, 1, -1),
			COLORS.frameDark,
			outerFrame
		)
	end
	
	-- Left decorative piece (scaled down)
	local leftDeco = createBorderPiece("LeftDeco", UDim2.new(0, 8, 0, 30), UDim2.new(0, -6, 0.5, -15), COLORS.frameDark, outerFrame)
	
	-- Right decorative piece (scaled down)
	local rightDeco = createBorderPiece("RightDeco", UDim2.new(0, 8, 0, 30), UDim2.new(1, -2, 0.5, -15), COLORS.frameDark, outerFrame)
	
	-- Inner accent border
	local accentBorder = Instance.new("Frame")
	accentBorder.Name = "AccentBorder"
	accentBorder.Size = UDim2.new(1, -12, 1, -12)
	accentBorder.Position = UDim2.new(0, 6, 0, 6)
	accentBorder.BackgroundColor3 = COLORS.frameAccent
	accentBorder.BorderSizePixel = 0
	accentBorder.Parent = outerFrame
	
	-- Health bar background (dark)
	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBackground"
	healthBg.Size = UDim2.new(1, -16, 1, -16)
	healthBg.Position = UDim2.new(0, 8, 0, 8)
	healthBg.BackgroundColor3 = Color3.fromRGB(40, 20, 30)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = accentBorder
	
	-- Health fill bar (the red part that shrinks/grows)
	healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.Position = UDim2.new(0, 0, 0, 0)
	healthFill.BackgroundColor3 = COLORS.healthFull
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBg
	
	-- Gradient overlay for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.new(0.9, 0.9, 0.9)),
		ColorSequenceKeypoint.new(1, Color3.new(0.7, 0.7, 0.7)),
	})
	gradient.Rotation = 90
	gradient.Parent = healthFill
	
	-- Shine effect on top
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.new(1, 0, 0.3, 0)
	shine.Position = UDim2.new(0, 0, 0, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.7
	shine.BorderSizePixel = 0
	shine.Parent = healthFill
	
	-- Hearts on ends (scaled down)
	createHeart("LeftHeart", UDim2.new(0, -3, 0.5, -7), outerFrame)
	createHeart("RightHeart", UDim2.new(1, -12, 0.5, -7), outerFrame)
	
	-- Health text (centered, smaller)
	healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.Position = UDim2.new(0, 0, 0, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = "100 / 100"
	healthText.TextColor3 = COLORS.textWhite
	healthText.TextSize = 14
	healthText.Font = Enum.Font.GothamBold
	healthText.TextStrokeColor3 = COLORS.textShadow
	healthText.TextStrokeTransparency = 0.3
	healthText.Parent = healthBg
	
	print("[HealthBar] UI built")
end

-- Update the health bar display
function HealthBar.update(newHealth: number, newMaxHealth: number)
	currentHealth = newHealth
	maxHealth = newMaxHealth
	
	if not healthFill or not healthText then return end
	
	local percent = math.clamp(currentHealth / maxHealth, 0, 1)
	
	-- Tween the health bar width
	local tween = TweenService:Create(
		healthFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(percent, 0, 1, 0) }
	)
	tween:Play()
	
	-- Update color based on health percentage
	local healthColor = COLORS.healthFull
	if percent <= 0.25 then
		healthColor = COLORS.healthCritical
	elseif percent <= 0.5 then
		healthColor = COLORS.healthLow
	end
	
	local colorTween = TweenService:Create(
		healthFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundColor3 = healthColor }
	)
	colorTween:Play()
	
	-- Update text
	healthText.Text = string.format("%d / %d", math.floor(currentHealth), math.floor(maxHealth))
	
	-- Flash effect when taking damage (low health)
	if percent <= 0.25 and currentHealth > 0 then
		task.spawn(function()
			for _ = 1, 3 do
				healthFill.BackgroundTransparency = 0.3
				task.wait(0.1)
				healthFill.BackgroundTransparency = 0
				task.wait(0.1)
			end
		end)
	end
end

-- Set health directly (for initial load)
function HealthBar.setHealth(health: number, max: number)
	currentHealth = health
	maxHealth = max
	
	if healthFill and healthText then
		local percent = math.clamp(currentHealth / maxHealth, 0, 1)
		healthFill.Size = UDim2.new(percent, 0, 1, 0)
		healthText.Text = string.format("%d / %d", math.floor(currentHealth), math.floor(maxHealth))
	end
end

-- Get current health values
function HealthBar.getHealth(): (number, number)
	return currentHealth, maxHealth
end

-- Show/hide
function HealthBar.show()
	if screenGui then
		screenGui.Enabled = true
	end
end

function HealthBar.hide()
	if screenGui then
		screenGui.Enabled = false
	end
end

return HealthBar
