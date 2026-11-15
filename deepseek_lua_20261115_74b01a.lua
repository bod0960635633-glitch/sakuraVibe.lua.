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
local currentTracks = {}   -- idle/walk/run/fall/jump
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

    -- Останавливаем все, кроме нужного
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

    -- Чистим старые подключения и треки
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

    -- Загружаем треки (idle/walk/run/fall — зацикленные, jump — один раз)
    currentTracks.idle = loadTrack(animator, preset.idle, true)
    currentTracks.walk = loadTrack(animator, preset.walk, true)
    currentTracks.run  = loadTrack(animator, preset.run, true)
    currentTracks.fall = loadTrack(animator, preset.fall, true)
    currentTracks.jump = loadTrack(animator, preset.jump, false)

    -- Стартовое состояние — idle
    if currentTracks.idle then
        currentTracks.idle:Play()
        currentState = "idle"
    end

    -- Переключение по состоянию Humanoid
    stateConnection = hum.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Freefall then
            playState("fall")
        elseif newState == Enum.HumanoidStateType.Running then
            -- Running = идём/бежим; выбираем по скорости
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