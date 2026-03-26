set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Prohibit in-source builds.
if ("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")
    message(
        FATAL_ERROR
            "In-source builds are not allowed. Please use "
            "./configure to choose a build directory and " "initialize the build configuration.")
endif ()

# Abort the configuration if no C or C++ compiler is found, depending
# on whether a previous call to the project() macro was supplied either
# language as a requirement.
if (NOT CMAKE_C_COMPILER AND DEFINED CMAKE_C_COMPILER)
    message(FATAL_ERROR "Could not find prerequisite C compiler")
endif ()

if (NOT CMAKE_CXX_COMPILER AND DEFINED CMAKE_CXX_COMPILER)
    message(FATAL_ERROR "Could not find prerequisite C++ compiler")
endif ()

if (WIN32 AND NOT CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    message(
        FATAL_ERROR "Could not find prerequisite C compiler for Windows platform. MSVC is required")
endif ()

if (WIN32 AND NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    message(
        FATAL_ERROR
            "Could not find prerequisite C++ compiler for Windows platform. MSVC is required")
endif ()

# Add an uninstall target if one isn't already defined.
if (NOT TARGET uninstall)
    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in")
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
                       "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake" @ONLY)
        add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P
                                            ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
    endif ()
endif ()

# Keep RPATH upon installing so that user doesn't have to ensure the linker
# can find internal/private libraries or libraries external to the build
# directory that were explicitly linked against
if (NOT BINARY_PACKAGING_MODE)
    include(GNUInstallDirs)

    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_FULL_LIBDIR}")
endif ()

# Set up the default flags and CMake build type once during the configuration
# of the top-level CMake project.
if (NOT MSVC and "${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    set(EXTRA_COMPILE_FLAGS "-Wall -Wno-unused -funsigned-char")
    set(EXTRA_COMPILE_FLAGS_CXX "-Wno-register -Werror=vla -funsigned-char")

    if (NOT CMAKE_BUILD_TYPE)
        if (ENABLE_DEBUG)
            set(CMAKE_BUILD_TYPE Debug)
        else ()
            set(CMAKE_BUILD_TYPE RelWithDebInfo)
        endif ()
    endif ()

    string(TOUPPER ${CMAKE_BUILD_TYPE} _build_type_upper)

    if ("${_build_type_upper}" STREQUAL "DEBUG")
        if (ENABLE_COVERAGE)
            set(EXTRA_COMPILE_FLAGS "${EXTRA_COMPILE_FLAGS} --coverage -fprofile-update=atomic")
            set(EXTRA_LD_FLAGS "${EXTRA_LD_FLAGS} --coverage -fprofile-update=atomic")
        endif ()
        # manual add of -g works around its omission in FreeBSD's CMake port
        set(EXTRA_COMPILE_FLAGS "${EXTRA_COMPILE_FLAGS} -g -DDEBUG -DBRO_DEBUG")
    endif ()

    # Compiler flags may already exist in CMake cache (e.g. when specifying
    # CFLAGS environment variable before running cmake for the the first time)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${EXTRA_COMPILE_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${EXTRA_COMPILE_FLAGS} ${EXTRA_COMPILE_FLAGS_CXX}")
endif ()

# ============================================================================
# MacDependencyPaths
# ============================================================================
# As of CMake 2.8.3, Fink and MacPorts search paths are appended to the
# default search prefix paths, but the nicer thing would be if they are
# prepended to the default, so that is fixed here.

# Prepend the default search path locations, in case for some reason the
# ports/brew/fink executables are not found.
# If they are found, the actual paths will be pre-pended again below.
list(PREPEND CMAKE_PREFIX_PATH /usr/local)
list(PREPEND CMAKE_PREFIX_PATH /opt/local)
list(PREPEND CMAKE_PREFIX_PATH /sw)

if (APPLE AND "${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    find_program(MAC_PORTS_BIN ports)
    find_program(MAC_HBREW_BIN brew)
    find_program(MAC_FINK_BIN fink)

    if (MAC_PORTS_BIN)
        list(PREPEND CMAKE_PREFIX_PATH ${MAC_PORTS_BIN}) # MacPorts
    endif ()

    if (MAC_HBREW_BIN)
        execute_process(COMMAND ${MAC_HBREW_BIN} "--prefix" OUTPUT_VARIABLE BREW_PREFIX
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        # Homebrew, if linked
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX})
        # Homebrew OpenSSL
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX}/opt/openssl)
        # Homebrew Bison
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX}/opt/bison/bin)
        # Homebrew Flex
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX}/opt/flex/bin)
        # Homebrew actor-framework
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX}/opt/actor-framework)
    endif ()

    if (MAC_FINK_BIN)
        list(PREPEND CMAKE_PREFIX_PATH /sw) # Fink
    endif ()

endif ()
