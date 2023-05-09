# - Try to find libmaxminddb headers and libraries
#
# Usage of this module as follows:
#
#     find_package(LibMMDB)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  LibMMDB_ROOT_DIR         Set this variable to the root installation of
#                           libmaxminddb if the module has problems finding the
#                           proper installation path.
#
# Variables defined by this module:
#
#  LibMMDB_FOUND                    System has libmaxminddb libraries and headers
#  LibMMDB_LIBRARY                  The libmaxminddb library
#  LibMMDB_INCLUDE_DIR              The location of libmaxminddb headers

find_path(LibMMDB_ROOT_DIR NAMES include/maxminddb.h)

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    # the static version of the library is preferred on OS X for the
    # purposes of making packages (libmaxminddb doesn't ship w/ OS X)
    set(libmmdb_names libmaxminddb.a maxminddb)
else ()
    set(libmmdb_names maxminddb)
endif ()

find_library(LibMMDB_LIBRARY NAMES ${libmmdb_names} HINTS ${LibMMDB_ROOT_DIR}/lib)

find_path(LibMMDB_INCLUDE_DIR NAMES maxminddb.h HINTS ${LibMMDB_ROOT_DIR}/include)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibMMDB DEFAULT_MSG LibMMDB_LIBRARY LibMMDB_INCLUDE_DIR)

mark_as_advanced(LibMMDB_ROOT_DIR LibMMDB_LIBRARY LibMMDB_INCLUDE_DIR)
