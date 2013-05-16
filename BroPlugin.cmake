## A set of functions for defining Bro plugins.
##
## TODO: Currently, these support only plugins that are statically
## compiled into the Bro binary. Eventually we'll extend them
## to alternatively produce shared libraries that can be loaded at
## run-time.

include(BifCl)
include(BinPAC)

function(bro_plugin_add)
    list(APPEND _plugin_objs ${ARGV})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
endfunction()

# Begin a plugin definition, given its name as the argument.
function(bro_plugin_begin ns name)
    _plugin_target_name(target "${ns}" "${name}")
    set(_plugin_lib  "${target}" PARENT_SCOPE)
    set(_plugin_name "${target}" PARENT_SCOPE)
    set(_plugin_ns   "${ns}_${name}" PARENT_SCOPE)
    set(_plugin_objs "" PARENT_SCOPE)
endfunction()

# Adds *.cc files to a plugin.
function(bro_plugin_cc)
        list(APPEND _plugin_objs ${ARGV})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
endfunction()

# Adds a *.pac files to a plugin. Further *.pac files may given as
# dependencies.
function(bro_plugin_pac)
    binpac_target(${ARGV})
    list(APPEND _plugin_objs ${BINPAC_OUTPUT_CC})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
endfunction()

# Adds *.bif files to a plugin.
function(bro_plugin_bif)
    foreach ( bif ${ARGV} )
        bif_target(${bif} "plugin" ${_plugin_ns})
        list(APPEND _plugin_objs ${BIF_OUTPUT_CC})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    endforeach ()
endfunction()

function(bro_plugin_end)
    add_library(${_plugin_lib} OBJECT ${_plugin_objs})
    add_dependencies(${_plugin_lib} generate_outputs)
    set(bro_PLUGIN_OBJECT_LIBS ${bro_PLUGIN_OBJECT_LIBS} $<TARGET_OBJECTS:${_plugin_lib}> CACHE INTERNAL "plugin object libraries")
endfunction()

#function(bro_plugin_dependencies ns name deps)
#    _plugin_target_name(target ${ns} ${name})
#    add_dependencies(${target} deps)
#endfunction()

macro(_plugin_target_name target ns name)
    # STRING(REGEX REPLACE "${CMAKE_BINARY_DIR}/src/" "" tmp "plugin-${CMAKE_CURRENT_BINARY_DIR}/${name}")
    ### STRING(REGEX REPLACE "-[^-]+$" "" tmp "${tmp}") # FIXME: Doesn't work.
    # STRING(REGEX REPLACE "/" "-" ${target} "${tmp}")
    set(${target} "plugin-${ns}-${name}")
endmacro()

