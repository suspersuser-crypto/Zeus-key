-- ============================================================
-- vanta v8.0 · ЧАСТЬ 1/8 — services + config + anti-ban
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local Lighting     = game:GetService("Lighting")
local ReplicatedSt = game:GetService("ReplicatedStorage")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

local Config = {
    Aim = {
        Enabled=false, FOV=120, Smooth=0.35,
        Key=Enum.UserInputType.MouseButton2,
        Visible=true, WallCheck=true, TeamCheck=true,
        Part="Head",
    },
    Trigger = {
        Enabled=false, Key=Enum.UserInputType.MouseButton1,
        Delay=0.06, WallCheck=true, TeamCheck=true,
    },
    ESP = {
        Enabled=false,
        Box=true, Name=true, Health=true, Distance=true,
        TeamCheck=false, MaxDist=2000, MinParts=5,
    },
    Move = {
        Speed=false, SpeedVal=28,
        Fly=false, FlySpeed=50,
        InfJump=false, Noclip=false,
        AutoRespawn=false,
    },
    Vis = { Fullbright=false, NoFog=false, FOV=70 },
    Misc = {
        Hitsound=false, KillNotify=true, AntiFling=true, Watermark=true,
    },
    Anti = {
        StealthSpeedCap=44, StealthFlyCap=72,
    },
    Team = {
        MyTeamId = nil,
    },
}
getgenv().vanta_cfg = Config

local Anti = {}
local origWalkSpeed, origJumpPower = 16, 50

function Anti.clampSpeed(v)
    if v > Config.Anti.StealthSpeedCap then return Config.Anti.StealthSpeedCap end
    return v
end
function Anti.clampFly(v)
    return math.min(v, Config.Anti.StealthFlyCap)
end

getgenv().vanta_anti = Anti
getgenv().vanta_orig = { WalkSpeed=origWalkSpeed, JumpPower=origJumpPower }
getgenv().vanta_Tween = TweenService

print("[vanta] part 1 OK")-- ============================================================
-- vanta v8.0 · ЧАСТЬ 2/8 — discovery + team resolver
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Config      = getgenv().vanta_cfg

local IGNORE_NAMES = { TheMlgShep = true, R15_Dummy = true, Dummy = true }

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
    if IGNORE_NAMES[model.Name] then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return true end
    if hum.MaxHealth == math.huge or hum.MaxHealth <= 0 or hum.MaxHealth > 100000 then return true end
    if #model:GetChildren() < (Config.ESP.MinParts or 5) then return true end
    return false
end

local teamResolveCache = {}

local function getPlayerOf(model)
    local plr = Players:FindFirstChild(model.Name)
    if plr then return plr end
    local uid = model:GetAttribute("UserId") or model:GetAttribute("OwnerId")
    if uid then
        for _, p in ipairs(Players:GetPlayers()) do
            if tostring(p.UserId) == tostring(uid) then return p end
        end
    end
    return nil
end

local function resolveTeamId(obj)
    if not obj then return nil end
    if obj:IsA("Player") and obj.Team then return obj.Team end
    if obj:IsA("Player") and obj.TeamColor then return obj.TeamColor end
    if obj:IsA("Player") then
        local t = obj:GetAttribute("Team") or obj:GetAttribute("TeamId")
              or obj:GetAttribute("TeamName") or obj:GetAttribute("team")
        if t then return t end
    end
    if obj:IsA("Model") then
        local t = obj:GetAttribute("Team") or obj:GetAttribute("TeamId")
              or obj:GetAttribute("TeamName") or obj:GetAttribute("team")
        if t then return t end
    end
    return nil
end

local function getMyTeamId()
    if Config.Team.MyTeamId ~= nil then return Config.Team.MyTeamId end
    return resolveTeamId(LocalPlayer)
end

local function getTargetTeamId(model)
    if teamResolveCache[model] ~= nil then return teamResolveCache[model] end
    local plr = getPlayerOf(model)
    if plr then
        local t = resolveTeamId(plr)
        if t ~= nil then teamResolveCache[model] = t; return t end
    end
    local t = resolveTeamId(model)
    teamResolveCache[model] = t
    return t
end

task.spawn(function()
    while task.wait(5) do teamResolveCache = {} end
end)

local function sameTeam(model)
    if model.Name == LocalPlayer.Name then return true end
    local myT = getMyTeamId()
    local theirT = getTargetTeamId(model)
    if myT == nil then return false end
    if theirT == nil then return false end
    return myT == theirT
end

function _G.vanta_team_debug()
    print("=== TEAM DEBUG ===")
    print("My Team (Player.Team):", LocalPlayer.Team)
    print("My Team (TeamColor):", LocalPlayer.TeamColor)
    print("My Team (resolved):", getMyTeamId())
    print("My Attributes:")
    for k, v in pairs(LocalPlayer:GetAttributes()) do print("  ", k, "=", v) end
    print("Players:")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            print("  ", p.Name, "| Team:", p.Team, "| TeamColor:", p.TeamColor, "| resolved:", resolveTeamId(p))
        end
    end
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

