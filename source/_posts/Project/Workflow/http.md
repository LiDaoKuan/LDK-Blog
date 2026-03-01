---
title: workflow源码分析——http实现
date: 2026-02-18
updated: 2026-02-18
tags: [sogo workflow, C++, project]
categories: sogo workflow
description: 
---

## 先看一个简单的例子

```cpp
// 发起一个http请求

#include <iostream>
#include <workflow/Workflow.h>
#include <workflow/WFTaskFactory.h>
#include <workflow/WFFacilities.h>
#include <signal.h>

using namespace protocol;

#define REDIRECT_MAX 4
#define RETRY_MAX 2

void http_callback(WFHttpTask *task)
{
    HttpResponse *resp = task->get_resp();
    fprintf(stderr, "Http status : %s\n", resp->get_status_code());

    // response body
    const void *body;
    size_t body_len;
    resp->get_parsed_body(&body, &body_len);

    // write body to file
    FILE *fp = fopen("res.txt", "w");
    fwrite(body, 1, body_len, fp);
    fclose(fp);

    fprintf(stderr, "write file done");
}

static WFFacilities::WaitGroup wait_group(1);

void sig_handler(int signo)
{
    wait_group.done();
}

int main()
{
    signal(SIGINT, sig_handler);
    // logger_initConsoleLogger(stderr);
	// logger_setLevel(LogLevel_TRACE);
    std::string url = "http://www.baidu.com";

    // 通过create_xxx_task创建的对象为任务，一旦创建，必须被启动或取消
    // 工厂函数创建的对象的生命周期均由内部管理
    WFHttpTask *task = WFTaskFactory::create_http_task(url,
                                                       REDIRECT_MAX,
                                                       RETRY_MAX,
                                                       http_callback);

    // 通过start,自行以task为first_task创建一个串行并理解启动任务
    // 任务start后，http_callback回调前，用户不能再操作该任务
    // 在一个task被直接或间接 dismiss/start 之后，用户不再拥有其所有权
    // 此后用户只能在该task的回调函数内部进行操作
    task->start();
    // 当http_callback任务结束后，任务立即被释放
    wait_group.wait();
}
```

上述代码中，通过`WFTaskFactory::create_http_task`函数创建了一个`http`任务。函数细节如下：

```cpp
/**
 * @brief 创建普通HTTP任务（通过URL字符串）
 *
 * 工作流程:
 * 1. 创建ComplexHttpTask实例（支持重定向/重试）
 * 2. 解析URL为结构化URI
 * 3. 初始化任务参数
 * 4. 设置默认保活时间
 *
 * @param url 目标URL（如 "http://example.com/path"）
 * @param redirect_max 最大重定向次数（0表示禁止重定向）
 * @param retry_max 最大重试次数（0表示禁止重试）
 * @param callback 任务完成回调
 * @return WFHttpTask* 创建的任务对象
 */
WFHttpTask *WFTaskFactory::create_http_task(const std::string &url,
                                            int redirect_max,
                                            int retry_max,
                                            http_callback_t callback) {
    // 创建核心任务对象（支持重定向/重试）
    auto *task = new ComplexHttpTask(redirect_max,
                                     retry_max,
                                     std::move(callback));
    // 解析URL
    ParsedURI uri;
    URIParser::parse(url, uri);
    // 初始化任务（设置目标地址、协议版本等）
    task->init(std::move(uri));
    // 启用Keep-Alive（默认60秒）
    task->set_keep_alive(HTTP_KEEPALIVE_DEFAULT);
    return task;
}
```

可以看到，上面函数返回的是一个`ComplexHttpTask`：

```cpp
/**
 * @brief 支持重定向/重试的HTTP客户端任务
 * 继承自WFComplexClientTask, 实现HTTP特有的连接管理、认证、重定向逻辑
 */
class ComplexHttpTask : public WFComplexClientTask<HttpRequest, HttpResponse> {
public:
    /**
     * @param redirect_max 允许的最大重定向次数
     * @param retry_max 允许的最大重试次数
     * @param callback 用户回调函数
     */
    ComplexHttpTask(int redirect_max, int retry_max, http_callback_t &&callback) :
        WFComplexClientTask(retry_max, std::move(callback)),
        redirect_max_(redirect_max),
        redirect_count_(0) {
        HttpRequest *client_req = this->get_req();
        // 设置默认请求方法和HTTP版本
        client_req->set_method(HttpMethodGet);
        client_req->set_http_version("HTTP/1.1");
    }

public:
    /* ... */

private:
    /* ... */
};
```

