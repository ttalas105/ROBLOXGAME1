--[[
	Crate Opening Animation - Spinning slot machine effect with epic reveal.
	Features scrolling weapons that slow down and land on the winner.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ShopRemotes = require(script.Parent.ShopRemotes)
local UIHelper = require(script.Parent.UIHelper)

local COLORS = UIHelper.colors()

local CrateOpener = {}

-- UI Elements
local screenGui: ScreenGui?
local spinOverlay: Frame?
local spinContainer: Frame?
local spinStrip: Frame?
local pointerArrow: Frame?
local resultOverlay: Frame?
local resultCard: Frame?
local weaponIcon: TextLabel?
local weaponName: TextLabel?
local rarityBadge: Frame?
local oddsLabel: TextLabel?
local continueBtn: TextButton?
local openingLabel: TextLabel?

-- State
local isOpening = false
local spinTween: Tween?
local spinTweenConnection: RBXScriptConnection?
local resultQueue: {{weaponId: string, odds: number, uid: string?, inventoryFull: boolean?}} = {}
local currentQueueIndex = 0
local pendingWeaponUids: {string} = {} -- Track weapons waiting for animation
local onWeaponRevealedCallback: (() -> ())? -- Called when a weapon is revealed

-- Forward declarations
local processNextInQueue: () -> ()

-- Constants
local CARD_WIDTH = 120
local CARD_HEIGHT = 140
local CARD_GAP = 10
local VISIBLE_CARDS = 7
local SPIN_CARDS = 40 -- Total cards in the spin strip

-- Sound effects
local tickSound: Sound?
local winSound: Sound?
local epicWinSound: Sound?
local tickConnection: RBXScriptConnection?

local function createSounds()
	-- Tick sound (plays during spin)
	tickSound = Instance.new("Sound")
	tickSound.Name = "TickSound"
	tickSound.SoundId = "rbxassetid://6042053626" -- Click/tick sound
	tickSound.Volume = 0.1
	tickSound.PlaybackSpeed = 1.2
	tickSound.Parent = SoundService
	
	-- Normal win sound
	winSound = Instance.new("Sound")
	winSound.Name = "WinSound"
	winSound.SoundId = "rbxassetid://6042053626" -- Ding sound
	winSound.Volume = 0.2
	winSound.PlaybackSpeed = 0.8
	winSound.Parent = SoundService
	
	-- Epic win sound (for rare+ items)
	epicWinSound = Instance.new("Sound")
	epicWinSound.Name = "EpicWinSound"
	epicWinSound.SoundId = "rbxassetid://5030141545" -- Fanfare/epic sound
	epicWinSound.Volume = 0.25
	epicWinSound.Parent = SoundService
end

local function playTickSound()
	if tickSound then
		tickSound:Play()
	end
end

local function playWinSound(rarity: string)
	-- Play epic sound for rare items
	local epicRarities = {Rare = true, Epic = true, Legendary = true, Mythic = true}
	if epicRarities[rarity] and epicWinSound then
		epicWinSound:Play()
	elseif winSound then
		winSound:Play()
	end
end

local function stopTickSounds()
	if tickConnection then
		tickConnection:Disconnect()
		tickConnection = nil
	end
end

local function getRarityColor(rarity: string): Color3
	local r = Config.Rarities[rarity]
	return r and r.color or COLORS.text
end

local function formatOdds(odds: number): string
	if odds >= 1000000 then
		return "1 in " .. string.format("%.1fM", odds / 1000000)
	elseif odds >= 1000 then
		return "1 in " .. string.format("%.1fK", odds / 1000)
	else
		return "1 in " .. tostring(odds)
	end
end

-- Get random weapons for the spin strip
local function getRandomWeapons(winningWeaponId: string, count: number): {string}
	local weapons = {}
	local allWeapons = {}
	
	for weaponId, _ in Config.Weapons do
		table.insert(allWeapons, weaponId)
	end
	
	-- Fill with random weapons, placing winner near the end
	local winnerPosition = count - 3 -- Winner lands 3rd from end
	
	for i = 1, count do
		if i == winnerPosition then
			table.insert(weapons, winningWeaponId)
		else
			local randomWeapon = allWeapons[math.random(1, #allWeapons)]
			table.insert(weapons, randomWeapon)
		end
	end
	
	return weapons
end

-- Create a weapon card for the spin strip
local function createSpinCard(weaponId: string, index: number): Frame
	local def = Config.Weapons[weaponId]
	if not def then return Instance.new("Frame") end
	
	local rarityColor = getRarityColor(def.rarity)
	local baseZIndex = 54 -- Above the strip
	
	local card = Instance.new("Frame")
	card.Name = "SpinCard_" .. index
	card.Size = UDim2.new(0, CARD_WIDTH, 0, CARD_HEIGHT)
	card.Position = UDim2.new(0, (index - 1) * (CARD_WIDTH + CARD_GAP), 0, 0)
	card.BackgroundColor3 = COLORS.bgCard
	card.BorderSizePixel = 0
	card.ZIndex = baseZIndex
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card
	
	-- Rarity border
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarityColor
	stroke.Thickness = 3
	stroke.Parent = card
	
	-- Top color bar
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 8)
	topBar.BackgroundColor3 = rarityColor
	topBar.BorderSizePixel = 0
	topBar.ZIndex = baseZIndex + 1
	topBar.Parent = card
	
	local topBarCorner = Instance.new("UICorner")
	topBarCorner.CornerRadius = UDim.new(0, 12)
	topBarCorner.Parent = topBar
	
	-- Fix bottom corners of top bar
	local topBarFix = Instance.new("Frame")
	topBarFix.Size = UDim2.new(1, 0, 0, 6)
	topBarFix.Position = UDim2.new(0, 0, 1, -6)
	topBarFix.BackgroundColor3 = rarityColor
	topBarFix.BorderSizePixel = 0
	topBarFix.ZIndex = baseZIndex + 1
	topBarFix.Parent = topBar
	
	-- Weapon icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 50)
	icon.Position = UDim2.new(0, 0, 0, 15)
	icon.BackgroundTransparency = 1
	icon.Text = "⚔️"
	icon.TextSize = 32
	icon.TextColor3 = rarityColor
	icon.ZIndex = baseZIndex + 1
	icon.Parent = card
	
	-- Weapon name
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -8, 0, 45)
	name.Position = UDim2.new(0, 4, 0, 60)
	name.BackgroundTransparency = 1
	name.Text = def.name
	name.TextColor3 = COLORS.text
	name.TextSize = 11
	name.Font = Enum.Font.GothamBold
	name.TextWrapped = true
	name.TextYAlignment = Enum.TextYAlignment.Top
	name.ZIndex = baseZIndex + 1
	name.Parent = card
	
	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 20)
	rarityLabel.Position = UDim2.new(0, 0, 1, -22)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = def.rarity
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextSize = 10
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.ZIndex = baseZIndex + 1
	rarityLabel.Parent = card
	
	return card
