
## A set of functions for defining Bro plugins.
##
## TODO: Currently, these support only plugins that are statically
## compiled into the Bro binary, but eventually we'll extend them
## to alternatively produce shared libraries that can be loaded at
## run-time.

include(BifCl)
include(BinPAC)

function(bro_plugin_add)
    list(APPEND _plugin_objs ${ARGV})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
endfunction()

# Begin a plugin definition, given its name as the argument.
function(bro_plugin_begin name)
    set(_plugin_name ${name} PARENT_SCOPE)
    set(_plugin_lib  plugin-${name} PARENT_SCOPE)
    set(_plugin_objs "" PARENT_SCOPE)
endfunction()

# Adds *.cc files to a plugin.
function(bro_plugin_cc)
        list(APPEND _plugin_objs ${ARGV})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
endfunction()

# Adds a *.pac files to a plugin. Furhter *.pac files may given as
# dependencies.
function(bro_plugin_pac)
    set(ALL_BINPAC_OUTPUTS "")
    set(ALL_BINPAC_INPUTS "")
    binpac_target(${ARGV})
    list(APPEND _plugin_objs ${ALL_BINPAC_OUTPUTS})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
endfunction()

# Adds *.bif files to a plugin.
function(bro_plugin_bif)
    foreach ( bif ${ARGV} )
        bif_target_for_plugin(${_plugin_name} ${bif})
        list(APPEND _plugin_objs ${BIF_OUTPUT_CC})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    endforeach ()
endfunction()

function(bro_plugin_end)
    add_library(${_plugin_lib} OBJECT ${_plugin_objs})
    set(bro_PLUGIN_OBJECT_LIBS ${bro_PLUGIN_OBJECT_LIBS} $<TARGET_OBJECTS:${_plugin_lib}> CACHE INTERNAL "plugin object libraries")
endfunction()

function(bro_plugin_bif_create_loader target dstdir)
     add_custom_target(${target}
			COMMAND "touch" "/tmp/a"
			COMMAND "sh" "-c" "ls *.bif.bro \\| sed 's#\\\\\\(.*\\\\\\).bro#@load ./\\\\1#g' >__load__.bro"
			WORKING_DIRECTORY ${dstdir}
			)
endfunction()
