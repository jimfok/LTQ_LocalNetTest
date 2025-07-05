local socket = require "socket"
local M = { udp=nil, timer=0, is_server=false, server=nil, clients={} }

local MULTICAST_IP = "224.0.0.167"
local MULTICAST_PORT = 53316
local TCP_PORT = 60101

local function get_ip()
    local ip = socket.dns.gethostname()
    local addr = socket.dns.toip(ip)
    return addr or "0.0.0.0"
end

function M.start(is_server)
    M.is_server = is_server or false
    M.udp = assert(socket.udp())
    M.udp:setoption("reuseaddr", true)
    M.udp:setsockname("*", MULTICAST_PORT)
    M.udp:settimeout(0)
    M.timer = 0
    if M.is_server then
        M.server = assert(socket.tcp())
        M.server:setoption("reuseaddr", true)
        assert(M.server:bind("*", TCP_PORT))
        M.server:listen()
        M.server:settimeout(0)
    end
end

function M.stop()
    if M.udp then M.udp:close() M.udp=nil end
    if M.server then M.server:close() M.server=nil end
    for _,c in ipairs(M.clients) do c:close() end
    M.clients={}
    M.timer=0
    M.is_server=false
end

function M.become_server()
    if not M.is_server then
        M.stop()
        M.start(true)
    end
end

function M.broadcast_hello()
    if not M.udp then return end
    local msg = M.is_server and ("SERVER with " .. get_ip()) or "HELLO"
    M.udp:sendto(msg, MULTICAST_IP, MULTICAST_PORT)
end

function M.update(dt, add_msg)
    if not M.udp then return end
    M.timer = M.timer + dt
    if M.timer > 2 then
        M.timer = 0
        M.broadcast_hello()
    end
    local data, ip = M.udp:receivefrom()
    if data then
        add_msg(string.format("%s: %s", ip or "?", data))
    end
    if M.is_server and M.server then
        local client = M.server:accept()
        if client then
            client:settimeout(0)
            table.insert(M.clients, client)
            add_msg("New connection from " .. (client:getpeername() or "?"))
        end
        for i, c in ipairs(M.clients) do
            local line, err = c:receive()
            if line then
                add_msg("TCP:" .. line)
            elseif err == "closed" then
                table.remove(M.clients, i)
            end
        end
    end
end

return M
