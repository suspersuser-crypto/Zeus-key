-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 1/14
-- services + config (расширенный) + hwid + keygate core
-- ============================================================

print("[zeusx-lite] v3.4 · part 1/14 — start")

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Stats        = game:GetService("Stats")
local Lighting     = game:GetService("Lighting")

local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

local SERVER_URL = "https://zeus-key-mjep.onrender.com/check"
local TG_LINK    = "https://t.me/noir_xis"
local CFG_DIR    = "zeusx"

if isfolder and not isfolder(CFG_DIR) then pcall(makefolder, CFG_DIR) end

local function log(tag, ...)
    local parts = {...}
    local msg = "[zeusx-lite][" .. tostring(tag) .. "]"
    for _, v in ipairs(parts) do msg = msg .. " " .. tostring(v) end
    pcall(print, msg)
end
getgenv().zeusx_log = log

-- ============================================================
-- CONFIG (расширенный)
-- ============================================================
getgenv().zeusx_cfg = {
    Aim = {
        Enabled=false, FOV=120, Smooth=0.35, FastSmooth=0.9,
        Key=Enum.UserInputType.MouseButton2, FastKey=Enum.KeyCode.LeftShift,
        Visible=true, StrictTeam=true, FriendCheck=true,
        Part="auto", Mode="camera",
        Prediction=false, PredictionStrength=0.5,
        IgnoreDying=true, DyingHpPct=15,
        TargetLockMs=180, Curve=true, FovCircle=false,
        -- NEW
        HitPriority=false,
        HitPriorityOrder={"Head","UpperTorso","HumanoidRootPart","LowerTorso"},
        TargetMemory=false,
        MemorySize=5,
        MemoryCooldownMs=8000,
        Presets = {
            verySmooth = { Smooth=0.15, FastSmooth=0.40 },
            medium     = { Smooth=0.35, FastSmooth=0.90 },
            fast       = { Smooth=0.70, FastSmooth=1.00 },
            insane     = { Smooth=0.95, FastSmooth=1.00 },
        },
    },
    Silent = {
        Enabled=false, HitChance=100,
        StrictTeam=true, FriendCheck=true,
        RequireVisible=false, Part="auto",
        FreezeMs=200, PerShotCooldownMs=30,
        SubstitutionMode="all",
        -- NEW
        PartRotation=false,
        PartRotationList={"Head","UpperTorso","Head","HumanoidRootPart"},
        PartRotationIndex=1,
    },
    Trigger = {
        Enabled=false, Mode="esp-box",
        Key=Enum.UserInputType.MouseButton1, AlwaysOn=false,
        Delay=0.06, AutoDelay=true, RandomizeDelay=0.30,
        WallCheck=true, StrictTeam=true, FriendCheck=true,
        MinDist=0, MaxDist=2000,
        HpMin=0, HpMax=100000,
        PixelRadius=40, HitboxRadius=45,
        RequireTool=true, FireMode="both",
        Burst=1, BurstGapMs=50,
        PrefireMs=0, AfterKillMs=0, RatePerSec=0,
        PreferHead=true, IgnoreDying=true, DyingHpPct=15,
        WeaponBlacklist={}, WeaponWhitelist={}, WhitelistMode=false,
        UniversalFov=200,
        -- NEW
        PrefireEnabled=false,
        PrefireDistance=100,
        PrefireFOV=15,
    },
    ESP = {
        Enabled=false, Box=true, Name=true, Health=true, Distance=true,
        Tracer=false, HeadDot=false, Skeleton=false, Chams=false, OffScreen=false,
        StrictTeam=true, FriendCheck=true, ShowTeammates=false,
        MaxDist=3000, HpFormat="hp", TracerStyle="bottom",
        BoxColor=Color3.fromRGB(170,120,255),
        SkeletonColor=Color3.fromRGB(220,180,255),
        ChamsColor=Color3.fromRGB(255,80,80),
        DistanceColor=true, InterpSpeed=1.0,
        -- NEW
        BoxFill=false,
        BoxFillTransparency=0.85,
        EnemyTeamColor=false,
        SkeletonMultiColor=true,
        SkeletonHeadColor=Color3.fromRGB(255,80,80),
        SkeletonArmColor=Color3.fromRGB(255,220,120),
        SkeletonLegColor=Color3.fromRGB(120,220,255),
        DistanceRings=false,
        DistanceRingRadii={50, 100, 200},
        DistanceRingColor=Color3.fromRGB(180,130,255),
    },
    Wallhack = {
        Enabled=false, Mode="chams-only",
        ChamsColor=Color3.fromRGB(255,80,80), ChamsFill=0.6,
        Transparent=0.15,
        ClearTerrain=false, ClearDecor=true,
        RestoreOnDisable=true,
    },
    Noclip = {
        Enabled=false, Key=Enum.KeyCode.N,
        IncludeHRP=true,
    },
    Fly = {
        Enabled=false, Speed=60, Key=Enum.KeyCode.F,
        Mode="normal",
    },
    Move = {
        -- NEW
        LongJump=false,
        LongJumpKey=Enum.KeyCode.Space,
        LongJumpPower=100,
        AntiFall=false,
        AntiFallThreshold=80,
        AutoClimb=false,
        AutoClimbHeight=8,
    },
    Team = { Friends={}, Whitelist={} },
    Misc = {
        Watermark=true, PanicKey=Enum.KeyCode.End,
        Hitsound=false, HitsoundVolume=0.4,
        KillNotify=false,
        Killstreak=false,
        FpsMonitor=false, PingMonitor=false,
        CustomCrosshair=false, CrosshairColor=Color3.fromRGB(255,80,80),
        CrosshairSize=14, CrosshairThickness=2,
        -- NEW
        WatermarkText="Zeus-X Lite v3.4",
        DiscordRP=false,
        CompactMode=false,
        AutoSaveSlot="default",
        SaveOnChange=false,
    },
    Anti = {
        FakeReaction=false,
        FakeReactionMinMs=150,
        FakeReactionMaxMs=250,
        AimMissChance=0,
        AutoDisableOnLag=false,
        LagThresholdMs=300,
        KickWarning=true,
        SessionTimeLimit=false,
        SessionTimeLimitMin=180,
        SuspiciousCheck=true,
    },
    UI = {
        SearchOpen=false,
        TooltipsEnabled=true,
        KeybindsOpen=false,
    },
    Key = { Active=nil, Expiry=0 },
}
getgenv().zeusx_Config = getgenv().zeusx_cfg

-- HWID
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

-- KEYGATE CORE
local function checkKeyOnServer(key)
    local hwid = getHWID()
    local username = LocalPlayer.Name
    local url = SERVER_URL .. "?token=" .. key .. "&hwid=" .. hwid .. "&username=" .. username .. "&ver=lite"
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

getgenv().zeusx_set_key = function(k)
    getgenv()._zeusx_active_key = k
    getgenv().zeusx_cfg.Key.Active = k
end
getgenv().zeusx_get_key = function()
    return getgenv()._zeusx_active_key
end

task.spawn(function()
    while task.wait(60) do
        local k = getgenv().zeusx_get_key()
        if not k then continue end
        local ok, msg = checkKeyOnServer(k)
        if ok == false then
            getgenv().zeusx_set_key(nil)
            log("key", "revoked:", msg)
            if getgenv().zeusx_disableAll then getgenv().zeusx_disableAll() end
            if getgenv().zeusx_show_keygate then
                getgenv().zeusx_show_keygate(getgenv().zeusx_on_success, tostring(msg))
            end
            break
        elseif ok == true then
            getgenv().zeusx_cfg.Key.Expiry = os.time() + (tonumber(msg) or 0)
        end
    end
end)

log("part", "1/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 2/14
-- team detection + helpers + config save/load
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local CFG_DIR     = "zeusx"

local teamCache = {}
task.spawn(function() while task.wait(5) do teamCache = {} end end)

local IGNORE_NAMES = { TheMlgShep=true, R15_Dummy=true, Dummy=true }
local SUSPICIOUS_KEYWORDS = {
    "admin","moder","staff","owner","dev",
    "youtube","yt ","verified","official","roblox",
}

local function isSuspicious(m)
    local cfg = getgenv().zeusx_cfg
    if not cfg.Anti.SuspiciousCheck then return false end
    local name = string.lower(m.Name)
    for _, kw in ipairs(SUSPICIOUS_KEYWORDS) do
        if string.find(name, kw, 1, true) then return true end
    end
    return false
end
getgenv().zeusx_isSuspicious = isSuspicious

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

local function getTeamColor(m)
    local plr = getPlayerOf(m)
    if plr and plr.TeamColor then return plr.TeamColor.Color end
    if plr and plr.Team then return plr.Team.TeamColor.Color end
    return nil
end

local function isFriend(m)
    local cfg = getgenv().zeusx_cfg
    local plr = getPlayerOf(m)
    if not plr then return false end
    for _, f in ipairs(cfg.Team.Friends) do
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
    local cfg = getgenv().zeusx_cfg
    if not m then return true end
    if m == LocalPlayer.Character then return true end
    if isSuspicious(m) then return true end
    if inList(cfg.Team.Whitelist, m.Name) then return true end
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
        local cfg = getgenv().zeusx_cfg
        if not LocalPlayer.GetFriendsAsync then return end
        local page = LocalPlayer:GetFriendsAsync()
        while true do
            for _, f in ipairs(page:GetCurrentPage()) do
                table.insert(cfg.Team.Friends, f.Id)
            end
            if page.IsFinished then break end
            page:AdvanceToNextPageAsync()
        end
    end)
end)

getgenv().zeusx_h = {
    getTargets=getTargets, getHumanoid=getHumanoid, getHead=getHead, getRoot=getRoot,
    isAlive=isAlive, partPos=partPos, resolvePart=resolvePart,
    w2s=w2s, isVisible=isVisible,
    shouldIgnore=shouldIgnore, isFriend=isFriend,
    isSameTeam=isSameTeam, getPlayerOf=getPlayerOf,
    isSuspicious=isSuspicious, getTeamColor=getTeamColor,
    collectPlayers=collectPlayers, collectWorkspace=collectWorkspace,
}

-- ============================================================
-- CONFIG SAVE / LOAD
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
        for k, vv in pairs(v) do
            if not (type(k) == "table") then
                o[k] = serialize(vv)
            end
        end
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
    slot = slot or getgenv().zeusx_cfg.Misc.AutoSaveSlot or "default"
    local data = serialize(deep_copy(getgenv().zeusx_cfg))
    local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
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
    local okD, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not okD or type(data) ~= "table" then return false end
    data = deserialize(data)
    local cfg = getgenv().zeusx_cfg
    for section, vals in pairs(data) do
        if cfg[section] and type(vals) == "table" then
            for k, v in pairs(vals) do cfg[section][k] = v end
        end
    end
    return true
end

