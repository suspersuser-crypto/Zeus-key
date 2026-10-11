-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 1/9
-- services + config + logger + hwid + keygate core
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Stats        = game:GetService("Stats")

local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

local SERVER_URL = "https://zeus-key-mjep.onrender.com/check"
local TG_LINK    = "https://t.me/noir_xis"

-- ============================================================
-- CONFIG
-- ============================================================

local Config = {
    Aim = {
        Enabled       = false,
        FOV           = 120,
        Smooth        = 0.35,
        FastSmooth    = 0.9,
        Key           = Enum.UserInputType.MouseButton2,
        FastKey       = Enum.KeyCode.LeftShift,
        Visible       = true,
        StrictTeam    = true,
        FriendCheck   = true,
        Part          = "auto",
        Mode          = "camera",
        Prediction    = false,
        PredictionStrength = 0.5,
        IgnoreDying   = true,
        DyingHpPct    = 15,
        TargetLockMs  = 180,
        Curve         = true,
        FovCircle     = false,
    },
    Silent = {
        Enabled         = false,
        HitChance       = 100,
        StrictTeam      = true,
        FriendCheck     = true,
        RequireVisible  = false,
        Part            = "auto",
        FreezeMs        = 200,
        PerShotCooldownMs = 30,
        SubstitutionMode = "all",
    },
    ESP = {
        Enabled       = false,
        Box           = true,
        Name          = true,
        Health        = true,
        Distance      = true,
        Tracer        = false,
        HeadDot       = false,
        Skeleton      = false,
        Chams         = false,
        OffScreen     = false,
        StrictTeam    = true,
        FriendCheck   = true,
        ShowTeammates = false,
        MaxDist       = 3000,
        HpFormat      = "hp",
        TracerStyle   = "bottom",
        BoxColor      = Color3.fromRGB(170,120,255),
        SkeletonColor = Color3.fromRGB(220,180,255),
        ChamsColor    = Color3.fromRGB(255,80,80),
        DistanceColor = true,
        InterpSpeed   = 1.0,
    },
    Team = {
        Friends   = {},
        Whitelist = {},
    },
    Misc = {
        Watermark  = true,
        PanicKey   = Enum.KeyCode.End,
    },
    Key = {
        Active = nil,
        Expiry = 0,
    },
}

getgenv().zeusx_cfg = Config

local function log(tag, ...)
    local parts = {...}
    local msg = "[zeusx-lite][" .. tostring(tag) .. "]"
    for _, v in ipairs(parts) do msg = msg .. " " .. tostring(v) end
    pcall(print, msg)
end
getgenv().zeusx_log = log

-- ============================================================
-- HWID
-- ============================================================

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
getgenv().zeusx_getHWID = getHWID

-- ============================================================
-- KEYGATE CORE
-- ============================================================

local function checkKeyOnServer(key)
    local hwid = getHWID()
    local username = LocalPlayer.Name
    local url = SERVER_URL .. "?token=" .. key .. "&hwid=" .. hwid .. "&username=" .. username
    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not response or response == "" then return nil, "нет соединения" end
    local okDecode, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not okDecode or type(data) ~= "table" then return nil, "ошибка формата" end
    if data.ok then return true, data.left or 0, data end
    local reasons = {
        invalid="неверный ключ",
        hwid_mismatch="ключ на другом устройстве",
        expired="срок истёк",
        banned="ключ забанен",
        no_activations="активации кончились",
        too_many_attempts="слишком много попыток",
    }
    return false, reasons[data.reason] or (data.reason or "ошибка"), data
end
getgenv().zeusx_checkKey = checkKeyOnServer

local active_key = nil
getgenv().zeusx_set_key = function(k) active_key = k; Config.Key.Active = k end
getgenv().zeusx_get_key = function() return active_key end

task.spawn(function()
    while task.wait(60) do
        if not active_key then continue end
        local ok, msg = checkKeyOnServer(active_key)
        if ok == false then
            active_key = nil
            Config.Key.Active = nil
            log("key", "revoked:", msg)
            if getgenv().zeusx_disableAll then getgenv().zeusx_disableAll() end
            if getgenv().zeusx_show_keygate then
                getgenv().zeusx_show_keygate(getgenv().zeusx_on_success, tostring(msg))
            end
            break
        elseif ok == true then
            Config.Key.Expiry = os.time() + (tonumber(msg) or 0)
        end
    end
end)

getgenv().zeusx_log("part", "1/9 OK")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 2/9
-- team detection (3 источника) + сбор целей
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Config      = getgenv().zeusx_cfg

local teamCache = {}
task.spawn(function() while task.wait(5) do teamCache = {} end end)

local IGNORE_NAMES = { TheMlgShep=true, R15_Dummy=true, Dummy=true }

local function hasParts(m)
    if not m or not m.Parent or not m:IsA("Model") then return false end
    return m:FindFirstChildOfClass("Humanoid")
       and m:FindFirstChild("Head", true)
       and m:FindFirstChild("HumanoidRootPart", true)
end

local function isGarbage(m)
    if not hasParts(m) then return true end
    if m == LocalPlayer.Character then return true end
    if IGNORE_NAMES[m.Name] then return true end
    local h = m:FindFirstChildOfClass("Humanoid")
    if not h then return true end
    if h.MaxHealth == math.huge or h.MaxHealth <= 0 or h.MaxHealth > 1e6 then return true end
    return false
end

local WS_CONTAINERS = {
    "Characters","Entities","Actors","Players","Living","Units","Combatants",
    "Fighters","Dummies","Bots","Enemies","Mobs","Monsters","NPCs","Pool","Active",
    "Zombies","Targets","AIs",
}

local function collectPlayers()
    local l = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and not isGarbage(p.Character) then
            table.insert(l, p.Character)
        end
    end
    return l
end

local function collectWorkspace()
    local l = {}
    for _, m in ipairs(Workspace:GetChildren()) do
        if not isGarbage(m) then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then table.insert(l, m) end
        end
    end
    for _, name in ipairs(WS_CONTAINERS) do
        local f = Workspace:FindFirstChild(name)
        if f then
            for _, m in ipairs(f:GetChildren()) do
                if not isGarbage(m) then
                    local h = m:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then table.insert(l, m) end
                end
            end
        end
    end
    return l
end

local scanMode = "players"
task.spawn(function()
    while task.wait(2) do
        local nP = #collectPlayers()
        local nW = #collectWorkspace()
        if nP >= nW and nP > 0 then scanMode = "players"
        elseif nW > nP then scanMode = "workspace" end
    end
end)

local function getTargets()
    if scanMode == "workspace" then return collectWorkspace()
    else return collectPlayers() end
end

