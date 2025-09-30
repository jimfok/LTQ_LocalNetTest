--[=[
 spec:sim-tools log sinks placeholder

 Pseudo-code outline:
 * Define sink constructors for stdout, file capture, and in-memory buffers for specs.
 * Allow logging.lua to iterate configured sinks for each TRACE emission.
 * Provide deterministic formatting so tests can assert against emitted lines.
]=]

local LogSinks = {}

function LogSinks.stdout()
    return function(_entry)
        -- Placeholder sink intentionally does nothing until logging is implemented.
    end
end

return LogSinks
