--[[
	Case Shop: spend keys to buy cases. Shows available cases and key balance.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigCases = require(Shared.Config.Cases)
local Create = require(script.Parent.Parent.CreateGui)

local CaseShop = {}
local frame: Frame? = nil
local keyLabel: TextLabel? = nil
local casesContainer: ScrollingFrame? = nil
local remotes: any = nil

local function onBuyCase(caseId: string, keyCost: number, button: TextButton)
	button.Text = "..."
	button.Active = false
	local result = remotes.BuyCase:InvokeServer(caseId)
	button.Active = true
	if result.success then
		button.Text = "Bought!"
		keyLabel.Text = "Keys: " .. tostring(result.keysLeft)
		task.delay(0.5, function()
			button.Text = string.format("Buy (%d keys)", keyCost)
		end)
	else
		button.Text = result.error or "Failed"
		task.delay(1, function()
			button.Text = string.format("Buy (%d keys)", keyCost)
		end)
	end
end

function CaseShop.Build(parent: Instance, r: any)
	remotes = r
	local main = Create.frame("CaseShop", parent, { Size = UDim2.new(0.8, 0, 0.7, 0), Position = UDim2.new(0.1, 0, 0.15, 0), Visible = false })
	Create.uICorner(main, 12)
	Create.uIPadding(main, 20)
	frame = main

	local title = Create.textLabel("Title", main, "Case Shop — Buy with Keys", { Size = UDim2.new(1, 0, 0, 36), TextSize = 24 })
	keyLabel = Create.textLabel("Keys", main, "Keys: 0", { Size = UDim2.new(1, 0, 0, 24) })
	keyLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

	local scroll = Create.scrollingFrame("CasesList", main, { Size = UDim2.new(1, -10, 1, -100), Position = UDim2.new(0, 0, 0, 70) })
	Create.uICorner(scroll, 8)
	Create.uIListLayout(scroll, 10)
	casesContainer = scroll

	local closeBtn = Create.textButton("Close", main, "Close", { Size = UDim2.new(0, 120, 0, 40), Position = UDim2.new(1, -140, 1, -50) })
	Create.uICorner(closeBtn, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	closeBtn.MouseButton1Click:Connect(function()
		CaseShop.Hide()
	end)

	for _, caseConfig in ConfigCases do
		if caseConfig.unlockCondition then continue end -- skip locked for now
		local row = Create.frame("CaseRow_" .. caseConfig.id, scroll, { Size = UDim2.new(1, -20, 0, 56), BackgroundColor3 = Color3.fromRGB(50, 50, 55) })
		Create.uICorner(row, 8)
		Create.uIPadding(row, 12)
		local nameLbl = Create.textLabel("Name", row, caseConfig.name, { Size = UDim2.new(0.5, -20, 1, 0), Position = UDim2.new(0, 0, 0, 0) })
		local costLbl = Create.textLabel("Cost", row, string.format("%d keys", caseConfig.keyCost), { Size = UDim2.new(0.3, -20, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), TextColor3 = Color3.fromRGB(255, 200, 100) })
		local buyBtn = Create.textButton("Buy", row, string.format("Buy (%d keys)", caseConfig.keyCost), { Size = UDim2.new(0, 100, 0, 36), Position = UDim2.new(1, -112, 0.5, -18) })
		Create.uICorner(buyBtn, 6)
		buyBtn.MouseButton1Click:Connect(function()
			onBuyCase(caseConfig.id, caseConfig.keyCost, buyBtn)
		end)
	end

	return main
end

function CaseShop.Show()
	if frame then frame.Visible = true end
	-- Refresh key count
	if remotes then
		local data = remotes.GetPlayerData:InvokeServer()
		if data and keyLabel then keyLabel.Text = "Keys: " .. tostring(data.keys) end
	end
end

function CaseShop.Hide()
	if frame then frame.Visible = false end
end

return CaseShop
