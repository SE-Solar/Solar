-- Solar | Strongman Simulator
if game.PlaceId ~= 6766156863 then
    game.Players.LocalPlayer:Kick("game not supported")
    return
end

local Players     = game:GetService("Players")
local LP          = Players.LocalPlayer
local UIS         = game:GetService("UserInputService")
local VIM         = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

-- KEY SYSTEM
local BASE_URL  = "https://seeclipse.pythonanywhere.com"
local LOOTLABS  = "https://lootdest.org/s?NORUfvwE"
local KEY_FILE  = "SolarKey.txt"

local function validateKey(key)
    local userId = tostring(LP.UserId)
    local ok, res = pcall(function()
        return game:HttpGet(BASE_URL .. "/validate?key=" .. key .. "&userid=" .. userId)
    end)
    if not ok then return false, "server offline" end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    if not ok2 then return false, "bad response" end
    return data.valid == true, data.reason or ""
end

local savedKey = ""
pcall(function() if isfile(KEY_FILE) then savedKey = readfile(KEY_FILE) end end)

local keyValid = false
if savedKey ~= "" then
    keyValid = validateKey(savedKey)
end

if not keyValid then
    local sg = Instance.new("ScreenGui")
    sg.Name          = "SolarKeyGui"
    sg.ResetOnSpawn  = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent        = LP.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size            = UDim2.new(0, 420, 0, 270)
    frame.Position        = UDim2.new(0.5, -210, 0.5, -135)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BorderSizePixel = 0
    frame.Parent          = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color     = Color3.fromRGB(168, 85, 247)
    stroke.Thickness = 1

    local function label(text, size, y, color, fontSize)
        local l = Instance.new("TextLabel")
        l.Text              = text
        l.Size              = UDim2.new(1, -20, 0, size)
        l.Position          = UDim2.new(0, 10, 0, y)
        l.BackgroundTransparency = 1
        l.TextColor3        = color or Color3.fromRGB(255, 255, 255)
        l.TextSize          = fontSize or 14
        l.Font              = Enum.Font.Gotham
        l.TextXAlignment    = Enum.TextXAlignment.Center
        l.Parent            = frame
        return l
    end

    label("☀️ Solar — Key Required", 30, 12, Color3.fromRGB(168, 85, 247), 18).Font = Enum.Font.GothamBold
    label("Get your free key by watching 3 short ads:", 20, 46, Color3.fromRGB(170, 170, 170), 13)
    label(LOOTLABS, 20, 68, Color3.fromRGB(100, 160, 255), 12)

    local input = Instance.new("TextBox")
    input.PlaceholderText  = "Paste your key here..."
    input.Size             = UDim2.new(1, -40, 0, 42)
    input.Position         = UDim2.new(0, 20, 0, 100)
    input.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    input.BorderSizePixel  = 0
    input.TextColor3       = Color3.fromRGB(255, 255, 255)
    input.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
    input.TextSize         = 13
    input.Font             = Enum.Font.Code
    input.ClearTextOnFocus = false
    input.Parent           = frame
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 8)
    local iStroke = Instance.new("UIStroke", input)
    iStroke.Color = Color3.fromRGB(60, 60, 60)

    local btn = Instance.new("TextButton")
    btn.Text             = "Unlock Script"
    btn.Size             = UDim2.new(1, -40, 0, 42)
    btn.Position         = UDim2.new(0, 20, 0, 154)
    btn.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    btn.BorderSizePixel  = 0
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.TextSize         = 15
    btn.Font             = Enum.Font.GothamBold
    btn.Parent           = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local statusLbl = label("", 20, 208, Color3.fromRGB(255, 80, 80), 12)

    local validated = false
    btn.MouseButton1Click:Connect(function()
        local key = input.Text:gsub("%s+", "")
        if key == "" then return end
        btn.Text   = "Checking..."
        btn.Active = false
        local valid, reason = validateKey(key)
        if valid then
            pcall(function() writefile(KEY_FILE, key) end)
            sg:Destroy()
            validated = true
        else
            statusLbl.Text = reason == "expired"      and "Key expired — get a new one at the link above"
                          or reason == "already_used" and "Key already claimed by another player"
                          or reason == "server offline" and "Server offline — try again in a moment"
                          or "Invalid key"
            btn.Text   = "Unlock Script"
            btn.Active = true
        end
    end)

    repeat task.wait(0.1) until validated
end

-- MAIN SCRIPT
local looping      = false
local wsValue      = 16
local jpValue      = 50
local energyMin    = 300000000000
local energyMax    = 700000000000
local bankPos      = Vector3.new(5404, 12, -2756)
local squatPos     = _G.SSSquatPos or nil
local needsBuyPets = true

