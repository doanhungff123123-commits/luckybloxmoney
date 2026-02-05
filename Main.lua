-- =====================================
--   HungDao9999 | Galaxy Auto Waypoint (FIXED)
-- =====================================

-- ========= CONFIG =========
local HOLD_TIME = 2
local CHECK_RADIUS = 3
local KEYWORDS = {"money", "cash", "lucky", "block", "+"}

local POINTS = {
	Vector3.new(424, -14, -337.25),
	Vector3.new(1132.36, 1.56, 531.31),
	Vector3.new(2571.35, -7.7, -33.7)
}

-- ========= SERVICES =========
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local placeId = game.PlaceId

-- ========= SAVE STEP =========
getgenv().STEP = getgenv().STEP or 1

-- ========= CHARACTER =========
local function getChar()
	local c = player.Character or player.CharacterAdded:Wait()
	return c, c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
end

-- ========= NOCLIP =========
local function noclip(char)
	for _,v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
end

-- ========= FREEZE HARD =========
local function freeze(hrp)
	hrp.Anchored = true
end

local function unfreeze(hrp)
	hrp.Anchored = false
end

-- ========= GUI =========
local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false
gui.Name = "HungDaoGalaxy"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(320,170)
frame.Position = UDim2.fromScale(0.35,0.35)
frame.BackgroundColor3 = Color3.fromRGB(15,0,40)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 3

task.spawn(function()
	local h = 0
	while true do
		h = (h + 0.002) % 1
		stroke.Color = Color3.fromHSV(h,1,1)
		task.wait()
	end
end)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.fromScale(1,0.35)
title.BackgroundTransparency = 1
title.Text = "🌌 HungDao9999 🌌"
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.TextColor3 = Color3.fromRGB(200,150,255)

local status = Instance.new("TextLabel", frame)
status.Position = UDim2.fromScale(0,0.4)
status.Size = UDim2.fromScale(1,0.6)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(0,255,200)

-- ========= TEXT CHECK =========
local function matchText(t)
	t = t:lower()
	for _,k in ipairs(KEYWORDS) do
		if t:find(k) then return true end
	end
end

-- ========= CHECKPOINT LOGIC =========
local function waitCheckpoint(hrp, hum, point)
	local start = tick()
	local gotText = false

	local conn = PlayerGui.DescendantAdded:Connect(function(v)
		if v:IsA("TextLabel") and matchText(v.Text) then
			gotText = true
		end
	end)

	while tick() - start < HOLD_TIME do
		if hum.Health <= 0 then
			conn:Disconnect()
			return false
		end

		if (hrp.Position - point).Magnitude > CHECK_RADIUS then
			conn:Disconnect()
			return false
		end

		if gotText then
			conn:Disconnect()
			return true
		end

		task.wait(0.05)
	end

	conn:Disconnect()
	return true
end

-- ========= SERVER HOP (FIXED) =========
local tried = {}

local function serverHop()
	while true do
		local data = HttpService:JSONDecode(
			game:HttpGet("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100")
		)

		for _,s in ipairs(data.data) do
			if s.id ~= game.JobId and not tried[s.id] and s.playing < s.maxPlayers then
				tried[s.id] = true
				local ok = pcall(function()
					TeleportService:TeleportToPlaceInstance(placeId, s.id, player)
				end)
				if ok then return end
			end
		end
		task.wait(1.5)
	end
end

-- ========= MAIN =========
task.spawn(function()
	while getgenv().STEP <= #POINTS do
		status.Text = "📍 Point "..getgenv().STEP
		local char, hrp, hum = getChar()

		noclip(char)
		hrp.CFrame = CFrame.new(POINTS[getgenv().STEP])
		freeze(hrp)

		local ok = waitCheckpoint(hrp, hum, POINTS[getgenv().STEP])
		unfreeze(hrp)

		if ok then
			getgenv().STEP += 1
		else
			player.CharacterAdded:Wait()
		end
	end

	status.Text = "✅ COMPLETED\n🔄 Switching server..."
	getgenv().STEP = nil
	task.wait(1)
	serverHop()
end)
