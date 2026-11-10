-- FREE MENU v1.0 | clean UI-only build
-- Sections: Test, Visuals, Settings. No gameplay or vehicle functions.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local parent
pcall(function() if gethui then parent = gethui() end end)
if not parent then pcall(function() parent = CoreGui end) end
if not parent then parent = player:WaitForChild("PlayerGui") end

for _, container in ipairs({parent, CoreGui, player:FindFirstChildOfClass("PlayerGui")}) do
    if container then
        pcall(function()
            local old = container:FindFirstChild("FreeMenuUI")
            if old then old:Destroy() end
        end)
    end
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
    customText = Color3.fromRGB(242, 244, 250)
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
    b.MouseButton1Click:Connect(callback)
    b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = C.hover}, 0.1) end)
    b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = C.card}, 0.1) end)
    return b
end

local opened = false
local maximized = false
local baseSize = Vector2.new(760, 510)
local function setWindowSize()
    if maximized then return end
    local w, h = baseSize.X * state.scale, baseSize.Y * state.scale
    window.Size = UDim2.fromOffset(w, h)
    window.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
    shadow.Size = UDim2.fromOffset(w + 24, h + 24)
    shadow.Position = UDim2.new(0.5, -(w + 24) / 2, 0.5, -(h + 24) / 2)
end

local function closeMenu()
    opened = false
    tween(window, {Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1}, 0.16)
    tween(shadow, {BackgroundTransparency = 1}, 0.16)
    task.wait(state.animations and 0.17 or 0)
    window.Visible = false
    shadow.Visible = false
    window.BackgroundTransparency = state.transparency
    setWindowSize()
end

topButton("□", -126, function()
    maximized = not maximized
    if maximized then
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
    Text = "FREE BUILD  •  1.0",
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
    b.MouseButton1Click:Connect(callback)
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
            muted = state.customText:Lerp(C and C.bg or Color3.new(0,0,0), 0.42)
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
            obj.TextColor3 = Color3.fromRGB(15,18,25)
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
        b.Text = getter() and "ВКЛЮЧЕНО" or "ВЫКЛЮЧЕНО"
        b.BackgroundColor3 = getter() and state.accent or C.hover
        b.TextColor3 = getter() and Color3.fromRGB(15,18,25) or C.text
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

local function buildVisuals()
    clearPage()
    local f = card(82)
    textLabel(f, "Акцентный цвет", UDim2.fromOffset(16, 10), UDim2.new(1, -160, 0, 22), 12, C.text, true)
    textLabel(f, "Цвет выделения кнопок и активных вкладок", UDim2.fromOffset(16, 37), UDim2.new(1, -160, 0, 20), 9, C.muted)
    local choices = {
        {"Синий", Color3.fromRGB(110,145,255)}, {"Фиолетовый", Color3.fromRGB(174,125,255)},
        {"Бирюзовый", Color3.fromRGB(65,205,190)}, {"Зелёный", Color3.fromRGB(100,205,135)},
        {"Оранжевый", Color3.fromRGB(255,160,85)}, {"Красный", Color3.fromRGB(240,95,110)},
        {"Розовый", Color3.fromRGB(245,125,185)}
    }
    local row = make("Frame", {Position = UDim2.fromOffset(16, 63), Size = UDim2.new(1, -32, 0, 28), BackgroundTransparency = 1, ZIndex = 7}, f)
    local layout = make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, row)
    for i, item in ipairs(choices) do
        local dot = make("TextButton", {Size = UDim2.fromOffset(25,25), BackgroundColor3 = item[2], Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 8}, row)
        round(dot, 13)
        stroke(dot, C.line)
        dot.MouseButton1Click:Connect(function()
            state.accent = item[2]
            applyTheme()
            notify("Цвет применён", item[1])
        end)
    end
    f.Size = UDim2.new(1, -5, 0, 102)

    addToggle("Скругление элементов", "Мягкие углы у карточек и кнопок", function() return state.rounded end, function(v) state.rounded = v; applyTheme() end)
    addToggle("Компактная боковая панель", "Уменьшает ширину навигации", function() return state.compact end, function(v)
        state.compact = v
        sidebar.Size = UDim2.new(0, v and 138 or 166, 1, -92)
        content.Position = UDim2.fromOffset(v and 164 or 192, 78)
        content.Size = UDim2.new(1, v and -178 or -206, 1, -92)
    end)
    addToggle("Плавные анимации", "Включает или отключает переходы", function() return state.animations end, function(v) state.animations = v end)

    local sizeCard = card(82)
    textLabel(sizeCard, "Масштаб интерфейса", UDim2.fromOffset(16, 9), UDim2.new(1, -170, 0, 22), 12, C.text, true)
    textLabel(sizeCard, "Измени общий размер окна", UDim2.fromOffset(16, 35), UDim2.new(1, -170, 0, 20), 9, C.muted)
    local value = textLabel(sizeCard, string.format("%d%%", math.floor(state.scale * 100)), UDim2.new(1, -150, 0, 28), UDim2.fromOffset(58, 24), 11, state.accent, true)
    actionButton(sizeCard, "−", 82, 24, 34, function()
        state.scale = math.clamp(state.scale - 0.05, 0.75, 1.2)
        value.Text = string.format("%d%%", math.floor(state.scale * 100))
        setWindowSize()
    end, true)
    actionButton(sizeCard, "+", 16, 24, 34, function()
        state.scale = math.clamp(state.scale + 0.05, 0.75, 1.2)
        value.Text = string.format("%d%%", math.floor(state.scale * 100))
        setWindowSize()
    end, true)
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
        b.MouseButton1Click:Connect(function()
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
    b.MouseButton1Click:Connect(function() showPage(name) end)
end

local function openMenu()
    if opened then return end
    opened = true
    window.Visible = true
    shadow.Visible = true
    local targetSize = maximized and UDim2.new(1,-28,1,-28) or UDim2.fromOffset(baseSize.X*state.scale, baseSize.Y*state.scale)
    local targetPos = maximized and UDim2.fromOffset(14,14) or UDim2.new(0.5,-baseSize.X*state.scale/2,0.5,-baseSize.Y*state.scale/2)
    window.Size = UDim2.fromOffset(28,28)
    window.Position = UDim2.new(launcher.Position.X.Scale, launcher.Position.X.Offset, launcher.Position.Y.Scale, launcher.Position.Y.Offset)
    window.BackgroundTransparency = 1
    tween(window, {Size = targetSize, Position = targetPos, BackgroundTransparency = state.transparency}, 0.22)
    tween(shadow, {BackgroundTransparency = 0.72}, 0.22)
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
UserInputService.InputChanged:Connect(function(input)
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = true
        dragStart = input.Position
        windowStart = window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then draggingWindow = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
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

showPage("Тест")
applyTheme()
