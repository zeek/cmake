# Detect if compiler version is sufficient for supporting C++17.
# If it is, CMAKE_CXX_FLAGS are modified appropriately and HAVE_CXX17
# is set to a true value.  Else, CMake exits with a fatal error message.
# This currently only works for GCC and Clang compilers.
# In Cmake 3.8+, CMAKE_CXX_STANDARD_REQUIRED should be able to replace
# all the logic below.

if (DEFINED HAVE_CXX17)
    return()
endif ()

set(required_gcc_version 7.0)
set(required_clang_version 4.0)
set(required_msvc_version 19.14)
set(required_apple_clang_version 6.0)

if (MSVC)
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${required_msvc_version})
        message(
            FATAL_ERROR
                "MSVC version must be at least "
                "${required_gcc_version} for C++17 support, detected: "
                "${CMAKE_CXX_COMPILER_VERSION}")
    endif ()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17")
    set(HAVE_CXX17 true)
    return()
endif ()

include(CheckCXXSourceCompiles)

set(cxx17_testcode "#include <optional>
     int main() { std::optional<int> a; }")

check_cxx_source_compiles("${cxx17_testcode}" cxx17_already_works)

if (cxx17_already_works)
    # Nothing to do. Flags already select a suitable C++ version.
    set(HAVE_CXX17 true)
    return()
endif ()

set(cxx17_flag "-std=c++17")

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${required_gcc_version})
        message(
            FATAL_ERROR
                "GCC version must be at least "
                "${required_gcc_version} for C++17 support, detected: "
                "${CMAKE_CXX_COMPILER_VERSION}")
    endif ()
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${required_clang_version})
        message(
            FATAL_ERROR
                "Clang version must be at least "
                "${required_clang_version} for C++17 support, detected: "
                "${CMAKE_CXX_COMPILER_VERSION}")
    endif ()
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 5)
        set(cxx17_flag "-std=c++1z")
    endif ()
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${required_apple_clang_version})
        message(
            FATAL_ERROR
                "Apple Clang version must be at least "
                "${required_apple_clang_version} for C++17 support, detected: "
                "${CMAKE_CXX_COMPILER_VERSION}")
    endif ()
else ()
    # Unrecognized compiler: fine to be permissive of other compilers as long
    # as they are able to support C++17 and can compile the test program, but
    # we just won't be able to give specific advice on what compiler version a
    # user needs in the case it actually doesn't support C++17.
endif ()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${cxx17_flag}")

check_cxx_source_compiles("${cxx17_testcode}" cxx17_works)

if (NOT cxx17_works)
    message(FATAL_ERROR "failed using C++17 for compilation")
endif ()

set(HAVE_CXX17 true)
