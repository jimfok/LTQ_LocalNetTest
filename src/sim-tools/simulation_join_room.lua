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

local DEFAULT_MULTICAST = "224.0.0.167"
local DEFAULT_BROADCAST = "255.255.255.255"
local DEFAULT_UDP_PORT = 53316
local DEFAULT_PROTOCOL = "localsend"
local BROADCAST_INTERVAL = 1.0
local POLL_INTERVAL = 0.1
local TCP_TIMEOUT = 3
local BROADCAST_ONLY = "broadcast-only"
local UDP_RECEIVE_ATTEMPTS = 8

local function is_multicast(addr)
    if not addr then return false end
    local first_octet = tonumber(addr:match("^(%d+)"))
    return first_octet ~= nil and first_octet >= 224 and first_octet <= 239
end

local function setup_broadcast_listener(port)
    local udp = assert(socket.udp(), "unable to create UDP socket for broadcast listener")
    udp:settimeout(0)
    udp:setoption("reuseaddr", true)
    local reuseport_ok, reuseport_err = udp:setoption("reuseport", true)
    if not reuseport_ok and reuseport_err and reuseport_err ~= "Option not supported" then
        -- proceed; reuseport is not required on all platforms
    end

    local ok_bind, bind_err = udp:setsockname("*", port)
    if not ok_bind then
        udp:close()
        error(string.format("broadcast_listen_failed:%s", bind_err or "bind_error"))
    end

    local ok_broadcast, broadcast_err = udp:setoption("broadcast", true)
    if not ok_broadcast then
        udp:close()
        error(string.format("broadcast_flag_failed:%s", broadcast_err or "setoption_error"))
    end

    return udp
end

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

    return config
end

