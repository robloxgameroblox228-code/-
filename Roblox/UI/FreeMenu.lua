--[[
  FREE MENU | Roblox UI
  LocalScript / Executor
  Toggle icon -> open/close with smooth animation
  Tabs are demo placeholders until features are added.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local old = nil
local parent
pcall(function()
    if gethui then parent = gethui() end
end)
if not parent then
    pcall(function() parent = CoreGui end)
end
if not parent then
    parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

pcall(function()
    old = parent:FindFirstChild("FreeMenuUI")
    if old then old:Destroy() end
end)

local C = {
    bg = Color3.fromRGB(13, 15, 22),
    panel = Color3.fromRGB(20, 23, 33),
    panel2 = Color3.fromRGB(27, 31, 44),
    line = Color3.fromRGB(52, 61, 82),
    text = Color3.fromRGB(239, 243, 255),
    muted = Color3.fromRGB(139, 150, 174),
    accent = Color3.fromRGB(80, 190, 255),
    purple = Color3.fromRGB(164, 104, 255),
    green = Color3.fromRGB(91, 220, 160),
    red = Color3.fromRGB(255, 91, 111)
}

local gui = Instance.new("ScreenGui")
gui.Name = "FreeMenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local function make(class, props, parentObj)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parentObj
    return obj
end

local function corner(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, obj)
end

local function stroke(obj, color, transparency)
    make("UIStroke", {
        Color = color or C.line,
        Transparency = transparency or 0,
        Thickness = 1
    }, obj)
end

local function tween(obj, duration, props, style)
    local t = TweenService:Create(obj, TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- Floating launcher icon. Three bars are drawn locally, so no external image is needed.
local launcher = make("TextButton", {
    Name = "OpenMenu",
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.new(0, 24, 0.5, -27),
    BackgroundColor3 = C.panel,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 20
}, gui)
corner(launcher, 18)
stroke(launcher, C.accent, 0.2)

for i = 1, 3 do
    make("Frame", {
        Size = UDim2.fromOffset(i == 2 and 19 or 24, 2),
        Position = UDim2.new(0.5, -(i == 2 and 9.5 or 12), 0.5, (i - 2) * 7),
        BackgroundColor3 = i == 2 and C.purple or C.accent,
        BorderSizePixel = 0,
        ZIndex = 21
    }, launcher)
end

local shadow = make("Frame", {
    Name = "Shadow",
    Size = UDim2.fromOffset(590, 410),
    Position = UDim2.new(0.5, -295, 0.5, -205),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.55,
    Visible = false,
    ZIndex = 1
}, gui)
corner(shadow, 22)

local window = make("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(570, 390),
    Position = UDim2.new(0.5, -285, 0.5, -195),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = 0.04,
    Visible = false,
    ClipsDescendants = true,
    ZIndex = 2
}, gui)
corner(window, 20)
stroke(window, C.line, 0.15)

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 3
}, window)
corner(top, 20)
make("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 1, -20),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 3
}, top)

local brand = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 11),
    Size = UDim2.fromOffset(210, 25),
    Font = Enum.Font.GothamBold,
    Text = "FREE  MENU",
    TextColor3 = C.text,
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, top)

local subtitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(21, 37),
    Size = UDim2.fromOffset(220, 16),
    Font = Enum.Font.Gotham,
    Text = "Universal control panel",
    TextColor3 = C.muted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, top)

local function topButton(symbol, x, color, callback)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, x, 0, 18),
        BackgroundColor3 = C.panel2,
        Text = symbol,
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        AutoButtonColor = false,
        ZIndex = 5
    }, top)
    corner(b, 9)
    b.MouseButton1Click:Connect(callback)
    b.MouseEnter:Connect(function() tween(b, 0.12, {BackgroundColor3 = C.line}) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, {BackgroundColor3 = C.panel2}) end)
    return b
end

local maximized = false
local normalSize = UDim2.fromOffset(570, 390)
local normalPos = UDim2.new(0.5, -285, 0.5, -195)

