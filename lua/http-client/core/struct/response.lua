---@class RawRespData
---@field err? string
---@field headers? string
---@field body? string
---@field info? string

---@class Response
---@field content_type string
---@field err? string
---@field version? string
---@field status? string
---@field reason? string
---@field headers? string
---@field body? string
---@field info? string
---@field headers_to_dict? table<string,string>
local Response = {}
Response.__index = Response

---@param resp_data RawRespData
---@return Response
function Response.new(resp_data)
    local self = setmetatable({}, Response)

    for key, value in pairs(resp_data) do
        self[key] = value
    end

    if not self.err then
        local status, headers = self.headers:match("^(.-)\r?\n(.*)")

        if status then
            self.version, self.status, self.reason =
                status:match("^(HTTP/%d%.?%d?) (%d%d%d) ?(.*)$")
        end

        -- Convert the raw headers string into a table
        self.headers_to_dict = {}
        for line in headers:gmatch("[^\r?\n]+") do
            local key, value = line:match("^(.-):%s*(.+)$")
            if key and value then
                self.headers_to_dict[key] = value

                -- Identify and store the content type
                if key:lower():match("^content%-type") then
                    self.content_type = vim.fn.trim(value:lower())
                end
            end
        end
    end

    -- Ensure content_type is initialized
    self.content_type = self.content_type or ""

    return self
end

return Response
