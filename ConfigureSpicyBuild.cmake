# Adapt the Spicy build to compiling it as part of Zeek, when some
# defaults might be set differently than what Spicy expects.
#
# This is included from the top-level CMakelists.txt after the Spicy
# subdirectory has been added.

# We set custom compile options on the main Spicy targets.
set(_spicy_targets
    hilti-config
    hilti-objects
    hilti-rt-debug-objects
    hilti-rt-objects
    hiltic
    jrx-objects
    retest
    spicy-batch-extract
    spicy-config
    spicy-driver
    spicy-objects
    spicy-rt-debug-objects
    spicy-rt-objects
    spicyc
    testregex
    spicy-doc
    spicy-dump)

include(CheckCXXCompilerFlag)
check_cxx_compiler_flag("-Wno-changes-meaning" _has_no_changes_meaning_flag)

foreach (_target ${_spicy_targets})
    # Spicy uses slightly less strict warnings than Zeek proper. Mute a few
    # warnings for Spicy.
    target_compile_options(${_target} PRIVATE -Wno-missing-braces -Wno-vla)
    if (_has_no_changes_meaning_flag)
        # GCC 13 adds a new flag to check whether a symbol changes meaning. Due
        # to an issue in one of the dependencies used by Spicy, this causes
        # Zeek to fail to build on that compiler. Until this is fixed, ignore
        # that warning, but check to to make sure the flag exists first.
        target_compile_options(${_target} PRIVATE -Wno-changes-meaning)
    endif ()
endforeach ()

# Disable Spicy unit test targets.
#
# Spicy builds its unit tests as part of `ALL`. They are usually not only
# uninteresting for us but might cause problems. Since any configuration we do
# for our unit tests happens through global C++ compiler flags, they would get
# inherited directly by Spicy which can cause issues, e.g., we set
# `-DDOCTEST_CONFIG_DISABLE` if `ENABLE_ZEEK_UNIT_TESTS` is false, but Spicy
# unit test do not anticipate this define being set.
set_target_properties(hilti-rt-tests hilti-rt-configuration-tests spicy-rt-tests
                      hilti-toolchain-tests spicy-toolchain-tests PROPERTIES EXCLUDE_FROM_ALL TRUE)

get_directory_property(SPICY_VERSION_NUMBER DIRECTORY ${PROJECT_SOURCE_DIR}/auxil/spicy/spicy
                                                      DEFINITION SPICY_VERSION_NUMBER)
