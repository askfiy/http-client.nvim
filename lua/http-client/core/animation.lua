local config = require("http-client.config")

local extmark = require("http-client.core.extmark")

--[[
This animation is used to display the extmark text to the right of the request after the request is sent. 
]]

---@class Animation
---@field line number
---@field timer uv_timer_t?
---@field spinner_index number
local Animation = {}
Animation.__index = Animation

---@param line number
---@return Animation
function Animation.new(line)
    local self = setmetatable({}, Animation)

    self.line = line
    self.timer = nil

    self.spinner_index = 1

    return self
end

function Animation:start()
    self.timer = vim.loop.new_timer()

    self.timer:start(
        config.animation.interval,
        config.animation.interval,
        vim.schedule_wrap(function()
            local icon = config.animation.spinner[self.spinner_index]

            extmark.reset_extmark_content(
                0,
                self.line,
                config.extmark.active.virt_text .. " " .. icon,
                config.extmark.active.hl_group
            )

            -- Update index to cycle through spinner symbols
            self.spinner_index = (
                self.spinner_index % #config.animation.spinner
            ) + 1
        end)
    )
end

function Animation:clear()
    extmark.reset_extmark_content(
        0,
        self.line,
        config.extmark.still.virt_text,
        config.extmark.still.hl_group
    )
    self.timer:stop()
    self.timer:close()
end

return Animation
