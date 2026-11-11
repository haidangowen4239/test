-- lang: Lua, file: BFHub.lua, target: Blox Fruits (Roblox), executor: any
-- *offsets và RemoteEvent names dựa trên game version hiện tại — re-pin sau mỗi update*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

-- re-link sau respawn
lp.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
    hum = c:WaitForChild("Humanoid")
end)

--==================================================
-- STATE
--==================================================

local State = {
    AutoFarmMob    = false,
    AutoFarmBoss   = false,
    AutoChest      = false,
    AutoQuest      = false,
    AutoEat        = false,
    AutoSkill      = false,
    KillAura       = false,
    BringMobs      = false,
    Fly            = false,
    ServerHop      = false,
    FlySpeed       = 80,
    WalkSpeed      = 16,
    KillAuraRange  = 40,
    FarmMobName    = "",
    TeleportIsland = "",
}

--==================================================
-- UTILS
--==================================================

local function Notify(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BFHub",
        Text = msg,
        Duration = 3
    })
end

local function GetDistance(a, b)
    return (a - b).Magnitude
end

local function SafeTP(pos)
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

local function GetHRP(model)
    return model:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(model)
    local h = model:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

--==================================================
-- TELEPORT TO ISLAND
--==================================================

local Islands = {
    ["Starter Island"]     = Vector3.new(914.3, 124.0, 1799.7),
    ["Middle Island"]      = Vector3.new(-2680, 128, -814),
    ["Frozen Village"]     = Vector3.new(1273, 125, -1428),
    ["Marine Fortress"]    = Vector3.new(-4463, 24, -4255),
    ["Sky Islands"]        = Vector3.new(-7873, 528, -3822),
    ["Prison"]             = Vector3.new(4813, 10, 1023),
    ["Colosseum"]          = Vector3.new(-1300, 128, -3650),
    ["Magma Village"]      = Vector3.new(-5765, 141, 2270),
    ["Underwater City"]    = Vector3.new(-4800, -800, -1800),
    ["Fountain City"]      = Vector3.new(5280, 24, 2810),
    ["Cafe (Sea 2)"]       = Vector3.new(-1180, 50, -1600),
    ["Green Zone"]         = Vector3.new(-3680, 243, 2000),
    ["Graveyard"]          = Vector3.new(5990, 24, 2990),
    ["Snow Mountain"]      = Vector3.new(2050, 450, -3800),
    ["Hot & Cold"]         = Vector3.new(3980, 125, -4040),
    ["Cursed Ship"]        = Vector3.new(1230, 25, -4810),
    ["Ice Castle"]         = Vector3.new(2650, 24, -4820),
    ["Forgotten Island"]   = Vector3.new(-3830, 24, 4290),
    ["Dressrosa"]          = Vector3.new(-1618, 50, -1218),
    ["Zou"]                = Vector3.new(-840, 395, 2985),
    ["Thriller Bark"]      = Vector3.new(-8700, 25, -2900),
    ["Cake Island"]        = Vector3.new(-13550, 25, -4830),
    ["Wano"]               = Vector3.new(5600, 24, -11000),
    ["Haunted Castle"]     = Vector3.new(-11650, 24, -3250),
    ["Port Town"]          = Vector3.new(-3870, 24, 6300),
}

local function TeleportIsland(name)
    local pos = Islands[name]
    if pos then
        SafeTP(pos)
        Notify("Teleported: " .. name)
    else
        Notify("Island not found: " .. name)
    end
end

local function TeleportToPlayer(name)
    local target = Players:FindFirstChild(name)
    if target and target.Character then
        local hrp = GetHRP(target.Character)
        if hrp then
            SafeTP(hrp.Position + Vector3.new(3, 0, 0))
            Notify("Teleported to " .. name)
        end
    end
end

--==================================================
-- FLY
--==================================================

local flyBody = nil

local function StartFly()
    if not root then return end
    local bp = Instance.new("BodyVelocity")
    bp.Name = "FlyBV"
    bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bp.Velocity = Vector3.new(0, 0, 0)
    bp.Parent = root
    flyBody = bp

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.D = 50
    bg.Parent = root
