# Async DNS resolver example

Simple example of async DNS resolver demonstrating the usage of c-ares library on KasperskyOS.

The example also demonstrates the use of a callable handle, a client IPC handle that identifies
both an IPC channel to a server and an endpoint of that server. The server creates a callable handle
and passes it to the client so that the client can use the server endpoint. The client initializes
the IPC transport using the received callable handle. For more information, see
[Creating handles](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=libkos_handles_create).

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
      - [Hardware](#hardware)
      - [CMake input files](#cmake-input-files)

## Solution overview

### List of programs

* `Client`—Program that sends a request to the `NameResolver` program for name resolution and prints
the host name and address (or any errors) returned by the `NameResolver`.
* `NameResolver`—Program acts as a server that takes a host name to resolve and uses a callback to
report the result to the `Client` program. To resolve the host name, the `cares_gethostbyname`
function is used.
* `Dhcpcd`—DHCP client implementation program that gets network interface parameters from an external
DHCP server in the background and passes them to the virtual file system.
* `VfsSdCardFs`—Program that supports the SD Card file system.
* `VfsNet`—Program that is used for working with the network.
* `SDCard`—SD Card driver.
* `BlobContainer`—Program that loads dynamic libraries used by other programs into shared memory.
* `EntropyEntity`—Random number generator.
* `DNetSrv`—Driver for working with network cards.
* `BSP`—Driver for configuring pin multiplexing parameters (pinmux).
* `Bcm2711MboxArmToVc`—Driver for working with the VideoCore (VC6) coprocessor via mailbox technology for Raspberry Pi 4 B.

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
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=cmake_yaml_templates).

### Security policy description

The [`./einit/src/security.psl.in`](einit/src/security.psl.in) template is used to automatically
generate part of the `security.psl` file using CMake tools. The `security.psl` file contains part
of a solution security policy description. For more information about the `security.psl` file, see
[Describing a security policy for a KasperskyOS-based solution](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=ssp_descr).

[⬆ Back to Top](#table-of-contents)

## Getting started

### Prerequisites

To install [KasperskyOS Community Edition SDK](https://os.kaspersky.com/development/) and run examples
on QEMU or a hardware platform, make sure you meet all the
[System requirements](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=system_requirements)
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

* `platform` can take one of the following values: `qemu` for QEMU or `hw` for Raspberry Pi 4 B or Radxa ROCK 3A.
* `version` specifies the latest version number of the [KasperskyOS Community Edition SDK](https://os.kaspersky.com/development/).

For example, review the following command:
```sh
$ SDK_PREFIX=/opt/KasperskyOS-Community-Edition-<version> ./cross-build.sh qemu
```

The command builds the example and runs the KasperskyOS-based solution image on QEMU. The solution
image is based on the SDK found in the `/opt/KasperskyOS-Community-Edition-<version>` path, where
`version` is the latest version number of the KasperskyOS Community Edition SDK.

#### QEMU

Running `cross-build.sh` creates a KasperskyOS-based solution image that includes the example. The
`kos-qemu-image` solution image is located in the `./build/einit` directory.

The `cross-build.sh` script both builds the example for QEMU and runs it.

#### Hardware

Running `cross-build.sh` creates a KasperskyOS-based solution image that includes the example and
a bootable SD card image for the hardware platform. The `kos-image` solution image is located in the
`./build/einit` directory. The `hdd.img` bootable SD card image is located in the `./build`
directory.

1. To copy the bootable SD card image to the SD card, connect the SD card to the computer and run
the following command:

   `$ sudo dd bs=64k if=build/hdd.img of=/dev/sd[X] conv=fsync`,

   where `[X]` is the final character in the name of the SD card block device.

1. Connect the bootable SD card to the hardware.
1. Supply power to the hardware and wait for the example to run.

You can also use an alternative option to prepare and run the example:

1. Prepare the required hardware platform and bootable SD card by following the instructions in the KasperskyOS Community Edition Online Help:
    * [Raspberry Pi 4 B](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=preparing_sd_card_rpi)
    * [Radxa ROCK 3A](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=preparing_sd_card_radxa)
1. Run the example by following the instructions in the
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.3&customization=KCE&helpid=running_sample_programs_rpi)

[⬆ Back to Top](#table-of-contents)

#### CMake input files

[./client/CMakeLists.txt](client/CMakeLists.txt)—CMake commands for building the `Client` program.

[./einit/CMakeLists.txt](einit/CMakeLists.txt)—CMake commands for building the `Einit` program
and the solution image.

[./resolver/CMakeLists.txt](CMakeLists.txt)—CMake commands for building the `NameResolver` program.

[./CMakeLists.txt](CMakeLists.txt)—CMake commands for building the solution.

[⬆ Back to Top](#table-of-contents)

© 2025 AO Kaspersky Lab
