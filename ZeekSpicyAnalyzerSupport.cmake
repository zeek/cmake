# Copyright (c) 2020-2021 by the Zeek Project. See LICENSE for details.
#
# Helpers for building analyzers. This is can be included from analyzer packages.
#
# Needs SPICYZ to point to the "spicyz" binary in either CMake or environment.

include(GNUInstallDirs)

# Add target to build an analyzer.
#
# Usage:
#
#     spicy_add_analyzer(
#         NAME <analyzer_name>
#         [SOURCES <source files for spicyz>...]
#         [PACKAGE_NAME <package_name>]
#         [SCRIPTS <additional script files to install>...]
#         [CXX_LINK <libraries to link>...]
#         [ENV <environment variable=value>...]
#     )
function (spicy_add_analyzer)
    set(options)
    set(oneValueArgs NAME PACKAGE_NAME)
    set(multiValueArgs ENV SOURCES SCRIPTS CXX_LINK)

    cmake_parse_arguments(PARSE_ARGV 0 SPICY_ANALYZER "${options}" "${oneValueArgs}"
                          "${multiValueArgs}")

    # We also support the legacy behavior where the first arg is
    # the analyzer NAME and all remaining arguments are SOURCES.
    if (SPICY_ANALYZER_UNPARSED_ARGUMENTS)
        if (SPICY_ANALYZER_NAME OR SPICY_ANALYZER_SOURCES OR SPICY_ANALYZER_SCRIPTS)
            message(FATAL_ERROR "named an unnamed arguments cannot be mixed")
        endif ()

        list(GET ARGN 0 SPICY_ANALYZER_NAME)
        list(POP_FRONT ARGN)

        set(SPICY_ANALYZER_SOURCES ${ARGN})
    endif ()

    if (NOT DEFINED SPICY_ANALYZER_NAME)
        message(FATAL_ERROR "NAME is required")
    endif ()

    string(TOLOWER "${SPICY_ANALYZER_NAME}" NAME_LOWER)
    set(OUTPUT "${SPICY_MODULE_OUTPUT_DIR_BUILD}/${NAME_LOWER}.hlto")

    # list(TRANSFORM SPICY_ANALYZER_CXX_LINK PREPEND "--cxx-link ")
    foreach (cxx_link ${SPICY_ANALYZER_CXX_LINK})
        list(APPEND CXX_LINK "--cxx-link")
        list(APPEND CXX_LINK ${cxx_link})
    endforeach ()

    # Create a link for backwards compatibility with older zkg packages.
    file(CREATE_LINK "." ${SPICY_MODULE_OUTPUT_DIR_BUILD}/spicy-modules SYMBOLIC)

    add_custom_command(
        OUTPUT ${OUTPUT}
        DEPENDS ${SPICY_ANALYZER_SOURCES} spicyz ${SPICY_ANALYZER_CXX_LINK}
        COMMENT "Compiling ${SPICY_ANALYZER_NAME} analyzer"
        COMMAND
            ${CMAKE_COMMAND} -E env ASAN_OPTIONS=$ENV{ASAN_OPTIONS}:detect_leaks=0
            ${SPICY_ANALYZER_ENV} spicyz -o ${OUTPUT} ${_SPICYZ_FLAGS} ${SPICY_ANALYZER_SOURCES}
            ${CXX_LINK}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

    add_custom_target(${SPICY_ANALYZER_NAME} ALL DEPENDS ${OUTPUT}
                      COMMENT "Preparing dependencies of ${SPICY_ANALYZER_NAME}")

    if (SPICY_MODULE_OUTPUT_DIR_INSTALL)
        install(FILES ${OUTPUT} DESTINATION "${SPICY_MODULE_OUTPUT_DIR_INSTALL}")
    endif ()

    if (SPICY_SCRIPTS_OUTPUT_DIR_INSTALL AND DEFINED SPICY_ANALYZER_SCRIPTS)
        if (NOT DEFINED SPICY_ANALYZER_PACKAGE_NAME)
            message(FATAL_ERROR "SCRIPTS argument requires PACKAGE_NAME")
        endif ()
        install(
            FILES ${SPICY_ANALYZER_SCRIPTS}
            DESTINATION
                "${SPICY_SCRIPTS_OUTPUT_DIR_INSTALL}/${SPICY_ANALYZER_PACKAGE_NAME}/${NAME_LOWER}")
    endif ()

    get_property(tmp GLOBAL PROPERTY __spicy_included_analyzers)
    list(APPEND tmp "${SPICY_ANALYZER_NAME}")
    set_property(GLOBAL PROPERTY __spicy_included_analyzers "${tmp}")
endfunction ()

# Flag that analyzer is *not* being built. This is purely informational:
# the cmake output will contain a corresponding note. Arguments are the
# name of the analyzers and a descriptive string explaining why it's
# being skipped.
function (spicy_skip_analyzer name reason)
    get_property(tmp GLOBAL PROPERTY __spicy_skipped_analyzers)
    list(APPEND tmp "${name} ${reason}")
    set_property(GLOBAL PROPERTY __spicy_skipped_analyzers "${tmp}")
endfunction ()

# Prints a summary of configured analyzers.
function (print_analyzers)
    message("\n======================|  Spicy Analyzer Summary  |======================")

    message(
        "\nspicy-config:          ${SPICY_CONFIG}"
        "\nzeek-config:           ${ZEEK_CONFIG}"
        "\nSpicy compiler:        ${SPICYZ}"
        "\nModule directory:      ${SPICY_MODULE_OUTPUT_DIR_INSTALL}"
        "\nScripts directory:     ${SPICY_SCRIPTS_OUTPUT_DIR_INSTALL}"
        "\nPlugin version:        "
        "${ZEEK_SPICY_PLUGIN_VERSION} (${ZEEK_SPICY_PLUGIN_VERSION_NUMBER})")

    if (NOT SPICYZ)
        message("\n    Make sure spicyz is in your PATH, or set SPICYZ to its location.")
    endif ()

    get_property(included GLOBAL PROPERTY __spicy_included_analyzers)
    message("\nAvailable analyzers:\n")
    foreach (x ${included})
        message("    ${x}")
    endforeach ()

    get_property(skipped GLOBAL PROPERTY __spicy_skipped_analyzers)
    if (skipped)
        message("\nSkipped analyzers:\n")
        foreach (x ${skipped})
            message("    ${x}")
        endforeach ()
    endif ()

    message("\n========================================================================\n")
endfunction ()

### Main

set(SPICYZ_FLAGS "" CACHE STRING "Additional flags for spicyz")

set_property(GLOBAL PROPERTY __spicy_included_analyzers)
set_property(GLOBAL PROPERTY __spicy_skipped_analyzers)

if (NOT SPICYZ)
    set(SPICYZ "$ENV{SPICYZ}")
endif ()

if (SPICYZ)
    message(STATUS "Using spicyz: ${SPICYZ}")

    add_executable(spicyz IMPORTED)
    set_property(TARGET spicyz PROPERTY IMPORTED_LOCATION "${SPICYZ}")

    string(REPLACE " " ";" _SPICYZ_FLAGS "${SPICYZ_FLAGS}")

    # Allow passing further SPICYZ_FLAGS via environment variable.
    string(REPLACE " " ";" _spicyz_flags_env "$ENV{SPICYZ_FLAGS}")
    if (_spicyz_flags_env)
        list(APPEND _SPICYZ_FLAGS ${_spicyz_flags_env})
    endif ()

    if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        list(APPEND _SPICYZ_FLAGS "-d")
    endif ()

    message(STATUS "Using spicyz with flags: ${_SPICYZ_FLAGS}")

    set(SPICY_MODULE_OUTPUT_DIR_BUILD "${PROJECT_BINARY_DIR}")

    execute_process(COMMAND "${SPICYZ}" "--print-module-path" OUTPUT_VARIABLE output
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(SPICY_MODULE_OUTPUT_DIR_INSTALL "${output}" CACHE STRING "")

    execute_process(COMMAND "${SPICYZ}" "--version" OUTPUT_VARIABLE output
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ZEEK_SPICY_PLUGIN_VERSION "${output}" CACHE STRING "")

    execute_process(COMMAND "${SPICYZ}" "--version-number" OUTPUT_VARIABLE output
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ZEEK_SPICY_PLUGIN_VERSION_NUMBER "${output}" CACHE STRING "")
else ()
    message(WARNING "spicyz: not specified")
endif ()
