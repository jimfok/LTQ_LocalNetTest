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
    -- TODO(spec:sim-tools): Instantiate RoomServer:new(...) with config overrides (port, room_id) and dependency injections before returning the harness.
    -- TODO(spec:sim-tools): Attach Discovery listeners that broadcast availability using the configured announcement options.
    -- TODO(spec:sim-tools): Register scheduler/timer hooks on the harness to drive cooperative server loop execution.
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
    -- TODO(spec:sim-tools): Drain queued events via state.server/state.scheduler until shutdown criteria are met.
    -- TODO(spec:sim-tools): Process discovery announcements and accept/track client join state via state.discovery.
    -- TODO(spec:sim-tools): Emit TRACE logs for lifecycle transitions and termination paths through the shared logging helper.
    return state
end

return M
