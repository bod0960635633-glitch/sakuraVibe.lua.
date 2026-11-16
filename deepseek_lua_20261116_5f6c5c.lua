-- ========== BODY SHAPES (Безопасно через скейлы) ==========
local bodyMode = 0
local bodyButton = makeButton("Body: Normal", 124)
local savedScales = nil

local function applyBodyShape()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if bodyMode == 0 then
        if savedScales then
            hum.BodyTypeScale = savedScales.BodyTypeScale
            hum.BodyDepthScale = savedScales.BodyDepthScale
            hum.BodyWidthScale = savedScales.BodyWidthScale
            hum.HeadScale = savedScales.HeadScale
            savedScales = nil
        end
    else
        if not savedScales then
            savedScales = {
                BodyTypeScale = hum.BodyTypeScale,
                BodyDepthScale = hum.BodyDepthScale,
                BodyWidthScale = hum.BodyWidthScale,
                HeadScale = hum.HeadScale,
            }
        end
        
        if bodyMode == 1 then
            hum.BodyTypeScale = 0
            hum.BodyDepthScale = 0
            hum.BodyWidthScale = 0
            hum.HeadScale = 1
        elseif bodyMode == 2 then
            hum.BodyTypeScale = 0.1
            hum.BodyDepthScale = 0.1
            hum.BodyWidthScale = 0.1
            hum.HeadScale = 1.2
        end
    end
end

bodyButton.MouseButton1Click:Connect(function()
    bodyMode = (bodyMode + 1) % 3
    local names = {"Normal", "Blocky", "Robloxian 2.0"}
    bodyButton.Text = "Body: " .. names[bodyMode + 1]
    bodyButton.BackgroundColor3 = bodyMode ~= 0 and Color3.fromRGB(145, 82, 145) or Color3.fromRGB(91, 57, 119)
    applyBodyShape()
end)

player.CharacterAdded:Connect(function() 
    task.wait(1.5)
    savedScales = nil
    if bodyMode ~= 0 then applyBodyShape() end 
end)

-- ========== BLACK SHADES (Визуально, без физики) ==========
local shadesOn = false
local shadesButton = makeButton("Black Shades", 170)
local shadesFolder = nil
local shadesRenderConn = nil

local function updateShadesPosition()
    if not shadesOn or not shadesFolder then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local offset = CFrame.new(0, 0.2, -0.55)
    local targetCFrame = head.CFrame * offset

    for _, part in ipairs(shadesFolder:GetChildren()) do
        if part:IsA("BasePart") then
            part.CFrame = targetCFrame * (part:GetAttribute("Offset") or CFrame.new())
        end
    end
end

local function applyShades()
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    if shadesOn then
        if shadesFolder then shadesFolder:Destroy() end
        shadesFolder = Instance.new("Folder")
        shadesFolder.Name = "SakuraVibe_Shades"
        shadesFolder.Parent = char

        local function makePart(name, size, offset, color)
            local p = Instance.new("Part")
            p.Name = name
            p.Size = size
            p.Color = color or Color3.fromRGB(0, 0, 0)
            p.Material = Enum.Material.SmoothPlastic
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
            p.Massless = true
            p.Anchored = true
            p.Parent = shadesFolder
            p:SetAttribute("Offset", offset)
            return p
        end

        makePart("LeftLens", Vector3.new(0.9, 0.6, 0.1), CFrame.new(-0.5, 0, 0))
        makePart("RightLens", Vector3.new(0.9, 0.6, 0.1), CFrame.new(0.5, 0, 0))
        makePart("Bridge", Vector3.new(0.3, 0.1, 0.1), CFrame.new(0, 0, 0))
        makePart("LeftTemple", Vector3.new(0.1, 0.1, 0.8), CFrame.new(-0.95, 0, 0.4))
        makePart("RightTemple", Vector3.new(0.1, 0.1, 0.8), CFrame.new(0.95, 0, 0.4))

        updateShadesPosition()

        if shadesRenderConn then shadesRenderConn:Disconnect() end
        shadesRenderConn = RunService.RenderStepped:Connect(updateShadesPosition)

    else
        if shadesRenderConn then shadesRenderConn:Disconnect(); shadesRenderConn = nil end
        if shadesFolder then shadesFolder:Destroy(); shadesFolder = nil end
    end
end

shadesButton.MouseButton1Click:Connect(function()
    shadesOn = not shadesOn
    applyShades()
    setButton(shadesButton, "Black Shades", shadesOn)
end)

player.CharacterAdded:Connect(function() 
    task.wait(1.5)
    if shadesOn then applyShades() end 
end)

