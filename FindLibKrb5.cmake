# - Try to find Krb5 headers and libraries
#
# Usage of this module as follows:
#
#     find_package(LibKrb5)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  LibKrb5_ROOT_DIR         Set this variable to the root installation of
#                            libKrb5 if the module has problems finding the
#                            proper installation path.
#
# Variables defined by this module:
#
#  LibKrb5_FOUND                   System has Krb5 libraries and headers
#  LibKrb5_LIBRARY                 The Krb5 library
#  LibKrb5_INCLUDE_DIR             The location of Krb5 headers

if (NOT LibKrb5_ROOT_DIR)
    if ("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
        # If we're on macOS, try using the brew binary potentially set by
        # MacDependencyPaths.cmake to search for a krb5 installation. Use that as a hint
        # to find the library.
        if (MAC_HBREW_BIN)
            execute_process(COMMAND ${MAC_HBREW_BIN} "--prefix" "krb5" OUTPUT_VARIABLE MAC_KRB5_HINT
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
        endif ()
        find_path(LibKrb5_ROOT_DIR NAMES include/krb5/krb5.h HINTS "${MAC_KRB5_HINT}")
    else ()
        find_path(LibKrb5_ROOT_DIR NAMES include/krb5/krb5.h)
    endif ()
endif ()

find_library(LibKrb5_LIBRARY NAMES krb5 HINTS ${LibKrb5_ROOT_DIR}/lib)

find_path(LibKrb5_INCLUDE_DIR NAMES krb5/krb5.h HINTS ${LibKrb5_ROOT_DIR}/include)

# If using macOS, make sure that we're not finding the system's libkrb5. It
# an old version, which points you at GSS.framework, which is also deprecated.
if (LibKrb5_LIBRARY AND "${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
    if ("${LibKrb5_LIBRARY}" MATCHES "^/Library/Developer/CommandLineTools/SDKs/.*"
        OR "${LibKrb5_LIBRARY}" MATCHES ".*/Developer/Platforms/MacOSX.platform/Developer/SDKs/.*")
        message(
            WARNING "Found macOS system version of libkrb5 at ${LibKrb5_LIBRARY}, which is known "
                    "to be unstable. Use a newer version, such as the one from Homebrew.")
        unset(LibKrb5_LIBRARY CACHE)
        unset(LibKrb5_INCLUDE_DIR CACHE)
    endif ()
endif ()

if (LibKrb5_LIBRARY AND LibKrb5_INCLUDE_DIR)
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(LibKrb5 DEFAULT_MSG LibKrb5_LIBRARY LibKrb5_INCLUDE_DIR)

    mark_as_advanced(LibKrb5_ROOT_DIR LibKrb5_LIBRARY LibKrb5_INCLUDE_DIR)
endif ()
