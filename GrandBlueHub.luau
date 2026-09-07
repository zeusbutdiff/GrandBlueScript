--[[
    Grand Blue Auto-Roll & Codes
    UI Library: Rayfield Gen2
    Features: Auto Race Roll, Auto Trait Roll, Auto Redeem Codes
    Animation skip via fast-tween override
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
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
    name = "Callie Hub",
    subtitle = "By SHEN",
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

local TraitRarities = {"Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}

local TraitNames = {
    "Beast Tamer", "Copycat", "Gaudy", "Limit-Breaker", "Man of Steel", "Maniac",
    "Battle Tempo", "Glass Cannon", "Predator", "Protagonist", "Pyromaniac",
    "Arrogant", "Assassin", "Chameleon", "Marathoner", "Prodigy", "Second Wind", "Sturdy Guard",
    "Adrenaline", "Escape Artist", "Gourmand", "Iron Will", "Nimble",
    "Athlete", "Climber", "Coward", "Early Bird", "Vengeful",
    "Bargainer", "Diver", "Enduring Speed", "Garbage Collector", "Hoarder", "Pacifist", "Pitcher",
}

local TraitRarityMap = {
    ["Beast Tamer"] = "Mythic", ["Copycat"] = "Mythic", ["Gaudy"] = "Mythic",
    ["Limit-Breaker"] = "Mythic", ["Man of Steel"] = "Mythic", ["Maniac"] = "Mythic",
    ["Battle Tempo"] = "Legendary", ["Glass Cannon"] = "Legendary",
    ["Predator"] = "Legendary", ["Protagonist"] = "Legendary", ["Pyromaniac"] = "Legendary",
    ["Arrogant"] = "Epic", ["Assassin"] = "Epic", ["Chameleon"] = "Epic",
    ["Marathoner"] = "Epic", ["Prodigy"] = "Epic", ["Second Wind"] = "Epic", ["Sturdy Guard"] = "Epic",
    ["Adrenaline"] = "Rare", ["Escape Artist"] = "Rare", ["Gourmand"] = "Rare",
    ["Iron Will"] = "Rare", ["Nimble"] = "Rare",
    ["Athlete"] = "Uncommon", ["Climber"] = "Uncommon", ["Coward"] = "Uncommon",
    ["Early Bird"] = "Uncommon", ["Vengeful"] = "Uncommon",
    ["Bargainer"] = "Common", ["Diver"] = "Common", ["Enduring Speed"] = "Common",
    ["Garbage Collector"] = "Common", ["Hoarder"] = "Common", ["Pacifist"] = "Common", ["Pitcher"] = "Common",
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
    AutoRaceRoll = false,
    TargetRaces = {},
    TargetVariants = {},
    AutoTraitRoll = false,
    TargetTraits = {},
    TargetRarities = {},
    RollSlot1 = false,
    RollSlot2 = false,
    RollSlot3 = false,
    AutoQuest = false,
    QuestStatus = "Idle",
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
        for _, traitName in pairs(traitData) do
            if traitName and traitName ~= false and traitName ~= "None" then
                table.insert(traitNames, traitName)
            end
        end
        return traitNames
    end
    return {}
end

local function GetSlotTraitName(slotNum)
    local ok, traitData = pcall(function()
        return GetDataRemote:InvokeServer("Traits")
    end)
    if ok and traitData then
        local key = "Slot " .. slotNum
        local traitName = traitData[key]
        if traitName and traitName ~= false and traitName ~= "None" then
            return traitName
        end
    end
    return nil
end

local function IsTargetSingleTrait(traitName)
    if not traitName then return false end
    if #State.TargetTraits == 0 and #State.TargetRarities == 0 then return false end
    for _, target in pairs(State.TargetTraits) do
        if target == traitName then return true end
    end
    if #State.TargetRarities > 0 then
        local rarity = TraitRarityMap[traitName]
        if rarity then
            for _, targetRarity in pairs(State.TargetRarities) do
                if targetRarity == rarity then return true end
            end
        end
    end
    return false
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
        if #State.TargetRarities > 0 then
            local rarity = TraitRarityMap[traitName]
            if rarity then
                for _, targetRarity in pairs(State.TargetRarities) do
                    if targetRarity == rarity then return true end
                end
            end
        end
    end
    return false
end

local function GetActiveSlots()
    local slots = {}
    if State.RollSlot1 then table.insert(slots, 1) end
    if State.RollSlot2 then table.insert(slots, 2) end
    if State.RollSlot3 then table.insert(slots, 3) end
    return slots
end

-- ============================================
-- ANIMATION SKIP
-- ============================================

local function SkipTraitAnimation(slotNum)
    pcall(function()
        local gui = LocalPlayer.PlayerGui:FindFirstChild("CharacterCustomization")
        if not gui then return end
        local right = gui:FindFirstChild("Right", true)
        if not right then return end
        local traits = right:FindFirstChild("Traits", true)
        if not traits then return end
        local slot = traits:FindFirstChild("Slot " .. slotNum)
        if not slot then return end

        local spinFrame = slot:FindFirstChild("SpinFrame", true)
        if not spinFrame then return end
        local bg = spinFrame:FindFirstChild("BackgroundFrame", true)
        if not bg then return end
        local mf = bg:FindFirstChild("MainFrame", true)
        if not mf then return end

        for _ = 1, 10 do
            task.wait(0.1)
            if slot:GetAttribute("Spinning") == true then break end
        end
        if not slot:GetAttribute("Spinning") then return end

        local goal = mf:GetAttribute("Goal")
        if not goal then return end

        slot:SetAttribute("Skipped", true)
        local fastInfo = TweenInfo.new(0.25, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
        local fastTween = TweenService:Create(mf, fastInfo, {Position = goal})
        fastTween:Play()
        task.wait(0.35)
    end)
end

local function SkipRaceAnimation()
    pcall(function()
        local gui = LocalPlayer.PlayerGui:FindFirstChild("CharacterCustomization")
        if not gui then return end
        local right = gui:FindFirstChild("Right", true)
        if not right then return end
        local race = right:FindFirstChild("Race", true)
        if not race then return end
        local spinner = race:FindFirstChild("Spinner", true)
        if not spinner then return end
        local bg = spinner:FindFirstChild("Frame", true)
        if not bg then return end
        bg = bg:FindFirstChild("BackgroundFrame", true)
        if not bg then return end
        local mf = bg:FindFirstChild("MainFrame", true)
        if not mf then return end

        for _ = 1, 10 do
            task.wait(0.1)
            if mf.Visible then break end
        end
        if not mf.Visible then return end

        local fastInfo = TweenInfo.new(0.25, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
        local fastTween = TweenService:Create(mf, fastInfo, {Position = UDim2.new(0.5, 0, -2, 0)})
        fastTween:Play()
        task.wait(0.35)
    end)
end

-- ============================================
-- AUTO QUEST HELPERS
-- ============================================

local VK_F = 0x46
local VK_Q = 0x51
local VK_L = 0x4C

local ClientCache = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ClientCache"))

local function FindNPC(npcName)
    local ok, result = pcall(function()
        local folder = workspace:FindFirstChild("AA IMPORTANT")
        if not folder then return nil end
        local npcs = folder:FindFirstChild("DialogueNPCs")
        if not npcs then return nil end
        for _, zone in pairs(npcs:GetChildren()) do
            for _, npc in pairs(zone:GetChildren()) do
                if npc.Name == npcName then
                    return npc
                end
            end
        end
        return nil
    end)
    return ok and result or nil
end

local function TeleportToNPC(npcName)
    local npc = FindNPC(npcName)
    if not npc then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local npcHRP = npc:FindFirstChild("HumanoidRootPart")
    if not hrp or not npcHRP then return false end
    local offset = npcHRP.CFrame.LookVector * 5
    hrp.CFrame = CFrame.new(npcHRP.Position + offset, npcHRP.Position)
    return true
end

local function WaitForDialogue(timeout)
    timeout = timeout or 10
    local gui = LocalPlayer.PlayerGui:FindFirstChild("DialogueUI")
    if not gui then return false end
    local t = tick()
    while not gui.Enabled and (tick() - t) < timeout do
        task.wait(0.2)
    end
    return gui.Enabled
end

local function ClickGuiButton(button)
    if not button then return false end
    local ok = pcall(function()
        local pos = button.AbsolutePosition
        local size = button.AbsoluteSize
        local x = pos.X + size.X / 2
        local y = pos.Y + size.Y / 2
        mousemoveabs(x, y)
        task.wait(0.1)
        mouse1click()
    end)
    return ok
end

local function ClickThroughDialogue()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("DialogueUI")
    if not gui then return end
    local main = gui:FindFirstChild("Main")
    if not main then return end
    for _ = 1, 20 do
        if not gui.Enabled then break end
        local clicked = false
        for _, child in pairs(main:GetChildren()) do
            if child:IsA("Frame") and child.Visible then
                local btn = child:FindFirstChild("ImageButton")
                if btn and btn.Visible then
                    ClickGuiButton(btn)
                    clicked = true
                    task.wait(0.5)
                    break
                end
            end
        end
        if not clicked then break end
    end
end

local function AcceptQuest()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("DialogueUI")
    if not gui then return false end
    local main = gui:FindFirstChild("Main")
    if not main then return false end
    for _, child in pairs(main:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Accept" and child.Visible then
            local btn = child:FindFirstChild("ImageButton")
            if btn then
                ClickGuiButton(btn)
                return true
            end
        end
    end
    return false
end

local function DoBlock()
    pcall(function() keypress(VK_F) end)
    task.wait(1.5)
    pcall(function() keyrelease(VK_F) end)
end

local function DoDash(amount)
    for _ = 1, amount do
        pcall(function() keypress(VK_Q) end)
        task.wait(0.1)
        pcall(function() keyrelease(VK_Q) end)
        task.wait(0.5)
    end
end

local function DoTalk(npcName)
    if not TeleportToNPC(npcName) then return false end
    task.wait(1)
    if not WaitForDialogue(8) then return false end
    task.wait(0.3)
    ClickThroughDialogue()
    task.wait(0.5)
    AcceptQuest()
    return true
end

local function DoHit(targetName, amount)
    local target = workspace:FindFirstChild(targetName, true)
    if not target then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    local targetPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
    if not hrp or not humanoid or not targetPart then return false end
    humanoid:MoveTo(targetPart.Position)
    task.wait(2)
    for _ = 1, amount do
        pcall(function() mouse1press() end)
        task.wait(0.3)
        pcall(function() mouse1release() end)
        task.wait(0.3)
    end
    return true
end

local function DoCast(skillName)
    local hotbar = LocalPlayer.PlayerGui:FindFirstChild("Hotbar")
    if not hotbar then return false end
    for _, slot in pairs(hotbar:GetDescendants()) do
        if slot:IsA("Frame") then
            local label = slot:FindFirstChild("TextLabel")
            if label and label.Text == skillName then
                local btn = slot:FindFirstChild("ImageButton") or slot:FindFirstChildWhichIsA("GuiButton")
                if btn then
                    ClickGuiButton(btn)
                    return true
                end
            end
        end
    end
    return false
end

local function DoEquipSkill(skillName)
    local inventory = LocalPlayer.PlayerGui:FindFirstChild("Inventory")
    if not inventory then return false end
    for _, slot in pairs(inventory:GetDescendants()) do
        if slot:IsA("Frame") then
            local label = slot:FindFirstChild("TextLabel")
            if label and label.Text == skillName then
                local btn = slot:FindFirstChild("ImageButton") or slot:FindFirstChildWhichIsA("GuiButton")
                if btn then
                    ClickGuiButton(btn)
                    return true
                end
            end
        end
    end
    return false
end

local function DoOpen(elementName)
    if elementName == "Logbook" then
        pcall(function() keyclick(VK_L) end)
        return true
    end
    return false
end

local function GetActiveQuest()
    local ok, result = pcall(function()
        local quests = ClientCache.Data.Quests
        if #quests == 0 then return nil end
        return quests[1]
    end)
    return ok and result or nil
end

local function GetCurrentStage(quest)
    if not quest then return nil, nil end
    for i, stage in ipairs(quest.Stages) do
        if not stage.Complete then
            return i, stage
        end
    end
    return nil, nil
end

local function DoQuestAction(condition)
    if condition.Complete then return true end
    if condition.Type == "Block" then
        DoBlock()
        return true
    elseif condition.Type == "Dash" then
        local needed = (condition.Target.RequiredAmount or 1) - (condition.Target.Amount or 0)
        if needed > 0 then DoDash(needed) end
        return true
    elseif condition.Type == "Talk" then
        return DoTalk(condition.Target.Name)
    elseif condition.Type == "Hit" then
        local needed = (condition.Target.RequiredAmount or 1) - (condition.Target.Amount or 0)
        if needed > 0 then DoHit(condition.Target.Name, needed) end
        return true
    elseif condition.Type == "Cast" then
        return DoCast(condition.Target.Name)
    elseif condition.Type == "EquipSkill" then
        return DoEquipSkill(condition.Target.Name)
    elseif condition.Type == "Open" then
        return DoOpen(condition.Target.Name)
    end
    return false
end

-- ============================================
-- TAB 1: AUTO RACE ROLL
-- ============================================

local RaceTab = Window:CreateTab({ name = "Auto Race Roll" })

RaceTab:CreateText({
    name = "Race Roll Info",
    text = "Human(74%): Normal, Half Fish, Long Armed, Long Legged, Celestial. Seafolk(15%), Skyfolk(5%), Beastfolk(4%): Cat, Bunny. Dwarf(2%).",
})

RaceTab:CreateSection({ name = "Target Selection" })

RaceTab:CreateDropdown({
    name = "Target Races",
    description = "Select races to stop on",
    multiSelect = true,
    options = {
        "Human (74%)",
        "Seafolk (15%)",
        "Skyfolk (5%)",
        "Beastfolk (4%)",
        "Dwarf (2%)",
    },
    callback = function(value)
        local mapped = {}
        for _, v in pairs(value) do
            local name = v:match("^(.+) %(")
            if name then table.insert(mapped, name) end
        end
        State.TargetRaces = mapped
    end,
})

RaceTab:CreateDropdown({
    name = "Target Variants",
    description = "Select variants to stop on. Each variant belongs to a specific race.",
    multiSelect = true,
    options = {
        "Half Fish (Human - 1%)",
        "Celestial (Human - 0.1%)",
        "Long Armed (Human - 5%)",
        "Long Legged (Human - 5%)",
        "Cat (Beastfolk - 50%)",
        "Bunny (Beastfolk - 50%)",
    },
    callback = function(value)
        local mapped = {}
        for _, v in pairs(value) do
            local name = v:match("^(.+) %(")
            if name then table.insert(mapped, name) end
        end
        State.TargetVariants = mapped
    end,
})

RaceTab:CreateSection({ name = "Control" })

local RaceToggle = RaceTab:CreateToggle({
    name = "Enable Auto Race Roll",
    description = "Start auto rolling for your target race/variant",
    callback = function(value) State.AutoRaceRoll = value end,
})

-- ============================================
-- TAB 2: AUTO TRAIT ROLL
-- ============================================

local TraitTab = Window:CreateTab({ name = "Auto Trait Roll" })

TraitTab:CreateText({
    name = "Trait Roll Settings",
    text = "Enable the slots you want to roll. Each slot rolls with 5s cooldown.",
})

TraitTab:CreateSection({ name = "Slots to Roll" })

local Slot1Toggle = TraitTab:CreateToggle({
    name = "Roll Slot 1",
    description = "Include slot 1 in auto roll",
    callback = function(value) State.RollSlot1 = value end,
})

local Slot2Toggle = TraitTab:CreateToggle({
    name = "Roll Slot 2",
    description = "Include slot 2 in auto roll",
    callback = function(value) State.RollSlot2 = value end,
})

local Slot3Toggle = TraitTab:CreateToggle({
    name = "Roll Slot 3",
    description = "Include slot 3 in auto roll",
    callback = function(value) State.RollSlot3 = value end,
})

TraitTab:CreateSection({ name = "Target Selection" })

TraitTab:CreateDropdown({
    name = "Target Traits",
    description = "Select specific traits to stop on",
    multiSelect = true,
    options = TraitNames,
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

local SlotToggles = {
    [1] = Slot1Toggle,
    [2] = Slot2Toggle,
    [3] = Slot3Toggle,
}

local SlotStateKeys = {
    [1] = "RollSlot1",
    [2] = "RollSlot2",
    [3] = "RollSlot3",
}

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
-- TAB 4: AUTO QUEST
-- ============================================

local QuestTab = Window:CreateTab({ name = "Auto Quest" })

QuestTab:CreateText({
    name = "Auto Quest Info",
    text = "Automatically progresses through the Officer Graves quest chain and beyond. Handles Talk, Block, Dash, Hit, Cast, and Open objectives.",
})

QuestTab:CreateSection({ name = "Not Automatable" })

QuestTab:CreateText({
    name = "Limitations",
    text = "Invest Stat Points (server checks unspent points), Level Gates (some quests require min level), Purchase/Smelt/Upgrade (need station proximity), Steal/CashOut (complex interactions), EquipSkill (inventory UI varies per quest), Cast (hotbar UI varies), Shoot (aim-dependent).",
})

QuestTab:CreateSection({ name = "Control" })

local QuestStatusText = QuestTab:CreateText({
    name = "Status",
    text = "Idle",
})

local QuestToggle = QuestTab:CreateToggle({
    name = "Enable Auto Quest",
    description = "Automatically progress through quest objectives",
    callback = function(value)
        State.AutoQuest = value
        if value then
            State.QuestStatus = "Starting..."
        else
            State.QuestStatus = "Idle"
        end
    end,
})

QuestTab:CreateButton({
    name = "Force Block (Test)",
    description = "Hold F to block once",
    callback = function()
        task.spawn(function()
            DoBlock()
        end)
    end,
})

QuestTab:CreateButton({
    name = "Force Talk to Graves (Test)",
    description = "Teleport to Officer Graves and start dialogue",
    callback = function()
        task.spawn(function()
            DoTalk("Officer Graves")
        end)
    end,
})

-- ============================================
-- AUTO ROLL LOOPS
-- ============================================

local COOLDOWN = 5.5

-- Race auto roll
task.spawn(function()
    while true do
        if State.AutoRaceRoll then
            local race, variant = GetRace()
            if race then
                if IsTargetRace(race, variant) then
                    State.AutoRaceRoll = false
                    pcall(function() RaceToggle:Set(false) end)
                else
                    pcall(function() RerollRemote:FireServer("Race") end)
                    task.spawn(function() SkipRaceAnimation() end)
                    task.wait(COOLDOWN)
                end
            else
                task.wait(2)
            end
        end
        task.wait(0.25)
    end
end)

-- Trait auto roll - fires all active slots at once, server queues them
task.spawn(function()
    while true do
        if State.AutoTraitRoll then
            local activeSlots = GetActiveSlots()
            if #activeSlots > 0 then
                local fired = {}
                for _, slotNum in pairs(activeSlots) do
                    if State.AutoTraitRoll and State[SlotStateKeys[slotNum]] then
                        pcall(function() RerollRemote:FireServer("Trait", slotNum) end)
                        task.spawn(function() SkipTraitAnimation(slotNum) end)
                        table.insert(fired, slotNum)
                        task.wait(0.5)
                    end
                end

                if #fired > 0 then
                    task.wait(COOLDOWN - 0.5)
                end

                for _, slotNum in pairs(fired) do
                    if State.AutoTraitRoll and State[SlotStateKeys[slotNum]] then
                        local traitName = GetSlotTraitName(slotNum)
                        if traitName and IsTargetSingleTrait(traitName) then
                            State[SlotStateKeys[slotNum]] = false
                            pcall(function() SlotToggles[slotNum]:Set(false) end)
                        end
                    end
                end

                if #GetActiveSlots() == 0 then
                    State.AutoTraitRoll = false
                    pcall(function() TraitToggle:Set(false) end)
                end
            else
                State.AutoTraitRoll = false
                pcall(function() TraitToggle:Set(false) end)
            end
        end
        task.wait(0.25)
    end
end)

-- ============================================
-- AUTO QUEST LOOP
-- ============================================

task.spawn(function()
    while true do
        if State.AutoQuest then
            local quest = GetActiveQuest()
            if not quest then
                State.QuestStatus = "No active quest"
                if QuestStatusText then pcall(function() QuestStatusText:Set("No active quest") end) end
                task.wait(2)
            else
                local stageIndex, stage = GetCurrentStage(quest)
                if not stageIndex then
                    State.QuestStatus = "Quest complete: " .. (quest.Title or "Unknown")
                    if QuestStatusText then pcall(function() QuestStatusText:Set(State.QuestStatus) end) end
                    task.wait(2)
                else
                    local stageTitle = stage.Title or "Unknown"
                    State.QuestStatus = string.format("%s [%d/%d] %s", quest.Title or "?", stageIndex, #quest.Stages, stageTitle)
                    if QuestStatusText then pcall(function() QuestStatusText:Set(State.QuestStatus) end) end

                    local allComplete = true
                    for _, cond in ipairs(stage.Conditions or {}) do
                        if not cond.Complete then
                            allComplete = false
                            local acted = DoQuestAction(cond)
                            if acted then
                                task.wait(2)
                            else
                                State.QuestStatus = "Blocked: " .. (cond.Type or "?") .. " - " .. (cond.Target and cond.Target.Name or "?")
                                if QuestStatusText then pcall(function() QuestStatusText:Set(State.QuestStatus) end) end
                                task.wait(5)
                            end
                        end
                    end

                    if allComplete then
                        task.wait(1)
                    end
                end
            end
        else
            State.QuestStatus = "Idle"
            if QuestStatusText then pcall(function() QuestStatusText:Set("Idle") end) end
        end
        task.wait(0.5)
    end
end)

pcall(function() Window:Load() end)
