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

    OPTION (CARES_STATIC "" ON)
    OPTION (CARES_SHARED "" OFF)
    OPTION (CARES_INSTALL "" OFF)
    OPTION (CARES_STATIC_PIC "" ON)
    OPTION (CARES_BUILD_TESTS "" OFF)
    OPTION (CARES_BUILD_CONTAINER_TESTS "" OFF)
    OPTION (CARES_BUILD_TOOLS "" OFF)

    add_subdirectory(auxil/c-ares)

    set(cares_src   "${CMAKE_CURRENT_SOURCE_DIR}/auxil/c-ares")
    set(cares_build "${CMAKE_CURRENT_BINARY_DIR}/auxil/c-ares")
    set(cares_lib   "${cares_build}/${CMAKE_INSTALL_LIBDIR}/libcares.a")

    set(HAVE_CARES true)
    set(zeekdeps ${zeekdeps} ${cares_lib})
    include_directories(BEFORE ${cares_src}/include)
    include_directories(BEFORE ${cares_build})

  endif()
endif()

if ( NOT HAVE_CARES )
  message(FATAL_ERROR "Failed to find a working version of c-ares.")
endif()
