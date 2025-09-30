-- src/sim-tools/cli.lua
-- Placeholder CLI bridge for spec:sim-tools simulators.
local server_harness = require "sim-tools.harness.server"
local client_harness = require "sim-tools.harness.client"
local logging = require "sim-tools.logging"

local M = {}

function M.parse_argv(argv)
    --[[
    Parse CLI arguments into a command plus option table.
    Placeholder outline:
      * Inspect argv for the command name (argv[1]).
      * Expand into option tables once flag parsing lands.
    ]]
    -- TODO(spec:sim-tools): Inspect argv[1] and normalise command aliases before dispatch.
    -- TODO(spec:sim-tools): Parse remaining argv entries into structured option tables.
    return {
        command = argv and argv[1] or nil,
        options = {},
    }
end

function M.dispatch(command, argv, deps)
    --[[
    Dispatch CLI commands to the appropriate simulator harness.
    Placeholder outline:
      * Resolve harness dependencies for server and client flows.
      * Forward parsed options to harness builders.
      * Emit TRACE lines through the shared logging helper.
    ]]
    -- TODO(spec:sim-tools): Resolve dependency overrides (e.g. sinks, timers) before invoking harness builders.
    -- TODO(spec:sim-tools): Forward parsed options into build_*_harness implementations once available.
    -- TODO(spec:sim-tools): Emit TRACE lines describing dispatch success or failure outcomes.
    if command == "simulation-created-room" then
        local harness = server_harness.build_server_harness(argv or {}, deps)
        return {
            harness = harness,
            message = logging.trace("sim.server", "dispatch", "stub"),
        }
    elseif command == "simulation-join-room" then
        local harness = client_harness.build_client_harness(argv or {}, deps)
        return {
            harness = harness,
            message = logging.trace("sim.client", "dispatch", "stub"),
        }
    end

    return {
        error = logging.trace("sim.cli", "dispatch", "unknown", { command = command or "" }),
    }
end

return M
