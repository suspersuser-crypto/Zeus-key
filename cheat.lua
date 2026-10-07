-- ============================================================
-- Zeus-X v9.5 Global Edition · ЧАСТЬ 1/11
-- services + config + hwid + keygate core
-- сервер: https://zeus-key-mjep.onrender.com
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

local SERVER_URL = "https://zeus-key-mjep.onrender.com/check"
local TG_LINK    = "https://t.me/noir_xis"
local CFG_DIR    = "zeusx"

if isfolder and not isfolder(CFG_DIR) then pcall(makefolder, CFG_DIR) end

local Config = {
    Aim = {
        Enabled=false, FOV=120, Smooth=0.35,
        Key=Enum.UserInputType.MouseButton2,
        Visible=true, WallCheck=true,
        StrictTeam=true, FriendCheck=true, IgnoreWhitelist=true,
        Part="auto", Mode="camera", NoRecoil=true, Priority="score",
        Prediction=false, PredictionStrength=0.5,
        TargetLockMs=180, Curve=true,
    },
    Silent = {
        Enabled=false, HitChance=100,
        StrictTeam=true, FriendCheck=true, IgnoreWhitelist=true,
        RequireVisible=true, Part="Head",
        SubstitutionMode="all",
        FreezeMs=200, Prediction=false, PredictionStrength=0.5,
        PerShotCooldownMs=30,
    },
    Trigger = {
        Enabled=false, Key=Enum.UserInputType.MouseButton1,
        Delay=0.06, WallCheck=true,
        StrictTeam=true, FriendCheck=true, IgnoreWhitelist=true,
        Mode="esp-box", PixelRadius=40,
        MinDist=5, MaxDist=2000,
        HpMin=0, HpMax=100000,
        AutoDelay=true, FireMode="both",
        RequireTool=true, AlwaysOn=false,
    },
    ESP = {
        Enabled=false,
        Box=true, Name=true, Health=true, Distance=true, Tracer=false,
        StrictTeam=true, FriendCheck=true, IgnoreWhitelist=true,
        ShowTeammates=false,
        MaxDist=2000, MinParts=5,
    },
    Move = {
        Speed=false, SpeedVal=28, Fly=false, FlySpeed=50,
        InfJump=false, Noclip=false, AutoRespawn=false,
    },
    Vis = { Fullbright=false, NoFog=false, FOV=70 },
    Misc = { KillNotify=true, Watermark=true, SaveOnChange=false },
    Anti = {
        AntiAFK=true, AntiFling=true, AntiVoid=true,
        StealthSpeedCap=44, StealthFlyCap=72,
    },
    Team = {
        MyTeamId=nil,
        Whitelist={},
        Blacklist={},
        Friends={},
    },
}
getgenv().vanta_cfg = Config
getgenv().vanta_orig = { WalkSpeed=16, JumpPower=50 }

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

-- ok(bool|nil), msg(string), data(table|nil)
local function checkKeyOnServer(key)
    local hwid = getHWID()
    local username = LocalPlayer.Name
    local url = SERVER_URL .. "?token=" .. key .. "&hwid=" .. hwid .. "&username=" .. username
    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not response or response == "" then
        return nil, "нет соединения"
    end
    local okDecode, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not okDecode or type(data) ~= "table" then
        return nil, "ошибка формата"
    end
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

local function disableAll()
    for _, section in pairs(Config) do
        if type(section) == "table" then
            for k, v in pairs(section) do
                if type(v) == "boolean" then section[k] = false end
            end
        end
    end
    local p = (gethui and gethui()) or CoreGui
    for _, n in ipairs({"vanta_esp","vanta_menu_root","vanta_keygui","vanta_notify"}) do
        local e = p:FindFirstChild(n); if e then e:Destroy() end
    end
end

getgenv().vanta_disableAll = disableAll
getgenv().vanta_checkKey = checkKeyOnServer
getgenv().vanta_getHWID = getHWID

local active_key = nil
getgenv().vanta_set_key = function(k) active_key = k end
getgenv().vanta_get_key = function() return active_key end

task.spawn(function()
    while task.wait(60) do
        if not active_key then continue end
        local ok, msg = checkKeyOnServer(active_key)
        if ok == false then
            active_key = nil
            disableAll()
            if getgenv().vanta_show_keygate then
                getgenv().vanta_show_keygate(getgenv().vanta_on_success, tostring(msg))
            end
            break
        end
    end
end)

print("[zeusx] part 1/11 OK")-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 2/11 — config save/load + notify
-- ============================================================

local CFG_DIR = "zeusx"

local function deep_copy(t)
    local c = {}
    for k, v in pairs(t) do
        if type(v) == "table" then c[k] = deep_copy(v) else c[k] = v end
    end
    return c
end

local function serialize(v)
    if type(v) == "EnumItem" then return {__enum=true, t=tostring(v.EnumType), n=v.Name} end
    if type(v) == "table" then
        local o = {}; for k, vv in pairs(v) do o[k] = serialize(vv) end; return o
    end
    return v
end

local function deserialize(v)
    if type(v) == "table" and v.__enum then
        local ok, e = pcall(function() return Enum[v.t][v.n] end)
        if ok then return e end
    end
    if type(v) == "table" then
        local o = {}; for k, vv in pairs(v) do o[k] = deserialize(vv) end; return o
    end
    return v
end

local function cfg_path(slot) return CFG_DIR .. "/cfg_" .. (slot or "default") .. ".json" end

getgenv().zeusx_saveConfig = function(slot)
    if not writefile then return false end
    slot = slot or "default"
    local data = serialize(deep_copy(getgenv().vanta_cfg))
    local ok, enc = pcall(function() return game:GetService("HttpService"):JSONEncode(data) end)
    if not ok then return false end
    return pcall(writefile, cfg_path(slot), enc)
end

getgenv().zeusx_loadConfig = function(slot)
    if not readfile or not isfile then return false end
    slot = slot or "default"
    local p = cfg_path(slot)
    if not isfile(p) then return false end
    local ok, raw = pcall(readfile, p)
    if not ok or not raw then return false end
    local okD, data = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
    if not okD or type(data) ~= "table" then return false end
    data = deserialize(data)
    local cfg = getgenv().vanta_cfg
    for section, vals in pairs(data) do
        if cfg[section] and type(vals) == "table" then
            for k, v in pairs(vals) do cfg[section][k] = v end
        end
    end
    return true
end

getgenv().zeusx_listConfigs = function()
    if not listfiles or not isfolder then return {} end
    local out = {}
    local ok, files = pcall(listfiles, CFG_DIR)
    if not ok or not files then return out end
    for _, p in ipairs(files) do
        local n = p:match("cfg_(.+)%.json$")
        if n then table.insert(out, n) end
    end
    return out
end

getgenv().zeusx_saveKey  = function() end
getgenv().zeusx_loadKey  = function() return nil end
getgenv().zeusx_clearKey = function() end

task.defer(function()
    if delfile and isfile and isfile(CFG_DIR .. "/key.txt") then
        pcall(delfile, CFG_DIR .. "/key.txt")
    end
end)

task.defer(function()
    if getgenv().zeusx_loadConfig("default") then
        print("[zeusx] config 'default' загружен")
    end
end)

