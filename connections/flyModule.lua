local flyModule = {}
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

getgenv().flyModeSpeed = getgenv().flyModeSpeed or 1
getgenv().isFlyActive = false

local flyConnection1 = nil
local flyConnection2 = nil

local ctrl = {f = 0, b = 0, l = 0, r = 0, u = 0, d = 0}
local inputBeganConn, inputEndedConn

local function startTrackingControls()
	if inputBeganConn then return end
	
	inputBeganConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		local key = input.KeyCode
		if key == Enum.KeyCode.W then ctrl.f = 1
		elseif key == Enum.KeyCode.S then ctrl.b = -1
		elseif key == Enum.KeyCode.A then ctrl.l = -1
		elseif key == Enum.KeyCode.D then ctrl.r = 1
		elseif key == Enum.KeyCode.Space then ctrl.u = 1
		elseif key == Enum.KeyCode.LeftShift then ctrl.d = -1
		end
	end)

	inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		local key = input.KeyCode
		if key == Enum.KeyCode.W then ctrl.f = 0
		elseif key == Enum.KeyCode.S then ctrl.b = 0
		elseif key == Enum.KeyCode.A then ctrl.l = 0
		elseif key == Enum.KeyCode.D then ctrl.r = 0
		elseif key == Enum.KeyCode.Space then ctrl.u = 0
		elseif key == Enum.KeyCode.LeftShift then ctrl.d = 0
		end
	end)
end

local function stopTrackingControls()
	if inputBeganConn then inputBeganConn:Disconnect(); inputBeganConn = nil end
	if inputEndedConn then inputEndedConn:Disconnect(); inputEndedConn = nil end
	ctrl = {f = 0, b = 0, l = 0, r = 0, u = 0, d = 0}
end

function flyModule.flymodel1(value, customSpeed)
	if value == nil then
		getgenv().isFlyActive = not getgenv().isFlyActive
	else
		getgenv().isFlyActive = value
	end
	
	if customSpeed then getgenv().flyModeSpeed = customSpeed end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if flyConnection1 then flyConnection1:Disconnect(); flyConnection1 = nil end
	stopTrackingControls()

	if not getgenv().isFlyActive then
		if hum then
			for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
				hum:SetStateEnabled(state, true)
			end
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
		end
		if char and char:FindFirstChild("Animate") then
			char.Animate.Disabled = false
		end
		if root then
			local bg = root:FindFirstChild("FlyGyro")
			local bv = root:FindFirstChild("FlyVelocity")
			if bg then bg:Destroy() end
			if bv then bv:Destroy() end
		end
		return
	end

	if not (char and hum and root) then return end
	startTrackingControls()

	if char:FindFirstChild("Animate") then
		char.Animate.Disabled = true
	end

	for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
		track:AdjustSpeed(0)
	end
  
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	hum.PlatformStand = true
	hum:ChangeState(Enum.HumanoidStateType.Swimming)

	local bg = Instance.new("BodyGyro")
	bg.Name = "FlyGyro"
	bg.P = 9e4
	bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.CFrame = root.CFrame
	bg.Parent = root

	local bv = Instance.new("BodyVelocity")
	bv.Name = "FlyVelocity"
	bv.Velocity = Vector3.zero
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Parent = root

	local speed = 0
	local maxSpeed = 50 * getgenv().flyModeSpeed
	local lastCtrl = {f = 0, b = 0, l = 0, r = 0, u = 0, d = 0}

	flyConnection1 = RunService.RenderStepped:Connect(function()
		if not getgenv().isFlyActive or not root or not root.Parent or hum.Health <= 0 then
			flyModule.flymodel1(false)
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then return end

		local isMoving = (ctrl.l + ctrl.r ~= 0) or (ctrl.f + ctrl.b ~= 0) or (ctrl.u + ctrl.d ~= 0)
		
		if isMoving then
			speed = math.min(speed + 0.5 + (speed / maxSpeed), maxSpeed)
			lastCtrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r, u = ctrl.u, d = ctrl.d}
		else
			speed = math.max(speed - 1, 0)
		end

		local currentCtrl = isMoving and ctrl or lastCtrl
		if speed > 0 then
			local lookVec = camera.CFrame.LookVector * (currentCtrl.f + currentCtrl.b)
			local rightVec = camera.CFrame.RightVector * (currentCtrl.l + currentCtrl.r)
			local upVec = Vector3.new(0, 1, 0) * (currentCtrl.u + currentCtrl.d)
			
			bv.Velocity = (lookVec + rightVec + upVec).Unit * speed
		else
			bv.Velocity = Vector3.zero
		end

		bg.CFrame = camera.CFrame * CFrame.Angles(-math.rad((currentCtrl.f + currentCtrl.b) * 50 * (speed / maxSpeed)), 0, 0)
	end)
end

function flyModule.flymodel2(value, customSpeed)
	if value == nil then
		getgenv().isFlyActive = not getgenv().isFlyActive
	else
		getgenv().isFlyActive = value
	end

	if customSpeed then getgenv().flyModeSpeed = customSpeed end
	
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid", 3)
	local root = char:WaitForChild("HumanoidRootPart", 3)

	if flyConnection2 then flyConnection2:Disconnect(); flyConnection2 = nil end

	if not getgenv().isFlyActive then
		if root then
			local vHandler = root:FindFirstChild("VelocityHandler")
			local gHandler = root:FindFirstChild("GyroHandler")
			if vHandler then vHandler:Destroy() end
			if gHandler then gHandler:Destroy() end
		end
		if hum then hum.PlatformStand = false end
		return
	end

	if not (char and hum and root) then return end

	local playerScripts = player:WaitForChild("PlayerScripts", 5)
	local playerModule = playerScripts and playerScripts:WaitForChild("PlayerModule", 2)
	local controlModule = playerModule and playerModule:WaitForChild("ControlModule", 2)
	
	if not controlModule then 
		warn("FlyModule Error: Dynamic ControlModule missing.") 
		return 
	end
	
	local activeControls = require(controlModule)

	local bv = root:FindFirstChild("VelocityHandler") or Instance.new("BodyVelocity", root)
	bv.Name = "VelocityHandler"
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	local bg = root:FindFirstChild("GyroHandler") or Instance.new("BodyGyro", root)
	bg.Name = "GyroHandler"
	bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.P = 1000
	bg.D = 50

	flyConnection2 = RunService.PostSimulation:Connect(function()
		if not getgenv().isFlyActive or not root or not root.Parent or hum.Health <= 0 then
			flyModule.flymodel2(false)
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then return end

		hum.PlatformStand = true
		bg.CFrame = camera.CFrame

		local moveVec = activeControls:GetMoveVector()
		local finalVelocity = Vector3.zero
		
		finalVelocity = finalVelocity + camera.CFrame.RightVector * moveVec.X * (getgenv().flyModeSpeed * 25)
		finalVelocity = finalVelocity - camera.CFrame.LookVector * moveVec.Z * (getgenv().flyModeSpeed * 25)
		
		bv.Velocity = finalVelocity
	end)
end

return flyModule
