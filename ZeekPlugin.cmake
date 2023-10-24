# This function wraps the find_package call for Zeek to allow us to override
# variables such as CMAKE_PREFIX_PATH in the function scope without changing the
# variable at directory scope. The function also locates dependencies for
# dynamic plugins like BinPAC and BifCl.
function (zeek_plugin_bootstrapping)
    # Plugins that build against the source tree set ZEEK_DIST. Here, we have our
    # package file plus ZeekPluginConfig.cmake to help out.
    if (ZEEK_DIST)
        message("-- Using ZEEK_DIST: ${ZEEK_DIST}")
        find_package(Zeek REQUIRED CONFIG NO_DEFAULT_PATH PATHS "${ZEEK_DIST}/build")
        return()
    endif ()
    # When building plugins against an installed Zeek, this file must be installed
    # alongside this script. It provides the variables ZEEK_CMAKE_CONFIG_DIR and
    # ZEEK_CMAKE_INSTALL_PREFIX.
    include(ZeekPluginBootstrap)
    # When looking for dependencies, make sure to look into the install prefix.
    list(PREPEND CMAKE_PREFIX_PATH "${ZEEK_CMAKE_INSTALL_PREFIX}")
    # We also needs to find Broker, which we usually can find through the install
    # prefix. Plugins may also set BROKER_ROOT_DIR to help find Broker, which we
    # forward to the actual CMake variable if present.
    if (NOT Broker_DIR AND BROKER_ROOT_DIR)
        set(Broker_DIR "${BROKER_ROOT_DIR}")
    endif ()
    # Load the CMake package for Zeek. This pulls in dependencies as well as
    # targets such as Zeek::DynamicPluginBase.
    find_package(Zeek REQUIRED CONFIG NO_DEFAULT_PATH PATHS "${ZEEK_CMAKE_CONFIG_DIR}")
    # Find BinPAC via Zeek's FindBinPAC.cmake script.
    if (NOT TARGET Zeek::BinPAC)
        find_package(BinPAC REQUIRED)
        add_executable(Zeek::BinPAC IMPORTED)
        set_property(TARGET Zeek::BinPAC PROPERTY IMPORTED_LOCATION "${BinPAC_EXE}")
    endif ()
    # Find BifCl. This should be located under ZEEK_CMAKE_INSTALL_PREFIX/bin.
    if (NOT TARGET Zeek::BifCl)
        list(PREPEND CMAKE_PROGRAM_PATH "${ZEEK_CMAKE_INSTALL_PREFIX}/bin")
        find_program(ZeekBifClPath bifcl)
        if (NOT ZeekBifClPath) # Note: CMake > 3.18 has REQUIRED for find_program.
            message(
                FATAL_ERROR
                    "failed to find bifcl, please add hints to CMAKE_PREFIX_PATH or CMAKE_PROGRAM_PATH"
            )
        endif ()
        message(STATUS "Found BifCl at ${ZeekBifClPath}")
        add_executable(Zeek::BifCl IMPORTED)
        set_property(TARGET Zeek::BifCl PROPERTY IMPORTED_LOCATION "${ZeekBifClPath}")
    endif ()
    # For historic reasons, we also automagically add <plugin-src>/cmake (if it
    # exists) to CMAKE_MODULE_PATH.
    if (EXISTS "${PROJECT_SOURCE_DIR}/cmake")
        list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
        set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)
    endif ()
    # Another historic quirk: force CMAKE_EXPORT_COMPILE_COMMANDS to ON.
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON
        CACHE PATH "Configures whether to write a compile database." FORCE)

    # When CMAKE_BUILD_TYPE is not set, use the one from Zeek.
    if (NOT CMAKE_BUILD_TYPE)
        message(STATUS "Setting plugin CMAKE_BUILD_TYPE to ${ZEEK_CMAKE_BUILD_TYPE}")
        set(CMAKE_BUILD_TYPE "${ZEEK_CMAKE_BUILD_TYPE}"
            CACHE STRING "Configures the CMAKE_BUILD_TYPE for the plugin." FORCE)
    endif ()
