-- WindUI Script: "the button" by abyssnt (COMPLETO)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================================
-- WINDUI LOADER
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ============================================================
-- WINDOW
-- ============================================================
local Window = WindUI:CreateWindow({
    Title       = "The Button",
    Author      = "by: abyssnt",
    Size        = UDim2.fromOffset(580, 460),
    Theme       = "Dark",
    Transparent = true,
})

-- ============================================================
-- STATE
-- ============================================================
local State = {
    AimbotEnabled       = false,
    SelectedTarget      = nil,
    SelectedPlayerName  = "nobody",
    EspHighlightEnabled = false,
    EspNicknameEnabled  = false,
    SpawnNotifyEnabled  = false,
    Highlights          = {},
    NicknameLabels      = {},
    AimbotSmoothness    = 0.1,
    TpWalkEnabled       = false,
    NoclipEnabled       = false,
    AntiVoidEnabled     = false,
    GrabMode            = "Grab mode adaptive mobile",
    InfJumpEnabled      = false,
    AutoGrab = {
        Shield    = false,
        Katana    = false,
        L106      = false,
        Knife     = false,
        Briefcase = false,
        Sledge    = false,
        Vest      = false,
        Bandage   = false,
    },
    AutoGrabAll = false,
}

-- ============================================================
-- UTILITIES
-- ============================================================
local function GetRoot(player)
    local char = player and player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(player)
    local char = player and player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local RayParamsCache = nil

local function GetRayParams(targetChar)
    if not RayParamsCache then
        RayParamsCache = RaycastParams.new()
        RayParamsCache.FilterType = Enum.RaycastFilterType.Blacklist
        RayParamsCache.IgnoreWater = true
    end
    RayParamsCache.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    return RayParamsCache
end

local function HasLineOfSight(targetRoot)
    if not targetRoot then return false end
    local origin = Camera.CFrame.Position
    local direction = targetRoot.Position - origin
    local distance = direction.Magnitude
    if distance > 300 then return false end
    local params = GetRayParams(targetRoot.Parent)
    local result = Workspace:Raycast(origin, direction.Unit * distance, params)
    return result == nil
end

local function GetPlayerFromEntry(entry)
    if entry == "nobody" then return nil end
    local name = entry:match("@(.+)%)$")
    return name and Players:FindFirstChild(name) or nil
end

-- ============================================================
-- AIMBOT LOOP
-- ============================================================
local AimbotConn
local ClickConn
local Mouse = LocalPlayer:GetMouse()

local lastCameraCF = CFrame.new()
local cameraStuckTime = 0
local lastRaycastTime = 0
local lastLOS = true
local targetLostCount = 0
local RAYCAST_INTERVAL = 0.08
local lastForcedRotation = 0

local function StopAimbot()
    if AimbotConn then AimbotConn:Disconnect() AimbotConn = nil end
    if ClickConn  then ClickConn:Disconnect()  ClickConn  = nil end
    State.SelectedTarget = nil
    targetLostCount = 0
    cameraStuckTime = 0
    lastForcedRotation = 0
end

local function StartAimbot()
    StopAimbot()

    local lastClickTime = 0
    local CLICK_COOLDOWN = 25

    ClickConn = Mouse.Button1Down:Connect(function()
        if not State.AimbotEnabled then return end
        if State.SelectedPlayerName ~= "nobody" then return end
        local now = tick()
        if State.SelectedTarget ~= nil and (now - lastClickTime) < CLICK_COOLDOWN then return end
        local hit = Mouse.Target
        if not hit then return end
        local model = hit:FindFirstAncestorOfClass("Model")
        if not model then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == model and p ~= LocalPlayer then
                State.SelectedTarget = p
                lastClickTime = now
                targetLostCount = 0
                cameraStuckTime = 0
                lastForcedRotation = now
                break
            end
        end
    end)

    AimbotConn = RunService.Heartbeat:Connect(function()
        if not State.AimbotEnabled then return end

        local target = State.SelectedTarget
        if not target or not IsAlive(target) then
            if State.SelectedTarget ~= nil then
                State.SelectedTarget = nil
                targetLostCount = 0
                WindUI:Notify({
                    Title    = "Aimbot",
                    Content  = "Target is dead. Aimbot and Auto Shoot paused.",
                    Duration = 2,
                    Icon     = "x",
                })
            end
            return
        end

        local root = GetRoot(target)
        if not root then
            State.SelectedTarget = nil
            targetLostCount = 0
            return
        end

        targetLostCount = 0

        local currentCF = Camera.CFrame
        local isCameraStuck = (currentCF.Position - lastCameraCF.Position).Magnitude < 0.01 and 
                              (currentCF.LookVector - lastCameraCF.LookVector).Magnitude < 0.01

        if isCameraStuck then
            cameraStuckTime = cameraStuckTime + 0.03
        else
            cameraStuckTime = 0
        end
        lastCameraCF = currentCF

        local now = tick()
        if now - lastRaycastTime >= RAYCAST_INTERVAL then
            lastRaycastTime = now
            lastLOS = HasLineOfSight(root)
        end

        if lastLOS then
            local cf = Camera.CFrame
            local targetPos = root.Position
            local newCF = CFrame.lookAt(cf.Position, targetPos)

            if cameraStuckTime > 0.5 or (now - lastForcedRotation) > 0.5 then
                Camera.CFrame = newCF * CFrame.Angles(0, math.rad(0.01), 0)
                lastForcedRotation = now
                cameraStuckTime = 0
                task.wait(0.01)
            end

            local lerpFactor = 1 - State.AimbotSmoothness
            if lerpFactor < 0.1 then lerpFactor = 0.1 end
            Camera.CFrame = cf:Lerp(newCF, lerpFactor)
        end
    end)
