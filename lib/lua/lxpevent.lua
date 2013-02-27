require "lxp"

local Public = {}
lxpevent = Public

local tinsert=table.insert
local tremove=table.remove

local methods = {}
local metatable = {__index=methods}

local START = "start"
local END = "end"
local CHARDATA = "chardata"
local EOF = "eof"
Public.START = START
Public.END = END
Public.CHARDATA = CHARDATA
Public.EOF = EOF

local
function parsebase()
  local p = {n=0, next=1}
  
  local callbacks = {}
  function callbacks.StartElement(parser, elementName, attributes)
    local evt = {START, elementName, attributes}
    tinsert(p, evt)
  end
  function callbacks.EndElement(parser, elementName)
    local evt = {END, elementName}
    tinsert(p, evt)
  end
  function callbacks.CharacterData(parser, string)
    local evt = {CHARDATA, string}
    tinsert(p, evt)
  end

  p.callbacks = callbacks
  local parser = lxp.new(callbacks)

  function p:parsemore(s)
    -- print("parsemore", s)
    local result, msg, line, col, pos = parser:parse(s)
    if not result then
      error("expat parse error "..msg.." at line "..line.." column "..col)
    end
    if not s then
      parser:close()
      tinsert(p, {EOF})
      p.nomore = true
      if p.on_eof then p:on_eof() end
    end
  end
  
  setmetatable(p, metatable)
  return p
end

-- surprisingly, larger sizes may not help much
local BUFSIZE = 4096

function file_getmore(self)
  local s = self.file:read(BUFSIZE)
  self:parsemore(s)
end

function string_getmore(self)
  local offset = self.string_offset
  local s = string.sub(self.string, offset, offset+BUFSIZE)
  self.string_offset = offset+BUFSIZE+1
  if s == "" then s = nil end
  self:parsemore(s)
end

function Public.parsefile(f)
  local base = parsebase()
  if type(f) == "string" then
    f = assert(io.open(f))
    function base:on_eof() f:close() end
  end
  base.file = f
  base.getmore = file_getmore
  return base
end

function Public.parsestring(s)
  local base = parsebase()
  base.string = s
  base.getmore = string_getmore
  base.string_offset = 1
  return base
end

function methods:getnext()
  local pos = self.next
  if pos > self.n then
    self:getmore()
    return self:getnext()
  end
  local evt = self[pos]
  self[pos] = nil
  self.next = pos + 1
  return unpack(evt)
end

function methods:consumenext()
  local pos = self.next
  if pos > self.n then
    self:getmore()
    return self:consumenext()
  end
  self[pos] = nil
  self.next = pos + 1
end

function methods:peeknext()
  local pos = self.next
  if pos > self.n then
    self:getmore()
    return self:peeknext()
  end
  local evt = self[pos]
  return unpack(evt)
end
