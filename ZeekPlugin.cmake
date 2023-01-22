# Make sure BifCl and BinPAC are available.
if ( NOT ZEEK_PLUGIN_INTERNAL_BUILD AND NOT Zeek_FOUND )
  find_package(Zeek REQUIRED CONFIG NO_DEFAULT_PATH PATHS "${ZEEK_DIST}/build")
endif ()

include(BifCl)
include(BinPAC)

# Wrapper include file that loads the macros for building a Zeek
# plugin either statically or dynamically, depending on whether
# we're building as part of the main Zeek source tree, or externally.

# Utility function for zeek_add_*plugin functions. Those functions use
# cmake_parse_arguments, which lumps together all arguments for the 'PAC'
# sections into one array. This function simply allows us to traverse all 'PAC'
# sections individually.
#
# Usage example:
#
#   zeek_next_pac_block(at_end pacInputs pacRemainder ${args})
#   while (NOT at_end)
#       message(STATUS "inputs ${pacInputs}")
#       message(STATUS "pacRemainder ${pacRemainder}")
#       zeek_next_pac_block(at_end pacInputs pacRemainder ${pacRemainder})
#   endwhile()
function(zeek_next_pac_block at_end inputs remainder)
  # Sanity checking.
  list(LENGTH ARGN n)
  if ( n EQUAL "0" )
    set(${at_end} ON PARENT_SCOPE)
    return()
  endif()
  # List of separators, i.e., keywords recognized by zeek_add_*plugin functions.
  set(separators INCLUDE_DIRS DEPENDENCIES SOURCES BIFS DIST_FILES PAC)
  # Seek to the first PAC block.
  set(i 0)
  foreach ( arg ${ARGN} )
    math(EXPR i "${i}+1")
    if ( arg  STREQUAL "PAC" )
      break()
    endif()
  endforeach()
  # Bail out if no block was found.
  if ( i EQUAL n )
    set(${at_end} ON PARENT_SCOPE)
    return()
  endif ()
  # Fill the result list.
  set(j ${i})
  list(SUBLIST ARGN ${i} -1 subArgs)
  set(res "")
  foreach ( arg ${subArgs} )
    if ( arg  IN_LIST separators )
      break()
    endif()
    list(APPEND res ${arg})
    math(EXPR j "${j}+1")
  endforeach ()
  if ( j EQUAL n )
    set(unusedArgs "")
  else()
    list(SUBLIST ARGN ${j} -1 unusedArgs)
  endif()
  # Fill the result variables.
  set(${at_end} OFF PARENT_SCOPE)
  set(${inputs} ${res} PARENT_SCOPE)
  set(${remainder} ${unusedArgs} PARENT_SCOPE)
endfunction()

include(ZeekPluginStatic)
include(ZeekPluginDynamic)

if ( ZEEK_PLUGIN_INTERNAL_BUILD AND NOT ZEEK_PLUGIN_BUILD_DYNAMIC)
    set(ZEEK_PLUGIN_BUILD_DYNAMIC OFF)
elseif (NOT ZEEK_PLUGIN_BUILD_DYNAMIC)
    set(ZEEK_PLUGIN_BUILD_DYNAMIC ON)
endif ()

# Sets `target` to contain the CMake target name for a plugin.
macro(zeek_get_plugin_target var ns name)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        zeek_get_dynamic_plugin_target(${var} ${ns} ${name})
    else ()
        zeek_get_static_plugin_target(${var} ${ns} ${name})
    endif ()
endmacro ()

# Usage:
# zeek_add_plugin(
#   <namespace>
#   <name>
#   [INCLUDE_DIRS ...]
#   [DEPENDENCIES ...]
#   [DIST_FILES ...]
#   [SOURCES ...]
#   [BIFS ...]
#   [[PAC ...] ... ]
# )
# * INCLUDE_DIRS:
#   Adds additional include directories for building the plugin. By default, the
#   function adds `CMAKE_CURRENT_BINARY_DIR` as additional include directory.
# * DEPENDENCIES:
#   Adds additional CMake targets as extra dependencies.
# * DIST_FILES:
#   Adds additional files to install alongside the plugin when building a
#   dynamic plugin. Ignored when building static plugins.
# * SOURCES:
#   List of C++ files for compiling the plugin.
# * BIFS:
#   List of BIF files (*.bif) for compiling the plugin.
# * PAC:
#   Adds a BinPAC parser to the plugin. The function accepts multiple `PAC`
#   blocks. Each block defines a single BinPAC parser.
function(zeek_add_plugin ns name)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        zeek_add_dynamic_plugin(${ns} ${name} ${ARGV})
    else ()
        zeek_add_static_plugin(${ns} ${name} ${ARGV})
    endif ()
endfunction()

include(ZeekPluginCommon)
