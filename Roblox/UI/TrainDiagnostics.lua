-- TRAIN DIAGNOSTICS | standalone local logger
-- Records local input, clicked part, relative motion, visible character joints and animations.
-- Local-only: does not send data to any server.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
if not player then return end

local env = _G
pcall(function() if type(getgenv) == "function" then env = getgenv() end end)
pcall(function()
    if type(env.__TRAIN_DIAG_CLEANUP) == "function" then
        env.__TRAIN_DIAG_CLEANUP()
    end
end)

local guiParent
pcall(function() if type(gethui) == "function" then guiParent = gethui() end end)
if not guiParent then
    pcall(function() guiParent = CoreGui end)
end
if not guiParent then guiParent = player:WaitForChild("PlayerGui") end

local old = guiParent:FindFirstChild("TrainDiagnostics")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TrainDiagnostics"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Name = "Window"
frame.Size = UDim2.fromOffset(520, 390)
frame.Position = UDim2.new(0.5, -260, 0.5, -195)
frame.BackgroundColor3 = Color3.fromRGB(22, 23, 29)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 34)
title.Position = UDim2.fromOffset(10, 4)
title.BackgroundTransparency = 1
title.Text = "TRAIN DIAGNOSTICS • LOCAL LOGGER"
title.TextColor3 = Color3.fromRGB(235, 235, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 22)
status.Position = UDim2.fromOffset(10, 38)
status.BackgroundTransparency = 1
status.Text = "ЗАПИСЬ ВЫКЛ"
status.TextColor3 = Color3.fromRGB(170, 170, 185)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local function makeButton(label, x, width, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(width, 30)
    b.Position = UDim2.fromOffset(x, 65)
    b.BackgroundColor3 = Color3.fromRGB(48, 49, 62)
    b.BorderSizePixel = 0
    b.Text = label
    b.TextColor3 = Color3.fromRGB(245, 245, 250)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(callback)
    return b
end

local box = Instance.new("TextBox")
box.Name = "Log"
box.Position = UDim2.fromOffset(10, 105)
box.Size = UDim2.new(1, -20, 1, -115)
box.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
box.BorderSizePixel = 0
box.TextColor3 = Color3.fromRGB(205, 210, 220)
box.PlaceholderText = "Нажми «СТАРТ», затем запрыгни на поезд и нажми ЛКМ + ПКМ."
box.Text = ""
box.ClearTextOnFocus = false
box.TextEditable = false
box.MultiLine = true
box.TextWrapped = false
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.Font = Enum.Font.Code
box.TextSize = 10
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local active = false
local lines = {}
local dropped = 0
local startedAt = 0
local lastPos, lastAt
local lastButtons = {}
local selectedPart, selectedAt
local lastAnimSignature = ""
local connections = {}
local maxLines = 9000

local function log(message)
    if not active then return end
    local line = string.format("[%07.2f] %s", os.clock() - startedAt, tostring(message))
    table.insert(lines, line)
    if #lines > maxLines then
        table.remove(lines, 1)
        dropped += 1
    end
end

local function vec(v)
    if typeof(v) ~= "Vector3" then return "n/a" end
    return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
end

local function path(obj)
    if not obj then return "nil" end
    local out, current = {}, obj
    for _ = 1, 5 do
        if not current then break end
        table.insert(out, 1, current.Name)
        current = current.Parent
    end
    return table.concat(out, "/")
end

local function getCharacter()
    local char = player.Character
    if not char then return end
    return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

local function logCharacterJoints(char)
    local count = 0
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("JointInstance") or obj:IsA("WeldConstraint")
            or obj:IsA("AlignPosition") or obj:IsA("AlignOrientation")
            or obj:IsA("RopeConstraint") or obj:IsA("RodConstraint")
            or obj:IsA("HingeConstraint") then
            local extra = ""
            pcall(function()
                if obj:IsA("JointInstance") or obj:IsA("WeldConstraint") then
                    extra = " Part0=" .. path(obj.Part0) .. " Part1=" .. path(obj.Part1)
                end
            end)
            log("CHAR JOINT: " .. obj.ClassName .. " " .. path(obj) .. extra)
            count += 1
        end
    end
    if count == 0 then log("CHAR JOINT: видимых соединений не найдено") end
end

local function logTarget(part, hit)
    if not part or not part:IsA("BasePart") then
        log("CLICK TARGET: курсор не попал в BasePart")
        return
    end
    local assembly = part.AssemblyRootPart or part
    local _, _, root = getCharacter()
    log("CLICK TARGET: " .. path(part)
        .. " | hit=" .. vec(hit)
        .. " | partPos=" .. vec(part.Position)
        .. " | assemblyRoot=" .. path(assembly)
        .. " | assemblyVel=" .. vec(assembly.AssemblyLinearVelocity)
        .. " | playerMinusPart=" .. (root and vec(root.Position - part.Position) or "n/a"))
end

local function stop()
    if not active then return end
    log("=== STOP ===")
    active = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
    status.Text = "ЗАПИСЬ ВЫКЛ • " .. #lines .. " строк"
    box.Text = (dropped > 0 and ("Удалено старых строк: " .. dropped .. "\n") or "") .. table.concat(lines, "\n")
end

local function start()
    if active then return end
    lines, dropped = {}, 0
    lastPos, lastAt, selectedPart, selectedAt = nil, nil, nil, nil
    lastButtons, lastAnimSignature = {}, ""
    startedAt = os.clock()
    active = true
    log("=== TRAIN DIAGNOSTICS START ===")
    log("Player=" .. player.Name .. " | PlaceId=" .. game.PlaceId .. " | GameId=" .. game.GameId)
    log("Локальная запись; данные никуда не отправляются.")
    local char = player.Character
    if char then logCharacterJoints(char) end

    table.insert(connections, player.CharacterAdded:Connect(function(newChar)
        log("CHARACTER ADDED: " .. newChar.Name)
        task.delay(0.5, function()
            if active and newChar.Parent then logCharacterJoints(newChar) end
        end)
    end))
    table.insert(connections, player.CharacterRemoving:Connect(function(charRemoving)
        log("CHARACTER REMOVING: " .. charRemoving.Name)
        lastPos, lastAt = nil, nil
    end))

    table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseMovement then return end
        if input.KeyCode == Enum.KeyCode.Insert then return end
        -- Ignore clicks on this diagnostics window: they are UI controls, not gameplay actions.
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.MouseButton2 then
            local mousePos = UserInputService:GetMouseLocation()
            local overWindow = false
            pcall(function()
                for _, obj in ipairs(player:WaitForChild("PlayerGui"):GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)) do
                    if obj == gui or obj:IsDescendantOf(gui) then overWindow = true break end
                end
            end)
            if overWindow then return end
        end
        log("INPUT DOWN: " .. kind.Name .. " / " .. input.KeyCode.Name .. " | processed=" .. tostring(processed))
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.MouseButton2 then
            local name = kind == Enum.UserInputType.MouseButton1 and "LMB" or "RMB"
            local other = name == "LMB" and "RMB" or "LMB"
            local now = os.clock()
            lastButtons[name] = now
            if lastButtons[other] and math.abs(now - lastButtons[other]) <= 0.30 then
                log("GRAB INPUT: ЛКМ + ПКМ нажаты в пределах 0.30 сек")
            end
            local mouse = player:GetMouse()
            local part, hit = nil, Vector3.zero
            pcall(function() part, hit = mouse.Target, mouse.Hit.Position end)
            selectedPart, selectedAt = part, now
            logTarget(part, hit)
        end
    end))
    table.insert(connections, UserInputService.InputEnded:Connect(function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            log("INPUT UP: " .. input.UserInputType.Name .. " / " .. input.KeyCode.Name .. " | processed=" .. tostring(processed))
        end
    end))

    task.spawn(function()
        while active and gui.Parent do
            local now = os.clock()
            local char, hum, root = getCharacter()
            if hum and root and root:IsA("BasePart") then
                local pos, vel = root.Position, root.AssemblyLinearVelocity
                local dt = lastAt and now - lastAt or 0
                local moved = lastPos and (pos - lastPos).Magnitude or 0
                local stateName, floorName = "Unknown", "Unknown"
                pcall(function() stateName = hum:GetState().Name end)
                pcall(function() floorName = hum.FloorMaterial.Name end)
                log(string.format("PLAYER pos=%s vel=%s speed=%.2f moved=%.2f/%.3fs state=%s floor=%s MoveDirection=%s WalkSpeed=%.1f Sit=%s PlatformStand=%s",
                    vec(pos), vec(vel), vel.Magnitude, moved, dt, stateName, floorName,
                    vec(hum.MoveDirection), hum.WalkSpeed, tostring(hum.Sit), tostring(hum.PlatformStand)))

                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    local tracks, signature = animator:GetPlayingAnimationTracks(), {}
                    for _, track in ipairs(tracks) do
                        local id, name = "unknown", "unknown"
                        pcall(function()
                            if track.Animation then id, name = track.Animation.AnimationId, track.Animation.Name end
                        end)
                        table.insert(signature, tostring(id) .. ":" .. tostring(track.Speed))
                    end
                    local sig = table.concat(signature, "|")
                    if sig ~= lastAnimSignature then
                        lastAnimSignature = sig
                        if #tracks == 0 then
                            log("ANIMATION: активных треков нет")
                        else
                            for _, track in ipairs(tracks) do
                                local id, name = "unknown", "unknown"
                                pcall(function()
                                    if track.Animation then id, name = track.Animation.AnimationId, track.Animation.Name end
                                end)
                                log("ANIMATION id=" .. tostring(id) .. " name=" .. tostring(name)
                                    .. " speed=" .. tostring(track.Speed) .. " weight=" .. tostring(track.WeightCurrent)
                                    .. " priority=" .. tostring(track.Priority))
                            end
                        end
                    end
                end

                if selectedPart and selectedPart.Parent and selectedAt and now - selectedAt <= 15 then
                    local assembly = selectedPart.AssemblyRootPart or selectedPart
                    local targetVel = assembly.AssemblyLinearVelocity
                    local rel = pos - selectedPart.Position
                    log("TARGET TRACK part=" .. path(selectedPart)
                        .. " playerPos=" .. vec(pos) .. " targetPos=" .. vec(selectedPart.Position)
                        .. " relativePos=" .. vec(rel) .. " distance=" .. string.format("%.2f", rel.Magnitude)
                        .. " targetVel=" .. vec(targetVel) .. " relativeVel=" .. vec(vel - targetVel))
                elseif selectedPart and not selectedPart.Parent then
                    log("TARGET LOST: выбранная деталь удалена")
                    selectedPart = nil
                end

                if lastPos and dt > 0 then
                    local measured = moved / dt
                    if moved > 5 and measured > 25 and vel.Magnitude < 8 then
                        log(string.format("POSSIBLE ROLLBACK/TELEPORT moved=%.2f in %.3fs measured=%.2f", moved, dt, measured))
                    end
                end
                lastPos, lastAt = pos, now
            else
                log("PLAYER: персонаж или HumanoidRootPart отсутствует")
                lastPos, lastAt = nil, nil
            end
            status.Text = string.format("ЗАПИСЬ ВКЛ • %.1f сек • %d строк", now - startedAt, #lines)
            local first = math.max(1, #lines - 79)
            local preview = {}
            for i = first, #lines do table.insert(preview, lines[i]) end
            box.Text = table.concat(preview, "\\n")
            task.wait(0.5)
        end
    end)
end

makeButton("СТАРТ", 10, 90, start)
makeButton("СТОП", 108, 90, stop)
makeButton("КОПИРОВАТЬ", 206, 105, function()
    if active then stop() end
    local full = "TRAIN DIAGNOSTICS LOG\n" .. (dropped > 0 and ("Dropped lines: " .. dropped .. "\n") or "") .. table.concat(lines, "\n")
    local clipboard
    pcall(function() clipboard = env.setclipboard or env.toclipboard end)
    if type(clipboard) == "function" then
        local ok = pcall(clipboard, full)
        if ok then status.Text = "Лог скопирован • " .. #full .. " символов" else box.Text = full; status.Text = "Буфер недоступен: Ctrl+A, Ctrl+C" end
    else
        box.Text = full
        status.Text = "Буфер недоступен: Ctrl+A, Ctrl+C"
    end
end)
makeButton("ОЧИСТИТЬ", 319, 90, function()
    if active then stop() end
    lines, dropped = {}, 0
    box.Text = ""
    status.Text = "ЛОГ ОЧИЩЕН"
end)
makeButton("ЗАКРЫТЬ", 417, 93, function()
    if active then stop() end
    if env.__TRAIN_DIAG_CLEANUP then env.__TRAIN_DIAG_CLEANUP() end
end)

-- Insert toggles visibility; it does not stop or clear the current recording.
local toggleConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Insert then
        gui.Enabled = not gui.Enabled
    end
end)

-- Simple draggable title bar.
local dragging, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, input.Position, frame.Position
    end
end)
title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
local dragConnection = UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local cleaned = false
local function cleanup()
    if cleaned then return end
    cleaned = true
    if active then stop() end
    pcall(function() dragConnection:Disconnect() end)
    pcall(function() toggleConnection:Disconnect() end)
    pcall(function() gui:Destroy() end)
    if env.__TRAIN_DIAG_CLEANUP == cleanup then env.__TRAIN_DIAG_CLEANUP = nil end
end
env.__TRAIN_DIAG_CLEANUP = cleanup
gui.Destroying:Connect(function()
    if not cleaned then
        cleaned = true
        if active then stop() end
        pcall(function() dragConnection:Disconnect() end)
        pcall(function() toggleConnection:Disconnect() end)
        if env.__TRAIN_DIAG_CLEANUP == cleanup then env.__TRAIN_DIAG_CLEANUP = nil end
    end
end)

status.Text = "ЗАПИСЬ ВЫКЛ • нажми СТАРТ"
