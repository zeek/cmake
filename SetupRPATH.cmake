# Keep RPATH upon installing so that user doesn't have to ensure the linker
# can find internal/private libraries or libraries external to the build
# directory that were explicitly linked against
if (NOT BINARY_PACKAGING_MODE)
    SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")

    include(GNUInstallDirs)

    if ( NOT CMAKE_INSTALL_LIBDIR STREQUAL "lib" )
        # Ideally, we'd consistently use just one lib dir (e.g. lib/ or lib64/),
        # which requires every sub-project and external/embedded dependency
        # agrees and/or offers ability to install at that canonical location.
        set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH};${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
    endif ()
endif ()
