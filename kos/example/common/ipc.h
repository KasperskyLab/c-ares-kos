/*
 * © 2024 AO Kaspersky Lab
 * Licensed under the MIT License
 */

#ifndef COMMON_IPC_H
#define COMMON_IPC_H

#include <example/Resolver.idl.cpp.h>
#include <example/ResolveCallback.idl.cpp.h>

namespace resolver {

namespace ipc =  kosipc::stdcpp::example;

constexpr auto SeviceId = "name_resolver";
constexpr auto Endpoint = "resolver";

} // namespace resolver
#endif // COMMON_IPC_H