local function getHumanoid(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function getHead(m)     return m and m:FindFirstChild("Head", true) end
local function getRoot(m)     return m and m:FindFirstChild("HumanoidRootPart", true) end

local function isAlive(m)
    local h = getHumanoid(m)
    if h then return h.Health > 0 end
    return getHead(m) ~= nil
end

local function partPos(m, p)
    if p == "Head" then local x = getHead(m); return x and x.Position end
    if p == "HumanoidRootPart" then local x = getRoot(m); return x and x.Position end
    local x = m:FindFirstChild(p, true); return x and x.Position
end

local function resolvePart(m, requested)
    if requested ~= "auto" then return requested end
    if getHead(m) then return "Head" end
    if getRoot(m) then return "HumanoidRootPart" end
    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then return p.Name end
    end
    return "Head"
end

local function w2s(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y), sp.Z
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(m, p)
    local part = resolvePart(m, p or "auto")
    local t = partPos(m, part)
    if not t then return false end
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    local hit = Workspace:Raycast(Camera.CFrame.Position, t - Camera.CFrame.Position, rayParams)
    if not hit then return true end
    return hit.Instance and hit.Instance:IsDescendantOf(m)
end

local function getPlayerOf(m)
    local plr = Players:FindFirstChild(m.Name)
    if plr then return plr end
    local uid = m:GetAttribute("UserId") or m:GetAttribute("OwnerId")
    if uid then
        for _, p in ipairs(Players:GetPlayers()) do
            if tostring(p.UserId) == tostring(uid) then return p end
        end
    end
    return nil
end

local function resolveTeamStrict(o)
    if not o then return nil end
    if o:IsA("Player") then
        if o.Team then return "T:" .. tostring(o.Team) end
        if o.TeamColor then return "C:" .. tostring(o.TeamColor) end
        local a = o:GetAttribute("Team") or o:GetAttribute("TeamId")
              or o:GetAttribute("TeamName") or o:GetAttribute("team")
        if a then return "A:" .. tostring(a) end
    end
    if o:IsA("Model") then
        local a = o:GetAttribute("Team") or o:GetAttribute("TeamId")
              or o:GetAttribute("TeamName") or o:GetAttribute("team")
        if a then return "A:" .. tostring(a) end
    end
    return nil
end

local function resolveTeamSoft(o)
    if not o then return nil end
    if o:IsA("Player") and o.Team then return "T:" .. tostring(o.Team) end
    return nil
end

local function getMyTeamId(strict)
    return strict and resolveTeamStrict(LocalPlayer) or resolveTeamSoft(LocalPlayer)
end

local function getTargetTeamId(m, strict)
    local key = m.Name .. (strict and ":s" or ":w")
    if teamCache[key] ~= nil then return teamCache[key] end
    local plr = getPlayerOf(m)
    local t = strict
        and ((plr and resolveTeamStrict(plr)) or resolveTeamStrict(m))
        or ((plr and resolveTeamSoft(plr)) or resolveTeamSoft(m))
    teamCache[key] = t
    return t
end

local function isSameTeam(m, strict)
    if m.Name == LocalPlayer.Name then return true end
    local a = getMyTeamId(strict)
    local b = getTargetTeamId(m, strict)
    if a == nil or b == nil then return false end
    return a == b
end

local function isFriend(m)
    local plr = getPlayerOf(m)
    if not plr then return false end
    for _, f in ipairs(Config.Team.Friends) do
        if tostring(f) == tostring(plr.UserId) then return true end
    end
    return false
end

local function inList(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

local function shouldIgnore(m, opts)
    opts = opts or {}
    if not m then return true end
    if m == LocalPlayer.Character then return true end
    if inList(Config.Team.Whitelist, m.Name) then return true end
    if opts.FriendCheck ~= false and isFriend(m) then return true end
    local strict = (opts.StrictTeam ~= false)
    if isSameTeam(m, strict) then
        if opts.ShowTeammates then return false end
        return true
    end
    return false
end

task.spawn(function()
    pcall(function()
        if not LocalPlayer.GetFriendsAsync then return end
        local page = LocalPlayer:GetFriendsAsync()
        while true do
            for _, f in ipairs(page:GetCurrentPage()) do
                table.insert(Config.Team.Friends, f.Id)
            end
            if page.IsFinished then break end
            page:AdvanceToNextPageAsync()
        end
    end)
end)

getgenv().zeusx_h = {
    getTargets = getTargets,
    getHumanoid = getHumanoid,
    getHead = getHead,
    getRoot = getRoot,
    isAlive = isAlive,
    partPos = partPos,
    resolvePart = resolvePart,
    w2s = w2s,
    isVisible = isVisible,
    shouldIgnore = shouldIgnore,
    isFriend = isFriend,
    isSameTeam = isSameTeam,
    getPlayerOf = getPlayerOf,
}

getgenv().zeusx_log("part", "2/9 OK")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 3/9
-- AIM (aimbot) — стабильный, prediction, curve, target lock
-- ============================================================

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local CoreGui     = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Config      = getgenv().zeusx_cfg
local H           = getgenv().zeusx_h

local aimHeld = false
local fastHeld = false
local lockedTarget, lockedAt = nil, 0

local function getRootVelocity(model)
    local hrp = H.getRoot(model)
    if not hrp then return Vector3.zero end
    local ok, v = pcall(function() return hrp.AssemblyLinearVelocity or hrp.Velocity end)
    if ok and v then return v end
    return Vector3.zero
end

local function predictPos(model, basePos, strength)
    if not strength or strength == 0 then return basePos end
    local v = getRootVelocity(model)
    local camPos = Camera.CFrame.Position
    local dist = (camPos - basePos).Magnitude
    local t = dist / 200 * strength
    return basePos + v * t
end

local function aimIgnore(m)
    return H.shouldIgnore(m, {
        StrictTeam  = Config.Aim.StrictTeam,
        FriendCheck = Config.Aim.FriendCheck,
    })
end

local function dyingCheck(m)
    if not Config.Aim.IgnoreDying then return true end
    local hum = H.getHumanoid(m)
    if not hum then return true end
    local pct = hum.Health / math.max(hum.MaxHealth, 1) * 100
    return pct > Config.Aim.DyingHpPct
end

local function scoreTargetAim(m, fov, camPos, center)
    if not H.isAlive(m) then return nil end
    if aimIgnore(m) then return nil end
    if not dyingCheck(m) then return nil end
    local part = H.resolvePart(m, Config.Aim.Part)
    local pos = H.partPos(m, part)
    if not pos then return nil end
    if Config.Aim.Prediction then
        pos = predictPos(m, pos, Config.Aim.PredictionStrength)
    end
    local screen = H.w2s(pos)
    if not screen then return nil end
    local pxD = (screen - center).Magnitude
    if pxD > fov then return nil end
    if Config.Aim.Visible and not H.isVisible(m, part) then return nil end
    local worldD = (camPos - pos).Magnitude
    local score = pxD + worldD * 0.05
    return score, m, pos
end

local function pickAimTarget()
    local now = tick()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)

    if lockedTarget and (now - lockedAt) * 1000 < Config.Aim.TargetLockMs then
        if H.isAlive(lockedTarget) and not aimIgnore(lockedTarget) then
            local part = H.resolvePart(lockedTarget, Config.Aim.Part)
            local pos = H.partPos(lockedTarget, part)
            if pos then
                if Config.Aim.Prediction then
                    pos = predictPos(lockedTarget, pos, Config.Aim.PredictionStrength)
                end
                local screen = H.w2s(pos)
                if screen and (screen - center).Magnitude <= Config.Aim.FOV * 1.3 then
                    return lockedTarget, pos
                end
            end
        end
        lockedTarget = nil
    end

    local best, bestScore, bestPos = nil, math.huge, nil
    for _, m in ipairs(H.getTargets()) do
        local s, mm, pp = scoreTargetAim(m, Config.Aim.FOV, camPos, center)
        if s and s < bestScore then best, bestScore, bestPos = mm, s, pp end
    end

    if best then lockedTarget = best; lockedAt = now end
    return best, bestPos
end

local function aimAt(pos)
    if Config.Aim.Mode == "camera" then
        local camCF = Camera.CFrame
        local newCF = CFrame.new(camCF.Position, pos)
        local baseSmooth = fastHeld and Config.Aim.FastSmooth or Config.Aim.Smooth
        local alpha = math.clamp(baseSmooth, 0.02, 1)
        if Config.Aim.Curve then
            local currentDir = camCF.LookVector
            local targetDir = (pos - camCF.Position).Unit
            local dot = currentDir:Dot(targetDir)
            local angleFactor = math.clamp(1 - dot, 0, 1)
            alpha = alpha * (0.4 + angleFactor * 1.2)
            alpha = math.clamp(alpha, 0.02, 0.95)
        end
        Camera.CFrame = camCF:Lerp(newCF, alpha)
    else
        local screen = H.w2s(pos)
        if not screen then return end
        local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
        local baseSmooth = fastHeld and Config.Aim.FastSmooth or Config.Aim.Smooth
        local delta = (screen - center) * math.clamp(baseSmooth, 0.05, 1)
        if math.abs(delta.X) < 1 and math.abs(delta.Y) < 1 then return end
        if mousemoverel then mousemoverel(delta.X, delta.Y) end
    end
end

local function updateAim()
    if not Config.Aim.Enabled or not aimHeld then return end
    if not H.isAlive(LocalPlayer.Character) then return end
    local target, pos = pickAimTarget()
    if not target or not pos then return end
    aimAt(pos)
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == Config.Aim.Key then aimHeld = true end
    if i.KeyCode == Config.Aim.FastKey then fastHeld = true end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Config.Aim.Key then aimHeld = false end
    if i.KeyCode == Config.Aim.FastKey then fastHeld = false end
end)

-- FOV circle
local fovCircle
local function updateFovCircle()
    if not Config.Aim.FovCircle or not Config.Aim.Enabled then
        if fovCircle then fovCircle.Visible = false end
        return
    end
    local parent = (gethui and gethui()) or CoreGui
    if not fovCircle then
        local sg = parent:FindFirstChild("zeusx_fovcircle")
        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "zeusx_fovcircle"; sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true; sg.DisplayOrder = 999
            sg.Parent = parent
        end
        fovCircle = Instance.new("Frame")
        fovCircle.BackgroundTransparency = 1
        fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
        fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        fovCircle.Parent = sg
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(180,130,255); s.Thickness = 1.5; s.Transparency = 0.3
        s.Parent = fovCircle
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0); corner.Parent = fovCircle
    end
    fovCircle.Visible = true
    fovCircle.Size = UDim2.new(0, Config.Aim.FOV*2, 0, Config.Aim.FOV*2)
end

getgenv().zeusx_updateAim = updateAim
getgenv().zeusx_updateFovCircle = updateFovCircle
getgenv().zeusx_log("part", "3/9 OK")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 4/9
-- SILENT AIM — hook FireServer, подмена координат
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Config      = getgenv().zeusx_cfg
local H           = getgenv().zeusx_h

local silentTarget, silentFrozenPos = nil, nil
local silentLockedAt = 0

local function silentIgnore(m)
    return H.shouldIgnore(m, {
        StrictTeam  = Config.Silent.StrictTeam,
        FriendCheck = Config.Silent.FriendCheck,
    })
end

local SILENT_PARTS_ORDER = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" }

local function silentPickPart(m)
    if Config.Silent.Part ~= "auto" then
        return H.resolvePart(m, Config.Silent.Part)
    end
    for _, p in ipairs(SILENT_PARTS_ORDER) do
        local part = m:FindFirstChild(p, true)
        if part and part:IsA("BasePart") then
            if not Config.Silent.RequireVisible or H.isVisible(m, p) then
                return p
            end
        end
    end
    return H.resolvePart(m, "auto")
end

local function getSilentTarget()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local best, bestScore, bestPos = nil, math.huge, nil

    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not silentIgnore(m) then
            local part = silentPickPart(m)
            local pos = H.partPos(m, part)
            if pos then
                local visibleOk = true
                if Config.Silent.RequireVisible then visibleOk = H.isVisible(m, part) end
                if visibleOk then
                    local sc = H.w2s(pos)
                    if sc then
                        local pxD = (sc - center).Magnitude
                        local worldD = (camPos - pos).Magnitude
                        local score = pxD + worldD * 0.05
                        if score < bestScore then best, bestScore, bestPos = m, score, pos end
                    end
                end
            end
        end
    end
    return best, bestPos
end

local function updateSilent()
    if not Config.Silent.Enabled then
        silentTarget, silentFrozenPos = nil, nil
        return
    end
    local now = tick()
    if silentTarget and silentFrozenPos and (now - silentLockedAt)*1000 < Config.Silent.FreezeMs then
        if H.isAlive(silentTarget) then return end
    end
    silentTarget, silentFrozenPos = getSilentTarget()
    silentLockedAt = now
end

if hookmetamethod and getrawmetatable and setreadonly and newcclosure then
    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        if not old then return end
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if Config.Silent.Enabled and silentTarget and silentFrozenPos and method == "FireServer" then
                local now = tick()
                if (now - (getgenv()._silent_lastshot or 0))*1000 < Config.Silent.PerShotCooldownMs then
                    return old(self, ...)
                end
                getgenv()._silent_lastshot = now
                local args = {...}
                local mod = false
                for i = 1, #args do
                    if typeof(args[i]) == "Vector3" then
                        if Config.Silent.SubstitutionMode == "all" then
                            args[i] = silentFrozenPos; mod = true
                        else
                            local dCam = (args[i] - Camera.CFrame.Position).Magnitude
                            if dCam > 5 then args[i] = silentFrozenPos; mod = true end
                        end
                    end
                end
                if mod then
                    if math.random(1,100) <= Config.Silent.HitChance then
                        return old(self, table.unpack(args))
                    end
                    return nil
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

getgenv().zeusx_updateSilent = updateSilent
getgenv().zeusx_log("part", "4/9 OK")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 5/9
-- ESP CORE — real-time, zero-lag, интерполяция позиций
-- ============================================================

local CoreGui     = game:GetService("CoreGui")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local Camera      = Workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer
local Config      = getgenv().zeusx_cfg
local H           = getgenv().zeusx_h

local espGui, ESP

local function initESP()
    if espGui then return end
    local parent = (gethui and gethui()) or CoreGui
    espGui = Instance.new("ScreenGui")
    espGui.Name = "zeusx_esp"
    espGui.ResetOnSpawn = false
    espGui.IgnoreGuiInset = true
    espGui.DisplayOrder = 998
    espGui.Parent = parent
    ESP = setmetatable({}, { __mode = "k" })
end

