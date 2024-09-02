--[[
Come from:
    - https://github.com/thibaultcha/lua-resty-jit-uuid/blob/master/lib/resty/jit-uuid.lua

Thank you!
]]

local bit = require("bit")

local tohex = bit.tohex
local band = bit.band
local bor = bit.bor
local fmt = string.format
local random = math.random

local uuid = {}

function uuid.generate_v4()
    return (
        fmt(
            "%s%s%s%s-%s%s-%s%s-%s%s-%s%s%s%s%s%s",
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),

            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),

            tohex(bor(band(random(0, 255), 0x0F), 0x40), 2),
            tohex(random(0, 255), 2),

            tohex(bor(band(random(0, 255), 0x3F), 0x80), 2),
            tohex(random(0, 255), 2),

            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2),
            tohex(random(0, 255), 2)
        )
    )
end

return uuid
