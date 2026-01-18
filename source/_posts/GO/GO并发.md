---
title: GO基础语法
date: 2026-01-12
updated: 2026-01-13
tags: [GO, 并发]
categories: GO
description: GO语言并发
---

### GO语言并发

#### 基本并发知识

##### 并发和并行

- 并发：并发主要由切换时间片来实现**宏观上**的"同时"运行
- 并行：并行是直接**利用多核实现**多线程的运行，go可以设置使用核数，以发挥多核计算机的能力

##### 进程和线程

- **资源分配和调度**：
  - 进程是程序在操作系统中的一次执行过程，**系统进行资源分配的一个独立单位**。线程是进程的一个执行实体, 是CPU调度的基本单位,它是比进程更小的能独立运行的基本单位。
  - 进程拥有独立的内存空间，同一个进程内部的多个线程共享进程的内存和资源。
- **开销**：进程切换需要保存和恢复整个内存状态，开销较大；线程切换只需保存和恢复少量寄存器，开销较小。
- **独立性**：进程之间互不影响，一个进程崩溃不会影响其他进程；线程共享进程资源，一个线程崩溃可能导致整个进程终止。
- **通信方式**：进程间通信需要使用管道、消息队列、共享内存等机制；线程间可以直接通过共享内存进行通信，但需要同步机制保证数据一致性。

##### 线程和协程

协程是一种**用户态的轻量级线程**，由程序自身控制调度，无需操作系统介入。它通过**协作式多任务**实现并发，适用于高并发和异步I/O场景。线程则是**内核态的执行单元**，由操作系统调度。

- **调度方式**：协程采用用户态协作式调度，线程采用内核态抢占式调度。
- **切换开销**：协程切换开销极低（通常小于1微秒），线程切换开销较高。
- **并发数量**：单线程可管理数万个协程，而线程数量受限于内核资源（通常为数百个）。
- **使用场景**：协程适合I/O密集型和高并发服务，线程适合CPU密集型和多核并行任务。

#### goroutine

`goroutine`其实就是一个超级大的线程池，或者说**协程池**。Go语言中使用`goroutine`非常简单，只需要在调用函数的时候在前面加上go关键字，就可以为一个函数创建一个`goroutine`。

一个`goroutine`必定对应一个函数，可以创建多个`goroutine`去执行相同的函数。

一个简单的例子：

```go
var wg sync.WaitGroup

func hello(i int) {
    defer wg.Done() // goroutine结束就登记-1
    fmt.Println("Hello Goroutine!", i)
}

func main() {
    for i := 0; i < 10; i++ {
        wg.Add(1) // 启动一个goroutine就登记+1
        go hello(i)
    }
    wg.Wait() // 等待所有登记的goroutine都结束
}
```

##### 注意

- 如果主协程退出了，其他任务还执行吗？

  不会。

- 如果某个协程创建了一个子协程，那么这个协程退出后，其子协程还会执行吗？

#### runtime包

##### `runtime.Gosched()`

让出CPU时间片。将当前goroutine放回等待队列中，重新等待安排任务。

```go
package main

import (
	"fmt"
	"runtime"
)

func main() {
	go func(s string) {
		for i := 0; i < 10000; i++ {
			fmt.Println(s)
		}
	}("world")
	// 主协程
	for i := 0; i < 2; i++ {
		// 切一下，再次分配任务
		runtime.Gosched()
		fmt.Println("hello")
	}
}
```

##### `runtime.Goexit()`

`Goexit()` 函数用于终止当前Goroutine ，让当前 Goroutine 正常退出，但不影响其他 Goroutine 的运行。使用 `Goexit()` 函数时，可以在 Goroutine 内部调用，强制终止当前 Goroutine 的执行。

```go
package main

import (
	"fmt"
	"runtime"
	"time"
)

func Test() {
	fmt.Println("hello world")
}

func main() {
	go func() {
		defer fmt.Println("sub routine exited")
		defer fmt.Println("A.defer")
		func() {

			defer fmt.Println("B.defer")
			// 结束协程
			runtime.Goexit()
			defer fmt.Println("C.defer")
			fmt.Println("B")
		}()
		fmt.Println("A")
	}()
	for {
		fmt.Println("main routine")
		time.Sleep(time.Second * 2)
	}
}
```

