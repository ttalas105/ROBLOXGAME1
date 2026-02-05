--[[
	BaseClient: Client-side logic for home base system
	- Income collection notifications
	- Base claimed notifications
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BaseClient = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get remotes folder
local function getRemotesFolder(): Folder?
	return ReplicatedStorage:FindFirstChild("ShopRemotes")
end

-- Show income notification (floating text)
function BaseClient.showIncomeNotification(amount: number)
	if not playerGui then return end
	
	-- Create floating text
	local notification = Instance.new("ScreenGui")
	notification.Name = "IncomeNotification"
	notification.ResetOnSpawn = false
	notification.Parent = playerGui
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 250, 0, 60)
	label.Position = UDim2.new(0.5, -125, 0.3, 0)
	label.BackgroundTransparency = 1
	label.Text = "+" .. amount .. " Keys Collected!"
	label.TextColor3 = Color3.fromRGB(100, 255, 100)
	label.TextSize = 32
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = notification
	
	-- Animate
	TweenService:Create(label, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -125, 0.2, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1
	}):Play()
	
	task.delay(1.5, function()
		notification:Destroy()
	end)
end

-- Show base claimed notification
function BaseClient.showBaseClaimedNotification(plotNumber: number)
	if not playerGui then return end
	
	local notification = Instance.new("ScreenGui")
	notification.Name = "BaseClaimedNotification"
	notification.ResetOnSpawn = false
	notification.Parent = playerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 400, 0, 80)
	frame.Position = UDim2.new(0.5, -200, 0.35, 0)
	frame.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = notification
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.6, 0)
	label.BackgroundTransparency = 1
	label.Text = "Base Claimed!"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.Parent = frame
	
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0.4, 0)
	subtitle.Position = UDim2.new(0, 0, 0.6, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Equip a weapon and press E on a pedestal to place it"
	subtitle.TextColor3 = Color3.fromRGB(200, 255, 200)
	subtitle.TextSize = 14
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Parent = frame
	
	-- Animate out
	task.delay(3, function()
		TweenService:Create(frame, TweenInfo.new(0.5), {
			Position = UDim2.new(0.5, -200, 0.3, 0),
			BackgroundTransparency = 1
		}):Play()
		TweenService:Create(label, TweenInfo.new(0.5), {
			TextTransparency = 1
		}):Play()
		TweenService:Create(subtitle, TweenInfo.new(0.5), {
			TextTransparency = 1
		}):Play()
		task.delay(0.5, function()
			notification:Destroy()
		end)
	end)
end

-- Build/initialize
function BaseClient.build()
	BaseClient.connectEvents()
	print("[BaseClient] Initialized")
end

-- Connect to remote events
function BaseClient.connectEvents()
	local remotes = getRemotesFolder()
	if not remotes then
		-- Wait for remotes
		task.spawn(function()
			remotes = ReplicatedStorage:WaitForChild("ShopRemotes", 10)
			if remotes then
				BaseClient.connectEventsInternal(remotes)
			end
		end)
	else
		BaseClient.connectEventsInternal(remotes)
	end
end

function BaseClient.connectEventsInternal(remotes: Folder)
	-- Income earned notification
	local incomeEarned = remotes:FindFirstChild("BaseIncomeEarned")
	if incomeEarned and incomeEarned:IsA("RemoteEvent") then
		incomeEarned.OnClientEvent:Connect(function(amount: number)
			BaseClient.showIncomeNotification(amount)
		end)
	end
	
	-- Base claimed notification
	local baseClaimed = remotes:FindFirstChild("BaseClaimed")
	if baseClaimed and baseClaimed:IsA("RemoteEvent") then
		baseClaimed.OnClientEvent:Connect(function(plotNumber: number, userId: number, ownerName: string)
			if userId == player.UserId then
				BaseClient.showBaseClaimedNotification(plotNumber)
			end
		end)
	end
end

-- Update state (called from main client) - no longer needed but kept for compatibility
function BaseClient.updateState(state: any)
	-- No-op
end

return BaseClient
