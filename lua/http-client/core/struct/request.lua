---@class RawRestData
---@field method string
---@field url string
---@field headers table<string, string>
---@field form_data table<string, string>
---@field files table<string, string>
---@field json_body? string
---@field xml_body? string
---@field raw_body? string
---@field content_type? string

---@class Request
---@field method string
---@field url string
---@field headers table<string, string>
---@field form_data table<string, string>
---@field files table<string, string>
---@field json_body? string
---@field xml_body? string
---@field raw_body? string
---@field content_type? string
---@field command? table<string>
---@field curl_command? string
local Request = {}
Request.__index = Request

---@param rest_data RawRestData
---@return Request
function Request.new(rest_data)
    local self = setmetatable({}, Request)

    for key, value in pairs(rest_data) do
        self[key] = value
    end

    self.command = nil
    self.curl_command = nil

    return self
end

---@param command table<string>
function Request:update_command(command)
    self.command = command
end

---@param curl_command string
function Request:update_curl_command(curl_command)
    self.curl_command = curl_command
end

---@return string
function Request:get_curl_command()
    return self.curl_command
end

return Request
