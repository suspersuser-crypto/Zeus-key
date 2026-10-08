-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 1/25
-- services + config + hwid + keygate core + safe-log
-- ============================================================

Players      = Players or game:GetService("Players")
RunService   = RunService or game:GetService("RunService")
UIS          = UIS or game:GetService("UserInputService")
Workspace    = Workspace or game:GetService("Workspace")
HttpService  = HttpService or game:GetService("HttpService")
CoreGui      = CoreGui or game:GetService("CoreGui")
TweenService = TweenService or game:GetService("TweenService")
Lighting     = Lighting or game:GetService("Lighting")
LocalPlayer  = LocalPlayer or Players.LocalPlayer
Camera       = Camera or Workspace.CurrentCamera

SERVER_URL = "https://zeus-key-mjep.onrender.com/check"
TG_LINK    = "https://t.me/noir_xis"
CFG_DIR    = "zeusx"

if isfolder and not isfolder(CFG_DIR) then pcall(makefolder, CFG_DIR) end

getgenv().zeusx_log = function(tag, ...)
    local args = {...}
    pcall(function()
        local msg = "[zeusx][" .. tostring(tag) .. "]"
        for _, v in ipairs(args) do msg = msg .. " " .. tostring(v) end
        print(msg)
        warn(msg)
    end)
end

getgenv().vanta_cfg = {
    Aim = {
        Enabled=false, FOV=120, Smooth=0.35,
        Key=Enum.UserInputType.MouseButton2,
        FastKey=Enum.KeyCode.LeftShift,
        FastSmooth=0.9,
        Visible=true, WallCheck=true,
        StrictTeam=true, FriendCheck=true, IgnoreWhitelist=true,
        Part="auto", Mode="camera", NoRecoil=true, Priority="score",
        Prediction=false, PredictionStrength=0.5,
        TargetLockMs=180, Curve=true, SwitchDelayMs=0,
        IgnoreDying=true, DyingHpPct=15,
        DisableOnFire=false,
        WeightFov=1.0, WeightDist=0.1,
        FovCircle=false,
    },
    Silent = {
        Enabled=false, HitChance=100,
        StrictTeam=true, FriendCheck=true, IgnoreWhitelist=true,
        RequireVisible=true, Part="auto",
        PartAutoFallback=true,
        SubstitutionMode="all", Mode="vector",
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
        Burst=1, BurstGapMs=50,
        PrefireMs=0, AfterKillDelayMs=0,
        RatePerSec=0,
        WeaponBlacklist={},
        WeaponWhitelist={},
        WhitelistMode=false,
    },
    ESP = {
        Enabled=false,
        Box=true, Name=true, Health=true, Distance=true, Tracer=false,
        Skeleton=false, Chams=false, HeadDot=false, Weapon=false,
        OffScreenArrows=false, CustomFont="GothamBold",
        StrictTeam=true, FriendCheck=true, IgnoreWhitelist=true,
        ShowTeammates=false,
        MaxDist=2000, MinParts=5,
        HpFormat="hp",
        TracerStyle="bottom",
        DistanceColor=true,
        EnemyFrame=true,
        FriendColor=true,
        Box3D=false,
        Box3DColor=Color3.fromRGB(180,130,255),
        Box3DTransparency=0.6,
        BoxColor=Color3.fromRGB(170,120,255),
        ChamsColor=Color3.fromRGB(255,80,80),
    },
    Move = {
        Speed=false, SpeedVal=28, SpeedMode="walkspeed",
        Fly=false, FlySpeed=50, FlyMode="velocity", FlySmooth=false,
        InfJump=false, Noclip=false, NoclipMode="collide",
        AutoRespawn=false, AntiGravity=false, Gravity=100,
        BHop=false,
        NoFallDamage=false,
    },
    Vis = {
        Fullbright=false, FullbrightMode="ambient", NoFog=false, FOV=70,
        Skybox=false, SkyboxId="",
        Ambient=false, AmbientColor=Color3.fromRGB(178,178,178),
        Freecam=false, ZoomExtend=false,
        RemoveTextures=false, RemoveAccessories=false, NoPost=false,
        RemoveTerrain=false, HighlightSelf=false,
        CustomCrosshair=false, CrosshairColor=Color3.fromRGB(255,80,80),
        NoShadows=false,
    },
    Misc = {
        KillNotify=true, HitMarker=false, HitSound=false,
        DeathNotify=false,
        ChatSpam=false, ChatSpamText="", ChatSpamDelay=5,
        AutoChat=false, AutoChatText="", AutoChatDelay=10,
        FakeLag=false, FakeLagMs=200,
        AntiAFK=true, AutoRejoin=false, ServerHop=false,
        FriendNotify=false, Watermark=true,
        FpsMonitor=false, TimePlayed=false,
        SaveOnChange=false,
        AutoSaveSlot="default",
        PanicKey=Enum.KeyCode.End,
        CustomKeybinds={},
    },
    Anti = {
        AntiFling=true, AntiVoid=true,
        StealthMode=false, Randomization=false,
        StealthSpeedCap=44, StealthFlyCap=72,
        HookHider=false,
        StringEncrypt=false,
        AntiDetect=false, AntiLog=false, AntiScreenshot=false,
        HideFromServer=false,
        NoSpeedDetect=false,
    },
    Team = {
        MyTeamId=nil,
        Whitelist={}, Blacklist={}, Friends={},
        Notes={}, NickTracker={},
    },
    UI = { Theme="purple", Compact=false, SearchOpen=false, NotifyLog={} },
    Key = { Active=nil, Expiry=0, Multi={} },
}

getgenv().vanta_orig = { WalkSpeed=16, JumpPower=50, Gravity=Workspace.Gravity }

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
    if not ok or not response or response == "" then return nil, "нет соединения" end
    local okDecode, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not okDecode or type(data) ~= "table" then return nil, "ошибка формата" end
    if data.ok then return true, data.left or 0, data end
    local reasons = {
        invalid="неверный ключ", hwid_mismatch="ключ на другом устройстве",
        expired="срок истёк", banned="ключ забанен",
        no_activations="активации кончились",
        too_many_attempts="слишком много попыток",
        tampered="скрипт изменён — скачай заново",
        bad_signature="подпись неверна",
    }
    return false, reasons[data.reason] or (data.reason or "ошибка"), data
end

getgenv().vanta_disableAll = function()
    local cfg = getgenv().vanta_cfg
    for _, section in pairs(cfg) do
        if type(section) == "table" then
            for k, v in pairs(section) do
                if type(v) == "boolean" then section[k] = false end
            end
        end
    end
    local p = (gethui and gethui()) or CoreGui
    for _, n in ipairs({"vanta_esp","vanta_menu_root","vanta_keygui","vanta_notify",
                        "vanta_fovcircle","vanta_crosshair","vanta_notify_log",
                        "vanta_fps","vanta_time","vanta_hitmarker","vanta_arrows",
                        "vanta_chams","vanta_skel","vanta_freecam_hint",
                        "vanta_emergency","vanta_box3d"}) do
        local e = p:FindFirstChild(n)
        if e then e:Destroy() end
    end
    getgenv().vanta_menu = nil
end

getgenv().vanta_checkKey = checkKeyOnServer
getgenv().vanta_getHWID = getHWID

getgenv().vanta_set_key = function(k)
    getgenv()._active_key = k
    getgenv().vanta_cfg.Key.Active = k
end
getgenv().vanta_get_key = function() return getgenv()._active_key end

task.spawn(function()
    while task.wait(60) do
        if getgenv()._active_key then
            local ok, msg, data = checkKeyOnServer(getgenv()._active_key)
            if ok == false then
                getgenv()._active_key = nil
                getgenv().vanta_disableAll()
                if getgenv().vanta_show_keygate then
                    getgenv().vanta_show_keygate(getgenv().vanta_on_success, tostring(msg))
                end
                break
            elseif ok == true and data and data.left then
                getgenv().vanta_cfg.Key.Expiry = os.time() + data.left
            end
        end
    end
end)

task.spawn(function()
    while task.wait(300) do
        if getgenv()._active_key then pcall(checkKeyOnServer, getgenv()._active_key) end
    end
end)

getgenv().zeusx_log("part", "1/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 2/25 — config save/load + notify
-- ============================================================

local function deep_copy(t)
    local c = {}
    for k, v in pairs(t) do
        if type(v) == "table" then c[k] = deep_copy(v) else c[k] = v end
    end
    return c
end

local function serialize(v)
    if type(v) == "EnumItem" then return {__enum=true, t=tostring(v.EnumType), n=v.Name} end
    if typeof(v) == "Color3" then return {__color=true, r=v.R, g=v.G, b=v.B} end
    if type(v) == "table" then
        local o = {}
        for k, vv in pairs(v) do o[k] = serialize(vv) end
        return o
    end
    return v
end

local function deserialize(v)
    if type(v) == "table" and v.__enum then
        local ok, e = pcall(function() return Enum[v.t][v.n] end)
        if ok then return e end
    end
    if type(v) == "table" and v.__color then
        return Color3.new(v.r, v.g, v.b)
    end
    if type(v) == "table" then
        local o = {}
        for k, vv in pairs(v) do o[k] = deserialize(vv) end
        return o
    end
    return v
end

local function cfg_path(slot) return CFG_DIR .. "/cfg_" .. (slot or "default") .. ".json" end

getgenv().zeusx_saveConfig = function(slot)
    if not writefile then return false end
    slot = slot or getgenv().vanta_cfg.Misc.AutoSaveSlot or "default"
    local data = serialize(deep_copy(getgenv().vanta_cfg))
    local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    if isfile and isfile(cfg_path(slot)) then
        local okOld, old = pcall(readfile, cfg_path(slot))
        if okOld and old then pcall(writefile, cfg_path(slot) .. ".bak", old) end
    end
    return pcall(writefile, cfg_path(slot), enc)
end

getgenv().zeusx_loadConfig = function(slot)
    if not readfile or not isfile then return false end
    slot = slot or "default"
    local p = cfg_path(slot)
    if not isfile(p) then return false end
    local ok, raw = pcall(readfile, p)
    if not ok or not raw then return false end
    local okD, data = pcall(function() return HttpService:JSONDecode(raw) end)
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

getgenv().zeusx_exportConfig = function(slot)
    if not readfile then return nil end
    local p = cfg_path(slot or "default")
    if not isfile(p) then return nil end
    local ok, raw = pcall(readfile, p)
    if not ok or not raw then return nil end
    if syn and syn.crypt and syn.crypt.base64 then
        local okE, enc = pcall(function() return syn.crypt.base64.encode(raw) end)
        if okE and enc then return enc end
    end
    return raw
end

getgenv().zeusx_importConfig = function(str, slot)
    if not writefile then return false end
    local raw = str
    if syn and syn.crypt and syn.crypt.base64 then
        local okD, dec = pcall(function() return syn.crypt.base64.decode(str) end)
        if okD and dec then raw = dec end
    end
    return pcall(writefile, cfg_path(slot or "default"), raw)
end

getgenv().zeusx_applyPreset = function(name)
    local cfg = getgenv().vanta_cfg
    if name == "legit" then
        cfg.Aim.FOV=60; cfg.Aim.Smooth=0.15; cfg.Aim.Prediction=false; cfg.Aim.TargetLockMs=80
        cfg.Silent.Enabled=false; cfg.Trigger.Enabled=false
    elseif name == "rage" then
        cfg.Aim.FOV=400; cfg.Aim.Smooth=1; cfg.Aim.Prediction=true; cfg.Aim.PredictionStrength=0.9
        cfg.Aim.TargetLockMs=0; cfg.Silent.Enabled=true; cfg.Silent.HitChance=100
        cfg.Trigger.Enabled=true; cfg.Trigger.Delay=0.02
    elseif name == "sniper" then
        cfg.Aim.FOV=30; cfg.Aim.Smooth=0.08; cfg.Aim.Prediction=true; cfg.Aim.PredictionStrength=0.7
        cfg.Aim.Part="Head"; cfg.Trigger.Enabled=false
    elseif name == "cqc" then
        cfg.Aim.FOV=120; cfg.Aim.Smooth=0.4; cfg.Aim.Prediction=false
        cfg.Trigger.Enabled=true; cfg.Trigger.Mode="hitbox-projection"
        cfg.Trigger.MinDist=0; cfg.Trigger.MaxDist=50
    end
    getgenv().vanta_notify("preset: " .. name)
end

getgenv().zeusx_notifyLog = {}

getgenv().vanta_notify = function(text, dur)
    dur = dur or 3
    table.insert(getgenv().zeusx_notifyLog, {t=os.time(), msg=text})
    if #getgenv().zeusx_notifyLog > 50 then table.remove(getgenv().zeusx_notifyLog, 1) end
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("vanta_notify")
    if old then old:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "vanta_notify"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    sg.DisplayOrder = 3000; sg.Parent = parent
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 340, 0, 48)
    f.Position = UDim2.new(0.5, -170, 0, -60)
    f.BackgroundColor3 = Color3.fromRGB(18,12,28)
    f.BackgroundTransparency = 0.15; f.BorderSizePixel = 0; f.Parent = sg
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180,130,255); s.Thickness = 1.4; s.Parent = f
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 1, 0); l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1; l.Text = text
    l.TextColor3 = Color3.fromRGB(235,225,250)
    l.Font = Enum.Font.GothamBold; l.TextSize = 14; l.Parent = f
    local T = TweenService
    T:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -170, 0, 20)}):Play()
    task.delay(dur, function()
        T:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -170, 0, -60)}):Play()
        task.wait(0.3); sg:Destroy()
    end)
end

task.defer(function()
    if getgenv().zeusx_loadConfig("default") then
        getgenv().zeusx_log("config", "'default' загружен")
    end
end)

