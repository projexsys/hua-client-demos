-- looq.lua
-- Expects document input in the layout provided by htmlparser.lua

-- define module
local M = { }

function M.dumpTree(t, indent)
   indent = indent or 0
   local tab = string.rep('  ', indent)
   for k, v in pairs(t) do
      if type(v) == 'table' then
         if k ~= 'child' then
            print(tab .. k .. ':')
            M.dumpTree(v, indent+1)
         end
      else
         if v == nil then
            print(tab .. tostring(k) .. ': nil')
         else
            print(tab .. tostring(k) .. ': ' .. tostring(v))
         end
      end
   end
end


local function split(s, delim)
   local result = {}
   local o = 1
   local b, e = s:find(delim, o)
   while b and e do
      if o < b then
         table.insert(result, s:sub(o, b-1))
      else
         table.insert(result, '')
      end
      o = e + 1
      b, e = s:find(delim, o)
   end
   if o <= #s then
      table.insert(result, s:sub(o, #s))
   else
      table.insert(result, '')
   end
   return result
end


local function filter(xs, f)
   local rs = {}
   for _, x in ipairs(xs) do -- assumes "array"
      if f(x) then
         table.insert(rs, x)
      end
   end
   return rs
end


local function matchElement(element)
   local function match(document, result)
      local result = result or {}
      for _, doc in ipairs(document) do
         if type(doc) == 'table' and doc.type == 'tag' then
            if doc.tag == element then
               table.insert(result, doc)
            end
            if doc.child then
               match(doc.child, result)
            end
         end
      end
   end
   return match
end

local function nextToken(s)
   local tokens = {
      { '~=',                 'INCLUDES'    },
      { '|=',                 'DASHMATCH'   },
      { '\^=',                'PREFIXMATCH' },
      { '%$=',                'SUFFIXMATCH' },
      { '%*=',                'SUBSTRMATCH' },
      { '%s*%+',              'PLUS'        },
      { '%s*>',               'GREATER'     },
      { '%s*,',               'COMMA'       },
      { '%s*~',               'TILDE'       },
      { '%s+',                'WHITESPACE'  },
      { ':not%(',             'NOT'         },
      { '%-?[_%a][_%w%-]*%(', 'FUNCTION'    },
      { '%-?[_%a][_%w%-]*',   'IDENT'       },
      { '"[^\r\n\f\\"]*"',    'STRING'      },
      { "'[^\r\n\f\\']*'",    'STRING'      },
      { '"[^\r\n\f\\"]*',     'INVALID'     },
      { "'[^\r\n\f\\']*",     'INVALID'     },
      { '%d*%.%d+%%',         'PERCENTAGE'  },
      { '%d+%%',              'PERCENTAGE'  },
      { '%d*%.%d+%-?[_%a][_%w%-]*', 'DIMENSION' },
      { '%d+%-?[_%a][_%w%-]*',      'DIMENSION' },
      { '%d*%.%d+',           'NUMBER'      },
      { '%d+',                'NUMBER'      },
      { '#[_%w%-]+',          'HASH'        },
      { '@%-?[_%a][_%w%-]*',  'ATKEYWORD'   },
      { '.',                  'CHARACTER'   },
   }
   for _, t in ipairs(tokens) do
      local b, e = s:find('^' .. t[1])
      if b then
         if t[2] == 'CHARACTER' then
            return s:sub(1, e), s:sub(1, e), s:sub(e + 1)
         else
            return t[2], s:sub(1, e), s:sub(e + 1)
         end
      end
   end
   return nil, nil, s
end

local function contains(t, s)
   for _, v in ipairs(t) do
      if v == s then return true end
   end
   return false
end

local firstSelector   = {'IDENT', '*', 'HASH', '.', '[', ':', 'NOT'}
local firstTypeOrUni  = {'IDENT', '*'}
local firstSelSeqOpt  = {'HASH', '.', '[', ':', 'NOT'}
local firstAttrMatch  = {'PREFIXMATCH', 'SUFFIXMATCH', 'SUBSTRMATCH', 'INCLUDES', 'DASHMATCH', '='}
local firstCombinator = {'PLUS', 'GREATER', 'TILDE', 'WHITESPACE'}


function string.startsWith(s, prefix)
   return s:sub(1, prefix:len()) == prefix
end

function string.endsWith(s, suffix)
   return s:sub(-suffix:len()) == suffix
end

local attrOperation = {
   ['PREFIXMATCH'] = function (trees, ident, value)
      return filter(trees, function (x)
                       if x.attrs then
                          for _, attr in ipairs(x.attrs) do
                             if attr.name == ident then
                                if attr.value:startsWith(value) then
                                   return true
                                end
                             end
                          end
                       end
                       return false
                           end)
   end,

   ['SUFFIXMATCH'] = function (trees, ident, value)
      return filter(trees, function (x)
                       if x.attrs then
                          for _, attr in ipairs(x.attrs) do
                             if attr.name == ident then
                                if attr.value:endsWith(value) then
                                   return true
                                end
                             end
                          end
                       end
                       return false
                           end)
   end,

   ['SUBSTRMATCH'] = function (trees, ident, value)
      return filter(trees, function (x)
                       if x.attrs then
                          for _, attr in ipairs(x.attrs) do
                             if attr.name == ident then
                                if attr.value:find(value, 1, true) then
                                   return true
                                end
                             end
                          end
                       end
                       return false
                           end)
   end,

   ['DASHMATCH'] = function (trees, ident, value)
      return filter(trees, function (x)
                       if x.attrs then
                          for _, attr in ipairs(x.attrs) do
                             if attr.name == ident then
                                if attr.value == value or
                                   attr.value:startsWith(value) then
                                   return true
                                end
                             end
                          end
                       end
                       return false
                           end)
   end,

   ['INCLUDES'] = function (trees, ident, value)
      return filter(trees, function (x)
                       if x.attrs then
                          for _, attr in ipairs(x.attrs) do
                             if attr.name == ident then
                                local parts = split(attr.value, '%s+')
                                for _, v in ipairs(parts) do
                                   if v == value then
                                      return true
                                   end
                                end
                             end
                          end
                       end
                       return false
                           end)
   end,

   ['='] = function (trees, ident, value)
      return filter(trees, function (x)
                       if x.attrs then
                          for _, attr in ipairs(x.attrs) do
                             if attr.name == ident and attr.value == value then
                                return true
                             end
                          end
                       end
                       return false
                           end)
   end,

   ['EXISTENCE'] = function (trees, ident, value)
      return filter(trees, function (x)
                       if x.attrs then
                          for _, attr in ipairs(x.attrs) do
                             if attr.name == ident then
                                return true
                             end
                          end
                       end
                       return false
                           end)
   end,
}


local function getNextToken(data)
   data.token, data.value, data.input = nextToken(data.input)
   return data
end

local function skipWhitespace(data)
   while data.token == 'WHITESPACE' do
      getNextToken(data)
   end
end


local function parseAttrib(data)
   local node = {
      ident = 'attrib',
      child = {},
   }
   local tokens = {}
   if data.token == '[' then
      getNextToken(data)
   else
      print('FAILED A parseAttrib on: ' .. data.token, 'expected: [')
      return nil
   end
   skipWhitespace(data)
   if data.token == 'IDENT' then
      table.insert(tokens, data.value)
      --table.insert(node.child, data.value)
      getNextToken(data)
   else
      print('FAILED B parseAttrib on: ' .. data.token, 'expected: IDENT')
      return nil
   end
   skipWhitespace(data)
   if contains(firstAttrMatch, data.token) then
      table.insert(tokens, data.token)
      getNextToken(data)
      --skipWhitespace(data)    -- needed here?
      if data.token == 'IDENT' then
         table.insert(tokens, data.value)
      elseif data.token == 'STRING' then
         table.insert(tokens, data.value:sub(2, -2))
      else
         print('FAILED C parseAttrib on: ' .. data.token)
         return nil
      end
      getNextToken(data)
      skipWhitespace(data)
   else
      -- existence operation
      table.insert(tokens, 'EXISTENCE')
      table.insert(tokens, '')
   end
   if data.token == ']' then
      getNextToken(data)
   else
      print('FAILED D parseAttrib on: ' .. data.token)
      return nil
   end
   node.query = function (trees)
      if #tokens == 3 then
         local ident = tokens[1]
         local oper  = tokens[2]
         local value = tokens[3]
         return attrOperation[oper](trees, ident, value)
      else
         print('QUERY FAILED: expected #tokens to be 3 or 3, but was ' .. #tokens)
         return nil
      end
   end
   return node
end

local function parseElementName(data)
   if data.token == 'IDENT' then
      local node = {
         ident = 'elementName',
         value = data.value,
      }
      node.query = function (trees)
         return filter(trees, function (x)
                          return x.type == 'tag' and x.tag == node.value
                              end)
      end

      getNextToken(data)
      return node
   else
      print('FAILED parseElementName on: ' .. data.token)
      return nil
   end
end

local function parseTypeSelector(data)
   if data.token == 'IDENT' then
      local x = parseElementName(data)
      if not x then return nil end
      return {
         ident = 'typeSelector',
         child = {x},
         query = function (trees)
            return x.query(trees)
         end
             }
   else
      print('FAILED parseTypeSelector on: ' .. data.token)
      return nil
   end
end

local function parseHash(data)
   if data.token ~= 'HASH' then
      print('FAILED parseHash on:')
      return nil
   end
   local node = {
      ident = 'hash',
      value = data.value:sub(2),  -- remove # prefix
   }
   getNextToken(data)
   node.query = function (trees)
      -- #abc is same as *[id=abc]
      return attrOperation['='](trees, 'id', node.value)
   end
   return node
end

local function parseClass(data)
   if data.token ~= '.' then
      print('FAILED parseClass on: ' .. data.token)
      return nil
   end
   getNextToken(data)
   if data.token ~= 'IDENT' then
      print('FAILED parseClass on: ' .. data.token)
      return nil
   end
   local node = {
      ident = 'class',
      value = data.value
   }
   getNextToken(data)
   node.query = function (trees)
      -- xyz.abc is the same as xyz[class~=abc]
      return attrOperation['INCLUDES'](trees, 'class', node.value)
   end
   return node
end

local function parseSelectorSequenceOpt(data)
   local node = {
      ident = 'selectorSequenceOpt',
      child = {}
   }
   while data.token do
      if data.token == 'HASH' then
         local x = parseHash(data)
         if not x then return nil end
         table.insert(node.child, x)
      elseif data.token == '.' then
         local x = parseClass(data)
         if not x then return nil end
         table.insert(node.child, x)
      elseif data.token == '[' then
         local x = parseAttrib(data)
         if not x then return nil end
         table.insert(node.child, x)
      elseif data.token == ':' then
         local x = parsePseudo(data)
         if not x then return nil end
         table.insert(node.child, x)
      elseif data.token == 'NOT' then
         local x = parseNegation(data)
         if not x then return nil end
         table.insert(node.child, x)
      else
         break  -- optional: not an error
      end
   end
   node.query = function (trees)
      local ts = trees
      for _, v in ipairs(node.child) do
         ts = v.query(ts)
      end
      return ts
   end
   return node
end

local function parseSelectorSequence2(data)
   local node = {
      ident = 'selectorSequence2',
      child = { },
   }
   local a, b
   if data.token == 'HASH' then
      a = parseHash(data)
   elseif data.token == '.' then
      a = parseClass(data)
   elseif data.token == '[' then
      a = parseAttrib(data)
   elseif data.token == ':' then
      a = parsePseudo(data)
   elseif data.token == 'NOT' then
      a = parseNegation(data)
   else
      print('FAILED on token: ' .. data.token)
      return nil
   end
   if not a then return nil end
   b = parseSelectorSequenceOpt(data)
   if not b then return nil end
   table.insert(node.child, a)
   table.insert(node.child, b)
   node.query = function (trees)
      return b.query(a.query(trees))
   end
   return node
end

local function parseSelectorSequence1(data)
   if data.token == 'IDENT' then
      local ts = parseTypeSelector(data)
      if not ts then return nil end
      local sso = parseSelectorSequenceOpt(data)
      if not sso then return nil end
      return {
         ident = 'selectorSequence1',
         child = {ts, sso},
         query = function (trees)
            return ts.query(sso.query(trees))
         end
             }
   elseif data.token == '*' then
      getNextToken(data)
      --local u = parseUniversal(data)
      --if not u then return nil end
      local sso = parseSelectorSequenceOpt(data)
      if not sso then return nil end
      return { ident = 'selectorSequence1',
               child = {sso},
               query = function (trees)
                  return sso.query(trees)
               end
             }
   else
      print('FAILED parseSelectorSequence1 on: ' .. data.token)
      return nil
   end
end

local function parseSelectorSequence(data)
   local node = {
      ident = 'selectorSequence',
      child = { },
   }
   if contains(firstTypeOrUni, data.token) then
      local ss1 = parseSelectorSequence1(data)
      if not ss1 then return nil end
      table.insert(node.child, ss1)
      node.query = function (trees)
         return ss1.query(trees)
      end
   elseif contains(firstSelSeqOpt, data.token) then
      local ss2 = parseSelectorSequence2(data)
      if not ss2 then return nil end
      table.insert(node.child, ss2)
      node.query = function (trees)
         return ss2.query(trees)
      end
   else
      print('FAILED parseSelectorSequence on: ' .. data.token)
      return nil
   end
   return node
end

local function parseSelectorOpt(data)
   local node = {
      ident = 'selectorOpt',
      child = { },
   }
   if data.token and contains(firstCombinator, data.token) then
      local x = data.token
      getNextToken(data)
      skipWhitespace(data)
      local y = parseSelectorSequence(data)
      if not y then return nil end
      local z = parseSelectorOpt(data)

      node.query = function (trees)
         if x == 'PLUS' or x == 'TILDE' then
            print(x .. ' combinator not yet supported')
            return nil
         elseif x == 'GREATER' then
            print(x .. ' combinator not yet supported')
            return nil
         elseif x == 'WHITESPACE' then
            print(x .. ' combinator not yet supported')
            return nil
         else
            print('QUERY FAILED: expected a combinator; found:', x)
            return nil
         end
      end
   else
      node.query = function (trees)
         return trees
      end
   end
   return node
end

local function parseSelector(data)
   if contains(firstSelector, data.token) then
      local ss = parseSelectorSequence(data)
      if not ss then return nil end
      local so = parseSelectorOpt(data)
      if not so then return nil end
      return {
         ident = 'selector',
         child = {ss, so},
         query = function (trees)
            return so.query(ss.query(trees))
         end
             }
   else
      print('FAILED parseSelector on: ' .. token)
      return nil
   end
end

local function parseSelectorsGroupOpt(data)
   local node = {
      ident = 'selectorsGroupOpt',
      child = {},
      query = function (trees)
         return trees
      end
   }
   -- TODO
   return node
end

local function parseSelectorsGroup(data)
   if not data.token then
      print('FAILED parseSelectorsGroup, nothing to parse')
      return nil
   end
   if contains(firstSelector, data.token) then
      local s = parseSelector(data)
      if not s then return nil end
      local sgo = parseSelectorsGroupOpt(data)
      if not sgo then return nil end
      return {
         ident = 'selectorsGroup',
         child = {s, sgo},
         query = function (trees)
            return sgo.query(s.query(trees))
         end
             }
   else
      print('FAILED parseSelectorsGroup on: ' .. data.token)
      return nil
   end
end


local function parseCSSSelector(s)
   local data = {input = s}
   return parseSelectorsGroup( getNextToken(data) )
end

local function allNodes(doc, all)
   table.insert(all, doc)
   if doc.child then
      for _, c in ipairs(doc.child) do
         allNodes(c, all)
      end
   end
end


function M.all(document, selector)
   local parser = parseCSSSelector(selector)
   if not parser then
      print('parse failed!')
      return nil
   else
      local all = {}
      for _, d in ipairs(document) do
         allNodes(d, all)
      end
      return parser.query(all)
   end
end

function M.first(document, selector)
   return M.all(document, selector)[1]
end

return M
