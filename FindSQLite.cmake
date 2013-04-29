# - Try to find SQLite headers and libraries.
#
# Usage of this module as follows:
#
#     find_package(SQLite)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  SQLite_ROOT_DIR  Set this variable to the root installation of
#                   SQLite if the module has problems finding
#                   the proper installation path.
#
# Variables defined by this module:
#
#  SQLITE_FOUND              System has SQLite libs/headers
#  SQLite_LIBRARIES          The SQLite libraries
#  SQLite_INCLUDE_DIR        The location of SQLite headers
#  SQLite_VERSION            The SQLite version string

find_path(SQLite_ROOT_DIR
    NAMES include/sqlite3.h
)

find_library(SQLite_LIBRARIES
    NAMES sqlite3
    HINTS ${SQLite_ROOT_DIR}/lib
)

find_path(SQLite_INCLUDE_DIR
    NAMES sqlite3.h
    HINTS ${SQLite_ROOT_DIR}/include
)

if (SQLite_INCLUDE_DIR AND EXISTS "${SQLite_INCLUDE_DIR}/sqlite3.h")
    file(STRINGS "${SQLite_INCLUDE_DIR}/sqlite3.h" SQLite_H
         REGEX "^#define SQLITE_VERSION.*\"[^\"]*\"$")
    string(REGEX REPLACE "^.*SQLITE_VERSION.*\"(.*)\".*$" "\\1"
           SQLite_VERSION "${SQLite_H}")

    if (SQLite_VERSION)
        message(STATUS "Found SQLite version: ${SQLite_VERSION}")
    endif ()
endif ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SQLite DEFAULT_MSG
    SQLite_LIBRARIES
    SQLite_INCLUDE_DIR
)

mark_as_advanced(
    SQLite_ROOT_DIR
    SQLite_LIBRARIES
    SQLite_INCLUDE_DIR
)