local isMobile  = UIS.TouchEnabled and not UIS.KeyboardEnabled
local hasFirePP = false
pcall(function() hasFirePP = fireproximityprompt ~= nil end)

local function getChar() return LP.Character end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function applyMovement()
    local h = getHum()
    if h then h.WalkSpeed = wsValue; h.JumpPower = jpValue end
end

LP.CharacterAdded:Connect(function()
    task.wait(1)
    applyMovement()
end)

local function tpTo(pos, offset)
    local root = getRoot()
    if root then root.CFrame = CFrame.new(pos + (offset or Vector3.new(0, 0, 0))) end
end

local function vClick(x, y)
    VIM:SendMouseButtonEvent(x, y, 0, true,  game, 0)
    task.wait(0.05)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function vClickGui(btn)
    local pos  = btn.AbsolutePosition
    local size = btn.AbsoluteSize
    vClick(pos.X + size.X / 2, pos.Y + size.Y / 2)
end

local function fireButton(btn)
    local fired = false
    pcall(function()
        local conns = getconnections(btn.Activated)
        if #conns > 0 then conns[1]:Fire(); fired = true end
    end)
    if not fired then vClickGui(btn) end
end

local function triggerPP(pp)
    if hasFirePP then
        fireproximityprompt(pp)
    elseif not isMobile then
        VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    else
        local s = workspace.CurrentCamera.ViewportSize
        vClick(s.X / 2, s.Y / 2)
    end
end

local function getStatValue(containerName)
    local ok, v = pcall(function()
        return LP.PlayerGui.ParticleOverlay.ResourceHolder[containerName]
            .Counter.TextLabel.ClientComponent_ResourceCounter.CounterValue.Value
    end)
    return ok and v or 0
end

local function getEnergy()   return getStatValue("DefaultCurrencyContainer") end
local function getStrength() return getStatValue("DefaultStrengthContainer") end
local function getRebirths() return getStatValue("RebirthContainer") end

local function rebirthVisible()
    local ok, v = pcall(function()
        return LP.PlayerGui.HUD.RightButtons.Rebirth.Visible
    end)
    return ok and v
end

local function jumpDrop()
    local h = getHum()
    if h then h.Jump = true end
    task.wait(0.3)
end

local function tpToBank()
    tpTo(bankPos, Vector3.new(0, 5, 0))
    task.wait(2)
end

local cachedSafe = nil
local function farmEnergy()
    tpToBank()
    applyMovement()

    local s     = workspace.CurrentCamera.ViewportSize
    local dropX = s.X * 0.5
    local dropY = s.Y - 80

    while looping do
        if getEnergy() >= energyMax then break end

        if not cachedSafe or not cachedSafe.Parent then
            local bank = workspace:FindFirstChild("Area29_Bank")
            if bank then
                for _, d in ipairs(bank:GetDescendants()) do
                    if d:IsA("BasePart") and d.Name:lower():find("safe") then
                        cachedSafe = d; break
                    end
                end
            end
            if not cachedSafe then task.wait(0.5); continue end
        end

        local floor = cachedSafe.Position
        tpTo(floor, Vector3.new(0, 2, 0)); task.wait(0.05)
        local pp = cachedSafe:FindFirstChildOfClass("ProximityPrompt")
        if pp then triggerPP(pp) end; task.wait(0.08)
        tpTo(floor, Vector3.new(0, 52, 0)); task.wait(0.05)
        tpTo(floor, Vector3.new(0, 2, 0));  task.wait(0.05)
        vClick(dropX, dropY);               task.wait(0.05)
    end
end

local function buyPets()
    local pp   = nil
    local hoop = workspace:FindFirstChild("ShopHoop", true)
    if hoop then pp = hoop:FindFirstChildOfClass("ProximityPrompt") end

    if pp then
        local part = pp.Parent:IsA("BasePart") and pp.Parent or pp.Parent.Parent
        tpTo(part.Position, Vector3.new(0, 3, 0)); task.wait(0.5)
        for _ = 1, 2 do triggerPP(pp); task.wait(0.5) end
    else
        if not isMobile then
            VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        else
            local s = workspace.CurrentCamera.ViewportSize
            vClick(s.X / 2, s.Y / 2)
        end
    end
end

