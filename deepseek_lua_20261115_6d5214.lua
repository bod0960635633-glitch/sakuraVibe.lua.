-- ========== CUSTOM ANIMATIONS (ниндзя и др.) ==========
-- ВАЖНО: для работы нужны валидные asset ID анимаций, доступные твоему аккаунту.
-- ID ниже — публичные примеры; если не проигрываются, замени на свои.
-- Анимации применяются к Humanoid через Animator:LoadAnimation.

local animPresets = {
    {
        name = "Default",
        -- nil = вернуть стандартный Animate-скрипт (просто не трогаем)
        idle = nil, walk = nil, run = nil, jump = nil, fall = nil,
    },
    {
        name = "Ninja",
        -- Публичные ID (примерные). Замени на свои, если не работают.
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
local activeTracks = {}
local originalAnimateScript -- сохраняем ссылку на стандартный Animate

local function stopAllTracks()
    for _, track in ipairs(activeTracks) do
        pcall(function() track:Stop() end)
    end
    table.clear(activeTracks)
end

local function playAnimation(animator, id, looped)
    if not id then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then
        track.Looped = looped
        track:Play()
        table.insert(activeTracks, track)
    end
    anim:Destroy()
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

    -- Всегда сначала останавливаем то, что запустили мы
    stopAllTracks()

    local preset = animPresets[animIndex]

    -- Управляем стандартным Animate-скриптом
    local animateScript = char:FindFirstChild("Animate")
    if preset.name == "Default" then
        if animateScript then animateScript.Enabled = true end
        return
    end

    -- Отключаем стандартный Animate, чтобы не конфликтовал
    if animateScript then animateScript.Enabled = false end

    -- Проигрываем наши анимации
    playAnimation(animator, preset.idle, true)
    playAnimation(animator, preset.walk, true)
    playAnimation(animator, preset.run, true)
    playAnimation(animator, preset.fall, true)
    -- jump проигрываем один раз по событию
    if preset.jump then
        local jumpAnim = Instance.new("Animation")
        jumpAnim.AnimationId = preset.jump
        local ok, track = pcall(function() return animator:LoadAnimation(jumpAnim) end)
        if ok and track then
            track.Looped = false
            hum.Jumping:Connect(function()
                if animPresets[animIndex].name ~= "Default" then
                    track:Play()
                end
            end)
        end
        jumpAnim:Destroy()
    end
end

local animButton = makeButton("Animation: Default", 78)
animButton.MouseButton1Click:Connect(function()
    animIndex = animIndex % #animPresets + 1
    animButton.Text = "Animation: " .. animPresets[animIndex].name
    applyAnimationPreset()
end)

-- При респавне переприменяем выбранную анимацию
player.CharacterAdded:Connect(function()
    task.wait(1.5)
    if animPresets[animIndex].name ~= "Default" then
        applyAnimationPreset()
    end
end)

-- Возврат к стандартным анимациям при выключении
local function resetAnimations()
    animIndex = 1
    animButton.Text = "Animation: Default"
    stopAllTracks()
    local char = player.Character
    local animateScript = char and char:FindFirstChild("Animate")
    if animateScript then animateScript.Enabled = true end
end