local function mkLabel(color, size)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.fromRGB(255,255,255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = size or 13
    l.TextStrokeTransparency = 0
    l.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    l.Visible = false
    l.Parent = espGui
    return l
end

local function createESP(m)
    if ESP[m] then return end
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false
    box.Parent = espGui
    local stroke = Instance.new("UIStroke")
    stroke.Color = Config.ESP.BoxColor; stroke.Thickness = 1.5; stroke.Parent = box

    local hpBg = Instance.new("Frame")
    hpBg.BackgroundColor3 = Color3.fromRGB(20,10,30)
    hpBg.BorderSizePixel = 0; hpBg.Visible = false; hpBg.Parent = espGui
    local hpFill = Instance.new("Frame")
    hpFill.BackgroundColor3 = Color3.fromRGB(100,220,140)
    hpFill.BorderSizePixel = 0; hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.Parent = hpBg

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = Color3.fromRGB(180,130,255)
    tracer.BackgroundTransparency = 0.4
    tracer.BorderSizePixel = 0; tracer.Visible = false
    tracer.AnchorPoint = Vector2.new(0, 0.5); tracer.Parent = espGui

    local headDot = Instance.new("Frame")
    headDot.BackgroundColor3 = Color3.fromRGB(255,80,80)
    headDot.BorderSizePixel = 0; headDot.Visible = false
    headDot.Size = UDim2.new(0, 6, 0, 6)
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.Parent = espGui
    Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)

    ESP[m] = {
        box=box, stroke=stroke, hpBg=hpBg, hpFill=hpFill, tracer=tracer, headDot=headDot,
        name=mkLabel(Color3.fromRGB(255,255,255), 13),
        hp=mkLabel(Color3.fromRGB(180,255,180), 11),
        dist=mkLabel(Color3.fromRGB(200,200,200), 11),
        -- cached smoothed screen coords
        _sx = nil, _sy = nil, _sw = nil, _sh = nil,
    }
end

local function destroyESP(m)
    local t = ESP[m]; if not t then return end
    for _, o in pairs(t) do
        if typeof(o) == "Instance" then pcall(function() o:Destroy() end) end
    end
    ESP[m] = nil
end

local function hideAll(t)
    t.box.Visible=false; t.name.Visible=false
    t.hp.Visible=false; t.dist.Visible=false
    t.hpBg.Visible=false; t.tracer.Visible=false; t.headDot.Visible=false
end

-- интерполяция координат (smooth, но не отстающая)
local function lerp(a, b, alpha)
    return a + (b - a) * alpha
end

local function renderESP()
    if not espGui then return end
    if not Config.ESP.Enabled then
        for _, t in pairs(ESP) do hideAll(t) end
        return
    end
    local myPos = Camera.CFrame.Position
    local seen = {}
    local interp = math.clamp(Config.ESP.InterpSpeed, 0.3, 1.0)

    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        local t = ESP[m]
        if not t then createESP(m); t = ESP[m] end

        local ignore = H.shouldIgnore(m, {
            StrictTeam    = Config.ESP.StrictTeam,
            FriendCheck   = Config.ESP.FriendCheck,
            ShowTeammates = Config.ESP.ShowTeammates,
        })
        local show = H.isAlive(m) and not ignore
        local root = H.getRoot(m)
        if show and root and (myPos - root.Position).Magnitude > Config.ESP.MaxDist then show = false end
        if not show then hideAll(t); continue end

        local head = H.getHead(m)
        local hum = H.getHumanoid(m)
        if not head or not root then hideAll(t); continue end

        -- берём реальные позиции в этом кадре
        local top = H.w2s(head.Position + Vector3.new(0, 1, 0))
        local bot = H.w2s(root.Position - Vector3.new(0, 3, 0))
        if not top or not bot then hideAll(t); continue end

        -- считаем размеры
        local targetX = top.X
        local targetY = top.Y
        local targetW = (bot.Y - top.Y) * 0.5
        local targetH = bot.Y - top.Y

        -- интерполяция для плавности (устраняет дрожание)
        if t._sx then
            t._sx = lerp(t._sx, targetX, interp)
            t._sy = lerp(t._sy, targetY, interp)
            t._sw = lerp(t._sw, targetW, interp)
            t._sh = lerp(t._sh, targetH, interp)
        else
            t._sx, t._sy, t._sw, t._sh = targetX, targetY, targetW, targetH
        end

        local cx, cy, w, h = t._sx, t._sy, t._sw, t._sh

        local dist = (myPos - root.Position).Magnitude
        local isFriendTgt = H.isFriend(m)

        -- цвет
        if isFriendTgt then
            t.stroke.Color = Color3.fromRGB(120,220,255)
        elseif Config.ESP.DistanceColor then
            local ratio = math.clamp(dist / Config.ESP.MaxDist, 0, 1)
            t.stroke.Color = Color3.new(1, 1 - ratio, 0.3)
        else
            t.stroke.Color = Config.ESP.BoxColor
        end

        t.box.Visible = Config.ESP.Box
        t.box.Size = UDim2.new(0, w, 0, h)
        t.box.Position = UDim2.new(0, cx - w/2, 0, cy)

        t.name.Visible = Config.ESP.Name
        t.name.Text = m.Name
        t.name.TextColor3 = isFriendTgt and Color3.fromRGB(120,220,255) or Color3.fromRGB(255,255,255)
        t.name.Size = UDim2.new(0, 200, 0, 16)
        t.name.Position = UDim2.new(0, cx - 100, 0, cy - 18)

        local hp = hum and hum.Health or 100
        local maxHp = hum and hum.MaxHealth or 100
        local ratio = math.clamp(hp / maxHp, 0, 1)

        t.hpBg.Visible = Config.ESP.Health
        t.hpBg.Size = UDim2.new(0, 3, 0, h)
        t.hpBg.Position = UDim2.new(0, cx - w/2 - 6, 0, cy)
        t.hpFill.Size = UDim2.new(1, 0, ratio, 0)
        t.hpFill.Position = UDim2.new(0, 0, 1 - ratio, 0)
        t.hpFill.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(100,220,140) or Color3.fromRGB(255,120,140)

        t.hp.Visible = Config.ESP.Health
        if Config.ESP.HpFormat == "hp_max" then
            t.hp.Text = math.floor(hp) .. "/" .. math.floor(maxHp)
        elseif Config.ESP.HpFormat == "pct" then
            t.hp.Text = math.floor(ratio*100) .. "%"
        else
            t.hp.Text = math.floor(hp) .. " hp"
        end
        t.hp.Size = UDim2.new(0, 200, 0, 14)
        t.hp.Position = UDim2.new(0, cx - 100, 0, cy + h + 2)

        t.dist.Visible = Config.ESP.Distance
        t.dist.Text = math.floor(dist) .. " m"
        t.dist.Size = UDim2.new(0, 200, 0, 14)
        t.dist.Position = UDim2.new(0, cx - 100, 0, cy + h + 16)

        if Config.ESP.HeadDot then
            local headScr = H.w2s(head.Position)
            if headScr then
                t.headDot.Visible = true
                t.headDot.Position = UDim2.new(0, headScr.X, 0, headScr.Y)
            end
        else t.headDot.Visible = false end

        if Config.ESP.Tracer then
            t.tracer.Visible = true
            local origin
            if Config.ESP.TracerStyle == "top" then
                origin = Vector2.new(Camera.ViewportSize.X*0.5, 0)
            elseif Config.ESP.TracerStyle == "center" then
                origin = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
            else
                origin = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y)
            end
            local to = Vector2.new(cx, cy + h)
            local d = to - origin
            t.tracer.Size = UDim2.new(0, d.Magnitude, 0, 1)
            t.tracer.Position = UDim2.new(0, origin.X, 0, origin.Y)
            t.tracer.Rotation = math.deg(math.atan2(d.Y, d.X))
        else t.tracer.Visible = false end
    end
    for m in pairs(ESP) do
        if not seen[m] or not m.Parent then destroyESP(m) end
    end
end

getgenv().zeusx_initESP = initESP
getgenv().zeusx_renderESP = renderESP
getgenv().zeusx_log("part", "5/9 OK")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 6/9
-- ESP ADVANCED — skeleton (R6 + R15) real-time
-- ============================================================

local CoreGui     = game:GetService("CoreGui")
local Workspace   = game:GetService("Workspace")
local Camera      = Workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer
local Config      = getgenv().zeusx_cfg
local H           = getgenv().zeusx_h

local skelGui, SKEL = nil, nil

local R6_BONES = {
    {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"},
    {"Torso","Left Leg"}, {"Torso","Right Leg"},
}
local R15_BONES = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}

local function initSkeleton()
    if skelGui then return end
    local parent = (gethui and gethui()) or CoreGui
    skelGui = Instance.new("ScreenGui")
    skelGui.Name = "zeusx_skel"; skelGui.ResetOnSpawn = false
    skelGui.IgnoreGuiInset = true; skelGui.DisplayOrder = 997
    skelGui.Parent = parent
    SKEL = setmetatable({}, { __mode = "k" })
end

local function createSkel(m)
    if SKEL[m] then return end
    SKEL[m] = { lines = {} }
end

local function destroySkel(m)
    if not SKEL[m] then return end
    for _, l in ipairs(SKEL[m].lines) do pcall(function() l:Destroy() end) end
    SKEL[m] = nil
end

local function drawLine(a, b, parent)
    if not a or not b then return nil end
    local d = b - a
    local line = Instance.new("Frame")
    line.BackgroundColor3 = Config.ESP.SkeletonColor
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 0.15
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.Size = UDim2.new(0, d.Magnitude, 0, 1)
    line.Position = UDim2.new(0, a.X, 0, a.Y)
    line.Rotation = math.deg(math.atan2(d.Y, d.X))
    line.Visible = true
    line.Parent = parent
    return line
end

local function renderSkeleton()
    if not Config.ESP.Enabled or not Config.ESP.Skeleton then
        if SKEL then for m in pairs(SKEL) do destroySkel(m) end end
        return
    end
    initSkeleton()
    local seen = {}
    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        local ignore = H.shouldIgnore(m, {
            StrictTeam    = Config.ESP.StrictTeam,
            FriendCheck   = Config.ESP.FriendCheck,
            ShowTeammates = Config.ESP.ShowTeammates,
        })
        if not H.isAlive(m) or ignore then
            if SKEL[m] then destroySkel(m) end
            continue
        end
        createSkel(m)
        local data = SKEL[m]
        for _, l in ipairs(data.lines) do l.Visible = false end
        local bones = (m:FindFirstChild("UpperTorso") and R15_BONES) or R6_BONES
        local idx = 1
        for _, pair in ipairs(bones) do
            local a = m:FindFirstChild(pair[1], true)
            local b = m:FindFirstChild(pair[2], true)
            if a and b then
                local sa = H.w2s(a.Position)
                local sb = H.w2s(b.Position)
                if sa and sb then
                    local line = data.lines[idx]
                    if not line then
                        line = drawLine(sa, sb, skelGui)
                        table.insert(data.lines, line)
                    else
                        local d = sb - sa
                        line.Visible = true
                        line.Size = UDim2.new(0, d.Magnitude, 0, 1)
                        line.Position = UDim2.new(0, sa.X, 0, sa.Y)
                        line.Rotation = math.deg(math.atan2(d.Y, d.X))
                    end
                    idx = idx + 1
                end
            end
        end
    end
    for m in pairs(SKEL) do
        if not seen[m] or not m.Parent then destroySkel(m) end
    end
