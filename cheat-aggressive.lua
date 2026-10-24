if getgenv().zeusx_aggro_loaded then return end
getgenv().zeusx_aggro_loaded = true

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

local function log(tag, ...)
    local parts = {...}
    local msg = "[zeusx-aggro][" .. tostring(tag) .. "]"
    for _, v in ipairs(parts) do msg = msg .. " " .. tostring(v) end
    pcall(print, msg)
end
getgenv().zeusx_aggro_log = log

getgenv().zeusx_aggro_cfg = {
    Aim = { Enabled=false, FOV=250, Smooth=0.95, Key=Enum.UserInputType.MouseButton2, Part="Head", Visible=true, StrictTeam=true, Mode="camera", Prediction=true },
    Silent = { Enabled=false, HitChance=100, Part="Head", StrictTeam=true, FreezeMs=200 },
    Trigger = { Enabled=false, Mode="hitbox", Key=Enum.UserInputType.MouseButton1, Delay=0.01, StrictTeam=true, WallCheck=false },
    ESP = { Enabled=false, Box=true, Name=true, Health=true, Distance=true, Skeleton=true, Chams=true, StrictTeam=true, MaxDist=5000 },
    Wallhack = { Enabled=false, Mode="full-clear" },
    Move = { Speed=false, SpeedVal=50, Fly=false, FlySpeed=100, Noclip=false },
    Misc = { PanicKey=Enum.KeyCode.End }
}
local Config = getgenv().zeusx_aggro_cfg

local function safeCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then log("ERROR", err) end
    return ok, err
end
getgenv().zeusx_aggro_safeCall = safeCall

log("part", "1/10 OK")local function getHead(m)
    return m and m:FindFirstChild("Head", true)
end

local function getRoot(m)
    return m and m:FindFirstChild("HumanoidRootPart", true)
end

local function getHum(m)
    return m and m:FindFirstChildOfClass("Humanoid")
end

local function isAlive(m)
    local h = getHum(m)
    return h and h.Health > 0
end

local function isSameTeam(m)
    if not Config.Aim.StrictTeam then return false end
    local plr = Players:FindFirstChild(m.Name)
    if plr then
        return plr.Team == LocalPlayer.Team or plr.TeamColor == LocalPlayer.TeamColor
    end
    return false
end

local function isFriend(m)
    local plr = Players:FindFirstChild(m.Name)
    if not plr then return false end
    local success, result = pcall(function() return LocalPlayer:IsFriendsWith(plr.UserId) end)
    return success and result
end

local function isVisible(m, partName)
    local part = m:FindFirstChild(partName, true) or getHead(m)
    if not part then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, m }
    local ray = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams)
    return not ray
end

local function isValidTarget(m)
    if not m or not m.Parent then return false end
    if m == LocalPlayer.Character then return false end
    if not isAlive(m) then return false end
    if isSameTeam(m) then return false end
    if isFriend(m) then return false end
    
    local hum = getHum(m)
    if hum and (hum.MaxHealth == math.huge or hum.MaxHealth > 1e6) then return false end
    
    return true
end

local function getTargets()
    local targets = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isValidTarget(plr.Character) then
            table.insert(targets, plr.Character)
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and isValidTarget(obj) and not Players:GetPlayerFromCharacter(obj) then
            table.insert(targets, obj)
        end
    end
    return targets
end

getgenv().zeusx_aggro_h = {
    getHead = getHead, getRoot = getRoot, getHum = getHum,
    isAlive = isAlive, isSameTeam = isSameTeam, isFriend = isFriend,
    isValidTarget = isValidTarget, getTargets = getTargets, isVisible = isVisible
}

log("part", "2/10 OK")local H = getgenv().zeusx_aggro_h
local aimHeld = false
local lockedTarget = nil
local lockedAt = 0

local function predictPos(model, basePos)
    local root = H.getRoot(model)
    if not root then return basePos end
    local vel = root.AssemblyLinearVelocity or root.Velocity
    if vel.Magnitude < 1 then return basePos end
    local camPos = Camera.CFrame.Position
    local dist = (camPos - basePos).Magnitude
    local t = dist / 200 * 0.8
    return basePos + vel * t
end