getgenv().zeusx_log("part", "2/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 3/14 — AIM
-- + hit-part priority + target memory
-- ============================================================

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local CoreGui     = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local aimHeld = false
local fastHeld = false
local aimLockedTarget, aimLockedAt = nil, 0
local lastReactionAt = 0
local aimMissArmed = false
local killedMemory = {}  -- {[m] = unlock_tick}

local function cleanMemory()
    local now = tick()
    for m, t in pairs(killedMemory) do
        if now > t then killedMemory[m] = nil end
    end
end

local function isInMemory(m)
    local cfg = getgenv().zeusx_cfg.Aim
    if not cfg.TargetMemory then return false end
    local t = killedMemory[m]
    if not t then return false end
    if tick() > t then killedMemory[m] = nil; return false end
    return true
end

getgenv().zeusx_markKilled = function(m)
    local cfg = getgenv().zeusx_cfg.Aim
    if not cfg.TargetMemory then return end
    killedMemory[m] = tick() + (cfg.MemoryCooldownMs / 1000)
end

local function getRootVelocity(model)
    local H = getgenv().zeusx_h
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
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    return H.shouldIgnore(m, {
        StrictTeam=cfg.Aim.StrictTeam,
        FriendCheck=cfg.Aim.FriendCheck,
    })
end

local function dyingCheck(m)
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not cfg.Aim.IgnoreDying then return true end
    local hum = H.getHumanoid(m)
    if not hum then return true end
    local pct = hum.Health / math.max(hum.MaxHealth, 1) * 100
    return pct > cfg.Aim.DyingHpPct
end

-- NEW: pick part с приоритетом
local function pickBestPart(m)
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Aim
    if cfg.HitPriority then
        for _, p in ipairs(cfg.HitPriorityOrder) do
            if m:FindFirstChild(p, true) then return p end
        end
    end
    return H.resolvePart(m, cfg.Part)
end

local function scoreTargetAim(m, fov, camPos, center)
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not H.isAlive(m) then return nil end
    if aimIgnore(m) then return nil end
    if not dyingCheck(m) then return nil end
    if isInMemory(m) then return nil end
    local part = pickBestPart(m)
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
    local score = pxD + worldD * 0.05
    return score, m, pos
end

local function pickAimTarget()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    local now = tick()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    cleanMemory()

    if aimLockedTarget and (now - aimLockedAt) * 1000 < cfg.Aim.TargetLockMs then
        if H.isAlive(aimLockedTarget) and not aimIgnore(aimLockedTarget) and not isInMemory(aimLockedTarget) then
            local part = pickBestPart(aimLockedTarget)
            local pos = H.partPos(aimLockedTarget, part)
            if pos then
                if cfg.Aim.Prediction then
                    pos = predictPos(aimLockedTarget, pos, cfg.Aim.PredictionStrength)
                end
                local screen = H.w2s(pos)
                if screen and (screen - center).Magnitude <= cfg.Aim.FOV * 1.3 then
                    return aimLockedTarget, pos
                end
            end
        end
        aimLockedTarget = nil
    end

    local best, bestScore, bestPos = nil, math.huge, nil
    for _, m in ipairs(H.getTargets()) do
        local s, mm, pp = scoreTargetAim(m, cfg.Aim.FOV, camPos, center)
        if s and s < bestScore then best, bestScore, bestPos = mm, s, pp end
    end

    if best then aimLockedTarget = best; aimLockedAt = now end
    return best, bestPos
end

local function aimAt(pos)
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if cfg.Aim.Mode == "camera" then
        local camCF = Camera.CFrame
        local newCF = CFrame.new(camCF.Position, pos)
        local baseSmooth = fastHeld and cfg.Aim.FastSmooth or cfg.Aim.Smooth
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
        local screen = H.w2s(pos)
        if not screen then return end
        local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
        local baseSmooth = fastHeld and cfg.Aim.FastSmooth or cfg.Aim.Smooth
        local delta = (screen - center) * math.clamp(baseSmooth, 0.05, 1)
        if math.abs(delta.X) < 1 and math.abs(delta.Y) < 1 then return end
        if mousemoverel then mousemoverel(delta.X, delta.Y) end
    end
end

local function updateAim()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not cfg.Aim.Enabled or not aimHeld then return end
    if not H.isAlive(LocalPlayer.Character) then return end

    if cfg.Anti.FakeReaction then
        local now = tick()
        if now - lastReactionAt < (cfg.Anti.FakeReactionMinMs / 1000) then return end
    end

    local target, pos = pickAimTarget()
    if not target or not pos then return end

    if cfg.Anti.FakeReaction and lastReactionAt == 0 then
        lastReactionAt = tick()
    end

    if cfg.Anti.AimMissChance > 0 and not aimMissArmed then
        if math.random(1, 100) <= cfg.Anti.AimMissChance then
            aimMissArmed = true
        end
    end

    if aimMissArmed then
        local offset = Vector3.new(
            (math.random() - 0.5) * 6,
            (math.random() - 0.5) * 4,
            (math.random() - 0.5) * 6
        )
        aimAt(pos + offset)
        task.delay(0.15, function() aimMissArmed = false end)
    else
        aimAt(pos)
    end
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local cfg = getgenv().zeusx_cfg
    if i.UserInputType == cfg.Aim.Key then
        aimHeld = true
        if cfg.Anti.FakeReaction then
            lastReactionAt = tick() + math.random(
                cfg.Anti.FakeReactionMinMs,
                cfg.Anti.FakeReactionMaxMs
            ) / 1000
        end
    end
    if i.KeyCode == cfg.Aim.FastKey then fastHeld = true end
end)
UIS.InputEnded:Connect(function(i)
    local cfg = getgenv().zeusx_cfg
    if i.UserInputType == cfg.Aim.Key then
        aimHeld = false
        lastReactionAt = 0
    end
    if i.KeyCode == cfg.Aim.FastKey then fastHeld = false end
end)

local fovCircle
local function updateFovCircle()
    local cfg = getgenv().zeusx_cfg
    if not cfg.Aim.FovCircle or not cfg.Aim.Enabled then
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
            sg.Parent = sg
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(180,130,255); s.Thickness = 1.5; s.Transparency = 0.3
        s.Parent = fovCircle
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0); corner.Parent = fovCircle
    end
    fovCircle.Visible = true
    fovCircle.Size = UDim2.new(0, cfg.Aim.FOV*2, 0, cfg.Aim.FOV*2)
end

