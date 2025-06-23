# Add target to build an analyzer.
#
# Usage:
#
#     spicy_add_analyzer(
#         NAME <analyzer_name>
#         SOURCES <source files for spicyz>...
#         [MODULES <module names>...]
#     )
#
# `MODULES` can be used to specify which modules are part of this this
# analyzer. If not specified, its values is assumed to be identical to `NAME`.

set(ZEEK_LEGACY_ANALYZERS CACHE INTERNAL "")
set(ZEEK_SKIPPED_ANALYZERS CACHE INTERNAL "")

# Force Spicy include directories to the front of the include paths.
#
# While in principal we could use normal CMake target-based dependencies to
# inherit Spicy include directories if not building against an external Spicy,
# this still only appends include directories to the end of the list of include
# paths. This means that if any include prefix added before also contains
# another Spicy installation (possible if e.g., a required dependency was
# installed into a prefix which contains another Spicy installation) we prefer
# picking up that one when searching for a Spicy header. This functions
# explicitly pushes Spicy include directories to the front.
function (prefer_configured_spicy_include_dirs target)
    # Nothing to do if we are building against an externally built Spicy.
    if (SPICY_ROOT_DIR)
        return()
    endif ()

    foreach (_lib IN ITEMS hilti-rt-objects spicy-rt-objects hilti-objects spicy-objects)
        get_target_property(_inc_dirs ${_lib} INCLUDE_DIRECTORIES)
        target_include_directories(${target} BEFORE PRIVATE ${_inc_dirs})
    endforeach ()
endfunction ()

function (spicy_add_analyzer)
    set(options)
    set(oneValueArgs NAME LEGACY)
    set(multiValueArgs SOURCES MODULES)

    cmake_parse_arguments(PARSE_ARGV 0 SPICY_ANALYZER "${options}" "${oneValueArgs}"
                          "${multiValueArgs}")

    if (NOT DEFINED SPICY_ANALYZER_NAME)
        message(FATAL_ERROR "NAME is required")
    endif ()

    if (USE_SPICY_ANALYZERS)
        set(SPICYZ_FLAGS "")
        string(TOLOWER "${SPICY_ANALYZER_NAME}" NAME_LOWER)

        set(generated_sources ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}___linker__.cc
                              ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}_spicy_init.cc)

        # CXX files given to SOURCES are added to the lib target
        # separately from generated_sources.
        set(cxx_sources ${SPICY_ANALYZER_SOURCES})
        list(FILTER cxx_sources INCLUDE REGEX ".*\.cc$")

        if (NOT DEFINED SPICY_ANALYZER_MODULES)
            list(APPEND generated_sources
                 ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}_${SPICY_ANALYZER_NAME}.cc)
            list(APPEND generated_sources
                 ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}_spicy_hooks_${SPICY_ANALYZER_NAME}.cc)
        else ()
            foreach (module ${SPICY_ANALYZER_MODULES})
                list(APPEND generated_sources
                     ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}_${module}.cc)
                list(APPEND generated_sources
                     ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}_spicy_hooks_${module}.cc)
            endforeach ()
        endif ()

        if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.27")
            set_source_files_properties(${generated_sources} PROPERTIES SKIP_LINTING ON)
        endif ()

        add_custom_command(
            OUTPUT ${generated_sources}
            DEPENDS ${SPICY_ANALYZER_SOURCES} spicyz
            COMMENT "Compiling ${SPICY_ANALYZER_NAME} analyzer"
            COMMAND
                ${CMAKE_COMMAND} -E env
                "ZEEK_SPICY_LIBRARY_PATH=${PROJECT_SOURCE_DIR}/scripts/spicy"
                ASAN_OPTIONS=$ENV{ASAN_OPTIONS}:detect_leaks=0 $<TARGET_FILE:spicyz> -L
                ${spicy_SOURCE_DIR}/hilti/lib -L ${spicy_SOURCE_DIR}/spicy/lib -x
                ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER} ${SPICYZ_FLAGS} ${SPICY_ANALYZER_SOURCES}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

        set(lib "spicy_${SPICY_ANALYZER_NAME}")
        add_library(${lib} OBJECT ${generated_sources} ${cxx_sources})
        target_compile_features(${lib} PRIVATE cxx_std_20)
        set_target_properties(${lib} PROPERTIES CXX_EXTENSIONS OFF)

        target_include_directories(${lib} PRIVATE ${SPICY_PLUGIN_PATH}/include
                                                  ${SPICY_PLUGIN_BINARY_PATH}/include)
        target_compile_definitions(${lib} PRIVATE HILTI_MANUAL_PREINIT)
        target_link_libraries(${lib} hilti spicy $<BUILD_INTERFACE:zeek_internal>)
        prefer_configured_spicy_include_dirs(${lib})

        # Feed into the main Zeek target(s).
        zeek_target_link_libraries(${lib})

        if (SPICY_ROOT_DIR)
            target_include_directories(${lib} PRIVATE ${SPICY_ROOT_DIR}/include)
        endif ()

        # Install Spicy grammars into a default search path of Spicy.
        # This allows users importing the file relatively easily.
        set(_SPIYC_SOURCES ${SPICY_ANALYZER_SOURCES})
        list(FILTER _SPIYC_SOURCES INCLUDE REGEX "\.spicy$")
        install(FILES ${_SPIYC_SOURCES} DESTINATION ${CMAKE_INSTALL_DATADIR}/spicy/${NAME_LOWER})

    elseif (SPICY_ANALYZER_LEGACY)
        message(
            STATUS
                "Warning: Using unmaintained legacy analyzer for ${SPICY_ANALYZER_NAME} because Spicy is not available"
        )
        list(APPEND ZEEK_LEGACY_ANALYZERS "${SPICY_ANALYZER_NAME}")
        set(ZEEK_LEGACY_ANALYZERS "${ZEEK_LEGACY_ANALYZERS}" CACHE INTERNAL "")
        add_subdirectory(legacy)
    else ()
        message(
            STATUS
                "Warning: Disabling analyzer for ${SPICY_ANALYZER_NAME} because Spicy is not available"
        )
        list(APPEND ZEEK_SKIPPED_ANALYZERS "${SPICY_ANALYZER_NAME}")
        set(ZEEK_SKIPPED_ANALYZERS "${ZEEK_SKIPPED_ANALYZERS}" CACHE INTERNAL "")
    endif ()

endfunction ()