local function getAimTarget()
    local now = tick()
    if lockedTarget and (now - lockedAt) * 1000 < 200 then
        if H.isValidTarget(lockedTarget) then return lockedTarget end
        lockedTarget = nil
    end

    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
    local best, bestScore = nil, math.huge

    for _, m in ipairs(H.getTargets()) do
        local part = m:FindFirstChild(Config.Aim.Part, true) or H.getHead(m)
        if part then
            local pos = part.Position
            if Config.Aim.Prediction then pos = predictPos(m, pos) end
            
            local sp, onScreen = Camera:WorldToViewportPoint(pos)
            if onScreen then
                local pxDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if pxDist <= Config.Aim.FOV then
                    if Config.Aim.Visible and not H.isVisible(m, Config.Aim.Part) then continue end
                    
                    local score = pxDist + (camPos - pos).Magnitude * 0.05
                    if score < bestScore then
                        best = m
                        bestScore = score
                    end
                end
            end
        end
    end

    if best then
        lockedTarget = best
        lockedAt = now
    end
    return best
end

local function updateAim()
    if not Config.Aim.Enabled or not aimHeld then return end
    local target = getAimTarget()
    if not target then return end

    local part = target:FindFirstChild(Config.Aim.Part, true) or H.getHead(target)
    if not part then return end

    local targetPos = part.Position
    if Config.Aim.Prediction then targetPos = predictPos(target, targetPos) end

    if Config.Aim.Mode == "camera" then
        local camCF = Camera.CFrame
        local newCF = CFrame.new(camCF.Position, targetPos)
        Camera.CFrame = camCF:Lerp(newCF, Config.Aim.Smooth)
    else
        local sp = Camera:WorldToViewportPoint(targetPos)
        if sp then
            local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
            local delta = (Vector2.new(sp.X, sp.Y) - center) * Config.Aim.Smooth
            if mousemoverel then mousemoverel(delta.X, delta.Y) end
        end
    end
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == Config.Aim.Key then aimHeld = true end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Config.Aim.Key then aimHeld = false end
end)

getgenv().zeusx_aggro_updateAim = updateAim
log("part", "3/10 OK")local H = getgenv().zeusx_aggro_h
local silentTarget, silentPos = nil, nil
local silentAt = 0

local function getSilentTarget()
    local camPos = Camera.CFrame.Position
    local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
    local best, bestScore, bestPos = nil, math.huge, nil

    for _, m in ipairs(H.getTargets()) do
        local part = m:FindFirstChild(Config.Silent.Part, true) or H.getHead(m)
        if part then
            local pos = part.Position
            local sp, onScreen = Camera:WorldToViewportPoint(pos)
            if onScreen then
                local pxDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                local score = pxDist + (camPos - pos).Magnitude * 0.05
                if score < bestScore then
                    best, bestScore, bestPos = m, score, pos
                end
            end
        end
    end
    return best, bestPos
end

local function updateSilent()
    if not Config.Silent.Enabled then
        silentTarget, silentPos = nil, nil
        return
    end
    local now = tick()
    if silentTarget and silentPos and (now - silentAt) * 1000 < Config.Silent.FreezeMs then
        if H.isAlive(silentTarget) then return end
    end
    silentTarget, silentPos = getSilentTarget()
    silentAt = now
end

if hookmetamethod and getrawmetatable and setreadonly and newcclosure then
    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        if not old then return end
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if Config.Silent.Enabled and silentTarget and silentPos and method == "FireServer" then
                local args = {...}
                local mod = false
                for i = 1, #args do
                    if typeof(args[i]) == "Vector3" then
                        args[i] = silentPos
                        mod = true
                    end
                end
                if mod then
                    if math.random(1, 100) <= Config.Silent.HitChance then
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

getgenv().zeusx_aggro_updateSilent = updateSilent
log("part", "4/10 OK")local HttpService = game:GetService("HttpService")
local SERVER_URL = "https://zeus-key-mjep.onrender.com/check"

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
    local url = SERVER_URL .. "?token=" .. key .. "&hwid=" .. hwid .. "&username=" .. username .. "&ver=aggressive"
    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    
    if not ok or not response or response == "" then return nil, "нет соединения" end
    local okDecode, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not okDecode or type(data) ~= "table" then return nil, "ошибка формата" end
    
    if data.ok then return true, data.left or 0, data end
    
    local reasons = {
        invalid="неверный ключ", hwid_mismatch="ключ на другом устройстве",
        expired="срок истёк", banned="ключ забанен",
        no_activations="активации кончились", too_many_attempts="слишком много попыток",
    }
    return false, reasons[data.reason] or (data.reason or "ошибка"), data
end

getgenv().zeusx_aggro_getHWID = getHWID
getgenv().zeusx_aggro_checkKey = checkKeyOnServer

