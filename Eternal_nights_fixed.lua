local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Eternal Nights",
    Author = "by abyssnt",
    Folder = "EternalNights",
    Size = UDim2.fromOffset(580, 460),
    OpenButton = {
        Title = "FNAF: Eternal Nights",
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Color3.fromHex("#3b82f6"), Color3.fromHex("#60a5fa"))
    }
})

Window:Tag({ Title = "V4", Icon = "gamepad-2", Color = Color3.fromHex("#60a5fa") })

local AnimFolder = workspace.Game.Animatronics.Animatronics
local Foxy = AnimFolder:WaitForChild("Foxy")

local Door1 = {
    Buttons = workspace.Game.Sistema.DoorSecurity.PackDoor1.Buttons,
    State = workspace.Game.Sistema.DoorSecurity.PackDoor1.Door.Configurators.State,
    Teleport = CFrame.new(-216,4,151)
}

local Door2 = {
    Buttons = workspace.Game.Sistema.DoorSecurity.PackDoor.Buttons,
    State = workspace.Game.Sistema.DoorSecurity.PackDoor.Door.Configurators.State,
    Teleport = CFrame.new(-203,4,151)
}

local Doors = {Door1, Door2}

local function getHRP()
    return LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
end

local function getPart(model)
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end

local function getPrompt(obj)
    return obj:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local espPlayers, espAnims, espChests = false, false, false
local playerHL, animHL, chestHL = {}, {}, {}

local function clearESP(tbl)
    for _,v in pairs(tbl) do if v then v:Destroy() end end
    table.clear(tbl)
end

RunService.Heartbeat:Connect(function()
    if espPlayers then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                if playerHL[plr] and (not plr.Character or not playerHL[plr].Parent) then
                    playerHL[plr]:Destroy()
                    playerHL[plr] = nil
                end
                if plr.Character and not playerHL[plr] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(0,255,0)
                    hl.OutlineColor = Color3.fromRGB(0,255,0)
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = 0.3
                    hl.Parent = plr.Character
                    playerHL[plr] = hl
                end
            end
        end
    end

    if espAnims then
        for _,anim in ipairs(AnimFolder:GetChildren()) do
            if animHL[anim] and not anim.Parent then
                animHL[anim]:Destroy()
                animHL[anim] = nil
            end
            if not animHL[anim] then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255,0,0)
                hl.OutlineColor = Color3.fromRGB(255,0,0)
                hl.FillTransparency = 1
                hl.OutlineTransparency = 0.4
                hl.Parent = anim
                animHL[anim] = hl
            end
        end
    end
    
    -- ESP CHESTS
    if espChests then
        local chestsFolder = workspace.Map:FindFirstChild("Baus")
        if chestsFolder then
            local bauFolder = chestsFolder:FindFirstChild("Bau")
            if bauFolder then
                for chest, hl in pairs(chestHL) do
                    if not chest.Parent or chest.Parent ~= bauFolder then
                        pcall(function() hl:Destroy() end)
                        chestHL[chest] = nil
                    end
                end
                
                for i = 1, 5 do
                    local chest = bauFolder:GetChildren()[i]
                    if chest and (chest:IsA("Model") or chest:IsA("BasePart")) then
                        if not chestHL[chest] then
                            local hl = Instance.new("Highlight")
                            hl.FillColor = Color3.fromRGB(138, 43, 226)
                            hl.OutlineColor = Color3.fromRGB(138, 43, 226)
                            hl.FillTransparency = 1
                            hl.OutlineTransparency = 0.3
                            hl.Parent = chest
                            chestHL[chest] = hl
                        end
                    end
                end
            end
        end
    else
        for _,hl in pairs(chestHL) do 
            pcall(function() hl:Destroy() end) 
        end 
        table.clear(chestHL)
    end
end)

local autoDoors = false
local doorBusy, doorTimer = {}, {}

