--[[
	Modern Roblox game-style UI helpers with gradients, shadows, and animations.
	Redesigned for cleaner, more professional look.
]]

local TweenService = game:GetService("TweenService")

local UIHelper = {}

local CORNER_RADIUS = 16
local CARD_CORNER = 12

-- Modern color palette
local COLORS = {
	-- Backgrounds
	bgDark = Color3.fromRGB(15, 15, 25),
	bgMedium = Color3.fromRGB(25, 25, 40),
	bgLight = Color3.fromRGB(35, 35, 55),
	bgCard = Color3.fromRGB(40, 40, 60),
	bgCardHover = Color3.fromRGB(50, 50, 75),
	
	-- Accents
	accent = Color3.fromRGB(0, 170, 255),
	accentDark = Color3.fromRGB(0, 130, 200),
	success = Color3.fromRGB(50, 205, 100),
	successDark = Color3.fromRGB(40, 165, 80),
	warning = Color3.fromRGB(255, 180, 0),
	danger = Color3.fromRGB(255, 70, 70),
	purple = Color3.fromRGB(140, 80, 255),
	purpleDark = Color3.fromRGB(110, 60, 200),
	gold = Color3.fromRGB(255, 200, 50),
	
	-- Text
	text = Color3.fromRGB(255, 255, 255),
	textDim = Color3.fromRGB(150, 150, 170),
	textMuted = Color3.fromRGB(100, 100, 120),
	
	-- States
	locked = Color3.fromRGB(60, 60, 75),
	disabled = Color3.fromRGB(80, 80, 95),
	
	-- Borders
	border = Color3.fromRGB(70, 70, 90),
	borderLight = Color3.fromRGB(100, 100, 120),
}

function UIHelper.colors()
	return COLORS
end

-- Add drop shadow effect
function UIHelper.addShadow(parent: GuiObject, offset: number?, transparency: number?)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://5554236805" -- Soft shadow image
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = transparency or 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(23, 23, 277, 277)
	shadow.Size = UDim2.new(1, (offset or 20) * 2, 1, (offset or 20) * 2)
	shadow.Position = UDim2.new(0, -(offset or 20), 0, -(offset or 20))
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

-- Modern frame with gradient background
function UIHelper.frame(name: string, size: UDim2?, parent: Instance?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size or UDim2.fromScale(1, 1)
	f.BackgroundColor3 = COLORS.bgDark
	f.BorderSizePixel = 0
	f.ClipsDescendants = true
	if parent then f.Parent = parent end
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
	corner.Parent = f
	
	-- Gradient overlay
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 220)),
	})
	gradient.Rotation = 135
	gradient.Parent = f
	
	-- Border stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 80)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = f
	
	return f
end

function UIHelper.padding(parent: Instance, top: number?, right: number?, bottom: number?, left: number?): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, top or 20)
	p.PaddingRight = UDim.new(0, right or top or 20)
	p.PaddingBottom = UDim.new(0, bottom or top or 20)
	p.PaddingLeft = UDim.new(0, left or right or top or 20)
	p.Parent = parent
	return p
end

function UIHelper.label(text: string, size: UDim2?, parent: Instance?): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size or UDim2.new(1, 0, 0, 24)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = COLORS.text
	l.TextSize = 16
	l.Font = Enum.Font.GothamMedium
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextWrapped = true
	if parent then l.Parent = parent end
	return l
end

function UIHelper.title(text: string, parent: Instance?): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 40)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = COLORS.text
	l.TextSize = 28
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Center
	if parent then l.Parent = parent end
	return l
end

-- Modern button with hover effects
function UIHelper.button(label: string, onClick: () -> (), parent: Instance?, color: Color3?): TextButton
	local btnColor = color or COLORS.accent
	
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 120, 0, 44)
	b.BackgroundColor3 = btnColor
	b.Text = label
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 16
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	if parent then b.Parent = parent end
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = b
	
	-- Gradient for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180)),
	})
	gradient.Rotation = 90
	gradient.Parent = b
	
	-- Hover/click effects
	local isHovering = false
	
	b.MouseEnter:Connect(function()
		isHovering = true
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.new(
				math.min(1, btnColor.R * 1.15),
				math.min(1, btnColor.G * 1.15),
				math.min(1, btnColor.B * 1.15)
			)
		}):Play()
	end)
	
	b.MouseLeave:Connect(function()
		isHovering = false
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = btnColor
		}):Play()
	end)
	
	b.MouseButton1Click:Connect(function()
		-- Press effect
		TweenService:Create(b, TweenInfo.new(0.05), {
			Size = UDim2.new(b.Size.X.Scale, b.Size.X.Offset - 4, b.Size.Y.Scale, b.Size.Y.Offset - 2)
		}):Play()
		task.wait(0.05)
		TweenService:Create(b, TweenInfo.new(0.1), {
			Size = UDim2.new(b.Size.X.Scale, b.Size.X.Offset + 4, b.Size.Y.Scale, b.Size.Y.Offset + 2)
		}):Play()
		onClick()
	end)
	
	return b
end

