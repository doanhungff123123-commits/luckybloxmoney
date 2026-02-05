-- HungDao9999 | Galaxy Tool (FINAL)

local HOLD_TIME = 1.5
local CHECK_RADIUS = 3

local POINTS = {
	Vector3.new(424, -14, -337.25),
	Vector3.new(1132.36, 1.56, 531.31),
	Vector3.new(2571.35, -7.7, -33.7)
}

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

getgenv().STEP = getgenv().STEP or 1
getgenv().RUNNING = false

-- ===== GUI =====
local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(260,120)
frame.Position = UDim2.fromScale(0.37,0.4)
frame.BackgroundColor3 = Color3.fromRGB(15,0,40)
frame.Active, frame.Draggable = true, true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.BackgroundTransparency = 1
title.Text = "🌌 HungDao9999"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(180,140,255)

local status = Instance.new("TextLabel", frame)
status.Position = UDim2.new(0,0,0,40)
status.Size = UDim2.new(1,0,0,40)
status.BackgroundTransparency = 1
status.Text = "Idle"
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(0,255,200)

local btn = Instance.new("TextButton", frame)
btn.Position = UDim2.new(0.15,0,0.7,0)
btn.Size = UDim2.new(0.7,0,0.22,0)
btn.Text = "▶ START"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.BackgroundColor3 = Color3.fromRGB(80,40,140)
btn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", btn)

-- ===== LOGIC =====
local function getChar()
	local c = player.Character or player.CharacterAdded:Wait()
	return c, c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
end

local function waitCheckpoint(hrp, hum, point)
	local start = tick()
	while tick() - start < HOLD_TIME do
		if hum.Health <= 0 then return false end
		if (hrp.Position - point).Magnitude > CHECK_RADIUS then
			return false
		end
		task.wait(0.05)
	end
	return true
end

btn.MouseButton1Click:Connect(function()
	if getgenv().RUNNING then return end
	getgenv().RUNNING = true

	task.spawn(function()
		while getgenv().STEP <= #POINTS do
			status.Text = "Point "..getgenv().STEP
			local char, hrp, hum = getChar()

			hrp.Anchored = true
			hrp.CFrame = CFrame.new(POINTS[getgenv().STEP])

			local ok = waitCheckpoint(hrp, hum, POINTS[getgenv().STEP])
			hrp.Anchored = false

			if ok then
				getgenv().STEP += 1
			else
				player.CharacterAdded:Wait()
			end
		end

		status.Text = "Rejoining..."
		getgenv().STEP = nil
		task.wait(1)
		TeleportService:Teleport(game.PlaceId, player)
	end)
end)
