# © 2024 AO Kaspersky Lab
# Licensed under the MIT License

# Initialize CMake library for the KasperskyOS SDK.
include(platform)
initialize_platform(FORCE_STATIC)

# Include the CMake library named nk for working with the NK compiler (nk-gen-c).
include(platform/nk)

# Include the CMake library named test-generator to write and build unit tests
# using the specialized program named test_generator provided in the KasperskyOS SDK.
include(test-generator/test_generator)

# Add a package with the VFS program implementations.
find_package(vfs REQUIRED)
include_directories(${vfs_INCLUDE})

# Add a package with prebuilt VFS program implementations.
find_package(precompiled_vfs REQUIRED)

# Add a package with the Dhcpcd program implementation.
find_package(rump REQUIRED COMPONENTS DHCPCD_ENTITY)
include_directories(${rump_INCLUDE})

# Set additional properties for the VfsSdCardFs program.
set_target_properties(${precompiled_vfsVfsSdCardFs} PROPERTIES
  EXTRA_ENV "
    VFS_FILESYSTEM_BACKEND: server:kl.VfsSdCardFs"
  EXTRA_ARGS "
    - -f
    - /fstab"
)

# Set additional properties for VfsNet program.
set_target_properties(${precompiled_vfsVfsNet} PROPERTIES
  EXTRA_ENV "
    VFS_FILESYSTEM_BACKEND: server:kl.VfsNet"
  EXTRA_ARGS "
  - -l
  - devfs /dev devfs 0
  - -l
  - romfs /etc romfs ro"
)

###
# Helper function to create GTest unit test with test generator.
# Options:
#   WITH_NETWORK  - network support for test.
# Arguments:
#   TEST_TARGET   - executable target that represents test.
#   ARGS          - tests command line arguments.
#   ENV_VARIABLES - environment variables that will be set while test runs.
#   LIBS_SCOPE    - test libraries scope type can be PUBLIC PRIVATE or empty.
#   FSTAB_FILE    - path to test fstab file.
#   FILES         - files that will be added to test kos-image.
#   FILES_TO_COPY - list of strings with format "path_to_files_need_by_test:path_where_it_should_be_placed".
#   DEPENDS_ON    - extra programs that test depends on.
function(kos_gtest TEST_TARGET)
  set(OPTIONS WITH_NETWORK)
  set(SINGLE_VAL_ARGS FSTAB_FILE LIBS_SCOPE)
  set(MULTI_VAL_ARGS FILES FILES_TO_COPY ENV_VARIABLES ARGS DEPENDS_ON)
  cmake_parse_arguments(TEST "${OPTIONS}" "${SINGLE_VAL_ARGS}" "${MULTI_VAL_ARGS}" ${ARGN})

  IF(NOT TEST_FSTAB_FILE)
      message(FATAL_ERROR  "No fstab file specified for test on KasperskyOS")
  ENDIF()

  # Add programs to support disk storage.
  set(TEST_DEPENDS_ON ${precompiled_vfsVfsSdCardFs})
  # Set environment variables to select disk storage backend.
  set(TEST_ENV_VARIABLES VFS_FILESYSTEM_BACKEND=client:kl.VfsSdCardFs)

  IF(TEST_WITH_NETWORK)
    # Add programs to support network.
    list(APPEND TEST_DEPENDS_ON ${precompiled_vfsVfsNet})
    # Set environment variables to select network backend.
    list(APPEND TEST_ENV_VARIABLES VFS_NETWORK_BACKEND=client:kl.VfsNet)
    set(WITH_NETWORK_OPTION WITH_NETWORK)
  ENDIF(TEST_WITH_NETWORK)

  get_entity_name(${TEST_TARGET} TEST_ENTITY_NAME)
  generate_edl_file(${TEST_ENTITY_NAME})
  nk_build_edl_files(${TEST_TARGET}_edl_files EDL ${EDL_FILE})
  add_dependencies(${TEST_TARGET} ${TEST_TARGET}_edl_files)

  target_link_libraries(${TEST_TARGET} ${TEST_LIBS_SCOPE} ${vfs_CLIENT_LIB})

  set_target_properties(${TEST_TARGET} PROPERTIES
    ${vfs_ENTITY}_REPLACEMENT ""
    DEPENDS_ON_ENTITY "${TEST_DEPENDS_ON}"
  )

  IF(TEST_FILTER)
    list(APPEND TEST_ARGS --gtest_filter=${TEST_FILTER})
  ENDIF()

  unset(vfs_ENTITY)
  generate_kos_test(
    ${WITH_NETWORK_OPTION}
    ENTITY_NAME ${TEST_ENTITY_NAME}
    TARGET_NAME ${TEST_TARGET}
    TEST_TYPE gtest
    ARGUMENTS ${TEST_ARGS}
    FSTAB_FILE ${TEST_FSTAB_FILE}
    VARIABLES ${TEST_ENV_VARIABLES}
    ENTITY_HAS_VFS YES
    FILES ${TEST_FILES}
    FILES_TO_COPY ${TEST_FILES_TO_COPY}
  )
endfunction(kos_gtest)
