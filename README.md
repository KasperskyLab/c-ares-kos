# KasperskyOS adaptation patch for the c-ares library

This project provides an adaptation patch for the
[c-ares library](https://github.com/c-ares/c-ares), enabling its use in KasperskyOS-based solutions.
The project is based on the [commit](https://github.com/c-ares/c-ares/tree/cares-1_19_1) of version
1.19.1.

The c-ares library for KasperskyOS is an asynchronous resolver library. It is intended for
applications that need to perform DNS queries without blocking, or that need to perform multiple DNS
queries in parallel. The primary examples of such applications are servers that communicate with
multiple clients and programs with graphical user interfaces.

For more information about the original c-ares library, see [c-ares website](https://c-ares.org/).

The full source code is available in the [c-ares release archives](https://c-ares.haxx.se/download/)
and in a [git repository](http://github.com/c-ares/c-ares).

For additional details on KasperskyOS, including its limitations and known issues, please refer to
the [KasperskyOS Community Edition Online Help](https://kas.pr/nuf9).

## Table of contents
- [KasperskyOS adaptation patch for the c-ares library](#kasperskyos-adaptation-patch-for-the-c-ares-library)
  - [Table of contents](#table-of-contents)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building and installing](#building-and-installing)
  - [Usage](#usage)
  - [Trademarks](#trademarks)
  - [Contributing](#contributing)
  - [Licensing](#licensing)

## Getting started

### Prerequisites

1. Confirm that your host system meets all the
[System requirements](https://kas.pr/uwz1)
listed in the KasperskyOS Community Edition Developer's Guide.
1. [Install](https://kas.pr/v21a)
the KasperskyOS Community Edition SDK version 1.4. You can download it for free from
[os.kaspersky.com](https://kas.pr/377x).
1. Copy the source files of this adaptation patch to your local project directory.
1. Source the SDK setup script to configure the build environment. This exports the `KOSCEDIR`
  environment variable, which points to the SDK installation directory:
   ```sh
   source /opt/KasperskyOS-Community-Edition-<platform>-<version>/common/set_env.sh
   ```

### Building and installing

The KasperskyOS-adapted version of the c-ares library is built using the CMake build system, which
is provided in the KasperskyOS Community Edition SDK. When you develop a KasperskyOS-based solution,
use the
[recommended structure of project directories](https://kas.pr/3ce8)
to simplify the use of CMake scripts.

Suppose to install the library into a user directory `~/.local/share/kos/`. This path is
passed to CMake using the `CMAKE_INSTALL_PREFIX` option.

To build and install the library, choose the command block corresponding to your desired library
type:

* Dynamic (Shared) Library
   ```sh
   $ cmake -B build \
           -D CMAKE_INSTALL_PREFIX=~/.local/share/kos/$(basename $KOSCEDIR)/sysroot-aarch64-kos \
           -D CMAKE_TOOLCHAIN_FILE="${KOSCEDIR}/toolchain/share/toolchain-aarch64-kos.cmake"
   $ cmake --build build -j`nproc` --target all install
   ```
* Dynamic (Shared) Library + Static Library
   ```sh
   $ cmake -B build \
           -D CARES_STATIC=ON \
           -D CMAKE_INSTALL_PREFIX=~/.local/share/kos/$(basename $KOSCEDIR)/sysroot-aarch64-kos \
           -D CMAKE_TOOLCHAIN_FILE="${KOSCEDIR}/toolchain/share/toolchain-aarch64-kos.cmake"
   $ cmake --build build -j`nproc` --target all install
   ```

* Static Library
   ```sh
   $ cmake -B build \
           -D CARES_STATIC=ON \
           -D CARES_SHARED=OFF \
           -D CMAKE_INSTALL_PREFIX=~/.local/share/kos/$(basename $KOSCEDIR)/sysroot-aarch64-kos \
           -D CMAKE_TOOLCHAIN_FILE="${KOSCEDIR}/toolchain/share/toolchain-aarch64-kos.cmake"
   $ cmake --build build -j`nproc` --target all install
   ```

After a successful build, the library is installed in the
`~/.local/share/kos/$(basename $KOSCEDIR)/sysroot-aarch64-kos` directory.

> [!NOTE]
> This adaptation patch does not include the adaptation of unit tests.
>
> Running the original c-ares unit tests on KasperskyOS requires significant additional adaptation,
> including but not limited to:
>
> * Adapting the test source code for KasperskyOS.
> * Resolving external dependencies.
> * Adapting the CMake build scripts, including writing wrappers that create appropriate solutions
>  for KasperskyOS for each test.

[⬆ Back to Top](#table-of-contents)

## Usage

To integrate the c-ares library into your solution, first build and install it into the
`~/.local/share/kos/` directory. For a practical implementation, refer to the
[c-ares example](https://kas.pr/s4s7) in the
`KasperskyLab/kos-ce-extra` repository, which demonstrates this exact workflow.

## Trademarks

Registered trademarks and endpoint marks are the property of their respective owners.

AIX is a trademark of International Business Machines Corporation, registered in many jurisdictions
worldwide.

Android is a trademark of Google LLC.

Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc. in the United
States and/or other countries. Docker, Inc. and other parties may also have trademark rights in
other terms used herein.

GITHUB is a trademark of GitHub, Inc., registered in the United States and other countries.

Linux is the registered trademark of Linus Torvalds in the U.S. and other countries.

MVS is a trademark of International Business Machines Corporation, registered in many
jurisdictions worldwide.

NetWare is a registered trademark of Novell Inc. in the United States and other countries.

Novell is a registered trademark of Novell Enterprises Inc. in the United States and other
countries.

Symbian trademark is owned by the Symbian Foundation Ltd.

## Contributing

Only KasperskyOS-specific changes can be approved. See [CONTRIBUTING.md](CONTRIBUTING.md) for
detailed instructions on code contribution.

## Licensing

This project is licensed under the terms of the MIT license. See [LICENSE](LICENSE) for more information.

This project comprises publication(s) intended to be used with [c-ares library](https://github.com/c-ares/c-ares/tree/cares-1_19_1) ( “Upstream Project”).
The Upstream Project is licensed and distributed under its own license terms, which are separate from the terms of this project.
Nothing in this repository is intended to modify, replace, supersede, or relicense the Upstream Project or any of its components.

[⬆ Back to Top](#table-of-contents)

© 2026 AO Kaspersky Lab
