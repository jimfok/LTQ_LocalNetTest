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

return SimToolsFakes
