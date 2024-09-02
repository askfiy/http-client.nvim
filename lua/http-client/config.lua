---@class config
---@field client string
---@field animation table<string, any>
---@field extmark table<string, any>
---@field render table<string, any>
---@field hooks table<string, any>
local M = {}

local config = {
    client = "curl",
    animation = {
        spinner = { "|", "/", "-", "\\" },
        interval = 100,
    },
    extmark = {
        still = {
            virt_text = "Send Request",
            hl_group = "Comment",
        },
        active = {
            virt_text = "Sending",
            hl_group = "Comment",
        },
    },
    render = {
        open = {
            width = nil, -- nil | number
            height = nil, -- nil | number,
            foucs = true,
        },
        keybinds = {
            help = "?",
            copy_curl_command = "<leader>cp",
        },
    },
    hooks = {
        process_request = function(request)
            return request
        end,
        process_response = function(response)
            return response
        end,
        process_template_render = function(request, response, template)
            return template
        end,
        process_exception_render = function(request, response, template)
            return template
        end,
    },
}

setmetatable(M, {
    -- getter
    __index = function(_, key)
        return config[key]
    end,

    -- setter
    __newindex = function(_, key, value)
        config[key] = value
    end,
})

---@param opts table<string, any>
function M.update(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
