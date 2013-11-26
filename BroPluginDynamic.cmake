## A set of functions for defining Bro plugins.
##
## This set is for plugins compiled dynamically for loading at run-time.
## See BroPluginsStatic.cmake for the static version.
##
## Note: This is meant to run as a standalone CMakeLists.txt. It sets
## up all the basic infrastructure to compile a dynamic Bro plugin when
## included from its top-level CMake file.

cmake_minimum_required(VERSION 2.6.3 FATAL_ERROR)

include(CommonCMakeConfig)

if ( NOT BRO_DIST )
    message(FATAL_ERROR "BRO_DIST not set")
endif ()

if ( NOT EXISTS "${BRO_DIST}/build/CMakeCache.txt" )
    message(FATAL_ERROR "${BRO_DIST}/build/CMakeCache.txt; has Bro been built?")
endif ()

load_cache("${BRO_DIST}/build" READ_WITH_PREFIX bro_cache_ CMAKE_INSTALL_PREFIX Bro_BINARY_DIR Bro_SOURCE_DIR ENABLE_DEBUG)

set(BRO_PLUGIN_SRC                "${CMAKE_CURRENT_SOURCE_DIR}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BUILD              "${CMAKE_CURRENT_BINARY_DIR}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BRO_INSTALL_PREFIX "${bro_cache_CMAKE_INSTALL_PREFIX}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BRO_SRC            "${bro_cache_Bro_SOURCE_DIR}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BRO_BUILD          "${bro_cache_Bro_BINARY_DIR}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_INTERNAL_BUILD     false CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_ENABLE_DEBUG       "${bro_cache_ENABLE_DEBUG}"   CACHE INTERNAL "" FORCE)

message(STATUS "Bro source        : ${BRO_PLUGIN_BRO_SRC}")
message(STATUS "Bro build         : ${BRO_PLUGIN_BRO_BUILD}")
message(STATUS "Bro install prefix: ${BRO_PLUGIN_BRO_INSTALL_PREFIX}")

set(CMAKE_MODULE_PATH ${BRO_PLUGIN_SRC}/cmake)
set(CMAKE_MODULE_PATH ${BRO_PLUGIN_BRO_SRC}/cmake)

include_directories(BEFORE ${BRO_PLUGIN_BRO_SRC}/src
                           ${BRO_PLUGIN_BRO_SRC}/aux/binpac/lib
                           ${BRO_PLUGIN_BRO_BUILD}
                           ${BRO_PLUGIN_BRO_BUILD}/src
                           ${BRO_PLUGIN_BRO_BUILD}/aux/binpac/lib
                           ${CMAKE_CURRENT_BINARY_DIR}
                           ${CMAKE_CURRENT_BINARY_DIR}/src
                           ${CMAKE_CURRENT_SOURCE_DIR}
                           ${CMAKE_CURRENT_SOURCE_DIR}/src
                           )

set(ENV{PATH} "${BRO_PLUGIN_BRO_BUILD}/build/src:$ENV{PATH}")

set(bro_PLUGIN_LIBS CACHE INTERNAL "plugin libraries" FORCE)

add_definitions(-DBRO_PLUGIN_INTERNAL_BUILD=false)

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/scripts/bif)

include(BroPluginCommon)
include(GetArchitecture)

function(bro_plugin_end)
    set(lib "${_plugin_ns}-${_plugin_name}-${HOST_ARCHITECTURE}")
    add_library(${_plugin_lib} SHARED ${_plugin_objs})
    add_dependencies(${_plugin_lib} ${_plugin_deps})
    set_target_properties(${_plugin_lib} PROPERTIES PREFIX "")

    # Create bif/__init__.bro.
    bro_bif_create_loader(bif-init-${_plugin_ns} ${CMAKE_CURRENT_BINARY_DIR}/bif)
    add_dependencies(bif-init-${_plugin_ns} ${_plugin_deps})
    add_dependencies(${_plugin_lib} bif-init-${_plugin_ns})

    # Create scripts/__init__.bro.
    add_custom_target(scripts-init-${_plugin_ns}
			COMMAND echo @load ./bif >>__load__.bro
			WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/scripts)
    add_dependencies(scripts-init-${_plugin_ns} ${_plugin_deps})
    add_dependencies(${_plugin_lib} scripts-init-${_plugin_ns})
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${CMAKE_BINARY_DIR}/scripts/__load__.bro)
endfunction()

# Function createing the library name.
macro(_plugin_target_name target ns name)
    set(arch "${CMAKE_SYSTEM_NAME}.${CMAKE_SYSTEM_PROCESSOR}")
    string(TOLOWER ${arch} arch)
    set(${target} "${ns}-${name}.${HOST_ARCHITECTURE}")
endmacro()

