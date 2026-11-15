-- Sakura Vibe for Xeno (client-side visual-only)
-- No remote code loading, no game-state edits, no player targeting.
-- Run locally. Some experiences may restrict or reset local visual changes.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clean up a previous copy
local old = playerGui:FindFirstChild("SakuraVibe_Xeno")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SakuraVibe_Xeno"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 580)
frame.Position = UDim2.new(0.5, -140, 0.5, -290)
frame.BackgroundColor3 = Color3.fromRGB(34, 23, 48)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(205, 130, 205)
stroke.Thickness = 1.5
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 42)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Text = "SAKURA VIBE  ✿"
title.TextColor3 = Color3.fromRGB(255, 190, 225)
title.Font = Enum.Font.GothamBold
title.TextSize = 21
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 20)
subtitle.Position = UDim2.fromOffset(10, 45)
subtitle.BackgroundTransparency = 1
subtitle.Text = "client-side visual effects"
subtitle.TextColor3 = Color3.fromRGB(190, 170, 205)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.Parent = frame

-- Make the window draggable
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local function makeButton(label, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -28, 0, 38)
    b.Position = UDim2.fromOffset(14, y)
    b.BackgroundColor3 = Color3.fromRGB(91, 57, 119)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(255, 240, 250)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13
    b.Text = label .. "  [OFF]"
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    return b
end

local function setButton(b, label, state)
    b.Text = label .. (state and "  [ON]" or "  [OFF]")
    b.BackgroundColor3 = state and Color3.fromRGB(145, 82, 145)
                                   or Color3.fromRGB(91, 57, 119)
end

-- ========== CUSTOM ANIMATIONS ==========
-- Ninja Walk: rbxassetid://656118852
-- Zombie Animation Pack: ID из официального пака (см. таблицу ниже)

local animPresets = {
    {
        name = "Default",
        idle = nil, walk = nil, run = nil, jump = nil, fall = nil,
    },
    {
        name = "Ninja",
        idle   = "rbxassetid://507766666",
        walk   = "rbxassetid://656118852",
        run    = "rbxassetid://656118852",
        jump   = "rbxassetid://507765000",
        fall   = "rbxassetid://507767968",
    },
    {
        name = "Zombie",
        -- Официальный Zombie Animation Pack
        idle   = "rbxassetid://616158929",   -- Zombie Idle
        walk   = "rbxassetid://616168032",   -- Zombie Walk
        run    = "rbxassetid://616163682",   -- Zombie Run
        jump   = "rbxassetid://616161997",   -- Zombie Jump
        fall   = "rbxassetid://616157476",   -- Zombie Fall
    },
    {
        name = "Levitate",
        idle   = "rbxassetid://616006778",
        walk   = "rbxassetid://616013216",
        run    = "rbxassetid://616010382",
        jump   = "rbxassetid://616008087",
        fall   = "rbxassetid://616005863",
    },
    {
        name = "Dance",
        idle   = "rbxassetid://507771019",
        walk   = "rbxassetid://507777826",
        run    = "rbxassetid://507767714",
        jump   = "rbxassetid://507765000",
        fall   = "rbxassetid://507767968",
    },
}

local animIndex = 1
local currentTracks = {}
local stateConnection
local runningConnection
local jumpConnection
local currentState = "idle"
local WALK_SPEED_THRESHOLD = 10

local function stopTrack(track)
    if track then pcall(function() track:Stop() end) end
end

local function stopAllTracks()
    for _, t in pairs(currentTracks) do stopTrack(t) end
    currentTracks = {}
end

local function loadTrack(animator, id, looped)
    if not id then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    anim:Destroy()
    if ok and track then
        track.Looped = looped
        return track
    end
    return nil
end

local function playState(state)
    if currentState == state then return end
    currentState = state

    for name, t in pairs(currentTracks) do
        if name ~= state then stopTrack(t) end
    end

    local t = currentTracks[state]
    if t and not t.IsPlaying then
        t:Play()
    end
end

local function updateLocomotion(speed)
    if currentState == "fall" or currentState == "jump" then return end
    if speed < 0.5 then
        playState("idle")
    elseif speed < WALK_SPEED_THRESHOLD then
        playState("walk")
    else
        playState("run")
    end
end

local function applyAnimationPreset()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    stopAllTracks()
    if stateConnection then stateConnection:Disconnect(); stateConnection = nil end
    if runningConnection then runningConnection:Disconnect(); runningConnection = nil end
    if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
    currentState = "idle"

    local preset = animPresets[animIndex]
    local animateScript = char:FindFirstChild("Animate")

    if preset.name == "Default" then
        if animateScript then animateScript.Enabled = true end
        return
    end

    if animateScript then animateScript.Enabled = false end

    currentTracks.idle = loadTrack(animator, preset.idle, true)
    currentTracks.walk = loadTrack(animator, preset.walk, true)
    currentTracks.run  = loadTrack(animator, preset.run, true)
    currentTracks.fall = loadTrack(animator, preset.fall, true)
    currentTracks.jump = loadTrack(animator, preset.jump, false)

    if currentTracks.idle then
        currentTracks.idle:Play()
        currentState = "idle"
    end

    stateConnection = hum.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Freefall then
            playState("fall")
        elseif newState == Enum.HumanoidStateType.Running or
               newState == Enum.HumanoidStateType.RunningNoPhysics then
            local speed = hum.RootPart and hum.RootPart.Velocity.Magnitude or 0
            updateLocomotion(speed)
        elseif newState == Enum.HumanoidStateType.Landed then
            playState("idle")
        elseif newState == Enum.HumanoidStateType.Jumping then
            currentState = "jump"
            if currentTracks.jump then
                currentTracks.jump:Play()
            end
        elseif newState == Enum.HumanoidStateType.Seated then
            playState("idle")
        else
            playState("idle")
        end
    end)

    runningConnection = hum.Running:Connect(function(speed)
        updateLocomotion(speed)
    end)
end

local animButton = makeButton("Animation: Default", 78)
animButton.MouseButton1Click:Connect(function()
    animIndex = animIndex % #animPresets + 1
    animButton.Text = "Animation: " .. animPresets[animIndex].name
    applyAnimationPreset()
end)

player.CharacterAdded:Connect(function()
    task.wait(1.5)
    if animPresets[animIndex].name ~= "Default" then
        applyAnimationPreset()
    end
end)

local function resetAnimations()
    animIndex = 1
    animButton.Text = "Animation: Default"
    stopAllTracks()
    if stateConnection then stateConnection:Disconnect(); stateConnection = nil end
    if runningConnection then runningConnection:Disconnect(); runningConnection = nil end
    if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
    currentState = "idle"
    local char = player.Character
    local animateScript = char and char:FindFirstChild("Animate")
    if animateScript then animateScript.Enabled = true end
end

-- ========== ROBLOXIAN 2.0 BODY (локально, только если куплено