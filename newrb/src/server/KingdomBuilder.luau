--[[
	Dark Fantasy Kingdom Builder
	Creates the atmospheric home area with castle walls, themed shops, and arena doors.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local KingdomBuilder = {}

-- Background music
local function setupBackgroundMusic()
	-- Remove any existing background music
	local existingMusic = SoundService:FindFirstChild("BackgroundMusic")
	if existingMusic then existingMusic:Destroy() end
	
	-- Create medieval/fantasy ambient music
	local music = Instance.new("Sound")
	music.Name = "BackgroundMusic"
	music.SoundId = "rbxassetid://1839245717" -- Calm medieval tavern/castle ambience
	music.Volume = 0.15
	music.Looped = true
	music.Parent = SoundService
	
	-- Play the music
	music:Play()
	
	print("[KingdomBuilder] Background music started")
end

-- Color palette
local COLORS = {
	-- Stone/Structure
	darkStone = Color3.fromRGB(35, 30, 40),
	stone = Color3.fromRGB(55, 50, 60),
	lightStone = Color3.fromRGB(75, 70, 80),
	
	-- Wood
	darkWood = Color3.fromRGB(45, 30, 20),
	wood = Color3.fromRGB(70, 45, 30),
	
	-- Metals
	iron = Color3.fromRGB(60, 65, 70),
	gold = Color3.fromRGB(180, 150, 50),
	
	-- Magic/Glow
	arcaneBlue = Color3.fromRGB(50, 150, 255),
	arcanePurple = Color3.fromRGB(150, 50, 255),
	fireOrange = Color3.fromRGB(255, 120, 30),
	ghostGreen = Color3.fromRGB(100, 255, 150),
	bloodRed = Color3.fromRGB(180, 30, 50),
	
	-- Atmosphere
	fog = Color3.fromRGB(30, 25, 40),
	ambient = Color3.fromRGB(40, 35, 60),
}

-- Setup starry evening atmosphere
local function setupAtmosphere()
	-- Evening lighting - not too dark
	Lighting.Ambient = Color3.fromRGB(70, 60, 90)
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 70, 100)
	Lighting.Brightness = 1.5
	Lighting.ClockTime = 20.5 -- Evening (8:30 PM)
	Lighting.GeographicLatitude = 45
	Lighting.FogColor = Color3.fromRGB(50, 45, 70)
	Lighting.FogStart = 100
	Lighting.FogEnd = 600
	
	-- Remove existing effects
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("Sky") then
			child:Destroy()
		end
	end
	
	-- Starry sky
	local sky = Instance.new("Sky")
	sky.SkyboxBk = "rbxassetid://1013852" -- Night sky
	sky.SkyboxDn = "rbxassetid://1013853"
	sky.SkyboxFt = "rbxassetid://1013854"
	sky.SkyboxLf = "rbxassetid://1013855"
	sky.SkyboxRt = "rbxassetid://1013856"
	sky.SkyboxUp = "rbxassetid://1013857"
	sky.StarCount = 5000
	sky.MoonAngularSize = 15
	sky.MoonTextureId = "rbxassetid://6444320592"
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting
	
	-- Atmosphere - lighter evening feel
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(140, 120, 170)
	atmosphere.Decay = Color3.fromRGB(100, 90, 130)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1
	atmosphere.Parent = Lighting
	
	-- Bloom for neon glow
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.5
	bloom.Parent = Lighting
	
	-- Color correction - subtle fantasy tint
	local colorCorrect = Instance.new("ColorCorrectionEffect")
	colorCorrect.Brightness = 0.02
	colorCorrect.Contrast = 0.1
	colorCorrect.Saturation = 0.05
	colorCorrect.TintColor = Color3.fromRGB(245, 240, 255)
	colorCorrect.Parent = Lighting
	
	print("[KingdomBuilder] Starry evening atmosphere set up")
end

-- Create stone ground/courtyard
local function createGround()
	local ground = Instance.new("Model")
	ground.Name = "KingdomGround"
	
	-- Main courtyard floor - simple cobblestone
	local floor = Instance.new("Part")
	floor.Name = "Courtyard"
	floor.Size = Vector3.new(200, 3, 200)
	floor.Position = Vector3.new(0, -1.5, 0)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(45, 45, 50)
	floor.Material = Enum.Material.Cobblestone
	floor.CastShadow = false
	floor.Parent = ground
	
	ground.Parent = workspace
	print("[KingdomBuilder] Ground created")
	return ground
end

-- Create castle walls
local function createWalls()
	local walls = Instance.new("Model")
	walls.Name = "CastleWalls"
	
	local wallHeight = 25
	local wallThickness = 5
	local wallLength = 180
	local wallDistance = 90
	
	-- Wall positions (surrounding the area)
	local wallConfigs = {
		{pos = Vector3.new(0, wallHeight/2, -wallDistance), size = Vector3.new(wallLength, wallHeight, wallThickness), name = "NorthWall"},
		{pos = Vector3.new(0, wallHeight/2, wallDistance), size = Vector3.new(wallLength, wallHeight, wallThickness), name = "SouthWall"},
		{pos = Vector3.new(-wallDistance, wallHeight/2, 0), size = Vector3.new(wallThickness, wallHeight, wallLength), name = "WestWall"},
		{pos = Vector3.new(wallDistance, wallHeight/2, 0), size = Vector3.new(wallThickness, wallHeight, wallLength), name = "EastWall"},
	}
	
	for _, config in wallConfigs do
		local wall = Instance.new("Part")
		wall.Name = config.name
		wall.Size = config.size
		wall.Position = config.pos
		wall.Anchored = true
		wall.Color = COLORS.darkStone
		wall.Material = Enum.Material.Brick
		wall.Parent = walls
		
		-- Wall top trim
		local trim = Instance.new("Part")
		trim.Name = config.name .. "_Trim"
		trim.Size = Vector3.new(config.size.X + 2, 2, config.size.Z + 2)
		trim.Position = config.pos + Vector3.new(0, wallHeight/2 + 1, 0)
		trim.Anchored = true
		trim.Color = COLORS.stone
		trim.Material = Enum.Material.Slate
		trim.Parent = walls
	end
	
	-- Corner towers
	local towerPositions = {
		Vector3.new(-wallDistance, 0, -wallDistance),
		Vector3.new(wallDistance, 0, -wallDistance),
		Vector3.new(-wallDistance, 0, wallDistance),
		Vector3.new(wallDistance, 0, wallDistance),
	}
	
	for i, pos in towerPositions do
		local tower = Instance.new("Part")
		tower.Name = "Tower_" .. i
		tower.Shape = Enum.PartType.Cylinder
		tower.Size = Vector3.new(35, 15, 15)
		tower.Position = pos + Vector3.new(0, 17.5, 0)
		tower.Orientation = Vector3.new(0, 0, 0)
		tower.Anchored = true
		tower.Color = COLORS.stone
		tower.Material = Enum.Material.Brick
		tower.Parent = walls
		
		-- Tower top
		local towerTop = Instance.new("Part")
		towerTop.Name = "TowerTop_" .. i
		towerTop.Shape = Enum.PartType.Cylinder
		towerTop.Size = Vector3.new(8, 18, 18)
		towerTop.Position = pos + Vector3.new(0, 39, 0)
		towerTop.Anchored = true
		towerTop.Color = COLORS.darkStone
		towerTop.Material = Enum.Material.Slate
		towerTop.Parent = walls
		
		-- Tower torch
		local torch = createTorch(pos + Vector3.new(0, 30, 0))
		torch.Parent = walls
	end
	
	walls.Parent = workspace
	print("[KingdomBuilder] Walls created")
	return walls
end

-- Create a torch
function createTorch(position: Vector3, color: Color3?): Model
	local torchColor = color or COLORS.fireOrange
	
	local torch = Instance.new("Model")
	torch.Name = "Torch"
	
	-- Torch base
	local base = Instance.new("Part")
	base.Name = "TorchBase"
	base.Size = Vector3.new(1, 4, 1)
	base.Position = position
	base.Anchored = true
	base.Color = COLORS.iron
	base.Material = Enum.Material.Metal
	base.Parent = torch
	
	-- Fire part with neon glow
	local fire = Instance.new("Part")
	fire.Name = "Fire"
	fire.Size = Vector3.new(1.2, 1.8, 1.2)
	fire.Position = position + Vector3.new(0, 3, 0)
	fire.Anchored = true
	fire.Color = torchColor
	fire.Material = Enum.Material.Neon
	fire.Transparency = 0.3
	fire.CanCollide = false
	fire.Parent = torch
	
	-- Fire light
	local fireLight = Instance.new("PointLight")
	fireLight.Color = torchColor
	fireLight.Brightness = 1.5
	fireLight.Range = 20
	fireLight.Parent = fire
	
	-- Fire particles
	local fireParticle = Instance.new("ParticleEmitter")
	fireParticle.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, torchColor),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 100)),
	})
	fireParticle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	fireParticle.Lifetime = NumberRange.new(0.5, 1)
	fireParticle.Rate = 20
	fireParticle.Speed = NumberRange.new(3, 5)
	fireParticle.SpreadAngle = Vector2.new(15, 15)
	fireParticle.LightEmission = 1
	fireParticle.Parent = fire
	
	return torch
