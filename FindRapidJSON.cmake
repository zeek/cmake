# - Try to find rapidjson headers.
#
# Usage of this module as follows:
#
#     find_package(RapidJSON)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  RAPIDJSON_ROOT_DIR     Set this variable to the root installation of
#                         RapidJSON if the module has problems finding the
#                         proper installation path.
#
# Variables defined by this module:
#
#  RAPIDJSON_INCLUDE_DIR      The location of rapidjson headers

find_path(RAPIDJSON_INCLUDE_DIR NAMES rapidjson/document.h HINTS ${RAPIDJSON_ROOT_DIR}/include)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(RapidJSON DEFAULT_MSG RAPIDJSON_INCLUDE_DIR)
