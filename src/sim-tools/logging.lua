--[=[
 spec:sim-tools logging utility placeholder

 Pseudo-code outline:
 * Provide helpers for emitting TRACE lines with consistent prefixes.
 * Allow harness modules to request contextual loggers (server vs client flows).
 * Route events to sinks defined in `log_sinks.lua` while keeping side effects injectable for tests.
]=]

local Logging = {}

function Logging.build_trace_logger(_options)
    -- Placeholder keeps API surface for upcoming structured logging implementation.
    return function()
        return nil, "trace logging not yet implemented"
    end
end

return Logging
