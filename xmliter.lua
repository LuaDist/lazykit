
-- This is used to pick up the lazytree.consume operator.
-- require "lazytree"

local Public = {}
xmliter = Public


--[[

xpairs(tree)
xpairs_c(tree)
xnpairs(tree)
xnpairs_c(tree)

Iterate over an XML tree.

xpairs(tree) returns an iterator over tree that returns each index and
its child.  Example:

parent = lazytree.parsestring("<p>a<z>cdef</z>b</p>")

for i,x in xpairs(parent) do
  if type(x) == "string" then
    print("string:", x)
  else
    print("tag:", x.name)
  end
end

prints:

string:	a
tag:	z
string:	b

Note that it does not descend into child elements (as "cdef" was not
printed).

xnpairs(tree) ignores character data elements, and returns an index,
tree, and element name (which may be ignored):

for i,x in xnpairs(parent) do
  print("tag:", x.name)
end

for i,x,name in xnpairs(parent) do
  print("tag:", name)
end

either of which prints:

tag:	z

Consuming iterators:

xpairs_c(tree) and xnpairs_c(tree) also iterate over the children of
tree, but they consume the children of tree as they process it.  The
following two fragments have similar semantics:

for i,x in xpairs(parent) do
  parent[i] = nil
  do_something_with(x)
end

for i,x in xpairs_c(parent) do
  do_something_with(x)
end

Using a consuming iterator means that you do not care about accessing
previously processed trees through parent.  However, you can still
save them for later use:

for i,x,name in xnpairs(parent) do
  if x.name == "xref" then
    table.insert(references, x)
  end
end

The primary reason to use consuming iterators is to reduce memory
usage.  When using conventional XML trees, this may help a little if
you are building up another data structure while tearing down the XML
tree; parts of the tree you have already processed are eligible for
garbage collection, saving space for your new structure.

However, when using lazytree XML trees, memory usage can be vastly
smaller.  Consider processing a large log file:

<log>
  <entry>[....]</entry>
  <entry>[....]</entry>
  [...millions of elements later...]
  <entry>[....]</entry>
</log>

With a conventional XML tree, processing this requires space linearly
proportional to the size of all the <entry> elements.  With normal
iterators and a lazy tree, this requires space linearly proportional
to all previously processed <entry> elements (as future elements are
only read on demand.)  With consuming iterators and a lazy tree,
processing only requires space proportional to the size of a single
<entry> element, as previously processed <entry>s have been forgotten.

A secondary benefit to consuming iterators is that they may reduce CPU
usage a small amount.  The Lua 5.0 garbage collector does not have to
work as hard during collections when less live data is present.  (??? 
reread the GC algorithm to make sure this is true, have timing numbers
though.)

What is really going on here is that iterators provide an event-based
interface to tables.  Consuming iterators provide many of the same
benefits as pure event-based XML parsers, while allowing you to
fluidly switch back to a tree-based API when that makes sense.

Usage hints:

It is always safe to replace a consuming iterator with a non-consuming
iterator; the only consequence may be memory exhaustion when
processing huge documents.

It makes the most sense to use a consuming iterator only as the last
step in processing a tree.  Because of how lazy XML trees work, it is
not an error to touch child nodes before calling a consuming iterator.

When recursively processing elements, you should only call a consuming
iterator if you know your caller no longer cares about its contents.
A rule of thumb is to only call a consuming iterator inside another
consuming iterator.
]]


local function getn(tree)
   return tree.n or table.getn(tree.n)
end

Public.getn = getn

local
function xnext(lz, i)
  i = i + 1
  local elt = lz[i]
  if not elt then return nil end
  return i, elt
end

function xpairs(lz)
  if type(lz) ~= "table" then
    error("argument to xpairs must be a table")
  end
  return xnext, lz, 0
end

local
function xnext_c(lz, i)
  i = i + 1
  local elt = lz[i]
  lz[i] = nil
  if not elt then return nil end
  return i, elt
end

function xpairs_c(lz)
  if type(lz) ~= "table" then
    error("argument to xpairs_c must be a table")
  end
  lz._consumed = true
  return xnext_c, lz, 0
end


local
function xnnext(lz, i)
  i = i + 1
  local elt = lz[i]
  while elt and type(elt) ~= "table" do
    i = i + 1
    elt = lz[i]
  end
  if not elt then return nil end
  return i, elt, elt.name
end

function xnpairs(lz)
  if type(lz) ~= "table" then
    error("argument to xnpairs must be a table")
  end
  return xnnext, lz, 0
end

local
function xnnext_c(lz, i)
  i = i + 1
  local elt = lz[i]
  while elt and type(elt) ~= "table" do
    lz[i] = nil
    i = i + 1
    elt = lz[i]
  end
  if not elt then return nil end
  lz[i] = nil
  return i, elt, elt.name
end


function xnpairs_c(lz)
  if type(lz) ~= "table" then
    error("argument to xnpairs_c must be a table")
  end
  lz._consumed = true
  return xnnext_c, lz, 0
end


local
function xattrnext(attr, k)
  local nextk, nextv = next(attr, k)
  if not nextk then return nil end
  if type(nextk) ~= "string" then
    return xattrnext(attr, nextk)
  end
  return nextk, nextv
end

function xattrpairs(lz)
  if type(lz) ~= "table" then
    error("argument to xattrpairs must be a table")
  end
  local attr = lz.attr or {}
  return xattrnext, attr, nil
end

local
function switch_internal(lz, ftable, parent, iterator, opts, consume)
  if ftable[0] then
    local escape, val = ftable[0](lz, parent)
    if escape then
      return escape, val
    end
  end
  for i, elt in iterator(lz) do
    if type(elt) == "string" then
      local strhandler = ftable[""]
      if strhandler then
        local escape, val = strhandler(elt, lz)
        if escape then
          return escape, val
        end
      elseif opts.no_chardata then
        error("found unexpected character data in "..elt.name)
      end
    else
      local f = ftable[elt.name] or ftable[true]
      if f then 
        local escape, val
        if type(f) == "table" then
          escape, val = switch_internal(elt, f, lz, iterator, opts)
        else
          escape, val = f(elt, lz) 
        end
        if escape then
          return escape, val
        end
      elseif opts.no_tags then
        local parentstr = ""
        if parent then
          parentstr = " in parent "..parent.name
        end
        error("unexpected element "..elt.name..parentstr)
      else
        if consume then consume(elt) end
      end
    end
  end
  if ftable[-1] then
    return ftable[-1](lz, parent)
  end
end

local emptyopts = {}

local
function switch_c(lz, ftable, opts)
  local consume = (lazytree and lazytree.consume) or nil
  opts = opts or emptyopts
  local parent = opts.parent
  return switch_internal(lz, ftable, parent, xpairs_c, opts, consume)
end

Public.switch_c = switch_c

local
function switch(lz, ftable, opts)
  opts = opts or emptyopts
  local parent = opts.parent
  return switch_internal(lz, ftable, parent, xpairs, opts, nil)
end

Public.switch = switch

return Public