##### `runtime.GOMAXPROCS`

Go语言中可以通过`runtime.GOMAXPROCS()`函数设置当前程序并发时占用的CPU逻辑核心数，本质上`runtime.GOMAXPROCS()`控制的是GPM模型中的P的数量。

```go
func a() {
    for i := 1; i < 10; i++ {
        fmt.Println("A:", i)
    }
}

func b() {
    for i := 1; i < 10; i++ {
        fmt.Println("B:", i)
    }
}

func main() {
    runtime.GOMAXPROCS(1) // 设置只使用一个逻辑核心数。此时程序会顺序执行。
    go a()
    go b()
    time.Sleep(time.Second)
}
```

将逻辑核心数改为2，程序会并行执行

```go
func a() {
    for i := 1; i < 10; i++ {
        fmt.Println("A:", i)
    }
}

func b() {
    for i := 1; i < 10; i++ {
        fmt.Println("B:", i)
    }
}

func main() {
    runtime.GOMAXPROCS(2)
    go a()
    go b()
    time.Sleep(time.Second)
}
```

#### channel

GO语言提倡通过channel通信实现共享内存而不是通过共享内存实现通信。遵循先入先出（First In First Out）的规则，保证收发数据的顺序。每一个通道都是一个具体类型的导管，也就是声明channel的时候需要为其指定元素类型。

Channel和select的搭配使用以及调度器对goroutine的调度，可以高效实现协程的阻塞和唤醒及多路复用。关于select的使用在后面。

##### 基本使用

channel是一种引用类型，**声明**channel的举例：

```go
var chanInt chan int; // 声明一个传递int的通道
var chanBool chan bool; // 声明一个传递bool的通道
var chanIntSlice chan []int // 声明一个传递int切片的通道

fmt.println("chanInt: ", chanInt) // 只是声明，并没有初始化，所以是<nil>
```

###### 创建channel

```go
chanInt := make(chan int, 10) // 创建一个传递 int 的通道，缓冲区大小为10
chanBool := make(chan bool) // 创建一个无缓冲（阻塞式）的channel
```

###### channel的操作

channel有发送、接受、关闭（close）三种操作

```go
chInt := make(chan int) // 无缓冲channel
chInt <- 10 // 把int发送到chInt中
x := <- chInt // 从ch中接受值并且赋值给变量x
<-chInt // 从chInt中取出值，忽略结果
```

上述代码不能直接执行，会报错：
```go
package main

import "fmt"

func main() {
	chInt := make(chan int) // 无缓冲
	chInt <- 10             // 把 int 发送到 chInt 中. 此处会报错，因为主协程会阻塞，而有没有其他协程存在能够生产消息数据
	x := <-chInt            // 从 chInt 中接受值并且赋值给变量 x
	fmt.Println(x)
}
```

报错：

```shell
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan receive]:
main.main()
	/home/ldk/GolandProjects/GoTest/main.go:8 +0x2f
```

##### channel的分类

- 无缓冲channel

  - 当发送方执行 ch <- val 发送数据时，它会一直阻塞，直到有另一个 goroutine 执行<-ch 来接收数据。
  - 反之，如果接收方先执行<-ch获取数据，它也会等待，直到发送方准备好数据。

  无缓冲 Channel的行为类似于一种“同步握手”机制。这种严格的同步特性使得无缓冲 Channel 非常适合用于精确协调 goroutine 的执行顺序，例如确保某个任务完成后才允许后续操作继续执行。

  > 无缓冲channel必须先启动接收方。否则发送方发送时会阻塞，如果此时接收方未启动，程序将死锁。

- 有缓冲channel

  - 发送方在缓冲区未满时立即发送，而不必等待接收方。只有当缓冲区填满后，发送操作才会阻塞。
  - 接收方在缓冲区为空时会等待，否则直接从缓冲区读取数据。

  **有缓冲的 Channel 底层使用环形队列**。因为存在缓冲区，更适合处理突发流量或解耦生产者和消费者的执行速度，从而提高整体吞吐量。

