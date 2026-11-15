-- HydraulicsUI_DRIFT_v2.lua
-- Recovered from the user's saved Oct 27 and Oct 29 source versions.
-- Target car: Workspace.Cars.negtryifg943 (A-Chassis 1.7.2).
-- Modes: hop, sway, lean, plus a separate drift mode with spring load transfer and launch assist.
-- Run as a LocalScript in StarterPlayer > StarterPlayerScripts.
-- BodyVelocity / BodyAngularVelocity are intentionally retained for compatibility
-- with the original script and its behavior; Roblox now marks both classes deprecated.

local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ==========================================
-- 0. ОЧИСТКА СТАРОГО
-- ==========================================
local pg = player:WaitForChild("PlayerGui")
for _, name in ipairs({"HydraulicsUI", "AChassisTunerMenu", "RocketMenu", "TuneToggle"}) do
    local g = pg:FindFirstChild(name)
    if g then g:Destroy() end
end

-- ==========================================
-- 1. СОСТОЯНИЕ
-- ==========================================
local currentCar, hydraCar, swayCar, leanCar, driftCar = nil, nil, nil, nil, nil
local isHydraOn, isSwayOn, isLeanOn, isDriftOn = false, false, false, false
local hydraCoroutine, swayCoroutine, leanCoroutine, driftCoroutine = nil, nil, nil, nil
local btnHydra, btnSway, btnLean, btnDrift

-- ==========================================
-- 2. НАСТРОЙКИ (мягкость/амплитуда)
-- ==========================================
local SWAY = {
    AMPLITUDE_DEG = 12,   -- амплитуда покачивания (градусы)
    OMEGA         = 2.1,  -- скорость, rad/s (немного быстрее)
    KP            = 2.5,  -- коэффициент P-регулятора
    FF            = 0.85, -- feedforward (0..1) — компенсация фазового запаздывания
    MAX_RATE      = 1.2,  -- макс. угловая скорость рад/с
    RAMP_TIME     = 0.7,  -- плавный вход в покачивание (сек)
}

local LEAN = {
    ANGLE_DEG = 30,
    KP        = 3.0,
    MAX_RATE  = 1.8,
    RAMP_TIME = 0.9,
}

-- Drift tuning. Suspension remains completely stock; only steering assist and launch boost are added.
local DRIFT = {
    BOOST_ACCEL   = 28,   -- studs/s^2 forward acceleration while throttle is pressed
    YAW_RATE      = 0.38, -- slightly sharper yaw assistance at full steering and speed
    YAW_MIN_SPEED = 7,
    YAW_FULL_SPEED = 38,
    UPDATE_RATE   = 0.04,
}

-- ==========================================
-- 3. ХЕЛПЕРЫ
-- ==========================================
local function safeCancel(co)
    if co and coroutine.status(co) ~= "dead" then pcall(task.cancel, co) end
end

local function cleanTune(car, tag)
    if not car then return end
    for _, obj in pairs(car:GetDescendants()) do
        if obj.Name == tag then pcall(function() obj:Destroy() end) end
    end
end

local function getVehicle()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil end
    return hum.SeatPart:FindFirstAncestorOfClass("Model") or hum.SeatPart
end

