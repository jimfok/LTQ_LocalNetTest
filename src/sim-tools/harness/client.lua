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
    -- TODO(spec:sim-tools): Configure Discovery probes based on config and dependency overrides.
    -- TODO(spec:sim-tools): Implement RoomServer join attempts with retry/backoff strategy hooks.
    -- TODO(spec:sim-tools): Wire scheduler/timer callbacks so the client loop can coordinate retries.
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
    -- TODO(spec:sim-tools): Broadcast discovery requests using configured discovery client on a repeating interval.
    -- TODO(spec:sim-tools): Handle discovery responses and drive join attempts until success/timeout.
    -- TODO(spec:sim-tools): Emit TRACE logs for each attempt, response, and exit condition.
    return state
end

return M