RunService.Heartbeat:Connect(function()
    if not autoDoors then return end
    local hrp = getHRP()
    if not hrp then return end

    local dominantMap = {}

    for _,anim in ipairs(AnimFolder:GetChildren()) do
        local animPart = getPart(anim)
        if not animPart then continue end

        local closestDoor, minDist = nil, math.huge
        for i,door in ipairs(Doors) do
            local prompt = getPrompt(door.Buttons)
            if not prompt then continue end

            local d = (animPart.Position - prompt.Parent.Position).Magnitude
            local radius = (anim == Foxy and animPart.AssemblyLinearVelocity.Magnitude > 20) and 45 or 29

            if d <= radius and d < minDist then
                closestDoor = i
                minDist = d
            end
        end

        if closestDoor then
            if not dominantMap[closestDoor] or minDist < dominantMap[closestDoor].dist then
                dominantMap[closestDoor] = {dist = minDist}
            end
        end
    end

    for i,door in ipairs(Doors) do
        doorBusy[i] = doorBusy[i] or false
        doorTimer[i] = doorTimer[i] or 0
        local prompt = getPrompt(door.Buttons)
        if not prompt then continue end
        local originalCF = hrp.CFrame
        local dominant = dominantMap[i]

        if dominant and not door.State.Value and not doorBusy[i] then
            doorBusy[i] = true
            hrp.CFrame = door.Teleport
            task.wait(0.15)
            fireproximityprompt(prompt)
            task.wait(0.15)
            hrp.CFrame = originalCF
            doorBusy[i] = false
            doorTimer[i] = os.clock() + 3
        end

        if not dominant and door.State.Value and os.clock() >= doorTimer[i] and not doorBusy[i] then
            doorBusy[i] = true
            doorTimer[i] = os.clock() + 3
            task.delay(3,function()
                if autoDoors and door.State.Value then
                    hrp.CFrame = door.Teleport
                    task.wait(0.15)
                    fireproximityprompt(prompt)
                    task.wait(0.15)
                    hrp.CFrame = originalCF
                end
                doorBusy[i] = false
            end)
        end
    end
end)

----------------------------------------------------------------
-- AUTO HIDE (DETECTA APENAS ANIMATRONICS EM MOVIMENTO > 1)
----------------------------------------------------------------
local autoHide = false
local hiding = false
local exitStartTime = 0
local wasInDanger = false
local spaceConnection = nil
local hasTeleported = false
local stopSpaceSignal = false
local dangerCheckPos = nil -- FIX: posição original do player quando o perigo foi detectado

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

function resetAutoHide()
    hiding = false
    exitStartTime = 0
    wasInDanger = false
    hasTeleported = false
    stopSpaceSignal = false
    dangerCheckPos = nil -- FIX: limpa a posição salva
    
    if spaceConnection then
        spaceConnection = nil
    end
    
    ReplicatedStorage.Events.Closet:FireServer("SairArmario")
end

