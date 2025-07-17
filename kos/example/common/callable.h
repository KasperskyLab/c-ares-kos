/*
 * © 2024 AO Kaspersky Lab
 * Licensed under the MIT License
 */

#ifndef COMMON_CALLABLE_H
#define COMMON_CALLABLE_H

#include <thread>
#include <functional>
#include <queue>
#include <mutex>
#include <condition_variable>

#include <kosipc/auto_handle.h>
#include <kosipc/event_loop.h>
#include <kosipc/serve_user_handle.h>

namespace resolver {
namespace util     {

class Callable
{
    using CBHandler  = std::function<void(kosipc::EventLoop&)>;
    using CBHandlers = std::queue<CBHandler>;

    kosipc::AutoHandle      m_callable;
    std::thread             m_thread;
    CBHandlers              m_handlers;
    std::mutex              m_handlersGuard;
    std::condition_variable m_notEmpty;

    void ServeCalls(kosipc::EventLoop loop)
    {
        while (auto handler = GetHandler())
        {
            handler(loop);
        }
    }

    void AddHandler(CBHandler&& handler)
    {
        {
            std::unique_lock lock{m_handlersGuard};
            m_handlers.push(std::move(handler));
        }
        m_notEmpty.notify_one();
    }

    CBHandler GetHandler()
    {
        std::unique_lock lock{m_handlersGuard};
        if (m_handlers.empty())
        {
            m_notEmpty.wait(lock, [this]() { return !m_handlers.empty(); });
        }
        CBHandler handler = std::move(m_handlers.front());
        m_handlers.pop();
        return handler;
    }

public:

    template <typename Endpoint>
    Callable(kosipc::Application& app, Endpoint& endpoint)
    {
        Handle listener;
        Handle server;
        Handle client;

        KnHandleConnect(INVALID_HANDLE, &listener, &server, &client);
        KnHandleClose(client);
        if (server != listener)
        {
            KnHandleClose(server);
        }

        Handle callable;
        auto rc = KnHandleCreateUserObjectEx(
            HANDLE_TYPE_USER_FIRST,
            OCAP_IPC_CALL | OCAP_HANDLE_TRANSFER,
            nullptr,
            listener,
            GetGeneralEndpoint(endpoint).GetRiid(),
            &callable
        );

        if (rc != rcOk)
        {
            std::string msg{"KnHandleCreateUserObjectEx failed with code: "};
            msg.append(std::to_string(rc));
            throw std::runtime_error(msg);
        }

        m_callable = kosipc::AutoHandle{callable};
        auto loop  = app.MakeEventLoop(ServeUserHandle(kosipc::AutoHandle{listener}, endpoint));
        m_thread   = std::thread{[this](auto loop) mutable { ServeCalls(std::move(loop)); }, std::move(loop)};
    }

    ~Callable()
    {
        AddHandler(CBHandler{});
        if (m_thread.joinable())
        {
            m_thread.join();
        }
    }

    Handle Get()
    {
        AddHandler([](auto& loop){loop.Step();});
        return m_callable.GetHandle();
    }
};

} // namespace util
} // namespace resolver
#endif // COMMON_CALLABLE_H