## `WFComplexClientTask<HttpRequest, HttpResponse>`

而`ComplexHttpTask`又继承自`WFComplexClientTask<HttpRequest, HttpResponse>`，这是一个**模板特化**类

```cpp
/**创建复杂网络客户端任务的模板基类.
 * @param REQ: 请求协议类型（例如 protocol::HttpRequest）.
 * @param RESP: 响应协议类型（例如 protocol::HttpResponse）.
 * @param ctx: 任务上下文类型. 用于在任务执行过程中携带和传递用户自定义的上下文信息, 实现更复杂的状态管理. 默认为bool型 */
template <class REQ, class RESP, typename CTX = bool>
class WFComplexClientTask : public WFClientTask<REQ, RESP>
{
    /* ... */

protected:
    void dispatch() override;

    SubTask *done() override;
}
```

`WFComplexClientTask`类的具体实现细节先放后面，总之只需要知道这个类实现了应用层client该有的功能就行了，其他细节以后在说。

在workflow中，所有的`task`任务类都直接或者间接继承自`SubTask`和`ParallelTask`，同时必须实现两个纯虚函数：`dispatch`和`done`，不同的task继承实现不同的逻辑。`dispatch`是任务

而`http client`中的具体逻辑就实现在`WFComplexClientTask`这一层。

```cpp
template <class REQ, class RESP, typename CTX>
void WFComplexClientTask<REQ, RESP, CTX>::dispatch() {
    switch (this->state) //
    {
    case WFT_STATE_UNDEFINED:      // 第一次请求时是未定义状态.
        if (this->check_request()) // 检查参数是否合法，此处直接return true。如果是mysql协议这里更复杂，可以在子类重写
        {
            if (this->route_result_.request_object) // 检查是否已有有效的请求对象。第一次请求走到这里，request_object是空的，直接到下面产生router_task_
            {
            case WFT_STATE_SUCCESS: // 第二次请求就直接success了
                this->set_request_object(this->route_result_.request_object);
                // 此处实际上调用了WFClientTask的父类的父类CommRequest的dispatch
                // 调用scheduler->request
                this->WFClientTask<REQ, RESP>::dispatch();
                return;
            }
            // 没有有效的请求对象, 产生一个router_task_插入到前面去做dns解析
            router_task_ = this->route();
            series_of(this)->push_front(this);         // 将当前任务放入任务队列
            series_of(this)->push_front(router_task_); // 将路由任务放在当前任务之前
        }
    default: break;
    }
    this->subtask_done();
}
```

这个函数的大致逻辑就是：

第一次执行dispatch时，由于不知道目标的ip地址，我们首先需要做DNS解析，这样才能得到请求对象的ip地址。此时新创建一个路由任务进行DNS解析，并且将其放在原任务的前面。

```cpp
// 没有有效的请求对象, 产生一个router_task_插入到前面去做dns解析
router_task_ = this->route();
series_of(this)->push_front(this);         // 将当前任务放入任务队列
series_of(this)->push_front(router_task_); // 将路由任务放在当前任务之前
```

这样在获取到目标的ip地址后（`route_task_`执行完毕），会接着执行下一个任务，也就是再重新执行一次原任务，但这一次有了ip地址。

## `CommRequest::dispatch`

还有一点，`WFComplexClientTask<HttpRequest, HttpResponse>::dispatch()`最终会调用`this->WFClientTask<REQ, RESP>::dispatch();`来执行任务的真正逻辑（发送请求）。

而`WFClientTask<REQ, RESP>`其实并没有实现`dispatch()`，但它有继承于`CommRequest`的`dispatch`函数。

先来看一下继承关系：

```
父    CommRequest         // dispatch() override
        ^
        |   继承
    WFNetworkTask<REQ, RESP>
        ^
        |   继承
    WFClientTask<REQ, RESP>
        ^
        |   继承
    WFComplexClientTask<HttpRequest, HttpResponse>(模板特化)  // dispatch() override
        ^
        |   继承
子    ComplexHttpTask
```

