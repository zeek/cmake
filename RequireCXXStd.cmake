# Check for a specific C++ standard level, and require the compiler to
# support that via some CMake settings.

if (DEFINED ZEEK_CXX_STD)
    return()
endif ()

# Require a specific C++ standard and set the proper flag when creating targets.
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 20)

# Disable using extensions provided by various compilers. Notably this keeps us
# setting it to c++20 instead of gnu++20 with GCC.
set(CMAKE_CXX_EXTENSIONS OFF)

set(_old_cmake_required_flags "${CMAKE_REQUIRED_FLAGS}")
if (MSVC)
    set(CMAKE_REQUIRED_FLAGS "/std:c++20")
else ()
    set(CMAKE_REQUIRED_FLAGS "-std=c++20")
endif ()

include(CheckCXXSourceCompiles)

# The <version> header is a good baseline version of C++20 support for us
# since we can use it to determine support for various features in other
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
