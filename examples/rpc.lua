require "lazytree"
require "xmliter"
require "xmlview"

local function hasElementContent(t)
  for i,v in xnpairs(t) do
    return true
  end
  return false
end

-- This is not the clearest way to parse XML-RPC values, but it does
-- illustrate how to use [0] and [-1] handlers along with setting values
-- on XML tree nodes.

-- If you were doing this for real, you'd probably break out separate
-- parsestruct and parsearray functions.

-- Strategy: descend into tree, annotating nodes with their values.

-- This does not detect duplicate content like
--
-- <value><i4>1</i4><i4>2</i4></value>
--
-- Feel free to assert(not value.value) before setting it in each place...


valuetable={
  [0]=function (value)
    if not hasElementContent(value) then
      value.value = xstring(value)
      -- We could abort by:
      --   return true
      -- but we know we're only going to be skipping strings...
    end
  end;

  i4=function (i4, value)
    local v = tonumber(xstring(i4))
    if v ~= math.floor(v) then
      error("i4 value must be an integer, not "..v)
    end
    value.value=tonumber(v)
  end;

  boolean=function (boolean, value)
    local v = tonumber(xstring(boolean))
    if v == 1 then
      value.value = true
    elseif v == 0 then
      value.value = false
    else
      error("boolean value must be 1 or 0, not "..v)
    end
  end;

  string=function(string, value)
    value.value = xstring(string)
  end;

  double=function(double, value)
    value.value = tonumber(xstring(double))
  end;

  ["dateTime.iso8601"]=function (dt, value)
    -- insert type wrapper here
    value.value = xstring(dt)
  end;

  base64=function (base64, value)
    -- insert type wrapper here
    value.value = xstring(base64)
  end;

  struct={
    [0]=function (struct, value) struct.structvalue={} end;
    member={
      name=function(name, member)
        assert(not member.membername)
        member.membername=xstring(name)
      end;
      value=function(value, member)
        assert(not member.membervalue)
        member.membervalue = parse_value(value)
      end;
      [-1]=function(member, struct)
        local name = member.membername
        local value = member.membervalue
        assert(name) assert(value)
        assert(not struct.structvalue[name])
        struct.structvalue[name] = value
      end;
    };
    [-1]=function (struct, value)
      value.value = struct.structvalue
    end;
  };

  array={
    data={
      [0]=function (data, array) data.datavalue={n=0} end;
      value=function (value, data)
        local v = parse_value(value)      
        table.insert(data.datavalue, v)
      end;
      [-1]=function (data, array) array.arrayvalue=data.datavalue end;
    };
    [-1]=function (array, value) 
      -- value.value = assert(array.arrayvalue, "no <data> in array")
      -- sadly, some implementations don't send an empty <data>
      value.value = array.arrayvalue or {n=0}
    end;
  }
}

-- integer is an alias for i4
valuetable.integer = valuetable.i4

function parse_value(tree)
  assert(tree.name=="value")
  xmliter.switch_c(tree, valuetable, {no_tags=true})
  return tree.value
end


function pv(s)
  local l0 = lazytree.parsestring(s)
  return parse_value(l0)
end

  
x1 = [[
<value><struct>
   <member>
      <name>lowerBound</name>
      <value><i4>18</i4></value>
   </member>
   <member>
      <name>upperBound</name>
      <value><i4>139</i4></value>
      </member>
   </struct></value>
]]

v1 = pv(x1)
print("v1.lowerBound", v1.lowerBound)
print("v1.upperBound", v1.upperBound)

x0 = [[
<value><i4>7</i4></value>
]]

v0 = pv(x0)

print()
print("v0", v0)

x2 = [[
<value>
<array>
   <data>
      <value><i4>12</i4></value>
      <value>Egypt</value>
      <value><boolean>0</boolean></value>
      <value><i4>-31</i4></value>
   </data>
</array>
</value>
  ]]

v2 = pv(x2)

print()
print("v2.n", v2.n)
for i,v in ipairs(v2) do
  print("v2."..i, type(v), v)
end