RunService.Heartbeat:Connect(function()
    if not autoHide then 
        if hiding then
            resetAutoHide()
        end
        return 
    end
    
    local hrp = getHRP()
    if not hrp then return end

    rayParams.FilterDescendantsInstances = {LP.Character}

    local danger = false

    -- FIX: quando já está escondido, usa a posição original (dangerCheckPos)
    -- em vez da posição atual do armário para checar o perigo.
    -- Isso evita que o animatronic "saia" da zona por causa do teleporte pro armário,
    -- e também evita que armários perto da rota mantenham danger=true eternamente.
    local checkPos = (hiding and dangerCheckPos) or hrp.Position
    
    for _,anim in ipairs(AnimFolder:GetChildren()) do
        local p = getPart(anim)
        if p then
            local velocity = 0
            if p:IsA("BasePart") then
                velocity = p.AssemblyLinearVelocity.Magnitude
            end
            
            if velocity > 1 then
                local dist = (p.Position - checkPos).Magnitude
                
                if dist <= 29 then
                    if not hiding then
                        -- COM wall check (antes de se esconder)
                        local direction = p.Position - hrp.Position
                        local result = workspace:Raycast(hrp.Position, direction, rayParams)
                        
                        if result and result.Instance and result.Instance:IsDescendantOf(anim) then
                            danger = true
                            break
                        end
                    else
                        -- SEM wall check (já escondido) - usa checkPos = dangerCheckPos
                        danger = true
                        break
                    end
                end
            end
        end
    end

    if danger and wasInDanger == false and hiding then
        exitStartTime = 0
    end
    wasInDanger = danger

    if not danger and not hiding then
        hasTeleported = false
    end

    if danger and not hiding and not hasTeleported then
        hiding = true
        hasTeleported = true
        stopSpaceSignal = false
        dangerCheckPos = hrp.Position -- FIX: salva posição ANTES de teleportar pro armário
        
        local closestCloset = nil
        local closestDist = math.huge

        for _,closet in ipairs(workspace.Game.Sistema.Armario.Normal:GetChildren()) do
            local prompts = {}
            for _,desc in ipairs(closet:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    table.insert(prompts, desc)
                end
            end

            if #prompts > 0 then
                local closetPosition
                if closet:IsA("Model") then
                    closetPosition = closet:GetPivot().Position
                elseif closet:IsA("BasePart") then
                    closetPosition = closet.Position
                end

                if closetPosition then
                    local dist = (closetPosition - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestCloset = {model=closet, prompts=prompts, pos=closetPosition}
                    end
                end
            end
        end
        
        if closestCloset then
            hrp.CFrame = CFrame.new(closestCloset.pos + Vector3.new(0, 3, 0))
            task.wait(0.1)
            
            for _,prompt in ipairs(closestCloset.prompts) do
                fireproximityprompt(prompt)
                task.wait(0.05)
            end
            
            -- SPACE: Loop simples
            spaceConnection = task.spawn(function()
                while hiding and autoHide and not stopSpaceSignal do
                    ReplicatedStorage.Events.Closet:FireServer("Space")
                    task.wait(0.01)
                end
            end)
        end
        
    elseif not danger and hiding then
        if exitStartTime == 0 then
            exitStartTime = os.clock()
        end
        
        if os.clock() - exitStartTime >= 3 then
            ReplicatedStorage.Events.Closet:FireServer("SairArmario")
            hiding = false
            stopSpaceSignal = true
            dangerCheckPos = nil -- FIX: limpa ao sair
            
            if spaceConnection then
                spaceConnection = nil
            end
        end
    end
end)

-- tabs abaixo
local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })
local AutoTab = Window:Tab({ Title = "Auto", Icon = "bot" })
local GrabTab = Window:Tab({ Title = "Grab", Icon = "hand" })
local TpTab = Window:Tab({ Title = "Teleports", Icon = "map-pin" })
local PuppetTab = Window:Tab({ Title = "Puppet", Icon = "ghost" })

EspTab:Toggle({ Title = "ESP Players", Desc = "Highlights players in green", Default = false, Callback = function(v) espPlayers = v if not v then clearESP(playerHL) end end })
EspTab:Space()
EspTab:Toggle({ Title = "ESP Animatronics", Desc = "Highlights animatronics in red", Default = false, Callback = function(v) espAnims = v if not v then clearESP(animHL) end end })
EspTab:Space()
EspTab:Toggle({ 
    Title = "ESP Chests", 
    Desc = "Highlights chests in purple", 
    Default = false, 
    Callback = function(v) 
        espChests = v 
        if not v then 
            for _,hl in pairs(chestHL) do 
                pcall(function() hl:Destroy() end) 
            end 
            table.clear(chestHL) 
        end 
    end 
})

AutoTab:Toggle({ Title = "Auto Close Doors [Beta]", Desc = "Auto closes doors when animatronics approach", Default = false, Callback = function(v) autoDoors = v end })
AutoTab:Space()
AutoTab:Toggle({
    Title = "Auto Hide [Beta]",
    Desc = "Auto hides when animatronics approach",
    Default = false,
    Callback = function(v)
        autoHide = v
        if not v and resetAutoHide then
            resetAutoHide()
        end
    end
})

AutoTab:Space()
AutoTab:Button({ Title = "Turn Generator On/Off", Desc = "Toggles generator", Icon = "power", Callback = function()
    local hrp = getHRP()
    local prompt = workspace.Game.Sistema.Gerador.Alavanca.Push.Segurar:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not hrp or not prompt then WindUI:Notify({ Title = "Error", Content = "Generator not found" }) return end
    local oldCF = hrp.CFrame
    hrp.CFrame = CFrame.new(-75,3,153)
    task.wait(0.15)
    fireproximityprompt(prompt)
    task.wait(0.15)
    hrp.CFrame = oldCF
    WindUI:Notify({ Title = "Success", Content = "Generator toggled" })
end })

-- Variáveis de controle
local selectedFuseMode = "security room"

-- Dropdown pra selecionar modo
AutoTab:Dropdown({
    Title = "Select Fuse Location",
    Desc = "Choose where to insert the fuse",
    Values = {"security room", "back room", "Puppet's energy"},
    Value = "security room",
    Callback = function(v)
        selectedFuseMode = v
    end
})

