-- ============================================================
-- vanta v9.0 · ЧАСТЬ 1/8 — services + config + keygate
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

local SERVER_URL = "https://zeus-key-mjep.onrender.com/check"
local TG_LINK    = "https://t.me/noir_xis"

local Config = {
    Aim = {
        Enabled=false, FOV=120, Smooth=0.35,
        Key=Enum.UserInputType.MouseButton2,
        Visible=true, WallCheck=true, TeamCheck=true,
        Part="Head",
    },
    Silent = { Enabled=false, HitChance=100, TeamCheck=true },
    Trigger = {
        Enabled=false, Key=Enum.UserInputType.MouseButton1,
        Delay=0.06, WallCheck=true, TeamCheck=true,
    },
    ESP = {
        Enabled=false, Box=true, Name=true, Health=true, Distance=true,
        TeamCheck=true, MaxDist=2000, MinParts=5,
    },
    Move = {
        Speed=false, SpeedVal=28,
        Fly=false, FlySpeed=50,
        InfJump=false, Noclip=false,
    },
    Zeus = { Enabled=false, RegenSpeed=10, MaxHealth=1000 },
    Ammo = { Enabled=false, AmmoValue=999, AutoReload=true },
    Vis = { Fullbright=false, NoFog=false, FOV=70 },
}
getgenv().vanta_cfg = Config

local origWalkSpeed = 16

local function getHWID()
    if gethwid then
        local ok, id = pcall(gethwid)
        if ok and id then return tostring(id) end
    end
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id then return tostring(id) end
    return "unknown_" .. tostring(os.time())
end

local function checkKeyOnServer(key)
    local hwid = getHWID()
    local username = LocalPlayer.Name
    local url = SERVER_URL .. "?token=" .. key .. "&hwid=" .. hwid .. "&username=" .. username
    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not response then return false, "нет соединения" end
    local okDecode, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not okDecode or type(data) ~= "table" then return false, "ошибка сервера" end
    if data.ok then return true, data.left or 0 end
    local reasons = {
        invalid = "неверный ключ",
        hwid_mismatch = "ключ на другом устройстве",
        expired = "срок истёк",
        banned = "ключ забанен",
        no_activations = "активации кончились",
    }
    return false, reasons[data.reason] or "ошибка"
end

local function disableAll()
    Config.ESP.Enabled = false
    Config.Aim.Enabled = false
    Config.Silent.Enabled = false
    Config.Trigger.Enabled = false
    Config.Move.Speed = false
    Config.Move.Fly = false
    Config.Move.Noclip = false
    Config.Move.InfJump = false
    local p = (gethui and gethui()) or CoreGui
    local e = p:FindFirstChild("vanta_esp");  if e then e:Destroy() end
    local m = p:FindFirstChild("vanta_menu"); if m then m:Destroy() end
end

local active_key = nil

task.spawn(function()
    while task.wait(60) do
        if active_key then
            local ok = checkKeyOnServer(active_key)
            if not ok then
                active_key = nil
                disableAll()
                print("[vanta] ключ истёк или отозван")
                break
            end
        end
    end
end)

print("[vanta] part 1 OK")-- ============================================================
-- vanta v9.0 · ЧАСТЬ 2/8 — адаптивный поиск целей
-- ============================================================

local IGNORE = { TheMlgShep=true, R15_Dummy=true, Dummy=true }

local function hasParts(model)
    if not model or not model.Parent then return false end
    if not model:IsA("Model") then return false end
    local hum  = model:FindFirstChildOfClass("Humanoid")
    local head = model:FindFirstChild("Head", true)
    local root = model:FindFirstChild("HumanoidRootPart", true)
    return hum and head and root
end

local function isGarbage(model)
    if not hasParts(model) then return true end
    if model == LocalPlayer.Character then return true end
    if IGNORE[model.Name] then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return true end
    if hum.MaxHealth == math.huge or hum.MaxHealth <= 0 or hum.MaxHealth > 100000 then return true end
    if #model:GetChildren() < Config.ESP.MinParts then return true end
    return false
end

local function countPlayers()
    local n = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and hasParts(plr.Character) then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then n = n + 1 end
        end
    end
    return n
end

