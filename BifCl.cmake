
# A macro to define a command that uses the BIF compiler to produce C++
# segments and Bro language declarations from a .bif file. The outputs
# are returned in BIF_OUTPUT_{CC,H,BRO}. By default, it runs bifcl in
# alternative mode (-a; suitable for standalone compilation). If
# an additional parameter "standard"is given, it runs it in standard mode
# for inclusion in NetVar.*. If an additional parameter "plugin" is given,
# it runs it in plugin mode (-p). In the latter case, one more argument
# is required with the plugins name.
#
# TODO: Update description with target.

macro(bif_target bifInput)
    set(target "")

    if ( "${ARGV1}" STREQUAL "standard" )
        set(bifcl_args "")
        set(target "bif-std-${CMAKE_CURRENT_BINARY_DIR}/${bifInput}")
        set(bifOutputs
            ${CMAKE_BINARY_DIR}/scripts/base/bif/${bifInput}.bro
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInput}.func_def
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInput}.func_h
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInput}.func_init
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInput}.netvar_def
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInput}.netvar_h
            ${CMAKE_CURRENT_BINARY_DIR}/${bifInput}.netvar_init)
    	set(BIF_OUTPUT_CC  ${bifInput}.func_def
                           ${bifInput}.func_init
                           ${bifInput}.netvar_def
                           ${bifInput}.netvar_init)
        set(BIF_OUTPUT_H   ${bifInput}.func_h
                           ${bifInput}.netvar_h)
	    set(BIF_OUTPUT_BRO ${CMAKE_BINARY_DIR}/scripts/base/bif/${bifInput}.bro)

    elseif ( "${ARGV1}" STREQUAL "plugin" )
        set(plugin_name ${ARGV2})
        set(target "bif-plugin-${plugin_name}-${bifInput}")
        set(bifcl_args "-p ${plugin_name}")
        set(bifOutputs
            ${CMAKE_BINARY_DIR}/scripts/base/bif/plugins/${plugin_name}.${bifInput}.bro
            ${bifInput}.h
            ${bifInput}.cc
            ${bifInput}.init.cc)
    	set(BIF_OUTPUT_CC  ${bifInput}.cc
                           ${bifInput}.init.cc)
        set(BIF_OUTPUT_H   ${bifInput}.h)
    	set(BIF_OUTPUT_BRO ${CMAKE_BINARY_DIR}/scripts/base/bif/plugins/${plugin_name}.${bifInput}.bro)

    else ()
        # Alternative mode.
        set(bifcl_args "-s")
        set(target "bif-alt-${CMAKE_CURRENT_BINARY_DIR}/${bifInput}")
        set(bifOutputs
            ${CMAKE_BINARY_DIR}/scripts/base/bif/${bifInput}.bro
            ${bifInput}.h
            ${bifInput}.cc
            ${bifInput}.init.cc)
    	set(BIF_OUTPUT_CC  ${bifInput}.cc)
        set(BIF_OUTPUT_H   ${bifInput}.h)
	    set(BIF_OUTPUT_BRO ${CMAKE_BINARY_DIR}/scripts/base/bif/${bifInput}.bro)
    endif ()

    add_custom_command(OUTPUT ${bifOutputs}
                       COMMAND bifcl
                       ARGS ${bifcl_args} ${CMAKE_CURRENT_SOURCE_DIR}/${bifInput} || (rm -f ${bifOutputs} && exit 1)
                       # In order be able to run bro from the build directory,
                       # the generated bro script needs to be inside a
                       # a directory tree named the same way it will be
                       # referenced from an @load.
                       COMMAND "${CMAKE_COMMAND}"
                       ARGS -E copy ${bifInput}.bro ${BIF_OUTPUT_BRO}
                       COMMAND "${CMAKE_COMMAND}"
                       ARGS -E remove -f ${bifInput}.bro
                       DEPENDS ${bifInput}
                       DEPENDS bifcl
                       COMMENT "[BIFCL] Processing ${bifInput}"
    )

    string(REGEX REPLACE "${CMAKE_BINARY_DIR}/src/" "" target "${target}")
    string(REGEX REPLACE "/" "-" target "${target}")
    add_custom_target(${target} DEPENDS ${BIF_OUTPUT_H} ${BIF_OUTPUT_CC})
    set_source_files_properties(${bifOutputs} PROPERTIES GENERATED 1)

    set(bro_ALL_GENERATED_OUTPUTS ${bro_ALL_GENERATED_OUTPUTS} ${target}  CACHE INTERNAL "automatically generated files" FORCE) # Propagate to top-level.
endmacro(bif_target)

function(bro_bif_create_loader target dstdir)
     file(MAKE_DIRECTORY ${dstdir})
     add_custom_target(${target}
			COMMAND "sh" "-c" "ls *.bif.bro \\| sed 's#\\\\\\(.*\\\\\\).bro#@load ./\\\\1#g' >__load__.bro"
			WORKING_DIRECTORY ${dstdir}
			)
     add_dependencies(${target} generate_outputs)
endfunction()
