# Prohibit in-source builds.
if ("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")
    message(
        FATAL_ERROR
            "In-source builds are not allowed. Please use "
            "./configure to choose a build directory and " "initialize the build configuration.")
endif ()
