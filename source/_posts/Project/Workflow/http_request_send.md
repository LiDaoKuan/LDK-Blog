---
title: workflow源码分析——http请求-02
date: 2026-02-19
updated: 2026-02-20
tags: [sogo workflow, C++, project]
categories: sogo workflow
description: workflow源码分析——http请求发送
---

阅读本文章前，请先阅读：[workflow源码分析——http请求-01](./http_request_create.md).

## 从`Communicator::request`继续

```cpp
// 发起请求(客户端专用)
int Communicator::request(CommSession *session, CommTarget *target) {
    if (session->passive) {
        // 服务端被动接收的连接, 不应该调用此函数, 设置错误码并且返回-1
        errno = EINVAL;
        return -1;
    }
    const int errno_bak = errno;
    session->target = target; // 关联会话和连接目标
    session->msg_out = nullptr;
    session->msg_in = nullptr;
    // 尝试复用空闲连接
    if (this->request_idle_conn(session, target) < 0) {
        // 没有空闲连接可以复用, 新建连接(异步)
        if (this->request_new_conn(session, target) < 0) {
            // 新建连接失败, 清空conn和seq, 防止无效的上下文传播到后续流程
            session->conn = nullptr;
            session->seq = 0;
            return -1;
        }
    }
    // 请求发起成功, 恢复原来的错误码
    errno = errno_bak;
    return 0;
}
```


