-- state.lua

-- define module
local M = { }

----------------
local Machine = { }

function Machine:new(o)
   self.__index = self

   local machine = { states = o }
   for k, _ in pairs(o) do
      machine.states[k].name = k
   end

   assert(machine.states.Initial, "State machine must define an 'Initial' state.")
   machine.current = 'Initial'

   return setmetatable(machine, self)
end

function Machine:transition(event)
   local current = self.states[self.current]
   local common  = self.states.Common
   local handler = current[event.name] or common[event.name]
   if not handler then
      error("Unexpected state transition: '" .. self.current .. "' -> '" .. event.name .. "'")
   else
      local nextState = handler(current, event)
      if nextState == 'Common' then
         error("Do not use 'Common' as a transition state.")
      elseif not self.states[nextState] then
         error("Cannot transition to non-existant state '" .. nextState .. "'")
      else
         self.current = nextState
      end
   end
end

-- factory methods
function M.newMachine(o)
   return Machine:new(o)
end

-- return module
return M
