--[[
    Grand Blue Auto-Roll & Codes
    UI Library: Rayfield Gen2
    Features: Auto Race Roll, Auto Trait Roll, Auto Redeem Codes
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local RerollRemote = Events:WaitForChild("Reroll")
local CodesRemote = Events:WaitForChild("Codes")
local GetDataRemote = Events:WaitForChild("GetData")

-- Load UI Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "Grand Blue Hub",
    LoadingTitle = "Grand Blue Hub",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrandBlueHub",
        FileName = "Settings"
    },
    KeySystem = false,
})

-- ============================================
-- DATA: Races and Traits
-- ============================================

local Races = {
    "Human", "Seafolk", "Skyfolk", "Beastfolk", "Dwarf"
}

local RaceVariants = {
    "Normal", "Long Legged", "Long Armed", "Half Fish", "Celestial", "Cat", "Bunny"
}

local Traits = {
    -- Mythic
    "Will of the King", "Heavenly Restricted", "Limit-Breaker", "Man of Steel", "Beast Tamer",
    -- Legendary
    "Snake", "Swordsman's Shame", "Glass Cannon", "Pyromaniac",
    -- Epic
    "Prodigy", "Usain Bolt", "Flash God", "Ruthless", "Arrogant", "Chameleon", "Second Wind",
    -- Rare
    "Super Stephon Meal", "Fast Learner", "Gifted", "#1 Swimmer", "Gourmand", "Adrenaline", "Escape Artist",
    -- Uncommon
    "Coward", "Foodie", "Talented", "Climber", "Athlete", "Night Owl", "Early Bird",
    -- Common
    "Enduring Speed", "Glutton", "Bargainer", "Pacifist", "Sneaky", "Garbage Collector"
}

local TraitRarities = {
    "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"
}

local Codes = {
    "RollWithIt", "PocketOfStars", "GrandBlueCode", "CelestialBlessing",
    "FruitBasket", "NewYouNewCrew", "10KCCU", "WorldBossBroke",
    "SorryForBreakingGame", "HappySunday", "TwitterGoalReached", "Release!"
}

-- ============================================
-- STATE
-- ============================================

