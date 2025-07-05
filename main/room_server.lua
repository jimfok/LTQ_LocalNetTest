local socket = require "socket"
local json = require "json"

local M = {}

M.room_id = 1
M.players = {}
M.clients = {}

function M.start(port)
    local server, err = socket.bind("*", port)
    assert(server, err)
    server:settimeout(0)
    M.server = server
    M.port = port
    print("▶▶▶ room_server listening on port " .. port)
end

local function accept_new()
    while M.server do
        local client = M.server:accept()
        if not client then break end
        client:settimeout(0)
        local ip, cport = client:getpeername()
        table.insert(M.clients, {sock = client, ip = ip, port = cport})
    end
end

function M.update()
    if not M.server then return end
    accept_new()
    for i = #M.clients, 1, -1 do
        local c = M.clients[i]
        local line, err = c.sock:receive("*l")
        if line then
            local ok, payload = pcall(json.decode, line)
            local details = ok and json.encode(payload) or line
            print(string.format("Received JoinRoom from %s:%s → %s", c.ip or "-", c.port or "-", details))
            local resp = {status = "Accept", roomId = M.room_id, players = M.players}
            c.sock:send(json.encode(resp) .. "\n")
            c.sock:close()
            table.remove(M.clients, i)
        elseif err == "closed" then
            c.sock:close()
            table.remove(M.clients, i)
        end
    end
end

return M