end

-- Build the spin strip with weapon cards
local function buildSpinStrip(winningWeaponId: string)
	if not spinStrip then 
		warn("[CrateOpener] spinStrip is nil!")
		return 
	end
	
	-- Clear existing cards
	for _, child in spinStrip:GetChildren() do
		child:Destroy()
	end
	
	local weapons = getRandomWeapons(winningWeaponId, SPIN_CARDS)
	
	for i, weaponId in weapons do
		local card = createSpinCard(weaponId, i)
		card.Parent = spinStrip
	end
	
	-- Set strip size - make it tall enough for cards
	local totalWidth = SPIN_CARDS * (CARD_WIDTH + CARD_GAP)
	spinStrip.Size = UDim2.new(0, totalWidth, 0, CARD_HEIGHT)
	spinStrip.Position = UDim2.new(0, 0, 0.5, -CARD_HEIGHT/2)
end

-- Spin animation
local function playSpin(winningWeaponId: string, onComplete: () -> ())
	if not spinStrip or not spinContainer then return end
	
	-- Clean up previous tween and connection
	stopTickSounds()
	if spinTweenConnection then
		spinTweenConnection:Disconnect()
		spinTweenConnection = nil
	end
	if spinTween then 
		spinTween:Cancel() 
		spinTween = nil
	end
	
	-- Build the strip
	buildSpinStrip(winningWeaponId)
	
	-- Wait a frame for container to be ready
	task.wait()
	
	-- Calculate end position (winner should be in center)
	local containerWidth = spinContainer.AbsoluteSize.X
	if containerWidth == 0 then containerWidth = 900 end -- Fallback
	
	local winnerIndex = SPIN_CARDS - 3
	local winnerPosition = (winnerIndex - 1) * (CARD_WIDTH + CARD_GAP)
	local centerOffset = (containerWidth / 2) - (CARD_WIDTH / 2)
	local endPosition = -(winnerPosition - centerOffset)
	
	-- Add some randomness to where it lands on the card
	endPosition = endPosition + math.random(-20, 20)
	
	-- Reset position (start from right side)
	local startPosition = 100
	spinStrip.Position = UDim2.new(0, startPosition, 0.5, -CARD_HEIGHT/2)
	
	-- Spin animation - fast start, slow end
	local spinDuration = 4 -- Total spin time
	
	spinTween = TweenService:Create(
		spinStrip,
		TweenInfo.new(spinDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, endPosition, 0.5, -CARD_HEIGHT/2) }
	)
	
	-- Track position for tick sounds
	local lastCardIndex = 0
	local cardSpacing = CARD_WIDTH + CARD_GAP
	
	tickConnection = game:GetService("RunService").RenderStepped:Connect(function()
		if not spinStrip then return end
		local currentPos = -spinStrip.Position.X.Offset + (containerWidth / 2)
		local currentCardIndex = math.floor(currentPos / cardSpacing)
		
		if currentCardIndex > lastCardIndex then
			lastCardIndex = currentCardIndex
			playTickSound()
		end
	end)
	
	spinTween:Play()
	
	-- Store connection so we can disconnect it later
	spinTweenConnection = spinTween.Completed:Once(function()
		stopTickSounds()
		task.wait(0.5) -- Pause before reveal
		onComplete()
	end)