getgenv().zeusx_updateAim = updateAim
getgenv().zeusx_updateFovCircle = updateFovCircle
getgenv().zeusx_log("part", "3/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 4/14 — SILENT AIM
-- + part rotation
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local silentTarget, silentFrozenPos = nil, nil
local silentLockedAt = 0

local function silentIgnore(m)
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    return H.shouldIgnore(m, {
        StrictTeam=cfg.Silent.StrictTeam,
        FriendCheck=cfg.Silent.FriendCheck,
    })
end

local SILENT_PARTS_ORDER = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" }

local function silentPickPart(m)
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Silent
    if cfg.PartRotation then
        local list = cfg.PartRotationList
        local idx = (cfg.PartRotationIndex - 1) % #list + 1
        local partName = list[idx]
        if m:FindFirstChild(partName, true) then return partName end
    end
    if cfg.Part ~= "auto" then
        return H.resolvePart(m, cfg.Part)
    end
    for _, p in ipairs(SILENT_PARTS_ORDER) do
        local part = m:FindFirstChild(p, true)
        if part and part:IsA("BasePart") then
            if not cfg.RequireVisible or H.isVisible(m, p) then
                return p
            end
        end
    end
    return H.resolvePart(m, "auto")
end

local function getSilentTarget()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Silent
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local best, bestScore, bestPos = nil, math.huge, nil
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not silentIgnore(m) then
            local part = silentPickPart(m)
            local pos = H.partPos(m, part)
            if pos then
                local visibleOk = true
                if cfg.RequireVisible then visibleOk = H.isVisible(m, part) end
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
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Silent
    if not cfg.Enabled then
        silentTarget, silentFrozenPos = nil, nil
        return
    end
    local now = tick()
    if silentTarget and silentFrozenPos and (now - silentLockedAt)*1000 < cfg.FreezeMs then
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
            local cfg = getgenv().zeusx_cfg.Silent
            local method = getnamecallmethod()
            if cfg.Enabled and silentTarget and silentFrozenPos and method == "FireServer" then
                local now = tick()
                if (now - (getgenv()._silent_lastshot or 0))*1000 < cfg.PerShotCooldownMs then
                    return old(self, ...)
                end
                getgenv()._silent_lastshot = now
                local args = {...}
                local mod = false
                for i = 1, #args do
                    if typeof(args[i]) == "Vector3" then
                        if cfg.SubstitutionMode == "all" then
                            args[i] = silentFrozenPos; mod = true
                        else
                            local dCam = (args[i] - Camera.CFrame.Position).Magnitude
                            if dCam > 5 then args[i] = silentFrozenPos; mod = true end
                        end
                    end
                end
                if mod then
                    if math.random(1,100) <= cfg.HitChance then
                        -- rotate index после выстрела
                        if cfg.PartRotation then
                            cfg.PartRotationIndex = (cfg.PartRotationIndex % #cfg.PartRotationList) + 1
                        end
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
getgenv().zeusx_log("part", "4/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 5/14 — TRIGGERBOT + PREFIRE
-- ============================================================

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local trigHeld         = false
local lastShot         = 0
local lastAutoDelay    = 0.06
local lastKillTime     = 0
local shotTimes        = {}
local trigLockedTarget = nil
local trigLockUntil    = 0
local prefireLastShot  = 0

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
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Trigger
    return H.shouldIgnore(m, {
        StrictTeam=cfg.StrictTeam,
        FriendCheck=cfg.FriendCheck,
    })
end

local function dyingCheckT(m)
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Trigger
    if not cfg.IgnoreDying then return true end
    local hum = H.getHumanoid(m)
    if not hum then return true end
    local pct = hum.Health / math.max(hum.MaxHealth, 1) * 100
    return pct > cfg.DyingHpPct
end

local function toolReady(tool)
    local cfg = getgenv().zeusx_cfg.Trigger
    if not cfg.RequireTool then
        if tool then
            if cfg.WhitelistMode then
                if #cfg.WeaponWhitelist > 0 and not inList(cfg.WeaponWhitelist, tool.Name) then
                    return false
                end
            else
                if inList(cfg.WeaponBlacklist, tool.Name) then return false end
            end
        end
        return true
    end
    if not tool then return false end
    if not tool.Enabled then return false end
    local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("AmmoValue")
    if ammo and ammo:IsA("IntValue") and ammo.Value <= 0 then return false end
    if cfg.WhitelistMode then
        if #cfg.WeaponWhitelist > 0 and not inList(cfg.WeaponWhitelist, tool.Name) then
            return false
        end
    else
        if inList(cfg.WeaponBlacklist, tool.Name) then return false end
    end
    return true
end

local function fireWeapon()
    local cfg = getgenv().zeusx_cfg.Trigger
    local tool = getCurrentTool()
    if cfg.FireMode == "mouse1click" or cfg.FireMode == "both" then
        if mouse1click then pcall(mouse1click) end
    end
    if (cfg.FireMode == "remoteevent" or cfg.FireMode == "both") and tool then
        for _, name in ipairs({"Fire","Shoot","Attack","FireWeapon","ShootEvent","FireEvent","WeaponFire"}) do
            local r = tool:FindFirstChild(name)
            if r and r:IsA("RemoteEvent") then
                pcall(function() r:FireServer() end)
                break
            end
        end
    end
end

local function isCrosshairInEspBox(m)
    local H = getgenv().zeusx_h
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
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Trigger
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local radius = cfg.HitboxRadius
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

local function isPixelHit(m)
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Trigger
    local partName = cfg.PreferHead and "Head" or H.resolvePart(m, "auto")
    local part = m:FindFirstChild(partName, true)
    if not part then return false end
    local sc = H.w2s(part.Position)
    if not sc then return false end
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    return (sc - center).Magnitude < cfg.PixelRadius
end

local function universalScore(m)
    local H = getgenv().zeusx_h
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local bestPart = nil
    local bestDist = math.huge
    for _, part in ipairs(m:GetDescendants()) do
        if part:IsA("BasePart") then
            local name = part.Name
            if name ~= "HumanoidRootPart" and not name:find("Accessory") and not name:find("Handle") then
                local sc, onScreen = H.w2s(part.Position)
                if sc and onScreen then
                    local d = (sc - center).Magnitude
                    if d < bestDist then bestDist = d; bestPart = part end
                end
            end
        end
    end
    return bestDist, bestPart
end

local function isUniversalHit(m)
    local cfg = getgenv().zeusx_cfg.Trigger
    local d, part = universalScore(m)
    if not part then return false end
    return d <= cfg.UniversalFov
end

local function getBestTriggerTarget()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Trigger
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)

    if trigLockedTarget and tick() < trigLockUntil then
        if H.isAlive(trigLockedTarget) and not triggerIgnore(trigLockedTarget) then
            local ok = false
            if cfg.Mode == "esp-box" then ok = isCrosshairInEspBox(trigLockedTarget)
            elseif cfg.Mode == "hitbox" then ok = isCrosshairOnHitbox(trigLockedTarget)
            elseif cfg.Mode == "pixel" then ok = isPixelHit(trigLockedTarget)
            elseif cfg.Mode == "universal" then ok = isUniversalHit(trigLockedTarget) end
            if ok then return trigLockedTarget end
        end
        trigLockedTarget = nil
    end

    local best, bestScore = nil, math.huge
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not triggerIgnore(m) and dyingCheckT(m) then
            local root = H.getRoot(m)
            local hum = H.getHumanoid(m)
            if root and hum then
                local d = (camPos - root.Position).Magnitude
                if d >= cfg.MinDist and d <= cfg.MaxDist then
                    local hp = hum.Health
                    if hp >= cfg.HpMin and hp <= cfg.HpMax then
                        local wallOk = true
                        if cfg.WallCheck then
                            local part = cfg.PreferHead and "Head" or H.resolvePart(m, "auto")
                            wallOk = H.isVisible(m, part)
                        end
                        if wallOk then
                            local inAim = false
                            local score = math.huge
                            if cfg.Mode == "esp-box" then
                                inAim = isCrosshairInEspBox(m)
                                if inAim then score = 1 end
                            elseif cfg.Mode == "hitbox" then
                                inAim = isCrosshairOnHitbox(m)
                                if inAim then score = 1 end
                            elseif cfg.Mode == "pixel" then
                                local partName = cfg.PreferHead and "Head" or H.resolvePart(m, "auto")
                                local part = m:FindFirstChild(partName, true)
                                if part then
                                    local sc = H.w2s(part.Position)
                                    if sc then
                                        local pxD = (sc - center).Magnitude
                                        if pxD < cfg.PixelRadius then inAim = true; score = pxD end
                                    end
                                end
                            elseif cfg.Mode == "universal" then
                                local d2 = universalScore(m)
                                if d2 <= cfg.UniversalFov then inAim = true; score = d2 end
                            end
                            if inAim and score < bestScore then best = m; bestScore = score end
                        end
                    end
                end
            end
        end
    end

    if best then
        trigLockedTarget = best
        trigLockUntil = tick() + 0.25
    end
    return best
end

-- NEW: PREFIRE — стреляем заранее в угол
local function updatePrefire()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Trigger
    if not cfg.PrefireEnabled or not cfg.Enabled then return end
    if not H.isAlive(LocalPlayer.Character) then return end
    local now = tick()
    if now - prefireLastShot < 0.15 then return end
    local tool = getCurrentTool()
    if not toolReady(tool) then return end

    local camPos = Camera.CFrame.Position
    local camLook = Camera.CFrame.LookVector
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not triggerIgnore(m) then
            local root = H.getRoot(m)
            if root then
                local toTarget = root.Position - camPos
                local dist = toTarget.Magnitude
                if dist <= cfg.PrefireDistance and dist > 3 then
                    local dot = camLook:Dot(toTarget.Unit)
                    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
                    if angle <= cfg.PrefireFOV and angle > 3 then
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (now - prefireLastShot) > 0.2 then
                            fireWeapon()
                            prefireLastShot = now
                            return
                        end
                    end
                end
            end
        end
    end
end

local function rateLimitOk()
    local cfg = getgenv().zeusx_cfg.Trigger
    if cfg.RatePerSec <= 0 then return true end
    local now = tick()
    local cutoff = now - 1
    local new = {}
    for _, t in ipairs(shotTimes) do
        if t >= cutoff then table.insert(new, t) end
    end
    shotTimes = new
    return #shotTimes < cfg.RatePerSec
end

local function updateTrigger()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg.Trigger
    if not cfg.Enabled then return end
    if not cfg.AlwaysOn and not trigHeld then return end
    if not H.isAlive(LocalPlayer.Character) then return end

    local now = tick()
    if (now - lastKillTime)*1000 < cfg.AfterKillMs then return end

    local delay = cfg.AutoDelay and lastAutoDelay or cfg.Delay
    if cfg.RandomizeDelay > 0 then
        local jitter = delay * cfg.RandomizeDelay
        delay = delay + (math.random() * 2 - 1) * jitter
        if math.random() < 0.08 then delay = delay * (1.4 + math.random() * 0.6) end
    end
    if now - lastShot < delay then return end
    if not rateLimitOk() then return end

    local tool = getCurrentTool()
    if not toolReady(tool) then return end

    local target = getBestTriggerTarget()
    if not target then return end

    if cfg.AutoDelay and tool then
        local rate = tool:GetAttribute("FireRate") or tool:GetAttribute("RPM")
        if type(rate) == "number" and rate > 0 then
            lastAutoDelay = math.max(0.03, 60 / rate * 1.05)
        else
            lastAutoDelay = cfg.Delay
        end
    end

    if cfg.PrefireMs > 0 then
        task.wait(cfg.PrefireMs / 1000)
        if not cfg.Enabled then return end
    end

    fireWeapon()
    lastShot = now
    table.insert(shotTimes, now)

    if cfg.Burst > 1 then
        task.spawn(function()
            for i = 2, cfg.Burst do
                task.wait(cfg.BurstGapMs / 1000)
                if cfg.Enabled and (cfg.AlwaysOn or trigHeld) then fireWeapon() end
            end
        end)
    end
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local key = getgenv().zeusx_cfg.Trigger.Key
    if i.UserInputType == key or i.KeyCode == key then trigHeld = true end
end)
UIS.InputEnded:Connect(function(i)
    local key = getgenv().zeusx_cfg.Trigger.Key
    if i.UserInputType == key or i.KeyCode == key then trigHeld = false end
end)

getgenv().zeusx_updateTrigger = updateTrigger
getgenv().zeusx_updatePrefire = updatePrefire
getgenv().zeusx_log("part", "5/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 6/14 — ESP CORE (с fill и team color)
-- ============================================================

local CoreGui     = game:GetService("CoreGui")
local Workspace   = game:GetService("Workspace")
local Camera      = Workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer

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
    local cfg = getgenv().zeusx_cfg
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1; box.BorderSizePixel = 0; box.Visible = false
    box.Parent = espGui
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = cfg.ESP.BoxColor
    fill.BackgroundTransparency = cfg.ESP.BoxFillTransparency
    fill.BorderSizePixel = 0
    fill.Visible = false
    fill.Parent = box
    local stroke = Instance.new("UIStroke")
    stroke.Color = cfg.ESP.BoxColor; stroke.Thickness = 1.5; stroke.Parent = box

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
        box=box, fill=fill, stroke=stroke, hpBg=hpBg, hpFill=hpFill, tracer=tracer, headDot=headDot,
        name=mkLabel(Color3.fromRGB(255,255,255), 13),
        hp=mkLabel(Color3.fromRGB(180,255,180), 11),
        dist=mkLabel(Color3.fromRGB(200,200,200), 11),
        _sx=nil, _sy=nil, _sw=nil, _sh=nil,
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
    t.box.Visible=false; t.fill.Visible=false; t.name.Visible=false
    t.hp.Visible=false; t.dist.Visible=false
    t.hpBg.Visible=false; t.tracer.Visible=false; t.headDot.Visible=false
end

local function lerp(a, b, alpha) return a + (b - a) * alpha end

local function renderESP()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not espGui then return end
    if not cfg.ESP.Enabled then
        for _, t in pairs(ESP) do hideAll(t) end
        return
    end
    local myPos = Camera.CFrame.Position
    local seen = {}
    local interp = math.clamp(cfg.ESP.InterpSpeed, 0.3, 1.0)

    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        local t = ESP[m]
        if not t then createESP(m); t = ESP[m] end

        local ignore = H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam,
            FriendCheck=cfg.ESP.FriendCheck,
            ShowTeammates=cfg.ESP.ShowTeammates,
        })
        local show = H.isAlive(m) and not ignore
        local root = H.getRoot(m)
        if show and root and (myPos - root.Position).Magnitude > cfg.ESP.MaxDist then show = false end
        if not show then hideAll(t); continue end

        local head = H.getHead(m)
        local hum = H.getHumanoid(m)
        if not head or not root then hideAll(t); continue end

        local top = H.w2s(head.Position + Vector3.new(0, 1, 0))
        local bot = H.w2s(root.Position - Vector3.new(0, 3, 0))
        if not top or not bot then hideAll(t); continue end

        local targetX = top.X
        local targetY = top.Y
        local targetW = (bot.Y - top.Y) * 0.5
        local targetH = bot.Y - top.Y

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

        local hpNow = hum and hum.Health or 100
        local maxHpNow = hum and hum.MaxHealth or 100
        local hpRatio = math.clamp(hpNow / maxHpNow, 0, 1)

        -- team color override
        local boxColor
        if isFriendTgt then
            boxColor = Color3.fromRGB(120,220,255)
        elseif cfg.ESP.EnemyTeamColor then
            local tc = H.getTeamColor(m)
            boxColor = tc or cfg.ESP.BoxColor
        elseif hpRatio < 0.3 then
            boxColor = Color3.fromRGB(255,60,60)
        elseif hpRatio < 0.6 then
            boxColor = Color3.fromRGB(255,200,60)
        elseif cfg.ESP.DistanceColor then
            local ratio = math.clamp(dist / cfg.ESP.MaxDist, 0, 1)
            boxColor = Color3.new(1, 1 - ratio, 0.3)
        else
            boxColor = cfg.ESP.BoxColor
        end
        t.stroke.Color = boxColor
        t.fill.BackgroundColor3 = boxColor

        t.box.Visible = cfg.ESP.Box
        t.box.Size = UDim2.new(0, w, 0, h)
        t.box.Position = UDim2.new(0, cx - w/2, 0, cy)
        t.fill.Visible = cfg.ESP.BoxFill
        t.fill.Size = UDim2.new(1, 0, 1, 0)
        t.fill.BackgroundTransparency = cfg.ESP.BoxFillTransparency

        t.name.Visible = cfg.ESP.Name
        t.name.Text = m.Name
        t.name.TextColor3 = boxColor
        t.name.Size = UDim2.new(0, 200, 0, 16)
        t.name.Position = UDim2.new(0, cx - 100, 0, cy - 18)

        t.hpBg.Visible = cfg.ESP.Health
        t.hpBg.Size = UDim2.new(0, 3, 0, h)
        t.hpBg.Position = UDim2.new(0, cx - w/2 - 6, 0, cy)
        t.hpFill.Size = UDim2.new(1, 0, hpRatio, 0)
        t.hpFill.Position = UDim2.new(0, 0, 1 - hpRatio, 0)
        t.hpFill.BackgroundColor3 = hpRatio > 0.5 and Color3.fromRGB(100,220,140) or Color3.fromRGB(255,120,140)

        t.hp.Visible = cfg.ESP.Health
        if cfg.ESP.HpFormat == "hp_max" then
            t.hp.Text = math.floor(hpNow) .. "/" .. math.floor(maxHpNow)
        elseif cfg.ESP.HpFormat == "pct" then
            t.hp.Text = math.floor(hpRatio*100) .. "%"
        else
            t.hp.Text = math.floor(hpNow) .. " hp"
        end
        t.hp.Size = UDim2.new(0, 200, 0, 14)
        t.hp.Position = UDim2.new(0, cx - 100, 0, cy + h + 2)

        t.dist.Visible = cfg.ESP.Distance
        t.dist.Text = math.floor(dist) .. " m"
        t.dist.Size = UDim2.new(0, 200, 0, 14)
        t.dist.Position = UDim2.new(0, cx - 100, 0, cy + h + 16)

        if cfg.ESP.HeadDot then
            local headScr = H.w2s(head.Position)
            if headScr then
                t.headDot.Visible = true
                t.headDot.Position = UDim2.new(0, headScr.X, 0, headScr.Y)
            end
        else t.headDot.Visible = false end

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
        else t.tracer.Visible = false end
    end
    for m in pairs(ESP) do
        if not seen[m] or not m.Parent then destroyESP(m) end
    end
end

