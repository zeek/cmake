# Set up the default flags and CMake build type once during the configuration
# of the top-level CMake project.
if ("${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    set(EXTRA_COMPILE_FLAGS "-Wall -Wno-unused")

    if (ENABLE_DEBUG)
        set(CMAKE_BUILD_TYPE Debug)
        # manual add of -g works around its omission in FreeBSD's CMake port
        set(EXTRA_COMPILE_FLAGS "${EXTRA_COMPILE_FLAGS} -g -DDEBUG -DBRO_DEBUG")
    else ()
        set(CMAKE_BUILD_TYPE RelWithDebInfo)
    endif ()

    # Compiler flags may already exist in CMake cache (e.g. when specifying
    # CFLAGS environment variable before running cmake for the the first time)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${EXTRA_COMPILE_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${EXTRA_COMPILE_FLAGS}")
endif ()
