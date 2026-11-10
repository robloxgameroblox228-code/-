-- FREE MENU v2.0 | reviewed and hardened UI build
-- Sections: Test, Visuals, Settings. No gameplay or vehicle functions.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Keep one active copy and disconnect listeners from previous executions.
local sharedEnv = _G
pcall(function()
    if type(getgenv) == "function" then sharedEnv = getgenv() end
end)
pcall(function()
    local previousCleanup = sharedEnv.__FREE_MENU_CLEANUP
    if type(previousCleanup) == "function" then previousCleanup() end
end)

local externalConnections = {}
local function connectExternal(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(externalConnections, connection)
    return connection
end

local player = Players.LocalPlayer
if not player then
    warn("[FREE MENU] LocalPlayer is unavailable.")
    return
end
local parent
pcall(function() if gethui then parent = gethui() end end)
if not parent then pcall(function() parent = CoreGui end) end
if not parent then parent = player:WaitForChild("PlayerGui") end

local cleanupContainers = {}
local function addCleanupContainer(container)
    if container then table.insert(cleanupContainers, container) end
end
addCleanupContainer(parent)
addCleanupContainer(CoreGui)
addCleanupContainer(player:FindFirstChildOfClass("PlayerGui"))

for _, container in ipairs(cleanupContainers) do
    pcall(function()
        local old = container:FindFirstChild("FreeMenuUI")
        if old then old:Destroy() end
    end)
end

local state = {
    theme = "Dark",
    accent = Color3.fromRGB(110, 145, 255),
    transparency = 0,
    scale = 1,
    animations = true,
    rounded = true,
    compact = false,
    customBg = Color3.fromRGB(25, 27, 34),
    customPanel = Color3.fromRGB(34, 37, 46),
    customText = Color3.fromRGB(242, 244, 250),
    playerESP = false, playerChams = false, espStyle = "Контур",
    espColor = Color3.fromRGB(100, 220, 255),
    overheadHat = false, overheadTrail = false, overheadParticles = false,
    particleStyle = "Звёзды", playerExpanded = false, ownExpanded = false
}

local palettes = {
    Dark = {
        bg = Color3.fromRGB(17, 19, 25),
        panel = Color3.fromRGB(24, 27, 35),
        card = Color3.fromRGB(32, 36, 46),
        hover = Color3.fromRGB(43, 48, 61),
        line = Color3.fromRGB(54, 61, 77),
        text = Color3.fromRGB(242, 244, 250),
        muted = Color3.fromRGB(151, 160, 179)
    },
    Light = {
        bg = Color3.fromRGB(241, 243, 248),
        panel = Color3.fromRGB(255, 255, 255),
        card = Color3.fromRGB(232, 235, 242),
        hover = Color3.fromRGB(220, 224, 234),
        line = Color3.fromRGB(204, 210, 222),
        text = Color3.fromRGB(31, 35, 45),
        muted = Color3.fromRGB(103, 111, 128)
    }
}
local C = palettes.Dark

local function tween(obj, props, time)
    if not state.animations then
        for k, v in pairs(props) do obj[k] = v end
        return
    end
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function make(className, props, parentObj, role)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    if role then obj:SetAttribute("FreeRole", role) end
    obj.Parent = parentObj
    return obj
end

local function round(obj, radius)
    local c = obj:FindFirstChildOfClass("UICorner")
    if not c then c = Instance.new("UICorner"); c.Parent = obj end
    c.CornerRadius = UDim.new(0, state.rounded and (radius or 12) or 3)
end

local function stroke(obj, color)
    local s = obj:FindFirstChildOfClass("UIStroke")
    if not s then s = Instance.new("UIStroke"); s.Parent = obj end
    s.Color = color or C.line
    s.Thickness = 1
    s.Transparency = 0.12
end

local gui = make("ScreenGui", {
    Name = "FreeMenuUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, parent)

local launcher = make("TextButton", {
    Name = "Launcher",
    Size = UDim2.fromOffset(64, 46),
    Position = UDim2.new(0, 22, 0.5, -23),
    BackgroundColor3 = C.panel,
    Text = "FREE",
    TextColor3 = state.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    AutoButtonColor = false,
    ZIndex = 30
}, gui, "panel")
round(launcher, 14)
stroke(launcher, state.accent)

local shadow = make("Frame", {
    Name = "Shadow",
    Size = UDim2.fromOffset(784, 534),
    Position = UDim2.new(0.5, -392, 0.5, -267),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.72,
    Visible = false,
    ZIndex = 1
}, gui)
round(shadow, 20)

local window = make("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(760, 510),
    Position = UDim2.new(0.5, -380, 0.5, -255),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = state.transparency,
    Visible = false,
    ClipsDescendants = true,
    ZIndex = 2
}, gui, "bg")
round(window, 18)
local windowScale = make("UIScale", {Scale = 1}, window)
stroke(window)

local top = make("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 3
}, window, "panel")
round(top, 18)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 1, -18),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 3
}, top, "panel")

