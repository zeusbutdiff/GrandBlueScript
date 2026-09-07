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
    RaceSkipAnimation = true,
    RaceDelay = 2,
    AutoTraitRoll = false,
    TargetTraits = {},
    TargetRarities = {},
    TraitSlots = {},
    TraitSkipAnimation = true,
    TraitDelay = 2,
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
    local data = GetCharacterData()
    if data and data.Traits then
        local traitNames = {}
        for _, trait in pairs(data.Traits) do
            if trait.Name then
                table.insert(traitNames, trait.Name)
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

-- ============================================
-- TAB 1: AUTO RACE ROLL
-- ============================================

local RaceTab = Window:CreateTab({ name = "Auto Race Roll" })

RaceTab:CreateText({
    name = "Race Roll Settings",
    text = "Half Fish = Seafolk, Celestial = Skyfolk, Cat/Bunny = Beastfolk, Long Legged/Long Armed = Dwarf. Human has no variants.",
})

RaceTab:CreateToggle({
    name = "Skip Animation",
    description = "Skip spin animation for faster rolling",
    value = true,
    callback = function(value) State.RaceSkipAnimation = value end,
})

RaceTab:CreateSlider({
    name = "Roll Delay",
    description = "Delay between rolls in seconds",
    range = {1, 10},
    increment = 0.5,
    value = 2,
    suffix = "s",
    callback = function(value) State.RaceDelay = value end,
})

RaceTab:CreateSection({ name = "Target Selection" })

RaceTab:CreateDropdown({
    name = "Target Races",
    description = "Select races to stop on",
    multiSelect = true,
    options = Races,
    callback = function(value)
        State.TargetRaces = value
    end,
})

RaceTab:CreateDropdown({
    name = "Target Variants",
    description = "Half Fish=Seafolk, Celestial=Skyfolk, Cat/Bunny=Beastfolk, Long=",
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
    text = "Configure your target traits/rarities, then enable auto roll.",
})

TraitTab:CreateToggle({
    name = "Skip Animation",
    description = "Skip spin animation for faster rolling",
    value = true,
    callback = function(value) State.TraitSkipAnimation = value end,
})

TraitTab:CreateSlider({
    name = "Roll Delay",
    description = "Delay between rolls in seconds",
    range = {1, 10},
    increment = 0.5,
    value = 2,
    suffix = "s",
    callback = function(value) State.TraitDelay = value end,
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

-- Race auto roll
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
                    RaceStatus:Append("Rolling... Current: " .. race .. " " .. (variant or ""))
                    RerollRemote:FireServer("Race")
                    task.wait(State.RaceDelay)
                end
            else
                RaceStatus:Append("Waiting for character data...")
            end
        end
        task.wait(0.5)
    end
end)

-- Trait auto roll - rolls all selected slots
task.spawn(function()
    while true do
        if State.AutoTraitRoll and #State.TraitSlots > 0 then
            local traitNames = GetTraits()
            if #traitNames > 0 then
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
                            task.wait(State.TraitDelay)
                        end
                    end
                end
            else
                TraitStatus:Append("Waiting for character data...")
            end
        end
        task.wait(0.5)
    end
end)

pcall(function() Window:Load() end)
