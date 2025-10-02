local function ensure_package_path()
    local source = debug.getinfo(1, "S").source
    local script_dir = source:match("@(.*/)")
    if not script_dir then
        return
    end
    local repo_root = script_dir:match("^(.*)src/sim%-tools/") or "./"
    local prefixes = {
        repo_root .. "src/?.lua",
        repo_root .. "src/?/init.lua",
        repo_root .. "?.lua",
    }
    for _, prefix in ipairs(prefixes) do
        if not package.path:find(prefix, 1, true) then
            package.path = prefix .. ";" .. package.path
        end
    end
end

ensure_package_path()

local Discovery = require "network.discovery"
local json = require "json"
local socket = require "socket"
local Logging = require "src.sim-tools.logging"

local function build_sys()
    local existing = rawget(_G, "sys")
    if existing then
        return existing
    end

    local ok, module = pcall(require, "sys")
    if ok and module then
        _G.sys = module
        return module
    end

    local fallback = {
        get_sys_info = function()
            return {
                device_id = os.getenv("SIM_TOOLS_DEVICE_ID") or "",
                model = os.getenv("SIM_TOOLS_DEVICE_MODEL") or "sim-tools-cli",
            }
        end,
        get_config = function()
            return nil
        end,
    }
    _G.sys = fallback
    return fallback
end

local function build_sys_info(sys_module)
    if not sys_module then
        return {
            device_id = os.getenv("SIM_TOOLS_DEVICE_ID") or "",
            model = os.getenv("SIM_TOOLS_DEVICE_MODEL") or "sim-tools-cli",
        }
    end

    local ok, info = pcall(sys_module.get_sys_info)
    if not ok or type(info) ~= "table" then
        info = {}
    end

    if not info.device_id or info.device_id == "" then
        info.device_id = os.getenv("SIM_TOOLS_DEVICE_ID") or ""
    end

    if not info.model or info.model == "" then
        info.model = os.getenv("SIM_TOOLS_DEVICE_MODEL") or "sim-tools-cli"
    end

    return info
end

local DEFAULT_BROADCAST = "224.0.0.167"
local DEFAULT_UDP_PORT = 53316
local DEFAULT_PROTOCOL = "localsend"
local BROADCAST_INTERVAL = 1.0
local POLL_INTERVAL = 0.1
local TCP_TIMEOUT = 3

local function emit(action, status, fields)
    local line = Logging.trace("sim.client", action, status, fields)
    if line then
        print(line)
    end
end

local function parse_args(argv)
    local config = {
        broadcast = DEFAULT_BROADCAST,
        udp_port = DEFAULT_UDP_PORT,
        duration = nil,
        protocol = DEFAULT_PROTOCOL,
        discovery_addr = nil,
    }

    local i = 1
    while argv and i <= #argv do
        local argi = argv[i]
        if argi == "--broadcast" and argv[i + 1] then
            config.broadcast = argv[i + 1]
            i = i + 1
        elseif argi == "--udp-port" and argv[i + 1] then
            config.udp_port = tonumber(argv[i + 1]) or config.udp_port
            i = i + 1
        elseif argi == "--protocol" and argv[i + 1] then
            config.protocol = argv[i + 1]
            i = i + 1
        elseif argi == "--duration" and argv[i + 1] then
            config.duration = tonumber(argv[i + 1])
            i = i + 1
        elseif argi == "--help" then
            print("Simulation-Join Room harness")
            print("Usage: lua src/sim-tools/simulation_join_room.lua [--broadcast <addr>] [--udp-port <port>] [--protocol <name>] [--duration <seconds>]")
            os.exit(0)
        end
        i = i + 1
    end

    local function in_multicast_range(address)
        if not address then return false end
        local first_octet = address:match("^(%d+)")
        local first = tonumber(first_octet)
        return first ~= nil and first >= 224 and first <= 239
    end

    if config.broadcast and in_multicast_range(config.broadcast) then
        config.discovery_addr = config.broadcast
    end

    return config
end

local function determine_peer_id(sys_info)
    if sys_info and sys_info.device_id and sys_info.device_id ~= "" then
        return sys_info.device_id
    end
    math.randomseed(os.time())
    return string.format("peer-%06d", math.random(0, 999999))
end