local WS_CONTAINERS = {
    "Characters","Entities","Actors","Players","Living","Units",
    "Combatants","Fighters","Dummies","Bots","Enemies","Mobs",
    "Monsters","NPCs","Pool","Active",
}

local function collectFromWorkspace()
    local list = {}
    for _, m in ipairs(Workspace:GetChildren()) do
        if not isGarbage(m) then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then table.insert(list, m) end
        end
    end
    for _, name in ipairs(WS_CONTAINERS) do
        local folder = Workspace:FindFirstChild(name)
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if not isGarbage(m) then
                    local h = m:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then table.insert(list, m) end
                end
            end
        end
    end
    return list
end

local function collectFromPlayers()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not isGarbage(plr.Character) then
            table.insert(list, plr.Character)
        end
    end
    return list
end

local scanMode = "players"
task.spawn(function()
    while task.wait(2) do
        local nP = countPlayers()
        local nW = #collectFromWorkspace()
        if nP >= nW and nP > 0 then scanMode = "players"
        elseif nW > nP then scanMode = "workspace" end
    end
end)

local function getTargets()
    if scanMode == "workspace" then return collectFromWorkspace()
    else return collectFromPlayers() end
end

local function getHumanoid(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function getHead(m)     return m and m:FindFirstChild("Head", true) end
local function getRoot(m)     return m and m:FindFirstChild("HumanoidRootPart", true) end

local function isAlive(m)
    local h = getHumanoid(m)
    if h then return h.Health > 0 end
    return getHead(m) ~= nil
end

local function resolveTeamId(obj)
    if not obj then return nil end
    if obj:IsA("Player") and obj.Team then return obj.Team end
    if obj:IsA("Player") and obj.TeamColor then return obj.TeamColor end
    if obj:IsA("Player") then
        local t = obj:GetAttribute("Team") or obj:GetAttribute("TeamId") or obj:GetAttribute("TeamName")
        if t then return t end
    end
    if obj:IsA("Model") then
        local t = obj:GetAttribute("Team") or obj:GetAttribute("TeamId")
        if t then return t end
    end
    return nil
end

local function sameTeam(model)
    if model.Name == LocalPlayer.Name then return true end
    local myT = resolveTeamId(LocalPlayer)
    local theirT = nil
    local plr = Players:FindFirstChild(model.Name)
    if plr then theirT = resolveTeamId(plr) end
    if not theirT then theirT = resolveTeamId(model) end
    if myT == nil or theirT == nil then return false end
    return myT == theirT
end

local function partPos(model, partName)
    if partName == "Head" then local h = getHead(model); return h and h.Position end
    local r = getRoot(model); return r and r.Position
end

local function w2s(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y), sp.Z
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(model, partName)
    local target = partPos(model, partName or "Head")
    if not target then return false end
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    local hit = Workspace:Raycast(Camera.CFrame.Position, target - Camera.CFrame.Position, rayParams)
    if not hit then return true end
    return hit.Instance and hit.Instance:IsDescendantOf(model)
end

print("[vanta] part 2 OK")-- ============================================================
-- vanta v9.0 · ЧАСТЬ 3/8 — ESP
-- ============================================================

local espGui = Instance.new("ScreenGui")
espGui.Name = "vanta_esp"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 998
espGui.Parent = (gethui and gethui()) or CoreGui

local ESP = setmetatable({}, { __mode = "k" })

local function mkLabel(color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.fromRGB(255,255,255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextStrokeTransparency = 0
    l.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    l.Visible = false
    l.Parent = espGui
    return l
end

local function createESP(model)
    if ESP[model] then return end
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = espGui
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(170,120,255)
    stroke.Thickness = 1.5
    stroke.Parent = box
    ESP[model] = {
        box=box, stroke=stroke,
        name=mkLabel(Color3.fromRGB(255,255,255)),
        hp=mkLabel(Color3.fromRGB(180,255,180)),
        dist=mkLabel(Color3.fromRGB(200,200,200)),
    }
end

local function destroyESP(model)
    local t = ESP[model]
    if not t then return end
    for _, o in pairs(t) do if o and o.Destroy then pcall(o.Destroy, o) end end
    ESP[model] = nil
end

local function renderESP()
    if not Config.ESP.Enabled then
        for _, t in pairs(ESP) do
            t.box.Visible=false; t.name.Visible=false; t.hp.Visible=false; t.dist.Visible=false
        end
        return
    end
    local myPos = Camera.CFrame.Position
    local seen = {}
    for _, model in ipairs(getTargets()) do
        seen[model] = true
        local t = ESP[model]
        if not t then createESP(model); t = ESP[model] end
        local show = isAlive(model) and not (Config.ESP.TeamCheck and sameTeam(model))
        local root = getRoot(model)
        if show and root then
            if (myPos - root.Position).Magnitude > Config.ESP.MaxDist then show = false end
        end
        if not show then
            t.box.Visible=false; t.name.Visible=false; t.hp.Visible=false; t.dist.Visible=false
        else
            local head = getHead(model)
            local hum  = getHumanoid(model)
            if head and root then
                local top = w2s(head.Position + Vector3.new(0,1,0))
                local bot = w2s(root.Position - Vector3.new(0,3,0))
                if top and bot then
                    local h = bot.Y - top.Y
                    local w = h * 0.5
                    local cx, cy = top.X, top.Y
                    t.box.Visible = Config.ESP.Box
                    t.box.Size = UDim2.new(0, w, 0, h)
                    t.box.Position = UDim2.new(0, cx - w/2, 0, cy)
                    t.name.Visible = Config.ESP.Name
                    t.name.Text = model.Name
                    t.name.Size = UDim2.new(0, 200, 0, 16)
                    t.name.Position = UDim2.new(0, cx - 100, 0, cy - 18)
                    local hp = hum and hum.Health or 100
                    t.hp.Visible = Config.ESP.Health
                    t.hp.Text = math.floor(hp) .. " hp"
                    t.hp.Size = UDim2.new(0, 200, 0, 16)
                    t.hp.Position = UDim2.new(0, cx - 100, 0, cy + h + 2)
                    t.hp.TextColor3 = hp > 50 and Color3.fromRGB(180,255,180) or Color3.fromRGB(255,140,180)
                    t.dist.Visible = Config.ESP.Distance
                    t.dist.Text = math.floor((myPos - root.Position).Magnitude) .. " m"
                    t.dist.Size = UDim2.new(0, 200, 0, 16)
                    t.dist.Position = UDim2.new(0, cx - 100, 0, cy + h + 18)
                else
                    t.box.Visible=false; t.name.Visible=false; t.hp.Visible=false; t.dist.Visible=false
                end
            end
        end
    end
    for m,_ in pairs(ESP) do
        if not seen[m] or not m.Parent then destroyESP(m) end
    end
end

print("[vanta] part 3 OK")-- ============================================================
-- vanta v9.0 · ЧАСТЬ 4/8 — aim + silent + trigger
-- ============================================================

local aimHeld = false
local trigHeld = false
local lastShot = 0
local silentTarget = nil

local function getAimTarget(fov)
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local best, bestD = nil, math.huge
    for _, model in ipairs(getTargets()) do
        if isAlive(model) and not (Config.Aim.TeamCheck and sameTeam(model)) then
            local target = partPos(model, Config.Aim.Part)
            if target then
                local screen = w2s(target)
                if screen then
                    local d = (screen - center).Magnitude
                    if d <= fov and d < bestD then
                        if not Config.Aim.Visible or isVisible(model, Config.Aim.Part) then
                            best, bestD = model, d
                        end
                    end
                end
            end
        end
    end
    return best
end

local function updateAim()
    if not Config.Aim.Enabled or not aimHeld then return end
    if not isAlive(LocalPlayer.Character) then return end
    local target = getAimTarget(Config.Aim.FOV)
    if not target then return end
    local pos = partPos(target, Config.Aim.Part)
    if not pos then return end
    local screen = w2s(pos)
    if not screen then return end
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local delta = (screen - center) * Config.Aim.Smooth
    if math.abs(delta.X) < 1 and math.abs(delta.Y) < 1 then return end
    if mousemoverel then mousemoverel(delta.X, delta.Y) end
end

local function getSilentTarget()
    local camPos = Camera.CFrame.Position
    local best, bestD = nil, math.huge
    for _, model in ipairs(getTargets()) do
        if isAlive(model) and not (Config.Silent.TeamCheck and sameTeam(model)) then
            local head = getHead(model)
            if head then
                local d = (camPos - head.Position).Magnitude
                if d < bestD and isVisible(model, "Head") then best, bestD = model, d end
            end
        end
    end
    return best
end

local function updateSilent()
    if not Config.Silent.Enabled then silentTarget = nil; return end
    silentTarget = getSilentTarget()
end

if hookmetamethod and getrawmetatable and setreadonly and newcclosure then
    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if Config.Silent.Enabled and silentTarget and method == "FireServer" then
                local args = {...}
                local head = getHead(silentTarget)
                if head then
                    local modified = false
                    for i = 1, #args do
                        if typeof(args[i]) == "Vector3" then
                            args[i] = head.Position
                            modified = true
                        end
                    end
                    if modified then
                        if math.random(1,100) <= Config.Silent.HitChance then
                            return old(self, table.unpack(args))
                        end
                        return nil
                    end
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

local function safeClick()
    if mouse1click then pcall(mouse1click) end
end

local function updateTrigger()
    if not Config.Trigger.Enabled or not trigHeld then return end
    if tick() - lastShot < Config.Trigger.Delay then return end
    if not isAlive(LocalPlayer.Character) then return end
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    for _, model in ipairs(getTargets()) do
        if isAlive(model) and not (Config.Trigger.TeamCheck and sameTeam(model)) then
            local head = getHead(model)
            if head then
                local screen = w2s(head.Position)
                if screen and (screen - center).Magnitude < 40 then
                    if not Config.Trigger.WallCheck or isVisible(model, "Head") then
                        safeClick()
                        lastShot = tick()
                        return
                    end
                end
            end
        end
    end
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == Config.Aim.Key then aimHeld = true end
    if i.UserInputType == Config.Trigger.Key then trigHeld = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Config.Aim.Key then aimHeld = false end
    if i.UserInputType == Config.Trigger.Key then trigHeld = false end
end)

print("[vanta] part 4 OK")-- ============================================================
-- vanta v9.0 · ЧАСТЬ 5/8 — move + zeus + ammo + visual
-- ============================================================

local function updateMove()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if Config.Move.Speed then
        hum.WalkSpeed = Config.Move.SpeedVal
    elseif hum.WalkSpeed ~= origWalkSpeed then
        hum.WalkSpeed = origWalkSpeed
    end

    if Config.Move.Fly then
        hum.PlatformStand = true
        local dir = Vector3.zero
        local camCF = Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then
            hrp.Velocity = dir.Unit * Config.Move.FlySpeed
        else
            hrp.Velocity = Vector3.zero
        end
    elseif hum.PlatformStand then
        hum.PlatformStand = false
    end
end

UIS.JumpRequest:Connect(function()
    if Config.Move.InfJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local function updateNoclip()
    if not Config.Move.Noclip then return end
    local c = LocalPlayer.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.Collide = false; p.CanCollide = false end
    end
end

local zeusSaved = nil
local function updateZeus()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Config.Zeus.Enabled then
        if not zeusSaved then zeusSaved = { MaxHealth = hum.MaxHealth } end
        hum.MaxHealth = Config.Zeus.MaxHealth
        if hum.Health < hum.MaxHealth then
            hum.Health = math.min(hum.MaxHealth, hum.Health + Config.Zeus.RegenSpeed)
        end
    elseif zeusSaved then
        hum.MaxHealth = zeusSaved.MaxHealth
        if hum.Health > zeusSaved.MaxHealth then hum.Health = zeusSaved.MaxHealth end
        zeusSaved = nil
    end
end

local function updateAmmo()
    if not Config.Ammo.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function()
                if tool:FindFirstChild("Ammo") then tool.Ammo.Value = Config.Ammo.AmmoValue end
            end)
            pcall(function()
                if tool:GetAttribute("Ammo") ~= nil then tool:SetAttribute("Ammo", Config.Ammo.AmmoValue) end
            end)
        end
    end
end

local function updateVis()
    if Config.Vis.Fullbright then
        game:GetService("Lighting").Ambient = Color3.fromRGB(178,178,178)
        game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(178,178,178)
        game:GetService("Lighting").Brightness = 2
    end
    if Config.Vis.NoFog then
        game:GetService("Lighting").FogEnd = 1e6
    end
    Camera.FieldOfView = Config.Vis.FOV
end

print("[vanta] part 5 OK")-- ============================================================
-- vanta v9.0 · ЧАСТЬ 6/8 — меню
-- ============================================================

getgenv().vanta_create_menu = function()

if getgenv().vanta_menu and getgenv().vanta_menu.Parent then getgenv().vanta_menu:Destroy() end

local A = {
    bg      = Color3.fromRGB(18, 12, 28),
    panel   = Color3.fromRGB(38, 28, 58),
    panelHi = Color3.fromRGB(52, 38, 80),
    accent  = Color3.fromRGB(180, 130, 255),
    accent2 = Color3.fromRGB(220, 150, 255),
    accentD = Color3.fromRGB(110, 70, 190),
    text    = Color3.fromRGB(235, 225, 250),
    textDim = Color3.fromRGB(170, 155, 200),
}

local function tweenQuad(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local sg = Instance.new("ScreenGui")
sg.Name = "vanta_menu"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999
sg.Parent = (gethui and gethui()) or CoreGui
getgenv().vanta_menu = sg

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 500, 0, 520)
win.Position = UDim2.new(0, 80, 0, 100)
win.BackgroundColor3 = A.bg
win.BackgroundTransparency = 0.22
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.ClipsDescendants = true
win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 18)

local ws = Instance.new("UIStroke")
ws.Color = A.accent
ws.Thickness = 1.4
ws.Transparency = 0.3
ws.Parent = win
local wg = Instance.new("UIGradient")
wg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(140,90,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220,150,255))})
wg.Rotation = 35
wg.Parent = ws

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 44)
bar.BackgroundTransparency = 1
bar.Parent = win

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "vanta · v9.0"
title.TextColor3 = A.accent
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -66, 0, 8)
minBtn.BackgroundColor3 = A.panel
minBtn.Text = "—"
minBtn.TextColor3 = A.textDim
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.BorderSizePixel = 0
minBtn.AutoButtonColor = false
minBtn.Parent = bar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 32)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local tabBar = Instance.new("ScrollingFrame")
tabBar.Size = UDim2.new(1, -16, 0, 32)
tabBar.Position = UDim2.new(0, 8, 0, 46)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 2
tabBar.ScrollBarImageColor3 = A.accent
tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.Parent = win

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -88)
content.Position = UDim2.new(0, 8, 0, 82)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = win

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = A.accent
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.Active = true
scroll.Selectable = true
scroll.Parent = content

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 12)
pad.Parent = scroll

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    tabBar.Visible = not minimized
    tweenQuad(win, 0.25, { Size = minimized and UDim2.new(0, 500, 0, 50) or UDim2.new(0, 500, 0, 520) })
    minBtn.Text = minimized and "+" or "—"
