local HOLD_TIME = 1.5
local CHECK_RADIUS = 3
local POINTS = {
	Vector3.new(424, -14, -337.25),
	Vector3.new(1132.36, 1.56, 531.31),
	Vector3.new(2571.35, -7.7, -33.7)
}
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Khởi tạo settings
if not getgenv().GALAXY_SETTINGS then
	getgenv().GALAXY_SETTINGS = {
		STEP = 1,
		AUTO_START = false
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
status.Text = getgenv().GALAXY_SETTINGS.AUTO_START and "Auto Mode ON" or "Idle"
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(0,255,200)

local btn = Instance.new("TextButton", frame)
btn.Position = UDim2.new(0.15,0,0.7,0)
btn.Size = UDim2.new(0.7,0,0.22,0)
btn.Text = getgenv().GALAXY_SETTINGS.AUTO_START and "⏸ STOP" or "▶ START"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.BackgroundColor3 = getgenv().GALAXY_SETTINGS.AUTO_START and Color3.fromRGB(140,40,40) or Color3.fromRGB(80,40,140)
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

local function serverHop()
	local servers = {}
	local req = syn and syn.request or http_request or request
	if req then
		local response = req({
			Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId),
			Method = "GET"
		})
		if response.StatusCode == 200 then
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
	while getgenv().GALAXY_SETTINGS.AUTO_START and getgenv().GALAXY_SETTINGS.STEP <= #POINTS do
		status.Text = "Point "..getgenv().GALAXY_SETTINGS.STEP
		local char, hrp, hum = getChar()
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(POINTS[getgenv().GALAXY_SETTINGS.STEP])
		local ok = waitCheckpoint(hrp, hum, POINTS[getgenv().GALAXY_SETTINGS.STEP])
		hrp.Anchored = false
		
		if ok then
			getgenv().GALAXY_SETTINGS.STEP += 1
		else
			player.CharacterAdded:Wait()
		end
	end
	
	if getgenv().GALAXY_SETTINGS.AUTO_START and getgenv().GALAXY_SETTINGS.STEP > #POINTS then
		status.Text = "Hopping server..."
		getgenv().GALAXY_SETTINGS.STEP = 1
		task.wait(1)
		serverHop()
	end
end

btn.MouseButton1Click:Connect(function()
	if getgenv().RUNNING then return end
	
	getgenv().GALAXY_SETTINGS.AUTO_START = not getgenv().GALAXY_SETTINGS.AUTO_START
	
	if getgenv().GALAXY_SETTINGS.AUTO_START then
		btn.Text = "⏸ STOP"
		btn.BackgroundColor3 = Color3.fromRGB(140,40,40)
		status.Text = "Starting..."
		status.TextColor3 = Color3.fromRGB(255,100,100)
		getgenv().RUNNING = true
		task.spawn(function()
			runLoop()
			getgenv().RUNNING = false
		end)
	else
		btn.Text = "▶ START"
		btn.BackgroundColor3 = Color3.fromRGB(80,40,140)
		status.Text = "Stopped"
		status.TextColor3 = Color3.fromRGB(255,200,0)
		getgenv().GALAXY_SETTINGS.STEP = 1
	end
end)

-- Auto start nếu đã bật trước đó
if getgenv().GALAXY_SETTINGS.AUTO_START then
	task.wait(2)
	getgenv().RUNNING = true
	status.Text = "Auto resuming..."
	task.spawn(function()
		runLoop()
		getgenv().RUNNING = false
	end)
end