end

-- Create decorative pillar
local function createPillar(position: Vector3, height: number?): Model
	local h = height or 12
	
	local pillar = Instance.new("Model")
	pillar.Name = "Pillar"
	
	-- Base
	local base = Instance.new("Part")
	base.Size = Vector3.new(4, 2, 4)
	base.Position = position + Vector3.new(0, 1, 0)
	base.Anchored = true
	base.Color = COLORS.stone
	base.Material = Enum.Material.Slate
	base.Parent = pillar
	
	-- Column
	local column = Instance.new("Part")
	column.Shape = Enum.PartType.Cylinder
	column.Size = Vector3.new(h - 4, 3, 3)
	column.Position = position + Vector3.new(0, h/2, 0)
	column.Orientation = Vector3.new(0, 0, 0)
	column.Anchored = true
	column.Color = COLORS.darkStone
	column.Material = Enum.Material.Marble
	column.Parent = pillar
	
	-- Capital (top)
	local capital = Instance.new("Part")
	capital.Size = Vector3.new(5, 2, 5)
	capital.Position = position + Vector3.new(0, h - 1, 0)
	capital.Anchored = true
	capital.Color = COLORS.stone
	capital.Material = Enum.Material.Slate
	capital.Parent = pillar
	
	return pillar
end

-- Create themed shop altar
local function createShopAltar(config: any, Remotes: any): Model
	local altar = Instance.new("Model")
	altar.Name = config.name .. "_Altar"
	
	-- Base platform
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(14, 2, 14)
	platform.Position = config.position + Vector3.new(0, 1, 0)
	platform.Anchored = true
	platform.Color = COLORS.darkStone
	platform.Material = Enum.Material.Slate
	platform.Parent = altar
	
	-- Steps
	for i = 1, 2 do
		local step = Instance.new("Part")
		step.Name = "Step_" .. i
		step.Size = Vector3.new(14 + i*2, 1, 14 + i*2)
		step.Position = config.position + Vector3.new(0, -i, 0)
		step.Anchored = true
		step.Color = COLORS.stone
		step.Material = Enum.Material.Cobblestone
		step.Parent = altar
	end
	
	-- Main altar piece (themed) - NEON glow
	local mainPiece = Instance.new("Part")
	mainPiece.Name = "MainAltar"
	mainPiece.Size = Vector3.new(8, 6, 8)
	mainPiece.Position = config.position + Vector3.new(0, 5, 0)
	mainPiece.Anchored = true
	mainPiece.Color = config.color
	mainPiece.Material = Enum.Material.Neon
	mainPiece.Transparency = 0.2
	mainPiece.Parent = altar
	
	-- Bright glow
	local glow = Instance.new("PointLight")
	glow.Color = config.glowColor
	glow.Brightness = 3
	glow.Range = 30
	glow.Parent = mainPiece
	
	-- Floating crystal/orb above - NEON
	local crystal = Instance.new("Part")
	crystal.Name = "Crystal"
	crystal.Size = Vector3.new(3, 4, 3)
	crystal.Position = config.position + Vector3.new(0, 12, 0)
	crystal.Anchored = true
	crystal.Color = config.glowColor
	crystal.Material = Enum.Material.Neon
	crystal.Transparency = 0
	crystal.Parent = altar
	
	local crystalGlow = Instance.new("PointLight")
	crystalGlow.Color = config.glowColor
	crystalGlow.Brightness = 2
	crystalGlow.Range = 20
	crystalGlow.Parent = crystal
	
	-- Corner pillars
	local corners = {
		Vector3.new(-5, 0, -5),
		Vector3.new(5, 0, -5),
		Vector3.new(-5, 0, 5),
		Vector3.new(5, 0, 5),
	}
	
	for i, offset in corners do
		local pillar = createPillar(config.position + offset, 10)
		pillar.Name = "AltarPillar_" .. i
		pillar.Parent = altar
		
		-- Torch on pillar
		local torch = createTorch(config.position + offset + Vector3.new(0, 10, 0), config.glowColor)
		torch.Parent = altar
	end
	
	-- Floating sign
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ShopSign"
	billboard.Size = UDim2.new(0, 350, 0, 120)
	billboard.StudsOffset = Vector3.new(0, 18, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = mainPiece
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = config.displayName
	titleLabel.TextColor3 = config.glowColor
	titleLabel.TextSize = 42
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.Parent = billboard
	
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "[ Press E ]"
	subtitleLabel.TextColor3 = Color3.new(1, 1, 1)
	subtitleLabel.TextSize = 24
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.TextStrokeTransparency = 0.3
	subtitleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	subtitleLabel.Parent = billboard
	
	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = config.action
	prompt.ObjectText = config.displayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = platform
	
	-- Connect prompt to remote immediately
	if Remotes then
		prompt.Triggered:Connect(function(player: Player)
			local folder = Remotes.getFolder()
			if folder then
				local ev = folder:FindFirstChild(config.remoteName)
				if ev and ev:IsA("RemoteEvent") then
					(ev :: RemoteEvent):FireClient(player)
					print("[KingdomBuilder]", player.Name, "opened", config.name)
				else
					warn("[KingdomBuilder] Remote not found:", config.remoteName)
				end
			else
				warn("[KingdomBuilder] Remotes folder not found")
			end
		end)
	end
	
	return altar
end

-- Create arena door
local function createArenaDoor(config: any): Model
	local door = Instance.new("Model")
	door.Name = config.name .. "_Door"
	
	-- Calculate rotation to face center (0,0,0)
	local toCenter = Vector3.new(0, 0, 0) - config.position
	local rotation = math.deg(math.atan2(toCenter.X, toCenter.Z))
	
	-- Helper to rotate offset around Y axis
	local function rotateOffset(offset: Vector3): Vector3
		local rad = math.rad(rotation)
		local cos, sin = math.cos(rad), math.sin(rad)
		return Vector3.new(
			offset.X * cos - offset.Z * sin,
			offset.Y,
			offset.X * sin + offset.Z * cos
		)
	end
	
	-- Door frame
	local frameLeft = Instance.new("Part")
	frameLeft.Name = "FrameLeft"
	frameLeft.Size = Vector3.new(4, 20, 4)
	frameLeft.Position = config.position + rotateOffset(Vector3.new(-7, 10, 0))
	frameLeft.Orientation = Vector3.new(0, rotation, 0)
	frameLeft.Anchored = true
	frameLeft.Color = COLORS.darkStone
	frameLeft.Material = Enum.Material.Brick
	frameLeft.Parent = door
	
	local frameRight = Instance.new("Part")
	frameRight.Name = "FrameRight"
	frameRight.Size = Vector3.new(4, 20, 4)
	frameRight.Position = config.position + rotateOffset(Vector3.new(7, 10, 0))
	frameRight.Orientation = Vector3.new(0, rotation, 0)
	frameRight.Anchored = true
	frameRight.Color = COLORS.darkStone
	frameRight.Material = Enum.Material.Brick
	frameRight.Parent = door
	
	-- Top arch
	local arch = Instance.new("Part")
	arch.Name = "Arch"
	arch.Size = Vector3.new(18, 4, 4)
	arch.Position = config.position + rotateOffset(Vector3.new(0, 22, 0))
	arch.Orientation = Vector3.new(0, rotation, 0)
	arch.Anchored = true
	arch.Color = COLORS.stone
	arch.Material = Enum.Material.Slate
	arch.Parent = door
	
	-- Wooden doors (Arena 1: positioned "open" to the sides; others: closed)
	local doorOffset = (config.name == "Arena1") and 6 or 3  -- open = further out
	local doorLeft = Instance.new("Part")
	doorLeft.Name = "DoorLeft"
	doorLeft.Size = Vector3.new(5, 18, 1.5)
	doorLeft.Position = config.position + rotateOffset(Vector3.new(-doorOffset, 9, 0))
	doorLeft.Orientation = Vector3.new(0, rotation, 0)
	doorLeft.Anchored = true
	doorLeft.Color = COLORS.darkWood
	doorLeft.Material = Enum.Material.Wood
	doorLeft.Parent = door
	
	local doorRight = Instance.new("Part")
	doorRight.Name = "DoorRight"
	doorRight.Size = Vector3.new(5, 18, 1.5)
	doorRight.Position = config.position + rotateOffset(Vector3.new(doorOffset, 9, 0))
	doorRight.Orientation = Vector3.new(0, rotation, 0)
	doorRight.Anchored = true
	doorRight.Color = COLORS.darkWood
	doorRight.Material = Enum.Material.Wood
	doorRight.Parent = door
	
	-- Metal bands on doors (skip for Arena 1 open look)
	if config.name ~= "Arena1" then
		for i = 1, 3 do
			local bandLeft = Instance.new("Part")
			bandLeft.Name = "BandLeft_" .. i
			bandLeft.Size = Vector3.new(5.2, 0.8, 1.7)
			bandLeft.Position = config.position + rotateOffset(Vector3.new(-3, 3 + i * 5, 0))
			bandLeft.Orientation = Vector3.new(0, rotation, 0)
			bandLeft.Anchored = true
			bandLeft.Color = COLORS.iron
			bandLeft.Material = Enum.Material.Metal
			bandLeft.Parent = door
			
			local bandRight = Instance.new("Part")
			bandRight.Name = "BandRight_" .. i
			bandRight.Size = Vector3.new(5.2, 0.8, 1.7)
			bandRight.Position = config.position + rotateOffset(Vector3.new(3, 3 + i * 5, 0))
			bandRight.Orientation = Vector3.new(0, rotation, 0)
			bandRight.Anchored = true
			bandRight.Color = COLORS.iron
			bandRight.Material = Enum.Material.Metal
			bandRight.Parent = door
		end
		
		-- Door handles (closed doors only)
		local handleLeft = Instance.new("Part")
		handleLeft.Name = "HandleLeft"
		handleLeft.Shape = Enum.PartType.Ball
		handleLeft.Size = Vector3.new(1.5, 1.5, 1.5)
		handleLeft.Position = config.position + rotateOffset(Vector3.new(-1.5, 10, 1))
		handleLeft.Anchored = true
		handleLeft.Color = COLORS.gold
		handleLeft.Material = Enum.Material.Metal
		handleLeft.Parent = door
		
		local handleRight = Instance.new("Part")
		handleRight.Name = "HandleRight"
		handleRight.Shape = Enum.PartType.Ball
		handleRight.Size = Vector3.new(1.5, 1.5, 1.5)
		handleRight.Position = config.position + rotateOffset(Vector3.new(1.5, 10, 1))
		handleRight.Anchored = true
		handleRight.Color = COLORS.gold
		handleRight.Material = Enum.Material.Metal
		handleRight.Parent = door
	end
	
	-- Torches on either side
	local torchLeft = createTorch(config.position + rotateOffset(Vector3.new(-10, 12, 0)), config.color)
	torchLeft.Parent = door
	
	local torchRight = createTorch(config.position + rotateOffset(Vector3.new(10, 12, 0)), config.color)
	torchRight.Parent = door
	
	-- Arena sign
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ArenaSign"
	billboard.Size = UDim2.new(0, 300, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 15, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = arch
	
	local arenaLabel = Instance.new("TextLabel")
	arenaLabel.Size = UDim2.new(1, 0, 0.7, 0)
	arenaLabel.BackgroundTransparency = 1
	arenaLabel.Text = config.displayName
	arenaLabel.TextColor3 = config.color
	arenaLabel.TextSize = 36
	arenaLabel.Font = Enum.Font.GothamBlack
	arenaLabel.TextStrokeTransparency = 0
	arenaLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	arenaLabel.Parent = billboard
	
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
	statusLabel.Position = UDim2.new(0, 0, 0.7, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = config.name == "Arena1" and "WALK THROUGH TO ENTER" or "🔒 COMING SOON"
	statusLabel.TextColor3 = config.name == "Arena1" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150)
	statusLabel.TextSize = 18
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextStrokeTransparency = 0.3
	statusLabel.Parent = billboard
	
	-- Arena 1: invisible trigger - walk through to teleport (wired in init.server)
	if config.name == "Arena1" then
		local trigger = Instance.new("Part")
		trigger.Name = "Arena1Trigger"
		trigger.Size = Vector3.new(12, 20, 8)
		trigger.Position = config.position + rotateOffset(Vector3.new(0, 10, 5))
		trigger.Orientation = Vector3.new(0, rotation, 0)
		trigger.Anchored = true
		trigger.CanCollide = false
		trigger.Transparency = 1
		trigger.Parent = door
	end
	
	-- Locked chains (visual) only for arenas that aren't Arena1
	if config.name ~= "Arena1" then
		local chain = Instance.new("Part")
		chain.Name = "Chain"
		chain.Size = Vector3.new(8, 1, 1)
		chain.Position = config.position + Vector3.new(0, 10, 1.5)
		chain.Anchored = true
		chain.Color = COLORS.iron
		chain.Material = Enum.Material.Metal
		chain.Parent = door
	end
	
	return door
end

-- Create decorative elements
local function createDecorations()
	local decorations = Instance.new("Model")
	decorations.Name = "Decorations"
	
	-- Fog emitters on ground
	local fogPositions = {
		Vector3.new(-40, 1, -40),
		Vector3.new(40, 1, -40),
		Vector3.new(-40, 1, 40),
		Vector3.new(40, 1, 40),
		Vector3.new(0, 1, 0),
	}
	
	for i, pos in fogPositions do
		local fogPart = Instance.new("Part")
		fogPart.Name = "FogEmitter_" .. i
		fogPart.Size = Vector3.new(1, 1, 1)
		fogPart.Position = pos
		fogPart.Anchored = true
		fogPart.Transparency = 1
		fogPart.CanCollide = false
		fogPart.Parent = decorations
		
		local fogParticle = Instance.new("ParticleEmitter")
		fogParticle.Color = ColorSequence.new(Color3.fromRGB(100, 90, 120))
		fogParticle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 3),
			NumberSequenceKeypoint.new(0.5, 10),
			NumberSequenceKeypoint.new(1, 3),
		})
		fogParticle.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.85),
			NumberSequenceKeypoint.new(0.7, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		})
		fogParticle.Lifetime = NumberRange.new(6, 10)
		fogParticle.Rate = 2
		fogParticle.Speed = NumberRange.new(0.5, 2)
		fogParticle.SpreadAngle = Vector2.new(180, 180)
		fogParticle.Parent = fogPart
	end
	
	decorations.Parent = workspace
	print("[KingdomBuilder] Decorations created")
	return decorations