end

local function StopFly()
    if root then
        local bp = root:FindFirstChild("FlyBV")
        local bg = root:FindFirstChild("FlyBG")
        if bp then bp:Destroy() end
        if bg then bg:Destroy() end
    end
    flyBody = nil
end

RunService.RenderStepped:Connect(function()
    if not State.Fly or not root then return end
    local bp = root:FindFirstChild("FlyBV")
    local bg = root:FindFirstChild("FlyBG")
    if not bp or not bg then return end

    local cam = Workspace.CurrentCamera
    local dir = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        dir = dir + cam.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        dir = dir - cam.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        dir = dir - cam.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        dir = dir + cam.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        dir = dir + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        dir = dir - Vector3.new(0, 1, 0)
    end

    bp.Velocity = dir.Magnitude > 0 and dir.Unit * State.FlySpeed or Vector3.new(0, 0, 0)
    bg.CFrame = cam.CFrame
end)

--==================================================
-- KILL AURA
--==================================================

local function GetNearestMob(range)
    local nearest, dist = nil, range
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= char then
            local h = v:FindFirstChildOfClass("Humanoid")
            local hrp = GetHRP(v)
            if h and h.Health > 0 and hrp then
                local d = GetDistance(root.Position, hrp.Position)
                if d < dist then
                    nearest = v
                    dist = d
                end
            end
        end
    end
    return nearest
end

RunService.Heartbeat:Connect(function()
    if not State.KillAura or not root or not char then return end
    local mob = GetNearestMob(State.KillAuraRange)
    if mob then
        local hrp = GetHRP(mob)
        if hrp then
            root.CFrame = CFrame.new(root.Position, hrp.Position)
            -- trigger melee swing
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local remote = tool:FindFirstChildOfClass("RemoteEvent")
                    or tool:FindFirstChildOfClass("RemoteFunction")
                if remote and remote:IsA("RemoteEvent") then
                    remote:FireServer(hrp.Position)
                end
            end
        end
    end
end)

--==================================================
-- BRING MOBS
--==================================================

RunService.Heartbeat:Connect(function()
    if not State.BringMobs or not root then return end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= char then
            local h = v:FindFirstChildOfClass("Humanoid")
            local hrp = GetHRP(v)
            if h and h.Health > 0 and hrp then
                hrp.CFrame = CFrame.new(root.Position + Vector3.new(math.random(-5,5), 0, math.random(-5,5)))
            end
        end
    end
end)

--==================================================
-- AUTO FARM MOB
--==================================================

RunService.Heartbeat:Connect(function()
    if not State.AutoFarmMob or not root or State.FarmMobName == "" then return end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == State.FarmMobName then
            local h = v:FindFirstChildOfClass("Humanoid")
            local hrp = GetHRP(v)
            if h and h.Health > 0 and hrp then
                SafeTP(hrp.Position + Vector3.new(0, 2, 3))
                task.wait(0.05)
                return
            end
        end
    end
end)

--==================================================
-- AUTO FARM BOSS
--==================================================

local BossNames = {
    "Gorilla King", "Bobby", "Yeti", "Mob Leader",
    "Saw", "Vice Admiral", "Warden", "Chief Warden",
    "Swan", "Magma Admiral", "Croc", "Smoke Admiral",
    "Awakened Ice Admiral", "Cake Queen", "Island Empress",
    "Longma", "Rip_Indra", "Stone", "Diamante",
}

RunService.Heartbeat:Connect(function()
    if not State.AutoFarmBoss or not root then return end
    for _, name in ipairs(BossNames) do
        local boss = Workspace:FindFirstChild(name, true)
        if boss and boss:IsA("Model") then
            local h = boss:FindFirstChildOfClass("Humanoid")
            local hrp = GetHRP(boss)
            if h and h.Health > 0 and hrp then
                SafeTP(hrp.Position + Vector3.new(0, 2, 3))
                task.wait(0.05)
                return
            end
        end
    end
end)

