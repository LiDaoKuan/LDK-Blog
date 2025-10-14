---
title: epoll的LT模式和ET模式
date: 2025-08-10
tags: [epoll, socket]
categories: 网络编程
---

### epoll

epoll是Linux特有的IO复用函数，关于epoll的原理，参见：[Linux的IO多路复用](../Linux的IO多路复用)

### LT模式

`epoll`的默认模式，这种情况下`epoll`相当于一个效率较高的`poll`。

对于采用`LT`工作模式的文件描述符，当`epoll_wait`检测到其上有事件发生并且将此事件通知给应用程序后，应用程序还可以<mark>不立即</mark>处理该事件。这样，当应用程序下一次调用`epoll_wait`时，`epoll_wait`还会再次通知应用程序，直到该事件被处理。

### ET模式

当往`epoll内核事件表`中注册一个文件描述符上的`EPOLLET`事件时，`epoll`将以`ET`模式来操作该文件描述符。`ET`模式是`epoll`的高效工作模式。

对于采用`ET`模式的文件描述符，当`epoll_wait`检测到其上有事件发生并将此事件通知给应用程序后，应用程序必须立即处理该事件，因为后续的`epoll_wait`调用将不再向应用程序通知这一事件。

> 拿读取事件来举例：
> `LT`模式是：只要该文件描述符上有数据可读，就通知应用程序
> `ET`模式是：只在<mark>原来没有数据可读，现在到来了新的数据</mark>时，通知应用程序。如果应用程序没有将此次的数据读完，下次epoll_wait将不会通知应用程序。

可见，`ET`模式和大程度上降低了同一个`epoll`事件被重复触发的次数。但是使用`ET`模式需要确保读写完整数据包，否则会导致数据丢失

### 具体实现

