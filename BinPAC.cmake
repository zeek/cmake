
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
    if ( BRO_PLUGIN_INTERNAL_BUILD )
        if ( BINPAC_EXE_PATH )
            set(BinPAC_EXE ${BINPAC_EXE_PATH})
        endif ()

        set(binpacDep "${BinPAC_EXE}")
    else ()
        if ( BRO_PLUGIN_BRO_BUILD )
            set(BinPAC_EXE "${BRO_PLUGIN_BRO_BUILD}/aux/binpac/src/binpac")
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
                            -I ${CMAKE_SOURCE_DIR}/src
                            ${BinPAC_addl_args}
                            ${CMAKE_CURRENT_SOURCE_DIR}/${pacFile}
                       DEPENDS ${binpacDep} ${pacFile}
                               ${BINPAC_AUXSRC} ${ARGN}
                       COMMENT "[BINPAC] Processing ${pacFile}"
    )

    set(BINPAC_OUTPUT_H ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.h)
    set(BINPAC_OUTPUT_CC ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.cc)
    set(pacOutputs ${BINPAC_OUTPUT_H} ${BINPAC_OUTPUT_CC})
    set_property(SOURCE ${BINPAC_OUTPUT_CC} APPEND_STRING PROPERTY COMPILE_FLAGS "-Wno-tautological-compare")

    set(target "pac-${CMAKE_CURRENT_BINARY_DIR}/${pacFile}")

    string(REGEX REPLACE "${CMAKE_BINARY_DIR}/src/" "" target "${target}")
    string(REGEX REPLACE "/" "-" target "${target}")
    add_custom_target(${target} DEPENDS ${pacOutputs})
    set(BINPAC_BUILD_TARGET ${target})

    set(bro_ALL_GENERATED_OUTPUTS ${bro_ALL_GENERATED_OUTPUTS} ${target}  CACHE INTERNAL "automatically generated files" FORCE) # Propagate to top-level.
endmacro(BINPAC_TARGET)
