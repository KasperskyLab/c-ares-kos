/*
 * © 2024 AO Kaspersky Lab
 * Licensed under the MIT License.
 */


#ifndef KOS_TEST_BOOTSTRAP_H
#define KOS_TEST_BOOTSTRAP_H

#include <filesystem>
#include <iostream>
#include <string>

#include <sys/mount.h>

#include <kos_net.h>

namespace kos  {
namespace test {

inline void bootstrap()
{
  using namespace std::string_literals;

  constexpr auto device     = "romfs";
  constexpr auto fs         = "romfs";
  constexpr auto mountpoint = "/etc";

  if (!std::filesystem::create_directory(mountpoint)) {
    throw std::runtime_error("Failed to create directory "s + mountpoint);
  }

  if (mount(device, mountpoint, fs, MS_RDONLY, "") != 0) {
    throw std::runtime_error("Failed to mount romfs to "s + mountpoint);
  }

  if (!wait_for_network()) {
    throw std::runtime_error("Network up failed");
  }
}

} // namespace test
} // namespace kos

#endif
