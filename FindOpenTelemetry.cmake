set(opentelemetry_build   "${CMAKE_CURRENT_BINARY_DIR}/libopentelemetry-build")
set(opentelemetry_install "${CMAKE_CURRENT_BINARY_DIR}/libopentelemetry-build")
set(opentelemetry_src     "${CMAKE_CURRENT_SOURCE_DIR}/auxil/opentelemetry-cpp")

set(opentelemetry_metrics_lib "${opentelemetry_build}/sdk/src/metrics/libopentelemetry_metrics${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(opentelemetry_resources_lib "${opentelemetry_build}/sdk/src/resource/libopentelemetry_resources${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(opentelemetry_common_lib "${opentelemetry_build}/sdk/src/common/libopentelemetry_common${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(opentelemetry_ostream_lib "${opentelemetry_build}/exporters/ostream/libopentelemetry_exporter_ostream_metrics${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(opentelemetry_prometheus_lib "${opentelemetry_build}/exporters/prometheus/libopentelemetry_exporter_prometheus${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(prometheuscpp_core_lib "${opentelemetry_build}/third_party/prometheus-cpp/lib/libprometheus-cpp-core${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(prometheuscpp_pull_lib "${opentelemetry_build}/third_party/prometheus-cpp/lib/libprometheus-cpp-pull${CMAKE_STATIC_LIBRARY_SUFFIX}")

set(opentelemetry_includes
  "${opentelemetry_src}/api/include"
  "${opentelemetry_src}/sdk/include"
  "${opentelemetry_src}/exporters/ostream/include"
  "${opentelemetry_src}/exporters/prometheus/include"
  "${opentelemetry_src}/third_party/prometheus-cpp/pull/include"
  "${opentelemetry_src}/third_party/prometheus-cpp/core/include"
  "${opentelemetry_build}/third_party/prometheus-cpp/pull/include"
  "${opentelemetry_build}/third_party/prometheus-cpp/core/include"
)

include(ExternalProject)

ExternalProject_Add(project_opentelemetry
  PREFIX            "${opentelemetry_ep}"
  BINARY_DIR        "${opentelemetry_build}"
  DOWNLOAD_COMMAND  ""
  CONFIGURE_COMMAND ""
  BUILD_COMMAND     ""
  INSTALL_COMMAND   ""
  BUILD_BYPRODUCTS  ${opentelemetry_metrics_lib} ${opentelemetry_resources_lib} ${opentelemetry_common_lib} ${opentelemetry_ostream_lib} ${opentelemetry_prometheus_lib} ${prometheuscpp_core_lib} ${prometheuscpp_pull_lib}
)

ExternalProject_Add_Step(project_opentelemetry project_opentelemetry_build_step
  COMMAND ${CMAKE_MAKE_PROGRAM}
  COMMENT "Building libopentelemetry"
  WORKING_DIRECTORY ${opentelemetry_build}
  ALWAYS 1
  USES_TERMINAL 1
)

if ( MSVC )
  set(OTHER_CONFIG -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DCMAKE_MSVC_RUNTIME_LIBRARY=${CMAKE_MSVC_RUNTIME_LIBRARY} -CMAKE_CXX_FLAGS=/std:c++17)
else()
  set(OTHER_CONFIG -DCMAKE_CXX_FLAGS=-std=c++17)
endif()

if ( CMAKE_TOOLCHAIN_FILE )
  set(toolchain_arg -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
else ()
  set(toolchain_arg)
endif ()

if ( CMAKE_C_COMPILER_LAUNCHER )
  set(cmake_c_compiler_launcher_arg
    -DCMAKE_C_COMPILER_LAUNCHER:path=${CMAKE_C_COMPILER_LAUNCHER})
else ()
  set(cmake_c_compiler_launcher_arg)
endif ()

if ( CMAKE_CXX_COMPILER_LAUNCHER )
  set(cmake_cxx_compiler_launcher_arg
    -DCMAKE_CXX_COMPILER_LAUNCHER:path=${CMAKE_CXX_COMPILER_LAUNCHER})
else ()
  set(cmake_cxx_compiler_launcher_arg)
endif ()

execute_process(
  COMMAND
  ${CMAKE_COMMAND}
  -G${CMAKE_GENERATOR}
  ${toolchain_arg}
  ${cmake_c_compiler_launcher_arg}
  ${cmake_cxx_compiler_launcher_arg}
  -DCMAKE_BUILD_TYPE:string=${CMAKE_BUILD_TYPE}
  -DWITH_BENCHMARK=NO
  -DBUILD_TESTING=NO
  -DWITH_EXAMPLES=NO
  -DWITH_STL=CXX17
  -DWITH_PROMETHEUS=YES
  ${OTHER_CONFIG}
  ${opentelemetry_src}
  WORKING_DIRECTORY ${opentelemetry_build}
  RESULT_VARIABLE opentelemetry_cmake_result
  ERROR_VARIABLE OPENTELEMETRY_CMAKE_OUTPUT
  OUTPUT_VARIABLE OPENTELEMETRY_CMAKE_OUTPUT
  ERROR_STRIP_TRAILING_WHITESPACE
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

message("\n********** Begin libopentelemetry External Project CMake Output ************")
message("\n${OPENTELEMETRY_CMAKE_OUTPUT}")
message("\n*********** End libopentelemetry External Project CMake Output *************")
message("\n")

if (opentelemetry_cmake_result)
  message(FATAL_ERROR "libopentelemetry CMake configuration failed")
endif ()

add_library(libopentelemetry_metrics_a STATIC IMPORTED)
set_property(TARGET libopentelemetry_metrics_a PROPERTY IMPORTED_LOCATION ${opentelemetry_metrics_lib})
add_dependencies(libopentelemetry_metrics_a project_opentelemetry)

add_library(libopentelemetry_resources_a STATIC IMPORTED)
set_property(TARGET libopentelemetry_resources_a PROPERTY IMPORTED_LOCATION ${opentelemetry_resources_lib})
add_dependencies(libopentelemetry_resources_a project_opentelemetry)

add_library(libopentelemetry_common_a STATIC IMPORTED)
set_property(TARGET libopentelemetry_common_a PROPERTY IMPORTED_LOCATION ${opentelemetry_common_lib})
add_dependencies(libopentelemetry_common_a project_opentelemetry)

add_library(libopentelemetry_ostream_a STATIC IMPORTED)
set_property(TARGET libopentelemetry_ostream_a PROPERTY IMPORTED_LOCATION ${opentelemetry_ostream_lib})
add_dependencies(libopentelemetry_ostream_a project_opentelemetry)

add_library(libopentelemetry_prometheus_a STATIC IMPORTED)
set_property(TARGET libopentelemetry_prometheus_a PROPERTY IMPORTED_LOCATION ${opentelemetry_prometheus_lib})
add_dependencies(libopentelemetry_prometheus_a project_opentelemetry)

add_library(prometheuscpp_core_a STATIC IMPORTED)
set_property(TARGET prometheuscpp_core_a PROPERTY IMPORTED_LOCATION ${prometheuscpp_core_lib})
add_dependencies(prometheuscpp_core_a project_opentelemetry)

add_library(prometheuscpp_pull_a STATIC IMPORTED)
set_property(TARGET prometheuscpp_pull_a PROPERTY IMPORTED_LOCATION ${prometheuscpp_pull_lib})
add_dependencies(prometheuscpp_pull_a project_opentelemetry)

set(HAVE_OPENTELEMETRY true)

set(LIBOPENTELEMETRY_LIBRARIES
    libopentelemetry_metrics_a
    libopentelemetry_resources_a
    libopentelemetry_common_a
    libopentelemetry_ostream_a
    libopentelemetry_prometheus_a
    prometheuscpp_pull_a
    prometheuscpp_core_a
  CACHE STRING "libopentelemetry libs" FORCE)
set(zeekdeps ${zeekdeps} ${LIBOPENTELEMETRY_LIBRARIES})

set(LIBOPENTELEMETRY_INCLUDE_DIRS ${opentelemetry_includes} CACHE INTERNAL "libopentelemetry includes" FORCE)
include_directories(BEFORE ${LIBOPENTELEMETRY_INCLUDE_DIRS})
