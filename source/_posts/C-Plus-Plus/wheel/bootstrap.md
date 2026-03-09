---
title: C++ 使用bootstrap进程管理服务器进程
date: 2026-02-22
updated: 2026-02-22
tags: [轮子, C++， bootstrap]
categories: 轮子
description: C++ 使用bootstrap管理服务器进程
---

#### bootstrap进程

```cpp
// main.cpp
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <signal.h>

// 全局标志位：0=正常运行, 1=重启信号, 2=停止信号
int flag = 0;

// 信号处理函数
void sig_handler(int signo) {
    if (signo == SIGUSR1) {
        printf("pid: %d received SIGUSR1 signal\n", getpid());
        flag = 1; // 重启信号
    } else if (signo == SIGINT || signo == SIGTERM) {
        printf("pid: %d received SIGINT or SIGTERM signal\n", getpid());
        flag = 2; // 停止信号
    }
}

int main(int argc, const char *argv[]) {
    // 参数校验：必须提供服务器程序路径和端口号
    if (argc != 3) {
        fprintf(stderr, "USAGE: %s EXEC_PROCESS PORT\n"
                "Bootstrap for workflow server to restart gracefully.\n",
                argv[0]);
        exit(1);
    }

    // 解析端口号
    const unsigned short port = strtol(argv[2], nullptr, 10);
    // 创建TCP监听套接字
    const int listen_fd = socket(AF_INET, SOCK_STREAM, 0);

    // 配置套接字地址结构
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_port = htons(port);              // 转换为网络字节序
    sin.sin_addr.s_addr = htonl(INADDR_ANY); // 监听所有ip

    // 绑定套接字到制定端口
    if (bind(listen_fd, (struct sockaddr *)&sin, sizeof sin) < 0) {
        close(listen_fd);
        perror("bind error");
        exit(1);
    }

    pid_t pid;
    int pipe_fd[2]; // 管道文件描述符. [0]=读端, [1]=写入端
    ssize_t len;
    char buf[100]; // 读取管道数据缓冲区
    int status;    // 子进程退出状态
    int ret;       // waitpid返回值

    char listen_fd_str[10] = {0}; // 存储转换为字符串后的监听套接字
    char write_fd_str[10] = {0};  // 存储转换为字符串后的管道写端文件描述符

    // 将套接字转换为字符串，用于传递给子进程
    sprintf(listen_fd_str, "%d", listen_fd);

    // 注册信号处理函数
    signal(SIGINT, sig_handler);
    signal(SIGTERM, sig_handler);
    signal(SIGUSR1, sig_handler);

    // 主循环：持续管理服务器进程
    while (flag < 2) {
        // 创建管道用于子进程通信
        if (pipe(pipe_fd) == -1) {
            perror("open pipe error");
            exit(1);
        }

        // 管道写端文件描述符转换为字符串
        memset(write_fd_str, 0, sizeof write_fd_str);
        sprintf(write_fd_str, "%d", pipe_fd[1]);

        // 创建子进程（服务器进程）
        pid = fork();
        if (pid < 0) {
            perror("fork error");
            close(pipe_fd[0]);
            close(pipe_fd[1]);
            break; // fork失败，退出
        }
        // 子进程（服务器进程）
        else if (pid == 0) {
            close(pipe_fd[0]); // 子进程关闭管道读取端
            // 执行服务器程序，传递监听套接字和管道写端
            execlp(argv[1], argv[1], listen_fd_str, write_fd_str, NULL);

            // execlp失败
            perror("execlp error");
            exit(1);
        }
        // 父进程（bootstrap）
        else {
            close(pipe_fd[1]); // 父进程关闭管道写端

            // 初始化状态
            status = 0;
            ret = 0;
            flag = 0; // 重置标志位
            // 输出运行信息
            fprintf(stderr, "Bootstrap daemon running with server pid-%d. "
                    "Send SIGUSR1 to RESTART or SIGTERM to STOP.\n", pid);

            // 等待子进程（服务器进程）退出
            while (1) {
                ret = waitpid(pid, &status, WNOHANG); // 非阻塞等待
                // 退出条件：
                // 1. waitpid错误
                // 2. 子进程未正常退出
                // 3. 收到信号
                if (ret == -1 || !WIFEXITED(status) || flag != 0) {
                    break;
                }
                // 每3秒检查一次
                sleep(3);
            }

            // 处理子进程退出（对比while循环中的if）
            if (ret != -1 && WIFEXITED(status)) {
                // 忽略子进程退出信号（避免僵尸进程）
                signal(SIGCHLD, SIG_IGN);
                // 发送SIGUSR1给子进程，使其终止（正常退出）
                kill(pid, SIGUSR1);
                fprintf(stderr, "Bootstrap daemon SIGUSR1 to pid-%ld %sing.\n", (long)pid, flag == 1 ? "restart" : "stop");

                // 读取子进程写入的管道数据（用于确认关闭状态）
                len = read(pipe_fd[0], buf, 7);
                fprintf(stderr, "Bootstrap server served %*s.\n", (int)len, buf);
            }
            // 子进程异常终止
            else {
                fprintf(stderr, "child exit. status = %d, waitpid ret = %d\n", WEXITSTATUS(status), ret);
                flag = 2; // 设置停止标志
            }

            close(pipe_fd[0]);
        }
    }

    close(listen_fd);
    return 0;
}
```

