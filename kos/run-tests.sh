#!/usr/bin/env bash
#
# © 2024 AO Kaspersky Lab
# Licensed under the MIT License

if [ -z "${SDK_PREFIX}" ];then
    echo "Can't get path to the installed KasperskyOS SDK."
    echo "Please specify it via SDK_PREFIX environment variable."
    exit 1
fi

if [ -z "${TARGET}"];then
    echo "TARGET environment variable is not set."
    echo "Default target: aarch64-kos."
    export TARGET="aarch64-kos"
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

KOS_DIR="$(dirname "$(realpath "${0}")")"
ROOT_DIR="$(dirname ${KOS_DIR})"
BUILD="${KOS_DIR}/build_tests"

export TESTS_DIR="${BUILD}/bin/tests"
export GENERATED_DIR="${BUILD}/generated"
export TEST_LOGS_DIR="${BUILD}/test_logs"
export TEST_TARGET_PREFIX="copy-image-qemu-"
export TEST_TIMEOUT=300
export QEMU_PID=
export ALL_TESTS=
export TESTS=

CMAKE="${SDK_PREFIX}/toolchain/bin/cmake"

function KillQemu() {
    kill ${QEMU_PID} 2>/dev/null
}

function PrintHelp () {
    cat<<HELP

Script to build and run project tests in QEMU.

USAGE:

run-tests.sh [-h | --help] [-n | --name {test name}] [-t | --timeout {sec}] [-l | --list] [-o | --out {directory}]

OPTIONS:

-h, --help               Help text.
-l, --list               List of tests that can be run.
-n, --name {test name}   Test name to execute. It can be repeated multiple times. If not specified, all tests will be executed.
-t, --timeout {sec}      Time, in seconds, allotted to start and execute a single test case. Default value is 300 seconds.
-o, --out {directory}    Path where the results of the test run will be stored.
                         If not specified, the results will be stored in the ${TEST_LOGS_DIR} directory.
HELP
}

function ParsArguments {
    while [ -n "${1}" ]; do
        case "${1}" in
        -h | --help) PrintHelp
            exit 0;;
        -l | --list) PrintTestNames
            exit 0;;
        -n | --name) TESTS="${TESTS} ${2}"
            shift ;;
        -t | --timeout) TEST_TIMEOUT="${2}"
            shift ;;
        -o | --out) TEST_LOGS_DIR="${2}";
            shift ;;
        *) echo "Unknown option -'${1}'"
            exit 1;;
        esac
        shift
    done
}

function Generate () {
    "${CMAKE}" -G "Unix Makefiles" -B "${BUILD}" \
             -D CARES_STATIC=ON \
             -D CARES_BUILD_TESTS=ON \
             -D CMAKE_BUILD_TYPE:STRING=Debug \
             -D CMAKE_INSTALL_PREFIX:STRING="${INSTALL_PREFIX}" \
             -D CMAKE_FIND_ROOT_PATH="${PREFIX_DIR}/sysroot-${TARGET}" \
             -D CMAKE_TOOLCHAIN_FILE="${SDK_PREFIX}/toolchain/share/toolchain-${TARGET}${TOOLCHAIN_SUFFIX}.cmake" \
             "${ROOT_DIR}/"
     if [ $? -ne 0 ]; then
         echo "Can't generate make files.";
         rm -rf "${BUILD}"
         exit 1
     fi
}

function ListTests () {
    [ ! -e ${BUILD} ] && Generate
    ALL_TESTS=$("${CMAKE}" --build ${BUILD} --target help | grep -wo ${TEST_TARGET_PREFIX}.* | sed "s|${TEST_TARGET_PREFIX}\(.*\)|\1|")
    if [ -z "${ALL_TESTS}" ]; then
        echo "No test targets found - nothing to do."
        exit 0
    fi
}

function PrintTestNames () {
    ListTests
    echo "Tests available:"
    echo "${ALL_TESTS}" | sed 's/\s\+/\n/g' | sort | sed 's/^/  /'
}

function GetTests () {
    ListTests
    if [ -z "${TESTS}" ]; then
        TESTS="${ALL_TESTS}"
    else
        TESTS=$(echo "${TESTS}" | sed 's/ /\n/g' | sort | uniq)
        for TEST in ${TESTS}; do
            if ! echo "${ALL_TESTS}" | grep -q "${TEST}"; then
                echo "Unknown test: ${TEST}."
                exit 1;
            fi
        done
    fi
}

function SetupEnvironment () {
    # TEST_LOGS_DIR should be a full path, no matter relative or absolute.
    [[ "${TEST_LOGS_DIR}" != /* ]] && TEST_LOGS_DIR="${PWD}/${TEST_LOGS_DIR}"

    [ -e "${TEST_LOGS_DIR}" ] &&  rm -rf "${TEST_LOGS_DIR}"
    mkdir -p ${TEST_LOGS_DIR} &> /dev/null

    FAILED_TESTS="${TEST_LOGS_DIR}/failed_tests"
    [ -e "${FAILED_TESTS}" ] && rm "${FAILED_TESTS}"
}

function RunTests {
    # Run all specified tests.
    for TEST in ${TESTS}; do

        RUN_TEST_SCRIPT="${TESTS_DIR}/gtest_${TEST}.qemu.sh"
        TEST_LOG="${TEST_LOGS_DIR}/${TEST}.result"
        QEMU_PID_FILE="${TEST_LOGS_DIR}/qemu_pid"

        # Build test.
        "${CMAKE}" --build ${BUILD} --target "${TEST_TARGET_PREFIX}${TEST}" -j `nproc`

        # Prepare test script to run.
        sed -i "s|qemu-system.*|& \&> \"${TEST_LOG}\" \&|" "${RUN_TEST_SCRIPT}"
        echo "echo \$! > \"${QEMU_PID_FILE}\"" >> "${RUN_TEST_SCRIPT}"

        # Run test.
        bash "${RUN_TEST_SCRIPT}"
        QEMU_PID=$(cat "${QEMU_PID_FILE}")

        tail -F -n +1 --pid="${QEMU_PID}" "${TEST_LOG}" 2>/dev/null \
        | while IFS= read -t ${TEST_TIMEOUT} -r STR; do
            echo ${STR}
            if [[ ${STR} == *"ALL-KTEST-FINISHED"* ]]; then
                break;
            elif [[ ${STR} == *"FAILED TEST"* ]]; then
                echo "  ${TEST}" >> "${FAILED_TESTS}"
                break;
            fi
        done;
        KillQemu

        # Cleanup.
        rm -rf "${TESTS_DIR}/${TEST}_images" "${GENERATED_DIR}" "${QEMU_PID_FILE}"
    done
}

function PrintResult {
    if [ -e "${FAILED_TESTS}" ]; then
        echo "Some tests have failed. See the logs for more details."
        echo "List of failed tests can be found at ${FAILED_TESTS}."
        echo "Failed tests:"
        cat "${FAILED_TESTS}"
    else
        echo "All tests are passed."
    fi
}

# Main.
trap KillQemu 0 1 2 3 13 15
ParsArguments $@
GetTests
SetupEnvironment
RunTests
PrintResult