AutoTab:Space()

-- Botão Insert Fuse
AutoTab:Button({
    Title = "Insert Fuse",
    Desc = "Teleports and inserts fuse at selected location",
    Icon = "zap",
    Color = Color3.fromHex("#f59e0b"),
    Callback = function()
        local hrp = getHRP()
        if not hrp then
            WindUI:Notify({ Title = "Error", Content = "Character not found!" })
            return
        end
        
        local oldCF = hrp.CFrame
        local hasFuse = false
        local equippedFuse = nil
        
        -- Método 1: Verifica no Character (já equipado)
        for _,item in ipairs(LP.Character:GetDescendants()) do
            if item.Name == "Fuse" and (item:IsA("Tool") or item:IsA("Model")) then
                hasFuse = true
                equippedFuse = item
                break
            end
        end
        
        -- Método 2: Verifica no Backpack e equipa
        if not hasFuse and LP:FindFirstChild("Backpack") then
            for _,item in ipairs(LP.Backpack:GetDescendants()) do
                if item.Name == "Fuse" and (item:IsA("Tool") or item:IsA("Model")) then
                    -- Tenta equipar
                    pcall(function()
                        item.Parent = LP.Character
                    end)
                    
                    -- Verifica se equipou
                    task.wait(0.1)
                    for _,charItem in ipairs(LP.Character:GetDescendants()) do
                        if charItem.Name == "Fuse" and (charItem:IsA("Tool") or charItem:IsA("Model")) then
                            hasFuse = true
                            equippedFuse = charItem
                            break
                        end
                    end
                    break
                end
            end
        end
        
        -- Se não tem fuse, avisa e retorna
        if not hasFuse then
            WindUI:Notify({ 
                Title = "Error", 
                Content = "There are no fuses in your inventory",
                Icon = "x-circle"
            })
            return
        end
        
        -- Define posição e path baseado no modo selecionado
        local teleportPos = CFrame.new(-76, 3, 149)
        local fusePath = nil
        
        if selectedFuseMode == "security room" then
            fusePath = workspace.Game.Sistema.Gerador.Fusiveis.Body.Fusivel2
        elseif selectedFuseMode == "back room" then
            fusePath = workspace.Game.Sistema.Gerador.Fusiveis.Body.Fusivel3
        elseif selectedFuseMode == "Puppet's energy" then
            fusePath = workspace.Game.Sistema.Gerador.Fusiveis.Body.Fusivel1
        end
        
        -- Verifica se o path existe
        if not fusePath then
            WindUI:Notify({ Title = "Error", Content = "Fuse slot not found!" })
            return
        end
        
        -- Teleporta pra posição
        hrp.CFrame = teleportPos
        task.wait(0.2)
        
        -- Procura o ProximityPrompt no path
        local prompt = fusePath:FindFirstChildWhichIsA("ProximityPrompt", true)
        
        if prompt then
            fireproximityprompt(prompt)
            task.wait(0.2)
            WindUI:Notify({ 
                Title = "Success", 
                Content = "Fuse inserted at " .. selectedFuseMode .. "!"
            })
        else
            WindUI:Notify({ Title = "Error", Content = "ProximityPrompt not found!" })
        end
        
        -- Volta pra posição original
        task.wait(0.1)
        hrp.CFrame = oldCF
        
        -- Aviso final
        WindUI:Notify({ 
            Title = "Note", 
            Content = "In case you don't have a fuse in your inventory or anyone to make it work",
            Icon = "info",
            Duration = 1
        })
    end
})

AutoTab:Space()

-- Aviso abaixo do botão
AutoTab:Paragraph({
    Title = "Important Note",
    Desc = "In case you don't have a fuse in your inventory or anyone to make it work",
    Image = "",
    Thumbnail = "",
    ImageSize = 0,
    Buttons = {}
})

