-- util.lua

-- define module
local M = { }

-- Capitalizes a string.
function M.capitalize(s)
   return s:gsub("^%l", string.upper)
end

-- Remove leading/trailing whitespace.
function M.trim(s)
   return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- This is a standard map over a collection.
-- It is assumed the collection is an array-like table.
function M.map(coll, fn)
   local res = { }
   for _, val in ipairs(coll) do
      table.insert(res, fn(val))
   end
   return res
end

-- This encodes a table of key/value parameters in the typical
-- key1=val1&key2=... format for URLs and HTTP request bodies.
-- It also works with a string, percent-escaping as needed.
function M.urlEncode(params)
   if type(params) == 'string' then
      local str = params
      str = string.gsub(str, "\n", "\r\n")
      str = string.gsub(str, "([^%w ])",
                        function (c) return string.format("%%%02X", string.byte(c)) end)
      str = string.gsub(str, " ", "+")
      return str
   elseif type(params) == 'table' then
      local eqs = { }
      for k, v in pairs(params) do
         table.insert(eqs, M.urlEncode(k) .. '=' .. M.urlEncode(v))
      end
      return table.concat(eqs, '&')
   else
      error('Invalid argument: must be a string or table')
   end
end

return M