local State = {
    -- Race Roll
    AutoRaceRoll = false,
    TargetRaces = {},
    TargetVariants = {},
    RaceSkipAnimation = true,
    RaceDelay = 2,
    
    -- Trait Roll
    AutoTraitRoll = false,
    TargetTraits = {},
    TargetRarities = {},
    TraitSlot = 1,
    TraitSkipAnimation = true,
    TraitDelay = 2,
    
    -- Codes
    AutoRedeem = false,
    RedeemedCodes = {},
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
        -- Check by name
        if #State.TargetTraits > 0 then
            for _, target in pairs(State.TargetTraits) do
                if target == traitName then
                    return true
                end
            end
        end
        
        -- Check by rarity (would need trait info lookup)
        -- For now, we'll rely on name matching
    end
    
    return false
end

local function FireRaceReroll()
    RerollRemote:FireServer("Race")
end

local function FireRaceApply()
    RerollRemote:FireServer("RaceApply")
end

local function FireTraitReroll(slot)
    RerollRemote:FireServer("Trait", slot or State.TraitSlot)
end

local function RedeemCode(code)
    CodesRemote:FireServer(code)
end

-- ============================================
-- TAB 1: AUTO RACE ROLL
-- ============================================

local RaceTab = Window:CreateTab("Auto Race Roll", 4483362458)

-- Section: Settings
RaceTab:CreateSection("Settings")

local RaceToggle = RaceTab:CreateToggle({
    name = "Enable Auto Race Roll",
    description = "Automatically roll for target race/variant",
    flag = "AutoRaceRoll",
    callback = function(value)
        State.AutoRaceRoll = value
    end,
})

local RaceSkipToggle = RaceTab:CreateToggle({
    name = "Skip Animation",
    description = "Skip spin animation (experimental, faster rolling)",
    flag = "RaceSkipAnimation",
    value = true,
    callback = function(value)
        State.RaceSkipAnimation = value
    end,
})

local RaceDelaySlider = RaceTab:CreateSlider({
    name = "Roll Delay (seconds)",
    description = "Delay between rolls",
    range = {1, 10},
    increment = 0.5,
    value = 2,
    suffix = "s",
    flag = "RaceDelay",
    callback = function(value)
        State.RaceDelay = value
    end,
})

-- Section: Targets
RaceTab:CreateSection("Target Race(s)")

local RaceDropdown = RaceTab:CreateDropdown({
    name = "Target Races",
    description = "Select which races to stop on",
    multiSelect = true,
    options = Races,
    flag = "TargetRaces",
    callback = function(value)
        State.TargetRaces = value
    end,
})

local VariantDropdown = RaceTab:CreateDropdown({
    name = "Target Variants",
    description = "Select which variants to stop on",
    multiSelect = true,
    options = RaceVariants,
    flag = "TargetVariants",
    callback = function(value)
        State.TargetVariants = value
    end,
})

-- Section: Status
RaceTab:CreateSection("Status")

local RaceStatus = RaceTab:CreateConsole({
    name = "Roll Status",
    height = 100,
    follow = true,
    maxLines = 50,
})

-- ============================================
-- TAB 2: AUTO TRAIT ROLL
-- ============================================

local TraitTab = Window:CreateTab("Auto Trait Roll", 4483362458)

-- Section: Settings
TraitTab:CreateSection("Settings")

local TraitToggle = TraitTab:CreateToggle({
    name = "Enable Auto Trait Roll",
    description = "Automatically roll for target traits",
    flag = "AutoTraitRoll",
    callback = function(value)
        State.AutoTraitRoll = value
    end,
})

local TraitSkipToggle = TraitTab:CreateToggle({
    name = "Skip Animation",
    description = "Skip spin animation (experimental, faster rolling)",
    flag = "TraitSkipAnimation",
    value = true,
    callback = function(value)
        State.TraitSkipAnimation = value
    end,
})

local TraitDelaySlider = TraitTab:CreateSlider({
    name = "Roll Delay (seconds)",
    description = "Delay between rolls",
    range = {1, 10},
    increment = 0.5,
    value = 2,
    suffix = "s",
    flag = "TraitDelay",
    callback = function(value)
        State.TraitDelay = value
    end,
})

local TraitSlotDropdown = TraitTab:CreateDropdown({
    name = "Slot to Roll",
    description = "Which trait slot to reroll",
    options = {"1", "2", "3", "4"},
    value = "1",
    flag = "TraitSlot",
    callback = function(value)
        State.TraitSlot = tonumber(value)
    end,
})

-- Section: Targets
TraitTab:CreateSection("Target Trait(s)")

local TraitDropdown = TraitTab:CreateDropdown({
    name = "Target Traits",
    description = "Select specific traits to stop on",
    multiSelect = true,
    options = Traits,
    flag = "TargetTraits",
    callback = function(value)
        State.TargetTraits = value
    end,
})

local RarityDropdown = TraitTab:CreateDropdown({
    name = "Target Rarities",
    description = "Stop on any trait of these rarities",
    multiSelect = true,
    options = TraitRarities,
    flag = "TargetRarities",
    callback = function(value)
        State.TargetRarities = value
    end,
})

-- Section: Status
TraitTab:CreateSection("Status")

local TraitStatus = TraitTab:CreateConsole({
    name = "Roll Status",
    height = 100,
    follow = true,
    maxLines = 50,
})

-- ============================================
-- TAB 3: AUTO REDEEM CODES
-- ============================================

local CodesTab = Window:CreateTab("Auto Codes", 4483362458)

-- Section: Settings
CodesTab:CreateSection("Settings")

local CodesToggle = CodesTab:CreateToggle({
    name = "Auto Redeem on Load",
    description = "Automatically redeem all codes when script loads",
    flag = "AutoRedeem",
    callback = function(value)
        State.AutoRedeem = value
        if value then
            -- Redeem all codes
            task.spawn(function()
                for _, code in pairs(Codes) do
                    if not State.RedeemedCodes[code] then
                        CodesRemote:FireServer(code)
                        State.RedeemedCodes[code] = true
                        CodesStatus:Append("Redeemed: " .. code)
                        task.wait(1)
                    end
                end
                CodesStatus:Append("All codes redeemed!")
            end)
        end
    end,
})

local RedeemButton = CodesTab:CreateButton({
    name = "Redeem All Codes Now",
    description = "Click to redeem all codes",
    callback = function()
        task.spawn(function()
            CodesStatus:Append("Starting code redemption...")
            for _, code in pairs(Codes) do
                if not State.RedeemedCodes[code] then
                    CodesRemote:FireServer(code)
                    State.RedeemedCodes[code] = true
                    CodesStatus:Append("Redeemed: " .. code)
                    task.wait(1)
                else
                    CodesStatus:Append("Already redeemed: " .. code)
                end
            end
            CodesStatus:Append("Done!")
        end)
    end,
})

-- Section: Status
CodesTab:CreateSection("Status")

local CodesStatus = CodesTab:CreateConsole({
    name = "Redemption Status",
    height = 150,
    follow = true,
    maxLines = 100,
})

-- Section: Code List
CodesTab:CreateSection("Available Codes")

CodesTab:CreateConsole({
    name = "Code List",
    text = table.concat(Codes, "\n"),
    height = 200,
})

-- ============================================
-- MAIN LOOP: AUTO RACE ROLL
-- ============================================

task.spawn(function()
    while true do
        if State.AutoRaceRoll then
            local char = GetCharacter()
            if char then
                local currentRace = GetRace()
                local currentVariant = GetRaceVariant()
                
                -- Check if we already have target
                if IsTargetRace(currentRace, currentVariant) then
                    RaceStatus:Append("✅ Target reached: " .. currentRace .. " (" .. (currentVariant or "Normal") .. ")")
                    State.AutoRaceRoll = false
                    RaceToggle:Set(false)
                else
                    RaceStatus:Append("Rolling... Current: " .. (currentRace or "None"))
                    
                    -- Fire reroll
                    FireRaceReroll()
                    
                    if State.RaceSkipAnimation then
                        -- Wait only for server cooldown, not animation
                        task.wait(State.RaceDelay)
                        
                        -- Try to apply immediately
                        FireRaceApply()
                    else
                        -- Wait for full animation + buffer
                        task.wait(5 + State.RaceDelay)
                    end
                end
            else
                RaceStatus:Append("⚠️ No character found. Please spawn first.")
            end
        end
        task.wait(0.5)
    end
end)

-- ============================================
-- MAIN LOOP: AUTO TRAIT ROLL
-- ============================================

task.spawn(function()
    while true do
        if State.AutoTraitRoll then
            local char = GetCharacter()
            if char then
                local currentTraits = GetTraits()
                
                -- Check if we already have target
                if IsTargetTrait(currentTraits) then
                    TraitStatus:Append("✅ Target trait found!")
                    State.AutoTraitRoll = false
                    TraitToggle:Set(false)
                else
                    TraitStatus:Append("Rolling slot " .. State.TraitSlot .. "...")
                    
                    -- Fire reroll
                    FireTraitReroll(State.TraitSlot)
                    
                    if State.TraitSkipAnimation then
                        -- Wait only for server cooldown
                        task.wait(State.TraitDelay)
                    else
                        -- Wait for full animation
                        task.wait(7 + State.TraitDelay)
                    end
                end
            else
                TraitStatus:Append("⚠️ No character found. Please spawn first.")
            end
        end
        task.wait(0.5)
    end
end)

-- ============================================
-- INITIALIZE
-- ============================================

Rayfield:LoadConfiguration()

-- Welcome message
task.spawn(function()
    task.wait(2)
    CodesStatus:Append("Grand Blue Hub loaded!")
    CodesStatus:Append("Codes available: " .. #Codes)
    RaceStatus:Append("Ready to roll!")
    TraitStatus:Append("Ready to roll!")
end)
