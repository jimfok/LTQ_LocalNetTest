--[=[
 spec:sim-tools harness module placeholder aggregator

 Pseudo-code outline:
 * Expose helpers for creating server and client harness loops.
 * Provide constructors or factories that the CLI can require without touching internal file paths.
]=]

local Harness = {
    server = require "sim-tools.harness.server",
    client = require "sim-tools.harness.client",
}

return Harness
