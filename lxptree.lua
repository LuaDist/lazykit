require "lxp"

local Public = {}
lxptree = Public

local tinsert=table.insert
local tremove=table.remove

local function top(l)
   return l[table.getn(l)]
end

local 
function nukenumeric(t)
   for i=1,table.getn(t) do
      t[i] = nil
   end
end

local
function makeParser()
   local stack = {{}, n=1}
   local self = {}
   local callbacks = {}

   function callbacks.StartElement(parser, elementName, attributes)
      local t = {name=elementName}
      if attributes and attributes[1] then 
         nukenumeric(attributes)
         t.attr=attributes 
      end
      tinsert(top(stack), t)
      tinsert(stack, t)
   end
   
   function callbacks.EndElement(parser, elementName)
      tremove(stack, t)
   end

   function callbacks.CharacterData(parser, string)
      tinsert(top(stack), string)
   end

   local parser = lxp.new(callbacks)
   function self:parse(s)
      local result, msg, line, col, pos = parser:parse(s)
      if result then
         result, msg, line, col, pos = parser:parse()
      end
      if not result then
         error("expat parse error "..msg.." at line "..line.." column "..col)
      end
      parser:close()
      return stack[1][1]
   end
   
   return self
end

local
function parsestring(s)
   local p = makeParser()
   return p:parse(s)
end

Public.parsestring = parsestring

local 
function wholeFile(filename)
   local f = assert(io.open(filename))
   local s = f:read("*a")
   assert(f:close())
   return s
end

local
function parsefile(f)
  local s
  if type(f) == "string" then
    f = assert(io.open(f))
    s = f:read("*a")
    assert(f:close())
  else
    s = f:read("*a")
  end
  return parsestring(s)
end

Public.parsefile = parsefile

return Public
