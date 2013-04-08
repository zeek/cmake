
# A macro to define a command that uses the BinPac compiler to
# produce C++ code that implements a protocol parser/analyzer.
# The outputs of the command are appended to list ALL_BINPAC_OUTPUTS
# All arguments to this macro are appended to list ALL_BINPAC_INPUTS.
# Additional dependencies are pulled from BINPAC_AUXSRC.
macro(BINPAC_TARGET pacFile)
    get_filename_component(basename ${pacFile} NAME_WE)
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.h
                              ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.cc
                       COMMAND ${BinPAC_EXE}
                       ARGS -q -d ${CMAKE_CURRENT_BINARY_DIR}
                            -I ${CMAKE_CURRENT_SOURCE_DIR}
                            -I ${CMAKE_SOURCE_DIR}/src
                            ${CMAKE_CURRENT_SOURCE_DIR}/${pacFile}
                       DEPENDS ${BinPAC_EXE} ${pacFile}
                               ${BINPAC_AUXSRC} ${ARGN}
                       COMMENT "[BINPAC] Processing ${pacFile}"
    )
    list(APPEND ALL_BINPAC_INPUTS ${ARGV})
    list(APPEND ALL_BINPAC_OUTPUTS
         ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.h
         ${CMAKE_CURRENT_BINARY_DIR}/${basename}_pac.cc) 
endmacro(BINPAC_TARGET)
