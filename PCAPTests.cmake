include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckCSourceCompiles)
include(CheckIncludeFiles)

set(PCAP_OS_LIBRARIES)
if (MSVC)
    set(PCAP_OS_LIBRARIES ws2_32.lib Crypt32.lib ${OPENSSL_LIBRARIES})
endif ()
set(CMAKE_REQUIRED_INCLUDES ${PCAP_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${PCAP_LIBRARY} ${PCAP_OS_LIBRARIES})

cmake_policy(PUSH)

if (POLICY CMP0075)
    # It's fine that check_include_files links against CMAKE_REQUIRED_LIBRARIES
    cmake_policy(SET CMP0075 NEW)
endif ()

check_include_files(pcap-int.h HAVE_PCAP_INT_H)

cmake_policy(POP)

check_function_exists(pcap_freecode HAVE_LIBPCAP_PCAP_FREECODE)
if (NOT HAVE_LIBPCAP_PCAP_FREECODE)
    set(DONT_HAVE_LIBPCAP_PCAP_FREECODE true)
    message(STATUS "No implementation for pcap_freecode()")
endif ()

check_symbol_exists(DLT_PPP_SERIAL pcap.h HAVE_DLT_PPP_SERIAL)
if (NOT HAVE_DLT_PPP_SERIAL)
    set(DLT_PPP_SERIAL 50)
endif ()

check_symbol_exists(DLT_NFLOG pcap.h HAVE_DLT_NFLOG)
if (NOT HAVE_DLT_NFLOG)
    set(DLT_NFLOG 239)
endif ()

check_symbol_exists(DLT_LINUX_SLL2 pcap.h HAVE_DLT_LINUX_SLL2)
if (NOT HAVE_DLT_LINUX_SLL2)
    set(DONT_HAVE_LIBPCAP_DLT_LINUX_SLL2 true)
    message(STATUS "No DLT_LINUX_SLL2 support in libpcap")
endif ()

set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES)
