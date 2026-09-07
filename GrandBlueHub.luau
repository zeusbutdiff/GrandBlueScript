--[[
    Grand Blue Auto-Roll & Codes
    UI Library: Rayfield Gen2
    Features: Auto Race Roll, Auto Trait Roll, Auto Redeem Codes
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local LocalPlayer = Players.LocalPlayer

-- Wait for events
local Events = ReplicatedStorage:WaitForChild("Events", 10)
if not Events then
    warn("[GrandBlueHub] Events folder not found!")
    return
end

local RerollRemote = Events:WaitForChild("Reroll", 10)
local CodesRemote = Events:WaitForChild("Codes", 10)

if not RerollRemote or not CodesRemote then
    warn("[GrandBlueHub] Required remotes not found!")
    return
end

-- Load UI Library
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/gen2"))()
end)

if not success or not Rayfield then
    warn("[GrandBlueHub] Failed to load Rayfield:", Rayfield)
    return
end

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "Grand Blue Hub",
    LoadingTitle = "Grand Blue Hub",
    LoadingSubtitle = "Loading features...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrandBlueHub",
        FileName = "Settings"
    },
    KeySystem = false,
})

-- ============================================
-- DATA
-- ============================================

local Races = {"Human", "Seafolk", "Skyfolk", "Beastfolk", "Dwarf"}
local RaceVariants = {"Normal", "Long Legged", "Long Armed", "Half Fish", "Celestial", "Cat", "Bunny"}
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
    RaceSkipAnimation = true,
    RaceDelay = 2,
    AutoTraitRoll = false,
    TargetTraits = {},
    TargetRarities = {},
    TraitSlot = 1,
    TraitSkipAnimation = true,
    TraitDelay = 2,
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRace()
    local char = GetCharacter()
    if char then
        local raceObj = char:FindFirstChild("Race")
        if raceObj then
            return raceObj.Value
        end
    end
    return nil
end

local function GetRaceVariant()
    local char = GetCharacter()
    if char then
        local variantObj = char:FindFirstChild("RaceVariant")
        if variantObj then
            return variantObj.Value
        end
    end
    return nil
end

local function GetTraits()
    local char = GetCharacter()
    local traits = {}
    if char then
        local traitsFolder = char:FindFirstChild("Traits")
        if traitsFolder then
            for _, v in pairs(traitsFolder:GetChildren()) do
                table.insert(traits, v.Name)
            end
        end
    end
    return traits
end

local function IsTargetRace(race, variant)
    if #State.TargetRaces == 0 and #State.TargetVariants == 0 then
        return false
    end
    local raceMatch = #State.TargetRaces == 0
    local variantMatch = #State.TargetVariants == 0
    if #State.TargetRaces > 0 then
        for _, target in pairs(State.TargetRaces) do
            if target == race then
                raceMatch = true
                break
            end
        end
    end
    if #State.TargetVariants > 0 then
        for _, target in pairs(State.TargetVariants) do
            if target == variant then
                variantMatch = true
                break
            end
        end
    end
    return raceMatch and variantMatch
end

local function IsTargetTrait(traits)
    if #State.TargetTraits == 0 and #State.TargetRarities == 0 then
        return false
    end
    for _, traitName in pairs(traits) do
        if #State.TargetTraits > 0 then
            for _, target in pairs(State.TargetTraits) do
                if target == traitName then
                    return true
                end
            end
        end
    end
    return false
end

-- ============================================
-- TAB 1: AUTO RACE ROLL
-- ============================================

local RaceTab = Window:CreateTab("Auto Race Roll", 4483362458)

RaceTab:CreateSection("Settings")

local RaceSkipToggle = RaceTab:CreateToggle({
    name = "Skip Animation",
    description = "Skip spin animation (faster rolling)",
    value = true,
    callback = function(value)
        State.RaceSkipAnimation = value
    end,
})

local RaceDelaySlider = RaceTab:CreateSlider({
    name = "Roll Delay",
    description = "Delay between rolls in seconds",
    range = {1, 10},
    increment = 0.5,
    value = 2,
    suffix = "s",
    callback = function(value)
        State.RaceDelay = value
    end,
})

RaceTab:CreateSection("Target Race(s)")

local RaceDropdown = RaceTab:CreateDropdown({
    name = "Target Races",
    description = "Select races to stop on",
    multiSelect = true,
    options = Races,
    callback = function(value)
        State.TargetRaces = value
    end,
})

local VariantDropdown = RaceTab:CreateDropdown({
    name = "Target Variants",
    description = "Select variants to stop on",
    multiSelect = true,
    options = RaceVariants,
    callback = function(value)
        State.TargetVariants = value
    end,
})

RaceTab:CreateSection("Control")

local RaceToggle = RaceTab:CreateToggle({
    name = "Enable Auto Race Roll",
    description = "Start auto rolling",
    callback = function(value)
        State.AutoRaceRoll = value
    end,
})

local RaceStatus = RaceTab:CreateConsole({
    name = "Status",
    height = 80,
    follow = true,
    maxLines = 20,
})

