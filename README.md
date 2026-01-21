--==================================================
-- DRAWING API ESP (BOX 2D - WALLHACK REAL)
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local ESPObjects = {}

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end

    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(0, 255, 0)
    box.Thickness = 1
    box.Filled = false
    box.Visible = false

    ESPObjects[player] = box
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Remove()
        ESPObjects[player] = nil
    end
end

-- Criar ESP inicial
for _,plr in ipairs(Players:GetPlayers()) do
    CreateESP(plr)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Atualização contínua
RunService.RenderStepped:Connect(function()
    for player,box in pairs(ESPObjects) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not hrp or not humanoid or humanoid.Health <= 0 then
            box.Visible = false
            continue
        end

        local pos, onScreen, depth = WorldToScreen(hrp.Position)
        if not onScreen or depth < 0 then
            box.Visible = false
            continue
        end

        -- Escala baseada na distância (estável)
        local scale = math.clamp(300 / depth, 2, 6)
        local width = 15 * scale
        local height =  20* scale

        box.Size = Vector2.new(width, height)
        box.Position = Vector2.new(
            pos.X - width / 2,
            pos.Y - height / 2
        )

        box.Visible = true
    end
end)
