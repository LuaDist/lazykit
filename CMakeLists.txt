# Copyright (C) 2007-2011 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( lazykit C )
cmake_minimum_required ( VERSION 2.6 )
include ( dist.cmake )

# LazyKit C modules
install_lua_module ( ciostring ciostring/iostring.c )
install_lua_module ( iostring iostring.lua )
install_lua_module ( ioxmlgen ioxmlgen.lua )
install_lua_module ( lazytree lazytree.lua )
install_lua_module ( lxpevent lxpevent.lua )
install_lua_module ( lxptree lxptree.lua )
install_lua_module ( xmlgen xmlgen.lua )
install_lua_module ( xmliter xmliter.lua )
install_lua_module ( xmlview xmlview.lua )
install_lua_module ( concatxmlgen.lua ciostring/concatxmlgen.lua )

# Install LazyKit Documentation
install_data ( README )
install_doc ( doc/ )

# LazyKit tests and samples
install_example ( examples/ )
install_test ( ciostring/benchmark.lua )

#add_lua_test ( ciostring/benchmark.lua ) # FIX

