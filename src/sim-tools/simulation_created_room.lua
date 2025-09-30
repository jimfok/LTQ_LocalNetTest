-- src/sim-tools/simulation_created_room.lua
local RoomServer = require "network.room_server"
local Discovery = require "network.discovery"

local function run_simulation_created_room()
    -- TODO(spec:sim-tools): Replace hard-coded port/room_id with values passed from the sim-tools CLI or harness config (config.port, config.room_id).
    local server = RoomServer:new({
        port = 53316,
        on_join = function(event)
            -- TODO(spec:sim-tools): Emit TRACE|sim.server|join logs via logging.trace and push them through configured log sinks instead of print statements.
            print("Client joined:", event.payload.device_id, event.ip, event.port)
        end
    })

    -- TODO(spec:sim-tools): Inject discovery settings (broadcast, protocol, udp_port) sourced from CLI flags or harness config.
    local discovery = Discovery:new({
        port = 53316,
        on_hello = function(event)
            -- TODO(spec:sim-tools): Replace prints with TRACE|sim.server|discover logs routed through sim-tools logging sinks (sink:push(logging.trace(...))).
            print("Received hello from:", event.payload.device_id, event.ip, event.port)
        end
    })

    server:start()
    discovery:listen()

    while true do
        -- TODO(spec:sim-tools): Exit loop based on duration timeout or SIGINT handled by the harness scheduler/deps.exit_requested instead of running forever.
        server:update()
        discovery:receive()
        -- TODO(spec:sim-tools): Remove socket.sleep busy wait by delegating cadence control to the harness scheduler or injected sleep helper.
        socket.sleep(0.1)
    end
end

run_simulation_created_room()