-- CORRIGIDO - Teleporta até o ProximityPrompt do Fuse (Apenas Raiz do Workspace)
GrabTab:Button({ 
    Title = "Grab Fuse", 
    Desc = "Grabs all fuses available", 
    Icon = "zap", 
    Callback = function()
        local hrp = getHRP()
        if not hrp then 
            WindUI:Notify({ Title = "Error", Content = "Character not found!" }) 
            return 
        end
        
        local count = 0
        
        for _, fuse in ipairs(workspace:GetChildren()) do 
            if fuse.Name == "Fuse" and (fuse:IsA("Model") or fuse:IsA("BasePart") or fuse:IsA("Part")) then 
                local oldCF = hrp.CFrame
                local prompt = fuse:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
                    hrp.CFrame = CFrame.new(prompt.Parent.Position + Vector3.new(0, 3, 0))
                    task.wait(0.10)
                    
                    for i = 1, 3 do
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                    end
                    
                    task.wait(0.2)
                    hrp.CFrame = oldCF
                    count = count + 1
                end
                
                task.wait(0.2)
            end 
        end
        
        if count > 0 then
            WindUI:Notify({ Title = "Success", Content = "Collected " .. count .. " fuses!" })
        else
            WindUI:Notify({ Title = "Error", Content = "No fuses found! Check if they spawned." })
        end
    end 
})
                
GrabTab:Space()
GrabTab:Button({ Title = "Grab Screwdriver", Desc = "Grabs screwdriver", Icon = "wrench", Callback = function()
    local hrp = getHRP()
    if not hrp then return end
    local screwdriver = workspace:FindFirstChild("Phillips screwdriver")
    if not screwdriver then WindUI:Notify({ Title = "Error", Content = "Screwdriver not found" }) return end
    local prompt, part = getPrompt(screwdriver), getPart(screwdriver)
    if not prompt or not part then WindUI:Notify({ Title = "Error", Content = "Cannot interact" }) return end
    local oldCF = hrp.CFrame
    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0))
    task.wait(0.15)
    for i=1,3 do fireproximityprompt(prompt) task.wait(0.1) end
    task.wait(0.2)
    hrp.CFrame = oldCF
    WindUI:Notify({ Title = "Success", Content = "Screwdriver collected" })
end })
GrabTab:Space()
GrabTab:Button({ Title = "Grab Battery", Desc = "Grabs battery", Icon = "battery", Callback = function()
    local hrp = getHRP()
    if not hrp then return end
    local battery = workspace:FindFirstChild("Battery")
    if not battery then WindUI:Notify({ Title = "Error", Content = "Battery not found" }) return end
    local prompt = getPrompt(battery)
    if not prompt then WindUI:Notify({ Title = "Error", Content = "Prompt not found" }) return end
    local targetPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
    if not targetPart then WindUI:Notify({ Title = "Error", Content = "No BasePart found" }) return end
    local oldCF = hrp.CFrame
    hrp.CFrame = CFrame.new(targetPart.Position + Vector3.new(0,3,0))
    task.wait(0.15)
    for i=1,3 do fireproximityprompt(prompt) task.wait(0.1) end
    task.wait(0.2)
    hrp.CFrame = oldCF
    WindUI:Notify({ Title = "Success", Content = "Battery collected" })
end })
GrabTab:Space()

-- BOTÃO GRAB PLIERS
GrabTab:Button({ 
    Title = "Grab Pliers", 
    Desc = "Grabs pliers", 
    Icon = "wrench", 
    Callback = function()
        local hrp = getHRP()
        if not hrp then 
            WindUI:Notify({ Title = "Error", Content = "Character not found!" }) 
            return 
        end
        
        for _, item in ipairs(workspace:GetChildren()) do 
            if item.Name == "Pliers" and (item:IsA("Model") or item:IsA("BasePart") or item:IsA("Part")) then 
                local oldCF = hrp.CFrame
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
                    hrp.CFrame = CFrame.new(prompt.Parent.Position + Vector3.new(0, 3, 0))
                    task.wait(0.10)
                    
                    for i = 1, 3 do
                        fireproximityprompt(prompt)
                        task.wait(0.1)
                    end
                    
                    task.wait(0.2)
                    hrp.CFrame = oldCF
                    
                    WindUI:Notify({ Title = "Success", Content = "Pliers collected!" })
                    return
                end
            end 
        end
        
        WindUI:Notify({ Title = "Error", Content = "No pliers found!" })
    end 
})

GrabTab:Space()

