require "lazytree"
require "xmlgen"

s = [[
<a foo='bar' baz='"'>
  <b/>
  <mixed>a<b>b</b></mixed>
</a>
  ]]

lz = lazytree.parsestring(s)
xmlgen.writefile(io.stdout, lz)
print("\n----")
print(xmlgen.tostring(lz))