topButton("□", -112, C.accent, function()
    maximized = not maximized
    if maximized then
        tween(window, 0.28, {Size = UDim2.new(1, -36, 1, -36), Position = UDim2.fromOffset(18, 18)})
        tween(shadow, 0.28, {Size = UDim2.new(1, -30, 1, -30), Position = UDim2.fromOffset(15, 15)})
    else
        tween(window, 0.28, {Size = normalSize, Position = normalPos})
        tween(shadow, 0.28, {Size = UDim2.fromOffset(590, 410), Position = UDim2.new(0.5, -295, 0.5, -205)})
    end
end)

topButton("—", -72, C.text, function()
    tween(window, 0.18, {Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 36, 0.5, -15), BackgroundTransparency = 1})
    tween(shadow, 0.18, {BackgroundTransparency = 1})
    task.wait(0.19)
    window.Visible = false
    shadow.Visible = false
    window.Size = normalSize
    window.Position = normalPos
    window.BackgroundTransparency = 0.04
    shadow.Size = UDim2.fromOffset(590, 410)
    shadow.Position = UDim2.new(0.5, -295, 0.5, -205)
    shadow.BackgroundTransparency = 0.55
end)

topButton("×", -32, C.red, function()
    tween(window, 0.18, {Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1})
    tween(launcher, 0.18, {BackgroundTransparency = 1})
    task.wait(0.2)
    gui:Destroy()
end)

local sidebar = make("Frame", {
    Position = UDim2.fromOffset(14, 78),
    Size = UDim2.new(0, 145, 1, -92),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 3
}, window)
corner(sidebar, 14)

local content = make("Frame", {
    Position = UDim2.fromOffset(171, 78),
    Size = UDim2.new(1, -185, 1, -92),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 3
}, window)
corner(content, 14)

local tabNames = {"Главная", "Машина", "Подвеска", "Визуал", "Настройки", "Информация"}
local tabIcons = {"⌂", "◆", "↕", "◉", "⚙", "i"}
local currentTab = nil
local tabButtons = {}

local pageTitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 16),
    Size = UDim2.new(1, -36, 0, 27),
    Font = Enum.Font.GothamBold,
    Text = "Главная",
    TextColor3 = C.text,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, content)

local pageHint = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(19, 44),
    Size = UDim2.new(1, -38, 0, 18),
    Font = Enum.Font.Gotham,
    Text = "Выбери раздел слева",
    TextColor3 = C.muted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, content)

local pageBody = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(16, 76),
    Size = UDim2.new(1, -32, 1, -90),
    ZIndex = 4
}, content)

local function clearPage()
    for _, child in ipairs(pageBody:GetChildren()) do child:Destroy() end
end

local function addCard(title, description, y)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        Position = UDim2.fromOffset(0, y),
        BackgroundColor3 = C.panel2,
        BorderSizePixel = 0,
        ZIndex = 5
    }, pageBody)
    corner(card, 11)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(13, 9),
        Size = UDim2.new(1, -74, 0, 19),
        Font = Enum.Font.GothamSemibold,
        Text = title,
        TextColor3 = C.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6
    }, card)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(13, 31),
        Size = UDim2.new(1, -26, 0, 17),
        Font = Enum.Font.Gotham,
        Text = description,
        TextColor3 = C.muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6
    }, card)
    local tag = make("TextLabel", {
        Size = UDim2.fromOffset(48, 21),
        Position = UDim2.new(1, -60, 0, 10),
        BackgroundColor3 = Color3.fromRGB(27, 54, 66),
        Text = "FREE",
        TextColor3 = C.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        ZIndex = 6
    }, card)
    corner(tag, 7)
end

