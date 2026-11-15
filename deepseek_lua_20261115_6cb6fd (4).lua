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
frame.Size = UDim2.fromOffset(280, 540)
frame.Position = UDim2.new(0.5, -140, 0.5, -270)
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

-- ========== CUSTOM ANIMATIONS (ниндзя и др.) ==========
-- Анимации переключаются по состоянию Humanoid, а не играют все сразу.

local animPresets = {
    {
        name = "Default",
        idle = nil, walk = nil, run = nil, jump = nil, fall = nil,
    },
    {
        name = "Ninja",
        idle   = "rbxassetid://507766666",
        walk   = "rbxassetid://507777826",
        run    = "rbxassetid://507767714",
        jump   = "rbxassetid://507765000",
        fall   = "rbxassetid://507767968",
    },
    {
        name = "Zombie",
        idle   = "rbxassetid://616158929",
        walk   = "rbxassetid://616168032",
        run    = "rbxassetid://616163682",
        jump   = "rbxassetid://616161997",
        fall   = "rbxassetid://616157476",
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
local jumpConnection
local currentState = "idle"

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
        elseif newState == Enum.HumanoidStateType.Running then
            if hum.MoveDirection.Magnitude > 0 then
                local speed = hum.WalkSpeed
                if speed >= 16 then
                    playState("run")
                else
                    playState("walk")
                end
            else
                playState("idle")
            end
        elseif newState == Enum.HumanoidStateType.Landed or
               newState == Enum.HumanoidStateType.RunningNoPhysics then
            playState("idle")
        elseif newState == Enum.HumanoidStateType.Jumping then
            if currentTracks.jump then
                currentTracks.jump:Play()
            end
        elseif newState == Enum.HumanoidStateType.Seated then
            playState("idle")
        else
            playState("idle")
        end
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
    if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
    currentState = "idle"
    local char = player.Character
    local animateScript = char and char:FindFirstChild("Animate")
    if animateScript then animateScript.Enabled = true end
end

-- ========== WORLD COLOR VIBE (карта + небо) ==========
local colorVibes = {
    { name = "None",         tint = nil },
    { name = "Sakura Pink",  tint = Color3.fromRGB(255, 170, 210), sat = 0.15, bright = 0.05,
      atm = Color3.fromRGB(255, 200, 230), dens = 0.30 },
    { name = "Sunset",       tint = Color3.fromRGB(255, 180, 120), sat = 0.25, bright = 0.08,
      atm = Color3.fromRGB(255, 170, 110), dens = 0.35 },
    { name = "Cyber Blue",   tint = Color3.fromRGB(120, 200, 255), sat = 0.35, bright = 0.10,
      atm = Color3.fromRGB(120, 200, 255), dens = 0.25 },
    { name = "Neon Green",   tint = Color3.fromRGB(150, 255, 160), sat = 0.30, bright = 0.06,
      atm = Color3.fromRGB(150, 255, 160), dens = 0.20 },
    { name = "Purple Dream", tint = Color3.fromRGB(200, 140, 255), sat = 0.40, bright = 0.10,
      atm = Color3.fromRGB(200, 140, 255), dens = 0.35 },
    { name = "Mono",         tint = Color3.fromRGB(220, 220, 220), sat = -1.0, bright = 0.0,
      atm = Color3.fromRGB(220, 220, 220), dens = 0.15 },
}

local colorIndex = 1
local colorEffect = Instance.new("ColorCorrectionEffect")
colorEffect.Name = "SakuraVibe_Color"
colorEffect.Enabled = false
colorEffect.Parent = Lighting

local ourAtmosphere

local function ensureAtmosphere()
    if not ourAtmosphere then
        ourAtmosphere = Instance.new("Atmosphere")
        ourAtmosphere.Name = "SakuraVibe_Atmosphere"
        ourAtmosphere.Parent = Lighting
    end
end

local function applyWorldColor()
    local v = colorVibes[colorIndex]
    if not v or not v.tint then
        colorEffect.Enabled = false
        if ourAtmosphere then ourAtmosphere:Destroy(); ourAtmosphere = nil end
    else
        colorEffect.Enabled = true
        colorEffect.TintColor = v.tint
        colorEffect.Saturation = v.sat or 0
        colorEffect.Brightness = v.bright or 0

        ensureAtmosphere()
        ourAtmosphere.Color = v.atm or v.tint
        ourAtmosphere.Decay = v.atm or v.tint
        ourAtmosphere.Density = v.dens or 0.3
        ourAtmosphere.Glare = 0.2
        ourAtmosphere.Haze = 2
        ourAtmosphere.Offset = 0.1
    end
end

local colorButton = makeButton("World Vibe: None", 124)
colorButton.MouseButton1Click:Connect(function()
    colorIndex = colorIndex % #colorVibes + 1
    colorButton.Text = "World Vibe: " .. colorVibes[colorIndex].name
    applyWorldColor()
end)

-- ========== REALISTIC SAKURA (3D-лепестки в мире) ==========
local petalsOn = false
local petalFolder
local petalParts = {}
local MAX_PETALS = 40
local petalsButton = makeButton("Sakura 3D petals", 170)

local function clearPetals()
    petalsOn = false
    if petalFolder then
        petalFolder:Destroy()
        petalFolder = nil
    end
    table.clear(petalParts)
end

local function spawnPetal()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local part = Instance.new("Part")
    part.Name = "SakuraPetal3D"
    part.Size = Vector3.new(0.4, 0.05, 0.6)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.SmoothPlastic
    part.Color = Color3.fromRGB(255, math.random(170, 215), math.random(205, 235))
    part.Transparency = math.random(10, 35) / 100

    local basePos = camera.CFrame.Position
    local angle = math.random() * math.pi * 2
    local radius = math.random(15, 45)
    local height = math.random(-10, 25)
    part.Position = basePos + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)

    part.Parent = petalFolder
    table.insert(petalParts, {
        part = part,
        speed = math.random(2, 6),
        sway = math.random(1, 3),
        phase = math.random() * math.pi * 2,
        rotSpeed = math.random(-2, 2),
    })
end

petalsButton.MouseButton1Click:Connect(function()
    petalsOn = not petalsOn
    if petalsOn then
        petalFolder = Instance.new("Folder")
        petalFolder.Name = "SakuraVibe_Petals"
        petalFolder.Parent = workspace
        for _ = 1, MAX_PETALS do spawnPetal() end
    else
        clearPetals()
    end
    setButton(petalsButton, "Sakura 3D petals", petalsOn)
end)

RunService.Heartbeat:Connect(function(dt)
    if not petalsOn or not petalFolder then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local camPos = camera.CFrame.Position
    local t = tick()

    for _, p in ipairs(petalParts) do
        local part = p.part
        if part and part.Parent then
            local sway = math.sin(t * p.sway + p.phase) * 0.8
            part.Position = part.Position + Vector3.new(sway * dt, -p.speed * dt, math.cos(t * p.sway + p.phase) * 0.5 * dt)
            part.CFrame = part.CFrame * CFrame.Angles(math.rad(p.rotSpeed * dt * 60), math.rad(p.rotSpeed * dt * 30), 0)

            if (part.Position - camPos).Magnitude > 60 then
                local angle = math.random() * math.pi * 2
                local radius = math.random(15, 45)
                part.Position = camPos + Vector3.new(math.cos(angle) * radius, math.random(10, 25), math.sin(angle) * radius)
            end
        end
    end
end)

-- ========== HEADLESS (фикс первого лица) ==========
local headlessOn = false
local headlessButton = makeButton("Headless visual", 216)

local function setLocalHeadHidden(hidden)
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    head.LocalTransparencyModifier = hidden and 1 or 0
end

RunService.RenderStepped:Connect(function()
    if not headlessOn then return end
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if head and head.LocalTransparencyModifier ~= 1 then
        head.LocalTransparencyModifier = 1
    end
end)

headlessButton.MouseButton1Click:Connect(function()
    headlessOn = not headlessOn
    setLocalHeadHidden(headlessOn)
    setButton(headlessButton, "Headless visual", headlessOn)
end)

player.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local head = char:WaitForChild("Head", 5)
        if head and headlessOn then
            head.LocalTransparencyModifier = 1
        end
    end)