getgenv().zeusx_log("part", "2/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 3/25 — поиск целей + team detection
-- ============================================================

IGNORE_NAMES = IGNORE_NAMES or { TheMlgShep=true, R15_Dummy=true, Dummy=true }

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
    if #m:GetChildren() < (getgenv().vanta_cfg.ESP.MinParts or 5) then return true end
    return false
end

WS_CONTAINERS = WS_CONTAINERS or {
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

getgenv().vanta_scanMode = "players"
task.spawn(function()
    while task.wait(2) do
        local nP = #collectPlayers()
        local nW = #collectWorkspace()
        if nP >= nW and nP > 0 then
            getgenv().vanta_scanMode = "players"
        elseif nW > nP then
            getgenv().vanta_scanMode = "workspace"
        end
    end
end)

getgenv().vanta_getTargets = function()
    local mode = getgenv().vanta_scanMode
    if mode == "workspace" then
        return collectWorkspace()
    elseif mode == "mixed" then
        local l = collectPlayers()
        for _, m in ipairs(collectWorkspace()) do
            local dup = false
            for _, e in ipairs(l) do
                if e == m then dup = true; break end
            end
            if not dup then table.insert(l, m) end
        end
        return l
    else
        return collectPlayers()
    end
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

RAY_PARAMS = RAY_PARAMS or RaycastParams.new()
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(m, p)
    local part = resolvePart(m, p or "auto")
    local t = partPos(m, part)
    if not t then return false end
    RAY_PARAMS.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    local hit = Workspace:Raycast(Camera.CFrame.Position, t - Camera.CFrame.Position, RAY_PARAMS)
    if not hit then return true end
    return hit.Instance and hit.Instance:IsDescendantOf(m)
end

getgenv().vanta_teamCache = {}
task.spawn(function() while task.wait(5) do getgenv().vanta_teamCache = {} end end)

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
    local cfg = getgenv().vanta_cfg
    if cfg.Team.MyTeamId ~= nil then return "M:" .. tostring(cfg.Team.MyTeamId) end
    return strict and resolveTeamStrict(LocalPlayer) or resolveTeamSoft(LocalPlayer)
end

local function getTargetTeamId(m, strict)
    local key = m.Name .. (strict and ":s" or ":w")
    local cache = getgenv().vanta_teamCache
    if cache[key] ~= nil then return cache[key] end
    local plr = getPlayerOf(m)
    local t
    if strict then
        t = (plr and resolveTeamStrict(plr)) or resolveTeamStrict(m)
    else
        t = (plr and resolveTeamSoft(plr)) or resolveTeamSoft(m)
    end
    cache[key] = t
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
    for _, f in ipairs(getgenv().vanta_cfg.Team.Friends) do
        if tostring(f) == tostring(plr.UserId) then return true end
    end
    return false
end

local function inList(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

getgenv().zeusx_shouldIgnore = function(m, opts)
    opts = opts or {}
    if not m then return true end
    if m == LocalPlayer.Character then return true end
    local cfg = getgenv().vanta_cfg
    if inList(cfg.Team.Blacklist, m.Name) then return false end
    if opts.IgnoreWhitelist ~= false then
        if inList(cfg.Team.Whitelist, m.Name) then return true end
    end
    if opts.FriendCheck ~= false and isFriend(m) then return true end
    local strict = (opts.StrictTeam ~= false)
    if isSameTeam(m, strict) then
        if opts.ShowTeammates then return false end
        return true
    end
    return false
end

task.spawn(function()
    while task.wait(10) do
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local uid = tostring(p.UserId)
                if not getgenv().vanta_cfg.Team.NickTracker[uid] then
                    getgenv().vanta_cfg.Team.NickTracker[uid] = {name=p.Name, first=os.time()}
                end
            end
        end
    end
end)

getgenv().zeusx_teamDebug = function()
    print("=== ZEUS-X TEAM DEBUG ===")
    print("My Team:", LocalPlayer.Team, "| Color:", LocalPlayer.TeamColor)
    local cfg = getgenv().vanta_cfg
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local ign = getgenv().zeusx_shouldIgnore(p.Character, {StrictTeam=cfg.Aim.StrictTeam, FriendCheck=cfg.Aim.FriendCheck})
            print(string.format(" %s | Team=%s | ignore=%s", p.Name, tostring(p.Team), tostring(ign)))
        end
    end
end

task.spawn(function()
    pcall(function()
        if not LocalPlayer.GetFriendsAsync then return end
        local page = LocalPlayer:GetFriendsAsync()
        while true do
            for _, f in ipairs(page:GetCurrentPage()) do
                table.insert(getgenv().vanta_cfg.Team.Friends, f.Id)
            end
            if page.IsFinished then break end
            page:AdvanceToNextPageAsync()
        end
    end)
end)

getgenv().vanta_h = {
    getTargets=getgenv().vanta_getTargets,
    getHumanoid=getHumanoid, getHead=getHead, getRoot=getRoot,
    isAlive=isAlive, sameTeam=function(m) return isSameTeam(m, true) end,
    partPos=partPos, resolvePart=resolvePart,
    w2s=w2s, isVisible=isVisible, getMyTeamId=getMyTeamId,
    teamDebug=getgenv().zeusx_teamDebug,
    shouldIgnore=getgenv().zeusx_shouldIgnore,
    isSameTeam=isSameTeam, isFriend=isFriend,
    getPlayerOf=getPlayerOf,
}

getgenv().zeusx_log("part", "3/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 4/25 — ESP базовый
-- ============================================================

ESP = ESP or nil
ESP_GUI = ESP_GUI or nil

local function initESP()
    if ESP_GUI then return end
    local parent = (gethui and gethui()) or CoreGui
    ESP_GUI = Instance.new("ScreenGui")
    ESP_GUI.Name = "vanta_esp"
    ESP_GUI.ResetOnSpawn = false
    ESP_GUI.IgnoreGuiInset = true
    ESP_GUI.DisplayOrder = 998
    ESP_GUI.Parent = parent
    ESP = setmetatable({}, { __mode = "k" })
end

local function mkLabel(color, size, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.fromRGB(255,255,255)
    l.Font = Enum.Font[font or "GothamBold"] or Enum.Font.GothamBold
    l.TextSize = size or 13
    l.TextStrokeTransparency = 0
    l.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    l.Visible = false
    l.Parent = ESP_GUI
    return l
end

local function createESP(m)
    if ESP[m] then return end
    local cfg = getgenv().vanta_cfg
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false
    box.Parent = ESP_GUI
    local stroke = Instance.new("UIStroke")
    stroke.Color = cfg.ESP.BoxColor; stroke.Thickness = 1.5; stroke.Parent = box

    local hpBg = Instance.new("Frame")
    hpBg.BackgroundColor3 = Color3.fromRGB(20,10,30)
    hpBg.BorderSizePixel = 0; hpBg.Visible = false; hpBg.Parent = ESP_GUI

    local hpFill = Instance.new("Frame")
    hpFill.BackgroundColor3 = Color3.fromRGB(100,220,140)
    hpFill.BorderSizePixel = 0; hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.Parent = hpBg

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = Color3.fromRGB(180,130,255)
    tracer.BackgroundTransparency = 0.4
    tracer.BorderSizePixel = 0; tracer.Visible = false
    tracer.AnchorPoint = Vector2.new(0, 0.5); tracer.Parent = ESP_GUI

    local headDot = Instance.new("Frame")
    headDot.BackgroundColor3 = Color3.fromRGB(255,80,80)
    headDot.BorderSizePixel = 0; headDot.Visible = false
    headDot.Size = UDim2.new(0, 6, 0, 6)
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.Parent = ESP_GUI
    Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)

    ESP[m] = {
        box=box, stroke=stroke, hpBg=hpBg, hpFill=hpFill, tracer=tracer, headDot=headDot,
        name=mkLabel(Color3.fromRGB(255,255,255), 13),
        hp=mkLabel(Color3.fromRGB(180,255,180), 11),
        dist=mkLabel(Color3.fromRGB(200,200,200), 11),
        weapon=mkLabel(Color3.fromRGB(255,220,120), 11),
    }
end

local function destroyESP(m)
    local t = ESP[m]
    if not t then return end
    for _, o in pairs(t) do pcall(function() o:Destroy() end) end
    ESP[m] = nil
end

local function hideAll(t)
    t.box.Visible=false; t.name.Visible=false
    t.hp.Visible=false; t.dist.Visible=false; t.weapon.Visible=false
    t.hpBg.Visible=false; t.tracer.Visible=false; t.headDot.Visible=false
end

local function getWeaponName(m)
    local plr = getgenv().vanta_h.getPlayerOf and getgenv().vanta_h.getPlayerOf(m)
    if plr and plr.Character then
        local tool = plr.Character:FindFirstChildOfClass("Tool")
        if tool then return tool.Name end
    end
    return nil
end

getgenv().vanta_render_esp = function()
    if not ESP_GUI then return end
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not cfg.ESP.Enabled then
        for _, t in pairs(ESP) do hideAll(t) end
        return
    end
    local myPos = Camera.CFrame.Position
    local seen = {}

    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        local t = ESP[m]
        if not t then createESP(m); t = ESP[m] end

        local ignore = H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam, FriendCheck=cfg.ESP.FriendCheck,
            IgnoreWhitelist=cfg.ESP.IgnoreWhitelist, ShowTeammates=cfg.ESP.ShowTeammates,
        })
        local show = H.isAlive(m) and not ignore
        local root = H.getRoot(m)
        if show and root and (myPos - root.Position).Magnitude > cfg.ESP.MaxDist then show = false end
        if not show then
            hideAll(t)
        else
            local head = H.getHead(m)
            local hum = H.getHumanoid(m)
            if not head or not root then
                hideAll(t)
            else
                local top = H.w2s(head.Position + Vector3.new(0,1,0))
                local bot = H.w2s(root.Position - Vector3.new(0,3,0))
                if not top or not bot then
                    hideAll(t)
                else
                    local h = bot.Y - top.Y
                    local w = h * 0.5
                    local cx, cy = top.X, top.Y
                    local dist = (myPos - root.Position).Magnitude
                    local isFriendTarget = cfg.ESP.FriendColor and H.isFriend(m)

                    if isFriendTarget then
                        t.stroke.Color = Color3.fromRGB(120,220,255)
                    elseif cfg.ESP.DistanceColor then
                        local ratio = math.clamp(dist / cfg.ESP.MaxDist, 0, 1)
                        t.stroke.Color = Color3.new(1, 1 - ratio, 0.3)
                    else
                        t.stroke.Color = cfg.ESP.BoxColor
                    end
                    if cfg.ESP.EnemyFrame and not isFriendTarget then
                        t.stroke.Thickness = 2
                    else
                        t.stroke.Thickness = 1.5
                    end

                    t.box.Visible = cfg.ESP.Box
                    t.box.Size = UDim2.new(0, w, 0, h)
                    t.box.Position = UDim2.new(0, cx - w/2, 0, cy)

                    t.name.Visible = cfg.ESP.Name
                    t.name.Text = m.Name
                    t.name.TextColor3 = isFriendTarget and Color3.fromRGB(120,220,255) or Color3.fromRGB(255,255,255)
                    t.name.Size = UDim2.new(0, 200, 0, 16)
                    t.name.Position = UDim2.new(0, cx - 100, 0, cy - 18)

                    local hp = hum and hum.Health or 100
                    local maxHp = hum and hum.MaxHealth or 100
                    local ratio = math.clamp(hp / maxHp, 0, 1)

                    t.hpBg.Visible = cfg.ESP.Health
                    t.hpBg.Size = UDim2.new(0, 3, 0, h)
                    t.hpBg.Position = UDim2.new(0, cx - w/2 - 6, 0, cy)
                    t.hpFill.Size = UDim2.new(1, 0, ratio, 0)
                    t.hpFill.Position = UDim2.new(0, 0, 1 - ratio, 0)
                    t.hpFill.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(100,220,140) or Color3.fromRGB(255,120,140)

                    t.hp.Visible = cfg.ESP.Health
                    if cfg.ESP.HpFormat == "hp_max" then
                        t.hp.Text = math.floor(hp) .. "/" .. math.floor(maxHp)
                    elseif cfg.ESP.HpFormat == "pct" then
                        t.hp.Text = math.floor(ratio*100) .. "%"
                    else
                        t.hp.Text = math.floor(hp) .. " hp"
                    end
                    t.hp.Size = UDim2.new(0, 200, 0, 14)
                    t.hp.Position = UDim2.new(0, cx - 100, 0, cy + h + 2)

                    t.dist.Visible = cfg.ESP.Distance
                    t.dist.Text = math.floor(dist) .. " m"
                    t.dist.Size = UDim2.new(0, 200, 0, 14)
                    t.dist.Position = UDim2.new(0, cx - 100, 0, cy + h + 16)

                    if cfg.ESP.Weapon then
                        local wname = getWeaponName(m)
                        if wname then
                            t.weapon.Visible = true
                            t.weapon.Text = wname
                            t.weapon.Size = UDim2.new(0, 200, 0, 14)
                            t.weapon.Position = UDim2.new(0, cx - 100, 0, cy + h + 30)
                        else
                            t.weapon.Visible = false
                        end
                    else
                        t.weapon.Visible = false
                    end

                    if cfg.ESP.HeadDot then
                        local headScr = H.w2s(head.Position)
                        if headScr then
                            t.headDot.Visible = true
                            t.headDot.Position = UDim2.new(0, headScr.X, 0, headScr.Y)
                        end
                    else
                        t.headDot.Visible = false
                    end

                    if cfg.ESP.Tracer then
                        t.tracer.Visible = true
                        local origin
                        if cfg.ESP.TracerStyle == "top" then
                            origin = Vector2.new(Camera.ViewportSize.X*0.5, 0)
                        elseif cfg.ESP.TracerStyle == "center" then
                            origin = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
                        else
                            origin = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y)
                        end
                        local to = Vector2.new(cx, cy + h)
                        local d = to - origin
                        t.tracer.Size = UDim2.new(0, d.Magnitude, 0, 1)
                        t.tracer.Position = UDim2.new(0, origin.X, 0, origin.Y)
                        t.tracer.Rotation = math.deg(math.atan2(d.Y, d.X))
                    else
                        t.tracer.Visible = false
                    end
                end
            end
        end
    end
    for m in pairs(ESP) do
        if not seen[m] or not m.Parent then destroyESP(m) end
    end
end

getgenv().vanta_init_esp = initESP
getgenv().zeusx_log("part", "4/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 5/25 — ESP advanced (skeleton/chams/arrows)
-- ============================================================

SKEL_GUI = SKEL_GUI or nil
SKEL = SKEL or nil
ARROWS_GUI = ARROWS_GUI or nil
ARROWS = ARROWS or nil
CHAMS_FOLDER = CHAMS_FOLDER or nil

R6_BONES = R6_BONES or {
    {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"},
    {"Torso","Left Leg"}, {"Torso","Right Leg"},
}
R15_BONES = R15_BONES or {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}

local function initSkeleton()
    if SKEL_GUI then return end
    local parent = (gethui and gethui()) or CoreGui
    SKEL_GUI = Instance.new("ScreenGui")
    SKEL_GUI.Name = "vanta_skel"; SKEL_GUI.ResetOnSpawn = false
    SKEL_GUI.IgnoreGuiInset = true; SKEL_GUI.DisplayOrder = 997
    SKEL_GUI.Parent = parent
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
    line.BackgroundColor3 = Color3.fromRGB(220,180,255)
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

getgenv().vanta_render_skeleton = function()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not cfg.ESP.Enabled or not cfg.ESP.Skeleton then
        if SKEL then for m in pairs(SKEL) do destroySkel(m) end end
        return
    end
    initSkeleton()
    local seen = {}
    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        local ignore = H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam, FriendCheck=cfg.ESP.FriendCheck,
            IgnoreWhitelist=cfg.ESP.IgnoreWhitelist, ShowTeammates=cfg.ESP.ShowTeammates,
        })
        if not H.isAlive(m) or ignore then
            if SKEL[m] then destroySkel(m) end
        else
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
                            line = drawLine(sa, sb, SKEL_GUI)
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
    end
    for m in pairs(SKEL) do
        if not seen[m] or not m.Parent then destroySkel(m) end
    end
end

getgenv().vanta_render_chams = function()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not cfg.ESP.Enabled or not cfg.ESP.Chams then
        if CHAMS_FOLDER then for _, h in ipairs(CHAMS_FOLDER:GetChildren()) do h:Destroy() end end
        return
    end
    if not CHAMS_FOLDER then
        CHAMS_FOLDER = Instance.new("Folder")
        CHAMS_FOLDER.Name = "vanta_chams"
        CHAMS_FOLDER.Parent = CoreGui
    end
    local active = {}
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam, FriendCheck=cfg.ESP.FriendCheck,
            IgnoreWhitelist=cfg.ESP.IgnoreWhitelist, ShowTeammates=cfg.ESP.ShowTeammates,
        }) then
            active[m] = true
            local hl = CHAMS_FOLDER:FindFirstChild(m.Name)
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = m.Name; hl.Parent = CHAMS_FOLDER
            end
            hl.Adornee = m
            hl.FillColor = cfg.ESP.ChamsColor
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255,255,255)
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
    for _, h in ipairs(CHAMS_FOLDER:GetChildren()) do
        if not active[h.Name] then
            h.Adornee = nil
            h:Destroy()
        end
    end
end

local function initArrows()
    if ARROWS_GUI then return end
    local parent = (gethui and gethui()) or CoreGui
    ARROWS_GUI = Instance.new("ScreenGui")
    ARROWS_GUI.Name = "vanta_arrows"; ARROWS_GUI.ResetOnSpawn = false
    ARROWS_GUI.IgnoreGuiInset = true; ARROWS_GUI.DisplayOrder = 996
    ARROWS_GUI.Parent = parent
    ARROWS = {}
end

getgenv().vanta_render_arrows = function()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not cfg.ESP.Enabled or not cfg.ESP.OffScreenArrows then
        if ARROWS then for _, a in ipairs(ARROWS) do a.Visible = false end end
        return
    end
    initArrows()
    local idx = 0
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam, FriendCheck=cfg.ESP.FriendCheck,
            IgnoreWhitelist=cfg.ESP.IgnoreWhitelist, ShowTeammates=cfg.ESP.ShowTeammates,
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
                        f.Text = "▲"; f.TextColor3 = Color3.fromRGB(255,255,255)
                        f.Font = Enum.Font.GothamBold; f.TextSize = 16
                        f.Parent = ARROWS_GUI
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

