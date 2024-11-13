/*
 * © 2024 AO Kaspersky Lab
 * Licensed under the MIT License
 */


#include <iostream>
#include <utility>
#include <thread>
#include <vector>
#include <chrono>
#include <atomic>

#include <kosipc/application.h>
#include <kosipc/make_application.h>
#include <kosipc/connect_static_channel.h>

#include <common/ipc.h>
#include <common/callable.h>
#include <common/print.h>

#include <example/Client.edl.cpp.h>

using namespace kosipc;
using namespace resolver;
using namespace util;

class OnResolveCallback : public ipc::ResolveCallback
{
public:

    void OnResolve(const std::string& name, const std::string& address) override
    {
        Print("Host", name, "has address:", address);
    }
};

int main(int argc, const char *argv[])
{
    Print("Started");

    if (argc == 1)
    {
        Print("No host names passed - nothing to do");
        return EXIT_SUCCESS;
    }

    auto              app{MakeApplicationAutodetect()};
    OnResolveCallback onResolve{};
    components::Root  root;
    root.onResolve = &onResolve;

    try
    {
        Callable callback{app, root.onResolve};
        auto     resolver{app.MakeProxy<ipc::Resolver>(ConnectStaticChannel(resolver::SeviceId, resolver::Endpoint))};
        for (auto name = argv + 1; *name != nullptr; ++name)
        {
            resolver->Resolve(*name, callback.Get());
        }
    }
    catch (const std::exception& exc)
    {
        Print("Error occurred while name resolving:", exc.what());
        return EXIT_FAILURE;
    }

    Print("Finished");
    return EXIT_SUCCESS;
}