log("part", "5/10 OK · keygate core")local H = getgenv().zeusx_aggro_h
local trigHeld = false
local lastShot = 0

local function getCurrentTool()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChildOfClass("Tool") end
    return nil
end

local function fireWeapon()
    local tool = getCurrentTool()
    if mouse1click then pcall(mouse1click) end
    if tool then
        for _, name in ipairs({"Fire","Shoot","Attack","FireWeapon","ShootEvent","FireEvent"}) do
            local r = tool:FindFirstChild(name)
            if r and r:IsA("RemoteEvent") then
                pcall(function() r:FireServer() end)
                break
            end
        end
    end
end

local function isTargetInHitbox(m)
    local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
    local radius = 45
    
    for _, part in ipairs(m:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local sp = Camera:WorldToViewportPoint(part.Position)
            if sp then
                local r = radius
                if part.Name == "Head" then r = 25 end
                if (Vector2.new(sp.X, sp.Y) - center).Magnitude < r then return true end
            end
        end
    end
    return false
end

local function getTriggerTarget()
    local camPos = Camera.CFrame.Position
    for _, m in ipairs(H.getTargets()) do
        local root = H.getRoot(m)
        if root then
            local dist = (camPos - root.Position).Magnitude
            if dist <= Config.ESP.MaxDist then
                if isTargetInHitbox(m) then
                    if not Config.Trigger.WallCheck or H.isVisible(m, "Head") then
                        return m
                    end
                end
            end
        end
    end
    return nil
end

local function updateTrigger()
    if not Config.Trigger.Enabled or not trigHeld then return end
    if not H.isAlive(LocalPlayer.Character) then return end

    local now = tick()
    if now - lastShot < Config.Trigger.Delay then return end

    local target = getTriggerTarget()
    if target then
        fireWeapon()
        lastShot = now
    end
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType == Config.Trigger.Key then trigHeld = true end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Config.Trigger.Key then trigHeld = false end
end)

getgenv().zeusx_aggro_updateTrigger = updateTrigger
log("part", "6/10 OK")local H = getgenv().zeusx_aggro_h
local espDrawings = {}
local chamsFolder = nil

local function createESP(m)
    if espDrawings[m] then return end
    espDrawings[m] = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        healthBg = Drawing.new("Square"),
        healthFg = Drawing.new("Square"),
        dist = Drawing.new("Text"),
        tracer = Drawing.new("Line")
    }
    local d = espDrawings[m]
    d.box.Thickness = 1.5; d.box.Filled = false; d.box.Color = Color3.fromRGB(255, 60, 60); d.box.Transparency = 1
    d.name.Size = 14; d.name.Center = true; d.name.Outline = true; d.name.Color = Color3.fromRGB(255, 255, 255); d.name.Font = 2
    d.healthBg.Filled = true; d.healthBg.Color = Color3.fromRGB(0, 0, 0); d.healthBg.Thickness = 1
    d.healthFg.Filled = true; d.healthFg.Color = Color3.fromRGB(0, 255, 100); d.healthFg.Thickness = 1
    d.dist.Size = 12; d.dist.Center = true; d.dist.Outline = true; d.dist.Color = Color3.fromRGB(200, 200, 200); d.dist.Font = 2
    d.tracer.Thickness = 1; d.tracer.Color = Color3.fromRGB(255, 60, 60); d.tracer.Transparency = 0.6
end

local function removeESP(m)
    if not espDrawings[m] then return end
    for _, d in pairs(espDrawings[m]) do d:Remove() end
    espDrawings[m] = nil
end

