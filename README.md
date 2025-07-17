# C-ares adaptation for KasperskyOS

This version of the [c-ares library](https://github.com/c-ares/c-ares) is adapted for KasperskyOS.
The project is based on a [commit](https://github.com/c-ares/c-ares/tree/cares-1_17_2) of version
1.17.2 and includes a simple example of the asynchronous DNS resolver.

The c-ares library for KasperskyOS (hereinafter also referred to as the c-ares library) is an
asynchronous resolver library. It is intended for applications that need to perform DNS queries
without blocking, or that need to perform multiple DNS queries in parallel. The primary examples
of such applications are servers that communicate with multiple clients and programs with graphical
user interfaces.

For more information about c-ares library, see [c-ares website](https://c-ares.org/).

The full source code is available in the [c-ares release archives](https://c-ares.haxx.se/download/)
and in a [git repository](http://github.com/c-ares/c-ares).

For additional details on KasperskyOS, including its limitations and known issues, please refer to the
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=community_edition).

## Table of contents
- [C-ares adaptation for KasperskyOS](#c-ares-adaptation-for-kasperskyos)
  - [Table of contents](#table-of-contents)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building and installing](#building-and-installing)
      - [C-ares library](#c-ares-library)
      - [Tests](#tests)
  - [Usage](#usage)
    - [Example](#example)
    - [Tests](#tests-1)
  - [Trademarks](#trademarks)
  - [Contributing](#contributing)
  - [Licensing](#licensing)

## Getting started

### Prerequisites

1. [Install](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=sdk_install_and_remove)
KasperskyOS Community Edition SDK. You can download the latest version of the KasperskyOS Community
Edition for free from [os.kaspersky.com](https://os.kaspersky.com/development/). The minimum required
version of KasperskyOS Community Edition SDK is 1.3. For more information, see
[System requirements](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=system_requirements).
1. Copy source files to your project directory. The example of KasperskyOS-based solution and tests
are located in the [`./kos`](kos) directory.

### Building and installing

#### C-ares library

The c-ares library is built using the CMake build system, which is provided in the KasperskyOS
Community Edition SDK.

To build and install the c-ares library, execute the [`./kos/cross-build.sh`](kos/cross-build.sh)
script. There are environment variables that affect the build and installation of the c-ares library:

* `SDK_PREFIX`

  Specifies the path to the installed version of the KasperskyOS Community Edition SDK.
The value of this environment variable must be set.
* `INSTALL_PREFIX`

  Specifies the installation path of the library. If not specified, the library will be installed
in the `./kos/install` directory.
* `TARGET`

  Specifies the target platform. (Currently only the `aarch64-kos` platform is supported.)

For example, review the following command:
```
$ SDK_PREFIX=/opt/KasperskyOS-Community-Edition-<version> INSTALL_PREFIX=/home/libs/c-ares-kos/ ./cross-build.sh
```
The command builds the c-ares library and installs it in the `/home/libs/c-ares-kos/` directory.
The library is based on the SDK found in the `/opt/KasperskyOS-Community-Edition-<version>` path,
where `version` is the latest version number of the KasperskyOS Community Edition SDK.

#### Tests

[`./kos/test`](kos/test)—Unit testing using the GoogleTest framework.

Tests use an out-of-source build. The build tree is situated in the generated `build_tests`
subdirectory of the `./kos` directory. For each test suite, a separate image will be created.
As it can be taxing on disk space, the tests will run sequentially.

To build and run the tests, go to the `./kos` directory and run the command:

`$ SDK_PREFIX=/opt/KasperskyOS-Community-Edition-<version> [TARGET="aarch64-kos"] ./run-tests.sh [--help] [--list] [-n TEST_NAME_1] ... [-n TEST_NAME_N] [-t TIMEOUT] [-o OUT_PATH]`,

where:

* `SDK_PREFIX`

  Path to the installed version of the KasperskyOS Community Edition SDK.
The value of this environment variable must be set.
* `TARGET`

  Target platform. (Currently only the `aarch64-kos` platform is supported.)
* `-h, --help`

  Help text.
* `-l, --list`

  List of tests that can be run.
* `-n, --name TEST_NAME`

  Test name to execute. The parameter can be repeated multiple times.
If not specified, all tests will be executed.
* `-t, --timeout TIMEOUT`

  The time, in seconds, allotted to start and execute a single test case.
Default value is 300 seconds.
* `-o, --out OUT_PATH`

  Path where the results of the test run will be stored. If not specified, the results will be stored
in the `./kos/build_tests/test_logs` directory.

[⬆ Back to Top](#table-of-contents)

## Usage

When you develop a KasperskyOS-based solution, use the
[recommended structure of project directories](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=cmake_using_sdk_cmake)
to simplify usage of CMake scripts.

To include the c-ares library in your KasperskyOS-based solution, do the following:

* Use CMake command `target_include_directories()` to specify the paths to the header file directories.
* Link the built library to your program using CMake command `target_link_libraries()`. Example of
implementing this approach is shown in the file [`./kos/example/resolver/CMakeLists.txt`](kos/example/resolver/CMakeLists.txt).
* Add the required header files to your code file to enable calls to library functions:
   ```
   #include <ares.h>
   ...
   ```

This solution uses the dynamic variant of the c-ares library. To build a static variant of the library,
use the `initialize_platform` command with the `FORCE_STATIC` parameter. For additional details
regarding this command, please refer to the
[platform library](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=cmake_platform_lib).

### Example

The example of the asynchronous DNS resolver demonstrates how to use of the adapted c-ares library in
a KasperskyOS-based solution. You can review the example in the [`./kos/example`](kos/example) directory.

### Tests

The c-ares library's [tests](test) have been adapted to run on KasperskyOS. The tests have the
following limitations:

* Unit tests for KasperskyOS are currently only available for QEMU.
* Only IPv4 tests are compatible with KasperskyOS.
* `MockChannelTest.HostAliasUnreadable` test is skipped due to KasperskyOS incompatibility (open
file caching).

[Build and run](#tests) the tests. Information about the results of the tests will be displayed in the standard output.

## Trademarks

Registered trademarks and endpoint marks are the property of their respective owners.

GoogleTest, Android, Dalvik are trademarks of Google LLC.

FreeBSD is a registered trademark of The FreeBSD Foundation.

AFS, AIX, IBM, Power PC are trademarks of International Business Machines Corporation, registered in many jurisdictions 
worldwide.

Apple, macOS, Mac OS, Xcode, OS X, iPhone are trademarks of Apple Inc.

FreeBSD is a registered trademark of The FreeBSD Foundation.

Intel, Itanium are trademarks of Intel Corporation or its subsidiaries.

Nokia is registered trademark of Nokia Corporation.

IBM, PowerPC, z/OS are trademarks of International Business Machines Corporation, registered in many jurisdictions worldwide.

UNIX is a registered trademark in the United States and other countries, licensed exclusively through X/Open Company Limited.

IOS is a registered trademark of Cisco Systems, Inc. and/or its affiliates in the United States and certain other countries.

Linux is the registered trademark of Linus Torvalds in the U.S. and other countries.

Microsoft Windows, Visual Studio, Visual C++, Win32, Windows Server, Windows Store are trademarks of the Microsoft group of companies.

MIPS is a trademark or registered trademark of MIPS Technologies, Inc. in the United States and other countries.

NetWare, Novell are registered trademarks of Novell Enterprises Inc. in the United States and other countries.

Solaris is a registered trademarks of Oracle and/or its affiliates.

Raspberry Pi is a trademark of the Raspberry Pi Foundation.

## Contributing

Only KasperskyOS-specific changes can be approved. See [CONTRIBUTING.md](CONTRIBUTING.md)
for detailed instructions on code contribution.

## Licensing

This project is licensed under the terms of the MIT License. See [LICENSE.md](LICENSE.md) for more information.

[⬆ Back to Top](#table-of-contents)

© 2025 AO Kaspersky Lab
