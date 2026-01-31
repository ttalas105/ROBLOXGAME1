--[[
	Main shop hub: "Shops" button opens menu; each option opens one of the three shop fronts.
]]
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemotesModule = require(Shared:WaitForChild("Remotes"))
local Create = require(script.Parent.Parent.CreateGui)
local CaseShop = require(script.Parent:WaitForChild("CaseShop"))
local CaseOpening = require(script.Parent:WaitForChild("CaseOpening"))
local SellShop = require(script.Parent:WaitForChild("SellShop"))
local UpgradesShop = require(script.Parent:WaitForChild("UpgradesShop"))

local ShopsController = {}
local screenGui: ScreenGui? = nil
local menuFrame: Frame? = nil
local remotes: any = nil

local function hideAllShops()
	CaseShop.Hide()
	CaseOpening.Hide()
	SellShop.Hide()
	UpgradesShop.Hide()
	if menuFrame then menuFrame.Visible = false end
end

local function showMenu()
	hideAllShops()
	if menuFrame then menuFrame.Visible = true end
end

function ShopsController.Init()
	remotes = RemotesModule.WaitFor()

	local gui = Instance.new("ScreenGui")
	gui.Name = "ShopGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PlayerGui
	screenGui = gui

	-- Main container for all shop panels (centered)
	local container = Create.frame("ShopContainer", gui, { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 })
	container.Parent = gui

	-- Build each shop (they start hidden)
	CaseShop.Build(container, remotes)
	CaseOpening.Build(container, remotes)
	SellShop.Build(container, remotes)
	UpgradesShop.Build(container, remotes)

	-- "Shops" button (bottom-right or top-right)
	local openBtn = Create.textButton("OpenShops", gui, "Shops", { Size = UDim2.new(0, 140, 0, 50), Position = UDim2.new(1, -160, 0, 20) })
	Create.uICorner(openBtn, 10)
	openBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
	openBtn.TextSize = 20
	openBtn.MouseButton1Click:Connect(function()
		showMenu()
	end)

	-- Menu popup: Buy Cases | Open Cases | Sell Weapons | Upgrades
	local menu = Create.frame("ShopMenu", gui, { Size = UDim2.new(0, 280, 0, 320), Position = UDim2.new(0.5, -140, 0.5, -160), BackgroundColor3 = Color3.fromRGB(45, 45, 50), Visible = false })
	Create.uICorner(menu, 12)
	Create.uIPadding(menu, 24)
	menuFrame = menu

	local menuTitle = Create.textLabel("Title", menu, "Shop Fronts", { Size = UDim2.new(1, 0, 0, 36), TextSize = 22 })
	menuTitle.TextXAlignment = Enum.TextXAlignment.Center

	local btnH = 44
	local pad = 12
	local y = 50
	local function addMenuButton(text: string, callback: () -> ())
		local btn = Create.textButton("Btn_" .. text, menu, text, { Size = UDim2.new(1, -20, 0, btnH), Position = UDim2.new(0, 10, 0, y) })
		Create.uICorner(btn, 8)
		btn.MouseButton1Click:Connect(function()
			hideAllShops()
			callback()
		end)
		y = y + btnH + pad
	end

	addMenuButton("Buy Cases (Keys)", function() CaseShop.Show() end)
	addMenuButton("Open Cases", function() CaseOpening.Show() end)
	addMenuButton("Sell Weapons (Coins)", function() SellShop.Show() end)
	addMenuButton("Upgrades Shop", function() UpgradesShop.Show() end)

	local closeMenuBtn = Create.textButton("CloseMenu", menu, "Close", { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 1, -50) })
	Create.uICorner(closeMenuBtn, 8)
	closeMenuBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	closeMenuBtn.MouseButton1Click:Connect(function()
		menuFrame.Visible = false
	end)
end

return ShopsController
