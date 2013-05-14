-- parts.lua

-- imports
local widget = require('widget')
local hyperua = require('hyperua')
local chart = require('chart')

-- define module
local M = { }


----------------
local SessionErrorItem = { margin = 22 }

function SessionErrorItem:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

function SessionErrorItem:render(group)
   assert(self.message, 'SessionErrorItem requires a message.')

   local message = self.message
   local detail = self.detail or ''
   local margin = self.margin
   display.newText(group, message, margin, margin, native.systemFontBold, 32)
   display.newText(group, detail,  margin, 36 + margin, native.systemFont, 24)
end

----------------
local SessionInfoItem = { margin = 22 }

function SessionInfoItem:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

function SessionInfoItem:render(group)
   assert(self.label and self.link, "SessionInfoItem requires a label and link.")

   local x = self.margin
   local y = self.margin
   local icon = display.newImage(group, 'assets/server.png', x, y, true)
   x = x + icon.width + self.margin
   local text = display.newText(group, 'Session: ' .. self.label, x, y, native.systemFontBold, 36)
   y = y + text.height
   display.newText(group, self.link, x, y, native.systemFont, 24)
end

----------------
local StatusItem = {
   label = '',
   labelWidth = 240,
   labelFont = native.systemFontBold,
   labelFontSize = 24,
   font = native.systemFont,
   fontSize = 24,
}

function StatusItem:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

function StatusItem:render(group)
   display.newText(group, self.label, 0, 0, self.labelFont, self.labelFontSize)
   self.valueField = display.newText(group, 'N/A', self.labelWidth, 0, self.font, self.fontSize)
   self.valueField:setReferencePoint(display.TopLeftReferencePoint)
end

function StatusItem:setValue(value)
   self.valueField:setText(value)
   self.valueField:setReferencePoint(display.TopLeftReferencePoint)
   self.valueField.x = self.labelWidth
end

function StatusItem:update(done)
   return self:query(function (v)
                        self:setValue(v)
                        if done then done() end
                     end)
end

----------------
ValveItem = StatusItem:new
{
   nodeId = false,
   hasToggle = false,
}

function ValveItem:query(onComplete)
   return hyperua.read(self.nodeId, 'value', onComplete)
end

function ValveItem:render(group)
   StatusItem.render(self, group)
   if self.hasToggle then
      group:insert(
         widget.newButton{
            left = 360,
            top = 0,
            width = 120,
            height = 32,
            label = 'Toggle',
            yOffset = -2,
            onRelease = function (event)
               -- send value opposite of valueField
               local value = tostring(self.valueField.text ~= 'Open')
               hyperua.write(self.nodeId, 'value', value,
                             function (e)
                                if not e.isError and e.status == 200 then
                                   self:setValue(value)
                                end
                             end)
            end})
   end
end

function ValveItem:setValue(value)
   local color, text
   if not value then
      text = 'N/A'
      color = { 0, 0, 0 }
   elseif value == 'true' then
      text = 'Open'
      color = { 0, 127, 0 }
   elseif value == 'false' then
      text = 'Closed'
      color = { 0, 0, 255 }
   else
      text = value
      color = { 255, 0, 0 }
   end
   StatusItem.setValue(self, text)
   self.valueField:setTextColor(unpack(color))
end

function ValveItem:update(done)
   assert(self.nodeId, 'Node id required for ValveItem ' .. self.label)
   return StatusItem.update(self, done)
end


-- module factory methods
function M.newSessionError(o)
   return SessionErrorItem:new(o)
end

function M.newSessionInfo(o)
   return SessionInfoItem:new(o)
end

function M.newStatus(o)
   return StatusItem:new(o)
end

function M.newValve(o)
   return ValveItem:new(o)
end

function M.newSeries(o)
   return chart.newSeries(o)
end

function M.newChart(o)
   return chart.newChart(o)
end


-- return module
return M
