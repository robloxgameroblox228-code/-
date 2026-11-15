-- Standalone sustained lift control.
-- Intended for local testing in your own Roblox experience.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    return
end

local playerGui = player:WaitForChild("PlayerGui")
local GUI_NAME = "StandaloneLiftGui"
local FORCE_NAME = "StandaloneLiftForce"
local ATTACHMENT_NAME = "StandaloneLiftAttachment"

-- Net upward acceleration in studs/second^2.
local LIFT_ACCELERATION = 85

-- Remove remnants from an earlier run.
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
    oldGui:Destroy()
end

local function removeOldLiftObjects()
    local character = player.Character
    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object.Name == FORCE_NAME or object.Name == ATTACHMENT_NAME then
            object:Destroy()
        end
    end
end

removeOldLiftObjects()

local enabled = false
local activeForce = nil
local activeAttachment = nil

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(230, 112)
panel.Position = UDim2.new(0.5, -115, 0.72, -56)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(76, 76, 88)
stroke.Thickness = 1
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -42, 0, 30)
title.Position = UDim2.fromOffset(12, 5)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "LIFT CONTROL"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.fromOffset(27, 25)
closeButton.Position = UDim2.new(1, -33, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(54, 54, 63)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(245, 245, 245)
closeButton.TextSize = 12
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleLift"
toggleButton.Size = UDim2.new(1, -24, 0, 40)
toggleButton.Position = UDim2.fromOffset(12, 39)
toggleButton.BackgroundColor3 = Color3.fromRGB(145, 48, 48)
toggleButton.BorderSizePixel = 0
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "ПОДЪЁМ: ВЫКЛ"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 14
toggleButton.Parent = panel

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -24, 0, 20)
status.Position = UDim2.fromOffset(12, 83)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.Text = "Нажми кнопку для подъёма"
status.TextColor3 = Color3.fromRGB(175, 175, 185)
status.TextSize = 10
status.TextXAlignment = Enum.TextXAlignment.Center
status.Parent = panel

local function destroyActiveObjects()
    if activeForce then
        activeForce:Destroy()
        activeForce = nil
    end

    if activeAttachment then
        activeAttachment:Destroy()
        activeAttachment = nil
    end
end

local function updateButton()
    if enabled then
        toggleButton.Text = "ПОДЪЁМ: ВКЛ"
        toggleButton.BackgroundColor3 = Color3.fromRGB(43, 132, 76)
        status.Text = "Постоянный подъём активен"
    else
        toggleButton.Text = "ПОДЪЁМ: ВЫКЛ"
        toggleButton.BackgroundColor3 = Color3.fromRGB(145, 48, 48)
        status.Text = "Нажми кнопку для подъёма"
    end
end

local function enableLift()
    enabled = true
    updateButton()
end

local function disableLift()
    enabled = false
    destroyActiveObjects()
    removeOldLiftObjects()
    updateButton()
end

local heartbeatConnection = RunService.Heartbeat:Connect(function()
    if not enabled then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root or not root:IsA("BasePart") then
        destroyActiveObjects()
        status.Text = "Ожидание персонажа..."
        return
    end

    -- Recreate the force after respawn or character replacement.
    if activeForce and activeForce.Parent ~= root then
        destroyActiveObjects()
    end

    if not activeForce then
        local attachment = Instance.new("Attachment")
        attachment.Name = ATTACHMENT_NAME
        attachment.Parent = root

        local force = Instance.new("VectorForce")
        force.Name = FORCE_NAME
        force.Attachment0 = attachment
        force.RelativeTo = Enum.ActuatorRelativeTo.World
        force.ApplyAtCenterOfMass = true
        force.Parent = root

        activeAttachment = attachment
        activeForce = force
    end

    -- Counter gravity, then add a constant upward acceleration.
    activeForce.Force = Vector3.new(
        0,
        root.AssemblyMass * (workspace.Gravity + LIFT_ACCELERATION),
        0
    )
end)

toggleButton.Activated:Connect(function()
    if enabled then
        disableLift()
    else
        enableLift()
    end
end)

closeButton.Activated:Connect(function()
    disableLift()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    gui:Destroy()
end)

updateButton()