local function getChassis(car)
    if not car then return nil end

    if car:IsA("BasePart") then
        return car.AssemblyRootPart or car
    end

    if not car:IsA("Model") then return nil end

    -- The diagnostic dump identifies Body.#Weight as the main mass-carrying body part.
    -- Prefer its assembly root, then fall back to the driver's seat assembly.
    local body = car:FindFirstChild("Body")
    local weight = body and body:FindFirstChild("#Weight")
    if weight and weight:IsA("BasePart") and not weight.Anchored then
        local root = weight.AssemblyRootPart or weight
        local mass = 0
        pcall(function() mass = root.AssemblyMass end)
        if mass >= 10 then return root end
    end

    local seat = car:FindFirstChild("DriveSeat", true)
    if seat and seat:IsA("BasePart") then
        local root = seat.AssemblyRootPart or seat
        local mass = 0
        pcall(function() mass = root.AssemblyMass end)
        if mass >= 10 then return root end
    end

    if weight and weight:IsA("BasePart") then
        return weight.AssemblyRootPart or weight
    end

    if car.PrimaryPart then
        return car.PrimaryPart.AssemblyRootPart or car.PrimaryPart
    end

    -- Fallback for other compatible A-Chassis vehicles: prefer the heaviest physical part.
    local bestPart, bestMass = nil, -1
    for _, d in ipairs(car:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "DriveSeat" and d.Name ~= "VehicleSeat" then
            local mass = 0
            pcall(function() mass = d:GetMass() end)
            if mass > bestMass then
                bestPart, bestMass = d, mass
            end
        end
    end

    if bestPart then return bestPart.AssemblyRootPart or bestPart end
    return nil
end

local function getSafeMass(chassis)
    -- AssemblyMass reflects the complete rigid assembly, unlike the mass of a visual part.
    local mass = 0
    pcall(function() mass = chassis.AssemblyMass end)
    if not mass or mass < 10 then
        pcall(function() mass = chassis:GetMass() end)
    end
    if not mass or mass < 10 then mass = 100 end
    return mass
end

local function getRoll(chassis)
    local cf = chassis.CFrame
    local look = cf.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    local flatMagnitude = flatLook.Magnitude

    if flatMagnitude < 1e-4 then
        return math.asin(math.clamp(cf.RightVector.Y, -1, 1))
    end

    local referenceRight = flatLook.Unit:Cross(Vector3.new(0, 1, 0))
    local sinRoll = math.clamp(cf.RightVector.Y / flatMagnitude, -1, 1)
    local cosRoll = cf.RightVector:Dot(referenceRight)
    return math.atan2(sinRoll, cosRoll)
end

local function updateButtons()
    if btnHydra then
        btnHydra.BackgroundColor3 = isHydraOn and Color3.fromRGB(0, 200, 220) or Color3.fromRGB(30, 30, 30)
        btnHydra.TextColor3      = isHydraOn and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(220, 220, 220)
    end
    if btnSway then
        btnSway.BackgroundColor3 = isSwayOn and Color3.fromRGB(0, 200, 220) or Color3.fromRGB(30, 30, 30)
        btnSway.TextColor3      = isSwayOn and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(220, 220, 220)
    end
    if btnLean then
        btnLean.BackgroundColor3 = isLeanOn and Color3.fromRGB(0, 200, 220) or Color3.fromRGB(30, 30, 30)
        btnLean.TextColor3      = isLeanOn and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(220, 220, 220)
    end
    if btnDrift then
        btnDrift.BackgroundColor3 = isDriftOn and Color3.fromRGB(0, 200, 220) or Color3.fromRGB(30, 30, 30)
        btnDrift.TextColor3      = isDriftOn and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(220, 220, 220)
    end
end

-- ==========================================
-- 4. ФИЗИКА
-- ==========================================
local function stopHydra()
    isHydraOn = false; safeCancel(hydraCoroutine); hydraCoroutine = nil
    if hydraCar then cleanTune(hydraCar, "Tune_Hydra") end
    hydraCar = nil; updateButtons()
end

local function stopSway()
    isSwayOn = false; safeCancel(swayCoroutine); swayCoroutine = nil
    if swayCar then cleanTune(swayCar, "Tune_Sway") end
    swayCar = nil; updateButtons()
end

local function stopLean()
    isLeanOn = false; safeCancel(leanCoroutine); leanCoroutine = nil
    if leanCar then cleanTune(leanCar, "Tune_Lean") end
    leanCar = nil; updateButtons()
end

local function stopDrift()
    isDriftOn = false
    safeCancel(driftCoroutine)
    driftCoroutine = nil
    if driftCar then
        cleanTune(driftCar, "Tune_Drift")
        cleanTune(driftCar, "Tune_Drift_Yaw")
        cleanTune(driftCar, "Tune_Drift_Attachment")
    end
    driftCar = nil
    updateButtons()
end

-- 4.1 ПОДПРЫГИВАНИЯ
local function toggleHydra()
    local car = getVehicle()
    if not car then warn("[HydraulicsUI] Сначала сядь на водительское место."); return end
    local chassis = getChassis(car)
    if not chassis then warn("[HydraulicsUI] Не удалось определить основную сборку машины."); return end

    if isHydraOn and hydraCar ~= car then stopHydra() end
    if isHydraOn then stopHydra(); return end

    isHydraOn = true; hydraCar = car; updateButtons()

    hydraCoroutine = task.spawn(function()
        while isHydraOn do
            local v = getVehicle(); if not v or v ~= hydraCar then isHydraOn = false; break end
            local ch = getChassis(v); if not ch then isHydraOn = false; break end

            if math.abs(ch.AssemblyLinearVelocity.Y) < 2 then
                local mass = getSafeMass(ch)
                local bv = Instance.new("BodyVelocity")
                bv.Name = "Tune_Hydra"
                bv.Velocity = Vector3.new(0, 10.5, 0)
                bv.MaxForce = Vector3.new(0, math.max(mass * 500, 150000), 0)
                bv.Parent = ch
                task.wait(0.05)
                if bv and bv.Parent then bv:Destroy() end
            end
            task.wait(0.4)
        end
        if hydraCar then cleanTune(hydraCar, "Tune_Hydra") end
        isHydraOn = false; hydraCar = nil; updateButtons()
    end)
end

-- 4.2 ПОКАЧИВАНИЯ (симметричные, мягкие, с feedforward)
-- Физика: BodyAngularVelocity = LookVector * angVel
--         Положительный angVel → УМЕНЬШЕНИЕ roll → dφ/dt = -angVel
-- Значит для отслеживания φ*(t): angVel = -φ*'(t) + Kp*(φ - φ*)
local function toggleSway()
    local car = getVehicle()
    if not car then warn("[HydraulicsUI] Сначала сядь на водительское место."); return end
    local chassis = getChassis(car)
    if not chassis then warn("[HydraulicsUI] Не удалось определить основную сборку машины."); return end

    if isSwayOn and swayCar ~= car then stopSway() end
    if isSwayOn then stopSway(); return end
    if isLeanOn then stopLean() end

    isSwayOn = true; swayCar = car; updateButtons()

    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "Tune_Sway"
    bav.MaxTorque = Vector3.new(math.huge, 0, math.huge) -- roll only; do not fight steering yaw
    bav.Parent = chassis

    local AMPLITUDE = math.rad(SWAY.AMPLITUDE_DEG)
    local OMEGA     = SWAY.OMEGA
    local KP        = SWAY.KP
    local FF        = SWAY.FF
    local MAX_RATE  = SWAY.MAX_RATE
    local RAMP      = SWAY.RAMP_TIME

    local t0 = tick()
    swayCoroutine = task.spawn(function()
        while isSwayOn do
            local v = getVehicle(); if not v or v ~= swayCar or not bav.Parent then isSwayOn = false; break end
            local ch = getChassis(v); if not ch then isSwayOn = false; break end

            local t = tick() - t0
            -- Плавный вход амплитуды, чтобы не дёргало при включении
            local ramp = math.min(1, t / RAMP)
            local A = AMPLITUDE * ramp

            -- Целевой угол и его производная
            local targetRoll = A * math.sin(t * OMEGA)
            local targetRate = A * OMEGA * math.cos(t * OMEGA)
            local currentRoll = getRoll(ch)

            -- Feedforward + P-регулятор с ПРАВИЛЬНЫМ знаком
            local angVel = -FF * targetRate + KP * (currentRoll - targetRoll)
            angVel = math.clamp(angVel, -MAX_RATE, MAX_RATE)

            bav.AngularVelocity = ch.CFrame.LookVector * angVel
            task.wait(0.03)
        end
        if bav and bav.Parent then bav:Destroy() end
        isSwayOn = false; swayCar = nil; updateButtons()
    end)
end

-- 4.3 ФИКСАЦИЯ НАКЛОНА (реальная, мягкая)
-- 4.4 DRIFT MODE
-- Stock suspension is left untouched. A bounded forward VectorForce improves launch
-- and a slightly stronger yaw assist makes steering response sharper.
local function toggleDrift()
    local car = getVehicle()
    if not car then warn("[HydraulicsUI] Сначала сядь на водительское место."); return end
    local chassis = getChassis(car)
    if not chassis then warn("[HydraulicsUI] Не удалось определить основную сборку машины."); return end

    if isDriftOn and driftCar ~= car then stopDrift() end
    if isDriftOn then stopDrift(); return end
    if isSwayOn then stopSway() end
    if isLeanOn then stopLean() end
    if isHydraOn then stopHydra() end

    local seat = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    seat = seat and seat.SeatPart
    if not seat or not seat:IsA("VehicleSeat") then
        warn("[HydraulicsUI] Не удалось получить VehicleSeat водителя.")
        return
    end

    isDriftOn = true
    driftCar = car
    updateButtons()

    local attachment = Instance.new("Attachment")
    attachment.Name = "Tune_Drift_Attachment"
    attachment.Parent = chassis

    local boost = Instance.new("VectorForce")
    boost.Name = "Tune_Drift"
    boost.Attachment0 = attachment
    boost.RelativeTo = Enum.ActuatorRelativeTo.World
    boost.ApplyAtCenterOfMass = true
    boost.Force = Vector3.zero
    boost.Parent = chassis

    local yaw = Instance.new("BodyAngularVelocity")
    yaw.Name = "Tune_Drift_Yaw"
    yaw.MaxTorque = Vector3.new(0, math.max(getSafeMass(chassis) * 1800, 25000), 0)
    yaw.AngularVelocity = Vector3.zero
    yaw.Parent = chassis

    driftCoroutine = task.spawn(function()
        while isDriftOn do
            local activeCar = getVehicle()
            if not activeCar or activeCar ~= driftCar or not chassis.Parent or not seat.Parent then
                break
            end

            local steer = math.clamp(seat.SteerFloat, -1, 1)
            local throttle = math.max(0, seat.ThrottleFloat)
            local speed = chassis.AssemblyLinearVelocity.Magnitude
            local mass = getSafeMass(chassis)

            -- Launch assist only adds force while the driver is pressing forward.
            boost.Force = chassis.CFrame.LookVector * (mass * DRIFT.BOOST_ACCEL * throttle)

            -- Mild yaw assist grows with speed and steering, capped to avoid spinning out.
            local speedFactor = math.clamp(
                (speed - DRIFT.YAW_MIN_SPEED) / (DRIFT.YAW_FULL_SPEED - DRIFT.YAW_MIN_SPEED),
                0, 1
            )
            yaw.AngularVelocity = Vector3.new(0, -steer * DRIFT.YAW_RATE * speedFactor, 0)

            task.wait(DRIFT.UPDATE_RATE)
        end

        if boost and boost.Parent then boost:Destroy() end
        if yaw and yaw.Parent then yaw:Destroy() end
        if attachment and attachment.Parent then attachment:Destroy() end
        isDriftOn = false
        driftCar = nil
        updateButtons()
    end)
end

local function toggleLean()
    local car = getVehicle()
    if not car then warn("[HydraulicsUI] Сначала сядь на водительское место."); return end
    local chassis = getChassis(car)
    if not chassis then warn("[HydraulicsUI] Не удалось определить основную сборку машины."); return end

    if isLeanOn and leanCar ~= car then stopLean() end
    if isLeanOn then stopLean(); return end
    if isSwayOn then stopSway() end

    isLeanOn = true; leanCar = car; updateButtons()

    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "Tune_Lean"
    bav.MaxTorque = Vector3.new(math.huge, 0, math.huge) -- roll only; do not fight steering yaw
    bav.Parent = chassis

    -- Адаптивный угол: чем шире машина, тем больше можно
    local targetAngle = math.rad(LEAN.ANGLE_DEG) * (math.random(1, 2) == 1 and 1 or -1)

    local KP        = LEAN.KP
    local MAX_RATE  = LEAN.MAX_RATE
    local RAMP      = LEAN.RAMP_TIME

    local t0 = tick()
    local recoveringFromOverTilt = false
    local leanLimit = math.rad(40)
    local recoveryRelease = math.rad(30)

    leanCoroutine = task.spawn(function()
        while isLeanOn do
            local v = getVehicle(); if not v or v ~= leanCar or not bav.Parent then isLeanOn = false; break end
            local ch = getChassis(v); if not ch then isLeanOn = false; break end

            local t = tick() - t0
            -- Smoothly ramp toward the requested lean angle.
            local ramp = math.min(1, t / RAMP)
            local target = targetAngle * ramp
            local currentRoll = getRoll(ch)
            local absRoll = math.abs(currentRoll)

            -- Hysteresis: if roll reaches 40 degrees, stop leaning outward and recover toward level.
            -- Release recovery only after the body returns below 30 degrees.
            if absRoll >= leanLimit then
                recoveringFromOverTilt = true
            elseif absRoll <= recoveryRelease then
                recoveringFromOverTilt = false
            end

            local angVel
            if recoveringFromOverTilt then
                angVel = 4.5 * currentRoll
                angVel = math.clamp(angVel, -2.2, 2.2)
            else
                angVel = KP * (currentRoll - target)
                angVel = math.clamp(angVel, -MAX_RATE, MAX_RATE)
            end

            bav.AngularVelocity = ch.CFrame.LookVector * angVel
            task.wait(0.03)
        end
        if bav and bav.Parent then bav:Destroy() end
        isLeanOn = false; leanCar = nil; updateButtons()
    end)
end

-- ==========================================
-- 5. АВТО-СБРОС ПРИ СМЕНЕ МАШИНЫ
-- ==========================================
local heartbeatConnection = RunService.Heartbeat:Connect(function()
    local v = getVehicle()
    if v ~= currentCar then
        if isHydraOn then stopHydra() end
        if isSwayOn then stopSway() end
        if isLeanOn then stopLean() end
        if isDriftOn then stopDrift() end
        currentCar = v
    end
end)

-- ==========================================
-- 6. UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HydraulicsUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = pg

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 35, 0, 35)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.Text = "⚙️"
ToggleBtn.TextSize = 16
ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local function syncMenuPosition()
    MainFrame.Position = UDim2.new(
        ToggleBtn.Position.X.Scale, ToggleBtn.Position.X.Offset + 42,
        ToggleBtn.Position.Y.Scale, ToggleBtn.Position.Y.Offset
    )