local function countWorkspace()
    local n = 0
    for _, m in ipairs(Workspace:GetChildren()) do
        if not isGarbage(m) then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then n = n + 1 end
        end
    end
    return n
end

local scanMode = "players"
task.spawn(function()
    while task.wait(2) do
        local nP = countPlayers()
        local nW = countWorkspace()
        if nP >= nW and nP > 0 then scanMode = "players"
        elseif nW > nP then scanMode = "workspace" end
    end
end)

local function getPlayerTargets()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not isGarbage(plr.Character) then
            table.insert(list, plr.Character)
        end
    end
    return list
end

local function getWorkspaceTargets()
    local list = {}
    for _, m in ipairs(Workspace:GetChildren()) do
        if not isGarbage(m) then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then table.insert(list, m) end
        end
    end
    return list
end

local function getTargets()
    if scanMode == "workspace" then return getWorkspaceTargets()
    else return getPlayerTargets() end
end

local function getHumanoid(m) return m and m:FindFirstChildOfClass("Humanoid") end
local function getHead(m)     return m and m:FindFirstChild("Head", true) end
local function getRoot(m)     return m and m:FindFirstChild("HumanoidRootPart", true) end

local function isAlive(m)
    local h = getHumanoid(m)
    if h then return h.Health > 0 end
    return getHead(m) ~= nil
end

local function partPos(model, partName)
    if partName == "Head" then
        local h = getHead(model); return h and h.Position
    elseif partName == "HumanoidRootPart" then
        local r = getRoot(model); return r and r.Position
    else
        local p = model:FindFirstChild(partName, true)
        return p and p.Position
    end
end

local function w2s(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y), sp.Z
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(model, partName)
    local target = partPos(model, partName)
    if not target then return false end
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    local hit = Workspace:Raycast(Camera.CFrame.Position, target - Camera.CFrame.Position, rayParams)
    if not hit then return true end
    return hit.Instance and hit.Instance:IsDescendantOf(model)
end

getgenv().vanta_helpers = {
    getTargets=getTargets, getHumanoid=getHumanoid, getHead=getHead, getRoot=getRoot,
    isAlive=isAlive, sameTeam=sameTeam,
    partPos=partPos, w2s=w2s, isVisible=isVisible,
    getMode=function() return scanMode end,
    getMyTeamId=getMyTeamId,
    resolveTeamId=resolveTeamId,
    teamDebug=_G.vanta_team_debug,
}

print("[vanta] part 2 OK")-- ============================================================
-- vanta v8.0 · ЧАСТЬ 3/8 — ESP
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local CoreGui     = game:GetService("CoreGui")
local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Config      = getgenv().vanta_cfg
local H           = getgenv().vanta_helpers

local getTargets  = H.getTargets
local getHumanoid = H.getHumanoid
local getHead     = H.getHead
local getRoot     = H.getRoot
local isAlive     = H.isAlive
local sameTeam    = H.sameTeam
local w2s         = H.w2s

local fromRGB = Color3.fromRGB
local floor = math.floor

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
    ESP = {}
end

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
    if not ESP or ESP[model] then return end
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = espGui
    local stroke = Instance.new("UIStroke")
    stroke.Color = fromRGB(170, 120, 255)
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
    if not ESP then return end
    local t = ESP[model]
    if not t then return end
    for _, o in pairs(t) do if o and o.Destroy then pcall(o.Destroy, o) end end
    ESP[model] = nil
end

local function renderESP()
    if not espGui then return end
    if not Config.ESP.Enabled then
        if ESP then
            for _, t in pairs(ESP) do
                if t then
                    t.box.Visible = false
                    t.name.Visible = false
                    t.hp.Visible = false
                    t.dist.Visible = false
                end
            end
        end
        return
    end

    local myPos = Camera.CFrame.Position
    local seen = {}
    for _, model in ipairs(getTargets()) do
        seen[model] = true
        local t = ESP[model]
        if not t then createESP(model); t = ESP[model] end
        if t then
            local show = isAlive(model) and not (Config.ESP.TeamCheck and sameTeam(model))
            local root = getRoot(model)
            if show and root then
                if (myPos - root.Position).Magnitude > Config.ESP.MaxDist then show = false end
            end

            if not show then
                t.box.Visible = false
                t.name.Visible = false
                t.hp.Visible = false
                t.dist.Visible = false
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
                        t.hp.Text = floor(hp) .. " hp"
                        t.hp.Size = UDim2.new(0, 200, 0, 16)
                        t.hp.Position = UDim2.new(0, cx - 100, 0, cy + h + 2)
                        t.hp.TextColor3 = hp > 50 and fromRGB(180,255,180) or fromRGB(255,140,180)

                        t.dist.Visible = Config.ESP.Distance
                        t.dist.Text = floor((myPos - root.Position).Magnitude) .. " m"
                        t.dist.Size = UDim2.new(0, 200, 0, 16)
                        t.dist.Position = UDim2.new(0, cx - 100, 0, cy + h + 18)
                    else
                        t.box.Visible = false
                        t.name.Visible = false
                        t.hp.Visible = false
                        t.dist.Visible = false
                    end
                end
            end
        end
    end

    for model, _ in pairs(ESP) do
        if not seen[model] or not model.Parent then destroyESP(model) end
    end