-- ========== WORLD COLOR VIBE ==========
local colorVibes = {
    { name = "None", tint = nil },
    { name = "Sakura Pink", tint = Color3.fromRGB(255, 170, 210), sat = 0.15, bright = 0.05, atm = Color3.fromRGB(255, 200, 230), dens = 0.30 },
    { name = "Sunset", tint = Color3.fromRGB(255, 180, 120), sat = 0.25, bright = 0.08, atm = Color3.fromRGB(255, 170, 110), dens = 0.35 },
    { name = "Cyber Blue", tint = Color3.fromRGB(120, 200, 255), sat = 0.35, bright = 0.10, atm = Color3.fromRGB(120, 200, 255), dens = 0.25 },
    { name = "Neon Green", tint = Color3.fromRGB(150, 255, 160), sat = 0.30, bright = 0.06, atm = Color3.fromRGB(150, 255, 160), dens = 0.20 },
    { name = "Purple Dream", tint = Color3.fromRGB(200, 140, 255), sat = 0.40, bright = 0.10, atm = Color3.fromRGB(200, 140, 255), dens = 0.35 },
    { name = "Mono", tint = Color3.fromRGB(220, 220, 220), sat = -1.0, bright = 0.0, atm = Color3.fromRGB(220, 220, 220), dens = 0.15 },
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

local colorButton = makeButton("World Vibe: None", 216)
colorButton.MouseButton1Click:Connect(function()
    colorIndex = colorIndex % #colorVibes + 1
    colorButton.Text = "World Vibe: " .. colorVibes[colorIndex].name
    applyWorldColor()
end)

-- ========== REALISTIC SAKURA ==========
local petalsOn = false
local petalFolder
local petalParts = {}
local MAX_PETALS = 100
local petalsButton = makeButton("Sakura 3D petals", 262)

local function clearPetals()
    petalsOn = false
    if petalFolder then petalFolder:Destroy(); petalFolder = nil end
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
        part = part, speed = math.random(2, 6), sway = math.random(1, 3),
        phase = math.random() * math.pi * 2, rotSpeed = math.random(-2, 2),
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

-- ========== HEADLESS ==========
local headlessOn = false
local headlessButton = makeButton("Headless visual", 308)

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
    if head and head.LocalTransparencyModifier ~= 1 then head.LocalTransparencyModifier = 1 end
end)

headlessButton.MouseButton1Click:Connect(function()
    headlessOn = not headlessOn
    setLocalHeadHidden(headlessOn)
    setButton(headlessButton, "Headless visual", headlessOn)
end)

player.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local head = char:WaitForChild("Head", 5)
        if head and headlessOn then head.LocalTransparencyModifier = 1 end
    end)
end)

-- ========== SCREEN VIEW ==========
local viewPresets = {
    { name = "Original", fov = nil }, { name = "Wide 100", fov = 100 }, { name = "Wide 110", fov = 110 },
    { name = "Ultra 120", fov = 120 }, { name = "Ultra 130", fov = 130 }, { name = "Fisheye 140", fov = 140 }, { name = "Insane 160", fov = 160 },
}

local viewIndex = 1
local savedFieldOfView
local function getCamera() return workspace.CurrentCamera end

local function applyViewPreset()
    local camera = getCamera()
    if not camera then return end
    if savedFieldOfView == nil then savedFieldOfView = camera.FieldOfView end
    camera.FieldOfView = viewPresets[viewIndex].fov or savedFieldOfView
end

local viewButton = makeButton("Screen View: Original", 354)
viewButton.MouseButton1Click:Connect(function()
    viewIndex = viewIndex % #viewPresets + 1
    viewButton.Text = "Screen View: " .. viewPresets[viewIndex].name
    applyViewPreset()
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel and UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        local camera = getCamera()
        if camera then
            camera.FieldOfView = math.clamp(camera.FieldOfView - input.Position.Z * 5, 30, 170)
            viewButton.Text = "Screen View: Custom " .. math.floor(camera.FieldOfView)
        end
    end
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(function() savedFieldOfView = nil; applyViewPreset() end)
end)

-- RightShift hides/shows the menu
local menuVisible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.RightShift and input.UserInputType == Enum.UserInputType.Keyboard then
        menuVisible = not menuVisible
        frame.Visible = menuVisible
    end
end)

-- ========== RESET ==========
local resetButton = makeButton("Reset visual effects", 400)
resetButton.MouseButton1Click:Connect(function()
    viewIndex = 1
    viewButton.Text = "Screen View: Original"
    local camera = getCamera()
    if camera and savedFieldOfView then camera.FieldOfView = savedFieldOfView end
    savedFieldOfView = nil
    clearPetals(); setButton(petalsButton, "Sakura 3D petals", false)
    colorIndex = 1; colorButton.Text = "World Vibe: None"; applyWorldColor()
    headlessOn = false; setLocalHeadHidden(false); setButton(headlessButton, "Headless visual", false)
    resetAnimations()

    if bodyMode ~= 0 then
        bodyMode = 0
        bodyButton.Text = "Body: Normal"
        bodyButton.BackgroundColor3 = Color3.fromRGB(91, 57, 119)
        applyBodyShape()
    end

    if shadesOn then
        shadesOn = false
        applyShades()
        setButton(shadesButton, "Black Shades", false)
    end
end)

-- ========== CLOSE ==========
local closeButton = makeButton("Close menu", 446)
closeButton.MouseButton1Click:Connect(function()
    local camera = getCamera()
    if camera and savedFieldOfView then camera.FieldOfView = savedFieldOfView end
    savedFieldOfView = nil
    clearPetals(); setLocalHeadHidden(false); resetAnimations()
    if colorEffect then colorEffect:Destroy() end
    if ourAtmosphere then ourAtmosphere:Destroy() end
    if bodyMode ~= 0 then bodyMode = 0; applyBodyShape() end
    if shadesOn then shadesOn = false; applyShades() end
    gui:Destroy()
end)

print("Sakura Vibe loaded")