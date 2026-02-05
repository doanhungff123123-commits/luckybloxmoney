-- SERVICES
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")

-- ===============================================
-- ĐIỀN TỌA ĐỘ VÀO ĐÂY
-- ===============================================
local waypoints = {
	{name = "Point A", pos = Vector3.new(425, -12, -338.5)},  -- Thay số 0 bằng tọa độ thực
	{name = "Point B", pos = Vector3.new(1134, 3.88, 530.34)},  -- Thay số 0 bằng tọa độ thực
	{name = "Point C", pos = Vector3.new(2572.7, -8.17, -337.98)}   -- Thay số 0 bằng tọa độ thực
}
-- ===============================================

-- STATE
local currentIndex = 1
local isRunning = false
local FlySpeed = 150 -- Tốc độ bay

-- BODY VELOCITY & GYRO
local bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
bv.Velocity = Vector3.zero

local bg = Instance.new("BodyGyro")
bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
bg.P = 9e4

-- FUNCTION RANDOM WAIT TIME
local function getRandomWaitTime()
	return math.random(50, 100) / 100 -- Random từ 0.5 đến 1.0 giây
end

-- FUNCTION BẬT NOCLIP
local function enableNoclip()
	for _, v in pairs(Char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
end

-- FUNCTION TẮT NOCLIP
local function disableNoclip()
	for _, v in pairs(Char:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.CanCollide = true
		end
	end
end

-- FUNCTION BAY ĐẾN VỊ TRÍ
local function flyToPosition(targetPos)
	if not HRP or not HRP.Parent then
		return false
	end
	
	-- Bật noclip
	enableNoclip()
	
	-- Gắn BodyVelocity và BodyGyro
	bv.Parent = HRP
	bg.Parent = HRP
	Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Bay đến vị trí
	local startTime = tick()
	local timeout = 30 -- 30 giây timeout
	
	while isRunning do
		if not HRP or not HRP.Parent then
			return false
		end
		
		local distance = (HRP.Position - targetPos).Magnitude
		
		-- Đã đến nơi (trong vòng 5 studs)
		if distance < 5 then
			bv.Velocity = Vector3.zero
			return true
		end
		
		-- Timeout
		if tick() - startTime > timeout then
			print("Timeout while flying to " .. tostring(targetPos))
			bv.Velocity = Vector3.zero
			return false
		end
		
		-- Tính hướng bay
		local direction = (targetPos - HRP.Position).Unit
		bv.Velocity = direction * FlySpeed
		bg.CFrame = CFrame.new(HRP.Position, targetPos)
		
		task.wait()
	end
	
	return false
end

-- FUNCTION DỪNG BAY
local function stopFlying()
	if bv then bv.Parent = nil end
	if bg then bg.Parent = nil end
	if Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	disableNoclip()
end

-- FUNCTION AUTO RUN
local autoRunCoroutine = nil

local function startAutoRun()
	isRunning = true
	
	autoRunCoroutine = task.spawn(function()
		while isRunning and currentIndex <= #waypoints do
			-- Kiểm tra xem character còn tồn tại không
			if not HRP or not HRP.Parent then
				print("Waiting for character to respawn...")
				task.wait(0.5)
				continue
			end
			
			local waypoint = waypoints[currentIndex]
			print("Flying to " .. waypoint.name .. ": " .. tostring(waypoint.pos))
			
			-- Bay đến vị trí (tự động bay từ dưới lên)
			local success = flyToPosition(waypoint.pos)
			
			if not success then
				print("Failed to reach " .. waypoint.name .. ", retrying...")
				task.wait(1)
				continue
			end
			
			print("Reached " .. waypoint.name)
			
			-- Dừng bay và đứng im
			stopFlying()
			
			-- Đợi random 0.5-1.0 giây
			local waitTime = getRandomWaitTime()
			print("Waiting " .. string.format("%.2f", waitTime) .. " seconds...")
			task.wait(waitTime)
			
			-- Chuyển sang điểm tiếp theo
			currentIndex = currentIndex + 1
			print("Moving to next waypoint. Current index: " .. currentIndex)
		end
		
		-- Hoàn thành tất cả waypoints
		if currentIndex > #waypoints and isRunning then
			print("All waypoints completed! Switching server...")
			statusLabel.Text = "✅ COMPLETED!\n🔄 Switching server..."
			task.wait(1)
			
			-- Chuyển server
			local success, err = pcall(function()
				TeleportService:Teleport(game.PlaceId, Player)
			end)
			
			if not success then
				warn("Failed to switch server: " .. tostring(err))
				statusLabel.Text = "❌ Switch server failed!\nTry manually"
			end
		end
		
		isRunning = false
	end)
end

-- FUNCTION STOP
local function stopAutoRun()
	isRunning = false
	stopFlying()
	if autoRunCoroutine then
		task.cancel(autoRunCoroutine)
	end
end

-- GUI
local gui = Instance.new("ScreenGui", Player.PlayerGui)
gui.Name = "AutoWaypointGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(300, 200)
frame.Position = UDim2.fromScale(0.35, 0.35)
frame.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- GRADIENT BACKGROUND
local gradient = Instance.new("UIGradient", frame)
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 0, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 0, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 0, 150))
}
gradient.Rotation = 45

