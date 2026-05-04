--[[=====================================================================
   Fluxiom RM – Super Anti‑Kick / Anti‑Ban Pack (Adonis‑Ready)
   Compatível com: Adonis, Adonis_2.0, A‑Lite, A‑Secure, A‑Beta
   Requisitos: Executor nível 7+ (hookfunction / hookmetamethod)
=====================================================================]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService") -- só para gerar IDs únicos
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-------------------------------------------------
-- 1️⃣  Variáveis de controle
-------------------------------------------------
local BypassActive = true
local UniqueID = HttpService:GenerateGUID(false) -- ID para debug interno

-------------------------------------------------
-- 2️⃣  Funções auxiliares
-------------------------------------------------
local function isAdonisRemote(remote)
    local name = tostring(remote.Name):lower()
    return name:find("kick") or name:find("ban") or name:find("log") 
        or name:find("detect") or name:find("secure") or name:find("anti")
end

local function isBanGui(gui)
    local name = tostring(gui.Name):lower()
    return name:find("ban") or name:find("kick") or name:find("blacklist")
end

-------------------------------------------------
-- 3️⃣  Hook do __namecall (Remote + Kick)
-------------------------------------------------
local oldNamecall = nil
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Só entra se não for do nosso código (checkcaller == false)
    if not checkcaller() then
        -- ----------- Bloqueio de Kick (Remote) -------------
        if method == "Kick" or method == "kick" then
            warn("[Fluxiom RM] Kick remoto bloqueado!")
            return nil
        end

        -- ----------- Bloqueio de Remotes de Anti‑Cheat ---------
        if method == "FireServer" or method == "InvokeServer" then
            if isAdonisRemote(self) then
                warn("[Fluxiom RM] Remote de Adonis bloqueado: " .. tostring(self.Name))
                return nil
            end
        end
    end

    return oldNamecall(self, ...)
end)

-------------------------------------------------
-- 4️⃣  Hook do método Kick (C‑Level)
-------------------------------------------------
local oldKick = nil
oldKick = hookfunction(LocalPlayer.Kick, function(self, reason)
    if not checkcaller() then
        warn("[Fluxiom RM] Kick direto bloqueado! Motivo: " .. tostring(reason or "sem motivo"))
        return nil
    end
    return oldKick(self, reason)
end)

-------------------------------------------------
-- 5️⃣  Spoof de __index (Health, WalkSpeed, JumpPower)
-------------------------------------------------
local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() then
        -- Bloqueia checagens de saúde que dão 0 e causam kick
        if self:IsA("Humanoid") and key == "Health" then
            -- Se a verificação estiver pedindo saúde, devolve 100
            return 100
        end

        -- Spoof de velocidade (evita detecção de speed hacks)
        if self:IsA("Humanoid") and (key == "WalkSpeed" or key == "JumpPower") then
            if key == "WalkSpeed" then return 16 end
            if key == "JumpPower" then return 50 end
        end
    end
    return oldIndex(self, key)
end)

-------------------------------------------------
-- 6️⃣  Hook de FindFirstChild / GetDescendants (Camuflar objetos)
-------------------------------------------------
local oldFindFirstChild = nil
oldFindFirstChild = hookfunction(game.FindFirstChild, function(self, name, recursive)
    if not checkcaller() then
        local lowered = tostring(name):lower()
        if lowered:find("adonis") or lowered:find("secure") or lowered:find("anticheat") then
            return nil   -- "Esconde" o objeto ao cheat do jogo
        end
    end
    return oldFindFirstChild(self, name, recursive)
end)

local oldGetDescendants = nil
oldGetDescendants = hookfunction(game.GetDescendants, function(self)
    if not checkcaller() then
        local list = oldGetDescendants(self)
        local filtered = {}
        for _,obj in ipairs(list) do
            if not (obj.Name:lower():find("adonis") or obj.Name:lower():find("secure")) then
                table.insert(filtered, obj)
            end
        end
        return filtered
    end
    return oldGetDescendants(self)
end)

-------------------------------------------------
-- 7️⃣  Hook de pcall/xpcall (esconde erro de kick)
-------------------------------------------------
local oldPcall = nil
oldPcall = hookfunction(pcall, function(func, ...)
    if not checkcaller() then
        local info = debug.getinfo(func, "n")
        -- Se a função for algo como "Kick" ou "Ban", mascaramos o erro
        if info and info.name and info.name:lower():find("kick") then
            return true, nil   -- Não gera erro para o script de detecção
        end
    end
    return oldPcall(func, ...)
end)

local oldXpcall = nil
oldXpcall = hookfunction(xpcall, function(func, errhandler, ...)
    if not checkcaller() then
        local info = debug.getinfo(func, "n")
        if info and info.name and info.name:lower():find("kick") then
            return true, nil
        end
    end
    return oldXpcall(func, errhandler, ...)
end)

-------------------------------------------------
-- 8️⃣  Limpeza automática de GUIs de Ban/Kick
-------------------------------------------------
task.spawn(function()
    while BypassActive and task.wait(0.5) do
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if isBanGui(gui) then
                gui:Destroy()
                warn("[Fluxiom RM] GUI de Ban destruída: " .. tostring(gui.Name))
            end
        end
    end
end)

-------------------------------------------------
-- 9️⃣  Mensagem de inicialização
-------------------------------------------------
print("[Fluxiom RM] Super Anti‑Kick/Ban Pack carregado (ID: " .. UniqueID .. ")")
