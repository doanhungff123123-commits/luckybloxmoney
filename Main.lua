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
	{name = "Point C", pos = Vector3.new(2571.35, -7.7, -337.7)}
}

-- STATE
local currentIndex = 1
local isRunning = false
local FlySpeed = 280
local spinSpeed = 5
local waitTime = 2 -- Thời gian chờ cứng 2 giây

-- BODY VELOCITY & GYRO
local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
bv.Velocity = Vector3.zero

local bg = Instance.new("BodyGyro")
bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
bg.P = 9e4

-- GUI ĐƠN GIẢN ĐẸP
local gui = Instance.new("ScreenGui", Player.PlayerGui)
gui.Name = "AutoWaypointGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(160, 80)
frame.Position = UDim2.fromScale(0.42, 0.05)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local border = Instance.new("UIStroke", frame)
border.Color = Color3.fromRGB(60, 60, 80)
border.Thickness = 2

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.fromOffset(140, 35)
toggleBtn.Position = UDim2.fromOffset(10, 10)
toggleBtn.Text = "HUNGDAO9999"
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BorderSizePixel = 0

local btnCorner = Instance.new("UICorner", toggleBtn)
btnCorner.CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.fromOffset(140, 20)
statusLabel.Position = UDim2.fromOffset(10, 50)
statusLabel.Text = "OFF • 0/3"
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
statusLabel.BackgroundTransparency = 1

-- FUNCTIONS

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
	toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
	
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
			
			-- Đợi 2 giây
			print("Waiting 2 seconds...")
			task.wait(waitTime)
			
			currentIndex = currentIndex + 1
			print("Progress: " .. (currentIndex - 1) .. "/" .. #waypoints)
		end
		
		-- Hoàn thành tất cả waypoints
		if currentIndex > #waypoints and isRunning then
			print("All waypoints completed! Switching server...")
			statusLabel.Text = "DONE • Switching..."
			task.wait(2)
			
			local placeId = game.PlaceId
			print("Attempting to teleport to PlaceId: " .. tostring(placeId))
			
			local success, err = pcall(function()
				TeleportService:Teleport(placeId, Player)
			end)
			
			if not success then
				warn("Failed to switch server: " .. tostring(err))
				statusLabel.Text = "ERROR • Failed"
				
				-- Thử lại sau 3 giây
				task.wait(3)
				pcall(function()
					TeleportService:Teleport(placeId, Player)
				end)
			end
		end
		
		isRunning = false
		toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
		statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	end)
end

local function stopAutoRun()
	isRunning = false
	stopFlying()
	if autoRunCoroutine then
		task.cancel(autoRunCoroutine)
	end
	toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	statusLabel.Text = "OFF • " .. (currentIndex - 1) .. "/3"
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
		statusLabel.Text = "RUNNING • " .. progress .. "/3"
	elseif currentIndex > #waypoints then
		statusLabel.Text = "DONE • 3/3"
	end
end)

print("🌟 Auto Waypoint loaded! 🌟")
print("Waypoints: " .. #waypoints)

-- TỰ ĐỘNG BẬT SAU 7 GIÂY KHI JOIN SERVER
task.spawn(function()
	print("Script will auto-start in 7 seconds...")
	statusLabel.Text = "Starting in 7s..."
	
	for i = 7, 1, -1 do
		statusLabel.Text = "Auto start: " .. i .. "s"
		task.wait(1)
	end
	
	-- Bật tự động
	print("Auto-starting script!")
	startAutoRun()
end)
