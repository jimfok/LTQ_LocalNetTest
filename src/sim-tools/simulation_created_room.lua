-- src/sim-tools/simulation_created_room.lua
local RoomServer = require "network.room_server"
local Discovery = require "network.discovery"

local function run_simulation_created_room()
    -- TODO(spec:sim-tools): Read port/room-id from CLI args instead of hard-coding values here.
    local server = RoomServer:new({
        port = 53316,
        on_join = function(event)
            -- TODO(spec:sim-tools): Emit TRACE|sim.server|join logs instead of print statements.
            print("Client joined:", event.payload.device_id, event.ip, event.port)
        end
    })

    -- TODO(spec:sim-tools): Inject discovery settings (broadcast, protocol) from CLI flags.
    local discovery = Discovery:new({
        port = 53316,
        on_hello = function(event)
            -- TODO(spec:sim-tools): Replace prints with TRACE|sim.server|discover logs.
            print("Received hello from:", event.payload.device_id, event.ip, event.port)
        end
    })

    server:start()
    discovery:listen()

    while true do
        -- TODO(spec:sim-tools): Exit loop on duration timeout or SIGINT instead of running forever.
        server:update()
        discovery:receive()
        -- TODO(spec:sim-tools): Remove socket.sleep busy wait by folding into harness scheduler.
        socket.sleep(0.1)
    end
end

run_simulation_created_room()
