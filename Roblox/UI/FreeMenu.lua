--[[
    FREE MENU v0.2
    General-purpose UI template for Roblox.
    One floating launcher, two sections: Test and Settings.
    No vehicle-specific features.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local parent
pcall(function() if gethui then parent = gethui() end end)
if not parent then pcall(function() parent = CoreGui end) end
if not parent then parent = player:WaitForChild("PlayerGui") end

pcall(function()
    local old = parent:FindFirstChild("FreeMenuUI")
    if old then old:Destroy() end
end)

local state = {
    accent = Color3.fromRGB(91, 174, 255),
    transparency = 0.04,
    scale = 1,
    animations = true,
    showStatus = true,
    compact = false
}

local C = {
    bg = Color3.fromRGB(14, 16, 23),
    panel = Color3.fromRGB(21, 24, 34),
    panel2 = Color3.fromRGB(29, 33, 46),
    line = Color3.fromRGB(54, 63, 83),
    text = Color3.fromRGB(239, 243, 255),
    muted = Color3.fromRGB(143, 153, 175),
    red = Color3.fromRGB(255, 95, 112),
    green = Color3.fromRGB(91, 220, 160)
}

local gui = Instance.new("ScreenGui")
gui.Name = "FreeMenuUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local function make(class, props, p)
    local obj = Instance.new(class)
    for k,v in pairs(props) do obj[k] = v end
    obj.Parent = p
    return obj
end
local function corner(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, obj)
end
local function outline(obj, color)
    make("UIStroke", {Color = color or C.line, Transparency = 0.2, Thickness = 1}, obj)
end
local function tw(obj, duration, props, style)
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end
local function duration()
    return state.animations and 0.24 or 0
end

local launcher = make("TextButton", {
    Name = "FreeLauncher",
    Size = UDim2.fromOffset(58, 58),
    Position = UDim2.new(0, 24, 0.5, -29),
    BackgroundColor3 = C.panel,
    BackgroundTransparency = 0,
    Text = "FREE",
    TextColor3 = state.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    AutoButtonColor = false,
    ZIndex = 20
}, gui)
corner(launcher, 19)
outline(launcher, state.accent)

local shadow = make("Frame", {
    Size = UDim2.fromOffset(610, 430),
    Position = UDim2.new(0.5, -305, 0.5, -215),
    BackgroundColor3 = Color3.new(0,0,0),
    BackgroundTransparency = 0.58,
    Visible = false,
    ZIndex = 1
}, gui)
corner(shadow, 22)

local window = make("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(590, 410),
    Position = UDim2.new(0.5, -295, 0.5, -205),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = state.transparency,
    Visible = false,
    ClipsDescendants = true,
    ZIndex = 2
}, gui)
corner(window, 20)
outline(window)

local top = make("Frame", {
    Size = UDim2.new(1,0,0,62),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 3
}, window)
corner(top, 20)
make("Frame", {Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,1,-18), BackgroundColor3 = C.panel, BorderSizePixel = 0, ZIndex = 3}, top)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20,10),
    Size = UDim2.fromOffset(220,25),
    Font = Enum.Font.GothamBold,
    Text = "FREE MENU",
    TextColor3 = C.text,
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, top)
make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(21,35),
    Size = UDim2.fromOffset(230,15),
    Font = Enum.Font.Gotham,
    Text = "GENERAL INTERFACE",
    TextColor3 = C.muted,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, top)

local opened = false
local maximized = false
local normalSize = UDim2.fromOffset(590,410)
local normalPos = UDim2.new(0.5,-295,0.5,-205)

local function topButton(text, x, color, callback)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(31,31),
        Position = UDim2.new(1,x,0,15),
        BackgroundColor3 = C.panel2,
        Text = text,
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        AutoButtonColor = false,
        ZIndex = 5
    }, top)
    corner(b,9)
    b.MouseButton1Click:Connect(callback)
    b.MouseEnter:Connect(function() tw(b,0.12,{BackgroundColor3=C.line}) end)
    b.MouseLeave:Connect(function() tw(b,0.12,{BackgroundColor3=C.panel2}) end)