end

-- Hide the spin animation
local function hideSpinAnimation()
	if spinOverlay then
		TweenService:Create(spinOverlay, TweenInfo.new(0.2), {
			BackgroundTransparency = 1
		}):Play()
		task.delay(0.2, function()
			spinOverlay.Visible = false
		end)
	end
	
	if spinContainer then
		spinContainer.Visible = false
	end
	
	if pointerArrow then
		pointerArrow.Visible = false
	end
end

-- Create floating particles
local particleFrames: {Frame} = {}

local function createParticles(parent: Frame, color: Color3)
	for _, p in particleFrames do
		p:Destroy()
	end
	particleFrames = {}
	
	for i = 1, 25 do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(6, 14), 0, math.random(6, 14))
		particle.Position = UDim2.new(math.random() * 0.8 + 0.1, 0, 1.2, 0)
		particle.BackgroundColor3 = color
		particle.BorderSizePixel = 0
		particle.ZIndex = 105
		particle.Parent = parent
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle
		
		table.insert(particleFrames, particle)
		
		local duration = math.random(20, 35) / 10
		local targetX = math.random() * 0.8 + 0.1
		
		TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(targetX, 0, -0.3, 0),
			BackgroundTransparency = 0.9,
			Size = UDim2.new(0, 4, 0, 4)
		}):Play()
	end
end

