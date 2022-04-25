include(CheckFunctionExists)

# First check whether the system has cares built-in. Prefer that over everything else.
check_function_exists(ares_init HAVE_CARES)

if ( NOT HAVE_CARES )

  # If the user passed in a path for cares, see if we can find a copy of it there.
  # If they didn't pass one, build our local copy of it.
  if ( CARES_ROOT_DIR )

    find_path(CARES_ROOT_DIR
      NAMES "include/ares.h")

    # Prefer linking statically but look for a shared library version too.
    find_library(CARES_LIBRARIES
      NAMES libcares_static.a libcares.so
      HINTS ${CARES_ROOT_DIR}/lib)

    find_path(CARES_INCLUDE_DIRS
      NAMES "ares.h"
      HINTS ${CARES_ROOT_DIR}/include)

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(CARES DEFAULT_MSG
      CARES_LIBRARIES
      CARES_INCLUDE_DIRS
      )

    mark_as_advanced(
      CARES_ROOT_DIR
      CARES_LIBRARIES
      CARES_INCLUDE_DIRS
      )

    set(HAVE_CARES true)
    set(zeekdeps ${zeekdeps} ${CARES_LIBRARIES})
    include_directories(BEFORE ${CARES_INCLUDE_DIRS})

  else()

    include(ExternalProject)
    include(GNUInstallDirs)

    set(cares_src     "${CMAKE_CURRENT_SOURCE_DIR}/auxil/c-ares")
    set(cares_ep      "${CMAKE_CURRENT_BINARY_DIR}/cares-ep")
    set(cares_build   "${CMAKE_CURRENT_BINARY_DIR}/cares-build")
    set(cares_static  "${cares_build}/${CMAKE_INSTALL_LIBDIR}/libcares${CMAKE_STATIC_LIBRARY_SUFFIX}")

    set(build_byproducts_arg BUILD_BYPRODUCTS ${cares_static})

    ExternalProject_Add(project_cares
      PREFIX            "${cares_ep}"
      BINARY_DIR        "${cares_build}"
      DOWNLOAD_COMMAND  ""
      CONFIGURE_COMMAND ""
      BUILD_COMMAND     ""
      INSTALL_COMMAND   ""
      ${build_byproducts_arg}
      )

    set(use_terminal_arg USES_TERMINAL 1)

    ExternalProject_Add_Step(project_cares project_cares_build_step
      COMMAND ${CMAKE_MAKE_PROGRAM}
      COMMENT "Building c-ares"
      WORKING_DIRECTORY ${cares_build}
      ALWAYS 1
      ${use_terminal_arg}
      )

    set(cares_cmake_flags "")
    list(APPEND cares_cmake_flags -DCMAKE_BUILD_TYPE:string=${CMAKE_BUILD_TYPE})
    list(APPEND cares_cmake_flags -DCARES_SHARED=no)
    list(APPEND cares_cmake_flags -DCARES_STATIC=yes)
    list(APPEND cares_cmake_flags -DCARES_STATIC_PIC=yes)
    list(APPEND cares_cmake_flags -DCARES_INSTALL=no)
    list(APPEND cares_cmake_flags -DCARES_BUILD_TOOLS=no)

    if ( CMAKE_TOOLCHAIN_FILE )
      list(APPEND cares_cmake_flags -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
    endif ()

    if ( CMAKE_C_COMPILER_LAUNCHER )
      list(APPEND cares_cmake_flags
        -DCMAKE_C_COMPILER_LAUNCHER:path=${CMAKE_C_COMPILER_LAUNCHER})
    endif ()

    if ( CMAKE_CXX_COMPILER_LAUNCHER )
      list(APPEND cares_cmake_flags
        -DCMAKE_CXX_COMPILER_LAUNCHER:path=${CMAKE_CXX_COMPILER_LAUNCHER})
    endif ()

    if ( CMAKE_INSTALL_PREFIX )
      list(APPEND cares_cmake_flags
	-DCMAKE_INSTALL_PREFIX:path=${CMAKE_INSTALL_PREFIX})
    endif ()

    execute_process(
      COMMAND
      ${CMAKE_COMMAND}
      -G${CMAKE_GENERATOR}
      ${cares_cmake_flags}
      ${cares_src}
      WORKING_DIRECTORY ${cares_build}
      RESULT_VARIABLE cares_cmake_result
      ERROR_VARIABLE CARES_CMAKE_OUTPUT
      OUTPUT_VARIABLE CARES_CMAKE_OUTPUT
      ERROR_STRIP_TRAILING_WHITESPACE
      OUTPUT_STRIP_TRAILING_WHITESPACE
      )

    message("\n********** Begin c-ares External Project CMake Output ************")
    message("\n${CARES_CMAKE_OUTPUT}")
    message("\n*********** End c-ares External Project CMake Output *************")
    message("\n")

    if (cares_cmake_result)
      message(FATAL_ERROR "c-ares CMake configuration failed")
    endif ()

    add_library(cares_a STATIC IMPORTED)
    set_property(TARGET cares_a PROPERTY IMPORTED_LOCATION ${cares_static})
    add_dependencies(cares_a project_cares)

    set(HAVE_CARES true)
    set(CARES_LIBRARIES cares_a CACHE STRING "cares libs" FORCE)
    set(CARES_INCLUDE_DIRS "${cares_src}/include;${cares_build}/include;${cares_build}" CACHE INTERNAL "cares includes" FORCE)

    include_directories(BEFORE ${CARES_INCLUDE_DIRS})
    set(zeekdeps ${zeekdeps} ${CARES_LIBRARIES})

  endif()
endif()

if ( NOT HAVE_CARES )
  message(FATAL_ERROR "Failed to find a working version of c-ares.")
endif()
