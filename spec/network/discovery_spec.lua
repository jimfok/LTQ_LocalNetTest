require "spec.spec_helper"

local Discovery = require "src.network.discovery"
local network_support = require "spec.support.network_context"
local build_context = network_support.build_discovery_context

describe("network.discovery", function()
    it("configures a multicast listener", function()
        local ctx = build_context()
        local udp = ctx.discovery:listen()
        assert.is_not_nil(udp)
        assert.equal(udp, ctx.socket.created_udps[1])
        assert.same({ "*", Discovery.DEFAULT_PORT }, udp.setsockname_calls[1])
        assert.equal(0, udp.timeout)

        assert.same("reuseaddr", udp.setoption_calls[1][1])
        assert.is_true(udp.setoption_calls[1][2])

        assert.same("reuseport", udp.setoption_calls[2][1])
        assert.is_true(udp.setoption_calls[2][2])

        assert.same("ip-multicast-loop", udp.setoption_calls[3][1])
        assert.is_true(udp.setoption_calls[3][2])

        local membership = udp.setoption_calls[4]
        assert.same("ip-add-membership", membership[1])
        assert.same({ multiaddr = Discovery.DEFAULT_MULTICAST_ADDR, interface = "0.0.0.0" }, membership[2])
    end)

    it("broadcasts hello payload with sys info", function()
        local ctx = build_context()
        ctx.discovery:listen()
        local message = ctx.discovery:broadcast_hello()

        assert.equal("__JSON__", message)
        assert.same({
            device_id = "device-123",
            model = "TestModel",
            protocol = Discovery.DEFAULT_PROTOCOL,
            udp_port = Discovery.DEFAULT_PORT,
        }, ctx.json.last_encoded)

        local broadcast_udp = ctx.socket.created_udps[2]
        assert.is_not_nil(broadcast_udp)
        local send_call = broadcast_udp.sent[1]
        assert.same("__JSON__", send_call.message)
        assert.same(Discovery.DEFAULT_MULTICAST_ADDR, send_call.addr)
        assert.same(Discovery.DEFAULT_PORT, send_call.port)
    end)

    it("invokes callback when receiving remote hello", function()
        local ctx = build_context()
        ctx.discovery:listen()
        local listener = ctx.socket.created_udps[1]

        ctx.json.decode_map["LOCAL"] = {
            protocol = Discovery.DEFAULT_PROTOCOL,
            device_id = "device-123",
            model = "TestModel",
        }

        ctx.json.decode_map["REMOTE"] = {
            protocol = Discovery.DEFAULT_PROTOCOL,
            device_id = "peer-001",
            model = "RemoteModel",
        }

        table.insert(listener.receive_queue, { data = "LOCAL", ip = "192.168.1.5", port = 53316 })
        table.insert(listener.receive_queue, { data = "REMOTE", ip = "192.168.1.20", port = 53317 })

        local events = {}
        ctx.discovery:set_on_hello(function(event)
            events[#events + 1] = event
        end)

        assert.is_nil(ctx.discovery:receive()) -- ignored local loopback
        local event = ctx.discovery:receive()
        assert.is_not_nil(event)
        assert.same("peer-001", event.payload.device_id)
        assert.same("192.168.1.20", event.ip)
        assert.same(53317, event.port)
        assert.equal(1, #events)
    end)

    it("closes listener when requested", function()
        local ctx = build_context()
        ctx.discovery:listen()
        ctx.discovery:close()
        local listener = ctx.socket.created_udps[1]
        assert.is_true(listener.closed)
    end)
    it("allows overriding port via sys.get_config", function()
        local ctx = build_context({ skip_default = true })
        ctx.sys.config["network.discovery_port"] = "60001"
        ctx.discovery = Discovery.new({
            deps = {
                socket = ctx.socket,
                json = ctx.json,
                sys = ctx.sys,
                logger = function() end,
            },
            logger = function() end,
        })
        local udp = ctx.discovery:listen()
        assert.same({ "*", 60001 }, udp.setsockname_calls[1])
    end)
end)