-- Epic reveal after spin
local function showResult(weaponId: string, odds: number, revealedUid: string?)
	local def = Config.Weapons[weaponId]
	if not def then return end
	
	-- Play win sound based on rarity
	playWinSound(def.rarity)
	
	-- Remove this weapon from pending list (so it shows in inventory now)
	if revealedUid then
		for i, uid in pendingWeaponUids do
			if uid == revealedUid then
				table.remove(pendingWeaponUids, i)
				break
			end
		end
		
		-- Notify that a weapon was revealed (so inventory can refresh)
		if onWeaponRevealedCallback then
			onWeaponRevealedCallback()
		end
	end
	
	local rarityColor = getRarityColor(def.rarity)
	
	if resultOverlay then
		resultOverlay.Visible = true
		resultOverlay.BackgroundTransparency = 1
		TweenService:Create(resultOverlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 0.6
		}):Play()
	end
	
	-- Particles
	if resultOverlay then
		createParticles(resultOverlay, rarityColor)
	end
	
	if resultCard then
		local stroke = resultCard:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = rarityColor end
		
		resultCard.Size = UDim2.new(0, 50, 0, 50)
		resultCard.BackgroundTransparency = 1
		resultCard.Rotation = -20
		resultCard.Visible = true
		
		TweenService:Create(resultCard, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 360, 0, 300),
			BackgroundTransparency = 0,
			Rotation = 0
		}):Play()
	end
	
	if weaponIcon then
		weaponIcon.Text = "⚔️"
		weaponIcon.TextColor3 = rarityColor
		weaponIcon.TextTransparency = 1
		task.delay(0.25, function()
			TweenService:Create(weaponIcon, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {
				TextTransparency = 0
			}):Play()
		end)
	end
	
	if weaponName then
		weaponName.Text = def.name
		weaponName.TextColor3 = rarityColor
		weaponName.TextTransparency = 1
		task.delay(0.35, function()
			TweenService:Create(weaponName, TweenInfo.new(0.25), {
				TextTransparency = 0
			}):Play()
		end)
	end
	
	if rarityBadge then
		rarityBadge.BackgroundColor3 = rarityColor
		rarityBadge.BackgroundTransparency = 1
		local label = rarityBadge:FindFirstChild("Label")
		if label then
			label.Text = def.rarity
			label.TextTransparency = 1
		end
		task.delay(0.45, function()
			TweenService:Create(rarityBadge, TweenInfo.new(0.25), {
				BackgroundTransparency = 0
			}):Play()
			if label then
				TweenService:Create(label, TweenInfo.new(0.25), {
					TextTransparency = 0
				}):Play()
			end
		end)
	end
	
	if oddsLabel then
		oddsLabel.Text = formatOdds(odds)
		oddsLabel.TextTransparency = 1
		task.delay(0.55, function()
			TweenService:Create(oddsLabel, TweenInfo.new(0.25), {
				TextTransparency = 0
			}):Play()
		end)
	end
	
	if continueBtn then
		-- Update button text based on remaining items
		local remaining = #resultQueue - currentQueueIndex
		if remaining > 0 then
			continueBtn.Text = "⏭️ Next (" .. remaining .. " left)"
			continueBtn.BackgroundColor3 = COLORS.accent
		else
			continueBtn.Text = "✨ Continue"
			continueBtn.BackgroundColor3 = COLORS.success
		end
		
		continueBtn.Visible = true
		continueBtn.BackgroundTransparency = 1
		continueBtn.TextTransparency = 1
		task.delay(0.7, function()
			TweenService:Create(continueBtn, TweenInfo.new(0.25), {
				BackgroundTransparency = 0,
				TextTransparency = 0
			}):Play()
		end)
	end
end

local function hideResult()
	if resultOverlay then
		TweenService:Create(resultOverlay, TweenInfo.new(0.2), {
			BackgroundTransparency = 1
		}):Play()
		task.delay(0.2, function()
			resultOverlay.Visible = false
		end)
	end
	
	if resultCard then
		TweenService:Create(resultCard, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 50, 0, 50),
			BackgroundTransparency = 1
		}):Play()
		task.delay(0.15, function()
			resultCard.Visible = false
		end)
	end
	
	if continueBtn then
		continueBtn.Visible = false
	end
	
	for _, p in particleFrames do
		p:Destroy()
	end
	particleFrames = {}
	
	-- Check if there are more results to show
	if currentQueueIndex < #resultQueue then
		task.wait(0.3)
		processNextInQueue()
	else
		-- All done, clear queue
		resultQueue = {}
		currentQueueIndex = 0
		isOpening = false
	end
end

-- Show the spin container and start animation
local function showSpinAnimation(winningWeaponId: string, odds: number, uid: string?)
	if spinOverlay then
		spinOverlay.Visible = true
		spinOverlay.BackgroundTransparency = 1
		TweenService:Create(spinOverlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 0.7
		}):Play()
	end
	
	if spinContainer then
		spinContainer.Visible = true
		spinContainer.BackgroundTransparency = 1
		TweenService:Create(spinContainer, TweenInfo.new(0.3), {
			BackgroundTransparency = 0
		}):Play()
	end
	
	if pointerArrow then
		pointerArrow.Visible = true
	end
	
	-- Start spinning
	playSpin(winningWeaponId, function()
		-- Hide spin, show result
		hideSpinAnimation()
		task.wait(0.2)
		showResult(winningWeaponId, odds, uid)
	end)
