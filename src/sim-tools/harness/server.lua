-- src/sim-tools/harness/server.lua
-- Placeholder harness scaffolding for spec:sim-tools server loops.
local RoomServer = require "network.room_server"
local Discovery = require "network.discovery"

local M = {}

function M.build_server_harness(config, deps)
    --[[
    Build a table describing the Simulation-Created Room harness.
    Placeholder outline:
      * Instantiate RoomServer with configuration values.
      * Attach Discovery listeners for broadcast announcements.
      * Prepare scheduler hooks for cooperative multitasking.
    ]]
    return {
        config = config or {},
        deps = deps or {},
        server = nil, -- placeholder slot for RoomServer:new({...}) once implemented.
        discovery = nil, -- placeholder slot for Discovery:new({...}) wiring.
    }
end

function M.run_server_loop(state)
    --[[
    Drive the Simulation-Created Room lifecycle until completion.
    Placeholder outline:
      * Iterate over queued events until shutdown.
      * Process discovery announcements and accept joins.
      * Emit TRACE logs for each lifecycle transition.
    ]]
    return state
end

return M
