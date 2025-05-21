local CommonModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Supreme4ab/Supreme-Hub/main/Modules/CommonModule.lua"))()
local Players = CommonModule.GetService("Players")
local TweenService = CommonModule.GetService("TweenService")

local AUTLevelModule = {}

-- Teleport locations dictionary
AUTLevelModule.TeleportLocations = {
    ["Alabasta"]            = Vector3.new(2085.529, 945.397, -2417.796),
    ["Beach"]               = Vector3.new(607.062, 917.219, -1989.912),
    ["Boss Spawn Room"]     = Vector3.new(19153.26, 910.548, 118.567),
    ["Central Wilds"]       = Vector3.new(2528.788, 989.488, -544.948),
    ["Desert Approach"]     = Vector3.new(1983.827, 924.261, -1137.514),
    ["Diavolo Spawn"]       = Vector3.new(1011.125, 934.362, 2888.195),
    ["Floating Village"]    = Vector3.new(1222.878, 1015.637, -281.11),
    ["Football Field"]      = Vector3.new(1980.397, 973.423, -356.92),
    ["Goku"]                = Vector3.new(2544.647, 916.524, 1828.544),
    ["Guardians Spawn Room"]= Vector3.new(3509.697, 937.592, -430.434),
    ["Gyro TA1"]            = Vector3.new(2070.348, 1074.851, -714.886),
    ["Gyro TA2"]            = Vector3.new(2272.279, 973.616, 685.383),
    ["Gyro TA4"]            = Vector3.new(1015.955, 949.607, -1243.879),
    ["Gyro TA5"]            = Vector3.new(2590.929, 1021.208, -182.963),
    ["Hollow World"]        = Vector3.new(1245.528, 948.131, 458.005),
    ["Inazuma Shrine"]      = Vector3.new(1233.544, 1016.12, -286.343),
    ["Jotaro"]              = Vector3.new(2467.263, 983.808, 1094.06),
    ["Las Venturas"]        = Vector3.new(2758.77, 972.048, 1033.998),
    ["Mass Destruction"]    = Vector3.new(4445.358, 924.385, -70.223),
    ["Mass Destruction 2"]  = Vector3.new(4244.616, 924.385, -70.224),
    ["New World"]           = Vector3.new(1543.839, 951.838, 1791.469),
    ["New World 2"]         = Vector3.new(1753.839, 951.838, 1791.469),
    ["Old World"]           = Vector3.new(2636.636, 1023.395, -510.703),
    ["Old World 2"]         = Vector3.new(2436.636, 1023.395, -510.703),
    ["Poseidon"]            = Vector3.new(1319.08, 958.028, 1141.568),
    ["Ramen Shop"]          = Vector3.new(1705.593, 1012.385, -227.39),
    ["Raven Tower"]         = Vector3.new(2476.015, 1011.89, 678.45),
    ["Reaper's Farm"]       = Vector3.new(2615.525, 1019.326, -242.225),
    ["Safari"]              = Vector3.new(1207.765, 957.727, -1809.468),
    ["Snow World"]          = Vector3.new(502.247, 1020.812, 3311.629),
    ["Yamanote Tower"]      = Vector3.new(2356.003, 1011.153, 646.781),
}

-- State variables
AUTLevelModule.IsMonitoring = false
AUTLevelModule.FarmInterval = 0.1
AUTLevelModule.ShardRarities = { ["Common"] = true }
AUTLevelModule.AutoAscend = false
AUTLevelModule.Player = Players.LocalPlayer
AUTLevelModule.Teleports = AUTLevelModule.TeleportLocations

-- Get remotes
local RemoteRoll = CommonModule.GetRemote("Roll")
local RemoteConvert = CommonModule.GetRemote("Convert")
local RemoteAscend = CommonModule.GetRemote("Ascend")

-- Safe remote invocation wrapper
local function safeInvoke(remote, ...)
    if remote then
        local success, result = pcall(function() return remote:InvokeServer(...) end)
        if not success then
            warn("Remote invoke failed: " .. tostring(result))
            return nil
        end
        return result
    else
        warn("Remote not found")
        return nil
    end
end

-- Update which shard rarities to convert
function AUTLevelModule.SetShardRarity(rarities)
    AUTLevelModule.ShardRarities = {}
    for _, rarity in ipairs(rarities) do
        AUTLevelModule.ShardRarities[rarity] = true
    end
end

function AUTLevelModule.SetAutoAscend(enabled)
    AUTLevelModule.AutoAscend = enabled
end

function AUTLevelModule.Teleport(position)
    if not position then return false end
    local character = AUTLevelModule.Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end

    local hrp = character.HumanoidRootPart
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(position)})
    tween:Play()
    tween.Completed:Wait()
    return true
end

function AUTLevelModule.RemoveVFX()
    local workspaceDescendants = game:GetService("Workspace"):GetDescendants()
    for _, obj in ipairs(workspaceDescendants) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
        elseif obj:IsA("PostEffect") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") then
            obj.Enabled = false
        end
    end
end

function AUTLevelModule.SetFogAutoRemove(state)
    if state then
        local Lighting = game:GetService("Lighting")
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    end
end

function AUTLevelModule.RemoveDesertFog()
    AUTLevelModule.SetFogAutoRemove(true)
end

function AUTLevelModule.Reset()
    AUTLevelModule.IsMonitoring = false
    AUTLevelModule.AutoAscend = false
end

function AUTLevelModule.RunLevelWatcher()
    if AUTLevelModule.IsMonitoring then return end
    AUTLevelModule.IsMonitoring = true

    spawn(function()
        while AUTLevelModule.IsMonitoring do
            local stats = AUTLevelModule.Player:FindFirstChild("leaderstats")
            local level = stats and stats:FindFirstChild("Level")
            if level then
                local currentLevel = level.Value
                if AUTLevelModule.AutoAscend and currentLevel >= 200 then
                    safeInvoke(RemoteAscend)
                    AUTLevelModule.AutoAscend = false
                end
            end

            safeInvoke(RemoteRoll)

            local shardInventory = AUTLevelModule.Player:FindFirstChild("Shards")
            if shardInventory and RemoteConvert then
                for _, shard in ipairs(shardInventory:GetChildren()) do
                    if shard:IsA("IntValue") and AUTLevelModule.ShardRarities[shard.Name] and shard.Value > 0 then
                        safeInvoke(RemoteConvert, shard.Name)
                    end
                end
            end

            task.wait(AUTLevelModule.FarmInterval or 0.1)
        end
    end)
end

return AUTLevelModule
