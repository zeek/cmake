## A set of functions for defining Bro plugins.
##
## This set is used by both static and dynamic plugins via
## BroPluginsStatic and BroPluginsDynamic, respectively.

include(BifCl)
include(BinPAC)

# Begins a plugin definition, giving its namespace and name as the arguments.
function(bro_plugin_begin ns name)
    _plugin_target_name(target "${ns}" "${name}")
    set(_plugin_lib  "${target}" PARENT_SCOPE)
    set(_plugin_name "${target}" PARENT_SCOPE)
    set(_plugin_ns   "${ns}_${name}" PARENT_SCOPE)
    set(_plugin_objs "" PARENT_SCOPE)
    set(_plugin_deps "" PARENT_SCOPE)
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
    list(APPEND _plugin_deps ${BINPAC_BUILD_TARGET})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    set(_plugin_deps "${_plugin_deps}" PARENT_SCOPE)
endfunction()

# Adds *.bif files to a plugin.
function(bro_plugin_bif)
    foreach ( bif ${ARGV} )
        bif_target(${bif} "plugin" ${_plugin_ns})
        list(APPEND _plugin_objs ${BIF_OUTPUT_CC})
        list(APPEND _plugin_deps ${BIF_BUILD_TARGET})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
        set(_plugin_deps "${_plugin_deps}" PARENT_SCOPE)
    endforeach ()
endfunction()

# Internal function to create a unique target name for a plugin.
macro(_plugin_target_name target ns name)
    set(${target} "plugin-${ns}-${name}")
endmacro()