local function renderESP()
    if not Config.ESP.Enabled then
        for m, d in pairs(espDrawings) do
            for _, draw in pairs(d) do draw.Visible = false end
        end
        if chamsFolder then
            for _, h in ipairs(chamsFolder:GetChildren()) do h:Destroy() end
        end
        return
    end

    local seen = {}
    local camPos = Camera.CFrame.Position
    local vpSize = Camera.ViewportSize

    for _, m in ipairs(H.getTargets()) do
        seen[m] = true
        createESP(m)
        local d = espDrawings[m]
        local head = H.getHead(m)
        local root = H.getRoot(m)
        local hum = H.getHum(m)

        if not head or not root or not hum then
            for _, draw in pairs(d) do draw.Visible = false end
            continue
        end

        local dist = (camPos - root.Position).Magnitude
        if dist > Config.ESP.MaxDist then
            for _, draw in pairs(d) do draw.Visible = false end
            continue
        end

        local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        if top.Z > 0 and bottom.Z > 0 then
            local h = bottom.Y - top.Y
            local w = h * 0.55
            local x = top.X - w / 2
            local y = top.Y

            d.box.Visible = Config.ESP.Box
            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(x, y)

            d.name.Visible = Config.ESP.Name
            d.name.Text = m.Name
            d.name.Position = Vector2.new(top.X, y - 16)

            local hp = hum.Health / hum.MaxHealth
            d.healthBg.Visible = Config.ESP.Health
            d.healthBg.Size = Vector2.new(3, h)
            d.healthBg.Position = Vector2.new(x - 6, y)
            d.healthFg.Visible = Config.ESP.Health
            d.healthFg.Size = Vector2.new(3, h * hp)
            d.healthFg.Position = Vector2.new(x - 6, y + h * (1 - hp))
            d.healthFg.Color = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(0, 255, 100), hp)

            d.dist.Visible = Config.ESP.Distance
            d.dist.Text = math.floor(dist) .. "m"
            d.dist.Position = Vector2.new(top.X, y + h + 4)

            d.tracer.Visible = true
            d.tracer.From = Vector2.new(vpSize.X / 2, vpSize.Y)
            d.tracer.To = Vector2.new(top.X, y + h)
        else
            for _, draw in pairs(d) do draw.Visible = false end
        end
    end

    for m in pairs(espDrawings) do
        if not seen[m] or not m.Parent then removeESP(m) end
    end

    if Config.ESP.Chams then
        if not chamsFolder then
            chamsFolder = Instance.new("Folder")
            chamsFolder.Name = "zeusx_chams"
            chamsFolder.Parent = (gethui and gethui()) or CoreGui
        end
        local active = {}
        for _, m in ipairs(H.getTargets()) do
            active[m.Name] = true
            local hl = chamsFolder:FindFirstChild(m.Name)
            if not hl then
                hl = Instance.new("Highlight", chamsFolder)
                hl.Name = m.Name
            end
            hl.Adornee = m
            hl.FillColor = Color3.fromRGB(255, 60, 60)
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
        for _, h in ipairs(chamsFolder:GetChildren()) do
            if not active[h.Name] then h:Destroy() end
        end
    elseif chamsFolder then
        for _, h in ipairs(chamsFolder:GetChildren()) do h:Destroy() end
    end
end

getgenv().zeusx_aggro_renderESP = renderESP
log("part", "7/10 OK")local H = getgenv().zeusx_aggro_h
local whHidden = {}
local whActive = false
local whApplied = false

local function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    while model do
        if model:FindFirstChildOfClass("Humanoid") then return true end
        model = model:FindFirstAncestorOfClass("Model")
    end
    return false
end

local function applyFullClear()
    if whApplied then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not isCharacterPart(obj) then
            if obj.Name ~= "Baseplate" then
                if whHidden[obj] == nil then whHidden[obj] = obj.Transparency end
                pcall(function() obj.Transparency = 1 end)
            end
        end
    end
    whApplied = true
end

local function restoreFullClear()
    for obj, orig in pairs(whHidden) do
        if obj and obj.Parent then pcall(function() obj.Transparency = orig end) end
    end
    whHidden = {}
    whApplied = false
end

local function updateWallhack()
    if not Config.Wallhack.Enabled then
        if whActive then restoreFullClear(); whActive = false end
        return
    end
    if not whActive then
        applyFullClear()
        whActive = true
    end
end

local skelLines = {}

