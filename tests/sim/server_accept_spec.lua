-- tests/sim/server_accept_spec.lua
local busted = require "busted"
local RoomServer = require "network.room_server"

describe("Room Server Accept Flow", function()
    local server

    setup(function()
        server = RoomServer:new({
            port = 53316,
            on_join = function(event)
                print("Client joined:", event.payload.device_id, event.ip, event.port)
            end
        })
        server:start()
    end)

    teardown(function()
        server:stop()
    end)

    it("should accept a client connection", function()
        -- Simulate a client connecting
        local client = socket.connect("*", 53316)
        assert.is_true(client ~= nil, "Client failed to connect")

        -- Send a join request
        local payload = {
            device_id = "client1",
            model = "test_model"
        }
        client:send(busted.json.encode(payload) .. "\n")

        -- Wait for the server to process the connection
        socket.sleep(0.1)

        -- Verify that the client was added to the server's clients list
        assert.is_true(#server.clients > 0, "No clients connected")

        -- TODO(spec:sim-tools): Replace real socket interaction with fakes and assert TRACE|sim.server|join output.
    end)
end)
