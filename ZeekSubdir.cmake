# Creates a target for a library of objects file in a subdirectory,
# and adds to the global bro_SUBDIR_LIBS.
function (bro_add_subdir_library name)
    add_library("bro_${name}" OBJECT ${ARGN})
    set(bro_SUBDIR_LIBS "$<TARGET_OBJECTS:bro_${name}>" ${bro_SUBDIR_LIBS} CACHE INTERNAL
                                                                                 "subdir libraries")
    set(bro_SUBDIR_DEPS "bro_${name}" ${bro_SUBDIR_DEPS} CACHE INTERNAL "subdir dependencies")
    add_clang_tidy_files(${ARGN})
endfunction ()
