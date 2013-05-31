
# Creates a target for a library of objects file in a subdirectory,
# and adds to the global bro_SUBDIR_LIBS.
function(bro_add_subdir_library name)
    if ( bro_HAVE_OBJECT_LIBRARIES )
        add_library("bro_${name}" OBJECT ${ARGN})
        set(_target "$<TARGET_OBJECTS:bro_${name}>")
    else ()
        add_library("bro_${name}" STATIC ${ARGN})
        set(_target "bro_${name}")
    endif ()

    set(bro_SUBDIR_LIBS ${bro_SUBDIR_LIBS} "${_target}" CACHE INTERNAL "subdir libraries")
endfunction()
