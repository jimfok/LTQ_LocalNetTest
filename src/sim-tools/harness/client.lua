-- src/sim-tools/harness/client.lua
-- Placeholder harness scaffolding for spec:sim-tools client loops.
local Discovery = require "network.discovery"
local RoomServer = require "network.room_server"

local M = {}

function M.build_client_harness(config, deps)
    --[[
    Build a table describing the Simulation-Join Room harness.
    Placeholder outline:
      * Configure discovery probes to locate available rooms.
      * Attempt join operations against the advertised room server.
      * Coordinate scheduler hooks for retries and timeouts.
    ]]
    return {
        config = config or {},
        deps = deps or {},
        discovery = nil, -- placeholder slot for Discovery:new({...}) configuration.
        joiner = nil, -- placeholder slot for helpers driving RoomServer joins.
    }
end

function M.run_client_loop(state)
    --[[
    Drive the Simulation-Join Room lifecycle until completion.
    Placeholder outline:
      * Broadcast discovery requests on an interval.
      * Handle discovery responses and attempt joins.
      * Emit TRACE logs covering attempt/response states.
    ]]
    return state
end

return M