getgenv().vanta_notify = function(text, dur)
    dur = dur or 3
    local parent = (gethui and gethui()) or game:GetService("CoreGui")
    local old = parent:FindFirstChild("vanta_notify"); if old then old:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "vanta_notify"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    sg.DisplayOrder = 3000; sg.Parent = parent
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 320, 0, 48)
    f.Position = UDim2.new(0.5, -160, 0, -60)
    f.BackgroundColor3 = Color3.fromRGB(18,12,28)
    f.BackgroundTransparency = 0.15; f.BorderSizePixel = 0; f.Parent = sg
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180,130,255); s.Thickness = 1.4; s.Parent = f
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 1, 0); l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1; l.Text = text
    l.TextColor3 = Color3.fromRGB(235,225,250)
    l.Font = Enum.Font.GothamBold; l.TextSize = 14; l.Parent = f
    local T = game:GetService("TweenService")
    T:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -160, 0, 20)}):Play()
    task.delay(dur, function()
        T:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -160, 0, -60)}):Play()
        task.wait(0.3); sg:Destroy()
    end)
end

print("[zeusx] part 2/11 OK")-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 3/11 — поиск целей + team detection
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Config      = getgenv().vanta_cfg

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
    if #m:GetChildren() < (Config.ESP.MinParts or 5) then return true end
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
    elseif scanMode == "mixed" then
        local l = collectPlayers()
        for _, m in ipairs(collectWorkspace()) do
            local dup = false
            for _, e in ipairs(l) do if e == m then dup = true break end end
            if not dup then table.insert(l, m) end
        end
        return l
    else return collectPlayers() end
end
getgenv().vanta_getTargets = getTargets

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

-- ============================================================
-- TEAM DETECTION — реальная логика
-- ============================================================

local teamCache = {}
task.spawn(function() while task.wait(5) do teamCache = {} end end)

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
    if Config.Team.MyTeamId ~= nil then return "M:" .. tostring(Config.Team.MyTeamId) end
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
    for _, n in ipairs(list) do
        if n == name then return true end
    end
    return false
end

-- возвращает true если target надо игнорировать
local function shouldIgnore(m, opts)
    opts = opts or {}
    if not m then return true end
    if m == LocalPlayer.Character then return true end

    -- blacklist → force-target (никогда не игнорим)
    if inList(Config.Team.Blacklist, m.Name) then return false end

    -- whitelist → всегда игнор (если включено)
    if opts.IgnoreWhitelist ~= false then
        if inList(Config.Team.Whitelist, m.Name) then return true end
    end

    -- друзья
    if opts.FriendCheck ~= false then
        if isFriend(m) then return true end
    end

    -- свои по команде
    local strict = (opts.StrictTeam ~= false)
    if isSameTeam(m, strict) then
        if opts.ShowTeammates then return false end
        return true
    end

    return false
end

local function sameTeam(m)
    return isSameTeam(m, true)
end

getgenv().zeusx_shouldIgnore = shouldIgnore
getgenv().zeusx_isSameTeam = isSameTeam
getgenv().zeusx_isFriend = isFriend

getgenv().zeusx_teamDebug = function()
    print("=== ZEUS-X TEAM DEBUG ===")
    print("My Team:", LocalPlayer.Team, "| Color:", LocalPlayer.TeamColor)
    print("My strict id:", getMyTeamId(true))
    print("My soft id:", getMyTeamId(false))
    print("Whitelist:", table.concat(Config.Team.Whitelist, ", "))
    print("Blacklist:", table.concat(Config.Team.Blacklist, ", "))
    print("Friends cached:", #Config.Team.Friends)
    print("---")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local chr = p.Character
            if chr then
                local ign = shouldIgnore(chr, {StrictTeam=Config.Aim.StrictTeam, FriendCheck=Config.Aim.FriendCheck})
                print(string.format(" %s | Team=%s | strict=%s | friend=%s | ignore=%s",
                    p.Name, tostring(p.Team), tostring(getTargetTeamId(chr, true)),
                    tostring(isFriend(chr)), tostring(ign)))
            end
        end
    end
end

-- подгрузка друзей Roblox
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
        print("[zeusx] friends cached:", #Config.Team.Friends)
    end)
end)

getgenv().vanta_h = {
    getTargets=getTargets, getHumanoid=getHumanoid, getHead=getHead, getRoot=getRoot,
    isAlive=isAlive, sameTeam=sameTeam, partPos=partPos, resolvePart=resolvePart,
    w2s=w2s, isVisible=isVisible, getMyTeamId=getMyTeamId, resolveTeamId=resolveTeamStrict,
    teamDebug=getgenv().zeusx_teamDebug,
    shouldIgnore=shouldIgnore, isSameTeam=isSameTeam, isFriend=isFriend,
}

print("[zeusx] part 3/11 OK")-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 4/11 — ESP
-- ============================================================

local CoreGui  = game:GetService("CoreGui")
local Camera   = game:GetService("Workspace").CurrentCamera
local Config   = getgenv().vanta_cfg
local H        = getgenv().vanta_h

local espGui, ESP

local function initESP()
    if espGui then return end
    local parent = (gethui and gethui()) or CoreGui
    espGui = Instance.new("ScreenGui")
    espGui.Name = "vanta_esp"
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
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = espGui
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(170,120,255)
    stroke.Thickness = 1.5
    stroke.Parent = box

    local hpBg = Instance.new("Frame")
    hpBg.BackgroundColor3 = Color3.fromRGB(20,10,30)
    hpBg.BorderSizePixel = 0
    hpBg.Visible = false
    hpBg.Parent = espGui

    local hpFill = Instance.new("Frame")
    hpFill.BackgroundColor3 = Color3.fromRGB(100,220,140)
    hpFill.BorderSizePixel = 0
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.Parent = hpBg

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = Color3.fromRGB(180,130,255)
    tracer.BackgroundTransparency = 0.4
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.AnchorPoint = Vector2.new(0, 0.5)
    tracer.Parent = espGui

    ESP[m] = {
        box=box, stroke=stroke, hpBg=hpBg, hpFill=hpFill, tracer=tracer,
        name=mkLabel(Color3.fromRGB(255,255,255)),
        hp=mkLabel(Color3.fromRGB(180,255,180), 11),
        dist=mkLabel(Color3.fromRGB(200,200,200), 11),
    }
end

local function destroyESP(m)
    local t = ESP[m]; if not t then return end
    for _, o in pairs(t) do pcall(function() o:Destroy() end) end
    ESP[m] = nil
end

local function hideAll(t)
    t.box.Visible=false; t.name.Visible=false
    t.hp.Visible=false; t.dist.Visible=false
    t.hpBg.Visible=false; t.tracer.Visible=false
end

