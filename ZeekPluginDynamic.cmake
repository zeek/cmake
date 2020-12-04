## A set of functions for defining Zeek plugins.
##
## This set is for plugins compiled dynamically for loading at run-time.
## See ZeekPluginStatic.cmake for the static version.
##
## Note: This is meant to run as a standalone CMakeLists.txt. It sets
## up all the basic infrastructure to compile a dynamic Zeek plugin when
## included from its top-level CMake file.

if ( NOT ZEEK_PLUGIN_INTERNAL_BUILD )
   set(BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH "${BRO_PLUGIN_INSTALL_ROOT}"
       CACHE INTERNAL "" FORCE)

    if ( BRO_DIST )
        include(${BRO_DIST}/cmake/CommonCMakeConfig.cmake)

        if ( NOT EXISTS "${BRO_DIST}/build/CMakeCache.txt" )
           message(FATAL_ERROR
                   "${BRO_DIST}/build/CMakeCache.txt; has Zeek been built?")
        endif ()

        load_cache("${BRO_DIST}/build" READ_WITH_PREFIX bro_cache_
                   CMAKE_INSTALL_PREFIX
                   Zeek_BINARY_DIR
                   Zeek_SOURCE_DIR
                   ENABLE_DEBUG
                   BRO_PLUGIN_INSTALL_PATH
                   ZEEK_EXE_PATH
                   CMAKE_CXX_FLAGS
                   CMAKE_C_FLAGS
                   PCAP_INCLUDE_DIR
                   ZLIB_INCLUDE_DIR
                   OPENSSL_INCLUDE_DIR
                   LibKrb5_INCLUDE_DIR
                   GooglePerftools_INCLUDE_DIR
                   CAF_INCLUDE_DIRS)

        if ( NOT BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH )
           set(BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH
               "${bro_cache_BRO_PLUGIN_INSTALL_PATH}" CACHE INTERNAL "" FORCE)
        endif ()

        set(BRO_PLUGIN_BRO_INSTALL_PREFIX "${bro_cache_CMAKE_INSTALL_PREFIX}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_ENABLE_DEBUG "${bro_cache_ENABLE_DEBUG}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_SRC "${bro_cache_Zeek_SOURCE_DIR}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_BUILD "${bro_cache_Zeek_BINARY_DIR}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_EXE_PATH "${bro_cache_ZEEK_EXE_PATH}"
            CACHE INTERNAL "" FORCE)

        set(BRO_PLUGIN_BRO_CMAKE ${BRO_PLUGIN_BRO_SRC}/cmake)
        set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})
        set(CMAKE_MODULE_PATH ${BRO_PLUGIN_BRO_CMAKE} ${CMAKE_MODULE_PATH})
        set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   ${bro_cache_CMAKE_C_FLAGS}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${bro_cache_CMAKE_CXX_FLAGS}")

        if ( bro_cache_PCAP_INCLUDE_DIR )
            include_directories(BEFORE ${bro_cache_PCAP_INCLUDE_DIR})
        endif ()
        if ( bro_cache_ZLIB_INCLUDE_DIR )
            include_directories(BEFORE ${bro_cache_ZLIB_INCLUDE_DIR})
        endif ()
        if ( bro_cache_OPENSSL_INCLUDE_DIR )
            include_directories(BEFORE ${bro_cache_OPENSSL_INCLUDE_DIR})
        endif ()
        if ( bro_cache_LibKrb5_INCLUDE_DIR )
            include_directories(BEFORE ${bro_cache_LibKrb5_INCLUDE_DIR})
        endif ()
        if ( bro_cache_GooglePerftools_INCLUDE_DIR )
            include_directories(BEFORE ${bro_cache_GooglePerftools_INCLUDE_DIR})
        endif ()

        # Zeek 3.2+ has auxil/ instead of aux/
        include_directories(BEFORE
                            ${BRO_PLUGIN_BRO_SRC}/src
                            ${BRO_PLUGIN_BRO_SRC}/aux/binpac/lib
                            ${BRO_PLUGIN_BRO_SRC}/auxil/binpac/lib
                            ${BRO_PLUGIN_BRO_SRC}/aux/broker/include
                            ${BRO_PLUGIN_BRO_SRC}/auxil/broker/include
                            ${BRO_PLUGIN_BRO_SRC}/aux/paraglob/include
                            ${BRO_PLUGIN_BRO_SRC}/auxil/paraglob/include
                            ${BRO_PLUGIN_BRO_SRC}/aux/rapidjson/include
                            ${BRO_PLUGIN_BRO_SRC}/auxil/rapidjson/include
                            ${BRO_PLUGIN_BRO_BUILD}
                            ${BRO_PLUGIN_BRO_BUILD}/src
                            ${BRO_PLUGIN_BRO_BUILD}/aux/binpac/lib
                            ${BRO_PLUGIN_BRO_BUILD}/auxil/binpac/lib
                            ${BRO_PLUGIN_BRO_BUILD}/aux/broker/include
                            ${BRO_PLUGIN_BRO_BUILD}/auxil/broker/include
                            ${bro_cache_CAF_INCLUDE_DIRS}
                            ${CMAKE_CURRENT_BINARY_DIR}
                            ${CMAKE_CURRENT_BINARY_DIR}/src
                            ${CMAKE_CURRENT_SOURCE_DIR}/src
                            )

        set(ENV{PATH} "${BRO_PLUGIN_BRO_BUILD}/build/src:$ENV{PATH}")

    else ()
        # Independent from BRO_DIST source tree

        if ( NOT BRO_CONFIG_CMAKE_DIR )
            message(FATAL_ERROR "CMake var. BRO_CONFIG_CMAKE_DIR must be set"
                    " to the path where Zeek installed its cmake modules")
        endif ()

        include(${BRO_CONFIG_CMAKE_DIR}/CommonCMakeConfig.cmake)

        if ( NOT BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH )
            if ( NOT BRO_CONFIG_PLUGIN_DIR )
                message(FATAL_ERROR "CMake var. BRO_CONFIG_PLUGIN_DIR must be"
                        " set to the path where Zeek installs its plugins")
            endif ()

            set(BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH
                "${BRO_CONFIG_PLUGIN_DIR}" CACHE INTERNAL "" FORCE)
        endif ()

        if ( NOT BRO_CONFIG_PREFIX )
            message(FATAL_ERROR "CMake var. BRO_CONFIG_PREFIX must be set"
                    " to the root installation path of Zeek")
        endif ()

        if ( NOT BRO_CONFIG_INCLUDE_DIR )
            message(FATAL_ERROR "CMake var. BRO_CONFIG_INCLUDE_DIR must be set"
                    " to the installation path of Zeek headers")
        endif ()

        # Add potential custom library paths to our search path. This
        # works transparently across future find_library() calls.
        #
        # The zeek-config call is currently an outlier ... we need it
        # because existing plugin configure scripts need to keep
        # working with possible alternative libdirs, but do not
        # determine the libdir themselves. zeek-config is the only way
        # to determine it post-installation in those cases.
        #
        # XXX In the future the FindZeek module should make
        # zeek-config calls to establish the various settings
        # consistently within cmake. This would simplify configure
        # scripts and make cmake use with Zeek more standard.
        if ( NOT BRO_CONFIG_LIB_DIR )
            execute_process(
                COMMAND ${BRO_CONFIG_PREFIX}/bin/zeek-config --lib_dir
                OUTPUT_VARIABLE BRO_CONFIG_LIB_DIR
                OUTPUT_STRIP_TRAILING_WHITESPACE)
        endif ()

        if ( BRO_CONFIG_LIB_DIR )
            set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} ${BRO_CONFIG_LIB_DIR})
        endif ()

        set(BRO_PLUGIN_BRO_CONFIG_INCLUDE_DIR "${BRO_CONFIG_INCLUDE_DIR}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_INSTALL_PREFIX "${BRO_CONFIG_PREFIX}"
            CACHE INTERNAL "" FORCE)
        set(BRO_PLUGIN_BRO_EXE_PATH "${BRO_CONFIG_PREFIX}/bin/zeek"
            CACHE INTERNAL "" FORCE)

        set(BRO_PLUGIN_BRO_CMAKE ${BRO_CONFIG_CMAKE_DIR})
        set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})
        set(CMAKE_MODULE_PATH ${BRO_PLUGIN_BRO_CMAKE} ${CMAKE_MODULE_PATH})

        find_package(BinPAC REQUIRED)
        find_package(CAF COMPONENTS core io openssl REQUIRED)
        find_package(Broker REQUIRED)

        string(REPLACE ":" ";" ZEEK_CONFIG_INCLUDE_DIRS "${BRO_CONFIG_INCLUDE_DIR}")
        list(GET ZEEK_CONFIG_INCLUDE_DIRS 0 ZEEK_CONFIG_BASE_INCLUDE_DIR)
        list(APPEND ZEEK_CONFIG_INCLUDE_DIRS
             "${ZEEK_CONFIG_BASE_INCLUDE_DIR}/zeek/3rdparty/rapidjson/include")

        include_directories(BEFORE
                            ${ZEEK_CONFIG_INCLUDE_DIRS}
                            ${BinPAC_INCLUDE_DIR}
                            ${BROKER_INCLUDE_DIR}
                            ${CAF_INCLUDE_DIRS}
                            ${CMAKE_CURRENT_BINARY_DIR}
                            ${CMAKE_CURRENT_BINARY_DIR}/src
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

   set(ZEEK_PLUGIN_INTERNAL_BUILD         false CACHE INTERNAL "" FORCE)
   set(ZEEK_PLUGIN_BUILD_DYNAMIC          true CACHE INTERNAL "" FORCE)

   message(STATUS "Zeek executable      : ${BRO_PLUGIN_BRO_EXE_PATH}")
   message(STATUS "Zeek source          : ${BRO_PLUGIN_BRO_SRC}")
   message(STATUS "Zeek build           : ${BRO_PLUGIN_BRO_BUILD}")
   message(STATUS "Zeek install prefix  : ${BRO_PLUGIN_BRO_INSTALL_PREFIX}")
   message(STATUS "Zeek plugin directory: ${BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH}")
   message(STATUS "Zeek debug mode      : ${BRO_PLUGIN_ENABLE_DEBUG}")

   if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
       # By default Darwin's linker requires all symbols to be present at link time.
       set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -undefined dynamic_lookup -Wl,-bind_at_load")
   endif ()

   set(bro_PLUGIN_LIBS CACHE INTERNAL "plugin libraries" FORCE)
   set(bro_PLUGIN_BIF_SCRIPTS CACHE INTERNAL "Zeek script stubs for BIFs in Zeek plugins" FORCE)

   add_definitions(-DZEEK_PLUGIN_INTERNAL_BUILD=false)

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

    # Create bif/__load__.zeek.
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

    set(_dist_tarball_name ${_plugin_name_canon}.tgz)
    set(_dist_output ${CMAKE_CURRENT_BINARY_DIR}/${_dist_tarball_name})

    # Create binary install package.
    add_custom_command(OUTPUT ${_dist_output}
            COMMAND ${BRO_PLUGIN_BRO_CMAKE}/zeek-plugin-create-package.sh ${_plugin_name_canon} ${_plugin_dist}
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
        COMMAND ${BRO_PLUGIN_BRO_CMAKE}/zeek-plugin-install-package.sh ${_plugin_name_canon} \$ENV{DESTDIR}/${BRO_PLUGIN_BRO_PLUGIN_INSTALL_PATH}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )")


endfunction()

macro(_plugin_target_name_dynamic target ns name)
    set(${target} "${ns}-${name}.${HOST_ARCHITECTURE}")
endmacro()

