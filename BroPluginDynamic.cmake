## A set of functions for defining Bro plugins.
##
## This set is for plugins compiled dynamically for loading at run-time.
## See BroPluginsStatic.cmake for the static version.
##
## Note: This is meant to run as a standalone CMakeLists.txt. It sets
## up all the basic infrastructure to compile a dynamic Bro plugin when
## included from its top-level CMake file.

if ( NOT BRO_PLUGIN_INTERNAL_BUILD )
   set(BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH "${BRO_PLUGIN_INSTALL_ROOT}"
       CACHE INTERNAL "" FORCE)

    if ( BRO_DIST )
        include(${BRO_DIST}/cmake/CommonCMakeConfig.cmake)

        if ( NOT EXISTS "${BRO_DIST}/build/CMakeCache.txt" )
           message(FATAL_ERROR
                   "${BRO_DIST}/build/CMakeCache.txt; has Bro been built?")
        endif ()

        load_cache("${BRO_DIST}/build" READ_WITH_PREFIX bro_cache_
                   CMAKE_INSTALL_PREFIX
                   Bro_BINARY_DIR
                   Bro_SOURCE_DIR
                   ENABLE_DEBUG
                   BRO_PLUGIN_INSTALL_PATH
                   BRO_EXE_PATH
                   CMAKE_CXX_FLAGS
                   CMAKE_C_FLAGS
                   CAF_INCLUDE_DIR_CORE
                   CAF_INCLUDE_DIR_IO
                   CAF_INCLUDE_DIR_OPENSSL)

        if ( NOT BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH )
           set(BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH
               "${bro_cache_BRO_PLUGIN_INSTALL_PATH}" CACHE INTERNAL "" FORCE)
        endif ()

        set(BRO_PLUGIN_BRO_INSTALL_PREFIX "${bro_cache_CMAKE_INSTALL_PREFIX}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_ENABLE_DEBUG "${bro_cache_ENABLE_DEBUG}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_SRC "${bro_cache_Bro_SOURCE_DIR}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_BUILD "${bro_cache_Bro_BINARY_DIR}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_EXE_PATH "${bro_cache_BRO_EXE_PATH}"
            CACHE INTERNAL "" FORCE)

        set(BRO_PLUGIN_BRO_CMAKE ${BRO_PLUGIN_BRO_SRC}/cmake)
        set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})
        set(CMAKE_MODULE_PATH ${BRO_PLUGIN_BRO_CMAKE} ${CMAKE_MODULE_PATH})
        set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   ${bro_cache_CMAKE_C_FLAGS}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${bro_cache_CMAKE_CXX_FLAGS}")

        include_directories(BEFORE
                            ${BRO_PLUGIN_BRO_SRC}/src
                            ${BRO_PLUGIN_BRO_SRC}/aux/binpac/lib
                            ${BRO_PLUGIN_BRO_SRC}/aux/broker
                            ${BRO_PLUGIN_BRO_BUILD}
                            ${BRO_PLUGIN_BRO_BUILD}/src
                            ${BRO_PLUGIN_BRO_BUILD}/aux/binpac/lib
                            ${BRO_PLUGIN_BRO_BUILD}/aux/broker
                            ${bro_cache_CAF_INCLUDE_DIR_CORE}
                            ${bro_cache_CAF_INCLUDE_DIR_IO}
                            ${bro_cache_CAF_INCLUDE_DIR_OPENSSL}
                            ${CMAKE_CURRENT_BINARY_DIR}
                            ${CMAKE_CURRENT_BINARY_DIR}/src
                            ${CMAKE_CURRENT_SOURCE_DIR}
                            ${CMAKE_CURRENT_SOURCE_DIR}/src
                            )

        set(ENV{PATH} "${BRO_PLUGIN_BRO_BUILD}/build/src:$ENV{PATH}")

    else ()
        # Independent from BRO_DIST source tree

        if ( NOT BRO_CONFIG_CMAKE_DIR )
            message(FATAL_ERROR "CMake var. BRO_CONFIG_CMAKE_DIR must be set"
                    " to the path where Bro installed its cmake modules")
        endif ()

        include(${BRO_CONFIG_CMAKE_DIR}/CommonCMakeConfig.cmake)

        if ( NOT BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH )
            if ( NOT BRO_CONFIG_PLUGIN_DIR )
                message(FATAL_ERROR "CMake var. BRO_CONFIG_PLUGIN_DIR must be"
                        " set to the path where Bro installs its plugins")
            endif ()

            set(BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH
                "${BRO_CONFIG_PLUGIN_DIR}" CACHE INTERNAL "" FORCE)
        endif ()

        if ( NOT BRO_CONFIG_PREFIX )
            message(FATAL_ERROR "CMake var. BRO_CONFIG_PREFIX must be set"
                    " to the root installation path of Bro")
        endif ()

        if ( NOT BRO_CONFIG_INCLUDE_DIR )
            message(FATAL_ERROR "CMake var. BRO_CONFIG_INCLUDE_DIR must be set"
                    " to the installation path of Bro headers")
        endif ()

        set(BRO_PLUGIN_BRO_CONFIG_INCLUDE_DIR "${BRO_CONFIG_INCLUDE_DIR}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_INSTALL_PREFIX "${BRO_CONFIG_PREFIX}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_EXE_PATH "${BRO_CONFIG_PREFIX}/bin/bro"
            CACHE INTERNAL "" FORCE)

        set(BRO_PLUGIN_BRO_CMAKE ${BRO_CONFIG_CMAKE_DIR})
        set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})
        set(CMAKE_MODULE_PATH ${BRO_PLUGIN_BRO_CMAKE} ${CMAKE_MODULE_PATH})

        find_package(BinPAC REQUIRED)
        find_package(CAF COMPONENTS core io openssl REQUIRED)
        find_package(Broker REQUIRED)

        include_directories(BEFORE
                            ${BRO_CONFIG_INCLUDE_DIR}
                            ${BinPAC_INCLUDE_DIR}
                            ${BROKER_INCLUDE_DIR}
                            ${CAF_INCLUDE_DIR_CORE}
                            ${CAF_INCLUDE_DIR_IO}
                            ${CAF_INCLUDE_DIR_OPENSSL}
                            ${CMAKE_CURRENT_BINARY_DIR}
                            ${CMAKE_CURRENT_BINARY_DIR}/src
                            ${CMAKE_CURRENT_SOURCE_DIR}
                            ${CMAKE_CURRENT_SOURCE_DIR}/src
                            )
    endif ()

   if ( NOT BRO_PLUGIN_BASE )
       set(BRO_PLUGIN_BASE                "${CMAKE_CURRENT_SOURCE_DIR}" CACHE INTERNAL "" FORCE)
   endif ()

   set(BRO_PLUGIN_SCRIPTS                 "${CMAKE_CURRENT_BINARY_DIR}/scripts" CACHE INTERNAL "" FORCE)
   set(BRO_PLUGIN_SCRIPTS_SRC             "${BRO_PLUGIN_BASE}/scripts" CACHE INTERNAL "" FORCE)
   set(BRO_PLUGIN_BUILD                   "${CMAKE_CURRENT_BINARY_DIR}" CACHE INTERNAL "" FORCE)
   set(BRO_PLUGIN_LIB                     "${BRO_PLUGIN_BUILD}/lib" CACHE INTERNAL "" FORCE)
   set(BRO_PLUGIN_BIF                     "${BRO_PLUGIN_LIB}/bif" CACHE INTERNAL "" FORCE)
   set(BRO_PLUGIN_MAGIC                   "${BRO_PLUGIN_BUILD}/__bro_plugin__" CACHE INTERNAL "" FORCE)
   set(BRO_PLUGIN_README                  "${BRO_PLUGIN_BASE}/README" CACHE INTERNAL "" FORCE)

   set(BRO_PLUGIN_INTERNAL_BUILD          false CACHE INTERNAL "" FORCE)
   set(BRO_PLUGIN_BUILD_DYNAMIC           true CACHE INTERNAL "" FORCE)

   message(STATUS "Bro executable      : ${BRO_PLUGIN_BRO_EXE_PATH}")
   message(STATUS "Bro source          : ${BRO_PLUGIN_BRO_SRC}")
   message(STATUS "Bro build           : ${BRO_PLUGIN_BRO_BUILD}")
   message(STATUS "Bro install prefix  : ${BRO_PLUGIN_BRO_INSTALL_PREFIX}")
   message(STATUS "Bro plugin directory: ${BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH}")
   message(STATUS "Bro debug mode      : ${BRO_PLUGIN_ENABLE_DEBUG}")

   if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
       # By default Darwin's linker requires all symbols to be present at link time.
       set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -undefined dynamic_lookup -Wl,-bind_at_load")
   endif ()

   set(bro_PLUGIN_LIBS CACHE INTERNAL "plugin libraries" FORCE)
   set(bro_PLUGIN_BIF_SCRIPTS CACHE INTERNAL "Bro script stubs for BIFs in Bro plugins" FORCE)

   add_definitions(-DBRO_PLUGIN_INTERNAL_BUILD=false)

   add_custom_target(generate_outputs)

   if ( BRO_PLUGIN_ENABLE_DEBUG )
       set(ENABLE_DEBUG true)
       set(CMAKE_BUILD_TYPE Debug)
   endif ()

   include(SetDefaultCompileFlags)