end

local function hideWindow()
    opened = false
    if not window.Visible then return end
    tw(window,duration(),{Size=UDim2.fromOffset(24,24),BackgroundTransparency=1})
    tw(shadow,duration(),{BackgroundTransparency=1})
    task.wait(duration())
    window.Visible = false
    shadow.Visible = false
    window.Size = normalSize
    window.Position = normalPos
    window.BackgroundTransparency = state.transparency
    shadow.Size = UDim2.fromOffset(610,430)
    shadow.Position = UDim2.new(0.5,-305,0.5,-215)
    shadow.BackgroundTransparency = 0.58
end

topButton("□",-116,C.text,function()
    maximized = not maximized
    if maximized then
        tw(window,duration(),{Size=UDim2.new(1,-28,1,-28),Position=UDim2.fromOffset(14,14)})
        tw(shadow,duration(),{Size=UDim2.new(1,-20,1,-20),Position=UDim2.fromOffset(10,10)})
    else
        tw(window,duration(),{Size=normalSize,Position=normalPos})
        tw(shadow,duration(),{Size=UDim2.fromOffset(610,430),Position=UDim2.new(0.5,-305,0.5,-215)})
    end
end)
topButton("—",-76,C.text,function() hideWindow() end)
topButton("×",-36,C.red,function() gui:Destroy() end)

local sidebar = make("Frame", {
    Position=UDim2.fromOffset(14,74),
    Size=UDim2.new(0,132,1,-88),
    BackgroundColor3=C.panel,
    BorderSizePixel=0,
    ZIndex=3
},window)
corner(sidebar,14)

local content = make("Frame", {
    Position=UDim2.fromOffset(158,74),
    Size=UDim2.new(1,-172,1,-88),
    BackgroundColor3=C.panel,
    BorderSizePixel=0,
    ZIndex=3
},window)
corner(content,14)

local pages = {}
local activePage = "Тест"
local tabButtons = {}

local function makeTab(label, y)
    local b = make("TextButton", {
        Size=UDim2.new(1,-14,0,40),
        Position=UDim2.fromOffset(7,y),
        BackgroundColor3=C.panel,
        Text=label,
        TextColor3=C.muted,
        Font=Enum.Font.GothamSemibold,
        TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
        AutoButtonColor=false,
        ZIndex=4
    },sidebar)
    make("UIPadding",{PaddingLeft=UDim.new(0,13)},b)
    corner(b,9)
    tabButtons[label]=b
    return b
end
makeTab("Тест",9)
makeTab("Настройки",56)

local statusLabel = make("TextLabel", {
    BackgroundTransparency=1,
    Position=UDim2.new(0,12,1,-30),
    Size=UDim2.new(1,-24,0,18),
    Font=Enum.Font.Gotham,
    Text="FREE BUILD  •  0.2",
    TextColor3=C.muted,
    TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=4
},sidebar)

local pageTitle = make("TextLabel", {
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(18,13),
    Size=UDim2.new(1,-36,0,25),
    Font=Enum.Font.GothamBold,
    Text="Тест",
    TextColor3=C.text,
    TextSize=18,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=4
},content)

local pageHint = make("TextLabel", {
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(19,40),
    Size=UDim2.new(1,-38,0,18),
    Font=Enum.Font.Gotham,
    Text="Проверка элементов интерфейса",
    TextColor3=C.muted,
    TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=4
},content)

local scroll = make("ScrollingFrame", {
    Name="PageScroll",
    Position=UDim2.fromOffset(14,68),
    Size=UDim2.new(1,-28,1,-80),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ScrollBarThickness=3,
    ScrollBarImageColor3=state.accent,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ScrollingDirection=Enum.ScrollingDirection.Y,
    ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
    ZIndex=4
},content)
local scrollLayout = make("UIListLayout", {
    Padding=UDim.new(0,9),
    SortOrder=Enum.SortOrder.LayoutOrder
},scroll)
make("UIPadding",{PaddingBottom=UDim.new(0,8)},scroll)