end

-- ============================================================
-- ESP: HIGHLIGHT
-- ============================================================
local function ClearHighlights()
    for _, h in pairs(State.Highlights) do
        if h and h.Parent then h:Destroy() end
    end
    State.Highlights = {}
end

local function ApplyHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    if State.Highlights[player.Name] and State.Highlights[player.Name].Parent then return end
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL_" .. player.Name
    hl.Adornee = char
    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
    hl.OutlineTransparency = 0.3
    hl.FillColor = Color3.fromRGB(0, 255, 0)
    hl.FillTransparency = 1
    hl.Parent = char
    State.Highlights[player.Name] = hl
end

local function EnableHighlightESP()
    for _, p in ipairs(Players:GetPlayers()) do ApplyHighlight(p) end
end

-- ============================================================
-- ESP: NICKNAME
-- ============================================================
local function ClearNicknames()
    for _, b in pairs(State.NicknameLabels) do
        if b and b.Parent then b:Destroy() end
    end
    State.NicknameLabels = {}
end

local function ApplyNickname(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if State.NicknameLabels[player.Name] and State.NicknameLabels[player.Name].Parent then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Nick_" .. player.Name
    bb.Adornee = root
    bb.Size = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = root
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = "@" .. player.Name
    lbl.Parent = bb
    State.NicknameLabels[player.Name] = bb
end

local function EnableNicknameESP()
    for _, p in ipairs(Players:GetPlayers()) do ApplyNickname(p) end
end

-- ============================================================
-- PLAYER HOOKS
-- ============================================================
local function HookPlayer(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if State.EspHighlightEnabled then ApplyHighlight(p) end
        if State.EspNicknameEnabled then ApplyNickname(p) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do HookPlayer(p) end
Players.PlayerAdded:Connect(HookPlayer)

Players.PlayerRemoving:Connect(function(p)
    if State.SelectedTarget == p then State.SelectedTarget = nil end
    if State.Highlights[p.Name] then
        State.Highlights[p.Name]:Destroy()
        State.Highlights[p.Name] = nil
    end
    if State.NicknameLabels[p.Name] then
        State.NicknameLabels[p.Name]:Destroy()
        State.NicknameLabels[p.Name] = nil
    end
end)

-- ============================================================
-- ITEM SPAWN WATCHER
-- ============================================================
local WATCH_ITEMS = { "Shield", "Katana", "L106", "Knife", "Briefcase", "Sledge", "Vest", "Bandage" }
local SpawnConns = {}

local function IsInWorkspace(obj)
    if not obj or not obj.Parent then return false end

    local current = obj
    while current do
        if current == Workspace then
            local parent = obj.Parent
            while parent do
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character and parent == player.Character then
                        return false
                    end
                end
                parent = parent.Parent
            end
            return true
        end
        if current.Parent == game then break end
        current = current.Parent
    end
    return false
end

local function StopSpawnWatcher()
    for _, c in ipairs(SpawnConns) do c:Disconnect() end
    SpawnConns = {}
end

local function StartSpawnWatcher()
    StopSpawnWatcher()
    local present = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsInWorkspace(obj) then
            for _, w in ipairs(WATCH_ITEMS) do
                if obj.Name == w then
                    present[obj] = true
                    break
                end
            end
        end
    end

    local c1 = Workspace.DescendantAdded:Connect(function(obj)
        if not State.SpawnNotifyEnabled then return end

        if not IsInWorkspace(obj) then return end

        for _, w in ipairs(WATCH_ITEMS) do
            if obj.Name == w and not present[obj] then
                present[obj] = true
                WindUI:Notify({
                    Title = "Item Spawned",
                    Content = "The item " .. w .. " spawned in Workspace",
                    Duration = 5,
                    Icon = "package",
                })
                break
            end
        end
    end)

    local c2 = Workspace.DescendantRemoving:Connect(function(obj)
        present[obj] = nil
    end)

    table.insert(SpawnConns, c1)
    table.insert(SpawnConns, c2)
end

-- ============================================================
-- GRAB ITEM
-- ============================================================
local function GrabItem(itemName)
    local char = LocalPlayer.Character
    if not char then 
        WindUI:Notify({
            Title = "Error",
            Content = "Character not found!",
            Duration = 2,
            Icon = "x",
        })
        return 
    end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then 
        WindUI:Notify({
            Title = "Error",
            Content = "HumanoidRootPart not found!",
            Duration = 2,
            Icon = "x",
        })
        return 
    end

    local originalCFrame = root.CFrame
    local prompt = nil
    local itemPart = nil

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == itemName and IsInWorkspace(obj) then
            local pp = obj:FindFirstChildOfClass("ProximityPrompt")
            if not pp then
                pp = obj:FindFirstChild("ProximityPrompt", true)
            end

            if pp then
                prompt = pp
                if obj:IsA("BasePart") then
                    itemPart = obj
                else
                    itemPart = obj:FindFirstChildWhichIsA("BasePart")
                    if not itemPart then
                        for _, child in ipairs(obj:GetDescendants()) do
                            if child:IsA("BasePart") then
                                itemPart = child
                                break
                            end
                        end
                    end
                end
                break
            end
        end
    end

    if not prompt then
        WindUI:Notify({
            Title = "Not Found",
            Content = itemName .. " not available",
            Duration = 2,
            Icon = "x",
        })
        return
    end

    if not itemPart then
        WindUI:Notify({
            Title = "Error",
            Content = "Cannot locate " .. itemName,
            Duration = 2,
            Icon = "x",
        })
        return
    end

    local targetPos = itemPart.CFrame.Position + Vector3.new(0, 3, 0)
    root.CFrame = CFrame.new(targetPos)

    task.wait(0.2)

    local distance = (root.Position - itemPart.Position).Magnitude

    if distance > prompt.MaxActivationDistance then
        local direction = (itemPart.Position - root.Position).Unit
        local closerPos = itemPart.Position - (direction * (prompt.MaxActivationDistance - 1))
        root.CFrame = CFrame.new(closerPos + Vector3.new(0, 2, 0))
        task.wait(0.1)
    end

    -- MODO DE GRAB
    if State.GrabMode == "Grab mode adaptive mobile" then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    else
        if prompt and prompt:IsDescendantOf(Workspace) then
            local currentDist = (root.Position - itemPart.Position).Magnitude
            if currentDist <= prompt.MaxActivationDistance then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
        end
    end

    task.wait(0.2)

    root.CFrame = originalCFrame

    WindUI:Notify({
        Title = "Grabbed " .. itemName,
        Content = "Successfully picked up " .. itemName,
        Duration = 2,
        Icon = "check",
    })
end

-- ============================================================
-- LOCAL PLAYER FEATURES
-- ============================================================
local TpWalkConn = nil
local NoclipConn = nil
local AntiVoidConn = nil

-- TPWALK
local function StopTpWalk()
    if TpWalkConn then
        TpWalkConn:Disconnect()
        TpWalkConn = nil
    end
end

local function StartTpWalk()
    StopTpWalk()

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    TpWalkConn = RunService.Heartbeat:Connect(function()
        if not State.TpWalkEnabled then return end
        if not hum or not hum.Parent then return end

        local root = hum.Parent:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            root.CFrame = root.CFrame + (moveDir * 0.3)
        end
    end)
end

-- NOCLIP
local function StopNoclip()
    if NoclipConn then
        NoclipConn:Disconnect()
        NoclipConn = nil
    end

    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function StartNoclip()
    StopNoclip()

    NoclipConn = RunService.Stepped:Connect(function()
        if not State.NoclipEnabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

-- ANTI-VOID
local function StopAntiVoid()
    if AntiVoidConn then
        AntiVoidConn:Disconnect()
        AntiVoidConn = nil
    end
end

local function StartAntiVoid()
    StopAntiVoid()

    local lastY = 0
    local fallingSpeed = 0

    AntiVoidConn = RunService.Heartbeat:Connect(function()
        if not State.AntiVoidEnabled then return end

        local root = GetRoot(LocalPlayer)
        if not root then 
            lastY = 0
            return 
        end

        local currentY = root.Position.Y

        if currentY < -100 then
            root.Velocity = Vector3.new(root.Velocity.X, 100, root.Velocity.Z)
            root.CFrame = root.CFrame + Vector3.new(0, 20, 0)

            WindUI:Notify({
                Title = "Anti-Void",
                Content = "Void detected by position! Launching up...",
                Duration = 2,
                Icon = "shield",
            })
            lastY = currentY
            return
        end

        if lastY > 0 then
            local deltaY = currentY - lastY
            if deltaY < -10 then
                fallingSpeed = math.abs(deltaY)

                WindUI:Notify({
                    Title = "Anti-Void",
                    Content = "Void detected! Launching up...",
                    Duration = 1,
                    Icon = "shield",
                })
            end
        end

        lastY = currentY
    end)
end

-- ============================================================
-- AUTO GRAB WATCHER
-- ============================================================
local AutoGrabConn = nil

-- Checa se o item está solto no Workspace (não dentro de nenhum Character)
local function IsItemFreeInWorld(obj)
    if not obj or not obj.Parent then return false end
    local ancestor = obj.Parent
    while ancestor and ancestor ~= game do
        if ancestor == Workspace then return true end
        -- se qualquer ancestral for um Character de player, está no inventário
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character == ancestor then return false end
        end
        ancestor = ancestor.Parent
    end
    return false
end

-- Checa se tem chão abaixo do item (evita spawns no void)
local function HasGroundBelow(obj)
    local part = nil
    if obj:IsA("BasePart") then
        part = obj
    else
        part = obj:FindFirstChildWhichIsA("BasePart", true)
    end
    if not part then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { obj, LocalPlayer.Character or {} }

    local result = Workspace:Raycast(part.Position, Vector3.new(0, -150, 0), params)
    return result ~= nil
end

local function StopAutoGrabWatcher()
    if AutoGrabConn then
        AutoGrabConn:Disconnect()
        AutoGrabConn = nil
    end
end

local function StartAutoGrabWatcher()
    StopAutoGrabWatcher()

    AutoGrabConn = Workspace.DescendantAdded:Connect(function(obj)
        -- Checa o nome antes de qualquer wait para evitar falsos positivos
        local itemName = obj.Name
        local isWatched = false
        for _, w in ipairs(WATCH_ITEMS) do
            if w == itemName then isWatched = true break end
        end
        if not isWatched then return end

        -- Pequena espera para o item se estabilizar
        task.wait(0.1)

        -- Verifica se está solto no mundo (não no inventário/character)
        if not IsItemFreeInWorld(obj) then return end

        -- Verifica se tem chão abaixo (não está no void)
        if not HasGroundBelow(obj) then return end

        local shouldGrab = State.AutoGrabAll or State.AutoGrab[itemName]
        if not shouldGrab then return end

        task.spawn(function()
            task.wait(0.1) -- aguarda ProximityPrompt aparecer
            -- Re-verifica antes de teleportar
            if not IsItemFreeInWorld(obj) then return end
            if not HasGroundBelow(obj) then return end
            GrabItem(itemName)
        end)
    end)
end

local function RefreshAutoGrabWatcher()
    local anyActive = State.AutoGrabAll
    if not anyActive then
        for _, v in pairs(State.AutoGrab) do
            if v then anyActive = true break end
        end
    end
    if anyActive then
        if not AutoGrabConn then StartAutoGrabWatcher() end
    else
        StopAutoGrabWatcher()
    end
end

-- ============================================================
-- INF JUMP
-- ============================================================
local InfJumpConn = nil

local function StopInfJump()
    if InfJumpConn then
        InfJumpConn:Disconnect()
        InfJumpConn = nil
    end
end

local function StartInfJump()
    StopInfJump()

    InfJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
        if not State.InfJumpEnabled then return end

        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- Reseta o estado de queda para permitir novo pulo no ar
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
end

-- ============================================================
-- TABS
-- ============================================================
local TabCombat = Window:Tab({ Title = "Combat", Icon = "swords" })
local TabESP    = Window:Tab({ Title = "ESP", Icon = "eye" })
local TabPickup = Window:Tab({ Title = "Pick Up Items", Icon = "package" })
local TabLocal  = Window:Tab({ Title = "Local Player", Icon = "user" })

-- ============================================================
-- TAB: COMBAT
-- ============================================================
TabCombat:Toggle({
    Title = "Aimbot Players",
    Desc  = "It looks directly at the person you click on if you don't select a target, After 25 seconds with the Aimbot turned on, you can click on another person; otherwise, turn it off and on again",
    Value = false,
    Callback = function(enabled)
        State.AimbotEnabled = enabled
        if enabled then
            State.SelectedTarget = GetPlayerFromEntry(State.SelectedPlayerName)
            StartAimbot()
        else
            StopAimbot()
            State.SelectedTarget = nil
        end
    end,
})

local playerEntries = { "nobody" }
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        table.insert(playerEntries, p.DisplayName .. "(@" .. p.Name .. ")")
    end
end

TabCombat:Dropdown({
    Title  = "Select Target",
    Desc   = "Choose the player for Aimbot to lock onto",
    Values = playerEntries,
    Value  = "nobody",
    Multi  = false,
    Callback = function(value)
        State.SelectedPlayerName = value
        State.SelectedTarget     = GetPlayerFromEntry(value)
    end,
})

TabCombat:Button({
    Title = "Disable Fall Injury",
    Desc  = "Toggles the FallDamage script in your character",
    Callback = function()
        local ok, result = pcall(function()
            return Workspace[LocalPlayer.Name].FallDamage
        end)
        if not ok or not result then
            WindUI:Notify({
                Title    = "Fall Injury",
                Content  = "FallDamage script not found in your character.",
                Duration = 3,
                Icon     = "x",
            })
            return
        end
        if result.Enabled then
            result.Enabled = false
            WindUI:Notify({
                Title    = "Fall Injury",
                Content  = "Fall injury disabled!",
                Duration = 2,
                Icon     = "check",
            })
        else
            result.Enabled = true
            WindUI:Notify({
                Title    = "Fall Injury",
                Content  = "Fall injury re-enabled.",
                Duration = 2,
                Icon     = "check",
            })
        end
    end,
})

-- ============================================================
-- TAB: ESP
-- ============================================================
TabESP:Toggle({
    Title = "ESP Player Highlight",
    Desc  = "Highlights all players in green",
    Value = false,
    Callback = function(enabled)
        State.EspHighlightEnabled = enabled
        if enabled then EnableHighlightESP() else ClearHighlights() end
    end,
})

TabESP:Toggle({
    Title = "ESP Nickname",
    Desc  = "Shows @username",
    Value = false,
    Callback = function(enabled)
        State.EspNicknameEnabled = enabled
        if enabled then EnableNicknameESP() else ClearNicknames() end
    end,
})

-- ============================================================
-- TAB: PICK UP ITEMS
-- ============================================================
TabPickup:Toggle({
    Title = "Notification when the item spawns",
    Desc  = "Notifies when items spawn",
    Value = false,
    Callback = function(enabled)
        State.SpawnNotifyEnabled = enabled
        if enabled then StartSpawnWatcher() else StopSpawnWatcher() end
    end,
})

TabPickup:Dropdown({
    Title  = "Mode",
    Desc   = "Select grab mode: Mobile uses FireServer, PC uses E key",
    Values = { "Grab mode adaptive mobile", "Grab mode Pc adaptive" },
    Value  = "Grab mode adaptive mobile",
    Multi  = false,
    Callback = function(value)
        State.GrabMode = value
        WindUI:Notify({
            Title    = "Grab Mode",
            Content  = "Changed to: " .. value,
            Duration = 1,
            Icon     = "settings",
        })
    end,
})

TabPickup:Button({
    Title    = "Grab Shield",
    Desc     = "Teleports to Shield and grab according to the Grab mode",
    Callback = function() GrabItem("Shield") end,
})

TabPickup:Button({
    Title    = "Grab Katana",
    Desc     = "Teleports to Katana and grab according to the Grab mode",
    Callback = function() GrabItem("Katana") end,
})

TabPickup:Button({
    Title    = "Grab L106 Gun",
    Desc     = "Teleports to L106 and grab according to the Grab mode",
    Callback = function() GrabItem("L106") end,
})

TabPickup:Button({
    Title    = "Grab Knife",
    Desc     = "Teleports to Knife and grab according to the Grab mode",
    Callback = function() GrabItem("Knife") end,
})

TabPickup:Button({
    Title    = "Grab Briefcase",
    Desc     = "Teleports to Briefcase and grab according to the Grab mode",
    Callback = function() GrabItem("Briefcase") end,
})

TabPickup:Button({
    Title    = "Grab Sledge",
    Desc     = "Teleports to Sledge and grab according to the Grab mode",
    Callback = function() GrabItem("Sledge") end,
})

TabPickup:Button({
    Title    = "Grab Vest",
    Desc     = "Teleports to Vest and grab according to the Grab mode",
    Callback = function() GrabItem("Vest") end,
})

TabPickup:Button({
    Title    = "Grab Bandage",
    Desc     = "Teleports to Bandage and grab according to the Grab mode",
    Callback = function() GrabItem("Bandage") end,
})

TabPickup:Section({ Title = "Auto" })

TabPickup:Toggle({
    Title = "Auto Grab Shield",
    Desc  = "Automatically grabs Shield when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrab.Shield = enabled
        RefreshAutoGrabWatcher()
    end,
})

TabPickup:Toggle({
    Title = "Auto Grab Katana",
    Desc  = "Automatically grabs Katana when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrab.Katana = enabled
        RefreshAutoGrabWatcher()
    end,
})

TabPickup:Toggle({
    Title = "Auto Grab L106 Gun",
    Desc  = "Automatically grabs L106 when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrab.L106 = enabled
        RefreshAutoGrabWatcher()
    end,
})

TabPickup:Toggle({
    Title = "Auto Grab Knife",
    Desc  = "Automatically grabs Knife when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrab.Knife = enabled
        RefreshAutoGrabWatcher()
    end,
})

TabPickup:Toggle({
    Title = "Auto Grab Briefcase",
    Desc  = "Automatically grabs Briefcase when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrab.Briefcase = enabled
        RefreshAutoGrabWatcher()
    end,
})

TabPickup:Toggle({
    Title = "Auto Grab Sledge",
    Desc  = "Automatically grabs Sledge when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrab.Sledge = enabled
        RefreshAutoGrabWatcher()
    end,
})

TabPickup:Toggle({
    Title = "Auto Grab Vest",
    Desc  = "Automatically grabs Vest when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrab.Vest = enabled
        RefreshAutoGrabWatcher()
    end,
})

TabPickup:Toggle({
    Title = "Auto Grab Bandage",
    Desc  = "Automatically grabs Bandage when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrab.Bandage = enabled
        RefreshAutoGrabWatcher()
    end,
})

TabPickup:Toggle({
    Title = "Auto Grab All Items",
    Desc  = "Automatically grabs every item when it spawns",
    Value = false,
    Callback = function(enabled)
        State.AutoGrabAll = enabled
        RefreshAutoGrabWatcher()
    end,
})

-- ============================================================
-- TAB: LOCAL PLAYER
-- ============================================================
TabLocal:Toggle({
    Title = "TpWalk 1",
    Desc  = "It makes you a little faster",
    Value = false,
    Callback = function(enabled)
        State.TpWalkEnabled = enabled
        if enabled then
            StartTpWalk()
        else
            StopTpWalk()
        end
    end,
})

TabLocal:Toggle({
    Title = "Noclip",
    Desc  = "Disables collision for your character, allowing you to walk through walls",
    Value = false,
    Callback = function(enabled)
        State.NoclipEnabled = enabled
        if enabled then
            StartNoclip()
        else
            StopNoclip()
        end
    end,
})

TabLocal:Toggle({
    Title = "Anti-Void [Beta]",
    Desc  = "Detects when falling into void and launches you back up at the same speed.",
    Value = false,
    Callback = function(enabled)
        State.AntiVoidEnabled = enabled
        if enabled then
            StartAntiVoid()
        else
            StopAntiVoid()
        end
    end,
})

TabLocal:Toggle({
    Title = "Inf Jump",
    Desc  = "Allows you to jump infinitely in the air",
    Value = false,
    Callback = function(enabled)
        State.InfJumpEnabled = enabled
        if enabled then
            StartInfJump()
        else
            StopInfJump()
        end
    end,
})

-- ============================================================
-- STARTUP NOTIFICATION
-- ============================================================
WindUI:Notify({
    Title    = "The Button",
    Content  = "Script loaded! by: abyssnt",
    Duration = 2,
    Icon     = "check",
})