local function attempt_join(event, peer_id, config)
    local host = event and event.ip
    local port = event and event.payload and (event.payload.tcp_port or event.payload.port or event.payload.udp_port) or config.udp_port
    if not host or not port then
        return false, "missing_host_or_port"
    end

    local client, err = socket.tcp()
    if not client then
        return false, err or "tcp_init_failed"
    end

    client:settimeout(TCP_TIMEOUT)
    local ok, connect_err = client:connect(host, port)
    if not ok then
        client:close()
        return false, connect_err or "connect_failed"
    end

    local payload = json.encode({
        type = "JoinRoom",
        peer_id = peer_id,
        timestamp = socket.gettime(),
    })
    local sent, send_err = client:send(payload .. "\n")
    if not sent then
        client:close()
        return false, send_err or "send_failed"
    end

    local response, recv_err = client:receive("*l")
    client:close()
    if not response then
        return false, recv_err or "receive_failed"
    end

    local ok_decode, decoded = pcall(json.decode, response)
    if not ok_decode or type(decoded) ~= "table" then
        return false, "invalid_response"
    end

    return true, decoded
end

local function run_simulation_join_room()
    local config = parse_args(arg)
    local sys_module = build_sys()
    local sys_info = build_sys_info(sys_module)
    local peer_id = determine_peer_id(sys_info)
    emit("boot", "starting", {
        peer = peer_id,
        broadcast = config.broadcast,
        udp_port = config.udp_port,
        protocol = config.protocol,
        duration = config.duration,
    })

    local discovery
    local ok, err = pcall(function()
        local discovery_opts = {
            port = config.udp_port,
            protocol = config.protocol,
            deps = {
                socket = socket,
                json = json,
                sys = sys_module,
                logger = function() end,
            },
            sys_info = sys_info,
        }
        if config.discovery_addr then
            discovery_opts.multicast_addr = config.discovery_addr
        elseif config.broadcast then
            emit("config", "fallback", {
                broadcast = config.broadcast,
                multicast = discovery_opts.multicast_addr or DEFAULT_BROADCAST,
            })
        end
        discovery = Discovery.new(discovery_opts)
        local ok_listen, listen_err = pcall(function()
            discovery:listen()
        end)
        if not ok_listen then
            emit("discover", "error", { reason = listen_err or "listen_failed" })
            discovery:close()
            discovery = nil
            return
        end
    end)

    if not ok or not discovery then
        emit("boot", "error", { reason = err or "discovery_init_failed" })
        os.exit(1)
    end

    local start_time = socket.gettime()
    local next_broadcast = start_time
    local discover_attempts = 0

    local function maybe_broadcast(now)
        if now >= next_broadcast then
            discover_attempts = discover_attempts + 1
            local ok_broadcast, broadcast_err = pcall(function()
                discovery:broadcast_hello()
            end)
            if not ok_broadcast then
                emit("discover", "error", { reason = broadcast_err or "broadcast_failed", attempt = discover_attempts })
            else
                emit("discover", "sent", { attempt = discover_attempts })
            end
            next_broadcast = now + BROADCAST_INTERVAL
        end
    end

    local exit_code = 1
    local joined = false

    while true do
        local now = socket.gettime()
        if config.duration and (now - start_time) >= config.duration then
            emit("exit", "timeout", { elapsed = string.format("%.2f", now - start_time) })
            break
        end

        maybe_broadcast(now)

        local event = discovery:receive()
        if event then
            emit("discover", "match", {
                peer = event.payload and event.payload.device_id or "unknown",
                ip = event.ip or "?",
                udp_port = event.payload and event.payload.udp_port,
            })

            local joined_ok, response_or_err = attempt_join(event, peer_id, config)
            if joined_ok then
                emit("join", "accept", {
                    roomId = response_or_err.roomId,
                    players = response_or_err.players and #response_or_err.players or 0,
                })
                joined = true
                exit_code = 0
                break
            else
                emit("join", "error", {
                    reason = response_or_err,
                    peer = event.payload and event.payload.device_id or "unknown",
                })
            end
        end

        socket.sleep(POLL_INTERVAL)
    end

    if discovery then
        discovery:close()
    end

    if joined then
        emit("exit", "ok", { elapsed = string.format("%.2f", socket.gettime() - start_time) })
    else
        emit("exit", "failed", { elapsed = string.format("%.2f", socket.gettime() - start_time) })
    end

    os.exit(exit_code)
end

run_simulation_join_room()
