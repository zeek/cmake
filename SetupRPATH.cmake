# Keep RPATH upon installing so that user doesn't have to ensure the linker
# can find internal/private libraries or libraries external to the build
# directory that were explicitly linked against
if (NOT BINARY_PACKAGING_MODE)
    include(GNUInstallDirs)

    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
    set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_FULL_LIBDIR}")
endif ()
