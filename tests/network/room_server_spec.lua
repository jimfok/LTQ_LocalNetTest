require "tests.spec_helper"

local RoomServer = require "src.network.room_server"
local network_support = require "tests.support.network_context"
local build_context = network_support.build_room_server_context

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
