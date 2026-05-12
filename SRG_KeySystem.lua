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

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SRGKeyUI"; screenGui.ResetOnSpawn = false; screenGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 0, 0, 0); frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(12, 21, 38); frame.BorderSizePixel = 0
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(30, 80, 160); stroke.Thickness = 1.5; stroke.Parent = frame

    local function label(text, y, size, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 0, size + 4); l.Position = UDim2.new(0, 10, 0, y)
        l.Text = text; l.Font = Enum.Font.Gotham; l.TextSize = size
        l.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        l.BackgroundTransparency = 1; l.Parent = frame; return l
    end

    label("🔑  SRG Key System", 10, 17, Color3.fromRGB(255,255,255)).Font = Enum.Font.GothamBold
    label(HasScript and "✅ Script available" or "❌ No script for this game",
        48, 11, HasScript and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100))

    -- show HWID so user can copy it to the site
    local myHwid = "?"
    pcall(function() myHwid = tostring(fGetHwid()) end)
    local hwidLbl = label("HWID: " .. myHwid, 66, 10, Color3.fromRGB(77, 184, 255))
    hwidLbl.TextXAlignment = Enum.TextXAlignment.Left
    hwidLbl.Size = UDim2.new(1, -20, 0, 14)

    local copyHwidBtn = Instance.new("TextButton")
    copyHwidBtn.Size = UDim2.new(1, -30, 0, 28); copyHwidBtn.Position = UDim2.new(0, 15, 0, 84)
    copyHwidBtn.Text = "Copy HWID"; copyHwidBtn.Font = Enum.Font.GothamBold; copyHwidBtn.TextSize = 11
    copyHwidBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 110); copyHwidBtn.TextColor3 = Color3.fromRGB(255,255,255)
    copyHwidBtn.Parent = frame
    Instance.new("UICorner", copyHwidBtn).CornerRadius = UDim.new(0, 7)

    local siteLbl = label("Get your key: randomscripts364.github.io/verified/", 84, 10, Color3.fromRGB(77,184,255))
    siteLbl.TextXAlignment = Enum.TextXAlignment.Left; siteLbl.Size = UDim2.new(1,-20,0,14)

    -- open site with HWID pre-filled
    local openSiteBtn = Instance.new("TextButton")
    openSiteBtn.Size = UDim2.new(1, -30, 0, 34); openSiteBtn.Position = UDim2.new(0, 15, 0, 102)
    openSiteBtn.Text = "Open Key Site"; openSiteBtn.Font = Enum.Font.GothamBold; openSiteBtn.TextSize = 12
    openSiteBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 240); openSiteBtn.TextColor3 = Color3.fromRGB(255,255,255)
    openSiteBtn.Parent = frame
    Instance.new("UICorner", openSiteBtn).CornerRadius = UDim.new(0, 8)

    openSiteBtn.MouseButton1Click:Connect(function()
        local url = "https://randomscripts364.github.io/verified/?hwid=" .. game:GetService("HttpService"):UrlEncode(myHwid)
        pcall(function()
            if syn and syn.openbrowser then
                syn.openbrowser(url)
            elseif openbrowser then
                openbrowser(url)
            elseif os and os.execute then
                os.execute('start "" "' .. url .. '"')
            else
                setclipboard(url)
                openSiteBtn.Text = "URL copied! Paste in browser"
                task.wait(3); openSiteBtn.Text = "Open Key Site"
            end
        end)
    end)
    keyBox.PlaceholderText = "Paste your SRG-...-...-... key"
    keyBox.Text = ""; keyBox.Font = Enum.Font.Gotham; keyBox.TextSize = 11
    keyBox.BackgroundColor3 = Color3.fromRGB(20, 30, 50); keyBox.TextColor3 = Color3.fromRGB(255,255,255)
    keyBox.ClearTextOnFocus = false; keyBox.Parent = frame
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)

    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(1, -30, 0, 34); checkBtn.Position = UDim2.new(0, 15, 0, 178)
    checkBtn.Text = "CHECK KEY"; checkBtn.Font = Enum.Font.GothamBold; checkBtn.TextSize = 13
    checkBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 240); checkBtn.TextColor3 = Color3.fromRGB(255,255,255)
    checkBtn.Parent = frame
    Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0, 8)

    local statusLbl = label("", 220, 11)
    statusLbl.TextWrapped = true; statusLbl.Size = UDim2.new(1,-20,0,28)

    -- hover
    local function addHover(btn, col)
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = col:Lerp(Color3.new(1,1,1),0.12) }):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = col }):Play() end)
    end
    addHover(checkBtn,    Color3.fromRGB(30,140,240))
    addHover(copyHwidBtn, Color3.fromRGB(20,60,110))

    copyHwidBtn.MouseButton1Click:Connect(function()
        local ok, _ = pcall(function()
            local fc = setclipboard or toclipboard
            if fc then fc(myHwid) end
        end)
        copyHwidBtn.Text = ok and "✅ Copied!" or "HWID: " .. myHwid:sub(1,20) .. "..."
        task.wait(2); copyHwidBtn.Text = "Copy HWID"
    end)

    local function closeAndRun()
        TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            { Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0) }):Play()
        task.wait(0.5); screenGui:Destroy()
        if HasScript then runScript() else showNoScriptMessage() end
    end

    checkBtn.MouseButton1Click:Connect(function()
        local key = keyBox.Text:gsub("%s+", "")
        if key == "" then
            statusLbl.Text = "❌ Paste your key first!"
            statusLbl.TextColor3 = Color3.fromRGB(255,100,100); return
        end
        statusLbl.Text = "⏳ Verifying..."; statusLbl.TextColor3 = Color3.fromRGB(255,220,80)
        task.spawn(function()
            if verifyKey(key) then
                saveKey(key)
                statusLbl.Text = "✅ Valid! Loading..."; statusLbl.TextColor3 = Color3.fromRGB(100,255,100)
                task.wait(0.8); closeAndRun()
            else
                statusLbl.Text = "❌ Invalid or expired key. Get a new one at the site."
                statusLbl.TextColor3 = Color3.fromRGB(255,100,100)
            end
        end)
    end)

    -- entrance animation
    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 360, 0, 260), Position = UDim2.new(0.5,-180,0.5,-130) }):Play()
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
