local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Swing Obby for Brainrot",
    SubTitle = "by Scriptide",
    LoadingTitle = "Swing Obby Script",
    LoadingSubtitle = "by Scriptide",
    Theme = "Dark",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SwingObbyScript",
        FileName = "Config"
    },
    KeySystem = false,
})

-- Tabs
local FarmTab       = Window:CreateTab("Farm", "bot")
local UpgradesTab   = Window:CreateTab("Upgrades", "dollar-sign")
local AutomationTab = Window:CreateTab("Automation", "folder-cog")
local RandomTab     = Window:CreateTab("Random", "box")

-- ─── SERVICES / SHARED ────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local player            = Players.LocalPlayer

-- ─── FARM TAB ─────────────────────────────────────────────────────────────────
FarmTab:CreateSection("Farm Settings")

local suffixes = {
    k=1e3, m=1e6, b=1e9, t=1e12,
    qa=1e15, qi=1e18, sx=1e21,
    sp=1e24, oc=1e27, no=1e30, dc=1e33
}

local function parseMoney(text)
    if not text then return 0 end
    text = text:lower():gsub("%$",""):gsub(",","")
    local num, suf = text:match("([%d%.]+)(%a*)")
    num = tonumber(num)
    if not num then return 0 end
    return num * (suffixes[suf] or 1)
end

local farmRunning      = false
local excludedRarities = {}
local excludedRanks    = {}
local levelLimit       = 0