local pages = {
    ["Главная"] = {
        hint = "Добро пожаловать в FREE MENU",
        cards = {
            {"Панель загружена", "Интерфейс работает и готов к настройке"},
            {"Быстрый доступ", "Все будущие функции будут появляться здесь"},
            {"Статус", "FREE BUILD  •  DEMO"}
        }
    },
    ["Машина"] = {
        hint = "Управление автомобилем",
        cards = {
            {"Управление", "Здесь появятся настройки управления"},
            {"Скорость", "Тестовый раздел • FREE"},
            {"Настройки руля", "Тестовый раздел • FREE"}
        }
    },
    ["Подвеска"] = {
        hint = "Настройка поведения автомобиля",
        cards = {
            {"Высота подвески", "Настройка появится позже"},
            {"Жёсткость", "Настройка появится позже"},
            {"Гидравлика", "Режимы и управление • FREE"}
        }
    },
    ["Визуал"] = {
        hint = "Внешний вид интерфейса и игры",
        cards = {
            {"Цветовая тема", "Настройка появится позже"},
            {"Эффекты", "Тестовый раздел • FREE"},
            {"Интерфейс", "Настройка появится позже"}
        }
    },
    ["Настройки"] = {
        hint = "Параметры меню",
        cards = {
            {"Анимации", "Плавное открытие и закрытие включено"},
            {"Положение", "Меню можно перетаскивать за верхнюю панель"},
            {"Свернуть", "Кнопка сверху оставляет только иконку"}
        }
    },
    ["Информация"] = {
        hint = "Информация о сборке",
        cards = {
            {"Название", "FREE MENU"},
            {"Версия", "0.1 • Interface preview"},
            {"Статус", "Демо-интерфейс, функции добавим отдельно"}
        }
    }
}

local function showPage(name)
    currentTab = name
    local data = pages[name]
    pageTitle.Text = name
    pageHint.Text = data.hint
    clearPage()
    for i, card in ipairs(data.cards) do
        addCard(card[1], card[2], (i - 1) * 72)
    end
    for tabName, button in pairs(tabButtons) do
        local selected = tabName == name
        tween(button, 0.14, {
            BackgroundColor3 = selected and Color3.fromRGB(35, 62, 83) or C.panel,
            TextColor3 = selected and C.accent or C.muted
        })
    end
end

for i, name in ipairs(tabNames) do
    local b = make("TextButton", {
        Size = UDim2.new(1, -14, 0, 39),
        Position = UDim2.fromOffset(7, 9 + (i - 1) * 45),
        BackgroundColor3 = C.panel,
        Text = tabIcons[i] .. "   " .. name,
        TextColor3 = C.muted,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex = 4
    }, sidebar)
    corner(b, 9)
    make("UIPadding", {PaddingLeft = UDim.new(0, 11)}, b)
    b.MouseButton1Click:Connect(function() showPage(name) end)
    tabButtons[name] = b
end

local foot = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 1, -29),
    Size = UDim2.new(1, -24, 0, 17),
    Font = Enum.Font.Gotham,
    Text = "FREE  •  v0.1",
    TextColor3 = C.muted,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, sidebar)

-- Drag the window by its header.
local dragging, dragStart, startPos
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        shadow.Position = window.Position - UDim2.fromOffset(10, 10)
    end
end)

local opened = false
local function openMenu()
    if opened then
        opened = false
        tween(window, 0.2, {Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1})
        tween(shadow, 0.2, {BackgroundTransparency = 1})
        task.wait(0.21)
        window.Visible = false
        shadow.Visible = false
        window.Size = normalSize
        window.Position = normalPos
        window.BackgroundTransparency = 0.04
        shadow.Size = UDim2.fromOffset(590, 410)
        shadow.Position = UDim2.new(0.5, -295, 0.5, -205)
        shadow.BackgroundTransparency = 0.55
    else
        opened = true
        window.Visible = true
        shadow.Visible = true
        window.Size = UDim2.fromOffset(30, 30)
        window.Position = UDim2.new(0, 36, 0.5, -15)
        window.BackgroundTransparency = 1
        shadow.BackgroundTransparency = 1
        tween(window, 0.32, {Size = normalSize, Position = normalPos, BackgroundTransparency = 0.04})
        tween(shadow, 0.32, {BackgroundTransparency = 0.55})
    end
end

launcher.MouseButton1Click:Connect(openMenu)
showPage("Главная")
