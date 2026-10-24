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

-- Создание красивого меню
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local oldGui = CoreGui:FindFirstChild("ZeusXLoader")
if oldGui then oldGui:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "ZeusXLoader"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = CoreGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 400, 0, 250)
bg.Position = UDim2.new(0.5, -200, 0.5, -125)
bg.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
bg.BackgroundTransparency = 0.1
bg.BorderSizePixel = 0
bg.Parent = sg
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 42, 42)
stroke.Thickness = 1.5
stroke.Transparency = 0.3
stroke.Parent = bg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "ZEUS-X LOADER"
title.TextColor3 = Color3.fromRGB(255, 42, 42)
title.Font = Enum.Font.GothamBlack
title.TextSize = 24
title.Parent = bg

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, 0, 0, 20)
sub.Position = UDim2.new(0, 0, 0, 40)
sub.BackgroundTransparency = 1
sub.Text = "Выбери версию для запуска"
sub.TextColor3 = Color3.fromRGB(150, 150, 160)
sub.Font = Enum.Font.Gotham
sub.TextSize = 12
sub.Parent = bg

local function createButton(text, color, yPos, verType)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -60, 0, 50)
    btn.Position = UDim2.new(0, 30, 0, yPos)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.Parent = bg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local bStroke = Instance.new("UIStroke")
    bStroke.Color = color
    bStroke.Thickness = 1.5
    bStroke.Transparency = 0.5
    bStroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        btn.Text = "Загрузка..."
        btn.Active = false
        task.wait(0.5)
        sg:Destroy()
        runScript(verType)
    end)
end

createButton("🔥 AGGRESSIVE", Color3.fromRGB(180, 30, 30), 80, "aggressive")
createButton("🌀 LITE", Color3.fromRGB(40, 80, 180), 150, "lite")