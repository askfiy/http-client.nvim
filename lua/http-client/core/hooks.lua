local config = require("http-client.config")

local M = {}

--- Processes a request using a hook defined in the configuration.
---
--- @param request Request The request object to be processed.
--- @return Request The processed request object.
function M.process_request(request)
    if config.hooks.process_request then
        return config.hooks.process_request(request)
    end
    return request
end

--- Processes a response using a hook defined in the configuration.
---
--- @param response Response The response object to be processed.
--- @return Response The processed response object.
function M.process_response(response)
    if config.hooks.process_response then
        return config.hooks.process_response(response)
    end
    return response
end

--- Processes a response render on request success
---
---@param request Request The request object used to render the template.
---@param response Response The response object used to render the template.
---@param template string Request success template string
---@return string The rendered template string.
function M.process_template_render(request, response, template)
    if config.hooks.process_template_render then
        return config.hooks.process_template_render(request, response, template)
    end

    return template
end

--- Processes a response render on request fail
---
---@param request Request The request object used to render the template.
---@param response Response The response object used to render the template.
---@param template string Request fail template string
--- @return string The rendered exception template with placeholders replaced.
function M.process_exception_render(request, response, template)
    if config.hooks.process_exception_render then
        return config.hooks.process_exception_render(
            request,
            response,
            template
        )
    end

    return template
end

return M
