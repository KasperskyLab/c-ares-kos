#!/usr/bin/env bash
#
# © 2024 AO Kaspersky Lab
# Licensed under the MIT License


KOS_DIR="$(dirname "$(realpath "${0}")")"
ROOT_DIR="$(dirname ${KOS_DIR})"
BUILD="${KOS_DIR}/build"

if [ -z "${SDK_PREFIX}" ]; then
    echo "Can't get path to the installed KasperskyOS SDK."
    echo "Please specify it via the SDK_PREFIX environment variable."
    exit 1
fi

if [ -z "${TARGET}" ]; then
    echo "Target platform is not specified. Try to autodetect..."
    TARGETS=($(ls -d "${SDK_PREFIX}"/sysroot-* | sed 's|.*sysroot-\(.*\)|\1|'))
    if [ ${#TARGETS[@]} -gt 1 ]; then
        echo More than one target platform found: ${TARGETS[*]}.
        echo Use the TARGET environment variabe to specify exact platform.
        exit 1
    fi

    export TARGET=${TARGETS[0]}
    echo "Platform ${TARGET} will be used."
fi

if [ -z "${INSTALL_PREFIX}" ]; then
    export INSTALL_PREFIX="${KOS_DIR}/install"
    echo "Install path is not specified."
    echo "Use default install path - ${INSTALL_PREFIX}."
fi

export LANG=C
export PKG_CONFIG=""
export PATH="${SDK_PREFIX}/toolchain/bin:${PATH}"

export BUILD_WITH_CLANG=
export BUILD_WITH_GCC=

TOOLCHAIN_SUFFIX=""

if [ "${BUILD_WITH_CLANG}" == "y" ];then
    TOOLCHAIN_SUFFIX="-clang"
fi

if [ "${BUILD_WITH_GCC}" == "y" ];then
    TOOLCHAIN_SUFFIX="-gcc"
fi

"${SDK_PREFIX}/toolchain/bin/cmake" -G "Unix Makefiles" -B "${BUILD}" \
      -D CARES_INSTALL=ON \
      -D CARES_STATIC=ON \
      -D CARES_BUILD_TESTS=OFF \
      -D CMAKE_BUILD_TYPE:STRING=Debug \
      -D CMAKE_INSTALL_PREFIX:STRING="${INSTALL_PREFIX}" \
      -D CMAKE_FIND_ROOT_PATH="${PREFIX_DIR}/sysroot-${TARGET}" \
      -D CMAKE_TOOLCHAIN_FILE="${SDK_PREFIX}/toolchain/share/toolchain-${TARGET}${TOOLCHAIN_SUFFIX}.cmake" \
      "${ROOT_DIR}/" &&  "${SDK_PREFIX}/toolchain/bin/cmake" --build "${BUILD}" -j`nproc`  --target install
