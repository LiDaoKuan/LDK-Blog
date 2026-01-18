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

### 通道



### WaitGroup类型