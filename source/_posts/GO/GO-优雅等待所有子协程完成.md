---
title: GO-优雅等待所有子协程结束
date: 2026-01-14
updated: 2026-01-15
tags: [GO, 并发]
categories: GO
description: GO语言等待子协程结束
---

### 为什么要等待子协程结束

可能是因为`cpp`写多了(bushi。众所周知，在`cpp`中，有`thread.join()`可以等待线程结束。但是`GO`中的协程没有这类API，所以就有了这个问题。主要平时写demo程序时，总是需要等待子协程结束才能完成看出来协程的调度顺序。不然就会出现下面这种情况：

```go
package main

import (
	"fmt"
)

func main(){
    go sayHi(){
        fmt.Println("say hello......")
    }()
    fmt.Println("main groutine....")
}
```

上面程序的输出只有：

```sjell
main groutine....
```

很简单，main协程跑太快了，子协程还没来得及Print，main协程就已经结束了，子协程也跟着结束了。

下面就是正文：如何让子协程顺利执行完。

### 通道channel

声明一个和子协程数量一致的通道数组，然后为每个子协程分配一个通道元素，在子协程执行完毕时向对应的通道发送数据；然后在主协程中，依次读取这些通道接收子协程发送的数据，只有所有通道都接收到数据才会退出主协程。

```go
package main

import "fmt"

func add(i int, j int, ch chan int) {
	ch <- i + j
	fmt.Println("add", i, j)
}

func main() {
	chs := make([]chan int, 10)
	for i := 0; i < 10; i++ {
		chs[i] = make(chan int)
		go add(1, i, chs[i])
	}
	for _, ch := range chs {
		<-ch
	}

	fmt.Println("All goroutines finished")
}

```

### WaitGroup

```go
package main

import (
    "fmt"
    "sync"
)

func add_num(a, b int, done func()) {
    defer done() // 执行回调, 实际上是wg.Done(), 表示结束了一个子协程
    c := a + b
    fmt.Printf("%d + %d = %d\n", a, b, c)
}

func main() {
    var wg sync.WaitGroup
    for i := 0; i < 10; i++ {
        wg.Add(1) // 标记增加了一个子协程
        go add_num(i, 1, wg.Done)
    }
    wg.Wait()
}
```

