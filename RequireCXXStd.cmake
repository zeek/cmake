# Detect if compiler version is sufficient for supporting C++20.
# If it is, CMAKE_CXX_FLAGS are modified appropriately and HAVE_CXX17
# is set to a true value.  Else, CMake exits with a fatal error message.
# This currently only works for GCC and Clang compilers.
# In Cmake 3.8+, CMAKE_CXX_STANDARD_REQUIRED should be able to replace
# all the logic below.

if (DEFINED ZEEK_CXX_STD)
    return()
endif ()

set(_old_cmake_required_flags "${CMAKE_REQUIRED_FLAGS}")
if (MSVC)
    set(CMAKE_REQUIRED_FLAGS "/std:c++20")
else ()
    set(CMAKE_REQUIRED_FLAGS "-std=c++20")
endif ()

include(CheckCXXSourceCompiles)

# The <version> header is a good baseline version of C++20 support for us
# since we'll use it to ddetermine support for various features in other
# places.
set(cxx_std_testcode "#include <version>
     int main() { }")

check_cxx_source_compiles("${cxx_std_testcode}" cxx_std_works)

set(CMAKE_REQUIRED_FLAGS "${_old_cmake_required_flags}")

if (cxx_std_works)
    set(ZEEK_CXX_STD cxx_std_20)
else ()
    message(FATAL_ERROR "failed using C++20 for compilation")
endif ()