```cpp
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <assert.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/epoll.h>
#include <pthread.h>
#include <libgen.h>

#define MAX_EVENT_NUMBER 1024
#define BUFFER_SIZE 10

/**
 * @brief 将文件描述符设置为非阻塞的
 */
int setnonblocking(int fd) {
    int old_option = fcntl(fd, F_GETFL); // 读取当前文件状态标志
    int new_option = old_option | O_NONBLOCK; // 设置非阻塞
    fcntl(fd, F_SETFL, old_option); // 写入新的文件状态标志
    return old_option;
}

/**
 * @brief 注册EPOLLIN事件到epoll内核事件表
 * @param epollfd 内核事件表对应的文件描述符
 * @param fd 要注册EPOLLIN的文件描述符
 * @param enable_et 是否对fd启用ET模式
 */
void addfd(int epollfd, int fd, bool enable_et) {
    epoll_event event;
    event.data.fd = fd;
    event.events = EPOLLIN;
    if (enable_et) {
        event.events |= EPOLLET; // 通过按位或，增加EPOLLET属性
    }
    // 注意此处的event作为一个局部变量竟然传入了地址（使用epoll_ctl该参数是指针），
    // 推测是因为传指针可以避免拷贝，速度更快
    epoll_ctl(epollfd, EPOLL_CTL_ADD, fd, &event);
    setnonblocking(fd); // 设置文件描述符为非阻塞
}

/**
 * @brief LT模式工作流程
 * @param events 已经就绪的事件的数组
 * @param number 已就绪事件的数量
 * @param epollfd 内核事件表的文件描述符
 * @param listenfd 要处理的事件
 */
void LT(epoll_event *events, int number, int epollfd, int listenfd) {
    char buf[BUFFER_SIZE];
    // 用循环遍历所有已经就绪的事件的列表(events)
    for (int i = 0; i < number; ++i) {
        int sockfd = events[i].data.fd; // 通常不用event.data的fd成员
        if (sockfd == listenfd) { // 连接未受理。执行accept进行受理。注意此处可以用==判断相等！
            sockaddr_in client_address;
            socklen_t client_addrlength = sizeof(client_address);
            // 受理连接。注意accept的后两个参数都需要取地址
            int connfd = accept(listenfd, (struct sockaddr *)&client_address, &client_addrlength);
            // 将受理后的连接加入内核事件表，监听后续客户端的消息
            addfd(epollfd, connfd, false); // 对connfd禁用ET模式
        } else if (events[i].events & EPOLLIN) { // 连接已经受理并且有数据可读（数据未被全部读出）
            // 只要socket读缓存中还有未读出的数据，这段代码就会触发
            printf("enevt trigger once\n");
            memset(buf, '\0', BUFFER_SIZE);
            // 读出数据。注意recv的第三个参数是 BUFFERE_SIZE - 1。不是BUFFER_SIZE
            int ret = recv(sockfd, buf, BUFFER_SIZE - 1, 0);
            if (ret < 0) {
                close(sockfd);
                continue;
            }
            printf("get %d bytes of content: %s\n", ret, buf);
        } else {
            printf("something else happened \n");
        }
    }
}

/**
 * @brief ET模式工作流程
 * @param
 */
void ET(epoll_event *events, int number, int epollfd, int listenfd) {
    char buf[BUFFER_SIZE];
    for (int i = 0; i < number; ++i) {
        int sockfd = events[i].data.fd;
        if (sockfd == listenfd) { // 未受理的连接。调用accept受理该连接
            sockaddr_in client_address;
            socklen_t client_addrlength = sizeof(client_address);
            int connfd = accept(listenfd, (sockaddr *)&client_address, &client_addrlength);
            addfd(epollfd, connfd, true); // 对connfd开启ET模式
        } else if (events[i].events & EPOLLIN) {
            printf("event trigger once\n");
            /**
             * else if 中的这段代码不会被重复触发，所以我们循环读取数据，以确保把socket读缓存中的所有数据读出
             */
            while (1) {
                memset(buf, '\0', BUFFER_SIZE);
                // 读出数据
                int ret = recv(sockfd, buf, BUFFER_SIZE - 1, 0);
                if (ret < 0) {
                    /**
                     * 对于非阻塞IO，下面的条件成立则表示数据已经被全部读取完毕。
                     * 此后epoll就能再次触发sockfd上的EPOLLIN事件，以驱动下一次读操作
                     */
                    if ((errno == EAGAIN) || (errno == EWOULDBLOCK)) {
                        printf("read later\n");
                        break;
                    }
                    close(sockfd);
                    break;
                } else if (ret == 0) {
                    close(sockfd);
                } else {
                    /* 数据处理 */
                    printf("get %d bytes of content: %s\n", ret, buf);
                }
            }
        } else {
            printf("something else happened \n");
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc <= 2) {
        // 参数不够
        printf("usage: %s ip_address port_number\n", basename(argv[0]));
        return 1;
    }
    const char *ip = argv[1];
    int port = atoi(argv[2]);

    int ret = 0;
    sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    inet_pton(AF_INET, ip, &address.sin_addr); // 将标准文本表示形式的IPv4或IPv6地址转换为网络字节序
    address.sin_port = htons(port); // 将主机字节序(host)的port转换为网络字节序(net)

    int listenfd = socket(PF_INET, SOCK_STREAM, 0); // 创建socket
    assert(listenfd >= 0);

    // bind函数的第二个参数可以直接强转
    ret = bind(listenfd, (struct sockaddr *)&address, sizeof(address));
    assert(ret != -1);

    ret = listen(listenfd, 5);
    assert(ret != -1);

    epoll_event events[MAX_EVENT_NUMBER];
    int epollfd = epoll_create(5); // 创建内核事件表
    assert(epollfd != -1); // 确保创建成功
    addfd(epollfd, listenfd, true); // 添加socket文件描述符到内核事件表。注意此处是开启ET模式的！

    while (1) {
        // 第三个参数为-1, 则epoll_wait将永远阻塞，直到某个事件发生
        int ret = epoll_wait(epollfd, events, MAX_EVENT_NUMBER, -1);
        if (ret < 0) {
            printf("epoll failure\n");
            break;
        }

        LT(events, ret, epollfd, listenfd); // 使用LT模式
        // ET(events, ret, epollfd, listenfd); // 使用ET模式
    }

    close(listenfd);
    return 0;
}

```

