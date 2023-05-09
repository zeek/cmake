# Determine a tag for the host architecture (e.g., "linux-x86_64").
# We run uname ourselves here as CMAKE by default uses -p rather than
# -m.

execute_process(COMMAND uname -m OUTPUT_VARIABLE arch OUTPUT_STRIP_TRAILING_WHITESPACE)
set(HOST_ARCHITECTURE "${CMAKE_SYSTEM_NAME}-${arch}")
string(TOLOWER ${HOST_ARCHITECTURE} HOST_ARCHITECTURE)