end

getgenv().vanta_init_esp = initESP
getgenv().vanta_render_esp = renderESP

print("[vanta] part 3 OK")-- ============================================================
-- vanta v8.0 · ЧАСТЬ 4/8 — aim + trigger
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local UIS         = game:GetService("UserInputService")
local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Config      = getgenv().vanta_cfg
local H           = getgenv().vanta_helpers

local getTargets  = H.getTargets
local isAlive     = H.isAlive
local sameTeam    = H.sameTeam
local partPos     = H.partPos
local w2s         = H.w2s
local isVisible   = H.isVisible

local tick = tick
local V2 = Vector2.new

local aimHeld = false
local trigHeld = false
local lastShot = 0

local function getAimTarget(fov)
    local center = V2(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local camPos = Camera.CFrame.Position
    local best, bestScore = nil, math.huge
    for _, model in ipairs(getTargets()) do
        if isAlive(model) and not (Config.Aim.TeamCheck and sameTeam(model)) then
            local target = partPos(model, Config.Aim.Part)
            if target then
                local screen = w2s(target)
                if screen then
                    local pxD = (screen - center).Magnitude
                    if pxD <= fov then
                        if not Config.Aim.Visible or isVisible(model, Config.Aim.Part) then
                            local worldD = (camPos - target).Magnitude
                            local score = pxD + worldD * 0.1
                            if score < bestScore then best, bestScore = model, score end
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
    local center = V2(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    local delta = screen - center
    local s = math.clamp(Config.Aim.Smooth, 0.05, 1)
    local mx = delta.X * s
    local my = delta.Y * s
    if math.abs(mx) < 1 and math.abs(my) < 1 then return end
    if mousemoverel then mousemoverel(mx, my) end
end

local function safeClick()
    if mouse1click then pcall(mouse1click) end
end

local function updateTrigger()
    if not Config.Trigger.Enabled or not trigHeld then return end
    if tick() - lastShot < Config.Trigger.Delay then return end
    if not isAlive(LocalPlayer.Character) then return end
    local center = V2(Camera.ViewportSize.X*0.5, Camera.ViewportSize.Y*0.5)
    for _, model in ipairs(getTargets()) do
        if isAlive(model) and not (Config.Trigger.TeamCheck and sameTeam(model)) then
            local head = partPos(model, "Head")
            if head then
                local screen = w2s(head)
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

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Config.Aim.Key then aimHeld = true end
    if input.UserInputType == Config.Trigger.Key then trigHeld = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Config.Aim.Key then aimHeld = false end
    if input.UserInputType == Config.Trigger.Key then trigHeld = false end
end)

getgenv().vanta_update_aim = updateAim
getgenv().vanta_update_trigger = updateTrigger

print("[vanta] part 4 OK")-- ============================================================
-- vanta v8.0 · ЧАСТЬ 5/8 — move + misc
-- ============================================================

local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local UIS         = game:GetService("UserInputService")
local CoreGui     = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Config      = getgenv().vanta_cfg
local Anti        = getgenv().vanta_anti

local origWalkSpeed = getgenv().vanta_orig.WalkSpeed
local floor = math.floor

local function updateMove()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if Config.Move.Speed then
        hum.WalkSpeed = Anti.clampSpeed(Config.Move.SpeedVal)
    elseif hum.WalkSpeed ~= origWalkSpeed then
        hum.WalkSpeed = origWalkSpeed
    end

    if Config.Move.Fly then
        hum.PlatformStand = true
        local dir = Vector3.zero
        local camCF = Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        local spd = Anti.clampFly(Config.Move.FlySpeed)
        if dir.Magnitude > 0 then hrp.Velocity = dir.Unit * spd
        else hrp.Velocity = Vector3.zero end
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

local guiParent = (gethui and gethui()) or CoreGui

local function antiFling()
    if not Config.Misc.AntiFling then return end
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.01, 1, 1)
    end
end

local wm
local function updateWatermark()
    if Config.Misc.Watermark then
        if not wm then
            wm = Instance.new("TextLabel")
            wm.Size = UDim2.new(0, 320, 0, 28)
            wm.Position = UDim2.new(0, 12, 0, 12)
            wm.BackgroundColor3 = Color3.fromRGB(20, 14, 30)
            wm.BackgroundTransparency = 0.4
            wm.BorderSizePixel = 0
            wm.Text = "  vanta · v8.0"
            wm.TextColor3 = Color3.fromRGB(180, 140, 255)
            wm.Font = Enum.Font.GothamBold
            wm.TextSize = 13
            wm.TextXAlignment = Enum.TextXAlignment.Left
            wm.Parent = guiParent
            Instance.new("UICorner", wm).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke")
            s.Color = Color3.fromRGB(170, 120, 255)
            s.Thickness = 1
            s.Transparency = 0.5
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

