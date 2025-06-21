if getgenv().SupremeHubLoaded then
    return
end
getgenv().SupremeHubLoaded = true

local function safeLoad(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("Failed to load: " .. url)
        return nil
    end
    return result
end

local rolibwaita = safeLoad("https://codeberg.org/Blukez/rolibwaita/raw/branch/master/Source.lua")
local CommonModule = safeLoad("https://raw.githubusercontent.com/Supreme4ab/Supreme-Hub/main/Main/Modules/CommonModule.lua")
local AUTMainModule = safeLoad("https://raw.githubusercontent.com/Supreme4ab/Supreme-Hub/main/Modules/AUTMainModule.lua")

if not rolibwaita or not CommonModule or not AUTMainModule then
    warn("One or more required modules failed to load. Aborting.")
    return
end

local Window = rolibwaita:NewWindow({
    Name = "Supreme Hub | AUT | By Supreme",
    Keybind = "LeftControl",
    UseCoreGui = true,
    PrintCredits = true
})

local TabMain = Window:NewTab({Name = "Main", Icon = "home"})
local TabAutoLevel = Window:NewTab({Name = "Auto-Level", Icon = "activity"})
local TabMisc = Window:NewTab({Name = "Misc", Icon = "map"})
local TabSettings = Window:NewTab({Name = "Settings", Icon = "settings"})

local SectionAutoLevel = TabAutoLevel:NewSection({
    Name = "Auto-Level System",
    Description = "Automatically rolls banners, converts shards, and levels up."
})

local ToggleAutoFarm = SectionAutoLevel:NewToggle({
    Name = "Enable Auto-Level",
    Description = "Runs farm + XP logic in loop.",
    CurrentState = false,
    Callback = function(state)
        if state then
            AUTMainModule.IsMonitoring = true
            AUTMainModule.RunLevelWatcher()
        else
            AUTMainModule.Reset()
        end
    end
})

SectionAutoLevel:NewSlider({
    Name = "Farm Delay (Seconds)",
    Description = "Time between shard conversion cycles.",
    MinMax = {0.05, 1},
    Increment = 0.01,
    CurrentValue = 0.1,
    Callback = function(val)
        AUTMainModule.FarmInterval = val
    end
})

local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
local selectedRarities = {}
for _, rarity in ipairs(rarities) do
    local default = rarity == "Common"
    selectedRarities[rarity] = default
    SectionAutoLevel:NewToggle({
        Name = rarity .. " Shards",
        Description = "Include " .. rarity .. " shards in farming.",
        CurrentState = default,
        Callback = function(state)
            selectedRarities[rarity] = state
            local activeRarities = {}
            for r, s in pairs(selectedRarities) do
                if s then table.insert(activeRarities, r) end
            end
            AUTMainModule.SetShardRarity(activeRarities)
        end
    })
end

local SectionTeleports = TabMisc:NewSection({Name = "Teleports"})
local locationNames = {}
for name in pairs(AUTMainModule.TeleportLocations or {}) do
    table.insert(locationNames, name)
end
table.sort(locationNames)

local selectedLocation
SectionTeleports:NewDropdown({
    Name = "Choose a Location",
    Description = "Select where to teleport",
    Choices = locationNames,
    CurrentState = locationNames[1] or "",
    Callback = function(choice)
        selectedLocation = choice
    end
})

SectionTeleports:NewButton({
    Name = "Teleport",
    Description = "Instantly teleport to the selected location",
    Callback = function()
        if not selectedLocation then
            return
        end
        local position = AUTMainModule.TeleportLocations[selectedLocation]
        if position then
            local success, err = pcall(function()
                CommonModule.Teleport(position)
            end)
            if not success then
                warn("Teleport error: " .. tostring(err))
            end
        end
    end
})

local SectionStand = TabMisc:NewSection({Name = "Stand"})
SectionStand:NewToggle({
    Name = "Auto Ascension",
    Description = "Automatically ascend your stand at level 200.",
    CurrentState = false,
    Callback = function(state)
        AUTMainModule.SetAutoAscend(state)
        if state then
            AUTMainModule.IsMonitoring = true
            AUTMainModule.RunLevelWatcher()
        else
            AUTMainModule.Reset()
        end
    end
})

local SectionVisuals = TabMisc:NewSection({Name = "Visuals"})
SectionVisuals:NewToggle({
    Name = "VFX Remover",
    Description = "Removes heavy or distracting visual effects.",
    CurrentState = false,
    Callback = function(state)
        AUTMainModule.SetVFXAutoRemove(state)
    end
})

SectionVisuals:NewToggle({
    Name = "Remove Desert Fog",
    Description = "Disables fog and post-processing in the desert area.",
    CurrentState = false,
    Callback = function(state)
        AUTMainModule.SetFogAutoRemove(state)
    end
})

Window:SelectTab(2)