else ()
    set(BRO_PLUGIN_BASE        "${CMAKE_CURRENT_BINARY_DIR}"         CACHE INTERNAL "" FORCE)
    set(BRO_PLUGIN_LIB         "${CMAKE_CURRENT_BINARY_DIR}/lib"     CACHE INTERNAL "" FORCE)
    set(BRO_PLUGIN_BIF         "${BRO_PLUGIN_LIB}/bif"               CACHE INTERNAL "" FORCE)
    set(BRO_PLUGIN_MAGIC       "${BRO_PLUGIN_BASE}/__bro_plugin__"   CACHE INTERNAL "" FORCE)
    set(BRO_PLUGIN_README      "${BRO_PLUGIN_BASE}/README"           CACHE INTERNAL "" FORCE)
    set(BRO_PLUGIN_SCRIPTS     "${BRO_PLUGIN_BASE}/scripts"          CACHE INTERNAL "" FORCE)
    set(BRO_PLUGIN_SCRIPTS_SRC "${CMAKE_CURRENT_SOURCE_DIR}/scripts" CACHE INTERNAL "" FORCE)
endif ()

include(GetArchitecture)

function(bro_plugin_bif_dynamic)
    foreach ( bif ${ARGV} )
        bif_target(${bif} "plugin" ${_plugin_name} ${_plugin_name_canon} FALSE)
        list(APPEND _plugin_objs ${BIF_OUTPUT_CC})
        list(APPEND _plugin_deps ${BIF_BUILD_TARGET})
        set(_plugin_objs "${_plugin_objs}" PARENT_SCOPE)
        set(_plugin_deps "${_plugin_deps}" PARENT_SCOPE)
    endforeach ()
