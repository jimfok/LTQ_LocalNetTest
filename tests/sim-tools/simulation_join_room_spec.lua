-- tests/sim-tools/simulation_join_room_spec.lua
local busted = require "busted"
local Discovery = require "network.discovery"

describe("Simulation-Join Room discovers servers (spec:sim-tools)", function()
    local discovery

    setup(function()
        discovery = Discovery:new({
            port = 53316,
            on_hello = function(event)
                print("Received hello from:", event.payload.device_id, event.ip, event.port)
            end
        })
        discovery:listen()
    end)

    teardown(function()
        discovery:close()
    end)

    it("should broadcast a HELLO message", function()
        -- Simulate broadcasting a HELLO message
        local message = discovery:broadcast_hello()

        -- Verify that the message is correctly formatted
        local payload = busted.json.decode(message)
        assert.is_true(payload.device_id ~= nil, "device_id missing from HELLO message")
        assert.is_true(payload.model ~= nil, "model missing from HELLO message")
        assert.is_equal(payload.protocol, "localsend", "protocol mismatch in HELLO message")
        assert.is_true(payload.udp_port == 53316, "udp_port mismatch in HELLO message")

        -- TODO(spec:sim-tools): Swap to stubbed discovery and assert TRACE|sim.client|discover/join events instead of print output.
    end)
end)
