--[[
	Dash: Press Q to dash 10 studs in look direction. Includes dash animation and cooldown.
]]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local DASH_DISTANCE = 10
local DASH_DURATION = 0.15
local DASH_COOLDOWN = 1.2
-- Roblox catalog animation (Sprint) - replace with your own dash animation ID if desired
local DASH_ANIMATION_ID = "rbxassetid://616158929"

local player = Players.LocalPlayer
local dashCooldownEnd = 0
local dashAnimTrack: AnimationTrack? = nil

local function getCharacter()
	return player.Character
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function loadDashAnimation()
	local humanoid = getHumanoid()
	if not humanoid then return nil end
	if dashAnimTrack then return dashAnimTrack end
	local anim = Instance.new("Animation")
	anim.AnimationId = DASH_ANIMATION_ID
	dashAnimTrack = humanoid:LoadAnimation(anim)
	return dashAnimTrack
end

-- When character respawns, clear cached animation
player.CharacterAdded:Connect(function()
	dashAnimTrack = nil
end)

local function performDash()
	local root = getRoot()
	local humanoid = getHumanoid()
	if not root or not humanoid then return end
	if humanoid.Health <= 0 then return end

	local now = tick()
	if now < dashCooldownEnd then return end

	-- Direction: camera look, flattened to horizontal
	local cam = workspace.CurrentCamera
	local look = if cam then cam.CFrame.LookVector else root.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.01 then return end
	look = look.Unit

	local startPos = root.Position
	local endPos = startPos + look * DASH_DISTANCE

	-- Optional: raycast to stop at walls
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { player.Character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(startPos, look * DASH_DISTANCE, params)
	if result then
		endPos = result.Position - look * 2
	end

	dashCooldownEnd = now + DASH_COOLDOWN

	-- Play dash animation
	local track = loadDashAnimation()
	if track then
		track:Play()
		track.Priority = Enum.AnimationPriority.Action
	end

	-- Tween position for smooth dash
	local tween = TweenService:Create(
		root,
		TweenInfo.new(DASH_DURATION, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(endPos) * (root.CFrame - root.Position) }
	)
	tween:Play()
	tween.Completed:Connect(function()
		if track then track:Stop() end
	end)
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		performDash()
	end
end

UserInputService.InputBegan:Connect(onInputBegan)

return {}
