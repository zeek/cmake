
# Wrapper include file that loads the macros for building a Zeek
# plugin either statically or dynamically, depending on whether
# we're building as part of the main Zeek source tree, or externally.

if ( ZEEK_PLUGIN_INTERNAL_BUILD )
    if ( "${ZEEK_PLUGIN_BUILD_DYNAMIC}" STREQUAL "" )
        set(ZEEK_PLUGIN_BUILD_DYNAMIC FALSE)
    endif()
else ()
    set(ZEEK_PLUGIN_BUILD_DYNAMIC TRUE)
endif ()

include(ZeekPluginCommon)
include(ZeekPluginStatic)
include(ZeekPluginDynamic)

