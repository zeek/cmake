## A set of functions for defining Zeek plugins.
##
## This set is used by both static and dynamic plugins via
## ZeekPluginStatic and ZeekPluginDynamic, respectively.

include(RequireCXX17)
include(FindClangTidy)

include(BifCl)
include(BinPAC)

# Begins a plugin definition, giving its namespace and name as the arguments.
function(zeek_plugin_begin ns name)
    _plugin_target_name(target "${ns}" "${name}")
    set(_plugin_lib        "${target}" PARENT_SCOPE)
    set(_plugin_name       "${ns}::${name}" PARENT_SCOPE)
    set(_plugin_name_canon "${ns}_${name}" PARENT_SCOPE)
    set(_plugin_ns         "${ns}" PARENT_SCOPE)
    set(_plugin_objs       "" PARENT_SCOPE)
    set(_plugin_deps       "" PARENT_SCOPE)
    set(_plugin_dist       "" PARENT_SCOPE)
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_begin)
    zeek_plugin_begin(${ARGV})
endmacro()

# Adds *.cc files to a plugin.
function(zeek_plugin_cc)
    list(APPEND _plugin_objs ${ARGV})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    add_clang_tidy_files(${ARGV})
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_cc)
    zeek_plugin_cc(${ARGV})
endmacro()

# Adds a *.pac file to a plugin. Further *.pac files may given that
# it depends on.
function(zeek_plugin_pac)
    binpac_target(${ARGV})
    list(APPEND _plugin_objs ${BINPAC_OUTPUT_CC})
    list(APPEND _plugin_deps ${BINPAC_BUILD_TARGET})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    set(_plugin_deps "${_plugin_deps}" PARENT_SCOPE)
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_pac)
    zeek_plugin_pac(${ARGV})
endmacro()

# Add an additional object file to the plugin's library.
function(zeek_plugin_obj)
    foreach ( bif ${ARGV} )
        list(APPEND _plugin_objs ${bif})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    endforeach ()
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_obj)
    zeek_plugin_obj(${ARGV})
endmacro()

# Add additional files that should be included into the binary plugin distribution.
# Ignored for static plugins.
macro(zeek_plugin_dist_files)
    foreach ( file ${ARGV} )
        list(APPEND _plugin_dist ${file})
        # Don't need this here, and generates an error that
        # there is not parent scope. Not sure why it does that
        # here but not for other macros doing something similar.
        # set(_plugin_dist "${_plugin_dist}" PARENT_SCOPE)
    endforeach ()
endmacro()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_dist_files)
    zeek_plugin_dist_files(${ARGV})
endmacro()

# Link an additional library to the plugin's library.
function(zeek_plugin_link_library)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_link_library_dynamic(${ARGV})
    else ()
        bro_plugin_link_library_static(${ARGV})
    endif ()
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_link_library)
    zeek_plugin_link_library(${ARGV})
endmacro()

# Adds *.bif files to a plugin.
macro(zeek_plugin_bif)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_bif_dynamic(${ARGV})
    else ()
        bro_plugin_bif_static(${ARGV})
    endif ()
endmacro()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_bif)
    zeek_plugin_bif(${ARGV})
endmacro()

# Ends a plugin definition.
macro(zeek_plugin_end)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_end_dynamic(${ARGV})
    else ()
        bro_plugin_end_static(${ARGV})
    endif ()
endmacro()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_end)
    zeek_plugin_end(${ARGV})
endmacro()

# Internal macro to create a unique target name for a plugin.
macro(_plugin_target_name target ns name)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        _plugin_target_name_dynamic(${ARGV})
    else ()
        _plugin_target_name_static(${ARGV})
    endif ()
endmacro()

