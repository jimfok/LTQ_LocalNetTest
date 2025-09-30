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
    -- TODO(spec:sim-tools): Configure Discovery:new({...}) using config (config.broadcast, config.udp_port) or dependency overrides before returning the harness.
    -- TODO(spec:sim-tools): Implement join attempt helpers that retry RoomServer connections with configurable backoff hooks from deps.retry/deps.sleep.
    -- TODO(spec:sim-tools): Surface scheduler/timer callbacks on the harness (deps.scheduler/deps.timers) so the client loop can coordinate retries.
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
    -- TODO(spec:sim-tools): Use state.discovery to broadcast HELLO probes at the configured interval sourced from config.duration/config.interval.
    -- TODO(spec:sim-tools): Consume discovery responses and drive join attempts until success or the configured timeout elapses, utilising retry helpers.
    -- TODO(spec:sim-tools): Emit TRACE logs for attempts, responses, and exit conditions via the shared logging helper (logging.trace -> sink:push).
    return state
end

return M