-- BOTÃO GRAB OLD LANTERN
GrabTab:Button({ 
    Title = "Grab Old Lantern", 
    Desc = "Grabs the old lantern", 
    Icon = "flashlight", 
    Callback = function()
        local hrp = getHRP()
        if not hrp then 
            WindUI:Notify({ Title = "Error", Content = "Character not found!" }) 
            return 
        end
        
        local lanternFolder = workspace:FindFirstChild("OldFlashlight")
        if not lanternFolder then
            WindUI:Notify({ Title = "Error", Content = "Old lantern not found!" })
            return
        end
        
        local prompt = lanternFolder:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not prompt or not prompt.Parent or not prompt.Parent:IsA("BasePart") then
            WindUI:Notify({ Title = "Error", Content = "Prompt not found!" })
            return
        end
        
        local oldCF = hrp.CFrame
        hrp.CFrame = CFrame.new(prompt.Parent.Position + Vector3.new(0, 3, 0))
        task.wait(0.15)
        
        fireproximityprompt(prompt)
        
        task.wait(0.2)
        hrp.CFrame = oldCF
        
        WindUI:Notify({ Title = "Success", Content = "Old lantern collected!" })
    end 
})

TpTab:Button({ Title = "TP Security Room", Desc = "Teleports to security room", Icon = "shield", Callback = function()
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(-209,4,152) WindUI:Notify({ Title = "Teleport", Content = "Teleported to Security Room" }) end
end })
TpTab:Space()
TpTab:Button({ Title = "TP Generator", Desc = "Teleports to generator", Icon = "power", Callback = function()
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(-75,3,151) WindUI:Notify({ Title = "Teleport", Content = "Teleported to Generator" }) end
end })
TpTab:Space()
TpTab:Button({ 
    Title = "Teleport for the Safe Zone", 
    Desc = "Teleports to safe position", 
    Icon = "shield-check", 
    Callback = function()
        local hrp = getHRP()
        if hrp then 
            hrp.CFrame = CFrame.new(2, 3, -137) 
            WindUI:Notify({ Title = "Teleport", Content = "Teleported to Safe Zone!" })
        end
    end 
})
TpTab:Space()
TpTab:Button({ 
    Title = "Delete Anti-Teleport System", 
    Desc = "Removes teleport return system", 
    Icon = "trash-2", 
    Color = Color3.fromHex("#ef4444"),
    Callback = function()
        local antiTp = workspace.Map:FindFirstChild("TeleportReturn")
        if antiTp then
            antiTp:Destroy()
            WindUI:Notify({ Title = "Success", Content = "Anti-teleport system deleted!" })
        else
            WindUI:Notify({ Title = "Error", Content = "Anti-teleport system not found!" })
        end
    end 
})

----------------------------------------------------------------
-- PUPPET TAB (CORRIGIDO - REMOTE REALMENTE EM LOOP POR 15 SEGUNDOS)
----------------------------------------------------------------
local puppetMode = "Remote"
local puppetTeleportCF = CFrame.new(-116,4,-9)
local PuppetButtonsFolder = workspace.Game.Sistema.Puppet.Door.Button
local puppetRecharging = false
local cancelRecharge = false
local currentRechargeThread = nil

