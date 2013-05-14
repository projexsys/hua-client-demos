-- sessions.lua

-- imports
local storyboard = require('storyboard')
local widget = require('widget')
local hyperua = require('hyperua')
local parts = require('parts')
local state = require('state')

-- storyboard scene
local scene = storyboard.newScene()

-- local forward references should go here --
local serverUrl = 'http://localhost:3000'
local updateTimer = nil
local netRequest = nil
local serverInput = nil
local sessionList = nil

local function linkContent(link)
   return link.child[1]
end

local function linkAttr(link, attrName)
   for _, attr in pairs(link.attrs) do
      if attr.name == attrName then
         return attr.value
      end
   end
   return ''
end

local function onRowEvent(event, item)
   if event.phase == 'tap' then
      storyboard.gotoScene('kepware', { params = { url = serverUrl .. item.link }})
   end
end

local updaterSM                 -- forward declaration of state machine

local function updateScene(event)
   updaterSM:transition(event)
end

local function processResponse(result, arg)
   updateScene{ name = 'networkRequest' }

   -- Remove all previous sessions.
   sessionList:deleteAllRows()

   if type(result) ~= 'table' then
      -- An error or some status message: display it.
      local item = parts.newSessionError{ message = result, detail = arg }
      sessionList:insertRow{ height = 84, onRender = function (e) item:render(e.view) end }
   else
      if #result == 0 then
         -- No sessions: display appropriate message.
         local item = parts.newSessionError{ message = 'No sessions found.' }
         sessionList:insertRow{ height = 84, onRender = function (e) item:render(e.view) end }
      else
         -- Found some sessions; display each it its own row.
         for _, sessionLink in pairs(result) do
            local item = parts.newSessionInfo
            {
               label = linkContent(sessionLink),
               link  = linkAttr(sessionLink, 'href'),
            }
            sessionList:insertRow{
               height = 160,
               onRender = function (e) item:render(e.view) end,
               onEvent  = function (e) onRowEvent(e, item) end,
            }
         end
      end
   end
end

local function startRequest()
   updateTimer = timer.performWithDelay(5000, updateScene) -- updateScene{ name = 'timer' }
   netRequest = hyperua.sessions(serverUrl, processResponse)
end

local function cancelRequest()
   if updateTimer then timer.cancel(updateTimer) ; updateTimer = nil end
   if netRequest then network.cancel(netRequest) ; netRequest = nil end
end

local function restartRequest()
   cancelRequest()
   startRequest()
end

-- define state machine
updaterSM = state.newMachine
{
   ['Common'] = {
      exitScene = function (s, e) cancelRequest() ; return 'Initial' end,
      userInput = function (s, e) restartRequest() ; return 'Waiting' end,
   },
   ['Initial'] = {
      enterScene = function (s, e) startRequest() ; return 'Waiting' end,
      exitScene = nil,          -- override common exitScene handler
   },
   ['Waiting'] = {
      networkRequest = function (s, e) return 'Responded' end,
      timer          = function (s, e) return 'Delayed' end,
   },
   ['Responded'] = {
      timer = function (s, e) startRequest() ; return 'Waiting' end,
   },
   ['Delayed'] = {
      networkRequest = function (s, e) startRequest() ; return 'Waiting' end,
   },
}

---------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
-- Use this hook to create display objects, add them to view group, etc.
function scene:createScene(event)
        local group = self.view

        display.setDefault('background', 255)
        display.setDefault('textColor', 0)

        display.newText(group, 'Enter HyperUA URL (e.g. "http://server:port")',
                        16, display.statusBarHeight + 72, system.nativeFont, 24)
        display.newRect(group, 0, display.statusBarHeight + 112, display.contentWidth, 8):setFillColor(0)
        sessionList = widget.newTableView{
           topPadding = display.statusBarHeight + 128,
           hideBackground = true,
        }
        sessionList.isLocked = true
        group:insert(sessionList)
end


-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene(event)
        local group = self.view
        serverInput = native.newTextField(16, display.statusBarHeight + 16, 480, 48)
        serverInput.text = serverUrl
        serverInput.font = native.newFont(native.systemFontBold, 16)
        serverInput:addEventListener('userInput',
                                     function (event)
                                        if event.phase == 'submitted' then
                                           serverUrl = event.target.text
                                           updateScene{ name = 'userInput' }
                                        end
                                     end)
end


-- Called immediately after scene has moved onscreen:
-- Use this hook to start timers, load audio, start listeners, etc.
function scene:enterScene(event)
        local group = self.view
        updateScene{ name = 'enterScene' }
end


-- Called when scene is about to move offscreen:
-- Use this hook to stop timers, remove listeners, unload sounds, etc.
function scene:exitScene(event)
        local group = self.view
        updateScene{ name = 'exitScene' }
end


-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene(event)
        local group = self.view
        serverInput:removeSelf()
        serverInput = nil
end


-- Called prior to the removal of scene's 'view' (display group)
-- Use this hook to remove listeners, widgets, save state, etc.
function scene:destroyScene(event)
        local group = self.view
        sessionList:removeSelf()
        sessionList = nil
end


---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- 'createScene' event is dispatched if scene's view does not exist
scene:addEventListener('createScene', scene)

-- 'willEnterScene' event is dispatched before scene transition begins
scene:addEventListener('willEnterScene', scene)

-- 'enterScene' event is dispatched whenever scene transition has finished
scene:addEventListener('enterScene', scene)

-- 'exitScene' event is dispatched before next scene's transition begins
scene:addEventListener('exitScene', scene)

-- 'didExitScene' event is dispatched after scene has finished transitioning out
scene:addEventListener('didExitScene', scene)

-- 'destroyScene' event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener('destroyScene', scene)

---------------------------------------------------------------------------------

return scene