print("[vanta] part 5 OK")-- ============================================================
-- vanta v8.0 · ЧАСТЬ 6/8 — main loop
-- ============================================================

local RunService = game:GetService("RunService")

local renderESP   = getgenv().vanta_render_esp
local updateAim   = getgenv().vanta_update_aim
local updateTrig  = getgenv().vanta_update_trigger
local updateMove  = getgenv().vanta_update_move
local updateNoclip = getgenv().vanta_update_noclip
local updateAutoRespawn = getgenv().vanta_update_autorespawn
local antiFling   = getgenv().vanta_update_antifling
local updateWatermark = getgenv().vanta_update_watermark

local function startLoop()
    if getgenv().vanta_loop_started then return end
    getgenv().vanta_loop_started = true

    local renderAccum = 0
    RunService.RenderStepped:Connect(function(dt)
        updateAim()
        updateTrig()
        updateMove()
        updateNoclip()
        updateAutoRespawn()
        antiFling()
        updateWatermark()

        renderAccum += dt
        if renderAccum < 1/60 then return end
        renderAccum = 0

        renderESP()
    end)

    print("[vanta] loop запущен")
end

getgenv().vanta_start_loop = startLoop
print("[vanta] part 6 OK")-- ============================================================
-- vanta v8.0 · ЧАСТЬ 7/8 — menu (glass + tween)
-- ============================================================

getgenv().vanta_create_menu = function()

local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local parent = (gethui and gethui()) or CoreGui
local Config = getgenv().vanta_cfg
if not Config then return end

if getgenv().vanta_menu and getgenv().vanta_menu.Parent then
    getgenv().vanta_menu:Destroy()
end

local A = {
    bg       = Color3.fromRGB(18, 12, 28),
    panel    = Color3.fromRGB(38, 28, 58),
    panelHi  = Color3.fromRGB(52, 38, 80),
    accent   = Color3.fromRGB(180, 130, 255),
    accent2  = Color3.fromRGB(220, 150, 255),
    accentDim= Color3.fromRGB(110, 70, 190),
    text     = Color3.fromRGB(235, 225, 250),
    textDim  = Color3.fromRGB(170, 155, 200),
}

local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function tweenQuad(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local sg = Instance.new("ScreenGui")
sg.Name = "vanta_menu_root"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999
sg.Parent = parent
getgenv().vanta_menu = sg

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 500, 0, 520)
win.Position = UDim2.new(0, 80, 0, 150)
win.BackgroundColor3 = A.bg
win.BackgroundTransparency = 0.3
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
win.ClipsDescendants = true
win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 18)

local winStroke = Instance.new("UIStroke")
winStroke.Color = A.accent
winStroke.Thickness = 1.4
winStroke.Transparency = 0.25
winStroke.Parent = win
local winGrad = Instance.new("UIGradient")
winGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 90, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 150, 255)),
}
winGrad.Rotation = 35
winGrad.Parent = winStroke

tween(win, 0.55, {
    Position = UDim2.new(0, 80, 0, 100),
    BackgroundTransparency = 0.1,
})

local shine = Instance.new("Frame")
shine.Size = UDim2.new(1, -20, 0, 1)
shine.Position = UDim2.new(0, 10, 0, 44)
shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shine.BackgroundTransparency = 0.85
shine.BorderSizePixel = 0
shine.Parent = win

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 44)
bar.BackgroundTransparency = 1
bar.Parent = win

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "vanta · v8.0"
title.TextColor3 = A.accent
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local function iconBtn(pos, text, hoverColor, click)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = pos
    btn.BackgroundColor3 = A.panel
    btn.BackgroundTransparency = 0.35
    btn.Text = text
    btn.TextColor3 = A.textDim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = bar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke")
    s.Color = A.accent
    s.Thickness = 1
    s.Transparency = 0.7
    s.Parent = btn
    btn.MouseEnter:Connect(function()
        tweenQuad(btn, 0.15, {
            BackgroundColor3 = hoverColor,
            BackgroundTransparency = 0.15,
            TextColor3 = Color3.fromRGB(255,255,255),
        })
    end)
    btn.MouseLeave:Connect(function()
        tweenQuad(btn, 0.15, {
            BackgroundColor3 = A.panel,
            BackgroundTransparency = 0.35,
            TextColor3 = A.textDim,
        })
    end)
    btn.MouseButton1Click:Connect(click)
    return btn
end