getgenv().zeusx_log("part", "5/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 6/25 — aim stable + fast aim + hook hider
-- ============================================================

AIM_HELD = false
FAST_HELD = false
SAVED_RECOIL = SAVED_RECOIL or {}
FOV_CIRCLE = FOV_CIRCLE or nil
LOCKED_TARGET = nil
LOCKED_AT = 0
SWITCH_PENDING_AT = 0

local function getRootVelocity(model)
    local hrp = getgenv().vanta_h.getRoot(model)
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
    local cfg = getgenv().vanta_cfg
    return getgenv().vanta_h.shouldIgnore(m, {
        StrictTeam=cfg.Aim.StrictTeam, FriendCheck=cfg.Aim.FriendCheck,
        IgnoreWhitelist=cfg.Aim.IgnoreWhitelist,
    })
end

local function dyingCheck(m)
    local cfg = getgenv().vanta_cfg
    if not cfg.Aim.IgnoreDying then return true end
    local hum = getgenv().vanta_h.getHumanoid(m)
    if not hum then return true end
    local pct = hum.Health / math.max(hum.MaxHealth, 1) * 100
    return pct > cfg.Aim.DyingHpPct
end

local function scoreTargetAim(m, fov, camPos, center)
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not H.isAlive(m) then return nil end
    if aimIgnore(m) then return nil end
    if not dyingCheck(m) then return nil end
    local part = H.resolvePart(m, cfg.Aim.Part)
    local pos = H.partPos(m, part)
    if not pos then return nil end
    if cfg.Aim.Prediction then
        pos = predictPos(m, pos, cfg.Aim.PredictionStrength)
    end
    local screen = H.w2s(pos)
    if not screen then return nil end
    local pxD = (screen - center).Magnitude
    if pxD > fov then return nil end
    if cfg.Aim.Visible and not H.isVisible(m, part) then return nil end
    local worldD = (camPos - pos).Magnitude
    local score
    if cfg.Aim.Priority == "distance" then score = worldD
    elseif cfg.Aim.Priority == "fov" then score = pxD
    else score = pxD * cfg.Aim.WeightFov + worldD * cfg.Aim.WeightDist end
    return score, m, pos
end

local function pickAimTarget()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    local now = tick()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)

    if LOCKED_TARGET and (now - LOCKED_AT) * 1000 < cfg.Aim.TargetLockMs then
        if H.isAlive(LOCKED_TARGET) and not aimIgnore(LOCKED_TARGET) then
            local part = H.resolvePart(LOCKED_TARGET, cfg.Aim.Part)
            local pos = H.partPos(LOCKED_TARGET, part)
            if pos then
                if cfg.Aim.Prediction then
                    pos = predictPos(LOCKED_TARGET, pos, cfg.Aim.PredictionStrength)
                end
                local screen = H.w2s(pos)
                if screen and (screen - center).Magnitude <= cfg.Aim.FOV * 1.3 then
                    return LOCKED_TARGET, pos
                end
            end
        end
        LOCKED_TARGET = nil
    end

    local best, bestScore, bestPos = nil, math.huge, nil
    for _, m in ipairs(H.getTargets()) do
        local s, mm, pp = scoreTargetAim(m, cfg.Aim.FOV, camPos, center)
        if s and s < bestScore then best, bestScore, bestPos = mm, s, pp end
    end

    if best and best ~= LOCKED_TARGET and cfg.Aim.SwitchDelayMs > 0 then
        if (now - SWITCH_PENDING_AT) * 1000 < cfg.Aim.SwitchDelayMs then
            return LOCKED_TARGET, nil
        end
        SWITCH_PENDING_AT = now
    end

    if best then LOCKED_TARGET = best; LOCKED_AT = now end
    return best, bestPos
end

local function aimAt(pos)
    local cfg = getgenv().vanta_cfg
    if cfg.Aim.Mode == "camera" then
        local camCF = Camera.CFrame
        local newCF = CFrame.new(camCF.Position, pos)
        local baseSmooth = FAST_HELD and cfg.Aim.FastSmooth or cfg.Aim.Smooth
        local alpha = math.clamp(baseSmooth, 0.02, 1)
        if cfg.Aim.Curve then
            local currentDir = camCF.LookVector
            local targetDir = (pos - camCF.Position).Unit
            local dot = currentDir:Dot(targetDir)
            local angleFactor = math.clamp(1 - dot, 0, 1)
            alpha = alpha * (0.4 + angleFactor * 1.2)
            alpha = math.clamp(alpha, 0.02, 0.95)
        end
        Camera.CFrame = camCF:Lerp(newCF, alpha)
    else
        local screen = getgenv().vanta_h.w2s(pos)
        if not screen then return end
        local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
        local baseSmooth = FAST_HELD and cfg.Aim.FastSmooth or cfg.Aim.Smooth
        local delta = (screen - center) * math.clamp(baseSmooth, 0.05, 1)
        if math.abs(delta.X) < 1 and math.abs(delta.Y) < 1 then return end
        if mousemoverel then mousemoverel(delta.X, delta.Y) end
    end
end

getgenv().vanta_update_aim = function()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not cfg.Aim.Enabled or not AIM_HELD then return end
    if not H.isAlive(LocalPlayer.Character) then return end
    if cfg.Aim.DisableOnFire then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:GetAttribute("IsFiring") then return end
    end
    local target, pos = pickAimTarget()
    if not target or not pos then return end
    if cfg.Aim.WallCheck then
        local part = H.resolvePart(target, cfg.Aim.Part)
        if not H.isVisible(target, part) then return end
    end
    aimAt(pos)
end

getgenv().vanta_update_norecoil = function()
    local cfg = getgenv().vanta_cfg
    if not cfg.Aim.NoRecoil then
        if next(SAVED_RECOIL) then
            for obj, val in pairs(SAVED_RECOIL) do pcall(function() obj.Value = val end) end
            SAVED_RECOIL = {}
        end
        return
    end
    local cv = Camera:FindFirstChild("Recoil") or Camera:FindFirstChild("RecoilValue")
    if cv and cv:IsA("NumberValue") and SAVED_RECOIL[cv] == nil then
        SAVED_RECOIL[cv] = cv.Value; cv.Value = 0
    end
    local char = LocalPlayer.Character
    if char then
        for _, n in ipairs({"Recoil","RecoilValue","WeaponRecoil"}) do
            local v = char:FindFirstChild(n)
            if v and v:IsA("NumberValue") and SAVED_RECOIL[v] == nil then
                SAVED_RECOIL[v] = v.Value; v.Value = 0
            end
        end
    end
end

getgenv().vanta_update_fovcircle = function()
    local cfg = getgenv().vanta_cfg
    if not cfg.Aim.FovCircle or not cfg.Aim.Enabled then
        if FOV_CIRCLE then FOV_CIRCLE.Visible = false end
        return
    end
    local parent = (gethui and gethui()) or CoreGui
    if not FOV_CIRCLE then
        local sg = parent:FindFirstChild("vanta_fovcircle")
        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "vanta_fovcircle"; sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true; sg.DisplayOrder = 995
            sg.Parent = parent
        end
        FOV_CIRCLE = Instance.new("Frame")
        FOV_CIRCLE.BackgroundTransparency = 1
        FOV_CIRCLE.AnchorPoint = Vector2.new(0.5, 0.5)
        FOV_CIRCLE.Position = UDim2.new(0.5, 0, 0.5, 0)
        FOV_CIRCLE.Parent = sg
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(180,130,255); s.Thickness = 1.5; s.Transparency = 0.3
        s.Parent = FOV_CIRCLE
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = FOV_CIRCLE
    end
    FOV_CIRCLE.Visible = true
    FOV_CIRCLE.Size = UDim2.new(0, cfg.Aim.FOV*2, 0, cfg.Aim.FOV*2)
end

getgenv().zeusx_installHookHider = function()
    if not getgenv().vanta_cfg.Anti.HookHider then return end
    pcall(function()
        if hookmetamethod and newcclosure then
            local orig = hookmetamethod
            local hidden = newcclosure(function(...) return orig(...) end)
            pcall(function() getgenv().hookmetamethod = hidden end)
        end
    end)
    getgenv().zeusx_log("hookhider", "installed")
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local cfg = getgenv().vanta_cfg
    if i.UserInputType == cfg.Aim.Key then AIM_HELD = true end
    if i.KeyCode == cfg.Aim.FastKey then FAST_HELD = true end
end)
UIS.InputEnded:Connect(function(i)
    local cfg = getgenv().vanta_cfg
    if i.UserInputType == cfg.Aim.Key then AIM_HELD = false end
    if i.KeyCode == cfg.Aim.FastKey then FAST_HELD = false end
end)

