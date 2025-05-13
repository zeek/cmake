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
    find_path(LibKrb5_ROOT_DIR NAMES include/krb5/krb5.h)
endif ()

find_library(LibKrb5_LIBRARY NAMES krb5 HINTS ${LibKrb5_ROOT_DIR}/lib)

find_path(LibKrb5_INCLUDE_DIR NAMES krb5/krb5.h HINTS ${LibKrb5_ROOT_DIR}/include)

# If using macOS, make sure that we're not finding the system's libkrb5. It
# an old version, which points you at GSS.framework, which is also deprecated.
if (LibKrb5_LIBRARY AND "${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
    if ("${LibKrb5_LIBRARY}" MATCHES "^/Library/Developer/CommandLineTools/SDKs/.*"
        OR "${LibKrb5_LIBRARY}" MATCHES ".*/Developer/Platforms/MacOSX.platform/Developer/SDKs/.*")
        message(
            FATAL_ERROR
                "Found macOS system version of libkrb5 at ${LibKrb5_LIBRARY}. Please use the version from Homebrew instead, which is known to be more stable."
        )
    endif ()
endif ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibKrb5 DEFAULT_MSG LibKrb5_LIBRARY LibKrb5_INCLUDE_DIR)

mark_as_advanced(LibKrb5_ROOT_DIR LibKrb5_LIBRARY LibKrb5_INCLUDE_DIR)
