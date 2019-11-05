## A set of functions for defining Zeek plugins.
##
## This set is for plugins compiled in statically.
## See ZeekPluginDynamic.cmake for the dynamic version.

function(bro_plugin_bif_static)
    foreach ( bif ${ARGV} )
        bif_target(${bif} "plugin" ${_plugin_name} ${_plugin_name_canon} TRUE)
        list(APPEND _plugin_objs ${BIF_OUTPUT_CC})
        list(APPEND _plugin_deps ${BIF_BUILD_TARGET})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
        set(_plugin_deps "${_plugin_deps}" PARENT_SCOPE)
    endforeach ()
endfunction()

function(bro_plugin_link_library_static)
    foreach ( lib ${ARGV} )
        set(bro_SUBDIR_LIBS ${bro_SUBDIR_LIBS} "${lib}" CACHE INTERNAL "plugin libraries")
    endforeach ()
endfunction()

function(bro_plugin_end_static)
    add_library(${_plugin_lib} OBJECT ${_plugin_objs})

    if ( NOT "${_plugin_deps}" STREQUAL "" )
        add_dependencies(${_plugin_lib} ${_plugin_deps})
    endif ()

    add_dependencies(${_plugin_lib} generate_outputs)

    set(bro_PLUGIN_LIBS ${bro_PLUGIN_LIBS} "$<TARGET_OBJECTS:${_plugin_lib}>" CACHE INTERNAL "plugin libraries")
    set(bro_PLUGIN_DEPS ${bro_PLUGIN_DEPS} "${_plugin_lib}" CACHE INTERNAL "plugin dependencies")
endfunction()

macro(_plugin_target_name_static target ns name)
    set(${target} "plugin-${ns}-${name}")
endmacro()