getgenv().zeusx_initESP = initESP
getgenv().zeusx_renderESP = renderESP
getgenv().zeusx_log("part", "6/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 7/14 — ESP ADV: skeleton + chams + arrows + rings
-- ============================================================

local CoreGui   = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera    = Workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer

-- SKELETON с multi-colour
local skelGui, SKEL = nil, nil

local R6_BONES_HEAD = {{"Head","Torso"}}
local R6_BONES_ARM  = {{"Torso","Left Arm"},{"Torso","Right Arm"}}
local R6_BONES_LEG  = {{"Torso","Left Leg"},{"Torso","Right Leg"}}
local R15_BONES_HEAD = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"}}
local R15_BONES_ARM  = {
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
}
local R15_BONES_LEG = {
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
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

local function createSkel(m) if SKEL[m] then return end; SKEL[m] = { lines = {} } end
local function destroySkel(m)
    if not SKEL[m] then return end
    for _, l in ipairs(SKEL[m].lines) do pcall(function() l:Destroy() end) end
    SKEL[m] = nil
end

local function drawLine(a, b, parent, color)
    if not a or not b then return nil end
    local d = b - a
    local line = Instance.new("Frame")
    line.BackgroundColor3 = color or Color3.fromRGB(220,180,255)
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
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not cfg.ESP.Enabled or not cfg.ESP.Skeleton then
        if SKEL then for m in pairs(SKEL) do destroySkel(m) end end
        return
    end
    initSkeleton()
    local seen = {}
    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        local ignore = H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam,
            FriendCheck=cfg.ESP.FriendCheck,
            ShowTeammates=cfg.ESP.ShowTeammates,
        })
        if not H.isAlive(m) or ignore then
            if SKEL[m] then destroySkel(m) end
            continue
        end
        createSkel(m)
        local data = SKEL[m]
        for _, l in ipairs(data.lines) do l.Visible = false end
        local isR15 = m:FindFirstChild("UpperTorso") ~= nil
        local headB = isR15 and R15_BONES_HEAD or R6_BONES_HEAD
        local armB = isR15 and R15_BONES_ARM or R6_BONES_ARM
        local legB = isR15 and R15_BONES_LEG or R6_BONES_LEG

        local headC = cfg.ESP.SkeletonMultiColor and cfg.ESP.SkeletonHeadColor or cfg.ESP.SkeletonColor
        local armC = cfg.ESP.SkeletonMultiColor and cfg.ESP.SkeletonArmColor or cfg.ESP.SkeletonColor
        local legC = cfg.ESP.SkeletonMultiColor and cfg.ESP.SkeletonLegColor or cfg.ESP.SkeletonColor

        local idx = 1
        local function drawGroup(bones, color)
            for _, pair in ipairs(bones) do
                local a = m:FindFirstChild(pair[1], true)
                local b = m:FindFirstChild(pair[2], true)
                if a and b then
                    local sa = H.w2s(a.Position)
                    local sb = H.w2s(b.Position)
                    if sa and sb then
                        local line = data.lines[idx]
                        if not line then
                            line = drawLine(sa, sb, skelGui, color)
                            table.insert(data.lines, line)
                        else
                            local d = sb - sa
                            line.Visible = true
                            line.BackgroundColor3 = color
                            line.Size = UDim2.new(0, d.Magnitude, 0, 1)
                            line.Position = UDim2.new(0, sa.X, 0, sa.Y)
                            line.Rotation = math.deg(math.atan2(d.Y, d.X))
                        end
                        idx = idx + 1
                    end
                end
            end
        end
        drawGroup(headB, headC)
        drawGroup(armB, armC)
        drawGroup(legB, legC)
    end
    for m in pairs(SKEL) do
        if not seen[m] or not m.Parent then destroySkel(m) end
    end
end

-- CHAMS
local chamsFolder = nil

local function renderChams()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not cfg.ESP.Enabled or not cfg.ESP.Chams then
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
            StrictTeam=cfg.ESP.StrictTeam,
            FriendCheck=cfg.ESP.FriendCheck,
            ShowTeammates=cfg.ESP.ShowTeammates,
        }) then
            active[m] = true
            local hl = chamsFolder:FindFirstChild(m.Name)
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = m.Name
                hl.Parent = chamsFolder
            end
            hl.Adornee = m
            hl.FillColor = cfg.ESP.ChamsColor
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

-- ARROWS
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
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not cfg.ESP.Enabled or not cfg.ESP.OffScreen then
        if ARROWS then for _, a in ipairs(ARROWS) do a.Visible = false end end
        return
    end
    initArrows()
    local idx = 0
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam,
            FriendCheck=cfg.ESP.FriendCheck,
            ShowTeammates=cfg.ESP.ShowTeammates,
        }) then
            local head = H.getHead(m)
            if head then
                local scr, onScreen = H.w2s(head.Position)
                if scr and not onScreen then
                    idx = idx + 1
                    if not ARROWS[idx] then
                        local f = Instance.new("TextLabel")
                        f.Size = UDim2.new(0, 60, 0, 24)
                        f.BackgroundColor3 = Color3.fromRGB(180,130,255)
                        f.BackgroundTransparency = 0.2
                        f.BorderSizePixel = 0
                        f.Text = "▲"
                        f.TextColor3 = Color3.fromRGB(255,255,255)
                        f.Font = Enum.Font.GothamBold
                        f.TextSize = 12
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
                    arrow.Position = UDim2.new(0, pos.X - 30, 0, pos.Y - 12)
                    arrow.Rotation = math.deg(angle)
                    local dist = (Camera.CFrame.Position - head.Position).Magnitude
                    arrow.Text = "▲ " .. math.floor(dist)
                end
            end
        end
    end
    for i = idx + 1, #ARROWS do ARROWS[i].Visible = false end
end

-- DISTANCE RINGS (на земле)
local ringsGui, rings = nil, {}

local function initRings()
    if ringsGui then return end
    local parent = (gethui and gethui()) or CoreGui
    ringsGui = Instance.new("ScreenGui")
    ringsGui.Name = "zeusx_rings"
    ringsGui.ResetOnSpawn = false
    ringsGui.IgnoreGuiInset = true
    ringsGui.DisplayOrder = 990
    ringsGui.Parent = parent
end

local function renderRings()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not cfg.ESP.Enabled or not cfg.ESP.DistanceRings then
        for _, r in ipairs(rings) do r.Visible = false end
        return
    end
    initRings()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position
    local groundY = myPos.Y - 3

    local ringIdx = 0
    for _, radius in ipairs(cfg.ESP.DistanceRingRadii) do
        local points = 32
        for i = 0, points - 1 do
            ringIdx += 1
            if not rings[ringIdx] then
                local dot = Instance.new("Frame")
                dot.BorderSizePixel = 0
                dot.Size = UDim2.new(0, 4, 0, 4)
                dot.AnchorPoint = Vector2.new(0.5, 0.5)
                dot.Parent = ringsGui
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                rings[ringIdx] = dot
            end
            local ring = rings[ringIdx]
            local angle = (i / points) * math.pi * 2
            local pos = myPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            pos = Vector3.new(pos.X, groundY, pos.Z)
            local scr = H.w2s(pos)
            if scr then
                ring.Visible = true
                ring.Position = UDim2.new(0, scr.X, 0, scr.Y)
                ring.BackgroundColor3 = cfg.ESP.DistanceRingColor
                ring.BackgroundTransparency = 0.3
            else
                ring.Visible = false
            end
        end
    end
    for i = ringIdx + 1, #rings do rings[i].Visible = false end
end

getgenv().zeusx_renderSkeleton = renderSkeleton
getgenv().zeusx_renderChams = renderChams
getgenv().zeusx_renderArrows = renderArrows
getgenv().zeusx_renderRings = renderRings
getgenv().zeusx_log("part", "7/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 8/14 — WALLHACK + NOCLIP + FLY (modes)
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local UIS         = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- WALLHACK
local whFolder       = nil
local whHidden       = {}
local whHiddenCanCollide = {}
local whActive       = false
local whLastMode     = nil
local whAppliedOnce  = false
local whConn         = nil

local function isCharacterPart(part)
    if not part or not part.Parent then return false end
    local model = part:FindFirstAncestorOfClass("Model")
    while model do
        if model:FindFirstChildOfClass("Humanoid") then return true end
        model = model:FindFirstAncestorOfClass("Model")
    end
    return false
end

local function shouldHideForWallhack(inst)
    local cfg = getgenv().zeusx_cfg
    if not inst or not inst.Parent then return false end
    if inst:IsA("Terrain") then return cfg.Wallhack.ClearTerrain end
    if inst:IsA("BasePart") then
        if isCharacterPart(inst) then return false end
        if inst.Name == "Baseplate" and not cfg.Wallhack.ClearDecor then return false end
        return true
    end
    return false
end

local function renderChamsOnly()
    local H = getgenv().zeusx_h
    local cfg = getgenv().zeusx_cfg
    if not whFolder then
        whFolder = Instance.new("Folder")
        whFolder.Name = "zeusx_wallhack"
        whFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end
    local active = {}
    for _, m in ipairs(H.getTargets()) do
        if H.isAlive(m) and not H.shouldIgnore(m, {
            StrictTeam=cfg.ESP.StrictTeam,
            FriendCheck=cfg.ESP.FriendCheck,
            ShowTeammates=cfg.ESP.ShowTeammates,
        }) then
            active[m] = true
            local hl = whFolder:FindFirstChild(m.Name)
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = m.Name
                hl.Parent = whFolder
            end
            hl.Adornee = m
            hl.FillColor = cfg.Wallhack.ChamsColor
            hl.FillTransparency = cfg.Wallhack.ChamsFill
            hl.OutlineColor = Color3.fromRGB(255,255,255)
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
    for _, h in ipairs(whFolder:GetChildren()) do
        if not active[h.Name] then h.Adornee = nil; h:Destroy() end
    end
end

local function applyWallsTransparent()
    local cfg = getgenv().zeusx_cfg
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if shouldHideForWallhack(obj) then
            if whHidden[obj] == nil then whHidden[obj] = obj.LocalTransparencyModifier end
            obj.LocalTransparencyModifier = 1 - cfg.Wallhack.Transparent
        end
    end
end

local function restoreWallsTransparent()
    for obj, orig in pairs(whHidden) do
        if obj and obj.Parent then pcall(function() obj.LocalTransparencyModifier = orig end) end
    end
    whHidden = {}
end

local function applyFullClear()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if shouldHideForWallhack(obj) then
            if whHidden[obj] == nil then whHidden[obj] = obj.Transparency end
            if whHiddenCanCollide[obj] == nil then whHiddenCanCollide[obj] = obj.CanCollide end
            pcall(function()
                obj.Transparency = 1
                obj.CanCollide = false
            end)
        end
    end
end

local function restoreFullClear()
    for obj, orig in pairs(whHidden) do
        if obj and obj.Parent then pcall(function() obj.Transparency = orig end) end
    end
    for obj, orig in pairs(whHiddenCanCollide) do
        if obj and obj.Parent then pcall(function() obj.CanCollide = orig end) end
    end
    whHidden = {}; whHiddenCanCollide = {}
end

local function disconnectWhConn()
    if whConn then whConn:Disconnect(); whConn = nil end
end

local function updateWallhack()
    local cfg = getgenv().zeusx_cfg
    if not cfg.Wallhack.Enabled then
        if whActive then
            disconnectWhConn()
            if whLastMode == "walls-transparent" then restoreWallsTransparent()
            elseif whLastMode == "full-clear" then restoreFullClear() end
            if whFolder then for _, h in ipairs(whFolder:GetChildren()) do h:Destroy() end end
            whActive = false; whLastMode = nil; whAppliedOnce = false
        end
        return
    end
    local mode = cfg.Wallhack.Mode
    if whActive and whLastMode ~= mode then
        disconnectWhConn()
        if whLastMode == "walls-transparent" then restoreWallsTransparent()
        elseif whLastMode == "full-clear" then restoreFullClear() end
        if whFolder then for _, h in ipairs(whFolder:GetChildren()) do h:Destroy() end end
        whAppliedOnce = false
    end
    if mode == "chams-only" then
        renderChamsOnly(); whActive = true; whLastMode = mode; return
    end
    if not whAppliedOnce then
        if mode == "walls-transparent" then applyWallsTransparent()
        elseif mode == "full-clear" then applyFullClear() end
        whAppliedOnce = true; whActive = true; whLastMode = mode
        disconnectWhConn()
        whConn = Workspace.DescendantAdded:Connect(function(obj)
            if not getgenv().zeusx_cfg.Wallhack.Enabled then return end
            if not shouldHideForWallhack(obj) then return end
            task.defer(function()
                if not obj or not obj.Parent then return end
                if mode == "walls-transparent" then
                    if whHidden[obj] == nil then whHidden[obj] = obj.LocalTransparencyModifier end
                    pcall(function() obj.LocalTransparencyModifier = 1 - getgenv().zeusx_cfg.Wallhack.Transparent end)
                elseif mode == "full-clear" then
                    if whHidden[obj] == nil then whHidden[obj] = obj.Transparency end
                    if whHiddenCanCollide[obj] == nil then whHiddenCanCollide[obj] = obj.CanCollide end
                    pcall(function() obj.Transparency = 1; obj.CanCollide = false end)
                end
            end)
        end)
    end
end

-- NOCLIP
local noclipApplied = false
local function applyNoclipToPart(part)
    if not part or not part.Parent then return end
    pcall(function() part.CanCollide = false; part.CanQuery = false; part.CanTouch = false end)
end
local function updateNoclip()
    local cfg = getgenv().zeusx_cfg
    if not cfg.Noclip.Enabled then
        if noclipApplied then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = true; part.CanQuery = true; part.CanTouch = true end)
                    end
                end
            end
            noclipApplied = false
        end
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then applyNoclipToPart(part) end
    end
    if cfg.Noclip.IncludeHRP then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then applyNoclipToPart(hrp) end
    end
    noclipApplied = true