local function renderESP()
    if not espGui then return end
    if not Config.ESP.Enabled then
        for _, t in pairs(ESP) do hideAll(t) end
        return
    end
    local myPos = Camera.CFrame.Position
    local seen = {}
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y)

    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        local t = ESP[m]
        if not t then createESP(m); t = ESP[m] end

        local ignore = H.shouldIgnore(m, {
            StrictTeam = Config.ESP.StrictTeam,
            FriendCheck = Config.ESP.FriendCheck,
            IgnoreWhitelist = Config.ESP.IgnoreWhitelist,
            ShowTeammates = Config.ESP.ShowTeammates,
        })
        local show = H.isAlive(m) and not ignore

        local root = H.getRoot(m)
        if show and root and (myPos - root.Position).Magnitude > Config.ESP.MaxDist then
            show = false
        end
        if not show then hideAll(t); continue end

        local head = H.getHead(m)
        local hum = H.getHumanoid(m)
        if not head or not root then hideAll(t); continue end

        local top = H.w2s(head.Position + Vector3.new(0,1,0))
        local bot = H.w2s(root.Position - Vector3.new(0,3,0))
        if not top or not bot then hideAll(t); continue end

        local h = bot.Y - top.Y
        local w = h * 0.5
        local cx, cy = top.X, top.Y

        t.box.Visible = Config.ESP.Box
        t.box.Size = UDim2.new(0, w, 0, h)
        t.box.Position = UDim2.new(0, cx - w/2, 0, cy)

        t.name.Visible = Config.ESP.Name
        t.name.Text = m.Name
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
        t.hp.Text = math.floor(hp) .. " hp"
        t.hp.Size = UDim2.new(0, 200, 0, 14)
        t.hp.Position = UDim2.new(0, cx - 100, 0, cy + h + 2)

        t.dist.Visible = Config.ESP.Distance
        t.dist.Text = math.floor((myPos - root.Position).Magnitude) .. " m"
        t.dist.Size = UDim2.new(0, 200, 0, 14)
        t.dist.Position = UDim2.new(0, cx - 100, 0, cy + h + 16)

        if Config.ESP.Tracer then
            t.tracer.Visible = true
            local d = Vector2.new(cx, cy + h) - center
            t.tracer.Size = UDim2.new(0, d.Magnitude, 0, 1)
            t.tracer.Position = UDim2.new(0, center.X, 0, center.Y)
            t.tracer.Rotation = math.deg(math.atan2(d.Y, d.X))
        else
            t.tracer.Visible = false
        end
    end
    for m in pairs(ESP) do
        if not seen[m] or not m.Parent then destroyESP(m) end
    end
end

getgenv().vanta_init_esp = initESP
getgenv().vanta_render_esp = renderESP
print("[zeusx] part 4/11 OK")-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 5/11 — aim + silent + trigger (stable)
-- ============================================================

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local RunService  = game:GetService("RunService")
local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Config      = getgenv().vanta_cfg
local H           = getgenv().vanta_h

local aimHeld, trigHeld = false, false
local lastShot = 0
local savedRecoil = {}

-- ============ AIM HELPERS ============

local function getRootVelocity(model)
    local hrp = H.getRoot(model)
    if not hrp then return Vector3.zero end
    local ok, v = pcall(function() return hrp.AssemblyLinearVelocity or hrp.Velocity end)
    if ok and v then return v end
    return Vector3.zero
end

local function predictPos(model, basePos, strength)
    if not strength then return basePos end
    local v = getRootVelocity(model)
    local camPos = Camera.CFrame.Position
    local dist = (camPos - basePos).Magnitude
    local t = dist / 200 * strength
    return basePos + v * t
end

local function aimShouldIgnore(m)
    return H.shouldIgnore(m, {
        StrictTeam = Config.Aim.StrictTeam,
        FriendCheck = Config.Aim.FriendCheck,
        IgnoreWhitelist = Config.Aim.IgnoreWhitelist,
    })
end

local function scoreTargetAim(m, fov, camPos, center)
    if not H.isAlive(m) then return nil end
    if aimShouldIgnore(m) then return nil end

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
    local score
    if Config.Aim.Priority == "distance" then score = worldD
    elseif Config.Aim.Priority == "fov" then score = pxD
    else score = pxD + worldD * 0.1 end

    return score, m, pos
end

-- ============ AIM: lock ============

local lockedTarget = nil
local lockedAt = 0

local function pickAimTarget()
    local now = tick()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)

    if lockedTarget and (now - lockedAt) * 1000 < Config.Aim.TargetLockMs then
        if H.isAlive(lockedTarget) and not aimShouldIgnore(lockedTarget) then
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

    if best then
        lockedTarget = best
        lockedAt = now
    end

    return best, bestPos
end

local function aimAt(pos)
    if Config.Aim.Mode == "camera" then
        local camCF = Camera.CFrame
        local newCF = CFrame.new(camCF.Position, pos)
        local alpha = math.clamp(Config.Aim.Smooth, 0.02, 1)

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
        local delta = (screen - center) * math.clamp(Config.Aim.Smooth, 0.05, 1)
        if math.abs(delta.X) < 1 and math.abs(delta.Y) < 1 then return end
        if mousemoverel then mousemoverel(delta.X, delta.Y) end
    end
end

local function updateAim()
    if not Config.Aim.Enabled or not aimHeld then return end
    if not H.isAlive(LocalPlayer.Character) then return end

    local target, pos = pickAimTarget()
    if not target or not pos then return end

    if Config.Aim.WallCheck then
        local part = H.resolvePart(target, Config.Aim.Part)
        if not H.isVisible(target, part) then return end
    end

    aimAt(pos)
end

-- ============ NORECOIL ============

local function updateNoRecoil()
    if not Config.Aim.NoRecoil then
        if next(savedRecoil) then
            for obj, val in pairs(savedRecoil) do pcall(function() obj.Value = val end) end
            savedRecoil = {}
        end
        return
    end
    local cv = Camera:FindFirstChild("Recoil") or Camera:FindFirstChild("RecoilValue")
    if cv and cv:IsA("NumberValue") and savedRecoil[cv] == nil then
        savedRecoil[cv] = cv.Value; cv.Value = 0
    end
    local char = LocalPlayer.Character
    if char then
        for _, n in ipairs({"Recoil","RecoilValue","WeaponRecoil"}) do
            local v = char:FindFirstChild(n)
            if v and v:IsA("NumberValue") and savedRecoil[v] == nil then
                savedRecoil[v] = v.Value; v.Value = 0
            end
        end
    end
end

-- ============ SILENT ============

local silentTarget, silentFrozenPos = nil, nil
local silentLockedAt = 0

local function silentShouldIgnore(m)
    return H.shouldIgnore(m, {
        StrictTeam = Config.Silent.StrictTeam,
        FriendCheck = Config.Silent.FriendCheck,
        IgnoreWhitelist = Config.Silent.IgnoreWhitelist,
    })
end

local function getSilentTarget()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local best, bestScore, bestPos = nil, math.huge, nil

    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not silentShouldIgnore(m) then
            local part = H.resolvePart(m, Config.Silent.Part)
            local pos = H.partPos(m, part)
            if pos then
                if Config.Silent.Prediction then
                    pos = predictPos(m, pos, Config.Silent.PredictionStrength)
                end
                local visibleOk = true
                if Config.Silent.RequireVisible then
                    visibleOk = H.isVisible(m, part)
                end
                if visibleOk then
                    local sc = H.w2s(pos)
                    if sc then
                        local pxD = (sc - center).Magnitude
                        local worldD = (camPos - pos).Magnitude
                        local score = pxD + worldD * 0.05
                        if score < bestScore then
                            best, bestScore, bestPos = m, score, pos
                        end
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
    if silentTarget and silentFrozenPos and (now - silentLockedAt) * 1000 < Config.Silent.FreezeMs then
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
                if (now - (getgenv()._silent_lastshot or 0)) * 1000 < Config.Silent.PerShotCooldownMs then
                    return old(self, ...)
                end
                getgenv()._silent_lastshot = now

                local args = {...}
                local mod = false
                for i = 1, #args do
                    if typeof(args[i]) == "Vector3" then
                        if Config.Silent.SubstitutionMode == "all" then
                            args[i] = silentFrozenPos
                            mod = true
                        else
                            local distToCam = (args[i] - Camera.CFrame.Position).Magnitude
                            if distToCam > 5 then
                                args[i] = silentFrozenPos
                                mod = true
                            end
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

