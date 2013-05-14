-- chart.lua

-- imports
local swq = require('swq')
local hyperua = require('hyperua')

-- define module
local M = { }

local BAD = 'x'

local Series = { }

function Series:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   -- initialize series data queue
   o.data = swq:new{ maxCount = o.numSamples }
   for i = 1, o.numSamples do
      o.data:push(BAD)
   end

   return o
end

function Series:add(x)
   self.data:push(x)
end

function Series:draw(group, options)
   local top = options.top
   local left = options.left
   local width = options.width
   local height = options.height
   local range = self.range
   local color = self.color
   local data = self.data

   local head, tail = data.head, data.tail
   local count = data:count()
   local wSeg = width / (count + 1)
   local hwSeg = wSeg / 2
   local mhSeg = height / 20
   local dRange = range.max - range.min
   local x = left + hwSeg
   while head < tail do
      local a, b = data[head], data[head + 1]
      if a and b and type(a) == 'number' and type(b) == 'number' then
         local x1, y1 = x, (top  + (height * (dRange - a)) / dRange)
         local x2, y2 = x1 + wSeg, (top + (height * (dRange - b)) / dRange)
         for dx = -1,1 do
            for dy = -1,1 do
               local segment = display.newLine(group, x1+dx, y1+dy, x2+dx, y2+dy)
               segment:setColor(unpack(color))
            end
         end
      end
      x = x + wSeg
      head = head + 1
   end
   -- add a text label on right of the series's current value
   local curr = data[tail]
   if type(curr) == 'number' then
      local label = display.newText(group, curr, 0, 0, native.systemFont, 16)
      label:setReferencePoint(display.CenterLeftReferencePoint)
      label.x = x + wSeg + 8
      label.y = top + (height * (dRange - data[tail])) / dRange
   end
end

local Chart = {
   label = '',
   labelWidth = 240,
   labelFont = native.systemFontBold,
   labelFontSize = 24,
}

function Chart:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

function Chart:render(group)
   display.newText(group, self.label, 0, 0, self.labelFont, self.labelFontSize)
   if self.chartView then self.chartView:removeSelf() end
   self.chartView = display.newGroup()
   group:insert(self.chartView)
end

function Chart:drawBackground(options)
   local group = self.chartView
   local top = options.top
   local left = options.left
   local width = options.width
   local height = options.height
   -- draw a gradiated background
   local grad = graphics.newGradient({245, 245, 255}, {235, 235, 245})
   local nBar = 10
   local hBar = height / nBar
   for i = 1, nBar do
      display.newRect(group, left, top + (i-1) * hBar, width, hBar):setFillColor(grad)
   end
   -- add percetage labels on left
   local label = display.newText(group, "100", 0, 0, native.systemFont, 16)
   label:setReferencePoint(display.CenterRightReferencePoint)
   label.x = left - 8
   label.y = top
   label = display.newText(group, "0", 0, 0, native.systemFont, 16)
   label:setReferencePoint(display.CenterRightReferencePoint)
   label.x = left - 8
   label.y = top + height
   -- add series labels below
   local y = top + height + 8
   for _, ser in ipairs(self.series) do
      local label = display.newText(group, ser.label, left, y, native.systemFontBold, 24)
      label:setTextColor(unpack(ser.color))
      y = y + label.height + 8
   end
end

function Chart:draw(options)
   local group = self.chartView
   self:drawBackground(options)
   for _, ser in ipairs(self.series) do
      ser:draw(group, options)
   end
end

function Chart:update(done)
   for _, ser in ipairs(self.series) do
      -- query hyperua server
      hyperua.read(ser.nodeId, 'value',
                  function (value)
                     local value = tonumber(value)
                     if value then
                        ser:add(value)
                     else
                        ser:add(BAD)
                     end
                  end)
   end
   -- Delete previous chart
   for i = self.chartView.numChildren, 1, -1 do
      self.chartView[i]:removeSelf()
   end
   -- Render new chart
   local width = display.contentWidth - 128
   self:draw{ left = 48, top = 48, width = width, height = 320 }

   if done then done() end
end


function M.newSeries(o)
   return Series:new(o)
end

function M.newChart(o)
   return Chart:new(o)
end

return M