end

-- Process the next item in the queue
processNextInQueue = function()
	currentQueueIndex += 1
	if currentQueueIndex > #resultQueue then
		resultQueue = {}
		currentQueueIndex = 0
		pendingWeaponUids = {} -- Clear any remaining pending
		isOpening = false
		return
	end
	
	local result = resultQueue[currentQueueIndex]
	if result.inventoryFull then
		-- Skip this one, inventory was full
		warn("[CrateOpener] Inventory was full - crate wasted!")
		processNextInQueue()
		return
	end
	
	if result.weaponId and result.odds then
		showSpinAnimation(result.weaponId, result.odds, result.uid)
	else
		processNextInQueue()
	end
end

function CrateOpener.build(parent: Instance): ScreenGui
	-- Initialize sounds
	createSounds()
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CrateOpenerGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 200
	screenGui.Enabled = true
	screenGui.Parent = parent
	
	-- SPIN OVERLAY
	spinOverlay = Instance.new("Frame")
	spinOverlay.Name = "SpinOverlay"
	spinOverlay.Size = UDim2.fromScale(1, 1)
	spinOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	spinOverlay.BackgroundTransparency = 0.7
	spinOverlay.BorderSizePixel = 0
	spinOverlay.Visible = false
	spinOverlay.ZIndex = 50
	spinOverlay.Parent = screenGui
	
	-- Spin container (the visible window)
	spinContainer = Instance.new("Frame")
	spinContainer.Name = "SpinContainer"
	spinContainer.Size = UDim2.new(0, VISIBLE_CARDS * (CARD_WIDTH + CARD_GAP), 0, CARD_HEIGHT + 40)
	spinContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
	spinContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	spinContainer.BackgroundColor3 = COLORS.bgDark
	spinContainer.BorderSizePixel = 0
	spinContainer.ClipsDescendants = true
	spinContainer.Visible = false
	spinContainer.ZIndex = 51
	spinContainer.Parent = screenGui
	
	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 16)
	containerCorner.Parent = spinContainer
	
	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = COLORS.gold
	containerStroke.Thickness = 3
	containerStroke.Parent = spinContainer
	
	-- Inner padding frame for the strip
	local spinPadding = Instance.new("Frame")
	spinPadding.Size = UDim2.new(1, -20, 1, -40)
	spinPadding.Position = UDim2.new(0, 10, 0, 20)
	spinPadding.BackgroundTransparency = 1
	spinPadding.ClipsDescendants = true
	spinPadding.ZIndex = 52
	spinPadding.Parent = spinContainer
	
	-- The actual strip that moves
	spinStrip = Instance.new("Frame")
	spinStrip.Name = "SpinStrip"
	spinStrip.Size = UDim2.new(0, 1000, 1, 0)
	spinStrip.BackgroundTransparency = 1
	spinStrip.ZIndex = 53
	spinStrip.Parent = spinPadding
	
	-- RED CENTER LINE - shows where item lands
	local centerLine = Instance.new("Frame")
	centerLine.Name = "CenterLine"
	centerLine.Size = UDim2.new(0, 4, 1, 20)
	centerLine.Position = UDim2.new(0.5, -2, 0, -10)
	centerLine.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	centerLine.BorderSizePixel = 0
	centerLine.ZIndex = 60
	centerLine.Parent = spinContainer
	
	-- Glow effect for the line
	local lineGlow = Instance.new("UIStroke")
	lineGlow.Color = Color3.fromRGB(255, 100, 100)
	lineGlow.Thickness = 2
	lineGlow.Transparency = 0.3
	lineGlow.Parent = centerLine
	
	-- Top arrow pointer
	pointerArrow = Instance.new("Frame")
	pointerArrow.Name = "Pointer"
	pointerArrow.Size = UDim2.new(0, 24, 0, 24)
	pointerArrow.Position = UDim2.new(0.5, 0, 0, -8)
	pointerArrow.AnchorPoint = Vector2.new(0.5, 1)
	pointerArrow.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	pointerArrow.Rotation = 45
	pointerArrow.BorderSizePixel = 0
	pointerArrow.Visible = false
	pointerArrow.ZIndex = 61
	pointerArrow.Parent = spinContainer
	
	-- Bottom arrow pointer
	local pointerBottom = Instance.new("Frame")
	pointerBottom.Size = UDim2.new(0, 24, 0, 24)
	pointerBottom.Position = UDim2.new(0.5, 0, 1, 8)
	pointerBottom.AnchorPoint = Vector2.new(0.5, 0)
	pointerBottom.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	pointerBottom.Rotation = 45
	pointerBottom.BorderSizePixel = 0
	pointerBottom.ZIndex = 61
	pointerBottom.Parent = spinContainer
	
	-- Title above spin
	local spinTitle = Instance.new("TextLabel")
	spinTitle.Size = UDim2.new(0, 300, 0, 40)
	spinTitle.Position = UDim2.new(0.5, 0, 0, -50)
	spinTitle.AnchorPoint = Vector2.new(0.5, 1)
	spinTitle.BackgroundTransparency = 1
	spinTitle.Text = "🎲 SPINNING..."
	spinTitle.TextColor3 = COLORS.gold
	spinTitle.TextSize = 28
	spinTitle.Font = Enum.Font.GothamBold
	spinTitle.ZIndex = 55
	spinTitle.Parent = spinContainer
	
	-- RESULT OVERLAY
	resultOverlay = Instance.new("Frame")
	resultOverlay.Name = "ResultOverlay"
	resultOverlay.Size = UDim2.fromScale(1, 1)
	resultOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	resultOverlay.BackgroundTransparency = 0.6
	resultOverlay.BorderSizePixel = 0
	resultOverlay.Visible = false
	resultOverlay.ZIndex = 100
	resultOverlay.Parent = screenGui
	
	resultCard = Instance.new("Frame")
	resultCard.Name = "ResultCard"
	resultCard.Size = UDim2.new(0, 360, 0, 300)
	resultCard.Position = UDim2.new(0.5, 0, 0.45, 0)
	resultCard.AnchorPoint = Vector2.new(0.5, 0.5)
	resultCard.BackgroundColor3 = COLORS.bgDark
	resultCard.BorderSizePixel = 0
	resultCard.Visible = false
	resultCard.ZIndex = 102
	resultCard.Parent = resultOverlay
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 20)
	cardCorner.Parent = resultCard
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = COLORS.gold
	cardStroke.Thickness = 4
	cardStroke.Parent = resultCard
	
	weaponIcon = Instance.new("TextLabel")
	weaponIcon.Size = UDim2.new(0, 80, 0, 70)
	weaponIcon.Position = UDim2.new(0.5, 0, 0, 30)
	weaponIcon.AnchorPoint = Vector2.new(0.5, 0)
	weaponIcon.BackgroundTransparency = 1
	weaponIcon.Text = "⚔️"
	weaponIcon.TextSize = 55
	weaponIcon.ZIndex = 103
	weaponIcon.Parent = resultCard
	
	weaponName = Instance.new("TextLabel")
	weaponName.Size = UDim2.new(1, -30, 0, 45)
	weaponName.Position = UDim2.new(0.5, 0, 0, 105)
	weaponName.AnchorPoint = Vector2.new(0.5, 0)
	weaponName.BackgroundTransparency = 1
	weaponName.Text = "Weapon"
	weaponName.TextColor3 = COLORS.gold
	weaponName.TextSize = 30
	weaponName.Font = Enum.Font.GothamBold
	weaponName.ZIndex = 103
	weaponName.Parent = resultCard
	
	rarityBadge = Instance.new("Frame")
	rarityBadge.Size = UDim2.new(0, 110, 0, 30)
	rarityBadge.Position = UDim2.new(0.5, 0, 0, 160)
	rarityBadge.AnchorPoint = Vector2.new(0.5, 0)
	rarityBadge.BackgroundColor3 = COLORS.gold
	rarityBadge.BorderSizePixel = 0
	rarityBadge.ZIndex = 103
	rarityBadge.Parent = resultCard
	
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 15)
	badgeCorner.Parent = rarityBadge
	
	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Name = "Label"
	badgeLabel.Size = UDim2.new(1, 0, 1, 0)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.Text = "Rarity"
	badgeLabel.TextColor3 = Color3.new(1, 1, 1)
	badgeLabel.TextSize = 15
	badgeLabel.Font = Enum.Font.GothamBold
	badgeLabel.ZIndex = 104
	badgeLabel.Parent = rarityBadge
	
	oddsLabel = Instance.new("TextLabel")
	oddsLabel.Size = UDim2.new(1, -30, 0, 35)
	oddsLabel.Position = UDim2.new(0.5, 0, 0, 205)
	oddsLabel.AnchorPoint = Vector2.new(0.5, 0)
	oddsLabel.BackgroundTransparency = 1
	oddsLabel.Text = "1 in ???"
	oddsLabel.TextColor3 = COLORS.gold
	oddsLabel.TextSize = 26
	oddsLabel.Font = Enum.Font.GothamBold
	oddsLabel.ZIndex = 103
	oddsLabel.Parent = resultCard
	
	continueBtn = Instance.new("TextButton")
	continueBtn.Size = UDim2.new(0, 170, 0, 50)
	continueBtn.Position = UDim2.new(0.5, 0, 0.82, 0)
	continueBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	continueBtn.BackgroundColor3 = COLORS.success
	continueBtn.Text = "✨ Continue"
	continueBtn.TextColor3 = Color3.new(1, 1, 1)
	continueBtn.TextSize = 19
	continueBtn.Font = Enum.Font.GothamBold
	continueBtn.BorderSizePixel = 0
	continueBtn.Visible = false
	continueBtn.ZIndex = 103
	continueBtn.Parent = resultOverlay
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 14)
	btnCorner.Parent = continueBtn
	
	continueBtn.MouseButton1Click:Connect(hideResult)
	
	-- Listen for results
	ShopRemotes.openCrateResult().OnClientEvent:Connect(function(
		success, 
		weaponIdOrResults, 
		odds, 
		uid,
		errorMsg
	)
		if not success then
			isOpening = false
			pendingWeaponUids = {}
			if spinOverlay then spinOverlay.Visible = false end
			if spinContainer then spinContainer.Visible = false end
			if errorMsg then warn("[CrateOpener]", errorMsg) end
			return
		end
		
		-- Check if we got an array of results (multi-open) or single result
		if type(weaponIdOrResults) == "table" and weaponIdOrResults[1] then
			-- Multiple results - queue them up and track pending UIDs
			resultQueue = {}
			pendingWeaponUids = {}
			for _, result in weaponIdOrResults do
				table.insert(resultQueue, {
					weaponId = result.weaponId,
					odds = result.odds,
					uid = result.uid,
					inventoryFull = result.inventoryFull,
				})
				-- Track this UID as pending (hide from inventory until revealed)
				if result.uid and not result.inventoryFull then
					table.insert(pendingWeaponUids, result.uid)
				end
			end
			currentQueueIndex = 0
			isOpening = true
			processNextInQueue()
		elseif type(weaponIdOrResults) == "string" and odds then
			-- Single result
			resultQueue = {{
				weaponId = weaponIdOrResults,
				odds = odds,
				uid = uid,
				inventoryFull = false,
			}}
			pendingWeaponUids = {}
			if uid then
				table.insert(pendingWeaponUids, uid)
			end
			currentQueueIndex = 0
			isOpening = true
			processNextInQueue()
		else
			isOpening = false
			pendingWeaponUids = {}
		end
	end)
	
	return screenGui
end

function CrateOpener.startOpening()
	if isOpening then return end
	isOpening = true
end

function CrateOpener.isOpening(): boolean
	return isOpening
end

function CrateOpener.getPendingWeaponUids(): {string}
	return pendingWeaponUids
end

function CrateOpener.setOnWeaponRevealed(callback: () -> ())
	onWeaponRevealedCallback = callback
end

function CrateOpener.getGui()
	return screenGui
end

return CrateOpener