local function getNearestPuppetPrompt()
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    for _,obj in ipairs(PuppetButtonsFolder:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local d = (obj.Parent.Position - hrp.Position).Magnitude
            if d < dist then dist, closest = d, obj end
        end
    end
    return closest
end

PuppetTab:Dropdown({
    Title = "Recharge Mode",
    Desc = "Select recharge mode",
    Values = {"Remote", "Inf recharge"},
    Value = "Remote",
    Callback = function(v) 
        if puppetRecharging and v ~= puppetMode then
            cancelRecharge = true
            task.wait(0.2)
        end
        puppetMode = v 
    end
})

PuppetTab:Space()

PuppetTab:Button({
    Title = "Recharge Puppet",
    Desc = "Recharges puppet",
    Icon = "refresh-cw",
    Callback = function()
        if puppetRecharging then
            WindUI:Notify({ 
                Title = "Wait", 
                Content = "Recharge in progress!",
                Icon = "alert-triangle"
            })
            return
        end

        puppetRecharging = true
        cancelRecharge = false

        if puppetMode == "Remote" then
            -- REMOTE CORRIGIDO: Loop garantido por 15 segundos
            local start = os.clock()
            local count = 0
            
            currentRechargeThread = task.spawn(function()
                -- Loop enquanto nao passar 15 segundos E nao for cancelado
                while (os.clock() - start < 15) and not cancelRecharge do
                    -- Envia 5 eventos rapido
                    for i = 1, 5 do
                        if cancelRecharge then break end
                        ReplicatedStorage.Events.Cameras:FireServer("PuppetCharge")
                        count = count + 1
                    end
                    
                    -- Pequena pausa para nao travar (0.05s = 20 ciclos por segundo)
                    task.wait(0.05)
                end
                
                puppetRecharging = false
                currentRechargeThread = nil
                
                if cancelRecharge then
                    WindUI:Notify({ 
                        Title = "Cancelled", 
                        Content = "Recharge cancelled after " .. count .. " charges",
                        Icon = "x-circle"
                    })
                else
                    WindUI:Notify({ 
                        Title = "Success", 
                        Content = "Puppet recharged Please check if it worked /Total: " .. count .. " charges",
                        Icon = "check"
                    })
                end
            end)
            
        else
            -- INF RECHARGE
            local hrp = getHRP()
            local prompt = getNearestPuppetPrompt()
            
            if not hrp or not prompt then 
                WindUI:Notify({ 
                    Title = "Error", 
                    Content = "HRP or Prompt not found",
                    Icon = "x-circle"
                })
                puppetRecharging = false
                return 
            end

            local oldCF = hrp.CFrame
            
            currentRechargeThread = task.spawn(function()
                hrp.CFrame = puppetTeleportCF
                task.wait(0.15)
                
                if cancelRecharge then
                    hrp.CFrame = oldCF
                    puppetRecharging = false
                    currentRechargeThread = nil
                    WindUI:Notify({ 
                        Title = "Cancelled", 
                        Content = "Recharge cancelled during teleport",
                        Icon = "x-circle"
                    })
                    return
                end
                
                fireproximityprompt(prompt, 0)
                task.wait(0.15)
                
                if cancelRecharge then
                    hrp.CFrame = oldCF
                    puppetRecharging = false
                    currentRechargeThread = nil
                    WindUI:Notify({ 
                        Title = "Cancelled", 
                        Content = "Recharge cancelled",
                        Icon = "x-circle"
                    })
                    return
                end
                
                hrp.CFrame = oldCF
                puppetRecharging = false
                currentRechargeThread = nil
                
                WindUI:Notify({ 
                    Title = "Success", 
                    Content = "activated/ may stop working if a player goes to the button and press",
                    Icon = "check"
                })
            end)
        end
    end
})

----------------------------------------------------------------
-- COINS TAB (AUTOMÁTICO - CONTADOR NO TOPO)
----------------------------------------------------------------
local CoinsTab = Window:Tab({ Title = "Coins", Icon = "coins" })
local CoinsFolder = workspace.Map.CoinsMap

-- Contador de moedas
local currentCoinCount = 0
local CounterParagraph = nil

local function countCoins()
    local count = 0
    for _,obj in ipairs(CoinsFolder:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            count = count + 1
        end
    end
    return count
end

-- Cria contador no TOPO (primeiro elemento)
currentCoinCount = countCoins()

CounterParagraph = CoinsTab:Paragraph({
    Title = "💰 Coins on map: " .. currentCoinCount,
    Desc = "Auto-updating...",
    Image = "",
    Thumbnail = "",
    ImageSize = 0,
    Buttons = {}
})

-- Atualização automática a cada 2 segundos
task.spawn(function()
    while true do
        task.wait(2)
        
        local newCount = countCoins()
        if newCount ~= currentCoinCount then
            currentCoinCount = newCount
            
            -- Destrói e recria o paragraph com novo valor
            pcall(function() CounterParagraph:Destroy() end)
            task.wait(0.1)
            
            -- Recria no topo (primeiro elemento da tab)
            CounterParagraph = CoinsTab:Paragraph({
                Title = "💰 Coins on map: " .. currentCoinCount,
                Desc = "Auto-updating...",
                Image = "",
                Thumbnail = "",
                ImageSize = 0,
                Buttons = {}
            })
        end
    end
end)

CoinsTab:Space()

-- Botão Take Only 1 Coin
CoinsTab:Button({
    Title = "Take Only 1 Coin",
    Desc = "Teleports to 1 coin and collects it",
    Icon = "mouse-pointer-click",
    Callback = function()
        local hrp = getHRP()
        if not hrp then WindUI:Notify({ Title = "Error", Content = "Character not found" }) return end
        
        local coins = {}
        for _,obj in ipairs(CoinsFolder:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                table.insert(coins, obj)
            end
        end
        
        if #coins == 0 then
            WindUI:Notify({ Title = "Error", Content = "No coins found!" })
            return
        end
        
        local closest, minDist = nil, math.huge
        local hrpPos = hrp.Position
        
        for _,prompt in ipairs(coins) do
            local parent = prompt.Parent
            local pos
            if parent:IsA("BasePart") then
                pos = parent.Position
            elseif parent:IsA("Model") and parent:GetPivot() then
                pos = parent:GetPivot().Position
            else
                continue
            end
            
            local dist = (pos - hrpPos).Magnitude
            if dist < minDist then
                minDist = dist
                closest = {prompt = prompt, pos = pos}
            end
        end
        
        if not closest then
            WindUI:Notify({ Title = "Error", Content = "Could not find valid coin" })
            return
        end
        
        local oldCF = hrp.CFrame
        hrp.CFrame = CFrame.new(closest.pos + Vector3.new(0, 3, 0))
        task.wait(0.15)
        fireproximityprompt(closest.prompt)
        task.wait(0.2)
        hrp.CFrame = oldCF
        
        -- Atualiza imediatamente após coletar
        currentCoinCount = countCoins()
        pcall(function() CounterParagraph:Destroy() end)
        task.wait(0.1)
        CounterParagraph = CoinsTab:Paragraph({
            Title = "💰 Coins on map: " .. currentCoinCount,
            Desc = "Auto-updating...",
            Image = "",
            Thumbnail = "",
            ImageSize = 0,
            Buttons = {}
        })
        
        WindUI:Notify({ Title = "Success", Content = "1 coin collected! Remaining: " .. currentCoinCount })
    end
})

CoinsTab:Space()

-- Botão Collect All Coins
local collectingAll = false

CoinsTab:Button({
    Title = "Collect All Coins",
    Desc = "Teleports to all coins and collects them",
    Icon = "sparkles",
    Color = Color3.fromHex("#22c55e"),
    Callback = function()
        if collectingAll then
            collectingAll = false
            WindUI:Notify({ Title = "Stopped", Content = "Collection cancelled!" })
            return
        end
        
        local hrp = getHRP()
        if not hrp then WindUI:Notify({ Title = "Error", Content = "Character not found" }) return end
        
        collectingAll = true
        
        task.spawn(function()
            local collected = 0
            local oldCF = hrp.CFrame
            local startTime = os.clock()
            
            while collectingAll and (os.clock() - startTime < 60) do
                local coins = {}
                for _,obj in ipairs(CoinsFolder:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        table.insert(coins, obj)
                    end
                end
                
                if #coins == 0 then break end
                
                local closest, minDist = nil, math.huge
                local hrpPos = hrp.Position
                
                for _,prompt in ipairs(coins) do
                    local parent = prompt.Parent
                    local pos
                    if parent:IsA("BasePart") then
                        pos = parent.Position
                    elseif parent:IsA("Model") and parent:GetPivot() then
                        pos = parent:GetPivot().Position
                    else
                        continue
                    end
                    
                    local dist = (pos - hrpPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = {prompt = prompt, pos = pos}
                    end
                end
                
                if not closest then
                    task.wait(0.1)
                    continue
                end
                
                hrp.CFrame = CFrame.new(closest.pos + Vector3.new(0, 3, 0))
                task.wait(0.1)
                fireproximityprompt(closest.prompt)
                task.wait(0.15)
                
                collected = collected + 1
                
                if collected % 5 == 0 then
                    WindUI:Notify({ Title = "Collecting...", Content = collected .. " coins!" })
                end
            end
            
            hrp.CFrame = oldCF
            collectingAll = false
            
            -- Atualiza imediatamente após terminar
            currentCoinCount = countCoins()
            pcall(function() CounterParagraph:Destroy() end)
            task.wait(0.1)
            CounterParagraph = CoinsTab:Paragraph({
                Title = "💰 Coins on map: " .. currentCoinCount,
                Desc = "Auto-updating...",
                Image = "",
                Thumbnail = "",
                ImageSize = 0,
                Buttons = {}
            })
            
            WindUI:Notify({ 
                Title = "Success", 
                Content = "Collected " .. collected .. "! Remaining: " .. currentCoinCount,
                Icon = "check"
            })
        end)
    end
})