-- ============ TRIGGER ============

local lastFireAttempt = 0
local lastAutoDelay = 0.06

local function getCurrentTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function toolReady(tool)
    if not Config.Trigger.RequireTool then return true end
    if not tool then return false end
    if not tool.Enabled then return false end
    local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("AmmoValue")
    if ammo and ammo:IsA("IntValue") and ammo.Value <= 0 then return false end
    return true
end

local function fireWeapon()
    local mode = Config.Trigger.FireMode
    local tool = getCurrentTool()
    if mode == "mouse1click" or mode == "both" then
        if mouse1click then pcall(mouse1click) end
    end
    if (mode == "remoteevent" or mode == "both") and tool then
        for _, name in ipairs({"Fire","Shoot","Attack","FireWeapon","ShootEvent","FireEvent"}) do
            local r = tool:FindFirstChild(name)
            if r and r:IsA("RemoteEvent") then
                pcall(function() r:FireServer() end)
                break
            end
        end
    end
end

local function triggerShouldIgnore(m)
    return H.shouldIgnore(m, {
        StrictTeam = Config.Trigger.StrictTeam,
        FriendCheck = Config.Trigger.FriendCheck,
        IgnoreWhitelist = Config.Trigger.IgnoreWhitelist,
    })
end

local function isCrosshairInEspBox(m)
    local head = H.getHead(m)
    local root = H.getRoot(m)
    if not head or not root then return false end
    local top = H.w2s(head.Position + Vector3.new(0,1,0))
    local bot = H.w2s(root.Position - Vector3.new(0,3,0))
    if not top or not bot then return false end
    local h = bot.Y - top.Y
    local w = h * 0.5
    local boxX1, boxX2 = top.X - w/2, top.X + w/2
    local boxY1, boxY2 = top.Y, bot.Y
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    return center.X >= boxX1 and center.X <= boxX2 and center.Y >= boxY1 and center.Y <= boxY2
end

local function isCrosshairOnHitbox(m)
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    for _, part in ipairs(m:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local sp = H.w2s(part.Position)
            if sp then
                local rad = 40
                if part.Name == "Head" then rad = 25 end
                if part.Name == "UpperTorso" or part.Name == "Torso" then rad = 45 end
                if part.Name == "LowerTorso" then rad = 40 end
                if (sp - center).Magnitude < rad then return true end
            end
        end
    end
    return false
end

local function getBestTriggerTarget()
    local camPos = Camera.CFrame.Position
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not triggerShouldIgnore(m) then
            local root = H.getRoot(m)
            local hum = H.getHumanoid(m)
            if root and hum then
                local d = (camPos - root.Position).Magnitude
                if d >= Config.Trigger.MinDist and d <= Config.Trigger.MaxDist then
                    local hp = hum.Health
                    if hp >= Config.Trigger.HpMin and hp <= Config.Trigger.HpMax then
                        local wallOk = true
                        if Config.Trigger.WallCheck then
                            local part = H.resolvePart(m, "Head")
                            wallOk = H.isVisible(m, part)
                        end
                        if wallOk then
                            local inAim = false
                            if Config.Trigger.Mode == "pixel-center" then
                                local part = H.resolvePart(m, "Head")
                                local pos = H.partPos(m, part)
                                if pos then
                                    local sc = H.w2s(pos)
                                    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
                                    if sc and (sc - center).Magnitude < Config.Trigger.PixelRadius then
                                        inAim = true
                                    end
                                end
                            elseif Config.Trigger.Mode == "esp-box" then
                                inAim = isCrosshairInEspBox(m)
                            elseif Config.Trigger.Mode == "hitbox-projection" then
                                inAim = isCrosshairOnHitbox(m)
                            end
                            if inAim then return m end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function updateTrigger()
    if not Config.Trigger.Enabled then return end
    if not Config.Trigger.AlwaysOn and not trigHeld then return end
    if not H.isAlive(LocalPlayer.Character) then return end

    local now = tick()
    local delay = Config.Trigger.Delay
    if Config.Trigger.AutoDelay then delay = lastAutoDelay end
    if now - lastShot < delay then return end

    local tool = getCurrentTool()
    if not toolReady(tool) then return end

    local target = getBestTriggerTarget()
    if not target then return end

    if Config.Trigger.AutoDelay and tool then
        local rate = tool:GetAttribute("FireRate") or tool:GetAttribute("RPM")
        if type(rate) == "number" and rate > 0 then
            lastAutoDelay = math.max(0.03, 60 / rate * 1.1)
        else
            lastAutoDelay = Config.Trigger.Delay
        end
    end

    fireWeapon()
    lastShot = now
    if getgenv()._silent_lastshot == nil then getgenv()._silent_lastshot = 0 end
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

getgenv().vanta_update_aim = updateAim
getgenv().vanta_update_silent = updateSilent
getgenv().vanta_update_trigger = updateTrigger
getgenv().vanta_update_norecoil = updateNoRecoil
print("[zeusx] part 5/11 OK")-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 6/11 — move + antiban + watermark
-- ============================================================

local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera     = Workspace.CurrentCamera
local Config     = getgenv().vanta_cfg
local origWalkSpeed = getgenv().vanta_orig.WalkSpeed

local function clampSpeed(v)
    if v > Config.Anti.StealthSpeedCap then return Config.Anti.StealthSpeedCap end
    return v
end
local function clampFly(v)
    return math.min(v, Config.Anti.StealthFlyCap)
end

local function updateMove()
    local char = LocalPlayer.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if Config.Move.Speed then hum.WalkSpeed = clampSpeed(Config.Move.SpeedVal)
    elseif hum.WalkSpeed ~= origWalkSpeed then hum.WalkSpeed = origWalkSpeed end

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
        hrp.Velocity = dir.Magnitude > 0 and dir.Unit * clampFly(Config.Move.FlySpeed) or Vector3.zero
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
    local c = LocalPlayer.Character; if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end

local function updateAutoRespawn()
    if not Config.Move.AutoRespawn then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        task.wait(1)
        pcall(function() LocalPlayer:LoadCharacter() end)
    end
end

local function antiFling()
    if not Config.Anti.AntiFling then return end
    local c = LocalPlayer.Character; if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    pcall(function()
        hrp.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.01, 1, 1)
    end)
end

