-- tests/support/sim_tools_fakes.lua
-- Placeholder fakes for spec:sim-tools simulator specs.
local M = {}

function M.build_fake_socket()
    --[[
    Return a minimal fake socket capturing payloads for future assertions.
    Placeholder outline:
      * Capture payloads pushed through send for later inspection.
      * Expand into richer fake sockets once networking hooks land.
    ]]
    -- TODO(spec:sim-tools): Record payload metadata (timestamps, sizes) for richer assertions.
    -- TODO(spec:sim-tools): Emulate socket lifecycle methods needed by harness implementations.
    local fake = { sent = {} }
    function fake:send(payload)
        table.insert(self.sent, payload)
    end
    return fake
end

function M.build_fake_timer()
    --[[
    Provide a stub timer interface consumed by harness loops later on.
    Placeholder outline:
      * Track elapsed time as ticks are invoked.
      * Offer helpers for advancing time deterministically.
    ]]
    -- TODO(spec:sim-tools): Track scheduled callbacks and trigger them during tick advances.
    -- TODO(spec:sim-tools): Provide helpers to reset elapsed time between spec runs.
    return {
        elapsed = 0,
        tick = function(self, delta)
            self.elapsed = self.elapsed + (delta or 0)
        end,
    }
end

function M.collect_trace_logs()
    --[[
    Capture TRACE lines pushed by log sinks during specs.
    Placeholder outline:
      * Store each TRACE entry for assertions.
      * Expose both the list and sink function to specs.
    ]]
    -- TODO(spec:sim-tools): Allow filtering or pattern matching when collecting TRACE lines.
    -- TODO(spec:sim-tools): Expose helper assertions for validating expected TRACE sequences.
    local lines = {}
    return {
        lines = lines,
        sink = function(_, line)
            table.insert(lines, line)
        end,
    }
end

return M
