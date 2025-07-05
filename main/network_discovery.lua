-- main/network_discovery.lua
local socket = require "socket"
local json   = require "json"
local SYS    = sys.get_sys_info()

local M = {}

--- 建立並設定好用來收 Multicast 的 UDP socket
function M.listen()
    local udp = assert(socket.udp(), "無法建立 UDP socket")
    udp:setoption("reuseaddr", true)                       -- 允許重複 bind
    assert(udp:setsockname("*", 53316))                    -- 改成 53316
    udp:settimeout(0)
    udp:setoption("ip-multicast-loop", true)
    -- 正確的加入方式：
    local mreq = { multiaddr = "224.0.0.167", interface = "0.0.0.0" }
    assert(udp:setoption("ip-add-membership", mreq))
    M.udp = udp
    print("▶▶▶ network_discovery: listener ready on 224.0.0.167:53316")
end

--- 廣播 HELLO 到 224.0.0.167:53316
function M.broadcast_hello()
    local udp = assert(socket.udp())
    udp:setsockname("*", 0)
    udp:setoption("ip-multicast-ttl",   1)
    udp:setoption("ip-multicast-loop",  true)
    local payload = {
        device_id = SYS.device_id,
        model     = SYS.model,
        protocol  = "localsend",
        udp_port  = 53316,                             -- 同樣改 53316
    }
    local msg = json.encode(payload)
    udp:sendto(msg, "224.0.0.167", 53316)
    udp:close()
    print("▶▶▶ broadcast HELLO:", msg)
end

--- 嘗試接收一筆 incoming message
function M.receive()
    if not M.udp then return end
    local data, ip, port = M.udp:receivefrom()
    if data then
        local ok, t = pcall(json.decode, data)
        if ok and t.protocol == "localsend" then
            print(string.format(
              "👍 Received HELLO from %s:%d → device_id=%s, model=%s",
              ip, port, t.device_id or "-", t.model or "-"
            ))
        end
    end
end

return M
