## A set of functions for defining Bro plugins.
##
## This set is used by both static and dynamic plugins via
## BroPluginsStatic and BroPluginsDynamic, respectively.

include(RequireCXX11)

include(BifCl)
include(BinPAC)

# Begins a plugin definition, giving its namespace and name as the arguments.
function(bro_plugin_begin ns name)
    _plugin_target_name(target "${ns}" "${name}")
    set(_plugin_lib        "${target}" PARENT_SCOPE)
    set(_plugin_name       "${ns}::${name}" PARENT_SCOPE)
    set(_plugin_name_canon "${ns}_${name}" PARENT_SCOPE)
    set(_plugin_ns         "${ns}" PARENT_SCOPE)
    set(_plugin_objs       "" PARENT_SCOPE)
    set(_plugin_deps       "" PARENT_SCOPE)
    set(_plugin_dist       "" PARENT_SCOPE)
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

# Add an additional object file to the plugin's library.
function(bro_plugin_obj)
    foreach ( bif ${ARGV} )
        list(APPEND _plugin_objs ${bif})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    endforeach ()
endfunction()

# Add additional files that should be included into the binary plugin distribution.
# Ignored for static plugins.
macro(bro_plugin_dist_files)
    foreach ( file ${ARGV} )
        list(APPEND _plugin_dist ${file})
        # Don't need this here, and generates an error that
        # there is not parent scope. Not sure why it does that
        # here but not for other macros doing something similar.
        # set(_plugin_dist "${_plugin_dist}" PARENT_SCOPE)
    endforeach ()
endmacro()

# Link an additional library to the plugin's library.
function(bro_plugin_link_library)
    if ( BRO_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_link_library_dynamic(${ARGV})
    else ()
        bro_plugin_link_library_static(${ARGV})
    endif ()
endfunction()

# Adds *.bif files to a plugin.
macro(bro_plugin_bif)
    if ( BRO_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_bif_dynamic(${ARGV})
    else ()
        bro_plugin_bif_static(${ARGV})
    endif ()
endmacro()

# Ends a plugin definition.
macro(bro_plugin_end)
    if ( BRO_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_end_dynamic(${ARGV})
    else ()
        bro_plugin_end_static(${ARGV})
    endif ()
endmacro()

# Internal macro to create a unique target name for a plugin.
macro(_plugin_target_name target ns name)
    if ( BRO_PLUGIN_BUILD_DYNAMIC )
        _plugin_target_name_dynamic(${ARGV})
    else ()
        _plugin_target_name_static(${ARGV})
    endif ()
endmacro()