再看一下具体实现：

```cpp
class CommRequest : public SubTask, public CommSession {
public:
    // 实现任务启动接口
    void dispatch() override {
        // 将实际的网络请求发起工作委托给了CommScheduler.
        // scheduler->request是一个异步操作, 它会将请求提交给底层的Communicator(通信器), 然后立即返回, 不会阻塞当前线程
        if (this->scheduler->request(this, this->object, this->wait_timeout, &this->target) < 0) {
            // 返回值<0表示出现了错误
            this->handle(CS_STATE_ERROR, errno); // 立即失败
        }
    }
};
```

这里需要关注两点：

1. 首先 `CommRequest` 继承自 `SubTask` 和 `CommSession`

    说明 `CommRequest` 即是一个（请求）任务，又满足 `CommSession` 的特性。

    `CommSession`是一次 `req->resp`(请求到响应) 的交互，主要要实现`message_in()`, `message_out()`等几个虚函数，让核心知道怎么收发消息。同时`CommSession`也是协议无关的，具体看后面代码。

2. 这里的 `scheduler` 是 `CommScheduler`

    之前我们在epoll章节中讲过，`CommScheduler`是全局唯一的单例，在`Scheduler` 单例第一次实例化的时候，执行了 `CommScheduler init`，然后`Communicator init`, 产生 `poller` 线程和线程池，并启动了 `poller` 线程。

附上`CommSession`的源码：

```cpp
/* 管理单个网络会话生命周期 */
class CommSession {
private:
    /* message_out/message_in 这两个纯虚函数是 “工厂方法模式” 的典型应用.
     * 它强制要求每个具体的协议会话(如HTTPSession、MySQLSession)必须提供自己专用的消息解析器(CommMessageIn)和消息构造器(CommMessageOut).
     * 这使得 CommSession 本身完全不关心数据包的具体格式（无论是 HTTP 头部、MySQL 协议包还是自定义二进制协议），实现了真正的 协议无关性.
     * 框架底层(如Communicator)在需要读取或发送数据时，只需调用这两个接口获得相应的消息处理器进行操作即可 */

    // message_out/message_in: 提供消息处理器, 用于构造请求和解析响应
    virtual CommMessageOut *message_out() = 0;
    virtual CommMessageIn *message_in() = 0;

    /* 下面四个函数使用了策略模式:
     * 可以根据不同协议的特性(如HTTP请求需要响应超时, 而TCP长连接可能需要心跳保活)来定制最合适的超时策略
     * 这些函数返回 -1 表示禁用超时，返回 0 表示使用默认值，返回正数表示自定义超时毫秒数 */

    // 控制超时策略, 管理连接生命周期
    virtual int send_timeout() { return -1; }      /* 控制发送数据过程的超时, 防止因网络延迟或对端无响应导致的连接长期挂起, 默认返回-1, 即: 永不超时 */
    virtual int receive_timeout() { return -1; }   /* 控制接收数据过程的超时, 防止因网络延迟或对端无响应导致的连接长期挂起 */
    virtual int keep_alive_timeout() { return 0; } /* 管理连接空闲时间，是实现 HTTP Keep-Alive 或数据库连接池等长连接功能的关键 */
    virtual int first_timeout() { return 0; }      /* 控制连接建立或首包发送的超时, 对于快速发现不可达的服务端至关重要 */

    /* handle方法是整个异步框架的 回调入口, 是 “模板方法模式” 的体现.
     * 当底层的 I/O 操作完成(如连接建立成功、数据接收完毕、超时发生或出错)时, WorkFlow 的 Communicator 会调用此函数
     * 子类在此方法中实现核心业务逻辑. 如：
     *  - 当state为成功时，处理接收到的完整请求(CommMessageIn), 并生成回复数据(CommMessageOut)
     *  - 当发生错误或超时时，进行资源的清理和错误日志记录 */

    // 异步事件处理, 处理IO操作结果或状态变更
    virtual void handle(int state, int error) = 0;

protected:
    // 获取会话上下文, 如连接对象、消息对象和序列号
    [[nodiscard]] CommTarget *get_target() const { return this->target; }
    [[nodiscard]] CommConnection *get_connect() const { return this->conn; }
    [[nodiscard]] CommMessageIn *get_message_in() const { return this->msg_in; }
    [[nodiscard]] CommMessageOut *get_message_out() const { return msg_out; }
    [[nodiscard]] long long get_seq() const { return this->seq; }

private:
    CommTarget *target;
    CommConnection *conn;    // 代表底层的网络连接
    CommMessageOut *msg_out; // 指向当前会话使用的消息处理器
    CommMessageIn *msg_in;   // 指向当前会话使用的消息处理器
    long long seq;           // 序列号, 用于匹配请求和响应, 尤其在多路复用的连接中非常重要

    struct timespec begin_time; // 操作的开始时间
    int timeout;                // 操作的超时阀值(毫秒？)
    int passive;                // 当设置为 1 时, 表示该会话是由服务端被动接受的连接, 这将影响框架内部对其生命周期管理的策略

public:
    CommSession() { this->passive = 0; }
    virtual ~CommSession() = 0;
    friend class CommMessageIn;
    friend class Communicator;
};
```

