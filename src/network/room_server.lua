-- src/network/room_server.lua
-- Lightweight TCP room server with injectable dependencies.
local DEFAULT_DEPS = {
    socket = require "socket",
    json = require "json",
    logger = print,
}

local RoomServer = {}
RoomServer.__index = RoomServer

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
    assert(deps.socket, "socket dependency missing")
    assert(deps.json, "json dependency missing")
    return deps
end

function RoomServer:new(opts)
    opts = opts or {}
    local deps = merge_deps(opts.deps)
    local instance = {
        deps = deps,
        room_id = opts.room_id or 1,
        players = opts.players or {},
        clients = {},
        server = nil,
        port = opts.port,
        on_join = opts.on_join,
        logger = opts.logger or deps.logger,
    }
    return setmetatable(instance, RoomServer)
end

function RoomServer:set_on_join(callback)
    self.on_join = callback
end

function RoomServer:start(port)
    assert(not self.server, "server already started")
    port = port or self.port or 0
    local server, err = self.deps.socket.bind("*", port)
    assert(server, err)
    server:settimeout(0)
    self.server = server
    local _, actual_port = server:getsockname()
    self.port = port ~= 0 and port or actual_port
    if self.logger then
        self.logger(string.format("▶▶▶ room_server listening on port %s", tostring(self.port)))
    end
    return server
end

function RoomServer:stop()
    if self.server then
        self.server:close()
        self.server = nil
    end
    for i = #self.clients, 1, -1 do
        local client = self.clients[i]
        if client.sock then
            client.sock:close()
        end
        self.clients[i] = nil
    end
end

local function accept_new(self)
    while self.server do
        local client = self.server:accept()
        if not client then break end
        if client.settimeout then
            client:settimeout(0)
        end
        local ip, cport = client:getpeername()
        table.insert(self.clients, { sock = client, ip = ip, port = cport })
    end
end

local function respond(self, client, ok, payload, raw_message)
    if self.logger then
        local details = ok and self.deps.json.encode(payload) or raw_message
        local label = ok and "Received JoinRoom" or "Received invalid JoinRoom"
        self.logger(string.format("%s from %s:%s → %s", label, client.ip or "-", client.port or "-", details))
    end
    local response = { status = "Accept", roomId = self.room_id, players = self.players }
    client.sock:send(self.deps.json.encode(response) .. "\n")
    if ok and self.on_join then
        self.on_join({ payload = payload, client = client })
    end
    client.sock:close()
end

function RoomServer:update()
    if not self.server then return end
    accept_new(self)
    for i = #self.clients, 1, -1 do
        local client = self.clients[i]
        local line, err = client.sock:receive("*l")
        if line then
            local ok, payload = pcall(self.deps.json.decode, line)
            respond(self, client, ok, payload, line)
            table.remove(self.clients, i)
        elseif err == "closed" then
            client.sock:close()
            table.remove(self.clients, i)
        end
    end
end

-- Module-level convenience API mirroring the old table-based usage.
local default_instance
local function ensure_default()
    if not default_instance then
        default_instance = RoomServer:new()
    end
    return default_instance
end

local M = {}

function M.new(opts)
    return RoomServer:new(opts)
end

function M.default()
    return ensure_default()
end

function M.start(port)
    return ensure_default():start(port)
end

function M.update()
    return ensure_default():update()
end

function M.stop()
    return ensure_default():stop()
end

M.RoomServer = RoomServer

return M