local scrollTween
scroll.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local maxY = math.max(0,scroll.AbsoluteCanvasSize.Y-scroll.AbsoluteSize.Y)
        local target = math.clamp(scroll.CanvasPosition.Y-input.Position.Z*68,0,maxY)
        if scrollTween then scrollTween:Cancel() end
        scrollTween = TweenService:Create(scroll,TweenInfo.new(0.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CanvasPosition=Vector2.new(0,target)})
        scrollTween:Play()
    end
end)

local function refreshAccent()
    launcher.TextColor3=state.accent
    local s=launcher:FindFirstChildOfClass("UIStroke")
    if s then s.Color=state.accent end
    local ws=window:FindFirstChildOfClass("UIStroke")
    if ws then ws.Color=state.accent end
    scroll.ScrollBarImageColor3=state.accent
    for name,b in pairs(tabButtons) do
        b.BackgroundColor3=(name==activePage) and C.panel2 or C.panel
        b.TextColor3=(name==activePage) and state.accent or C.muted
    end
end

local function clearScroll()
    for _,v in ipairs(scroll:GetChildren()) do
        if v:IsA("GuiObject") and v~=scrollLayout then v:Destroy() end
    end
end

local function card(height)
    local f=make("Frame",{
        Size=UDim2.new(1,-4,0,height or 68),
        BackgroundColor3=C.panel2,
        BorderSizePixel=0,
        LayoutOrder=#scroll:GetChildren(),
        ZIndex=5
    },scroll)
    corner(f,11)
    return f
end

local function label(parentObj,text,y,size,color)
    return make("TextLabel",{
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(13,y),
        Size=UDim2.new(1,-26,0,20),
        Font=Enum.Font.GothamSemibold,
        Text=text,
        TextColor3=color or C.text,
        TextSize=size or 12,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=6
    },parentObj)
end

local function button(parentObj,text,x,y,w,callback)
    local b=make("TextButton",{
        Size=UDim2.fromOffset(w or 120,30),
        Position=UDim2.new(1,-(x or 135),0,y or 18),
        BackgroundColor3=state.accent,
        Text=text,
        TextColor3=Color3.fromRGB(12,17,25),
        Font=Enum.Font.GothamBold,
        TextSize=10,
        AutoButtonColor=false,
        ZIndex=7
    },parentObj)
    corner(b,8)
    b.MouseButton1Click:Connect(callback)
    b.MouseEnter:Connect(function() tw(b,0.1,{BackgroundColor3=Color3.fromRGB(130,200,255)}) end)
    b.MouseLeave:Connect(function() tw(b,0.1,{BackgroundColor3=state.accent}) end)
    return b
end

local function notify(title,text)
    local n=make("Frame",{
        Size=UDim2.fromOffset(270,72),
        Position=UDim2.new(1,290,1,-96),
        BackgroundColor3=C.panel,
        ZIndex=30
    },gui)
    corner(n,12)
    outline(n,state.accent)
    label(n,title,9,12)
    local desc=label(n,text,34,10,C.muted)
    desc.Size=UDim2.new(1,-24,0,28)
    tw(n,0.3,{Position=UDim2.new(1,-290,1,-96)})
    task.delay(2.5,function()
        if n.Parent then
            tw(n,0.25,{Position=UDim2.new(1,290,1,-96)})
            task.wait(0.26)
            n:Destroy()
        end
    end)
end

local function addToggle(title,description,getter,setter)
    local f=card(66)
    label(f,title,8,12)
    label(f,description,33,9,C.muted)
    local b=button(f,getter() and "ВКЛ" or "ВЫКЛ",12,18,62,function()
        setter(not getter())
        b.Text=getter() and "ВКЛ" or "ВЫКЛ"
        b.BackgroundColor3=getter() and state.accent or C.line
    end)
    b.BackgroundColor3=getter() and state.accent or C.line
    b.TextColor3=getter() and Color3.fromRGB(12,17,25) or C.text
end

