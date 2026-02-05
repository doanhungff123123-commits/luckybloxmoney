local HOLD_TIME = 2
local CHECK_RADIUS = 3
local POINTS = {
	Vector3.new(424, -14, -337.25),
	Vector3.new(1132.36, 1.56, 531.31),
	Vector3.new(2571.35, -7.7, -337.7)
}
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Khởi tạo settings - Mặc định BẬT
if getgenv().GALAXY_SETTINGS == nil then
	getgenv().GALAXY_SETTINGS = {
		STEP = 1,
		AUTO_START = true  -- BẬT mặc định
	}
end

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
status.Text = "Loading..."
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
		if not getgenv().GALAXY_SETTINGS.AUTO_START then return false end
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
	while getgenv().GALAXY_SETTINGS.AUTO_START do
		-- Reset step khi hoàn thành
		if getgenv().GALAXY_SETTINGS.STEP > #POINTS then
			getgenv().GALAXY_SETTINGS.STEP = 1
			status.Text = "Hopping server..."
			task.wait(1)
			serverHop()
			return
		end
		
		status.Text = "Point "..getgenv().GALAXY_SETTINGS.STEP.."/"..#POINTS
		local char, hrp, hum = getChar()
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(POINTS[getgenv().GALAXY_SETTINGS.STEP])
		local ok = waitCheckpoint(hrp, hum, POINTS[getgenv().GALAXY_SETTINGS.STEP])
		hrp.Anchored = false
		
		if ok then
			getgenv().GALAXY_SETTINGS.STEP += 1
		else
			if not getgenv().GALAXY_SETTINGS.AUTO_START then break end
			player.CharacterAdded:Wait()
		end
	end
	
	getgenv().RUNNING = false
end

-- Nút STOP
btn.MouseButton1Click:Connect(function()
	if getgenv().RUNNING and getgenv().GALAXY_SETTINGS.AUTO_START then
		-- TẮT
		getgenv().GALAXY_SETTINGS.AUTO_START = false
		btn.Text = "▶ START"
		btn.BackgroundColor3 = Color3.fromRGB(80,40,140)
		status.Text = "Stopped by user"
		status.TextColor3 = Color3.fromRGB(255,200,0)
		getgenv().GALAXY_SETTINGS.STEP = 1
	elseif not getgenv().RUNNING then
		-- BẬT lại
		getgenv().GALAXY_SETTINGS.AUTO_START = true
		getgenv().GALAXY_SETTINGS.STEP = 1
		btn.Text = "⏸ STOP"
		btn.BackgroundColor3 = Color3.fromRGB(140,40,40)
		status.Text = "Starting..."
		status.TextColor3 = Color3.fromRGB(0,255,200)
		getgenv().RUNNING = true
		task.spawn(runLoop)
	end
end)

-- TỰ ĐỘNG CHẠY KHI VÀO SERVER
task.wait(2)  -- Đợi load xong
if getgenv().GALAXY_SETTINGS.AUTO_START then
	btn.Text = "⏸ STOP"
	btn.BackgroundColor3 = Color3.fromRGB(140,40,40)
	status.Text = "Auto running..."
	status.TextColor3 = Color3.fromRGB(0,255,200)
	getgenv().RUNNING = true
	task.spawn(runLoop)
else
	btn.Text = "▶ START"
	btn.BackgroundColor3 = Color3.fromRGB(80,40,140)
	status.Text = "Stopped"
	status.TextColor3 = Color3.fromRGB(255,200,0)
end
