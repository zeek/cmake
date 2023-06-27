# Copyright (c) 2020-2021 by the Zeek Project. See LICENSE for details.
#
# CMake helpers to find Spicy and build Spicy code.
#
# To have this find the Spicy toolchain, either set PATH to contain
# spicy-config, set SPICY_ROOT_DIR to the Spicy installation, or set
# SPICY_CONFIG to the binary.
#
# Output:
#     SPICY_FOUND                 true if Spicy has been found
#
#     If SPICY_FOUND is true:
#
#         SPICYC                        full path to spicyc
#         SPICY_BUILD_MODE              Spicy's debug/release build mode
#         SPICY_INCLUDE_DIRS_RUNTIME    Spicy C++ include directories for the runtime
#         SPICY_INCLUDE_DIRS_TOOLCHAIN  Spicy C++ include directories for the toolchain
#         SPICY_CXX_LIBRARY_DIRS_TOOLCHAIN        Spicy C++ library directories
#         SPICY_CXX_LIBRARY_DIRS_RUNTIME        Spicy C++ library directories
#         SPICY_CXX_FLAGS               Spicy C++ flags with include directories
#         SPICY_PREFIX                  Spicy installation prefix
#         SPICY_VERSION                 Spicy version as a string
#         SPICY_VERSION_NUMBER          Spicy version as a numerical value
#         SPICY_CMAKE_PATH              Spicy cmake directory
#         SPICY_HAVE_TOOLCHAIN          True if the compiler is available

### Functions

# Configure build against Spicy.
macro (configure)
    ### Find spicy-config
    if (NOT SPICY_CONFIG)
        set(SPICY_CONFIG "$ENV{SPICY_CONFIG}")
    endif ()

    if (SPICY_CONFIG)
        if (EXISTS "${SPICY_CONFIG}")
            set(spicy_config "${SPICY_CONFIG}")
        else ()
            message(STATUS "'${SPICY_CONFIG}' does not exist")
        endif ()
    else ()
        # Attempt to find `spicy-config` only with configured paths.
        find_program(
            spicy_config spicy-config
            HINTS ${SPICY_ROOT_DIR}/bin
                  ${SPICY_ROOT_DIR}/build/bin
                  $ENV{SPICY_ROOT_DIR}/bin
                  $ENV{SPICY_ROOT_DIR}/build/bin
                  # Try build directory of Spicy distribution we may be part of.
                  ${PROJECT_SOURCE_DIR}/../../build/bin
            NO_DEFAULT_PATH)

        # If above search was not successful attempt to find the program in
        # builtin search paths. CMake's `find_program` will only execute a new
        # search if the output variable `spicy-config` is unset.
        find_program(spicy_config spicy-config)
    endif ()

    if (NOT spicy_config)
        message(STATUS "cannot determine location of Spicy installation")
        set(HAVE_SPICY no)
    else ()
        message(STATUS "Found spicy-config: ${spicy_config}")
        set(HAVE_SPICY yes)
        set(SPICY_CONFIG "${spicy_config}" CACHE FILEPATH "")

        ### Determine properties.

        run_spicy_config(SPICYC "--spicyc")
        run_spicy_config(SPICY_BUILD_MODE "--build")
        run_spicy_config(SPICY_PREFIX "--prefix")
        run_spicy_config(SPICY_VERSION "--version")
        run_spicy_config(SPICY_VERSION_NUMBER "--version-number")
        run_spicy_config(SPICY_CMAKE_PATH "--cmake-path")
        run_spicy_config(SPICY_HAVE_TOOLCHAIN "--have-toolchain")

        run_spicy_config(SPICY_INCLUDE_DIRS_RUNTIME --include-dirs)
        string(REPLACE " " ";" SPICY_INCLUDE_DIRS_RUNTIME "${SPICY_INCLUDE_DIRS_RUNTIME}")

        run_spicy_config(SPICY_LIBRARY_DIRS_RUNTIME --libdirs-cxx-runtime)
        string(REPLACE " " ";" SPICY_LIBRARY_DIRS_RUNTIME "${SPICY_LIBRARY_DIRS_RUNTIME}")

        run_spicy_config(SPICY_INCLUDE_DIRS_TOOLCHAIN --include-dirs-toolchain)
        string(REPLACE " " ";" SPICY_INCLUDE_DIRS_TOOLCHAIN "${SPICY_INCLUDE_DIRS_TOOLCHAIN}")

        run_spicy_config(SPICY_LIBRARY_DIRS_TOOLCHAIN --libdirs-cxx-toolchain)
        string(REPLACE " " ";" SPICY_LIBRARY_DIRS_TOOLCHAIN "${SPICY_LIBRARY_DIRS_TOOLCHAIN}")

        find_library(
            HILTI_LIBRARY
            NAMES hilti
            NO_DEFAULT_PATH
            HINTS "${SPICY_LIBRARY_DIRS_TOOLCHAIN}" "${SPICY_LIBRARY_DIRS_RUNTIME}")

        find_library(
            SPICY_LIBRARY
            NAMES spicy
            NO_DEFAULT_PATH
            HINTS "${SPICY_LIBRARY_DIRS_TOOLCHAIN}" "${SPICY_LIBRARY_DIRS_RUNTIME}")

        add_library(hilti SHARED IMPORTED GLOBAL)
        set_target_properties(hilti PROPERTIES IMPORTED_LOCATION "${HILTI_LIBRARY}")
        target_include_directories(hilti BEFORE INTERFACE ${HILTI_INCLUDE_DIRS_TOOLCHAIN}
                                                          ${HILTI_INCLUDE_DIRS_RUNTIME})

        add_library(spicy SHARED IMPORTED GLOBAL)
        set_target_properties(spicy PROPERTIES IMPORTED_LOCATION "${SPICY_LIBRARY}")
        target_include_directories(spicy BEFORE INTERFACE ${SPICY_INCLUDE_DIRS_TOOLCHAIN}
                                                          ${SPICY_INCLUDE_DIRS_RUNTIME})
    endif ()
