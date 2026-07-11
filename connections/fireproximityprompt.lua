local _env = getgenv()
local badExecutors = {"Xeno", "Solara", "Wave", "Celery"}
local execName, exeVersion = (_env.identifyexecutor or function() return "Solara", "unknown" end)()

local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

if not _env.isFireproximityPrompt then
    _env.isFireproximityPrompt = true
    warn("[Dynamic Hub] Injecting robust fireproximityprompt framework for: " .. execName)

    shared.supportSunc = shared.supportSunc or {}
    shared.supportSunc.fireProximityPromptFuncs = shared.supportSunc.fireProximityPromptFuncs or {}

    _env.fireproximityprompt = function(prompt, cameraStand)
        if not prompt or not prompt:IsA("ProximityPrompt") then 
            warn("[Dynamic Hub] Invalid argument passed to fireproximityprompt.")
            return false 
        end

        local funcs = shared.supportSunc.fireProximityPromptFuncs
        if funcs and funcs.Activated then pcall(funcs.Activated) end

        local oldHoldDuration = prompt.HoldDuration
        local oldLineOfSight = prompt.RequiresLineOfSight
        local oldMaxDistance = prompt.MaxActivationDistance
        local oldEnabled = prompt.Enabled

        prompt.Enabled = true
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.huge

        local triggerSuccess = false

        local getconnections = _env.getconnections or _env.get_signal_cons
        if getconnections then
            local signals = {prompt.Triggered, prompt.TriggerEnded}
            for _, signal in ipairs(signals) do
                local success, cons = pcall(getconnections, signal)
                if success and type(cons) == "table" then
                    for _, con in ipairs(cons) do
                        if con and con.Function and con.Enabled then
                            task.spawn(con.Function, LocalPlayer)
                            triggerSuccess = true
                        end
                    end
                end
            end
        end

        if not triggerSuccess then
            prompt:InputHoldBegin()
            RunService.Heartbeat:Wait()
            prompt:InputHoldEnd()
            triggerSuccess = true
        end

        local camera = workspace.CurrentCamera
        if camera and not triggerSuccess then
            local oldCameraCFrame = camera.CFrame
            local oldCameraType = camera.CameraType

            local targetPart = cameraStand
            if not targetPart then
                local parent = prompt.Parent
                if parent and parent:IsA("BasePart") then
                    targetPart = parent
                elseif parent and parent:IsA("Model") then
                    targetPart = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
                end
            end

            if targetPart and targetPart:IsA("BasePart") then
                pcall(function()
                    camera.CameraType = Enum.CameraType.Scriptable
                    camera.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 2, 4), targetPart.Position)
                    task.wait(0.05)
                    
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                    triggerSuccess = true
                end)
            end

            camera.CameraType = oldCameraType
            camera.CFrame = oldCameraCFrame
        end

        if funcs and funcs.CustomTrigger then
            local customSuccess, res = pcall(funcs.CustomTrigger, prompt)
            if customSuccess and res then triggerSuccess = true end
        end

        prompt.HoldDuration = oldHoldDuration
        prompt.RequiresLineOfSight = oldLineOfSight
        prompt.MaxActivationDistance = oldMaxDistance
        prompt.Enabled = oldEnabled

        if funcs and funcs.Disabled then pcall(funcs.Disabled) end

        return triggerSuccess
    end
end
