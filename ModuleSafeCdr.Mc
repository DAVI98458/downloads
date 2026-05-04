--[[=====================================================================
   Fluxiom RM – Anti‑Kick/Ban Light (compatível com Adonis)
   Versão otimizada: menos overhead, sem travamentos.
   Requisitos: Executor nível 7+ (hookfunction / hookmetamethod)
=====================================================================]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

--=====================================================================
-- 1️⃣ Configurações
--=====================================================================
local DEBUG = true                 -- true → prints no console, false → silêncio total
local DEBOUNCE_TIME = 0.2          -- segundos entre verificações de GUI
local ACTIVE = true                -- controla o ciclo de limpeza de GUIs

local function log(...)
    if DEBUG then
        print("[Fluxiom RM] ", ...)
    end
end

--=====================================================================
-- 2️⃣ Funções auxiliares
--=====================================================================
local function isAdonisRemote(remote)
    local n = tostring(remote.Name):lower()
    return n:find("kick") or n:find("ban") or n:find("log") or n:find("detect") or n:find("secure")
end

local function isBanGui(gui)
    local n = tostring(gui.Name):lower()
    return n:find("ban") or n:find("kick") or n:find("blacklist")
end

--=====================================================================
-- 3️⃣ Hook __namecall (Remote + Kick)
--=====================================================================
local oldNamecall = nil
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() then
        -- ---- Bloqueio de Kick via Remote ----
        if method == "Kick" or method == "kick" then
            log("Kick remoto bloqueado! Motivo:", tostring(args[1] or "Nenhum"))
            return nil
        end

        -- ---- Bloqueio de Remotes de Anti‑Cheat ----
        if method == "FireServer" or method == "InvokeServer" then
            if isAdonisRemote(self) then
                log("Remote Adonis bloqueado:", self:GetFullName())
                return nil
            end
        end
    end

    return oldNamecall(self, ...)
end)

--=====================================================================
-- 4️⃣ Hook função Kick (C‑Level) – protege contra chamadas diretas
--=====================================================================
local oldKick = nil
oldKick = hookfunction(LocalPlayer.Kick, function(self, reason)
    if not checkcaller() then
        log("Kick direto bloqueado! Motivo:", tostring(reason or "Nenhum"))
        return nil
    end
    return oldKick(self, reason)
end)

--=====================================================================
-- 5️⃣ Spoof de __index (Health, WalkSpeed, JumpPower)
--=====================================================================
local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() then
        if self:IsA("Humanoid") then
            if key == "Health" then
                return 100               -- nunca deixa o AC ver 0
            elseif key == "WalkSpeed" then
                return 16                -- padrão Roblox
            elseif key == "JumpPower" then
                return 50                -- padrão Roblox
            end
        end
    end
    return oldIndex(self, key)
end)

--=====================================================================
-- 6️⃣ Hook FindFirstChild / GetDescendants (esconde objetos Adonis)
--=====================================================================
local oldFindFirstChild = nil
oldFindFirstChild = hookfunction(game.FindFirstChild, function(self, name, recursive)
    if not checkcaller() then
        local lowered = tostring(name):lower()
        if lowered:find("adonis") or lowered:find("secure") or lowered:find("anticheat") then
            return nil
        end
    end
    return oldFindFirstChild(self, name, recursive)
end)

local oldGetDescendants = nil
oldGetDescendants = hookfunction(game.GetDescendants, function(self)
    if not checkcaller() then
        local all = oldGetDescendants(self)
        local filtered = {}
        for _,obj in ipairs(all) do
            local n = obj.Name:lower()
            if not (n:find("adonis") or n:find("secure")) then
                table.insert(filtered, obj)
            end
        end
        return filtered
    end
    return oldGetDescendants(self)
end)

--=====================================================================
-- 7️⃣ Proteção contra pcall/xpcall usados pelo Adonis para esconder erros
--=====================================================================
local oldPcall = nil
oldPcall = hookfunction(pcall, function(func, ...)
    if not checkcaller() then
        local info = debug.getinfo(func, "n")
        if info and info.name and info.name:lower():find("kick") then
            return true, nil               -- finge que tudo deu ok
        end
    end
    return oldPcall(func, ...)
end)

local oldXpcall = nil
oldXpcall = hookfunction(xpcall, function(func, errHandler, ...)
    if not checkcaller() then
        local info = debug.getinfo(func, "n")
        if info and info.name and info.name:lower():find("kick") then
            return true, nil
        end
    end
    return oldXpcall(func, errHandler, ...)
end)

--=====================================================================
-- 8️⃣ Loop de limpeza de GUIs de Ban/Kick (com debounce)
--=====================================================================
local lastClean = 0
RunService.Heartbeat:Connect(function()
    if not ACTIVE then return end
    if tick() - lastClean < DEBOUNCE_TIME then return end

    lastClean = tick()
    for _,gui in ipairs(PlayerGui:GetChildren()) do
        if isBanGui(gui) then
            gui:Destroy()
            log("GUI de Ban removida:", gui.Name)
        end
    end
end)

--=====================================================================
-- 9️⃣ Mensagem final
--=====================================================================
log("✅ Anti‑Kick/Ban Light carregado (ID:", HttpService:GenerateGUID(false), ")")
