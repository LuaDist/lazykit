require "xmliter"
-- require "util"

--[[ Work in progress.  Quick summary:

xstring(node) => immediate string contents of node.  returns nil,error on mixed content
xtext(node) => recursive string contents of node

Views

v = xmlview.string(node)
v.date => finds a child element named date and returns xstring(date)
]]


--[[

<logentry>
  <type>INFO</info>
  <time>12:50</time>
  <receivedfrom>upstream1</receivedfrom>
  <receivedfrom>upstream2</receivedfrom>
  <body>This is a <b>test message</b></body>
  <empty/>
</logentry>

tree=lxptree.parsestring(s)
sv = xmlview.string(tree)
print(sv.type)          -- "INFO"
print(sv.time)          -- "12:50"
print(sv.empty)         -- ""
print(sv.receivedfrom)  -- error "contains duplicate content"
print(sv.body)          -- error "contains mixed content"
]]  

local Public = {}
xmlview = Public

local tree_key = {"tree_key"}
local cachecomplete_key = {"cachecomplete_key"}
local populate_key = {"populate_key"}
local error_key = {"error_key"}

--local function text(tree) return tree[1] end

function xtext(tree)
  if type(tree) == "string" then return tree end
  -- fast-path some common cases
  local first = tree[1]
  if not first then return "" end
  if type(first) == "string" and not tree[2] then
    return first
  end
  local s = ""
  for i, lz in xpairs(tree) do
    s = s..xtext(lz)
  end
  return s
end

function xstring(tree)
  if type(tree) == "string" then return tree end
  -- fast-path some common cases
  local first = tree[1]
  if not first then return "" end
  if type(first) == "string" and not tree[2] then
    return first
  end
  local s = ""
  for i, lz in xpairs(tree) do
    if type(lz) == "string" then
      s = s..lz
    else
      return nil, "contains mixed content"
    end
  end
  return s
end

local viewmetatable = {}

function viewmetatable.__index(t, k)
  if not rawget(t, cachecomplete_key) then
    local populate = t[populate_key]
    populate(t)
  end
  local error_table = rawget(t, error_key)
  if error_table and error_table[k] then
    local tablename = t[tree_key].name
    error("in element "..tablename.." xmlview index "..k..": "..error_table[k])
  end
  return rawget(t, k)
end

local
function ensure_table(t)
  if type(t) ~= "table" then
    error("view must be on a table")
  end
end

local
function populatestringcache(t)
  local error_table = {}
  t[error_key] = error_table
  local root = t[tree_key]
  for i, element, name in xnpairs(root) do
    if rawget(t, name) then
      error_table[name] = "contains duplicate content"
    else
      local s, msg = xstring(element)
      if s then
        t[name] = xstring(element)
      else
        error_table[name] = msg
      end
    end
  end
  for k,v in pairs(error_table) do
    t[k] = nil
  end
  t[cachecomplete_key] = true
end

local 
function string(x)
  ensure_table(x)
  local t = {[tree_key]=x, [populate_key]=populatestringcache}
  setmetatable(t, viewmetatable)
  return t
end

Public.string = string

local
function populatetextcache(t)
  local error_table = {}
  t[error_key] = error_table
  local root = t[tree_key]
  for i, element, name in xnpairs(root) do
    if rawget(t, name) then
      error_table[name] = "contains duplicate content"
    else
      t[name] = xtext(element)
    end
  end
  for k,v in pairs(error_table) do
    t[k] = nil
  end
  t[cachecomplete_key] = true
end

local 
function text(x)
  ensure_table(x)
  local t = {[tree_key]=x, [populate_key]=populatetextcache}
  setmetatable(t, viewmetatable)
  return t
end

Public.text = text

local
function populatenodecache(t)
  local error_table = {}
  t[error_key] = error_table
  local root = t[tree_key]
  for i, element, name in xnpairs(root) do
    if rawget(t, name) then
      error_table[name] = "contains duplicate content"
    else
      t[name] = element
    end
  end
  for k,v in pairs(error_table) do
    t[k] = nil
  end
  t[cachecomplete_key] = true
end

local
function element(x)
  ensure_table(x)
  local t = {[tree_key]=x, [populate_key]=populatenodecache}
  setmetatable(t, viewmetatable)
  return t
end

Public.element = element

local
function populatenodescache(t)
  local root = t[tree_key]
  for i, element, name in xnpairs(root) do
    local existing = rawget(t, name)
    if not existing then
      t[name] = {n=0}
    end
    table.insert(t[name], element)
  end
  t[cachecomplete_key] = true
end

local
function elements(x)
  ensure_table(x)
  local t = {[node_key]=x, [populate_key]=populatenodescache}
  setmetatable(t, viewmetatable)
  return t
end

Public.elements = elements