local title = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(24, 11),
    Size = UDim2.new(0, 260, 0, 26),
    Text = "FREE MENU",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C.text,
    ZIndex = 4
}, top, "text")
local subtitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(25, 38),
    Size = UDim2.new(0, 300, 0, 15),
    Text = "INTERFACE CUSTOMIZATION",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C.muted,
    ZIndex = 4
}, top, "muted")

local function topButton(caption, rightOffset, callback)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(34, 32),
        Position = UDim2.new(1, rightOffset, 0, 17),
        BackgroundColor3 = C.card,
        Text = caption,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        AutoButtonColor = false,
        ZIndex = 5
    }, top, "card")
    round(b, 9)
    local locked = false
    b.Activated:Connect(function()
        if locked then return end
        locked = true
        local ok, err = pcall(callback)
        if not ok then warn("[FREE MENU] Button action failed: " .. tostring(err)) end
        task.delay(0.22, function() locked = false end)
    end)
    b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = C.hover}, 0.1) end)
    b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = C.card}, 0.1) end)
    return b
end

local opened = false
local maximized = false
local transitioning = false
local RunService = game:GetService("RunService")
local oldMouseBehavior, oldMouseIcon
local cursorLoop
local function unlockCursor()
    oldMouseBehavior = UserInputService.MouseBehavior
    oldMouseIcon = UserInputService.MouseIconEnabled
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
    if cursorLoop then cursorLoop:Disconnect() end
    cursorLoop = RunService.RenderStepped:Connect(function()
        if opened and gui.Parent then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
    end)
end
local function restoreCursor()
    if cursorLoop then cursorLoop:Disconnect(); cursorLoop = nil end
    if oldMouseBehavior then UserInputService.MouseBehavior = oldMouseBehavior end
    if oldMouseIcon ~= nil then UserInputService.MouseIconEnabled = oldMouseIcon end
end
local baseSize = Vector2.new(760, 510)
local function getDisplayScale()
    local scale = state.scale
    local camera = workspace.CurrentCamera
    if camera then
        local viewport = camera.ViewportSize
        local fitX = math.max(0.45, (viewport.X - 28) / baseSize.X)
        local fitY = math.max(0.45, (viewport.Y - 28) / baseSize.Y)
        scale = math.min(scale, fitX, fitY)
    end
    return math.max(0.45, scale)
end

local function setWindowSize()
    if maximized then
        windowScale.Scale = 1
        window.Size = UDim2.new(1, -28, 1, -28)
        window.Position = UDim2.fromOffset(14, 14)
        shadow.Size = UDim2.new(1, -16, 1, -16)
        shadow.Position = UDim2.fromOffset(8, 8)
        return
    end

    local displayScale = getDisplayScale()
    windowScale.Scale = displayScale
    window.Size = UDim2.fromOffset(baseSize.X, baseSize.Y)
    window.Position = UDim2.new(0.5, -baseSize.X / 2, 0.5, -baseSize.Y / 2)

    local w, h = baseSize.X * displayScale, baseSize.Y * displayScale
    shadow.Size = UDim2.fromOffset(w + 24, h + 24)
    shadow.Position = UDim2.new(0.5, -(w + 24) / 2, 0.5, -(h + 24) / 2)
end

local function closeMenu()
    if transitioning or not opened then return end
    transitioning = true
    opened = false
    restoreCursor()
    tween(window, {Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1}, 0.16)
    tween(shadow, {BackgroundTransparency = 1}, 0.16)
    task.wait(state.animations and 0.17 or 0)
    window.Visible = false
    shadow.Visible = false
    window.BackgroundTransparency = state.transparency
    setWindowSize()
    transitioning = false
end

topButton("□", -126, function()
    maximized = not maximized
    if maximized then
        windowScale.Scale = 1
        tween(window, {Size = UDim2.new(1, -28, 1, -28), Position = UDim2.fromOffset(14, 14)}, 0.2)
        tween(shadow, {Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8)}, 0.2)
    else
        setWindowSize()
    end
end)
topButton("—", -82, closeMenu)
topButton("×", -38, function() gui:Destroy() end)

local sidebar = make("Frame", {
    Position = UDim2.fromOffset(14, 78),
    Size = UDim2.new(0, 166, 1, -92),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 3
}, window, "panel")
round(sidebar, 14)

local content = make("Frame", {
    Position = UDim2.fromOffset(192, 78),
    Size = UDim2.new(1, -206, 1, -92),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 3
}, window, "panel")
round(content, 14)

local tabButtons = {}
local activePage = "Тест"
local function createTab(name, y)
    local b = make("TextButton", {
        Position = UDim2.fromOffset(9, y),
        Size = UDim2.new(1, -18, 0, 44),
        BackgroundColor3 = C.panel,
        Text = name,
        TextColor3 = C.muted,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex = 4
    }, sidebar, "tab")
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 15)
    pad.Parent = b
    round(b, 10)
    tabButtons[name] = b
    return b
end
createTab("Тест", 12)
createTab("Визуалы", 64)
createTab("Настройки", 116)

local status = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 1, -30),
    Size = UDim2.new(1, -28, 0, 16),
    Text = "FREE BUILD  •  2.0",
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C.muted,
    ZIndex = 4
}, sidebar, "muted")

local pageTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 15),
    Size = UDim2.new(1, -40, 0, 25),
    Text = "Тест",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C.text,
    ZIndex = 4
}, content, "text")
local pageDesc = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(21, 42),
    Size = UDim2.new(1, -42, 0, 17),
    Text = "Проверка элементов интерфейса",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = C.muted,
    ZIndex = 4
}, content, "muted")

local scroll = make("ScrollingFrame", {
    Name = "PageScroll",
    Position = UDim2.fromOffset(16, 72),
    Size = UDim2.new(1, -32, 1, -86),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = state.accent,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
    ZIndex = 4
}, content)
local list = make("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
}, scroll)
make("UIPadding", {PaddingBottom = UDim.new(0, 10)}, scroll)

local function textLabel(parentObj, text, pos, size, fontSize, color, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Position = pos,
        Size = size,
        Text = text,
        Font = bold and Enum.Font.GothamSemibold or Enum.Font.Gotham,
        TextSize = fontSize or 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        TextColor3 = color or C.text,
        ZIndex = 7
    }, parentObj, color == C.muted and "muted" or "text")
end

local function card(height)
    local f = make("Frame", {
        Size = UDim2.new(1, -5, 0, height or 76),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        LayoutOrder = #scroll:GetChildren() + 1,
        ZIndex = 5
    }, scroll, "card")
    round(f, 12)
    return f
end

local function actionButton(parentObj, caption, x, y, width, callback, secondary)
    local b = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -(x or 14), 0, y or 22),
        Size = UDim2.fromOffset(width or 112, 34),
        BackgroundColor3 = secondary and C.hover or state.accent,
        Text = caption,
        TextColor3 = secondary and C.text or Color3.fromRGB(15, 18, 25),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
        ZIndex = 8
    }, parentObj, secondary and "hover" or "accent")
    round(b, 9)
    local locked = false
    b.Activated:Connect(function()
        if locked then return end
        locked = true
        local ok, err = pcall(callback)
        if not ok then warn("[FREE MENU] Button action failed: " .. tostring(err)) end
        task.delay(0.22, function() locked = false end)
    end)
    b.MouseEnter:Connect(function()
        if not secondary then tween(b, {BackgroundColor3 = state.accent:Lerp(Color3.new(1,1,1), 0.12)}, 0.1) end
    end)
    b.MouseLeave:Connect(function()
        if not secondary then tween(b, {BackgroundColor3 = state.accent}, 0.1) end
    end)
    return b
end

local function notify(head, message)
    local n = make("Frame", {
        Size = UDim2.fromOffset(290, 76),
        Position = UDim2.new(1, 310, 1, -96),
        BackgroundColor3 = C.panel,
        ZIndex = 40
    }, gui, "panel")
    round(n, 12)
    stroke(n, state.accent)
    textLabel(n, head, UDim2.fromOffset(15, 9), UDim2.new(1, -30, 0, 22), 12, C.text, true)
    textLabel(n, message, UDim2.fromOffset(15, 34), UDim2.new(1, -30, 0, 28), 10, C.muted, false)
    tween(n, {Position = UDim2.new(1, -306, 1, -96)}, 0.22)
    task.delay(2.2, function()
        if n.Parent then
            tween(n, {Position = UDim2.new(1, 310, 1, -96)}, 0.18)
            task.wait(0.2)
            if n.Parent then n:Destroy() end
        end
    end)
end

local function clearPage()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("GuiObject") and child ~= list and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local function hexToColor(value)
    local h = tostring(value):gsub("#", "")
    if #h ~= 6 or not h:match("^%x%x%x%x%x%x$") then return nil end
    return Color3.fromRGB(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16))
end
local function colorToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R*255+0.5), math.floor(color.G*255+0.5), math.floor(color.B*255+0.5))
end

local function applyTheme()
    if state.theme == "Dark" then
        C = palettes.Dark
    elseif state.theme == "Light" then
        C = palettes.Light
    else
        C = {
            bg = state.customBg,
            panel = state.customBg:Lerp(Color3.new(1,1,1), 0.08),
            card = state.customPanel,
            hover = state.customPanel:Lerp(Color3.new(1,1,1), 0.12),
            line = state.customPanel:Lerp(Color3.new(1,1,1), 0.22),
            text = state.customText,
            muted = state.customText:Lerp(state.customBg, 0.42)
        }
    end
    for _, obj in ipairs(gui:GetDescendants()) do
        local role = obj:GetAttribute("FreeRole")
        if role == "bg" then obj.BackgroundColor3 = C.bg
        elseif role == "panel" then obj.BackgroundColor3 = C.panel
        elseif role == "card" then obj.BackgroundColor3 = C.card
        elseif role == "hover" then obj.BackgroundColor3 = C.hover
        elseif role == "text" then obj.TextColor3 = C.text
        elseif role == "muted" then obj.TextColor3 = C.muted
        elseif role == "accent" then
            obj.BackgroundColor3 = state.accent
            if obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("TextLabel") then
                obj.TextColor3 = Color3.fromRGB(15,18,25)
            end
        elseif role == "accentText" then
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.TextColor3 = state.accent
            end
        elseif role == "tab" then
            obj.BackgroundColor3 = obj.Name == activePage and C.hover or C.panel
            obj.TextColor3 = obj.Name == activePage and state.accent or C.muted
        end
        if obj:IsA("UIStroke") and obj.Parent == window then obj.Color = C.line end
    end
    launcher.TextColor3 = state.accent
    local ls = launcher:FindFirstChildOfClass("UIStroke")
    if ls then ls.Color = state.accent end
    local ws = window:FindFirstChildOfClass("UIStroke")
    if ws then ws.Color = C.line end
    scroll.ScrollBarImageColor3 = state.accent
    window.BackgroundTransparency = state.transparency
    for name, tab in pairs(tabButtons) do
        tab.BackgroundColor3 = name == activePage and C.hover or C.panel
        tab.TextColor3 = name == activePage and state.accent or C.muted
    end
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("UICorner") then obj.CornerRadius = UDim.new(0, state.rounded and 12 or 3) end
    end
