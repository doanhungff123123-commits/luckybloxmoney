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

-- GUI GALAXY STYLE
local gui = Instance.new("ScreenGui", Player.PlayerGui)
gui.Name = "AutoWaypointGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(200, 120)
frame.Position = UDim2.fromScale(0.4, 0.1)
frame.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local gradient = Instance.new("UIGradient", frame)
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 0, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 0, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 0, 150))
}
gradient.Rotation = 45

local border = Instance.new("UIStroke", frame)
border.Color = Color3.fromRGB(150, 50, 255)
border.Thickness = 3

task.spawn(function()
	while true do
		for i = 0, 100 do
			border.Color = Color3.fromHSV(i/100, 1, 1)
			task.wait(0.05)
		end
	end
end)

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 15)

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.fromOffset(180, 60)
toggleBtn.Position = UDim2.fromOffset(10, 10)
toggleBtn.Text = "⭐ HUNGDAO9999 ⭐"
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(10, 0, 30)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BorderSizePixel = 0

local btnCorner = Instance.new("UICorner", toggleBtn)
btnCorner.CornerRadius = UDim.new(0, 10)

local btnGradient = Instance.new("UIGradient", toggleBtn)
btnGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 255))
}

task.spawn(function()
	while true do
		for i = 0, 360, 5 do
			btnGradient.Rotation = i
			task.wait(0.03)
		end
	end
end)

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.fromOffset(180, 35)
statusLabel.Position = UDim2.fromOffset(10, 75)
statusLabel.Text = "Status: OFF\n0/" .. #waypoints
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
statusLabel.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
statusLabel.BorderSizePixel = 0

local statusCorner = Instance.new("UICorner", statusLabel)
statusCorner.CornerRadius = UDim.new(0, 8)

-- FUNCTIONS
local function getRandomWaitTime()
	return math.random(150, 250) / 100  -- 1.5-2.5 giây
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
	statusLabel.Text = "Status: RUNNING\n0/" .. #waypoints
	
	autoRunCoroutine = task.spawn(function()
		while isRunning and currentIndex <= #waypoints do
			if not HRP or not HRP.Parent then
				print("Waiting for character...")
				task.wait(0.5)
				continue
			end
			
			local waypoint = waypoints[currentIndex]
			print("Going to " .. waypoint.name)
			
			-- BƯỚC 1: Bay xuống dưới sàn (Y = -80)
			local underFloor = Vector3.new(HRP.Position.X, -80, HRP.Position.Z)
			local success = flyToPosition(underFloor, FlySpeed)
			
			if not success and isRunning then
				print("Step 1 failed, retrying...")
				task.wait(1)
				continue
			end
			
			-- BƯỚC 2: Bay ngang đến dưới chân điểm đích
			local underTarget = Vector3.new(waypoint.pos.X, -80, waypoint.pos.Z)
			success = flyToPosition(underTarget, FlySpeed)
			
			if not success and isRunning then
				print("Step 2 failed, retrying...")
				task.wait(1)
				continue
			end
			
			-- BƯỚC 3: Bay thẳng lên điểm đích
			success = flyToPosition(waypoint.pos, FlySpeed)
			
			if not success and isRunning then
				print("Step 3 failed, retrying...")
				task.wait(1)
				continue
			end
			
			print("Reached " .. waypoint.name)
			stopFlying()
			
			local waitTime = getRandomWaitTime()
			print("Waiting " .. string.format("%.2f", waitTime) .. " seconds...")
			task.wait(waitTime)
			
			currentIndex = currentIndex + 1
			print("Progress: " .. (currentIndex - 1) .. "/" .. #waypoints)
		end
		
		-- Hoàn thành tất cả waypoints
		if currentIndex > #waypoints and isRunning then
			print("All waypoints completed! Switching server...")
			statusLabel.Text = "Status: DONE\nSwitching..."
			task.wait(2)
			
			local placeId = game.PlaceId
			print("Attempting to teleport to PlaceId: " .. tostring(placeId))
			
			local success, err = pcall(function()
				TeleportService:Teleport(placeId, Player)
			end)
			
			if not success then
				warn("Failed to switch server: " .. tostring(err))
				statusLabel.Text = "Status: ERROR\nFailed to switch"
				
				-- Thử lại sau 3 giây
				task.wait(3)
				pcall(function()
					TeleportService:Teleport(placeId, Player)
				end)
			end
		end
		
		isRunning = false
		statusLabel.Text = "Status: OFF\n" .. (currentIndex - 1) .. "/" .. #waypoints
	end)
end

local function stopAutoRun()
	isRunning = false
	stopFlying()
	if autoRunCoroutine then
		task.cancel(autoRunCoroutine)
	end
	statusLabel.Text = "Status: OFF\n" .. (currentIndex - 1) .. "/" .. #waypoints
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
		local progress = math.max(0, currentIndex - 1)
		statusLabel.Text = "Status: RUNNING\n" .. progress .. "/" .. #waypoints
	elseif currentIndex > #waypoints then
		statusLabel.Text = "Status: DONE\n" .. #waypoints .. "/" .. #waypoints
	end
end)

print("🌟 Auto Waypoint Galaxy loaded! 🌟")
print("Click HUNGDAO9999 button to start!")
print("Waypoints: " .. #waypoints)
