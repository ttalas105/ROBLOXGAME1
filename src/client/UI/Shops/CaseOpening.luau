--[[
	Case Opening: select a case to open, play animation, show "1 in X" message and weapon name/rarity.
]]
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Create = require(script.Parent.Parent.CreateGui)

local CaseOpening = {}
local frame: Frame? = nil
local overlay: Frame? = nil -- full-screen reveal overlay
local casesContainer: ScrollingFrame? = nil
local remotes: any = nil

local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(80, 200, 120),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(180, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
}

local function playRevealAnimation(weaponName: string, rarity: string, oddsDenominator: number, onDone: () -> ())
	-- Full-screen overlay: dark -> case shake -> reveal weapon + "1 in X"
	if not overlay then return onDone() end
	overlay.Visible = true
	local revealFrame = overlay:FindFirstChild("RevealFrame")
	local oddsLabel = overlay:FindFirstChild("OddsLabel") :: TextLabel?
	local weaponLabel = overlay:FindFirstChild("WeaponLabel") :: TextLabel?
	local rarityLabel = overlay:FindFirstChild("RarityLabel") :: TextLabel?
	if not revealFrame or not oddsLabel or not weaponLabel then onDone() return end

	revealFrame.BackgroundTransparency = 1
	oddsLabel.Text = ""
	weaponLabel.Text = ""
	if rarityLabel then rarityLabel.Text = ""

	-- Phase 1: "Opening..."
	local phase1 = overlay:FindFirstChild("Phase1Label") :: TextLabel?
	if phase1 then phase1.Text = "Opening..." phase1.Visible = true end
	TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 0.2 }):Play()
	task.wait(0.8)

	-- Phase 2: case shake (simulate with small position tweens)
	local rev = revealFrame
	local origPos = rev.Position
	for _ = 1, 4 do
		TweenService:Create(rev, TweenInfo.new(0.05), { Position = origPos + UDim2.new(0, 4, 0, 0) }):Play()
		task.wait(0.05)
		TweenService:Create(rev, TweenInfo.new(0.05), { Position = origPos - UDim2.new(0, 4, 0, 0) }):Play()
		task.wait(0.05)
	end
	rev.Position = origPos
	if phase1 then phase1.Visible = false end
	task.wait(0.2)

	-- Phase 3: reveal
	revealFrame.BackgroundColor3 = RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
	revealFrame.BackgroundTransparency = 0.3
	weaponLabel.Text = weaponName
	weaponLabel.TextColor3 = RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
	if rarityLabel then rarityLabel.Text = rarity rarityLabel.TextColor3 = RARITY_COLORS[rarity] or Color3.new(1, 1, 1) end
	oddsLabel.Text = string.format("1 in %s", tostring(oddsDenominator))
	oddsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	revealFrame.Size = UDim2.new(0, 20, 0, 20)
	TweenService:Create(revealFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = UDim2.new(0.4, 0, 0.35, 0) }):Play()
	task.wait(1.5)

	-- Phase 4: fade out
	TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	task.wait(0.5)
	overlay.Visible = false
	onDone()
end

local function openCase(caseInstanceId: string, caseId: string, row: Frame)
	row.Visible = false
	local result = remotes.OpenCase:InvokeServer(caseInstanceId)
	if result.success then
		playRevealAnimation(result.weaponName, result.rarity, result.oddsDenominator, function()
			CaseOpening.RefreshCases()
		end)
	else
		row.Visible = true
		-- could show error
	end
end

function CaseOpening.Build(parent: Instance, r: any)
	remotes = r
	local main = Create.frame("CaseOpening", parent, { Size = UDim2.new(0.8, 0, 0.7, 0), Position = UDim2.new(0.1, 0, 0.15, 0), Visible = false })
	Create.uICorner(main, 12)
	Create.uIPadding(main, 20)
	frame = main

	local title = Create.textLabel("Title", main, "Open a Case", { Size = UDim2.new(1, 0, 0, 36), TextSize = 24 })
	local scroll = Create.scrollingFrame("CasesList", main, { Size = UDim2.new(1, -10, 1, -100), Position = UDim2.new(0, 0, 0, 50) })
	Create.uICorner(scroll, 8)
	Create.uIListLayout(scroll, 10)
	casesContainer = scroll

	local closeBtn = Create.textButton("Close", main, "Close", { Size = UDim2.new(0, 120, 0, 40), Position = UDim2.new(1, -140, 1, -50) })
	Create.uICorner(closeBtn, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	closeBtn.MouseButton1Click:Connect(function()
		CaseOpening.Hide()
	end)

	-- Full-screen overlay for reveal
	local overlayFrame = Create.frame("CaseRevealOverlay", parent, { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 100 })
	overlay = overlayFrame
	local phase1 = Create.textLabel("Phase1Label", overlayFrame, "Opening...", { Size = UDim2.new(0.5, 0, 0.1, 0), Position = UDim2.new(0.25, 0, 0.4, 0), TextSize = 28, ZIndex = 101 })
	phase1.Visible = false
	local revealFrame = Create.frame("RevealFrame", overlayFrame, { Size = UDim2.new(0.4, 0, 0.35, 0), Position = UDim2.new(0.3, 0, 0.25, 0), BackgroundColor3 = Color3.new(0.2, 0.2, 0.2), ZIndex = 101 })
	Create.uICorner(revealFrame, 16)
	local weaponLabel = Create.textLabel("WeaponLabel", revealFrame, "", { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0.35, 0), TextSize = 32, ZIndex = 102 })
	local rarityLabel = Create.textLabel("RarityLabel", revealFrame, "", { Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0.5, 0), TextSize = 22, ZIndex = 102 })
	local oddsLabel = Create.textLabel("OddsLabel", revealFrame, "", { Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0.65, 0), TextSize = 24, ZIndex = 102 })
	oddsLabel.TextColor3 = Color3.fromRGB(255, 220, 100)

	return main
end

function CaseOpening.RefreshCases()
	if not casesContainer or not remotes then return end
	for _, child in casesContainer:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
	local data = remotes.GetPlayerData:InvokeServer()
	if not data or not data.cases then return end
	local ConfigCases = require(Shared.Config.Cases)
	local caseNameById = {}
	for _, cas in ConfigCases do caseNameById[cas.id] = cas.name end
	for _, c in data.cases do
		local row = Create.frame("CaseRow_" .. c.id, casesContainer, { Size = UDim2.new(1, -20, 0, 50), BackgroundColor3 = Color3.fromRGB(50, 50, 55) })
		Create.uICorner(row, 8)
		Create.uIPadding(row, 12)
		Create.textLabel("Name", row, caseNameById[c.caseId] or c.caseId, { Size = UDim2.new(0.6, -20, 1, 0) })
		local openBtn = Create.textButton("Open", row, "Open", { Size = UDim2.new(0, 80, 0, 32), Position = UDim2.new(1, -90, 0.5, -16) })
		Create.uICorner(openBtn, 6)
		openBtn.MouseButton1Click:Connect(function()
			openCase(c.id, c.caseId, row)
		end)
	end
end

function CaseOpening.Show()
	if frame then frame.Visible = true end
	CaseOpening.RefreshCases()
end

function CaseOpening.Hide()
	if frame then frame.Visible = false end
end

return CaseOpening
