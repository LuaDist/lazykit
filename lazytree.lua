require "lxpevent"

--function makelazy(evts)
  
local tinsert=table.insert
local tremove=table.remove

local Public = {}
lazytree=Public

local
function parseevents(evts)
  local treestack = {n=0}
  local depth = 0
  
  local makelazy
  local getnextlazy
  local finishlazy
  
  -- If at the end of a tree, return false
  -- If not, returns true and any child node found
  function getnextlazy(lz)
    local evt, data, attr = evts:peeknext()
    local offset = lz._read_so_far + 1
      --[[']]
    if evt == "chardata" then
      lz[offset] = data
      lz._read_so_far = offset
      evts:consumenext()
      evt, data = evts:peeknext()
      while evt == "chardata" do
        evts:consumenext()
        lz[offset] = lz[offset]..data
        evt, data = evts:peeknext()
      end
      return true, nil
    elseif evt == "start" then
      local childtree = makelazy(evts)
      lz[offset] = childtree
      lz._read_so_far = offset
      return true, childtree
    elseif evt == "end" then
      lz.n = lz._read_so_far
      lz._read_so_far = nil
      treestack[depth] = nil
      depth = depth - 1
      evts:getnext()
      return false
    else
      error("unknown event "..evt)
    end
  end
  
  function finishlazy(lz, limit)
    -- if rawget(lz, "n") then print("busted") return end
    
    -- you don't have an XML file this big, do you?
    -- actually you'd run out of lua_number precision before you got there
    limit = limit or 1e99
    
    -- If "n" is present, we're already read everything there is
    if rawget(lz, "n") then return end
    
    if lz._read_so_far >= limit then
      return
    end
    
    if depth > lz._depth then
      -- we're off in the children of a previous tree
      -- pop up back to this level
      -- print("recursing ", lz._depth)
      finishlazy(treestack[lz._depth+1])
    end
    while lz._read_so_far < limit and not rawget(lz, "n") do
      local still_going, child = getnextlazy(lz, evts)
      if not still_going then break end
      if child then
        if lz._read_so_far == limit then
          -- do nothing.  we already have a lazy tree, which is good enough
        else 
          finishlazy(child)
        end
      end
    end
  end
  
  local get_child
  function get_child(lz, i)
    if rawget(lz, "n") then
      return rawget(lz, i)
    elseif i <= lz._read_so_far then
      -- print("here")
      return l[i]
    end
    -- print("gln", lz, i)
    finishlazy(lz, i)
    return rawget(lz, i)
  end
  
  local lazy_indexmethod
  function lazy_indexmethod(t, k)
    if k == "n" then
      -- sigh, we have to finish to get this
      finishlazy(t)
      return rawget(t, "n")
    elseif k == "attr" then
      -- we're lazily creating empty attr tables...
      -- this is an attempt to keep most trees from having a unique 
      -- empty attribute table.
      local attr = {}
      rawset(t, "attr", attr)
      return attr
    elseif type(k) == "number" then
      return get_child(t, k)
    end
    return nil
  end
  
  local metatable = {}
  metatable.__index = lazy_indexmethod
  
  -- forward declared local makelazy
  function makelazy()
    local evt, data, attr = evts:getnext()
    if evt ~= "start" then
      error("expecting start tree")
    end
    local lazytree = {}
    lazytree.name = data
    if attr and attr[1] then
      lazytree.attr = attr
    end
    lazytree._read_so_far = 0
    depth = depth + 1
    lazytree._depth = depth
    treestack[depth] = lazytree
    setmetatable(lazytree, metatable)
    return lazytree
  end

  return makelazy(evts)
end

Public.parseevents = parseevents

local 
function parsefile(f)
  local evts = lxpevent.parsefile(f)
  return parseevents(evts)
end

Public.parsefile = parsefile

local 
function parsestring(s)
  local evts = lxpevent.parsestring(s)
  return parseevents(evts)
end

Public.parsestring = parsestring

local
function lazyprint(lz, depth, header)
  depth = depth or 0
  local prefix = header or string.rep(" ", depth)
  local finished = ""
  if rawget(lz, "n") then finished = " DONE" end
  local read = ""
  if lz._read_so_far then read = " read:"..lz._read_so_far end
  print(prefix.."<"..lz.name..finished..read)
  local consumed = lz._consumed
  local limit=1e99
  if rawget(lz, "n") then
    limit = rawget(lz, "n")
  elseif lz._read_so_far then
    limit = lz._read_so_far
  end
  for i = 1,limit do
    local elt = rawget(lz, i)
    local numpre = "  "..i..":"
    if not elt then
      if not consumed then break end
      print(prefix..numpre.."consumed")
    elseif type(elt) == "string" then
      local s = string.gsub(elt, "\\", "\\\\")
      s = string.gsub(elt, "\n", "\\n")
      print(prefix..numpre.."  str: |"..s.."|")
    else
      lazyprint(elt, depth + 2, prefix..numpre)
    end
  end
end

Public.print = lazyprint

local
function load(lz)
  local n = lz.n
end

Public.load = load

local
function consume_completed(lz, n)
  for i=1,n do
    local elt = lz[i]
    lz[i] = nil
    if type(elt) == "table" then
      consume(lz)
    end
  end
end

--[[

Here is the situation where consume() is necessary:

<doc>
  <title>My Title</title>
  <bodytext>[a zillion bytes of mixed content]</bodytext>
</doc>

xmliter.switch_c(doc, {
  title=function (title) print(xtext(title)) end
}

We don't want the enormous bodytext tree to be fully loaded into
memory just to be ignored.  So we walk that tree, carefully loading
and then ignoring its content.
'
]]

local
function consume(lz)
  if type(lz) ~= table then return end
  lz._consumed = true
  local start = rawget(lz, "_read_so_far")
  if not start then return end
  -- This isn't necessary; the garbage collector will do this for us
  -- if rawget(lz, "n") then return consume_completed(lz, n) end

  -- We start one element after current position.  Potentially, somebody 
  -- could have saved a reference to something in our current tree.

  for i=start+1,1e99 do
    local elt = lz[i]
    if not elt then break end
    lz[i] = nil
    if type(elt) == "table" then
      consume(elt)
    end
  end
end

-- local function consume(lz)
-- end

Public.consume = consume

return Public


