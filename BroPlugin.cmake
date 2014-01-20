
# Wrapper include file that loads the macros for building a Bro #
# plugin either statically or dynamically, depending on whether
# we're building as part of the main Bro source tree, or externally.

if ( BRO_PLUGIN_INTERNAL_BUILD )
    if ( "${BRO_PLUGIN_BUILD_DYNAMIC}" STREQUAL "" )
        set(BRO_PLUGIN_BUILD_DYNAMIC FALSE)
    endif()
else ()
    set(BRO_PLUGIN_BUILD_DYNAMIC TRUE)
endif ()

#set( BRO_DIST "/Users/robin/bro/dynamic-plugins-2.3")

include(BroPluginCommon)
include(BroPluginStatic)
include(BroPluginDynamic)

