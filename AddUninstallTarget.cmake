if (NOT TARGET uninstall)
    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in")
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
                       "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake" @ONLY)
        add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P
                                            ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
    endif ()
endif ()