local minBtn = iconBtn(UDim2.new(1, -66, 0, 8), "—", A.accentDim, function() end)
local closeBtn = iconBtn(UDim2.new(1, -34, 0, 8), "×",
    Color3.fromRGB(160, 50, 80),
    function()
        tweenQuad(win, 0.2, { BackgroundTransparency = 1 })
        task.wait(0.2)
        sg:Destroy()
        getgenv().vanta_menu = nil
    end)

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
scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
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
    tweenQuad(win, 0.25, {
        Size = minimized and UDim2.new(0, 500, 0, 50) or UDim2.new(0, 500, 0, 520)
    })
    minBtn.Text = minimized and "+" or "—"
end)

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

local function makeRow()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 32)
    row.BackgroundColor3 = A.panel
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke")
    s.Color = A.accent
    s.Thickness = 1
    s.Transparency = 0.8
    s.Parent = row
    return row
end

local function toggle(label, get, set)
    local row = makeRow()
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = A.text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local st = get()
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 22)
    btn.Position = UDim2.new(1, -58, 0, 5)
    btn.BackgroundColor3 = st and A.accentDim or Color3.fromRGB(55, 42, 80)
    btn.BackgroundTransparency = 0.15
    btn.Text = st and "on" or "off"
    btn.TextColor3 = A.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        local nv = not get()
        set(nv)
        tweenQuad(btn, 0.18, {
            BackgroundColor3 = nv and A.accentDim or Color3.fromRGB(55, 42, 80),
            TextColor3 = nv and Color3.fromRGB(255,255,255) or A.text,
        })
        btn.Text = nv and "on" or "off"
    end)
end

