# As of CMake 2.8.3, Fink and MacPorts search paths are appended to the
# default search prefix paths, but the nicer thing would be if they are
# prepended to the default, so that is fixed here.

# Prepend the default search path locations, in case for some reason the
# ports/brew/fink executables are not found.
# If they are found, the actual paths will be pre-pended again below.
list(PREPEND CMAKE_PREFIX_PATH /usr/local)
list(PREPEND CMAKE_PREFIX_PATH /opt/local)
list(PREPEND CMAKE_PREFIX_PATH /sw)

if (APPLE AND "${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    find_program(MAC_PORTS_BIN ports)
    find_program(MAC_HBREW_BIN brew)
    find_program(MAC_FINK_BIN fink)

    if (MAC_PORTS_BIN)
        list(PREPEND CMAKE_PREFIX_PATH ${MAC_PORTS_BIN}) # MacPorts
    endif ()

    if (MAC_HBREW_BIN)
        execute_process(COMMAND ${MAC_HBREW_BIN} "--prefix" OUTPUT_VARIABLE BREW_PREFIX
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        # Homebrew, if linked
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX})
        # Homebrew OpenSSL
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX}/opt/openssl)
        # Homebrew Bison
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX}/opt/bison/bin)
        # Homebrew Flex
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX}/opt/flex/bin)
        # Homebrew actor-framework
        list(PREPEND CMAKE_PREFIX_PATH ${BREW_PREFIX}/opt/actor-framework)
    endif ()

    if (MAC_FINK_BIN)
        list(PREPEND CMAKE_PREFIX_PATH /sw) # Fink
    endif ()

endif ()