local function buildTest()
    clearScroll()
    local f=card(76)
    label(f,"Проверка уведомлений",10,12)
    label(f,"Нажми кнопку, чтобы проверить всплывающее сообщение",35,9,C.muted)
    button(f,"ПРОВЕРИТЬ",12,23,105,function() notify("FREE MENU","Уведомление работает!") end)

    local f2=card(76)
    label(f2,"Проверка анимации",10,12)
    label(f2,"Тест плавного появления интерфейсного блока",35,9,C.muted)
    button(f2,"ЗАПУСТИТЬ",12,23,105,function()
        local p=make("Frame",{Size=UDim2.fromOffset(8,5),Position=UDim2.new(0,145,0,34),BackgroundColor3=state.accent,ZIndex=8},f2)
        corner(p,4)
        tw(p,0.45,{Size=UDim2.fromOffset(95,5)})
        task.delay(1,function() if p.Parent then tw(p,0.2,{BackgroundTransparency=1}) task.wait(0.2) p:Destroy() end end)
    end)

    local f3=card(66)
    label(f3,"Прокрутка",10,12)
    label(f3,"Колёсико мыши прокручивает страницу плавно",34,9,C.muted)

    for i=1,5 do
        local extra=card(54)
        label(extra,"Тестовый блок "..i,8,11)
        label(extra,"Дополнительный элемент для проверки скролла",29,9,C.muted)
    end
end

local function buildSettings()
    clearScroll()
    local f=card(86)
    label(f,"Цвет меню",9,12)
    label(f,"Переключай акцентный цвет интерфейса",34,9,C.muted)
    local colors={
        Color3.fromRGB(91,174,255),
        Color3.fromRGB(170,115,255),
        Color3.fromRGB(80,220,170),
        Color3.fromRGB(255,145,90),
        Color3.fromRGB(255,100,135),
        Color3.fromRGB(235,210,95)
    }
    local colorNames={"Синий","Фиолетовый","Мятный","Оранжевый","Розовый","Жёлтый"}
    local index=1
    button(f,"СЛЕДУЮЩИЙ",12,51,110,function()
        index=index%#colors+1
        state.accent=colors[index]
        refreshAccent()
        notify("Цвет изменён",colorNames[index])
    end)

    local f2=card(82)
    label(f2,"Прозрачность окна",9,12)
    label(f2,"Меняет прозрачность фона меню",34,9,C.muted)
    button(f2,"−",12,49,34,function()
        state.transparency=math.clamp(state.transparency-0.05,0,0.45)
        window.BackgroundTransparency=state.transparency
    end)
    label(f2,string.format("%d%%",math.floor((1-state.transparency)*100)),52,10,state.accent).Name="TransparencyValue"
    button(f2,"+",190,49,34,function()
        state.transparency=math.clamp(state.transparency+0.05,0,0.45)
        window.BackgroundTransparency=state.transparency
        for _,obj in ipairs(f2:GetChildren()) do
            if obj:IsA("TextLabel") and obj.Name=="TransparencyValue" then obj.Text=string.format("%d%%",math.floor((1-state.transparency)*100)) end
        end
    end)

    local f3=card(66)
    label(f3,"Размер интерфейса",8,12)
    label(f3,"Изменяет размер главного окна",33,9,C.muted)
    button(f3,"−",12,17,34,function()
        state.scale=math.clamp(state.scale-0.05,0.8,1.2)
        if not maximized then
            local w,h=590*state.scale,410*state.scale
            window.Size=UDim2.fromOffset(w,h)
            window.Position=UDim2.new(0.5,-w/2,0.5,-h/2)
        end
    end)
    button(f3,"+",190,17,34,function()
        state.scale=math.clamp(state.scale+0.05,0.8,1.2)
        if not maximized then
            local w,h=590*state.scale,410*state.scale
            window.Size=UDim2.fromOffset(w,h)
            window.Position=UDim2.new(0.5,-w/2,0.5,-h/2)
        end
    end)

    local f4=card(66)
    label(f4,"Общие параметры",8,12)
    label(f4,"Настройки поведения интерфейса",33,9,C.muted)
    addToggle("Плавные анимации","Включает и отключает переходы",function() return state.animations end,function(v) state.animations=v end)

    local f5=card(66)
    label(f5,"Статус в боковой панели",8,12)
    label(f5,"Показывать подпись версии",33,9,C.muted)
    addToggle("Показывать статус","Вкл/выкл нижнюю подпись",function() return state.showStatus end,function(v)
        state.showStatus=v
        statusLabel.Visible=v
    end)

    local f6=card(66)
    label(f6,"Компактный вид","",8,12)
    label(f6,"Уменьшает боковую панель",33,9,C.muted)
    addToggle("Компактная панель","Сжимает боковое меню",function() return state.compact end,function(v)
        state.compact=v
        sidebar.Size=UDim2.new(0,v and 105 or 132,1,-88)
        content.Position=UDim2.fromOffset(v and 131 or 158,74)
        content.Size=UDim2.new(1,v and -145 or -172,1,-88)
    end)

    local f7=card(66)
    label(f7,"Сброс настроек",8,12)
    label(f7,"Возвращает исходный вид меню",33,9,C.muted)
    button(f7,"СБРОСИТЬ",12,17,100,function()
        state.accent=colors[1]
        state.transparency=0.04
        state.scale=1
        state.animations=true
        state.showStatus=true
        state.compact=false
        window.BackgroundTransparency=state.transparency
        statusLabel.Visible=true
        sidebar.Size=UDim2.new(0,132,1,-88)
        content.Position=UDim2.fromOffset(158,74)
        content.Size=UDim2.new(1,-172,1,-88)
        if not maximized then window.Size=normalSize window.Position=normalPos end
        refreshAccent()
        notify("Настройки","Исходные параметры восстановлены")
        buildSettings()
    end)