task.spawn(function()
    while task.wait(60) do
        if not Config.Anti.AntiAFK then continue end
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not Config.Anti.AntiVoid then continue end
        local c = LocalPlayer.Character; if not c then continue end
        local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        local fpd = Workspace.FallenPartsDestroyHeight or -500
        if hrp.Position.Y < fpd + 50 then
            pcall(function()
                hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
                hrp.Velocity = Vector3.zero
            end)
        end
    end
end)

local wm
local function updateWatermark()
    if Config.Misc.Watermark then
        if not wm then
            local parent = (gethui and gethui()) or CoreGui
            wm = Instance.new("TextLabel")
            wm.Size = UDim2.new(0, 340, 0, 28)
            wm.Position = UDim2.new(0, 12, 0, 12)
            wm.BackgroundColor3 = Color3.fromRGB(20,14,30)
            wm.BackgroundTransparency = 0.4
            wm.BorderSizePixel = 0
            wm.Text = "  Zeus-X · v9.5 Global Edition"
            wm.TextColor3 = Color3.fromRGB(180,140,255)
            wm.Font = Enum.Font.GothamBold
            wm.TextSize = 13
            wm.TextXAlignment = Enum.TextXAlignment.Left
            wm.Parent = parent
            Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke")
            s.Color = Color3.fromRGB(170,120,255); s.Thickness = 1; s.Transparency = 0.5
            s.Parent = wm
        end
        wm.Visible = true
    elseif wm then
        wm.Visible = false
    end
end

getgenv().vanta_update_move = updateMove
getgenv().vanta_update_noclip = updateNoclip
getgenv().vanta_update_autorespawn = updateAutoRespawn
getgenv().vanta_update_antifling = antiFling
getgenv().vanta_update_watermark = updateWatermark
print("[zeusx] part 6/11 OK")-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 7/11 — menu core (каркас + widgets)
-- ============================================================

getgenv().vanta_create_menu = function()

local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Config = getgenv().vanta_cfg
local H = getgenv().vanta_h
if not Config then return end

local parent = (gethui and gethui()) or CoreGui
if getgenv().vanta_menu and getgenv().vanta_menu.Parent then getgenv().vanta_menu:Destroy() end

local A = {
    bg=Color3.fromRGB(18,12,28), panel=Color3.fromRGB(38,28,58),
    panelHi=Color3.fromRGB(52,38,80), accent=Color3.fromRGB(180,130,255),
    accent2=Color3.fromRGB(220,150,255), accentD=Color3.fromRGB(110,70,190),
    text=Color3.fromRGB(235,225,250), textDim=Color3.fromRGB(170,155,200),
}
local function tweenQuad(o,t,p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local vp = workspace.CurrentCamera.ViewportSize
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local winW, winH
if isMobile then
    winW = math.floor(vp.X * 0.94)
    winH = math.floor(vp.Y * 0.80)
else
    winW = math.min(680, math.floor(vp.X * 0.70))
    winH = math.min(640, math.floor(vp.Y * 0.82))
end
if winW < 300 then winW = 300 end
if winH < 420 then winH = 420 end

local HEADER_H = 44
local TABS_H   = 38
local TAB_W    = 74

getgenv().zeusx_menu_ctx = {
    A = A, tweenQuad = tweenQuad, Config = Config, H = H,
    tabButtons = {}, scroll = nil, setActiveTab = nil, makeTab = nil,
    section = nil, toggle = nil, slider = nil, dropdown = nil,
    winW = winW, winH = winH, HEADER_H = HEADER_H, TABS_H = TABS_H, TAB_W = TAB_W,
}

local sg = Instance.new("ScreenGui")
sg.Name = "vanta_menu_root"; sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true; sg.DisplayOrder = 999
sg.Parent = parent
getgenv().vanta_menu = sg

local win = Instance.new("Frame")
win.Size = UDim2.new(0, winW, 0, winH)
win.Position = UDim2.new(0.5, -math.floor(winW/2), 0.5, -math.floor(winH/2))
win.BackgroundColor3 = A.bg; win.BackgroundTransparency = 0.22
win.BorderSizePixel = 0; win.Active = true; win.Draggable = true
win.ClipsDescendants = true; win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 16)
local ws = Instance.new("UIStroke"); ws.Color = A.accent; ws.Thickness = 1.4; ws.Transparency = 0.25; ws.Parent = win
local wg = Instance.new("UIGradient")
wg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140,90,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220,150,255)),
}
wg.Rotation = 35; wg.Parent = ws

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, HEADER_H); bar.BackgroundTransparency = 1; bar.Parent = win
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 1, 0); title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1; title.Text = "Zeus-X · v9.5"
title.TextColor3 = A.accent; title.Font = Enum.Font.GothamBold; title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = bar

local function iconBtn(xo, txt, bgc, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 30); b.Position = UDim2.new(1, xo, 0, 7)
    b.BackgroundColor3 = bgc; b.Text = txt; b.TextColor3 = A.textDim
    b.Font = Enum.Font.GothamBold; b.TextSize = 16
    b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Parent = bar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(cb)
    return b
end
local minBtn = iconBtn(-70, "—", A.panel, function() end)
local closeBtn = iconBtn(-36, "×", Color3.fromRGB(60,25,32), function()
    sg:Destroy(); getgenv().vanta_menu = nil
end)

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
tabBar.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
tabBar.Active = true
tabBar.ScrollingEnabled = true
tabBar.Parent = win

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local tabPad = Instance.new("UIPadding")
tabPad.PaddingLeft = UDim.new(0, 2)
tabPad.PaddingRight = UDim.new(0, 2)
tabPad.PaddingTop  = UDim.new(0, 3)
tabPad.PaddingBottom = UDim.new(0, 3)
tabPad.Parent = tabBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -(HEADER_H + TABS_H + 12))
content.Position = UDim2.new(0, 8, 0, HEADER_H + TABS_H + 8)
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
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Active = true
scroll.ScrollingEnabled = true
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
pad.PaddingBottom = UDim.new(0, 14)
pad.Parent = scroll

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    tabBar.Visible = not minimized
    tweenQuad(win, 0.25, {
        Size = minimized and UDim2.new(0, winW, 0, HEADER_H + 8) or UDim2.new(0, winW, 0, winH),
    })
    minBtn.Text = minimized and "+" or "—"
end)

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
    local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.8; s.Parent = row
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
        if Config.Misc.SaveOnChange then pcall(getgenv().zeusx_saveConfig, "default") end
    end)
end

local function slider(label, minV, maxV, get, set, fmt)
    fmt = fmt or "%d"
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 50); row.BackgroundColor3 = A.panel
    row.BackgroundTransparency = 0.55; row.BorderSizePixel = 0; row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.8; s.Parent = row
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -120, 0, 20); lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = A.text
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 100, 0, 20); val.Position = UDim2.new(1, -112, 0, 6)
    val.BackgroundTransparency = 1; val.Text = string.format(fmt, get())
    val.TextColor3 = A.accent2; val.Font = Enum.Font.GothamBold; val.TextSize = 13
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
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; upd(i.Position.X)
        end
    end)
    hit.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if Config.Misc.SaveOnChange then pcall(getgenv().zeusx_saveConfig, "default") end
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                        or i.UserInputType == Enum.UserInputType.Touch) then
            upd(i.Position.X)
        end
    end)
end

