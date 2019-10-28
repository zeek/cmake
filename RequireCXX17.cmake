# Detect if compiler version is sufficient for supporting C++17.
# If it is, CMAKE_CXX_FLAGS are modified appropriately and HAVE_CXX17
# is set to a true value.  Else, CMake exits with a fatal error message.
# This currently only works for GCC and Clang compilers.
# In Cmake 3.8+, CMAKE_CXX_STANDARD_REQUIRED should be able to replace
# all the logic below.

if ( DEFINED HAVE_CXX17 )
    return()
endif ()

include(CheckCXXSourceCompiles)

set(required_gcc_version 7.0)
set(required_clang_version 4.0)

macro(cxx17_compile_test)
    check_cxx_source_compiles("
        #include <optional>
        int main() { std::optional<int> a; }"
        cxx17_works)

    if (NOT cxx17_works)
        message(FATAL_ERROR "failed using C++17 for compilation")
    endif ()
endmacro()

# CMAKE_CXX_COMPILER_VERSION may not always be available (e.g. particularly
# for CMakes older than 2.8.10, but use it if it exists.
if ( DEFINED CMAKE_CXX_COMPILER_VERSION )
    if ( CMAKE_CXX_COMPILER_ID STREQUAL "GNU" )
        if ( CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${required_gcc_version} )
            message(FATAL_ERROR "GCC version must be at least "
                    "${required_gcc_version} for C++17 support, detected: "
                    "${CMAKE_CXX_COMPILER_VERSION}")
        endif ()
    elseif ( CMAKE_CXX_COMPILER_ID STREQUAL "Clang" )
        if ( CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${required_clang_version} )
            message(FATAL_ERROR "Clang version must be at least "
                    "${required_clang_version} for C++17 support, detected: "
                    "${CMAKE_CXX_COMPILER_VERSION}")
        endif ()
    endif ()

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
    cxx17_compile_test()

    set(HAVE_CXX17 true)
    return()
endif ()

# Need to manually retrieve compiler version.
if ( CMAKE_CXX_COMPILER_ID STREQUAL "GNU" )
    execute_process(COMMAND ${CMAKE_CXX_COMPILER} -dumpversion OUTPUT_VARIABLE
                    gcc_version)
    if ( ${gcc_version} VERSION_LESS ${required_gcc_version} )
        message(FATAL_ERROR "GCC version must be at least "
                "${required_gcc_version} for C++17 support, manually detected: "
                "${CMAKE_CXX_COMPILER_VERSION}")
    endif ()
elseif ( CMAKE_CXX_COMPILER_ID STREQUAL "Clang" )
    execute_process(COMMAND ${CMAKE_CXX_COMPILER} -v ERROR_VARIABLE
                    clang_version)
    string(REGEX REPLACE "^clang version ([^ ]+) .*" "\\1"
           clang_version "${clang_version}")
    if ( ${clang_version} VERSION_LESS ${required_clang_version} )
        message(FATAL_ERROR "GCC version must be at least "
                "${required_clang_version} for C++17 support, manually detected: "
                "${CMAKE_CXX_COMPILER_VERSION}")
    endif ()
endif ()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
cxx17_compile_test()

set(HAVE_CXX17 true)
