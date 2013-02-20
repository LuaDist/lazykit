local Public = {}
xmlgen = Public

--[[
If you have ciostring installed, it is significantly faster than the
pure Lua iostring implementation.
]]

local USE_CIOSTRING = false
local newoutput

if USE_CIOSTRING then
  require "ciostring"
  newoutput = ciostring.newoutput
else
  require "iostring"
  newoutput = iostring.newoutput
end

require "ioxmlgen.lua"

local function writefile(file, t, opts)
  if type(file) == "string" then
    file = assert(io.open(file, "w"))
    ioxmlgen.write_xml(file, t, opts)
    assert(file:close())
  else
    ioxmlgen.write_xml(file, t, opts)
  end
end

Public.writefile = writefile

local function tostring(t, opts)
  opts = opts or {}
  f = newoutput()
  writefile(f, t, opts)
  f:close()
  return f:getstring()
end

Public.tostring = tostring

return Public
