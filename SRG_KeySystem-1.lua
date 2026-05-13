--// SRG Key System — HWID-bound keys
--// Get your key at: randomscripts364.github.io/verified/

local KEY_FILE = "srg_key.txt"

local Scripts = {
    ["92416817362629"]  = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/The%20Button",
    ["100255403764514"] = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/memory%203",
    ["125998488582708"] = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/Eternal%20nights",
    ["13803700382"]     = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/Fnaf%20Doom3",
    ["13803700135"]     = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/Fnaf%20Doom1",
    ["114413950886998"] = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/Fatal%20Floor",
    ["12497348201"]     = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/Fnaf%20coop",
    ["14896802601"]     = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/RMUH%20BETA",
    ["16667550979"]     = "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/Night%202",
    ["140260816701736"] = {
        "https://api.junkie-development.de/api/v1/luascripts/public/82a88dd956eefd8282330506b0b50762b661e3506208eed8de60a7ac7aed6ff5/download",
        "https://raw.githubusercontent.com/DAVI98458/Nicescript/refs/heads/main/CABINS%2BSafeZone"
    }
}

local TweenService   = game:GetService("TweenService")
local CoreGui        = game:GetService("CoreGui")
local CurrentPlaceId = tostring(game.PlaceId)
local HasScript      = Scripts[CurrentPlaceId] ~= nil

local fGetHwid = gethwid or getdeviceid or GetHWID or getmachineuid
    or function() return tostring(game:GetService("Players").LocalPlayer.UserId) end

repeat task.wait(1) until game:IsLoaded()

-- ══════════════════════════════════════════
--  KEY SAVE / LOAD
-- ══════════════════════════════════════════
local function saveKey(key)
    pcall(function() writefile(KEY_FILE, key) end)
end

local function loadSavedKey()
    local ok, val = pcall(function() return readfile(KEY_FILE) end)
    if ok and val and val ~= "" then return val end
    return nil
end

-- ══════════════════════════════════════════
--  HWID HASH — matches website JS exactly
--  h = (h * 31 + charcode) % (36^6)
--  result as 6-char uppercase base36
-- ══════════════════════════════════════════
local B36      = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local HWID_MOD = 36 ^ 6  -- 2176782336

local function toBase36(n)
    if n == 0 then return "0" end
    local s = ""
    while n > 0 do
        s = B36:sub((n % 36) + 1, (n % 36) + 1) .. s
        n = math.floor(n / 36)
    end
    return s
end

local function fromBase36(s)
    local n = 0
    for i = 1, #s do
        local c = s:sub(i, i):upper()
        local v = B36:find(c, 1, true)
        if not v then return nil end
        n = n * 36 + (v - 1)
    end
    return n
end

local function hwidHash(str)
    local h = 0
    for i = 1, #str do
        h = (h * 31 + str:byte(i)) % HWID_MOD
    end
    local result = toBase36(h)
    -- pad to 6 chars
    while #result < 6 do result = "0" .. result end
    return result
end

-- ══════════════════════════════════════════
--  VERIFY KEY
--  Format: SRG-[DAY_B36][CHECKSUM]-[HWIDHASH6]-[RAND4]
-- ══════════════════════════════════════════
local function verifyKey(key)
    if type(key) ~= "string" then return false end

    -- must match SRG-XXXXX-YYYYYY-ZZZZ
    local dayPart, hwidPart, rand = key:match("^SRG%-([A-Z0-9]+)%-([A-Z0-9]+)%-([A-Z0-9]+)$")
    if not dayPart or not hwidPart or not rand then return false end
    if #hwidPart ~= 6 or #rand ~= 4 then return false end

    -- split checksum from day string
    local dayStr   = dayPart:sub(1, -2)
    local checkChar = dayPart:sub(-1):upper()

    -- decode day
    local keyDay = fromBase36(dayStr)
    if not keyDay then return false end

    -- accept today or yesterday (timezone tolerance)
    local currentDay = math.floor(os.time() / 86400)
    if math.abs(currentDay - keyDay) > 1 then return false end

    -- verify day checksum
    local sum = 0
    for i = 1, #dayStr do sum = sum + dayStr:byte(i) end
    local expectedCheck = B36:sub((sum % 36) + 1, (sum % 36) + 1)
    if checkChar ~= expectedCheck then return false end

    -- verify HWID hash
    local myHwid     = tostring(pcall(fGetHwid) and fGetHwid() or "")
    local myHwidHash = hwidHash(myHwid)
    if hwidPart ~= myHwidHash then return false end

    return true
end

-- ══════════════════════════════════════════
--  RUN SCRIPT
-- ══════════════════════════════════════════
local function runScript()
    local s = Scripts[CurrentPlaceId]
    if type(s) == "table" then
        for _, url in ipairs(s) do
            pcall(function() loadstring(game:HttpGet(url, true))() end)
        end
    else
        pcall(function() loadstring(game:HttpGet(s, true))() end)
    end
