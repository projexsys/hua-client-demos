-- swq.lua
-- sliding window queue

-- define module
local M = { }

function M:count()
   return 1 + self.tail - self.head
end

function M:isEmpty()
   return self.head > self.tail
end

function M:pop()
   local value = self[self.head]
   self[self.head] = nil
   self.head = self.head + 1
   return value
end

function M:push(value)
   self.tail = self.tail + 1
   self[self.tail] = value
   while M.count(self) > self.maxCount do
      M.pop(self)
   end
end

function M:new(o)
   o = o or { maxCount = 120 }
   o = setmetatable({ head = 1, tail = 0, maxCount = o.maxCount }, self)
   self.__index = self
   return o
end

return M
