local CommonModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

function CommonModule.GetService(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    if success then
        return service
    else
        warn("Service not found: " .. tostring(serviceName))
        return nil
    end
end

function CommonModule.GetRemote(remoteName)
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        local remote = remotesFolder:FindFirstChild(remoteName)
        if remote then return remote end
    end

    local remote = ReplicatedStorage:FindFirstChild(remoteName)
    if remote then return remote end

    warn("Remote not found: " .. tostring(remoteName))
    return nil
end

-- Get the LocalPlayer
function CommonModule.GetLocalPlayer()
    return Players.LocalPlayer
end

function CommonModule.GetCharacter()
    local player = Players.LocalPlayer
    if not player then return nil end

    local character = player.Character or player.CharacterAdded:Wait()
    return character
end

function CommonModule.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("SafeCall error: " .. tostring(result))
        return nil
    end
    return result
end

return CommonModule
