--[[
	Upgrades Shop: spend coins on upgrades (e.g. health potions).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigUpgrades = require(Shared.Config.Upgrades)
local Create = require(script.Parent.Parent.CreateGui)

local UpgradesShop = {}
local frame: Frame? = nil
local coinsLabel: TextLabel? = nil
local remotes: any = nil

local function onBuyUpgrade(upgradeId: string, coinCost: number, button: TextButton)
	button.Text = "..."
	button.Active = false
	local result = remotes.BuyUpgrade:InvokeServer(upgradeId)
	button.Active = true
	if result.success then
		coinsLabel.Text = "Coins: " .. tostring(result.coinsLeft)
		button.Text = string.format("Buy (%d coins)", coinCost)
	else
		button.Text = result.error or "Failed"
		task.delay(1, function()
			button.Text = string.format("Buy (%d coins)", coinCost)
		end)
	end
end

function UpgradesShop.Build(parent: Instance, r: any)
	remotes = r
	local main = Create.frame("UpgradesShop", parent, { Size = UDim2.new(0.8, 0, 0.7, 0), Position = UDim2.new(0.1, 0, 0.15, 0), Visible = false })
	Create.uICorner(main, 12)
	Create.uIPadding(main, 20)
	frame = main

	local title = Create.textLabel("Title", main, "Upgrades Shop", { Size = UDim2.new(1, 0, 0, 36), TextSize = 24 })
	coinsLabel = Create.textLabel("Coins", main, "Coins: 0", { Size = UDim2.new(1, 0, 0, 24) })
	coinsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

	local scroll = Create.scrollingFrame("UpgradesList", main, { Size = UDim2.new(1, -10, 1, -100), Position = UDim2.new(0, 0, 0, 70) })
	Create.uICorner(scroll, 8)
	Create.uIListLayout(scroll, 10)

	for _, upgrade in ConfigUpgrades do
		local row = Create.frame("UpgradeRow_" .. upgrade.id, scroll, { Size = UDim2.new(1, -20, 0, 56), BackgroundColor3 = Color3.fromRGB(50, 50, 55) })
		Create.uICorner(row, 8)
		Create.uIPadding(row, 12)
		Create.textLabel("Name", row, upgrade.name, { Size = UDim2.new(0.5, -20, 1, 0) })
		Create.textLabel("Cost", row, string.format("%d coins", upgrade.coinCost), { Size = UDim2.new(0.3, -20, 1, 0), TextColor3 = Color3.fromRGB(255, 200, 100) })
		local buyBtn = Create.textButton("Buy", row, string.format("Buy (%d coins)", upgrade.coinCost), { Size = UDim2.new(0, 120, 0, 36), Position = UDim2.new(1, -132, 0.5, -18) })
		Create.uICorner(buyBtn, 6)
		buyBtn.MouseButton1Click:Connect(function()
			onBuyUpgrade(upgrade.id, upgrade.coinCost, buyBtn)
		end)
	end

	local closeBtn = Create.textButton("Close", main, "Close", { Size = UDim2.new(0, 120, 0, 40), Position = UDim2.new(1, -140, 1, -50) })
	Create.uICorner(closeBtn, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	closeBtn.MouseButton1Click:Connect(function()
		UpgradesShop.Hide()
	end)

	return main
end

function UpgradesShop.Show()
	if frame then frame.Visible = true end
	if remotes then
		local data = remotes.GetPlayerData:InvokeServer()
		if data and coinsLabel then coinsLabel.Text = "Coins: " .. tostring(data.coins) end
	end
end

function UpgradesShop.Hide()
	if frame then frame.Visible = false end
end

return UpgradesShop
