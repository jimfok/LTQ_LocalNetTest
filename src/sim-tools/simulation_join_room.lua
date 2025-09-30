-- src/sim-tools/simulation_join_room.lua
local Discovery = require "network.discovery"

local function run_simulation_join_room()
    -- TODO(spec:sim-tools): Accept broadcast/udp-port flags and configure discovery accordingly.
    local discovery = Discovery:new({
        port = 53316,
        on_hello = function(event)
            -- TODO(spec:sim-tools): Emit TRACE|sim.client|discover logs rather than prints.
            print("Received hello from:", event.payload.device_id, event.ip, event.port)
        end
    })

    discovery:listen()
    -- TODO(spec:sim-tools): Loop broadcast with retry cadence and TRACE logging.
    discovery:broadcast_hello()

    while true do
        discovery:receive()
        -- TODO(spec:sim-tools): Attempt join handshake and emit TRACE|sim.client|join|accept when matched.
        socket.sleep(0.1)
    end
end

run_simulation_join_room()
