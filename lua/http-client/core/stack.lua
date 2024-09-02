--[[
This is a custom Stack with a capacity that holds the request history of the ClientProxy instance.
It provides basic stack operations such as push, pop, and peek, with capacity management.
]]

---@class Stack
---@field size number The maximum number of elements the stack can hold.
---@field container table<number, ClientProxy> The internal storage for the stack elements.
local Stack = {}

Stack.__index = Stack

---@param size number The maximum capacity of the stack. Defaults to 5 if not provided.
---@return Stack A new instance of Stack.
function Stack.new(size)
    local self = setmetatable({}, Stack)
    self.size = size or 5 -- Set default size if not provided.
    self.container = {} -- Initialize the container to hold stack elements.

    return self
end

---@return ClientProxy|nil The element removed from the top of the stack, or nil if the stack is empty.
function Stack:pop()
    return table.remove(self.container, 1) -- Remove and return the top element of the stack.
end

---@param v ClientProxy The element to be added to the top of the stack.
function Stack:push(v)
    if #self.container >= self.size then
        table.remove(self.container) -- Remove the oldest element if the stack is full.
    end

    table.insert(self.container, 1, v) -- Add the new element to the top of the stack.
end

---@return boolean True if the stack is empty, otherwise false.
function Stack:is_empty()
    return vim.tbl_isempty(self.container) -- Check if the container is empty.
end

---@return ClientProxy The top element of the stack without removing it, or nil if the stack is empty.
function Stack:peek()
    return self.container[1] -- Return the top element of the stack without removing it.
end

return Stack