local function getR15Bones()
    return {
        {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
    }
end

local function getR6Bones()
    return {
        {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"},
        {"Torso","Left Leg"}, {"Torso","Right Leg"},
    }
end

local function renderSkeleton()
    if not Config.ESP.Enabled or not Config.ESP.Skeleton then
        for _, l in pairs(skelLines) do l.Visible = false end
        return
    end

    local idx = 1
    for _, m in ipairs(H.getTargets()) do
        local bones = m:FindFirstChild("UpperTorso") and getR15Bones() or getR6Bones()
        for _, pair in ipairs(bones) do
            local p1 = m:FindFirstChild(pair[1], true)
            local p2 = m:FindFirstChild(pair[2], true)
            if p1 and p2 then
                local s1, on1 = Camera:WorldToViewportPoint(p1.Position)
                local s2, on2 = Camera:WorldToViewportPoint(p2.Position)
                if on1 and on2 then
                    if not skelLines[idx] then
                        skelLines[idx] = Drawing.new("Line")
                        skelLines[idx].Thickness = 1
                        skelLines[idx].Color = Color3.fromRGB(255, 60, 60)
                        skelLines[idx].Transparency = 0.8
                    end
                    local line = skelLines[idx]
                    line.Visible = true
                    line.From = Vector2.new(s1.X, s1.Y)
                    line.To = Vector2.new(s2.X, s2.Y)
                    idx = idx + 1
                end
            end
        end
    end

    for i = idx, #skelLines do skelLines[i].Visible = false end
end

getgenv().zeusx_aggro_updateWallhack = updateWallhack
getgenv().zeusx_aggro_renderSkeleton = renderSkeleton
log("part", "8/10 OK")local H = getgenv().zeusx_aggro_h
local noclipApplied = false
local flyActive = false
local flyBV, flyBG = nil, nil

local function updateNoclip()
    if not Config.Move.Noclip then
        if noclipApplied then
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
                end
            end
            noclipApplied = false
        end
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.CanCollide = false; p.CanQuery = false; p.CanTouch = false end)
        end
    end
    noclipApplied = true
end

local function updateSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if Config.Move.Speed then
        hum.WalkSpeed = Config.Move.SpeedVal
    elseif hum.WalkSpeed ~= 16 then
        hum.WalkSpeed = 16
    end
end

local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.PlatformStand = false end) end
    end
    flyActive = false
end

local function updateFly()
    if not Config.Move.Fly then
        if flyActive then stopFly() end
        return
    end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if not flyActive then
        flyBV = Instance.new("BodyVelocity", hrp)
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBG = Instance.new("BodyGyro", hrp)
        flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBG.P = 3000; flyBG.D = 50
        pcall(function() hum.PlatformStand = true end)
        flyActive = true
    end

    local camCF = Camera.CFrame
    local move = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then move += camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move -= camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move -= camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move += camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

    if move.Magnitude > 0 then move = move.Unit * Config.Move.FlySpeed end
    
    if flyBV then flyBV.Velocity = move end
    if flyBG then flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector) end
end

getgenv().zeusx_aggro_updateNoclip = updateNoclip
getgenv().zeusx_aggro_updateSpeed = updateSpeed
getgenv().zeusx_aggro_updateFly = updateFly
log("part", "9/10 OK")local H = getgenv().zeusx_aggro_h