endfunction()

function(bro_plugin_link_library_dynamic)
    foreach ( lib ${ARGV} )
        set(_plugin_libs ${_plugin_libs} ${lib} CACHE INTERNAL "dynamic plugin libraries")
    endforeach ()
endfunction()

function(bro_plugin_end_dynamic)
    # Create the dynamic library/bundle.
    add_library(${_plugin_lib} MODULE ${_plugin_objs})
    set_target_properties(${_plugin_lib} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${BRO_PLUGIN_LIB}")
    set_target_properties(${_plugin_lib} PROPERTIES PREFIX "")
    # set_target_properties(${_plugin_lib} PROPERTIES ENABLE_EXPORTS TRUE)

    add_dependencies(${_plugin_lib} generate_outputs)

    if ( _plugin_deps )
        add_dependencies(${_plugin_lib} ${_plugin_deps})
    endif()

    target_link_libraries(${_plugin_lib} ${_plugin_libs})

    # Create bif/__init__.bro.
    bro_bif_create_loader(bif-init-${_plugin_name_canon} "${bro_PLUGIN_BIF_SCRIPTS}")

    # Copy scripts/ if it's not already at the right place inside the
    # plugin directory. (Actually, we create a symbolic link rather
    # than copy so that edits to the scripts show up immediately.)
    if ( NOT "${BRO_PLUGIN_SCRIPTS_SRC}" STREQUAL "${BRO_PLUGIN_SCRIPTS}" )
        add_custom_target(copy-scripts-${_plugin_name_canon}
            # COMMAND "${CMAKE_COMMAND}" -E remove_directory ${BRO_PLUGIN_SCRIPTS}
            # COMMAND "${CMAKE_COMMAND}" -E copy_directory   ${BRO_PLUGIN_SCRIPTS_SRC} ${BRO_PLUGIN_SCRIPTS})
            COMMAND test -d ${BRO_PLUGIN_SCRIPTS_SRC} && rm -f ${BRO_PLUGIN_SCRIPTS} && ln -s ${BRO_PLUGIN_SCRIPTS_SRC} ${BRO_PLUGIN_SCRIPTS} || true)
        add_dependencies(${_plugin_lib} copy-scripts-${_plugin_name_canon})
    endif()

    if ( _plugin_deps )
        add_dependencies(bif-init-${_plugin_name_canon} ${_plugin_deps})
        add_dependencies(${_plugin_lib} bif-init-${_plugin_name_canon})
    endif()

    # Create __bro_plugin__
    # string(REPLACE "${BRO_PLUGIN_BASE}/" "" msg "Creating ${BRO_PLUGIN_MAGIC} for ${_plugin_name}")
    get_filename_component(_magic_basename ${BRO_PLUGIN_MAGIC} NAME)

    add_custom_target(bro-plugin-${_plugin_name_canon}
            COMMAND echo "${_plugin_name}" ">${BRO_PLUGIN_MAGIC}"
            COMMENT "Creating ${_magic_basename} for ${_plugin_name}")

    if ( _plugin_deps )
        add_dependencies(bro-plugin-${_plugin_name_canon} ${_plugin_deps})
    endif()

    add_dependencies(${_plugin_lib} bro-plugin-${_plugin_name_canon})

    set(_dist_tarball_name ${_plugin_name_canon}.tar.gz)
    set(_dist_output ${CMAKE_CURRENT_BINARY_DIR}/${_dist_tarball_name})

    # Create binary install package.
    add_custom_command(OUTPUT ${_dist_output}
            COMMAND ${BRO_PLUGIN_BRO_CMAKE}/bro-plugin-create-package.sh ${_plugin_name_canon} ${_plugin_dist}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            DEPENDS ${_plugin_lib}
            COMMENT "Building binary plugin package: ${_dist_tarball_name}")

    add_custom_target(dist ALL DEPENDS ${_dist_output})

    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${BRO_PLUGIN_BIF})
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${BRO_PLUGIN_LIB})
    set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${BRO_PLUGIN_MAGIC})

    ### Plugin installation.

    set(plugin_install "${BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH}/${_plugin_name_canon}")

    INSTALL(CODE "execute_process(
        COMMAND ${BRO_PLUGIN_BRO_CMAKE}/bro-plugin-install-package.sh ${_plugin_name_canon} \$ENV{DESTDIR}/${BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )")


endfunction()

macro(_plugin_target_name_dynamic target ns name)
    set(${target} "${ns}-${name}.${HOST_ARCHITECTURE}")
endmacro()

