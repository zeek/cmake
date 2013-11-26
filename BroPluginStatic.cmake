## A set of functions for defining Bro plugins.
##
## This set is for plugins compiled in statically.
## See BroPluginsDynamic.cmake for the dynamic version.

include(BroPluginCommon)

# Ends a plugin definition.
function(bro_plugin_end)
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

# Internal function to create a unique target name for a plugin.
macro(_plugin_target_name target ns name)
    set(${target} "plugin-${ns}-${name}")
endmacro()
