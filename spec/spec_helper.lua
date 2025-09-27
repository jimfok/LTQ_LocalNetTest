package.path = table.concat({
    "src/?.lua",
    "src/?/init.lua",
    package.path,
}, ";")

local M = {}

function M.capture_logger()
    local logs = {}
    local function logger(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        logs[#logs + 1] = table.concat(parts, " ")
    end
    return logger, logs
end

return M