end)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy(); getgenv().vanta_menu = nil end)

local function section(text)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, -10, 0, 22)
    h.BackgroundTransparency = 1
    h.Text = "  " .. text
    h.TextColor3 = A.accent
    h.Font = Enum.Font.GothamBold
    h.TextSize = 12
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Parent = scroll
end

local function toggle(label, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 34)
    row.BackgroundColor3 = A.panel
    row.BackgroundTransparency = 0.5
    row.BorderSizePixel = 0
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.8; s.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = A.text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0, 46, 0, 24)
    sw.Position = UDim2.new(1, -58, 0.5, -12)
    sw.BackgroundColor3 = get() and A.accentD or Color3.fromRGB(45,35,65)
    sw.BorderSizePixel = 0
    sw.Parent = row
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = get() and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = get() and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,190)
    knob.BorderSizePixel = 0
    knob.Parent = sw
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local click = Instance.new("TextButton")
    click.Size = UDim2.new(1, 0, 1, 0)
    click.BackgroundTransparency = 1
    click.Text = ""
    click.AutoButtonColor = false
    click.Parent = sw

    click.MouseButton1Click:Connect(function()
        local nv = not get()
        set(nv)
        tweenQuad(sw, 0.2, { BackgroundColor3 = nv and A.accentD or Color3.fromRGB(45,35,65) })
        tweenQuad(knob, 0.2, {
            Position = nv and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
            BackgroundColor3 = nv and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,190),
        })
    end)
