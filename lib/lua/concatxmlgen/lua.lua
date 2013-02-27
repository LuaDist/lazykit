require "xmliter"

local Public = {}
concatxmlgen = Public

local function xml_quote(s)
  s = string.gsub(s, "&", "&amp;")
  s = string.gsub(s, "<", "&lt;")
  s = string.gsub(s, ">", "&gt;")
  return s
end

-- local function xml_quote(s) return s end

local function xml_quote_attr(s)
  s = xml_quote(s)
  s = string.gsub(s, "'", "&apos;")
  return s
end

-- local function xml_quote_attr(s) return s end

local function return_xml_attributes(t)
  local s = ""
  for i,v in xattrpairs(t) do
    if type(i) == "string" then
      s = s.." "..i.."='"..xml_quote_attr(v).."'"
    elseif type(i) == "number" then
      -- skip
    else
      error("non-string, non-number attribute key found")
    end
  end
  return s
end

local return_xml
function return_xml(t, opts)
  opts = opts or {}
  if type(t) == "string" then
    return xml_quote(t)
  elseif type(t) == "table" then
    local s = "<"..t.name
    if t.attr then s=s..return_xml_attributes(t) end
    if not t[1] and not opts.no_empty then
      s = s.."/>"
    else
      s = s..">"
      for i,v in xpairs(t) do
        s = s..return_xml(v)
      end
      s = s.."</"..t.name..">"
    end
    return s
  else
    error("unknown xml content")
  end
end

Public.return_xml = return_xml

return Public