local function dropdown(label, options, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 36); row.BackgroundColor3 = A.panel
    row.BackgroundTransparency = 0.55; row.BorderSizePixel = 0; row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.8; s.Parent = row
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -150, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = A.text
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local idx = 1
    for i, o in ipairs(options) do if o == get() then idx = i end end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 24); btn.Position = UDim2.new(1, -140, 0.5, -12)
    btn.BackgroundColor3 = A.panelHi; btn.BackgroundTransparency = 0.3
    btn.Text = options[idx]; btn.TextColor3 = A.accent2
    btn.Font = Enum.Font.Gotham; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        set(options[idx])
        if Config.Misc.SaveOnChange then pcall(getgenv().zeusx_saveConfig, "default") end
    end)
end

local tabButtons = {}
local function setActiveTab(name)
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
    if tabButtons[name] and tabButtons[name].build then tabButtons[name].build() end
end

local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, TAB_W, 1, 0); btn.BackgroundColor3 = A.panel
    btn.BackgroundTransparency = 0.55; btn.Text = name; btn.TextColor3 = A.textDim
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    tabButtons[name] = { btn=btn, build=function() end }
    btn.MouseButton1Click:Connect(function() setActiveTab(name) end)
    return tabButtons[name]
end

getgenv().zeusx_menu_ctx.scroll = scroll
getgenv().zeusx_menu_ctx.tabButtons = tabButtons
getgenv().zeusx_menu_ctx.setActiveTab = setActiveTab
getgenv().zeusx_menu_ctx.makeTab = makeTab
getgenv().zeusx_menu_ctx.section = section
getgenv().zeusx_menu_ctx.toggle = toggle
getgenv().zeusx_menu_ctx.slider = slider
getgenv().zeusx_menu_ctx.dropdown = dropdown

print("[zeusx] part 7/11 OK · menu core")
end -- vanta_create_menu-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 8/11 — табы меню
-- ============================================================

