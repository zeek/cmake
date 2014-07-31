## A set of functions for defining Bro plugins.
##
## This set is for plugins compiled in statically.
## See BroPluginsDynamic.cmake for the dynamic version.

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
    if ( bro_HAVE_OBJECT_LIBRARIES )
        add_library(${_plugin_lib} OBJECT ${_plugin_objs})
        set(_target "$<TARGET_OBJECTS:${_plugin_lib}>")
    else ()
        add_library(${_plugin_lib} STATIC ${_plugin_objs})
        set(_target "${_plugin_lib}")
    endif ()

    if ( NOT "${_plugin_deps}" STREQUAL "" )
        add_dependencies(${_plugin_lib} ${_plugin_deps})
    endif ()

    add_dependencies(${_plugin_lib} generate_outputs)

    set(bro_PLUGIN_LIBS ${bro_PLUGIN_LIBS} "${_target}" CACHE INTERNAL "plugin libraries")
endfunction()

macro(_plugin_target_name_static target ns name)
    set(${target} "plugin-${ns}-${name}")
endmacro()

