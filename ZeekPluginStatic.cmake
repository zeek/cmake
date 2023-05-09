include(BifCl)
include(BinPAC)
include(FindClangTidy)

# Sets `target` to contain the CMake target name for a static plugin.
macro (zeek_get_static_plugin_target target ns name)
    set(${target} "plugin-${ns}-${name}")
endmacro ()

# Implements the statically linked version of zeek_add_plugin.
function (zeek_add_static_plugin ns name)
    # Helper variables.
    zeek_get_static_plugin_target(target_name ${ns} ${name})
    set(full_name "${ns}::${name}")
    set(canon_name "${ns}_${name}")

    # Create the target if no begin function has been used.
    if (NOT TARGET ${target_name})
        add_library(${target_name} OBJECT)
    endif ()
    add_dependencies(${target_name} zeek_autogen_files)

    # Skip zeek-version.h when including zeek-config.h for statically build
    # plugins (they are always builtin) *except* if the current scope is tagged
    # with ZEEK_BUILDING_EXTRA_PLUGINS (this is the case when building plugins
    # from BUILTIN_PLUGIN_LIST).
    if (NOT ZEEK_BUILDING_EXTRA_PLUGINS)
        target_compile_definitions(${target_name} PRIVATE ZEEK_CONFIG_SKIP_VERSION_H)
    endif ()

    # Parse arguments (note: DIST_FILES are ignored in static builds).
    set(fn_varargs INCLUDE_DIRS DEPENDENCIES SOURCES BIFS DIST_FILES PAC)
    cmake_parse_arguments(FN_ARGS "" "" "${fn_varargs}" ${ARGN})

    # Take care of compiling BIFs.
    if (FN_ARGS_BIFS)
        # Generate the targets and add the .cc files.
        foreach (bif ${FN_ARGS_BIFS})
            bif_target(${bif} "plugin" ${full_name} ${canon_name} ON)
            target_sources(${target_name} PRIVATE ${BIF_OUTPUT_CC})
        endforeach ()
    endif ()

    # Take care of PAC files.
    zeek_next_pac_block(at_end pacInputs pacRemainder ${ARGN})
    while (NOT at_end)
        binpac_target(${pacInputs})
        target_sources(${target_name} PRIVATE ${BINPAC_OUTPUT_CC})
        zeek_next_pac_block(at_end pacInputs pacRemainder ${pacRemainder})
    endwhile ()

    # Pass compiler flags, paths and dependencies to the target.
    target_link_libraries(${target_name} PRIVATE $<BUILD_INTERFACE:zeek_internal>)
    target_include_directories(${target_name} PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

    # Per convention, plugins have their headers and sources under src/ and
    # legacy/external plugins expect this to auto-magically be available as
    # include path.
    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src)
        target_include_directories(${target_name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
    endif ()

    # Add extra dependencies.
    if (FN_ARGS_DEPENDENCIES)
        target_link_libraries(${target_name} PUBLIC ${FN_ARGS_DEPENDENCIES})
    endif ()

    # Add the sources for the plugin.
    if (FN_ARGS_SOURCES)
        target_sources(${target_name} PRIVATE ${FN_ARGS_SOURCES})
        add_clang_tidy_files(${FN_ARGS_SOURCES})
    endif ()

    # Setup for the load/preload scripts.
    set(preload_script ${canon_name}/__preload__.zeek)
    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/scripts/__preload__.zeek)
        file(APPEND ${CMAKE_BINARY_DIR}/scripts/builtin-plugins/__preload__.zeek
             "\n@load ${preload_script}")
    endif ()
    set(load_script ${canon_name}/__load__.zeek)
    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/scripts/__load__.zeek)
        file(APPEND ${CMAKE_BINARY_DIR}/scripts/builtin-plugins/__load__.zeek
             "\n@load ${load_script}")
    endif ()

    # Install the scripts.
    get_filename_component(plugin_name ${CMAKE_CURRENT_SOURCE_DIR} NAME)
    if (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/scripts")
        install(
            DIRECTORY ./scripts/
            DESTINATION "${ZEEK_SCRIPT_INSTALL_PATH}/builtin-plugins/${_plugin_name_canon}"
            FILES_MATCHING
            PATTERN "*.zeek"
            PATTERN "*.sig"
            PATTERN "*.fp")

        # Make a plugin directory and symlink the scripts directory into it
        # so that the development ZEEKPATH will work too.
        file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/scripts/builtin-plugins)
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -E create_symlink "${CMAKE_CURRENT_SOURCE_DIR}/scripts"
                    "${CMAKE_BINARY_DIR}/scripts/builtin-plugins/${_plugin_name_canon}")
    endif ()

    # Feed into the main Zeek target(s).
    zeek_target_link_libraries(${target_name})
endfunction ()