endmacro ()

# Checks that the Spicy version it at least the given version.
function (spicy_require_version version)
    string(REGEX MATCH "([0-9]*)\.([0-9]*)\.([0-9]*).*" _ ${version})
    math(EXPR version_number "${CMAKE_MATCH_1} * 10000 + ${CMAKE_MATCH_2} * 100 + ${CMAKE_MATCH_3}")
    if ("${SPICY_VERSION_NUMBER}" LESS "${version_number}")
        message(
            FATAL_ERROR "Package requires at least Spicy version ${version}, have ${SPICY_VERSION}")
    endif ()
endfunction ()

# Helper to link with `--whole-archive/-force-load`.
#
# This is adapted from https://github.com/horance-liu/flink.cmake
#
# With CMake >= 3.24, we could instead use LINK_LIBRARY, see
# https://cmake.org/cmake/help/v3.24/manual/cmake-generator-expressions.7.html#genex:LINK_LIBRARY
macro (spicy_get_runtime_libraries out debug)
    if (debug)
        set(hilti_rt ${HILTI_LIBRARY_RT_DEBUG})
        set(spicy_rt ${SPICY_LIBRARY_RT_DEBUG})
    else ()
        set(hilti_rt ${HILTI_LIBRARY_RT})
        set(spicy_rt ${SPICY_LIBRARY_RT})
    endif ()

    if (MSVC)
        set(${out} "/WHOLEARCHIVE:${hilti_rt};/WHOLEARCHIVE:${spicy_rt}")
    elseif (APPLE)
        set(${out} "-Wl,-force_load;${hilti_rt};-Wl,-force_load;${spicy_rt}")
    else ()
        set(${out} "-Wl,--whole-archive;${hilti_rt};${spicy_rt};-Wl,--no-whole-archive")
    endif ()
endmacro ()

# Runs `spicy-config` and stores its result in the given output variable.
function (run_spicy_config output)
    execute_process(COMMAND "${spicy_config}" ${ARGN} OUTPUT_VARIABLE output_
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(STRIP "${output_}" output_)
    set(${output} "${output_}" PARENT_SCOPE)
endfunction ()

# Prints a summary of detected Spicy.
function (spicy_print_summary)
    message("\n====================|  Spicy Installation Summary  |====================" "\n"
            "\nFound Spicy:           ${HAVE_SPICY}")

    if (HAVE_SPICY)
        message(
            "\nVersion:               ${SPICY_VERSION} (${SPICY_VERSION_NUMBER})"
            "\nPrefix:                ${SPICY_PREFIX}"
            "\nBuild type:            ${SPICY_BUILD_MODE}"
            "\nHave toolchain:        ${SPICY_HAVE_TOOLCHAIN}"
            "\nSpicy compiler:        ${SPICYC}")
    else ()
        message(
            "\n    Make sure spicy-config is in your PATH, or set SPICY_CONFIG to its location.")
    endif ()

    message("\n========================================================================\n")
endfunction ()

### Main

if (NOT HAVE_SPICY)
    configure()
endif ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Spicy DEFAULT_MSG HAVE_SPICY SPICY_CONFIG)
