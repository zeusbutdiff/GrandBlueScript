--[[
    Grand Blue Auto-Roll & Codes
    UI Library: Rayfield Gen2
    Features: Auto Race Roll, Auto Trait Roll, Auto Redeem Codes
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("Events", 10)
if not Events then warn("[GBH] Events not found!") return end

local RerollRemote = Events:WaitForChild("Reroll", 10)
local CodesRemote = Events:WaitForChild("Codes", 10)
local GetDataRemote = Events:WaitForChild("GetData", 10)

if not RerollRemote or not CodesRemote or not GetDataRemote then
    warn("[GBH] Remotes not found!")
    return
end

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/gen2"))()
end)

if not success or not Rayfield then
    warn("[GBH] Rayfield load failed:", Rayfield)
    return
end

local Window = Rayfield:CreateWindow({
    name = "Grand Blue Hub",
    subtitle = "Auto Roll & Codes",
    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "GrandBlueHub",
    },
})

-- ============================================
-- DATA
-- ============================================

local Races = {"Human", "Seafolk", "Skyfolk", "Beastfolk", "Dwarf"}

local RaceVariantMap = {
    Human = {},
    Seafolk = {"Half Fish"},
    Skyfolk = {"Celestial"},
    Beastfolk = {"Cat", "Bunny"},
    Dwarf = {"Long Legged", "Long Armed"},
}

