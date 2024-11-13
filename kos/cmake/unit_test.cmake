# © 2024 AO Kaspersky Lab
# Licensed under the MIT License

INCLUDE (test-generator/test_generator)

# Filtered tests:
#   *MockChannelTest.HostAliasUnreadable*:   see comment in test body.
#   *MockChannelTestAI.FamilyV4ServiceName*: getservbyname used by ares_getaddrinfo is not implemented in KasperskyOS.
STRING (JOIN : FILTERED_TESTS *MockChannelTest.HostAliasUnreadable*
                              *MockChannelTestAI.FamilyV4ServiceName*)

###
# Helper function to create GTest unit test with test generator.
# Options:
#   GTEST_DEFAULT_MAIN - if present, test is linked with GTest::gtest_main.
# Arguments:
#   TEST_NAME    - name of the test.
#   SOURCES      - list of test sources. Required parameter.
#   INCLUDE_DIRS - list of include directories using by test.
#   LIBS         - list of libraries using by test.
#   WITH_NETWORK - test use network YES/NO (default NO).
FUNCTION (add_unit_test TEST_NAME)

    SET (OPTIONS GTEST_DEFAULT_MAIN)
    SET (ONE_VAL_ARGS WITH_NETWORK)
    SET (MULTI_VAL_ARGS SOURCES INCLUDE_DIRS LIBS)
    CMAKE_PARSE_ARGUMENTS (arg "${OPTIONS}" "${ONE_VAL_ARGS}" "${MULTI_VAL_ARGS}" ${ARGN})

    IF (NOT arg_SOURCES)
        MESSAGE (FATAL_ERROR "No test sources provided")
    ENDIF ()

    IF (NOT arg_WITH_NETWORK)
        SET (arg_WITH_NETWORK NO)
    ENDIF ()

    # Initialize CMake library for the KasperskyOS SDK.
    INCLUDE (platform)
    INCLUDE (platform/image)

    # Include the CMake library named nk
    # for working with the NK compiler (nk-gen-c).
    INCLUDE (platform/nk)

    # Statically link executable files.
    initialize_platform (FORCE_STATIC)

    # Add a package with the VFS program implementations.
    FIND_PACKAGE (vfs REQUIRED)
    INCLUDE_DIRECTORIES (${vfs_INCLUDE})

    # Attach a package with the sdcard suppport implementation.
    FIND_PACKAGE (sdcard REQUIRED)
    INCLUDE_DIRECTORIES (${sdcard_INCLUDE})

    # Attach a package with the Ext4 file system implementation.
    FIND_PACKAGE (LWEXT4 REQUIRED)
    INCLUDE_DIRECTORIES (${LWEXT4_INCLUDE})

    # Due to limitations of test_generator, test should contain embedded VFS implementation.
    SET (VFS_IMPL_LIBS ${vfs_LOCAL_LIB} ${blkdev_CLIENT_LIB} ${LWEXT4_LIB})
    IF (arg_WITH_NETWORK)
        FIND_PACKAGE (dnet REQUIRED COMPONENTS IMPLEMENTATION_LIB)
        LIST (APPEND VFS_IMPL_LIBS ${vfs_IMPLEMENTATION_LIB} ${dnet_IMPLEMENTATION_LIB})
    ELSE ()
        LIST (APPEND VFS_IMPL_LIBS ${vfs_FS_LIB})
    ENDIF ()

    FIND_PACKAGE (GTest REQUIRED NO_CMAKE_PACKAGE_REGISTRY)
    SET (GTEST_LIBS GTest::gtest GTest::gmock $<$<BOOL:${arg_GTEST_DEFAULT_MAIN}>:GTest::gtest_main>)

    get_entity_name (${TEST_NAME} TEST_NAME)
    generate_edl_file (${TEST_NAME} PREFIX test)
    nk_build_edl_files (${TEST_NAME}_edl_files NK_MODULE test EDL ${EDL_FILE})

    ADD_EXECUTABLE (${TEST_NAME} ${arg_SOURCES})
    platform_target_force_static(${TEST_NAME})
    ADD_DEPENDENCIES (${TEST_NAME} ${TEST_NAME}_edl_files ${arg_DEPS})
    TARGET_COMPILE_FEATURES (${TEST_NAME} PRIVATE cxx_std_17)
    TARGET_INCLUDE_DIRECTORIES (${TEST_NAME}
                                PRIVATE
                                    ${GTEST_INCLUDE_DIRS}
                                    ${arg_INCLUDE_DIRS})

    TARGET_LINK_LIBRARIES (${TEST_NAME}
                           PRIVATE
                               ${GTEST_LIBS}
                               ${VFS_IMPL_LIBS}
                               ${arg_LIBS})

    SET_TARGET_PROPERTIES (${TEST_NAME} PROPERTIES ${blkdev_ENTITY}_REPLACEMENT ${sdcard_ENTITY})

    generate_kos_test (ENTITY_NAME ${TEST_NAME}
                       ENTITY_PREFIX  test
                       TEST_TYPE      gtest
                       ARGUMENTS      "-4;--gtest_filter=-${FILTERED_TESTS}"
                       FILES          ${CARES_TOPLEVEL_DIR}/kos/test/resources/resolv.conf
                       ENTITY_HAS_VFS YES
                       WITH_NETWORK   ${arg_WITH_NETWORK})

ENDFUNCTION (add_unit_test)
