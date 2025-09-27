local Discovery = require "src.network.discovery"
local RoomServer = require "src.network.room_server"

local M = {}

function M.build_discovery_context(options)
    options = options or {}

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

    if not options.skip_default then
        context.discovery = Discovery.new({
            deps = {
                socket = socket_stub,
                json = json_stub,
                sys = sys_stub,
                logger = options.logger or function() end,
            },
            logger = options.logger or function() end,
        })
    end

    return context
end

function M.build_room_server_context(options)
    options = options or {}

    local json_stub = {
        encoded = {},
        decode_map = {},
    }

    function json_stub.encode(tbl)
        local token = string.format("__ENCODED_%d__", #json_stub.encoded + 1)
        json_stub.encoded[#json_stub.encoded + 1] = { token = token, value = tbl }
        return token
    end

    function json_stub.decode(str)
        local payload = json_stub.decode_map[str]
        if not payload then
            error("unknown payload: " .. tostring(str))
        end
        return payload
    end

    local socket_stub = {
        bind_calls = {},
        assigned_port = 45000,
    }

    function socket_stub.bind(host, port)
        local server = {
            host = host,
            port = port,
            timeout = nil,
            closed = false,
            accept_queue = {},
        }

        function server:settimeout(value)
            self.timeout = value
        end

        function server:accept()
            return table.remove(self.accept_queue, 1)
        end

        function server:getsockname()
            return self.host, self.port == 0 and socket_stub.assigned_port or self.port
        end

        function server:close()
            self.closed = true
        end

        table.insert(socket_stub.bind_calls, { host = host, port = port, server = server })
        socket_stub.last_server = server
        return server
    end

    local logs = {}
    local function logger(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        logs[#logs + 1] = table.concat(parts, " ")
    end

    local server = RoomServer.new({
        deps = {
            socket = socket_stub,
            json = json_stub,
            logger = options.logger or logger,
        },
        logger = options.logger or logger,
        room_id = options.room_id or 42,
        players = options.players or { { id = 1 } },
    })

    return {
        json = json_stub,
        socket = socket_stub,
        server = server,
        logs = logs,
        logger = logger,
    }
end

return M