getgenv().zeusx_log("part", "6/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 7/25 — silent aim
-- ============================================================

SILENT_TARGET = nil
SILENT_FROZEN_POS = nil
SILENT_LOCKED_AT = 0
SILENT_PARTS_ORDER = SILENT_PARTS_ORDER or { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" }

local function silentIgnore(m)
    local cfg = getgenv().vanta_cfg
    return getgenv().vanta_h.shouldIgnore(m, {
        StrictTeam=cfg.Silent.StrictTeam, FriendCheck=cfg.Silent.FriendCheck,
        IgnoreWhitelist=cfg.Silent.IgnoreWhitelist,
    })
end

local function silentPickPart(m)
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if cfg.Silent.Part ~= "auto" then
        return H.resolvePart(m, cfg.Silent.Part)
    end
    for _, p in ipairs(SILENT_PARTS_ORDER) do
        local part = m:FindFirstChild(p, true)
        if part and part:IsA("BasePart") then
            if not cfg.Silent.RequireVisible or H.isVisible(m, p) then
                return p
            end
        end
    end
    if cfg.Silent.PartAutoFallback then
        return H.resolvePart(m, "auto")
    end
    return "Head"
end

local function getSilentTarget()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local best, bestScore, bestPos = nil, math.huge, nil

    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not silentIgnore(m) then
            local part = silentPickPart(m)
            local pos = H.partPos(m, part)
            if pos then
                local visibleOk = true
                if cfg.Silent.RequireVisible then visibleOk = H.isVisible(m, part) end
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

getgenv().vanta_update_silent = function()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not cfg.Silent.Enabled then
        SILENT_TARGET, SILENT_FROZEN_POS = nil, nil
        return
    end
    local now = tick()
    if SILENT_TARGET and SILENT_FROZEN_POS and (now - SILENT_LOCKED_AT)*1000 < cfg.Silent.FreezeMs then
        if H.isAlive(SILENT_TARGET) then return end
    end
    SILENT_TARGET, SILENT_FROZEN_POS = getSilentTarget()
    SILENT_LOCKED_AT = now
end

if hookmetamethod and getrawmetatable and setreadonly and newcclosure then
    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        if not old then return end
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local cfg = getgenv().vanta_cfg
            local method = getnamecallmethod()
            if cfg.Silent.Enabled and SILENT_TARGET and SILENT_FROZEN_POS and method == "FireServer" then
                local now = tick()
                if (now - (getgenv()._silent_lastshot or 0))*1000 < cfg.Silent.PerShotCooldownMs then
                    return old(self, ...)
                end
                getgenv()._silent_lastshot = now
                local args = {...}
                local mod = false
                for i = 1, #args do
                    if typeof(args[i]) == "Vector3" then
                        if cfg.Silent.SubstitutionMode == "all" then
                            args[i] = SILENT_FROZEN_POS; mod = true
                        else
                            local dCam = (args[i] - Camera.CFrame.Position).Magnitude
                            if dCam > 5 then args[i] = SILENT_FROZEN_POS; mod = true end
                        end
                    end
                end
                if mod then
                    if math.random(1,100) <= cfg.Silent.HitChance then
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

getgenv().zeusx_log("part", "7/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 8/25 — trigger full
-- ============================================================

TRIG_HELD = false
LAST_SHOT = 0
LAST_AUTO_DELAY = 0.06
LAST_KILL_TIME = 0
SHOT_TIMES = SHOT_TIMES or {}

local function getCurrentTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function inList(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

local function toolReady(tool)
    local cfg = getgenv().vanta_cfg
    if not cfg.Trigger.RequireTool then
        if tool then
            if cfg.Trigger.WhitelistMode then
                if #cfg.Trigger.WeaponWhitelist > 0 and not inList(cfg.Trigger.WeaponWhitelist, tool.Name) then
                    return false
                end
            else
                if inList(cfg.Trigger.WeaponBlacklist, tool.Name) then return false end
            end
        end
        return true
    end
    if not tool then return false end
    if not tool.Enabled then return false end
    local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("AmmoValue")
    if ammo and ammo:IsA("IntValue") and ammo.Value <= 0 then return false end
    if cfg.Trigger.WhitelistMode then
        if #cfg.Trigger.WeaponWhitelist > 0 and not inList(cfg.Trigger.WeaponWhitelist, tool.Name) then
            return false
        end
    else
        if inList(cfg.Trigger.WeaponBlacklist, tool.Name) then return false end
    end
    return true
end

local function fireWeapon()
    local cfg = getgenv().vanta_cfg
    local mode = cfg.Trigger.FireMode
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

local function triggerIgnore(m)
    local cfg = getgenv().vanta_cfg
    return getgenv().vanta_h.shouldIgnore(m, {
        StrictTeam=cfg.Trigger.StrictTeam, FriendCheck=cfg.Trigger.FriendCheck,
        IgnoreWhitelist=cfg.Trigger.IgnoreWhitelist,
    })
end

local function isCrosshairInEspBox(m)
    local H = getgenv().vanta_h
    local head = H.getHead(m); local root = H.getRoot(m)
    if not head or not root then return false end
    local top = H.w2s(head.Position + Vector3.new(0,1,0))
    local bot = H.w2s(root.Position - Vector3.new(0,3,0))
    if not top or not bot then return false end
    local h = bot.Y - top.Y; local w = h * 0.5
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    return center.X >= top.X - w/2 and center.X <= top.X + w/2
       and center.Y >= top.Y and center.Y <= bot.Y
end

local function isCrosshairOnHitbox(m)
    local H = getgenv().vanta_h
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
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    local camPos = Camera.CFrame.Position
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not triggerIgnore(m) then
            local root = H.getRoot(m); local hum = H.getHumanoid(m)
            if root and hum then
                local d = (camPos - root.Position).Magnitude
                if d >= cfg.Trigger.MinDist and d <= cfg.Trigger.MaxDist then
                    local hp = hum.Health
                    if hp >= cfg.Trigger.HpMin and hp <= cfg.Trigger.HpMax then
                        local wallOk = true
                        if cfg.Trigger.WallCheck then
                            local part = H.resolvePart(m, "Head")
                            wallOk = H.isVisible(m, part)
                        end
                        if wallOk then
                            local inAim = false
                            if cfg.Trigger.Mode == "pixel-center" then
                                local part = H.resolvePart(m, "Head")
                                local pos = H.partPos(m, part)
                                if pos then
                                    local sc = H.w2s(pos)
                                    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
                                    if sc and (sc - center).Magnitude < cfg.Trigger.PixelRadius then inAim = true end
                                end
                            elseif cfg.Trigger.Mode == "esp-box" then
                                inAim = isCrosshairInEspBox(m)
                            elseif cfg.Trigger.Mode == "hitbox-projection" then
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

local function rateLimitOk()
    local cfg = getgenv().vanta_cfg
    if cfg.Trigger.RatePerSec <= 0 then return true end
    local now = tick()
    local cutoff = now - 1
    local new = {}
    for _, t in ipairs(SHOT_TIMES) do
        if t >= cutoff then table.insert(new, t) end
    end
    SHOT_TIMES = new
    return #SHOT_TIMES < cfg.Trigger.RatePerSec
end

getgenv().vanta_update_trigger = function()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not cfg.Trigger.Enabled then return end
    if not cfg.Trigger.AlwaysOn and not TRIG_HELD then return end
    if not H.isAlive(LocalPlayer.Character) then return end
    local now = tick()
    if (now - LAST_KILL_TIME)*1000 < cfg.Trigger.AfterKillDelayMs then return end
    local delay = cfg.Trigger.AutoDelay and LAST_AUTO_DELAY or cfg.Trigger.Delay
    if now - LAST_SHOT < delay then return end
    if not rateLimitOk() then return end
    local tool = getCurrentTool()
    if not toolReady(tool) then return end
    local target = getBestTriggerTarget()
    if not target then return end
    if cfg.Trigger.AutoDelay and tool then
        local rate = tool:GetAttribute("FireRate") or tool:GetAttribute("RPM")
        if type(rate) == "number" and rate > 0 then
            LAST_AUTO_DELAY = math.max(0.03, 60 / rate * 1.1)
        else
            LAST_AUTO_DELAY = cfg.Trigger.Delay
        end
    end
    fireWeapon()
    LAST_SHOT = now
    table.insert(SHOT_TIMES, now)
    if cfg.Trigger.Burst > 1 then
        task.spawn(function()
            for i = 2, cfg.Trigger.Burst do
                task.wait(cfg.Trigger.BurstGapMs / 1000)
                if getgenv().vanta_cfg.Trigger.Enabled then fireWeapon() end
            end
        end)
    end
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == getgenv().vanta_cfg.Trigger.Key then TRIG_HELD = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == getgenv().vanta_cfg.Trigger.Key then TRIG_HELD = false end
end)

getgenv().zeusx_log("part", "8/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 9/25 — move
-- ============================================================

ORIG_WALK = getgenv().vanta_orig.WalkSpeed
ORIG_GRAV = getgenv().vanta_orig.Gravity

local function clampSpeed(v)
    local cfg = getgenv().vanta_cfg
    if cfg.Anti.StealthMode and v > cfg.Anti.StealthSpeedCap then return cfg.Anti.StealthSpeedCap end
    return v
end
local function clampFly(v)
    local cfg = getgenv().vanta_cfg
    if cfg.Anti.StealthMode then return math.min(v, cfg.Anti.StealthFlyCap) end
    return v
end

getgenv().vanta_update_move = function()
    local cfg = getgenv().vanta_cfg
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if cfg.Move.Speed then
        hum.WalkSpeed = clampSpeed(cfg.Move.SpeedVal)
    elseif hum.WalkSpeed ~= ORIG_WALK then
        hum.WalkSpeed = ORIG_WALK
    end

    if cfg.Move.Fly then
        hum.PlatformStand = true
        local dir = Vector3.zero
        local camCF = Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        local target = dir.Magnitude > 0 and dir.Unit * clampFly(cfg.Move.FlySpeed) or Vector3.zero
        if cfg.Move.FlySmooth then
            hrp.Velocity = hrp.Velocity:Lerp(target, 0.3)
        else
            hrp.Velocity = target
        end
    elseif hum.PlatformStand then
        hum.PlatformStand = false
    end

    if cfg.Move.AntiGravity then
        Workspace.Gravity = cfg.Move.Gravity
    elseif Workspace.Gravity ~= ORIG_GRAV then
        Workspace.Gravity = ORIG_GRAV
    end
end

UIS.JumpRequest:Connect(function()
    if getgenv().vanta_cfg.Move.InfJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

getgenv().vanta_update_noclip = function()
    if not getgenv().vanta_cfg.Move.Noclip then return end
    local c = LocalPlayer.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end

getgenv().vanta_update_bhop = function()
    if not getgenv().vanta_cfg.Move.BHop then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end
end

getgenv().vanta_update_autorespawn = function()
    if not getgenv().vanta_cfg.Move.AutoRespawn then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        task.wait(1)
        pcall(function() LocalPlayer:LoadCharacter() end)
    end
end

getgenv().zeusx_tpToPlayer = function(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == name and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                myHrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                getgenv().vanta_notify("TP → " .. name)
            end
        end
    end
end

getgenv().zeusx_saveWaypoint = function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        getgenv().vanta_waypoint = hrp.CFrame
        getgenv().vanta_notify("waypoint saved")
    end
end

getgenv().zeusx_tpToWaypoint = function()
    local wp = getgenv().vanta_waypoint
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if wp and hrp then
        hrp.CFrame = wp + Vector3.new(0, 3, 0)
        getgenv().vanta_notify("TP → waypoint")
    end
end

getgenv().vanta_clickTpConn = nil
getgenv().zeusx_setClickTp = function(enabled)
    if getgenv().vanta_clickTpConn then
        getgenv().vanta_clickTpConn:Disconnect()
        getgenv().vanta_clickTpConn = nil
    end
    if not enabled then return end
    getgenv().vanta_clickTpConn = UIS.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftAlt) then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local mouse = LocalPlayer:GetMouse()
            if hrp and mouse and mouse.Hit then
                hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end)
end

getgenv().zeusx_log("part", "9/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 10/25 — visual
-- ============================================================

SAVED_VIS = SAVED_VIS or {}
FREECAM_CONN = nil
FREECAM_STATE = nil
CROSSHAIR_V = nil
CROSSHAIR_H = nil
SELF_HIGHLIGHT = nil

getgenv().vanta_update_vis = function()
    local cfg = getgenv().vanta_cfg
    if cfg.Vis.Fullbright then
        if not SAVED_VIS.ambient then
            SAVED_VIS.ambient = Lighting.Ambient
            SAVED_VIS.out = Lighting.OutdoorAmbient
            SAVED_VIS.bright = Lighting.Brightness
        end
        if cfg.Vis.FullbrightMode == "ambient" then
            Lighting.Ambient = Color3.fromRGB(178,178,178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
            Lighting.Brightness = 2
        elseif cfg.Vis.FullbrightMode == "bloom" then
            local b = Lighting:FindFirstChild("vanta_bloom")
            if not b then
                b = Instance.new("BloomEffect")
                b.Name = "vanta_bloom"; b.Intensity = 1.5; b.Size = 24; b.Threshold = 0.5
                b.Parent = Lighting
            end
        end
    elseif SAVED_VIS.ambient then
        Lighting.Ambient = SAVED_VIS.ambient
        Lighting.OutdoorAmbient = SAVED_VIS.out
        Lighting.Brightness = SAVED_VIS.bright
        SAVED_VIS.ambient = nil
    end

    if cfg.Vis.NoFog then
        if not SAVED_VIS.fog then SAVED_VIS.fog = Lighting.FogEnd end
        Lighting.FogEnd = 1e6
    elseif SAVED_VIS.fog then
        Lighting.FogEnd = SAVED_VIS.fog; SAVED_VIS.fog = nil
    end

    if cfg.Vis.Ambient then Lighting.Ambient = cfg.Vis.AmbientColor end

    if cfg.Vis.Skybox and cfg.Vis.SkyboxId ~= "" then
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if not sky then sky = Instance.new("Sky"); sky.Parent = Lighting end
        pcall(function()
            sky.SkyboxBk = "rbxassetid://" .. cfg.Vis.SkyboxId
            sky.SkyboxDn = "rbxassetid://" .. cfg.Vis.SkyboxId
            sky.SkyboxFt = "rbxassetid://" .. cfg.Vis.SkyboxId
            sky.SkyboxLf = "rbxassetid://" .. cfg.Vis.SkyboxId
            sky.SkyboxRt = "rbxassetid://" .. cfg.Vis.SkyboxId
            sky.SkyboxUp = "rbxassetid://" .. cfg.Vis.SkyboxId
        end)
    end

    Camera.FieldOfView = math.min(cfg.Vis.FOV, 160)

    if cfg.Vis.NoPost then
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") or e:IsA("Atmosphere") then
                if not SAVED_VIS.post then SAVED_VIS.post = {} end
                SAVED_VIS.post[e] = e.Enabled
                e.Enabled = false
            end
        end
    elseif SAVED_VIS.post then
        for e, v in pairs(SAVED_VIS.post) do
            if e and e.Parent then e.Enabled = v end
        end
        SAVED_VIS.post = nil
    end

    if cfg.Vis.NoShadows then
        Lighting.GlobalShadows = false
    end

    if cfg.Vis.RemoveAccessories then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _, acc in ipairs(p.Character:GetChildren()) do
                    if acc:IsA("Accessory") or acc:IsA("Hat") then
                        acc.LocalTransparencyModifier = 1
                    end
                end
            end
        end
    end
end

getgenv().vanta_update_freecam = function()
    local cfg = getgenv().vanta_cfg
    if cfg.Vis.Freecam then
        if not FREECAM_STATE then
            FREECAM_STATE = { pos = Camera.CFrame.Position, rot = Camera.CFrame, speed = 50 }
        end
        if not FREECAM_CONN then
            FREECAM_CONN = RunService.RenderStepped:Connect(function(dt)
                local dir = Vector3.zero
                local camCF = FREECAM_STATE.rot
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir += camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir += camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
                if dir.Magnitude > 0 then FREECAM_STATE.pos += dir.Unit * FREECAM_STATE.speed * dt end
                Camera.CFrame = CFrame.new(FREECAM_STATE.pos) * (FREECAM_STATE.rot - FREECAM_STATE.rot.Position)
                Camera.CameraType = Enum.CameraType.Scriptable
            end)
        end
    else
        if FREECAM_CONN then FREECAM_CONN:Disconnect(); FREECAM_CONN = nil end
        if FREECAM_STATE then
            Camera.CameraType = Enum.CameraType.Custom
            FREECAM_STATE = nil
        end
    end
end

getgenv().vanta_update_crosshair = function()
    local cfg = getgenv().vanta_cfg
    if not cfg.Vis.CustomCrosshair then
        if CROSSHAIR_V then CROSSHAIR_V.Visible = false end
        if CROSSHAIR_H then CROSSHAIR_H.Visible = false end
        return
    end
    local parent = (gethui and gethui()) or CoreGui
    if not CROSSHAIR_V then
        local sg = parent:FindFirstChild("vanta_crosshair")
        if not sg then
            sg = Instance.new("ScreenGui")
            sg.Name = "vanta_crosshair"; sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true; sg.DisplayOrder = 994
            sg.Parent = parent
        end
        CROSSHAIR_V = Instance.new("Frame")
        CROSSHAIR_V.BackgroundColor3 = cfg.Vis.CrosshairColor
        CROSSHAIR_V.BorderSizePixel = 0
        CROSSHAIR_V.AnchorPoint = Vector2.new(0.5, 0.5)
        CROSSHAIR_V.Position = UDim2.new(0.5, 0, 0.5, 0)
        CROSSHAIR_V.Size = UDim2.new(0, 2, 0, 14)
        CROSSHAIR_V.Parent = sg
        CROSSHAIR_H = Instance.new("Frame")
        CROSSHAIR_H.BackgroundColor3 = cfg.Vis.CrosshairColor
        CROSSHAIR_H.BorderSizePixel = 0
        CROSSHAIR_H.AnchorPoint = Vector2.new(0.5, 0.5)
        CROSSHAIR_H.Position = UDim2.new(0.5, 0, 0.5, 0)
        CROSSHAIR_H.Size = UDim2.new(0, 14, 0, 2)
        CROSSHAIR_H.Parent = sg
    end
    CROSSHAIR_V.Visible = true; CROSSHAIR_H.Visible = true
    CROSSHAIR_V.BackgroundColor3 = cfg.Vis.CrosshairColor
    CROSSHAIR_H.BackgroundColor3 = cfg.Vis.CrosshairColor
end

getgenv().vanta_update_selfhighlight = function()
    local cfg = getgenv().vanta_cfg
    if not cfg.Vis.HighlightSelf then
        if SELF_HIGHLIGHT then SELF_HIGHLIGHT:Destroy(); SELF_HIGHLIGHT = nil end
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    if not SELF_HIGHLIGHT or SELF_HIGHLIGHT.Parent ~= char then
        if SELF_HIGHLIGHT then SELF_HIGHLIGHT:Destroy() end
        SELF_HIGHLIGHT = Instance.new("Highlight")
        SELF_HIGHLIGHT.FillColor = Color3.fromRGB(100,220,255)
        SELF_HIGHLIGHT.FillTransparency = 0.5
        SELF_HIGHLIGHT.OutlineColor = Color3.fromRGB(255,255,255)
        SELF_HIGHLIGHT.Parent = char
    end
end

getgenv().zeusx_log("part", "10/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 11/25 — misc + antiban base
-- ============================================================

FPS_GUI = nil
FPS_LBL = nil
FPS_FRAMES = 0
FPS_LAST = tick()
TIME_START = tick()
TIME_GUI = nil
TIME_LBL = nil
WM_LBL = nil
KNOWN_TARGETS = KNOWN_TARGETS or {}

getgenv().vanta_update_fps = function()
    if not getgenv().vanta_cfg.Misc.FpsMonitor then
        if FPS_GUI then FPS_GUI.Enabled = false end
        return
    end
    local parent = (gethui and gethui()) or CoreGui
    if not FPS_GUI then
        FPS_GUI = Instance.new("ScreenGui")
        FPS_GUI.Name = "vanta_fps"; FPS_GUI.ResetOnSpawn = false
        FPS_GUI.IgnoreGuiInset = true; FPS_GUI.DisplayOrder = 994
        FPS_GUI.Parent = parent
        FPS_LBL = Instance.new("TextLabel")
        FPS_LBL.Size = UDim2.new(0, 220, 0, 24)
        FPS_LBL.Position = UDim2.new(0, 12, 0, 44)
        FPS_LBL.BackgroundTransparency = 0.3
        FPS_LBL.BackgroundColor3 = Color3.fromRGB(20,14,30)
        FPS_LBL.TextColor3 = Color3.fromRGB(180,140,255)
        FPS_LBL.Font = Enum.Font.GothamBold; FPS_LBL.TextSize = 13
        FPS_LBL.TextXAlignment = Enum.TextXAlignment.Left
        FPS_LBL.Parent = FPS_GUI
        Instance.new("UICorner", FPS_LBL).CornerRadius = UDim.new(0, 6)
        FPS_FRAMES = 0; FPS_LAST = tick()
    end
    FPS_GUI.Enabled = true
    FPS_FRAMES = FPS_FRAMES + 1
    local now = tick()
    if now - FPS_LAST >= 1 then
        local fps = math.floor(FPS_FRAMES / (now - FPS_LAST))
        local ping = "?"
        pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        FPS_LBL.Text = string.format("  FPS %d · ping %s ms", fps, ping)
        FPS_FRAMES = 0; FPS_LAST = now
    end
end

getgenv().vanta_update_time = function()
    if not getgenv().vanta_cfg.Misc.TimePlayed then
        if TIME_GUI then TIME_GUI.Enabled = false end
        return
    end
    local parent = (gethui and gethui()) or CoreGui
    if not TIME_GUI then
        TIME_GUI = Instance.new("ScreenGui")
        TIME_GUI.Name = "vanta_time"; TIME_GUI.ResetOnSpawn = false
        TIME_GUI.IgnoreGuiInset = true; TIME_GUI.DisplayOrder = 994
        TIME_GUI.Parent = parent
        TIME_LBL = Instance.new("TextLabel")
        TIME_LBL.Size = UDim2.new(0, 220, 0, 24)
        TIME_LBL.Position = UDim2.new(0, 12, 0, 72)
        TIME_LBL.BackgroundTransparency = 0.3
        TIME_LBL.BackgroundColor3 = Color3.fromRGB(20,14,30)
        TIME_LBL.TextColor3 = Color3.fromRGB(180,140,255)
        TIME_LBL.Font = Enum.Font.GothamBold; TIME_LBL.TextSize = 13
        TIME_LBL.TextXAlignment = Enum.TextXAlignment.Left
        TIME_LBL.Parent = TIME_GUI
        Instance.new("UICorner", TIME_LBL).CornerRadius = UDim.new(0, 6)
    end
    TIME_GUI.Enabled = true
    local t = math.floor(tick() - TIME_START)
    local m = math.floor(t/60); local h = math.floor(m/60)
    TIME_LBL.Text = string.format("  session %02d:%02d:%02d", h, m%60, t%60)
end

getgenv().vanta_update_watermark = function()
    if getgenv().vanta_cfg.Misc.Watermark then
        if not WM_LBL then
            local parent = (gethui and gethui()) or CoreGui
            WM_LBL = Instance.new("TextLabel")
            WM_LBL.Size = UDim2.new(0, 360, 0, 28)
            WM_LBL.Position = UDim2.new(0, 12, 0, 12)
            WM_LBL.BackgroundColor3 = Color3.fromRGB(20,14,30)
            WM_LBL.BackgroundTransparency = 0.4
            WM_LBL.BorderSizePixel = 0
            WM_LBL.Text = "  Zeus-X · v10.4"
            WM_LBL.TextColor3 = Color3.fromRGB(180,140,255)
            WM_LBL.Font = Enum.Font.GothamBold; WM_LBL.TextSize = 13
            WM_LBL.TextXAlignment = Enum.TextXAlignment.Left
            WM_LBL.Parent = parent
            Instance.new("UICorner", WM_LBL).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke")
            s.Color = Color3.fromRGB(170,120,255); s.Thickness = 1; s.Transparency = 0.5
            s.Parent = WM_LBL
        end
        WM_LBL.Visible = true
    elseif WM_LBL then
        WM_LBL.Visible = false
    end
end

getgenv().vanta_update_killnotify = function()
    if not getgenv().vanta_cfg.Misc.KillNotify then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and not KNOWN_TARGETS[hum] then
                KNOWN_TARGETS[hum] = true
                hum.Died:Connect(function()
                    getgenv().vanta_notify("☠ " .. p.Name .. " died")
                end)
            end
        end
    end
end

task.spawn(function()
    while task.wait(60) do
        local cfg = getgenv().vanta_cfg
        if cfg.Anti.AntiAFK or cfg.Misc.AntiAFK then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().vanta_cfg.Anti.AntiVoid then
            local c = LocalPlayer.Character
            if c then
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local fpd = Workspace.FallenPartsDestroyHeight or -500
                    if hrp.Position.Y < fpd + 50 then
                        pcall(function()
                            hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
                            hrp.Velocity = Vector3.zero
                        end)
                    end
                end
            end
        end
    end
end)

getgenv().vanta_update_antifling = function()
    if not getgenv().vanta_cfg.Anti.AntiFling then return end
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        hrp.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.01, 1, 1)
    end)
end

getgenv().zeusx_rng = Random.new(os.time())
getgenv().zeusx_rand = function(min, max)
    if not getgenv().vanta_cfg.Anti.Randomization then return min end
    return getgenv().zeusx_rng:NextNumber(min, max)
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == getgenv().vanta_cfg.Misc.PanicKey then
        getgenv().vanta_disableAll()
    end
end)

getgenv().zeusx_log("part", "11/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 12/25 — misc 2
-- ============================================================

HIT_MARKER_GUI = nil
HIT_MARKER_LBL = nil
FAKELAG_CONN = nil
SEEN_FRIENDS = SEEN_FRIENDS or {}
DEATH_HOOK_DONE = false

getgenv().zeusx_hitmarker = function()
    local parent = (gethui and gethui()) or CoreGui
    if not HIT_MARKER_GUI then
        HIT_MARKER_GUI = Instance.new("ScreenGui")
        HIT_MARKER_GUI.Name = "vanta_hitmarker"; HIT_MARKER_GUI.ResetOnSpawn = false
        HIT_MARKER_GUI.IgnoreGuiInset = true; HIT_MARKER_GUI.DisplayOrder = 993
        HIT_MARKER_GUI.Parent = parent
        HIT_MARKER_LBL = Instance.new("TextLabel")
        HIT_MARKER_LBL.Size = UDim2.new(0, 40, 0, 40)
        HIT_MARKER_LBL.AnchorPoint = Vector2.new(0.5, 0.5)
        HIT_MARKER_LBL.Position = UDim2.new(0.5, 0, 0.5, 0)
        HIT_MARKER_LBL.BackgroundTransparency = 1
        HIT_MARKER_LBL.Text = "✕"
        HIT_MARKER_LBL.TextColor3 = Color3.fromRGB(255,80,80)
        HIT_MARKER_LBL.TextStrokeTransparency = 0
        HIT_MARKER_LBL.Font = Enum.Font.GothamBlack
        HIT_MARKER_LBL.TextSize = 28
        HIT_MARKER_LBL.Parent = HIT_MARKER_GUI
    end
    HIT_MARKER_LBL.Visible = true
    HIT_MARKER_LBL.TextTransparency = 0
    TweenService:Create(HIT_MARKER_LBL, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
    task.delay(0.3, function() HIT_MARKER_LBL.Visible = false end)
end

getgenv().zeusx_hitsound = function()
    if not getgenv().vanta_cfg.Misc.HitSound then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://6042053626"
        s.Volume = 0.4
        s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(1, function() s:Destroy() end)
    end)
end

local function setupDeathNotify()
    if DEATH_HOOK_DONE then return end
    DEATH_HOOK_DONE = true
    task.spawn(function()
        while task.wait(2) do
            if getgenv().vanta_cfg.Misc.DeathNotify then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and not hum:GetAttribute("vanta_hooked") then
                        hum:SetAttribute("vanta_hooked", true)
                        hum.Died:Connect(function()
                            local killer = ""
                            local creator = hum:FindFirstChild("creator")
                            if creator and creator.Value then killer = creator.Value.Name end
                            getgenv().vanta_notify("💀 killed by " .. (killer ~= "" and killer or "?"))
                        end)
                    end
                end
            end
        end
    end)
end
setupDeathNotify()

task.spawn(function()
    while task.wait(1) do
        local cfg = getgenv().vanta_cfg
        if cfg.Misc.ChatSpam and cfg.Misc.ChatSpamText ~= "" then
            pcall(function()
                local chat = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                if chat and chat:FindFirstChild("SayMessageRequest") then
                    chat.SayMessageRequest:FireServer(cfg.Misc.ChatSpamText, "All")
                end
            end)
            task.wait(cfg.Misc.ChatSpamDelay)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        local cfg = getgenv().vanta_cfg
        if cfg.Misc.AutoChat and cfg.Misc.AutoChatText ~= "" then
            pcall(function()
                local chat = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                if chat and chat:FindFirstChild("SayMessageRequest") then
                    chat.SayMessageRequest:FireServer(cfg.Misc.AutoChatText, "All")
                end
            end)
            task.wait(cfg.Misc.AutoChatDelay)
        end
    end
end)

getgenv().vanta_update_fakelag = function()
    local cfg = getgenv().vanta_cfg
    if cfg.Misc.FakeLag and not FAKELAG_CONN then
        FAKELAG_CONN = RunService.RenderStepped:Connect(function()
            task.wait(cfg.Misc.FakeLagMs / 1000)
        end)
    elseif not cfg.Misc.FakeLag and FAKELAG_CONN then
        FAKELAG_CONN:Disconnect(); FAKELAG_CONN = nil
    end
end

task.spawn(function()
    while task.wait(3) do
        local cfg = getgenv().vanta_cfg
        if cfg.Misc.FriendNotify then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local uid = tostring(p.UserId)
                    if not SEEN_FRIENDS[uid] then
                        SEEN_FRIENDS[uid] = true
                        for _, f in ipairs(cfg.Team.Friends) do
                            if tostring(f) == uid then
                                getgenv().vanta_notify("👥 friend online: " .. p.Name)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if getgenv().vanta_cfg.Misc.AutoRejoin then
            pcall(function()
                if LocalPlayer.Parent == nil then
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                end
            end)
        end
    end
end)

getgenv().zeusx_serverHop = function()
    pcall(function()
        local TS = game:GetService("TeleportService")
        local servers = TS:GetSortedGames(0, 10)
        if servers and #servers > 0 then
            local pick = servers[math.random(1, #servers)]
            TS:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
        end
    end)
end

getgenv().zeusx_log("part", "12/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 13/25 — menu core
-- ============================================================

getgenv().vanta_create_menu = function()

local MENU_THEMES = {
    purple = { bg=Color3.fromRGB(18,12,28), panel=Color3.fromRGB(38,28,58), panelHi=Color3.fromRGB(52,38,80),
               accent=Color3.fromRGB(180,130,255), accent2=Color3.fromRGB(220,150,255),
               accentD=Color3.fromRGB(110,70,190), text=Color3.fromRGB(235,225,250),
               textDim=Color3.fromRGB(170,155,200) },
    red    = { bg=Color3.fromRGB(28,10,14), panel=Color3.fromRGB(58,28,34), panelHi=Color3.fromRGB(80,38,48),
               accent=Color3.fromRGB(255,110,130), accent2=Color3.fromRGB(255,150,170),
               accentD=Color3.fromRGB(190,60,80), text=Color3.fromRGB(250,225,225),
               textDim=Color3.fromRGB(200,155,165) },
    cyan   = { bg=Color3.fromRGB(8,20,28), panel=Color3.fromRGB(28,48,58), panelHi=Color3.fromRGB(38,68,80),
               accent=Color3.fromRGB(100,220,240), accent2=Color3.fromRGB(150,240,255),
               accentD=Color3.fromRGB(50,170,200), text=Color3.fromRGB(220,245,250),
               textDim=Color3.fromRGB(150,190,210) },
    dark   = { bg=Color3.fromRGB(10,10,10), panel=Color3.fromRGB(28,28,28), panelHi=Color3.fromRGB(40,40,40),
               accent=Color3.fromRGB(180,180,180), accent2=Color3.fromRGB(220,220,220),
               accentD=Color3.fromRGB(120,120,120), text=Color3.fromRGB(230,230,230),
               textDim=Color3.fromRGB(160,160,160) },
}
local cfg = getgenv().vanta_cfg
local A = MENU_THEMES[cfg.UI.Theme] or MENU_THEMES.purple

local function tweenQuad(o,t,p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local vp = workspace.CurrentCamera.ViewportSize
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local winW, winH
if isMobile then
    winW = math.floor(vp.X * 0.94); winH = math.floor(vp.Y * 0.80)
else
    winW = math.min(720, math.floor(vp.X * 0.72))
    winH = math.min(700, math.floor(vp.Y * 0.84))
end
if cfg.UI.Compact then winW = math.floor(winW * 0.8); winH = math.floor(winH * 0.8) end
if winW < 300 then winW = 300 end
if winH < 420 then winH = 420 end

local HEADER_H = 44
local TABS_H   = 38
local TAB_W    = 74

local parent = (gethui and gethui()) or CoreGui
if getgenv().vanta_menu and getgenv().vanta_menu.Parent then getgenv().vanta_menu:Destroy() end

getgenv().zeusx_menu_ctx = {
    A = A, THEMES = MENU_THEMES, tweenQuad = tweenQuad, Config = cfg, H = getgenv().vanta_h,
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

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, HEADER_H); bar.BackgroundTransparency = 1; bar.Parent = win
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -200, 1, 0); title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1; title.Text = "Zeus-X · v10.4"
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
iconBtn(-140, "🔍", A.panel, function()
    if getgenv().zeusx_toggleSearch then getgenv().zeusx_toggleSearch() end
end)
iconBtn(-104, "!", Color3.fromRGB(80,40,20), function()
    getgenv().vanta_disableAll()
end)
local minBtn = iconBtn(-70, "—", A.panel, function() end)
iconBtn(-36, "×", Color3.fromRGB(60,25,32), function()
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
tabPad.PaddingLeft = UDim.new(0, 2); tabPad.PaddingRight = UDim.new(0, 2)
tabPad.PaddingTop = UDim.new(0, 3); tabPad.PaddingBottom = UDim.new(0, 3)
tabPad.Parent = tabBar

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
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scroll.Active = true; scroll.ScrollingEnabled = true; scroll.Selectable = true
scroll.Parent = content

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 6); layout.Parent = scroll
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 4); pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 14); pad.Parent = scroll

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized; tabBar.Visible = not minimized
    tweenQuad(win, 0.25, {Size = minimized and UDim2.new(0, winW, 0, HEADER_H + 8) or UDim2.new(0, winW, 0, winH)})
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
        if cfg.Misc.SaveOnChange then pcall(getgenv().zeusx_saveConfig, cfg.Misc.AutoSaveSlot) end
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
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; upd(i.Position.X)
        end
    end)
    hit.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if cfg.Misc.SaveOnChange then pcall(getgenv().zeusx_saveConfig, cfg.Misc.AutoSaveSlot) end
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
    local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.8; s.Parent = row
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -150, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = A.text
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local idx = 1
    for i, o in ipairs(options) do if o == get() then idx = i end end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 24); btn.Position = UDim2.new(1, -150, 0.5, -12)
    btn.BackgroundColor3 = A.panelHi; btn.BackgroundTransparency = 0.3
    btn.Text = options[idx]; btn.TextColor3 = A.accent2
    btn.Font = Enum.Font.Gotham; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        set(options[idx])
        if cfg.Misc.SaveOnChange then pcall(getgenv().zeusx_saveConfig, cfg.Misc.AutoSaveSlot) end
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
    if tabButtons[name] and tabButtons[name].build then
        local ok, err = pcall(tabButtons[name].build)
        if not ok then getgenv().zeusx_log("ERR", "tab build '"..name.."'", err) end
    end
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

getgenv().zeusx_log("part", "13/25 OK · menu core")
end-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 14/25 — табы aim + esp
-- ============================================================

getgenv().zeusx_build_tabs_aim_esp = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx or not ctx.scroll then
        getgenv().zeusx_log("ERR", "build_tabs_aim_esp: ctx not ready")
        return
    end
    local A = ctx.A
    local Config = ctx.Config
    local scroll = ctx.scroll
    local makeTab = ctx.makeTab
    local section = ctx.section
    local toggle = ctx.toggle
    local slider = ctx.slider
    local dropdown = ctx.dropdown

    local tAim = makeTab("aim")
    tAim.build = function()
        section("AIMBOT")
        toggle("aimbot", function() return Config.Aim.Enabled end, function(v) Config.Aim.Enabled=v end)
        toggle("strict team", function() return Config.Aim.StrictTeam end, function(v) Config.Aim.StrictTeam=v end)
        toggle("friend check", function() return Config.Aim.FriendCheck end, function(v) Config.Aim.FriendCheck=v end)
        toggle("wall check", function() return Config.Aim.WallCheck end, function(v) Config.Aim.WallCheck=v end)
        toggle("curve", function() return Config.Aim.Curve end, function(v) Config.Aim.Curve=v end)
        toggle("no recoil", function() return Config.Aim.NoRecoil end, function(v) Config.Aim.NoRecoil=v end)
        toggle("fov circle", function() return Config.Aim.FovCircle end, function(v) Config.Aim.FovCircle=v end)
        toggle("disable on fire", function() return Config.Aim.DisableOnFire end, function(v) Config.Aim.DisableOnFire=v end)
        toggle("ignore dying", function() return Config.Aim.IgnoreDying end, function(v) Config.Aim.IgnoreDying=v end)
        section("AIM TUNING")
        slider("fov", 10, 400, function() return Config.Aim.FOV end, function(v) Config.Aim.FOV=v end)
        slider("smooth %", 2, 100, function() return math.floor(Config.Aim.Smooth*100) end, function(v) Config.Aim.Smooth=v/100 end)
        slider("fast smooth %", 2, 100, function() return math.floor(Config.Aim.FastSmooth*100) end, function(v) Config.Aim.FastSmooth=v/100 end)
        slider("target lock ms", 0, 500, function() return Config.Aim.TargetLockMs end, function(v) Config.Aim.TargetLockMs=v end)
        slider("switch delay ms", 0, 300, function() return Config.Aim.SwitchDelayMs end, function(v) Config.Aim.SwitchDelayMs=v end)
        slider("dying hp %", 0, 100, function() return Config.Aim.DyingHpPct end, function(v) Config.Aim.DyingHpPct=v end)
        section("PREDICTION")
        toggle("enable", function() return Config.Aim.Prediction end, function(v) Config.Aim.Prediction=v end)
        slider("strength %", 0, 200, function() return math.floor(Config.Aim.PredictionStrength*100) end, function(v) Config.Aim.PredictionStrength=v/100 end)
        section("SCORING WEIGHTS")
        slider("fov weight x100", 0, 300, function() return math.floor(Config.Aim.WeightFov*100) end, function(v) Config.Aim.WeightFov=v/100 end)
        slider("dist weight x100", 0, 300, function() return math.floor(Config.Aim.WeightDist*100) end, function(v) Config.Aim.WeightDist=v/100 end)
        section("TARGET")
        dropdown("hit part", {"auto","Head","HumanoidRootPart","UpperTorso","LowerTorso"}, function() return Config.Aim.Part end, function(v) Config.Aim.Part=v end)
        dropdown("aim mode", {"camera","mouse"}, function() return Config.Aim.Mode end, function(v) Config.Aim.Mode=v end)
        dropdown("priority", {"score","fov","distance"}, function() return Config.Aim.Priority end, function(v) Config.Aim.Priority=v end)

        section("SILENT AIM")
        toggle("silent aim", function() return Config.Silent.Enabled end, function(v) Config.Silent.Enabled=v end)
        toggle("strict team", function() return Config.Silent.StrictTeam end, function(v) Config.Silent.StrictTeam=v end)
        toggle("friend check", function() return Config.Silent.FriendCheck end, function(v) Config.Silent.FriendCheck=v end)
        toggle("require visible", function() return Config.Silent.RequireVisible end, function(v) Config.Silent.RequireVisible=v end)
        toggle("auto fallback", function() return Config.Silent.PartAutoFallback end, function(v) Config.Silent.PartAutoFallback=v end)
        slider("hit chance %", 10, 100, function() return Config.Silent.HitChance end, function(v) Config.Silent.HitChance=v end)
        slider("freeze ms", 0, 500, function() return Config.Silent.FreezeMs end, function(v) Config.Silent.FreezeMs=v end)
        slider("per-shot cooldown", 0, 200, function() return Config.Silent.PerShotCooldownMs end, function(v) Config.Silent.PerShotCooldownMs=v end)
        dropdown("silent hit part", {"auto","Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso"}, function() return Config.Silent.Part end, function(v) Config.Silent.Part=v end)
        dropdown("silent mode", {"vector","hitbox"}, function() return Config.Silent.Mode end, function(v) Config.Silent.Mode=v end)
        dropdown("substitution", {"all","target-only"}, function() return Config.Silent.SubstitutionMode end, function(v) Config.Silent.SubstitutionMode=v end)

        section("TRIGGERBOT")
        toggle("triggerbot", function() return Config.Trigger.Enabled end, function(v) Config.Trigger.Enabled=v end)
        toggle("always on", function() return Config.Trigger.AlwaysOn end, function(v) Config.Trigger.AlwaysOn=v end)
        toggle("strict team", function() return Config.Trigger.StrictTeam end, function(v) Config.Trigger.StrictTeam=v end)
        toggle("friend check", function() return Config.Trigger.FriendCheck end, function(v) Config.Trigger.FriendCheck=v end)
        toggle("wall check", function() return Config.Trigger.WallCheck end, function(v) Config.Trigger.WallCheck=v end)
        toggle("auto delay", function() return Config.Trigger.AutoDelay end, function(v) Config.Trigger.AutoDelay=v end)
        toggle("require tool", function() return Config.Trigger.RequireTool end, function(v) Config.Trigger.RequireTool=v end)
        slider("delay ms", 20, 250, function() return math.floor(Config.Trigger.Delay*1000) end, function(v) Config.Trigger.Delay=v/1000 end)
        slider("pixel radius", 10, 120, function() return Config.Trigger.PixelRadius end, function(v) Config.Trigger.PixelRadius=v end)
        slider("min distance", 0, 200, function() return Config.Trigger.MinDist end, function(v) Config.Trigger.MinDist=v end)
        slider("max distance", 100, 5000, function() return Config.Trigger.MaxDist end, function(v) Config.Trigger.MaxDist=v end)
        slider("hp min", 0, 500, function() return Config.Trigger.HpMin end, function(v) Config.Trigger.HpMin=v end)
        slider("hp max", 0, 100000, function() return Config.Trigger.HpMax end, function(v) Config.Trigger.HpMax=v end)
        slider("burst count", 1, 10, function() return Config.Trigger.Burst end, function(v) Config.Trigger.Burst=v end)
        slider("burst gap ms", 20, 500, function() return Config.Trigger.BurstGapMs end, function(v) Config.Trigger.BurstGapMs=v end)
        slider("prefire ms", 0, 300, function() return Config.Trigger.PrefireMs end, function(v) Config.Trigger.PrefireMs=v end)
        slider("after-kill delay", 0, 2000, function() return Config.Trigger.AfterKillDelayMs end, function(v) Config.Trigger.AfterKillDelayMs=v end)
        slider("rate limit / sec", 0, 30, function() return Config.Trigger.RatePerSec end, function(v) Config.Trigger.RatePerSec=v end)
        dropdown("trigger mode", {"esp-box","hitbox-projection","pixel-center"}, function() return Config.Trigger.Mode end, function(v) Config.Trigger.Mode=v end)
        dropdown("fire mode", {"both","mouse1click","remoteevent"}, function() return Config.Trigger.FireMode end, function(v) Config.Trigger.FireMode=v end)

        section("WEAPON FILTER")
        toggle("whitelist mode", function() return Config.Trigger.WhitelistMode end, function(v) Config.Trigger.WhitelistMode=v end)
        local function autoAddButton(list, listName)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 32)
            btn.BackgroundColor3 = A.accentD; btn.BackgroundTransparency = 0.3
            btn.Text = "add current weapon to " .. listName
            btn.TextColor3 = A.text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
            btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Parent = scroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
            btn.MouseButton1Click:Connect(function()
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if tool then
                    table.insert(list, tool.Name)
                    getgenv().vanta_notify(listName .. ": " .. tool.Name, 2)
                else
                    getgenv().vanta_notify("нет оружия в руках", 2)
                end
            end)
        end
        autoAddButton(Config.Trigger.WeaponWhitelist, "weapon whitelist")
        autoAddButton(Config.Trigger.WeaponBlacklist, "weapon blacklist")
        local btnClearWl = Instance.new("TextButton")
        btnClearWl.Size = UDim2.new(1, -10, 0, 32)
        btnClearWl.BackgroundColor3 = A.accentD; btnClearWl.BackgroundTransparency = 0.3
        btnClearWl.Text = "clear weapon whitelist"
        btnClearWl.TextColor3 = A.text; btnClearWl.Font = Enum.Font.GothamBold; btnClearWl.TextSize = 13
        btnClearWl.BorderSizePixel = 0; btnClearWl.AutoButtonColor = false; btnClearWl.Parent = scroll
        Instance.new("UICorner", btnClearWl).CornerRadius = UDim.new(0, 10)
        btnClearWl.MouseButton1Click:Connect(function()
            Config.Trigger.WeaponWhitelist = {}
            getgenv().vanta_notify("wl cleared")
        end)
        local btnClearBl = Instance.new("TextButton")
        btnClearBl.Size = UDim2.new(1, -10, 0, 32)
        btnClearBl.BackgroundColor3 = A.accentD; btnClearBl.BackgroundTransparency = 0.3
        btnClearBl.Text = "clear weapon blacklist"
        btnClearBl.TextColor3 = A.text; btnClearBl.Font = Enum.Font.GothamBold; btnClearBl.TextSize = 13
        btnClearBl.BorderSizePixel = 0; btnClearBl.AutoButtonColor = false; btnClearBl.Parent = scroll
        Instance.new("UICorner", btnClearBl).CornerRadius = UDim.new(0, 10)
        btnClearBl.MouseButton1Click:Connect(function()
            Config.Trigger.WeaponBlacklist = {}
            getgenv().vanta_notify("bl cleared")
        end)
    end

    local tEsp = makeTab("esp")
    tEsp.build = function()
        section("ESP")
        toggle("esp enable", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled=v end)
        toggle("box", function() return Config.ESP.Box end, function(v) Config.ESP.Box=v end)
        toggle("enemy frame", function() return Config.ESP.EnemyFrame end, function(v) Config.ESP.EnemyFrame=v end)
        toggle("name", function() return Config.ESP.Name end, function(v) Config.ESP.Name=v end)
        toggle("health bar", function() return Config.ESP.Health end, function(v) Config.ESP.Health=v end)
        toggle("distance", function() return Config.ESP.Distance end, function(v) Config.ESP.Distance=v end)
        toggle("weapon", function() return Config.ESP.Weapon end, function(v) Config.ESP.Weapon=v end)
        toggle("tracer", function() return Config.ESP.Tracer end, function(v) Config.ESP.Tracer=v end)
        toggle("head dot", function() return Config.ESP.HeadDot end, function(v) Config.ESP.HeadDot=v end)
        toggle("skeleton", function() return Config.ESP.Skeleton end, function(v) Config.ESP.Skeleton=v end)
        toggle("chams", function() return Config.ESP.Chams end, function(v) Config.ESP.Chams=v end)
        toggle("off-screen arrows", function() return Config.ESP.OffScreenArrows end, function(v) Config.ESP.OffScreenArrows=v end)
        toggle("distance color", function() return Config.ESP.DistanceColor end, function(v) Config.ESP.DistanceColor=v end)
        toggle("friend color", function() return Config.ESP.FriendColor end, function(v) Config.ESP.FriendColor=v end)
        section("3D BOX")
        toggle("3D box", function() return Config.ESP.Box3D end, function(v) Config.ESP.Box3D=v end)
        slider("3D box transparency %", 0, 100, function() return math.floor((1-Config.ESP.Box3DTransparency)*100) end, function(v) Config.ESP.Box3DTransparency=1-v/100 end)
        section("TEAM FILTER")
        toggle("strict team", function() return Config.ESP.StrictTeam end, function(v) Config.ESP.StrictTeam=v end)
        toggle("friend check", function() return Config.ESP.FriendCheck end, function(v) Config.ESP.FriendCheck=v end)
        toggle("show teammates", function() return Config.ESP.ShowTeammates end, function(v) Config.ESP.ShowTeammates=v end)
        section("TUNING")
        slider("max distance", 50, 3000, function() return Config.ESP.MaxDist end, function(v) Config.ESP.MaxDist=v end)
        slider("min parts", 3, 30, function() return Config.ESP.MinParts end, function(v) Config.ESP.MinParts=v end)
        dropdown("hp format", {"hp","hp_max","pct"}, function() return Config.ESP.HpFormat end, function(v) Config.ESP.HpFormat=v end)
        dropdown("tracer style", {"bottom","top","center"}, function() return Config.ESP.TracerStyle end, function(v) Config.ESP.TracerStyle=v end)
        dropdown("font", {"GothamBold","SourceSansBold","ArialBold","Code","Cartoon"}, function() return Config.ESP.CustomFont end, function(v) Config.ESP.CustomFont=v end)
    end

    getgenv().zeusx_log("part", "14/25 OK · tabs aim/esp")
end-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 15/25 — табы move + visual + team
-- ============================================================

getgenv().zeusx_build_tabs_move_vis_team = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx or not ctx.scroll then return end
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
        local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.6; s.Parent = b
        b.MouseEnter:Connect(function() tweenQuad(b, 0.15, {BackgroundTransparency = 0.1, BackgroundColor3 = A.accent}) end)
        b.MouseLeave:Connect(function() tweenQuad(b, 0.15, {BackgroundTransparency = 0.3, BackgroundColor3 = bg or A.accentD}) end)
        b.MouseButton1Click:Connect(cb)
    end

    local tMove = makeTab("move")
    tMove.build = function()
        section("SPEED")
        toggle("speed", function() return Config.Move.Speed end, function(v) Config.Move.Speed=v end)
        slider("speed value", 16, 250, function() return Config.Move.SpeedVal end, function(v) Config.Move.SpeedVal=v end)
        dropdown("speed mode", {"walkspeed","velocity","cframe"}, function() return Config.Move.SpeedMode end, function(v) Config.Move.SpeedMode=v end)
        section("FLY")
        toggle("fly", function() return Config.Move.Fly end, function(v) Config.Move.Fly=v end)
        toggle("fly smooth", function() return Config.Move.FlySmooth end, function(v) Config.Move.FlySmooth=v end)
        slider("fly speed", 10, 300, function() return Config.Move.FlySpeed end, function(v) Config.Move.FlySpeed=v end)
        dropdown("fly mode", {"velocity","cframe","bodyvelocity"}, function() return Config.Move.FlyMode end, function(v) Config.Move.FlyMode=v end)
        section("OTHER")
        toggle("infinite jump", function() return Config.Move.InfJump end, function(v) Config.Move.InfJump=v end)
        toggle("noclip", function() return Config.Move.Noclip end, function(v) Config.Move.Noclip=v end)
        toggle("bhop", function() return Config.Move.BHop end, function(v) Config.Move.BHop=v end)
        toggle("auto respawn", function() return Config.Move.AutoRespawn end, function(v) Config.Move.AutoRespawn=v end)
        toggle("no fall damage", function() return Config.Move.NoFallDamage end, function(v) Config.Move.NoFallDamage=v end)
        toggle("anti-gravity", function() return Config.Move.AntiGravity end, function(v) Config.Move.AntiGravity=v end)
        slider("gravity value", 0, 200, function() return Config.Move.Gravity end, function(v) Config.Move.Gravity=v end)
        section("TELEPORT")
        button("save waypoint", function() getgenv().zeusx_saveWaypoint() end)
        button("tp to waypoint", function() getgenv().zeusx_tpToWaypoint() end)
        button("toggle click TP (Alt+Click)", function()
            getgenv().vanta_clicktp = not getgenv().vanta_clicktp
            getgenv().zeusx_setClickTp(getgenv().vanta_clicktp)
            getgenv().vanta_notify("click TP: " .. tostring(getgenv().vanta_clicktp))
        end)
    end

    local tVis = makeTab("visual")
    tVis.build = function()
        section("LIGHTING")
        toggle("fullbright", function() return Config.Vis.Fullbright end, function(v) Config.Vis.Fullbright=v end)
        dropdown("fullbright mode", {"ambient","bloom"}, function() return Config.Vis.FullbrightMode end, function(v) Config.Vis.FullbrightMode=v end)
        toggle("no fog", function() return Config.Vis.NoFog end, function(v) Config.Vis.NoFog=v end)
        toggle("custom ambient", function() return Config.Vis.Ambient end, function(v) Config.Vis.Ambient=v end)
        section("SKY / POST")
        toggle("custom skybox", function() return Config.Vis.Skybox end, function(v) Config.Vis.Skybox=v end)
        inputBox("skybox id", function() return Config.Vis.SkyboxId end, function(v) Config.Vis.SkyboxId=v end, "rbxassetid цифры")
        toggle("remove post-processing", function() return Config.Vis.NoPost end, function(v) Config.Vis.NoPost=v end)
        toggle("no shadows", function() return Config.Vis.NoShadows end, function(v) Config.Vis.NoShadows=v end)
        section("CAMERA")
        slider("camera FOV", 60, 160, function() return Config.Vis.FOV end, function(v) Config.Vis.FOV=v end)
        toggle("freecam", function() return Config.Vis.Freecam end, function(v) Config.Vis.Freecam=v end)
        toggle("zoom extend", function() return Config.Vis.ZoomExtend end, function(v) Config.Vis.ZoomExtend=v end)
        section("WORLD")
        toggle("remove accessories", function() return Config.Vis.RemoveAccessories end, function(v) Config.Vis.RemoveAccessories=v end)
        toggle("remove textures", function() return Config.Vis.RemoveTextures end, function(v) Config.Vis.RemoveTextures=v end)
        toggle("highlight self", function() return Config.Vis.HighlightSelf end, function(v) Config.Vis.HighlightSelf=v end)
        section("CROSSHAIR")
        toggle("custom crosshair", function() return Config.Vis.CustomCrosshair end, function(v) Config.Vis.CustomCrosshair=v end)
    end

    local tTeam = makeTab("team")
    tTeam.build = function()
        section("TEAM DETECTION")
        toggle("strict team (3 источника)", function() return Config.Aim.StrictTeam end, function(v)
            Config.Aim.StrictTeam=v; Config.Silent.StrictTeam=v
            Config.Trigger.StrictTeam=v; Config.ESP.StrictTeam=v
        end)
        toggle("friend check", function() return Config.Aim.FriendCheck end, function(v)
            Config.Aim.FriendCheck=v; Config.Silent.FriendCheck=v
            Config.Trigger.FriendCheck=v; Config.ESP.FriendCheck=v
        end)
        toggle("ignore whitelist", function() return Config.Aim.IgnoreWhitelist end, function(v)
            Config.Aim.IgnoreWhitelist=v; Config.Silent.IgnoreWhitelist=v
            Config.Trigger.IgnoreWhitelist=v; Config.ESP.IgnoreWhitelist=v
        end)
        toggle("esp: show teammates", function() return Config.ESP.ShowTeammates end, function(v) Config.ESP.ShowTeammates=v end)

        section("WHITELIST — всегда ignore")
        inputBox("add nick", function() return "" end, function(v)
            if v and v ~= "" then table.insert(Config.Team.Whitelist, v); getgenv().vanta_notify("wl: "..v, 2) end
        end, "ник + Enter")
        button("clear whitelist", function()
            Config.Team.Whitelist = {}; getgenv().vanta_notify("whitelist cleared")
        end)
        button("show whitelist", function()
            local s = #Config.Team.Whitelist == 0 and "(пусто)" or table.concat(Config.Team.Whitelist, ", ")
            getgenv().vanta_notify("wl: "..s, 4)
        end)

        section("BLACKLIST — всегда показывать")
        inputBox("add nick", function() return "" end, function(v)
            if v and v ~= "" then table.insert(Config.Team.Blacklist, v); getgenv().vanta_notify("bl: "..v, 2) end
        end, "ник + Enter")
        button("clear blacklist", function()
            Config.Team.Blacklist = {}; getgenv().vanta_notify("blacklist cleared")
        end)
        button("show blacklist", function()
            local s = #Config.Team.Blacklist == 0 and "(пусто)" or table.concat(Config.Team.Blacklist, ", ")
            getgenv().vanta_notify("bl: "..s, 4)
        end)

        section("TELEPORT TO PLAYER")
        inputBox("ник для TP", function() return getgenv().zeusx_tpNick or "" end, function(v) getgenv().zeusx_tpNick = v end, "ник + Enter")
        button("tp to nick", function()
            if getgenv().zeusx_tpNick then getgenv().zeusx_tpToPlayer(getgenv().zeusx_tpNick) end
        end)

        section("DEBUG")
        button("debug: команды в консоль", function()
            if H.teamDebug then H.teamDebug() end
        end)
    end

    getgenv().zeusx_log("part", "15/25 OK · tabs move/vis/team")
end-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 16/25 — табы misc + ui
-- ============================================================

getgenv().zeusx_build_tabs_misc_ui = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx or not ctx.scroll then return end
    local A = ctx.A
    local Config = ctx.Config
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
        local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.6; s.Parent = b
        b.MouseEnter:Connect(function() tweenQuad(b, 0.15, {BackgroundTransparency = 0.1, BackgroundColor3 = A.accent}) end)
        b.MouseLeave:Connect(function() tweenQuad(b, 0.15, {BackgroundTransparency = 0.3, BackgroundColor3 = bg or A.accentD}) end)
        b.MouseButton1Click:Connect(cb)
    end

    local tMisc = makeTab("misc")
    tMisc.build = function()
        section("NOTIFY")
        toggle("kill notify", function() return Config.Misc.KillNotify end, function(v) Config.Misc.KillNotify=v end)
        toggle("death notify", function() return Config.Misc.DeathNotify end, function(v) Config.Misc.DeathNotify=v end)
        toggle("friend notify", function() return Config.Misc.FriendNotify end, function(v) Config.Misc.FriendNotify=v end)
        toggle("hit marker", function() return Config.Misc.HitMarker end, function(v) Config.Misc.HitMarker=v end)
        toggle("hit sound", function() return Config.Misc.HitSound end, function(v) Config.Misc.HitSound=v end)
        section("CHAT")
        toggle("chat spam", function() return Config.Misc.ChatSpam end, function(v) Config.Misc.ChatSpam=v end)
        inputBox("spam text", function() return Config.Misc.ChatSpamText end, function(v) Config.Misc.ChatSpamText=v end)
        slider("spam delay sec", 1, 60, function() return Config.Misc.ChatSpamDelay end, function(v) Config.Misc.ChatSpamDelay=v end)
        toggle("auto chat", function() return Config.Misc.AutoChat end, function(v) Config.Misc.AutoChat=v end)
        inputBox("autochat text", function() return Config.Misc.AutoChatText end, function(v) Config.Misc.AutoChatText=v end)
        slider("autochat delay", 1, 60, function() return Config.Misc.AutoChatDelay end, function(v) Config.Misc.AutoChatDelay=v end)
        section("SESSION")
        toggle("fake lag", function() return Config.Misc.FakeLag end, function(v) Config.Misc.FakeLag=v end)
        slider("fake lag ms", 50, 1000, function() return Config.Misc.FakeLagMs end, function(v) Config.Misc.FakeLagMs=v end)
        toggle("fps monitor", function() return Config.Misc.FpsMonitor end, function(v) Config.Misc.FpsMonitor=v end)
        toggle("time played", function() return Config.Misc.TimePlayed end, function(v) Config.Misc.TimePlayed=v end)
        toggle("watermark", function() return Config.Misc.Watermark end, function(v) Config.Misc.Watermark=v end)
        toggle("anti-afk", function() return Config.Misc.AntiAFK end, function(v) Config.Misc.AntiAFK=v end)
        section("SERVER")
        toggle("auto rejoin", function() return Config.Misc.AutoRejoin end, function(v) Config.Misc.AutoRejoin=v end)
        button("server hop", function() getgenv().zeusx_serverHop() end)
        button("rejoin", function()
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
            end)
        end)
        section("ANTIBAN")
        toggle("anti-afk", function() return Config.Anti.AntiAFK end, function(v) Config.Anti.AntiAFK=v end)
        toggle("anti-fling", function() return Config.Anti.AntiFling end, function(v) Config.Anti.AntiFling=v end)
        toggle("anti-void", function() return Config.Anti.AntiVoid end, function(v) Config.Anti.AntiVoid=v end)
        toggle("stealth mode", function() return Config.Anti.StealthMode end, function(v) Config.Anti.StealthMode=v end)
        toggle("randomization", function() return Config.Anti.Randomization end, function(v) Config.Anti.Randomization=v end)
        toggle("anti-detect", function() return Config.Anti.AntiDetect end, function(v) Config.Anti.AntiDetect=v end)
        toggle("anti-log", function() return Config.Anti.AntiLog end, function(v) Config.Anti.AntiLog=v end)
        toggle("hide from server", function() return Config.Anti.HideFromServer end, function(v) Config.Anti.HideFromServer=v end)
        toggle("no speed detect", function() return Config.Anti.NoSpeedDetect end, function(v) Config.Anti.NoSpeedDetect=v end)
        toggle("hook hider", function() return Config.Anti.HookHider end, function(v)
            Config.Anti.HookHider = v
            if v and getgenv().zeusx_installHookHider then getgenv().zeusx_installHookHider() end
        end)
        slider("stealth speed cap", 20, 120, function() return Config.Anti.StealthSpeedCap end, function(v) Config.Anti.StealthSpeedCap=v end)
        slider("stealth fly cap", 20, 200, function() return Config.Anti.StealthFlyCap end, function(v) Config.Anti.StealthFlyCap=v end)
    end

    local tUi = makeTab("ui")
    tUi.build = function()
        section("THEME")
        dropdown("theme", {"purple","red","cyan","dark"}, function() return Config.UI.Theme end, function(v)
            Config.UI.Theme = v
            if getgenv().vanta_create_menu then
                getgenv().vanta_create_menu()
                if getgenv().zeusx_rebuild_all_tabs then getgenv().zeusx_rebuild_all_tabs() end
            end
        end)
        toggle("compact mode", function() return Config.UI.Compact end, function(v)
            Config.UI.Compact = v
            if getgenv().vanta_create_menu then
                getgenv().vanta_create_menu()
                if getgenv().zeusx_rebuild_all_tabs then getgenv().zeusx_rebuild_all_tabs() end
            end
        end)
        section("REBIND FUNCTIONS")
        button("bind aim key", function()
            getgenv().zeusx_awaitRebind = "aim"
            getgenv().vanta_notify("жми клавишу/мышь для aim", 3)
        end)
        button("bind trigger key", function()
            getgenv().zeusx_awaitRebind = "trigger"
            getgenv().vanta_notify("жми клавишу/мышь для trigger", 3)
        end)
        button("bind fly toggle", function()
            getgenv().zeusx_awaitRebind = "fly"
            getgenv().vanta_notify("жми клавишу для fly", 3)
        end)
        button("bind noclip toggle", function()
            getgenv().zeusx_awaitRebind = "noclip"
            getgenv().vanta_notify("жми клавишу для noclip", 3)
        end)
        button("bind panic key", function()
            getgenv().zeusx_awaitRebind = "panic"
            getgenv().vanta_notify("жми клавишу для panic", 3)
        end)
        button("clear all binds", function()
            Config.Misc.CustomKeybinds = {}
            getgenv().vanta_notify("all binds cleared")
        end)
        section("NOTIFY LOG")
        button("показать лог", function()
            local log = getgenv().zeusx_notifyLog
            for i = math.max(1, #log-9), #log do
                if log[i] then print(log[i].msg) end
            end
            getgenv().vanta_notify("log → console", 2)
        end)
        section("DEBUG")
        button("dump state → console", function()
            print("=== Zeus-X state ===")
            for section_name, vals in pairs(Config) do
                if type(vals) == "table" then
                    for k, v in pairs(vals) do
                        if type(v) == "boolean" and v then
                            print(section_name .. "." .. k .. " = true")
                        end
                    end
                end
            end
            getgenv().vanta_notify("state dumped", 2)
        end)
    end

    getgenv().zeusx_log("part", "16/25 OK · tabs misc/ui")
end-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 17/25 — табы config + key + info
-- ============================================================

getgenv().zeusx_build_tabs_cfg_key_info = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx or not ctx.scroll then return end
    local A = ctx.A
    local Config = ctx.Config
    local scroll = ctx.scroll
    local makeTab = ctx.makeTab
    local section = ctx.section
    local toggle = ctx.toggle
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
        local s = Instance.new("UIStroke"); s.Color = A.accent; s.Thickness = 1; s.Transparency = 0.6; s.Parent = b
        b.MouseEnter:Connect(function() tweenQuad(b, 0.15, {BackgroundTransparency = 0.1, BackgroundColor3 = A.accent}) end)
        b.MouseLeave:Connect(function() tweenQuad(b, 0.15, {BackgroundTransparency = 0.3, BackgroundColor3 = bg or A.accentD}) end)
        b.MouseButton1Click:Connect(cb)
    end

    local tCfg = makeTab("config")
    tCfg.build = function()
        section("SAVE / LOAD")
        inputBox("slot name", function() return Config.Misc.AutoSaveSlot end, function(v) Config.Misc.AutoSaveSlot = v end)
        toggle("auto-save on change", function() return Config.Misc.SaveOnChange end, function(v) Config.Misc.SaveOnChange=v end)
        button("save config", function()
            local ok = getgenv().zeusx_saveConfig(Config.Misc.AutoSaveSlot)
            getgenv().vanta_notify(ok and ("saved · "..Config.Misc.AutoSaveSlot) or "save failed")
        end)
        button("load config", function()
            local ok = getgenv().zeusx_loadConfig(Config.Misc.AutoSaveSlot)
            getgenv().vanta_notify(ok and ("loaded · "..Config.Misc.AutoSaveSlot) or "load failed")
            if ok and getgenv().vanta_create_menu then
                getgenv().vanta_create_menu()
                if getgenv().zeusx_rebuild_all_tabs then getgenv().zeusx_rebuild_all_tabs() end
            end
        end)
        button("list configs", function()
            local l = getgenv().zeusx_listConfigs()
            local s = "configs: "
            if #l == 0 then s = s .. "(пусто)"
            else for _, n in ipairs(l) do s = s .. n .. " " end end
            getgenv().vanta_notify(s, 4)
        end)
        button("revert from .bak", function()
            local p = "zeusx/cfg_" .. Config.Misc.AutoSaveSlot .. ".json.bak"
            if isfile and isfile(p) then
                local ok, raw = pcall(readfile, p)
                if ok and raw then
                    pcall(writefile, "zeusx/cfg_" .. Config.Misc.AutoSaveSlot .. ".json", raw)
                    getgenv().zeusx_loadConfig(Config.Misc.AutoSaveSlot)
                    getgenv().vanta_notify("reverted from bak")
                end
            else
                getgenv().vanta_notify("no backup found")
            end
        end)
        section("SHARE")
        button("export base64 → clipboard", function()
            local enc = getgenv().zeusx_exportConfig(Config.Misc.AutoSaveSlot)
            if enc and setclipboard then
                setclipboard(enc)
                getgenv().vanta_notify("exported to clipboard")
            else
                getgenv().vanta_notify("export failed")
            end
        end)
        inputBox("import string", function() return getgenv().zeusx_importStr or "" end, function(v)
            if v and v ~= "" then
                local ok = getgenv().zeusx_importConfig(v, Config.Misc.AutoSaveSlot)
                getgenv().vanta_notify(ok and "imported" or "import failed")
            end
        end, "paste base64 + Enter")
        section("PRESETS")
        button("legit", function() getgenv().zeusx_applyPreset("legit") end)
        button("rage", function() getgenv().zeusx_applyPreset("rage") end)
        button("sniper", function() getgenv().zeusx_applyPreset("sniper") end)
        button("cqc", function() getgenv().zeusx_applyPreset("cqc") end)
    end

    local tKey = makeTab("key")
    tKey.build = function()
        section("ACCESS")
        local hwid = getgenv().vanta_getHWID and getgenv().vanta_getHWID() or "?"
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -10, 0, 60)
        info.BackgroundColor3 = A.panel; info.BackgroundTransparency = 0.55
        info.TextColor3 = A.text; info.Font = Enum.Font.Code
        info.TextSize = 11; info.TextWrapped = true
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Text = "  HWID: " .. hwid .. "\n  key: " .. (Config.Key.Active or "—")
        info.Parent = scroll
        Instance.new("UICorner", info).CornerRadius = UDim.new(0, 10)

        button("copy HWID", function()
            if setclipboard then setclipboard(hwid); getgenv().vanta_notify("hwid copied") end
        end)
        button("change key", function()
            getgenv().vanta_set_key(nil)
            if getgenv().vanta_show_keygate then
                getgenv().vanta_show_keygate(getgenv().vanta_on_success, "")
            end
        end)
        button("check server now", function()
            local ok, msg, data = getgenv().vanta_checkKey(Config.Key.Active or "TEST")
            local s
            if ok == true then
                local left = tonumber(msg) or 0
                if left > 1e9 then s = "server: OK · вечный"
                else s = "server: OK · осталось " .. math.floor(left/86400) .. "д" end
            elseif ok == false then s = "server: " .. tostring(msg)
            else s = "server: нет связи" end
            getgenv().vanta_notify(s, 4)
        end)
        section("HWID RESET")
        button("request HWID reset", function()
            if getgenv().zeusx_requestHwidReset then getgenv().zeusx_requestHwidReset() end
        end, Color3.fromRGB(140,60,60))

        section("SESSION")
        local expiryLbl = Instance.new("TextLabel")
        expiryLbl.Size = UDim2.new(1, -10, 0, 40)
        expiryLbl.BackgroundColor3 = A.panel; expiryLbl.BackgroundTransparency = 0.55
        expiryLbl.TextColor3 = A.accent2; expiryLbl.Font = Enum.Font.GothamBold
        expiryLbl.TextSize = 13
        expiryLbl.Text = "  expires: ..."
        expiryLbl.Parent = scroll
        Instance.new("UICorner", expiryLbl).CornerRadius = UDim.new(0, 10)

        task.spawn(function()
            while expiryLbl.Parent do
                local left = Config.Key.Expiry - os.time()
                if left > 1e9 then expiryLbl.Text = "  expires: вечный"
                elseif left <= 0 then expiryLbl.Text = "  expires: истёк"
                else
                    local d = math.floor(left/86400)
                    local h = math.floor((left%86400)/3600)
                    local m = math.floor((left%3600)/60)
                    expiryLbl.Text = string.format("  expires: %dд %02dч %02dм", d, h, m)
                end
                task.wait(1)
            end
        end)
    end

    local tInfo = makeTab("info")
    tInfo.build = function()
        section("ZEUS-X")
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -10, 0, 180); info.BackgroundColor3 = A.panel
        info.BackgroundTransparency = 0.55
        info.Text = "Zeus-X · v10.4 Ultimate\n25 частей\n\nAim · silent · trigger · move · visual\nESP · skeleton · chams · 3D box · config · antiban\nfriend check · whitelist · themes · presets\nhook hider · rebind · HWID reset\n\nTG: @noir_xis\nServer: zeus-key-mjep.onrender.com"
        info.TextColor3 = A.text; info.Font = Enum.Font.Gotham
        info.TextSize = 13; info.TextWrapped = true
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Parent = scroll
        Instance.new("UICorner", info).CornerRadius = UDim.new(0, 10)
    end

    getgenv().zeusx_log("part", "17/25 OK · tabs config/key/info")
end-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 18/25 — rebuild + search + hotkeys
-- ============================================================

getgenv().zeusx_rebuild_all_tabs = function()
    local steps = {
        {"aim/esp",  getgenv().zeusx_build_tabs_aim_esp},
        {"move/vis/team", getgenv().zeusx_build_tabs_move_vis_team},
        {"misc/ui", getgenv().zeusx_build_tabs_misc_ui},
        {"config/key/info", getgenv().zeusx_build_tabs_cfg_key_info},
    }
    for _, s in ipairs(steps) do
        if not s[2] then
            getgenv().zeusx_log("ERR", "missing builder: " .. s[1])
        else
            local ok, err = pcall(s[2])
            if not ok then getgenv().zeusx_log("ERR", "rebuild " .. s[1], err) end
        end
    end
    if getgenv().zeusx_menu_ctx and getgenv().zeusx_menu_ctx.setActiveTab then
        getgenv().zeusx_menu_ctx.setActiveTab("aim")
    end
end

getgenv().zeusx_toggleSearch = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx then return end
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("vanta_search")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "vanta_search"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
    sg.DisplayOrder = 3500; sg.Parent = parent

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 300, 0, 40)
    box.Position = UDim2.new(0.5, -150, 0, 60)
    box.BackgroundColor3 = Color3.fromRGB(28,20,44)
    box.BackgroundTransparency = 0.15
    box.BorderSizePixel = 0
    box.PlaceholderText = "поиск настройки..."
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(235,225,250)
    box.PlaceholderColor3 = Color3.fromRGB(140,120,180)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Parent = sg
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180,130,255); s.Thickness = 1.4; s.Parent = box

    box:CaptureFocus()

    box.FocusLost:Connect(function()
        local query = box.Text:lower()
        sg:Destroy()
        if query == "" then return end
        local map = {
            {kw={"fov","aimbot","наводка","prediction","target","lock","silent"}, tab="aim"},
            {kw={"trigger","триггер","burst","prefire","weapon"}, tab="aim"},
            {kw={"esp","бокс","skeleton","chams","tracer","3d","box"}, tab="esp"},
            {kw={"move","speed","fly","noclip","bhop","tp","waypoint"}, tab="move"},
            {kw={"visual","fullbright","skybox","freecam","crosshair"}, tab="visual"},
            {kw={"team","friend","whitelist","blacklist"}, tab="team"},
            {kw={"chat","spam","hitmarker","fps","kill","fakelag"}, tab="misc"},
            {kw={"theme","ui","compact","rebind","search"}, tab="ui"},
            {kw={"config","save","load","preset","import"}, tab="config"},
            {kw={"key","hwid","expires","server","reset"}, tab="key"},
        }
        for _, m in ipairs(map) do
            for _, kw in ipairs(m.kw) do
                if query:find(kw, 1, true) then
                    ctx.setActiveTab(m.tab)
                    getgenv().vanta_notify("→ "..m.tab, 2)
                    return
                end
            end
        end
        getgenv().vanta_notify("не найдено", 2)
    end)
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx or not ctx.setActiveTab then return end
    local keyMap = {
        [Enum.KeyCode.F1]="aim", [Enum.KeyCode.F2]="esp",
        [Enum.KeyCode.F3]="move", [Enum.KeyCode.F4]="visual",
        [Enum.KeyCode.F5]="team", [Enum.KeyCode.F6]="misc",
        [Enum.KeyCode.F7]="ui",
    }
    if keyMap[i.KeyCode] then ctx.setActiveTab(keyMap[i.KeyCode]) end
