local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library     = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title   = 'Swing Obby for Brainrot',
    Center  = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Farm       = Window:AddTab('Farm'),
    Upgrades   = Window:AddTab('Upgrades'),
    Automation = Window:AddTab('Automation'),
    Random     = Window:AddTab('Random'),
    Settings   = Window:AddTab('Settings'),
}

-- ─── WATERMARK ────────────────────────────────────────────────────────────────
Library:SetWatermark('Scriptide | Click to toggle UI')
Library:SetWatermarkVisibility(true)

local menuVisible = true
local UIS = game:GetService('UserInputService')

-- Use RightShift as fallback keybind to toggle UI
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        menuVisible = not menuVisible
        Library.Enabled = menuVisible
        Library:SetWatermarkVisibility(true)
        if menuVisible then
            Library:SetWatermark('Scriptide | Click to toggle UI')
        else
            Library:SetWatermark('Scriptide | [RightShift] to show UI')
        end
    end
end)

-- Overlay transparent button on watermark to catch clicks
task.defer(function()
    local screenGui = Library.ScreenGui
    if not screenGui then return end

    -- Wait a tick for watermark to fully render
    task.wait(0.2)

    local wLabel
    for _, d in ipairs(screenGui:GetDescendants()) do
        if d:IsA('TextLabel') and d.Text:find('Scriptide') then
            wLabel = d
            break
        end
    end

    if not wLabel then return end
    local wFrame = wLabel.Parent

    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ''
    btn.ZIndex = wFrame.ZIndex + 10
    btn.Parent = wFrame

    btn.MouseButton1Click:Connect(function()
        menuVisible = not menuVisible
        -- Hide/show all main UI frames except watermark
        for _, child in ipairs(screenGui:GetChildren()) do
            if child ~= wFrame and child:IsA('Frame') then
                child.Visible = menuVisible
            end
        end
        Library:SetWatermarkVisibility(true)
        if menuVisible then
            Library:SetWatermark('Scriptide | Click to toggle UI')
        else
            Library:SetWatermark('Scriptide | Click to show UI')
        end
    end)
end)

-- Groups (Linoria uses AddLeftGroupbox / AddRightGroupbox)
local FarmBox      = Tabs.Farm:AddLeftGroupbox('Farm Settings')
local UpgradeBox   = Tabs.Upgrades:AddLeftGroupbox('Stat Upgrades')
local BrainrotBox  = Tabs.Upgrades:AddRightGroupbox('Brainrots')
local AutoBox      = Tabs.Automation:AddLeftGroupbox('Automation')
local CollectBox   = Tabs.Automation:AddRightGroupbox('Collecting')
local RandomBox    = Tabs.Random:AddLeftGroupbox('Random')

-- ─── SERVICES ─────────────────────────────────────────────────────────────────
local Players           = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService      = game:GetService('TweenService')
local player            = Players.LocalPlayer

-- ─── FARM TAB ─────────────────────────────────────────────────────────────────
local suffixes = {
    k=1e3,  m=1e6,  b=1e9,   t=1e12,
    qa=1e15, qi=1e18, sx=1e21,
    sp=1e24, oc=1e27, no=1e30, dc=1e33
}

local function parseMoney(text)
    if not text then return 0 end
    text = text:lower():gsub('%$',''):gsub(',','')
    local num, suf = text:match('([%d%.]+)(%a*)')
    num = tonumber(num)
    if not num then return 0 end
    return num * (suffixes[suf] or 1)
end

local farmRunning      = false
local excludedRarities = {}
local excludedRanks    = {}
local levelLimit       = 0

FarmBox:AddDropdown('ExcludeRarities', {
    Text    = 'Exclude Rarities',
    Values  = {'COMMON','UNCOMMON','RARE','EPIC','LEGENDARY','MYTHIC','SECRET','ANCIENT','DIVINE'},
    Default = {},
    Multi   = true,
    Callback = function(val)
        excludedRarities = {}
        for k, selected in pairs(val) do
            if selected then excludedRarities[k] = true end
        end
    end
})

FarmBox:AddDropdown('ExcludeRanks', {
    Text    = 'Exclude Ranks',
    Values  = {'NORMAL','GOLDEN','DIAMOND','EMERALD','RUBY','RAINBOW','VOID','ETHEREAL','CELESTIAL'},
    Default = {},
    Multi   = true,
    Callback = function(val)
        excludedRanks = {}
        for k, selected in pairs(val) do
            if selected then excludedRanks[k] = true end
        end
    end
})

FarmBox:AddInput('LevelLimit', {
    Text        = 'Minimum Brainrot Level',
    Default     = '',
    Placeholder = 'Enter number',
    Numeric     = true,
    Finished    = false,
    Callback    = function(val)
        levelLimit = tonumber(val) or 0
    end
})

