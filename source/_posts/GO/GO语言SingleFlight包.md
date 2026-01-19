---
title: GO语言SingleFlight包的使用
date: 2026-01-15
updated: 2026-01-16
tags: [GO, 并发]
categories: GO
description: GO语言SingleFlight包的使用
---

### SingleFlight

`singleflight` 包主要是用来做并发控制，常见的比如防止**缓存击穿**。

`singleflight` 包提供了一种“重复函数调用抑制机制”。

换句话说，当多个 goroutine 同时尝试调用同一个函数（基于某个给定的 key）时，`singleflight` 会确保该函数只会被第一个到达的 goroutine 调用，其他 goroutine 会等待这次调用的结果，然后共享这个结果，而不是同时发起多个调用。

一句话概括就是 `singleflight` 将多个请求合并成一个请求，多个请求共享同一个结果。

#### 组成部分

- `Group`：这是 singleflight 包的核心结构体。它管理着所有的请求，确保同一时刻，对同一资源的请求只会被执行一次。Group 对象不需要显式创建，直接声明后即可使用。

- `Do` 方法：Group 结构体提供了 Do 方法，这是实现合并请求的主要方法，该方法接收两个参数：一个是字符串 key（用于标识请求资源），另一个是函数 fn，用来执行实际的任务。在调用 Do 方法时，如果已经有一个相同 key 的请求正在执行，那么 Do 方法会等待这个请求完成并共享结果，否则执行 fn 函数，然后返回结果。

  `Do` 方法有三个返回值，前两个返回值是 fn 函数的返回值，类型分别为 interface{} 和 error，最后一个返回值是一个 bool 类型，表示 Do 方法的返回结果是否被多个调用共享。

- `DoChan`：该方法与 Do 方法类似，但它返回的是一个通道，通道在操作完成时接收到结果。返回值是通道，意味着我们能以非阻塞的方式等待结果。

- `Forget`：该方法用于从 Group 中删除一个 key 以及相关的请求记录，确保下次用同一 key 调用 Do 时，将立即执行新请求，而不是复用之前的结果。

- `Result`：这是 DoChan 方法返回结果时所使用的结构体类型，用于封装请求的结果。这个结构体包含三个字段，具体如下：

  - `Val`（interface{} 类型）：请求返回的结果。
  - `Err`（error 类型）：请求过程中发生的错误信息。
  - `Shared`（bool 类型）：表示这个结果是否被当前请求以外的其他请求共享。

### 使用示例

```go
package main

import (
    "errors"
    "fmt"
    "sync"

    "golang.org/x/sync/singleflight"
)

var errRedisKeyNotFound = errors.New("redis: key not found")

func fetchDataFromCache() (any, error) {
    fmt.Println("fetch data from cache")
    return nil, errRedisKeyNotFound
}

func fetchDataFromDataBase() (any, error) {
    fmt.Println("fetch data from database")
    return "value", nil
}

func fetchData() (any, error) {
    cache, err := fetchDataFromCache()
    if err != nil && errors.Is(err, errRedisKeyNotFound) {
        fmt.Println(errRedisKeyNotFound.Error())
        return fetchDataFromDataBase()
    }
    return cache, err
}

func main() {
    var (
        sg singleflight.Group
        wg sync.WaitGroup
    )

    for _ range 7 {
        wg.Add(1)

        go func() {
            defer wg.Done()

            v, err, shared := sg.Do("key", fetchData)
            if err != nil {
                panic(err)
            }
            fmt.Printf("v: %v, shared: %v\n", v, shared)
        }()
    }
    wg.Wait()
}
```

这段代码模拟了一个典型的并发访问场景：从缓存获取数据，若缓存未命中，则从数据库检索。在此过程中，singleflight 库起到了至关重要的作用。它确保在多个并发请求尝试同时获取相同数据时，实际的获取操作（不论是访问缓存还是查询数据库）只会执行一次。这样不仅减轻了数据库的压力，还有效防止了高并发环境下可能发生的缓存击穿问题。

### 参考文章

[[Go] 防缓存击穿利器 singleflight](https://piaohua.github.io/post/golang/20240324-singleflight/).