-- Card container for items
function UIHelper.card(parent: Instance?, height: number?): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, height or 100)
	f.BackgroundColor3 = COLORS.bgCard
	f.BorderSizePixel = 0
	if parent then f.Parent = parent end
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CARD_CORNER)
	corner.Parent = f
	
	-- Subtle border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 70, 90)
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	stroke.Parent = f
	
	-- Hover effect
	f.MouseEnter:Connect(function()
		TweenService:Create(f, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.bgCardHover
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {
			Transparency = 0.3
		}):Play()
	end)
	
	f.MouseLeave:Connect(function()
		TweenService:Create(f, TweenInfo.new(0.2), {
			BackgroundColor3 = COLORS.bgCard
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {
			Transparency = 0.7
		}):Play()
	end)
	
	return f
end

-- Scrolling frame
function UIHelper.scroll(parent: Instance?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Size = UDim2.new(1, 0, 1, 0)
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = COLORS.accent
	s.ScrollBarImageTransparency = 0.3
	s.CanvasSize = UDim2.new(0, 0, 0, 0)
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	if parent then s.Parent = parent end
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = s
	
	return s
end

-- Currency display badge
function UIHelper.currencyBadge(icon: string, amount: number, color: Color3?, parent: Instance?): Frame
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 140, 0, 40)
	badge.BackgroundColor3 = COLORS.bgLight
	badge.BorderSizePixel = 0
	if parent then badge.Parent = parent end
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = badge
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.gold
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = badge
	
	local label = Instance.new("TextLabel")
	label.Name = "Amount"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = icon .. " " .. tostring(amount)
	label.TextColor3 = color or COLORS.gold
	label.TextSize = 20
	label.Font = Enum.Font.GothamBold
	label.Parent = badge
	
	return badge
end

-- Close button (X)
function UIHelper.closeButton(parent: Instance, onClose: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "CloseButton"
	btn.Size = UDim2.new(0, 36, 0, 36)
	btn.Position = UDim2.new(1, -15, 0, 15)
	btn.AnchorPoint = Vector2.new(1, 0)
	btn.BackgroundColor3 = COLORS.danger
	btn.Text = "✕"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 18
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = btn
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(255, 100, 100)
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = COLORS.danger
		}):Play()
	end)
	
	btn.MouseButton1Click:Connect(onClose)
	
	return btn
end

-- Section header
function UIHelper.sectionHeader(text: string, icon: string?, color: Color3?, parent: Instance?): Frame
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 35)
	header.BackgroundTransparency = 1
	if parent then header.Parent = parent end
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = (icon or "") .. " " .. text
	label.TextColor3 = color or COLORS.accent
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = header
	
	return header
end

-- Divider line
function UIHelper.divider(parent: Instance?): Frame
	local div = Instance.new("Frame")
	div.Size = UDim2.new(1, -20, 0, 1)
	div.BackgroundColor3 = COLORS.bgLight
	div.BorderSizePixel = 0
	if parent then div.Parent = parent end
	return div
end

-- Fade in animation
function UIHelper.fadeIn(obj: GuiObject, duration: number?)
	obj.BackgroundTransparency = 1
	
	for _, child in obj:GetDescendants() do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child.TextTransparency = 1
		elseif child:IsA("Frame") then
			child.BackgroundTransparency = 1
		elseif child:IsA("ImageLabel") then
			child.ImageTransparency = 1
		end
	end
	
	TweenService:Create(obj, TweenInfo.new(duration or 0.25), {
		BackgroundTransparency = 0
	}):Play()
	
	for _, child in obj:GetDescendants() do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(duration or 0.25), {
				TextTransparency = 0
			}):Play()
		elseif child:IsA("Frame") and child.BackgroundTransparency < 1 then
			TweenService:Create(child, TweenInfo.new(duration or 0.25), {
				BackgroundTransparency = 0
			}):Play()
		elseif child:IsA("ImageLabel") then
			TweenService:Create(child, TweenInfo.new(duration or 0.25), {
				ImageTransparency = child:GetAttribute("TargetTransparency") or 0
			}):Play()
		end
	end
end

-- Pulse animation for updates
function UIHelper.pulse(obj: GuiObject)
	local originalSize = obj.Size
	TweenService:Create(obj, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(originalSize.X.Scale * 1.1, originalSize.X.Offset, originalSize.Y.Scale * 1.1, originalSize.Y.Offset)
	}):Play()
	task.delay(0.1, function()
		TweenService:Create(obj, TweenInfo.new(0.15, Enum.EasingStyle.Elastic), {
			Size = originalSize
		}):Play()
	end)
end

-- Rarity tag badge
function UIHelper.rarityBadge(rarity: string, color: Color3, parent: Instance?): Frame
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 90, 0, 24)
	badge.BackgroundColor3 = color
	badge.BorderSizePixel = 0
	if parent then badge.Parent = parent end
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = badge
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = rarity
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Parent = badge
	
	-- Subtle gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180)),
	})
	gradient.Rotation = 90
	gradient.Parent = badge
	
	return badge
end

return UIHelper
