--[[
	Arena 1: Farmland
	Builds a beautiful 420x420 farmland arena with farmhouse, windmill, tractor, cropland, and fenced animals.
	Tree border prevents players from falling off. Daylight lighting when in arena.
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Arena1Builder = {}

-- Arena position (far from hub)
local ARENA_ORIGIN = Vector3.new(2000, 0, 0)
local ARENA_SIZE_X = 420
local ARENA_SIZE_Z = 420

-- Hub lighting (evening) - stored so we can restore
local HUB_LIGHTING = {
	ClockTime = 20.5,
	Brightness = 1.5,
	Ambient = Color3.fromRGB(70, 60, 90),
	OutdoorAmbient = Color3.fromRGB(80, 70, 100),
	FogStart = 100,
	FogEnd = 600,
}

local DAYLIGHT_LIGHTING = {
	ClockTime = 14,
	Brightness = 1.4,
	Ambient = Color3.fromRGB(130, 140, 160),
	OutdoorAmbient = Color3.fromRGB(140, 150, 170),
	FogStart = 200,
	FogEnd = 800,
}

-- Colors
local COLORS = {
	grass = Color3.fromRGB(60, 120, 50),
	dirt = Color3.fromRGB(101, 67, 33),
	wood = Color3.fromRGB(139, 90, 43),
	woodDark = Color3.fromRGB(101, 67, 33),
	roof = Color3.fromRGB(150, 50, 50),
	roofDark = Color3.fromRGB(100, 30, 30),
	wall = Color3.fromRGB(240, 230, 210),
	stone = Color3.fromRGB(150, 150, 150),
	wheat = Color3.fromRGB(218, 165, 32),
	corn = Color3.fromRGB(255, 215, 0),
	tractor = Color3.fromRGB(200, 50, 50),
	tractorDark = Color3.fromRGB(150, 30, 30),
	cow = Color3.fromRGB(100, 100, 100),
	pig = Color3.fromRGB(255, 192, 203),
	chicken = Color3.fromRGB(255, 255, 200),
}

-- Helper: Create a part
local function createPart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, parent: Instance): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.Grass
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- Helper: Create a model
local function createModel(name: string, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

-- Create ground plane (grass)
local function createGround(arenaModel: Model)
	local ground = createPart("Ground", Vector3.new(ARENA_SIZE_X, 1, ARENA_SIZE_Z), ARENA_ORIGIN, COLORS.grass, Enum.Material.Grass, arenaModel)
	return ground
end

-- Create tree border around edges
local function createTreeBorder(arenaModel: Model)
	local trees = createModel("TreeBorder", arenaModel)
	local halfX = ARENA_SIZE_X / 2
	local halfZ = ARENA_SIZE_Z / 2
	local treeSpacing = 12
	local treeSize = Vector3.new(8, 20, 8)
	local trunkSize = Vector3.new(3, 12, 3)
	
	-- North edge
	for x = -halfX + 10, halfX - 10, treeSpacing do
		local trunk = createPart("Trunk", trunkSize, ARENA_ORIGIN + Vector3.new(x, 6, halfZ - 5), COLORS.woodDark, Enum.Material.Wood, trees)
		local leaves = createPart("Leaves", treeSize, ARENA_ORIGIN + Vector3.new(x, 18, halfZ - 5), Color3.fromRGB(30, 100, 30), Enum.Material.Grass, trees)
	end
	
	-- South edge
	for x = -halfX + 10, halfX - 10, treeSpacing do
		local trunk = createPart("Trunk", trunkSize, ARENA_ORIGIN + Vector3.new(x, 6, -halfZ + 5), COLORS.woodDark, Enum.Material.Wood, trees)
		local leaves = createPart("Leaves", treeSize, ARENA_ORIGIN + Vector3.new(x, 18, -halfZ + 5), Color3.fromRGB(30, 100, 30), Enum.Material.Grass, trees)
	end
	
	-- East edge
	for z = -halfZ + 10, halfZ - 10, treeSpacing do
		local trunk = createPart("Trunk", trunkSize, ARENA_ORIGIN + Vector3.new(halfX - 5, 6, z), COLORS.woodDark, Enum.Material.Wood, trees)
		local leaves = createPart("Leaves", treeSize, ARENA_ORIGIN + Vector3.new(halfX - 5, 18, z), Color3.fromRGB(30, 100, 30), Enum.Material.Grass, trees)
	end
	
	-- West edge
	for z = -halfZ + 10, halfZ - 10, treeSpacing do
		local trunk = createPart("Trunk", trunkSize, ARENA_ORIGIN + Vector3.new(-halfX + 5, 6, z), COLORS.woodDark, Enum.Material.Wood, trees)
		local leaves = createPart("Leaves", treeSize, ARENA_ORIGIN + Vector3.new(-halfX + 5, 18, z), Color3.fromRGB(30, 100, 30), Enum.Material.Grass, trees)
	end
end

-- Create farmhouse
local function createFarmhouse(arenaModel: Model)
	local farmhouse = createModel("Farmhouse", arenaModel)
	local basePos = ARENA_ORIGIN + Vector3.new(-150, 0, -100)
	
	-- Foundation
	createPart("Foundation", Vector3.new(40, 2, 30), basePos + Vector3.new(0, 1, 0), COLORS.stone, Enum.Material.Concrete, farmhouse)
	
	-- Walls
	createPart("WallFront", Vector3.new(40, 20, 2), basePos + Vector3.new(0, 11, 15), COLORS.wall, Enum.Material.Plastic, farmhouse)
	createPart("WallBack", Vector3.new(40, 20, 2), basePos + Vector3.new(0, 11, -15), COLORS.wall, Enum.Material.Plastic, farmhouse)
	createPart("WallLeft", Vector3.new(2, 20, 30), basePos + Vector3.new(-19, 11, 0), COLORS.wall, Enum.Material.Plastic, farmhouse)
	createPart("WallRight", Vector3.new(2, 20, 30), basePos + Vector3.new(19, 11, 0), COLORS.wall, Enum.Material.Plastic, farmhouse)
	
	-- Roof
	local roof = createPart("Roof", Vector3.new(45, 2, 35), basePos + Vector3.new(0, 22, 0), COLORS.roof, Enum.Material.Plastic, farmhouse)
	roof.Orientation = Vector3.new(0, 0, 15)
	
	-- Door
	local door = createPart("Door", Vector3.new(6, 12, 1), basePos + Vector3.new(0, 7, 15.5), COLORS.woodDark, Enum.Material.Wood, farmhouse)
	
	-- Windows
	createPart("Window1", Vector3.new(6, 6, 1), basePos + Vector3.new(-12, 12, 15.5), Color3.fromRGB(100, 150, 255), Enum.Material.Glass, farmhouse)
	createPart("Window2", Vector3.new(6, 6, 1), basePos + Vector3.new(12, 12, 15.5), Color3.fromRGB(100, 150, 255), Enum.Material.Glass, farmhouse)
	
	return farmhouse
end

-- Create windmill in front of farmhouse
local function createWindmill(arenaModel: Model)
	local windmill = createModel("Windmill", arenaModel)
	local basePos = ARENA_ORIGIN + Vector3.new(-80, 0, -100)
	
	-- Base tower
	createPart("Tower", Vector3.new(8, 30, 8), basePos + Vector3.new(0, 15, 0), COLORS.stone, Enum.Material.Concrete, windmill)
	
	-- Top platform
	createPart("Platform", Vector3.new(12, 1, 12), basePos + Vector3.new(0, 30.5, 0), COLORS.wood, Enum.Material.Wood, windmill)
	
	-- Blades (4 blades)
	local bladeLength = 20
	local bladeWidth = 2
	for i = 0, 3 do
		local angle = i * 90
		local blade = createPart("Blade" .. i, Vector3.new(bladeLength, bladeWidth, 0.5), 
			basePos + Vector3.new(math.cos(math.rad(angle)) * bladeLength/2, 30.5, math.sin(math.rad(angle)) * bladeLength/2),
			Color3.fromRGB(200, 200, 200), Enum.Material.Metal, windmill)
		blade.Orientation = Vector3.new(0, angle, 0)
	end
	
	-- Center hub
	createPart("Hub", Vector3.new(3, 3, 3), basePos + Vector3.new(0, 30.5, 0), Color3.fromRGB(100, 100, 100), Enum.Material.Metal, windmill)
	
	return windmill
end

-- Create tractor
local function createTractor(arenaModel: Model)
	local tractor = createModel("Tractor", arenaModel)
	local basePos = ARENA_ORIGIN + Vector3.new(-50, 0, -80)
	
	-- Main body
	createPart("Body", Vector3.new(12, 6, 8), basePos + Vector3.new(0, 3, 0), COLORS.tractor, Enum.Material.Plastic, tractor)
	
	-- Engine/cab
	createPart("Cab", Vector3.new(6, 8, 6), basePos + Vector3.new(3, 5, 0), COLORS.tractorDark, Enum.Material.Plastic, tractor)
	
	-- Wheels (4 wheels)
	local wheelSize = Vector3.new(6, 6, 6)
	createPart("Wheel1", wheelSize, basePos + Vector3.new(-4, 3, 4), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, tractor)
	createPart("Wheel2", wheelSize, basePos + Vector3.new(-4, 3, -4), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, tractor)
	createPart("Wheel3", wheelSize, basePos + Vector3.new(4, 3, 4), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, tractor)
	createPart("Wheel4", wheelSize, basePos + Vector3.new(4, 3, -4), Color3.fromRGB(30, 30, 30), Enum.Material.Rubber, tractor)
	
	return tractor
end

-- Create cropland (rows of crops)
local function createCropland(arenaModel: Model)
	local cropland = createModel("Cropland", arenaModel)
	local basePos = ARENA_ORIGIN + Vector3.new(50, 0, -120)
	
	-- Create rows of crops
	for row = 0, 8 do
		for col = 0, 12 do
			local cropPos = basePos + Vector3.new(col * 8, 0, row * 6)
			-- Dirt base
			createPart("Dirt" .. row .. "_" .. col, Vector3.new(7, 0.5, 5), cropPos + Vector3.new(0, 0.25, 0), COLORS.dirt, Enum.Material.Ground, cropland)
			-- Crop (wheat or corn)
			local cropType = (row + col) % 2 == 0 and COLORS.wheat or COLORS.corn
			createPart("Crop" .. row .. "_" .. col, Vector3.new(0.3, 4, 0.3), cropPos + Vector3.new(0, 2.5, 0), cropType, Enum.Material.Grass, cropland)
			createPart("Crop2" .. row .. "_" .. col, Vector3.new(0.3, 4, 0.3), cropPos + Vector3.new(1.5, 2.5, -1.5), cropType, Enum.Material.Grass, cropland)
			createPart("Crop3" .. row .. "_" .. col, Vector3.new(0.3, 4, 0.3), cropPos + Vector3.new(-1.5, 2.5, 1.5), cropType, Enum.Material.Grass, cropland)
		end
	end
	
	return cropland
end

-- Create animal pen with fence and animals
local function createAnimalPen(arenaModel: Model)
	local pen = createModel("AnimalPen", arenaModel)
	local basePos = ARENA_ORIGIN + Vector3.new(120, 0, 100)
	local penSize = 60
	
	-- Fence posts and rails
	local postSize = Vector3.new(2, 4, 2)
	local railSize = Vector3.new(2, 1, penSize)
	local postSpacing = 8
	
	-- North fence
	for x = 0, penSize, postSpacing do
		createPart("PostN" .. x, postSize, basePos + Vector3.new(x - penSize/2, 2, penSize/2), COLORS.wood, Enum.Material.Wood, pen)
	end
	for x = 0, penSize - postSpacing, postSpacing do
		createPart("RailN" .. x, railSize, basePos + Vector3.new(x - penSize/2 + postSpacing/2, 3.5, penSize/2), COLORS.woodDark, Enum.Material.Wood, pen)
	end
	
	-- South fence
	for x = 0, penSize, postSpacing do
		createPart("PostS" .. x, postSize, basePos + Vector3.new(x - penSize/2, 2, -penSize/2), COLORS.wood, Enum.Material.Wood, pen)
	end
	for x = 0, penSize - postSpacing, postSpacing do
		createPart("RailS" .. x, railSize, basePos + Vector3.new(x - penSize/2 + postSpacing/2, 3.5, -penSize/2), COLORS.woodDark, Enum.Material.Wood, pen)
	end
	
	-- East fence
	for z = 0, penSize, postSpacing do
		createPart("PostE" .. z, postSize, basePos + Vector3.new(penSize/2, 2, z - penSize/2), COLORS.wood, Enum.Material.Wood, pen)
	end
	for z = 0, penSize - postSpacing, postSpacing do
		local rail = createPart("RailE" .. z, Vector3.new(penSize, 1, 2), basePos + Vector3.new(penSize/2, 3.5, z - penSize/2 + postSpacing/2), COLORS.woodDark, Enum.Material.Wood, pen)
	end
	
	-- West fence
	for z = 0, penSize, postSpacing do
		createPart("PostW" .. z, postSize, basePos + Vector3.new(-penSize/2, 2, z - penSize/2), COLORS.wood, Enum.Material.Wood, pen)
	end
	for z = 0, penSize - postSpacing, postSpacing do
		local rail = createPart("RailW" .. z, Vector3.new(penSize, 1, 2), basePos + Vector3.new(-penSize/2, 3.5, z - penSize/2 + postSpacing/2), COLORS.woodDark, Enum.Material.Wood, pen)
	end
	
	-- Gate
	local gate = createPart("Gate", Vector3.new(6, 4, 1), basePos + Vector3.new(0, 2, penSize/2), COLORS.woodDark, Enum.Material.Wood, pen)
	
	-- Animals inside pen
	local animals = createModel("Animals", pen)
	-- Cows
	for i = 1, 4 do
		local cowPos = basePos + Vector3.new((i - 2.5) * 12, 0, -10)
		local cow = createModel("Cow" .. i, animals)
		createPart("Body", Vector3.new(4, 3, 6), cowPos + Vector3.new(0, 1.5, 0), COLORS.cow, Enum.Material.Plastic, cow)
		createPart("Head", Vector3.new(2, 2, 2), cowPos + Vector3.new(0, 2, 3), COLORS.cow, Enum.Material.Plastic, cow)
		createPart("Leg1", Vector3.new(0.8, 2, 0.8), cowPos + Vector3.new(-1.5, 0.5, -2), COLORS.cow, Enum.Material.Plastic, cow)
		createPart("Leg2", Vector3.new(0.8, 2, 0.8), cowPos + Vector3.new(1.5, 0.5, -2), COLORS.cow, Enum.Material.Plastic, cow)
		createPart("Leg3", Vector3.new(0.8, 2, 0.8), cowPos + Vector3.new(-1.5, 0.5, 2), COLORS.cow, Enum.Material.Plastic, cow)
		createPart("Leg4", Vector3.new(0.8, 2, 0.8), cowPos + Vector3.new(1.5, 0.5, 2), COLORS.cow, Enum.Material.Plastic, cow)
	end
	
	-- Pigs
	for i = 1, 3 do
		local pigPos = basePos + Vector3.new((i - 2) * 10, 0, 10)
		local pig = createModel("Pig" .. i, animals)
		createPart("Body", Vector3.new(3, 2, 4), pigPos + Vector3.new(0, 1, 0), COLORS.pig, Enum.Material.Plastic, pig)
		createPart("Head", Vector3.new(1.5, 1.5, 1.5), pigPos + Vector3.new(0, 1.5, 2), COLORS.pig, Enum.Material.Plastic, pig)
	end
	
	-- Chickens
	for i = 1, 6 do
		local chickenPos = basePos + Vector3.new((i - 3.5) * 8, 0, -20)
		local chicken = createModel("Chicken" .. i, animals)
		createPart("Body", Vector3.new(1.5, 1.5, 1.5), chickenPos + Vector3.new(0, 0.75, 0), COLORS.chicken, Enum.Material.Plastic, chicken)
		createPart("Head", Vector3.new(0.5, 0.8, 0.5), chickenPos + Vector3.new(0, 1.3, 0.8), Color3.fromRGB(255, 200, 150), Enum.Material.Plastic, chicken)
		createPart("Leg1", Vector3.new(0.3, 0.8, 0.3), chickenPos + Vector3.new(-0.5, 0.2, 0), Color3.fromRGB(255, 200, 100), Enum.Material.Plastic, chicken)
		createPart("Leg2", Vector3.new(0.3, 0.8, 0.3), chickenPos + Vector3.new(0.5, 0.2, 0), Color3.fromRGB(255, 200, 100), Enum.Material.Plastic, chicken)
	end
	
	return pen
end

-- Create spawn point
local function createSpawnPoint(arenaModel: Model)
	local spawn = Instance.new("Part")
	spawn.Name = "SpawnPoint"
	spawn.Size = Vector3.new(20, 3, 20)
	spawn.Position = ARENA_ORIGIN + Vector3.new(0, 1.5, 0)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = true
	spawn.Parent = arenaModel
	return spawn
end

-- Create return to hub pad
local function createReturnPad(arenaModel: Model)
	local pad = Instance.new("Part")
	pad.Name = "ReturnToHubPad"
	pad.Size = Vector3.new(10, 2, 8)
	pad.Position = ARENA_ORIGIN + Vector3.new(ARENA_SIZE_X/2 - 20, 1, 0)
	pad.Anchored = true
	pad.Color = Color3.fromRGB(50, 80, 50)
	pad.Material = Enum.Material.Grass
	pad.Transparency = 0.3
	pad.Parent = arenaModel

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ReturnPrompt"
	prompt.ActionText = "Return to Hub"
	prompt.ObjectText = "Exit Arena"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = pad

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = pad
	billboard.Adornee = pad

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Return to Hub\n[ E ]"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	return pad
end

function Arena1Builder.build()
	local existing = Workspace:FindFirstChild("Arena1")
	if existing then existing:Destroy() end

	local arenaModel = Instance.new("Model")
	arenaModel.Name = "Arena1"
	arenaModel.Parent = Workspace

	-- Build all components
	createGround(arenaModel)
	createTreeBorder(arenaModel)
	createFarmhouse(arenaModel)
	createWindmill(arenaModel)
	createTractor(arenaModel)
	createCropland(arenaModel)
	createAnimalPen(arenaModel)
	createSpawnPoint(arenaModel)
	createReturnPad(arenaModel)

	print("[Arena1Builder] Arena 1 built at", ARENA_ORIGIN, "- Farmland arena ready!")
	return arenaModel
end

-- Position to teleport player to
function Arena1Builder.getSpawnPosition(): Vector3
	return ARENA_ORIGIN + Vector3.new(0, 3, 0)
end

function Arena1Builder.getOrigin(): Vector3
	return ARENA_ORIGIN
end

-- Switch to daylight (arena) or restore hub evening
function Arena1Builder.setDaylight(isDaylight: boolean)
	local L = Lighting
	if isDaylight then
		L.ClockTime = DAYLIGHT_LIGHTING.ClockTime
		L.Brightness = DAYLIGHT_LIGHTING.Brightness
		L.Ambient = DAYLIGHT_LIGHTING.Ambient
		L.OutdoorAmbient = DAYLIGHT_LIGHTING.OutdoorAmbient
		L.FogStart = DAYLIGHT_LIGHTING.FogStart
		L.FogEnd = DAYLIGHT_LIGHTING.FogEnd
		print("[Arena1Builder] Lighting set to daylight")
	else
		L.ClockTime = HUB_LIGHTING.ClockTime
		L.Brightness = HUB_LIGHTING.Brightness
		L.Ambient = HUB_LIGHTING.Ambient
		L.OutdoorAmbient = HUB_LIGHTING.OutdoorAmbient
		L.FogStart = HUB_LIGHTING.FogStart
		L.FogEnd = HUB_LIGHTING.FogEnd
		print("[Arena1Builder] Lighting restored to hub (evening)")
	end
end

return Arena1Builder