end

-- FLY (3 modes)
local flyActive = false
local flyBodyVelocity = nil
local flyBodyGyro = nil

local function stopFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.PlatformStand = false end) end
    end
    flyActive = false
end

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if not flyBodyVelocity then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBodyVelocity.Velocity = Vector3.zero
        flyBodyVelocity.Parent = hrp
    end
    if not flyBodyGyro then
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBodyGyro.P = 3000; flyBodyGyro.D = 50
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp
    end
    pcall(function() hum.PlatformStand = true end)
    flyActive = true
end

local function updateFly()
    local cfg = getgenv().zeusx_cfg
    if not cfg.Fly.Enabled then
        if flyActive then stopFly() end
        return
    end
    if not flyActive then startFly() end
    if not flyActive then return end
    local char = LocalPlayer.Character
    if not char then stopFly(); return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then stopFly(); return end

    local camCF = Camera.CFrame
    local move = Vector3.zero
    if cfg.Fly.Mode == "hover" then
        -- висим на месте, но можно медленно двигать
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector * 0.3 end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector * 0.3 end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) * 0.5 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) * 0.5 end
        move = move * cfg.Fly.Speed
    elseif cfg.Fly.Mode == "cruise" then
        -- автолёт по WASD, без остановки
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
        if move.Magnitude > 0 then move = move.Unit * cfg.Fly.Speed * 1.5 end
    else
        -- normal
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        if move.Magnitude > 0 then move = move.Unit * cfg.Fly.Speed end
    end
    if flyBodyVelocity then flyBodyVelocity.Velocity = move end
    if flyBodyGyro then
        flyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local cfg = getgenv().zeusx_cfg
    if i.KeyCode == cfg.Noclip.Key then
        cfg.Noclip.Enabled = not cfg.Noclip.Enabled
        getgenv().zeusx_log("noclip", tostring(cfg.Noclip.Enabled))
    end
    if i.KeyCode == cfg.Fly.Key then
        cfg.Fly.Enabled = not cfg.Fly.Enabled
        getgenv().zeusx_log("fly", tostring(cfg.Fly.Enabled))
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if getgenv().zeusx_cfg.Noclip.Enabled then updateNoclip() end
end)

getgenv().zeusx_updateWallhack = updateWallhack
getgenv().zeusx_updateNoclip   = updateNoclip
getgenv().zeusx_updateFly      = updateFly
getgenv().zeusx_log("part", "8/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 9/14 — MOVE (longjump / antifall / climb)
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local UIS         = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local longJumpQueued = false
local lastFallY = nil

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    local cfg = getgenv().zeusx_cfg
    if cfg.Move.LongJump and i.KeyCode == cfg.Move.LongJumpKey then
        longJumpQueued = true
    end
end)

local function updateMove()
    local cfg = getgenv().zeusx_cfg
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- LONG JUMP
    if longJumpQueued and hum.FloorMaterial ~= Enum.Material.Air then
        local vel = hrp.AssemblyLinearVelocity or hrp.Velocity
        local horiz = Vector3.new(vel.X, 0, vel.Z)
        if horiz.Magnitude < 1 then
            horiz = hum.MoveDirection * 20
        end
        hrp.AssemblyLinearVelocity = horiz.Unit * cfg.Move.LongJumpPower + Vector3.new(0, 50, 0)
        longJumpQueued = false
    end

    -- ANTI-FALL
    if cfg.Move.AntiFall then
        local vel = hrp.AssemblyLinearVelocity or hrp.Velocity
        if vel.Y < -cfg.Move.AntiFallThreshold then
            hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -cfg.Move.AntiFallThreshold, vel.Z)
        end
    end

    -- AUTO CLIMB
    if cfg.Move.AutoClimb then
        if UIS:IsKeyDown(Enum.KeyCode.W) then
            local ray = Ray.new(hrp.Position, hrp.CFrame.LookVector * 3 + Vector3.new(0, -1, 0))
            local hitPart = Workspace:FindPartOnRay(ray, char)
            if hitPart then
                local height = hrp.Position.Y - hitPart.Position.Y
                if height > 1 and height < cfg.Move.AutoClimbHeight then
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 1.5, 0)
                end
            end
        end
    end
end

getgenv().zeusx_updateMove = updateMove
getgenv().zeusx_log("part", "9/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 10/14 — HUD + Discord RP
-- ============================================================

local Players     = game:GetService("Players")
local CoreGui     = game:GetService("CoreGui")
local SoundService= game:GetService("SoundService")
local Stats       = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local function hudCfg() return getgenv().zeusx_cfg.Misc end

getgenv().zeusx_playHitsound = function()
    local cfg = hudCfg()
    if not cfg.Hitsound then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://6042053626"
        s.Volume = cfg.HitsoundVolume
        s.Parent = SoundService
        s:Play()
        task.delay(2, function() if s and s.Parent then s:Destroy() end end)
    end)
end

-- NOTIFY SYSTEM
local notifyGui, notifyContainer
local function initNotify()
    if notifyGui then return end
    local parent = (gethui and gethui()) or CoreGui
    notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = "zeusx_killnotify"
    notifyGui.ResetOnSpawn = false
    notifyGui.IgnoreGuiInset = true
    notifyGui.DisplayOrder = 5000
    notifyGui.Parent = parent
    notifyContainer = Instance.new("Frame")
    notifyContainer.Size = UDim2.new(0, 240, 1, -40)
    notifyContainer.Position = UDim2.new(1, -260, 0, 20)
    notifyContainer.BackgroundTransparency = 1
    notifyContainer.Parent = notifyGui
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = notifyContainer
end

getgenv().zeusx_pushNotify = function(text, color)
    initNotify()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = color or Color3.fromRGB(60,25,32)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = notifyContainer
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(220,150,255); s.Thickness = 1; s.Transparency = 0.5; s.Parent = frame
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    local Tween = game:GetService("TweenService")
    Tween:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.15}):Play()
    task.delay(3, function()
        if not frame.Parent then return end
        Tween:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        Tween:Create(lbl, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        task.wait(0.5)
        if frame then frame:Destroy() end
    end)
end

-- KILL TRACKER + STREAK
local killstreak = 0
local tracked = {}

task.spawn(function()
    while task.wait(0.5) do
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and not tracked[hum] then
                    tracked[hum] = true
                    hum.Died:Connect(function()
                        if not hudCfg().KillNotify then return end
                        local creator = hum:FindFirstChild("creator")
                        if creator and creator.Value == LocalPlayer then
                            killstreak += 1
                            getgenv().zeusx_pushNotify("☠ " .. p.Name .. " · streak " .. killstreak, Color3.fromRGB(80,40,120))
                            if hudCfg().Hitsound then getgenv().zeusx_playHitsound() end
                            if getgenv().zeusx_markKilled then getgenv().zeusx_markKilled(p.Character) end
                        else
                            getgenv().zeusx_pushNotify("☠ " .. p.Name, Color3.fromRGB(60,30,40))
                        end
                    end)
                end
            end
        end
        local myChar = LocalPlayer.Character
        if myChar then
            local myHum = myChar:FindFirstChildOfClass("Humanoid")
            if myHum and not tracked[myHum] then
                tracked[myHum] = true
                myHum.Died:Connect(function()
                    killstreak = 0
                    if hudCfg().KillNotify then
                        getgenv().zeusx_pushNotify("💀 killed · streak reset", Color3.fromRGB(140,40,60))
                    end
                end)
            end
        end
    end
end)

-- FPS / PING
local fpsGui, fpsLbl
local frameCount = 0
local lastFpsTick = tick()

local function renderFps()
    local cfg = hudCfg()
    if not cfg.FpsMonitor and not cfg.PingMonitor then
        if fpsGui then fpsGui.Enabled = false end
        return
    end
    local parent = (gethui and gethui()) or CoreGui
    if not fpsGui then
        fpsGui = Instance.new("ScreenGui")
        fpsGui.Name = "zeusx_fps"
        fpsGui.ResetOnSpawn = false
        fpsGui.IgnoreGuiInset = true
        fpsGui.DisplayOrder = 4990
        fpsGui.Parent = parent
        fpsLbl = Instance.new("TextLabel")
        fpsLbl.Size = UDim2.new(0, 260, 0, 26)
        fpsLbl.Position = UDim2.new(0, 12, 0, 46)
        fpsLbl.BackgroundColor3 = Color3.fromRGB(20,14,30)
        fpsLbl.BackgroundTransparency = 0.4
        fpsLbl.BorderSizePixel = 0
        fpsLbl.TextColor3 = Color3.fromRGB(180,140,255)
        fpsLbl.Font = Enum.Font.GothamBold
        fpsLbl.TextSize = 12
        fpsLbl.TextXAlignment = Enum.TextXAlignment.Left
        fpsLbl.Parent = fpsGui
        Instance.new("UICorner", fpsLbl).CornerRadius = UDim.new(0, 6)
    end
    fpsGui.Enabled = true
    frameCount += 1
    local now = tick()
    if now - lastFpsTick >= 1 then
        local fps = math.floor(frameCount / (now - lastFpsTick))
        local parts = {}
        if cfg.FpsMonitor then table.insert(parts, "FPS " .. fps) end
        if cfg.PingMonitor then
            local ping = "?"
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            table.insert(parts, "PING " .. ping .. "ms")
        end
        fpsLbl.Text = "  " .. table.concat(parts, "  ·  ")
        frameCount = 0
        lastFpsTick = now
    end
end

-- STREAK UI
local streakGui, streakLbl
local function renderStreak()
    local cfg = hudCfg()
    if not cfg.Killstreak or killstreak < 2 then
        if streakGui then streakGui.Enabled = false end
        return
    end
    local parent = (gethui and gethui()) or CoreGui
    if not streakGui then
        streakGui = Instance.new("ScreenGui")
        streakGui.Name = "zeusx_streak"
        streakGui.ResetOnSpawn = false
        streakGui.IgnoreGuiInset = true
        streakGui.DisplayOrder = 5010
        streakGui.Parent = parent
        streakLbl = Instance.new("TextLabel")
        streakLbl.Size = UDim2.new(0, 220, 0, 34)
        streakLbl.Position = UDim2.new(0.5, -110, 0, 12)
        streakLbl.BackgroundColor3 = Color3.fromRGB(120,60,180)
        streakLbl.BackgroundTransparency = 0.2
        streakLbl.BorderSizePixel = 0
        streakLbl.TextColor3 = Color3.fromRGB(255,220,255)
        streakLbl.Font = Enum.Font.GothamBlack
        streakLbl.TextSize = 18
        streakLbl.Parent = streakGui
        Instance.new("UICorner", streakLbl).CornerRadius = UDim.new(0, 10)
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(220,150,255); s.Thickness = 1.5; s.Parent = streakLbl
    end
    streakGui.Enabled = true
    streakLbl.Text = "🔥 STREAK x" .. killstreak
    if killstreak >= 10 then streakLbl.BackgroundColor3 = Color3.fromRGB(180,40,40)
    elseif killstreak >= 5 then streakLbl.BackgroundColor3 = Color3.fromRGB(160,80,40)
    else streakLbl.BackgroundColor3 = Color3.fromRGB(120,60,180) end
end

-- CROSSHAIR
local chGui, chV, chH, chDot
local function renderCrosshair()
    local cfg = hudCfg()
    if not cfg.CustomCrosshair then
        if chGui then chGui.Enabled = false end
        return
    end
    local parent = (gethui and gethui()) or CoreGui
    if not chGui then
        chGui = Instance.new("ScreenGui")
        chGui.Name = "zeusx_crosshair"
        chGui.ResetOnSpawn = false
        chGui.IgnoreGuiInset = true
        chGui.DisplayOrder = 5020
        chGui.Parent = parent
        chV = Instance.new("Frame"); chV.BorderSizePixel = 0
        chV.AnchorPoint = Vector2.new(0.5, 0.5); chV.Position = UDim2.new(0.5, 0, 0.5, 0); chV.Parent = chGui
        chH = Instance.new("Frame"); chH.BorderSizePixel = 0
        chH.AnchorPoint = Vector2.new(0.5, 0.5); chH.Position = UDim2.new(0.5, 0, 0.5, 0); chH.Parent = chGui
        chDot = Instance.new("Frame"); chDot.BorderSizePixel = 0
        chDot.AnchorPoint = Vector2.new(0.5, 0.5); chDot.Position = UDim2.new(0.5, 0, 0.5, 0)
        chDot.Size = UDim2.new(0, 2, 0, 2); chDot.Parent = chGui
        Instance.new("UICorner", chDot).CornerRadius = UDim.new(1, 0)
    end
    chGui.Enabled = true
    local sz = cfg.CrosshairSize
    local th = cfg.CrosshairThickness
    chV.Size = UDim2.new(0, th, 0, sz); chV.BackgroundColor3 = cfg.CrosshairColor
    chH.Size = UDim2.new(0, sz, 0, th); chH.BackgroundColor3 = cfg.CrosshairColor
    chDot.BackgroundColor3 = cfg.CrosshairColor
end

-- KICK WARNING
local kickGui, kickShown = nil, false
local function showKickWarning(msg)
    if kickShown then return end
    kickShown = true
    local parent = (gethui and gethui()) or CoreGui
    kickGui = Instance.new("ScreenGui")
    kickGui.Name = "zeusx_kickwarn"; kickGui.ResetOnSpawn = false
    kickGui.IgnoreGuiInset = true; kickGui.DisplayOrder = 9999; kickGui.Parent = parent
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BackgroundTransparency = 0.4; frame.BorderSizePixel = 0; frame.Parent = kickGui
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 400, 0, 200)
    card.Position = UDim2.new(0.5, -200, 0.5, -100)
    card.BackgroundColor3 = Color3.fromRGB(140,30,30)
    card.BorderSizePixel = 0; card.Parent = frame
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -40, 0, 40); t.Position = UDim2.new(0, 20, 0, 20)
    t.BackgroundTransparency = 1; t.Text = "⚠ KICK WARNING"
    t.TextColor3 = Color3.fromRGB(255,255,255)
    t.Font = Enum.Font.GothamBlack; t.TextSize = 24; t.Parent = card
    local b = Instance.new("TextLabel")
    b.Size = UDim2.new(1, -40, 0, 100); b.Position = UDim2.new(0, 20, 0, 70)
    b.BackgroundTransparency = 1; b.Text = msg .. "\n\nВсе функции выключены."
    b.TextColor3 = Color3.fromRGB(255,220,220)
    b.Font = Enum.Font.GothamBold; b.TextSize = 14; b.TextWrapped = true; b.Parent = card
