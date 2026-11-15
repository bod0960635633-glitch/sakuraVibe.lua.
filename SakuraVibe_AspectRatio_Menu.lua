-- Sakura Vibe for Xeno (client-side visual-only)
-- No remote code loading, no game-state edits, no player targeting.
-- Run locally. Some experiences may restrict or reset local visual changes.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
frame.Size = UDim2.fromOffset(280, 376)
frame.Position = UDim2.new(0.5, -140, 0.5, -188)
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

-- Ambience: save current local Lighting values and restore them when disabled.
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

-- Screen-space sakura petals. Nothing is spawned until the button is clicked.
local petalsOn = false
local petalObjects = {}
local petalTweens = {}
local MAX_PETALS = 10
local petalsButton = makeButton("Sakura leaves", 124)

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

-- Local-only headless appearance. Other players may still see the normal avatar.
local headlessOn = false
local originalHeadTransparency
local headlessButton = makeButton("Headless visual", 170)

local function setLocalHeadHidden(hidden)
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end
    if hidden then
        if originalHeadTransparency == nil then
            originalHeadTransparency = head.LocalTransparencyModifier
        end
        head.LocalTransparencyModifier = 1
    else
        head.LocalTransparencyModifier = originalHeadTransparency or 0
        originalHeadTransparency = nil
    end
end

headlessButton.MouseButton1Click:Connect(function()
    headlessOn = not headlessOn
    setLocalHeadHidden(headlessOn)
    setButton(headlessButton, "Headless visual", headlessOn)
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    if headlessOn then setLocalHeadHidden(true) end
end)


-- Aspect-ratio presets are visual letterboxing only; they do not change
-- the actual monitor resolution or Roblox's rendered viewport resolution.
local aspectPresets = {
    { name = "Original", ratio = nil },
    { name = "16:9", ratio = 16 / 9 },
    { name = "4:3", ratio = 4 / 3 },
    { name = "5:4", ratio = 5 / 4 },
    { name = "1:1", ratio = 1 },
}

local aspectIndex = 1
local aspectBars = Instance.new("Folder")
aspectBars.Name = "SakuraAspectBars"
aspectBars.Parent = gui

local function clearAspectBars()
    for _, item in ipairs(aspectBars:GetChildren()) do
        item:Destroy()
    end
end

local function applyAspectRatio()
    clearAspectBars()
    local selected = aspectPresets[aspectIndex]
    if not selected.ratio then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then return end

    local currentRatio = viewport.X / viewport.Y
    local targetRatio = selected.ratio

    local function makeBar(position, size)
        local bar = Instance.new("Frame")
        bar.Name = "AspectBar"
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = Color3.new(0, 0, 0)
        bar.Position = position
        bar.Size = size
        bar.ZIndex = 20
        bar.Parent = aspectBars
    end

    if currentRatio > targetRatio then
        local widthScale = (1 - targetRatio / currentRatio) / 2
        makeBar(UDim2.new(0, 0, 0, 0), UDim2.new(widthScale, 0, 1, 0))
        makeBar(UDim2.new(1 - widthScale, 0, 0, 0), UDim2.new(widthScale, 0, 1, 0))
    else
        local heightScale = (1 - currentRatio / targetRatio) / 2
        makeBar(UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, heightScale, 0))
        makeBar(UDim2.new(0, 0, 1 - heightScale, 0), UDim2.new(1, 0, heightScale, 0))
    end
end

local aspectButton = makeButton("Aspect Ratio: Original", 216)
aspectButton.MouseButton1Click:Connect(function()
    aspectIndex = aspectIndex % #aspectPresets + 1
    local selected = aspectPresets[aspectIndex]
    aspectButton.Text = "Aspect Ratio: " .. selected.name
    applyAspectRatio()
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(applyAspectRatio)
end)

-- Restore visual settings and close.
local resetButton = makeButton("Reset visual effects", 262)
resetButton.MouseButton1Click:Connect(function()
    aspectIndex = 1
    aspectButton.Text = "Aspect Ratio: Original"
    clearAspectBars()
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

    headlessOn = false
    setLocalHeadHidden(false)
    setButton(headlessButton, "Headless visual", false)
end)

local closeButton = makeButton("Close menu", 308)
closeButton.MouseButton1Click:Connect(function()
    clearAspectBars()
    clearPetals()
    if ambienceOn and savedLighting then
        Lighting.ClockTime = savedLighting.ClockTime
        Lighting.Brightness = savedLighting.Brightness
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
    end
    setLocalHeadHidden(false)
    gui:Destroy()
end)

print("Sakura Vibe loaded")