local function getBest()
    local bestPart, bestModel, bestValue = nil, nil, 0
    for _, part in pairs(workspace.ActiveBrainrots:GetChildren()) do
        if part:IsA('BasePart') then
            local model = part:FindFirstChildOfClass('Model')
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
                local lv = tonumber(data.level:match('%d+')) or 0
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
    char:WaitForChild('HumanoidRootPart').CFrame = cf
end

local function farmProcess()
    local part, model = getBest()
    if not part or not model then return end
    local hrp = model:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    teleport(hrp.CFrame + Vector3.new(0,3,0))
    task.wait(0.3)
    local att = part:FindFirstChild('Attachment')
    if att then
        local prompt = att:FindFirstChildOfClass('ProximityPrompt')
        if prompt then fireproximityprompt(prompt) end
    end
    task.wait(0.3)
    teleport(CFrame.new(-18,-10,-57))
end

FarmBox:AddToggle('FarmBrainrots', {
    Text    = 'Farm Brainrots',
    Default = false,
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
local upgradeRunning  = false
local upgradeBusy     = false
local upgradeInterval = 1
local doPower, doReach, doCarry = false, false, false
local powerAmt, reachAmt = 5, 5

UpgradeBox:AddToggle('UpgradePower', { Text = 'Upgrade Power', Default = false, Callback = function(v) doPower = v end })
UpgradeBox:AddToggle('UpgradeReach', { Text = 'Upgrade Reach', Default = false, Callback = function(v) doReach = v end })
UpgradeBox:AddToggle('UpgradeCarry', { Text = 'Upgrade Carry', Default = false, Callback = function(v) doCarry = v end })

UpgradeBox:AddSlider('PowerAmount', {
    Text    = 'Power Amount',
    Default = 5,
    Min     = 5,
    Max     = 50,
    Rounding = 0,
    Callback = function(v) powerAmt = v end
})

UpgradeBox:AddSlider('ReachAmount', {
    Text    = 'Reach Amount',
    Default = 5,
    Min     = 5,
    Max     = 50,
    Rounding = 0,
    Callback = function(v) reachAmt = v end
})

UpgradeBox:AddSlider('UpgradeInterval', {
    Text     = 'Upgrade Interval (s)',
    Default  = 1,
    Min      = 0,
    Max      = 5,
    Rounding = 1,
    Callback = function(v) upgradeInterval = v end
})

local statUpgradeRemote = ReplicatedStorage
    :WaitForChild('Packages'):WaitForChild('Knit')
    :WaitForChild('Services'):WaitForChild('StatUpgradeService')
    :WaitForChild('RF'):WaitForChild('Upgrade')

local function doUpgrade()
    if upgradeBusy then return end
    upgradeBusy = true
    if doPower then pcall(function() statUpgradeRemote:InvokeServer('Power',          powerAmt) end) end
    if doReach then pcall(function() statUpgradeRemote:InvokeServer('Reach_Distance', reachAmt) end) end
    if doCarry then pcall(function() statUpgradeRemote:InvokeServer('GrabAmount',     1)        end) end
    upgradeBusy = false
end

UpgradeBox:AddToggle('AutoUpgrade', {
    Text    = 'Auto Upgrade Selected',
    Default = false,
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
local podRunning = false
local podBusy    = false
local maxLevel   = 100

BrainrotBox:AddInput('MaxLevel', {
    Text        = 'Max Brainrot Level',
    Default     = '100',
    Placeholder = 'Enter max level',
    Numeric     = true,
    Finished    = false,
    Callback    = function(val) maxLevel = tonumber(val) or 100 end
})

local podUpgradeRemote = ReplicatedStorage
    :WaitForChild('Packages'):WaitForChild('Knit')
    :WaitForChild('Services'):WaitForChild('PlotService')
    :WaitForChild('RF'):WaitForChild('Upgrade')

local function getMyPlot()
    local myName = string.upper(player.Name)
    for i = 1,5 do
        local plot = workspace.Plots:FindFirstChild('Plot'..i)
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
        local m  = pod:FindFirstChild('BrainrotModel')
        local va = m:FindFirstChild('VisualAnchor')
        local br = va:GetChildren()[1]
        return br.LevelBoard.Frame.Level.Text
    end)
    if ok and txt then return tonumber(txt:match('%d+')) or 0 end
    return nil
end

local function podProcess()
    if podBusy then return end
    podBusy = true
    local plot = getMyPlot()
    if not plot then podBusy = false return end
    local pods = plot:FindFirstChild('Pods')
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

BrainrotBox:AddToggle('AutoPodUpgrade', {
    Text    = 'Auto Upgrade Brainrots',
    Default = false,
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
local TIERS = {'Normal','Golden','Diamond','Emerald','Ruby','Rainbow','Void','Ethereal','Celestial'}
local indexRunning = false

local function getIndexButtons()
    local buttons = {}
    local path = player:WaitForChild('PlayerGui')
        :WaitForChild('ScreenGui'):WaitForChild('FrameIndex')
        :WaitForChild('Main'):WaitForChild('ScrollingFrame')
    for _, v in ipairs(path:GetChildren()) do
        if v:IsA('ImageButton') then table.insert(buttons, v) end
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
                    :WaitForChild('Remotes'):WaitForChild('NewBrainrotIndex')
                    :WaitForChild('ClaimBrainrotIndex'):FireServer(btn.Name, tier)
                task.wait(0.1)
            end
        end
        task.wait(1)
    end
end

AutoBox:AddToggle('AutoClaimIndex', {
    Text    = 'Auto Claim Index Rewards',
    Default = false,
    Callback = function(state)
        indexRunning = state
        if indexRunning then task.spawn(indexRun) end
    end
})

local rebirthEnabled = false
AutoBox:AddToggle('AutoRebirth', {
    Text    = 'Auto Rebirth',
    Default = false,
    Callback = function(state)
        rebirthEnabled = state
        if rebirthEnabled then
            task.spawn(function()
                while rebirthEnabled do
                    pcall(function()
                        ReplicatedStorage
                            :WaitForChild('Packages'):WaitForChild('Knit')
                            :WaitForChild('Services'):WaitForChild('StatUpgradeService')
                            :WaitForChild('RF'):WaitForChild('Rebirth'):InvokeServer()
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})

-- Collecting
local collectActive = false
local collectMode   = 'Teleport'

CollectBox:AddToggle('TweenMode', {
    Text    = 'Use Tween (off = Teleport)',
    Default = false,
    Callback = function(state)
        collectMode = state and 'Tween' or 'Teleport'
    end
})

local function getCollectPlot()
    for i = 1,5 do
        local plot = workspace:WaitForChild('Plots'):FindFirstChild('Plot'..i)
        if plot then
            local lbl = plot.MainSign.ScreenFrame.SurfaceGui.Frame.Owner.PlayerName
            if lbl and lbl.Text == string.upper(player.Name) then return plot end
        end
    end
end

local function moveTo(cf)
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild('HumanoidRootPart')
    if collectMode == 'Tween' then
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
        local pods = plot:WaitForChild('Pods')
        for i = 1,40 do
            if not collectActive then break end
            local pod = pods:FindFirstChild(tostring(i))
            if pod and pod:FindFirstChild('TouchPart') then
                moveTo(pod.TouchPart.CFrame + Vector3.new(0,3,0))
                task.wait(0.2)
            end
        end
        task.wait(1)
    end
end

CollectBox:AddToggle('AutoCollect', {
    Text    = 'Auto Collect Money',
    Default = false,
    Callback = function(state)
        collectActive = state
        if collectActive then task.spawn(collectRun) end
    end
})

-- ─── RANDOM TAB ───────────────────────────────────────────────────────────────
local reachStat    = player:WaitForChild('updateStatsFolder'):WaitForChild('Reach_Distance')
local reachEnabled = false
local reachOrig    = reachStat.Value

RandomBox:AddToggle('InfReach', {
    Text    = 'Inf Rope Reach',
    Default = false,
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

local powerStat    = player:WaitForChild('updateStatsFolder'):WaitForChild('Power')
local powerEnabled = false
local powerOrig    = powerStat.Value
local customPower  = 10

RandomBox:AddSlider('CustomPowerSlider', {
    Text     = 'Custom Power Value',
    Default  = 10,
    Min      = 5,
    Max      = 15000,
    Rounding = 0,
    Callback = function(v) customPower = v end
})

RandomBox:AddToggle('CustomPower', {
    Text    = 'Enable Custom Power',
    Default = false,
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

RandomBox:AddButton({
    Text = 'Tp to End',
    Func = function()
        local char = player.Character or player.CharacterAdded:Wait()
        char:WaitForChild('HumanoidRootPart').CFrame = CFrame.new(21,-10,-34044)
    end
})

local autoBatTp = false

local function equipBat()
    local char     = player.Character or player.CharacterAdded:Wait()
    local backpack = player:WaitForChild('Backpack')
    local bat = char:FindFirstChild('Bat') or backpack:FindFirstChild('Bat')
    if bat then char.Humanoid:EquipTool(bat) end
end

local function tpToEnd()
    local char = player.Character or player.CharacterAdded:Wait()
    char:WaitForChild('HumanoidRootPart').CFrame = CFrame.new(88,739,-38845)
end

RandomBox:AddToggle('AutoBatTp', {
    Text    = 'Equip Bat + Max Luck 3K',
    Default = false,
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

-- ─── SETTINGS TAB ─────────────────────────────────────────────────────────────
-- ThemeManager and SaveManager handle the Settings tab fully
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

ThemeManager:SetFolder('SwingObbyScript')
SaveManager:SetFolder('SwingObbyScript/configs')

ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

SaveManager:LoadAutoloadConfig()

-- ─── MISC ─────────────────────────────────────────────────────────────────────
setclipboard('https://discord.com/invite/hrhHYXGkWN')
Library:Notify('Discord link copied to clipboard!')
