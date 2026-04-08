# Determine a tag for the host architecture (e.g., "linux-x86_64").
# We run uname ourselves here as CMAKE by default uses -p rather than
# -m.

if (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # On Windows, uname may not be available; use CMake's built-in variable.
    # Normalize AMD64 to x86_64 for consistency with uname -m used by
    # external plugin builds running under Git Bash.
    set(arch "${CMAKE_HOST_SYSTEM_PROCESSOR}")
    if (arch STREQUAL "AMD64")
        set(arch "x86_64")
    endif ()
else ()
    execute_process(COMMAND uname -m OUTPUT_VARIABLE arch OUTPUT_STRIP_TRAILING_WHITESPACE)
endif ()
set(HOST_ARCHITECTURE "${CMAKE_SYSTEM_NAME}-${arch}")
string(TOLOWER ${HOST_ARCHITECTURE} HOST_ARCHITECTURE)