end

getgenv().zeusx_renderSkeleton = renderSkeleton
getgenv().zeusx_log("part", "6/9 OK")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 7/9
-- ESP ADVANCED — chams (Highlight) + off-screen arrows
-- ============================================================

local CoreGui     = game:GetService("CoreGui")
local Workspace   = game:GetService("Workspace")
local Camera      = Workspace.CurrentCamera
local Config      = getgenv().zeusx_cfg
local H           = getgenv().zeusx_h

-- ============================================================
-- CHAMS через Highlight
-- ============================================================

local chamsFolder = nil

local function renderChams()
    if not Config.ESP.Enabled or not Config.ESP.Chams then
        if chamsFolder then
            for _, h in ipairs(chamsFolder:GetChildren()) do h:Destroy() end
        end
        return
    end
    if not chamsFolder then
        chamsFolder = Instance.new("Folder")
        chamsFolder.Name = "zeusx_chams"
        chamsFolder.Parent = (gethui and gethui()) or CoreGui
    end
    local active = {}
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not H.shouldIgnore(m, {
            StrictTeam    = Config.ESP.StrictTeam,
            FriendCheck   = Config.ESP.FriendCheck,
            ShowTeammates = Config.ESP.ShowTeammates,
        }) then
            active[m] = true
            local hl = chamsFolder:FindFirstChild(m.Name)
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = m.Name
                hl.Parent = chamsFolder
            end
            hl.Adornee = m
            hl.FillColor = Config.ESP.ChamsColor
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255,255,255)
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
    for _, h in ipairs(chamsFolder:GetChildren()) do
        if not active[h.Name] then
            h.Adornee = nil
            h:Destroy()
        end
    end
end

-- ============================================================
-- OFF-SCREEN ARROWS
-- ============================================================

local arrowsGui, ARROWS = nil, nil

local function initArrows()
    if arrowsGui then return end
    local parent = (gethui and gethui()) or CoreGui
    arrowsGui = Instance.new("ScreenGui")
    arrowsGui.Name = "zeusx_arrows"; arrowsGui.ResetOnSpawn = false
    arrowsGui.IgnoreGuiInset = true; arrowsGui.DisplayOrder = 996
    arrowsGui.Parent = parent
    ARROWS = {}
end

local function renderArrows()
    if not Config.ESP.Enabled or not Config.ESP.OffScreen then
        if ARROWS then for _, a in ipairs(ARROWS) do a.Visible = false end end
        return
    end
    initArrows()
    local idx = 0
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not H.shouldIgnore(m, {
            StrictTeam    = Config.ESP.StrictTeam,
            FriendCheck   = Config.ESP.FriendCheck,
            ShowTeammates = Config.ESP.ShowTeammates,
        }) then
            local head = H.getHead(m)
            if head then
                local scr, onScreen = H.w2s(head.Position)
                if scr and not onScreen then
                    idx = idx + 1
                    if not ARROWS[idx] then
                        local f = Instance.new("TextLabel")
                        f.Size = UDim2.new(0, 24, 0, 24)
                        f.BackgroundColor3 = Color3.fromRGB(180,130,255)
                        f.BackgroundTransparency = 0.2
                        f.BorderSizePixel = 0
                        f.Text = "▲"
                        f.TextColor3 = Color3.fromRGB(255,255,255)
                        f.Font = Enum.Font.GothamBold
                        f.TextSize = 16
                        f.Parent = arrowsGui
                        Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
                        ARROWS[idx] = f
                    end
                    local arrow = ARROWS[idx]
                    arrow.Visible = true
                    local dir = (head.Position - Camera.CFrame.Position)
                    local camLook = Camera.CFrame.LookVector
                    local camRight = Camera.CFrame.RightVector
                    local rightDot = dir:Dot(camRight)
                    local forwardDot = dir:Dot(camLook)
                    local cx, cy = Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5
                    local radius = math.min(cx, cy) - 40
                    local angle = math.atan2(rightDot, forwardDot)
                    local pos = Vector2.new(cx + math.sin(angle)*radius, cy - math.cos(angle)*radius)
                    arrow.Position = UDim2.new(0, pos.X - 12, 0, pos.Y - 12)
                    arrow.Rotation = math.deg(angle)
                end
            end
        end
    end
    for i = idx + 1, #ARROWS do ARROWS[i].Visible = false end
end

getgenv().zeusx_renderChams = renderChams
getgenv().zeusx_renderArrows = renderArrows
getgenv().zeusx_log("part", "7/9 OK")-- ============================================================
-- Zeus-X Lite v1.2 · TRIGGERBOT MODULE (вставить после части 7, перед 8A)
-- авто-стрельба, универсальный режим, aim-based хитбоксы
-- ============================================================

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Config      = getgenv().zeusx_cfg
local H           = getgenv().zeusx_h

-- ============================================================
-- ДОБАВЛЯЕМ В CONFIG TRIGGER (если ещё нет)
-- ============================================================
Config.Trigger = Config.Trigger or {
    Enabled        = false,
    Mode           = "esp-box",       -- esp-box | hitbox | pixel | universal
    Key            = Enum.UserInputType.MouseButton1,
    AlwaysOn       = false,
    Delay          = 0.06,
    AutoDelay      = true,
    RandomizeDelay = 0.30,            -- ±% к задержке для анти-детекта
    WallCheck      = true,
    StrictTeam     = true,
    FriendCheck    = true,
    MinDist        = 0,
    MaxDist        = 2000,
    HpMin          = 0,
    HpMax          = 100000,
    PixelRadius    = 40,
    HitboxRadius   = 45,
    RequireTool    = true,
    FireMode       = "both",          -- mouse1click | remoteevent | both
    Burst          = 1,
    BurstGapMs     = 50,
    PrefireMs      = 0,
    AfterKillMs    = 0,
    RatePerSec     = 0,
    HeadOnly       = false,
    PreferHead     = true,
    SmoothToggle   = false,
    IgnoreDying    = true,
    DyingHpPct     = 15,
    WeaponBlacklist = {},
    WeaponWhitelist = {},
    WhitelistMode   = false,
    VisibleOnly     = false,           -- только если реально видно
    UniversalFov    = 200,             -- в universal-режиме — радиус от центра
}

local cfgT = Config.Trigger

-- ============================================================
-- STATE
-- ============================================================
local trigHeld         = false
local lastShot         = 0
local lastAutoDelay    = 0.06
local lastKillTime     = 0
local shotTimes        = {}
local targetLockUntil  = 0
local lockedTarget     = nil

