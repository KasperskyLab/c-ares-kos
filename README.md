# C-ares adaptation for KasperskyOS

This is a fork of [c-ares](http://github.com/c-ares/c-ares) project adapted to be used with KasperskyOS. For more information about the target OS, please refer to [KaspeksyOS Community Edition](https://support.kaspersky.com/help/KCE/1.1/en-US/community_edition.htm).

For general information on using c-ares, its features and so on, please see the [c-ares website](https://c-ares.org/).

## About C-ares

This is c-ares, an asynchronous resolver library.  It is intended for
applications which need to perform DNS queries without blocking, or need to
perform multiple DNS queries in parallel.  The primary examples of such
applications are servers which communicate with multiple clients and programs
with graphical user interfaces.

The full source code is available in the ['c-ares' release archives](https://c-ares.haxx.se/download/),
and in a git repository: http://github.com/c-ares/c-ares.

## Building C-ares

For a default build and use, you need to install the KasperskyOS Community Edition SDK on your system. The latest version of the SDK can be downloaded from this [link](https://os.kaspersky.com/development/). The Abseil source code has been checked on the KasperskyOS Community Edition SDK version 1.1.0.

See the [INSTALL.md](INSTALL.md) file for build information.

## Contributing

If you find bugs, correct flaws, have questions or have comments in general in
regard to c-ares (or by all means the original ares too), get in touch with us
on the c-ares mailing list: http://cool.haxx.se/mailman/listinfo/c-ares.

We'll follow the parent project contributing rules but would consider to accept only KasperskyOS-specific changes, so for that it is advised to use pull-requests.

## License

The c-ares library is licensed under the terms of the MIT License. See [LICENSE](LICENSE) for more information.

## Notes for c-ares hackers

* The distributed `ares_build.h` file is only intended to be used on systems
  which can not run the also distributed configure script.

* The distributed `ares_build.h` file is generated as a copy of `ares_build.h.dist`
  when the c-ares source code distribution archive file is originally created.

* If you check out from git on a non-configure platform, you must run the
  appropriate `buildconf*` script to set up `ares_build.h` and other local files
  before being able to compile the library.

* On systems capable of running the `configure` script, the `configure` process
  will overwrite the distributed `ares_build.h` file with one that is suitable
  and specific to the library being configured and built, this new file is
  generated from the `ares_build.h.in` template file.

* If you intend to distribute an already compiled c-ares library you **MUST**
  also distribute along with it the generated `ares_build.h` which has been
  used to compile it. Otherwise the library will be of no use for the users of
  the library that you have built. It is **your** responsibility to provide this
  file. No one at the c-ares project can know how you have built the library.

* File `ares_build.h` includes platform and configuration dependent info,
  and must not be modified by anyone. Configure script generates it for you.

* We cannot assume anything else but very basic compiler features being
  present. While c-ares requires an ANSI C compiler to build, some of the
  earlier ANSI compilers clearly can't deal with some preprocessor operators.

* Newlines must remain unix-style for older compilers' sake.

* Comments must be written in the old-style /* unnested C-fashion */.

* Try to keep line lengths below 80 columns.
