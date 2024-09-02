local env = require("http-client.core.env")
local treesitter = require("http-client.libs.treesitter")

local replace_placeholders = env.replace_placeholders

local M = {}

--- Escapes a URL string for use in a query
---
--- This function replaces special characters in the URL with their percent-encoded equivalents.
---
---@param s string The URL string to be escaped.
---@return string The escaped URL string.
local function url_escape(s)
    return (
        string.gsub(s, "([^A-Za-z0-9_])", function(c)
            return string.format("%%%02x", string.byte(c))
        end)
    )
end

---@param bufnr buffer
---@return table<TSNode>
function M.get_request_nodes(bufnr)
    local root = treesitter.get_root_node(bufnr)
    local request_nodes = {}

    for _, node in
        ipairs(treesitter.get_node_by_path(root, "document.section.request"))
    do
        if
            treesitter.prev_sibling_node_has_node(node, "request_separator", {
                "request",
                "comment",
                "variable_declaration",
            })
        then
            table.insert(request_nodes, node)
        end
    end

    return request_nodes
end

---@return table<TSNode, number, number>
function M.get_request_info_by_cursor()
    local current_line_number = vim.api.nvim_win_get_cursor(0)[1]
    local nearest_comment_line_number = nil

    -- Find the nearest "###" line upwards
    for line_number = current_line_number, 1, -1 do
        local line = vim.api.nvim_buf_get_lines(
            0,
            line_number - 1,
            line_number,
            false
        )[1]

        if line and line:find("^###") then
            nearest_comment_line_number = line_number
            break
        end
    end

    if nearest_comment_line_number then
        -- Get the comment node
        local node = vim.treesitter.get_node({
            bufnr = 0,
            pos = {
                nearest_comment_line_number - 1,
                0,
            },
        })

        -- Process multi-line comments down to nodes that aren't requests
        while
            node
            and treesitter.next_sibling_node_has_node(
                ---@diagnostic disable-next-line: param-type-mismatch
                node:next_sibling(),
                "request",
                { "comment", "variable_declaration" }
            )
        do
            node = node:next_sibling()
        end

        if node and "request" == node:type() then
            local pos = { node:range() }

            return {
                node,
                nearest_comment_line_number,
                pos[3],
            }
        end
    end

    return {}
end

---@param url_node TSNode
---@return RawRestData
function M.url_node_analyse(url_node, rest_data)
    local text = replace_placeholders(vim.treesitter.get_node_text(url_node, 0))

    local parts = vim.fn.split(text, "?", 1)

    local url = parts[1]
    local query = parts[2]

    if not query then
        rest_data["url"] = url
    else
        local query_encoding = {}

        for _, params in pairs(vim.fn.split(query, "&")) do
            local params_parts = vim.fn.split(params, "=")

            local k = params_parts[1]
            local v = params_parts[2]

            if not v then
                table.insert(query_encoding, k)
            else
                table.insert(query_encoding, ("%s=%s"):format(k, url_escape(v)))
            end
        end

        rest_data["url"] = ("%s?%s"):format(
            url,
            vim.fn.join(query_encoding, "&")
        )
    end

    return rest_data
end

---@param head_node TSNode
---@return RawRestData
function M.head_node_analyse(head_node, rest_data)
    local text =
        replace_placeholders(vim.treesitter.get_node_text(head_node, 0))

    local parts = vim.fn.split(text, ":", 1)

    local k = vim.fn.trim(parts[1])
    local v = vim.fn.trim(parts[2])

    if k:lower() == "content-type" then
        rest_data.content_type = v
    end

    rest_data.headers[k] = v

    return rest_data
end

---@param raw_body_node TSNode
---@return RawRestData
function M.raw_body_node_analyse(raw_body_node, rest_data)
    local text =
        replace_placeholders(vim.treesitter.get_node_text(raw_body_node, 0))

    text = vim.fn.trim(text):gsub(" ", "")

    if
        not rest_data.content_type
        or rest_data.content_type:match("application/x%-www%-form%-urlencoded")
    then
        rest_data.raw_body = text:gsub("\n", "")
    else
        for _, content in ipairs(vim.fn.split(text, "\n")) do
            local parts = vim.fn.split(content, "=", 1)
            local k = parts[1]
            local v = parts[2]

            if not k:match("^@") then
                rest_data.form_data[k] = v
            else
                rest_data.files[k:gsub("@", "")] = vim.fn.expand(v)
            end
        end
    end

    return rest_data
end

---@param external_node TSNode
---@param rest_data table<string>
function M.external_node_analyse(external_node, rest_data)
    for node in external_node:iter_children() do
        if "path" == node:type() then
            local text =
                replace_placeholders(vim.treesitter.get_node_text(node, 0))
            local parts = vim.fn.split(text, ":", 1)

            local file_name = ""
            local file_path = ""

            if #parts > 1 then
                file_name = vim.fn.trim(parts[1])
                file_path = vim.fn.expand(vim.fn.trim(parts[2]))
            else
                file_path = vim.fn.expand(vim.fn.trim(parts[1]))
                file_name = vim.fn.fnamemodify(file_path, ":t:r")
            end
            rest_data.files[file_name] = file_path
        end
    end
end

---@param rest_node TSNode
---@return RawRestData
function M.rest_node_analyse(rest_node)
    local rest_data = {}

    rest_data.method = "GET"
    rest_data.headers = {}
    rest_data.form_data = {}
    rest_data.files = {}

    for node in rest_node:iter_children() do
        local node_type = node:type()

        if node_type == "target_url" then
            M.url_node_analyse(node, rest_data)
        elseif node_type == "header" then
            M.head_node_analyse(node, rest_data)
        elseif node_type == "raw_body" then
            M.raw_body_node_analyse(node, rest_data)
        elseif node_type == "external_body" then
            M.external_node_analyse(node, rest_data)
        else
            rest_data[node_type] =
                replace_placeholders(vim.treesitter.get_node_text(node, 0))
        end
    end

    return rest_data
end

return M