-- ============================================================
-- HELPERS
-- ============================================================
local function inList(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

local function getCurrentTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function triggerIgnore(m)
    return H.shouldIgnore(m, {
        StrictTeam  = cfgT.StrictTeam,
        FriendCheck = cfgT.FriendCheck,
    })
end

local function dyingCheck(m)
    if not cfgT.IgnoreDying then return true end
    local hum = H.getHumanoid(m)
    if not hum then return true end
    local pct = hum.Health / math.max(hum.MaxHealth, 1) * 100
    return pct > cfgT.DyingHpPct
end

-- ============================================================
-- WEAPON FILTER
-- ============================================================
local function toolReady(tool)
    if not cfgT.RequireTool then
        if tool then
            if cfgT.WhitelistMode then
                if #cfgT.WeaponWhitelist > 0 and not inList(cfgT.WeaponWhitelist, tool.Name) then
                    return false
                end
            else
                if inList(cfgT.WeaponBlacklist, tool.Name) then return false end
            end
        end
        return true
    end
    if not tool then return false end
    if not tool.Enabled then return false end
    local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("AmmoValue")
    if ammo and ammo:IsA("IntValue") and ammo.Value <= 0 then return false end
    if cfgT.WhitelistMode then
        if #cfgT.WeaponWhitelist > 0 and not inList(cfgT.WeaponWhitelist, tool.Name) then
            return false
        end
    else
        if inList(cfgT.WeaponBlacklist, tool.Name) then return false end
    end
    return true
end

-- ============================================================
-- FIRE
-- ============================================================
local function fireWeapon()
    local tool = getCurrentTool()
    if cfgT.FireMode == "mouse1click" or cfgT.FireMode == "both" then
        if mouse1click then pcall(mouse1click) end
    end
    if (cfgT.FireMode == "remoteevent" or cfgT.FireMode == "both") and tool then
        for _, name in ipairs({"Fire","Shoot","Attack","FireWeapon","ShootEvent","FireEvent","WeaponFire"}) do
            local r = tool:FindFirstChild(name)
            if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                pcall(function()
                    if r:IsA("RemoteEvent") then
                        r:FireServer()
                    end
                end)
                break
            end
        end
    end
end

-- ============================================================
-- MODE 1: ESP-BOX — курсор внутри бокса цели
-- ============================================================
local function isCrosshairInEspBox(m)
    local head = H.getHead(m)
    local root = H.getRoot(m)
    if not head or not root then return false end
    local top = H.w2s(head.Position + Vector3.new(0, 1, 0))
    local bot = H.w2s(root.Position - Vector3.new(0, 3, 0))
    if not top or not bot then return false end
    local h = bot.Y - top.Y
    local w = h * 0.5
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    return center.X >= top.X - w/2 and center.X <= top.X + w/2
       and center.Y >= top.Y and center.Y <= bot.Y
end

-- ============================================================
-- MODE 2: HITBOX — курсор на любой части тела
-- ============================================================
local function isCrosshairOnHitbox(m)
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local radius = cfgT.HitboxRadius
    for _, part in ipairs(m:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local sp = H.w2s(part.Position)
            if sp then
                local r = radius
                if part.Name == "Head" then r = radius * 0.7 end
                if part.Name == "UpperTorso" or part.Name == "Torso" then r = radius * 1.1 end
                if (sp - center).Magnitude < r then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- MODE 3: PIXEL — радиус от центра экрана до головы
-- ============================================================
local function isPixelHit(m)
    local partName = cfgT.PreferHead and "Head" or H.resolvePart(m, "auto")
    local part = m:FindFirstChild(partName, true)
    if not part then return false end
    local sc = H.w2s(part.Position)
    if not sc then return false end
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    return (sc - center).Magnitude < cfgT.PixelRadius
end

-- ============================================================
-- MODE 4: UNIVERSAL — стреляет по всему что отрисовано ESP
-- сканирует все BasePart-хитбоксы цели, проверяет попадает ли курсор
-- в любой из них в 2D-проекции, приоритет по ближайшему к центру
-- ============================================================
local function universalScore(m)
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local best = nil
    local bestDist = math.huge
    for _, part in ipairs(m:GetDescendants()) do
        if part:IsA("BasePart") then
            -- исключаем декорации / аксессуары
            local name = part.Name
            if name ~= "HumanoidRootPart" and not name:find("Accessory") and not name:find("Handle") then
                local sc, onScreen = H.w2s(part.Position)
                if sc and onScreen then
                    local d = (sc - center).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = part
                    end
                end
            end
        end
    end
    return bestDist, best
end

local function isUniversalHit(m)
    local d, part = universalScore(m)
    if not part then return false end
    return d <= cfgT.UniversalFov, part
end

-- ============================================================
-- GET BEST TARGET
-- ============================================================
local function getBestTriggerTarget()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local best, bestScore = nil, math.huge

    -- если есть target lock — сначала проверяем залоченного
    if lockedTarget and tick() < targetLockUntil then
        if H.isAlive(lockedTarget) and not triggerIgnore(lockedTarget) then
            local ok = false
            if cfgT.Mode == "esp-box" then ok = isCrosshairInEspBox(lockedTarget)
            elseif cfgT.Mode == "hitbox" then ok = isCrosshairOnHitbox(lockedTarget)
            elseif cfgT.Mode == "pixel" then ok = isPixelHit(lockedTarget)
            elseif cfgT.Mode == "universal" then ok = isUniversalHit(lockedTarget) end
            if ok then return lockedTarget end
        end
        lockedTarget = nil
    end

    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not triggerIgnore(m) and dyingCheck(m) then
            local root = H.getRoot(m)
            local hum = H.getHumanoid(m)
            if root and hum then
                local d = (camPos - root.Position).Magnitude
                if d >= cfgT.MinDist and d <= cfgT.MaxDist then
                    local hp = hum.Health
                    if hp >= cfgT.HpMin and hp <= cfgT.HpMax then
                        -- wallcheck
                        local wallOk = true
                        if cfgT.WallCheck then
                            local part = cfgT.PreferHead and "Head" or H.resolvePart(m, "auto")
                            wallOk = H.isVisible(m, part)
                        end
                        if wallOk then
                            local inAim = false
                            local score = math.huge

                            if cfgT.Mode == "esp-box" then
                                inAim = isCrosshairInEspBox(m)
                                if inAim then score = 1 end
                            elseif cfgT.Mode == "hitbox" then
                                inAim = isCrosshairOnHitbox(m)
                                if inAim then score = 1 end
                            elseif cfgT.Mode == "pixel" then
                                local partName = cfgT.PreferHead and "Head" or H.resolvePart(m, "auto")
                                local part = m:FindFirstChild(partName, true)
                                if part then
                                    local sc = H.w2s(part.Position)
                                    if sc then
                                        local pxD = (sc - center).Magnitude
                                        if pxD < cfgT.PixelRadius then
                                            inAim = true
                                            score = pxD
                                        end
                                    end
                                end
                            elseif cfgT.Mode == "universal" then
                                local d2, _ = universalScore(m)
                                if d2 <= cfgT.UniversalFov then
                                    inAim = true
                                    score = d2
                                end
                            end

                            if inAim and score < bestScore then
                                best = m
                                bestScore = score
                            end
                        end
                    end
                end
            end
        end
    end

    if best then
        lockedTarget = best
        targetLockUntil = tick() + 0.25
    end
    return best
end

-- ============================================================
-- RATE LIMIT
-- ============================================================
local function rateLimitOk()
    if cfgT.RatePerSec <= 0 then return true end
    local now = tick()
    local cutoff = now - 1
    local new = {}
    for _, t in ipairs(shotTimes) do
        if t >= cutoff then table.insert(new, t) end
    end
    shotTimes = new
    return #shotTimes < cfgT.RatePerSec
end

-- ============================================================
-- MAIN UPDATE
-- ============================================================
local function updateTrigger()
    if not cfgT.Enabled then return end
    if not cfgT.AlwaysOn and not trigHeld then return end
    if not H.isAlive(LocalPlayer.Character) then return end

    local now = tick()
    if (now - lastKillTime)*1000 < cfgT.AfterKillMs then return end

    -- задержка между выстрелами
    local delay = cfgT.AutoDelay and lastAutoDelay or cfgT.Delay
    if cfgT.RandomizeDelay > 0 then
        local jitter = delay * cfgT.RandomizeDelay
        delay = delay + (math.random() * 2 - 1) * jitter
    end
    if now - lastShot < delay then return end
    if not rateLimitOk() then return end

    local tool = getCurrentTool()
    if not toolReady(tool) then return end

    local target = getBestTriggerTarget()
    if not target then return end

    -- auto delay от характеристик оружия
    if cfgT.AutoDelay and tool then
        local rate = tool:GetAttribute("FireRate") or tool:GetAttribute("RPM")
        if type(rate) == "number" and rate > 0 then
            lastAutoDelay = math.max(0.03, 60 / rate * 1.05)
        else
            lastAutoDelay = cfgT.Delay
        end
    end

    -- prefire
    if cfgT.PrefireMs > 0 then
        task.wait(cfgT.PrefireMs / 1000)
        if not cfgT.Enabled then return end
    end

    fireWeapon()
    lastShot = now
    table.insert(shotTimes, now)

    -- burst
    if cfgT.Burst > 1 then
        task.spawn(function()
            for i = 2, cfgT.Burst do
                task.wait(cfgT.BurstGapMs / 1000)
                if cfgT.Enabled and (cfgT.AlwaysOn or trigHeld) then
                    fireWeapon()
                end
            end
        end)
    end
end

-- ============================================================
-- KEYBIND
-- ============================================================
UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == cfgT.Key or i.KeyCode == cfgT.Key then
        trigHeld = true
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == cfgT.Key or i.KeyCode == cfgT.Key then
        trigHeld = false
    end
end)

-- ============================================================
-- KILL DETECT — для AfterKillMs
-- ============================================================
task.spawn(function()
    while task.wait(0.2) do
        if not cfgT.Enabled then continue end
        local hum = H.getHumanoid(LocalPlayer.Character)
        if hum then
            local tag = hum:GetAttribute("zeusx_last_kill")
            if tag and tag ~= lastKillTime then
                lastKillTime = tag
            end
        end
    end
end)

-- ============================================================
-- EXPORT
-- ============================================================
getgenv().zeusx_updateTrigger = updateTrigger
getgenv().zeusx_log("trigger", "module loaded · modes: esp-box / hitbox / pixel / universal")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 8/9 (A) — MENU CORE
-- базовые элементы UI: window, tabs, toggle, slider, dropdown
-- ============================================================

local UIS         = game:GetService("UserInputService")
local CoreGui     = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Camera      = game:GetService("Workspace").CurrentCamera
local Config      = getgenv().zeusx_cfg
local log         = getgenv().zeusx_log

local A = {
    bg      = Color3.fromRGB(18,12,28),
    panel   = Color3.fromRGB(38,28,58),
    accent  = Color3.fromRGB(180,130,255),
    accentD = Color3.fromRGB(110,70,190),
    text    = Color3.fromRGB(235,225,250),
    textDim = Color3.fromRGB(170,155,200),
}

local function tweenQuad(o,t,p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

getgenv().zeusx_create_menu = function()
    local parent = (gethui and gethui()) or CoreGui
    if getgenv().zeusx_menu and getgenv().zeusx_menu.Parent then
        getgenv().zeusx_menu:Destroy()
    end

    local vp = Camera.ViewportSize
    local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
    local winW = isMobile and math.floor(vp.X * 0.94) or math.min(680, math.floor(vp.X * 0.72))
    local winH = isMobile and math.floor(vp.Y * 0.80) or math.min(620, math.floor(vp.Y * 0.84))
    if winW < 320 then winW = 320 end
    if winH < 420 then winH = 420 end

    local HEADER_H = 44
    local TABS_H   = 38
    local TAB_W    = 72

    -- ============================================================
    -- WINDOW
    -- ============================================================
    local sg = Instance.new("ScreenGui")
    sg.Name = "zeusx_menu_root"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 999
    sg.Parent = parent
    getgenv().zeusx_menu = sg

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, winW, 0, winH)
    win.Position = UDim2.new(0.5, -math.floor(winW/2), 0.5, -math.floor(winH/2))
    win.BackgroundColor3 = A.bg; win.BackgroundTransparency = 0.22
    win.BorderSizePixel = 0; win.Active = true; win.Draggable = true
    win.ClipsDescendants = true; win.Parent = sg
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 16)
    local ws = Instance.new("UIStroke")
    ws.Color = A.accent; ws.Thickness = 1.4; ws.Transparency = 0.25; ws.Parent = win

    -- ============================================================
    -- HEADER (title + close)
    -- ============================================================
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, HEADER_H); bar.BackgroundTransparency = 1; bar.Parent = win
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -200, 1, 0); title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "Zeus-X Lite"
    title.TextColor3 = A.accent; title.Font = Enum.Font.GothamBold; title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = bar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -36, 0, 7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60,25,32); closeBtn.Text = "×"
    closeBtn.TextColor3 = A.textDim; closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16; closeBtn.BorderSizePixel = 0; closeBtn.Parent = bar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy(); getgenv().zeusx_menu = nil end)

    -- ============================================================
    -- TAB BAR
    -- ============================================================
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Size = UDim2.new(1, -16, 0, TABS_H)
    tabBar.Position = UDim2.new(0, 8, 0, HEADER_H + 4)
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 0
    tabBar.ScrollBarThickness = 3
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

    -- ============================================================
    -- CONTENT SCROLL
    -- ============================================================
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -16, 1, -(HEADER_H + TABS_H + 12))
    content.Position = UDim2.new(0, 8, 0, HEADER_H + TABS_H + 8)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = win

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0); scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = A.accent; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6); layout.Parent = scroll
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4); pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 14); pad.Parent = scroll

    -- ============================================================
    -- UI HELPERS: section, toggle, slider, dropdown, inputBox, button
    -- ============================================================
    local function section(t)
        local h = Instance.new("TextLabel")
        h.Size = UDim2.new(1, -10, 0, 22); h.BackgroundTransparency = 1
        h.Text = "  " .. t; h.TextColor3 = A.accent
        h.Font = Enum.Font.GothamBold; h.TextSize = 12
        h.TextXAlignment = Enum.TextXAlignment.Left; h.Parent = scroll
    end

    local function toggle(label, get, set)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 36); row.BackgroundColor3 = A.panel
        row.BackgroundTransparency = 0.55; row.BorderSizePixel = 0; row.Parent = scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -80, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = A.text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local sw = Instance.new("Frame")
        sw.Size = UDim2.new(0, 46, 0, 24); sw.Position = UDim2.new(1, -58, 0.5, -12)
        sw.BackgroundColor3 = get() and A.accentD or Color3.fromRGB(45,35,65)
        sw.BorderSizePixel = 0; sw.Parent = row
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = get() and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        knob.BackgroundColor3 = get() and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,190)
        knob.BorderSizePixel = 0; knob.Parent = sw
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local click = Instance.new("TextButton")
        click.Size = UDim2.new(1, 0, 1, 0); click.BackgroundTransparency = 1
        click.Text = ""; click.AutoButtonColor = false; click.Parent = row
        click.MouseButton1Click:Connect(function()
            local nv = not get(); set(nv)
            tweenQuad(sw, 0.2, {BackgroundColor3 = nv and A.accentD or Color3.fromRGB(45,35,65)})
            tweenQuad(knob, 0.2, {
                Position = nv and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10),
                BackgroundColor3 = nv and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,190),
            })
        end)
    end

    local function slider(label, minV, maxV, get, set, fmt)
        fmt = fmt or "%d"
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 50); row.BackgroundColor3 = A.panel
        row.BackgroundTransparency = 0.55; row.BorderSizePixel = 0; row.Parent = scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -120, 0, 20); lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = A.text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 100, 0, 20); val.Position = UDim2.new(1, -112, 0, 6)
        val.BackgroundTransparency = 1; val.Text = string.format(fmt, get())
        val.TextColor3 = Color3.fromRGB(220,150,255)
        val.Font = Enum.Font.GothamBold; val.TextSize = 13
        val.TextXAlignment = Enum.TextXAlignment.Right; val.Parent = row
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 8); track.Position = UDim2.new(0, 12, 0, 36)
        track.BackgroundColor3 = Color3.fromRGB(55,42,80); track.BorderSizePixel = 0; track.Parent = row
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((get() - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = A.accentD; fill.BorderSizePixel = 0; fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 3, 0); hit.Position = UDim2.new(0, 0, -1, 0)
        hit.BackgroundTransparency = 1; hit.Text = ""; hit.AutoButtonColor = false; hit.Parent = track
        local dragging = false
        local function upd(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(minV + (maxV - minV) * rel + 0.5)
            set(v); val.Text = string.format(fmt, v); fill.Size = UDim2.new(rel, 0, 1, 0)
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
        row.Size = UDim2.new(1, -10, 0, 36); row.BackgroundColor3 = A.panel
        row.BackgroundTransparency = 0.55; row.BorderSizePixel = 0; row.Parent = scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -150, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = A.text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local idx = 1
        for i, o in ipairs(options) do if o == get() then idx = i end end
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 140, 0, 24); btn.Position = UDim2.new(1, -150, 0.5, -12)
        btn.BackgroundColor3 = Color3.fromRGB(52,38,80); btn.BackgroundTransparency = 0.3
        btn.Text = options[idx]; btn.TextColor3 = Color3.fromRGB(220,150,255)
        btn.Font = Enum.Font.Gotham; btn.TextSize = 12
        btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            btn.Text = options[idx]
            set(options[idx])
        end)
    end

    local function inputBox(label, get, set, placeholder)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 36); row.BackgroundColor3 = A.panel
        row.BackgroundTransparency = 0.55; row.BorderSizePixel = 0; row.Parent = scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 120, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = A.text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1, -150, 0, 24); tb.Position = UDim2.new(0, 140, 0.5, -12)
        tb.BackgroundColor3 = Color3.fromRGB(28,20,44); tb.BackgroundTransparency = 0.2
        tb.BorderSizePixel = 0; tb.Text = get() or ""
        tb.PlaceholderText = placeholder or "text"
        tb.TextColor3 = A.text
        tb.PlaceholderColor3 = Color3.fromRGB(130,115,165)
        tb.Font = Enum.Font.Gotham; tb.TextSize = 13
        tb.ClearTextOnFocus = true; tb.Parent = row
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
        tb.FocusLost:Connect(function(enter)
            if enter then set(tb.Text); tb.Text = get() or "" end
        end)
    end

    local function button(label, cb, bg)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -10, 0, 32)
        b.BackgroundColor3 = bg or A.accentD
        b.BackgroundTransparency = 0.3; b.BorderSizePixel = 0
        b.Text = label; b.TextColor3 = A.text
        b.Font = Enum.Font.GothamBold; b.TextSize = 13
        b.AutoButtonColor = false; b.Parent = scroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        b.MouseButton1Click:Connect(cb)
    end

    -- ============================================================
    -- TAB MANAGEMENT
    -- ============================================================
    local tabButtons = {}
    local setActiveTab

    local function makeTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, TAB_W, 1, 0); btn.BackgroundColor3 = A.panel
        btn.BackgroundTransparency = 0.55; btn.Text = name; btn.TextColor3 = A.textDim
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
        btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Parent = tabBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        tabButtons[name] = { btn = btn, build = function() end }
        btn.MouseButton1Click:Connect(function() setActiveTab(name) end)
        return tabButtons[name]
    end

    setActiveTab = function(name)
        for n, d in pairs(tabButtons) do
            local a = (n == name)
            tweenQuad(d.btn, 0.18, {
                BackgroundColor3 = a and A.accentD or A.panel,
                TextColor3 = a and Color3.fromRGB(255,255,255) or A.textDim,
                BackgroundTransparency = a and 0 or 0.55,
            })
        end
        for _, c in ipairs(scroll:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
        scroll.CanvasPosition = Vector2.new(0, 0)
        if tabButtons[name] and tabButtons[name].build then
            local ok, err = pcall(tabButtons[name].build)
            if not ok then log("ERR", "tab build '"..name.."'", err) end
        end
    end

    -- экспортируем контекст для следующей части (8B)
    getgenv().zeusx_menu_ctx = {
        A = A,
        Config = Config,
        scroll = scroll,
        makeTab = makeTab,
        setActiveTab = setActiveTab,
        section = section,
        toggle = toggle,
        slider = slider,
        dropdown = dropdown,
        inputBox = inputBox,
        button = button,
        tweenQuad = tweenQuad,
        sg = sg,
    }

    return sg
end

getgenv().zeusx_log("part", "8A/9 OK · menu core")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 8/9 (B) — TABS CONTENT
-- наполнение табов: aim, esp, team, misc
-- ============================================================

local Config = getgenv().zeusx_cfg
local log    = getgenv().zeusx_log

getgenv().zeusx_build_tabs = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx then
        log("ERR", "build_tabs: menu_ctx not ready")
        return
    end

    local makeTab    = ctx.makeTab
    local setActiveTab = ctx.setActiveTab
    local section    = ctx.section
    local toggle     = ctx.toggle
    local slider     = ctx.slider
    local dropdown   = ctx.dropdown
    local inputBox   = ctx.inputBox
    local button     = ctx.button
    local sg         = ctx.sg

    -- ============================================================
    -- TAB: AIM
    -- ============================================================
    local tAim = makeTab("aim")
    tAim.build = function()
        section("AIMBOT")
        toggle("aimbot", function() return Config.Aim.Enabled end, function(v) Config.Aim.Enabled=v end)
        toggle("strict team", function() return Config.Aim.StrictTeam end, function(v) Config.Aim.StrictTeam=v end)
        toggle("friend check", function() return Config.Aim.FriendCheck end, function(v) Config.Aim.FriendCheck=v end)
        toggle("visible check", function() return Config.Aim.Visible end, function(v) Config.Aim.Visible=v end)
        toggle("curve", function() return Config.Aim.Curve end, function(v) Config.Aim.Curve=v end)
        toggle("fov circle", function() return Config.Aim.FovCircle end, function(v) Config.Aim.FovCircle=v end)
        toggle("ignore dying", function() return Config.Aim.IgnoreDying end, function(v) Config.Aim.IgnoreDying=v end)

        section("PREDICTION")
        toggle("enable prediction", function() return Config.Aim.Prediction end, function(v) Config.Aim.Prediction=v end)
        slider("prediction strength %", 0, 200,
            function() return math.floor(Config.Aim.PredictionStrength*100) end,
            function(v) Config.Aim.PredictionStrength=v/100 end)

        section("TUNING")
        slider("fov", 10, 400, function() return Config.Aim.FOV end, function(v) Config.Aim.FOV=v end)
        slider("smooth %", 2, 100,
            function() return math.floor(Config.Aim.Smooth*100) end,
            function(v) Config.Aim.Smooth=v/100 end)
        slider("fast smooth % (shift)", 2, 100,
            function() return math.floor(Config.Aim.FastSmooth*100) end,
            function(v) Config.Aim.FastSmooth=v/100 end)
        slider("target lock ms", 0, 500,
            function() return Config.Aim.TargetLockMs end,
            function(v) Config.Aim.TargetLockMs=v end)
        slider("dying hp %", 0, 100,
            function() return Config.Aim.DyingHpPct end,
            function(v) Config.Aim.DyingHpPct=v end)

        section("TARGET")
        dropdown("hit part",
            {"auto","Head","HumanoidRootPart","UpperTorso","LowerTorso"},
            function() return Config.Aim.Part end,
            function(v) Config.Aim.Part=v end)
        dropdown("aim mode",
            {"camera","mouse"},
            function() return Config.Aim.Mode end,
            function(v) Config.Aim.Mode=v end)

        section("SILENT AIM")
        toggle("silent aim", function() return Config.Silent.Enabled end, function(v) Config.Silent.Enabled=v end)
        toggle("strict team", function() return Config.Silent.StrictTeam end, function(v) Config.Silent.StrictTeam=v end)
        toggle("friend check", function() return Config.Silent.FriendCheck end, function(v) Config.Silent.FriendCheck=v end)
        toggle("require visible", function() return Config.Silent.RequireVisible end, function(v) Config.Silent.RequireVisible=v end)
        slider("hit chance %", 10, 100,
            function() return Config.Silent.HitChance end,
            function(v) Config.Silent.HitChance=v end)
        slider("freeze ms", 0, 500,
            function() return Config.Silent.FreezeMs end,
            function(v) Config.Silent.FreezeMs=v end)
        slider("per-shot cooldown ms", 0, 200,
            function() return Config.Silent.PerShotCooldownMs end,
            function(v) Config.Silent.PerShotCooldownMs=v end)
        dropdown("silent hit part",
            {"auto","Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso"},
            function() return Config.Silent.Part end,
            function(v) Config.Silent.Part=v end)
        dropdown("substitution",
            {"all","target-only"},
            function() return Config.Silent.SubstitutionMode end,
            function(v) Config.Silent.SubstitutionMode=v end)
    end

    -- ============================================================
    -- TAB: ESP
    -- ============================================================
    local tEsp = makeTab("esp")
    tEsp.build = function()
        section("ESP")
        toggle("esp enable", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled=v end)
        toggle("box", function() return Config.ESP.Box end, function(v) Config.ESP.Box=v end)
        toggle("name", function() return Config.ESP.Name end, function(v) Config.ESP.Name=v end)
        toggle("health bar", function() return Config.ESP.Health end, function(v) Config.ESP.Health=v end)
        toggle("distance", function() return Config.ESP.Distance end, function(v) Config.ESP.Distance=v end)
        toggle("tracer", function() return Config.ESP.Tracer end, function(v) Config.ESP.Tracer=v end)
        toggle("head dot", function() return Config.ESP.HeadDot end, function(v) Config.ESP.HeadDot=v end)
        toggle("skeleton", function() return Config.ESP.Skeleton end, function(v) Config.ESP.Skeleton=v end)
        toggle("chams", function() return Config.ESP.Chams end, function(v) Config.ESP.Chams=v end)
        toggle("off-screen arrows", function() return Config.ESP.OffScreen end, function(v) Config.ESP.OffScreen=v end)
        toggle("distance color", function() return Config.ESP.DistanceColor end, function(v) Config.ESP.DistanceColor=v end)

        section("TEAM FILTER")
        toggle("strict team", function() return Config.ESP.StrictTeam end, function(v) Config.ESP.StrictTeam=v end)
        toggle("friend check", function() return Config.ESP.FriendCheck end, function(v) Config.ESP.FriendCheck=v end)
        toggle("show teammates", function() return Config.ESP.ShowTeammates end, function(v) Config.ESP.ShowTeammates=v end)

        section("TUNING")
        slider("max distance", 50, 5000,
            function() return Config.ESP.MaxDist end,
            function(v) Config.ESP.MaxDist=v end)
        slider("interp speed %", 30, 100,
            function() return math.floor(Config.ESP.InterpSpeed*100) end,
            function(v) Config.ESP.InterpSpeed=v/100 end)
        dropdown("hp format",
            {"hp","hp_max","pct"},
            function() return Config.ESP.HpFormat end,
            function(v) Config.ESP.HpFormat=v end)
        dropdown("tracer style",
            {"bottom","top","center"},
            function() return Config.ESP.TracerStyle end,
            function(v) Config.ESP.TracerStyle=v end)
    end

    --

-- ============================================================
-- ДОБАВИТЬ В zeusx_build_tabs() — новый таб "trigger"
-- вставить после tEsp и перед tTeam
-- ============================================================

local tTrig = makeTab("trigger")
tTrig.build = function()
    local cfgT = Config.Trigger

    section("TRIGGERBOT")
    toggle("triggerbot enable", function() return cfgT.Enabled end, function(v) cfgT.Enabled=v end)
    toggle("always on (без удержания)", function() return cfgT.AlwaysOn end, function(v) cfgT.AlwaysOn=v end)
    toggle("strict team", function() return cfgT.StrictTeam end, function(v) cfgT.StrictTeam=v end)
    toggle("friend check", function() return cfgT.FriendCheck end, function(v) cfgT.FriendCheck=v end)
    toggle("wall check (visible)", function() return cfgT.WallCheck end, function(v) cfgT.WallCheck=v end)
    toggle("visible only (жёсткая проверка)", function() return cfgT.VisibleOnly end, function(v) cfgT.VisibleOnly=v end)
    toggle("ignore dying", function() return cfgT.IgnoreDying end, function(v) cfgT.IgnoreDying=v end)

    section("MODE")
    dropdown("trigger mode",
        {"esp-box","hitbox","pixel","universal"},
        function() return cfgT.Mode end,
        function(v) cfgT.Mode=v end)
    dropdown("fire mode",
        {"both","mouse1click","remoteevent"},
        function() return cfgT.FireMode end,
        function(v) cfgT.FireMode=v end)

    section("DELAY")
    toggle("auto delay (по RPM оружия)", function() return cfgT.AutoDelay end, function(v) cfgT.AutoDelay=v end)
    slider("manual delay ms", 10, 300,
        function() return math.floor(cfgT.Delay*1000) end,
        function(v) cfgT.Delay=v/1000 end)
    slider("randomize delay %", 0, 100,
        function() return math.floor(cfgT.RandomizeDelay*100) end,
        function(v) cfgT.RandomizeDelay=v/100 end)
    slider("prefire ms", 0, 500,
        function() return cfgT.PrefireMs end,
        function(v) cfgT.PrefireMs=v end)
    slider("after-kill delay ms", 0, 2000,
        function() return cfgT.AfterKillMs end,
        function(v) cfgT.AfterKillMs=v end)

    section("BURST")
    slider("burst count", 1, 20,
        function() return cfgT.Burst end,
        function(v) cfgT.Burst=v end)
    slider("burst gap ms", 20, 500,
        function() return cfgT.BurstGapMs end,
        function(v) cfgT.BurstGapMs=v end)

    section("RATE LIMIT")
    slider("max shots / sec (0 = off)", 0, 40,
        function() return cfgT.RatePerSec end,
        function(v) cfgT.RatePerSec=v end)

    section("DISTANCE")
    slider("min distance", 0, 200,
        function() return cfgT.MinDist end,
        function(v) cfgT.MinDist=v end)
    slider("max distance", 100, 5000,
        function() return cfgT.MaxDist end,
        function(v) cfgT.MaxDist=v end)

    section("HP FILTER")
    slider("hp min", 0, 500,
        function() return cfgT.HpMin end,
        function(v) cfgT.HpMin=v end)
    slider("hp max", 0, 100000,
        function() return cfgT.HpMax end,
        function(v) cfgT.HpMax=v end)
    slider("dying hp %", 0, 100,
        function() return cfgT.DyingHpPct end,
        function(v) cfgT.DyingHpPct=v end)

    section("HITBOX / PIXEL")
    slider("pixel radius", 10, 150,
        function() return cfgT.PixelRadius end,
        function(v) cfgT.PixelRadius=v end)
    slider("hitbox radius", 10, 150,
        function() return cfgT.HitboxRadius end,
        function(v) cfgT.HitboxRadius=v end)
    slider("universal fov", 50, 500,
        function() return cfgT.UniversalFov end,
        function(v) cfgT.UniversalFov=v end)
    toggle("head only", function() return cfgT.HeadOnly end, function(v) cfgT.HeadOnly=v end)
    toggle("prefer head", function() return cfgT.PreferHead end, function(v) cfgT.PreferHead=v end)

    section("WEAPON FILTER")
    toggle("whitelist mode", function() return cfgT.WhitelistMode end, function(v) cfgT.WhitelistMode=v end)
    toggle("require tool", function() return cfgT.RequireTool end, function(v) cfgT.RequireTool=v end)

    inputBox("add weapon to whitelist", function() return "" end, function(v)
        if v and v ~= "" then table.insert(cfgT.WeaponWhitelist, v) end
    end, "имя оружия + Enter")

    inputBox("add weapon to blacklist", function() return "" end, function(v)
        if v and v ~= "" then table.insert(cfgT.WeaponBlacklist, v) end
    end, "имя оружия + Enter")

    -- кнопка: добавить оружие в руках
    button("добавить оружие в руках → whitelist", function()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            table.insert(cfgT.WeaponWhitelist, tool.Name)
            print("[zeusx] wl+: " .. tool.Name)
        else
            print("[zeusx] нет оружия в руках")
        end
    end)
    button("добавить оружие в руках → blacklist", function()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            table.insert(cfgT.WeaponBlacklist, tool.Name)
            print("[zeusx] bl+: " .. tool.Name)
        else
            print("[zeusx] нет оружия в руках")
        end
    end)
    button("show whitelist", function()
        local s = #cfgT.WeaponWhitelist == 0 and "(пусто)" or table.concat(cfgT.WeaponWhitelist, ", ")
        print("[zeusx] weapon wl:", s)
    end)
    button("show blacklist", function()
        local s = #cfgT.WeaponBlacklist == 0 and "(пусто)" or table.concat(cfgT.WeaponBlacklist, ", ")
        print("[zeusx] weapon bl:", s)
    end)
    button("clear weapon whitelist", function() cfgT.WeaponWhitelist = {} end)
    button("clear weapon blacklist", function() cfgT.WeaponBlacklist = {} end)

    section("INFO")
    button("что значит universal", function()
        print("[zeusx] universal mode — стреляет по любой BasePart цели,")
        print("[zeusx] которая попадает в радиус UniversalFov от центра экрана.")
        print("[zeusx] покрывает ESP-box + skeleton + chams + arrows одновременно.")
    end)
end
 ============================================================
    -- TAB: TEAM
    -- ============================================================
    local tTeam = makeTab("team")
    tTeam.build = function()
        section("WHITELIST — всегда ignore")
        inputBox("add nick", function() return "" end, function(v)
            if v and v ~= "" then table.insert(Config.Team.Whitelist, v) end
        end, "ник + Enter")
        button("show whitelist", function()
            local s = #Config.Team.Whitelist == 0 and "(пусто)" or table.concat(Config.Team.Whitelist, ", ")
            print("[zeusx] whitelist:", s)
        end)
        button("clear whitelist", function() Config.Team.Whitelist = {} end)
    end

    -- ============================================================
    -- TAB: MISC
    -- ============================================================
    local tMisc = makeTab("misc")
    tMisc.build = function()
        section("UI")
        toggle("watermark", function() return Config.Misc.Watermark end, function(v) Config.Misc.Watermark=v end)

        section("KEY")
        button("показать статус ключа", function()
            local left = Config.Key.Expiry - os.time()
            if left > 1e9 then print("[zeusx] ключ: вечный")
            elseif left <= 0 then print("[zeusx] ключ: истёк")
            else print("[zeusx] ключ: осталось " .. tostring(left) .. " сек") end
        end)
        button("сменить ключ", function()
            active_key = nil
            Config.Key.Active = nil
            if sg then sg:Destroy() end
            if getgenv().zeusx_show_keygate then
                getgenv().zeusx_show_keygate(getgenv().zeusx_on_success, "")
            end
        end)

        section("PANIC")
        button("выключить всё", function()
            Config.Aim.Enabled = false
            Config.Silent.Enabled = false
            Config.ESP.Enabled = false
        end)
    end

    setActiveTab("aim")
end

getgenv().zeusx_log("part", "8B/9 OK · tabs content")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 9/9 (A) — KEYGATE UI + WATERMARK + PANIC
-- ============================================================

local UIS         = game:GetService("UserInputService")
local CoreGui     = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Config      = getgenv().zeusx_cfg
local log         = getgenv().zeusx_log

local TG_LINK = "https://t.me/noir_xis"
local accent  = Color3.fromRGB(180, 130, 255)

local function tweenQuad(o,t,p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local function formatTime(sec)
    if not sec or sec < 0 then sec = 0 end
    if sec > 1e9 then return "вечный" end
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    if d > 0 then return string.format("%dд %02dч %02dм", d, h, m) end
    return string.format("%02dч %02dм", h, m)
end

-- ============================================================
-- KEYGATE UI
-- ============================================================

getgenv().zeusx_show_keygate = function(onSuccess, message)
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("zeusx_keygui"); if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "zeusx_keygui"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 2000; sg.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 340)
    frame.Position = UDim2.new(0.5, -190, 0.65, -170)
    frame.BackgroundColor3 = Color3.fromRGB(18,12,28)
    frame.BackgroundTransparency = 0.25; frame.BorderSizePixel = 0
    frame.Active = true; frame.Draggable = true; frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 18)
    tweenQuad(frame, 0.55, {Position = UDim2.new(0.5, -190, 0.5, -170), BackgroundTransparency = 0.1})

    local stroke = Instance.new("UIStroke")
    stroke.Color = accent; stroke.Thickness = 1.4; stroke.Transparency = 0.3; stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 52); title.BackgroundTransparency = 1
    title.Text = "ZEUS-X"; title.TextColor3 = accent
    title.Font = Enum.Font.GothamBold; title.TextSize = 26; title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 18); sub.Position = UDim2.new(0, 0, 0, 50)
    sub.BackgroundTransparency = 1; sub.Text = "введите ключ доступа"
    sub.TextColor3 = Color3.fromRGB(180,160,220)
    sub.Font = Enum.Font.Gotham; sub.TextSize = 13; sub.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -40, 0, 44); box.Position = UDim2.new(0, 20, 0, 84)
    box.BackgroundColor3 = Color3.fromRGB(38,28,58); box.BackgroundTransparency = 0.3
    box.BorderSizePixel = 0; box.Text = ""
    box.PlaceholderText = "ключ..."
    box.TextColor3 = Color3.fromRGB(235,225,250)
    box.PlaceholderColor3 = Color3.fromRGB(140,120,180)
    box.Font = Enum.Font.Gotham; box.TextSize = 15
    box.ClearTextOnFocus = false; box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 44); btn.Position = UDim2.new(0, 20, 0, 142)
    btn.BackgroundColor3 = Color3.fromRGB(120,75,200); btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0; btn.Text = "войти"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 15
    btn.AutoButtonColor = false; btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local tgBtn = Instance.new("TextButton")
    tgBtn.Size = UDim2.new(1, -40, 0, 40); tgBtn.Position = UDim2.new(0, 20, 0, 198)
    tgBtn.BackgroundColor3 = Color3.fromRGB(30,90,140); tgBtn.BackgroundTransparency = 0.15
    tgBtn.BorderSizePixel = 0; tgBtn.Text = "получить ключ  ·  @noir_xis"
    tgBtn.TextColor3 = Color3.fromRGB(255,255,255)
    tgBtn.Font = Enum.Font.GothamBold; tgBtn.TextSize = 14
    tgBtn.AutoButtonColor = false; tgBtn.Parent = frame
    Instance.new("UICorner", tgBtn).CornerRadius = UDim.new(0, 10)

    tgBtn.MouseButton1Click:Connect(function()
        if setclipboard then pcall(function() setclipboard(TG_LINK) end) end
        tgBtn.Text = "скопировано  ·  " .. TG_LINK
        task.wait(2.5); tgBtn.Text = "получить ключ  ·  @noir_xis"
    end)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 16); status.Position = UDim2.new(0, 0, 0, 246)
    status.BackgroundTransparency = 1; status.Text = message or ""
    status.TextColor3 = Color3.fromRGB(255,120,140)
    status.Font = Enum.Font.Gotham; status.TextSize = 12; status.Parent = frame

    local timerLbl = Instance.new("TextLabel")
    timerLbl.Size = UDim2.new(1, 0, 0, 14); timerLbl.Position = UDim2.new(0, 0, 0, 264)
    timerLbl.BackgroundTransparency = 1; timerLbl.Text = ""
    timerLbl.TextColor3 = Color3.fromRGB(200,180,240)
    timerLbl.Font = Enum.Font.Gotham; timerLbl.TextSize = 11; timerLbl.Parent = frame

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, 0, 0, 14); hint.Position = UDim2.new(0, 0, 0, 282)
    hint.BackgroundTransparency = 1; hint.Text = "ключ проверяется на сервере"
    hint.TextColor3 = Color3.fromRGB(140,120,180)
    hint.Font = Enum.Font.Gotham; hint.TextSize = 10; hint.Parent = frame

    local function try()
        local entered = (box.Text:gsub("%s",""))
        if entered == "" then return end
        status.TextColor3 = Color3.fromRGB(180,180,220)
        status.Text = "проверка..."; btn.Text = "..."; btn.Active = false
        local ok, left, data = getgenv().zeusx_checkKey(entered)
        btn.Active = true; btn.Text = "войти"
        if not ok then
            status.TextColor3 = Color3.fromRGB(255,120,140)
            status.Text = left or "ошибка"
            box.Text = ""
            return
        end
        getgenv().zeusx_set_key(entered)
        Config.Key.Expiry = os.time() + (tonumber(left) or 0)
        status.TextColor3 = Color3.fromRGB(180,255,180)
        status.Text = "доступ разрешён"
        timerLbl.Text = "осталось: " .. formatTime(left)
        task.wait(1.2)
        sg:Destroy()
        if onSuccess then pcall(onSuccess) end
    end

    btn.MouseButton1Click:Connect(try)
    box.FocusLost:Connect(function(e) if e then try() end end)
