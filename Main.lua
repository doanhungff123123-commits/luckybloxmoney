local HOLD_TIME = 1.5
local CHECK_RADIUS = 3
local POINTS = {
	Vector3.new(425, -12, -338.5),
	Vector3.new(1134, 3,88, 531.31),
	Vector3.new(2571.35, -8, -337.98)
}
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Khởi tạo settings - CHỈ LẦN ĐẦU
if not _G.GALAXY_INITIALIZED then
	_G.GALAXY_SETTINGS = {
		STEP = 1,
		AUTO_START = true
	}
	_G.GALAXY_INITIALIZED = true
end

_G.RUNNING = false

-- ===== GUI =====
local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false
gui.Name = "GalaxyGUI"

-- Xóa GUI cũ nếu có
if PlayerGui:FindFirstChild("GalaxyGUI") then
	PlayerGui.GalaxyGUI:Destroy()
end

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
status.Text = "Initializing..."
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(0,255,200)

local btn = Instance.new("TextButton", frame)
btn.Position = UDim2.new(0.15,0,0.7,0)
btn.Size = UDim2.new(0.7,0,0.22,0)
btn.Text = "⏸ STOP"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.BackgroundColor3 = Color3.fromRGB(140,40,40)
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
		if not _G.GALAXY_SETTINGS.AUTO_START then return false end
		if hum.Health <= 0 then return false end
		if (hrp.Position - point).Magnitude > CHECK_RADIUS then
			return false
		end
		task.wait(0.05)
	end
	return true
end

local function serverHop()
	local servers = {}
	local req = syn and syn.request or http_request or request
	if req then
		local success, response = pcall(function()
			return req({
				Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId),
				Method = "GET"
			})
		end)
		if success and response.StatusCode == 200 then
			local body = HttpService:JSONDecode(response.Body)
			if body and body.data then
				for _, server in pairs(body.data) do
					if server.playing < server.maxPlayers and server.id ~= game.JobId then
						table.insert(servers, server.id)
					end
				end
			end
		end
	end
	
	if #servers > 0 then
		local randomServer = servers[math.random(1, #servers)]
		TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, player)
	else
		TeleportService:Teleport(game.PlaceId, player)
	end
end

local function runLoop()
	_G.RUNNING = true
	while _G.GALAXY_SETTINGS.AUTO_START do
		-- Reset step khi hoàn thành
		if _G.GALAXY_SETTINGS.STEP > #POINTS then
			_G.GALAXY_SETTINGS.STEP = 1
			status.Text = "✅ Complete! Hopping..."
			task.wait(2)
			serverHop()
			return
		end
		
		status.Text = "📍 Point ".._G.GALAXY_SETTINGS.STEP.."/"..#POINTS
		status.TextColor3 = Color3.fromRGB(0,255,200)
		
		local char, hrp, hum = getChar()
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(POINTS[_G.GALAXY_SETTINGS.STEP])
		
		local ok = waitCheckpoint(hrp, hum, POINTS[_G.GALAXY_SETTINGS.STEP])
		hrp.Anchored = false
		
		if ok then
			_G.GALAXY_SETTINGS.STEP += 1
		else
			if not _G.GALAXY_SETTINGS.AUTO_START then break end
			status.Text = "⚠️ Died, respawning..."
			status.TextColor3 = Color3.fromRGB(255,150,0)
			player.CharacterAdded:Wait()
		end
		
		task.wait(0.1)
	end
	
	_G.RUNNING = false
end

-- Nút STOP/START
btn.MouseButton1Click:Connect(function()
	if _G.GALAXY_SETTINGS.AUTO_START then
		-- TẮT
		_G.GALAXY_SETTINGS.AUTO_START = false
		btn.Text = "▶ START"
		btn.BackgroundColor3 = Color3.fromRGB(80,40,140)
		status.Text = "❌ Stopped"
		status.TextColor3 = Color3.fromRGB(255,100,100)
		_G.GALAXY_SETTINGS.STEP = 1
	else
		-- BẬT lại
		_G.GALAXY_SETTINGS.AUTO_START = true
		_G.GALAXY_SETTINGS.STEP = 1
		btn.Text = "⏸ STOP"
		btn.BackgroundColor3 = Color3.fromRGB(140,40,40)
		status.Text = "🚀 Starting..."
		status.TextColor3 = Color3.fromRGB(0,255,200)
		
		if not _G.RUNNING then
			task.spawn(runLoop)
		end
	end
end)

-- TỰ ĐỘNG CHẠY KHI VÀO SERVER
task.spawn(function()
	-- Đợi character load hoàn toàn
	repeat task.wait(0.5) until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	task.wait(3)  -- Delay dài hơn để chắc chắn
	
	print("[Galaxy] Auto-start check:", _G.GALAXY_SETTINGS.AUTO_START)
	
	if _G.GALAXY_SETTINGS.AUTO_START and not _G.RUNNING then
		btn.Text = "⏸ STOP"
		btn.BackgroundColor3 = Color3.fromRGB(140,40,40)
		status.Text = "🌌 Auto Running..."
		status.TextColor3 = Color3.fromRGB(0,255,200)
		
		print("[Galaxy] Starting auto loop")
		task.wait(1)
		runLoop()
	else
		btn.Text = "▶ START"
		btn.BackgroundColor3 = Color3.fromRGB(80,40,140)
		status.Text = "⏸ Stopped"
		status.TextColor3 = Color3.fromRGB(255,200,0)
	end
end)

print("[Galaxy] Script loaded - Auto:", _G.GALAXY_SETTINGS.AUTO_START, "Step:", _G.GALAXY_SETTINGS.STEP)