end

local function slider(label, minV, maxV, get, set, fmt)
    fmt = fmt or "%d"
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 48)
    row.BackgroundColor3 = A.panel
    row.BackgroundTransparency = 0.5
    row.BorderSizePixel = 0
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.8; s.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -120, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = A.text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 100, 0, 20)
    val.Position = UDim2.new(1, -112, 0, 6)
    val.BackgroundTransparency = 1
    val.Text = string.format(fmt, get())
    val.TextColor3 = A.accent2
    val.Font = Enum.Font.GothamBold
    val.TextSize = 13
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(55,42,80)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((get() - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = A.accentD
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 2, 0)
    hit.Position = UDim2.new(0, 0, -0.5, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Parent = track

    local dragging = false
    local function upd(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + (maxV - minV) * rel + 0.5)
        set(v)
        val.Text = string.format(fmt, v)
        fill.Size = UDim2.new(rel, 0, 1, 0)
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; upd(i.Position.X)
        end
    end)
    hit.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            upd(i.Position.X)
        end
    end)
end

local function dropdown(label, options, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 34)
    row.BackgroundColor3 = A.panel
    row.BackgroundTransparency = 0.5
    row.BorderSizePixel = 0
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.8; s.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -150, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = A.text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local idx = 1
    for i, o in ipairs(options) do if o == get() then idx = i end end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 22)
    btn.Position = UDim2.new(1, -140, 0, 6)
    btn.BackgroundColor3 = A.accentD
    btn.BackgroundTransparency = 0.3
    btn.Text = options[idx]
    btn.TextColor3 = A.accent2
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        set(options[idx])
    end)