end

local function addToggle(titleText, desc, getter, setter)
    local f = card(72)
    textLabel(f, titleText, UDim2.fromOffset(16, 10), UDim2.new(1, -150, 0, 22), 12, C.text, true)
    textLabel(f, desc, UDim2.fromOffset(16, 35), UDim2.new(1, -150, 0, 20), 9, C.muted, false)
    local b
    b = actionButton(f, getter() and "ВКЛЮЧЕНО" or "ВЫКЛЮЧЕНО", 14, 19, 112, function()
        setter(not getter())
        local enabled = getter()
        b.Text = enabled and "ВКЛЮЧЕНО" or "ВЫКЛЮЧЕНО"
        b:SetAttribute("FreeRole", enabled and "accent" or "hover")
        b.BackgroundColor3 = enabled and state.accent or C.hover
        b.TextColor3 = enabled and Color3.fromRGB(15,18,25) or C.text
    end, not getter())
    if not getter() then
        b.BackgroundColor3 = C.hover
        b.TextColor3 = C.text
    end
end

local function buildTest()
    clearPage()
    local f = card(82)
    textLabel(f, "Проверка уведомлений", UDim2.fromOffset(16, 10), UDim2.new(1, -160, 0, 22), 12, C.text, true)
    textLabel(f, "Проверь, как выглядят системные сообщения меню", UDim2.fromOffset(16, 37), UDim2.new(1, -160, 0, 20), 9, C.muted)
    actionButton(f, "ПРОВЕРИТЬ", 14, 24, 116, function() notify("Всё работает", "Тестовое уведомление отображается корректно.") end)

    local f2 = card(82)
    textLabel(f2, "Тест анимации", UDim2.fromOffset(16, 10), UDim2.new(1, -160, 0, 22), 12, C.text, true)
    textLabel(f2, "Проверь плавность появления элементов", UDim2.fromOffset(16, 37), UDim2.new(1, -160, 0, 20), 9, C.muted)
    actionButton(f2, "ЗАПУСТИТЬ", 14, 24, 116, function()
        local bar = make("Frame", {Position = UDim2.fromOffset(16, 67), Size = UDim2.fromOffset(8, 4), BackgroundColor3 = state.accent, ZIndex = 9}, f2, "accent")
        round(bar, 3)
        tween(bar, {Size = UDim2.fromOffset(math.max(80, f2.AbsoluteSize.X - 48), 4)}, 0.45)
        task.delay(1, function() if bar.Parent then tween(bar, {BackgroundTransparency = 1}, 0.2); task.wait(0.22); if bar.Parent then bar:Destroy() end end end)
    end)

    local f3 = card(72)
    textLabel(f3, "Плавная прокрутка", UDim2.fromOffset(16, 10), UDim2.new(1, -30, 0, 22), 12, C.text, true)
    textLabel(f3, "Прокрути эту страницу колёсиком мыши или свайпом", UDim2.fromOffset(16, 36), UDim2.new(1, -30, 0, 20), 9, C.muted)
    for i = 1, 4 do
        local extra = card(60)
        textLabel(extra, "Демонстрационный блок 0" .. i, UDim2.fromOffset(16, 8), UDim2.new(1, -30, 0, 20), 11, C.text, true)
        textLabel(extra, "Нужен только для проверки высоты и прокрутки страницы", UDim2.fromOffset(16, 30), UDim2.new(1, -30, 0, 18), 9, C.muted)
    end
end

local visualFolder = Instance.new("Folder")
visualFolder.Name = "FreeMenuVisuals"
visualFolder.Parent = gui
local playerVisuals = {}
local function clearPlayerVisual(target)
    local objects = playerVisuals[target]
    if objects then
        for _, object in ipairs(objects) do if object and object.Parent then object:Destroy() end end
    end
    playerVisuals[target] = nil
