local _env = getgenv()
local dynamichubfunctions = {}
local mainDir: string = "https://raw.githubusercontent.com/clientvoidlua/LN-Dynamic"
local moduleDir: string = mainDir .. "/refs/heads/main/connections/"

local flyModule = {}
pcall(function()
	flyModule = loadstring(game:HttpGet(moduleDir .. "flyModule.lua"))() or {}
end)

local MSESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSESP/main/source.luau"))()

local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Light = game:GetService("Lighting")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

shared.configLight = shared.configLight or {
	["Ambient"] = Light.Ambient,
	["ColorShift_Bottom"] = Light.ColorShift_Bottom,
	["ColorShift_Top"] = Light.ColorShift_Top,
	["Brightness"] = Light.Brightness,
	["ClockTime"] = Light.ClockTime,
	["FogEnd"] = Light.FogEnd,
	["GlobalShadows"] = Light.GlobalShadows
}

shared.dynamichubConnections = shared.dynamichubConnections or {}

for name, conn in pairs(shared.dynamichubConnections) do
	if typeof(conn) == "RBXScriptConnection" then
		conn:Disconnect()
	end
	shared.dynamichubConnections[name] = nil
end

local function updateCharacterReferences(char)
	if not char then return end
	shared.Character = char
end

if LocalPlayer.Character then updateCharacterReferences(LocalPlayer.Character) end
shared.dynamichubConnections["monitorCharacter"] = LocalPlayer.CharacterAdded:Connect(updateCharacterReferences)

function dynamichubfunctions.CreateESP(object: Instance, color: Color3, text: string, showArrow: boolean, showDistance: boolean)
	if not object then return end
	local arrowControl = if showArrow ~= nil then showArrow else false
	local distanceControl = if showDistance ~= nil then showDistance else false

	MSESP.Object({
		Name = text or object.Name,
		Object = object,
		Color = color or Color3.fromRGB(255, 255, 255),
		Arrow = arrowControl,
		Distance = distanceControl
	})
end

function dynamichubfunctions.ESPPlayers(value: boolean, options: table)
	_env.DynamicHubEspPlayer = value
	local config = options or {}
	
	MSESP.Config.Player.Enabled  = value
	MSESP.Config.Player.Box      = if config.Box ~= nil then config.Box else false
	MSESP.Config.Player.Name     = if config.Name ~= nil then config.Name else true
	MSESP.Config.Player.Tracer   = if config.Tracer ~= nil then config.Tracer else false
	MSESP.Config.Player.Chams    = if config.Chams ~= nil then config.Chams else false
	MSESP.Config.Player.Distance = if config.Distance ~= nil then config.Distance else false
	MSESP.Config.Player.Color    = config.Color or Color3.fromRGB(144, 238, 144)
	
	MSESP.Toggle(value)
end

function dynamichubfunctions.DisableESP(object: Instance)
	if not object then return end

	if MSESP.Objects then
		for i = #MSESP.Objects, 1, -1 do
			local obj = MSESP.Objects[i]
			if obj and (obj.Object == object or obj.Instance == object) then
				pcall(function() obj:Destroy() end)
			end
		end
	end
	
	if MSESP.Players then
		for i = #MSESP.Players, 1, -1 do
			local plrCache = MSESP.Players[i]
			if plrCache and (plrCache.Object == object or plrCache.Instance == object or plrCache.Player == object) then
				pcall(function() plrCache:Destroy() end)
			end
		end
	end
end

function dynamichubfunctions.AutoClickV1(value: boolean)
	_env.DynamicHubAutoClickV1 = value
	if not value then return end
	
	task.spawn(function()
		while _env.DynamicHubAutoClickV1 do
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:Button1Down(Vector2.zero)
			end)
			task.wait(0.01)
		end
	end)
end

function dynamichubfunctions.AutoClickV2(value: boolean)
	_env.DynamicHubAutoClickV2 = value
	if not value then return end
	
	task.spawn(function()
		while _env.DynamicHubAutoClickV2 do
			pcall(function()
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
			end)
			task.wait(0.01)
		end
	end)
end

function dynamichubfunctions.CreateFloor(position: Vector3, collision: boolean, transparency: number, colorRGB: Color3)
	local folderParts = workspace:FindFirstChild("DynamicHubFloor") or Instance.new("Folder")
	folderParts.Name = "DynamicHubFloor"
	folderParts.Parent = workspace

	local part = Instance.new("Part")
	part.Size = Vector3.new(10, 1, 10)
	part.Position = position
	part.Anchored = true
	part.Color = colorRGB or Color3.fromRGB(255, 255, 255)
	part.Transparency = transparency or 0
	part.Parent = folderParts

	if collision then
		local barrierThickness = 1
		local barrierHeight = 10
		local barrierPositions = {
			Vector3.new(part.Position.X, part.Position.Y + barrierHeight / 2, part.Position.Z - part.Size.Z / 2 - barrierThickness / 2),
			Vector3.new(part.Position.X, part.Position.Y + barrierHeight / 2, part.Position.Z + part.Size.Z / 2 + barrierThickness / 2),
			Vector3.new(part.Position.X - part.Size.X / 2 - barrierThickness / 2, part.Position.Y + barrierHeight / 2, part.Position.Z),
			Vector3.new(part.Position.X + part.Size.X / 2 + barrierThickness / 2, part.Position.Y + barrierHeight / 2, part.Position.Z),
		}

		for _, pos in ipairs(barrierPositions) do
			local barrier = Instance.new("Part")
			barrier.Size = (pos.Z == part.Position.Z) and Vector3.new(barrierThickness, barrierHeight, part.Size.Z) or Vector3.new(part.Size.X, barrierHeight, barrierThickness)
			barrier.Position = pos
			barrier.Anchored = true
			barrier.CanCollide = true
			barrier.Transparency = 1
			barrier.Parent = folderParts
		end
	end
