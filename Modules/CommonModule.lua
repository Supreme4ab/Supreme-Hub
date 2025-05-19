--Lazy-loaded Services
local Services = setmetatable({}, {
   __index = function(self, serviceName)
       local service = game:GetService(serviceName)
       rawset(self, serviceName, service)
       return service
   end
})

--Knit Remote Cache
local RemoteCache = {}

local CommonUtil = {}

--Get Roblox services
function CommonUtil.GetService(name)
   return Services[name]
end

--Cache Roblox service
function CommonUtil.WaitForService(name, timeout)
   local result = game:WaitForChild(name, timeout or 5)
   if result then
       rawset(Services, name, result)
   else
       warn("[CommonUtil] Service wait timeout:", name)
   end
   return result
end

--View all accessed services (for debug)
function CommonUtil.ListAccessedServices()
   local list = {}
   for name in pairs(Services) do
       table.insert(list, name)
   end
   return list
end

--Deep WaitForChild
function CommonUtil.WaitForChildDeep(parent, path, timeout)
   local segments = string.split(path, "/")
   local current = parent
   for _, segment in ipairs(segments) do
       current = current:FindFirstChild(segment)
       if not current then
           current = parent:WaitForChild(segment, timeout or 5)
       end
       if not current then break end
       parent = current
   end
   return current
end

--Get Knit Remote
function CommonUtil.GetKnitRemote(serviceName, remoteType, remoteName)
   local cacheKey = ("%s/%s/%s"):format(serviceName, remoteType, remoteName)
   if RemoteCache[cacheKey] then return RemoteCache[cacheKey] end

   local success, remote = pcall(function()
       local Knit = CommonUtil.WaitForChildDeep(Services.ReplicatedStorage, "ReplicatedModules/KnitPackage/Knit")
       if not Knit then return nil end

       local servicesFolder = Knit:FindFirstChild("Services")
       if not servicesFolder then return nil end

       local service = servicesFolder:FindFirstChild(serviceName)
       if not service then return nil end

       local container = service:FindFirstChild(remoteType)
       if not container then return nil end

       return container:FindFirstChild(remoteName)
   end)

   if success and remote then
       RemoteCache[cacheKey] = remote
   else
       warn("[CommonUtil] Failed to get Knit remote:", cacheKey)
   end

   return remote
end

--Get LocalPlayer (client only)
function CommonUtil.GetLocalPlayer()
   return Services.Players.LocalPlayer
end

--GC Table Scanner (matches if predicate returns true)
function CommonUtil.GCScan(predicate)
   local matches = {}
   for _, v in ipairs(getgc(true)) do
       if typeof(v) == "table" then
           local success, result = pcall(predicate, v)
           if success and result then
               table.insert(matches, v)
           end
       end
   end
   return matches
end

--Auto-reconnect signal hook
function CommonUtil.AutoReconnectSignal(signal, callback)
   local conn
   local function connect()
       if conn then conn:Disconnect() end
       conn = signal:Connect(callback)
   end
   connect()
   return {
       Disconnect = function()
           if conn then conn:Disconnect() end
       end,
       Reconnect = connect
   }
end

--Deep table debug printer
function CommonUtil.DeepPrint(tbl, indent)
   indent = indent or 0
   local pad = string.rep("    ", indent)
   for k, v in pairs(tbl) do
       if typeof(v) == "table" then
           print(pad .. tostring(k) .. " = {")
           CommonUtil.DeepPrint(v, indent + 1)
           print(pad .. "}")
       else
           print(pad .. tostring(k) .. " = " .. tostring(v))
       end
   end
end

function CommonUtil.Log(...)
   print("[SunniHub]", ...)
end

return CommonUtil