end

local tabButtons = {}
local function setActiveTab(name)
    for n, data in pairs(tabButtons) do
        local active = (n == name)
        tweenQuad(data.btn, 0.18, {
            BackgroundColor3 = active and A.accentD or A.panel,
            TextColor3 = active and Color3.fromRGB(255,255,255) or A.textDim,
            BackgroundTransparency = active and 0 or 0.55,
        })
    end
    for _, c in ipairs(scroll:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    scroll.CanvasPosition = Vector2.new(0, 0)
    if tabButtons[name] and tabButtons[name].build then tabButtons[name].build() end
end

local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 74, 1, 0)
    btn.BackgroundColor3 = A.panel
    btn.BackgroundTransparency = 0.55
    btn.Text = name
    btn.TextColor3 = A.textDim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    tabButtons[name] = { btn = btn, build = function() end }
    btn.MouseButton1Click:Connect(function() setActiveTab(name) end)
    return tabButtons[name]
end

local tAim = makeTab("aim")
tAim.build = function()
    section("AIMBOT")
    toggle("aimbot", function() return Config.Aim.Enabled end, function(v) Config.Aim.Enabled = v end)
    slider("fov", 10, 400, function() return Config.Aim.FOV end, function(v) Config.Aim.FOV = v end)
    slider("smooth %", 5, 100, function() return math.floor(Config.Aim.Smooth*100) end, function(v) Config.Aim.Smooth = v/100 end)
    toggle("wall check", function() return Config.Aim.WallCheck end, function(v) Config.Aim.WallCheck = v end)
    toggle("team check", function() return Config.Aim.TeamCheck end, function(v) Config.Aim.TeamCheck = v end)
    dropdown("hit part", {"Head","HumanoidRootPart","UpperTorso"}, function() return Config.Aim.Part end, function(v) Config.Aim.Part = v end)
    section("SILENT AIM")
    toggle("silent aim", function() return Config.Silent.Enabled end, function(v) Config.Silent.Enabled = v end)
    slider("hit chance %", 10, 100, function() return Config.Silent.HitChance end, function(v) Config.Silent.HitChance = v end)
    toggle("team check", function() return Config.Silent.TeamCheck end, function(v) Config.Silent.TeamCheck = v end)
    section("TRIGGERBOT")
    toggle("triggerbot", function() return Config.Trigger.Enabled end, function(v) Config.Trigger.Enabled = v end)
    slider("delay ms", 20, 250, function() return math.floor(Config.Trigger.Delay*1000) end, function(v) Config.Trigger.Delay = v/1000 end)
    toggle("wall check", function() return Config.Trigger.WallCheck end, function(v) Config.Trigger.WallCheck = v end)
    toggle("team check", function() return Config.Trigger.TeamCheck end, function(v) Config.Trigger.TeamCheck = v end)
