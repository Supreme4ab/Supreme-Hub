local CommonUtil = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/cassie/main/Main/Modules/CommonUtil.lua"))()
local Players = CommonUtil.GetService("Players")

local AUTLevelUtil = {}

--Constants/Config
AUTLevelUtil.AllowedAbilities = {
    "ABILITY_8881", "ABILITY_10019", "ABILITY_21", "ABILITY_10", "ABILITY_14"
}
AUTLevelUtil.ShardsPerAbility = 5
AUTLevelUtil.FarmInterval = 0.1
local maxLevel = 200
local lastLevel = nil

--States
AUTLevelUtil.IsFarming = false
AUTLevelUtil.IsMonitoring = false
local farmThread, levelWatcherThread

--Debug
AUTLevelUtil.Debug = false
function AUTLevelUtil.Log(msg)
	if AUTLevelUtil.Debug then
		CommonUtil.Log("[AUTLevel]", msg)
	end
end

--Reusable Attribute Getter
local function GetAbilityObject()
	local data = Players.LocalPlayer:FindFirstChild("Data")
	return data and data:FindFirstChild("Ability")
end

function AUTLevelUtil.GetCurrentLevel()
	local ability = GetAbilityObject()
	return ability and ability:GetAttribute("AbilityLevel") or nil
end

function AUTLevelUtil.GetAbilityName()
	local ability = GetAbilityObject()
	return ability and ability:GetAttribute("AbilityName") or nil
end

function AUTLevelUtil.GetAscensionRank()
	local ability = GetAbilityObject()
	return ability and ability:GetAttribute("AscensionRank") or nil
end

--Reusable GUI Shard Frame Lookup
local function GetShardGUIFrame()
	local gui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not gui then return nil end

	return gui:FindFirstChild("UI")
		and gui.UI:FindFirstChild("Menus")
		and gui.UI.Menus:FindFirstChild("Black Market")
		and gui.UI.Menus["Black Market"]:FindFirstChild("Frame")
		and gui.UI.Menus["Black Market"].Frame:FindFirstChild("ShardConvert")
		and gui.UI.Menus["Black Market"].Frame.ShardConvert:FindFirstChild("Shards")
end

--Builds sell table from allowed abilities
function AUTLevelUtil.BuildSellTable(allowed, shardsPerAbility)
	local allowedAbilities = allowed or AUTLevelUtil.AllowedAbilities
	local maxPerAbility = math.clamp(shardsPerAbility or AUTLevelUtil.ShardsPerAbility, 1, 15)
	local sellTable = {}

	local shardFrame = GetShardGUIFrame()
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

--Auto-farming loop
function AUTLevelUtil.RunFarmLoop()
	if farmThread and coroutine.status(farmThread) ~= "dead" then return end

	local RollBanner = CommonUtil.GetKnitRemote("ShopService", "RF", "RollBanner")
	local ConsumeShards = CommonUtil.GetKnitRemote("LevelService", "RF", "ConsumeShardsForXP")

	farmThread = task.spawn(function()
		while AUTLevelUtil.IsFarming do
			pcall(function()
				if RollBanner then
					RollBanner:InvokeServer(1, "UShards", 10)
				else
					AUTLevelUtil.Log("RollBanner remote missing")
				end
			end)

			local sellTable = AUTLevelUtil.BuildSellTable()
			if next(sellTable) then
				pcall(function()
					if ConsumeShards then
						ConsumeShards:InvokeServer(sellTable)
					else
						AUTLevelUtil.Log("ConsumeShards remote missing")
					end
				end)
			end

			task.wait(AUTLevelUtil.FarmInterval)
		end
		farmThread = nil
	end)
end

--Watches level and toggles farm
function AUTLevelUtil.RunLevelWatcher(onAscend, onMax)
	if levelWatcherThread and coroutine.status(levelWatcherThread) ~= "dead" then return end

	levelWatcherThread = task.spawn(function()
		while AUTLevelUtil.IsMonitoring do
			local level = AUTLevelUtil.GetCurrentLevel()
			if not level then task.wait(1) continue end

			if level ~= lastLevel and level <= maxLevel then
				lastLevel = level
				AUTLevelUtil.Log("Level changed: " .. level)
			end

			if level >= maxLevel then
				if AUTLevelUtil.IsFarming then
					AUTLevelUtil.IsFarming = false
					if onMax then onMax() end
					AUTLevelUtil.Log("Max level reached.")
				end
				task.wait(5)
			elseif level < maxLevel then
				if not AUTLevelUtil.IsFarming then
					AUTLevelUtil.IsFarming = true
					if onAscend then onAscend() end
					AUTLevelUtil.RunFarmLoop()
					AUTLevelUtil.Log("Started farming...")
				end
				task.wait(1)
			else
				task.wait(1)
			end
		end
		levelWatcherThread = nil
	end)
end

--reset runtime flags + threads
function AUTLevelUtil.Reset()
	AUTLevelUtil.IsFarming = false
	AUTLevelUtil.IsMonitoring = false
	farmThread = nil
	levelWatcherThread = nil
	AUTLevelUtil.Log("All systems reset.")
end

return AUTLevelUtil
