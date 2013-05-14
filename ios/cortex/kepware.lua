-- kepware.lua

-- imports
local storyboard = require('storyboard')
local widget = require('widget')
local hyperua = require('hyperua')
local parts = require('parts')

-- storyboard scene
local scene = storyboard.newScene()

-- local forward references should go here --
local sessionUrl = nil
local updateTimer = nil
local panelView = nil


local function querySessionStatus(self, onComplete)
   return hyperua.status(onComplete)
end

local function queryServerState(self, onComplete)
   local serverStateNodeId = 'i=2259'
   local serverStates = {
      'Running', 'Failed', 'NoConfiguration', 'Suspended',
      'Shutdown', 'Test', 'CommunicationFault', 'Unknown',
   }
   return hyperua.read(serverStateNodeId, 'value',
                       function (value)
                          local i = tonumber(value)
                          if i then
                             onComplete(serverStates[i + 1])
                          else
                             onComplete(value)
                          end
                       end)
end

local sessionStatus = parts.newStatus
{
   label = 'Session status',
   query = querySessionStatus,
}
local serverState = parts.newStatus
{
   label = 'Server state',
   query = queryServerState,
}
local waterValve = parts.newValve
{
   label = 'Water valve',
   nodeId = 'ns=2-s=InTouch.Demo.WaterValve',
}
local concValve = parts.newValve
{
   label = 'Concentrate valve',
   nodeId = 'ns=2-s=InTouch.Demo.ConcValve',
}
local steamValve = parts.newValve
{
   label = 'Steam valve',
   nodeId = 'ns=2-s=InTouch.Demo.SteamValve',
}
local transferValve = parts.newValve
{
   label = 'Transfer valve',
   nodeId = 'ns=2-s=InTouch.Demo.TransferValve',
}
local outputValve = parts.newValve
{
   label = 'Output valve',
   nodeId = 'ns=2-s=InTouch.Demo.OutputValve',
   hasToggle = true,
}
local reactor = parts.newChart
{
   label = 'Reactor',
   series = {
      parts.newSeries{ nodeId = 'ns=2-s=InTouch.Demo.ReactTemp',
                       numSamples = 120,
                       range = { min = 0, max = 200 },
                       color = { 255, 0, 0 },
                       label = 'Reactor Temp (C)',
                     },
      parts.newSeries{ nodeId = 'ns=2-s=InTouch.Demo.ReactLevel',
                       numSamples = 120,
                       range = { min = 0, max = 2000 },
                       color = { 64, 64, 255 },
                       label = 'Reactor Level (L)',
                     },
      parts.newSeries{ nodeId = 'ns=2-s=InTouch.Demo.ProdLevel',
                       numSamples = 120,
                       range = { min = 0, max = 12000 },
                       color = { 0, 160, 0 },
                       label = "Product Storage (L)",
                     },
   },
}

local updateItems = {
   sessionStatus, serverState,
   waterValve, concValve, steamValve, transferValve, outputValve,
   reactor,
}

local updateScene
local updateCount

local function updateDone()
   updateCount = updateCount - 1
   if updateCount == 0 then
      updateTimer = timer.performWithDelay(1000, updateScene)
   end
end

updateScene = function (event)
   updateCount = 0
   for _, item in ipairs(updateItems) do
      updateCount = updateCount + 1
      item:update(updateDone)
   end
end

local renderBlank = function (event) end

local function renderItem(item)
   return function (event) item:render(event.view) end
end


---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
-- Use this hook to create display objects, add them to view group, etc.
function scene:createScene(event)
   local group = self.view

   display.setDefault('background', 255)
   display.setDefault('textColor', 0)

   panelView = widget.newTableView{
      topPadding = display.statusBarHeight,
      left = 16,
      hideBackground = true,
      noLines = true,
      hideScrollBar = true,
   }
   -- This doesn't work from within the TableView constructor.
   panelView.isLocked = true

   panelView:insertRow{ height = 32, onRender = renderItem(sessionStatus) }
   panelView:insertRow{ height = 32, onRender = renderItem(serverState) }
   panelView:insertRow{ height = 16, onRender = renderBlank }
   panelView:insertRow{ height = 32, onRender = renderItem(waterValve) }
   panelView:insertRow{ height = 32, onRender = renderItem(concValve) }
   panelView:insertRow{ height = 32, onRender = renderItem(steamValve) }
   panelView:insertRow{ height = 32, onRender = renderItem(transferValve) }
   panelView:insertRow{ height = 16, onRender = renderBlank }
   panelView:insertRow{ height = 32, onRender = renderItem(outputValve)}
   panelView:insertRow{ height = 32, onRender = renderBlank }
   panelView:insertRow{ height = 384, onRender = renderItem(reactor) }
end


-- Called immediately after scene has moved onscreen:
-- Use this hook to start timers, load audio, start listeners, etc.
function scene:enterScene(event)
        local group = self.view
        sessionUrl = event.params.url
        hyperua.setSessionUrl(event.params.url)
        updateScene()
end


-- Called when scene is about to move offscreen:
-- Use this hook to stop timers, remove listeners, unload sounds, etc.
function scene:exitScene(event)
        local group = self.view
        if updateTimer then
           timer.cancel(updateTimer)
           updateTimer = nil
        end
end


-- Called prior to the removal of scene's 'view' (display group)
-- Use this hook to remove listeners, widgets, save state, etc.
function scene:destroyScene(event)
        local group = self.view
        panelView:deleteAllRows()
        panelView:removeSelf()
end


---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- 'createScene' event is dispatched if scene's view does not exist
scene:addEventListener('createScene', scene)

-- 'enterScene' event is dispatched whenever scene transition has finished
scene:addEventListener('enterScene', scene)

-- 'exitScene' event is dispatched before next scene's transition begins
scene:addEventListener('exitScene', scene)

-- 'destroyScene' event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener('destroyScene', scene)

---------------------------------------------------------------------------------

return scene
