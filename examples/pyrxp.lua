--[[ 

Benchmarking against python2.1.  See
http://www.reportlab.org/pyrxp.html and
http://www.reportlab.org/ftp/pyrxp_examples.zip .

On my system, running their benchmark returns:

expat: init 0.0000, parse 0.7900, traverse 0.1600, mem used 4884kb, mem factor 10.97
minidom: init 0.0600, parse 8.4300, traverse 0.0000, mem used 29860kb, mem factor 67.06

(Note that the minidom test doesn't bother traversing the table it
built...)

The Lua numbers without consuming are:

lxp: init 0.01, parse 0.51, traverse 0.13, mem used 3828kb, mem factor 8.59
lazy: init 0.01, parse 0.00, traverse 1.31, mem used 4968kb, mem factor 11.16
lazy2: init 0.01, parse 0.94, traverse 0.19, mem used 4948kb, mem factor 11.11

The Lua numbers with consuming are:

lxp: init 0.01, parse 0.51, traverse 0.15, mem used 3912kb, mem factor 8.78
lazy: init 0.01, parse 0.01, traverse 1.26, mem used 338kb, mem factor 0.87
lazy2: init 0.01, parse 0.95, traverse 0.21, mem used 4948kb, mem factor 11.11

The second line is the magic one.

'
]]

function printmeminfo()
  local statf = io.open("/proc/self/status")
  if statf then
    for line in statf:lines() do
      if string.find(line, "VmSize") or string.find(line, "VmData") then
        print(line)
      end
    end
    statf:close()
  else
    os.execute("ps ux | grep lua | grep traces | grep -v grep")
  end
end

printmeminfo()

preinit = os.clock()

require "lazytree"
require "lxptree"
require "xmliter"


local function tupleTreeStats(t)
  local attrcount = 0
  for k,v in xattrpairs(t) do
    attrcount = attrcount + 1
  end

  local nodecount = 1
  -- for i,x in xnpairs(t) do
  for i,x in xnpairs_c(t) do
    local a,n = tupleTreeStats(x)
    attrcount = attrcount + a
    nodecount = nodecount + n
  end
  return attrcount, nodecount
end

init = os.clock()
print("init", init-preinit)

local testfile = "/home/nop/rml_a.xml"

function doit_lazy()
  l0 = lazytree.parsefile(testfile)
end

function doit_lazy2()
  l0 = lazytree.parsefile(testfile)
  lazytree.load(l0)
end

function doit_lxp()
  l0 = lxptree.parsefile(testfile)
end

ft = {lazy=doit_lazy, lazy2=doit_lazy2, lxp=doit_lxp}

local strategyname = arg[1]
if not strategyname or not ft[strategyname] then
  print("usage: pyrxp.lua {lazy|lazy2|lxp}")
  os.exit(1)
end
ft[strategyname]()

start = os.clock()
print("parse", start - init)
print("counted", tupleTreeStats(l0))
endtime = os.clock()
print("traverse", endtime-start)

printmeminfo()
