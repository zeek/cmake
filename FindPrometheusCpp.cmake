set(prometheuscpp_build   "${CMAKE_CURRENT_BINARY_DIR}/prometheus-cpp-build")
set(prometheuscpp_install "${CMAKE_CURRENT_BINARY_DIR}/prometheus-cpp-build")
set(prometheuscpp_src     "${CMAKE_CURRENT_SOURCE_DIR}/auxil/prometheus-cpp")

set(prometheuscpp_core_lib "${prometheuscpp_build}/lib/libprometheus-cpp-core${CMAKE_STATIC_LIBRARY_SUFFIX}")
set(prometheuscpp_pull_lib "${prometheuscpp_build}/lib/libprometheus-cpp-pull${CMAKE_STATIC_LIBRARY_SUFFIX}")

set(prometheuscpp_includes
  "${prometheuscpp_src}/pull/include"
  "${prometheuscpp_src}/core/include"
  "${prometheuscpp_build}/pull/include"
  "${prometheuscpp_build}/core/include"
)

include(ExternalProject)

ExternalProject_Add(project_prometheuscpp
  PREFIX            "${prometheuscpp_ep}"
  BINARY_DIR        "${prometheuscpp_build}"
  DOWNLOAD_COMMAND  ""
  CONFIGURE_COMMAND ""
  BUILD_COMMAND     ""
  INSTALL_COMMAND   ""
  BUILD_BYPRODUCTS  ${prometheuscpp_core_lib} ${prometheuscpp_pull_lib}
)

ExternalProject_Add_Step(project_prometheuscpp project_prometheuscpp_build_step
  COMMAND ${CMAKE_MAKE_PROGRAM}
  COMMENT "Building libprometheuscpp"
  WORKING_DIRECTORY ${prometheuscpp_build}
  ALWAYS 1
  USES_TERMINAL 1
)

if ( MSVC )
  set(OTHER_CONFIG -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DCMAKE_MSVC_RUNTIME_LIBRARY=${CMAKE_MSVC_RUNTIME_LIBRARY})
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
  -DENABLE_PUSH=OFF
  -DENABLE_TESTING=OFF
  -DGENERATE_PKGCONFIG=OFF
  ${OTHER_CONFIG}
  ${prometheuscpp_src}
  WORKING_DIRECTORY ${prometheuscpp_build}
  RESULT_VARIABLE prometheuscpp_cmake_result
  ERROR_VARIABLE PROMETHEUSCPP_CMAKE_OUTPUT
  OUTPUT_VARIABLE PROMETHEUSCPP_CMAKE_OUTPUT
  ERROR_STRIP_TRAILING_WHITESPACE
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

message("\n********** Begin prometheus-cpp External Project CMake Output ************")
message("\n${PROMETHEUSCPP_CMAKE_OUTPUT}")
message("\n*********** End promtheus-cpp External Project CMake Output *************")
message("\n")

if (prometheuscpp_cmake_result)
  message(FATAL_ERROR "prometheus-cpp CMake configuration failed")
endif ()

add_library(prometheuscpp_core_a STATIC IMPORTED)
set_property(TARGET prometheuscpp_core_a PROPERTY IMPORTED_LOCATION ${prometheuscpp_core_lib})
add_dependencies(prometheuscpp_core_a project_prometheuscpp)

add_library(prometheuscpp_pull_a STATIC IMPORTED)
set_property(TARGET prometheuscpp_pull_a PROPERTY IMPORTED_LOCATION ${prometheuscpp_pull_lib})
add_dependencies(prometheuscpp_pull_a project_prometheuscpp)

set(HAVE_PROMETHEUSCPP true)

set(PROMETHEUSCPP_LIBRARIES
    prometheuscpp_core_a
    prometheuscpp_pull_a
  CACHE STRING "prometheuscpp libs" FORCE)
set(zeekdeps ${zeekdeps} ${PROMETHEUSCPP_LIBRARIES})

set(PROMETHEUSCPP_INCLUDE_DIRS ${prometheuscpp_includes} CACHE INTERNAL "prometheuscpp includes" FORCE)
include_directories(BEFORE ${PROMETHEUSCPP_INCLUDE_DIRS})