FarmTab:CreateDropdown({
    Name = "Exclude Rarities",
    Options = {"COMMON","UNCOMMON","RARE","EPIC","LEGENDARY","MYTHIC","SECRET","ANCIENT","DIVINE"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "ExcludeRarities",
    Callback = function(val)
        excludedRarities = {}
        for _, r in ipairs(val) do
            excludedRarities[r] = true
        end
    end
})

FarmTab:CreateDropdown({
    Name = "Exclude Ranks",
    Options = {"NORMAL","GOLDEN","DIAMOND","EMERALD","RUBY","RAINBOW","VOID","ETHEREAL","CELESTIAL"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "ExcludeRanks",
    Callback = function(val)
        excludedRanks = {}
        for _, r in ipairs(val) do
            excludedRanks[r] = true
        end
    end
})

FarmTab:CreateInput({
    Name = "Minimum Brainrot Level",
    PlaceholderText = "Enter number",
    RemoveTextAfterFocusLost = false,
    Callback = function(val)
        levelLimit = tonumber(val) or 0
    end
})

local function getBest()
    local bestPart, bestModel, bestValue = nil, nil, 0
    for _, part in pairs(workspace.ActiveBrainrots:GetChildren()) do
        if part:IsA("BasePart") then
            local model = part:FindFirstChildOfClass("Model")
            if not model then continue end
            local ok, data = pcall(function()
                local frame = model.LevelBoard.Frame
                return {
                    earnings = frame.CurrencyFrame.Earnings.Text,
                    rarity   = frame.Rarity.Text,
                    rank     = frame.Rank.Text,
                    level    = frame.Level.Text
                }
            end)
            if ok and data then
                if excludedRarities[data.rarity] then continue end
                if excludedRanks[data.rank]      then continue end
                local lv = tonumber(data.level:match("%d+")) or 0
                if lv <= levelLimit then continue end
                local v = parseMoney(data.earnings)
                if v > bestValue then
                    bestValue = v; bestPart = part; bestModel = model
                end
            end
        end
    end
    return bestPart, bestModel
end

local function teleport(cf)
    local char = player.Character or player.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart").CFrame = cf
end

local function farmProcess()
    local part, model = getBest()
    if not part or not model then return end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    teleport(hrp.CFrame + Vector3.new(0,3,0))
    task.wait(0.3)
    local att = part:FindFirstChild("Attachment")
    if att then
        local prompt = att:FindFirstChildOfClass("ProximityPrompt")
        if prompt then fireproximityprompt(prompt) end
    end
    task.wait(0.3)
    teleport(CFrame.new(-18,-10,-57))
end

FarmTab:CreateToggle({
    Name = "Farm Brainrots",
    CurrentValue = false,
    Flag = "FarmBrainrots",
    Callback = function(state)
        farmRunning = state
        if farmRunning then
            task.spawn(function()
                while farmRunning do
                    pcall(farmProcess)
                    task.wait(1.5)
                end
            end)
        end
    end
})

-- ─── UPGRADES TAB ─────────────────────────────────────────────────────────────
UpgradesTab:CreateSection("Stat Upgrades")

local upgradeRunning  = false
local upgradeBusy     = false
local upgradeInterval = 1
local doPower, doReach, doCarry = false, false, false
local powerAmt, reachAmt = 5, 5

UpgradesTab:CreateToggle({
    Name = "Upgrade Power",
    CurrentValue = false,
    Flag = "UpgradePower",
    Callback = function(v) doPower = v end
})

UpgradesTab:CreateToggle({
    Name = "Upgrade Reach",
    CurrentValue = false,
    Flag = "UpgradeReach",
    Callback = function(v) doReach = v end
})

UpgradesTab:CreateToggle({
    Name = "Upgrade Carry",
    CurrentValue = false,
    Flag = "UpgradeCarry",
    Callback = function(v) doCarry = v end
})

UpgradesTab:CreateSlider({
    Name = "Power Amount",
    Range = {5, 50},
    Increment = 5,
    Suffix = "x",
    CurrentValue = 5,
    Flag = "PowerAmount",
    Callback = function(v) powerAmt = v end
})

UpgradesTab:CreateSlider({
    Name = "Reach Amount",
    Range = {5, 50},
    Increment = 5,
    Suffix = "x",
    CurrentValue = 5,
    Flag = "ReachAmount",
    Callback = function(v) reachAmt = v end
})

UpgradesTab:CreateSlider({
    Name = "Upgrade Interval (s)",
    Range = {0, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "UpgradeInterval",
    Callback = function(v) upgradeInterval = v end
})

local statUpgradeRemote = ReplicatedStorage
    :WaitForChild("Packages"):WaitForChild("Knit")
    :WaitForChild("Services"):WaitForChild("StatUpgradeService")
    :WaitForChild("RF"):WaitForChild("Upgrade")

local function doUpgrade()
    if upgradeBusy then return end
    upgradeBusy = true
    if doPower then pcall(function() statUpgradeRemote:InvokeServer("Power",          powerAmt) end) end
    if doReach then pcall(function() statUpgradeRemote:InvokeServer("Reach_Distance", reachAmt) end) end
    if doCarry then pcall(function() statUpgradeRemote:InvokeServer("GrabAmount",     1)        end) end
    upgradeBusy = false
end

UpgradesTab:CreateToggle({
    Name = "Auto Upgrade Selected",
    CurrentValue = false,
    Flag = "AutoUpgrade",
    Callback = function(state)
        upgradeRunning = state
        if upgradeRunning then
            task.spawn(function()
                while upgradeRunning do
                    doUpgrade()
                    task.wait(upgradeInterval)
                end
            end)
        end
    end
})

-- Brainrot Pod Upgrades
UpgradesTab:CreateSection("Brainrots")

local podRunning = false
local podBusy    = false
local maxLevel   = 100

UpgradesTab:CreateInput({
    Name = "Max Brainrot Level",
    PlaceholderText = "Default: 100",
    RemoveTextAfterFocusLost = false,
    Callback = function(val)
        maxLevel = tonumber(val) or 100
    end
})

local podUpgradeRemote = ReplicatedStorage
    :WaitForChild("Packages"):WaitForChild("Knit")
    :WaitForChild("Services"):WaitForChild("PlotService")
    :WaitForChild("RF"):WaitForChild("Upgrade")

local function getMyPlot()
    local myName = string.upper(player.Name)
    for i = 1,5 do
        local plot = workspace.Plots:FindFirstChild("Plot"..i)
        if plot then
            local ok, ownerText = pcall(function()
                return plot.MainSign.ScreenFrame.SurfaceGui.Frame.Owner.PlayerName.Text
            end)
            if ok and ownerText == myName then return plot end
        end
    end
end

local function getPodLevel(pod)
    local ok, txt = pcall(function()
        local m  = pod:FindFirstChild("BrainrotModel")
        local va = m:FindFirstChild("VisualAnchor")
        local br = va:GetChildren()[1]
        return br.LevelBoard.Frame.Level.Text
    end)
    if ok and txt then return tonumber(txt:match("%d+")) or 0 end
    return nil
end

local function podProcess()
    if podBusy then return end
    podBusy = true
    local plot = getMyPlot()
    if not plot then podBusy = false return end
    local pods = plot:FindFirstChild("Pods")
    if not pods then podBusy = false return end
    for _, pod in pairs(pods:GetChildren()) do
        if not podRunning then break end
        local lv = getPodLevel(pod)
        if lv and lv < maxLevel then
            pcall(function() podUpgradeRemote:InvokeServer(pod) end)
            task.wait(0.1)
        end
    end
    podBusy = false
end

UpgradesTab:CreateToggle({
    Name = "Auto Upgrade Brainrots",
    CurrentValue = false,
    Flag = "AutoPodUpgrade",
    Callback = function(state)
        podRunning = state
        if podRunning then
            task.spawn(function()
                while podRunning do
                    podProcess()
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- ─── AUTOMATION TAB ───────────────────────────────────────────────────────────
AutomationTab:CreateSection("Automation")

local TIERS = {"Normal","Golden","Diamond","Emerald","Ruby","Rainbow","Void","Ethereal","Celestial"}
local indexRunning = false

local function getIndexButtons()
    local buttons = {}
    local path = player:WaitForChild("PlayerGui")
        :WaitForChild("ScreenGui"):WaitForChild("FrameIndex")
        :WaitForChild("Main"):WaitForChild("ScrollingFrame")
    for _, v in ipairs(path:GetChildren()) do
        if v:IsA("ImageButton") then table.insert(buttons, v) end
    end
    return buttons
end

local function indexRun()
    while indexRunning do
        for _, btn in ipairs(getIndexButtons()) do
            if not indexRunning then break end
            for _, tier in ipairs(TIERS) do
                if not indexRunning then break end
                ReplicatedStorage
                    :WaitForChild("Remotes"):WaitForChild("NewBrainrotIndex")
                    :WaitForChild("ClaimBrainrotIndex"):FireServer(btn.Name, tier)
                task.wait(0.1)
            end
        end
        task.wait(1)
    end
end

AutomationTab:CreateToggle({
    Name = "Auto Claim Index Rewards",
    CurrentValue = false,
    Flag = "AutoClaimIndex",
    Callback = function(state)
        indexRunning = state
        if indexRunning then task.spawn(indexRun) end
    end
})

AutomationTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(state)
        local rebirthEnabled = state
        if rebirthEnabled then
            task.spawn(function()
                while rebirthEnabled do
                    pcall(function()
                        ReplicatedStorage
                            :WaitForChild("Packages"):WaitForChild("Knit")
                            :WaitForChild("Services"):WaitForChild("StatUpgradeService")
                            :WaitForChild("RF"):WaitForChild("Rebirth"):InvokeServer()
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

-- Collecting
AutomationTab:CreateSection("Collecting")

local collectActive = false
local collectMode   = "Teleport"

AutomationTab:CreateToggle({
    Name = "Method Teleport ( On = Tween )",
    CurrentValue = false,
    Flag = "TweenMode",
    Callback = function(state)
        collectMode = state and "Tween" or "Teleport"
    end
})

local function getCollectPlot()
    for i = 1,5 do
        local plot = workspace:WaitForChild("Plots"):FindFirstChild("Plot"..i)
        if plot then
            local lbl = plot.MainSign.ScreenFrame.SurfaceGui.Frame.Owner.PlayerName
            if lbl and lbl.Text == string.upper(player.Name) then return plot end
        end
    end
end

local function moveTo(cf)
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    if collectMode == "Tween" then
        local tw = TweenService:Create(root, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {CFrame=cf})
        tw:Play(); tw.Completed:Wait()
    else
        root.CFrame = cf
    end
end

local function collectRun()
    while collectActive do
        local plot = getCollectPlot()
        if not plot then task.wait(1) continue end
        moveTo(plot.MainSign.ScreenFrame.CFrame + Vector3.new(0,3,0))
        task.wait(0.5)
        local pods = plot:WaitForChild("Pods")
        for i = 1,40 do
            if not collectActive then break end
            local pod = pods:FindFirstChild(tostring(i))
            if pod and pod:FindFirstChild("TouchPart") then
                moveTo(pod.TouchPart.CFrame + Vector3.new(0,3,0))
                task.wait(0.2)
            end
        end
        task.wait(1)
    end
end

AutomationTab:CreateToggle({
    Name = "Auto Collect Money",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(state)
        collectActive = state
        if collectActive then task.spawn(collectRun) end
    end
})

-- ─── RANDOM TAB ───────────────────────────────────────────────────────────────
RandomTab:CreateSection("Random")

-- Inf Rope Reach
local reachStat    = player:WaitForChild("updateStatsFolder"):WaitForChild("Reach_Distance")
local reachEnabled = false
local reachOrig    = reachStat.Value

RandomTab:CreateToggle({
    Name = "Inf Rope Reach",
    CurrentValue = false,
    Flag = "InfReach",
    Callback = function(state)
        reachEnabled = state
        if reachEnabled then
            reachOrig = reachStat.Value
            reachStat.Value = 1e9
            task.spawn(function()
                while reachEnabled do
                    if reachStat.Value ~= 1e9 then reachStat.Value = 1e9 end
                    task.wait(0.1)
                end
            end)
        else
            reachStat.Value = reachOrig
        end
    end
})

-- Custom Power
local powerStat    = player:WaitForChild("updateStatsFolder"):WaitForChild("Power")
local powerEnabled = false
local powerOrig    = powerStat.Value
local customPower  = 10

RandomTab:CreateSlider({
    Name = "Custom Power Value",
    Range = {5, 15000},
    Increment = 5,
    Suffix = "",
    CurrentValue = 10,
    Flag = "CustomPowerSlider",
    Callback = function(v)
        customPower = v
    end
})

RandomTab:CreateToggle({
    Name = "Enable Custom Power",
    CurrentValue = false,
    Flag = "CustomPower",
    Callback = function(state)
        powerEnabled = state
        if powerEnabled then
            powerOrig = powerStat.Value
            powerStat.Value = customPower
            task.spawn(function()
                while powerEnabled do
                    if powerStat.Value ~= customPower then powerStat.Value = customPower end
                    task.wait(0.1)
                end
            end)
        else
            powerStat.Value = powerOrig
        end
    end
})

-- TP to End
RandomTab:CreateButton({
    Name = "Tp to End",
    Callback = function()
        local char = player.Character or player.CharacterAdded:Wait()
        char:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(21,-10,-34044)
    end
})

-- Equip Bat + Max Luck 3K
local autoBatTp = false

local function equipBat()
    local char     = player.Character or player.CharacterAdded:Wait()
    local backpack = player:WaitForChild("Backpack")
    local bat = char:FindFirstChild("Bat") or backpack:FindFirstChild("Bat")
    if bat then char.Humanoid:EquipTool(bat) end
end

local function tpToEnd()
    local char = player.Character or player.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart").CFrame = CFrame.new(88,739,-38845)
end

RandomTab:CreateToggle({
    Name = "Equip Bat + Max Luck 3K",
    CurrentValue = false,
    Flag = "AutoBatTp",
    Callback = function(state)
        autoBatTp = state
        if autoBatTp then
            task.spawn(function()
                while autoBatTp do
                    pcall(function() tpToEnd(); task.wait(0.5); equipBat() end)
                    task.wait(10)
                end
            end)
        end
    end
})

-- ─── MISC ─────────────────────────────────────────────────────────────────────
setclipboard("https://discord.com/invite/hrhHYXGkWN")
Rayfield:LoadConfiguration()
