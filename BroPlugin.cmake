
# Wrapper include file that loads the macros for building a Bro #
# plugin either statically or dynamically, depending on whether
# we're building as part of the main Bro source tree, or externally.

if ( BRO_PLUGIN_INTERNAL_BUILD )
    include(BroPluginStatic)
else ()
    include(BroPluginDynamic)
endif ()

