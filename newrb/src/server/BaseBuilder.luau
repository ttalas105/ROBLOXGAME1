--[[
	BaseBuilder: Creates the 7 home base plots with pedestals and walkway from lobby.
	Each base has pedestals where players can display their weapons for passive income.
	- Auto-claims when player enters unclaimed base
	- Billboard sign above base showing owner name
	- Each pedestal has a collection pad for gathering accumulated keys
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BaseBuilder = {}

-- Colors
local COLORS = {
	walkway = Color3.fromRGB(100, 100, 110),
	walkwayStripe = Color3.fromRGB(255, 200, 50),
	plotFloor = Color3.fromRGB(60, 60, 70),
	plotBorder = Color3.fromRGB(80, 80, 90),
	pedestal = Color3.fromRGB(50, 50, 60),
	pedestalTop = Color3.fromRGB(70, 70, 80),
	collectionPad = Color3.fromRGB(50, 200, 100),
}

-- Rarity colors for pedestal glow
local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(100, 200, 100),
	Rare = Color3.fromRGB(100, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
	Mythic = Color3.fromRGB(255, 100, 100),
	Exotic = Color3.fromRGB(255, 50, 150),
	Divine = Color3.fromRGB(255, 255, 200),
}

-- Helper: Create a part
local function createPart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, parent: Instance): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- Create a weapon display pedestal with collection pad
local function createPedestal(index: number, position: Vector3, parent: Instance): Model
	local pedestal = Instance.new("Model")
	pedestal.Name = "Pedestal_" .. index
	
	local pedestalSize = Config.PedestalSize
	
	-- Base platform
	local base = createPart("Base", Vector3.new(pedestalSize.X, 1, pedestalSize.Z), 
		position, COLORS.pedestal, Enum.Material.Marble, pedestal)
	
	-- Column
	local columnHeight = pedestalSize.Y - 2
	local column = createPart("Column", Vector3.new(pedestalSize.X * 0.4, columnHeight, pedestalSize.Z * 0.4), 
		position + Vector3.new(0, columnHeight/2 + 0.5, 0), COLORS.pedestal, Enum.Material.Marble, pedestal)
	
	-- Top platform (where weapon sits)
	local top = createPart("Top", Vector3.new(pedestalSize.X * 0.8, 0.5, pedestalSize.Z * 0.8), 
		position + Vector3.new(0, columnHeight + 1, 0), COLORS.pedestalTop, Enum.Material.Marble, pedestal)
	
	-- Glow ring (changes color based on weapon rarity)
	local glowRing = createPart("GlowRing", Vector3.new(pedestalSize.X, 0.2, pedestalSize.Z), 
		position + Vector3.new(0, columnHeight + 1.4, 0), Color3.fromRGB(100, 100, 100), Enum.Material.Neon, pedestal)
	glowRing.Transparency = 0.7
	glowRing.CanCollide = false
	
	-- Income display billboard (shows keys/sec when weapon placed)
	local incomeBillboard = Instance.new("BillboardGui")
	incomeBillboard.Name = "IncomeBillboard"
	incomeBillboard.Size = UDim2.new(0, 100, 0, 40)
	incomeBillboard.StudsOffset = Vector3.new(0, 3, 0)
	incomeBillboard.AlwaysOnTop = false
	incomeBillboard.Enabled = false -- Hidden until weapon placed
	incomeBillboard.Parent = top
	
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, 0, 1, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "+0 Keys/s"
	incomeLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	incomeLabel.TextSize = 18
	incomeLabel.Font = Enum.Font.GothamBold
	incomeLabel.TextStrokeTransparency = 0
	incomeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	incomeLabel.Parent = incomeBillboard
	
	-- Proximity prompt to place weapon (only when empty and player has equipped weapon)
	local placePrompt = Instance.new("ProximityPrompt")
	placePrompt.Name = "PlacePrompt"
	placePrompt.ActionText = "Place Weapon"
	placePrompt.ObjectText = "Empty Slot"
	placePrompt.HoldDuration = 0.5
	placePrompt.MaxActivationDistance = 8
	placePrompt.RequiresLineOfSight = false
	placePrompt.Parent = top
	
	-- Remove weapon prompt (on the pedestal top, above the weapon)
	local removePrompt = Instance.new("ProximityPrompt")
	removePrompt.Name = "RemovePrompt"
	removePrompt.ActionText = "Remove Weapon"
	removePrompt.ObjectText = "Take back to inventory"
	removePrompt.HoldDuration = 0.5
	removePrompt.MaxActivationDistance = 8
	removePrompt.RequiresLineOfSight = false
	removePrompt.Enabled = false -- Hidden until weapon placed
	removePrompt.Parent = top
	
	-- Collection pad (appears in front of pedestal when weapon is placed)
	-- Bigger pad - step on to auto-collect keys
	local collectionPad = createPart("CollectionPad", Vector3.new(6, 0.3, 6),
		position + Vector3.new(0, 0.15, pedestalSize.Z/2 + 4), COLORS.collectionPad, Enum.Material.Neon, pedestal)
	collectionPad.Transparency = 1 -- Hidden until weapon placed
	collectionPad.CanCollide = false
	
	-- Accumulated keys display on collection pad
	local collectBillboard = Instance.new("BillboardGui")
	collectBillboard.Name = "CollectBillboard"
	collectBillboard.Size = UDim2.new(0, 120, 0, 50)
	collectBillboard.StudsOffset = Vector3.new(0, 2, 0)
	collectBillboard.AlwaysOnTop = false
	collectBillboard.Enabled = false
	collectBillboard.Parent = collectionPad
	
	local collectLabel = Instance.new("TextLabel")
	collectLabel.Name = "CollectLabel"
	collectLabel.Size = UDim2.new(1, 0, 1, 0)
	collectLabel.BackgroundTransparency = 1
	collectLabel.Text = "0"
	collectLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	collectLabel.TextSize = 20
	collectLabel.Font = Enum.Font.GothamBold
	collectLabel.TextStrokeTransparency = 0
	collectLabel.Parent = collectBillboard
	
	-- Store attributes
	pedestal:SetAttribute("PedestalIndex", index)
	pedestal:SetAttribute("HasWeapon", false)
	pedestal:SetAttribute("AccumulatedKeys", 0)
	pedestal:SetAttribute("WeaponId", "")
	pedestal:SetAttribute("WeaponUid", "")
	
	pedestal.PrimaryPart = top
	pedestal.Parent = parent
	
	return pedestal
end

-- Create a single base plot
local function createBasePlot(plotNumber: number, position: Vector3, parent: Instance): Model
	local plot = Instance.new("Model")
	plot.Name = "BasePlot_" .. plotNumber
	
	local plotSize = Config.BasePlotSize
	local pedestalCount = Config.PedestalsPerBase
	
	-- Raise position to sit on top of ground (avoid z-fighting)
	local floorY = 0.5
	local basePos = position + Vector3.new(0, floorY, 0)
	
	-- Floor
	local floor = createPart("Floor", plotSize, basePos, COLORS.plotFloor, Enum.Material.Concrete, plot)
	
	-- Border walls (low, decorative)
	local borderHeight = 1.5
	local borderThickness = 1
	
	-- Front border (with gap for entrance)
	local gapWidth = 12
	local frontSegmentWidth = (plotSize.X - gapWidth) / 2
	local frontLeft = createPart("BorderFrontLeft", Vector3.new(frontSegmentWidth, borderHeight, borderThickness), 
		basePos + Vector3.new(-(gapWidth/2 + frontSegmentWidth/2), borderHeight/2 + 0.5, plotSize.Z/2), COLORS.plotBorder, Enum.Material.Concrete, plot)
	local frontRight = createPart("BorderFrontRight", Vector3.new(frontSegmentWidth, borderHeight, borderThickness), 
		basePos + Vector3.new((gapWidth/2 + frontSegmentWidth/2), borderHeight/2 + 0.5, plotSize.Z/2), COLORS.plotBorder, Enum.Material.Concrete, plot)
	
	-- Back border
	local back = createPart("BorderBack", Vector3.new(plotSize.X, borderHeight, borderThickness), 
		basePos + Vector3.new(0, borderHeight/2 + 0.5, -plotSize.Z/2), COLORS.plotBorder, Enum.Material.Concrete, plot)
	
	-- Side borders
	local left = createPart("BorderLeft", Vector3.new(borderThickness, borderHeight, plotSize.Z), 
		basePos + Vector3.new(-plotSize.X/2, borderHeight/2 + 0.5, 0), COLORS.plotBorder, Enum.Material.Concrete, plot)
	local right = createPart("BorderRight", Vector3.new(borderThickness, borderHeight, plotSize.Z), 
		basePos + Vector3.new(plotSize.X/2, borderHeight/2 + 0.5, 0), COLORS.plotBorder, Enum.Material.Concrete, plot)
	
	-- Billboard sign above base (like arena doors)
	local signPost = createPart("SignPost", Vector3.new(2, 12, 2),
		basePos + Vector3.new(0, 6, -plotSize.Z/2 + 2), COLORS.plotBorder, Enum.Material.Concrete, plot)
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OwnerBillboard"
	billboard.Size = UDim2.new(0, 200, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = signPost
	
	local ownerLabel = Instance.new("TextLabel")
	ownerLabel.Name = "OwnerLabel"
	ownerLabel.Size = UDim2.new(1, 0, 0.6, 0)
	ownerLabel.BackgroundTransparency = 1
	ownerLabel.Text = "[Unclaimed]"
	ownerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	ownerLabel.TextSize = 24
	ownerLabel.Font = Enum.Font.GothamBlack
	ownerLabel.TextStrokeTransparency = 0
	ownerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	ownerLabel.Parent = billboard
	
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Walk in to claim"
	subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitleLabel.TextSize = 14
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.TextStrokeTransparency = 0.5
	subtitleLabel.Parent = billboard
	
	-- Auto-claim trigger zone (invisible, detects player entry)
	local claimZone = createPart("ClaimZone", Vector3.new(plotSize.X - 4, 10, plotSize.Z - 4),
		basePos + Vector3.new(0, 5, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, plot)
	claimZone.Transparency = 1
	claimZone.CanCollide = false
	
	-- Create pedestals in a spread-out pattern (2 rows of 3)
	local pedestalsFolder = Instance.new("Folder")
	pedestalsFolder.Name = "Pedestals"
	pedestalsFolder.Parent = plot
	
	-- Calculate spacing for pedestals
	local pedestalsPerRow = math.ceil(pedestalCount / 2)
	local xSpacing = (plotSize.X - 20) / (pedestalsPerRow - 1)
	local zSpacing = plotSize.Z / 3
	
	for i = 1, pedestalCount do
		local row = math.ceil(i / pedestalsPerRow)
		local col = ((i - 1) % pedestalsPerRow) + 1
		
		local xOffset = -plotSize.X/2 + 10 + ((col - 1) * xSpacing)
		local zOffset = if row == 1 then -zSpacing/2 else zSpacing/3
		
		local pedestalPos = basePos + Vector3.new(xOffset, 0.5, zOffset)
		createPedestal(i, pedestalPos, pedestalsFolder)
	end
	
	-- Store attributes
	plot:SetAttribute("PlotNumber", plotNumber)
	plot:SetAttribute("OwnerId", 0) -- 0 = unclaimed
	
	plot.PrimaryPart = floor
	plot.Parent = parent
	
	return plot
end

-- Create walkway and ground for bases area
local function createWalkway(parent: Instance)
	local walkway = Instance.new("Model")
	walkway.Name = "BasesWalkway"
	
	local startPos = Config.BasesWalkwayStart
	local direction = Config.BasesDirection
	local totalLength = (Config.TotalBasePlots * Config.BasePlotSpacing) + 150
	local plotSize = Config.BasePlotSize
	
	-- Large ground floor for entire bases area (matches hub floor style)
	local hubFloorEdge = 100 -- Hub floor ends at Z=100
	local groundWidth = plotSize.X * 2 + 80 -- Wide enough for plots on both sides
	local groundLength = totalLength + 100
	local ground = Instance.new("Part")
	ground.Name = "BasesGround"
	ground.Size = Vector3.new(groundWidth, 3, groundLength)
	ground.Position = Vector3.new(0, -1.5, hubFloorEdge + groundLength/2)
	ground.Anchored = true
	ground.Color = Color3.fromRGB(45, 45, 50)
	ground.Material = Enum.Material.Cobblestone
	ground.CastShadow = false
	ground.Parent = walkway
	
	-- Main walkway (slightly elevated, different color to stand out)
	local main = createPart("WalkwayMain", Vector3.new(14, 0.3, totalLength), 
		startPos + (direction * totalLength/2) + Vector3.new(0, 0.15, 0), COLORS.walkway, Enum.Material.Concrete, walkway)
	
	-- Center stripe
	local stripe = createPart("WalkwayStripe", Vector3.new(1.5, 0.1, totalLength), 
		startPos + (direction * totalLength/2) + Vector3.new(0, 0.35, 0), COLORS.walkwayStripe, Enum.Material.Neon, walkway)
	stripe.CanCollide = false
	
	walkway.Parent = parent
	return walkway
end

-- Build all bases
function BaseBuilder.build(): Folder
	-- Create main folder
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "HomeBases"
	basesFolder.Parent = Workspace
	
	-- Create walkway
	createWalkway(basesFolder)
	
	-- Create plots folder
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = basesFolder
	
	-- Create 7 base plots along the walkway
	local startPos = Config.BasesWalkwayStart
	local direction = Config.BasesDirection
	local spacing = Config.BasePlotSpacing
	local plotSize = Config.BasePlotSize
	
	for i = 1, Config.TotalBasePlots do
		-- Alternate left and right of walkway
		local side = if i % 2 == 1 then -1 else 1
		local distanceAlongWalkway = math.ceil(i / 2) * spacing + 50
		
		local plotPos = startPos + (direction * distanceAlongWalkway) + Vector3.new(side * (plotSize.X/2 + 12), 0, 0)
		
		createBasePlot(i, plotPos, plotsFolder)
	end
	
	print("[BaseBuilder] Built", Config.TotalBasePlots, "home base plots")
	return basesFolder
end

-- Get a plot by number
function BaseBuilder.getPlot(plotNumber: number): Model?
	local basesFolder = Workspace:FindFirstChild("HomeBases")
	if not basesFolder then return nil end
	
	local plotsFolder = basesFolder:FindFirstChild("Plots")
	if not plotsFolder then return nil end
	
	return plotsFolder:FindFirstChild("BasePlot_" .. plotNumber)
end

-- Update owner billboard on a plot
function BaseBuilder.updateOwnerSign(plotNumber: number, ownerName: string?)
	local plot = BaseBuilder.getPlot(plotNumber)
	if not plot then return end
	
	local signPost = plot:FindFirstChild("SignPost")
	if not signPost then return end
	
	local billboard = signPost:FindFirstChild("OwnerBillboard")
	if not billboard then return end
	
	local ownerLabel = billboard:FindFirstChild("OwnerLabel")
	local subtitleLabel = billboard:FindFirstChild("SubtitleLabel")
	
	if ownerName then
		if ownerLabel then
			ownerLabel.Text = ownerName .. "'s Base"
			ownerLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		end
		if subtitleLabel then
			subtitleLabel.Text = "Place weapons to earn keys"
		end
	else
		if ownerLabel then
			ownerLabel.Text = "[Unclaimed]"
			ownerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
		if subtitleLabel then
			subtitleLabel.Text = "Walk in to claim"
		end
	end
end

-- Get pedestal from a plot
function BaseBuilder.getPedestal(plotNumber: number, pedestalIndex: number): Model?
	local plot = BaseBuilder.getPlot(plotNumber)
	if not plot then return nil end
	
	local pedestals = plot:FindFirstChild("Pedestals")
	if not pedestals then return nil end
	
	return pedestals:FindFirstChild("Pedestal_" .. pedestalIndex)
end

-- Update pedestal visuals when weapon is placed/removed
function BaseBuilder.updatePedestalVisuals(plotNumber: number, pedestalIndex: number, weaponId: string?, rarity: string?, incomeRate: number?)
	local pedestal = BaseBuilder.getPedestal(plotNumber, pedestalIndex)
	if not pedestal then return end
	
	local top = pedestal:FindFirstChild("Top")
	local glowRing = pedestal:FindFirstChild("GlowRing")
	local collectionPad = pedestal:FindFirstChild("CollectionPad")
	local incomeBillboard = top and top:FindFirstChild("IncomeBillboard")
	local placePrompt = top and top:FindFirstChild("PlacePrompt")
	local removePrompt = top and top:FindFirstChild("RemovePrompt")
	local collectBillboard = collectionPad and collectionPad:FindFirstChild("CollectBillboard")
	
	if weaponId and rarity then
		-- Weapon placed
		pedestal:SetAttribute("HasWeapon", true)
		pedestal:SetAttribute("WeaponId", weaponId)
		
		-- Update glow ring color
		local rarityColor = RARITY_COLORS[rarity] or RARITY_COLORS.Common
		if glowRing then
			glowRing.Color = rarityColor
			glowRing.Transparency = 0.3
		end
		
		-- Show income rate
		if incomeBillboard then
			incomeBillboard.Enabled = true
			local incomeLabel = incomeBillboard:FindFirstChild("IncomeLabel")
			if incomeLabel then
				incomeLabel.Text = "+" .. (incomeRate or 0) .. " Keys/s"
				incomeLabel.TextColor3 = rarityColor
			end
		end
		
		-- Hide place prompt
		if placePrompt then
			placePrompt.Enabled = false
		end
		
		-- Show collection pad and remove prompt
		if collectionPad then
			collectionPad.Transparency = 0.3
		end
		if removePrompt then
			removePrompt.Enabled = true
		end
		if collectBillboard then
			collectBillboard.Enabled = true
		end
	else
		-- Weapon removed
		pedestal:SetAttribute("HasWeapon", false)
		pedestal:SetAttribute("WeaponId", "")
		pedestal:SetAttribute("WeaponUid", "")
		pedestal:SetAttribute("AccumulatedKeys", 0)
		
		-- Reset glow ring
		if glowRing then
			glowRing.Color = Color3.fromRGB(100, 100, 100)
			glowRing.Transparency = 0.7
		end
		
		-- Hide income billboard
		if incomeBillboard then
			incomeBillboard.Enabled = false
		end
		
		-- Show place prompt
		if placePrompt then
			placePrompt.Enabled = true
		end
		
		-- Hide collection pad and remove prompt
		if collectionPad then
			collectionPad.Transparency = 1
		end
		if removePrompt then
			removePrompt.Enabled = false
		end
		if collectBillboard then
			collectBillboard.Enabled = false
		end
	end
end

-- Update accumulated keys display on pedestal
function BaseBuilder.updateAccumulatedKeys(plotNumber: number, pedestalIndex: number, keys: number)
	local pedestal = BaseBuilder.getPedestal(plotNumber, pedestalIndex)
	if not pedestal then return end
	
	pedestal:SetAttribute("AccumulatedKeys", keys)
	
	local collectionPad = pedestal:FindFirstChild("CollectionPad")
	if not collectionPad then return end
	
	local collectPrompt = collectionPad:FindFirstChild("CollectPrompt")
	if collectPrompt then
		collectPrompt.ObjectText = keys .. " Keys"
	end
	
	local collectBillboard = collectionPad:FindFirstChild("CollectBillboard")
	if collectBillboard then
		local collectLabel = collectBillboard:FindFirstChild("CollectLabel")
		if collectLabel then
			collectLabel.Text = tostring(keys)
		end
	end
end

return BaseBuilder