-- ============================================
-- TAB 2: AUTO TRAIT ROLL
-- ============================================

local TraitTab = Window:CreateTab("Auto Trait Roll", 4483362458)

TraitTab:CreateSection("Settings")

local TraitSkipToggle = TraitTab:CreateToggle({
    name = "Skip Animation",
    description = "Skip spin animation (faster rolling)",
    value = true,
    callback = function(value)
        State.TraitSkipAnimation = value
    end,
})

local TraitDelaySlider = TraitTab:CreateSlider({
    name = "Roll Delay",
    description = "Delay between rolls in seconds",
    range = {1, 10},
    increment = 0.5,
    value = 2,
    suffix = "s",
    callback = function(value)
        State.TraitDelay = value
    end,
})

local TraitSlotDropdown = TraitTab:CreateDropdown({
    name = "Slot to Roll",
    description = "Which trait slot to reroll",
    options = {"1", "2", "3", "4"},
    value = "1",
    callback = function(value)
        State.TraitSlot = tonumber(value)
    end,
})

TraitTab:CreateSection("Target Trait(s)")

local TraitDropdown = TraitTab:CreateDropdown({
    name = "Target Traits",
    description = "Select specific traits to stop on",
    multiSelect = true,
    options = Traits,
    callback = function(value)
        State.TargetTraits = value
    end,
})

local RarityDropdown = TraitTab:CreateDropdown({
    name = "Target Rarities",
    description = "Stop on any trait of these rarities",
    multiSelect = true,
    options = TraitRarities,
    callback = function(value)
        State.TargetRarities = value
    end,
})

TraitTab:CreateSection("Control")

local TraitToggle = TraitTab:CreateToggle({
    name = "Enable Auto Trait Roll",
    description = "Start auto rolling",
    callback = function(value)
        State.AutoTraitRoll = value
    end,
})

local TraitStatus = TraitTab:CreateConsole({
    name = "Status",
    height = 80,
    follow = true,
    maxLines = 20,
})

-- ============================================
-- TAB 3: AUTO CODES
-- ============================================

local CodesTab = Window:CreateTab("Auto Codes", 4483362458)

CodesTab:CreateSection("Redeem Codes")

local CodesStatus = CodesTab:CreateConsole({
    name = "Redemption Status",
    height = 120,
    follow = true,
    maxLines = 50,
})

local RedeemButton = CodesTab:CreateButton({
    name = "Redeem All Codes",
    description = "Click to redeem all codes now",
    callback = function()
        task.spawn(function()
            CodesStatus:Clear()
            CodesStatus:Append("Starting code redemption...")
            for _, code in pairs(Codes) do
                pcall(function()
                    CodesRemote:FireServer(code)
                end)
                CodesStatus:Append("Redeemed: " .. code)
                task.wait(1.5)
            end
            CodesStatus:Append("All codes redeemed!")
        end)
    end,
})

CodesTab:CreateSection("Available Codes")

CodesTab:CreateConsole({
    name = "Code List",
    text = table.concat(Codes, "\n"),
    height = 180,
})

-- ============================================
-- AUTO ROLL LOOPS
-- ============================================

-- Race Auto Roll Loop
task.spawn(function()
    while true do
        if State.AutoRaceRoll then
            local char = GetCharacter()
            if char then
                local currentRace = GetRace()
                local currentVariant = GetRaceVariant()
                
                if IsTargetRace(currentRace, currentVariant) then
                    RaceStatus:Append("Target reached: " .. (currentRace or "?") .. " " .. (currentVariant or ""))
                    State.AutoRaceRoll = false
                    pcall(function() RaceToggle:Set(false) end)
                else
                    RaceStatus:Append("Rolling... " .. (currentRace or "None"))
                    RerollRemote:FireServer("Race")
                    
                    if State.RaceSkipAnimation then
                        task.wait(State.RaceDelay)
                        RerollRemote:FireServer("RaceApply")
                    else
                        task.wait(5 + State.RaceDelay)
                    end
                end
            else
                RaceStatus:Append("No character. Spawn first.")
            end
        end
        task.wait(0.5)
    end
end)

-- Trait Auto Roll Loop
task.spawn(function()
    while true do
        if State.AutoTraitRoll then
            local char = GetCharacter()
            if char then
                local currentTraits = GetTraits()
                
                if IsTargetTrait(currentTraits) then
                    TraitStatus:Append("Target trait found!")
                    State.AutoTraitRoll = false
                    pcall(function() TraitToggle:Set(false) end)
                else
                    TraitStatus:Append("Rolling slot " .. State.TraitSlot)
                    RerollRemote:FireServer("Trait", State.TraitSlot)
                    
                    if State.TraitSkipAnimation then
                        task.wait(State.TraitDelay)
                    else
                        task.wait(7 + State.TraitDelay)
                    end
                end
            else
                TraitStatus:Append("No character. Spawn first.")
            end
        end
        task.wait(0.5)
    end
end)

-- Load saved config
pcall(function()
    Rayfield:LoadConfiguration()
end)

print("[GrandBlueHub] Loaded successfully!")
