---
title: workflow源码分析——epoll和主事件循环
date: 2026-02-18
updated: 2026-02-18
tags: [sogo workflow, C++, project]
categories: sogo workflow
description: 
---

## epoll 切入口 `__poller_wait`

Linux平台下，epoll只有三个api: epoll_create， epoll_ctl， epoll_wait。

找到epoll_wait，就能找到事件处理的核心（主事件循环）。

而workflow中，epoll_wait只在一个位置调用：

```cpp
/src/kernel/poller.c
/* 阻塞式epoll */
static inline int __poller_wait(__poller_event_t *events, 
                                int maxevents, 
                                const poller_t *poller) {
    /* timeout参数：
     *  - -1: 阻塞模式
     *  - 0: 非阻塞模式，立即返回
     *  - >0: 表示定时阻塞的时间，单位毫秒 */
    return epoll_wait(poller->pfd, events, maxevents, -1);
}
```

先不看`poller_t`是个什么。只看`__poller_wait`这一个函数看不出来整个事件处理的逻辑。找找`__poller_wait`被谁调用了：

也只有一个地方：`poller_thread_routine`.

## `poller_thread_routine`

完整的`poller_thread_routine`是这样的，很长，不好分析具体逻辑。

```cpp
/* 核心事件循环函数. 处理事件分发 */
static void *poller_thread_routine(void *arg) {
    poller_t *poller = (poller_t *)arg; // 传入参数
    __poller_event_t events[POLLER_EVENTS_MAX]; // 存储epoll监听到的事件
    struct __poller_node time_node;
    struct __poller_node *node;
    int has_pipe_event = 0;
    int nevents = 0;
    int i = 0;

    while (1) {
        __poller_set_timer(poller); // 设置定时器
        nevents = __poller_wait(events, POLLER_EVENTS_MAX, poller); // 阻塞等待
        clock_gettime(CLOCK_MONOTONIC, &time_node.timeout); // 记录当前时间
        has_pipe_event = 0;
        // 循环遍历所有已经发生的事件
        for (i = 0; i < nevents; i++) {
            // 取出设置监听时传入的信息
            node = (struct __poller_node *)__poller_event_data(&events[i]);
            switch (node->data.operation) {
            // 根据当初设置的值判断触发了什么操作
            case PD_OP_READ: __poller_handle_read(node, poller);
                break;
            case PD_OP_WRITE: __poller_handle_write(node, poller);
                break;
            case PD_OP_LISTEN: __poller_handle_listen(node, poller);
                break;
            case PD_OP_CONNECT: __poller_handle_connect(node, poller);
                break;
            case PD_OP_RECVFROM: __poller_handle_recvfrom(node, poller);
                break;
            case PD_OP_SSL_ACCEPT: __poller_handle_ssl_accept(node, poller);
                break;
            case PD_OP_SSL_CONNECT: __poller_handle_ssl_connect(node, poller);
                break;
            case PD_OP_SSL_SHUTDOWN: __poller_handle_ssl_shutdown(node, poller);
                break;
            case PD_OP_EVENT: __poller_handle_event(node, poller);
                break;
            case PD_OP_NOTIFY: __poller_handle_notify(node, poller);
                break;
            case -1: has_pipe_event = 1; // 特殊管道事件
                break;
            default: ;
            }
        }

        if (has_pipe_event) {
            if (__poller_handle_pipe(poller)) {
                // 处理管道消息，若返回非0则说明出现问题，退出循环
                break;
            }
        }
        // 处理所有超时事件
        __poller_handle_timeout(&time_node, poller);
    }

    return NULL;
}
```

简化一下：

```cpp
static void *poller_thread_routine(void *arg)
{
	// ...
	while (1)
	{
        // ...
		nevents = __poller_wait(events, POLLER_EVENTS_MAX, poller);
        // ...
		for (i = 0; i < nevents; i++)
		{
			node = (struct __poller_node *)__poller_event_data(&events[i]);
			if (node > (struct __poller_node *)1)
			{
				switch (node->data.operation)
				{
				case PD_OP_READ:
					__poller_handle_read(node, poller);
					break;
				case PD_OP_WRITE:
					__poller_handle_write(node, poller);
					break;
					// ...
				}
			}
            // ...
		}   
        // ...
}
```

可以看到，这里是将epoll触发的事件数组`events`，挨个根据他们的`operation`分发给不同的行为函数(read/write....)

## `poller_start`

再看看`poller_thread_routine`在哪里被调用了：

`poller_thread_routine`的唯一一个引用就是在`poller_start`中，但**并不是直接调用。而是传给了`pthread_create`函数**，这是`pthread`库用来创建线程的函数。

```cpp
int poller_start(poller_t *poller) {
    pthread_t tid;
    int ret = 0;

    pthread_mutex_lock(&poller->mutex);
    if (__poller_open_pipe(poller) >= 0) {
        // 如果管道创建成功。则开启poller线程
        ret = pthread_create(&tid, NULL, poller_thread_routine, poller); // 重点在这一行
        if (ret == 0) {
            // 线程创建成功
            poller->tid = tid;
            poller->stopped = 0;
        } else {
            // 线程创建失败
            // 此处poller->stop没有更改, 因为poller->stop的默认值是1
            errno = ret;
            close(poller->pipe_wr);
            close(poller->pipe_rd);
        }
    }

    pthread_mutex_unlock(&poller->mutex);
    return -poller->stopped; // 返回poller线程开启状态
}
```

也就是说，**`poller_thread_routine`是某个线程的执行函数**。而执行该函数的线程，就是事件处理线程。

**那调用`poller_start`的又是谁呢？**

