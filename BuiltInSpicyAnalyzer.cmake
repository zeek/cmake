# Add target to build an analyzer.
#
# Usage:
#
#     spicy_add_analyzer(
#         NAME <analyzer_name>
#         SOURCES <source files for spicyz>...
#     )

set(ZEEK_LEGACY_ANALYZERS CACHE INTERNAL "")
set(ZEEK_SKIPPED_ANALYZERS CACHE INTERNAL "")

# Force Spicy include directories to the front of the include paths.
#
# While we can use normal CMake target-based dependencies to inherit Spicy
# include directories, this still only appends include directories to the end
# of the list of include paths. This means that if any include prefix added
# before also contains another Spicy installation (possible if e.g., a required
# dependency was installed into a prefix which contains another Spicy
# installation) we prefer picking up that one when searching for a Spicy
# header. This functions explicitly pushes Spicy include directories to the
# front.
function (prefer_configured_spicy_include_dirs target)
    foreach (_lib IN ITEMS hilti-rt-objects spicy-rt-objects hilti-objects spicy-objects)
        get_target_property(_inc_dirs ${_lib} INCLUDE_DIRECTORIES)
        target_include_directories(${target} BEFORE PRIVATE ${_inc_dirs})
    endforeach ()
endfunction ()

function (spicy_add_analyzer)
    set(options)
    set(oneValueArgs NAME LEGACY)
    set(multiValueArgs SOURCES)

    cmake_parse_arguments(PARSE_ARGV 0 SPICY_ANALYZER "${options}" "${oneValueArgs}"
                          "${multiValueArgs}")

    if (NOT DEFINED SPICY_ANALYZER_NAME)
        message(FATAL_ERROR "NAME is required")
    endif ()

    if (USE_SPICY_ANALYZERS)
        set(SPICYZ_FLAGS "")
        string(TOLOWER "${SPICY_ANALYZER_NAME}" NAME_LOWER)

        set(generated_sources
            ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}_${SPICY_ANALYZER_NAME}.cc
            ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}___linker__.cc
            ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}_spicy_init.cc
            ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER}_spicy_hooks_${SPICY_ANALYZER_NAME}.cc)

        add_custom_command(
            OUTPUT ${generated_sources}
            DEPENDS ${SPICY_ANALYZER_SOURCES} spicyz
            COMMENT "Compiling ${SPICY_ANALYZER_NAME} analyzer"
            COMMAND
                ${CMAKE_COMMAND} -E env
                "ZEEK_SPICY_LIBRARY_PATH=${PROJECT_SOURCE_DIR}/scripts/spicy" $<TARGET_FILE:spicyz>
                -L ${spicy_SOURCE_DIR}/hilti/lib -L ${spicy_SOURCE_DIR}/spicy/lib -x
                ${CMAKE_CURRENT_BINARY_DIR}/${NAME_LOWER} ${SPICYZ_FLAGS} ${SPICY_ANALYZER_SOURCES}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

        set(lib "spicy_${SPICY_ANALYZER_NAME}")
        add_library(${lib} OBJECT ${generated_sources})
        target_compile_features(${lib} PRIVATE cxx_std_17)
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
