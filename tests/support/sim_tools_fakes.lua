--[=[
 spec:sim-tools simulator fakes placeholder

 Pseudo-code outline:
 * Provide fake harness modules that capture received options for assertions.
 * Emit deterministic TRACE lines for specs without hitting real sockets.
 * Offer utilities to simulate discovery replies and join acknowledgements.
]=]

local SimToolsFakes = {}

function SimToolsFakes.stub_harness()
    return {
        calls = {},
        run = function(self, options)
            table.insert(self.calls, options)
            return nil, "stub harness executed"
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