--==================================================
-- AUTO CHEST
--==================================================

RunService.Heartbeat:Connect(function()
    if not State.AutoChest or not root then return end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "Chest" or v.Name == "Treasure" then
            if v:IsA("Model") or v:IsA("BasePart") then
                local pos = v:IsA("Model") and (v.PrimaryPart and v.PrimaryPart.Position or v:GetModelCFrame().Position) or v.Position
                if GetDistance(root.Position, pos) > 10 then
                    SafeTP(pos + Vector3.new(0, 3, 0))
                end
                task.wait(0.1)
                return
            end
        end
    end
end)

--==================================================
-- AUTO QUEST
--==================================================

RunService.Heartbeat:Connect(function()
    if not State.AutoQuest then return end
    local questGivers = Workspace:FindFirstChild("QuestGivers")
        or Workspace:FindFirstChild("NPCs")
    if not questGivers or not root then return end
    for _, npc in ipairs(questGivers:GetChildren()) do
        local hrp = GetHRP(npc)
        if hrp and GetDistance(root.Position, hrp.Position) < 15 then
            local remote = ReplicatedStorage:FindFirstChild("Interactions", true)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer(npc, "AcceptQuest")
            end
        end
    end
end)

--==================================================
-- AUTO EAT
--==================================================

RunService.Heartbeat:Connect(function()
    if not State.AutoEat or not hum then return end
    if hum.Health < hum.MaxHealth * 0.6 then
        for _, item in ipairs(lp.Backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:find("Fruit") or item.Name:find("Food")) then
                lp.Character.Humanoid:EquipTool(item)
                task.wait(0.1)
                local mouse = lp:GetMouse()
                local activate = item:FindFirstChild("Activated")
                if activate then activate:Fire() end
                task.wait(0.5)
                return
            end
        end
    end
end)

--==================================================
-- AUTO SKILL
--==================================================

local SkillKeys = {
    Enum.KeyCode.Z,
    Enum.KeyCode.X,
    Enum.KeyCode.C,
    Enum.KeyCode.V,
    Enum.KeyCode.F,
}

RunService.Heartbeat:Connect(function()
    if not State.AutoSkill or not root then return end
    local mob = GetNearestMob(60)
    if mob then
        for _, key in ipairs(SkillKeys) do
            local vk = Instance.new("InputObject")
            vk.KeyCode = key
            vk.UserInputType = Enum.UserInputType.Keyboard
            UserInputService.InputBegan:Fire(vk, false)
            task.wait(0.1)
        end
    end
end)

--==================================================
-- SERVER HOP
--==================================================

local function ServerHop()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    local ok, servers = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100")
        )
    end)
    if not ok or not servers.data then
        Notify("Server hop failed")
        return
    end
    for _, s in ipairs(servers.data) do
        if s.playing < s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(placeId, s.id, lp)
            return
        end
    end
    Notify("No server found")
end

--==================================================
-- SPEED
--==================================================

local function SetSpeed(spd)
    if hum then
        hum.WalkSpeed = spd
        State.WalkSpeed = spd
    end
end

--==================================================
-- UI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BFHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = lp:WaitForChild("PlayerGui")

local ACCENT   = Color3.fromRGB(255, 85, 0)
local BG       = Color3.fromRGB(14, 14, 18)
local BG2      = Color3.fromRGB(22, 22, 28)
local TEXT     = Color3.fromRGB(240, 240, 245)
local TEXTDIM  = Color3.fromRGB(130, 130, 145)
local GREEN    = Color3.fromRGB(80, 200, 100)
local RED      = Color3.fromRGB(200, 70, 70)

-- main frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(420, 520)
Frame.Position = UDim2.new(0.5, -210, 0.5, -260)
Frame.BackgroundColor3 = BG
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
local fs = Instance.new("UIStroke", Frame)
fs.Color = ACCENT
fs.Transparency = 0.6
fs.Thickness = 1