end

local tEsp = makeTab("esp")
tEsp.build = function()
    section("ESP")
    toggle("esp enable", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled = v end)
    toggle("box", function() return Config.ESP.Box end, function(v) Config.ESP.Box = v end)
    toggle("name", function() return Config.ESP.Name end, function(v) Config.ESP.Name = v end)
    toggle("health", function() return Config.ESP.Health end, function(v) Config.ESP.Health = v end)
    toggle("distance", function() return Config.ESP.Distance end, function(v) Config.ESP.Distance = v end)
    toggle("team check", function() return Config.ESP.TeamCheck end, function(v) Config.ESP.TeamCheck = v end)
    slider("max distance", 50, 3000, function() return Config.ESP.MaxDist end, function(v) Config.ESP.MaxDist = v end)
end

local tMove = makeTab("move")
tMove.build = function()
    section("SPEED")
    toggle("speed", function() return Config.Move.Speed end, function(v) Config.Move.Speed = v end)
    slider("speed value", 16, 200, function() return Config.Move.SpeedVal end, function(v) Config.Move.SpeedVal = v end)
    section("FLY")
    toggle("fly", function() return Config.Move.Fly end, function(v) Config.Move.Fly = v end)
    slider("fly speed", 10, 200, function() return Config.Move.FlySpeed end, function(v) Config.Move.FlySpeed = v end)
    section("OTHER")
    toggle("infinite jump", function() return Config.Move.InfJump end, function(v) Config.Move.InfJump = v end)
    toggle("noclip", function() return Config.Move.Noclip end, function(v) Config.Move.Noclip = v end)
