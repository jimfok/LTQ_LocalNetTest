require "spec.spec_helper"

local RoomServer = require "src.network.room_server"

local function build_context()
    local json_stub = {
        encoded = {},
        decode_map = {},
    }

    function json_stub.encode(tbl)
        local token = string.format("__ENCODED_%d__", #json_stub.encoded + 1)
        json_stub.encoded[#json_stub.encoded + 1] = { token = token, value = tbl }
        return token
    end

    function json_stub.decode(str)
        local payload = json_stub.decode_map[str]
        if not payload then
            error("unknown payload: " .. tostring(str))
        end
        return payload
    end

    local socket_stub = {
        bind_calls = {},
        assigned_port = 45000,
    }

    function socket_stub.bind(host, port)
        local server = {
            host = host,
            port = port,
            timeout = nil,
            closed = false,
            accept_queue = {},
        }

        function server:settimeout(value)
            self.timeout = value
        end

        function server:accept()
            return table.remove(self.accept_queue, 1)
        end

        function server:getsockname()
            return self.host, self.port == 0 and socket_stub.assigned_port or self.port
        end

        function server:close()
            self.closed = true
        end

        table.insert(socket_stub.bind_calls, { host = host, port = port, server = server })
        socket_stub.last_server = server
        return server
    end

    local logs = {}
    local function logger(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        logs[#logs + 1] = table.concat(parts, " ")
    end

    local server = RoomServer.new({
        deps = {
            socket = socket_stub,
            json = json_stub,
            logger = logger,
        },
        logger = logger,
        room_id = 42,
        players = { { id = 1 } },
    })

    return {
        json = json_stub,
        socket = socket_stub,
        server = server,
        logs = logs,
    }
end

describe("network.room_server", function()
    it("binds and tracks the listening port", function()
        local ctx = build_context()
        ctx.server:start(0)
        local bind_call = ctx.socket.bind_calls[1]
        assert.same("*", bind_call.host)
        assert.same(0, bind_call.port)
        assert.equal(0, bind_call.server.timeout)
        assert.equal(ctx.socket.assigned_port, ctx.server.port)
        assert.is_true(ctx.socket.last_server ~= nil)
    end)

    it("responds to join requests and triggers callback", function()
        local ctx = build_context()
        ctx.server:start(50010)
        local server_socket = ctx.socket.last_server

        local client = {
            receive_queue = {},
            sent = {},
            ip = "10.0.0.15",
            port = 40000,
            closed = false,
        }

        function client:settimeout(value)
            self.timeout = value
        end

        function client:getpeername()
            return self.ip, self.port
        end

        function client:receive()
            local msg = table.remove(self.receive_queue, 1)
            if not msg then
                return nil, "timeout"
            end
            return msg
        end

        function client:send(data)
            table.insert(self.sent, data)
        end

        function client:close()
            self.closed = true
        end

        table.insert(server_socket.accept_queue, client)
        ctx.json.decode_map["JOIN"] = { playerId = 7 }
        table.insert(client.receive_queue, "JOIN")

        local events = {}
        ctx.server:set_on_join(function(event)
            events[#events + 1] = event
        end)

        ctx.server:update()

        assert.equal(0, #server_socket.accept_queue)
        assert.is_true(client.closed)
        assert.equal(1, #client.sent)
        assert.is_not_nil(client.sent[1]:match("__ENCODED_%d__\n"))
        assert.equal(2, #ctx.json.encoded)
        assert.same({ status = "Accept", roomId = 42, players = ctx.server.players }, ctx.json.encoded[2].value)
        assert.equal(1, #events)
        assert.same("10.0.0.15", events[1].client.ip)
        assert.same(7, events[1].payload.playerId)
    end)

    it("closes sockets and clears clients on stop", function()
        local ctx = build_context()
        ctx.server:start(50011)
        local server_socket = ctx.socket.last_server
        local client = {
            closed = false,
        }
        function client:close()
            self.closed = true
        end
        ctx.server.clients[1] = { sock = client }
        ctx.server:stop()
        assert.is_true(server_socket.closed)
        assert.equal(0, #ctx.server.clients)
        assert.is_true(client.closed)
    end)

    it("handles malformed payloads without firing callback", function()
        local ctx = build_context()
        ctx.server:start(50012)
        local server_socket = ctx.socket.last_server
        local client = {
            ip = "10.0.0.16",
            port = 40100,
            sent = {},
        }
        function client:settimeout(value)
            self.timeout = value
        end
        function client:getpeername()
            return self.ip, self.port
        end
        function client:receive()
            return "UNKNOWN"
        end
        function client:send(data)
            table.insert(self.sent, data)
        end
        function client:close()
            self.closed = true
        end

        table.insert(server_socket.accept_queue, client)
        local events = {}
        ctx.server:set_on_join(function(event)
            events[#events + 1] = event
        end)

        ctx.server:update()

        assert.equal(0, #events)
        assert.equal(1, #client.sent)
        assert.is_not_nil(client.sent[1]:match("__ENCODED_%d__\n"))
    end)
end)
