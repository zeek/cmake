if (NOT TARGET Zeek::BifCl)
    message(FATAL_ERROR "BifCl.cmake needs Zeek::BifCl")
endif ()

# A macro to define a command that uses the BIF compiler to produce C++
# segments and Zeek language declarations from a .bif file. The outputs
# are returned in BIF_OUTPUT_{CC,H,BRO}. By default, it runs bifcl in
# alternative mode (-a; suitable for standalone compilation). If
# an additional parameter "standard" is given, it runs it in standard mode
# for inclusion in NetVar.*. If an additional parameter "plugin" is given,
# it runs it in plugin mode (-p). In the latter case, one more argument
# is required with the plugin's name.
#
# The macro also creates a target that can be used to define depencencies on
# the generated files. The name of the target depends on the mode and includes
# a normalized path to the input bif to make it unique. The target is added
# automatically to bro_ALL_GENERATED_OUTPUTS.
macro (bif_target bifInput)
    set(target "")
    get_filename_component(bifInputBasename "${bifInput}" NAME)

    set(BRO_PLUGIN_LIB "${CMAKE_CURRENT_BINARY_DIR}/lib")
    set(BRO_PLUGIN_BIF "${BRO_PLUGIN_LIB}/bif")

    if ("${ARGV1}" STREQUAL "standard")
        set(bifcl_args "")
        set(target "bif-std-${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}")
        set(bifOutputs
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.func_def
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.func_h
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.func_init
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.netvar_def
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.netvar_h
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.netvar_init)
        set(BIF_OUTPUT_CC ${bifInputBasename}.func_def ${bifInputBasename}.func_init
                          ${bifInputBasename}.netvar_def ${bifInputBasename}.netvar_init)
        set(BIF_OUTPUT_H ${bifInputBasename}.func_h ${bifInputBasename}.netvar_h)
        set(BIF_OUTPUT_BRO ${CMAKE_BINARY_DIR}/scripts/base/bif/${bifInputBasename}.zeek)

        # Register this BIF in the base BIFs load script.
        file(APPEND "${CMAKE_BINARY_DIR}/scripts/base/bif/__load__.zeek"
             "@load ./${bifInputBasename}.zeek\n")

        # Do this here so that all of the necessary files for each individual BIF get added to clang-tidy
        add_clang_tidy_files(${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.func_def)

    elseif ("${ARGV1}" STREQUAL "plugin")
        set(plugin_name ${ARGV2})
        set(plugin_name_canon ${ARGV3})
        set(plugin_is_static ${ARGV4})
        set(target "bif-plugin-${plugin_name_canon}-${bifInputBasename}")
        set(bifcl_args "-p;${plugin_name}")
        set(bifOutputs
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.h
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.cc
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.init.cc
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.register.cc)

        if (plugin_is_static)
            set(BIF_OUTPUT_CC ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.cc
                              ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.init.cc)
            # Register the generated C++ files.
            file(APPEND "${CMAKE_BINARY_DIR}/src/__all__.bif.cc"
                 "#include \"${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.register.cc\"\n")
        else ()
            set(BIF_OUTPUT_CC
                ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.cc
                ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.init.cc
                ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.register.cc)
        endif ()

        # Do this here so that all of the necessary files for each individual BIF get added to clang-tidy
        foreach (bif_cc_file ${BIF_OUTPUT_CC})
            add_clang_tidy_files(${CMAKE_CURRENT_BINARY_DIR}/${bif_cc_file})
        endforeach (bif_cc_file)

        set(BIF_OUTPUT_H ${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.h)

        if (NOT ZEEK_PLUGIN_BUILD_DYNAMIC)
            set(BIF_OUTPUT_BRO
                ${CMAKE_BINARY_DIR}/scripts/base/bif/plugins/${plugin_name_canon}.${bifInputBasename}.zeek
            )
            # Register this BIF in the plugins BIFs load script.
            file(APPEND "${CMAKE_BINARY_DIR}/scripts/base/bif/plugins/__load__.zeek"
                 "@load ./${plugin_name_canon}.${bifInputBasename}.zeek\n")
        else ()
            set(BIF_OUTPUT_BRO ${BRO_PLUGIN_BIF}/${bifInputBasename}.zeek)
        endif ()

    else ()
        # Alternative mode. These will get compiled in automatically.
        set(bifcl_args "-s")
        set(target "bif-alt-${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}")
        set(bifOutputs ${bifInputBasename}.h ${bifInputBasename}.cc ${bifInputBasename}.init.cc)
        set(BIF_OUTPUT_CC ${bifInputBasename}.cc)
        set(BIF_OUTPUT_H ${bifInputBasename}.h)

        # Do this here so that all of the necessary files for each individual BIF get added to clang-tidy
        foreach (bif_cc_file ${BIF_OUTPUT_CC})
            add_clang_tidy_files(${CMAKE_CURRENT_BINARY_DIR}/${bif_cc_file})
        endforeach (bif_cc_file)

        # In order be able to run Zeek from the build directory, the
        # generated Zeek script needs to be inside a directory tree
        # named the same way it will be referenced from an @load.
        set(BIF_OUTPUT_BRO ${CMAKE_BINARY_DIR}/scripts/base/bif/${bifInputBasename}.zeek)

        # Register this BIF in the builtin-plugins BIFs load script.
        file(APPEND "${CMAKE_BINARY_DIR}/scripts/base/bif/__load__.zeek"
             "@load ./${bifInputBasename}.zeek\n")

        # Register the generated C++ files.
        file(APPEND "${CMAKE_BINARY_DIR}/src/__all__.bif.cc"
             "#include \"${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.cc\"\n")
        file(APPEND "${CMAKE_BINARY_DIR}/src/__all__.bif.init.cc"
             "#include \"${CMAKE_CURRENT_BINARY_DIR}/${bifInputBasename}.init.cc\"\n")

    endif ()

    # Make sure to escape a bunch of special characters in the path before trying to use it as a
    # regular expression below.
    string(REGEX REPLACE "([][+.*()^])" "\\\\\\1" escaped_path "${CMAKE_BINARY_DIR}/src/")

    string(REGEX REPLACE "${escaped_path}" "" target "${target}")
    string(REGEX REPLACE "/" "-" target "${target}")
    string(REGEX REPLACE ":" "" target "${target}")

    add_custom_command(
        OUTPUT ${bifOutputs} ${BIF_OUTPUT_BRO}
        COMMAND Zeek::BifCl ${bifcl_args} ${CMAKE_CURRENT_SOURCE_DIR}/${bifInput}
        COMMAND "${CMAKE_COMMAND}" -E copy ${bifInputBasename}.zeek ${BIF_OUTPUT_BRO}
        COMMAND "${CMAKE_COMMAND}" -E remove -f ${bifInputBasename}.zeek
        DEPENDS ${bifInput} Zeek::BifCl
        COMMENT "[BIFCL] Processing ${CMAKE_CURRENT_SOURCE_DIR}/${bifInput}")
    add_custom_target(${target} DEPENDS ${bifOutputs} ${BIF_OUTPUT_BRO})

    if (ZEEK_PLUGIN_INTERNAL_BUILD)
        # Note: target is defined in Zeek's top-level CMake.
        add_dependencies(zeek_autogen_files ${target})
    endif ()
endmacro (bif_target)