-- BORDER GLOW
local border = Instance.new("UIStroke", frame)
border.Color = Color3.fromRGB(150, 50, 255)
border.Thickness = 3
border.Transparency = 0

-- Hiệu ứng glow cho border
task.spawn(function()
	while true do
		for i = 0, 100 do
			border.Color = Color3.fromHSV(i/100, 1, 1)
			task.wait(0.05)
		end
	end
end)

-- CORNER RADIUS
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 15)

-- LOGO/TITLE
local logo = Instance.new("TextLabel", frame)
logo.Size = UDim2.fromOffset(300, 70)
logo.Position = UDim2.fromOffset(0, 0)
logo.Text = "⭐ HUNGDAO9999 ⭐"
logo.TextColor3 = Color3.fromRGB(255, 255, 255)
logo.BackgroundColor3 = Color3.fromRGB(10, 0, 30)
logo.BackgroundTransparency = 0.3
logo.Font = Enum.Font.GothamBold
logo.TextSize = 28
logo.BorderSizePixel = 0

local logoCorner = Instance.new("UICorner", logo)
logoCorner.CornerRadius = UDim.new(0, 15)

-- Gradient cho logo
local logoGradient = Instance.new("UIGradient", logo)
logoGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 255))
}

-- Hiệu ứng chữ nhấp nháy
task.spawn(function()
	while true do
		for i = 0, 360, 5 do
			logoGradient.Rotation = i
			task.wait(0.03)
		end
	end
end)

-- SUBTITLE
local subtitle = Instance.new("TextLabel", frame)
subtitle.Size = UDim2.fromOffset(280, 25)
subtitle.Position = UDim2.fromOffset(10, 75)
subtitle.Text = "✨ AUTO FLY WAYPOINT ✨"
subtitle.TextColor3 = Color3.fromRGB(200, 150, 255)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.TextSize = 14

-- STATUS PANEL
local statusPanel = Instance.new("Frame", frame)
statusPanel.Size = UDim2.fromOffset(280, 90)
statusPanel.Position = UDim2.fromOffset(10, 105)
statusPanel.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
statusPanel.BorderSizePixel = 0

local statusCorner = Instance.new("UICorner", statusPanel)
statusCorner.CornerRadius = UDim.new(0, 10)

local statusStroke = Instance.new("UIStroke", statusPanel)
statusStroke.Color = Color3.fromRGB(100, 50, 200)
statusStroke.Thickness = 2

local statusLabel = Instance.new("TextLabel", statusPanel)
statusLabel.Size = UDim2.fromOffset(270, 80)
statusLabel.Position = UDim2.fromOffset(5, 5)
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.Text = "🚀 Starting...\nProgress: 0/" .. #waypoints

-- NOCLIP LIÊN TỤC KHI BAY
RunService.Stepped:Connect(function()
	if isRunning then
		enableNoclip()
	end
end)

-- XỬ LÝ KHI CHẾT (RESPAWN)
Player.CharacterAdded:Connect(function(newChar)
	Char = newChar
	HRP = Char:WaitForChild("HumanoidRootPart")
	Humanoid = Char:WaitForChild("Humanoid")
	
	-- Tạo lại BodyVelocity và BodyGyro
	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = Vector3.zero
	
	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bg.P = 9e4
	
	print("Character respawned. Continuing from index: " .. currentIndex)
	print("isRunning: " .. tostring(isRunning))
end)

-- UPDATE STATUS REAL-TIME
RunService.RenderStepped:Connect(function()
	if isRunning and currentIndex <= #waypoints then
		if HRP and HRP.Parent then
			local wp = waypoints[currentIndex]
			local distance = (HRP.Position - wp.pos).Magnitude
			
			statusLabel.Text = string.format(
				"✈️ FLYING...\nProgress: %d/%d\n🎯 %s\n📏 %.1f studs",
				currentIndex - 1,
				#waypoints,
				wp.name,
				distance
			)
		end
	elseif currentIndex > #waypoints then
		statusLabel.Text = "✅ ALL COMPLETED!\n🔄 Switching server..."
	end
end)

print("🌟 Auto Fly Waypoint Script loaded! 🌟")
print("👑 Created by HungDao9999 👑")
print("Waypoints: " .. #waypoints)

-- TỰ ĐỘNG BẮT ĐẦU KHI LOAD SCRIPT
task.wait(0.5)
print("🚀 Auto-starting...")
statusLabel.Text = "🚀 Starting automation...\nPlease wait..."
startAutoRun()