end

-- ============================================================
-- WATERMARK
-- ============================================================

local wm
getgenv().zeusx_updateWatermark = function()
    if Config.Misc.Watermark then
        if not wm then
            local parent = (gethui and gethui()) or CoreGui
            wm = Instance.new("TextLabel")
            wm.Size = UDim2.new(0, 260, 0, 26)
            wm.Position = UDim2.new(0, 12, 0, 12)
            wm.BackgroundColor3 = Color3.fromRGB(20,14,30)
            wm.BackgroundTransparency = 0.4
            wm.BorderSizePixel = 0
            wm.Text = "  Zeus-X Lite"
            wm.TextColor3 = Color3.fromRGB(180,140,255)
            wm.Font = Enum.Font.GothamBold; wm.TextSize = 13
            wm.TextXAlignment = Enum.TextXAlignment.Left
            wm.Parent = parent
            Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 8)
        end
        wm.Visible = true
    elseif wm then
        wm.Visible = false
    end
end

-- ============================================================
-- DISABLE ALL + PANIC KEY
-- ============================================================

getgenv().zeusx_disableAll = function()
    Config.Aim.Enabled = false
    Config.Silent.Enabled = false
    Config.ESP.Enabled = false
    if getgenv().zeusx_renderESP then
        pcall(getgenv().zeusx_renderESP)
    end
    log("panic", "all disabled")
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Config.Misc.PanicKey then
        getgenv().zeusx_disableAll()
    end
