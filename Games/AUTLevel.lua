local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local AUTLevelUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/AUTLevelUtil.lua"))()

local Window = Fluent:CreateWindow({
	Title = "SunnyDale | AUT Level Hub | By Supreme",
	SubTitle = "Shard Auto-Level",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = true,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
	Main = Window:AddTab({ Title = "Main", Icon = "activity" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Fluent:Notify({
	Title = "SunnyDale Hub",
	Content = "AUT Auto-Level Hub Loaded.",
	Duration = 5
})

Tabs.Main:AddParagraph({
	Title = "Auto-Level",
	Content = "Auto-Levels you up until maximum level - PS - Uses 10K Shards per cycle (So it uses a lot lol)."
})

local Toggle = Tabs.Main:AddToggle("AutoFarmToggle", {
	Title = "Enable Auto-Level",
	Description = "Enabled the Auto Level Farm.",
	Default = false
})

Toggle:OnChanged(function(state)
	if state then
		AUTLevelUtil.IsMonitoring = true
		AUTLevelUtil.RunLevelWatcher()
		Fluent:Notify({ Title = "Farming", Content = "Auto-leveling started." })
	else
		AUTLevelUtil.Reset()
		Fluent:Notify({ Title = "Farming", Content = "Stopped." })
	end
end)

Tabs.Main:AddSlider("FarmDelaySlider", {
	Title = "Farm Delay (Seconds)",
	Description = "Interval Per XP Cycle.",
	Default = 0.1,
	Min = 0.05,
	Max = 1,
	Rounding = 2,
	Callback = function(val)
		AUTLevelUtil.FarmInterval = val
	end
}):SetValue(0.1)

Tabs.Main:AddDropdown("ShardRarity", {
	Title = "Shard Rarity to Sell",
	Description = "Selects the Ability Shards to sell.",
	Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
	Multi = true,
	Default = { "Common" },
	Callback = function(selected)
		local combined = {}
		for _, rarity in ipairs(selected) do
			local list = AUTLevelUtil.ShardRarities[rarity]
			if list then
				for _, id in ipairs(list) do
					table.insert(combined, id)
				end
			end
		end
		AUTLevelUtil.AllowedAbilities = combined
	end
}):SetValue({ "Common" })

InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("SunnyDaleHub")
SaveManager:SetFolder("SunnyDaleHub/Config")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
