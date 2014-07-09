# Tries to locate libppa headers and libraries.
#
# Usage:
#
#     find_package(libcppa)
#
#     LIBCPPA_ROOT_DIR may be defined beforehand to hint at install location.
#
# Variables defined after calling:
#
#     LIBCPPA_FOUND       - whether a libcppa installation is located
#     LIBCPPA_INCLUDE_DIR - path to libcppa headers
#     LIBCPPA_LIBRARY     - path of libcppa library

find_path(LIBCPPA_ROOT_DIR
    NAMES include/cppa/cppa.hpp
)

find_path(LIBCPPA_INCLUDE_DIR
    NAMES cppa/cppa.hpp
    HINTS ${LIBCPPA_ROOT_DIR}/include
)

find_library(LIBCPPA_LIBRARY
    NAMES cppa
    HINTS ${LIBCPPA_ROOT_DIR}/lib
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(libcppa DEFAULT_MSG
    LIBCPPA_INCLUDE_DIR
    LIBCPPA_LIBRARY
)

mark_as_advanced(
    LIBCPPA_ROOT_DIR
    LIBCPPA_INCLUDE_DIR
    LIBCPPA_LIBRARY
)