end

pcall(function()
    game:GetService("LogService").MessageOut:Connect(function(msg, msgType)
        if not getgenv().zeusx_cfg.Anti.KickWarning then return end
        local lower = string.lower(msg)
        if string.find(lower, "kick") or string.find(lower, "banned") or string.find(lower, "detected") then
            if getgenv().zeusx_disableAll then getgenv().zeusx_disableAll() end
            showKickWarning(msg)
        end
    end)
end)

-- DISCORD RP (если executor поддерживает)
task.spawn(function()
    while task.wait(5) do
        if not getgenv().zeusx_cfg.Misc.DiscordRP then continue end
        pcall(function()
            if setfflag then
                -- не форсим, но если executor умеет — настраиваем
                -- это настройка клиента, не наша
            end
        end)
    end
end)

getgenv().zeusx_renderFps = renderFps
getgenv().zeusx_renderStreak = renderStreak
getgenv().zeusx_renderCrosshair = renderCrosshair
getgenv().zeusx_log("part", "10/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 11/14 — MENU CORE + search + compact + keybind manager
-- ============================================================

local UIS          = game:GetService("UserInputService")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Camera       = game:GetService("Workspace").CurrentCamera

local A = {
    bg = Color3.fromRGB(18,12,28), panel = Color3.fromRGB(38,28,58),
    accent = Color3.fromRGB(180,130,255), accentD = Color3.fromRGB(110,70,190),
    text = Color3.fromRGB(235,225,250), textDim = Color3.fromRGB(170,155,200),
}

local function tweenQuad(o,t,p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

-- Поиск-индекс
getgenv().zeusx_searchIndex = {}
getgenv().zeusx_addSearch = function(name, tab, buildFn)
    table.insert(getgenv().zeusx_searchIndex, {name=name, tab=tab, build=buildFn})
end

getgenv().zeusx_openSearch = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx then return end
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("zeusx_search"); if old then old:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "zeusx_search"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 3500; sg.Parent = parent
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 360, 0, 44)
    box.Position = UDim2.new(0.5, -180, 0, 60)
    box.BackgroundColor3 = Color3.fromRGB(28,20,44)
    box.BackgroundTransparency = 0.15; box.BorderSizePixel = 0
    box.PlaceholderText = "поиск настройки..."
    box.Text = ""; box.TextColor3 = Color3.fromRGB(235,225,250)
    box.PlaceholderColor3 = Color3.fromRGB(140,120,180)
    box.Font = Enum.Font.GothamBold; box.TextSize = 14
    box.ClearTextOnFocus = false; box.Parent = sg
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(180,130,255); s.Thickness = 1.4; s.Parent = box
    box:CaptureFocus()
    box.FocusLost:Connect(function()
        local q = string.lower(box.Text)
        sg:Destroy()
        if q == "" then return end
        for _, item in ipairs(getgenv().zeusx_searchIndex) do
            if string.find(string.lower(item.name), q, 1, true) then
                ctx.setActiveTab(item.tab)
                if getgenv().zeusx_pushNotify then
                    getgenv().zeusx_pushNotify("→ " .. item.tab .. " · " .. item.name, Color3.fromRGB(60,120,60))
                end
                return
            end
        end
        if getgenv().zeusx_pushNotify then
            getgenv().zeusx_pushNotify("не найдено", Color3.fromRGB(140,40,60))
        end
    end)
end

-- KEYBIND MANAGER
getgenv().zeusx_openKeybinds = function()
    local cfg = getgenv().zeusx_cfg
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("zeusx_keybinds"); if old then old:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "zeusx_keybinds"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 3500; sg.Parent = parent
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 360, 0, 400)
    frame.Position = UDim2.new(0.5, -180, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(18,12,28)
    frame.BackgroundTransparency = 0.1; frame.BorderSizePixel = 0; frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(180,130,255); s.Thickness = 1.4; s.Parent = frame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40); title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1; title.Text = "⌨ KEYBINDS"
    title.TextColor3 = Color3.fromRGB(180,130,255)
    title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.Parent = frame
    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -20, 1, -100)
    list.Position = UDim2.new(0, 10, 0, 60)
    list.BackgroundTransparency = 1; list.BorderSizePixel = 0
    list.ScrollBarThickness = 4; list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.Parent = frame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6); layout.Parent = list

    local function makeRow(name, get, set)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36); row.BackgroundColor3 = Color3.fromRGB(38,28,58)
        row.BackgroundTransparency = 0.4; row.BorderSizePixel = 0; row.Parent = list
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -120, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(235,225,250)
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 0, 26); btn.Position = UDim2.new(1, -110, 0.5, -13)
        btn.BackgroundColor3 = Color3.fromRGB(52,38,80); btn.BackgroundTransparency = 0.3
        btn.Text = tostring(get()); btn.TextColor3 = Color3.fromRGB(220,150,255)
        btn.Font = Enum.Font.Gotham; btn.TextSize = 12
        btn.BorderSizePixel = 0; btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(function()
            btn.Text = "нажми..."
            local conn
            conn = UIS.InputBegan:Connect(function(i, gpe)
                if gpe then return end
                if conn then conn:Disconnect() end
                local newKey = i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode or i.UserInputType
                set(newKey)
                btn.Text = tostring(newKey)
            end)
        end)
    end

    makeRow("aim key", function() return cfg.Aim.Key end, function(v) cfg.Aim.Key = v end)
    makeRow("fast key", function() return cfg.Aim.FastKey end, function(v) cfg.Aim.FastKey = v end)
    makeRow("trigger key", function() return cfg.Trigger.Key end, function(v) cfg.Trigger.Key = v end)
    makeRow("noclip", function() return cfg.Noclip.Key end, function(v) cfg.Noclip.Key = v end)
    makeRow("fly", function() return cfg.Fly.Key end, function(v) cfg.Fly.Key = v end)
    makeRow("long jump", function() return cfg.Move.LongJumpKey end, function(v) cfg.Move.LongJumpKey = v end)
    makeRow("panic", function() return cfg.Misc.PanicKey end, function(v) cfg.Misc.PanicKey = v end)

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(1, -40, 0, 32); close.Position = UDim2.new(0, 20, 1, -46)
    close.BackgroundColor3 = Color3.fromRGB(140,30,30); close.BackgroundTransparency = 0.2
    close.Text = "закрыть"; close.TextColor3 = Color3.fromRGB(255,255,255)
    close.Font = Enum.Font.GothamBold; close.TextSize = 13
    close.BorderSizePixel = 0; close.Parent = frame
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    close.MouseButton1Click:Connect(function() sg:Destroy() end)
end

-- MAIN MENU CREATE
getgenv().zeusx_create_menu = function()
    local parent = (gethui and gethui()) or CoreGui
    if getgenv().zeusx_menu and getgenv().zeusx_menu.Parent then
        getgenv().zeusx_menu:Destroy()
    end
    local vp = Camera.ViewportSize
    local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
    local compact = getgenv().zeusx_cfg.Misc.CompactMode
    local winW = isMobile and math.floor(vp.X * 0.94) or math.min(compact and 600 or 720, math.floor(vp.X * 0.72))
    local winH = isMobile and math.floor(vp.Y * 0.80) or math.min(compact and 520 or 640, math.floor(vp.Y * 0.84))
    if winW < 320 then winW = 320 end
    if winH < 420 then winH = 420 end
    local HEADER_H = 44
    local TABS_H = 38
    local TAB_W = 72

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

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, HEADER_H); bar.BackgroundTransparency = 1; bar.Parent = win
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -260, 1, 0); title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "Zeus-X Lite v3.4"
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

    iconBtn(-176, "🔍", A.panel, function() getgenv().zeusx_openSearch() end)
    iconBtn(-140, "⌨", A.panel, function() getgenv().zeusx_openKeybinds() end)
    iconBtn(-104, "💾", A.panel, function()
        local ok = getgenv().zeusx_saveConfig(getgenv().zeusx_cfg.Misc.AutoSaveSlot)
        if getgenv().zeusx_pushNotify then
            getgenv().zeusx_pushNotify(ok and "config saved" or "save failed", Color3.fromRGB(60,120,60))
        end
    end)
    iconBtn(-68, "📂", A.panel, function()
        local ok = getgenv().zeusx_loadConfig(getgenv().zeusx_cfg.Misc.AutoSaveSlot)
        if getgenv().zeusx_pushNotify then
            getgenv().zeusx_pushNotify(ok and "config loaded" or "load failed", Color3.fromRGB(60,120,60))
        end
    end)
    iconBtn(-32, "×", Color3.fromRGB(60,25,32), function() sg:Destroy(); getgenv().zeusx_menu = nil end)

    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Size = UDim2.new(1, -16, 0, TABS_H)
    tabBar.Position = UDim2.new(0, 8, 0, HEADER_H + 4)
    tabBar.BackgroundTransparency = 1; tabBar.BorderSizePixel = 0
    tabBar.ScrollBarThickness = 3; tabBar.ScrollBarImageColor3 = A.accent
    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.Parent = win
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4); tabLayout.Parent = tabBar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -16, 1, -(HEADER_H + TABS_H + 12))
    content.Position = UDim2.new(0, 8, 0, HEADER_H + TABS_H + 8)
    content.BackgroundTransparency = 1; content.ClipsDescendants = true; content.Parent = win

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0); scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = A.accent; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6); layout.Parent = scroll
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4); pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 14); pad.Parent = scroll

    -- helpers
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
            btn.Text = options[idx]; set(options[idx])
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
            if not ok then getgenv().zeusx_log("ERR", "tab build '"..name.."'", err) end
        end
    end

    getgenv().zeusx_menu_ctx = {
        A = A, scroll = scroll,
        makeTab = makeTab, setActiveTab = setActiveTab,
        section = section, toggle = toggle, slider = slider,
        dropdown = dropdown, inputBox = inputBox, button = button,
        tweenQuad = tweenQuad, sg = sg,
    }

    return sg
