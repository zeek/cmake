# - Try to find Zeek installation
#
# Usage of this module as follows:
#
#  find_package(Zeek)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  ZEEK_ROOT_DIR             Set this variable to the root installation of
#                            Zeek if the module has problems finding the
#                            proper installation path.
#
# Variables defined by this module:
#
#  BRO_FOUND                     Zeek is installed
#  ZEEK_EXE                      path to the 'zeek' binary

if (ZEEK_EXE AND ZEEK_ROOT_DIR)
    # this implies that we're building from the Zeek source tree
    set(BRO_FOUND true)
    return()
endif ()

find_program(ZEEK_EXE zeek
             HINTS ${ZEEK_ROOT_DIR}/bin /usr/local/zeek/bin /usr/local/bro/bin)

if (ZEEK_EXE)
    get_filename_component(ZEEK_ROOT_DIR ${ZEEK_EXE} PATH)
    get_filename_component(ZEEK_ROOT_DIR ${ZEEK_ROOT_DIR} PATH)
endif ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Zeek DEFAULT_MSG ZEEK_EXE)

mark_as_advanced(ZEEK_ROOT_DIR)