end)

-- ========== SCREEN VIEW ==========
local viewPresets = {
    { name = "Original",   fov = nil },
    { name = "Ultra Wide", fov = 120 },
    { name = "16:9 Wide",  fov = 100 },
    { name = "4:3",        fov = 80 },
    { name = "5:4",        fov = 76 },
    { name = "1:1",        fov = 60 },
    { name = "Fisheye",    fov = 140 },
}

local viewIndex = 1
local savedFieldOfView
local function getCamera()
    return workspace.CurrentCamera
end

local function applyViewPreset()
    local camera = getCamera()
    if not camera then return end
    if savedFieldOfView == nil then
        savedFieldOfView = camera.FieldOfView
    end
    local selected = viewPresets[viewIndex]
    camera.FieldOfView = selected.fov or savedFieldOfView
end

local viewButton = makeButton("Screen View: Original", 262)
viewButton.MouseButton1Click:Connect(function()
    viewIndex = viewIndex % #viewPresets + 1
    viewButton.Text = "Screen View: " .. viewPresets[viewIndex].name
    applyViewPreset()
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(function()
        savedFieldOfView = nil
        applyViewPreset()
    end)
end)

-- RightShift hides/shows the menu
local menuVisible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.RightShift then
        menuVisible = not menuVisible
        frame.Visible = menuVisible
    end
end)

-- ========== RESET ==========
local resetButton = makeButton("Reset visual effects", 308)
resetButton.MouseButton1Click:Connect(function()
    viewIndex = 1
    viewButton.Text = "Screen View: Original"
    local camera = getCamera()
    if camera and savedFieldOfView then
        camera.FieldOfView = savedFieldOfView
    end
    savedFieldOfView = nil

    clearPetals()
    setButton(petalsButton, "Sakura 3D petals", false)

    colorIndex = 1
    colorButton.Text = "World Vibe: None"
    applyWorldColor()

    headlessOn = false
    setLocalHeadHidden(false)
    setButton(headlessButton, "Headless visual", false)

    resetAnimations()
end)

local closeButton = makeButton("Close menu", 354)
closeButton.MouseButton1Click:Connect(function()
    local camera = getCamera()
    if camera and savedFieldOfView then
        camera.FieldOfView = savedFieldOfView
    end
    savedFieldOfView = nil
    clearPetals()
    setLocalHeadHidden(false)
    resetAnimations()
    if colorEffect then colorEffect:Destroy() end
    if ourAtmosphere then ourAtmosphere:Destroy() end
    gui:Destroy()
end)

print("Sakura Vibe loaded")