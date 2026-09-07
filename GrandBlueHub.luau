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

if not RerollRemote or not CodesRemote then
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

-- DATA
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

-- STATE
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

-- HELPERS
local function GetCharacter() return LocalPlayer.Character end

local function GetRace()
    local char = GetCharacter()
    if char then
        local obj = char:FindFirstChild("Race")
        if obj then return obj.Value end
    end
    return nil
end

local function GetRaceVariant()
    local char = GetCharacter()
    if char then
        local obj = char:FindFirstChild("RaceVariant")
        if obj then return obj.Value end
    end
    return nil
end

local function GetTraits()
    local char = GetCharacter()
    local traits = {}
    if char then
        local folder = char:FindFirstChild("Traits")
        if folder then
            for _, v in pairs(folder:GetChildren()) do
                table.insert(traits, v.Name)
            end
        end
    end
    return traits
end

local function IsTargetRace(race, variant)
    if #State.TargetRaces == 0 and #State.TargetVariants == 0 then return false end
    local raceMatch = #State.TargetRaces == 0
    local variantMatch = #State.TargetVariants == 0
    if #State.TargetRaces > 0 then
        for _, t in pairs(State.TargetRaces) do
            if t == race then raceMatch = true; break end
        end
    end
    if #State.TargetVariants > 0 then
        for _, t in pairs(State.TargetVariants) do
            if t == variant then variantMatch = true; break end
        end
    end
    return raceMatch and variantMatch
end

local function IsTargetTrait(traits)
    if #State.TargetTraits == 0 and #State.TargetRarities == 0 then return false end
    for _, traitName in pairs(traits) do
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
    text = "Configure your target race and variant, then enable auto roll.",
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
    callback = function(value) State.TargetRaces = value end,
})

RaceTab:CreateDropdown({
    name = "Target Variants",
    description = "Select variants to stop on",
    multiSelect = true,
    options = RaceVariants,
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

TraitTab:CreateDropdown({
    name = "Slot to Roll",
    description = "Which trait slot to reroll",
    options = {"1", "2", "3", "4"},
    value = "1",
    callback = function(value) State.TraitSlot = tonumber(value) end,
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
    description = "Start auto rolling for your target traits",
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

task.spawn(function()
    while true do
        if State.AutoRaceRoll then
            local char = GetCharacter()
            if char then
                local race = GetRace()
                local variant = GetRaceVariant()
                if IsTargetRace(race, variant) then
                    RaceStatus:Append("Target reached: " .. (race or "?") .. " " .. (variant or ""))
                    State.AutoRaceRoll = false
                    pcall(function() RaceToggle:Set(false) end)
                else
                    RaceStatus:Append("Rolling... " .. (race or "None"))
                    RerollRemote:FireServer("Race")
                    if State.RaceSkipAnimation then
                        task.wait(State.RaceDelay)
                        pcall(function() RerollRemote:FireServer("RaceApply") end)
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

task.spawn(function()
    while true do
        if State.AutoTraitRoll then
            local char = GetCharacter()
            if char then
                local traits = GetTraits()
                if IsTargetTrait(traits) then
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

pcall(function() Window:Load() end)