end)

getgenv().zeusx_log("part", "18/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 19/25 — main loop
-- ============================================================

if not getgenv().vanta_loop_started then
    getgenv().vanta_loop_started = true

    local function safeCall(fn)
        if not fn then return end
        local ok, err = pcall(fn)
        if not ok then
            getgenv()._loop_errs = getgenv()._loop_errs or {}
            if not getgenv()._loop_errs[fn] then
                getgenv()._loop_errs[fn] = true
                getgenv().zeusx_log("LOOP-ERR", tostring(fn), err)
            end
        end
    end

    local accum = 0
    RunService.RenderStepped:Connect(function(dt)
        safeCall(getgenv().vanta_update_aim)
        safeCall(getgenv().vanta_update_silent)
        safeCall(getgenv().vanta_update_trigger)
        safeCall(getgenv().vanta_update_norecoil)
        safeCall(getgenv().vanta_update_fovcircle)
        safeCall(getgenv().vanta_update_move)
        safeCall(getgenv().vanta_update_noclip)
        safeCall(getgenv().vanta_update_bhop)
        safeCall(getgenv().vanta_update_autorespawn)
        safeCall(getgenv().vanta_update_vis)
        safeCall(getgenv().vanta_update_freecam)
        safeCall(getgenv().vanta_update_crosshair)
        safeCall(getgenv().vanta_update_selfhighlight)
        safeCall(getgenv().vanta_update_fps)
        safeCall(getgenv().vanta_update_time)
        safeCall(getgenv().vanta_update_watermark)
        safeCall(getgenv().vanta_update_killnotify)
        safeCall(getgenv().vanta_update_antifling)
        safeCall(getgenv().vanta_update_fakelag)

        accum += dt
        if accum < 1/60 then return end
        accum = 0
        safeCall(getgenv().vanta_render_esp)
        safeCall(getgenv().vanta_render_skeleton)
        safeCall(getgenv().vanta_render_chams)
        safeCall(getgenv().vanta_render_arrows)
        safeCall(getgenv().vanta_render_box3d)
    end)
    getgenv().zeusx_log("loop", "запущен")
end

getgenv().zeusx_log("part", "19/25 OK")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 20/25 — 3D box + rebind + HWID reset
-- ============================================================

BOX3D_FOLDER = BOX3D_FOLDER or nil
BOX3D = BOX3D or setmetatable({}, { __mode = "k" })

local function init3DBox()
    if BOX3D_FOLDER then return end
    local parent = (gethui and gethui()) or CoreGui
    BOX3D_FOLDER = Instance.new("Folder")
    BOX3D_FOLDER.Name = "vanta_box3d"
    BOX3D_FOLDER.Parent = parent
end

local function create3DBox(m)
    if BOX3D[m] then return end
    local root = getgenv().vanta_h.getRoot(m)
    if not root then return end
    local cfg = getgenv().vanta_cfg
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "vanta_box3d_" .. m.Name
    box.Adornee = root
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = Vector3.new(3, 5, 3)
    box.Transparency = cfg.ESP.Box3DTransparency
    box.Color3 = cfg.ESP.Box3DColor
    box.Parent = BOX3D_FOLDER
    BOX3D[m] = box
end

local function destroy3DBox(m)
    if BOX3D[m] then pcall(function() BOX3D[m]:Destroy() end) BOX3D[m] = nil end
end

getgenv().vanta_render_box3d = function()
    local cfg = getgenv().vanta_cfg
    local H = getgenv().vanta_h
    if not cfg.ESP.Enabled or not cfg.ESP.Box3D then
        if BOX3D_FOLDER then
            for m in pairs(BOX3D) do destroy3DBox(m) end
        end
        return
    end
    init3DBox()
    local seen = {}
    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        local ignore = H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam, FriendCheck=cfg.ESP.FriendCheck,
            IgnoreWhitelist=cfg.ESP.IgnoreWhitelist, ShowTeammates=cfg.ESP.ShowTeammates,
        })
        if not H.isAlive(m) or ignore then
            destroy3DBox(m)
        else
            if not BOX3D[m] then create3DBox(m) end
            local box = BOX3D[m]
            if box then
                local head = H.getHead(m)
                local root = H.getRoot(m)
                if head and root then
                    local topY = head.Position.Y + 0.5
                    local botY = root.Position.Y - 2.5
                    local height = math.max(2, topY - botY)
                    box.Size = Vector3.new(3, height, 3)
                    box.Color3 = cfg.ESP.Box3DColor
                    box.Transparency = cfg.ESP.Box3DTransparency
                    box.Adornee = root
                end
            end
        end
    end
    for m in pairs(BOX3D) do
        if not seen[m] or not m.Parent then destroy3DBox(m) end
    end
