require "spec.spec_helper"

local Discovery = require "src.network.discovery"

local function build_context(options)
    local json_stub = {
        decode_map = {},
    }

    function json_stub.encode(tbl)
        json_stub.last_encoded = tbl
        return "__JSON__"
    end

    function json_stub.decode(str)
        local payload = json_stub.decode_map[str]
        if not payload then
            error("unknown payload: " .. tostring(str))
        end
        return payload
    end

    local socket_stub = {
        created_udps = {},
    }

    function socket_stub.udp()
        local udp = {
            setoption_calls = {},
            setsockname_calls = {},
            receive_queue = {},
            timeout = nil,
            closed = false,
            sent = {},
        }

        function udp:setoption(name, value)
            table.insert(self.setoption_calls, { name, value })
            return true
        end

        function udp:setsockname(host, port)
            table.insert(self.setsockname_calls, { host, port })
            self.bound = { host = host, port = port }
            return true
        end

        function udp:settimeout(value)
            self.timeout = value
        end

        function udp:receivefrom()
            local msg = table.remove(self.receive_queue, 1)
            if not msg then return nil end
            return msg.data, msg.ip, msg.port
        end

        function udp:sendto(message, addr, port)
            table.insert(self.sent, { message = message, addr = addr, port = port })
            return true
        end

        function udp:close()
            self.closed = true
        end

        table.insert(socket_stub.created_udps, udp)
        return udp
    end

    socket_stub.dns = {
        gethostname = function() return "test-host" end,
        toip = function() return "192.168.1.5" end,
    }

    local sys_stub = {
        config = {},
    }

    function sys_stub.get_sys_info()
        return { device_id = "device-123", model = "TestModel" }
    end

    function sys_stub.get_config(key)
        return sys_stub.config[key]
    end

    local context = {
        json = json_stub,
        socket = socket_stub,
        sys = sys_stub,
    }

    if not (options and options.skip_default) then
        context.discovery = Discovery.new({
            deps = {
                socket = socket_stub,
                json = json_stub,
                sys = sys_stub,
                logger = function() end,
            },
            logger = function() end,
        })
    end

    return context
end

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
