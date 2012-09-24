# - Try to find HILTI and BinPAC++.
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  HILTI_CONFIG    Set this variable to the location of hilti-config
#                  if the module has problems finding the proper
#                  installation path.
#
# Variables defined by this module:
#
#  HILTI_FOUND        HILTI/BinPAC++ found.
#  HILTI_CXX_FLAGS    CXX_FLAGS for compiling with HILTI integration.
#  HILTI_LD_FLAGS     LD_FLAGS for compiling with HILTI integration.
#  HILTI_LIBS         LIBS for compiling with HILTI integration.
#  HILTI_CLANG_EXEC   Full path to clang being used with HILTI.
#  HILTI_CLANGXX_EXEC Full path to clang++ being used with HILTI.

if (HILTI_EXECUTABLE AND EXISTS ${HILTI_EXECUTABLE}-config)
    set(HILTI_CONFIG ${HILTI_EXECUTABLE}-config CACHE PATH "" FORCE)
else ()
    find_program(HILTI_CONFIG NAMES hilti-config)
endif ()

if ( HILTI_CONFIG )
    execute_process(COMMAND "${HILTI_CONFIG}" --debug --compiler --runtime --cxxflags
                    OUTPUT_VARIABLE HILTI_CXX_FLAGS
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND "${HILTI_CONFIG}" --debug --compiler --runtime --ldflags
                    OUTPUT_VARIABLE HILTI_LD_FLAGS
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND "${HILTI_CONFIG}" --debug --compiler --runtime --libs-shared
                    OUTPUT_VARIABLE HILTI_LIBS_SHARED
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND "${HILTI_CONFIG}" --debug --compiler --runtime --libfiles-static
                    OUTPUT_VARIABLE HILTI_LIBS_STATIC
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND "${HILTI_CONFIG}" --clang
                    OUTPUT_VARIABLE HILTI_CLANG_EXEC
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND "${HILTI_CONFIG}" --clang++
                    OUTPUT_VARIABLE HILTI_CLANGXX_EXEC
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    set(HILTI_LIBS "${HILTI_LIBS_SHARED} -lc++")

    #string(REPLACE "-l" "" HILTI_LIBS "${HILTI_LIBS}")
    #sstring(REPLACE " " ";" HILTI_LIBS "${HILTI_LIBS}")

    #string(STRIP "${HILTI_LD_FLAGS}" HILTI_LD_FLAGS_LIST)
    #string(REPLACE "\n" ";" HILTI_LD_FLAGS_LIST "${HILTI_LD_FLAGS_LIST}")
    #string(REPLACE " " ";"  HILTI_LD_FLAGS_LIST "${HILTI_LD_FLAGS_LIST}")
    #####string(REPLACE "\"" ""  HILTI_LD_FLAGS_LIST "${HILTI_LD_FLAGS_LIST}")
    #
    #set(HILTI_LD_FLAGS "${HILTI_LD_FLAGS_LIST}")
    #
    #message("${HILTI_FOUND}")
    #message("${HILTI_CXX_FLAGS}")
    #message("${HILTI_LD_FLAGS}")

    if ( HILTI_LD_FLAGS AND HILTI_LIBS AND HILTI_CXX_FLAGS )
        set(HILTI_SUCCESS "Found")
    endif()

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(HILTI DEFAULT_MSG HILTI_SUCCESS)
endif ()