end

-- ══════════════════════════════════════════
--  NO SCRIPT NOTIFICATION
-- ══════════════════════════════════════════
local function showNoScriptMessage()
    if CoreGui:FindFirstChild("ScriptonNotif") then CoreGui.ScriptonNotif:Destroy() end

    local sg    = Instance.new("ScreenGui")
    sg.Name         = "ScriptonNotif"
    sg.ResetOnSpawn = false
    sg.Parent       = CoreGui

    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(0, 510, 0, 80)
    frame.Position         = UDim2.new(0.5, -255, -0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    frame.BorderSizePixel  = 0
    frame.Parent           = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke")
    stroke.Color     = Color3.fromRGB(220, 60, 60)
    stroke.Thickness = 1.5
    stroke.Parent    = frame

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 60, 1, 0); icon.Position = UDim2.new(0, 4, 0, 0)
    icon.BackgroundTransparency = 1; icon.Text = "⚠️"
    icon.TextScaled = true; icon.Font = Enum.Font.GothamBold; icon.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -72, 1, 0); label.Position = UDim2.new(0, 66, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "No scripts are available in this game,\nmaybe you're in the wrong game or lobby."
    label.TextColor3 = Color3.fromRGB(220, 220, 235); label.TextScaled = true
    label.Font = Enum.Font.Gotham; label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    TweenService:Create(frame, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -255, 0.07, 0) }):Play()

    task.delay(6, function()
        local t = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(frame,  t, { Position = UDim2.new(0.5, -255, -0.15, 0) }):Play()
        TweenService:Create(frame,  t, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(stroke, t, { Transparency = 1 }):Play()
        TweenService:Create(icon,   t, { TextTransparency = 1 }):Play()
        local tOut = TweenService:Create(label, t, { TextTransparency = 1 })
        tOut:Play(); tOut.Completed:Connect(function() sg:Destroy() end)
    end)
end

-- ══════════════════════════════════════════
--  KEY UI
-- ══════════════════════════════════════════
local function buildKeyUI()
    if CoreGui:FindFirstChild("SRGKeyUI") then CoreGui.SRGKeyUI:Destroy() end

    local myHwid = "NO_HWID"
    pcall(function() myHwid = tostring(fGetHwid()) end)

    local siteUrl = "https://randomscripts364.github.io/verified/"

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name            = "SRGKeyUI"
    screenGui.ResetOnSpawn    = false
    screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    screenGui.Parent          = CoreGui

    -- semi-transparent overlay
    local overlay = Instance.new("Frame")
    overlay.Size                  = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel       = 0
    overlay.ZIndex                = 1
    overlay.Parent                = screenGui

    -- card  (400 × 285, centered)
    local CW, CH = 400, 285
    local card = Instance.new("Frame")
    card.Size                  = UDim2.new(0, 0, 0, 0)
    card.Position              = UDim2.new(0.5, 0, 0.5, 0)
    card.BackgroundColor3      = Color3.fromRGB(10, 18, 34)
    card.BackgroundTransparency = 0
    card.BorderSizePixel       = 0
    card.ZIndex                = 2
    card.Parent                = screenGui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

    local border = Instance.new("UIStroke")
    border.Color     = Color3.fromRGB(40, 100, 200)
    border.Thickness = 1.5
    border.Parent    = card

    -- top accent line
    local accent = Instance.new("Frame")
    accent.Size             = UDim2.new(1, 0, 0, 3)
    accent.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    accent.BorderSizePixel  = 0
    accent.ZIndex           = 3
    accent.Parent           = card
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 16)

    local function lbl(txt, y, sz, col, bold)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -32, 0, sz + 6)
        l.Position = UDim2.new(0, 16, 0, y)
        l.Text = txt
        l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextSize = sz
        l.TextColor3 = col
        l.BackgroundTransparency = 1
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 3
        l.Parent = card
        return l
    end

    lbl("🔑  SRG Key System", 16, 16, Color3.fromRGB(255,255,255), true)
    lbl(
        HasScript and "✔  Script available for this game" or "✘  No script for this game",
        44, 11,
        HasScript and Color3.fromRGB(74,222,128) or Color3.fromRGB(248,113,113),
        false
    )

    -- divider
    local function div(y)
        local d = Instance.new("Frame")
        d.Size = UDim2.new(1,-32,0,1); d.Position = UDim2.new(0,16,0,y)
        d.BackgroundColor3 = Color3.fromRGB(25,45,85); d.BorderSizePixel = 0
        d.ZIndex = 3; d.Parent = card
    end
    div(66)

    lbl("Paste your key below:", 76, 11, Color3.fromRGB(140,165,210), false)

    -- key input
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1,-32,0,36); keyBox.Position = UDim2.new(0,16,0,96)
    keyBox.PlaceholderText = "SRG-XXXXX-XXXXXX-XXXX"
    keyBox.PlaceholderColor3 = Color3.fromRGB(60,85,130)
    keyBox.Text = ""; keyBox.Font = Enum.Font.Gotham; keyBox.TextSize = 12
    keyBox.TextColor3 = Color3.fromRGB(255,255,255)
    keyBox.BackgroundColor3 = Color3.fromRGB(14,26,50)
    keyBox.BackgroundTransparency = 0; keyBox.BorderSizePixel = 0
    keyBox.ClearTextOnFocus = false; keyBox.ZIndex = 3; keyBox.Parent = card
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)
    local kbStroke = Instance.new("UIStroke")
    kbStroke.Color = Color3.fromRGB(35,65,125); kbStroke.Thickness = 1; kbStroke.Parent = keyBox
    keyBox.Focused:Connect(function()
        TweenService:Create(kbStroke,TweenInfo.new(.2),{Color=Color3.fromRGB(59,130,246)}):Play()
    end)
    keyBox.FocusLost:Connect(function()
        TweenService:Create(kbStroke,TweenInfo.new(.2),{Color=Color3.fromRGB(35,65,125)}):Play()
    end)

    -- status
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1,-32,0,16); statusLbl.Position = UDim2.new(0,16,0,140)
    statusLbl.Text = ""; statusLbl.Font = Enum.Font.Gotham; statusLbl.TextSize = 11
    statusLbl.TextColor3 = Color3.fromRGB(200,200,200)
    statusLbl.BackgroundTransparency = 1; statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.ZIndex = 3; statusLbl.Parent = card

    local function mkBtn(txt, x, w, col)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0,w,0,36); b.Position = UDim2.new(0,x,0,164)
        b.Text = txt; b.Font = Enum.Font.GothamBold; b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(255,255,255); b.BackgroundColor3 = col
        b.BackgroundTransparency = 0; b.BorderSizePixel = 0; b.ZIndex = 3; b.Parent = card
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
        b.MouseEnter:Connect(function()
            TweenService:Create(b,TweenInfo.new(.15),{BackgroundColor3=col:Lerp(Color3.new(1,1,1),.15)}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b,TweenInfo.new(.15),{BackgroundColor3=col}):Play()
        end)
        return b
    end

    local checkBtn   = mkBtn("Check Key",         16, 182, Color3.fromRGB(37,99,235))
    local copyUrlBtn = mkBtn("Copy Website Link", 206, 178, Color3.fromRGB(15,70,100))

    div(214)
    local hint = lbl("Don't have a key? Copy the website link, open it in your browser and follow the steps.", 222, 10, Color3.fromRGB(85,115,175), false)
    hint.TextWrapped = true
    hint.Size = UDim2.new(1,-32,0,32)

    -- logic
    local function closeAndRun()
        TweenService:Create(card,TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.In),
            {Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)}):Play()
        TweenService:Create(overlay,TweenInfo.new(.3),{BackgroundTransparency=1}):Play()
        task.wait(.4); screenGui:Destroy()
        if HasScript then runScript() else showNoScriptMessage() end
    end

    checkBtn.MouseButton1Click:Connect(function()
        local key = keyBox.Text:gsub("%s+","")
        if key == "" then
            statusLbl.Text = "❌  Paste your key first."
            statusLbl.TextColor3 = Color3.fromRGB(248,113,113); return
        end
        statusLbl.Text = "⏳  Verifying..."
        statusLbl.TextColor3 = Color3.fromRGB(250,204,21)
        task.spawn(function()
            if verifyKey(key) then
                saveKey(key)
                statusLbl.Text = "✔  Valid! Loading..."
                statusLbl.TextColor3 = Color3.fromRGB(74,222,128)
                task.wait(.7); closeAndRun()
            else
                statusLbl.Text = "❌  Invalid or expired key. Get a new one."
                statusLbl.TextColor3 = Color3.fromRGB(248,113,113)
            end
        end)
    end)

    copyUrlBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local fc = setclipboard or toclipboard
            if fc then fc(siteUrl) end
        end)
        local orig = copyUrlBtn.Text
        copyUrlBtn.Text = "✔ Copied!"
        task.wait(2); copyUrlBtn.Text = orig
    end)

    -- entrance
    TweenService:Create(card, TweenInfo.new(.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size     = UDim2.new(0, CW, 0, CH),
        Position = UDim2.new(0.5, -CW/2, 0.5, -CH/2)
    }):Play()
end

-- ══════════════════════════════════════════
--  MAIN
-- ══════════════════════════════════════════
local savedKey = loadSavedKey()

if savedKey and verifyKey(savedKey) then
    if HasScript then runScript() else showNoScriptMessage() end
else
    pcall(function() writefile(KEY_FILE, "") end)
    buildKeyUI()
end