local function createMenu()
    local parent = (gethui and gethui()) or CoreGui
    if getgenv().zeusx_aggro_menu and getgenv().zeusx_aggro_menu.Parent then
        getgenv().zeusx_aggro_menu:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "zeusx_aggro_menu"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.DisplayOrder = 999; sg.Parent = parent
    getgenv().zeusx_aggro_menu = sg

    local winW, winH = 620, 520
    local win = Instance.new("Frame", sg)
    win.Size = UDim2.new(0, winW, 0, winH)
    win.Position = UDim2.new(0.5, -winW/2, 0.5, -winH/2)
    win.BackgroundColor3 = Color3.fromRGB(20, 5, 10)
    win.BackgroundTransparency = 0.15
    win.BorderSizePixel = 0; win.Active = true; win.Draggable = true
    win.ClipsDescendants = true
    Instance.new("UICorner", win).CornerRadius = UDim.new(0, 16)
    local stroke = Instance.new("UIStroke", win); stroke.Color = Color3.fromRGB(255, 60, 60); stroke.Thickness = 1.5; stroke.Transparency = 0.3

    local bar = Instance.new("Frame", win)
    bar.Size = UDim2.new(1, 0, 0, 44); bar.BackgroundTransparency = 1
    local title = Instance.new("TextLabel", bar)
    title.Size = UDim2.new(1, -60, 1, 0); title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "AGGRESSIVE v1.0"
    title.TextColor3 = Color3.fromRGB(255, 60, 60); title.Font = Enum.Font.GothamBlack; title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left

    local close = Instance.new("TextButton", bar)
    close.Size = UDim2.new(0, 30, 0, 30); close.Position = UDim2.new(1, -36, 0, 7)
    close.BackgroundColor3 = Color3.fromRGB(100, 20, 20); close.Text = "×"; close.TextColor3 = Color3.fromRGB(255, 200, 200)
    close.Font = Enum.Font.GothamBold; close.TextSize = 18; close.BorderSizePixel = 0
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    close.MouseButton1Click:Connect(function() sg:Destroy(); getgenv().zeusx_aggro_menu = nil end)

    local content = Instance.new("Frame", win)
    content.Size = UDim2.new(1, -32, 1, -60); content.Position = UDim2.new(0, 16, 0, 50)
    content.BackgroundTransparency = 1

    local scroll = Instance.new("ScrollingFrame", content)
    scroll.Size = UDim2.new(1, 0, 1, 0); scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4; scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 60, 60)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new()
    Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 6)

    local function section(t)
        local h = Instance.new("TextLabel", scroll)
        h.Size = UDim2.new(1, -10, 0, 24); h.BackgroundTransparency = 1
        h.Text = "  " .. t; h.TextColor3 = Color3.fromRGB(255, 60, 60)
        h.Font = Enum.Font.GothamBold; h.TextSize = 13
        h.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function toggle(label, get, set)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1, -10, 0, 40); row.BackgroundColor3 = Color3.fromRGB(40, 10, 20)
        row.BackgroundTransparency = 0.3; row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
        local s = Instance.new("UIStroke", row); s.Color = Color3.fromRGB(255, 60, 60); s.Thickness = 1; s.Transparency = 0.8

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1, -70, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = Color3.fromRGB(255, 230, 230)
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left

        local sw = Instance.new("TextButton", row)
        sw.Size = UDim2.new(0, 50, 0, 26); sw.Position = UDim2.new(1, -60, 0.5, -13)
        sw.BackgroundColor3 = get() and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(40, 20, 20)
        sw.Text = ""; sw.BorderSizePixel = 0
        Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
        
        local knob = Instance.new("Frame", sw)
        knob.Size = UDim2.new(0, 22, 0, 22); knob.Position = get() and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        sw.MouseButton1Click:Connect(function()
            local nv = not get(); set(nv)
            TweenService:Create(sw, TweenInfo.new(0.2), {BackgroundColor3 = nv and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(40, 20, 20)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = nv and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)}):Play()
        end)
    end

    section("AIMBOT")
    toggle("Aimbot Enable", function() return Config.Aim.Enabled end, function(v) Config.Aim.Enabled = v end)
    toggle("Silent Aim", function() return Config.Silent.Enabled end, function(v) Config.Silent.Enabled = v end)
    toggle("Triggerbot", function() return Config.Trigger.Enabled end, function(v) Config.Trigger.Enabled = v end)

    section("VISUALS")
    toggle("ESP Enable", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled = v end)
    toggle("Skeleton", function() return Config.ESP.Skeleton end, function(v) Config.ESP.Skeleton = v end)
    toggle("Chams", function() return Config.ESP.Chams end, function(v) Config.ESP.Chams = v end)
    toggle("Wallhack Full-Clear", function() return Config.Wallhack.Enabled end, function(v) Config.Wallhack.Enabled = v end)

    section("MOVEMENT")
    toggle("Speed", function() return Config.Move.Speed end, function(v) Config.Move.Speed = v end)
    toggle("Fly", function() return Config.Move.Fly end, function(v) Config.Move.Fly = v end)
    toggle("Noclip", function() return Config.Move.Noclip end, function(v) Config.Move.Noclip = v end)
end

if not getgenv().zeusx_aggro_loop then
    getgenv().zeusx_aggro_loop = RunService.RenderStepped:Connect(function()
        if Config.Aim.Enabled then safeCall(getgenv().zeusx_aggro_updateAim) end
        if Config.Silent.Enabled then safeCall(getgenv().zeusx_aggro_updateSilent) end
        if Config.Trigger.Enabled then safeCall(getgenv().zeusx_aggro_updateTrigger) end
        if Config.ESP.Enabled then safeCall(getgenv().zeusx_aggro_renderESP) end
        if Config.ESP.Enabled and Config.ESP.Skeleton then safeCall(getgenv().zeusx_aggro_renderSkeleton) end
        if Config.Wallhack.Enabled then safeCall(getgenv().zeusx_aggro_updateWallhack) end
        safeCall(getgenv().zeusx_aggro_updateNoclip)
        safeCall(getgenv().zeusx_aggro_updateSpeed)
        safeCall(getgenv().zeusx_aggro_updateFly)
    end)
end

UIS.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Config.Misc.PanicKey then
        Config.Aim.Enabled = false; Config.Silent.Enabled = false
        Config.Trigger.Enabled = false; Config.ESP.Enabled = false
        Config.Wallhack.Enabled = false; Config.Move.Noclip = false
        Config.Move.Fly = false; Config.Move.Speed = false
    end
end)

createMenu()
log("part", "10/10 OK · loaded")