getgenv().zeusx_build_tabs = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx or not ctx.scroll then
        warn("[zeusx] menu ctx not ready")
        return
    end

    local A = ctx.A
    local Config = ctx.Config
    local H = ctx.H
    local scroll = ctx.scroll
    local makeTab = ctx.makeTab
    local section = ctx.section
    local toggle = ctx.toggle
    local slider = ctx.slider
    local dropdown = ctx.dropdown
    local tweenQuad = ctx.tweenQuad

    local function inputBox(label, get, set, placeholder)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 36); row.BackgroundColor3 = A.panel
        row.BackgroundTransparency = 0.55; row.BorderSizePixel = 0; row.Parent = scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.8; s.Parent = row
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 120, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = A.text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1, -150, 0, 24); tb.Position = UDim2.new(0, 140, 0.5, -12)
        tb.BackgroundColor3 = Color3.fromRGB(28,20,44); tb.BackgroundTransparency = 0.2
        tb.BorderSizePixel = 0; tb.Text = get() or ""
        tb.PlaceholderText = placeholder or "default"
        tb.TextColor3 = A.text
        tb.PlaceholderColor3 = Color3.fromRGB(130,115,165)
        tb.Font = Enum.Font.Gotham; tb.TextSize = 13
        tb.ClearTextOnFocus = true; tb.Parent = row
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
        tb.FocusLost:Connect(function(enter)
            if enter then
                set(tb.Text)
                tb.Text = get() or ""
            end
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
        local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.6; s.Parent = b
        b.MouseEnter:Connect(function()
            tweenQuad(b, 0.15, {BackgroundTransparency = 0.1, BackgroundColor3 = A.accent})
        end)
        b.MouseLeave:Connect(function()
            tweenQuad(b, 0.15, {BackgroundTransparency = 0.3, BackgroundColor3 = bg or A.accentD})
        end)
        b.MouseButton1Click:Connect(cb)
    end

    -- ============ AIM ============
    local tAim = makeTab("aim")
    tAim.build = function()
        section("AIMBOT")
        toggle("aimbot", function() return Config.Aim.Enabled end, function(v) Config.Aim.Enabled=v end)
        toggle("strict team", function() return Config.Aim.StrictTeam end, function(v) Config.Aim.StrictTeam=v end)
        toggle("friend check", function() return Config.Aim.FriendCheck end, function(v) Config.Aim.FriendCheck=v end)
        slider("fov", 10, 400, function() return Config.Aim.FOV end, function(v) Config.Aim.FOV=v end)
        slider("smooth %", 2, 100, function() return math.floor(Config.Aim.Smooth*100) end, function(v) Config.Aim.Smooth=v/100 end)
        toggle("wall check", function() return Config.Aim.WallCheck end, function(v) Config.Aim.WallCheck=v end)
        toggle("no recoil", function() return Config.Aim.NoRecoil end, function(v) Config.Aim.NoRecoil=v end)
        toggle("curve наводка", function() return Config.Aim.Curve end, function(v) Config.Aim.Curve=v end)
        toggle("prediction", function() return Config.Aim.Prediction end, function(v) Config.Aim.Prediction=v end)
        slider("prediction %", 0, 200, function() return math.floor(Config.Aim.PredictionStrength*100) end, function(v) Config.Aim.PredictionStrength=v/100 end)
        slider("target lock ms", 0, 500, function() return Config.Aim.TargetLockMs end, function(v) Config.Aim.TargetLockMs=v end)
        dropdown("hit part", {"auto","Head","HumanoidRootPart","UpperTorso"}, function() return Config.Aim.Part end, function(v) Config.Aim.Part=v end)
        dropdown("aim mode", {"camera","mouse"}, function() return Config.Aim.Mode end, function(v) Config.Aim.Mode=v end)
        dropdown("priority", {"score","fov","distance"}, function() return Config.Aim.Priority end, function(v) Config.Aim.Priority=v end)

        section("SILENT AIM")
        toggle("silent aim", function() return Config.Silent.Enabled end, function(v) Config.Silent.Enabled=v end)
        toggle("strict team", function() return Config.Silent.StrictTeam end, function(v) Config.Silent.StrictTeam=v end)
        toggle("friend check", function() return Config.Silent.FriendCheck end, function(v) Config.Silent.FriendCheck=v end)
        slider("hit chance %", 10, 100, function() return Config.Silent.HitChance end, function(v) Config.Silent.HitChance=v end)
        toggle("require visible", function() return Config.Silent.RequireVisible end, function(v) Config.Silent.RequireVisible=v end)
        toggle("prediction", function() return Config.Silent.Prediction end, function(v) Config.Silent.Prediction=v end)
        slider("freeze ms", 0, 500, function() return Config.Silent.FreezeMs end, function(v) Config.Silent.FreezeMs=v end)
        slider("per-shot cooldown ms", 0, 200, function() return Config.Silent.PerShotCooldownMs end, function(v) Config.Silent.PerShotCooldownMs=v end)
        dropdown("substitution", {"all","target-only"}, function() return Config.Silent.SubstitutionMode end, function(v) Config.Silent.SubstitutionMode=v end)

        section("TRIGGERBOT")
        toggle("triggerbot", function() return Config.Trigger.Enabled end, function(v) Config.Trigger.Enabled=v end)
        toggle("always on", function() return Config.Trigger.AlwaysOn end, function(v) Config.Trigger.AlwaysOn=v end)
        toggle("strict team", function() return Config.Trigger.StrictTeam end, function(v) Config.Trigger.StrictTeam=v end)
        toggle("friend check", function() return Config.Trigger.FriendCheck end, function(v) Config.Trigger.FriendCheck=v end)
        toggle("auto delay", function() return Config.Trigger.AutoDelay end, function(v) Config.Trigger.AutoDelay=v end)
        slider("delay ms", 20, 250, function() return math.floor(Config.Trigger.Delay*1000) end, function(v) Config.Trigger.Delay=v/1000 end)
        dropdown("trigger mode", {"esp-box","hitbox-projection","pixel-center"}, function() return Config.Trigger.Mode end, function(v) Config.Trigger.Mode=v end)
        slider("pixel radius", 10, 120, function() return Config.Trigger.PixelRadius end, function(v) Config.Trigger.PixelRadius=v end)
        slider("min distance", 0, 200, function() return Config.Trigger.MinDist end, function(v) Config.Trigger.MinDist=v end)
        slider("max distance", 100, 5000, function() return Config.Trigger.MaxDist end, function(v) Config.Trigger.MaxDist=v end)
        slider("hp min", 0, 500, function() return Config.Trigger.HpMin end, function(v) Config.Trigger.HpMin=v end)
        slider("hp max", 0, 100000, function() return Config.Trigger.HpMax end, function(v) Config.Trigger.HpMax=v end)
        toggle("wall check", function() return Config.Trigger.WallCheck end, function(v) Config.Trigger.WallCheck=v end)
        toggle("require tool", function() return Config.Trigger.RequireTool end, function(v) Config.Trigger.RequireTool=v end)
        dropdown("fire mode", {"both","mouse1click","remoteevent"}, function() return Config.Trigger.FireMode end, function(v) Config.Trigger.FireMode=v end)
    end

    -- ============ ESP ============
    local tEsp = makeTab("esp")
    tEsp.build = function()
        section("ESP")
        toggle("esp enable", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled=v end)
        toggle("box", function() return Config.ESP.Box end, function(v) Config.ESP.Box=v end)
        toggle("name", function() return Config.ESP.Name end, function(v) Config.ESP.Name=v end)
        toggle("health", function() return Config.ESP.Health end, function(v) Config.ESP.Health=v end)
        toggle("distance", function() return Config.ESP.Distance end, function(v) Config.ESP.Distance=v end)
        toggle("tracer", function() return Config.ESP.Tracer end, function(v) Config.ESP.Tracer=v end)
        section("TEAM FILTER")
        toggle("strict team", function() return Config.ESP.StrictTeam end, function(v) Config.ESP.StrictTeam=v end)
        toggle("friend check", function() return Config.ESP.FriendCheck end, function(v) Config.ESP.FriendCheck=v end)
        toggle("show teammates", function() return Config.ESP.ShowTeammates end, function(v) Config.ESP.ShowTeammates=v end)
        section("RANGE")
        slider("max distance", 50, 3000, function() return Config.ESP.MaxDist end, function(v) Config.ESP.MaxDist=v end)
        slider("min parts", 3, 30, function() return Config.ESP.MinParts end, function(v) Config.ESP.MinParts=v end)
    end

    -- ============ TEAM ============
    local tTeam = makeTab("team")
    tTeam.build = function()
        section("TEAM DETECTION")
        toggle("strict team (3 источника)", function() return Config.Aim.StrictTeam end, function(v)
            Config.Aim.StrictTeam = v; Config.Silent.StrictTeam = v
            Config.Trigger.StrictTeam = v; Config.ESP.StrictTeam = v
        end)
        toggle("friend check", function() return Config.Aim.FriendCheck end, function(v)
            Config.Aim.FriendCheck = v; Config.Silent.FriendCheck = v
            Config.Trigger.FriendCheck = v; Config.ESP.FriendCheck = v
        end)
        toggle("ignore whitelist", function() return Config.Aim.IgnoreWhitelist end, function(v)
            Config.Aim.IgnoreWhitelist = v; Config.Silent.IgnoreWhitelist = v
            Config.Trigger.IgnoreWhitelist = v; Config.ESP.IgnoreWhitelist = v
        end)
        toggle("esp: show teammates", function() return Config.ESP.ShowTeammates end, function(v)
            Config.ESP.ShowTeammates = v
        end)

        section("WHITELIST — всегда ignore")
        inputBox("добавить ник", function() return "" end, function(v)
            if v and v ~= "" then
                table.insert(Config.Team.Whitelist, v)
                getgenv().vanta_notify("wl add: " .. v, 2)
            end
        end, "введи ник + Enter")
        button("очистить whitelist", function()
            Config.Team.Whitelist = {}
            getgenv().vanta_notify("whitelist cleared", 2)
        end)
        button("показать whitelist", function()
            local s = #Config.Team.Whitelist == 0 and "(пусто)" or table.concat(Config.Team.Whitelist, ", ")
            getgenv().vanta_notify("wl: " .. s, 4)
        end)

        section("BLACKLIST — всегда показывать")
        inputBox("добавить ник", function() return "" end, function(v)
            if v and v ~= "" then
                table.insert(Config.Team.Blacklist, v)
                getgenv().vanta_notify("bl add: " .. v, 2)
            end
        end, "введи ник + Enter")
        button("очистить blacklist", function()
            Config.Team.Blacklist = {}
            getgenv().vanta_notify("blacklist cleared", 2)
        end)
        button("показать blacklist", function()
            local s = #Config.Team.Blacklist == 0 and "(пусто)" or table.concat(Config.Team.Blacklist, ", ")
            getgenv().vanta_notify("bl: " .. s, 4)
        end)

        section("DEBUG")
        button("debug: команды в консоль", function()
            if H.teamDebug then H.teamDebug() end
        end)
    end

    -- ============ MOVE ============
    local tMove = makeTab("move")
    tMove.build = function()
        section("SPEED")
        toggle("speed", function() return Config.Move.Speed end, function(v) Config.Move.Speed=v end)
        slider("speed value", 16, 250, function() return Config.Move.SpeedVal end, function(v) Config.Move.SpeedVal=v end)
        section("FLY")
        toggle("fly", function() return Config.Move.Fly end, function(v) Config.Move.Fly=v end)
        slider("fly speed", 10, 300, function() return Config.Move.FlySpeed end, function(v) Config.Move.FlySpeed=v end)
        section("OTHER")
        toggle("infinite jump", function() return Config.Move.InfJump end, function(v) Config.Move.InfJump=v end)
        toggle("noclip", function() return Config.Move.Noclip end, function(v) Config.Move.Noclip=v end)
        toggle("auto respawn", function() return Config.Move.AutoRespawn end, function(v) Config.Move.AutoRespawn=v end)
    end

    -- ============ VISUAL ============
    local tVis = makeTab("visual")
    tVis.build = function()
        section("VISUAL")
        toggle("fullbright", function() return Config.Vis.Fullbright end, function(v)
            Config.Vis.Fullbright = v
            local L = game:GetService("Lighting")
            if v then
                L.Ambient = Color3.fromRGB(178,178,178)
                L.OutdoorAmbient = Color3.fromRGB(178,178,178)
                L.Brightness = 2
            else
                L.Ambient = Color3.fromRGB(70,70,70)
                L.OutdoorAmbient = Color3.fromRGB(70,70,70)
                L.Brightness = 1
            end
        end)
        toggle("no fog", function() return Config.Vis.NoFog end, function(v)
            Config.Vis.NoFog = v
            game:GetService("Lighting").FogEnd = v and 1e6 or 100000
        end)
        slider("camera fov", 60, 120, function() return Config.Vis.FOV end, function(v)
            Config.Vis.FOV = v
            game:GetService("Workspace").CurrentCamera.FieldOfView = v
        end)
    end

    -- ============ MISC ============
    local tMisc = makeTab("misc")
    tMisc.build = function()
        section("MISC")
        toggle("kill notify", function() return Config.Misc.KillNotify end, function(v) Config.Misc.KillNotify=v end)
        toggle("watermark", function() return Config.Misc.Watermark end, function(v) Config.Misc.Watermark=v end)
        section("ANTI-BAN")
        toggle("anti-afk", function() return Config.Anti.AntiAFK end, function(v) Config.Anti.AntiAFK=v end)
        toggle("anti-fling", function() return Config.Anti.AntiFling end, function(v) Config.Anti.AntiFling=v end)
        toggle("anti-void", function() return Config.Anti.AntiVoid end, function(v) Config.Anti.AntiVoid=v end)
        slider("speed cap", 20, 120, function() return Config.Anti.StealthSpeedCap end, function(v) Config.Anti.StealthSpeedCap=v end)
        slider("fly cap", 20, 200, function() return Config.Anti.StealthFlyCap end, function(v) Config.Anti.StealthFlyCap=v end)
    end

    -- ============ CONFIG ============
    local tCfg = makeTab("config")
    tCfg.build = function()
        section("SAVE / LOAD")
        inputBox("slot name",
            function() return getgenv().zeusx_cfg_slot or "default" end,
            function(v) getgenv().zeusx_cfg_slot = v end)
        button("сохранить конфиг", function()
            local s = getgenv().zeusx_cfg_slot or "default"
            local ok = getgenv().zeusx_saveConfig(s)
            getgenv().vanta_notify(ok and ("saved · " .. s) or "save failed")
        end)
        button("загрузить конфиг", function()
            local s = getgenv().zeusx_cfg_slot or "default"
            local ok = getgenv().zeusx_loadConfig(s)
            getgenv().vanta_notify(ok and ("loaded · " .. s) or "load failed")
            if ok and getgenv().vanta_create_menu then
                getgenv().vanta_create_menu()
                if getgenv().zeusx_build_tabs then getgenv().zeusx_build_tabs() end
            end
        end)
        button("список конфигов", function()
            local l = getgenv().zeusx_listConfigs()
            local s = "configs: "
            if #l == 0 then s = s .. "(пусто)"
            else for _, n in ipairs(l) do s = s .. n .. " " end end
            getgenv().vanta_notify(s, 4)
        end)
        section("AUTO")
        toggle("save on change", function() return Config.Misc.SaveOnChange end, function(v) Config.Misc.SaveOnChange=v end)
        section("KEY")
        button("сменить ключ", function()
            getgenv().vanta_set_key(nil)
            if getgenv().vanta_show_keygate then
                getgenv().vanta_show_keygate(getgenv().vanta_on_success, "")
            end
        end)
    end

    -- ============ INFO ============
    local tInfo = makeTab("info")
    tInfo.build = function()
        section("ZEUS-X")
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -10, 0, 110); info.BackgroundColor3 = A.panel
        info.BackgroundTransparency = 0.55
        info.Text = "Zeus-X · v9.5 Global Edition\ndj build · antiban bundle\nstable aim/silent/trigger · team detection\nconfig save/load · friend check · whitelist\n\nTG: @noir_xis"
        info.TextColor3 = A.text; info.Font = Enum.Font.Gotham
        info.TextSize = 13; info.TextWrapped = true
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Parent = scroll
        Instance.new("UICorner", info).CornerRadius = UDim.new(0, 10)
        local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.7; s.Parent = info
    end

    ctx.setActiveTab("aim")
    print("[zeusx] part 8/11 OK · tabs built")
