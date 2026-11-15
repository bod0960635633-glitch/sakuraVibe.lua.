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
frame.Size = UDim2.fromOffset(280, 456)
frame.Position = UDim2.new(0.5, -140, 0.5, -228)
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

-- ========== AMBIENCE ==========
local ambienceOn = false
local savedLighting
local ambienceButton = makeButton("Ambience", 78)
ambienceButton.MouseButton1Click:Connect(function()
    ambienceOn = not ambienceOn
    if ambienceOn then
        savedLighting = {
            ClockTime = Lighting.ClockTime,
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient
        }
        Lighting.ClockTime = 17.5
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(165, 125, 180)
        Lighting.OutdoorAmbient = Color3.fromRGB(130, 105, 155)
    elseif savedLighting then
        Lighting.ClockTime = savedLighting.ClockTime
        Lighting.Brightness = savedLighting.Brightness
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
    end
    setButton(ambienceButton, "Ambience", ambienceOn)
end)

-- ========== COLOR VIBES (разные цветовые фильтры) ==========
-- ColorCorrectionEffect — безопасный клиент-сайд фильтр.
local colorVibes = {
    { name = "None",        tint = nil },
    { name = "Sakura Pink", tint = Color3.fromRGB(255, 170, 210), sat = 0.15, bright = 0.05 },
    { name = "Sunset",      tint = Color3.fromRGB(255, 180, 120), sat = 0.25, bright = 0.08 },
    { name = "Cyber Blue",  tint = Color3.fromRGB(120, 200, 255), sat = 0.35, bright = 0.10 },
    { name = "Neon Green",  tint = Color3.fromRGB(150, 255, 160), sat = 0.30, bright = 0.06 },
    { name = "Purple Dream",tint = Color3.fromRGB(200, 140, 255), sat = 0.40, bright = 0.10 },
    { name = "Mono",        tint = Color3.fromRGB(220, 220, 220), sat = -1.0, bright = 0.0 },
}

local colorIndex = 1
local colorEffect = Instance.new("ColorCorrectionEffect")
colorEffect.Name = "SakuraVibe_Color"
colorEffect.Enabled = false
colorEffect.Parent = Lighting

local function applyColorVibe()
    local v = colorVibes[colorIndex]
    if not v or not v.tint then
        colorEffect.Enabled = false
        colorEffect.TintColor = Color3.fromRGB(255, 255, 255)
        colorEffect.Saturation = 0
        colorEffect.Brightness = 0
    else
        colorEffect.Enabled = true
        colorEffect.TintColor = v.tint
        colorEffect.Saturation = v.sat or 0
        colorEffect.Brightness = v.bright or 0
    end
end

local colorButton = makeButton("Color Vibe: None", 124)
colorButton.MouseButton1Click:Connect(function()
    colorIndex = colorIndex % #colorVibes + 1
    colorButton.Text = "Color Vibe: " .. colorVibes[colorIndex].name
    applyColorVibe()
end)

-- ========== SAKURA PETALS ==========
local petalsOn = false
local petalObjects = {}
local petalTweens = {}
local MAX_PETALS = 10
local petalsButton = makeButton("Sakura leaves", 170)

local function clearPetals()
    petalsOn = false

    for _, tween in ipairs(petalTweens) do
        pcall(function() tween:Cancel() end)
    end
    table.clear(petalTweens)

    for _, item in ipairs(petalObjects) do
        if item and item.Parent then item:Destroy() end
    end
    table.clear(petalObjects)
end

local function spawnPetal()
    local p = Instance.new("TextLabel")
    p.Name = "SakuraPetal"
    p.BackgroundTransparency = 1
    p.Size = UDim2.fromOffset(math.random(16, 25), math.random(16, 25))
    p.Position = UDim2.new(math.random(), 0, -0.08, 0)
    p.Text = (math.random(1, 2) == 1) and "✿" or "🌸"
    p.TextColor3 = Color3.fromRGB(255, math.random(170, 215), math.random(205, 235))
    p.TextTransparency = math.random(0, 25) / 100
    p.TextSize = math.random(16, 23)
    p.Parent = gui
    table.insert(petalObjects, p)

    task.spawn(function()
        while petalsOn and p.Parent do
            local duration = math.random(5, 10)
            local goal = {
                Position = UDim2.new(math.clamp(p.Position.X.Scale + (math.random(-18, 18) / 100), 0, 1),
                                     0, 1.08, 0),
                Rotation = math.random(180, 540)
            }
            local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
            table.insert(petalTweens, tween)
            tween:Play()
            tween.Completed:Wait()
            if petalsOn and p.Parent then
                p.Position = UDim2.new(math.random(), 0, -0.08, 0)
                p.Rotation = 0
            end
        end
    end)
end

petalsButton.MouseButton1Click:Connect(function()
    petalsOn = not petalsOn
    if petalsOn then
        for _ = 1, MAX_PETALS do spawnPetal() end
    else
        clearPetals()
    end
    setButton(petalsButton, "Sakura leaves", petalsOn)
end)

-- ========== HEADLESS (фикс первого лица) ==========
-- Движок Roblox перезаписывает LocalTransparencyModifier головы каждый кадр
-- при виде от первого лица. Поэтому мы принудительно держим 1 каждый кадр,
-- пока headless включён — тогда он не слетает.
local headlessOn = false
local headlessButton = makeButton("Headless visual", 216)

local function setLocalHeadHidden(hidden)
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    if hidden then
        head.LocalTransparencyModifier = 1
    else
        head.LocalTransparencyModifier = 0
    end
end

-- Каждый кадр поддерживаем скрытие головы, если headless включён.
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
    -- Дожидаемся Head и сразу применяем, если headless был включён
    task.spawn(function()
        local head = char:WaitForChild("Head", 5)
        if head and headlessOn then
            head.LocalTransparencyModifier = 1
        end
    end)
end)

-- ========== SCREEN VIEW (усиленный растяг) ==========
-- Усиленные пресеты FOV: шире — сильнее "растяг" картинки.
local viewPresets = {
    { name = "Original",  fov = nil },
    { name = "Ultra Wide",fov = 120 },
    { name = "16:9 Wide", fov = 100 },
    { name = "4:3",       fov = 80 },
    { name = "5:4",       fov = 76 },
    { name = "1:1",       fov = 60 },
    { name = "Fisheye",   fov = 140 },
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

    petalsOn = false
    clearPetals()
    setButton(petalsButton, "Sakura leaves", false)

    if ambienceOn and savedLighting then
        Lighting.ClockTime = savedLighting.ClockTime
        Lighting.Brightness = savedLighting.Brightness
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
    end
    ambienceOn = false
    setButton(ambienceButton, "Ambience", false)

    colorIndex = 1
    colorButton.Text = "Color Vibe: None"
    applyColorVibe()

    headlessOn = false
    setLocalHeadHidden(false)
    setButton(headlessButton, "Headless visual", false)
end)

local closeButton = makeButton("Close menu", 354)
closeButton.MouseButton1Click:Connect(function()
    local camera = getCamera()
    if camera and savedFieldOfView then
        camera.FieldOfView = savedFieldOfView
    end
    savedFieldOfView = nil
    clearPetals()
    if ambienceOn and savedLighting then
        Lighting.ClockTime = savedLighting.ClockTime
        Lighting.Brightness = savedLighting.Brightness
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
    end
    setLocalHeadHidden(false)
    if colorEffect then colorEffect:Destroy() end
    gui:Destroy()
end)

print("Sakura Vibe loaded")