end)

getgenv().zeusx_log("part", "9A/9 OK · keygate + watermark + panic")-- ============================================================
-- Zeus-X Lite v1.1 · ЧАСТЬ 9/9 (B) — MAIN LOOP + BOOTSTRAP
-- ============================================================

local RunService = game:GetService("RunService")
local log        = getgenv().zeusx_log

-- ============================================================
-- MAIN LOOP
-- ============================================================

if not getgenv()._zeusx_loop_started then
    getgenv()._zeusx_loop_started = true

    local function safeCall(fn)
        if not fn then return end
        local ok, err = pcall(fn)
        if not ok then
            getgenv()._loop_errs = getgenv()._loop_errs or {}
            if not getgenv()._loop_errs[fn] then
                getgenv()._loop_errs[fn] = true
                log("LOOP-ERR", tostring(fn), err)
            end
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        -- aim & silent & fov circle
        safeCall(getgenv().zeusx_updateAim)
        safeCall(getgenv().zeusx_updateSilent)
        safeCall(getgenv().zeusx_updateFovCircle)
        -- esp layers
        safeCall(getgenv().zeusx_renderESP)
        safeCall(getgenv().zeusx_renderSkeleton)
        safeCall(getgenv().zeusx_renderChams)
        safeCall(getgenv().zeusx_renderArrows)
        -- hud
        safeCall(getgenv().zeusx_updateWatermark)
    end)

    log("loop", "запущен")