end

getgenv().zeusx_getKeybind = function(fn)
    local CB = getgenv().vanta_cfg.Misc.CustomKeybinds or {}
    return CB[fn]
end

getgenv().zeusx_setKeybind = function(fn, keyCode)
    getgenv().vanta_cfg.Misc.CustomKeybinds = getgenv().vanta_cfg.Misc.CustomKeybinds or {}
    getgenv().vanta_cfg.Misc.CustomKeybinds[fn] = keyCode
    getgenv().vanta_notify("bind " .. fn .. " → " .. tostring(keyCode), 2)
end

getgenv().zeusx_clearKeybind = function(fn)
    if getgenv().vanta_cfg.Misc.CustomKeybinds then
        getgenv().vanta_cfg.Misc.CustomKeybinds[fn] = nil
    end
end

task.spawn(function()
    local connected = {}
    while task.wait(1) do
        local CB = getgenv().vanta_cfg.Misc.CustomKeybinds
        if CB then
            for fn, key in pairs(CB) do
                if not connected[fn] then
                    connected[fn] = true
                    UIS.InputBegan:Connect(function(i, gpe)
                        if gpe then return end
                        if i.KeyCode ~= key and i.UserInputType ~= key then return end
                        local cfg = getgenv().vanta_cfg
                        if fn == "fly" then cfg.Move.Fly = not cfg.Move.Fly
                        elseif fn == "noclip" then cfg.Move.Noclip = not cfg.Move.Noclip
                        elseif fn == "speed" then cfg.Move.Speed = not cfg.Move.Speed
                        elseif fn == "bhop" then cfg.Move.BHop = not cfg.Move.BHop
                        elseif fn == "freecam" then cfg.Vis.Freecam = not cfg.Vis.Freecam
                        elseif fn == "panic" then getgenv().vanta_disableAll()
                        elseif fn == "save_waypoint" then getgenv().zeusx_saveWaypoint()
                        elseif fn == "tp_waypoint" then getgenv().zeusx_tpToWaypoint()
                        end
                    end)
                end
            end
        end
    end
end)

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local target = getgenv().zeusx_awaitRebind
    if target then
        getgenv().zeusx_awaitRebind = nil
        local cfg = getgenv().vanta_cfg
        if target == "aim" then
            cfg.Aim.Key = i.UserInputType ~= Enum.UserInputType.None and i.UserInputType or i.KeyCode
            getgenv().vanta_notify("aim → " .. tostring(cfg.Aim.Key), 2)
        elseif target == "trigger" then
            cfg.Trigger.Key = i.UserInputType ~= Enum.UserInputType.None and i.UserInputType or i.KeyCode
            getgenv().vanta_notify("trigger → " .. tostring(cfg.Trigger.Key), 2)
        elseif target == "panic" then
            cfg.Misc.PanicKey = i.KeyCode
            getgenv().vanta_notify("panic → " .. tostring(i.KeyCode), 2)
        else
            local code = i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode or i.UserInputType
            getgenv().zeusx_setKeybind(target, code)
        end
    end
