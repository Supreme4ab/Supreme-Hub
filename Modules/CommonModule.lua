local Services = setmetatable({}, {
    __index = function(self, name)
        local service = game:GetService(name)
        rawset(self, name, service)
        return service
    end
})

local RemoteCache = {}
local CommonModule = {}

function CommonModule.GetService(name)
    return Services[name]
end

function CommonModule.GetKnitRemote(serviceName, remoteType, remoteName)
    local cacheKey = serviceName .. "/" .. remoteType .. "/" .. remoteName
    if RemoteCache[cacheKey] then return RemoteCache[cacheKey] end

    local Knit = Services.ReplicatedStorage:WaitForChild("ReplicatedModules")
        :WaitForChild("KnitPackage"):WaitForChild("Knit")
    local service = Knit:WaitForChild("Services"):WaitForChild(serviceName)
    local container = service:WaitForChild(remoteType)
    local remote = container:WaitForChild(remoteName)

    RemoteCache[cacheKey] = remote
    return remote
end

function CommonModule.Teleport(position)
    local player = Services.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not root then return false end

    local anchored = root.Anchored
    root.Anchored = true
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero

    if char:FindFirstChild("PivotTo") then
        char:PivotTo(CFrame.new(position))
    else
        root.CFrame = CFrame.new(position)
    end

    task.delay(0.1, function()
        root.Anchored = anchored
    end)

    return true
end

return CommonModule
