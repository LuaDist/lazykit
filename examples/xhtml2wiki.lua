require "lazytree"
require "xmliter"
require "xmlview"

local filename = arg[1]
if not filename or arg[2] then
   print("usage: xhtml2wiki.lua filename.html")
   os.exit(1)
end

local root=lazytree.parsefile(filename)

local function printi(s)
   -- no newline
   io.stdout:write(s)
end

local ftable = {
   head=function () end;
   body={
      h1=function (h1)
            print("=== "..xstring(h1).." ===")
         end;
      h2=function (h2)
            print("=== "..xstring(h2).." ===")
         end;
      h3=function (h3)
            print("== "..xstring(h3).." ==")
         end;
      pre=function (pre)
             print("        {{{"..xstring(pre).." }}}")
          end;
      p={
         [""]=function (s)
                 s = string.gsub(s, "\n[ ]+", "\n")
                 s = string.gsub(s, "[ ]+", " ")
                 printi(s)
              end;
         code=function (code)
                 local s = xstring(code)
                 s = string.gsub(s, "\n", " ")
                 s = string.gsub(s, "[ ]+", " ")                 
                 printi("{{"..s.."}}")
              end;
         dfn=function (dfn)
                 printi("''"..xstring(dfn).."''")
              end;
         [-1]=function () print() print() end;
      }
   }
}

xmliter.switch_c(root, ftable, {no_tags=true})