end)

getgenv().zeusx_requestHwidReset = function()
    local key = getgenv().vanta_get_key()
    if not key then
        getgenv().vanta_notify("нет активного ключа", 3)
        return
    end
    local hwid = getgenv().vanta_getHWID()
    local url = "https://zeus-key-mjep.onrender.com/hwid_reset?token=" .. key .. "&hwid=" .. hwid
    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not response then
        getgenv().vanta_notify("сервер не отвечает", 3)
        return
    end
    local okD, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not okD or type(data) ~= "table" then
        getgenv().vanta_notify("ошибка ответа", 3)
        return
    end
    if data.ok then
        if data.reset then
            getgenv().vanta_notify("HWID сброшен · активируй ключ заново", 5)
            getgenv().vanta_set_key(nil)
            getgenv().vanta_disableAll()
            if getgenv().vanta_show_keygate then
                getgenv().vanta_show_keygate(getgenv().vanta_on_success, "HWID сброшен")
            end
        else
            getgenv().vanta_notify("сброс доступен через " .. tostring(data.days_left or "?") .. " дн.", 5)
        end
    else
        getgenv().vanta_notify("ошибка: " .. tostring(data.reason or "?"), 3)
    end
end

getgenv().zeusx_log("part", "20/25 OK · 3d box / rebind / hwid reset")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 21/25 — keygate UI
-- ============================================================

