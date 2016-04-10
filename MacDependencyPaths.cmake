# As of CMake 2.8.3, Fink and MacPorts search paths are appended to the
# default search prefix paths, but the nicer thing would be if they are
# prepended to the default, so that is fixed here.
if (APPLE AND "${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    find_program(MAC_PORTS_BIN ports)
    find_program(MAC_HBREW_BIN brew)
    find_program(MAC_FINK_BIN fink)

    if (MAC_PORTS_BIN)
      list(INSERT CMAKE_PREFIX_PATH 0 ${MAC_PORTS_BIN}) # MacPorts
    endif ()
    
    if (MAC_HBREW_BIN)
        list(INSERT CMAKE_PREFIX_PATH 0 /usr/local) # Homebrew, if linked
        list(INSERT CMAKE_PREFIX_PATH 0 /usr/local/opt/openssl) # Homebrew OpenSSL
    endif ()

    if (MAC_FINK_BIN)
       list(INSERT CMAKE_PREFIX_PATH 0 /sw)        # Fink
    endif ()
    
endif ()