end-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 9/11 — keygate UI + логика
-- ============================================================

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local accent = Color3.fromRGB(180, 130, 255)
local TG_LINK = "https://t.me/noir_xis"

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

getgenv().vanta_show_keygate = function(onSuccess, message)
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("vanta_keygui"); if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "vanta_keygui"; sg.ResetOnSpawn = false
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
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(140,90,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(220,150,255)),
    }
    grad.Rotation = 35; grad.Parent = stroke

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
        local ok, left = getgenv().vanta_checkKey(entered)
        btn.Active = true; btn.Text = "войти"
        if not ok then
            status.TextColor3 = Color3.fromRGB(255,120,140)
            status.Text = left or "ошибка"
            box.Text = ""
            return
        end
        getgenv().vanta_set_key(entered)
        status.TextColor3 = Color3.fromRGB(180,255,180)
        status.Text = "доступ разрешён"
        timerLbl.Text = "осталось: " .. formatTime(left)
        task.wait(1.2)
        sg:Destroy(); onSuccess()
    end

    btn.MouseButton1Click:Connect(try)
    box.FocusLost:Connect(function(e) if e then try() end end)
end

print("[zeusx] part 9/11 OK")-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 10/11 — main loop
-- ============================================================

local RunService = game:GetService("RunService")

if not getgenv().vanta_loop_started then
    getgenv().vanta_loop_started = true
    local accum = 0
    RunService.RenderStepped:Connect(function(dt)
        pcall(function() getgenv().vanta_update_aim() end)
        pcall(function() getgenv().vanta_update_silent() end)
        pcall(function() getgenv().vanta_update_trigger() end)
        pcall(function() getgenv().vanta_update_norecoil() end)
        pcall(function() getgenv().vanta_update_move() end)
        pcall(function() getgenv().vanta_update_noclip() end)
        pcall(function() getgenv().vanta_update_autorespawn() end)
        pcall(function() getgenv().vanta_update_antifling() end)
        pcall(function() getgenv().vanta_update_watermark() end)
        accum += dt
        if accum < 1/60 then return end
        accum = 0
        pcall(function() getgenv().vanta_render_esp() end)
    end)
    print("[zeusx] loop запущен")
end

print("[zeusx] part 10/11 OK")-- ============================================================
-- Zeus-X v9.5 · ЧАСТЬ 11/11 — bootstrap
-- ============================================================

getgenv().vanta_on_success = function()
    if getgenv().vanta_init_esp then getgenv().vanta_init_esp() end
    if getgenv().vanta_create_menu then getgenv().vanta_create_menu() end
    task.wait(0.15)
    if getgenv().zeusx_build_tabs then getgenv().zeusx_build_tabs() end
    getgenv().vanta_notify("Zeus-X v9.5 online · " .. game:GetService("Players").LocalPlayer.Name, 2.5)
end

-- ключ всегда вводится заново, проверяется на сервере
task.spawn(function()
    getgenv().vanta_show_keygate(getgenv().vanta_on_success)
end)

print("[zeusx] v9.5 Global Edition loaded · " .. "https://zeus-key-mjep.onrender.com/check")