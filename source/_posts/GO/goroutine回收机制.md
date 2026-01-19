---
title: goroutine的回收机制
date: 2026-01-13
updated: 2026-01-14
tags: [GO, 并发]
categories: GO
description: goroutine回收机制
---

### goroutine的回收机制

goroutine的回收是自动进行的，但是有前提条件：

1. **自然退出**：goroutine运行的函数return之后，goroutine状态变为dead。
2. **释放资源**：
   - 栈内存归还runtime内存管理器
   - 对应的G对象可能被放入缓存池以便复用
3. **垃圾回收（GC）清理**：当 dead goroutine 没有任何引用时，会在 GC 中彻底释放内存。

> **如果goroutine一直被阻塞或者被引用，它将无法回收，造成资源泄漏（goroutine leak）**.

例如：

```go
func leakyFunction() {
    ch := make(chan int)
    
    go func() {
        val := <-ch  // 这个goroutine会一直等待数据，但没人会发送
        fmt.Println(val)
    }()
    
    // 函数返回，但上面的goroutine还在运行
    // 没有代码会往ch发送数据，所以这个goroutine永远不会结束
}
```

上述代码中的goroutine因为等不到数据，一直阻塞无法结束，也就无法被GC回收。

### 如何避免goroutine泄漏

#### 使用context控制goroutine生命周期

```go
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	defer fmt.Println("main exit")

	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		defer fmt.Println("cancelled")
		for {
			select {
			case <-ctx.Done():
				fmt.Println("goroutine exit")
				return
			default:
				// 执行业务逻辑
				fmt.Println("do something else")
			}
		}
	}()

	// 便于调试，否则主goroutine执行太快导致子goroutine没有机会执行default分支
	// 也避免了主协程执行太快导致子协程来不及输出
	time.Sleep(time.Millisecond)

	// 触发退出
	cancel()
}

```

#### 用waitgroup等待goroutine完成

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		fmt.Println("task done")
	}()
	wg.Wait()
	fmt.Println("main done")
}

```

#### 用workpool复用goroutine

极简workpool：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	jobs := make(chan int, 100)
    // 连续创建5个协程，每个协程都处理channel中的数据
	for w := 0; w < 5; w++ {
		go func(id int) {
			for j := range jobs {
				fmt.Printf("worker %d processing job %d\n", id, j)
			}
		}(w)
	}
	for i := 0; i < 10; i++ {
		jobs <- i
	}
	close(jobs)
	time.Sleep(time.Second) // 方便查看输出, 避免main协程过快结束
}

```

