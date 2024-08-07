# Aborts the configuration if no C or C++ compiler is found, depending
# on whether a previous call to the project() macro was supplied either
# language as a requirement.

if (NOT CMAKE_C_COMPILER AND DEFINED CMAKE_C_COMPILER)
    message(FATAL_ERROR "Could not find prerequisite C compiler")
endif ()

if (NOT CMAKE_CXX_COMPILER AND DEFINED CMAKE_CXX_COMPILER)
    message(FATAL_ERROR "Could not find prerequisite C++ compiler")
endif ()

if (WIN32 AND NOT CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    message(
        FATAL_ERROR "Could not find prerequisite C compiler for Windows platform. MSVC is required")
endif ()

if (WIN32 AND NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    message(
        FATAL_ERROR
            "Could not find prerequisite C++ compiler for Windows platform. MSVC is required")
endif ()