end

-- Main build function
function KingdomBuilder.build(Remotes: any)
	print("[KingdomBuilder] Building Dark Fantasy Kingdom...")
	
	-- Remove default Roblox baseplate (causes z-fighting)
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
		print("[KingdomBuilder] Removed default Baseplate")
	end
	
	-- Also remove any SpawnLocation that might be at ground level
	local spawn = workspace:FindFirstChild("SpawnLocation")
	if spawn then
		spawn.Position = Vector3.new(0, 3, 0) -- Raise it above ground
	end
	
	-- Clean up any existing kingdom elements
	for _, name in {"KingdomGround", "CastleWalls", "Decorations", "Shops", "ArenaDoors", "Arena1", "Moon"} do
		local existing = workspace:FindFirstChild(name)
		if existing then existing:Destroy() end
	end
	
	-- Setup atmosphere
	setupAtmosphere()
	
	-- Setup background music
	setupBackgroundMusic()
	
	-- Create environment
	createGround()
	createWalls()
	createDecorations()
	
	-- Create shops in the middle
	local shops = Instance.new("Model")
	shops.Name = "Shops"
	
	local shopConfigs = {
		{
			name = "CrateShop",
			displayName = "⚔️ ANCIENT CHEST",
			action = "Open Chest Altar",
			position = Vector3.new(-20, 0, 0),
			color = COLORS.arcaneBlue,
			glowColor = COLORS.arcaneBlue,
			remoteName = "OpenCrateShop",
		},
		{
			name = "SellShop",
			displayName = "💰 MERCHANT'S ALTAR",
			action = "Trade Weapons",
			position = Vector3.new(0, 0, 20),
			color = COLORS.gold,
			glowColor = Color3.fromRGB(255, 200, 50),
			remoteName = "OpenSellShop",
		},
		{
			name = "UpgradesShop",
			displayName = "🔮 ARCANE OBELISK",
			action = "Channel Power",
			position = Vector3.new(20, 0, 0),
			color = COLORS.arcanePurple,
			glowColor = COLORS.arcanePurple,
			remoteName = "OpenUpgradesShop",
		},
	}
	
	for _, config in shopConfigs do
		local altar = createShopAltar(config, Remotes)
		altar.Parent = shops
		print("[KingdomBuilder] Created shop:", config.name)
	end
	
	shops.Parent = workspace
	
	-- Create arena doors
	local arenaDoors = Instance.new("Model")
	arenaDoors.Name = "ArenaDoors"
	
	local arenaConfigs = {
		{
			name = "Arena1",
			displayName = "Farmland Frenzy",
			position = Vector3.new(0, 0, -70),
			color = COLORS.bloodRed,
		},
		{
			name = "Arena2",
			displayName = "🔥 ARENA II",
			position = Vector3.new(-70, 0, 0),
			color = COLORS.fireOrange,
		},
		{
			name = "Arena3",
			displayName = "💀 ARENA III",
			position = Vector3.new(70, 0, 0),
			color = COLORS.ghostGreen,
		},
	}
	
	for _, config in arenaConfigs do
		local door = createArenaDoor(config)
		door.Parent = arenaDoors
	end
	
	arenaDoors.Parent = workspace
	
	print("[KingdomBuilder] ✅ Dark Fantasy Kingdom complete!")
end

return KingdomBuilder
