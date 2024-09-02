local M = {}

---@param bufnr buffer
---@return TSNode
function M.get_root_node(bufnr)
    local parser_tree = vim.treesitter.get_parser(bufnr)
    return parser_tree:parse(true)[1]:root()
end

---@param node TSNode
---@param path string -- "document.section.request"
---@return table<TSNode>
function M.get_node_by_path(node, path)
    local nodes = {}

    local parts = vim.fn.split(path, "\\.")
    local target = parts[#parts]

    for children in node:iter_children() do
        if vim.tbl_contains(parts, children:type()) then
            if children:type() == target then
                table.insert(nodes, children)
            else
                nodes =
                    vim.list_extend(nodes, M.get_node_by_path(children, path))
            end
        end
    end

    return nodes
end

---@param node TSNode
---@return boolean
function M.node_has_childrn(node, children_type)
    for children_node in node:iter_children() do
        if children_node:type() == children_type then
            return true
        end
    end

    return false
end

---@param node TSNode
---@param find_node_type string
---@param ignore_types table<string>
---@return boolean
function M.prev_sibling_node_has_node(node, find_node_type, ignore_types)
    while node and vim.tbl_contains(ignore_types, node:type()) do
        ---@diagnostic disable-next-line:  cast-local-type
        node = node:prev_sibling()
    end

    ---@diagnostic disable-next-line:  return-type-mismatch
    return node and find_node_type == node:type()
end

---@param node TSNode
---@param find_node_type string
---@param ignore_types table<string>
---@return boolean
function M.next_sibling_node_has_node(node, find_node_type, ignore_types)
    while node and vim.tbl_contains(ignore_types, node:type()) do
        ---@diagnostic disable-next-line: cast-local-type
        node = node:next_sibling()
    end

    ---@diagnostic disable-next-line:  return-type-mismatch
    return node and find_node_type == node:type()
end

return M
