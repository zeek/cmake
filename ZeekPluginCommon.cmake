## A set of functions for defining Zeek plugins.
##
## This set is used by both static and dynamic plugins via
## ZeekPluginStatic and ZeekPluginDynamic, respectively.

include(RequireCXX17)
include(FindClangTidy)

include(BifCl)
include(BinPAC)

# CTest support: the following does not work when called from a function. We
# enable it always, but add tests only when zeek_plugin_begin() doesn't disable
# testing and Zeek has unit-test support.
enable_testing()

# Begins a plugin definition, giving its namespace and name as the arguments.
# The DISABLE_CPP_TESTS option disables unit test support. When not provided,
# unit-testing is enabled when Zeek supports it, and disabled otherwise.
function(zeek_plugin_begin ns name)
    _plugin_target_name(target "${ns}" "${name}")
    set(_plugin_lib        "${target}" PARENT_SCOPE)
    set(_plugin_name       "${ns}::${name}" PARENT_SCOPE)
    set(_plugin_name_canon "${ns}_${name}" PARENT_SCOPE)
    set(_plugin_ns         "${ns}" PARENT_SCOPE)
    set(_plugin_objs       "" PARENT_SCOPE)
    set(_plugin_deps       "" PARENT_SCOPE)
    set(_plugin_dist       "" PARENT_SCOPE)
    set(_plugin_scripts    "" PARENT_SCOPE)

    cmake_parse_arguments(PARSE_ARGV 2 ZEEK_PLUGIN "DISABLE_CPP_TESTS" "" "")

    # Whether to build the plugin with unit-test support
    set(_plugin_cpp_tests true PARENT_SCOPE)
    # The set of files to check for unit tests
    set(_plugin_cpp_test_sources "" PARENT_SCOPE)

    # Cover the dynamic case (ZEEK_HAS_CPP_TESTS, based on zeek --test return
    # code), the static one (ENABLE_ZEEK_UNIT_TESTS, provided by the build
    # system), and a possible override if the caller opted to DISABLE_CPP_TESTS.
    if ( (ZEEK_HAS_CPP_TESTS OR ENABLE_ZEEK_UNIT_TESTS)
            AND NOT ZEEK_PLUGIN_DISABLE_CPP_TESTS )
        add_definitions(-DDOCTEST_CONFIG_SUPER_FAST_ASSERTS)
    else ()
        set(_plugin_cpp_tests false PARENT_SCOPE)
        add_definitions(-DDOCTEST_CONFIG_DISABLE)
    endif()
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_begin)
    zeek_plugin_begin(${ARGV})
endmacro()

# Adds specified .zeek scripts to a plugin
# scripts will be added to the distribution regardless of this
# but adding them explicitly allows tracking changes in scripts
# when building dist
function(zeek_plugin_scripts)
    list(APPEND _plugin_scripts ${ARGV})
    set(_plugin_scripts "${_plugin_scripts}" PARENT_SCOPE)
endfunction()

# Adds *.cc files to a plugin.
function(zeek_plugin_cc)
    list(APPEND _plugin_objs ${ARGV})
    list(APPEND _plugin_cpp_test_sources ${ARGV})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    set(_plugin_cpp_test_sources "${_plugin_cpp_test_sources}" PARENT_SCOPE)
    add_clang_tidy_files(${ARGV})
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_cc)
    zeek_plugin_cc(${ARGV})
endmacro()

# Adds a *.pac file to a plugin. Further *.pac files may given that
# it depends on.
function(zeek_plugin_pac)
    binpac_target(${ARGV})
    list(APPEND _plugin_objs ${BINPAC_OUTPUT_CC})
    list(APPEND _plugin_deps ${BINPAC_BUILD_TARGET})
    set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    set(_plugin_deps "${_plugin_deps}" PARENT_SCOPE)
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_pac)
    zeek_plugin_pac(${ARGV})
endmacro()

# Add an additional object file to the plugin's library.
function(zeek_plugin_obj)
    foreach ( bif ${ARGV} )
        list(APPEND _plugin_objs ${bif})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
    endforeach ()
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_obj)
    zeek_plugin_obj(${ARGV})
endmacro()

# Add additional files that should be included into the binary plugin distribution.
# Ignored for static plugins.
macro(zeek_plugin_dist_files)
    foreach ( file ${ARGV} )
        list(APPEND _plugin_dist ${file})
        # Don't need this here, and generates an error that
        # there is not parent scope. Not sure why it does that
        # here but not for other macros doing something similar.
        # set(_plugin_dist "${_plugin_dist}" PARENT_SCOPE)
    endforeach ()
endmacro()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_dist_files)
    zeek_plugin_dist_files(${ARGV})
endmacro()

# Link an additional library to the plugin's library.
function(zeek_plugin_link_library)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_link_library_dynamic(${ARGV})
    else ()
        bro_plugin_link_library_static(${ARGV})
    endif ()
endfunction()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_link_library)
    zeek_plugin_link_library(${ARGV})
endmacro()

# Adds *.bif files to a plugin.
macro(zeek_plugin_bif)
    list(APPEND _plugin_cpp_test_sources ${ARGV})

    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_bif_dynamic(${ARGV})
    else ()
        bro_plugin_bif_static(${ARGV})
    endif ()
endmacro()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_bif)
    zeek_plugin_bif(${ARGV})
endmacro()

# Ends a plugin definition.
macro(zeek_plugin_end)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        bro_plugin_end_dynamic(${ARGV})
    else ()
        bro_plugin_end_static(${ARGV})
    endif ()

    # Scan relevant files for TEST_CASE macros and generate CTest targets.
    # This is similar to the logic in Zeek's src/CMakeLists.txt.
    if (_plugin_cpp_tests)
        set(test_cases "")
        foreach (cc_file ${_plugin_cpp_test_sources})
            file (STRINGS ${cc_file} test_case_lines REGEX "TEST_CASE")
            foreach (line ${test_case_lines})
                string(REGEX REPLACE "TEST_CASE\\(\"(.+)\"\\)" "\\1" test_case "${line}")
                list(APPEND test_cases "${test_case}")
            endforeach ()
        endforeach ()
        list(LENGTH test_cases num_test_cases)
        if (${num_test_cases} GREATER 0)
            foreach (test_case ${test_cases})
                add_test(NAME "${test_case}"
                    COMMAND zeek --test "--test-case=${test_case}")
            endforeach()
        endif ()
    endif ()
endmacro()

# This is needed to support legacy Bro plugins.
macro(bro_plugin_end)
    zeek_plugin_end(${ARGV})
endmacro()

# Internal macro to create a unique target name for a plugin.
macro(_plugin_target_name target ns name)
    if ( ZEEK_PLUGIN_BUILD_DYNAMIC )
        _plugin_target_name_dynamic(${ARGV})
    else ()
        _plugin_target_name_static(${ARGV})
    endif ()
endmacro()
