--[[ 
doc = {name="myroot", "text&more><", {name="empty", attr={remark="don't"}}}

st = iostring.newoutput()
write_xml(st, doc)
print(st:getstring())
]]

require "xmliter"

local Public = {}
ioxmlgen = Public

-- Convert an XML table to a string:

-- note that these two functions are responsible for about a quarter of
-- CPU time for file and ciostring runs...

local function xml_quote_pcdata(s)
  s = string.gsub(s, "&", "&amp;")
  s = string.gsub(s, "<", "&lt;")
  s = string.gsub(s, ">", "&gt;")
  return s
end

-- local function xml_quote_pcdata(s) return s end

local function xml_quote_attr(s)
  s = xml_quote_pcdata(s)
  s = string.gsub(s, "'", "&apos;")
  return s
end

-- local function xml_quote_attr(s) return s end

local function write_xml_attributes(file, t)
  for i,v in xattrpairs(t) do
    if type(i) == "string" then
      file:write(" "..i.."='"..xml_quote_attr(v).."'")
    elseif type(i) == "number" then
      -- skip
    else
      error("non-string, non-number attribute key found")
    end
  end
end

local write_xml
function write_xml(file, t, opts)
  opts = opts or {}
  if type(t) == "string" then
    file:write(xml_quote_pcdata(t))
  elseif type(t) == "table" then
    file:write("<"..t.name)
    if t.attr then
      write_xml_attributes(file, t)
    end
    if not t[1] and not opts.no_empty then
      file:write("/>")
    else
      file:write(">")
      for i,v in xpairs(t) do
        write_xml(file, v, opts)
      end
      file:write("</"..t.name..">")
    end
  else
    error("unknown xml content")
  end
end


Public.write_xml = write_xml

return Public
