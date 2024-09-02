---@diagnostic disable: param-type-mismatch

local uuid = require("http-client.libs.uuid")
local treesitter = require("http-client.libs.treesitter")

local M = {}

--- Reads the environment variables from a JSON file in the specified path.
---
--- @param path string The path to the directory where the environment file is located.
--- @return table<string, string> A table containing the environment variables read from the file.
local function read_to_file(path)
    path = table.concat(
        vim.iter({ path, "http-client.env.json" }):flatten():totable(),
        "/"
    )

    local env_file = {}

    if vim.fn.filereadable(path) == 1 then
        local fp = assert(io.open(path, "r"))
        env_file = vim.json.decode(fp:read("*all"))
        fp:close()
    end

    return env_file
end

--- Loads environment variables defined within the current buffer.
---
--- @return table<string, string> A table containing environment variables from the buffer.
local function load_buffer_env()
    local buffer_env = {}
    local root = treesitter.get_root_node(0)
    local nodes = treesitter.get_node_by_path(
        root,
        "document.section.variable_declaration"
    )

    for _, node in ipairs(nodes) do
        local text = vim.treesitter.get_node_text(node, 0)
        local k, v = text:match("@(.*)=(.*)")
        buffer_env[vim.fn.trim(k)] = vim.fn.trim(v)
    end

    return buffer_env
end

--- Generates values for special placeholders like UUID, date, timestamp, etc., in the content string.
---
--- @param content string The content string containing placeholders.
--- @return table<string, string> A table mapping placeholders to their generated values.
local function generate_magic_variable(content)
    local variables = {}

    -- Handle magic string
    for magic in content:gmatch("{{(%$.-)}}") do
        if magic:find("uuid") then
            variables[magic] = uuid.generate_v4()
        elseif magic:find("date") then
            variables[magic] = os.date("%Y-%m-%d")
        elseif magic:find("timestamp") then
            variables[magic] = os.time()
        elseif magic:find("isoTimestamp") then
            variables[magic] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        elseif magic:find("randomInt") then
            local parts = vim.fn.split(magic)
            if #parts == 1 then
                variables[magic] = math.random(0, 1000)
            elseif #parts == 2 then
                variables[magic] = math.random(0, tonumber(parts[2]))
            elseif #parts == 3 then
                variables[magic] =
                    math.random(tonumber(parts[2]), tonumber(parts[3]))
            end
        end
    end

    return variables
end

--- Replaces placeholders in the content string with their corresponding values from various sources.
---
--- @param content string The content string containing placeholders to be replaced.
--- @return string The content string with placeholders replaced by actual values.
function M.replace_placeholders(content)
    if content:match("{{.*}}") then
        local env = generate_magic_variable(content)

        -- Update env with variables from different sources
        env = vim.tbl_extend("keep", env, load_buffer_env())
        env = vim.tbl_extend("keep", env, read_to_file(vim.fn.expand("%:p:h")))
        env =
            vim.tbl_extend("keep", env, read_to_file(vim.fn.expand("%:p:h:h")))

        for key, value in pairs(env) do
            content = content:gsub("{{" .. key .. "}}", tostring(value))
        end

        local match_placeholder = content:match("{{.*}}")

        assert(
            not match_placeholder,
            ("Untreated Placeholder: %s"):format(match_placeholder)
        )
        return content
    end

    return content
end

return M
