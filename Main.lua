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
local FlySpeed = 200
local spinSpeed = 5
local waitTime = 2
local arrivalThreshold = 2 -- Khoảng cách coi như đã đến

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

-- Bay theo 1 trục (X, Y hoặc Z) - THẲNG TẮP
local function flyOnAxis(targetPos, speed, axis)
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
		
		local currentPos = HRP.Position
		local distance
		
		-- Tính khoảng cách theo trục
		if axis == "X" then
			distance = math.abs(currentPos.X - targetPos.X)
		elseif axis == "Y" then
			distance = math.abs(currentPos.Y - targetPos.Y)
		elseif axis == "Z" then
			distance = math.abs(currentPos.Z - targetPos.Z)
		end
		
		-- Đã đến nơi
		if distance < arrivalThreshold then
			bv.Velocity = Vector3.zero
			-- Cứng vào đúng vị trí
			if axis == "X" then
				HRP.CFrame = CFrame.new(targetPos.X, currentPos.Y, currentPos.Z)
			elseif axis == "Y" then
				HRP.CFrame = CFrame.new(currentPos.X, targetPos.Y, currentPos.Z)
			elseif axis == "Z" then
				HRP.CFrame = CFrame.new(currentPos.X, currentPos.Y, targetPos.Z)
			end
			return true
		end
		
		-- Timeout
		if tick() - startTime > timeout then
			bv.Velocity = Vector3.zero
			return false
		end
		
		-- Bay THẲNG theo 1 trục
		local velocity = Vector3.zero
		if axis == "X" then
			velocity = Vector3.new((targetPos.X > currentPos.X and speed or -speed), 0, 0)
		elseif axis == "Y" then
			velocity = Vector3.new(0, (targetPos.Y > currentPos.Y and speed or -speed), 0)
		elseif axis == "Z" then
			velocity = Vector3.new(0, 0, (targetPos.Z > currentPos.Z and speed or -speed))
		end
		
		bv.Velocity = velocity
		task.wait()
	end
	
	return false
end

-- Giữ vị trí cứng trong X giây
local function holdPosition(targetPos, duration)
	if not HRP or not HRP.Parent then
		return false
	end
	
	print("Holding position for " .. duration .. " seconds...")
	
	bv.Parent = HRP
	bg.Parent = HRP
	Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	local endTime = tick() + duration
	
	while tick() < endTime and isRunning do
		if not HRP or not HRP.Parent then
			return false
		end
		
		-- GIỮ CỨNG vị trí
		HRP.CFrame = CFrame.new(targetPos)
		bv.Velocity = Vector3.zero
		
		task.wait()
	end
	
	return true
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
			
			local currentPos = HRP.Position
			
			-- BƯỚC 1: Bay XUỐNG dưới sàn (chỉ trục Y)
			print("Step 1: Flying DOWN to Y = -80")
			local success = flyOnAxis(Vector3.new(currentPos.X, -80, currentPos.Z), FlySpeed, "Y")
			
			if not success and isRunning then
				print("Step 1 failed, retrying...")
				task.wait(1)
				continue
			end
			
			currentPos = HRP.Position
			
			-- BƯỚC 2: Bay NGANG theo X
			print("Step 2: Flying on X axis to " .. waypoint.pos.X)
			success = flyOnAxis(Vector3.new(waypoint.pos.X, currentPos.Y, currentPos.Z), FlySpeed, "X")
			
			if not success and isRunning then
				print("Step 2 failed, retrying...")
				task.wait(1)
				continue
			end
			
			currentPos = HRP.Position
			
			-- BƯỚC 3: Bay NGANG theo Z
			print("Step 3: Flying on Z axis to " .. waypoint.pos.Z)
			success = flyOnAxis(Vector3.new(currentPos.X, currentPos.Y, waypoint.pos.Z), FlySpeed, "Z")
			
			if not success and isRunning then
				print("Step 3 failed, retrying...")
				task.wait(1)
				continue
			end
			
			currentPos = HRP.Position
			
			-- BƯỚC 4: Bay LÊN điểm đích (chỉ trục Y)
			print("Step 4: Flying UP to final Y = " .. waypoint.pos.Y)
			success = flyOnAxis(Vector3.new(currentPos.X, waypoint.pos.Y, currentPos.Z), FlySpeed, "Y")
			
			if not success and isRunning then
				print("Step 4 failed, retrying...")
				task.wait(1)
				continue
			end
			
			-- ĐÃ ĐẾN - GIỮ VỊ TRÍ 2 GIÂY
			print("Reached " .. waypoint.name .. "! Holding position...")
			success = holdPosition(waypoint.pos, waitTime)
			
			if not success and isRunning then
				print("Failed to hold position, retrying...")
				task.wait(1)
				continue
			end
			
			print("✓ Completed " .. waypoint.name)
			
			currentIndex = currentIndex + 1
			print("Progress: " .. (currentIndex - 1) .. "/" .. #waypoints)
		end
		
		-- Hoàn thành tất cả waypoints
		if currentIndex > #waypoints and isRunning then
			stopFlying()
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