###### channel的使用案例

无缓冲channel：

```go
package main

import "fmt"

func main() {
	ch := make(chan int) // 创建无缓冲 Channel
	go func() {
		ch <- 42 // 发送数据会阻塞，直到有接收者
		fmt.Println("send message: ", 42)
	}()
	value := <-ch // 接收数据
	fmt.Println("get value: ", value)
}
```

有缓冲channel：

```go
package main

import (
	"fmt"
)

func main() {
	ch := make(chan int, 3) // 创建有缓冲Channel，缓冲区大小为3

	go func() {
		for i := 0; i < 7; i++ {
			ch <- i // 发送数据，前3次不会阻塞
			fmt.Println("Sent:", i)
		}
		close(ch) // 关闭 Channel
	}()

	for value := range ch { // 接收数据，直到Channel关闭
		fmt.Println("Received:", value)
	}
}

```

#### select语句

类似与switch语句，专门用于操作channel，它会一直等待某个channel操作准备就绪，然后执行相应的case分支。**如果多个case同时准备就绪，则会<mark>随机</mark>选择一个分支执行**。为什么随机呢？因为如果每一次都按照顺序执行，则会导致每次都只执行第一个，造成其他case语句饥饿。

##### 基本示例：

```go
package main

import (
	"fmt"
)

func main() {
	chanStr1 := make(chan string)
	chanStr2 := make(chan string)

	go func() {
		for i := 0; i < 10; i++ {
			chanStr1 <- fmt.Sprintf("%d from func1", i)
		}
		close(chanStr1)
	}()

	go func() {
		for i := 0; i < 10; i++ {
			chanStr2 <- fmt.Sprintf("%d from func2", i)
		}
		close(chanStr2)
	}()

	for {
		select {
		case str1, ok := <-chanStr1: // 如果 chanStr1 已经关闭, 则 ok 为 false
			if !ok {
				close(chanStr2)
				return
			}
			fmt.Println("received: ", str1)
		case str2, ok := <-chanStr2:
			if !ok {
				close(chanStr1)
				return
			}
			fmt.Println("received: ", str2)
		}
	}
}
```

上述程序只能打印20条消息的10条，因为selece语句每次只能随机二选一。

##### 空select

空 `select` 是指没有任何 case 分支的 `select` 语句。这种写法会造成 goroutine **永远**阻塞，常用于阻塞主 goroutine 以防止程序退出。

```go
package main

func main() {
    // 空 select 阻塞程序，防止退出
    select {}
}
```

##### 只有一个case分支的select

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    ch := make(chan string)

    go func() {
        time.Sleep( 1 * time.Second )
        ch <- "单一 case 的消息"
    }()

    // 只有一个 case 的 select
    select {
    case msg := <- ch:
        fmt.Println( "收到：" , msg )
    }
}
```

##### 含有default分支的select

在select语句中加入default分支，用于在没有任何channel就绪时执默认操作。**这样可以避免阻塞**。适用于需要非阻塞处理的场景。

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    ch := make(chan string)

    // 使用 default 分支的 select
    select {
    case msg := <- ch:
        fmt.Println( "收到：" , msg )
    default:
        fmt.Println( "没有数据，执行默认操作" )
    }

    // 模拟延时后数据进入 channel
    go func() {
        time.Sleep( 1 * time.Second )
        ch <- "延时后消息"
    }()

    time.Sleep( 2 * time.Second )
}
```

##### 超时控制

```go
select {
case <-ch:
    // 对应操作...
case <-time.After(3 * time.Second):
    fmt.Println("操作超时")
}
```

`time.After`是Go标准库`time`包中的一个函数，它返回一个**Channel**，该Channel会在指定时间后发送一个时间值。

- 如果`ch`在3秒内有数据，`case <-ch:`先执行
- 如果`ch`在3秒内没有数据，`case <-time.After(3 * time.Second):`先执行
