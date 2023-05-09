include(CheckFunctionExists)

# First check whether the system has cares built-in. Prefer that over everything else.
check_function_exists(ares_init HAVE_CARES)

if (NOT HAVE_CARES)

    # If the user passed in a path for cares, see if we can find a copy of it there.
    # If they didn't pass one, build our local copy of it.
    if (CARES_ROOT_DIR)

        find_path(CARES_ROOT_DIR NAMES "include/ares.h")

        # Prefer linking statically but look for a shared library version too.
        find_library(CARES_LIBRARIES NAMES libcares_static.a libcares.so
                     HINTS ${CARES_ROOT_DIR}/lib)

        find_path(CARES_INCLUDE_DIRS NAMES "ares.h" HINTS ${CARES_ROOT_DIR}/include)

        include(FindPackageHandleStandardArgs)
        find_package_handle_standard_args(CARES DEFAULT_MSG CARES_LIBRARIES CARES_INCLUDE_DIRS)

        mark_as_advanced(CARES_ROOT_DIR CARES_LIBRARIES CARES_INCLUDE_DIRS)

        set(HAVE_CARES true)
        set(zeekdeps ${zeekdeps} ${CARES_LIBRARIES})
        include_directories(BEFORE ${CARES_INCLUDE_DIRS})

    else ()

        option(CARES_STATIC "" ON)
        option(CARES_SHARED "" OFF)
        option(CARES_INSTALL "" OFF)
        option(CARES_STATIC_PIC "" ON)
        option(CARES_BUILD_TESTS "" OFF)
        option(CARES_BUILD_CONTAINER_TESTS "" OFF)
        option(CARES_BUILD_TOOLS "" OFF)

        set(cares_src "${CMAKE_CURRENT_SOURCE_DIR}/auxil/c-ares")
        set(cares_build "${CMAKE_CURRENT_BINARY_DIR}/auxil/c-ares")
        set(cares_lib c-ares::cares_static)

        # For reasons we haven't been able to determine, systems with c-ares already
        # installed will sometimes add /usr/local/include to the include path with
        # the call to add_subdirectory() below, which breaks things since it tries
        # use those versions of the c-ares headers before the local ones. I think
        # this is tied to a bug in c-ares 1.17.1 but we never nailed it down to that.
        # Instead, ensure that the local paths end up in the include path before
        # anything c-ares adds.
        include_directories(BEFORE ${cares_src}/include)
        include_directories(BEFORE ${cares_build})

        add_subdirectory(auxil/c-ares)

        set(HAVE_CARES true)
        set(zeekdeps ${zeekdeps} ${cares_lib})

    endif ()
endif ()

if (NOT HAVE_CARES)
    message(FATAL_ERROR "Failed to find a working version of c-ares.")
endif ()
