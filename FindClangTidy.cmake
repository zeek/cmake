# Common functions to use clang-tidy. This requires you to have clang-tidy in your path. If you also
# have run-clang-tidy.py in your path, it will attempt to use that to run clang-tidy in parallel.

########################################################################
# If this hasn't been initialized yet, find the program and then create a global property
# to store the list of sources in.
if (NOT CLANG_TIDY)
    find_program(CLANG_TIDY NAMES clang-tidy)
    find_program(RUN_CLANG_TIDY NAMES run-clang-tidy)

    if (NOT RUN_CLANG_TIDY)
        find_program(RUN_CLANG_TIDY NAMES run-clang-tidy.py)
    endif ()

    if (CLANG_TIDY)
        define_property(
            GLOBAL
            PROPERTY TIDY_SRCS
            BRIEF_DOCS "Global list of sources for clang-tidy"
            FULL_DOCS "Global list of sources for clang-tidy")
        set_property(GLOBAL PROPERTY TIDY_SRCS "")
    endif ()
endif ()

########################################################################
# Adds a list of files to the global list of files that will be checked.
function (add_clang_tidy_files)
    if (CLANG_TIDY)
        foreach (f ${ARGV})
            if (IS_ABSOLUTE ${f})
                set_property(GLOBAL APPEND PROPERTY TIDY_SRCS "${f}")
            else ()
                set_property(GLOBAL APPEND PROPERTY TIDY_SRCS "${CMAKE_CURRENT_SOURCE_DIR}/${f}")
            endif ()
        endforeach (f)
    endif ()
endfunction ()

########################################################################
# Creates the final target using the global list of files.
function (create_clang_tidy_target)
    if (CLANG_TIDY)
        get_property(final_tidy_srcs GLOBAL PROPERTY TIDY_SRCS)
        list(REMOVE_DUPLICATES final_tidy_srcs)

        if (RUN_CLANG_TIDY)
            add_custom_target(
                clang-tidy
                COMMAND ${RUN_CLANG_TIDY} -p ${PROJECT_BINARY_DIR} -clang-tidy-binary ${CLANG_TIDY}
                        -j 4 -export-fixes ${PROJECT_BINARY_DIR}/clang-tidy.yaml ${final_tidy_srcs}
                WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
        else ()
            add_custom_target(
                clang-tidy COMMAND ${CLANG_TIDY} -p ${PROJECT_BINARY_DIR} ${final_tidy_srcs}
                WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
        endif ()
    endif ()
endfunction ()