end

local function showPage(name)
    activePage=name
    pageTitle.Text=name
    pageHint.Text=name=="Тест" and "Проверка элементов интерфейса" or "Внешний вид и общие функции меню"
    refreshAccent()
    scroll.CanvasPosition=Vector2.new(0,0)
    if name=="Тест" then buildTest() else buildSettings() end
end
tabButtons["Тест"].MouseButton1Click:Connect(function() showPage("Тест") end)
tabButtons["Настройки"].MouseButton1Click:Connect(function() showPage("Настройки") end)

-- Smoothly drag the launcher itself with mouse or touch.
local draggingIcon=false
local dragStart,iconStart
local moved=false
launcher.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        draggingIcon=true
        moved=false
        dragStart=input.Position
        iconStart=launcher.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then draggingIcon=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingIcon and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-dragStart
        if math.abs(d.X)+math.abs(d.Y)>5 then moved=true end
        local target=UDim2.new(iconStart.X.Scale,iconStart.X.Offset+d.X,iconStart.Y.Scale,iconStart.Y.Offset+d.Y)
        tw(launcher,0.08,{Position=target,BackgroundColor3=C.panel})
    end
end)

local function toggleMenu()
    if moved then moved=false return end
    if opened then hideWindow() return end
    opened=true
    window.Visible=true
    shadow.Visible=true
    window.Size=UDim2.fromOffset(28,28)
    window.Position=UDim2.new(launcher.Position.X.Scale,launcher.Position.X.Offset,launcher.Position.Y.Scale,launcher.Position.Y.Offset)
    window.BackgroundTransparency=1
    shadow.BackgroundTransparency=1
    tw(window,duration(),{Size=normalSize,Position=normalPos,BackgroundTransparency=state.transparency})
    tw(shadow,duration(),{BackgroundTransparency=0.58})
end
launcher.Activated:Connect(toggleMenu)

-- Drag main window by its title bar.
local draggingWindow=false
local windowDragStart,windowStart
top.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        draggingWindow=true
        windowDragStart=input.Position
        windowStart=window.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then draggingWindow=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingWindow and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-windowDragStart
        local p=UDim2.new(windowStart.X.Scale,windowStart.X.Offset+d.X,windowStart.Y.Scale,windowStart.Y.Offset+d.Y)
        tw(window,0.08,{Position=p})
        tw(shadow,0.08,{Position=p-UDim2.fromOffset(10,10)})
    end
end)

showPage("Тест")
