# - Try to find Python include dirs and libraries
#
# Usage of this module as follows:
#
#     find_package(PythonDev)
#
# Variables used by this module, they can change the default behaviour and need
# to be set before calling find_package:
#
#  PYTHON_EXECUTABLE         If this is set to a path to a Python interpreter
#                            then this module attempts to infer the path to
#                            python-config from it
#  PYTHON_CONFIG             Set this variable to the location of python-config
#                            if the module has problems finding the proper
#                            installation path.
#
# Variables defined by this module:
#
#  PYTHONDEV_FOUND           System has Python dev headers/libraries
#  PYTHON_INCLUDE_DIR        The Python include directories.
#  PYTHON_LIBRARIES          The Python libraries and linker flags.

include(FindPackageHandleStandardArgs)

if (CMAKE_CROSSCOMPILING)
    find_package(PythonLibs)
    if (PYTHON_INCLUDE_PATH AND NOT PYTHON_INCLUDE_DIR)
        set(PYTHON_INCLUDE_DIR "${PYTHON_INCLUDE_PATH}")
    endif ()
    find_package_handle_standard_args(PythonDev DEFAULT_MSG PYTHON_INCLUDE_DIR PYTHON_LIBRARIES)

    return()
endif ()

if (PYTHON_EXECUTABLE)
    # Get the real path so that we can reliably find the correct python-config
    # (e.g. some systems may have a "python" symlink, but not a "python-config"
    # symlink).
    get_filename_component(PYTHON_EXECUTABLE "${PYTHON_EXECUTABLE}" REALPATH)
    get_filename_component(PYTHON_EXECUTABLE_DIR "${PYTHON_EXECUTABLE}" DIRECTORY)
    get_filename_component(PYTHON_EXECUTABLE_NAME "${PYTHON_EXECUTABLE}" NAME)

    if (EXISTS ${PYTHON_EXECUTABLE}-config)
        set(PYTHON_CONFIG ${PYTHON_EXECUTABLE}-config CACHE PATH "" FORCE)
        # Avoid assumption that python-config is associated with python3 if
        # python3 co-exists in a directory that also contains python2 stuff
    elseif (
        EXISTS ${PYTHON_EXECUTABLE_DIR}/python-config
        AND NOT EXISTS ${PYTHON_EXECUTABLE_DIR}/python2
        AND NOT EXISTS ${PYTHON_EXECUTABLE_DIR}/python2.7
        AND NOT EXISTS ${PYTHON_EXECUTABLE_DIR}/python2-config
        AND NOT EXISTS ${PYTHON_EXECUTABLE_DIR}/python2.7-config)
        set(PYTHON_CONFIG ${PYTHON_EXECUTABLE_DIR}/python-config CACHE PATH "" FORCE)
    endif ()
else ()
    find_program(
        PYTHON_CONFIG
        NAMES python3-config
              python3.9-config
              python3.8-config
              python3.7-config
              python3.6-config
              python3.5-config
              python-config)
endif ()

# The OpenBSD python packages have python-config's that don't reliably
# report linking flags that will work.
if (PYTHON_CONFIG AND NOT ${CMAKE_SYSTEM_NAME} STREQUAL "OpenBSD")
    # Try `--ldflags --embed` first and fallback to `--ldflags` if it fails.
    # Python 3.8+ introduced the `--embed` flag in relation to this:
    # https://docs.python.org/3.8/whatsnew/3.8.html#debug-build-uses-the-same-abi-as-release-build
    # Note that even if this FindPythonDev script could technically apply to
    # either embedded or extension use cases, the `--embed` flag only adds
    # a `-lpython` and it's generally safe to link libpython in both cases.
    # The only downside to doing that against an extension when it's not
    # strictly necessary is losing the ability to mix-and-match debug/release
    # modes between Python and extensions and that's not a feature to typically
    # care about.
    execute_process(
        COMMAND "${PYTHON_CONFIG}" --ldflags --embed
        RESULT_VARIABLE _python_config_result
        OUTPUT_VARIABLE PYTHON_LIBRARIES
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    if (NOT ${_python_config_result} EQUAL 0)
        execute_process(
            COMMAND "${PYTHON_CONFIG}" --ldflags
            RESULT_VARIABLE _python_config_result
            OUTPUT_VARIABLE PYTHON_LIBRARIES
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    endif ()

    string(STRIP "${PYTHON_LIBRARIES}" PYTHON_LIBRARIES)

    execute_process(COMMAND "${PYTHON_CONFIG}" --includes OUTPUT_VARIABLE PYTHON_INCLUDE_DIR
                    OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    string(REGEX REPLACE "^[-I]" "" PYTHON_INCLUDE_DIR "${PYTHON_INCLUDE_DIR}")
    string(REGEX REPLACE "[ ]-I" " " PYTHON_INCLUDE_DIR "${PYTHON_INCLUDE_DIR}")
    separate_arguments(PYTHON_INCLUDE_DIR)

    find_package_handle_standard_args(PythonDev DEFAULT_MSG PYTHON_CONFIG PYTHON_INCLUDE_DIR
                                      PYTHON_LIBRARIES)
else ()
    if (${CMAKE_VERSION} VERSION_LESS "3.12.0")
        find_package(PythonLibs)

        if (PYTHON_INCLUDE_PATH AND NOT PYTHON_INCLUDE_DIR)
            set(PYTHON_INCLUDE_DIR "${PYTHON_INCLUDE_PATH}")
        endif ()
    else ()
        # Expect this branch to be used mostly in macOS where the system
        # default Python 3 installation is not easily/consistently detected
        # by CMake.  CMake 3.12+ is required, but it's expected that macOS
        # users are getting a recent version from homebrew/etc anyway.
        find_package(Python3 COMPONENTS Development)

        if (Python3_INCLUDE_DIRS AND NOT PYTHON_INCLUDE_DIR)
            set(PYTHON_INCLUDE_DIR "${Python3_INCLUDE_DIRS}")
        endif ()

        if (Python3_LIBRARIES AND NOT PYTHON_LIBRARIES)
            set(PYTHON_LIBRARIES "${Python3_LIBRARIES}")
        endif ()
    endif ()

    find_package_handle_standard_args(PythonDev DEFAULT_MSG PYTHON_INCLUDE_DIR PYTHON_LIBRARIES)
endif ()
