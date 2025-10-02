-- src/network/discovery.lua
-- Network discovery helper with injectable dependencies for spec-driven tests.
local DEFAULT_MULTICAST_ADDR = "224.0.0.167"
local DEFAULT_PORT = 53316
local DEFAULT_PROTOCOL = "localsend"

local DEFAULT_DEPS = {
    socket = require "socket",
    json = require "json",
    sys = sys,
    logger = print,
}

local Discovery = {}
Discovery.__index = Discovery

local function merge_deps(overrides)
    local deps = {}
    for k, v in pairs(DEFAULT_DEPS) do
        deps[k] = v
    end
    if overrides then
        for k, v in pairs(overrides) do
            deps[k] = v
        end
    end
    deps.dns = deps.dns or (deps.socket and deps.socket.dns)
    assert(deps.socket, "socket dependency missing")
    assert(deps.json, "json dependency missing")
    assert(deps.dns and deps.dns.gethostname, "socket.dns dependency missing")
    return deps
end

function Discovery:new(opts)
    opts = opts or {}
    local deps = merge_deps(opts.deps)
    local configured_port
    if deps.sys and deps.sys.get_config then
        local value = deps.sys.get_config("network.discovery_port")
        if value then
            configured_port = tonumber(value)
        end
    end
    local hostname = deps.dns.gethostname()
    local local_ip = deps.dns.toip(hostname) or "127.0.0.1"
    local sys_info = opts.sys_info
    if not sys_info then
        assert(deps.sys and deps.sys.get_sys_info, "sys.get_sys_info dependency missing")
        sys_info = deps.sys.get_sys_info()
    end

    local instance = {
        deps = deps,
        multicast_addr = opts.multicast_addr or DEFAULT_MULTICAST_ADDR,
        port = opts.port or configured_port or DEFAULT_PORT,
        protocol = opts.protocol or DEFAULT_PROTOCOL,
        sys_info = sys_info,
        local_ip = local_ip,
        udp = nil,
        on_hello = opts.on_hello,
        logger = opts.logger or deps.logger,
    }
    return setmetatable(instance, Discovery)
end

function Discovery:set_on_hello(callback)
    self.on_hello = callback
end

function Discovery:listen()
    assert(not self.udp, "listener already started")
    local udp = assert(self.deps.socket.udp(), "unable to create UDP socket")
    local _, reuseaddr_err = udp:setoption("reuseaddr", true)
    if reuseaddr_err and self.logger then
        self.logger(string.format("⚠️ reuseaddr not available: %s", reuseaddr_err))
    end

    local reuseport_ok, reuseport_err = udp:setoption("reuseport", true)
    if reuseport_err and reuseport_err ~= "Option not supported" and self.logger then
        self.logger(string.format("⚠️ reuseport failed: %s", reuseport_err))
    end

    local ok, err = udp:setsockname("*", self.port)
    if not ok then
        udp:close()
        error(string.format("unable to bind UDP socket on port %d (%s)", self.port, err or "unknown"))
    end
    udp:settimeout(0)
    udp:setoption("ip-multicast-loop", true)
    local mreq = { multiaddr = self.multicast_addr, interface = "0.0.0.0" }
    assert(udp:setoption("ip-add-membership", mreq))
    self.udp = udp
    if self.logger then
        self.logger(string.format("▶▶▶ network_discovery: listener ready on %s:%d", self.multicast_addr, self.port))
    end
    return udp
end

function Discovery:broadcast_hello()
    local udp = assert(self.deps.socket.udp(), "unable to create UDP socket for broadcast")
    udp:setsockname("*", 0)
    if self.multicast_addr and self.multicast_addr:match("^(%d+)") then
        local first_octet = tonumber(self.multicast_addr:match("^(%d+)"))
        if first_octet and first_octet >= 224 and first_octet <= 239 then
            udp:setoption("ip-multicast-ttl", 1)
            udp:setoption("ip-multicast-loop", true)
        else
            udp:setoption("broadcast", true)
        end
    else
        udp:setoption("broadcast", true)
    end

    local payload = {
        device_id = self.sys_info.device_id,
        model = self.sys_info.model,
        protocol = self.protocol,
        udp_port = self.port,
    }
    local message = self.deps.json.encode(payload)
    udp:sendto(message, self.multicast_addr, self.port)
    udp:close()
    if self.logger then
        self.logger("▶▶▶ broadcast HELLO:", message)
    end
    return message
end

function Discovery:receive()
    if not self.udp then return nil end
    local data, ip, port = self.udp:receivefrom()
    if not data or ip == self.local_ip then return nil end
    local ok, payload = pcall(self.deps.json.decode, data)
    if not ok or payload.protocol ~= self.protocol or not payload.device_id then
        return nil
    end
    local event = { payload = payload, ip = ip, port = port }
    if self.on_hello then self.on_hello(event) end
    if self.logger then
        self.logger(string.format(
            "👍 Received HELLO from %s:%s → device_id=%s, model=%s",
            ip or "-", port or "-", payload.device_id or "-", payload.model or "-"
        ))
    end
    return event
end

function Discovery:close()
    if self.udp then
        self.udp:close()
        self.udp = nil
    end
end

-- Convenience singleton so existing code can keep using module functions directly.
local default_instance
local function ensure_default()
    if not default_instance then
        default_instance = Discovery:new()
    end
    return default_instance
end

local M = {}

function M.new(opts)
    return Discovery:new(opts)
end

function M.default()
    return ensure_default()
end

function M.listen()
    return ensure_default():listen()
end

function M.broadcast_hello()
    return ensure_default():broadcast_hello()
end

function M.receive()
    return ensure_default():receive()
end

function M.close()
    return ensure_default():close()
end

M.DEFAULT_MULTICAST_ADDR = DEFAULT_MULTICAST_ADDR
M.DEFAULT_PORT = DEFAULT_PORT
M.DEFAULT_PROTOCOL = DEFAULT_PROTOCOL

return M