endfunction ()

# Make sure BifCl and BinPAC are available.
if (NOT ZEEK_PLUGIN_INTERNAL_BUILD)
    zeek_plugin_bootstrapping()
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
function (zeek_next_pac_block at_end inputs remainder)
    # Sanity checking.
    list(LENGTH ARGN n)
    if (n EQUAL "0")
        set(${at_end} ON PARENT_SCOPE)
        return()
    endif ()
    # List of separators, i.e., keywords recognized by zeek_add_*plugin functions.
    set(separators INCLUDE_DIRS DEPENDENCIES SOURCES BIFS DIST_FILES PAC)
    # Seek to the first PAC block.
    set(i 0)
    foreach (arg ${ARGN})
        math(EXPR i "${i}+1")
        if (arg STREQUAL "PAC")
            break()
        endif ()
    endforeach ()
    # Bail out if no block was found.
    if (i EQUAL n)
        set(${at_end} ON PARENT_SCOPE)
        return()
    endif ()
    # Fill the result list.
    set(j ${i})
    list(SUBLIST ARGN ${i} -1 subArgs)
    set(res "")
    foreach (arg ${subArgs})
        if (arg IN_LIST separators)
            break()
        endif ()
        list(APPEND res ${arg})
        math(EXPR j "${j}+1")
    endforeach ()
    if (j EQUAL n)
        set(unusedArgs "")
    else ()
        list(SUBLIST ARGN ${j} -1 unusedArgs)
    endif ()
    # Fill the result variables.
    set(${at_end} OFF PARENT_SCOPE)
    set(${inputs} ${res} PARENT_SCOPE)
    set(${remainder} ${unusedArgs} PARENT_SCOPE)
endfunction ()

include(ZeekPluginStatic)
include(ZeekPluginDynamic)

if (NOT ZEEK_PLUGIN_INTERNAL_BUILD AND ${CMAKE_MINIMUM_REQUIRED_VERSION} VERSION_LESS 3.15.0)
    message(
        WARNING
            "Package requires CMake ${CMAKE_MINIMUM_REQUIRED_VERSION} which is less than Zeek's requirement (3.15.0). This will likely cause build failures and should be fixed."
    )
endif ()

if (ZEEK_PLUGIN_INTERNAL_BUILD AND NOT ZEEK_PLUGIN_BUILD_DYNAMIC)
    set(ZEEK_PLUGIN_BUILD_DYNAMIC OFF)
elseif (NOT ZEEK_PLUGIN_BUILD_DYNAMIC)
    set(ZEEK_PLUGIN_BUILD_DYNAMIC ON)
endif ()

# Sets `target` to contain the CMake target name for a plugin.
macro (zeek_get_plugin_target var ns name)
    if (ZEEK_PLUGIN_BUILD_DYNAMIC)
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
#   [SCRIPT_FILES ...]
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
# * SCRIPT_FILES:
#   Marks the given script files as dependencies for the tarball when building
#   a dynamic plugin. This is currently for dependency tracking only - the
#   plugin's whole script directory is included in the resulting tarball
#   regardless of the files provided here. Ignored when building static plugins.
# * SOURCES:
#   List of C++ files for compiling the plugin.
# * BIFS:
#   List of BIF files (*.bif) for compiling the plugin.
# * PAC:
#   Adds a BinPAC parser to the plugin. The function accepts multiple `PAC`
#   blocks. Each block defines a single BinPAC parser.
function (zeek_add_plugin ns name)
    if (ZEEK_PLUGIN_BUILD_DYNAMIC)
        zeek_add_dynamic_plugin(${ns} ${name} ${ARGV})
    else ()
        zeek_add_static_plugin(${ns} ${name} ${ARGV})
    endif ()
endfunction ()

include(ZeekPluginCommon)
