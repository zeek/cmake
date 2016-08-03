# - Determine if pybind11 is available
#
# Usage of this module as follows:
#
#  find_package(PythonInterp REQUIRED)
#  find_package(Pybind11)
#
# Variables used by this module (they can change the default behaviour and need
# to be set before calling find_package):
#
#  PYBIND11_ROOT_DIR  Set this variable either to the pybind11 source directory
#
# Variables defined by this module:
#
#  PYBIND11_FOUND             Python successfully imports pybind11
#  PYBIND11_INCLUDE_DIRS      The prefix to the pybind11 headers

if (NOT PYBIND11_FOUND)
  # Homebrew and Python make it difficult to solely rely on python-config to
  # figure out the exact include path. See http://bit.ly/homebrew-python for
  # details.
  if (APPLE)
    execute_process(COMMAND brew --prefix
      OUTPUT_VARIABLE HOMEBREW_PREFIX
      OUTPUT_STRIP_TRAILING_WHITESPACE
      RESULT_VARIABLE HOMEBREW_PREFIX_RESULT
      ERROR_QUIET)
    if (HOMEBREW_PREFIX_RESULT EQUAL 0)
      execute_process(COMMAND "${PYTHON_CONFIG}" --abiflags
                      OUTPUT_VARIABLE PYTHON_ABIFLAGS
                      OUTPUT_STRIP_TRAILING_WHITESPACE
                      ERROR_QUIET)
      set(major_minor ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR})
      set(PYTHON_HOMEBREW_INCLUDE_DIRS
          ${HOMEBREW_PREFIX}/include/python${major_minor}${PYTHON_ABIFLAGS})
    endif ()
  endif ()

  find_path(PYBIND11_INCLUDE_DIRS
    NAMES pybind11/pybind11.h
    HINTS ${PYBIND11_ROOT_DIR}
          ${PYBIND11_ROOT_DIR}/include
          ${PYTHON_HOMEBREW_INCLUDE_DIRS}
          ${PYTHON_INCLUDE_DIRS})
endif ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Pybind11
                                  REQUIRED_VARS PYBIND11_INCLUDE_DIRS)