end
syncMenuPosition()

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 20)
Title.BackgroundTransparency = 1
Title.Text = "ГИДРАВЛИКА"
Title.TextColor3 = Color3.fromRGB(150, 150, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 10
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Parent = MainFrame

local function createBtn(text, yPos, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 30)
    btn.Position = UDim2.new(0, 8, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        local active = (btn == btnHydra and isHydraOn) or (btn == btnSway and isSwayOn) or (btn == btnLean and isLeanOn)
        if not active then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play() end
    end)
    btn.MouseLeave:Connect(updateButtons)
    btn.MouseButton1Click:Connect(function() onClick(); updateButtons() end)
    return btn
end

btnHydra = createBtn("🔽 ПОДПРЫГИВАНИЯ", 25, toggleHydra)
btnSway  = createBtn("↔️ ПОКАЧИВАНИЯ",   60, toggleSway)
btnLean  = createBtn("↘️ ФИКС. НАКЛОН",   95, toggleLean)
btnDrift = createBtn("🏁 DRIFT MODE",    130, toggleDrift)

local isMenuOpen = false
local function toggleMenu()
    isMenuOpen = not isMenuOpen
    local targetSize = isMenuOpen and UDim2.new(0, 150, 0, 165) or UDim2.new(0, 0, 0, 0)
    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
    TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {Rotation = isMenuOpen and 90 or 0}):Play()
end

local dragging, dragInput, dragStart, startPos, didMove = false, nil, nil, nil, false
local inputConnections = {}

inputConnections[#inputConnections + 1] = ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, didMove, dragStart, startPos = true, false, input.Position, ToggleBtn.Position
    end
end)
inputConnections[#inputConnections + 1] = ToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
inputConnections[#inputConnections + 1] = UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        if delta.Magnitude > 3 then didMove = true end
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        syncMenuPosition()
    end
end)
inputConnections[#inputConnections + 1] = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragInput = false, nil
    end
end)
ToggleBtn.MouseButton1Click:Connect(function()
    if didMove then didMove = false; return end
    toggleMenu()
end)

-- ==========================================
-- 7. ЗАВЕРШЕНИЕ И ОЧИСТКА
-- ==========================================
local shuttingDown = false
local function shutdown(removeGui)
    if shuttingDown then return end
    shuttingDown = true

    stopHydra()
    stopSway()
    stopLean()
    stopDrift()

    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end

    for _, connection in ipairs(inputConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(inputConnections)

    if removeGui and ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end

ScreenGui.Destroying:Connect(function()
    shutdown(false)
end)

if script then
    script.Destroying:Connect(function()
        shutdown(true)
    end)
end