local Traits = {
    "Will of the King", "Heavenly Restricted", "Limit-Breaker", "Man of Steel", "Beast Tamer",
    "Snake", "Swordsman's Shame", "Glass Cannon", "Pyromaniac",
    "Prodigy", "Usain Bolt", "Flash God", "Ruthless", "Arrogant", "Chameleon", "Second Wind",
    "Super Stephon Meal", "Fast Learner", "Gifted", "#1 Swimmer", "Gourmand", "Adrenaline", "Escape Artist",
    "Coward", "Foodie", "Talented", "Climber", "Athlete", "Night Owl", "Early Bird",
    "Enduring Speed", "Glutton", "Bargainer", "Pacifist", "Sneaky", "Garbage Collector"
}
local TraitRarities = {"Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
local Codes = {
    "RollWithIt", "PocketOfStars", "GrandBlueCode", "CelestialBlessing",
    "FruitBasket", "NewYouNewCrew", "10KCCU", "WorldBossBroke",
    "SorryForBreakingGame", "HappySunday", "TwitterGoalReached", "Release!"
}

-- ============================================
-- STATE
-- ============================================

local State = {
    AutoRaceRoll = false,
    TargetRaces = {},
    TargetVariants = {},
    AutoTraitRoll = false,
    TargetTraits = {},
    TargetRarities = {},
    TraitSlots = {},
}

-- ============================================
-- HELPERS
-- ============================================

local function GetCharacterData()
    local ok, data = pcall(function()
        return GetDataRemote:InvokeServer("Character")
    end)
    if ok then return data end
    return nil
end

local function GetRace()
    local data = GetCharacterData()
    if data and data.Race then
        return data.Race.Species, data.Race.Variant
    end
    return nil, nil
end

local function GetTraits()
    local ok, traitData = pcall(function()
        return GetDataRemote:InvokeServer("Traits")
    end)
    if ok and traitData then
        local traitNames = {}
        for slotName, traitName in pairs(traitData) do
            if traitName and traitName ~= false and traitName ~= "None" then
                table.insert(traitNames, traitName)
            end
        end
        return traitNames
    end
    return {}
end

local function IsTargetRace(race, variant)
    if #State.TargetRaces == 0 and #State.TargetVariants == 0 then return false end
    local raceMatch = #State.TargetRaces == 0
    local variantMatch = #State.TargetVariants == 0
    if #State.TargetRaces > 0 and race then
        for _, t in pairs(State.TargetRaces) do
            if t == race then raceMatch = true; break end
        end
    end
    if #State.TargetVariants > 0 and variant then
        for _, t in pairs(State.TargetVariants) do
            if t == variant then variantMatch = true; break end
        end
    end
    return raceMatch and variantMatch
end

local function IsTargetTrait(traitNames)
    if #State.TargetTraits == 0 and #State.TargetRarities == 0 then return false end
    for _, traitName in pairs(traitNames) do
        for _, target in pairs(State.TargetTraits) do
            if target == traitName then return true end
        end
    end
    return false
end

local function SkipRaceAnimation()
    pcall(function()
        local char = LocalPlayer.Character
        if char then return end
        local gui = LocalPlayer.PlayerGui:FindFirstChild("CharacterCustomization")
        if not gui then return end
        local right = gui:FindFirstChild("Right", true)
        if not right then return end
        local race = right:FindFirstChild("Race", true)
        if not race then return end
        local spinner = race:FindFirstChild("Spinner", true)
        if not spinner then return end
        local frame = spinner:FindFirstChild("Frame", true)
        if not frame then return end
        local mainFrame = frame:FindFirstChild("MainFrame", true)
        if mainFrame and mainFrame.Visible then
            local goal = mainFrame:GetAttribute("Goal")
            if goal then
                mainFrame.Position = goal
            end
        end
    end)
end

local function SkipTraitAnimation(slotNum)
    pcall(function()
        local gui = LocalPlayer.PlayerGui:FindFirstChild("CharacterCustomization")
        if not gui then return end
        local right = gui:FindFirstChild("Right", true)
        if not right then return end
        local traits = right:FindFirstChild("Traits", true)
        if not traits then return end
        local slot = traits:FindFirstChild("Slot " .. slotNum, true)
        if not slot then return end
        local spinFrame = slot:FindFirstChild("SpinFrame", true)
        if not spinFrame then return end
        local bgFrame = spinFrame:FindFirstChild("BackgroundFrame", true)
        if not bgFrame then return end
        local mainFrame = bgFrame:FindFirstChild("MainFrame", true)
        if mainFrame and mainFrame.Visible then
            local goal = mainFrame:GetAttribute("Goal")
            if goal then
                mainFrame.Position = goal
            end
        end
    end)
end

-- ============================================
-- TAB 1: AUTO RACE ROLL
-- ============================================

local RaceTab = Window:CreateTab({ name = "Auto Race Roll" })

RaceTab:CreateText({
    name = "Race Roll Settings",
    text = "Half Fish=Seafolk, Celestial=Skyfolk, Cat/Bunny=Beastfolk, Long Legged/Long Armed=Dwarf. Human has no variants.",
})

RaceTab:CreateSection({ name = "Target Selection" })

RaceTab:CreateDropdown({
    name = "Target Races",
    description = "Select races to stop on",
    multiSelect = true,
    options = Races,
    callback = function(value) State.TargetRaces = value end,
})

RaceTab:CreateDropdown({
    name = "Target Variants",
    description = "Only valid variants shown per race",
    multiSelect = true,
    options = {"Half Fish", "Celestial", "Cat", "Bunny", "Long Legged", "Long Armed"},
    callback = function(value) State.TargetVariants = value end,
})

RaceTab:CreateSection({ name = "Control" })

local RaceToggle = RaceTab:CreateToggle({
    name = "Enable Auto Race Roll",
    description = "Start auto rolling for your target race/variant",
    callback = function(value) State.AutoRaceRoll = value end,
})

local RaceStatus = RaceTab:CreateConsole({
    name = "Roll Status",
    height = 100,
    follow = true,
    maxLines = 30,
})

-- ============================================
-- TAB 2: AUTO TRAIT ROLL
-- ============================================

local TraitTab = Window:CreateTab({ name = "Auto Trait Roll" })

TraitTab:CreateText({
    name = "Trait Roll Settings",
    text = "Select target traits/rarities and which slots to roll. Animation is auto-skipped.",
})

TraitTab:CreateSection({ name = "Slots to Roll" })

TraitTab:CreateDropdown({
    name = "Trait Slots",
    description = "Select which trait slots to roll (multiple allowed)",
    multiSelect = true,
    options = {"1", "2", "3"},
    callback = function(value) State.TraitSlots = value end,
})

TraitTab:CreateSection({ name = "Target Selection" })

TraitTab:CreateDropdown({
    name = "Target Traits",
    description = "Select specific traits to stop on",
    multiSelect = true,
    options = Traits,
    callback = function(value) State.TargetTraits = value end,
})

TraitTab:CreateDropdown({
    name = "Target Rarities",
    description = "Stop on any trait of these rarities",
    multiSelect = true,
    options = TraitRarities,
    callback = function(value) State.TargetRarities = value end,
})

TraitTab:CreateSection({ name = "Control" })

local TraitToggle = TraitTab:CreateToggle({
    name = "Enable Auto Trait Roll",
    description = "Start auto rolling selected slots",
    callback = function(value) State.AutoTraitRoll = value end,
})

local TraitStatus = TraitTab:CreateConsole({
    name = "Roll Status",
    height = 100,
    follow = true,
    maxLines = 30,
})

-- ============================================
-- TAB 3: AUTO CODES
-- ============================================

local CodesTab = Window:CreateTab({ name = "Auto Codes" })

CodesTab:CreateText({
    name = "Code Redemption",
    text = "Click the button below to redeem all 12 known codes.",
})

local CodesStatus = CodesTab:CreateConsole({
    name = "Redemption Status",
    height = 150,
    follow = true,
    maxLines = 50,
})

CodesTab:CreateButton({
    name = "Redeem All Codes",
    description = "Redeem all known codes now",
    callback = function()
        task.spawn(function()
            CodesStatus:Clear()
            CodesStatus:Append("Starting code redemption...")
            for _, code in pairs(Codes) do
                pcall(function() CodesRemote:FireServer(code) end)
                CodesStatus:Append("Redeemed: " .. code)
                task.wait(1.5)
            end
            CodesStatus:Append("Done! All codes redeemed.")
        end)
    end,
})

CodesTab:CreateText({
    name = "Available Codes",
    text = table.concat(Codes, ", "),
})

-- ============================================
-- AUTO ROLL LOOPS
-- ============================================

local RACE_COOLDOWN = 5
local TRAIT_COOLDOWN = 5

task.spawn(function()
    while true do
        if State.AutoRaceRoll then
            local race, variant = GetRace()
            if race then
                if IsTargetRace(race, variant) then
                    RaceStatus:Append("Target reached: " .. race .. " " .. (variant or "Normal"))
                    State.AutoRaceRoll = false
                    pcall(function() RaceToggle:Set(false) end)
                else
                    RaceStatus:Append("Rolling... " .. race .. " " .. (variant or ""))
                    RerollRemote:FireServer("Race")
                    task.wait(1)
                    SkipRaceAnimation()
                    task.wait(RACE_COOLDOWN - 1)
                end
            else
                RaceStatus:Append("Waiting for character data...")
                task.wait(2)
            end
        end
        task.wait(0.25)
    end
end)

task.spawn(function()
    while true do
        if State.AutoTraitRoll and #State.TraitSlots > 0 then
            local traitNames = GetTraits()
            if IsTargetTrait(traitNames) then
                TraitStatus:Append("Target trait found!")
                State.AutoTraitRoll = false
                pcall(function() TraitToggle:Set(false) end)
            else
                for _, slot in pairs(State.TraitSlots) do
                    local slotNum = tonumber(slot)
                    if slotNum then
                        TraitStatus:Append("Rolling slot " .. slot)
                        RerollRemote:FireServer("Trait", slotNum)
                        task.wait(1)
                        SkipTraitAnimation(slotNum)
                        task.wait(TRAIT_COOLDOWN - 1)
                    end
                end
            end
        end
        task.wait(0.25)
    end
end)

pcall(function() Window:Load() end)