end

getgenv().zeusx_log("part", "11/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 12/14 — TABS: AIM + TRIGGER + ANTI
-- ============================================================

local LocalPlayer = game:GetService("Players").LocalPlayer

getgenv().zeusx_build_tabs_aim_trigger = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx then return end
    local Config = getgenv().zeusx_cfg
    local makeTab = ctx.makeTab; local section = ctx.section
    local toggle = ctx.toggle; local slider = ctx.slider
    local dropdown = ctx.dropdown; local inputBox = ctx.inputBox
    local button = ctx.button

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

        section("HIT PRIORITY")
        toggle("enable priority", function() return Config.Aim.HitPriority end, function(v) Config.Aim.HitPriority=v end)
        button("head → torso → root", function()
            Config.Aim.HitPriorityOrder = {"Head","UpperTorso","HumanoidRootPart","LowerTorso"}
            if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("priority set", Color3.fromRGB(60,120,60)) end
        end)
        button("torso → head", function()
            Config.Aim.HitPriorityOrder = {"UpperTorso","Head","HumanoidRootPart","LowerTorso"}
            if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("priority set", Color3.fromRGB(60,120,60)) end
        end)

        section("TARGET MEMORY")
        toggle("skip recent kills", function() return Config.Aim.TargetMemory end, function(v) Config.Aim.TargetMemory=v end)
        slider("memory cooldown ms", 2000, 20000,
            function() return Config.Aim.MemoryCooldownMs end,
            function(v) Config.Aim.MemoryCooldownMs=v end)

        section("SMOOTH PRESETS")
        button("very smooth", function()
            Config.Aim.Smooth = Config.Aim.Presets.verySmooth.Smooth
            Config.Aim.FastSmooth = Config.Aim.Presets.verySmooth.FastSmooth
            if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("→ very smooth", Color3.fromRGB(60,120,60)) end
        end)
        button("medium", function()
            Config.Aim.Smooth = Config.Aim.Presets.medium.Smooth
            Config.Aim.FastSmooth = Config.Aim.Presets.medium.FastSmooth
            if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("→ medium", Color3.fromRGB(60,120,60)) end
        end)
        button("fast", function()
            Config.Aim.Smooth = Config.Aim.Presets.fast.Smooth
            Config.Aim.FastSmooth = Config.Aim.Presets.fast.FastSmooth
            if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("→ fast", Color3.fromRGB(120,90,60)) end
        end)
        button("insane", function()
            Config.Aim.Smooth = Config.Aim.Presets.insane.Smooth
            Config.Aim.FastSmooth = Config.Aim.Presets.insane.FastSmooth
            if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("→ insane", Color3.fromRGB(140,40,40)) end
        end)

        section("TUNING")
        slider("fov", 10, 400, function() return Config.Aim.FOV end, function(v) Config.Aim.FOV=v end)
        slider("smooth %", 2, 100,
            function() return math.floor(Config.Aim.Smooth*100) end,
            function(v) Config.Aim.Smooth=v/100 end)
        slider("fast smooth %", 2, 100,
            function() return math.floor(Config.Aim.FastSmooth*100) end,
            function(v) Config.Aim.FastSmooth=v/100 end)
        slider("target lock ms", 0, 500,
            function() return Config.Aim.TargetLockMs end,
            function(v) Config.Aim.TargetLockMs=v end)

        section("SILENT AIM")
        toggle("silent aim", function() return Config.Silent.Enabled end, function(v) Config.Silent.Enabled=v end)
        toggle("strict team", function() return Config.Silent.StrictTeam end, function(v) Config.Silent.StrictTeam=v end)
        slider("hit chance %", 10, 100,
            function() return Config.Silent.HitChance end,
            function(v) Config.Silent.HitChance=v end)
        slider("freeze ms", 0, 500,
            function() return Config.Silent.FreezeMs end,
            function(v) Config.Silent.FreezeMs=v end)
        dropdown("silent hit part",
            {"auto","Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso"},
            function() return Config.Silent.Part end,
            function(v) Config.Silent.Part=v end)

        section("PART ROTATION")
        toggle("rotate hit parts", function() return Config.Silent.PartRotation end, function(v) Config.Silent.PartRotation=v end)
    end

    local tTrig = makeTab("trigger")
    tTrig.build = function()
        local cfgT = Config.Trigger
        section("TRIGGERBOT")
        toggle("triggerbot enable", function() return cfgT.Enabled end, function(v) cfgT.Enabled=v end)
        toggle("always on", function() return cfgT.AlwaysOn end, function(v) cfgT.AlwaysOn=v end)
        toggle("strict team", function() return cfgT.StrictTeam end, function(v) cfgT.StrictTeam=v end)
        toggle("wall check", function() return cfgT.WallCheck end, function(v) cfgT.WallCheck=v end)

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
        slider("manual delay ms", 10, 300,
            function() return math.floor(cfgT.Delay*1000) end,
            function(v) cfgT.Delay=v/1000 end)
        slider("randomize delay %", 0, 100,
            function() return math.floor(cfgT.RandomizeDelay*100) end,
            function(v) cfgT.RandomizeDelay=v/100 end)

        section("PREFIRE")
        toggle("enable prefire", function() return cfgT.PrefireEnabled end, function(v) cfgT.PrefireEnabled=v end)
        slider("prefire distance", 20, 300,
            function() return cfgT.PrefireDistance end,
            function(v) cfgT.PrefireDistance=v end)
        slider("prefire angle °", 5, 45,
            function() return cfgT.PrefireFOV end,
            function(v) cfgT.PrefireFOV=v end)

        section("HITBOX")
        slider("hitbox radius", 10, 150,
            function() return cfgT.HitboxRadius end,
            function(v) cfgT.HitboxRadius=v end)
        slider("universal fov", 50, 500,
            function() return cfgT.UniversalFov end,
            function(v) cfgT.UniversalFov=v end)
    end

    local tAnti = makeTab("anti")
    tAnti.build = function()
        local cfgA = Config.Anti
        section("FAKE REACTION TIME")
        toggle("enable", function() return cfgA.FakeReaction end, function(v) cfgA.FakeReaction = v end)
        slider("min ms", 50, 500,
            function() return cfgA.FakeReactionMinMs end,
            function(v) cfgA.FakeReactionMinMs = v end)
        slider("max ms", 50, 500,
            function() return cfgA.FakeReactionMaxMs end,
            function(v) cfgA.FakeReactionMaxMs = v end)

        section("AIM MISS CHANCE")
        slider("miss chance %", 0, 50,
            function() return cfgA.AimMissChance end,
            function(v) cfgA.AimMissChance = v end)

        section("AUTO-DISABLE ON LAG")
        toggle("enable", function() return cfgA.AutoDisableOnLag end, function(v) cfgA.AutoDisableOnLag = v end)
        slider("lag threshold ms", 100, 800,
            function() return cfgA.LagThresholdMs end,
            function(v) cfgA.LagThresholdMs = v end)

        section("KICK WARNING")
        toggle("enable", function() return cfgA.KickWarning end, function(v) cfgA.KickWarning = v end)

        section("SESSION TIME LIMIT")
        toggle("enable", function() return cfgA.SessionTimeLimit end, function(v) cfgA.SessionTimeLimit = v end)
        slider("limit minutes", 30, 480,
            function() return cfgA.SessionTimeLimitMin end,
            function(v) cfgA.SessionTimeLimitMin = v end)

        section("SUSPICIOUS CHECK")
        toggle("skip admin/moder/staff", function() return cfgA.SuspiciousCheck end, function(v) cfgA.SuspiciousCheck = v end)
    end
end

getgenv().zeusx_log("part", "12/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 13/14 — TABS: ESP + WALL + TEAM + MISC
-- ============================================================

getgenv().zeusx_build_tabs_esp_wall = function()
    local ctx = getgenv().zeusx_menu_ctx
    if not ctx then return end
    local Config = getgenv().zeusx_cfg
    local makeTab = ctx.makeTab; local setActiveTab = ctx.setActiveTab
    local section = ctx.section; local toggle = ctx.toggle
    local slider = ctx.slider; local dropdown = ctx.dropdown
    local inputBox = ctx.inputBox; local button = ctx.button; local sg = ctx.sg

    local tEsp = makeTab("esp")
    tEsp.build = function()
        section("ESP")
        toggle("esp enable", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled=v end)
        toggle("box", function() return Config.ESP.Box end, function(v) Config.ESP.Box=v end)
        toggle("box fill", function() return Config.ESP.BoxFill end, function(v) Config.ESP.BoxFill=v end)
        toggle("name", function() return Config.ESP.Name end, function(v) Config.ESP.Name=v end)
        toggle("health bar", function() return Config.ESP.Health end, function(v) Config.ESP.Health=v end)
        toggle("distance", function() return Config.ESP.Distance end, function(v) Config.ESP.Distance=v end)
        toggle("tracer", function() return Config.ESP.Tracer end, function(v) Config.ESP.Tracer=v end)
        toggle("head dot", function() return Config.ESP.HeadDot end, function(v) Config.ESP.HeadDot=v end)
        toggle("skeleton", function() return Config.ESP.Skeleton end, function(v) Config.ESP.Skeleton=v end)
        toggle("chams", function() return Config.ESP.Chams end, function(v) Config.ESP.Chams=v end)
        toggle("off-screen arrows", function() return Config.ESP.OffScreen end, function(v) Config.ESP.OffScreen=v end)

        section("COLOURS")
        toggle("distance color", function() return Config.ESP.DistanceColor end, function(v) Config.ESP.DistanceColor=v end)
        toggle("enemy team color", function() return Config.ESP.EnemyTeamColor end, function(v) Config.ESP.EnemyTeamColor=v end)
        toggle("skeleton multi-color", function() return Config.ESP.SkeletonMultiColor end, function(v) Config.ESP.SkeletonMultiColor=v end)

        section("DISTANCE RINGS")
        toggle("enable rings", function() return Config.ESP.DistanceRings end, function(v) Config.ESP.DistanceRings=v end)

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
    end

    local tWall = makeTab("wall")
    tWall.build = function()
        section("WALLHACK")
        toggle("wallhack enable", function() return Config.Wallhack.Enabled end, function(v) Config.Wallhack.Enabled = v end)
        dropdown("mode", {"chams-only","walls-transparent","full-clear"},
            function() return Config.Wallhack.Mode end,
            function(v) Config.Wallhack.Mode = v end)
        slider("chams fill %", 0, 100,
            function() return math.floor(Config.Wallhack.ChamsFill*100) end,
            function(v) Config.Wallhack.ChamsFill = v/100 end)
        slider("wall transparency %", 0, 100,
            function() return math.floor((1 - Config.Wallhack.Transparent)*100) end,
            function(v) Config.Wallhack.Transparent = 1 - v/100 end)
        toggle("clear terrain", function() return Config.Wallhack.ClearTerrain end, function(v) Config.Wallhack.ClearTerrain = v end)

        section("NOCLIP")
        toggle("noclip enable", function() return Config.Noclip.Enabled end, function(v) Config.Noclip.Enabled = v end)

        section("FLY")
        toggle("fly enable", function() return Config.Fly.Enabled end, function(v) Config.Fly.Enabled = v end)
        dropdown("fly mode", {"normal","hover","cruise"},
            function() return Config.Fly.Mode end,
            function(v) Config.Fly.Mode = v end)
        slider("fly speed", 20, 300,
            function() return Config.Fly.Speed end,
            function(v) Config.Fly.Speed = v end)

        section("MOVE")
        toggle("long jump", function() return Config.Move.LongJump end, function(v) Config.Move.LongJump=v end)
        slider("long jump power", 50, 250,
            function() return Config.Move.LongJumpPower end,
            function(v) Config.Move.LongJumpPower=v end)
        toggle("anti fall", function() return Config.Move.AntiFall end, function(v) Config.Move.AntiFall=v end)
        toggle("auto climb", function() return Config.Move.AutoClimb end, function(v) Config.Move.AutoClimb=v end)
    end

    local tTeam = makeTab("team")
    tTeam.build = function()
        section("WHITELIST")
        inputBox("add nick", function() return "" end, function(v)
            if v and v ~= "" then table.insert(Config.Team.Whitelist, v) end
        end, "ник + Enter")
        button("show whitelist", function()
            local s = #Config.Team.Whitelist == 0 and "(пусто)" or table.concat(Config.Team.Whitelist, ", ")
            print("[zeusx] whitelist:", s)
        end)
        button("clear whitelist", function() Config.Team.Whitelist = {} end)
    end

    local tMisc = makeTab("misc")
    tMisc.build = function()
        section("UI")
        toggle("watermark", function() return Config.Misc.Watermark end, function(v) Config.Misc.Watermark=v end)
        inputBox("watermark text", function() return Config.Misc.WatermarkText end, function(v) Config.Misc.WatermarkText=v end)
        toggle("compact mode", function() return Config.Misc.CompactMode end, function(v) Config.Misc.CompactMode=v end)

        section("CONFIG")
        inputBox("slot name", function() return Config.Misc.AutoSaveSlot end, function(v) Config.Misc.AutoSaveSlot=v end)
        button("save config", function()
            local ok = getgenv().zeusx_saveConfig(Config.Misc.AutoSaveSlot)
            if getgenv().zeusx_pushNotify then
                getgenv().zeusx_pushNotify(ok and "saved" or "failed", Color3.fromRGB(60,120,60))
            end
        end)
        button("load config", function()
            local ok = getgenv().zeusx_loadConfig(Config.Misc.AutoSaveSlot)
            if getgenv().zeusx_pushNotify then
                getgenv().zeusx_pushNotify(ok and "loaded" or "failed", Color3.fromRGB(60,120,60))
            end
        end)

        section("HUD")
        toggle("hitsound", function() return Config.Misc.Hitsound end, function(v) Config.Misc.Hitsound=v end)
        toggle("kill notify", function() return Config.Misc.KillNotify end, function(v) Config.Misc.KillNotify=v end)
        toggle("killstreak", function() return Config.Misc.Killstreak end, function(v) Config.Misc.Killstreak=v end)
        toggle("fps monitor", function() return Config.Misc.FpsMonitor end, function(v) Config.Misc.FpsMonitor=v end)
        toggle("ping monitor", function() return Config.Misc.PingMonitor end, function(v) Config.Misc.PingMonitor=v end)
        toggle("custom crosshair", function() return Config.Misc.CustomCrosshair end, function(v) Config.Misc.CustomCrosshair=v end)

        section("KEY")
        button("HWID RESET", function()
            local key = getgenv().zeusx_get_key()
            if not key then
                if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("нет ключа", Color3.fromRGB(140,40,60)) end
                return
            end
            local hwid = getgenv().zeusx_getHWID()
            local url = "https://zeus-key-mjep.onrender.com/hwid_reset?token=" .. key .. "&hwid=" .. hwid
            local ok, resp = pcall(function() return game:HttpGet(url, true) end)
            if not ok or not resp then
                if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("сервер не отвечает", Color3.fromRGB(140,40,60)) end
                return
            end
            local okD, data = pcall(function() return game:GetService("HttpService"):JSONDecode(resp) end)
            if not okD or type(data) ~= "table" then return end
            if data.ok and data.reset then
                if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("HWID сброшен · перезапусти", Color3.fromRGB(60,120,60)) end
            elseif data.ok and not data.reset then
                if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("сброс через " .. tostring(data.days_left or "?") .. " дн", Color3.fromRGB(120,90,60)) end
            else
                if getgenv().zeusx_pushNotify then getgenv().zeusx_pushNotify("ошибка: " .. tostring(data.reason or "?"), Color3.fromRGB(140,40,60)) end
            end
        end)

        button("показать статус ключа", function()
            local left = Config.Key.Expiry - os.time()
            if left > 1e9 then print("[zeusx] вечный")
            elseif left <= 0 then print("[zeusx] истёк")
            else print("[zeusx] осталось " .. tostring(left) .. " сек") end
        end)
        button("сменить ключ", function()
            if getgenv().zeusx_set_key then getgenv().zeusx_set_key(nil) end
            if sg then sg:Destroy() end
            if getgenv().zeusx_show_keygate then
                getgenv().zeusx_show_keygate(getgenv().zeusx_on_success, "")
            end
        end)

        section("PANIC")
        button("выключить всё", function()
            if getgenv().zeusx_disableAll then getgenv().zeusx_disableAll() end
        end)
    end

    if setActiveTab then setActiveTab("aim") end
end

getgenv().zeusx_log("part", "13/14 OK")-- ============================================================
-- Zeus-X Lite v3.4 · ЧАСТЬ 14/14 — KEYGATE UI + WATERMARK + LOOP + BOOTSTRAP
-- ============================================================

local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Config       = getgenv().zeusx_cfg

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
    box.BorderSizePixel = 0; box.Text = ""; box.PlaceholderText = "ключ..."
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
    tgBtn.BorderSizePixel = 0; tgBtn.Text = "получить ключ · @noir_xis"
    tgBtn.TextColor3 = Color3.fromRGB(255,255,255)
    tgBtn.Font = Enum.Font.GothamBold; tgBtn.TextSize = 14
    tgBtn.AutoButtonColor = false; tgBtn.Parent = frame
    Instance.new("UICorner", tgBtn).CornerRadius = UDim.new(0, 10)
    tgBtn.MouseButton1Click:Connect(function()
        if setclipboard then pcall(function() setclipboard(TG_LINK) end) end
        tgBtn.Text = "скопировано · " .. TG_LINK
        task.wait(2.5); tgBtn.Text = "получить ключ · @noir_xis"
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
            status.Text = left or "ошибка"; box.Text = ""
            return
        end
        getgenv().zeusx_set_key(entered)
        getgenv().zeusx_cfg.Key.Expiry = os.time() + (tonumber(left) or 0)
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

-- WATERMARK
local wm
getgenv().zeusx_updateWatermark = function()
    if Config.Misc.Watermark then
        if not wm then
            local parent = (gethui and gethui()) or CoreGui
            wm = Instance.new("TextLabel")
            wm.Size = UDim2.new(0, 300, 0, 26)
            wm.Position = UDim2.new(0, 12, 0, 12)
            wm.BackgroundColor3 = Color3.fromRGB(20,14,30)
            wm.BackgroundTransparency = 0.4
            wm.BorderSizePixel = 0
            wm.TextColor3 = Color3.fromRGB(180,140,255)
            wm.Font = Enum.Font.GothamBold; wm.TextSize = 13
            wm.TextXAlignment = Enum.TextXAlignment.Left
            wm.Parent = parent
            Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 8)
        end
        wm.Text = "  " .. (Config.Misc.WatermarkText or "Zeus-X Lite v3.4")
        wm.Visible = true
    elseif wm then
        wm.Visible = false
    end
end

-- PANIC
getgenv().zeusx_disableAll = function()
    local cfg = getgenv().zeusx_cfg
    cfg.Aim.Enabled=false; cfg.Silent.Enabled=false; cfg.ESP.Enabled=false
    cfg.Trigger.Enabled=false; cfg.Wallhack.Enabled=false
    cfg.Noclip.Enabled=false; cfg.Fly.Enabled=false
    if getgenv().zeusx_renderESP then pcall(getgenv().zeusx_renderESP) end
    if getgenv().zeusx_updateWallhack then pcall(getgenv().zeusx_updateWallhack) end
    if getgenv().zeusx_updateNoclip then pcall(getgenv().zeusx_updateNoclip) end
    if getgenv().zeusx_updateFly then pcall(getgenv().zeusx_updateFly) end
    getgenv().zeusx_log("panic", "all disabled")
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Config.Misc.PanicKey then
        getgenv().zeusx_disableAll()
    end
end)

-- LOOP
if not getgenv()._zeusx_loop_started then
    getgenv()._zeusx_loop_started = true
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
    local wallAccum = 0
    RunService.RenderStepped:Connect(function(dt)
        safeCall(getgenv().zeusx_updateAim)
        safeCall(getgenv().zeusx_updateSilent)
        safeCall(getgenv().zeusx_updateTrigger)
        safeCall(getgenv().zeusx_updatePrefire)
        safeCall(getgenv().zeusx_updateFovCircle)
        safeCall(getgenv().zeusx_renderESP)
        safeCall(getgenv().zeusx_renderSkeleton)
        safeCall(getgenv().zeusx_renderChams)
        safeCall(getgenv().zeusx_renderArrows)
        safeCall(getgenv().zeusx_renderRings)
        safeCall(getgenv().zeusx_updateNoclip)
        safeCall(getgenv().zeusx_updateFly)
        safeCall(getgenv().zeusx_updateMove)
        safeCall(getgenv().zeusx_updateWatermark)
        safeCall(getgenv().zeusx_renderFps)
        safeCall(getgenv().zeusx_renderStreak)
        safeCall(getgenv().zeusx_renderCrosshair)
        wallAccum += dt
        if wallAccum >= 0.1 then
            wallAccum = 0
            safeCall(getgenv().zeusx_updateWallhack)
        end
    end)
    getgenv().zeusx_log("loop", "started")
end

-- BOOTSTRAP
getgenv().zeusx_on_success = function()
    getgenv().zeusx_log("bootstrap", "start")
    if getgenv().zeusx_initESP then
        local ok, err = pcall(getgenv().zeusx_initESP)
        if not ok then getgenv().zeusx_log("ERR", "init_esp", err) end
    end
    if getgenv().zeusx_create_menu then
        local ok, err = pcall(getgenv().zeusx_create_menu)
        if not ok then getgenv().zeusx_log("ERR", "create_menu", err) end
    end
    task.wait(0.05)
    if getgenv().zeusx_build_tabs_aim_trigger then
        local ok, err = pcall(getgenv().zeusx_build_tabs_aim_trigger)
        if not ok then getgenv().zeusx_log("ERR", "build_tabs_aim_trigger", err) end
    end
    if getgenv().zeusx_build_tabs_esp_wall then
        local ok, err = pcall(getgenv().zeusx_build_tabs_esp_wall)
        if not ok then getgenv().zeusx_log("ERR", "build_tabs_esp_wall", err) end
    end
    if getgenv().zeusx_menu_ctx and getgenv().zeusx_menu_ctx.setActiveTab then
        pcall(getgenv().zeusx_menu_ctx.setActiveTab, "aim")
    end
    -- авто-загрузка конфига
    pcall(function()
        if getgenv().zeusx_loadConfig then getgenv().zeusx_loadConfig("default") end
    end)
    getgenv().zeusx_log("bootstrap", "done")
end

task.spawn(function()
    getgenv().zeusx_log("bootstrap", "showing keygate")
    if getgenv().zeusx_show_keygate then
        local ok, err = pcall(getgenv().zeusx_show_keygate, getgenv().zeusx_on_success)
        if not ok then getgenv().zeusx_log("ERR", "show_keygate", err) end
    end
end)

getgenv().zeusx_log("v3.4", "loaded · 14 parts OK")