local function slider(label, minV, maxV, get, set, fmt)
    fmt = fmt or "%d"
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 46)
    row.BackgroundColor3 = A.panel
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke")
    s.Color = A.accent
    s.Thickness = 1
    s.Transparency = 0.8
    s.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -120, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = A.text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 100, 0, 20)
    val.Position = UDim2.new(1, -112, 0, 4)
    val.BackgroundTransparency = 1
    val.Text = string.format(fmt, get())
    val.TextColor3 = A.accent2
    val.Font = Enum.Font.GothamBold
    val.TextSize = 13
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(55, 42, 80)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((get() - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = A.accentDim
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
    local row = makeRow()
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -140, 1, 0)
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
    btn.Size = UDim2.new(0, 120, 0, 22)
    btn.Position = UDim2.new(1, -130, 0, 5)
    btn.BackgroundColor3 = A.panelHi
    btn.BackgroundTransparency = 0.3
    btn.Text = options[idx]
    btn.TextColor3 = A.accent2
    btn.Font = Enum.Font.Gotham
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

local function button(label, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = A.accentDim
    btn.BackgroundTransparency = 0.3
    btn.Text = label
    btn.TextColor3 = A.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke")
    s.Color = A.accent
    s.Thickness = 1
    s.Transparency = 0.6
    s.Parent = btn
    btn.MouseEnter:Connect(function()
        tweenQuad(btn, 0.15, { BackgroundTransparency = 0.1, BackgroundColor3 = A.accent })
    end)
    btn.MouseLeave:Connect(function()
        tweenQuad(btn, 0.15, { BackgroundTransparency = 0.3, BackgroundColor3 = A.accentDim })
    end)
    btn.MouseButton1Click:Connect(cb)
end

local tabButtons = {}
local function setActiveTab(name)
    for n, data in pairs(tabButtons) do
        local active = (n == name)
        tweenQuad(data.btn, 0.18, {
            BackgroundColor3 = active and A.accentDim or A.panel,
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
    section("AIM")
    toggle("aimbot", function() return Config.Aim.Enabled end, function(v) Config.Aim.Enabled = v end)
    toggle("team check (не бить своих)", function() return Config.Aim.TeamCheck end, function(v) Config.Aim.TeamCheck = v end)
    slider("fov", 10, 400, function() return Config.Aim.FOV end, function(v) Config.Aim.FOV = v end)
    slider("smooth %", 5, 100, function() return math.floor(Config.Aim.Smooth*100) end, function(v) Config.Aim.Smooth = v/100 end)
    toggle("wall check", function() return Config.Aim.WallCheck end, function(v) Config.Aim.WallCheck = v end)
    dropdown("hit part", {"Head","HumanoidRootPart","UpperTorso"}, function() return Config.Aim.Part end, function(v) Config.Aim.Part = v end)
    section("TEAM DEBUG")
    button("показать команды в консоли", function()
        local H = getgenv().vanta_helpers
        if H and H.teamDebug then H.teamDebug() end
    end)
end

local tTrig = makeTab("trigger")
tTrig.build = function()
    section("TRIGGER")
    toggle("triggerbot", function() return Config.Trigger.Enabled end, function(v) Config.Trigger.Enabled = v end)
    toggle("team check (не бить своих)", function() return Config.Trigger.TeamCheck end, function(v) Config.Trigger.TeamCheck = v end)
    slider("delay ms", 20, 250, function() return math.floor(Config.Trigger.Delay*1000) end, function(v) Config.Trigger.Delay = v/1000 end)
    toggle("wall check", function() return Config.Trigger.WallCheck end, function(v) Config.Trigger.WallCheck = v end)
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
    slider("min parts", 3, 30, function() return Config.ESP.MinParts end, function(v) Config.ESP.MinParts = v end)
end

local tMove = makeTab("move")
tMove.build = function()
    section("MOVE")
    toggle("speed", function() return Config.Move.Speed end, function(v) Config.Move.Speed = v end)
    slider("speed value", 16, 250, function() return Config.Move.SpeedVal end, function(v) Config.Move.SpeedVal = v end)
    toggle("fly", function() return Config.Move.Fly end, function(v) Config.Move.Fly = v end)
    slider("fly speed", 10, 300, function() return Config.Move.FlySpeed end, function(v) Config.Move.FlySpeed = v end)
    toggle("infinite jump", function() return Config.Move.InfJump end, function(v) Config.Move.InfJump = v end)
    toggle("noclip", function() return Config.Move.Noclip end, function(v) Config.Move.Noclip = v end)
    toggle("auto respawn", function() return Config.Move.AutoRespawn end, function(v) Config.Move.AutoRespawn = v end)
end

local tVis = makeTab("visual")
tVis.build = function()
    section("VISUAL")
    toggle("fullbright", function() return Config.Vis.Fullbright end,
        function(v)
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
    toggle("no fog", function() return Config.Vis.NoFog end,
        function(v) Config.Vis.NoFog = v; game:GetService("Lighting").FogEnd = v and 1e6 or 100000 end)
    slider("camera fov", 60, 120, function() return Config.Vis.FOV end,
        function(v) Config.Vis.FOV = v; game:GetService("Workspace").CurrentCamera.FieldOfView = v end)
end

local tMisc = makeTab("misc")
tMisc.build = function()
    section("MISC")
    toggle("kill notify", function() return Config.Misc.KillNotify end, function(v) Config.Misc.KillNotify = v end)
    toggle("anti-fling", function() return Config.Misc.AntiFling end, function(v) Config.Misc.AntiFling = v end)
    toggle("watermark", function() return Config.Misc.Watermark end, function(v) Config.Misc.Watermark = v end)
end

setActiveTab("aim")

print("[vanta] menu created")
end -- vanta_create_menu
print("[vanta] part 7 OK")-- ============================================================
-- vanta v8.0 · ЧАСТЬ 8/8 — SERVER keygate + TG button
-- ключи на сервере: https://zeus-key-mjep.onrender.com
-- ============================================================

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local SERVER_URL = "https://zeus-key-mjep.onrender.com/check"
local TG_LINK = "https://t.me/noir_xis"

local function getHWID()
    if gethwid then
        local ok, id = pcall(gethwid)
        if ok and id then return tostring(id) end
    end
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id then return tostring(id) end
    return "unknown_hwid_" .. tostring(os.time())
end

local function checkKeyOnServer(key)
    local hwid = getHWID()
    local url = SERVER_URL .. "?token=" .. key .. "&hwid=" .. hwid

    local ok, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not ok or not response then
        return false, "нет соединения с сервером"
    end

    local okDecode, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not okDecode or type(data) ~= "table" then
        return false, "неверный ответ сервера"
    end

    if data.ok then
        return true, data.left or 0
    end

    local reasons = {
        invalid = "неверный ключ",
        hwid_mismatch = "ключ привязан к другому устройству",
        expired = "срок действия ключа истёк",
    }
    return false, reasons[data.reason] or "ошибка проверки"
end

local function formatTime(sec)
    if not sec or sec < 0 then sec = 0 end
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    if d > 0 then return string.format("%dд %02dч %02dм", d, h, m) end
    return string.format("%02dч %02dм", h, m)
end

local function disableAll()
    local Config = getgenv().vanta_cfg
    if Config then
        Config.ESP.Enabled = false
        Config.Aim.Enabled = false
        Config.Trigger.Enabled = false
        Config.Move.Speed = false
        Config.Move.Fly = false
        Config.Move.Noclip = false
        Config.Move.InfJump = false
    end
    local parent = (gethui and gethui()) or CoreGui
    local esp = parent:FindFirstChild("vanta_esp")
    if esp then esp:Destroy() end
    local menu = parent:FindFirstChild("vanta_menu_root")
    if menu then menu:Destroy() end
end

getgenv().vanta_active_key = nil
getgenv().vanta_key_expiry_ts = nil

local function periodicRecheck()
    if not getgenv().vanta_active_key then return end
    local key = getgenv().vanta_active_key
    local ok, left = checkKeyOnServer(key)
    if not ok then
        getgenv().vanta_active_key = nil
        getgenv().vanta_key_expiry_ts = nil
        disableAll()
        if getgenv().vanta_show_keygate then
            getgenv().vanta_show_keygate(getgenv().vanta_on_success, "срок действия ключа истёк")
        end
    else
        getgenv().vanta_key_expiry_ts = os.time() + left
    end
end

task.spawn(function()
    while task.wait(60) do
        pcall(periodicRecheck)
    end
end)

local function tweenQuad(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local accent = Color3.fromRGB(180, 130, 255)

getgenv().vanta_show_keygate = function(onSuccess, message)

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
frame.Position = UDim2.new(0.5, -190, 0.65, -170)
frame.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 18)

tweenQuad(frame, 0.55, {
    Position = UDim2.new(0.5, -190, 0.5, -170),
    BackgroundTransparency = 0.1,
})

local stroke = Instance.new("UIStroke")
stroke.Color = accent
stroke.Thickness = 1.4
stroke.Transparency = 0.3
stroke.Parent = frame
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 90, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 150, 255)),
}
grad.Rotation = 35
grad.Parent = stroke

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 52)
title.BackgroundTransparency = 1
title.Text = "ZEUS-X"
title.TextColor3 = accent
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.Parent = frame

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, 0, 0, 18)
sub.Position = UDim2.new(0, 0, 0, 50)
sub.BackgroundTransparency = 1
sub.Text = "введите ключ доступа"
sub.TextColor3 = Color3.fromRGB(180, 160, 220)
sub.Font = Enum.Font.Gotham
sub.TextSize = 13
sub.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -40, 0, 44)
box.Position = UDim2.new(0, 20, 0, 84)
box.BackgroundColor3 = Color3.fromRGB(38, 28, 58)
box.BackgroundTransparency = 0.3
box.BorderSizePixel = 0
box.Text = ""
box.PlaceholderText = "ключ..."
box.TextColor3 = Color3.fromRGB(235, 225, 250)
box.PlaceholderColor3 = Color3.fromRGB(140, 120, 180)
box.Font = Enum.Font.Gotham
box.TextSize = 15
box.ClearTextOnFocus = false
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = accent
boxStroke.Thickness = 1
boxStroke.Transparency = 0.6
boxStroke.Parent = box

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -40, 0, 44)
btn.Position = UDim2.new(0, 20, 0, 142)
btn.BackgroundColor3 = Color3.fromRGB(120, 75, 200)
btn.BackgroundTransparency = 0.2
btn.BorderSizePixel = 0
btn.Text = "войти"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 15
btn.AutoButtonColor = false
btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
btn.MouseEnter:Connect(function()
    tweenQuad(btn, 0.15, { BackgroundColor3 = accent, BackgroundTransparency = 0 })
end)
btn.MouseLeave:Connect(function()
    tweenQuad(btn, 0.15, { BackgroundColor3 = Color3.fromRGB(120, 75, 200), BackgroundTransparency = 0.2 })
end)

