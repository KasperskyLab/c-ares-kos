/*
 * © 2024 AO Kaspersky Lab
 * Licensed under the MIT License
 */

#include "resolver.h"

#include <chrono>
#include <cstring>

#include <sys/time.h>
#include <netdb.h>

#include <common/print.h>
#include <kosipc/connect_user_handle.h>
#include <kosipc/auto_handle.h>

using namespace kosipc;
using namespace resolver::util;

namespace resolver {

void Resolver::OnResolved(void* req, int status, [[maybe_unused]] int timeouts, hostent* host)
{
    static constexpr int ipOctets = 4;
    auto request  = static_cast<Request*>(req);
    auto callback = std::move(std::get<CallbackPtr>(*request));
    if (status == ARES_SUCCESS && host != nullptr)
    {
        std::string addr;
        for (int i = 0; i < ipOctets; ++i)
        {
            addr += (std::to_string(host->h_addr_list[0][i]) + ".");
        }
        addr.pop_back();
        callback->OnResolve(host->h_name, addr);
    }
    else
    {
        callback->OnResolve(std::get<HostName>(*request), "Lookup failed");
    } 
}

int Resolver::GetTimeout()
{
    using namespace std::chrono;
    timeval tv{}, *tvp{};
    tvp = ares_timeout(m_channel, NULL, &tv);
    return static_cast<int>(duration_cast<milliseconds>(microseconds{tvp->tv_usec} + seconds{tvp->tv_sec}).count());
}

bool Resolver::HasRequests()
{
    std::unique_lock lock{m_requestsGuard};
    m_requests.remove_if([](auto const& request) { return std::get<CallbackPtr>(request) == nullptr; });

    if (m_requests.empty() && m_active)
    {
        m_hasRequests.wait(lock, [this]{ return !m_requests.empty() || !m_active; });
    }
    
    return !m_requests.empty();
}

void Resolver::AddRequest(std::string name, CallbackPtr&& callback)
{
    Request* request{};
    {
        std::unique_lock lock(m_requestsGuard);
        request = &m_requests.emplace_back(std::move(name), std::move(callback));
    }
    ares_gethostbyname(m_channel, request->first.c_str(), AF_INET, OnResolved, request);
    m_hasRequests.notify_one();
}

void Resolver::Shutdown()
{
    {
        std::unique_lock lock{m_requestsGuard};
        m_active = false;
    }
    m_hasRequests.notify_one();
}

nfds_t Resolver::FillPollDescriptors(pollfd descriptors[], const int size)
{
    nfds_t descNum = 0;
    ares_socket_t socks[ARES_GETSOCK_MAXNUM];
    const int maxSocksNum = std::min(size, ARES_GETSOCK_MAXNUM);
    auto bitmask = ares_getsock(m_channel, socks, maxSocksNum);
    for (int i = 0; i < maxSocksNum; i++)
    {
        descriptors[i].events  = 0;
        descriptors[i].revents = 0;

        if (ARES_GETSOCK_READABLE(bitmask, i))
        {
            descriptors[i].events |= POLLIN;
        }

        if (ARES_GETSOCK_WRITABLE(bitmask, i))
        {
            descriptors[i].events |= POLLOUT;
        }

        if (descriptors[i].events == 0)
        {
            break;
        }

        descriptors[i].fd = socks[i];
        ++descNum;
    }
    return descNum;
}

void Resolver::ServeRequests()
{
    pollfd descriptors[ARES_GETSOCK_MAXNUM];
    while (HasRequests())
    {
        auto descNum = FillPollDescriptors(descriptors, ARES_GETSOCK_MAXNUM);
        if (descNum <= 0)
        {
            continue;
        }

        auto pollResult = poll(descriptors, descNum, GetTimeout());
        if (pollResult > 0)
        {
            for (decltype(descNum) i = 0; i < descNum; ++i)
            {
                int fdRead  = descriptors[i].revents & POLLIN  ? descriptors[i].fd : ARES_SOCKET_BAD;
                int fdWrite = descriptors[i].revents & POLLOUT ? descriptors[i].fd : ARES_SOCKET_BAD;
                ares_process_fd(m_channel, fdRead, fdWrite);
            }
        }
        else
        {
            ares_process_fd(m_channel, ARES_SOCKET_BAD, ARES_SOCKET_BAD);
            if (pollResult < 0)
            {
                Print("Poll failed with error:", std::strerror(errno));
                ares_cancel(m_channel);
            }
        }
    }
}

Resolver::Resolver(Application& app) : m_app{app}
{
    ares_library_init(ARES_LIB_INIT_ALL);
    if (ares_init(&m_channel) != ARES_SUCCESS)
    {
        throw std::runtime_error{"Ares channel init failed"};
    }
    m_thread = std::thread{[this]{ ServeRequests(); }};
}

Resolver::~Resolver()
{
    Shutdown();

    if (m_thread.joinable())
    {
        m_thread.join();
    }

    ares_destroy(m_channel);
    ares_library_cleanup();
}

void Resolver::Resolve(const std::string& name, Handle onResolve)
{
    if (name.empty())
    {
       throw std::invalid_argument{"Empty host name"};
    }

    AutoHandle callable{onResolve};
    auto callback = m_app.MakeProxy<ipc::ResolveCallback>(ConnectUserHandle(std::move(callable)));
    AddRequest(name, std::move(callback));
}

} // namespace resolver
