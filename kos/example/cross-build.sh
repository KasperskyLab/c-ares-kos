#!/usr/bin/env bash
#
# © 2024 AO Kaspersky Lab
# Licensed under the MIT License

EXAMPLE_DIR="$(dirname "$(realpath "${0}")")"
KOS_DIR="$(dirname ${EXAMPLE_DIR})"
ROOT_DIR="$(dirname ${KOS_DIR})"
BUILD="${EXAMPLE_DIR}/build"
BUILD_TARGET=

function PrintHelp () {
    cat<<HELP

Script to build and run an example of using c-ares library for KasperskyOS.

USAGE:
    ${0} <BUILD_TARGET> [-h | --help]

BUILD_TARGET:
    qemu - to build and run the example on QEMU.
    hw   - to create a file system image bootable device for hardware.

OPTIONS:
    -h, --help
        Help text.
HELP
}

# Parse arguments.
while [ -n "${1}" ]; do
    case "${1}" in
    -h | --help) PrintHelp
        exit 0;;
    qemu) BUILD_TARGET=sim;;
    hw) BUILD_TARGET=sd-image;;
    *) echo "Unknown option -'${1}'."
        PrintHelp
        exit 1;;
    esac
    shift
done

if [ -z "${BUILD_TARGET}" ]; then
    echo "BUILD_TARGET is not specified. Specify the value: 'qemu' or 'hw'."
    PrintHelp
    exit 1
fi

# Prepare environment.
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
        echo Use the TARGET environment variable to specify exact platform.
        exit 1
    fi

    export TARGET=${TARGETS[0]}
    echo "Platform ${TARGET} will be used."
fi

export LANG=C
export PKG_CONFIG=""
export PATH="${SDK_PREFIX}/toolchain/bin:${PATH}"

export BUILD_WITH_CLANG=
export BUILD_WITH_GCC=

TOOLCHAIN_SUFFIX=""

if [ "${BUILD_WITH_CLANG}" == "y" ]; then
    TOOLCHAIN_SUFFIX="-clang"
fi

if [ "${BUILD_WITH_GCC}" == "y" ]; then
    TOOLCHAIN_SUFFIX="-gcc"
fi

# Build and install c-ares library if it is not installed previously.
CARES_INSTALL_DIR="${KOS_DIR}/../install/kos"
if [ ! -d "${CARES_INSTALL_DIR}" ]; then
    export INSTALL_PREFIX="${CARES_INSTALL_DIR}"
    ${KOS_DIR}/cross-build.sh && rm -rf "${ROOT_DIR}/build"
fi

# Build example.
export EXAMPLE_DIR="${ROOT_DIR}/kos/example"
echo -D CMAKE_TOOLCHAIN_FILE="${SDK_PREFIX}/toolchain/share/toolchain-${TARGET}${TOOLCHAIN_SUFFIX}.cmake"

"${SDK_PREFIX}/toolchain/bin/cmake" -G "Unix Makefiles" -B "${BUILD}" \
      -D CMAKE_BUILD_TYPE:STRING=Debug \
      -D CMAKE_TOOLCHAIN_FILE="${SDK_PREFIX}/toolchain/share/toolchain-${TARGET}${TOOLCHAIN_SUFFIX}.cmake" \
      -D CMAKE_FIND_ROOT_PATH="${CARES_INSTALL_DIR};${PREFIX_DIR}/sysroot-${TARGET}" \
      "${EXAMPLE_DIR}" && "${SDK_PREFIX}/toolchain/bin/cmake" --build "${BUILD}" --target ${BUILD_TARGET}
