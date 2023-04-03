
# A macro to define a command that uses the BinPac compiler to
# produce C++ code that implements a protocol parser/analyzer.
# The outputs are returned in BINPAC_OUTPUT_{CC,H}.
# Additional dependencies are pulled from BINPAC_AUXSRC.
#
# The macro also creates a target that can be used to define depencencies on
# the generated files. The name of the target includes a normalized path to
# the input pac to make it unique. The target is added automatically to
# bro_ALL_GENERATED_OUTPUTS.
macro(BINPAC_TARGET pacFile)
    if ( ZEEK_PLUGIN_INTERNAL_BUILD )
        if ( BINPAC_EXE_PATH )
            set(BinPAC_EXE ${BINPAC_EXE_PATH})
        endif ()

        set(binpacDep "${BinPAC_EXE}")

        # Ensure that for plugins included via --include-plugins, the Zeek's
        # source tree paths are added to binpac's include path as well.
        set(BinPAC_addl_args "-I;${CMAKE_SOURCE_DIR};-I;${CMAKE_SOURCE_DIR}/src;-I;${CMAKE_SOURCE_DIR}/src/include")
    else ()
        if ( BRO_PLUGIN_BRO_BUILD )
            # Zeek 3.2+ has auxil/ instead of aux/
            if ( EXISTS "${BRO_PLUGIN_BRO_BUILD}/auxil" )
                set(BinPAC_EXE "${BRO_PLUGIN_BRO_BUILD}/auxil/binpac/src/binpac")
            else ()
                set(BinPAC_EXE "${BRO_PLUGIN_BRO_BUILD}/aux/binpac/src/binpac")
            endif ()
            set(BinPAC_addl_args "-I;${BRO_PLUGIN_BRO_SRC}/src")
        else ()
            find_package(BinPAC REQUIRED)
            set(BinPAC_addl_args "-I;${BRO_PLUGIN_BRO_CONFIG_INCLUDE_DIR}")
        endif ()
    endif ()

    get_filename_component(basename ${pacFile} NAME_WE)
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.h
                              ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.cc
                       COMMAND ${BinPAC_EXE}
                       ARGS -q -d ${CMAKE_CURRENT_BINARY_DIR}
                            -I ${CMAKE_CURRENT_SOURCE_DIR}
                            -I ${CMAKE_CURRENT_SOURCE_DIR}/src
                            -I ${PROJECT_SOURCE_DIR}/src
                            ${BinPAC_addl_args}
                            ${CMAKE_CURRENT_SOURCE_DIR}/${pacFile}
                       DEPENDS ${binpacDep} ${pacFile}
                               ${BINPAC_AUXSRC} ${ARGN}
                       COMMENT "[BINPAC] Processing ${pacFile}"
    )

    set(BINPAC_OUTPUT_H ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.h)
    set(BINPAC_OUTPUT_CC ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.cc)
    set(pacOutputs ${BINPAC_OUTPUT_H} ${BINPAC_OUTPUT_CC})
    if ( NOT MSVC )
        set_property(SOURCE ${BINPAC_OUTPUT_CC} APPEND_STRING PROPERTY COMPILE_FLAGS "-Wno-tautological-compare")
    endif()

    add_clang_tidy_files(${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.cc)

    set(target "pac-${CMAKE_CURRENT_BINARY_DIR}/${pacFile}")

    # Make sure to escape a bunch of special characters in the path before trying to use it as a
    # regular expression below.
    string(REGEX REPLACE "([][+.*()^])" "\\\\\\1" escaped_path "${PROJECT_BINARY_DIR}/src/")

    string(REGEX REPLACE "${escaped_path}" "" target "${target}")
    string(REGEX REPLACE "/" "-" target "${target}")
    string(REGEX REPLACE ":" "" target "${target}")
    add_custom_target(${target} DEPENDS ${pacOutputs})
    set(BINPAC_BUILD_TARGET ${target})

    set(bro_ALL_GENERATED_OUTPUTS ${bro_ALL_GENERATED_OUTPUTS} ${target}  CACHE INTERNAL "automatically generated files" FORCE) # Propagate to top-level.
endmacro(BINPAC_TARGET)
