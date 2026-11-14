-- FREE MENU v3.1 | camera, movement and graphics refactor
-- Sections: Test, Visuals, Movement, Settings. Character movement tools included.

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
    accent = Color3.fromRGB(151, 112, 255),
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
    particleStyle = "Звёзды", playerExpanded = false, ownExpanded = false,
    speedEnabled = false, sprintEnabled = true, jumpEnabled = false,
    walkSpeed = 16, sprintSpeed = 28, jumpPower = 50, jumpHeight = 7.2,
    noclip = false, fly = false, flySpeed = 55,
}

local palettes = {
    Dark = {
        bg = Color3.fromRGB(10, 12, 20),
        panel = Color3.fromRGB(17, 20, 31),
        card = Color3.fromRGB(25, 29, 44),
        hover = Color3.fromRGB(37, 42, 62),
        line = Color3.fromRGB(58, 64, 91),
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
    if not obj then return nil end

    if not state.animations then
        local ok, err = pcall(function()
            for k, v in pairs(props) do obj[k] = v end
        end)
        if not ok then warn("[FREE MENU] Tween assignment failed: " .. tostring(err)) end
        return nil
    end

    local ok, result = pcall(function()
        local animation = TweenService:Create(
            obj,
            TweenInfo.new(time or 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            props
        )
        animation:Play()
        return animation
    end)
    if not ok then
        warn("[FREE MENU] Tween failed: " .. tostring(result))
        return nil
    end
    return result
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
    Size = UDim2.fromOffset(76, 48),
    Position = UDim2.new(0, 22, 0.5, -23),
    BackgroundColor3 = C.panel,
    Text = "✦ FREE",
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
    Size = UDim2.fromOffset(820, 550),
    Position = UDim2.new(0.5, -410, 0.5, -275),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = state.transparency,
    Visible = false,
    ClipsDescendants = true,
    ZIndex = 2
}, gui, "bg")
round(window, 18)

-- Download artwork through Zynova's request API and load it as a local asset.
-- The asset is placed behind translucent panels so it remains visible.
local backgroundImage = make("ImageLabel", {
    Name = "RemoteBackground",
    Position = UDim2.fromScale(0, 0),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = "",
    ImageColor3 = Color3.fromRGB(210, 220, 255),
    ImageTransparency = 0.04,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 2
}, window)
round(backgroundImage, 18)

local sharedArtworkAsset = ""
local homeArtwork
local backgroundUrl = "https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&fm=jpg&q=88&w=1600"
task.spawn(function()
    local ok, err = pcall(function()
        assert(type(writefile) == "function", "writefile is unavailable")
        local imageBytes

        if type(request) == "function" then
            local response = request({
                Url = backgroundUrl,
                Method = "GET",
                Headers = { ["User-Agent"] = "Mozilla/5.0" }
            })
            assert(type(response) == "table", "HTTP request returned an invalid response")
            assert(response.Success ~= false and (not response.StatusCode or response.StatusCode == 200), "HTTP status: " .. tostring(response.StatusCode))
            imageBytes = response.Body
        end

        if type(imageBytes) ~= "string" or #imageBytes < 1000 then
            imageBytes = game:HttpGet(backgroundUrl)
        end
        assert(type(imageBytes) == "string" and #imageBytes > 1000, "Downloaded image is empty or too small")

        local fileName = "FreeMenu_Cyberpunk_Background.jpg"
        writefile(fileName, imageBytes)

        local assetLoader = getcustomasset or getsynasset
        assert(type(assetLoader) == "function", "No custom asset loader is available")
        local asset = assetLoader(fileName)
        assert(type(asset) == "string" and #asset > 0, "Custom asset loader returned an empty asset")
        sharedArtworkAsset = asset
        backgroundImage.Image = asset
        if homeArtwork and homeArtwork.Parent then homeArtwork.Image = asset end
        print("[FREE MENU] Artwork loaded (" .. tostring(#imageBytes) .. " bytes)")
    end)

    if not ok then
        warn("[FREE MENU] Background image failed: " .. tostring(err))
    end
end)

local backgroundTint = make("Frame", {
    Name = "BackgroundTint",
    Position = UDim2.fromScale(0, 0),
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(8, 10, 20),
    BackgroundTransparency = 0.28,
    BorderSizePixel = 0,
    ZIndex = 2
}, window)
round(backgroundTint, 18)

local windowScale = make("UIScale", {Scale = 1}, window)
stroke(window)

local top = make("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = C.panel,
    BackgroundTransparency = 0.24,
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
local oldMouseIcon
local function unlockCursor()
    -- GuiButton.Modal is Roblox's native way to unlock the cursor for menus,
    -- including first-person mode. Do not overwrite MouseBehavior per frame.
    if oldMouseIcon == nil then
        pcall(function() oldMouseIcon = UserInputService.MouseIconEnabled end)
    end
    pcall(function()
        launcher.Modal = true
        UserInputService.MouseIconEnabled = true
    end)
end

local function restoreCursor()
    pcall(function() launcher.Modal = false end)
    if oldMouseIcon ~= nil then
        pcall(function() UserInputService.MouseIconEnabled = oldMouseIcon end)
    end
    oldMouseIcon = nil
end

local baseSize = Vector2.new(820, 550)
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
    BackgroundTransparency = 0.20,
    BorderSizePixel = 0,
    ZIndex = 3
}, window, "panel")
round(sidebar, 14)

local content = make("Frame", {
    Position = UDim2.fromOffset(192, 78),
    Size = UDim2.new(1, -206, 1, -92),
    BackgroundColor3 = C.panel,
    BackgroundTransparency = 0.20,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 3
}, window, "panel")
round(content, 14)

local tabButtons = {}
local activePage = "Главная"
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
createTab("Главная", 12)
createTab("Визуалы", 64)
createTab("Движение", 116)
createTab("Настройки", 168)
createTab("Диагностика", 220)

local status = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 1, -30),
    Size = UDim2.new(1, -28, 0, 16),
    Text = "FREE BUILD  •  3.1",
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
        BackgroundTransparency = 0.16,
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
        Size = UDim2.fromOffset(width or 116, 34),
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
        elseif role == "hover" then
            obj.BackgroundColor3 = C.hover
            if obj:IsA("TextBox") then
                obj.TextColor3 = C.text
                obj.PlaceholderColor3 = C.muted
            elseif obj:IsA("TextButton") then
                obj.TextColor3 = C.text
            end
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

local showPage
local function buildHome()
    clearPage()

    local hero = make("ImageLabel", {
        Name = "HomeArtwork",
        Size = UDim2.new(1, -5, 0, 154),
        BackgroundColor3 = C.card,
        BackgroundTransparency = 0,
        Image = sharedArtworkAsset,
        ImageColor3 = Color3.fromRGB(210, 220, 255),
        ImageTransparency = 0.06,
        ScaleType = Enum.ScaleType.Crop,
        LayoutOrder = 1,
        ZIndex = 5
    }, scroll, "card")
    homeArtwork = hero
    round(hero, 14)
    local shade = make("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(8, 10, 20),
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        ZIndex = 6
    }, hero)
    round(shade, 14)
    textLabel(hero, "FREE MENU", UDim2.fromOffset(20, 24), UDim2.new(1, -40, 0, 34), 24, Color3.new(1,1,1), true).ZIndex = 7
    textLabel(hero, "YOUR GAME. YOUR RULES.", UDim2.fromOffset(22, 62), UDim2.new(1, -44, 0, 20), 10, Color3.fromRGB(220,225,245), true).ZIndex = 7
    textLabel(hero, "Настрой игровой процесс под себя", UDim2.fromOffset(22, 94), UDim2.new(1, -44, 0, 22), 11, Color3.fromRGB(235,238,248), false).ZIndex = 7

    local quick = card(82)
    textLabel(quick, "БЫСТРЫЙ ДОСТУП", UDim2.fromOffset(16, 9), UDim2.new(1, -30, 0, 18), 10, C.muted, true)
    local function quickButton(caption, x, target)
        local b = make("TextButton", {
            Position = UDim2.fromOffset(x, 38),
            Size = UDim2.fromOffset(142, 32),
            BackgroundColor3 = C.hover,
            Text = caption,
            TextColor3 = C.text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 10,
            AutoButtonColor = false,
            ZIndex = 8
        }, quick, "hover")
        round(b, 9)
        b.Activated:Connect(function() showPage(target) end)
    end
    quickButton("ВИЗУАЛЫ", 16, "Визуалы")
    quickButton("ДВИЖЕНИЕ", 170, "Движение")
    quickButton("НАСТРОЙКИ", 324, "Настройки")

    local info = card(72)
    textLabel(info, "Всё под контролем", UDim2.fromOffset(16, 10), UDim2.new(1, -30, 0, 22), 13, C.text, true)
    textLabel(info, "ESP • Chams • Fly • Noclip • Sprint • персональное оформление", UDim2.fromOffset(16, 37), UDim2.new(1, -30, 0, 20), 9, C.muted, false)
end

local visualGuiParent = player:FindFirstChildOfClass("PlayerGui") or parent
local playerVisuals = {}
local playerCharacterConnections = {}
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
        h.Parent = character
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
            bill.Parent = visualGuiParent
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

    playerCharacterConnections[target] = connectExternal(target.CharacterAdded, function(character)
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
    local connection = playerCharacterConnections[target]
    if connection then
        pcall(function() connection:Disconnect() end)
        playerCharacterConnections[target] = nil
    end
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

-- Movement controller: restores original character properties when features are disabled.
local movementOriginal = {}
local noclipOriginal = {}
local noclipDescAddedConnection
local flyVelocity, flyOrientation, flyAttachment
local flyCharacter
local shiftHeld = false

local function getMovementCharacter()
    local character = player.Character
    if not character then return nil, nil, nil end
    return character, character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
end

local function saveHumanoidDefaults(humanoid)
    if not humanoid or movementOriginal[humanoid] then return end
    movementOriginal[humanoid] = {
        WalkSpeed = humanoid.WalkSpeed,
        JumpPower = humanoid.JumpPower,
        JumpHeight = humanoid.JumpHeight,
        UseJumpPower = humanoid.UseJumpPower,
        AutoRotate = humanoid.AutoRotate,
        PlatformStand = humanoid.PlatformStand,
    }
end

local function applyMovementStats()
    local _, humanoid = getMovementCharacter()
    if not humanoid then return end
    saveHumanoidDefaults(humanoid)
    local original = movementOriginal[humanoid]

    local sprinting = state.sprintEnabled and shiftHeld
    if state.speedEnabled or sprinting then
        humanoid.WalkSpeed = sprinting and state.sprintSpeed or state.walkSpeed
    else
        humanoid.WalkSpeed = original.WalkSpeed
    end

    if state.jumpEnabled then
        if humanoid.UseJumpPower then
            humanoid.JumpPower = state.jumpPower
        else
            humanoid.JumpHeight = state.jumpHeight
        end
    else
        humanoid.JumpPower = original.JumpPower
        humanoid.JumpHeight = original.JumpHeight
    end
end

local function restoreNoclip()
    if noclipDescAddedConnection then
        pcall(function() noclipDescAddedConnection:Disconnect() end)
        noclipDescAddedConnection = nil
    end

    for part, original in pairs(noclipOriginal) do
        if part and part.Parent and type(original) == "table" then
            pcall(function()
                -- Restore only when CanCollide still has the value applied here.
                if original.LastApplied ~= nil and part.CanCollide == original.LastApplied then
                    part.CanCollide = original.CanCollide
                end
            end)
        end
    end
    table.clear(noclipOriginal)
end

local function applyNoclipToPart(object)
    if not state.noclip or not object or not object:IsA("BasePart") then return end
    local original = noclipOriginal[object]
    if original == nil then
        original = {CanCollide = object.CanCollide, LastApplied = nil}
        noclipOriginal[object] = original
    elseif original.LastApplied ~= nil and object.CanCollide ~= original.LastApplied then
        -- A game script changed collision while Noclip was active; remember
        -- that newer value so disabling this feature does not overwrite it.
        original.CanCollide = object.CanCollide
    end
    object.CanCollide = false
    original.LastApplied = false
end

local function setNoclip(enabled)
    state.noclip = enabled
    restoreNoclip()
    if not enabled then return end

    local character = player.Character
    if not character then return end

    -- Apply once to existing parts; only process future parts when they appear.
    for _, object in ipairs(character:GetDescendants()) do
        applyNoclipToPart(object)
    end
    noclipDescAddedConnection = character.DescendantAdded:Connect(applyNoclipToPart)
end

local function stopFly()
    if flyVelocity then pcall(function() flyVelocity:Destroy() end); flyVelocity = nil end
    if flyOrientation then pcall(function() flyOrientation:Destroy() end); flyOrientation = nil end
    if flyAttachment then pcall(function() flyAttachment:Destroy() end); flyAttachment = nil end

    local character, humanoid = getMovementCharacter()
    if humanoid and flyCharacter == character then
        local original = movementOriginal[humanoid]
        if original and original.AutoRotate ~= nil then
            pcall(function() humanoid.AutoRotate = original.AutoRotate end)
        end
    end
    flyCharacter = nil
end

local function startFly()
    local character, humanoid, root = getMovementCharacter()
    if not character or not humanoid or not root then
        state.fly = false
        notify("Полёт недоступен", "Персонаж ещё не загрузился")
        return false
    end

    stopFly()
    saveHumanoidDefaults(humanoid)
    local original = movementOriginal[humanoid]
    if original.AutoRotate == nil then original.AutoRotate = humanoid.AutoRotate end
    humanoid.AutoRotate = false
    flyCharacter = character

    local attachment = Instance.new("Attachment")
    attachment.Name = "FreeMenuFlyAttachment"
    attachment.Parent = root

    local velocity = Instance.new("LinearVelocity")
    velocity.Name = "FreeMenuFlyVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    velocity.VectorVelocity = Vector3.zero
    velocity.ForceLimitsEnabled = true
    velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
    velocity.MaxForce = 1000000
    velocity.Parent = root

    local orientation = Instance.new("AlignOrientation")
    orientation.Name = "FreeMenuFlyOrientation"
    orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    orientation.Attachment0 = attachment
    orientation.RigidityEnabled = false
    orientation.Responsiveness = 22
    orientation.MaxTorque = 1000000
    orientation.MaxAngularVelocity = 25
    orientation.CFrame = root.CFrame.Rotation
    orientation.Parent = root

    flyAttachment, flyVelocity, flyOrientation = attachment, velocity, orientation
    return true
end

local function setFly(enabled)
    if enabled then
        state.fly = true
        if not startFly() then state.fly = false end
    else
        state.fly = false
        stopFly()
    end
end

local function restoreMovement()
    state.fly = false
    state.noclip = false
    shiftHeld = false
    stopFly()
    restoreNoclip()

    for humanoid, original in pairs(movementOriginal) do
        if humanoid and humanoid.Parent then
            pcall(function()
                humanoid.WalkSpeed = original.WalkSpeed
                humanoid.JumpPower = original.JumpPower
                humanoid.JumpHeight = original.JumpHeight
                humanoid.UseJumpPower = original.UseJumpPower
                if original.AutoRotate ~= nil then humanoid.AutoRotate = original.AutoRotate end
                if original.PlatformStand ~= nil then humanoid.PlatformStand = original.PlatformStand end
            end)
        end
    end
    table.clear(movementOriginal)
end

connectExternal(UserInputService.InputBegan, function(input, processed)
    if processed or opened or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if not shiftHeld then
            shiftHeld = true
            applyMovementStats()
        end
    end
end)

connectExternal(UserInputService.InputEnded, function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if shiftHeld then
            shiftHeld = false
            applyMovementStats()
        end
    end
end)

-- If Roblox loses window focus while Shift is held, InputEnded may not arrive.
connectExternal(UserInputService.WindowFocusReleased, function()
    if shiftHeld then
        shiftHeld = false
        applyMovementStats()
    end
end)

connectExternal(RunService.Heartbeat, function()
    if not gui.Parent then return end

    -- Recover missed key-up events, but only update movement when the state changes.
    local focusedTextBox = UserInputService:GetFocusedTextBox() ~= nil
    local shiftDown = false
    if not opened and not focusedTextBox and state.sprintEnabled then
        shiftDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
    end

    if shiftHeld ~= shiftDown then
        shiftHeld = shiftDown
        applyMovementStats()
    end

    if state.fly and flyVelocity and flyVelocity.Parent then
        local camera = workspace.CurrentCamera
        local character, humanoid, root = getMovementCharacter()
        if not camera or not character or character ~= flyCharacter or not humanoid or not root
            or not flyOrientation or not flyOrientation.Parent then
            setFly(false)
            return
        end

        -- While the menu or a text field is active, hold the character still.
        -- GUI interaction must never be interpreted as flight input.
        if opened or UserInputService:GetFocusedTextBox() then
            flyVelocity.VectorVelocity = Vector3.zero
        else
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end

            local cameraRight = camera.CFrame.RightVector
            local flatRight = Vector3.new(cameraRight.X, 0, cameraRight.Z)
            if flatRight.Magnitude > 0.001 then
                flatRight = flatRight.Unit
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += flatRight end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= flatRight end
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
                direction -= Vector3.yAxis
            end

            if direction.Magnitude > 1 then direction = direction.Unit end
            flyVelocity.VectorVelocity = direction * state.flySpeed

            -- Keep only yaw on the character. Camera pitch/roll must not tilt the rig.
            local look = camera.CFrame.LookVector
            local flatLook = Vector3.new(look.X, 0, look.Z)
            if flatLook.Magnitude > 0.001 then
                flyOrientation.CFrame = CFrame.lookAt(Vector3.zero, flatLook.Unit, Vector3.yAxis)
            end
        end
    elseif state.fly then
        setFly(false)
    end
end)

connectExternal(player.CharacterRemoving, function(character)
    stopFly()
    restoreNoclip()
    -- Restore the outgoing rig before Roblox removes it, so no modified state
    -- can leak into respawn or a replacement character.
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local original = humanoid and movementOriginal[humanoid]
    if humanoid and original then
        pcall(function()
            humanoid.WalkSpeed = original.WalkSpeed
            humanoid.JumpPower = original.JumpPower
            humanoid.JumpHeight = original.JumpHeight
            humanoid.UseJumpPower = original.UseJumpPower
            humanoid.AutoRotate = original.AutoRotate
            humanoid.PlatformStand = original.PlatformStand
        end)
        movementOriginal[humanoid] = nil
    end
    shiftHeld = false
    -- Keep the user's Noclip toggle state; CharacterAdded reapplies it to the new rig.
end)

connectExternal(player.CharacterAdded, function(character)
    shiftHeld = false
    task.delay(0.35, function()
        if not gui.Parent or player.Character ~= character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            saveHumanoidDefaults(humanoid)
            applyMovementStats()
        end
        if state.noclip then setNoclip(true) end
        if state.fly then setFly(true) end
    end)
end)

local function movementValueCard(titleText, description, getter, setter, step, minimum, maximum, suffix)
    local f = card(82)
    textLabel(f, titleText, UDim2.fromOffset(16, 8), UDim2.new(1, -245, 0, 22), 12, C.text, true)
    textLabel(f, description, UDim2.fromOffset(16, 32), UDim2.new(1, -245, 0, 18), 9, C.muted)
    local valueLabel = textLabel(f, tostring(getter()) .. (suffix or ""), UDim2.new(1, -230, 0, 25), UDim2.fromOffset(68, 28), 12, state.accent, true)
    actionButton(f, "−", 104, 24, 34, function()
        setter(math.clamp(getter() - step, minimum, maximum))
        valueLabel.Text = tostring(getter()) .. (suffix or "")
        applyMovementStats()
        if state.fly and titleText == "Скорость полёта" then
            -- Fly speed is read continuously by the movement loop.
        end
    end, true)
    actionButton(f, "+", 16, 24, 34, function()
        setter(math.clamp(getter() + step, minimum, maximum))
        valueLabel.Text = tostring(getter()) .. (suffix or "")
        applyMovementStats()
    end, true)
end

local function buildMovement()
    clearPage()

    local intro = card(70)
    textLabel(intro, "Управление персонажем", UDim2.fromOffset(16, 9), UDim2.new(1, -30, 0, 22), 12, C.text, true)
    textLabel(intro, "Настройки применяются к твоему персонажу и обновляются после респавна", UDim2.fromOffset(16, 34), UDim2.new(1, -30, 0, 24), 9, C.muted)

    movementValueCard("Обычная скорость", "Скорость ходьбы без Shift", function() return state.walkSpeed end, function(v) state.walkSpeed = v end, 2, 1, 200, "")
    addToggle("Своя скорость", "Включить заданную обычную скорость", function() return state.speedEnabled end, function(v)
        state.speedEnabled = v
        applyMovementStats()
    end)

    movementValueCard("Скорость бега", "Скорость при удержании Shift", function() return state.sprintSpeed end, function(v) state.sprintSpeed = v end, 2, 1, 250, "")
    addToggle("Бег на Shift", "Удерживай Shift для ускорения", function() return state.sprintEnabled end, function(v)
        state.sprintEnabled = v
        if not v then shiftHeld = false end
        applyMovementStats()
    end)

    movementValueCard("Сила прыжка", "Значение JumpPower или JumpHeight — зависит от игры", function()
        local _, humanoid = getMovementCharacter()
        return humanoid and humanoid.UseJumpPower and state.jumpPower or state.jumpHeight
    end, function(v)
        local _, humanoid = getMovementCharacter()
        if humanoid and humanoid.UseJumpPower then state.jumpPower = v else state.jumpHeight = v end
    end, 5, 1, 200, "")
    addToggle("Своя сила прыжка", "Включить заданную силу прыжка", function() return state.jumpEnabled end, function(v)
        state.jumpEnabled = v
        applyMovementStats()
    end)

    movementValueCard("Скорость полёта", "Измени скорость перемещения в режиме Fly", function() return state.flySpeed end, function(v) state.flySpeed = v end, 5, 10, 200, "")

    addToggle("Noclip", "Проходить сквозь стены и объекты", function() return state.noclip end, function(v)
        setNoclip(v)
        notify("Noclip", v and "Включён" or "Выключен")
    end)
    addToggle("Fly", "WASD — движение, Space — вверх, Ctrl/C — вниз", function() return state.fly end, function(v)
        setFly(v)
        notify("Fly", state.fly and "Полёт включён" or "Полёт выключен")
    end)

    local info = card(72)
    textLabel(info, "Управление Fly", UDim2.fromOffset(16, 8), UDim2.new(1, -30, 0, 20), 11, C.text, true)
    textLabel(info, "W/A/S/D — направление камеры  •  Space — вверх  •  Left Ctrl или C — вниз. Shift отдельно включает бег, когда Fly выключен.", UDim2.fromOffset(16, 30), UDim2.new(1, -30, 0, 34), 9, C.muted)
end

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
            local selectedColor = color
            local dot=make("TextButton",{Position=UDim2.fromOffset(16+(i-1)*39,37),Size=UDim2.fromOffset(26,26),BackgroundColor3=selectedColor,Text="",AutoButtonColor=false,ZIndex=8},cf)
            round(dot,13); stroke(dot,C.line)
            dot.Activated:Connect(function() state.espColor=selectedColor; refreshPlayerVisuals(); refreshOwnEffects() end)
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
        local themeIndex, themeName = i, name
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
            state.theme = (themeIndex == 1 and "Dark") or (themeIndex == 2 and "Light") or "Custom"
            applyTheme()
            notify("Тема изменена", themeName)
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
            local fieldKey, fieldHint, fieldX = item.key, item.hint, item.x
            local box = make("TextBox", {
                Position = UDim2.fromOffset(fieldX, 60),
                Size = UDim2.fromOffset(116, 30),
                BackgroundColor3 = C.hover,
                Text = colorToHex(state[fieldKey]),
                PlaceholderText = fieldHint,
                TextColor3 = C.text,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                ClearTextOnFocus = false,
                ZIndex = 8
            }, custom, "hover")
            round(box, 8)
            box.FocusLost:Connect(function()
                local parsed = hexToColor(box.Text)
                if parsed then state[fieldKey] = parsed; applyTheme() else notify("Неверный HEX", "Используй формат #RRGGBB") end
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


-- Local diagnostics: records movement, character state, input buttons and rollbacks.
local diagnostics = {
    active = false,
    lines = {},
    startedAt = 0,
    sampleCount = 0,
    lastPosition = nil,
    lastSampleAt = nil,
    connections = {},
    droppedLines = 0,
    uiStatus = nil,
    uiPreview = nil,
    clickedTarget = nil,
    clickedTargetAt = 0,
    lastMouseDown = {},
    lastAnimSignature = ""
}
local function diagDisconnect()
    for _, connection in ipairs(diagnostics.connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(diagnostics.connections)
end
local function diagLine(message)
    if not diagnostics.active then return end
    local elapsed = os.clock() - diagnostics.startedAt
    local line = string.format("[%08.2f | %s] %s", elapsed, os.date("%H:%M:%S"), tostring(message))
    table.insert(diagnostics.lines, line)
    if #diagnostics.lines > 8000 then
        table.remove(diagnostics.lines, 1)
        diagnostics.droppedLines += 1
    end
end
local function diagVector(v)
    if typeof(v) ~= "Vector3" then return "n/a" end
    return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
end
local function diagCharacter()
    local character = player.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end
local function diagPath(instance)
    if not instance then return "nil" end
    local names = {}
    local current = instance
    for _ = 1, 5 do
        if not current then break end
        table.insert(names, 1, current.Name)
        current = current.Parent
    end
    return table.concat(names, "/")
end
local function diagTargetDetails(target, hitPosition)
    if not target or not target:IsA("BasePart") then
        diagLine("TARGET: курсор не попал в BasePart")
        return
    end
    local assembly = target.AssemblyRootPart or target
    local character, _, root = diagCharacter()
    local relative = "n/a"
    if root then
        relative = diagVector(root.Position - target.Position)
    end
    diagLine("TARGET CLICK: " .. diagPath(target)
        .. " | class=" .. target.ClassName
        .. " | partPos=" .. diagVector(target.Position)
        .. " | hitPos=" .. diagVector(hitPosition)
        .. " | assemblyRoot=" .. diagPath(assembly)
        .. " | assemblyVel=" .. diagVector(assembly.AssemblyLinearVelocity)
        .. " | playerMinusTarget=" .. relative)
end
local function diagLogCharacterConnections(character)
    local count = 0
    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("JointInstance") or item:IsA("WeldConstraint")
            or item:IsA("AlignPosition") or item:IsA("AlignOrientation")
            or item:IsA("RopeConstraint") or item:IsA("RodConstraint")
            or item:IsA("HingeConstraint") then
            local connected = ""
            pcall(function()
                if item:IsA("JointInstance") then
                    connected = " Part0=" .. diagPath(item.Part0) .. " Part1=" .. diagPath(item.Part1)
                elseif item:IsA("WeldConstraint") then
                    connected = " Part0=" .. diagPath(item.Part0) .. " Part1=" .. diagPath(item.Part1)
                end
            end)
            diagLine("CHAR CONNECTION: " .. item.ClassName .. " " .. diagPath(item) .. connected)
            count += 1
        end
    end
    if count == 0 then diagLine("CHAR CONNECTION: видимых локально соединений не найдено") end
end
local function diagLogAnimations(humanoid)
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    local tracks = animator:GetPlayingAnimationTracks()
    local parts = {}
    for _, track in ipairs(tracks) do
        local animationId = "unknown"
        pcall(function()
            if track.Animation then animationId = track.Animation.AnimationId end
        end)
        table.insert(parts, tostring(animationId) .. ":" .. tostring(track.Speed) .. ":" .. tostring(track.WeightCurrent))
    end
    local signature = table.concat(parts, "|")
    if signature ~= diagnostics.lastAnimSignature then
        diagnostics.lastAnimSignature = signature
        if #tracks == 0 then
            diagLine("ANIMATION: активных треков нет")
        else
            for _, track in ipairs(tracks) do
                local animationId, animationName = "unknown", "unknown"
                pcall(function()
                    if track.Animation then
                        animationId = track.Animation.AnimationId
                        animationName = track.Animation.Name
                    end
                end)
                diagLine("ANIMATION: id=" .. tostring(animationId)
                    .. " | name=" .. tostring(animationName)
                    .. " | speed=" .. tostring(track.Speed)
                    .. " | weight=" .. tostring(track.WeightCurrent)
                    .. " | priority=" .. tostring(track.Priority))
            end
        end
    end
end
local function diagAttachCharacter(character)
    if not diagnostics.active or not character then return end
    diagLine("CHARACTER появился: " .. character.Name)
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if humanoid and diagnostics.active then
        table.insert(diagnostics.connections, humanoid.StateChanged:Connect(function(oldState, newState)
            diagLine("СОСТОЯНИЕ: " .. tostring(oldState.Name) .. " -> " .. tostring(newState.Name))
        end))
        for _, property in ipairs({"WalkSpeed", "JumpPower", "JumpHeight", "HipHeight", "PlatformStand", "AutoRotate", "Sit", "Health"}) do
            table.insert(diagnostics.connections, humanoid:GetPropertyChangedSignal(property):Connect(function()
                if diagnostics.active then
                    local value = humanoid[property]
                    diagLine("HUMANOID." .. property .. " = " .. tostring(value))
                end
            end))
        end
    end
end
local function diagStart()
    if diagnostics.active then return end
    diagnostics.lines = {}
    diagnostics.droppedLines = 0
    diagnostics.sampleCount = 0
    diagnostics.startedAt = os.clock()
    diagnostics.lastPosition = nil
    diagnostics.lastSampleAt = nil
    diagnostics.clickedTarget = nil
    diagnostics.clickedTargetAt = 0
    diagnostics.lastMouseDown = {}
    diagnostics.lastAnimSignature = ""
    diagnostics.active = true
    diagLine("=== FREE MENU DIAGNOSTICS START ===")
    diagLine("PlaceId=" .. tostring(game.PlaceId) .. " | GameId=" .. tostring(game.GameId))
    diagLine("Player=" .. player.Name .. " | UserId=" .. tostring(player.UserId))
    diagLine("Пишутся только локальные данные; ничего никуда не отправляется.")
    diagLine("Сэмплирование: 5 раз/сек; лимит буфера: 8000 строк.")
    diagAttachCharacter(player.Character)
    if player.Character then diagLogCharacterConnections(player.Character) end
    table.insert(diagnostics.connections, player.CharacterAdded:Connect(function(character)
        diagAttachCharacter(character)
        task.delay(0.5, function()
            if diagnostics.active and character.Parent then diagLogCharacterConnections(character) end
        end)
    end))
    table.insert(diagnostics.connections, player.CharacterRemoving:Connect(function(character)
        diagLine("CHARACTER удаляется: " .. character.Name)
        diagnostics.lastPosition = nil
        diagnostics.lastSampleAt = nil
    end))
    table.insert(diagnostics.connections, UserInputService.InputBegan:Connect(function(input, processed)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseMovement then return end
        local now = os.clock()
        diagLine("INPUT DOWN: " .. tostring(kind.Name) .. " / " .. tostring(input.KeyCode.Name) .. " | processed=" .. tostring(processed))
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.MouseButton2 then
            local buttonName = kind == Enum.UserInputType.MouseButton1 and "LMB" or "RMB"
            diagnostics.lastMouseDown[buttonName] = now
            local otherName = buttonName == "LMB" and "RMB" or "LMB"
            if diagnostics.lastMouseDown[otherName] and math.abs(now - diagnostics.lastMouseDown[otherName]) <= 0.25 then
                diagLine("ЗАЦЕП: ЛКМ + ПКМ нажаты почти одновременно (интервал <= 0.25 сек)")
            end
            local mouse = player:GetMouse()
            local target, hit = nil, Vector3.zero
            pcall(function()
                target = mouse.Target
                hit = mouse.Hit.Position
            end)
            diagnostics.clickedTarget = target
            diagnostics.clickedTargetAt = now
            diagTargetDetails(target, hit)
        end
    end))
    table.insert(diagnostics.connections, UserInputService.InputEnded:Connect(function(input, processed)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseMovement then return end
        diagLine("INPUT UP: " .. tostring(kind.Name) .. " / " .. tostring(input.KeyCode.Name) .. " | processed=" .. tostring(processed))
    end))
    table.insert(diagnostics.connections, UserInputService.WindowFocusReleased:Connect(function()
        diagLine("WINDOW: потерян фокус окна")
    end))
    table.insert(diagnostics.connections, UserInputService.WindowFocused:Connect(function()
        diagLine("WINDOW: окно снова в фокусе")
    end))
    task.spawn(function()
        while diagnostics.active and gui.Parent do
            local now = os.clock()
            local character, humanoid, root = diagCharacter()
            if humanoid and root and root:IsA("BasePart") then
                diagLogAnimations(humanoid)
                local position = root.Position
                local velocity = root.AssemblyLinearVelocity
                local deltaTime = diagnostics.lastSampleAt and (now - diagnostics.lastSampleAt) or 0
                local distance = diagnostics.lastPosition and (position - diagnostics.lastPosition).Magnitude or 0
                local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
                local stateName = "Unknown"
                pcall(function() stateName = humanoid:GetState().Name end)
                local floorName = "Air"
                pcall(function() floorName = humanoid.FloorMaterial.Name end)
                local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
                local move = humanoid.MoveDirection
                local line = string.format(
                    "SAMPLE #%d | pos=%s | vel=%s | speed=%.2f (horizontal=%.2f) | moved=%.2f/%.3fs | moveDir=%s | state=%s | floor=%s | grounded=%s | health=%.1f | WalkSpeed=%.1f | JumpPower=%.1f | JumpHeight=%.1f | HipHeight=%.2f | Sit=%s | PlatformStand=%s | AutoRotate=%s | noclip=%s | fly=%s | sprint=%s",
                    diagnostics.sampleCount + 1, diagVector(position), diagVector(velocity),
                    velocity.Magnitude, horizontalSpeed, distance, deltaTime, diagVector(move),
                    stateName, floorName, tostring(grounded), humanoid.Health,
                    humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.HipHeight,
                    tostring(humanoid.Sit), tostring(humanoid.PlatformStand), tostring(humanoid.AutoRotate),
                    tostring(state.noclip), tostring(state.fly), tostring(state.sprintEnabled and shiftHeld)
                )
                diagLine(line)
                local clickedTarget = diagnostics.clickedTarget
                if clickedTarget and clickedTarget.Parent and (now - diagnostics.clickedTargetAt) <= 12 then
                    local targetAssembly = clickedTarget.AssemblyRootPart or clickedTarget
                    local targetVelocity = targetAssembly.AssemblyLinearVelocity
                    local relativeVelocity = velocity - targetVelocity
                    local relativePosition = position - clickedTarget.Position
                    diagLine("TRAIN/TARGET TRACK | part=" .. diagPath(clickedTarget)
                        .. " | playerPos=" .. diagVector(position)
                        .. " | targetPos=" .. diagVector(clickedTarget.Position)
                        .. " | relativePos=" .. diagVector(relativePosition)
                        .. " | targetVel=" .. diagVector(targetVelocity)
                        .. " | relativeVel=" .. diagVector(relativeVelocity)
                        .. " | distance=" .. string.format("%.2f", relativePosition.Magnitude))
                elseif clickedTarget and not clickedTarget.Parent then
                    diagLine("TARGET LOST: выбранная деталь удалена из Workspace")
                    diagnostics.clickedTarget = nil
                end
                if diagnostics.lastPosition and deltaTime > 0 then
                    local measured = distance / deltaTime
                    if distance > 10 and measured > 45 then
                        diagLine(string.format("ПОДОЗРИТЕЛЬНЫЙ СКАЧОК: %.2f studs за %.3f сек (%.2f studs/s)", distance, deltaTime, measured))
                    elseif distance > 5 and measured > 25 and horizontalSpeed < 8 then
                        diagLine(string.format("ВОЗМОЖНЫЙ ОТКАТ/ТЕЛЕПОРТ: позиция изменилась на %.2f studs, текущая скорость %.2f", distance, horizontalSpeed))
                    end
                end
                diagnostics.lastPosition = position
                diagnostics.lastSampleAt = now
                diagnostics.sampleCount += 1
            else
                diagLine("SAMPLE: персонаж или HumanoidRootPart отсутствует")
                diagnostics.lastPosition = nil
                diagnostics.lastSampleAt = nil
            end
            if diagnostics.uiStatus and diagnostics.uiStatus.Parent then
                diagnostics.uiStatus.Text = string.format("ЗАПИСЬ: ВКЛ • %.1f сек • %d строк", os.clock() - diagnostics.startedAt, #diagnostics.lines)
            end
            task.wait(0.2)
        end
    end)
end
local function diagStop()
    if not diagnostics.active then return end
    diagLine("=== STOP: запись остановлена пользователем ===")
    diagnostics.active = false
    diagDisconnect()
    if diagnostics.uiStatus and diagnostics.uiStatus.Parent then
        diagnostics.uiStatus.Text = string.format("ЗАПИСЬ: ВЫКЛ • %d строк", #diagnostics.lines)
    end
end
local function diagGetLog()
    local header = "FREE MENU DIAGNOSTIC LOG\n"
    if diagnostics.droppedLines > 0 then
        header ..= "ВНИМАНИЕ: старые строки удалены из-за лимита буфера: " .. tostring(diagnostics.droppedLines) .. "\n"
    end
    return header .. table.concat(diagnostics.lines, "\n")
end
local function diagRefreshPreview()
    if not diagnostics.uiPreview or not diagnostics.uiPreview.Parent then return end
    local first = math.max(1, #diagnostics.lines - 44)
    local preview = {}
    for i = first, #diagnostics.lines do table.insert(preview, diagnostics.lines[i]) end
    diagnostics.uiPreview.Text = #preview > 0 and table.concat(preview, "\n") or "Лог пока пуст. Нажми «ЗАПУСТИТЬ ЛОГ»."
end
local function buildDiagnostics()
    clearPage()
    local info = card(86)
    textLabel(info, "ЛОКАЛЬНАЯ ДИАГНОСТИКА", UDim2.fromOffset(16, 9), UDim2.new(1, -30, 0, 22), 12, C.text, true)
    textLabel(info, "Скорость, позиция, физика, состояние персонажа, кнопки, прыжки, падения и возможные откаты сервера.", UDim2.fromOffset(16, 34), UDim2.new(1, -30, 0, 42), 9, C.muted, false)

    local statusCard = card(58)
    diagnostics.uiStatus = textLabel(statusCard, diagnostics.active and "ЗАПИСЬ: ВКЛ" or string.format("ЗАПИСЬ: ВЫКЛ • %d строк", #diagnostics.lines), UDim2.fromOffset(16, 8), UDim2.new(1, -30, 0, 40), 11, diagnostics.active and state.accent or C.text, true)

    local startCard = card(66)
    textLabel(startCard, "Начать сбор событий и замеров", UDim2.fromOffset(16, 7), UDim2.new(1, -155, 0, 48), 10, C.muted, false)
    actionButton(startCard, "ЗАПУСТИТЬ ЛОГ", 14, 16, 132, function()
        diagStart()
        if diagnostics.uiStatus then diagnostics.uiStatus.Text = "ЗАПИСЬ: ВКЛ" end
        notify("Диагностика", "Запись запущена")
    end)

    local stopCard = card(66)
    textLabel(stopCard, "Остановить запись и зафиксировать конец лога", UDim2.fromOffset(16, 7), UDim2.new(1, -155, 0, 48), 10, C.muted, false)
    actionButton(stopCard, "ОСТАНОВИТЬ", 14, 16, 132, function()
        diagStop()
        diagRefreshPreview()
        notify("Диагностика", "Запись остановлена")
    end, true)

    local copyCard = card(66)
    textLabel(copyCard, "Скопировать весь лог целиком в буфер обмена", UDim2.fromOffset(16, 7), UDim2.new(1, -155, 0, 48), 10, C.muted, false)
    actionButton(copyCard, "КОПИРОВАТЬ", 14, 16, 132, function()
        if diagnostics.active then diagStop() end
        local fullLog = diagGetLog()
        local clipboard = sharedEnv.setclipboard or sharedEnv.toclipboard
        if type(clipboard) == "function" then
            local ok, err = pcall(clipboard, fullLog)
            if ok then
                notify("Готово", "Полный лог скопирован (" .. tostring(#fullLog) .. " символов)")
            else
                warn("[FREE MENU] Clipboard failed: " .. tostring(err))
                if diagnostics.uiPreview and diagnostics.uiPreview.Parent then diagnostics.uiPreview.Text = fullLog end
                notify("Буфер недоступен", "Полный лог открыт ниже: Ctrl+A и Ctrl+C")
            end
        else
            if diagnostics.uiPreview and diagnostics.uiPreview.Parent then diagnostics.uiPreview.Text = fullLog end
            notify("Буфер недоступен", "Полный лог открыт ниже: Ctrl+A и Ctrl+C")
        end
    end)

    local clearCard = card(66)
    textLabel(clearCard, "Удалить текущий лог из памяти меню", UDim2.fromOffset(16, 7), UDim2.new(1, -155, 0, 48), 10, C.muted, false)
    actionButton(clearCard, "ОЧИСТИТЬ", 14, 16, 132, function()
        if diagnostics.active then diagStop() end
        diagnostics.lines = {}
        diagnostics.droppedLines = 0
        if diagnostics.uiStatus then diagnostics.uiStatus.Text = "ЗАПИСЬ: ВЫКЛ • 0 строк" end
        diagRefreshPreview()
        notify("Диагностика", "Лог очищен")
    end, true)

    local previewCard = card(210)
    textLabel(previewCard, "ПОСЛЕДНИЕ СТРОКИ ЛОГА", UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 20), 10, C.text, true)
    local preview = make("TextBox", {
        Position = UDim2.fromOffset(12, 34),
        Size = UDim2.new(1, -24, 1, -44),
        BackgroundColor3 = C.panel,
        TextColor3 = C.muted,
        Text = "",
        PlaceholderText = "Лог пока пуст...",
        Font = Enum.Font.Code,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = false,
        TextEditable = true,
        ClearTextOnFocus = false,
        MultiLine = true,
        ZIndex = 8
    }, previewCard, "card")
    round(preview, 8)
    diagnostics.uiPreview = preview
    diagRefreshPreview()
end


showPage = function(name)
    activePage = name
    pageTitle.Text = name
    pageDesc.Text = name == "Главная" and "Центр управления игровыми функциями"
        or name == "Визуалы" and "Подсветка игроков и эффекты персонажа"
        or name == "Движение" and "Скорость, прыжки, полёт и noclip"
        or name == "Диагностика" and "Локальный лог физики, движения и нажатий"
        or "Внешний вид и параметры интерфейса"
    applyTheme()
    scroll.CanvasPosition = Vector2.new(0, 0)
    if name == "Главная" then buildHome()
    elseif name == "Визуалы" then buildVisuals()
    elseif name == "Движение" then buildMovement()
    elseif name == "Диагностика" then buildDiagnostics()
    else buildSettings() end
end
for name, b in pairs(tabButtons) do
    local tabName = name
    b.Name = tabName
    b.Activated:Connect(function() showPage(tabName) end)
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

-- ScrollingFrame already handles mouse-wheel input natively. Avoid a second
-- wheel handler that competes with the built-in scroll behavior.

local emergencyStop -- forward declaration: the End-key callback is created before the function body
connectExternal(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.End then
        if emergencyStop then emergencyStop() end
    elseif input.KeyCode == Enum.KeyCode.Insert then
        if opened then closeMenu() else openMenu() end
    end
end)
emergencyStop = function()
    -- Stop all character-affecting features and restore the values captured at activation.
    state.speedEnabled = false
    state.sprintEnabled = false
    state.jumpEnabled = false
    state.noclip = false
    state.fly = false
    shiftHeld = false

    stopFly()
    restoreNoclip()
    restoreMovement()

    state.playerESP = false
    state.playerChams = false
    refreshPlayerVisuals()

    state.overheadHat = false
    state.overheadTrail = false
    state.overheadParticles = false
    clearOwnEffects()

    if showPage then showPage(activePage) end
    notify("Аварийная остановка", "Движение, визуалы и фильтры отключены")
end

local cleaned = false
local function cleanup()
    if cleaned then return end
    if diagnostics and diagnostics.active then diagStop() end
    cleaned = true

    restoreCursor()

    for _, connection in ipairs(externalConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(externalConnections)

    for target in pairs(playerVisuals) do
        clearPlayerVisual(target)
    end
    table.clear(playerVisuals)
    table.clear(playerCharacterConnections)
    clearOwnEffects()
    restoreMovement()
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

showPage("Главная")
applyTheme()
