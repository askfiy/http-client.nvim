local extmark = require("http-client.core.extmark")

local M = {}

local rs = vim.api.nvim_create_augroup("http-client-commands-group", {})

function M.startup()
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = rs,
        pattern = { "*.http" },
        callback = function(ev)
            if vim.opt_local.filetype:get() ~= "query" then
                vim.opt_local.filetype = "http"
                vim.defer_fn(function()
                    extmark.refresh_extmark(ev.buf)
                end, 100)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = rs,
        pattern = { "*.http" },
        callback = function(ev)
            extmark.refresh_extmark(ev.buf)
        end,
    })

    vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = { "http" },
        once = true,
        callback = function()
            vim.defer_fn(function()
                vim.opt_local.expandtab = true
                vim.opt_local.shiftwidth = 2
                vim.opt_local.tabstop = 2
                vim.opt_local.softtabstop = 2
            end, 100)
        end,
    })
end

return M
