
# Determine a tag for the host architecture (e.g., "linux-x86_64").
set(HOST_ARCHITECTURE "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
string(TOLOWER ${HOST_ARCHITECTURE} HOST_ARCHITECTURE)
