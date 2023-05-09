# A macro to define a command that uses the gen-zam templator to produce
# C++ headers from an input template file. The outputs are returned in
# GEN_ZAM_OUTPUT_H.
#
# The macro also creates a target that can be used to define depencencies on the
# generated files. The name of the target includes the input template filename
# to make it unique, and is added automatically to bro_ALL_GENERATED_OUTPUTS.
macro (gen_zam_target gzInput)
    get_filename_component(gzInputBasename "${gzInput}" NAME)

    set(target "gen-zam-${gzInputBasename}")
    string(REGEX REPLACE "/" "-" target "${target}")

    set(GEN_ZAM_OUTPUT_H
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-AssignFlavorsDefs.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-Conds.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-DirectDefs.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-EvalDefs.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-EvalMacros.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-GenExprsDefsC1.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-GenExprsDefsC2.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-GenExprsDefsC3.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-GenExprsDefsV.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-GenFieldsDefsC1.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-GenFieldsDefsC2.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-GenFieldsDefsV.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-MethodDecls.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-MethodDefs.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-Op1FlavorsDefs.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-OpSideEffects.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-OpsDefs.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-OpsNamesDefs.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-Vec1EvalDefs.h
        ${CMAKE_CURRENT_BINARY_DIR}/ZAM-Vec2EvalDefs.h)

    if (GEN_ZAM_EXE_PATH)
        set(GEN_ZAM_EXE ${GEN_ZAM_EXE_PATH})
    else ()
        set(GEN_ZAM_EXE "gen-zam")
    endif ()

    add_custom_command(
        OUTPUT ${GEN_ZAM_OUTPUT_H}
        COMMAND ${GEN_ZAM_EXE} ARGS ${gzInput}
        DEPENDS ${gzInput} ${GEN_ZAM_EXE}
        COMMENT "[gen-zam] Generating ZAM operations"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

    add_custom_target(${target} DEPENDS ${GEN_ZAM_OUTPUT_H})
    add_dependencies(zeek_autogen_files ${target})
endmacro (gen_zam_target)
