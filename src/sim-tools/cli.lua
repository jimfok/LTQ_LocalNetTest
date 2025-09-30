--[=[
 spec:sim-tools CLI placeholder

 Pseudo-code outline:
 * Accept argv input describing which simulator flow to execute (e.g. "simulation-created-room" or "simulation-join-room").
 * Parse shared options such as duration, discovery port, and log level flags.
 * Dispatch to the matching harness module while passing structured configuration tables.
 * Surface usage guidance when no command is provided or when arguments are invalid.
]=]

local Cli = {}

local function placeholder()
    return nil, "sim-tools CLI not yet implemented"
end

function Cli.run(argv)
    -- argv is kept so the signature is stable for future implementations.
    return placeholder()
end

return Cli
