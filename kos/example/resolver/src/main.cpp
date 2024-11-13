/*
 * © 2024 AO Kaspersky Lab
 * Licensed under the MIT License
 */

#include <kos_net.h>
#include <kosipc/application.h>
#include <kosipc/event_loop.h>
#include <kosipc/make_application.h>
#include <kosipc/serve_static_channel.h>

#include <common/print.h>
#include <example/NameResolver.edl.cpp.h>

#include "resolver.h"

using namespace kosipc;
using namespace resolver;
using namespace util;

int main(void)
{
    Print("Started");

    if (!wait_for_network())
    {
        Print("Network up failed");
        return EXIT_FAILURE;
    }

    try
    {
        auto             app{MakeApplicationAutodetect()};
        Resolver         resolver{app};
        components::Root root;

        root.resolver = &resolver;
        auto loop     = app.MakeEventLoop(ServeStaticChannel(resolver::SeviceId, root));
        loop.Run();
    }
    catch (const std::exception& exc)
    {
        Print("Error occurred:", exc.what());
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
