include(FindClangTidy)
include(GetArchitecture)

# Sets `target` to contain the CMake target name for a dynamic plugin.
macro (zeek_get_dynamic_plugin_target target ns name)
    set(${target} "${ns}_${name}")
endmacro ()

# Implements the dynamically linked version of zeek_add_plugin.
function (zeek_add_dynamic_plugin ns name)
    # Sanity check: need ZEEK_PLUGIN_SCRIPTS_PATH.
    if (NOT EXISTS "${ZEEK_PLUGIN_SCRIPTS_PATH}")
        message(
            FATAL_ERROR
                "Cannot build dynamic plugins: ZEEK_PLUGIN_SCRIPTS_PATH is undefined or invalid")
    endif ()

    # Helper variables.
    zeek_get_dynamic_plugin_target(target_name ${ns} ${name})
    set(full_name "${ns}::${name}")
    set(canon_name "${ns}_${name}")
    set(base_dir "${CMAKE_CURRENT_BINARY_DIR}")
    set(lib_dir "${base_dir}/lib")
    set(bif_dir "${lib_dir}/bif")
    set(readme "${base_dir}/README")
    set(scripts_bin "${base_dir}/scripts")
    set(scripts_src "${CMAKE_CURRENT_SOURCE_DIR}/scripts")

    # Create the target if no begin function has been used.
    if (NOT TARGET ${target_name})
        add_library(${target_name} MODULE)
    endif ()

    # Place library file into the 'lib' directory, drop default-generated file
    # prefix and override the default file name to include the architecture.
    set_target_properties(
        ${target_name} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${lib_dir}" PREFIX ""
                                  LIBRARY_OUTPUT_NAME "${ns}-${name}.${HOST_ARCHITECTURE}")

    # Parse arguments (note: DIST_FILES and SCRIPT_FILES are ignored in static builds).
    set(fn_varargs
        INCLUDE_DIRS
        DEPENDENCIES
        SOURCES
        BIFS
        DIST_FILES
        SCRIPT_FILES
        PAC)
    cmake_parse_arguments(FN_ARGS "" "" "${fn_varargs}" ${ARGN})

    # Take care of compiling BIFs.
    if (FN_ARGS_BIFS)
        # Generate the targets and add the .cc files.
        foreach (bif ${FN_ARGS_BIFS})
            bif_target(${bif} "plugin" ${full_name} ${canon_name} OFF)
            target_sources(${target_name} PRIVATE ${BIF_OUTPUT_CC})
        endforeach ()
        # Generate __load__.zeek when building the plugin outside of Zeek.
        if (ZEEK_PLUGIN_INTERNAL_BUILD)
            set(loader_target ${target_name}_bif_loader)
            bro_bif_create_loader(${loader_target} ${FN_ARGS_BIFS})
            add_dependencies(${target_name} ${loader_target})
        else ()
            set(load_script "${bif_dir}/__load__.zeek")
            file(WRITE ${load_script} "# Warning, this is an autogenerated file!\n")
            foreach (bif ${FN_ARGS_BIFS})
                get_filename_component(file_name ${bif} NAME)
                file(APPEND ${load_script} "@load ./${file_name}.zeek\n")
            endforeach ()
        endif ()
    endif ()

    # Take care of PAC files.
    zeek_next_pac_block(at_end pacInputs pacRemainder ${ARGN})
    while (NOT at_end)
        binpac_target(${pacInputs})
        target_sources(${target_name} PRIVATE ${BINPAC_OUTPUT_CC})
        zeek_next_pac_block(at_end pacInputs pacRemainder ${pacRemainder})
    endwhile ()

    # Add user-defined extra dependencies.
    if (FN_ARGS_DEPENDENCIES)
        target_link_libraries(${target_name} PUBLIC ${FN_ARGS_DEPENDENCIES})
    endif ()

    # Add the sources for the plugin.
    if (FN_ARGS_SOURCES)
        target_sources(${target_name} PRIVATE ${FN_ARGS_SOURCES})
    endif ()

    # Add extra dependencies when compiling with MSVC.
    if (MSVC)
        target_link_libraries(${target_name} ws2_32)
    endif ()

    # Pass compiler flags, paths and dependencies to the target.
    target_link_libraries(${target_name} PRIVATE Zeek::DynamicPluginBase)
    target_include_directories(${target_name} PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

    # Per convention, plugins have their headers and sources under src/ and
    # legacy/external plugins expect this to auto-magically be available as
    # include path.
    if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src)
        target_include_directories(${target_name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
    endif ()

    # Link scripts into the build directory (if present).
    if (IS_DIRECTORY "${scripts_src}")
        set(symlink_target ${target_name}_symlink)
        add_custom_target(${symlink_target} COMMAND "${CMAKE_COMMAND}" -E create_symlink
                                                    "${scripts_src}" "${scripts_bin}")
        add_dependencies(${target_name} ${symlink_target})
    endif ()

    # Add BinPAC_INCLUDE_DIR for picking up paths from FindBinPAC.cmake.
    if (BinPAC_INCLUDE_DIR)
        target_include_directories(${target_name} PRIVATE ${BinPAC_INCLUDE_DIR})
    endif ()

    # Write the 'magic' __bro_plugin__ file. We can do that once during CMake
    # invocation since it won't change.
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/__bro_plugin__" "${full_name}")

    # Stop here unless building 3rd party plugins.
    if (ZEEK_PLUGIN_INTERNAL_BUILD)
        return()
    endif ()

    # Plugins may set BRO_PLUGIN_INSTALL_ROOT to override the default
    # installation directory. Otherwise, we use ZEEK_PLUGIN_DIR from Zeek.
    if (BRO_PLUGIN_INSTALL_ROOT)
        set(install_dir "${BRO_PLUGIN_INSTALL_ROOT}")
    else ()
        set(install_dir ${ZEEK_PLUGIN_DIR})
    endif ()

    # Create the binary install package.
    set(dist_tarball_name ${canon_name}.tgz)
    set(dist_tarball_path ${CMAKE_CURRENT_BINARY_DIR}/${dist_tarball_name})
    message(STATUS "Install prefix for plugin ${canon_name}: ${install_dir}")
    message(STATUS "Tarball path for plugin ${canon_name}: ${dist_tarball_path}")
    add_custom_command(
        OUTPUT ${dist_tarball_path}
        COMMAND ${ZEEK_PLUGIN_SCRIPTS_PATH}/zeek-plugin-create-package.sh ${canon_name}
                ${FN_ARGS_DIST_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        DEPENDS ${target_name} ${FN_ARGS_SCRIPT_FILES}
        COMMENT "Building binary plugin package: ${dist_tarball_path}")
    add_custom_target(${target_name}_tarball ALL DEPENDS ${dist_tarball_path})

    # Tell CMake to install our tarball. Note: This usually runs from our
    # plugin-support skeleton.
    install(
        CODE "execute_process(
        COMMAND ${ZEEK_PLUGIN_SCRIPTS_PATH}/zeek-plugin-install-package.sh ${canon_name} \$ENV{DESTDIR}/${install_dir}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMAND_ECHO STDOUT
    )")
endfunction ()
