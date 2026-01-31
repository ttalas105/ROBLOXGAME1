--[[
	Sell Shop: sell weapons for coins. Lists owned weapons with sell price.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigWeapons = require(Shared.Config.Weapons)
local Create = require(script.Parent.Parent.CreateGui)

local SellShop = {}
local frame: Frame? = nil
local coinsLabel: TextLabel? = nil
local weaponsContainer: ScrollingFrame? = nil
local remotes: any = nil

local weaponById: { [string]: any } = {}
for _, w in ConfigWeapons do weaponById[w.id] = w end

local function onSell(weaponInstanceId: string, sellPrice: number, row: Frame, button: TextButton)
	button.Text = "..."
	button.Active = false
	local result = remotes.SellWeapon:InvokeServer(weaponInstanceId)
	button.Active = true
	if result.success then
		coinsLabel.Text = "Coins: " .. tostring(result.coinsLeft)
		row:Destroy()
	else
		button.Text = "Sell"
	end
end

function SellShop.Build(parent: Instance, r: any)
	remotes = r
	local main = Create.frame("SellShop", parent, { Size = UDim2.new(0.8, 0, 0.7, 0), Position = UDim2.new(0.1, 0, 0.15, 0), Visible = false })
	Create.uICorner(main, 12)
	Create.uIPadding(main, 20)
	frame = main

	local title = Create.textLabel("Title", main, "Sell Weapons for Coins", { Size = UDim2.new(1, 0, 0, 36), TextSize = 24 })
	coinsLabel = Create.textLabel("Coins", main, "Coins: 0", { Size = UDim2.new(1, 0, 0, 24) })
	coinsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

	local scroll = Create.scrollingFrame("WeaponsList", main, { Size = UDim2.new(1, -10, 1, -100), Position = UDim2.new(0, 0, 0, 70) })
	Create.uICorner(scroll, 8)
	Create.uIListLayout(scroll, 10)
	weaponsContainer = scroll

	local closeBtn = Create.textButton("Close", main, "Close", { Size = UDim2.new(0, 120, 0, 40), Position = UDim2.new(1, -140, 1, -50) })
	Create.uICorner(closeBtn, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	closeBtn.MouseButton1Click:Connect(function()
		SellShop.Hide()
	end)

	return main
end

function SellShop.RefreshWeapons()
	if not weaponsContainer or not remotes then return end
	for _, child in weaponsContainer:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
	local data = remotes.GetPlayerData:InvokeServer()
	if not data or not data.weapons then return end
	for _, w in data.weapons do
		local def = weaponById[w.weaponId]
		if not def then continue end
		local row = Create.frame("WeaponRow_" .. w.id, weaponsContainer, { Size = UDim2.new(1, -20, 0, 56), BackgroundColor3 = Color3.fromRGB(50, 50, 55) })
		Create.uICorner(row, 8)
		Create.uIPadding(row, 12)
		Create.textLabel("Name", row, def.name, { Size = UDim2.new(0.4, -20, 1, 0) })
		Create.textLabel("Rarity", row, def.rarity, { Size = UDim2.new(0.25, -20, 1, 0), TextColor3 = Color3.fromRGB(200, 200, 200) })
		Create.textLabel("Value", row, string.format("%d coins", def.sellPrice), { Size = UDim2.new(0.25, -20, 1, 0), TextColor3 = Color3.fromRGB(255, 200, 100) })
		local sellBtn = Create.textButton("Sell", row, "Sell", { Size = UDim2.new(0, 80, 0, 36), Position = UDim2.new(1, -92, 0.5, -18) })
		Create.uICorner(sellBtn, 6)
		sellBtn.MouseButton1Click:Connect(function()
			onSell(w.id, def.sellPrice, row, sellBtn)
		end)
	end
end

function SellShop.Show()
	if frame then frame.Visible = true end
	if remotes then
		local data = remotes.GetPlayerData:InvokeServer()
		if data and coinsLabel then coinsLabel.Text = "Coins: " .. tostring(data.coins) end
	end
	SellShop.RefreshWeapons()
end

function SellShop.Hide()
	if frame then frame.Visible = false end
end

return SellShop