-- title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = BG2
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🍊 BF Hub"
TitleLabel.TextColor3 = TEXT
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 4)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = TEXTDIM
CloseBtn.TextSize = 22
CloseBtn.Font = Enum.Font.Gotham
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- scroll content
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -46)
Scroll.Position = UDim2.new(0, 5, 0, 41)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = ACCENT
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Frame

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 6)
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Parent = Scroll

local Pad = Instance.new("UIPadding")
Pad.PaddingLeft = UDim.new(0, 8)
Pad.PaddingRight = UDim.new(0, 8)
Pad.PaddingTop = UDim.new(0, 6)
Pad.Parent = Scroll

-- helpers
local order = 0
local function Section(name)
    order += 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── " .. name .. " ──"
    lbl.TextColor3 = ACCENT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = Scroll
end

local function Toggle(label, stateKey, callback)
    order += 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = BG2
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TEXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.fromOffset(44, 22)
    pill.Position = UDim2.new(1, -54, 0.5, -11)
    pill.BackgroundColor3 = RED
    pill.Text = ""
    pill.AutoButtonColor = false
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(16, 16)
    dot.Position = UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    dot.BorderSizePixel = 0
    dot.Parent = pill
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local function Refresh()
        local on = State[stateKey]
        TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = on and GREEN or RED}):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {Position = on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
    end

    pill.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        Refresh()
        if callback then callback(State[stateKey]) end
    end)

    Refresh()
end

local function Button(label, cb)
    order += 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = ACCENT
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(cb)
end

local function InputRow(label, placeholder, cb)
    order += 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = BG2
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TEXTDIM
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.55, 0, 0.7, 0)
    box.Position = UDim2.new(0.42, 0, 0.15, 0)
    box.BackgroundColor3 = BG
    box.TextColor3 = TEXT
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = TEXTDIM
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    box.FocusLost:Connect(function()
        if cb then cb(box.Text) end
    end)
end

local function DropdownRow(label, options, cb)
    order += 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = BG2
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = TEXTDIM
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.55, 0, 0.7, 0)
    btn.Position = UDim2.new(0.42, 0, 0.15, 0)
    btn.BackgroundColor3 = BG
    btn.Text = options[1]
    btn.TextColor3 = TEXT
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local idx = 1
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        if cb then cb(options[idx]) end
    end)
end

--==================================================
-- BUILD UI SECTIONS
--==================================================

Section("⚔ COMBAT")
Toggle("Kill Aura", "KillAura")
Toggle("Auto Skill", "AutoSkill")
Toggle("Bring Mobs", "BringMobs")

Section("🌾 FARM")
InputRow("Mob Name", "e.g. Monkey", function(v) State.FarmMobName = v end)
Toggle("Auto Farm Mob", "AutoFarmMob")
Toggle("Auto Farm Boss", "AutoFarmBoss")
Toggle("Auto Collect Chest", "AutoChest")
Toggle("Auto Accept Quest", "AutoQuest")
Toggle("Auto Eat Food", "AutoEat")

Section("🚀 MOVEMENT")
Toggle("Fly", "Fly", function(on)
    if on then StartFly() else StopFly() end
end)
InputRow("Fly Speed", "default: 80", function(v)
    local n = tonumber(v)
    if n then State.FlySpeed = n end
end)
InputRow("Walk Speed", "default: 16", function(v)
    local n = tonumber(v)
    if n then SetSpeed(n) end
end)

Section("🗺 TELEPORT")
DropdownRow("Island", (function()
    local t = {}
    for k in pairs(Islands) do t[#t+1] = k end
    table.sort(t)
    return t
end)(), function(v)
    State.TeleportIsland = v
end)
Button("Teleport to Island", function()
    if State.TeleportIsland ~= "" then
        TeleportIsland(State.TeleportIsland)
    else
        Notify("Chọn island trước")
    end
end)
InputRow("Player Name", "e.g. Noob123", function(v)
    TeleportToPlayer(v)
end)

Section("🌐 MISC")
Button("Server Hop", function()
    State.ServerHop = true
    ServerHop()
end)

Notify("BF Hub loaded!")
