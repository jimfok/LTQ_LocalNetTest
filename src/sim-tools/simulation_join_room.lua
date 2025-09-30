-- src/sim-tools/simulation_join_room.lua
local Discovery = require "network.discovery"

local function run_simulation_join_room()
    -- TODO(spec:sim-tools): Accept broadcast/udp-port flags from the CLI or harness config and configure discovery accordingly.
    local discovery = Discovery:new({
        port = 53316,
        on_hello = function(event)
            -- TODO(spec:sim-tools): Emit TRACE|sim.client|discover logs through the shared logging helper rather than prints.
            print("Received hello from:", event.payload.device_id, event.ip, event.port)
        end
    })

    discovery:listen()
    -- TODO(spec:sim-tools): Loop broadcast with a configurable retry cadence and TRACE logging routed via sim-tools sinks.
    discovery:broadcast_hello()

    while true do
        discovery:receive()
        -- TODO(spec:sim-tools): Attempt the join handshake using harness helpers and emit TRACE|sim.client|join|accept on matches.
        socket.sleep(0.1)
    end
end

run_simulation_join_room()