-- TG кнопка
local tgBtn = Instance.new("TextButton")
tgBtn.Size = UDim2.new(1, -40, 0, 40)
tgBtn.Position = UDim2.new(0, 20, 0, 198)
tgBtn.BackgroundColor3 = Color3.fromRGB(30, 90, 140)
tgBtn.BackgroundTransparency = 0.15
tgBtn.BorderSizePixel = 0
tgBtn.Text = "получить ключ  ·  @noir_xis"
tgBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tgBtn.Font = Enum.Font.GothamBold
tgBtn.TextSize = 14
tgBtn.AutoButtonColor = false
tgBtn.Parent = frame
Instance.new("UICorner", tgBtn).CornerRadius = UDim.new(0, 10)

local tgStroke = Instance.new("UIStroke")
tgStroke.Color = Color3.fromRGB(120, 200, 255)
tgStroke.Thickness = 1.2
tgStroke.Transparency = 0.4
tgStroke.Parent = tgBtn
local tgGrad = Instance.new("UIGradient")
tgGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 160, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 200, 255)),
}
tgGrad.Rotation = 35
tgGrad.Parent = tgStroke

local tgIcon = Instance.new("Frame")
tgIcon.Size = UDim2.new(0, 22, 0, 22)
tgIcon.Position = UDim2.new(0, 8, 0.5, -11)
tgIcon.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
tgIcon.BorderSizePixel = 0
tgIcon.Parent = tgBtn
Instance.new("UICorner", tgIcon).CornerRadius = UDim.new(1, 0)

local tgArrow = Instance.new("TextLabel")
tgArrow.Size = UDim2.new(1, 0, 1, 0)
tgArrow.BackgroundTransparency = 1
tgArrow.Text = "✈"
tgArrow.TextColor3 = Color3.fromRGB(30, 90, 140)
tgArrow.Font = Enum.Font.GothamBold
tgArrow.TextSize = 14
tgArrow.Parent = tgIcon

tgBtn.MouseEnter:Connect(function()
    tweenQuad(tgBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(60, 160, 220), BackgroundTransparency = 0 })
    tweenQuad(tgStroke, 0.15, { Transparency = 0 })