local function parse_octets(addr)
    if type(addr) ~= "string" then return nil end
    local octets = {}
    for part in addr:gmatch("%d+") do
        octets[#octets + 1] = tonumber(part)
    end
    return octets[1], octets[2], octets[3], octets[4]
end

local function determine_local_ip()
    local dns = socket.dns
    if not (dns and dns.gethostname and dns.toip) then
        return nil
    end
    local hostname = dns.gethostname()
    if not hostname then return nil end
    local primary, details = dns.toip(hostname)
    local candidates = {}
    local function collect(values)
        if type(values) == "string" then
            candidates[#candidates + 1] = values
        elseif type(values) == "table" then
            for _, entry in ipairs(values) do
                collect(entry)
            end
        end
    end
    collect(primary)
    if details and type(details) == "table" then
        collect(details.ip)
        collect(details.alias)
    end

    local function score(addr)
        local a, b = parse_octets(addr)
        if not a or a == 127 then return nil end
        if a == 192 and b == 168 then return 400 end
        if a == 10 then return 350 end
        if a == 172 and b and b >= 16 and b <= 31 then return 300 end
        if a == 169 and b == 254 then return 100 end
        return 200
    end

    local best, best_score
    for _, addr in ipairs(candidates) do
        local s = score(addr)
        if s and (not best_score or s > best_score) then
            best, best_score = addr, s
        end
    end

    return best
end

local function guess_broadcast(ip)
    if type(ip) ~= "string" then return DEFAULT_BROADCAST end
    local octets = {}
    for part in ip:gmatch("%d+") do
        octets[#octets + 1] = tonumber(part)
    end
    local a, b, c = octets[1], octets[2], octets[3]
    if not (a and b and c) then return DEFAULT_BROADCAST end
    if a == 127 or a >= 224 then return DEFAULT_BROADCAST end
    return string.format("%d.%d.%d.255", a, b, c)
end

local function build_broadcast_targets(config_broadcast)
    local targets = {}
    local seen = {}

    local function add(addr, source)
        if not addr or addr == "" then return end
        if not seen[addr] then
            targets[#targets + 1] = { addr = addr, source = source }
            seen[addr] = true
        end
    end

    add(config_broadcast or DEFAULT_BROADCAST, "flag")

    local local_ip = determine_local_ip()
    if local_ip then
        emit("config", "local-ip", { value = local_ip })
    end
    if local_ip then
        add(guess_broadcast(local_ip), "derived")
    end

    if #targets == 0 then
        add(DEFAULT_BROADCAST, "default")
    end

    return targets
end

local function receive_broadcast_event(discovery, config)
    if not (discovery and discovery.udp) then return nil end
    for _ = 1, UDP_RECEIVE_ATTEMPTS do
        local data, ip, port = discovery.udp:receivefrom()
        if not data then break end
        local ok, payload = pcall(json.decode, data)
        if ok and type(payload) == "table" then
            if payload.type == "pong" then
                return {
                    payload = {
                        device_id = payload.peer_id or payload.device_id or "unknown",
                        udp_port = payload.port or config.udp_port,
                        pong = true,
                    },
                    ip = ip,
                    port = payload.port or port,
                    raw_payload = payload,
                    mode = BROADCAST_ONLY,
                }
            elseif payload.protocol == config.protocol and payload.device_id then
                return {
                    payload = payload,
                    ip = ip,
                    port = port,
                    raw_payload = payload,
                    mode = "discover",
                }
            end
        end
    end
    return nil
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
    local targets = build_broadcast_targets(config.broadcast)
    if #targets == 0 then
        emit("config", "error", { reason = "no_broadcast_targets" })
    else
        for idx, entry in ipairs(targets) do
            emit("config", "target", { index = idx, addr = entry.addr, source = entry.source })
        end
    end
    local primary_target = targets[1] and targets[1].addr or config.broadcast
    local discovery_mode = is_multicast(primary_target) and "multicast" or BROADCAST_ONLY
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
        if primary_target then
            discovery_opts.multicast_addr = primary_target
        end
        discovery = Discovery.new(discovery_opts)
        local ok_listen, listen_err = pcall(function()
            discovery:listen()
        end)
        if not ok_listen then
            discovery_mode = BROADCAST_ONLY
            emit("discover", "warn", { reason = listen_err or "listen_failed", mode = BROADCAST_ONLY })
            discovery:close()
            local fallback_udp = setup_broadcast_listener(config.udp_port)
            discovery.udp = fallback_udp
            discovery.multicast_addr = primary_target or discovery.multicast_addr or DEFAULT_MULTICAST
        end
    end)

    if not ok or not discovery then
        emit("boot", "error", { reason = err or "discovery_init_failed" })
        os.exit(1)
    end

    local start_time = socket.gettime()
    local next_broadcast = start_time
    local discover_attempts = 0

    local function dispatch_probe(now)
        if now >= next_broadcast then
            discover_attempts = discover_attempts + 1
            local ok_broadcast, broadcast_err
            local message
            ok_broadcast, broadcast_err = pcall(function()
                message = discovery:broadcast_hello()
            end)
            if not ok_broadcast then
                emit("discover", "error", { reason = broadcast_err or "broadcast_failed", attempt = discover_attempts })
            else
                emit("discover", "sent", { attempt = discover_attempts })
            end
            if message then
                for idx = 1, #targets do
                    local addr = targets[idx].addr
                    if idx > 1 or discovery_mode == BROADCAST_ONLY then
                        local ok_extra, err_extra = pcall(function()
                            local udp_extra = assert(socket.udp(), "unable to create UDP socket for broadcast target")
                            udp_extra:setsockname("*", 0)
                            udp_extra:setoption("broadcast", true)
                            udp_extra:sendto(message, addr, config.udp_port)
                            udp_extra:close()
                        end)
                        if not ok_extra then
                            emit("discover", "error", { reason = err_extra or "broadcast_failed", attempt = discover_attempts, target = addr })
                        else
                            emit("discover", "sent", { attempt = discover_attempts, target = addr })
                        end
                    end
                end
            end
            if discovery_mode == BROADCAST_ONLY then
                local ping_payload = json.encode({
                    type = "ping",
                    peer_id = peer_id,
                    timestamp = socket.gettime(),
                })
                for _, target in ipairs(targets) do
                    local addr = target.addr
                    local ok_ping, ping_err = pcall(function()
                        return discovery.udp:sendto(ping_payload, addr, config.udp_port)
                    end)
                    if ok_ping then
                        emit("discover", "sent", { attempt = discover_attempts, mode = BROADCAST_ONLY, payload = "ping", target = addr })
                    else
                        emit("discover", "error", { reason = ping_err or "ping_failed", attempt = discover_attempts, payload = "ping", target = addr })
                    end
                end
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

        dispatch_probe(now)

        local event
        if discovery_mode == BROADCAST_ONLY then
            event = receive_broadcast_event(discovery, config)
        end
        if not event then
            event = discovery:receive()
        end
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
