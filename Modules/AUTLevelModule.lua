local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local Players = CommonUtil.GetService("Players")

-- Config

local AUTLevelUtil = {}

local TeleportLocations = {
	["Alabasta"] = Vector3.new(2085.529, 945.397, -2417.796),
	["Beach"] = Vector3.new(607.062, 917.219, -1989.912),
	["Boss Spawn Room"] = Vector3.new(19153.26, 910.548, 118.567),
	["Central Wilds"] = Vector3.new(2528.788, 989.488, -544.948),
	["Desert Approach"] = Vector3.new(1983.827, 924.261, -1137.514),
	["Diavolo Spawn"] = Vector3.new(1011.125, 934.362, 2888.195),
	["Floating Village"] = Vector3.new(1222.878, 1015.637, -281.11),
	["Football Field"] = Vector3.new(1980.397, 973.423, -356.92),
	["Goku"] = Vector3.new(2544.647, 916.524, 1828.544),
	["Guardians Spawn Room"] = Vector3.new(3509.697, 937.592, -430.434),
	["Gyro TA1"] = Vector3.new(2070.348, 1074.851, -714.886),
	["Gyro TA2"] = Vector3.new(2272.279, 973.616, 685.383),
	["Gyro TA4"] = Vector3.new(1947.455, 918.397, -2133.456),
	["Infernal Cairn"] = Vector3.new(2699.286, 1007.21, -717.92),
	["Main Subway"] = Vector3.new(2482.364, 973.802, 96.771),
	["Minos Prime"] = Vector3.new(584.819, 1014.65, -433.61),
	["OG Sakuya Room"] = Vector3.new(1967.306, 55.113, -1112.305),
	["Orange Town"] = Vector3.new(-2900.586, 918.631, 15166.34),
	["Park Center"] = Vector3.new(2075.826, 973.99, 280.726),
	["Port"] = Vector3.new(2120.274, 921.774, 937.453),
	["Skaidev"] = Vector3.new(2005.01, 930.397, -2477.821),
	["Shibuya District"] = Vector3.new(-63.721, 4.6, -9939.011),
	["Subway"] = Vector3.new(-16788.955, 7.0, -5982.729),
	["Syrup Spawn"] = Vector3.new(10015.269, -48.41, 30133.928)
}

-- === Auto-Level Configuration ===
local ShardRarities = {
	Common = {
		"ABILITY_14", "ABILITY_1", "ABILITY_10", "ABILITY_10019", "ABILITY_21", "ABILITY_8881"
	},
	Uncommon = {
		"ABILITY_33", "ABILITY_7", "ABILITY_7955", "ABILITY_119", "ABILITY_22"
	},
	Rare = {
		"ABILITY_6", "ABILITY_9", "ABILITY_50923", "ABILITY_350", "ABILITY_2000", "ABILITY_300000",
		"ABILITY_4", "ABILITY_2", "ABILITY_732"
	},
	Epic = {
		"ABILITY_77", "ABILITY_420", "ABILITY_80086", "ABILITY_73", "ABILITY_2555",
		"ABILITY_41321", "ABILITY_456073", "ABILITY_140404", "ABILITY_24", "ABILITY_70",
		"ABILITY_19", "ABILITY_421", "ABILITY_100000", "ABILITY_1300"
	},
	Legendary = {
		"ABILITY_5", "ABILITY_666", "ABILITY_20", "ABILITY_9111", "ABILITY_684", "ABILITY_27",
		"ABILITY_3701", "ABILITY_23", "ABILITY_2319", "ABILITY_701", "ABILITY_26", "ABILITY_12",
		"ABILITY_2421", "ABILITY_658", "ABILITY_911111", "ABILITY_12789", "ABILITY_69"
	},
	Mythic = {
		"ABILITY_911", "ABILITY_42"
	}
}

AUTLevelUtil.ShardRarities = ShardRarities
AUTLevelUtil.TeleportLocations = TeleportLocations
AUTLevelUtil.AllowedAbilities = ShardRarities.Common
AUTLevelUtil.ShardsPerAbility = 5
AUTLevelUtil.FarmInterval = 0.1

