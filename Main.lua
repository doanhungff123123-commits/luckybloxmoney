-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")

-- DANH SÁCH TỌA ĐỘ
local waypoints = {
	{name = "Point A", pos = Vector3.new(424, -14, -337.25)},
	{name = "Point B", pos = Vector3.new(1132.36, 1.56, 531.31)},
	{name = "Point C", pos = Vector3.new(2571.35, -7.7, -33.7)}
}

-- STATE
local currentIndex = 1
local isRunning = false
local FlySpeed = 200
local spinSpeed = 5

-- BODY VELOCITY & GYRO
local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
bv.Velocity = Vector3.zero

local bg = Instance.new("BodyGyro")
bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
bg.P = 9e4

-- GUI
local gui = Instance.new("ScreenGui", Player.PlayerGui)
gui.Name = "AutoWaypointGUI"
gui.ResetOnSpawn = false

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.fromOffset(50, 50)
toggleBtn.Position = UDim2.fromScale(0.9, 0.1)
toggleBtn.Text = "▶"
toggleBtn.TextSize = 24
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0

local corner = Instance.new("UICorner", toggleBtn)
corner.CornerRadius = UDim.new(0.3, 0)

local stroke = Instance.new("UIStroke", toggleBtn)
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 2

local statusLabel = Instance.new("TextLabel", gui)
statusLabel.Size = UDim2.fromOffset(100, 30)
statusLabel.Position = UDim2.new(0.9, -25, 0.1, 55)
statusLabel.Text = "0/" .. #waypoints
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
statusLabel.BackgroundTransparency = 1

-- FUNCTIONS
local function getRandomWaitTime()
	return math.random(50, 100) / 100
end

local function enableNoclip()
	for _, v in pairs(Char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
end

local function disableNoclip()
	for _, v in pairs(Char:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.CanCollide = true
		end
	end
end

local function flyToPosition(targetPos, speed)
	if not HRP or not HRP.Parent then
		return false
	end
	
	enableNoclip()
	bv.Parent = HRP
	bg.Parent = HRP
	Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	local startTime = tick()
	local timeout = 60
	
	while isRunning do
		if not HRP or not HRP.Parent then
			return false
		end
		
		local distance = (HRP.Position - targetPos).Magnitude
		
		if distance < 3 then
			bv.Velocity = Vector3.zero
			return true
		end
		
		if tick() - startTime > timeout then
			bv.Velocity = Vector3.zero
			return false
		end
		
		local direction = (targetPos - HRP.Position).Unit
		bv.Velocity = direction * speed
		
		task.wait()
	end
	
	return false
end

local function stopFlying()
	if bv then bv.Parent = nil end
	if bg then bg.Parent = nil end
	if Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	disableNoclip()
end

local autoRunCoroutine = nil

local function startAutoRun()
	isRunning = true
	toggleBtn.Text = "⏸"
	toggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	
	autoRunCoroutine = task.spawn(function()
		while isRunning and currentIndex <= #waypoints do
			if not HRP or not HRP.Parent then
				task.wait(0.5)
				continue
			end
			
			local waypoint = waypoints[currentIndex]
			print("Going to " .. waypoint.name)
			
			-- BƯỚC 1: Bay xuống dưới sàn
			local underFloor = Vector3.new(HRP.Position.X, -50, HRP.Position.Z)
			local success = flyToPosition(underFloor, FlySpeed)
			
			if not success then
				task.wait(1)
				continue
			end
			
			-- BƯỚC 2: Bay ngang đến dưới chân điểm đích
			local underTarget = Vector3.new(waypoint.pos.X, -50, waypoint.pos.Z)
			success = flyToPosition(underTarget, FlySpeed)
			
			if not success then
				task.wait(1)
				continue
			end
			
			-- BƯỚC 3: Bay thẳng lên điểm đích
			success = flyToPosition(waypoint.pos, FlySpeed)
			
			if not success then
				task.wait(1)
				continue
			end
			
			print("Reached " .. waypoint.name)
			stopFlying()
			
			local waitTime = getRandomWaitTime()
			task.wait(waitTime)
			
			currentIndex = currentIndex + 1
		end
		
		-- Hoàn thành tất cả waypoints
		if currentIndex > #waypoints and isRunning then
			print("All waypoints completed! Switching server...")
			statusLabel.Text = "✅ DONE"
			task.wait(1)
			
			local success, err = pcall(function()
				TeleportService:Teleport(game.PlaceId, Player)
			end)
			
			if not success then
				warn("Failed to switch server: " .. tostring(err))
				statusLabel.Text = "❌ Failed"
			end
		end
		
		isRunning = false
		toggleBtn.Text = "▶"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	end)
end

local function stopAutoRun()
	isRunning = false
	stopFlying()
	if autoRunCoroutine then
		task.cancel(autoRunCoroutine)
	end
	toggleBtn.Text = "▶"
	toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
end

-- TOGGLE BUTTON
toggleBtn.MouseButton1Click:Connect(function()
	if isRunning then
		stopAutoRun()
	else
		startAutoRun()
	end
end)

-- NOCLIP LIÊN TỤC
RunService.Stepped:Connect(function()
	if isRunning then
		enableNoclip()
	end
end)

-- XOAY NHÂN VẬT
local rotationAngle = 0
RunService.RenderStepped:Connect(function(dt)
	if isRunning and HRP and HRP.Parent and bg.Parent then
		rotationAngle = rotationAngle + (spinSpeed * dt)
		bg.CFrame = CFrame.Angles(0, math.rad(rotationAngle * 50), 0)
	end
end)

-- XỬ LÝ KHI CHẾT
Player.CharacterAdded:Connect(function(newChar)
	Char = newChar
	HRP = Char:WaitForChild("HumanoidRootPart")
	Humanoid = Char:WaitForChild("Humanoid")
	
	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.zero
	
	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bg.P = 9e4
	
	print("Respawned. Continuing from: " .. currentIndex)
end)

-- UPDATE STATUS
RunService.RenderStepped:Connect(function()
	if isRunning and currentIndex <= #waypoints then
		statusLabel.Text = (currentIndex - 1) .. "/" .. #waypoints
	elseif currentIndex > #waypoints then
		statusLabel.Text = "✅ DONE"
	else
		statusLabel.Text = "0/" .. #waypoints
	end
end)

print("🌟 Auto Waypoint loaded! 🌟")
print("Click the button to start!")
