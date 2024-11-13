/*
 * © 2024 AO Kaspersky Lab
 * Licensed under the MIT License
 */

#ifndef RESOLVER_H
#define RESOLVER_H

#include <condition_variable>
#include <list>
#include <mutex>
#include <thread>
#include <utility>

#include <ares.h>
#include <poll.h>

#include <common/ipc.h>
#include <kosipc/application.h>

namespace resolver {

class Resolver : public ipc::Resolver
{
    using CallbackPtr = kosipc::unique_ptr<ipc::ResolveCallback>;
    using HostName    = std::string;
    using Request     = std::pair<HostName, CallbackPtr>;
    using Requests    = std::list<Request>;


    kosipc::Application&    m_app;
    ares_channel            m_channel;
    Requests                m_requests;
    std::mutex              m_requestsGuard;
    std::condition_variable m_hasRequests;
    bool                    m_active = true;
    std::thread             m_thread;


    static void OnResolved(void* req, int status, int timeouts, hostent* host);
    
    int GetTimeout();

    bool HasRequests();
    
    void AddRequest(std::string name, CallbackPtr&& callback);

    void Shutdown();
    
    nfds_t FillPollDescriptors(pollfd descriptors[], const int size);
    
    void ServeRequests();

public:
    explicit Resolver(kosipc::Application& app);

    ~Resolver() override;
    
    void Resolve(const std::string& name, Handle onResolve) override;
};

} // namespace resolver
#endif // RESOLVER_H
