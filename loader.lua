-- ============================================================
-- Zeus-X Premium Loader v2.0
-- Красивое меню выбора версии с анимациями
-- ============================================================

local SERVER_URL = "https://zeus-key-mjep.onrender.com/version"

local function fetchVersion(verType)
    local url = SERVER_URL .. "?type=" .. verType
    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not response or response == "" then return nil, "нет соединения" end
    local okDecode, data = pcall(function() return game:GetService("HttpService"):JSONDecode(response) end)
    if not okDecode or not data.ok then return nil, "ошибка сервера" end
    return data.url, data.version
end

local function runScript(verType)
    local scriptUrl, version = fetchVersion(verType)
    if not scriptUrl then
        print("[Zeus-X Loader] Ошибка: " .. tostring(version))
        return
    end
    print("[Zeus-X Loader] Загрузка " .. string.upper(verType) .. " v" .. tostring(version) .. "...")
    local ok, code = pcall(function() return game:HttpGet(scriptUrl, true) end)
    if not ok or not code or code == "" then
        print("[Zeus-X Loader] Ошибка скачивания")
        return
    end
    local func, err = loadstring(code)
    if not func then
        print("[Zeus-X Loader] Ошибка компиляции: " .. tostring(err))
        return
    end
    pcall(func)
end

-- ============================================================
-- GUI LOADER (Премиум дизайн)
-- ============================================================

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local oldGui = CoreGui:FindFirstChild("ZeusXPremiumLoader")
if oldGui then oldGui:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "ZeusXPremiumLoader"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 9999
sg.Parent = CoreGui

-- Основное окно
local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 420, 0, 320)
bg.Position = UDim2.new(0.5, -210, 0.5, -160)
bg.BackgroundColor3 = Color3.fromRGB(10, 6, 18)
bg.BackgroundTransparency = 0.1
bg.BorderSizePixel = 0
bg.Active = true
bg.Draggable = true
bg.Parent = sg
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 20)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(140, 90, 255)
stroke.Thickness = 2
stroke.Transparency = 0.2
stroke.Parent = bg

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.BackgroundTransparency = 1
title.Text = "ZEUS-X"
title.TextColor3 = Color3.fromRGB(180, 130, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 36
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = bg

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, 0, 0, 20)
sub.Position = UDim2.new(0, 0, 0, 50)
sub.BackgroundTransparency = 1
sub.Text = "PREMIUM LOADER"
sub.TextColor3 = Color3.fromRGB(140, 90, 255)
sub.Font = Enum.Font.GothamBold
sub.TextSize = 12
sub.Parent = bg

-- Кнопка AGGRESSIVE
local btnAggro = Instance.new("TextButton")
btnAggro.Size = UDim2.new(0, 380, 0, 50)
btnAggro.Position = UDim2.new(0, 20, 0, 100)
btnAggro.BackgroundColor3 = Color3.fromRGB(255, 42, 42)
btnAggro.BackgroundTransparency = 0.2
btnAggro.Text = "🔥 AGGRESSIVE"
btnAggro.TextColor3 = Color3.fromRGB(255, 255, 255)
btnAggro.Font = Enum.Font.GothamBold
btnAggro.TextSize = 18
btnAggro.BorderSizePixel = 0
btnAggro.Parent = bg
Instance.new("UICorner", btnAggro).CornerRadius = UDim.new(0, 12)

local strokeAggro = Instance.new("UIStroke", btnAggro)
strokeAggro.Color = Color3.fromRGB(255, 42, 42)
strokeAggro.Thickness = 2
strokeAggro.Transparency = 0.5

btnAggro.MouseButton1Click:Connect(function()
    btnAggro.Text = "Загрузка..."
    btnAggro.Active = false
    task.wait(0.3)
    sg:Destroy()
    runScript("aggressive")
end)

-- Кнопка LITE
local btnLite = Instance.new("TextButton")
btnLite.Size = UDim2.new(0, 380, 0, 50)
btnLite.Position = UDim2.new(0, 20, 0, 170)
btnLite.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
btnLite.BackgroundTransparency = 0.2
btnLite.Text = "🌀 LITE"
btnLite.TextColor3 = Color3.fromRGB(255, 255, 255)
btnLite.Font = Enum.Font.GothamBold
btnLite.TextSize = 18
btnLite.BorderSizePixel = 0
btnLite.Parent = bg
Instance.new("UICorner", btnLite).CornerRadius = UDim.new(0, 12)

local strokeLite = Instance.new("UIStroke", btnLite)
strokeLite.Color = Color3.fromRGB(59, 130, 246)
strokeLite.Thickness = 2
strokeLite.Transparency = 0.5

btnLite.MouseButton1Click:Connect(function()
    btnLite.Text = "Загрузка..."
    btnLite.Active = false
    task.wait(0.3)
    sg:Destroy()
    runScript("lite")
end)

-- Футер
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 30)
footer.Position = UDim2.new(0, 0, 1, -40)
footer.BackgroundTransparency = 1
footer.Text = "Telegram: @noir_xis"
footer.TextColor3 = Color3.fromRGB(100, 80, 120)
footer.Font = Enum.Font.Gotham
footer.TextSize = 12
footer.Parent = bg

-- Анимация появления
bg.Position = UDim2.new(0.5, -210, 0.5, -140)
bg.BackgroundTransparency = 1
task.spawn(function()
    TweenService:Create(bg, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
        Position = UDim2.new(0.5, -210, 0.5, -160),
        BackgroundTransparency = 0.1
    }):Play()
end)