local cachedSqPP = nil
local function findSquatPP()
    local bank = workspace:FindFirstChild("Area29_Bank")
    if not bank then return nil end
    for _, d in ipairs(bank:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.ActionText:lower():find("squat") then
            return d
        end
    end
end

local function squatPhase()
    if not cachedSqPP or not cachedSqPP.Parent then
        cachedSqPP = findSquatPP()
    end
    if not cachedSqPP then return end

    if squatPos then
        tpTo(squatPos)
    else
        local part = cachedSqPP.Parent:IsA("BasePart") and cachedSqPP.Parent or cachedSqPP.Parent.Parent
        tpTo(part.Position, Vector3.new(0, 3, 0)); task.wait(0.3)
        local root = getRoot()
        if root then squatPos = root.Position; _G.SSSquatPos = squatPos end
    end

    task.wait(0.3)
    applyMovement()

    local s  = workspace.CurrentCamera.ViewportSize
    local cx = s.X / 2
    local cy = s.Y / 2

    while looping do
        if rebirthVisible() then break end
        triggerPP(cachedSqPP)
        vClick(cx, cy)
        task.wait(0.1)
    end
end

local function doRebirth()
    local ok, btn = pcall(function() return LP.PlayerGui.HUD.RightButtons.Rebirth end)
    if ok and btn then fireButton(btn) end
    task.wait(0.5)

    local hud = LP.PlayerGui:FindFirstChild("HUD")
    if hud then
        for _, d in ipairs(hud:GetDescendants()) do
            if d:IsA("TextBox") and d.Visible then
                d:CaptureFocus(); d.Text = "ok"; d:ReleaseFocus(true)
                task.wait(0.3); break
            end
        end
        for _, d in ipairs(hud:GetDescendants()) do
            if d:IsA("GuiButton") and d.Name:lower():find("confirm") and d.Visible then
                fireButton(d); break
            end
        end
    end

    task.wait(1)
    jumpDrop()
    needsBuyPets = true
    cachedSafe   = nil
    cachedSqPP   = nil
end

task.spawn(function()
    while true do
        local h = getHum()
        if h then
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      false)
        end
        task.wait(0.1)
    end
end)

local function masterLoop()
    tpToBank()
    while looping do
        if rebirthVisible() then
            doRebirth(); task.wait(1); tpToBank(); continue
        end
        if getEnergy() < energyMin then
            farmEnergy()
            if not looping then break end
        end
        if needsBuyPets and not rebirthVisible() then
            buyPets(); needsBuyPets = false
            if not looping then break end
        end
        if not rebirthVisible() then squatPhase() end
        task.wait(0.1)
    end
end

-- UI
local Linoria = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"
))()
local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"
))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"
))()

local Window = Linoria:CreateWindow({ Title = "Solar", Center = true, AutoShow = true })
local Tabs   = { Main = Window:AddTab("Main"), Movement = Window:AddTab("Movement") }

local FarmGroup = Tabs.Main:AddLeftGroupbox("Farm")
FarmGroup:AddInput("EnergyMin", { Default = tostring(energyMin), Numeric = true, Finished = true, Text = "Energy Min", Callback = function(v) energyMin = tonumber(v) or energyMin end })
FarmGroup:AddInput("EnergyMax", { Default = tostring(energyMax), Numeric = true, Finished = true, Text = "Energy Max", Callback = function(v) energyMax = tonumber(v) or energyMax end })
FarmGroup:AddToggle("MasterLoop", { Text = "Master Loop", Default = false, Callback = function(v) looping = v; if v then task.spawn(masterLoop) end end })
FarmGroup:AddButton("Unload", function() looping = false; Linoria:Destroy() end)

local StatsGroup  = Tabs.Main:AddRightGroupbox("Stats")
local lblStrength = StatsGroup:AddLabel("Strength: --")
local lblRebirths = StatsGroup:AddLabel("Rebirths: --")
local lblEnergy   = StatsGroup:AddLabel("Energy: --")

task.spawn(function()
    while true do
        pcall(function()
            lblStrength:SetText("Strength: "  .. tostring(getStrength()))
            lblRebirths:SetText("Rebirths: "  .. tostring(getRebirths()))
            lblEnergy:SetText("Energy: "      .. tostring(getEnergy()))
        end)
        task.wait(2)
    end
end)

local MovGroup = Tabs.Movement:AddLeftGroupbox("Movement")
MovGroup:AddSlider("WalkSpeed", { Text = "Walk Speed", Default = 16, Min = 16, Max = 200, Rounding = 0, Callback = function(v) wsValue = v; applyMovement() end })
MovGroup:AddSlider("JumpPower", { Text = "Jump Power", Default = 50, Min = 50, Max = 300, Rounding = 0, Callback = function(v) jpValue = v; applyMovement() end })

ThemeManager:SetLibrary(Linoria)
SaveManager:SetLibrary(Linoria)
ThemeManager:ApplyToTab(Tabs.Movement)

Linoria:Notify({ Title = "Solar", Content = "Loaded | PC/Mobile | Full UNC/Low UNC", Duration = 5 })