## `CommSchedObject/CommTarget`

回到`CommRequest::dispatch()`中，我们可以看到发送请求时执行的是：

```cpp
this->scheduler->request(this, this->object, this->wait_timeout, &this->target);
```

此处的`request`函数在`CommScheduler`中：

```cpp
// 客户端发起请求(建立连接)
int CommScheduler::request(CommSession *session, CommSchedObject *object, const int wait_timeout, CommTarget **target) {
    int ret = -1;
    *target = object->acquire(wait_timeout); // 1. 获取连接
    if (*target) {
        ret = this->comm.request(session, *target); // 2. 发起异步请求
        if (ret < 0) { (*target)->release(); } // 3. 失败则立即释放连接
    }
    return ret;
}
```

那么，此处传入的`CommSchedObject`和`CommTarget`是什么呢？

在`WFComplexClientTask`的构造函数中可以看到，变量`CommScheduler::object`在初始化时传入的是`NULL`（通过子类构造函数一层一层向上传递），显然`NULL`值不可能直接拿来用，那是在哪里传入的非空值呢？

```cpp
// WFComplexClientTask的构造函数
WFComplexClientTask(const int retry_max, task_callback_t &&cb) :
        WFClientTask<REQ, RESP>(NULL, WFGlobal::get_scheduler(), std::move(cb))
{
    /* ... */
}
```

只有一个地方：

```cpp
void set_request_object(CommSchedObject *_object) { this->object = _object; }
```

没错，就是这个小小的`set`函数，它在哪里被调用呢？**在`WFComplexClientTask::dispatch`中**，有一句：

```cpp
this->set_request_object(route_result_.request_object)
```

也只有这一个地方调用了该set函数。代码在上面已经给出了，不重复贴了。

而此处传入的`route_result_.request_object`其实就是之前说的DNS解析生成的数据。它是`CommSchedObject*`类型。关于DNS解析，此处先略过。

所以`CommSchedObject`到底是一个什么呢？可以暂时这样理解：

```cpp
/*
CommSchedObject: 路由结果的核心, 指向一个可被调度的连接对象. 具体可能是两种类型:
    - CommSchedTarget: 当 DNS 解析结果只有一个 IP 地址时, 它直接代表一个具体的服务器目标.
    - CommSchedGroup: 当 DNS 解析结果有多个 IP 地址(即多个目标)时, 它是一个负载均衡组, 内部根据策略(如轮询或一致性哈希)选择一个目标进行连接
*/
```

这个类的定义：

```cpp
// 通信调度对象基类
class CommSchedObject {
public:
    // 获取最大负载
    [[nodiscard]] size_t get_max_load() const { return this->max_load; }
    // 获取当前负载
    [[nodiscard]] size_t get_cur_load() const { return this->cur_load; }

private:
    // 指定时间内获取连接. 由子类实现
    virtual CommTarget *acquire(int wait_timeout) = 0;

protected:
    size_t max_load;
    size_t cur_load;

public:
    virtual ~CommSchedObject() = default;
    friend class CommScheduler;
};
```


