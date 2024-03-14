set(prometheuscpp_build "${CMAKE_CURRENT_BINARY_DIR}/auxil/prometheus-cpp")
set(prometheuscpp_src   "${CMAKE_CURRENT_SOURCE_DIR}/auxil/prometheus-cpp")

# Reset this to prevent Prometheus from using the internal zeek value and thus building
# shared libraries instead of static ones.
set(_sharedlibs ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS OFF)

# These need to be reset before setting up Prometheus because otherwise it picks up
# the -DDEBUG from SetDefaultCompileFlags and causes civetweb to output a bunch of
# debugging information. Let the library figure out its own flags.
set(_cxxflags ${CMAKE_CXX_FLAGS})
set(CMAKE_CXX_FLAGS "")
set(_cflags ${CMAKE_C_FLAGS})
set(CMAKE_C_FLAGS "")

option(ENABLE_PUSH "" OFF)
option(ENABLE_TESTING "" OFF)
option(GENERATE_PKGCONFIG "" OFF)
option(CIVETWEB_ENABLE_DEBUG_TOOLS "" OFF)

message("\n==================|  prometheus-cpp Config Summary  |====================\n")
add_subdirectory(auxil/prometheus-cpp EXCLUDE_FROM_ALL)
message("=========================================================================\n ")

set(zeekdeps ${zeekdeps} prometheus-cpp::core prometheus-cpp::pull)
include_directories(BEFORE ${prometheuscpp_src}/pull/include ${prometheuscpp_src}/core/include)
#include_directories(BEFORE ${prometheuscpp_src}/3rdparty/civetweb/include)
include_directories(BEFORE ${prometheuscpp_build}/pull/include ${prometheuscpp_build}/core/include)

set(BUILD_SHARED_LIBS ${_sharedlibs})
set(CMAKE_CXX_FLAGS ${_cxxflags})
set(CMAKE_C_FLAGS ${_cflags})
