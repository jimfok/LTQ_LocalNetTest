-- src/sim-tools/logging.lua
-- Placeholder structured logging helper for spec:sim-tools harnesses.
local M = {}

local function serialise_fields(fields)
    --[[
    Prepare key=value fragments for TRACE output once the implementation lands.
    Placeholder outline:
      * Accept a table of fields and turn each into " key=value".
      * Concatenate fragments preserving insertion order.
    ]]
    -- TODO(spec:sim-tools): Preserve insertion order by respecting provided field metadata (e.g. fields.__order) when concatenating fragments instead of relying on pairs().
    -- TODO(spec:sim-tools): Escape pipe and newline delimiters on both keys and values so TRACE output stays machine readable.
    if not fields then
        return ""
    end

    local parts = {}
    for key, value in pairs(fields) do
        table.insert(parts, string.format(" %s=%s", key, tostring(value)))
    end
    return table.concat(parts)
end

function M.trace(component, action, status, fields)
    --[[
    Compose a TRACE line matching the spec:sim-tools logging contract.
    Placeholder outline:
      * Normalise arguments to safe defaults.
      * Concatenate into TRACE|component|action|status format.
      * Append serialised fields when present.
    ]]
    -- TODO(spec:sim-tools): Treat empty strings and whitespace-only component/action/status arguments as missing before applying defaults.
    -- TODO(spec:sim-tools): Route the final TRACE line through configured log sinks (deps.log_sinks or default stdout sink) before returning it for chaining.
    local base = string.format("TRACE|%s|%s|%s", component or "sim.tools", action or "pending", status or "stub")
    return base .. serialise_fields(fields)
end

return M
