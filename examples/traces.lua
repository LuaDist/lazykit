-- see http://tomacorp.com/perl/xml/saxvstwig.html

-- This is roughly 4-5 times faster than perl, and uses ~2.2M of
-- virtual memory space; perl reportedly used 6.6M, 12M, or 30M depending
-- on which package and options used.

-- Forcing the entire tree into memory uses ~10M.  The lxptree is 30%
-- faster.

-- Note that a bare Lua process with required extensions loaded 
-- uses ~1.8M of vm space, much of which is sharable....

-- Personally, I think this is easier to read too.

require "lazytree"
require "lxptree"
require "xmliter"

-- if you don't have ciostring, you can switch to iostring

require "ciostring"
out = ciostring.newoutput()

-- slower, uses more memory, but pure Lua
-- require "iostring"
-- out = iostring.newoutput()



function print_sep(...)
  out:write(table.concat(arg, " "))
  out:write("\n")
end

function process_net(lz)
  local ftable = 
    {
    HEADER=function (lz) out:write(lz[1]) end;
    UNITS=function (lz) print_sep("UNITS", lz.attr.val) end;
    STFIRST=function (lz) print_sep("ST", lz.attr.maxx,
      lz.attr.maxy, lz.attr.maxroute, lz.attr.numconn) end;
    XRF=function (lz) print_sep("XRF ", lz.attr.num, lz.attr.name) end;
    NET={
      [0]=function (lz) print_sep("# NET",  "'"..lz.attr.name.."'") end;
      WIR={
        [0]=function (lz) print_sep("WIR", lz.attr.numseg, lz.attr.startx,
          lz.attr.starty, lz.attr.termx, lz.attr.termy, lz.attr.optgroup) end;
        SEG=function (lz) print_sep("SEG", lz.attr.x, lz.attr.y,
          lz.attr.lay, lz.attr.width) end
      };
      GUI=function (lz) print_sep("GUI", lz.attr.startx, lz.attr.starty,
        lz.attr.startlay, lz.attr.termx, lz.attr.termy, lz.attr.termlay,
        lz.attr.optgroup) end
    };
    STLAST=function (lz)
      print_sep("ST", lz.attr.checkstat, lz.attr.numcomplete,
        lz.attr.numinc, lz.attr.numunroute, lz.attr.numnotrace, 
        lz.attr.numfill) end
  }
  xmliter.switch_c(lz, ftable)
  local dump = assert(io.open("lazy.out", "w"))
  dump:write(out:getstring())
  dump:close()
end

-- collectgarbage(20000)

function doit_lazy()
  l0 = lazytree.parsefile("traces.xml")
  -- print(l0.n)
  -- l0 = lxptree.parsefile("traces.xml")
  -- collectgarbage(0)
  process_net(l0)
end

function doit_lazy2()
  l0 = lazytree.parsefile("traces.xml")
  lazytree.load(l0)
  process_net(l0)
end

function doit_lxp()
  l0 = lxptree.parsefile("traces.xml")
  process_net(l0)
end

ft = {lazy=doit_lazy, lazy2=doit_lazy2, lxp=doit_lxp}

local strategyname = arg[1]
if not strategyname or not ft[strategyname] then
  print("usage: traces.lua {lazy|lazy2|lxp} [memsize]")
  os.exit(1)
end

ft[strategyname]()
print(os.clock())

if arg[2] then
  local statf = io.open("/proc/self/status")
  if statf then
    print(statf:read("*a"))
    statf:close()
  else
    os.execute("ps ux | grep lua | grep traces | grep -v grep")
  end
end