end)
tgBtn.MouseLeave:Connect(function()
    tweenQuad(tgBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(30, 90, 140), BackgroundTransparency = 0.15 })
    tweenQuad(tgStroke, 0.15, { Transparency = 0.4 })
end)

tgBtn.MouseButton1Click:Connect(function()
    local copied = false
    if setclipboard then pcall(function() setclipboard(TG_LINK) end); copied = true
    elseif toclipboard then pcall(function() toclipboard(TG_LINK) end); copied = true end

    if copied then
        tgBtn.Text = "скопировано  ·  " .. TG_LINK
        tweenQuad(tgBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(60, 180, 120) })
        task.wait(2.5)
        tgBtn.Text = "получить ключ  ·  @noir_xis"
        tweenQuad(tgBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(30, 90, 140) })
    else
        tgBtn.Text = "TG: " .. TG_LINK
        task.wait(3)
        tgBtn.Text = "получить ключ  ·  @noir_xis"
    end
end)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 16)
status.Position = UDim2.new(0, 0, 0, 246)
status.BackgroundTransparency = 1
status.Text = message or ""
status.TextColor3 = Color3.fromRGB(255, 120, 140)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Parent = frame

local timerLbl = Instance.new("TextLabel")
timerLbl.Size = UDim2.new(1, 0, 0, 14)
timerLbl.Position = UDim2.new(0, 0, 0, 264)
timerLbl.BackgroundTransparency = 1
timerLbl.Text = ""
timerLbl.TextColor3 = Color3.fromRGB(200, 180, 240)
timerLbl.Font = Enum.Font.Gotham
timerLbl.TextSize = 11
timerLbl.Parent = frame

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, 0, 0, 14)
hint.Position = UDim2.new(0, 0, 0, 282)
hint.BackgroundTransparency = 1
hint.Text = "ключ проверяется на сервере"
hint.TextColor3 = Color3.fromRGB(140, 120, 180)
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.Parent = frame

local function try()
    local entered = (box.Text:gsub("%s", ""))
    if entered == "" then return end

    status.TextColor3 = Color3.fromRGB(180, 180, 220)
    status.Text = "проверка..."
    btn.Text = "..."
    btn.Active = false

    local ok, left = checkKeyOnServer(entered)

    btn.Active = true
    btn.Text = "войти"

    if not ok then
        status.TextColor3 = Color3.fromRGB(255, 120, 140)
        status.Text = left
        box.Text = ""
        tweenQuad(box, 0.12, { BackgroundColor3 = Color3.fromRGB(90, 30, 50) })
        task.wait(0.18)
        tweenQuad(box, 0.2, { BackgroundColor3 = Color3.fromRGB(38, 28, 58) })
        return
    end

    getgenv().vanta_active_key = entered
    getgenv().vanta_key_expiry_ts = os.time() + left

    status.TextColor3 = Color3.fromRGB(180, 255, 180)
    status.Text = "доступ разрешён"
    timerLbl.Text = "осталось: " .. formatTime(left)

    task.wait(1.2)
    tweenQuad(frame, 0.3, {
        Position = UDim2.new(0.5, -190, 0.4, -170),
        BackgroundTransparency = 1,
    })
    task.wait(0.3)
    sg:Destroy()
    onSuccess()
end

btn.MouseButton1Click:Connect(try)
box.FocusLost:Connect(function(enter) if enter then try() end end)

end -- vanta_show_keygate

getgenv().vanta_on_success = function()
    if getgenv().vanta_init_esp then getgenv().vanta_init_esp() end
    if getgenv().vanta_start_loop then getgenv().vanta_start_loop() end
    if getgenv().vanta_create_menu then getgenv().vanta_create_menu() end

    local parent = (gethui and gethui()) or CoreGui
    local ts = getgenv().vanta_key_expiry_ts
    if ts then
        local left = ts - os.time()
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 340, 0, 34)
        notif.Position = UDim2.new(0, 20, 1, -60)
        notif.BackgroundColor3 = Color3.fromRGB(20, 14, 30)
        notif.BackgroundTransparency = 0.15
        notif.BorderSizePixel = 0
        notif.Text = "  доступ: " .. formatTime(left)
        notif.TextColor3 = Color3.fromRGB(180, 140, 255)
        notif.Font = Enum.Font.GothamBold
        notif.TextSize = 13
        notif.TextXAlignment = Enum.TextXAlignment.Left
        notif.Parent = parent
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
        local s = Instance.new("UIStroke")
        s.Color = Color3.fromRGB(170, 120, 255)
        s.Thickness = 1
        s.Transparency = 0.5
        s.Parent = notif
        task.delay(6, function() if notif.Parent then notif:Destroy() end end)
    end
end

getgenv().vanta_show_keygate(getgenv().vanta_on_success)

print("[vanta v8.0] server keygate loaded · " .. SERVER_URL)