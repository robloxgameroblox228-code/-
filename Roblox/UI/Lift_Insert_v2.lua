-- Lift Insert V2
-- Standalone local lift panel for testing in your own Roblox experience.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    warn("[Lift V2] LocalPlayer is unavailable.")
    return
end

local playerGui = player:WaitForChild("PlayerGui")
local GUI_NAME = "LiftInsertV2"
local ACTION_NAME = "LiftInsertV2_Toggle"
local LIFT_SPEED = 42

-- Clean up the previous copy of this version.
ContextActionService:UnbindAction(ACTION_NAME)

local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
    oldGui:Destroy()
end

local enabled = false
local lastToggle = 0
local inputConnection = nil

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(250, 126)
panel.Position = UDim2.new(0.5, -125, 0.65, -63)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -48, 0, 32)
title.Position = UDim2.fromOffset(12, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "LIFT CONTROL V2"
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local hideButton = Instance.new("TextButton")
hideButton.Size = UDim2.fromOffset(30, 26)
hideButton.Position = UDim2.new(1, -38, 0, 7)
hideButton.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
hideButton.BorderSizePixel = 0
hideButton.Font = Enum.Font.GothamBold
hideButton.Text = "X"
hideButton.TextColor3 = Color3.new(1, 1, 1)
hideButton.TextSize = 12
hideButton.Parent = panel

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 6)
hideCorner.Parent = hideButton

local liftButton = Instance.new("TextButton")
liftButton.Size = UDim2.new(1, -24, 0, 42)
liftButton.Position = UDim2.fromOffset(12, 42)
liftButton.BackgroundColor3 = Color3.fromRGB(145, 48, 48)
liftButton.BorderSizePixel = 0
liftButton.Font = Enum.Font.GothamBold
liftButton.Text = "ПОДЪЁМ: ВЫКЛ"
liftButton.TextColor3 = Color3.new(1, 1, 1)
liftButton.TextSize = 14
liftButton.Parent = panel

local liftCorner = Instance.new("UICorner")
liftCorner.CornerRadius = UDim.new(0, 8)
liftCorner.Parent = liftButton

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 24)
hint.Position = UDim2.fromOffset(10, 91)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.Text = "INSERT — открыть / скрыть меню"
hint.TextColor3 = Color3.fromRGB(180, 180, 190)
hint.TextSize = 10
hint.Parent = panel

local function getRoot()
    local character = player.Character
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function setLift(state)
    enabled = state

    if enabled then
        liftButton.Text = "ПОДЪЁМ: ВКЛ"
        liftButton.BackgroundColor3 = Color3.fromRGB(42, 135, 76)
    else
        liftButton.Text = "ПОДЪЁМ: ВЫКЛ"
        liftButton.BackgroundColor3 = Color3.fromRGB(145, 48, 48)

        -- Stop upward movement immediately when switched off.
        local root = getRoot()
        if root and root:IsA("BasePart") then
            local velocity = root.AssemblyLinearVelocity
            if velocity.Y > 0 then
                root.AssemblyLinearVelocity = Vector3.new(velocity.X, 0, velocity.Z)
            end
        end
    end
end

local function togglePanel()
    local now = os.clock()
    if now - lastToggle < 0.25 then
        return
    end
    lastToggle = now
    panel.Visible = not panel.Visible
end

liftButton.Activated:Connect(function()
    setLift(not enabled)
end)

hideButton.Activated:Connect(function()
    panel.Visible = false
end)

-- Constant upward speed while enabled. Horizontal movement is preserved.
local heartbeatConnection = RunService.Heartbeat:Connect(function()
    if not enabled then
        return
    end

    local root = getRoot()
    if root and root:IsA("BasePart") then
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(velocity.X, LIFT_SPEED, velocity.Z)
    end
end)

-- Preferred key handler. Unbinding by name prevents duplicate bindings on rerun.
local bindOk = pcall(function()
    ContextActionService:BindAction(
        ACTION_NAME,
        function(_, inputState)
            if inputState == Enum.UserInputState.Begin then
                togglePanel()
            end
            return Enum.ContextActionResult.Sink
        end,
        false,
        Enum.KeyCode.Insert
    )
end)

-- Fallback only if ContextActionService binding is unavailable.
if not bindOk then
    inputConnection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Insert then
            togglePanel()
        end
    end)
end

-- Start with the panel hidden; press Insert to show it.
setLift(false)

-- Keep the GUI independent from the lift state: hiding the panel does not stop ascent.
