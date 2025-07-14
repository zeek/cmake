include(BifCl)
include(BinPAC)
include(RequireCXXStd)

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

        target_compile_features(${target_name} PRIVATE ${ZEEK_CXX_STD})
        set_target_properties(${target_name} PROPERTIES CXX_EXTENSIONS OFF)
    endif ()
    add_dependencies(${target_name} zeek_autogen_files)

    # Skip zeek-version.h when including zeek-config.h for statically build
    # plugins (they are always builtin) *except* if the current scope is tagged
    # with ZEEK_BUILDING_EXTRA_PLUGINS (this is the case when building plugins
    # from BUILTIN_PLUGIN_LIST).
    if (NOT ZEEK_BUILDING_EXTRA_PLUGINS)
        target_compile_definitions(${target_name} PRIVATE ZEEK_CONFIG_SKIP_VERSION_H)
    endif ()

    # Parse arguments (note: DIST_FILES and SCRIPT_FILES are ignored in static builds).
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

    if (BUILD_WITH_WERROR)
        if (MSVC)
            # TODO: This is disabled for now because there a bunch of known
            # compiler warnings on Windows that we don't have good fixes for.
            #set(WERROR_FLAG "/WX")
        else ()
            set(WERROR_FLAG "-Werror")

            # With versions >=13.0 GCC gained `-Warray-bounds` which reports false
            # positives, see e.g., https://gcc.gnu.org/bugzilla/show_bug.cgi?id=111273.
            if (CMAKE_COMPILER_IS_GNUCXX AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 13.0)
                list(APPEND WERROR_FLAG "-Wno-error=array-bounds")
            endif ()

            # With versions >=11.0 GCC is retruning false positives for -Wrestrict. See
            # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=100366. It's more prevalent
            # building with -std=c++20.
            if (CMAKE_COMPILER_IS_GNUCXX AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 11.0)
                list(APPEND WERROR_FLAG "-Wno-error=restrict")
            endif ()
        endif ()
    endif ()

    # Pass compiler flags, paths and dependencies to the target.
    target_link_libraries(${target_name} PRIVATE $<BUILD_INTERFACE:zeek_internal>)
    target_include_directories(${target_name} PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
    target_compile_options(${target_name} PRIVATE ${WERROR_FLAG})

    # Per convention, plugins have their headers and sources under src/ and
    # legacy/external plugins expect this to auto-magically be available as
    # include path.
    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src)
        target_include_directories(${target_name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
    endif ()

    # Add user-defined extra include directories. If a path is outside of the current
    # project source dir, add it as a system path so that clang-tidy can easily ignore
    # it.
    if (FN_ARGS_INCLUDE_DIRS)
        foreach (_include_dir ${FN_ARGS_INCLUDE_DIRS})
            # In CMake 3.20, this can use cmake_path(IS_PREFIX).
            string(FIND "${PROJECT_SOURCE_DIR}" "${_include_dir}" _is_project_prefixed)
            if (_is_project_prefixed EQUAL 0)
                target_include_directories(${target_name} PRIVATE ${_include_dir})
            else ()
                target_include_directories(${target_name} SYSTEM PRIVATE ${_include_dir})
            endif ()
        endforeach ()
    endif ()

    # Add extra dependencies.
    if (FN_ARGS_DEPENDENCIES)
        target_link_libraries(${target_name} PRIVATE ${FN_ARGS_DEPENDENCIES})
    endif ()

    # Add the sources for the plugin.
    if (FN_ARGS_SOURCES)
        target_sources(${target_name} PRIVATE ${FN_ARGS_SOURCES})
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
            DESTINATION "${ZEEK_SCRIPT_INSTALL_PATH}/builtin-plugins/${canon_name}"
            FILES_MATCHING
            PATTERN "*.zeek"
            PATTERN "*.sig"
            PATTERN "*.fp")

        # Make a plugin directory and symlink the scripts directory into it
        # so that the development ZEEKPATH will work too.
        file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/scripts/builtin-plugins)
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -E create_symlink "${CMAKE_CURRENT_SOURCE_DIR}/scripts"
                    "${CMAKE_BINARY_DIR}/scripts/builtin-plugins/${canon_name}")
    endif ()

    # Feed into the main Zeek target(s).
    zeek_target_link_libraries(${target_name})

    if (NOT ZEEK_BUILDING_EXTRA_PLUGINS)
        # Add IWYU and clang-tidy to the target if enabled.
        zeek_target_add_linters(${target_name})

        zeek_target_enable_sanitizers(${target_name})
    endif ()
endfunction ()
