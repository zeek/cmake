## A set of functions for defining Bro plugins.
##
## Currently, these support only plugins that are statically
## compiled into the Bro binary. Eventually we'll extend them
## to alternatively produce shared libraries that can be loaded at
## run-time.

include(BifCl)
include(BinPAC)

# Begins a plugin definition, giving its namespace and name as the arguments.
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

# Adds a *.pac file to a plugin. Further *.pac files may given that
# it depends on.
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

# Ends a plugin definition.
function(bro_plugin_end)
    if ( bro_HAVE_OBJECT_LIBRARIES )
        add_library(${_plugin_lib} OBJECT ${_plugin_objs})
        set(_target "$<TARGET_OBJECTS:${_plugin_lib}>")
    else ()
        add_library(${_plugin_lib} STATIC ${_plugin_objs})
        set(_target "${_plugin_lib}")
    endif ()

    set(bro_PLUGIN_LIBS ${bro_PLUGIN_LIBS} "${_target}" CACHE INTERNAL "plugin libraries")
    add_dependencies(${_plugin_lib} generate_outputs)
endfunction()

# Internal function to create a unique target name for a plugin.
macro(_plugin_target_name target ns name)
    set(${target} "plugin-${ns}-${name}")
endmacro()

