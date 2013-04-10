
### Default versions.

# A macro to define a command that uses the BIF compiler to produce
# C++ segments and Bro language declarations from .bif file
# The outputs are appended to list ALL_BIF_OUTPUTS
# Outputs that should be installed are appended to INSTALL_BIF_OUTPUTS
macro(BIF_TARGET bifInput)
    get_bif_output_files(${bifInput} bifOutputs)
    add_custom_command(OUTPUT ${bifOutputs}
                       COMMAND bifcl
                       ARGS ${CMAKE_CURRENT_SOURCE_DIR}/${bifInput} || (rm -f ${bifOutputs} && exit 1)
                       # In order be able to run bro from the build directory,
                       # the generated bro script needs to be inside a
                       # a directory tree named the same way it will be
                       # referenced from an @load.
                       COMMAND "${CMAKE_COMMAND}"
                       ARGS -E copy ${bifInput}.bro ${CMAKE_BINARY_DIR}/scripts/base/bif/${bifInput}.bro
                       COMMAND "${CMAKE_COMMAND}"
                       ARGS -E remove -f ${bifInput}.bro
                       DEPENDS ${bifInput}
                       DEPENDS bifcl
                       COMMENT "[BIFCL] Processing ${bifInput}"
    )
    list(APPEND ALL_BIF_OUTPUTS ${bifOutputs})
    list(APPEND INSTALL_BIF_OUTPUTS
         ${CMAKE_CURRENT_BINARY_DIR}/base/bif/${bifInput}.bro)
endmacro(BIF_TARGET)

# Returns a list of output files that bifcl will produce
# for given input file in ${outputFileVar}.
macro(GET_BIF_OUTPUT_FILES inputFile outputFileVar)
    set(${outputFileVar}
        ${CMAKE_BINARY_DIR}/scripts/base/bif/${inputFile}.bro
        ${inputFile}.func_def
        ${inputFile}.func_h
        ${inputFile}.func_init
        ${inputFile}.netvar_def
        ${inputFile}.netvar_h
        ${inputFile}.netvar_init
    )
endmacro(GET_BIF_OUTPUT_FILES)

### Plugin versions.

# A variant of BIF_TARGET that's tailored for plugin use.
# The outputs are returned in BIF_OUTPUT_{C,H,BRO}.
macro(BIF_TARGET_FOR_PLUGIN pluginName bifInput)
    get_bif_output_files_for_plugin(${pluginName} ${bifInput} bifOutputs)
    add_custom_command(OUTPUT ${bifOutputs}
                       COMMAND bifcl
                       ARGS -p ${pluginName} ${CMAKE_CURRENT_SOURCE_DIR}/${bifInput} || (rm -f ${bifOutputs} && exit 1)
                       # In order be able to run bro from the build directory,
                       # the generated bro script needs to be inside a
                       # a directory tree named the same way it will be
                       # referenced from an @load.
                       COMMAND "${CMAKE_COMMAND}"
                       ARGS -E copy ${bifInput}.bro ${CMAKE_BINARY_DIR}/scripts/base/bif/plugins/${pluginName}.${bifInput}.bro
                       COMMAND "${CMAKE_COMMAND}"
                       ARGS -E remove -f ${bifInput}.bro
                       DEPENDS ${bifInput}
                       DEPENDS bifcl
                       DEPENDS generate_bifs
                       COMMENT "[BIFCL] Processing ${bifInput} (plugin)"
    )
	set(BIF_OUTPUT_CC  ${bifInput}.cc ${bifInput}.init.cc)
	set(BIF_OUTPUT_H   ${bifInput}.h)
	set(BIF_OUTPUT_BRO ${CMAKE_BINARY_DIR}/scripts/base/plugin.${pluginName}.${bifInput}.bro)
endmacro(BIF_TARGET_FOR_PLUGIN)

# A variant of GET_BIF_OUTPUT_FILES that's tailored for plugin use.
# This returns the files produces from ${inputFile} by "bifcl -p".
macro(GET_BIF_OUTPUT_FILES_FOR_PLUGIN pluginName inputFile outputFileVar)
    set(${outputFileVar}
        ${CMAKE_BINARY_DIR}/scripts/base/bif/plugins/${pluginName}.${inputFile}.bro
        ${inputFile}.h
        ${inputFile}.cc
        ${inputFile}.init.cc
    )
endmacro(GET_BIF_OUTPUT_FILES_FOR_PLUGIN)

### Subdirectory versions.

# A variant of BIF_TARGET that's tailored for sub-directory use.
# The outputs are returned in BIF_OUTPUT_{C,H,BRO}.
# This also define a new target "generate_${bifInput}" that triggers
# the generation; the target can be used to define dependencies if
# other parts require the generated file to be built first.
macro(BIF_TARGET_FOR_SUBDIR bifInput)
    get_bif_output_files_for_subdir(${bifInput} bifOutputs)
    add_custom_command(OUTPUT ${bifOutputs}
                       COMMAND bifcl
                       ARGS -s ${CMAKE_CURRENT_SOURCE_DIR}/${bifInput} || (rm -f ${bifOutputs} && exit 1)
                       # In order be able to run bro from the build directory,
                       # the generated bro script needs to be inside a
                       # a directory tree named the same way it will be
                       # referenced from an @load.
                       COMMAND "${CMAKE_COMMAND}"
                       ARGS -E copy ${bifInput}.bro ${CMAKE_BINARY_DIR}/scripts/base/bif/${bifInput}.bro
                       COMMAND "${CMAKE_COMMAND}"
                       ARGS -E remove -f ${bifInput}.bro
                       DEPENDS ${bifInput}
                       DEPENDS bifcl
                       DEPENDS generate_bifs
                       COMMENT "[BIFCL] Processing ${bifInput} (subdir)"
    )
	set(BIF_OUTPUT_CC  ${bifInput}.cc)
	set(BIF_OUTPUT_H   ${bifInput}.h)
	set(BIF_OUTPUT_BRO ${CMAKE_BINARY_DIR}/scripts/base/${bifInput}.bro)
    add_custom_target(generate_${bifInput} DEPENDS ${BIF_OUTPUT_H})
endmacro(BIF_TARGET_FOR_SUBDIR)

# A variant of GET_BIF_OUTPUT_FILES that's tailored for sub-directory use.
# This returns the files produces from ${inputFile} by "bifcl -p".
macro(GET_BIF_OUTPUT_FILES_FOR_SUBDIR inputFile outputFileVar)
    set(${outputFileVar}
        ${CMAKE_BINARY_DIR}/scripts/base/bif/${inputFile}.bro
        ${inputFile}.h
        ${inputFile}.cc
        ${inputFile}.init.cc
    )
endmacro(GET_BIF_OUTPUT_FILES_FOR_SUBDIR)