end

-- ============================================================
-- BOOTSTRAP — что делаем после успешного ввода ключа
-- ============================================================

getgenv().zeusx_on_success = function()
    log("bootstrap", "start")

    -- 1. инициализация ESP-канваса
    if getgenv().zeusx_initESP then
        local ok, err = pcall(getgenv().zeusx_initESP)
        if not ok then log("ERR", "init_esp", err) end
    end

    -- 2. создаём окно меню (часть 8A)
    if getgenv().zeusx_create_menu then
        local ok, err = pcall(getgenv().zeusx_create_menu)
        if not ok then log("ERR", "create_menu", err) end
    end

    -- 3. строим табы внутри окна (часть 8B)
    task.wait(0.05)
    if getgenv().zeusx_build_tabs then
        local ok, err = pcall(getgenv().zeusx_build_tabs)
        if not ok then log("ERR", "build_tabs", err) end
    end

    log("bootstrap", "done")
end

-- ============================================================
-- СТАРТ — показываем keygate сразу при запуске скрипта
-- ============================================================

task.spawn(function()
    log("bootstrap", "showing keygate")
    if getgenv().zeusx_show_keygate then
        local ok, err = pcall(getgenv().zeusx_show_keygate, getgenv().zeusx_on_success)
        if not ok then log("ERR", "show_keygate", err) end
    end
end)

log("lite v1.1", "loaded · 9 parts (A+B split)") 