## A set of functions for defining Zeek plugins.
##
## This set is used by both static and dynamic plugins via
## ZeekPluginStatic and ZeekPluginDynamic, respectively.

# Begins a plugin definition, giving its namespace and name as the arguments.
# The DISABLE_CPP_TESTS option disables unit test support. When not provided,
# unit-testing is enabled when Zeek supports it, and disabled otherwise.
macro (zeek_plugin_begin ns name)
    zeek_get_plugin_target(_plugin_lib ${ns} ${name})
    if (ZEEK_PLUGIN_BUILD_DYNAMIC)
        add_library(${_plugin_lib} MODULE)
    else ()
        add_library(${_plugin_lib} OBJECT)
    endif ()
    set(_plugin_name "${ns}::${name}")
    set(_plugin_name_canon "${ns}_${name}")
    set(_plugin_name_plain "${name}")
    set(_plugin_ns "${ns}")
    set(_plugin_cpp "")
    set(_plugin_dist "")
    set(_plugin_scripts "")
    set(_plugin_link_libs "")
    set(_plugin_bif_files "")
    set(_plugin_pac_args "")
endmacro ()

# Adds specified .zeek scripts to a plugin
# scripts will be added to the distribution regardless of this
# but adding them explicitly allows tracking changes in scripts
# when building dist
macro (zeek_plugin_scripts)
    list(APPEND _plugin_scripts ${ARGV})
endmacro ()

# Adds *.cc files to a plugin.
macro (zeek_plugin_cc)
    list(APPEND _plugin_cpp ${ARGV})
endmacro ()

# Adds a *.pac file to a plugin. Further *.pac files may given that
# it depends on.
macro (zeek_plugin_pac)
    list(APPEND _plugin_pac_args PAC ${ARGN})
endmacro ()

# Add additional files that should be included into the binary plugin distribution.
# Ignored for static plugins.
macro (zeek_plugin_dist_files)
    list(APPEND _plugin_dist ${ARGV})
endmacro ()

# Link an additional library to the plugin's library.
macro (zeek_plugin_link_library)
    list(APPEND _plugin_link_libs ${ARGV})
endmacro ()

# Adds *.bif files to a plugin.
macro (zeek_plugin_bif)
    list(APPEND _plugin_bif_files ${ARGV})
endmacro ()

# Ends a plugin definition.
macro (zeek_plugin_end)
    zeek_add_plugin(
        ${_plugin_ns}
        ${_plugin_name_plain}
        SOURCES
        ${_plugin_cpp}
        DEPENDENCIES
        ${_plugin_link_libs}
        BIFS
        ${_plugin_bif_files}
        DIST_FILES
        ${_plugin_dist}
        ${_plugin_pac_args})

    if (POLICY CMP0110)
        cmake_policy(SET CMP0110 NEW)
    endif ()

    # Scan relevant files for TEST_CASE macros and generate CTest targets.
    # This is similar to the logic in Zeek's src/CMakeLists.txt.
    if (_plugin_cpp_tests)
        set(test_cases "")
        foreach (cc_file ${_plugin_cpp_test_sources})
            file(STRINGS ${cc_file} test_case_lines REGEX "TEST_CASE")
            foreach (line ${test_case_lines})
                string(REGEX REPLACE "TEST_CASE\\(\"(.+)\"\\)" "\\1" test_case "${line}")
                list(APPEND test_cases "${test_case}")
            endforeach ()
        endforeach ()
        list(LENGTH test_cases num_test_cases)
        if (${num_test_cases} GREATER 0)
            foreach (test_case ${test_cases})
                add_test(NAME "${test_case}" COMMAND zeek --test "--test-case=${test_case}")
            endforeach ()
        endif ()
    endif ()
endmacro ()

# -- wrappers for legacy bro_* function names ----------------------------------

macro (bro_plugin_begin)
    message(DEPRECATION "please use zeek_add_plugin instead")
    zeek_plugin_begin(${ARGV})
endmacro ()

macro (bro_plugin_cc)
    zeek_plugin_cc(${ARGV})
endmacro ()

macro (bro_plugin_pac)
    zeek_plugin_pac(${ARGV})
endmacro ()

macro (bro_plugin_dist_files)
    zeek_plugin_dist_files(${ARGV})
endmacro ()

macro (bro_plugin_link_library)
    zeek_plugin_link_library(${ARGV})
endmacro ()

macro (bro_plugin_bif)
    zeek_plugin_bif(${ARGV})
endmacro ()

macro (bro_plugin_end)
    zeek_plugin_end(${ARGV})
endmacro ()
