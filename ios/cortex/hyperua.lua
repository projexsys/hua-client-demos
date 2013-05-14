-- hyperua.lua

-- imports
local htmlparser = require('htmlparser')
local looq = require('looq')
local util = require('util')


-- define module
local M = { }


local function extractNodeValue(response, selector)
   selector = selector or '.opcua-attr-node-value'
   local doc = htmlparser.new(response):parse()
   local node = looq.first(doc, selector)
   return util.trim(node.child[1])
end

local function getNodeUrl(nodeId)
   return M.sessionUrl .. '/address-space/' .. nodeId
end

function M.setSessionUrl(url)
   M.sessionUrl = url
end

function M.status(onComplete)
   assert(M.sessionUrl, 'HyperUA session url not set.')
   assert(onComplete, 'HyperUA status check requires a completion callback.')

   return network.request(M.sessionUrl, 'GET',
                          function (event)
                             if event.isError then
                                onComplete('network error')
                             elseif event.status ~= 200 then
                                onComplete('HTTP error: ' .. event.status)
                             else
                                local sel = '.opcua-attr-application-session-status'
                                local val = extractNodeValue(event.response, sel)
                                onComplete(util.capitalize(val))
                             end
                          end,
                          { timeout = 5 })
end

function M.read(nodeId, attributeId, onComplete)
   assert(M.sessionUrl, 'HyperUA session url not set.')
   assert(onComplete, 'HyperUA read service requires a completion callback.')

   local params = {
      ['form'] = 'read',
      ['do'] = 'submitForm',
      ['node-id'] = nodeId,
      ['attribute-id'] = attributeId,
      ['timestamps-to-return'] = 'neither',
   }
   local url = getNodeUrl(nodeId) .. '?' .. util.urlEncode(params)

   return network.request(url, 'GET',
                          function (event)
                             if event.isError then
                                onComplete('network error')
                             elseif event.status ~= 200 then
                                onComplete('HTTP error: ' .. event.status)
                             else
                                onComplete(extractNodeValue(event.response))
                             end
                          end,
                          { timeout = 5 })
end

function M.write(nodeId, attributeId, value, onComplete)
   assert(M.sessionUrl, 'HyperUA session url not set.')

   local headers = {
      ['Content-Type'] = 'application/x-www-form-urlencoded',
      ['Accept-Language'] = 'en-US',
   }
   local params = {
      ['form'] = 'write',
      ['do'] = 'submitForm',
      ['node-id'] = nodeId,
      ['attribute-id'] = attributeId,
      ['value'] = value,
   }
   local body = util.urlEncode(params)
   local url = getNodeUrl(nodeId)
   onComplete = onComplete or function (e) end
   network.request(url, 'POST', onComplete, { headers = headers, body = body })
end

function M.sessions(serverUrl, onComplete)
   local url = serverUrl .. '/api/application-sessions'
   return network.request(url, 'GET',
                          function (event)
                             if event.isError then
                                onComplete('Network error:', url)
                             elseif event.status ~= 200 then
                                onComplete('HTTP error: ' .. event.status, url)
                             else
                                local doc = htmlparser.new(event.response):parse()
                                local sessions = looq.all(doc, 'a[rel~="http://projexsys.com/hyperua/rel/application-session"][rel~="http://projexsys.com/hyperua/rel/item"]')
                                onComplete(sessions)
                             end
                          end)
end

return M