end

local tMisc = makeTab("misc")
tMisc.build = function()
    section("ZEUS MODE")
    toggle("zeus enable", function() return Config.Zeus.Enabled end, function(v) Config.Zeus.Enabled = v end)
    slider("max health", 100, 5000, function() return Config.Zeus.MaxHealth end, function(v) Config.Zeus.MaxHealth = v end)
    section("AMMO")
    toggle("inf ammo", function() return Config.Ammo.Enabled end, function(v) Config.Ammo.Enabled = v end)
    slider("ammo value", 100, 9999, function() return Config.Ammo.AmmoValue end, function(v) Config.Ammo.AmmoValue = v end)
    section("VISUAL")
    toggle("fullbright", function() return Config.Vis.Fullbright end, function(v) Config.Vis.Fullbright = v end)
    toggle("no fog", function() return Config.Vis.NoFog end, function(v) Config.Vis.NoFog = v end)
    slider("camera fov", 60, 120, function() return Config.Vis.FOV end, function(v) Config.Vis.FOV = v end)
end

setActiveTab("aim")
print("[vanta] part 6 OK · menu ready")
end-- ============================================================
-- vanta v9.0 · ЧАСТЬ 7/8 — keygate UI
-- ============================================================

local function tweenQuad(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local accent = Color3.fromRGB(180, 130, 255)

local function showKeygate(onSuccess, message)
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("vanta_keygui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "vanta_keygui"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2000
    sg.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 340)
    frame.Position = UDim2.new(0.5, -190, 0.5, -170)
    frame.BackgroundColor3 = Color3.fromRGB(18,12,28)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 18)

    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Thickness = 1.4
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 52)
    title.BackgroundTransparency = 1
    title.Text = "VANTA"
    title.TextColor3 = accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 18)
    sub.Position = UDim2.new(0, 0, 0, 50)
    sub.BackgroundTransparency = 1
    sub.Text = "введите ключ доступа"
    sub.TextColor3 = Color3.fromRGB(180,160,220)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -40, 0, 44)
    box.Position = UDim2.new(0, 20, 0, 84)
    box.BackgroundColor3 = Color3.fromRGB(38,28,58)
    box.BackgroundTransparency = 0.3
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = "ключ..."
    box.TextColor3 = Color3.fromRGB(235,225,250)
    box.PlaceholderColor3 = Color3.fromRGB(140,120,180)
    box.Font = Enum.Font.Gotham
    box.TextSize = 15
    box.ClearTextOnFocus = false
    box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 44)
    btn.Position = UDim2.new(0, 20, 0, 142)
    btn.BackgroundColor3 = Color3.fromRGB(120,75,200)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Text = "войти"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.AutoButtonColor = false
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local tgBtn = Instance.new("TextButton")
    tgBtn.Size = UDim2.new(1, -40, 0, 40)
    tgBtn.Position = UDim2.new(0, 20, 0, 198)
    tgBtn.BackgroundColor3 = Color3.fromRGB(30,90,140)
    tgBtn.BackgroundTransparency = 0.15
    tgBtn.BorderSizePixel = 0
    tgBtn.Text = "получить ключ · @noir_xis"
    tgBtn.TextColor3 = Color3.fromRGB(255,255,255)
    tgBtn.Font = Enum.Font.GothamBold
    tgBtn.TextSize = 14
    tgBtn.AutoButtonColor = false
    tgBtn.Parent = frame
    Instance.new("UICorner", tgBtn).CornerRadius = UDim.new(0, 10)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 16)
    status.Position = UDim2.new(0, 0, 0, 246)
    status.BackgroundTransparency = 1
    status.Text = message or ""
    status.TextColor3 = Color3.fromRGB(255,120,140)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.Parent = frame

    local timerLbl = Instance.new("TextLabel")
    timerLbl.Size = UDim2.new(1, 0, 0, 14)
    timerLbl.Position = UDim2.new(0, 0, 0, 264)
    timerLbl.BackgroundTransparency = 1
    timerLbl.Text = ""
    timerLbl.TextColor3 = Color3.fromRGB(200,180,240)
    timerLbl.Font = Enum.Font.Gotham
    timerLbl.TextSize = 11
    timerLbl.Parent = frame

    tgBtn.MouseButton1Click:Connect(function()
        if setclipboard then pcall(function() setclipboard(TG_LINK) end) end
        tgBtn.Text = "скопировано · " .. TG_LINK
        task.wait(2.5)
        tgBtn.Text = "получить ключ · @noir_xis"
    end)

    local function try()
        local entered = (box.Text:gsub("%s",""))
        if entered == "" then return end
        status.TextColor3 = Color3.fromRGB(180,180,220)
        status.Text = "проверка..."
        btn.Text = "..."
        btn.Active = false
        local ok, left = checkKeyOnServer(entered)
        btn.Active = true
        btn.Text = "войти"
        if not ok then
            status.TextColor3 = Color3.fromRGB(255,120,140)
            status.Text = left
            box.Text = ""
            return
        end
        active_key = entered
        status.TextColor3 = Color3.fromRGB(180,255,180)
        status.Text = "доступ разрешён"
        timerLbl.Text = "осталось: " .. math.floor(left/86400) .. " дн."
        task.wait(1.2)
        sg:Destroy()
        onSuccess()
    end

    btn.MouseButton1Click:Connect(try)
    box.FocusLost:Connect(function(enter) if enter then try() end end)
end

print("[vanta] part 7 OK")-- ============================================================
-- vanta v9.0 · ЧАСТЬ 8/8 — main loop + bootstrap
-- ============================================================

local renderAccum = 0
RunService.RenderStepped:Connect(function(dt)
    pcall(updateAim)
    pcall(updateSilent)
    pcall(updateTrigger)
    pcall(updateMove)
    pcall(updateNoclip)
    pcall(updateZeus)
    pcall(updateAmmo)
    pcall(updateVis)

    renderAccum += dt
    if renderAccum < 1/60 then return end
    renderAccum = 0
    pcall(renderESP)
end)

-- при истечении ключа — вырубаем всё и снова показываем keygate
task.spawn(function()
    while task.wait(60) do
        if active_key then
            local ok = checkKeyOnServer(active_key)
            if not ok then
                active_key = nil
                disableAll()
                showKeygate(function()
                    if getgenv().vanta_create_menu then getgenv().vanta_create_menu() end
                end, "срок действия ключа истёк")
                break
            end
        end
    end
end)

-- показываем keygate при старте
showKeygate(function()
    if getgenv().vanta_create_menu then getgenv().vanta_create_menu() end
end)

print("[vanta] v9.0 loaded · " .. SERVER_URL)