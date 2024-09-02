---@class Client
local M = {}

---@param request Request
---@return table<string>
function M.process_request(request)
    local cmd = {
        "curl",
        "-i",
        "-X",
        request["method"],
        request.url,
    }

    if request.headers then
        for hk, hv in pairs(request.headers) do
            table.insert(cmd, "-H")
            table.insert(cmd, ("%s:%s"):format(hk, hv))
        end
    end

    if request.raw_body then
        table.insert(cmd, "-d")
        table.insert(cmd, request.raw_body)
    end

    if request.xml_body then
        table.insert(cmd, "-d")
        table.insert(cmd, request.xml_body)
    end

    if request.json_body then
        table.insert(cmd, "-d")
        table.insert(cmd, request.json_body)
    end

    for form_key, form_value in pairs(request.form_data) do
        table.insert(cmd, "-F")
        table.insert(cmd, ("%s=%s"):format(form_key, form_value))
    end

    for file_name, file_path in pairs(request.files) do
        table.insert(cmd, "-F")
        table.insert(cmd, ("%s=@%s"):format(file_name, file_path))
    end

    -- Add time and size output format
    table.insert(cmd, "-w")
    table.insert(cmd, "{{%{time_total}}} {{%{size_request}}}")

    return cmd
end

---@param cmd table<string>
---@return string
function M.process_curl_command(cmd)
    local skip = { "-H", "-F", "-d" }
    local skip_next = false
    local curl_command = {}

    for _, element in ipairs(cmd) do
        -- Skip the timer argument
        if element == "-w" then
            break
        end

        if vim.tbl_contains(skip, element) then
            table.insert(curl_command, element)
            skip_next = true
        elseif skip_next then
            table.insert(curl_command, "'" .. element .. "'")
            skip_next = false
        else
            table.insert(curl_command, element)
        end
    end

    return table.concat(curl_command, " ")
end

---@param out vim.SystemCompleted
---@return RawRespData
function M.process_response(out)
    ---@type RawRespData
    local resp_data = {}

    -- Extract error message if present
    local err = out.stderr:match("(curl: %(%d+%) .+)")

    if not err then
        -- Skip the "100 Continue" response
        local stdout = out.stdout:gsub("HTTP/.* 100 Continue\r?\n\r?\n", "")
        local headers, body, time, size =
            stdout:match("^(.-)\r?\n\r?\n(.*)\r?\n?{{(.*)}} {{(.*)}}")

        -- Convert time from seconds to milliseconds
        local time_seconds = tonumber(time)
        time = string.format("%d ms", math.floor(time_seconds * 1000))

        -- Format size into a human-readable format
        local size_number = tonumber(size)
        local formatted_size

        if size_number >= 1024 * 1024 * 1024 then
            formatted_size =
                string.format("%.2f G", size_number / (1024 * 1024 * 1024))
        elseif size_number >= 1024 * 1024 then
            formatted_size =
                string.format("%.2f M", size_number / (1024 * 1024))
        elseif size_number >= 1024 then
            formatted_size = string.format("%.2f K", size_number / 1024)
        else
            formatted_size = string.format("%d B", size_number)
        end

        size = formatted_size

        -- Populate response data
        resp_data.headers = headers
        resp_data.body = body
        resp_data.info = ("time: %s\nsize: %s"):format(time, size)
    else
        resp_data.err = err
    end

    return resp_data
end

return M