end
local function updatePlayerVisual(target)
    clearPlayerVisual(target)
    if target == player or not (state.playerESP or state.playerChams) then return end
    local character = target.Character
    if not character then return end
    local made = {}
    playerVisuals[target] = made
    if state.playerChams then
        local h = Instance.new("Highlight")
        h.Adornee = character
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillColor = state.espColor
        h.OutlineColor = state.espColor:Lerp(Color3.new(1,1,1),0.35)
        h.FillTransparency = state.espStyle == "Заливка" and 0.25 or state.espStyle == "Контур" and 1 or 0.55
        h.OutlineTransparency = state.espStyle == "Заливка" and 0.2 or 0
        h.Parent = visualFolder
        table.insert(made,h)
    end
    if state.playerESP then
        local head = character:FindFirstChild("Head")
        if head then
            local bill = Instance.new("BillboardGui")
            bill.Adornee = head
            bill.Size = UDim2.fromOffset(150,30)
            bill.StudsOffset = Vector3.new(0,2.7,0)
            bill.AlwaysOnTop = true
            bill.Parent = visualFolder
            local text = Instance.new("TextLabel")
            text.Size = UDim2.fromScale(1,1)
            text.BackgroundColor3 = Color3.fromRGB(12,15,22)
            text.BackgroundTransparency = 0.18
            text.Text = target.DisplayName
            text.TextColor3 = state.espColor
            text.Font = Enum.Font.GothamBold
            text.TextSize = 12
            text.Parent = bill
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0,8)
            corner.Parent = text
            table.insert(made,bill)
        end
    end
end
local function refreshPlayerVisuals()
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then updatePlayerVisual(target) end
    end
end
local function bindPlayer(target)
    if target == player then return end

    connectExternal(target.CharacterAdded, function(character)
        task.delay(0.5, function()
            if gui.Parent and target.Parent == Players and target.Character == character then
                updatePlayerVisual(target)
            end
        end)
    end)

    if target.Character then
        task.defer(function()
            if gui.Parent and target.Parent == Players then
                updatePlayerVisual(target)
            end
        end)
    end
end

connectExternal(Players.PlayerAdded, bindPlayer)
connectExternal(Players.PlayerRemoving, function(target)
    clearPlayerVisual(target)
end)

for _, target in ipairs(Players:GetPlayers()) do
    bindPlayer(target)
end

local ownEffects = {}
local function clearOwnEffects()
    for _, obj in ipairs(ownEffects) do if obj and obj.Parent then obj:Destroy() end end
    table.clear(ownEffects)
end
local function refreshOwnEffects()
    clearOwnEffects()
    local character = player.Character
    if not character then return end
    local head, root = character:FindFirstChild("Head"), character:FindFirstChild("HumanoidRootPart")
    if state.overheadHat and head then
        -- Layered brim gives a simple stylized conical East-Asian hat silhouette.
        for i, spec in ipairs({
            {Vector3.new(2.1,0.12,2.1),1.0,Color3.fromRGB(225,174,75)},
            {Vector3.new(1.5,0.15,1.5),1.13,Color3.fromRGB(166,54,54)},
            {Vector3.new(0.85,0.17,0.85),1.28,Color3.fromRGB(225,174,75)}
        }) do
            local p = Instance.new("Part")
            p.Name = "FreeMenuHatLayer"..i
            p.Shape = Enum.PartType.Cylinder
            p.Size = spec[1]
            p.Color = spec[3]
            p.Material = Enum.Material.SmoothPlastic
            p.CanCollide, p.CanTouch, p.CanQuery, p.Massless = false,false,false,true
            p.CFrame = head.CFrame * CFrame.new(0,spec[2],0) * CFrame.Angles(0,0,math.rad(90))
            p.Parent = character
            local weld = Instance.new("WeldConstraint")
            weld.Part0, weld.Part1, weld.Parent = head,p,p
            table.insert(ownEffects,p)
        end
    end
    if state.overheadTrail and root then
        local x = Instance.new("Attachment"); x.Position=Vector3.new(0,0.7,0.45); x.Parent=root
        local y = Instance.new("Attachment"); y.Position=Vector3.new(0,-0.7,0.45); y.Parent=root
        local trail = Instance.new("Trail")
        trail.Attachment0,trail.Attachment1=x,y
        trail.Lifetime=0.6
        trail.Color=ColorSequence.new(state.espColor,state.accent)
        trail.LightEmission=0.6
        trail.Parent=root
        table.insert(ownEffects,x); table.insert(ownEffects,y); table.insert(ownEffects,trail)
    end
    if state.overheadParticles and root then
        local att=Instance.new("Attachment"); att.Position=Vector3.new(0,1.1,0); att.Parent=root
        local em=Instance.new("ParticleEmitter")
        em.Rate=14; em.Lifetime=NumberRange.new(0.7,1.4); em.Speed=NumberRange.new(1,2)
        em.SpreadAngle=Vector2.new(180,180); em.LightEmission=0.55
        em.Size=NumberSequence.new(0.2,0)
        em.Color=ColorSequence.new(state.espColor,state.accent)
        em.Texture=state.particleStyle=="Дым" and "rbxasset://textures/particles/smoke_main.dds"
            or state.particleStyle=="Огонь" and "rbxasset://textures/particles/fire_main.dds"
            or "rbxasset://textures/particles/sparkles_main.dds"
        em.Parent=att
        table.insert(ownEffects,att)
    end
end
connectExternal(player.CharacterAdded, function(character)
    task.delay(0.8, function()
        if gui.Parent and player.Character == character then
            refreshOwnEffects()
        end
    end)
end)

