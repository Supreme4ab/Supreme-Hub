local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager      = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local CommonUtil   = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/SunniHubTest/main/Modules/CommonModule.lua"))()
local AUTLevelUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/SunniHubTest/main/Modules/AUTLevelModule.lua"))()

local Window = Fluent:CreateWindow{
  Title       = "SunnyDale | AUT Hub | By Supreme",
  SubTitle    = "Cool features :drool:",
  TabWidth    = 160,
  Size        = UDim2.fromOffset(580, 460),
  Acrylic     = true,
  Theme       = "Dark",
  MinimizeKey = Enum.KeyCode.LeftControl
}

local Tabs = {
  Main      = Window:AddTab{Title = "Main",      Icon = "home"},
  AutoLevel = Window:AddTab{Title = "Auto-Level",Icon = "activity"},
  Misc      = Window:AddTab{Title = "Misc",      Icon = "map"},
  Settings  = Window:AddTab{Title = "Settings",  Icon = "settings"},
}

Fluent:Notify{
  Title    = "SunnyDale Loaded",
  Content  = "AUT Level Hub is now active.",
  Duration = 5
}

-- Auto-Level UI
Tabs.AutoLevel:AddParagraph{
  Title   = "Auto-Level System",
  Content = "Automatically rolls banners, converts shards, and levels up."
}

local Toggle = Tabs.AutoLevel:AddToggle("AutoFarmToggle", {
  Title       = "Enable Auto-Level",
  Description = "Runs farm + XP logic in loop.",
  Default     = false
})
Toggle:OnChanged(function(state)
  if state then
    AUTLevelUtil.IsMonitoring = true
    AUTLevelUtil.RunLevelWatcher()
    Fluent:Notify{Title = "Auto-Leveling", Content = "Farming started."}
  else
    AUTLevelUtil.Reset()
    Fluent:Notify{Title = "Auto-Leveling", Content = "Farming stopped."}
  end
end)

Tabs.AutoLevel:AddSlider("FarmDelaySlider", {
  Title       = "Farm Delay (Seconds)",
  Description = "Time between shard conversion cycles.",
  Default     = 0.1,
  Min         = 0.05,
  Max         = 1,
  Rounding    = 2,
  Callback    = function(val) AUTLevelUtil.FarmInterval = val end
}):SetValue(0.1)

Tabs.AutoLevel:AddDropdown("ShardRarity", {
  Title       = "Shard Rarity to Sell",
  Description = "Select one or more rarity tiers to farm for XP.",
  Values      = {"Common","Uncommon","Rare","Epic","Legendary","Mythic"},
  Default     = {"Common"},
  Multi       = true,
  Callback    = function(rarities) AUTLevelUtil.SetShardRarity(rarities) end
}):SetValue({"Common"})

-- Teleports
local selectedTeleport
local locationNames = {}
for name in pairs(AUTLevelUtil.TeleportLocations) do
  table.insert(locationNames, name)
end
table.sort(locationNames)

local section = Tabs.Misc:AddSection("Teleports")
section:AddDropdown("TeleportLocation", {
  Title       = "Choose a Location",
  Description = "Select where to teleport",
  Values      = locationNames,
  Multi       = false,
  Callback    = function(choice) selectedTeleport = AUTLevelUtil.TeleportLocations[choice] end
})

section:AddButton{
  Title       = "Teleport",
  Description = "Instantly teleport to the selected location",
  Callback    = function()
    if not selectedTeleport then
      Fluent:Notify{Title="Teleport Failed",Content="You must select a location.",Duration=3}
      return
    end
    local success, err = pcall(function()
      if not CommonUtil.Teleport(selectedTeleport) then
        error("Teleport returned false")
      end
    end)
    if not success then
      Fluent:Notify{Title="Teleport Error",Content=tostring(err),Duration=5}
    end
  end
}

-- Settings & Save
InterfaceManager:SetLibrary(Fluent)
SaveManager:   SetLibrary(Fluent)
InterfaceManager:SetFolder("SunnyDaleHub")
SaveManager:   SetFolder("SunnyDaleHub/Config")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:   BuildConfigSection(Tabs.Settings)

Window:SelectTab(2)
SaveManager:LoadAutoloadConfig()
