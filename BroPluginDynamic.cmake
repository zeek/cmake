## A set of functions for defining Bro plugins.
##
## This set is for plugins compiled dynamically for loading at run-time.
## See BroPluginsStatic.cmake for the static version.
##
## Note: This is meant to run as a standalone CMakeLists.txt. It sets
## up all the basic infrastructure to compile a dynamic Bro plugin when
## included from its top-level CMake file.

include(CommonCMakeConfig)

if ( NOT BRO_DIST )
    message(FATAL_ERROR "BRO_DIST not set")
endif ()

if ( NOT EXISTS "${BRO_DIST}/build/CMakeCache.txt" )
    message(FATAL_ERROR "${BRO_DIST}/build/CMakeCache.txt; has Bro been built?")
endif ()

set(CMAKE_MODULE_PATH ${BRO_DIST}/cmake)

load_cache("${BRO_DIST}/build" READ_WITH_PREFIX bro_cache_ CMAKE_INSTALL_PREFIX Bro_BINARY_DIR Bro_SOURCE_DIR ENABLE_DEBUG BRO_PLUGIN_INSTALL_PATH BRO_EXE_PATH)

set(BRO_PLUGIN_BASE                    "${CMAKE_CURRENT_SOURCE_DIR}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_SCRIPTS                 "${BRO_PLUGIN_BASE}/scripts" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BUILD                   "${CMAKE_CURRENT_BINARY_DIR}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_LIB                     "${BRO_PLUGIN_BASE}/lib" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BIF                     "${BRO_PLUGIN_BASE}/lib/bif" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_MAGIC                   "${BRO_PLUGIN_BASE}/__bro_plugin__" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_README                  "${BRO_PLUGIN_BASE}/README" CACHE INTERNAL "" FORCE)

set(BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH "${bro_cache_BRO_PLUGIN_INSTALL_PATH}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BRO_SRC                 "${bro_cache_Bro_SOURCE_DIR}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BRO_BUILD               "${bro_cache_Bro_BINARY_DIR}" CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_BRO_EXE_PATH            "${bro_cache_BRO_EXE_PATH}" CACHE INTERNAL "" FORCE)

set(BRO_PLUGIN_ENABLE_DEBUG            "${bro_cache_ENABLE_DEBUG}"   CACHE INTERNAL "" FORCE)
set(BRO_PLUGIN_INTERNAL_BUILD          false CACHE INTERNAL "" FORCE)

message(STATUS "Bro executable      : ${BRO_PLUGIN_BRO_EXE_PATH}")
message(STATUS "Bro source          : ${BRO_PLUGIN_BRO_SRC}")
message(STATUS "Bro build           : ${BRO_PLUGIN_BRO_BUILD}")
message(STATUS "Bro install prefix  : ${BRO_PLUGIN_BRO_INSTALL_PREFIX}")
message(STATUS "Bro plugin directory: ${BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH}")

set(CMAKE_MODULE_PATH ${BRO_PLUGIN_BASE}/cmake)
set(CMAKE_MODULE_PATH ${BRO_PLUGIN_BRO_SRC}/cmake)

include_directories(BEFORE ${BRO_PLUGIN_BRO_SRC}/src
                           ${BRO_PLUGIN_BRO_SRC}/aux/binpac/lib
                           ${BRO_PLUGIN_BRO_BUILD}
                           ${BRO_PLUGIN_BRO_BUILD}/src
                           ${BRO_PLUGIN_BRO_BUILD}/aux/binpac/lib
                           ${CMAKE_CURRENT_BINARY_DIR}
                           ${CMAKE_CURRENT_BINARY_DIR}/src
                           ${CMAKE_CURRENT_SOURCE_DIR}
                           ${CMAKE_CURRENT_SOURCE_DIR}/src
                           )

set(ENV{PATH} "${BRO_PLUGIN_BRO_BUILD}/build/src:$ENV{PATH}")

set(bro_PLUGIN_LIBS CACHE INTERNAL "plugin libraries" FORCE)

add_definitions(-DBRO_PLUGIN_INTERNAL_BUILD=false)

include(BroPluginCommon)
include(GetArchitecture)

function(bro_plugin_end)

    # Create the dynamic library/bundle.
    add_library(${_plugin_lib} MODULE ${_plugin_objs})
    set_target_properties(${_plugin_lib} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${BRO_PLUGIN_LIB}")
    set_target_properties(${_plugin_lib} PROPERTIES PREFIX "")
    # set_target_properties(${_plugin_lib} PROPERTIES ENABLE_EXPORTS TRUE)

    if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        # Dy default Darwin's linker requires all symbols to be present at link time.
        set_target_properties(${_plugin_lib} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
    endif ()

    add_dependencies(${_plugin_lib} ${_plugin_deps})

    # Copy bif/*.bro.
    string(REPLACE "${BRO_PLUGIN_BASE}/" "" msg "Creating ${BRO_PLUGIN_BIF}")
    add_custom_target(copy-bif-${_plugin_name_canon}
            COMMAND "${CMAKE_COMMAND}" -E copy_directory ${CMAKE_CURRENT_BINARY_DIR}/bif ${BRO_PLUGIN_BIF}
            COMMENT "${msg}")

    # Create bif/__init__.bro.
    bro_bif_create_loader(bif-init-${_plugin_name_canon} ${BRO_PLUGIN_BIF})

    add_dependencies(bif-init-${_plugin_name_canon} ${_plugin_deps})
    add_dependencies(copy-bif-${_plugin_name_canon} ${_plugin_deps})
    add_dependencies(bif-init-${_plugin_name_canon} copy-bif-${_plugin_name_canon})
    add_dependencies(${_plugin_lib} bif-init-${_plugin_name_canon} copy-bif-${_plugin_name_canon})

    # Create __bro_plugin__
    string(REPLACE "${BRO_PLUGIN_BASE}/" "" msg "Creating ${BRO_PLUGIN_MAGIC}")
    add_custom_target(bro-plugin-${_plugin_name_canon}
			COMMAND echo "${_plugin_name}" ">${BRO_PLUGIN_MAGIC}"
            COMMENT "${msg}")

    add_dependencies(bro-plugin-${_plugin_name_canon} ${_plugin_deps})
    add_dependencies(${_plugin_lib} bro-plugin-${_plugin_name_canon})

    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${BRO_PLUGIN_BIF})
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${BRO_PLUGIN_LIB})
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${BRO_PLUGIN_MAGIC})

    ### Plugin installation.

    set(plugin_install "${BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH}/${_plugin_name_canon}")

    install(DIRECTORY ${BRO_PLUGIN_LIB}        DESTINATION ${plugin_install})
    install(DIRECTORY ${BRO_PLUGIN_SCRIPTS}    DESTINATION ${plugin_install})
    install(FILES     ${BRO_PLUGIN_MAGIC}      DESTINATION ${plugin_install})
    install(FILES     ${BRO_PLUGIN_README}     DESTINATION ${plugin_install})

endfunction()

# Function createing the library name.
macro(_plugin_target_name target ns name)
    set(${target} "${ns}-${name}.${HOST_ARCHITECTURE}")
endmacro()