local function sectionHeader(titleText, description, expanded, callback)
    local f=card(74)
    textLabel(f,titleText,UDim2.fromOffset(16,8),UDim2.new(1,-155,0,22),12,C.text,true)
    textLabel(f,description,UDim2.fromOffset(16,34),UDim2.new(1,-155,0,20),9,C.muted)
    actionButton(f,expanded and "СВЕРНУТЬ" or "РАЗВЕРНУТЬ",14,20,112,callback,true)
end

local function buildVisuals()
    clearPage()
    sectionHeader("Игроки","ESP, Chams и разные виды подсветки",state.playerExpanded,function()
        state.playerExpanded=not state.playerExpanded
        buildVisuals()
    end)
    if state.playerExpanded then
        addToggle("ESP игроков","Имя над персонажами поверх объектов",function() return state.playerESP end,function(v)
            state.playerESP=v; refreshPlayerVisuals()
        end)
        addToggle("Chams","Подсветка силуэта сквозь стены",function() return state.playerChams end,function(v)
            state.playerChams=v; refreshPlayerVisuals()
        end)
        local styles={"Контур","Заливка","Комбинированный"}
        local st=card(78)
        textLabel(st,"Тип подсветки",UDim2.fromOffset(16,8),UDim2.new(1,-30,0,20),12,C.text,true)
        actionButton(st,state.espStyle,14,36,150,function()
            local i=table.find(styles,state.espStyle) or 1
            state.espStyle=styles[i%#styles+1]
            refreshPlayerVisuals()
            buildVisuals()
        end,true)
        local colors={Color3.fromRGB(90,210,255),Color3.fromRGB(255,90,110),Color3.fromRGB(120,255,150),Color3.fromRGB(190,120,255),Color3.fromRGB(255,205,95)}
        local cf=card(72)
        textLabel(cf,"Цвет подсветки",UDim2.fromOffset(16,7),UDim2.new(1,-30,0,20),12,C.text,true)
        for i,color in ipairs(colors) do
            local dot=make("TextButton",{Position=UDim2.fromOffset(16+(i-1)*39,37),Size=UDim2.fromOffset(26,26),BackgroundColor3=color,Text="",AutoButtonColor=false,ZIndex=8},cf)
            round(dot,13); stroke(dot,C.line)
            dot.Activated:Connect(function() state.espColor=color; refreshPlayerVisuals(); refreshOwnEffects() end)
        end
    end
    sectionHeader("Надо мной","Шляпа, след и частицы вокруг твоего персонажа",state.ownExpanded,function()
        state.ownExpanded=not state.ownExpanded
        buildVisuals()
    end)
    if state.ownExpanded then
        addToggle("Китайская шляпа","Декоративная шляпа над головой",function() return state.overheadHat end,function(v)
            state.overheadHat=v; refreshOwnEffects()
        end)
        addToggle("След за мной","Цветной след при движении",function() return state.overheadTrail end,function(v)
            state.overheadTrail=v; refreshOwnEffects()
        end)
        addToggle("Частицы","Эффект вокруг персонажа",function() return state.overheadParticles end,function(v)
            state.overheadParticles=v; refreshOwnEffects()
        end)
        local pf=card(78)
        textLabel(pf,"Вид частиц",UDim2.fromOffset(16,8),UDim2.new(1,-30,0,20),12,C.text,true)
        actionButton(pf,state.particleStyle,14,36,130,function()
            local kinds={"Звёзды","Дым","Огонь"}
            local i=table.find(kinds,state.particleStyle) or 1
            state.particleStyle=kinds[i%#kinds+1]
            refreshOwnEffects(); buildVisuals()
        end,true)
    end
end

local function buildSettings()
    clearPage()
    local f = card(100)
    textLabel(f, "Тема интерфейса", UDim2.fromOffset(16, 10), UDim2.new(1, -30, 0, 22), 12, C.text, true)
    textLabel(f, "Выбери готовую тему или настрой собственную", UDim2.fromOffset(16, 35), UDim2.new(1, -30, 0, 18), 9, C.muted)
    local themes = {"Тёмная", "Светлая", "Своя"}
    for i, name in ipairs(themes) do
        local b = make("TextButton", {
            Position = UDim2.fromOffset(16 + (i-1)*126, 62),
            Size = UDim2.fromOffset(116, 28),
            BackgroundColor3 = C.hover,
            Text = name,
            TextColor3 = C.text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 10,
            AutoButtonColor = false,
            ZIndex = 8
        }, f, "hover")
        round(b, 8)
        b.Activated:Connect(function()
            state.theme = (i == 1 and "Dark") or (i == 2 and "Light") or "Custom"
            applyTheme()
            notify("Тема изменена", name)
            buildSettings()
        end)
    end

    local accentCard = card(88)
    textLabel(accentCard, "Цвет меню", UDim2.fromOffset(16, 9), UDim2.new(1, -170, 0, 22), 12, C.text, true)
    textLabel(accentCard, "Введи HEX-код, например #6E91FF", UDim2.fromOffset(16, 35), UDim2.new(1, -170, 0, 20), 9, C.muted)
    local hexBox = make("TextBox", {
        Position = UDim2.new(1, -154, 0, 23),
        Size = UDim2.fromOffset(94, 32),
        BackgroundColor3 = C.hover,
        Text = colorToHex(state.accent),
        PlaceholderText = "#RRGGBB",
        TextColor3 = C.text,
        PlaceholderColor3 = C.muted,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 8
    }, accentCard, "hover")
    round(hexBox, 8)
    actionButton(accentCard, "ПРИМЕНИТЬ", 14, 22, 112, function()
        local color = hexToColor(hexBox.Text)
        if color then
            state.accent = color
            applyTheme()
            notify("Цвет применён", colorToHex(color))
        else
            notify("Неверный HEX", "Нужен формат #RRGGBB")
        end
    end)

    if state.theme == "Custom" then
        local custom = card(120)
        textLabel(custom, "Своя цветовая схема", UDim2.fromOffset(16, 8), UDim2.new(1, -30, 0, 22), 12, C.text, true)
        textLabel(custom, "Фон / карточки / текст — HEX цвета", UDim2.fromOffset(16, 31), UDim2.new(1, -30, 0, 18), 9, C.muted)
        local fields = {
            {key = "customBg", hint = "Фон", x = 16},
            {key = "customPanel", hint = "Карточки", x = 146},
            {key = "customText", hint = "Текст", x = 276}
        }
        for _, item in ipairs(fields) do
            local box = make("TextBox", {
                Position = UDim2.fromOffset(item.x, 60),
                Size = UDim2.fromOffset(116, 30),
                BackgroundColor3 = C.hover,
                Text = colorToHex(state[item.key]),
                PlaceholderText = item.hint,
                TextColor3 = C.text,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                ClearTextOnFocus = false,
                ZIndex = 8
            }, custom, "hover")
            round(box, 8)
            box.FocusLost:Connect(function()
                local parsed = hexToColor(box.Text)
                if parsed then state[item.key] = parsed; applyTheme() else notify("Неверный HEX", "Используй формат #RRGGBB") end
            end)
        end
    end

    local reset = card(76)
    textLabel(reset, "Сбросить оформление", UDim2.fromOffset(16, 9), UDim2.new(1, -160, 0, 22), 12, C.text, true)
    textLabel(reset, "Вернуть стандартную тёмную тему и настройки", UDim2.fromOffset(16, 35), UDim2.new(1, -160, 0, 18), 9, C.muted)
    actionButton(reset, "СБРОСИТЬ", 14, 20, 112, function()
        state.theme = "Dark"
        state.accent = Color3.fromRGB(110,145,255)
        state.transparency = 0
        state.scale = 1
        state.animations = true
        state.rounded = true
        state.compact = false
        state.customBg = Color3.fromRGB(25,27,34)
        state.customPanel = Color3.fromRGB(34,37,46)
        state.customText = Color3.fromRGB(242,244,250)
        sidebar.Size = UDim2.new(0,166,1,-92)
        content.Position = UDim2.fromOffset(192,78)
        content.Size = UDim2.new(1,-206,1,-92)
        setWindowSize()
        applyTheme()
        notify("Готово", "Оформление сброшено")
        buildSettings()
    end)

    addToggle("Скругление элементов","Мягкие углы у карточек и кнопок",function() return state.rounded end,function(v)
        state.rounded=v
        for _,o in ipairs(gui:GetDescendants()) do if o:IsA("UICorner") then o.CornerRadius=UDim.new(0,v and 12 or 3) end end
    end)
    addToggle("Компактная панель","Уменьшает ширину боковой панели",function() return state.compact end,function(v)
        state.compact=v
        sidebar.Size=UDim2.new(0,v and 138 or 166,1,-92)
        content.Position=UDim2.fromOffset(v and 164 or 192,78)
        content.Size=UDim2.new(1,v and -178 or -206,1,-92)
    end)
    addToggle("Плавные анимации","Включает или отключает анимации меню",function() return state.animations end,function(v) state.animations=v end)

    local geometry = card(104)
    textLabel(geometry,"Размер и прозрачность окна",UDim2.fromOffset(16,8),UDim2.new(1,-30,0,22),12,C.text,true)
    textLabel(geometry,"Масштаб и прозрачность главного меню",UDim2.fromOffset(16,32),UDim2.new(1,-30,0,18),9,C.muted)
    local geometryInfo = textLabel(geometry,
        string.format("Масштаб: %d%%  •  Прозрачность: %d%%", math.floor(state.scale*100), math.floor(state.transparency*100)),
        UDim2.fromOffset(16, 32), UDim2.new(1, -30, 0, 18), 9, C.muted, false)
    actionButton(geometry,"−",120,56,32,function()
        state.scale=math.clamp(state.scale-0.05,0.75,1.2)
        geometryInfo.Text=string.format("Масштаб: %d%%  •  Прозрачность: %d%%", math.floor(state.scale*100), math.floor(state.transparency*100))
        setWindowSize()
    end,true)
    actionButton(geometry,"+",16,56,32,function()
        state.scale=math.clamp(state.scale+0.05,0.75,1.2)
        geometryInfo.Text=string.format("Масштаб: %d%%  •  Прозрачность: %d%%", math.floor(state.scale*100), math.floor(state.transparency*100))
        setWindowSize()
    end,true)
    actionButton(geometry,"ПРОЗРАЧНОСТЬ −",350,56,112,function()
        state.transparency=math.clamp(state.transparency-0.05,0,0.45)
        window.BackgroundTransparency=state.transparency
        geometryInfo.Text=string.format("Масштаб: %d%%  •  Прозрачность: %d%%", math.floor(state.scale*100), math.floor(state.transparency*100))
    end,true)
    actionButton(geometry,"ПРОЗРАЧНОСТЬ +",225,56,112,function()
        state.transparency=math.clamp(state.transparency+0.05,0,0.45)
        window.BackgroundTransparency=state.transparency
        geometryInfo.Text=string.format("Масштаб: %d%%  •  Прозрачность: %d%%", math.floor(state.scale*100), math.floor(state.transparency*100))
    end,true)

end

local function showPage(name)
    activePage = name
    pageTitle.Text = name
    pageDesc.Text = name == "Тест" and "Проверка элементов интерфейса"
        or name == "Визуалы" and "Внешний вид и эффекты оформления"
        or "Темы, цвета и общие параметры"
    applyTheme()
    scroll.CanvasPosition = Vector2.new(0, 0)
    if name == "Тест" then buildTest()
    elseif name == "Визуалы" then buildVisuals()
    else buildSettings() end
end
for name, b in pairs(tabButtons) do
    b.Name = name
    b.Activated:Connect(function() showPage(name) end)
end

local function openMenu()
    if transitioning or opened then return end
    transitioning = true
    opened = true
    unlockCursor()
    window.Visible = true
    shadow.Visible = true
    local targetSize = maximized and UDim2.new(1,-28,1,-28) or UDim2.fromOffset(baseSize.X, baseSize.Y)
    local targetPos = maximized and UDim2.fromOffset(14,14) or UDim2.new(0.5,-baseSize.X/2,0.5,-baseSize.Y/2)
    windowScale.Scale = maximized and 1 or getDisplayScale()
    window.Size = UDim2.fromOffset(28,28)
    window.Position = targetPos
    window.BackgroundTransparency = 1
    tween(window, {Size = targetSize, Position = targetPos, BackgroundTransparency = state.transparency}, 0.22)
    tween(shadow, {BackgroundTransparency = 0.72}, 0.22)
    task.delay(state.animations and 0.24 or 0, function() transitioning = false end)
end

local draggingLauncher = false
local launcherMoved = false
local launcherStart, launcherPos
launcher.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingLauncher = true
        launcherMoved = false
        launcherStart = input.Position
        launcherPos = launcher.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingLauncher = false end
        end)
    end
end)
connectExternal(UserInputService.InputChanged, function(input)
    if draggingLauncher and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - launcherStart
        if math.abs(delta.X) + math.abs(delta.Y) > 5 then launcherMoved = true end
        launcher.Position = UDim2.new(launcherPos.X.Scale, launcherPos.X.Offset + delta.X, launcherPos.Y.Scale, launcherPos.Y.Offset + delta.Y)
    end
end)
launcher.Activated:Connect(function()
    if launcherMoved then launcherMoved = false; return end
    if opened then closeMenu() else openMenu() end
end)

