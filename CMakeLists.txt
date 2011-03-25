# Copyright (C) 2007-2009 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

PROJECT(lazykit C)
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
INCLUDE(dist.cmake)

# LazyKit C modules
ADD_LUA_MODULE(ciostring ciostring/iostring.c)

INSTALL (TARGETS ciostring DESTINATION ${INSTALL_CMOD})

# LazyKit Lua modules
INSTALL (FILES iostring.lua ioxmlgen.lua lazytree.lua lxpevent.lua lxptree.lua xmlgen.lua xmliter.lua xmlview.lua ciostring/concatxmlgen.lua DESTINATION ${INSTALL_LMOD})

# Install LazyKit Documentation
INSTALL(FILES README DESTINATION ${INSTALL_DATA})
INSTALL(DIRECTORY doc/ DESTINATION ${INSTALL_DOC})

# LazyKit tests and samples
INSTALL(DIRECTORY examples/ DESTINATION ${INSTALL_EXAMPLE})
INSTALL(FILES ciostring/benchmark.lua DESTINATION ${INSTALL_TEST})
