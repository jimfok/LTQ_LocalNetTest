-- src/sim-tools/log_sinks.lua
-- Placeholder log sink helpers for spec:sim-tools simulators.
local M = {}

function M.stdout_sink()
    --[[
    Return a sink function that writes TRACE lines to stdout during development.
    Placeholder outline:
      * Accept TRACE lines and forward to print for visibility.
      * Guard against nil entries before printing.
    ]]
    return function(line)
        if line then
            print(line)
        end
    end
end

function M.collector_sink()
    --[[
    Return a sink capturing TRACE lines for tests to inspect.
    Placeholder outline:
      * Maintain an internal table of entries.
      * Provide a push method storing new TRACE lines.
    ]]
    local collected = {}
    return {
        entries = collected,
        push = function(_, line)
            if line then
                table.insert(collected, line)
            end
        end,
    }
end

return M
