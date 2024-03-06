set(prometheuscpp_build "${CMAKE_CURRENT_BINARY_DIR}/auxil/prometheus-cpp")
set(prometheuscpp_src   "${CMAKE_CURRENT_SOURCE_DIR}/auxil/prometheus-cpp")

set(OLD_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS OFF)
option(ENABLE_PUSH "" OFF)
option(ENABLE_TESTING "" OFF)
option(GENERATE_PKGCONFIG "" OFF)

add_subdirectory(auxil/prometheus-cpp EXCLUDE_FROM_ALL)

set(zeekdeps ${zeekdeps} prometheus-cpp::core prometheus-cpp::pull)
include_directories(BEFORE ${prometheuscpp_src}/pull/include ${prometheuscpp_src}/core/include)
#include_directories(BEFORE ${prometheuscpp_src}/3rdparty/civetweb/include)
include_directories(BEFORE ${prometheuscpp_build}/pull/include ${prometheuscpp_build}/core/include)

set(BUILD_SHARED_LIBS ${OLD_BUILD_SHARED_LIBS})