local draggingWindow = false
local dragStart, windowStart
top.InputBegan:Connect(function(input)
    if input.Position.X >= top.AbsolutePosition.X + top.AbsoluteSize.X - 170 then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = true
        dragStart = input.Position
        windowStart = window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingWindow = false end
        end)
    end
end)
connectExternal(UserInputService.InputChanged, function(input)
    if draggingWindow and not maximized and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        window.Position = UDim2.new(windowStart.X.Scale, windowStart.X.Offset + d.X, windowStart.Y.Scale, windowStart.Y.Offset + d.Y)
        shadow.Position = UDim2.new(window.Position.X.Scale, window.Position.X.Offset - 12, window.Position.Y.Scale, window.Position.Y.Offset - 12)
    end
end)

local scrollTween
scroll.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local maxY = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y)
        local target = math.clamp(scroll.CanvasPosition.Y - input.Position.Z * 72, 0, maxY)
        if scrollTween then scrollTween:Cancel() end
        if state.animations then
            scrollTween = TweenService:Create(scroll, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(0, target)})
            scrollTween:Play()
        else
            scroll.CanvasPosition = Vector2.new(0, target)
        end
    end
end)

connectExternal(UserInputService.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Insert then
        if opened then closeMenu() else openMenu() end
    end
end)
local cleaned = false
local function cleanup()
    if cleaned then return end
    cleaned = true

    restoreCursor()

    for _, connection in ipairs(externalConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(externalConnections)

    for target in pairs(playerVisuals) do
        clearPlayerVisual(target)
    end
    clearOwnEffects()

    pcall(function()
        if sharedEnv.__FREE_MENU_CLEANUP == cleanup then
            sharedEnv.__FREE_MENU_CLEANUP = nil
        end
    end)
end

pcall(function()
    sharedEnv.__FREE_MENU_CLEANUP = cleanup
end)

gui.Destroying:Connect(cleanup)

showPage("Тест")
applyTheme()
