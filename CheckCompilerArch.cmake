# Findm the name of the architecture that we compile to. Currently
# this is used for highwayhash - but may be generally useful.

include(CheckCSourceCompiles)

check_c_source_compiles(
    "
	#if defined(__x86_64__) || defined(_M_X64)
	int main() { return 0; }
	#else
	#error wrongarch
	#endif
"
    test_arch_x64)
check_c_source_compiles(
    "
	#if defined(__aarch64__) || defined(__arm64__)
	int main() { return 0; }
	#else
	#error wrongarch
	#endif
"
    test_arch_aarch64)
check_c_source_compiles(
    "
	#if defined(__arm__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
	int main() { return 0; }
	#else
	#error wrongarch
	#endif
"
    test_arch_arm)
check_c_source_compiles(
    "
	#if defined(__powerpc64__) || defined(_M_PPC)
	int main() { return 0; }
	#else
	#error wrongarch
	#endif
"
    test_arch_power)

if (test_arch_x64)
    set(COMPILER_ARCHITECTURE "x86_64")
elseif (test_arch_aarch64)
    set(COMPILER_ARCHITECTURE "aarch64")
elseif (test_arch_arm)
    set(COMPILER_ARCHITECTURE "arm")
elseif (test_arch_power)
    set(COMPILER_ARCHITECTURE "power")
else ()
    set(COMPILER_ARCHITECTURE "portable")
endif ()

message(STATUS "Determined target architecture (for hashing): ${COMPILER_ARCHITECTURE}")