#### server进程

```cpp
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include "WFFacilities.h"
#include "WFHttpServer.h"

static WFFacilities::WaitGroup wait_group(1);

void sig_handler(int signo) {
    wait_group.done();
}

int main(int argc, const char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "USAGE: %s listen_fd pipe_fd\n", argv[0]);
        exit(1);
    }

    int listen_fd = atoi(argv[1]);
    int pipe_fd = atoi(argv[2]);

    signal(SIGUSR1, sig_handler);

    WFHttpServer server([](WFHttpTask *task) {
        task->get_resp()->append_output_body("<html>Hello World!</html>");
    });

    if (server.serve(listen_fd) == 0) {
        printf("pid: %d server started\n", getpid());
        wait_group.wait();
        server.shutdown();
        write(pipe_fd, "success", strlen("success"));
        server.wait_finish();
    } else {
        write(pipe_fd, "failed ", strlen("failed "));
    }

    close(pipe_fd);
    close(listen_fd);
    return 0;
}
```

#### 运行情况

在项目根目录，运行命令：

```shell
./main ./server 8080
```

另起一个终端，查询8080端口：

```shell
ps -ef | grep 8080
```

输出：

```shell
ldk@bogon:~/Documents/code$ ps -ef | grep 8080
ldk       194106  108766  0 16:13 pts/0    00:00:00 ./main ./server 8080
ldk       194469  194269  0 16:13 pts/3    00:00:00 grep --color=auto 8080
```

主线程的 pid 为 194160

向主线程发送：`SIGUSR1` 信号

```shell
kill -USR1 194106
```

回到主程序所在终端，查看输出：

```shell
ldk@fedora:~/Documents/code$ ./main ./server 8080
Bootstrap daemon running with server pid-194107. Send SIGUSR1 to RESTART or SIGTERM to STOP.
pid: 194107 server started
pid: 194106 received SIGUSR1 signal
Bootstrap daemon SIGUSR1 to pid-194107 restarting.
Bootstrap server served success.
Bootstrap daemon running with server pid-195967. Send SIGUSR1 to RESTART or SIGTERM to STOP.
pid: 195967 server started
```

#### 局限性

这样实现的bootstrap进程还是存在瑕疵，比如没办法实现服务器程序的热更新：必须停止服务器进程才能对服务器程序进行更新。但是基本框架就是这样，如果要实现热更新，需要使用类似运行时加载动态库的方式，具体方法后面再补吧，感兴趣可以自行百度。
