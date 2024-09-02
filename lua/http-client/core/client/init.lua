local config = require("http-client.config")
local parser = require("http-client.core.parser")
local hooks = require("http-client.core.hooks")

local Render = require("http-client.core.render")
local Request = require("http-client.core.struct.request")
local Response = require("http-client.core.struct.response")
local Animation = require("http-client.core.animation")

---@type Client
local proxy = require(("http-client.core.client.%s"):format(config.client))

---@class ClientProxy
---@field request Request
---@field response Response
---@field animation Animation
---@field render Render
local ClientProxy = {}
ClientProxy.__index = ClientProxy

---@param request_info table<TSNode, number, number>
---@return ClientProxy
function ClientProxy.new(request_info)
    local self = setmetatable({}, ClientProxy)

    self.animation = Animation.new(request_info[2])
    self.request = Request.new(parser.rest_node_analyse(request_info[1]))
    self.render = nil
    self.response = nil

    return self
end

--- Start running client instructions.
---
--- The start method provided by ClientProxy is used to request Request objects, obtain Response objects and render Response results.
---
function ClientProxy:start()
    local command = proxy.process_request(self.request)
    self.request:update_command(command)

    local curl_command = proxy.process_curl_command(command)
    self.request:update_curl_command(curl_command)

    self.request = hooks.process_request(self.request)

    self.animation:start()
    vim.system(
        command,
        {
            text = true,
        },
        vim.schedule_wrap(function(out)
            local resp_data = proxy.process_response(out)
            self.response = hooks.process_response(Response.new(resp_data))

            self.animation:clear()

            self.render = Render.new(self.request, self.response)
            self.render:start()
        end)
    )
end

return ClientProxy
