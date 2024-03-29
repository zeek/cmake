# - Try to find Broker library and headers
#
# Usage of this module as follows:
#
#     find_package(Broker)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  BROKER_ROOT_DIR           Set this variable to the root installation of
#                            Broker if the module has problems finding the
#                            proper installation path.
#
# Variables defined by this module:
#
#  BROKER_FOUND              System has Broker library
#  BROKER_LIBRARY            The broker library
#  BROKER_INCLUDE_DIR        The broker headers

if (NOT BROKER_ROOT_DIR)
    find_path(BROKER_ROOT_DIR NAMES include/broker/broker.hh)
    set(header_hints "${BROKER_ROOT_DIR}/include")
else ()
    set(header_hints "${BROKER_ROOT_DIR}/include" "${BROKER_ROOT_DIR}/../include"
                     "${BROKER_ROOT_DIR}/../../include")
endif ()

find_library(BROKER_LIBRARY NAMES broker HINTS ${BROKER_ROOT_DIR}/lib)

find_path(broker_hh_dir NAMES broker/broker.hh HINTS ${header_hints})

find_path(config_hh_dir NAMES broker/config.hh HINTS ${header_hints})

if ("${broker_hh_dir}" STREQUAL "${config_hh_dir}")
    set(BROKER_INCLUDE_DIR "${broker_hh_dir}")
else ()
    set(BROKER_INCLUDE_DIR "${broker_hh_dir}" "${config_hh_dir}")
endif ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Broker DEFAULT_MSG BROKER_LIBRARY BROKER_INCLUDE_DIR)

mark_as_advanced(BROKER_ROOT_DIR BROKER_LIBRARY BROKER_INCLUDE_DIR)
