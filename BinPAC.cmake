if (NOT TARGET Zeek::BinPAC)
    message(FATAL_ERROR "BinPAC.cmake needs Zeek::BinPAC")
endif ()

# A macro to define a command that uses the BinPac compiler to
# produce C++ code that implements a protocol parser/analyzer.
# The outputs are returned in BINPAC_OUTPUT_{CC,H}.
# Additional dependencies are pulled from BINPAC_AUXSRC.
function (binpac_target pacFile)

    set(BinPAC_addl_args "")

    if (ZEEK_PLUGIN_INTERNAL_BUILD)
        # Ensure that for plugins included via --include-plugins, the Zeek's
        # source tree paths are added to binpac's include path as well.
        set(BinPAC_addl_args
            "-I;${CMAKE_SOURCE_DIR};-I;${CMAKE_SOURCE_DIR}/src;-I;${CMAKE_SOURCE_DIR}/src/include")
        # Add a dependency on the target when building Zeek to make sure the
        # executable actually exists.
        set(binpacDep Zeek::BinPAC)
    endif ()

    # Add ZEEK_SOURCE_DIR and ZEEK_SOURCE_DIR/src to BinPAC_addl_args. This
    # variable is defined in the main CMake file.
    if (ZEEK_SOURCE_DIR)
        list(APPEND BinPAC_addl_args -I "${ZEEK_SOURCE_DIR}" -I "${ZEEK_SOURCE_DIR}/src")
    endif ()

    # Add ZEEK_CMAKE_INSTALL_PREFIX to BinPAC_addl_args if it exists. This
    # variable is present when loading ZeekPlugin.cmake.
    if (ZEEK_CMAKE_INSTALL_PREFIX)
        list(APPEND BinPAC_addl_args -I "${ZEEK_CMAKE_INSTALL_PREFIX}/include")
    endif ()

    # Add BinPAC_INCLUDE_DIR to BinPAC_addl_args if it exists. This variable is
    # present when finding BinPAC via FindBinPAC.cmake.
    if (BinPAC_INCLUDE_DIR)
        # Note: this variable may be a list.
        foreach (dir ${BinPAC_INCLUDE_DIR})
            list(APPEND BinPAC_addl_args -I "${dir}")
        endforeach ()
    endif ()

    get_filename_component(basename ${pacFile} NAME_WE)
    set(pacBaseName "${CMAKE_CURRENT_BINARY_DIR}/${basename}")
    set(hdr_file ${pacBaseName}_pac.h)
    set(src_file ${pacBaseName}_pac.cc)

    if (NOT MSVC)
        set_property(SOURCE ${src_file} APPEND_STRING PROPERTY COMPILE_FLAGS
                                                               "-Wno-tautological-compare")
    endif ()

    add_clang_tidy_files(${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.cc)

    set(target "pac-${CMAKE_CURRENT_BINARY_DIR}/${pacFile}")

    # Make sure to escape a bunch of special characters in the path before trying to use it as a
    # regular expression below.
    string(REGEX REPLACE "([][+.*()^])" "\\\\\\1" escaped_path "${PROJECT_BINARY_DIR}/src/")

    string(REGEX REPLACE "${escaped_path}" "" target "${target}")
    string(REGEX REPLACE "/" "-" target "${target}")
    string(REGEX REPLACE ":" "" target "${target}")
    add_custom_command(
        OUTPUT "${hdr_file}" "${src_file}"
        COMMAND
            Zeek::BinPAC -q -d ${CMAKE_CURRENT_BINARY_DIR} -I ${CMAKE_CURRENT_SOURCE_DIR} -I
            ${CMAKE_CURRENT_SOURCE_DIR}/src ${BinPAC_addl_args}
            ${CMAKE_CURRENT_SOURCE_DIR}/${pacFile}
        DEPENDS ${binpacDep} ${pacFile} ${BINPAC_AUXSRC} ${ARGN}
        COMMENT "[BINPAC] Processing ${CMAKE_CURRENT_SOURCE_DIR}/${pacFile}")
    add_custom_target(${target} DEPENDS "${hdr_file}" "${src_file}")

    # Make paths to generated visible at the caller.
    set(BINPAC_OUTPUT_H "${hdr_file}" PARENT_SCOPE)
    set(BINPAC_OUTPUT_CC "${src_file}" PARENT_SCOPE)

    # When building Zeek, this target bundles all auto-generated files.
    if (TARGET zeek_autogen_files)
        add_dependencies(zeek_autogen_files ${target})
    endif ()
endfunction ()