local maxLevel = 200
local lastLevel = nil
AUTLevelUtil.IsFarming = false
AUTLevelUtil.IsMonitoring = false

-- functs

function AUTLevelUtil.SetShardRarity(rarity)
	if ShardRarities[rarity] then
		AUTLevelUtil.AllowedAbilities = ShardRarities[rarity]
	end
end

local function GetAbilityObject()
	local data = Players.LocalPlayer:FindFirstChild("Data")
	return data and data:FindFirstChild("Ability")
end

function AUTLevelUtil.GetCurrentLevel()
	local ability = GetAbilityObject()
	return ability and ability:GetAttribute("AbilityLevel") or nil
end

function AUTLevelUtil.BuildSellTable(allowed, shardsPerAbility)
	local allowedAbilities = allowed or AUTLevelUtil.AllowedAbilities
	local maxPerAbility = math.clamp(shardsPerAbility or AUTLevelUtil.ShardsPerAbility, 1, 15)
	local sellTable = {}

	local gui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not gui then return sellTable end

	local shardFrame = gui:FindFirstChild("UI")
	shardFrame = shardFrame and shardFrame:FindFirstChild("Menus")
	shardFrame = shardFrame and shardFrame:FindFirstChild("Black Market")
	shardFrame = shardFrame and shardFrame:FindFirstChild("Frame")
	shardFrame = shardFrame and shardFrame:FindFirstChild("ShardConvert")
	shardFrame = shardFrame and shardFrame:FindFirstChild("Shards")

	if not shardFrame then return sellTable end

	for _, abilityId in ipairs(allowedAbilities) do
		local frame = shardFrame:FindFirstChild(abilityId)
		local amount = frame and frame:FindFirstChild("Button") and tonumber(frame.Button:FindFirstChild("Amount") and frame.Button.Amount.Text)
		if amount and amount > 0 then
			sellTable[abilityId] = math.clamp(amount, 1, maxPerAbility)
		end
	end

	return sellTable
end

function AUTLevelUtil.RunFarmLoop()
	if farmThread and coroutine.status(farmThread) ~= "dead" then return end

	local RollBanner = CommonUtil.GetKnitRemote("ShopService", "RF", "RollBanner")
	local ConsumeShards = CommonUtil.GetKnitRemote("LevelService", "RF", "ConsumeShardsForXP")

	farmThread = task.spawn(function()
		while AUTLevelUtil.IsFarming do
			pcall(function()
				if RollBanner then
					RollBanner:InvokeServer(1, "UShards", 10)
				end
			end)

			local sellTable = AUTLevelUtil.BuildSellTable()
			if next(sellTable) then
				pcall(function()
					if ConsumeShards then
						ConsumeShards:InvokeServer(sellTable)
					end
				end)
			end

			task.wait(AUTLevelUtil.FarmInterval)
		end
		farmThread = nil
	end)
end

function AUTLevelUtil.RunLevelWatcher(onAscend, onMax)
	if levelWatcherThread and coroutine.status(levelWatcherThread) ~= "dead" then return end

	levelWatcherThread = task.spawn(function()
		while AUTLevelUtil.IsMonitoring do
			local level = AUTLevelUtil.GetCurrentLevel()
			if not level then task.wait(1) continue end

			if level ~= lastLevel and level <= maxLevel then
				lastLevel = level
			end

			if level >= maxLevel then
				if AUTLevelUtil.IsFarming then
					AUTLevelUtil.IsFarming = false
					if onMax then onMax() end
				end
				task.wait(5)
			else
				if not AUTLevelUtil.IsFarming then
					AUTLevelUtil.IsFarming = true
					if onAscend then onAscend() end
					AUTLevelUtil.RunFarmLoop()
				end
				task.wait(1)
			end
		end
		levelWatcherThread = nil
	end)
end

function AUTLevelUtil.Reset()
	AUTLevelUtil.IsFarming = false
	AUTLevelUtil.IsMonitoring = false
	farmThread = nil
	levelWatcherThread = nil
end

return AUTLevelUtil