end

function dynamichubfunctions.SendInChat(msg: string)
	if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
		local sayEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		sayEvent = sayEvent and sayEvent:FindFirstChild("SayMessageRequest")
		if sayEvent then
			sayEvent:FireServer(msg, "All")
		end
	else
		local textChannels = TextChatService:FindFirstChild("TextChannels")
		local channel = textChannels and textChannels:FindFirstChild("RBXGeneral")
		if channel then
			channel:SendAsync(msg)
		end
	end
end

function dynamichubfunctions.FullBright(value: boolean)
	_env.isActiveFullBright = value

	if shared.dynamichubConnections["fullBright"] then
		shared.dynamichubConnections["fullBright"]:Disconnect()
		shared.dynamichubConnections["fullBright"] = nil
	end

	if not _env.isActiveFullBright then
		for prop, val in pairs(shared.configLight) do
			pcall(function() Light[prop] = val end)
		end
		return "Disabled FullBright"
	end

	local function applyBright()
		Light.Ambient = Color3.fromRGB(255, 255, 255)
		Light.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
		Light.ColorShift_Top = Color3.fromRGB(255, 255, 255)
		Light.Brightness = 2
		Light.ClockTime = 14
		Light.FogEnd = 9e9
		Light.GlobalShadows = false
	end

	applyBright()
	shared.dynamichubConnections["fullBright"] = Light.Changed:Connect(applyBright)
	return "Enabled FullBright"
end

function dynamichubfunctions.ClickButton(button: GuiButton)
	local getconnections = _env.getconnections or _env.get_signal_cons
	if not getconnections then return end

	pcall(function()
		for _, connection in pairs(getconnections(button.MouseButton1Click)) do
			if connection.Enabled and connection.Function then
				task.spawn(connection.Function)
			end
		end
	end)
end

function dynamichubfunctions.FreezePlayer(time: number, sync: boolean)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if not sync then
		task.spawn(function()
			root.Anchored = true
			task.wait(time)
			root.Anchored = false
		end)
	else
		root.Anchored = true
		task.wait(time)
		root.Anchored = false
	end
end

function dynamichubfunctions.FlyToPosition(targetPosition: Vector3, speed: number)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	dynamichubfunctions.StopFly()

	local bv = Instance.new("BodyVelocity")
	bv.Name = "DynamicHubFlyTo"
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity = (targetPosition - root.Position).Unit * speed
	bv.Parent = root

	shared.dynamichubConnections["flyToPosition"] = RunService.Heartbeat:Connect(function()
		if not root or not root.Parent or (targetPosition - root.Position).Magnitude <= 4 then
			dynamichubfunctions.StopFly()
			if root then root.CFrame = CFrame.new(targetPosition) end
		else
			bv.Velocity = (targetPosition - root.Position).Unit * speed
		end
	end)
end

function dynamichubfunctions.StopFly()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		local bv = root:FindFirstChild("DynamicHubFlyTo")
		if bv then bv:Destroy() end
	end
	if shared.dynamichubConnections["flyToPosition"] then
		shared.dynamichubConnections["flyToPosition"]:Disconnect()
		shared.dynamichubConnections["flyToPosition"] = nil
	end
end

function dynamichubfunctions.Noclip(value: boolean)
	_env.DynamicHubNoclip = value

	if shared.dynamichubConnections["noClip"] then
		shared.dynamichubConnections["noClip"]:Disconnect()
		shared.dynamichubConnections["noClip"] = nil
	end

	if not _env.DynamicHubNoclip then return "Noclip Disabled" end

	shared.dynamichubConnections["noClip"] = RunService.Stepped:Connect(function()
		local char = LocalPlayer.Character
		if not char or not _env.DynamicHubNoclip then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
	return "Noclip Enabled"
end

function dynamichubfunctions.SpectatePlayer(value: boolean, username: string)
	_env.DynamicHubSpectatePlayer = value
	
	if shared.dynamichubConnections["spectate"] then
		shared.dynamichubConnections["spectate"]:Disconnect()
		shared.dynamichubConnections["spectate"] = nil
	end

	local targetPlr = Players:FindFirstChild(username)
	local targetHum = targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChildOfClass("Humanoid")

	if not value or not targetHum then
		local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if myHum then Camera.CameraSubject = myHum end
		return
	end

	Camera.CameraSubject = targetHum
	shared.dynamichubConnections["spectate"] = targetPlr.CharacterRemoving:Connect(function()
		task.wait(0.5)
		local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if myHum then Camera.CameraSubject = myHum end
	end)
end

function dynamichubfunctions.InstantProximityPrompt(value: boolean)
	_env.instantInteraction = value

	if shared.dynamichubConnections["HoldConnection"] then
		shared.dynamichubConnections["HoldConnection"]:Disconnect()
		shared.dynamichubConnections["HoldConnection"] = nil
	end

	if not value then return end

	local function fixPrompt(prompt)
		if prompt:IsA("ProximityPrompt") then
			prompt.HoldDuration = 0
		end
	end

	for _, prompt in ipairs(workspace:GetDescendants()) do fixPrompt(prompt) end
	shared.dynamichubConnections["HoldConnection"] = workspace.DescendantAdded:Connect(fixPrompt)
end

function dynamichubfunctions.Fly(value, speed)
	if flyModule and flyModule.flymodel1 then flyModule.flymodel1(value, speed) end
end

function dynamichubfunctions.FlyV2(value, speed)
	if flyModule and flyModule.flymodel2 then flyModule.flymodel2(value, speed) end
end

shared.DynamicHubFunction = dynamichubfunctions
return dynamichubfunctions
