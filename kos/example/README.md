# Async DNS resolver example

Simple example of async DNS resolver demonstrating the usage of c-ares library on KasperskyOS.

The example also demonstrates the use of a callable handle, a client IPC handle that identifies
both an IPC channel to a server and an endpoint of that server. The server creates a callable handle
and passes it to the client so that the client can use the server endpoint. The client initializes
the IPC transport using the received callable handle. For more information, see
[Creating handles](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_libkos_handles_create).

## Table of contents
- [Async DNS resolver example](#async-dns-resolver-example)
  - [Table of contents](#table-of-contents)
  - [Solution overview](#solution-overview)
    - [List of programs](#list-of-programs)
    - [Initialization description](#initialization-description)
    - [Security policy description](#security-policy-description)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building and running the example](#building-and-running-the-example)
      - [QEMU](#qemu)
      - [Raspberry Pi 4 B](#raspberry-pi-4-b)
      - [CMake input files](#cmake-input-files)
  - [Usage](#usage)

## Solution overview

### List of programs

* `Client`—Program that sends a request to the `NameResolver` program for name resolution and prints
the host name and address (or any errors) returned by the `NameResolver`.
* `NameResolver`—Program acts as a server that takes a host name to resolve and uses a callback to
report the result to the `Client` program. To resolve the host name, the `cares_gethostbyname`
function is used.
* `Dhcpcd`—DHCP client implementation program that gets network interface parameters from an external
DHCP server in the background and passes them to the virtual file system
* `VfsSdCardFs`—Program that supports the SD Card file system
* `VfsNet`—Program that is used for working with the network
* `SDCard`—SD Card driver
* `BlobContainer`—Program that loads dynamic libraries used by other programs into shared memory
* `EntropyEntity`—Random number generator
* `DNetSrv`—Driver for working with network cards
* `BSP`—Driver for configuring pin multiplexing parameters (pinmux)
* `Bcm2711MboxArmToVc`—Mailbox driver for Raspberry Pi 4 B

### Initialization description

<details><summary>Statically created IPC channels</summary>

* `example.Client` → `example.NameResolver`
* `example.Client` → `kl.bc.BlobContainer`
* `example.NameResolver` → `kl.VfsSdCardFs`
* `example.NameResolver` → `kl.VfsNet`
* `example.NameResolver` → `kl.bc.BlobContainer`
* `kl.bc.BlobContainer` → `kl.VfsSdCardFs`
* `kl.VfsNet` → `kl.EntropyEntity`
* `kl.VfsNet` → `kl.drivers.DNetSrv`
* `kl.VfsNet` → `kl.bc.BlobContainer`
* `kl.rump.Dhcpcd` → `kl.bc.BlobContainer`
* `kl.rump.Dhcpcd` → `kl.VfsSdCardFs`
* `kl.rump.Dhcpcd` → `kl.VfsNet`
* `kl.VfsSdCardFs` → `kl.drivers.SDCard`
* `kl.VfsSdCardFs` → `kl.EntropyEntity`
* `kl.VfsSdCardFs` → `kl.bc.BlobContainer`
* `kl.EntropyEntity` → `kl.bc.BlobContainer`
* `kl.drivers.DNetSrv` → `kl.drivers.Bcm2711MboxArmToVc`
* `kl.drivers.DNetSrv` → `kl.bc.BlobContainer`
* `kl.drivers.SDCard` → `kl.drivers.BSP`
* `kl.drivers.SDCard` → `kl.bc.BlobContainer`
* `kl.drivers.Bcm2711MboxArmToVc` → `kl.bc.BlobContainer`
* `kl.drivers.BSP` → `kl.bc.BlobContainer`

</details>

The [`./einit/src/init.yaml.in`](einit/src/init.yaml.in) template is used to automatically generate
part of the solution initialization description file `init.yaml`. For more information about the
`init.yaml.in` template file, see the
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_cmake_yaml_templates).

### Security policy description

The [`./einit/src/security.psl.in`](einit/src/security.psl.in) template is used to automatically
generate part of the `security.psl` file using CMake tools. The `security.psl` file contains part
of a solution security policy description. For more information about the `security.psl` file, see
[Describing a security policy for a KasperskyOS-based solution](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_ssp_descr).

[⬆ Back to Top](#Table-of-contents)

## Getting started

### Prerequisites

To install [KasperskyOS Community Edition SDK](https://os.kaspersky.com/development/) and run examples
on QEMU or Raspberry Pi hardware platform, make sure you meet all the
[System requirements](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_system_requirements)
listed in the KasperskyOS Community Edition Developer's Guide.

### Building and running the example

The example is built using the CMake build system, which is provided in the KasperskyOS Community
Edition SDK.

The `SDK_PREFIX` environment variables affects the build of the example. It specifies the path to
the installed version of the KasperskyOS Community Edition SDK. The value of this environment variable
must be set.

To build the example, run the following command:

`$ SDK_PREFIX=/opt/KasperskyOS-Community-Edition-<version> ./cross-build.sh <platform>`,

where:

* `platform` can take one of the following values: `qemu` for QEMU or `rpi` for Raspberry Pi 4 B.
* `version` specifies the latest version number of the [KasperskyOS Community Edition SDK](https://os.kaspersky.com/development/).

The command builds the example and runs the KasperskyOS-based solution image on QEMU. The solution
image is based on the SDK found in the `/opt/KasperskyOS-Community-Edition-<version>` path.

#### QEMU

Running `cross-build.sh` creates a KasperskyOS-based solution image that includes the example. The
`kos-qemu-image` solution image is located in the `./build/einit` directory.

The `cross-build.sh` script both builds the example for QEMU and runs it.

#### Raspberry Pi 4 B

Running `cross-build.sh` creates a KasperskyOS-based solution image that includes the example and
a bootable SD card image for Raspberry Pi 4 B. The `kos-image` solution image is located in the
`./build/einit` directory. The `rpi4kos.img` bootable SD card image is located in the `./build`
directory.

1. To copy the bootable SD card image to the SD card, connect the SD card to the computer and run
the following command:

   `$ sudo dd bs=64k if=build/rpi4kos.img of=/dev/sd[X] conv=fsync`,

   where `[X]` is the final character in the name of the SD card block device.

1. Connect the bootable SD card to the Raspberry Pi 4 B.
1. Supply power to the Raspberry Pi 4 B and wait for the example to run.

You can also use an alternative option to prepare and run the example:

1. Prepare Raspberry Pi 4 B and a bootable SD card to run the example by following the instructions in the
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_preparing_sd_card_rpi).
1. Run the example by following the instructions in the
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_running_sample_programs_rpi)

[⬆ Back to Top](#Table-of-contents)

#### CMake input files

[./client/CMakeLists.txt](client/CMakeLists.txt)—CMake commands for building the `Client` program.

[./einit/CMakeLists.txt](einit/CMakeLists.txt)—CMake commands for building the `Einit` program
and the solution image.

[./resolver/CMakeLists.txt](CMakeLists.txt)—CMake commands for building the `NameResolver` program.

[./CMakeLists.txt](CMakeLists.txt)—CMake commands for building the solution.

## Usage

After running the example, details about the host address (or any errors) returned by the
`NameResolver` should be displayed in the standard output:
```
[example.Client1] Started
[example.Client4] Started
[example.Client2] Started
[example.Client3] Started
[example.NameResolver] Started
[example.Client1] Host dns.google has address: 8.8.8.8
[example.Client4] Host kaspersky.com has address: 185.85.15.26
[example.Client2] Host linux.org has address: 188.114.99.234
[example.Client3] Host os.kaspersky.com has address: 185.105.225.103
[example.Client1] Host www.google.com has address: 173.194.73.147
[example.Client1] Finished
[example.Client2] Host yandex.com has address: 77.88.55.80
[example.Client4] Host rust-lang.org has address: 18.165.122.119
[example.Client4] Host some.not.exists.hosthame.neverland has address: Lookup failed
[example.Client2] Finished
[example.Client3] Host localhost has address: 127.0.0.1
[example.Client4] Finished
[example.Client3] Host cppreference.com has address: 74.114.90.20
[example.Client3] Host isocpp.org has address: 198.199.109.141
[example.Client3] Finished
```

[⬆ Back to Top](#Table-of-contents)

© 2024 AO Kaspersky Lab
