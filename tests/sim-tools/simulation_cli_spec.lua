-- tests/sim-tools/simulation_cli_spec.lua
local cli = require "sim-tools.cli"

describe("Simulation CLI scaffolding (spec:sim-tools)", function()
    it("returns a stub harness when dispatching the server command", function()
        local result = cli.dispatch("simulation-created-room", {}, {})
        assert.is_table(result)
        assert.is_table(result.harness)
    end)

    it("returns an error payload for unknown commands", function()
        local result = cli.dispatch("unknown-command", {}, {})
        assert.is_table(result)
        assert.is_string(result.error)
    end)
end)
