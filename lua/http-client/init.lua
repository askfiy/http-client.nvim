-- author: askfiy

local config = require("http-client.config")
local parser = require("http-client.core.parser")
local command = require("http-client.core.command")

local Stack = require("http-client.core.stack")
local Client = require("http-client.core.client")

vim._json = require("http-client.libs.json")

-- require("http-client.debug")

local stack = Stack.new(3)

local M = {}

local function send_request()
    local request_info = parser.get_request_info_by_cursor()

    if vim.tbl_isempty(request_info) then
        vim.notify("Not found request", "ERROR", {
            annote = "[http-client]",
        })
        return
    end

    local client = Client.new(request_info)
    client:start()

    stack:push(client)
end

--- Reruns the last executed request.
---
--- The request is retrieved from the top of the stack and executed again.
---
local function last_request()
    if not stack:is_empty() then
        stack:peek():start()
    else
        vim.notify("Failed, not found last request", "ERROR", {
            annote = "[http-client]",
        })
    end
end

--- Renders the last executed request's response.
---
--- The render process is initiated for the request on the top of the stack.
---
local function last_render()
    if not stack:is_empty() then
        stack:peek().render:start()
    else
        vim.notify("Failed, not found last request", "ERROR", {
            annote = "[http-client]",
        })
    end
end

---@param opts table<string, any>
function M.setup(opts)
    config.update(opts)

    command.startup()

    local cmds = {
        sendRequest = send_request,
        lastRequest = last_request,
        lastRender = last_render,
    }

    vim.api.nvim_create_user_command("HttpClient", function(env)
        if cmds[env.args] then
            cmds[env.args]()
        else
            vim.notify("Invalid command", "ERROR", {
                annote = "[http-client]",
            })
        end
    end, {
        nargs = 1,
        complete = function(arglead, cmdline, cursorpos)
            return vim.tbl_keys(cmds)
        end,
    })
end

return M
