local Services = setmetatable({}, {
	__index = function(self, serviceName)
		local service = game:GetService(serviceName)
		rawset(self, serviceName, service)
		return service
	end
})

local CommonUtil = {}

function CommonUtil.GetService(name)
	return Services[name]
end

function CommonUtil.WaitForService(name, timeout)
	local success, result = pcall(function()
		return game:WaitForChild(name, timeout or 5)
	end)
	if not success then
		warn(("[CommonUtil] Service '%s' not found in time."):format(name))
	end
	return result
end

function CommonUtil.GetLocalPlayer()
	return Services.Players.LocalPlayer
end

function CommonUtil.WaitForChildDeep(parent, path, timeout)
	local segments = string.split(path, "/")
	local current = parent
	for _, segment in ipairs(segments) do
		current = current:WaitForChild(segment, timeout or 5)
		if not current then
			warn("[CommonUtil] Missing child in path:", segment)
			break
		end
	end
	return current
end

function CommonUtil.GetKnitRemote(serviceName, remoteType, remoteName)
	local success, remote
	success, remote = pcall(function()
		local Knit = CommonUtil.WaitForChildDeep(Services.ReplicatedStorage, "ReplicatedModules/KnitPackage/Knit")
		if not Knit then return nil end

		local service = Knit:FindFirstChild("Services") and Knit.Services:FindFirstChild(serviceName)
		if not service then return nil end

		local container = service:FindFirstChild(remoteType)
		if not container then return nil end

		return container:FindFirstChild(remoteName)
	end)

	if not success or not remote then
		warn(("[CommonUtil] Knit remote not found: %s.%s.%s"):format(serviceName, remoteType, remoteName))
	end

	return remote
end

function CommonUtil.DeepPrint(tbl, indent)
	indent = indent or 0
	local spacing = string.rep("    ", indent)
	for k, v in pairs(tbl) do
		if typeof(v) == "table" then
			print(spacing .. tostring(k) .. " = {")
			CommonUtil.DeepPrint(v, indent + 1)
			print(spacing .. "}")
		else
			print(spacing .. tostring(k) .. " = " .. tostring(v))
		end
	end
end

function CommonUtil.GCScan(predicate)
	local results = {}
	for _, obj in ipairs(getgc(true)) do
		if typeof(obj) == "table" and predicate(obj) then
			table.insert(results, obj)
		end
	end
	return results
end

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

function CommonUtil.Log(...)
	print("[SunniHub]", ...)
end

return CommonUtil
