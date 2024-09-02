local config = require("http-client.config")
local hooks = require("http-client.core.hooks")

local render = config.render
local keybinds = render.keybinds

local global_window = nil

---@class Render
---@field request Request
---@field response Response
---@field template string
---@field bufnr number
local Render = {}

Render.__index = Render

---@param request Request
---@param response Response
---@return Render
function Render.new(request, response)
    local self = setmetatable({}, Render)

    self.bufnr = nil
    self.request = request
    self.response = response

    if not self.response.err then
        self.template = hooks.process_template_render(
            request,
            response,
            self:get_render_template()
        )
    else
        self.template = hooks.process_exception_render(
            request,
            response,
            self:get_exception_template()
        )
    end

    return self
end

---
--- renders the final Respencer result
---
function Render:start()
    self:open()
    self:render()
    self:bindkeys()
end

---@return string The error template to be displayed when there is an error in the response.
function Render:get_exception_template()
    return self.response.err
end

---@return string The normal template based on the content type of the response.
function Render:get_render_template()
    local BASE_TEMPLATE = "%s\n---\n%s\n---\n%s\n"

    if self.response.content_type:match("application/json") then
        return BASE_TEMPLATE:format(
            self.response.headers,
            ("```json\n%s\n```"):format(
                vim._json.encode(vim._json.decode(self.response.body), {
                    indent = true,
                })
            ),
            self.response.info
        )
    end

    if self.response.content_type:match("application/xml") then
        return BASE_TEMPLATE:format(
            self.response.headers,
            ("%s\n---\n```xml\n%s\n```"):format(
                self.response.headers,
                vim.fn.trim(self.response.body)
            ),
            self.response.info
        )
    end

    if self.response.content_type:match("text/html") then
        return BASE_TEMPLATE:format(
            self.response.headers,
            ("%s\n---\n```html\n%s\n```"):format(
                self.response.headers,
                vim.fn.trim(self.response.body)
            ),
            self.response.info
        )
    end

    return BASE_TEMPLATE:format(
        self.response.headers,
        self.response.body,
        self.response.info
    )
end

--- Opens the render window and sets up the buffer for displaying the rendered content.
function Render:open()
    if not global_window or not vim.api.nvim_win_is_valid(global_window) then
        global_window = vim.api.nvim_open_win(0, render.open.foucs, {
            split = "right",
            style = "minimal", -- Minimal UI
            width = render.open.width,
            height = render.open.height,
        })
        vim.wo[global_window].conceallevel = 2
    end

    if not self.bufnr then
        self.bufnr = vim.api.nvim_create_buf(false, true)

        vim.bo[self.bufnr].syntax = "markdown"
        vim.bo[self.bufnr].filetype = "markdown"

        vim.lsp.util.stylize_markdown(
            self.bufnr,
            vim.fn.split(self.template, "\n"),
            {
                width = vim.api.nvim_win_get_width(global_window),
            }
        )

        vim.bo[self.bufnr].modifiable = false
    end

    vim.api.nvim_win_set_buf(global_window, self.bufnr)
end

--- Renders the content in the buffer using syntax highlighting for HTTP properties.
function Render:render()
    local match_groups = {
        {
            "@property.http",
            [[\v\zs.*\ze: .*]],
        },
        { "@attribute.http", [[\v\zsHTTPS?\/.*\ze\s\d*\s\w*]] },
        { "@constant.http", [[\vHTTPS?\/.*\s\zs\d*\ze\s\w*]] },
        { "@constant.http", [[\vHTTPS?\/.*\s\d*\s\zs\w*\ze]] },
    }

    for _, match_group in ipairs(match_groups) do
        vim.fn.matchadd(
            match_group[1],
            match_group[2],
            1,
            -1,
            { window = global_window }
        )
    end
end

--- Binds key mappings for the render buffer to copy the curl command and get help.
function Render:bindkeys()
    assert(self.bufnr, "Invalid bufnr")
    assert(global_window, "Invalid window")

    vim.keymap.set({ "n" }, keybinds.copy_curl_command, function()
        if self.request:get_curl_command() then
            vim.fn.setreg(vim.v.register, self.request:get_curl_command())
            vim.notify("Copy curl command success", "INFO", {
                annote = "[http-client]",
            })
        else
            vim.notify(
                "Copy curl command failed, invalid curl command",
                "ERROR",
                {
                    annote = "[http-client]",
                }
            )
        end
    end, { buffer = self.bufnr })

    vim.keymap.set({ "n" }, keybinds.help, function()
        local win_width = vim.api.nvim_win_get_width(global_window)
        local win_height = vim.api.nvim_win_get_height(global_window)

        vim.lsp.util.open_floating_preview(
            {
                "Http-Client Keybinds",
                "---",
                ("%s            Get Help"):format(keybinds.help),
                ("%s   Copy curl command"):format(keybinds.copy_curl_command),
            },
            "markdown",
            {
                border = "single",
                width = win_width > 30 and 30 or win_width,
                height = win_height > 30 and 30 or win_height,
            }
        )
    end, { buffer = self.bufnr })
end

return Render
