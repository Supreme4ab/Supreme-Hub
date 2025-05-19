local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local Players = CommonUtil.GetService("Players")

local AUTLevelUtil = {}

--Config
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
AUTLevelUtil.AllowedAbilities = ShardRarities.Common
AUTLevelUtil.ShardsPerAbility = 5
AUTLevelUtil.FarmInterval = 0.1

local maxLevel = 200
local lastLevel = nil
AUTLevelUtil.IsFarming = false
AUTLevelUtil.IsMonitoring = false

local farmThread, levelWatcherThread

--Useful Funcs
function AUTLevelUtil.SetShardRarity(rarity)
	if AUTLevelUtil.ShardRarities and AUTLevelUtil.ShardRarities[rarity] then
		AUTLevelUtil.AllowedAbilities = AUTLevelUtil.ShardRarities[rarity]
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

--Autofarm

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