local function formatTime(sec)
    if not sec or sec < 0 then sec = 0 end
    if sec > 1e9 then return "вечный" end
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    if d > 0 then return string.format("%dд %02dч %02dм", d, h, m) end
    return string.format("%02dч %02dм", h, m)
end

local function getSafeParent()
    local ok, p = pcall(function() return gethui and gethui() end)
    if ok and p then return p end
    local ok2, p2 = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and p2 then return p2 end
    local lp = game:GetService("Players").LocalPlayer
    if lp then
        local pg = lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
        if pg then return pg end
    end
    return nil
end

getgenv().vanta_show_keygate = function(onSuccess, message)
    local parent = getSafeParent()
    if not parent then
        warn("[zeusx] KEYGATE: не найден parent GUI — keygate не может быть показан")
        return
    end

    local old = parent:FindFirstChild("vanta_keygui")
    if old then old:Destroy() end

    local accent = Color3.fromRGB(180, 130, 255)
    local TG_LINK_LOCAL = "https://t.me/noir_xis"

    local sg = Instance.new("ScreenGui")
    sg.Name = "vanta_keygui"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 2000
    sg.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 340)
    frame.Position = UDim2.new(0.5, -190, 0.65, -170)
    frame.BackgroundColor3 = Color3.fromRGB(18,12,28)
    frame.BackgroundTransparency = 0.25; frame.BorderSizePixel = 0
    frame.Active = true; frame.Draggable = true; frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 18)
    TweenService:Create(frame, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -190, 0.5, -170), BackgroundTransparency = 0.1}):Play()

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
        if setclipboard then pcall(function() setclipboard(TG_LINK_LOCAL) end) end
        tgBtn.Text = "скопировано  ·  " .. TG_LINK_LOCAL
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
        local ok, left, data = getgenv().vanta_checkKey(entered)
        btn.Active = true; btn.Text = "войти"
        if not ok then
            status.TextColor3 = Color3.fromRGB(255,120,140)
            status.Text = left or "ошибка"
            box.Text = ""
            return
        end
        getgenv().vanta_set_key(entered)
        getgenv().vanta_cfg.Key.Expiry = os.time() + (tonumber(left) or 0)
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

getgenv().zeusx_log("part", "21/25 OK · keygate")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 22/25 — bootstrap
-- ============================================================

getgenv().vanta_on_success = function()
    getgenv().zeusx_log("bootstrap", "start")

    if getgenv().vanta_init_esp then
        local ok, err = pcall(getgenv().vanta_init_esp)
        if not ok then getgenv().zeusx_log("ERR", "init_esp", err) end
    end

    if getgenv().vanta_create_menu then
        local ok, err = pcall(getgenv().vanta_create_menu)
        if not ok then
            getgenv().zeusx_log("ERR", "create_menu", err)
        else
            getgenv().zeusx_log("menu", "created")
        end
    else
        getgenv().zeusx_log("ERR", "vanta_create_menu missing")
    end

    task.wait(0.15)

    if getgenv().zeusx_rebuild_all_tabs then
        local ok, err = pcall(getgenv().zeusx_rebuild_all_tabs)
        if not ok then getgenv().zeusx_log("ERR", "rebuild_tabs", err) end
    end

    if getgenv().vanta_notify then
        pcall(function()
            getgenv().vanta_notify("Zeus-X v10.4 · online", 2.5)
        end)
    end

    getgenv().zeusx_log("bootstrap", "done")
end

getgenv().zeusx_show_keygate_safe = function()
    if not getgenv().vanta_show_keygate then
        warn("[zeusx] FATAL: vanta_show_keygate не определён — проверь порядок частей")
        return
    end
    local ok, err = pcall(getgenv().vanta_show_keygate, getgenv().vanta_on_success)
    if not ok then
        warn("[zeusx] FATAL: keygate упал с ошибкой: " .. tostring(err))
    end
end

getgenv().zeusx_log("part", "22/25 OK · bootstrap ready")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 23/25 — финальный запуск
-- ============================================================

getgenv().zeusx_log("launch", "все части загружены, запускаю keygate...")

task.spawn(function()
    task.wait(0.2)
    if getgenv().zeusx_show_keygate_safe then
        getgenv().zeusx_show_keygate_safe()
    else
        warn("[zeusx] FATAL: zeusx_show_keygate_safe не определён")
    end
end)

getgenv().zeusx_log("part", "23/25 OK · launch scheduled")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 24/25 — резерв
-- ============================================================

getgenv().zeusx_log("part", "24/25 OK · reserved")-- ============================================================
-- Zeus-X v10.4 · ЧАСТЬ 25/25 — FINAL
-- ============================================================

getgenv().zeusx_log("v10.4", "Ultimate loaded · 25/25")

print("============================================")
print("  Zeus-X v10.4 Ultimate · loaded")
print("  если keygate не появился — проверь:")
print("  1. executor поддерживает http/JSON")
print("  2. сервер доступен: zeus-key-mjep.onrender.com")
print("  3. в консоли есть [zeusx] сообщения")
print("============================================")
    