毕竟只有先调用`poller_start`才能通过其内部的`pthread_create`创建事件线程。

## `mpoller_start`

`poller_start`在`mpoller_start`中被调用。

```cpp
/* 创建并开启所有poller线程 */
int mpoller_start(const mpoller_t *mpoller) {
    unsigned int i = 0;
    for (i = 0; i < mpoller->nthreads; ++i) {
        if (poller_start(mpoller->poller[i]) < 0) {         // 重点在这一行
            // 返回值=-1表示创建失败
            break;
        }
    }
    if (i == mpoller->nthreads) {
        // nthreads个线程都开启成功
        return 0;
    }
    // 部分线程开启失败. 停止所有已开启线程
    while (i > 0) { poller_stop(mpoller->poller[--i]); }
    return -1;
}
```

注意，上述代码中是循环调用`poller_start`，也就是说：<mark>创建了不止一个事件处理线程</mark>。

由此可见：`mpoller`的职责，是`start`我们设置的**epoll线程数**的epoll线程

## `create_poller`

而`mpoller_start` 在 `Communicator::create_poller` 的时候启动：

```cpp
// 启动I/O事件处理引擎. 初始化消息队列, mpoller, poller. 开启poller线程
int Communicator::create_poller(const size_t poller_threads) {
    // 默认参数
    const poller_params params = {
        // sysconf(_SC_OPEN_MAX): 获取系统允许单个进程打开的最大文件描述符数量
        .max_open_file = static_cast<size_t>(sysconf(_SC_OPEN_MAX)),
        .call_back = Communicator::callback,
        .context = this
    };

    // 确保有足够的文件描述符可用，否则函数直接返回-1
    if (static_cast<ssize_t>(params.max_open_file) < 0) { 
        return -1; 
    }

    // 创建消息队列
    this->msgqueue = msgqueue_create(16 * 1024, sizeof(poller_result));
    if (this->msgqueue) {
        // 根据poller_threads数量, 创建一个mpoller和指定数量的poller
        this->mpoller = mpoller_create(&params, poller_threads);
        if (this->mpoller) {
            // 开启所有poller线程
            if (mpoller_start(this->mpoller) >= 0) { 
                return 0; 
            }
            mpoller_destroy(this->mpoller); // 销毁
        }
        msgqueue_destroy(this->msgqueue); // 销毁
    }

    return -1;
}
```

## `Communicator::init`

上面的`Communicator::create_poller`又在`Communicator::init`中被调用：

```cpp
int Communicator::init(size_t poller_threads, size_t handler_threads)
{
	....
	create_poller(poller_threads);   // 创建poller线程
	create_handler_threads(handler_threads);  // 创建线程池
	....
}
```

## `CommScheduler`

继续向上追溯，发现`Communicator::init`在`CommScheduler::init`中被调用。

```cpp
class CommScheduler
{
public:
	int init(size_t poller_threads, size_t handler_threads)
	{
		return this->comm.init(poller_threads, handler_threads);
	}

    ...
private:
	Communicator comm;
};
```

而`CommScheduler`仅有一个成员变量`Communicator`, 对于`Communicator`来说就是对外封装了一层, 加入了一些逻辑操作，本质上都是`this->comm`的操作。

如果要说设计模式的话，这应该属于**外观模式**。

## `__CommManager`

`CommScheduler::init`的唯一一次调用在`__CommManager`的构造函数里：

```cpp
private:
    __CommManager() :
        fio_service_(nullptr), fio_flag_(false) {
        const auto *settings = WFGlobal::get_global_settings();
        // 初始化调度器: poller线程处理I/O事件, handler线程处理业务逻辑
        if (scheduler_.init(                        // 重点看这一行
                settings->poller_threads,
                settings->handler_threads) < 0) {
            abort();
        }
        // 忽略SIGPIPE信号: 防止写入已关闭的socket导致进程终止. 确保服务稳定性
        signal(SIGPIPE, SIG_IGN);
    }
```

注意到，**这个构造函数是私有的**，那么很容易就想到**单例模式**了。

```cpp
static __CommManager *get_instance() {
    static __CommManager kInstance;
    __CommManager::created_ = true; // 标记调度器已创建
    return &kInstance;
}
```

可以看到，此处使用的是：

> C++ 11 中的静态局部变量实现的懒汉式单例模式。
> 
> 优点是：
> 
> 1. 只有在第一次调用get_instance()方法时才创建实例，实现延迟加载。
>       `static __CommManager kInstance;`表示`kInstance`是静态局部变量，只在第一次调用`get_instance()`时初始化
> 
> 2. C++11标准保证了静态局部变量的初始化是线程安全的

由此，只要`__CommManager::get_instance`被首次调用，那么就一定有一个`_CommManager`对象被实例化，进而`__CommManager`的构造函数被调用，然后`scheduler_.init`被执行，进而创建`poller`线程。

到这里其实已经到了最外层了，但`__CommManager`实际上属于框架内部类，使用者一般不能直接使用这个类。因此还有一层封装。

## WFGlobal

所有`__CommManager`的使用，都被封装在`WFGlobal`中：

```cpp
bool WFGlobal::is_scheduler_created() {
    return __CommManager::is_created();
}

CommScheduler *WFGlobal::get_scheduler() {
    return __CommManager::get_instance()->get_scheduler();
}

IOService *WFGlobal::get_io_service() {
    return __CommManager::get_instance()->get_io_service(); // 这个后面再说
}
```

以此，我们实现了`__CommManager`的全局单例，也间接实现了`CommScheduler`的全局单例。（因为`CommScheduler`的创建只在`__CommManager`中有）。这样就可以避免执行多次`CommScheduler::init`了
