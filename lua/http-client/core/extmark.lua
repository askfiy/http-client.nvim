local config = require("http-client.config")
local parser = require("http-client.core.parser")

local M = {}

local ns = vim.api.nvim_create_namespace("http-client-extmarks-namespace")

--- @param bufnr buffer
function M.add_extmark(bufnr)
    local request_nodes = parser.get_request_nodes(bufnr)

    for _, node in ipairs(request_nodes) do
        local pos = { vim.treesitter.get_node_range(node) }

        local line_number = pos[1]
        for current_number = line_number, 1, -1 do
            local line = vim.api.nvim_buf_get_lines(
                0,
                current_number - 1,
                current_number,
                false
            )[1]

            if line and line:find("^###") then
                vim.api.nvim_buf_set_extmark(bufnr, ns, current_number - 1, 0, {
                    virt_lines = {
                        {
                            {
                                config.extmark.still.virt_text,
                                config.extmark.still.hl_group,
                            },
                        },
                    },
                    invalidate = true,
                })
                break
            end
        end
    end
end

--- @param bufnr buffer
function M.refresh_extmark(bufnr)
    vim.api.nvim_buf_clear_namespace(
        bufnr,
        ns,
        0,
        vim.api.nvim_buf_line_count(bufnr)
    )

    M.add_extmark(bufnr)
end

---@param bufnr buffer
---@line_number number
---@content string
---@hl_group string
function M.reset_extmark_content(bufnr, line_number, content, hl_group)
    -- Retrieve existing extmarks on the specified line
    local marks = vim.api.nvim_buf_get_extmarks(
        bufnr,
        ns,
        { line_number - 1, 0 },
        { line_number, 0 },
        {
            type = "virt_lines",
        }
    )

    -- If an extmark exists, delete it and set a new one
    if not vim.tbl_isempty(marks) then
        local mark = marks[1]
        vim.api.nvim_buf_del_extmark(bufnr, ns, mark[1])
        vim.api.nvim_buf_set_extmark(bufnr, ns, line_number - 1, 0, {
            virt_lines = {
                {
                    {
                        content,
                        hl_group,
                    },
                },
            },
            invalidate = true,
        })
    end
end

return M
