# © 2024 AO Kaspersky Lab
# Licensed under the MIT License

PROJECT (einit)

# Include the CMake library named image
# containing the solution image build scripts.
INCLUDE (platform/image)
INCLUDE (${KL_SDK_ROOT_PATH}/common/build-sd-image.cmake)

# Set the linker and compiler flags.
project_header_default ("STANDARD_GNU_17:YES" "EXTRA_STRICT_WARNINGS:YES")

# Define an ENTITIES variable with a list of programs.
SET (ENTITIES
    ${rump_DHCPCD_ENTITY}
    ${precompiled_vfsVfsSdCardFs}
    ${precompiled_vfsVfsNet}
    NameResolver
    Client
)

SET (SECURITY_PSL_FILE    "src/security.psl.in")
SET (CONNECTIONS_CFG_FILE "src/init.yaml.in")
SET (IMAGE_FS             "${CMAKE_BINARY_DIR}/hdd")
SET (LIBS_PATH            "${IMAGE_FS}/lib")
SET (QEMU_DISK_IMAGE      sdcard0.img)
SET (QEMU_DEPENDENCIES    ${QEMU_DISK_IMAGE})
SET (QEMU_FLAGS           "-drive file=${QEMU_DISK_IMAGE},if=sd,format=raw")
set (QEMU_ENV             "QEMU_AUDIO_DRV=none")

IF (blob_container_ENTITY_FOUND)
    SET_TARGET_PROPERTIES (${blob_container_ENTITY}
        PROPERTIES
            DEPENDS_ON_ENTITY ${precompiled_vfsVfsSdCardFs}
            EXTRA_ENV         "    VFS_FILESYSTEM_BACKEND: client:kl.VfsSdCardFs"
    )
ENDIF ()

# Set additional properties for Dhcpcd program.
SET_TARGET_PROPERTIES (${rump_DHCPCD_ENTITY}
    PROPERTIES
        DEPENDS_ON_ENTITY "${precompiled_vfsVfsSdCardFs};${precompiled_vfsVfsNet}"
        EXTRA_ENV "
            VFS_FILESYSTEM_BACKEND: client{fs->net}:kl.VfsSdCardFs
            VFS_NETWORK_BACKEND: client:kl.VfsNet"
        EXTRA_ARGS "
            - '-4'
            - '-f'
            - /etc/dhcpcd.conf"
)

# Add a target to create filesystem for disk image.
ADD_CUSTOM_TARGET (disk_image_fs
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${RESOURCES}/hdd ${IMAGE_FS}
)

# Add a target to create disk image for QEMU.
ADD_CUSTOM_TARGET (${QEMU_DISK_IMAGE}
    DEPENDS disk_image_fs copylibs_qemu
    COMMAND ${KL_SDK_ROOT_PATH}/common/prepare_hdd_img.sh
            -d ${IMAGE_FS}
            -s 64
            -f fat32
            -img ${QEMU_DISK_IMAGE}
)

# Create a top-level CMake target named kos-qemu-image which
# can be used when building a solution image to be started in QEMU.
build_kos_qemu_image (kos-qemu-image
    EINIT_ENTITY            EinitQemu
    CONNECTIONS_CFG         ${CONNECTIONS_CFG_FILE}
    SECURITY_PSL            ${SECURITY_PSL_FILE}
    QEMU_FLAGS              "${QEMU_FLAGS}"
    QEMU_ENV                ${QEMU_ENV}
    QEMU_DEPENDENCIES       ${QEMU_DEPENDENCIES}
    PACK_DEPS_COPY_ONLY     ON
    PACK_DEPS_LIBS_PATH     ${LIBS_PATH}
    PACK_DEPS_COPY_TARGET   copylibs_qemu
    IMAGE_FILES             ${ENTITIES}
)

IF (BOARD STREQUAL "RADXA_ROCK_3A")
    SET_TARGET_PROPERTIES (${precompiled_vfsVfsSdCardFs}
        PROPERTIES
            EXTRA_ENV "\
                ROOTFS: mmc1,0 / fat32 0
                VFS_FILESYSTEM_BACKEND: server:kl.VfsSdCardFs"
    )
ENDIF ()

# Create a top-level CMake target named kos-image which can be used
# when building a solution image to be started on the hardware platform.
build_kos_hw_image (kos-image
    EINIT_ENTITY          EinitHw
    CONNECTIONS_CFG       ${CONNECTIONS_CFG_FILE}
    SECURITY_PSL          ${SECURITY_PSL_FILE}
    PACK_DEPS_COPY_ONLY   ON
    PACK_DEPS_LIBS_PATH   ${LIBS_PATH}
    PACK_DEPS_COPY_TARGET copylibs_hw
    IMAGE_FILES           ${ENTITIES}
)

ADD_DEPENDENCIES (kos-image disk_image_fs copylibs_hw)

# Create a top-level CMake target named sd-image which can be used
# when building an SD card image to be started on the hardware platform.
build_sd_image (sd-image
    KOS_IMAGE_TARGET kos-image
    IMAGE_FS         ${IMAGE_FS}
)
