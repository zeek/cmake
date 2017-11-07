# Detect if compiler version is sufficient for supporting C++11.
# If it is, CMAKE_CXX_FLAGS are modified appropriately and HAVE_CXX11
# is set to a true value.  Else, CMake exits with a fatal error message.
# This currently only works for GCC and Clang compilers.
# In Cmake 3.1+, CMAKE_CXX_STANDARD_REQUIRED should be able to replace
# all the logic below.

if ( DEFINED HAVE_CXX11 )
    return()
endif ()

include(CheckCXXSourceCompiles)

set(required_gcc_version 4.8)
set(required_clang_version 3.3)

macro(cxx11_compile_test)
    # test a header file that has to be present in C++11
    check_cxx_source_compiles("
    #include <array>
    #include <iostream>
        int main() {
            std::array<int, 2> a{ {1, 2} };
            for (const auto& e: a)
                std::cout << e << ' ';
            std::cout << std::endl;
            }
        " cxx11_header_works)

    if (NOT cxx11_header_works)
        message(FATAL_ERROR "C++11 headers cannot be used for compilation")
    endif ()
endmacro()

# CMAKE_CXX_COMPILER_VERSION may not always be available (e.g. particularly
# for CMakes older than 2.8.10, but use it if it exists.
if ( DEFINED CMAKE_CXX_COMPILER_VERSION )
    if ( CMAKE_CXX_COMPILER_ID STREQUAL "GNU" )
        if ( CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${required_gcc_version} )
            message(FATAL_ERROR "GCC version must be at least "
                    "${required_gcc_version} for C++11 support, detected: "
                    "${CMAKE_CXX_COMPILER_VERSION}")
        endif ()
    elseif ( CMAKE_CXX_COMPILER_ID STREQUAL "Clang" )
        if ( CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${required_clang_version} )
            message(FATAL_ERROR "Clang version must be at least "
                    "${required_clang_version} for C++11 support, detected: "
                    "${CMAKE_CXX_COMPILER_VERSION}")
        endif ()
    endif ()

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    cxx11_compile_test()

    set(HAVE_CXX11 true)
    return()
endif ()

# Need to manually retrieve compiler version.
if ( CMAKE_CXX_COMPILER_ID STREQUAL "GNU" )
    execute_process(COMMAND ${CMAKE_CXX_COMPILER} -dumpversion OUTPUT_VARIABLE
                    gcc_version)
    if ( ${gcc_version} VERSION_LESS ${required_gcc_version} )
        message(FATAL_ERROR "GCC version must be at least "
                "${required_gcc_version} for C++11 support, manually detected: "
                "${CMAKE_CXX_COMPILER_VERSION}")
    endif ()
elseif ( CMAKE_CXX_COMPILER_ID STREQUAL "Clang" )
    # TODO: don't seem to be any great/easy ways to get a clang version string.
endif ()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
cxx11_compile_test()

set(HAVE_CXX11 true)
