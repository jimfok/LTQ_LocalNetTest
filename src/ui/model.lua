local MAX_LOGS = 32

local DEFAULT_STATES = { "splash", "menu", "create", "join" }

local contexts = {}

local function ensure(name)
    local context = contexts[name]
    if not context then
        context = { logs = {}, status = "" }
        contexts[name] = context
    end
    return context
end

for _, name in ipairs(DEFAULT_STATES) do
    ensure(name)
end

local M = {
    state = "splash",
    peer_id = "",
    peer_ip = "",
    broadcast_ip = "",
}

function M.set_state(state)
    M.state = state or "splash"
end

function M.get_state()
    return M.state
end

function M.set_peer_id(peer_id)
    M.peer_id = peer_id or ""
end

function M.get_peer_id()
    return M.peer_id
end

function M.set_peer_ip(peer_ip)
    M.peer_ip = peer_ip or ""
end

function M.get_peer_ip()
    return M.peer_ip
end

function M.set_broadcast_ip(ip)
    M.broadcast_ip = ip or ""
end

function M.get_broadcast_ip()
    return M.broadcast_ip
end

function M.set_status(name, status)
    ensure(name).status = status or ""
end

function M.get_status(name)
    return ensure(name).status
end

function M.clear_logs(name)
    ensure(name).logs = {}
end

function M.append_log(name, line)
    if not line then return end
    local context = ensure(name)
    local logs = context.logs
    logs[#logs + 1] = tostring(line)
    while #logs > MAX_LOGS do
        table.remove(logs, 1)
    end
end

function M.get_logs(name)
    return ensure(name).logs
end

return M
