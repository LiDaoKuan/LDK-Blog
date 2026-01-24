---
title: GO语言sync包的使用
date: 2026-01-15
updated: 2026-01-16
tags: [GO, 并发]
categories: GO
description: GO语言sync包的使用
---

#### sync.Mutex

互斥锁。`sync.Mutex`在使用的时候要注意：**对一个未锁定的互斥锁解锁将会产生运行时错误**。

使用示例：

```go
package main

import (
	"fmt"
	"sync"
)

var (
	num int
	wg  = sync.WaitGroup{}
	// 我们用锁来保证 num 的并发安全
	mutex = sync.Mutex{}
)

func add() {
	defer wg.Done()
	mutex.Lock()
	num += 1
	mutex.Unlock()
}

func main() {
	var n = 10 * 10 * 10 * 10
	wg.Add(n)

	for i := 0; i < n; i++ {
		// 启动 n 个 goroutine 去累加 num
		go add()
	}

	// 等待所有 goroutine 执行完毕
	wg.Wait()

	fmt.Println(num == n)
}

```

#### sync.RWMutex

读写锁。就是将读操作和写操作分开，可以分别对读和写进行加锁，一般用在大量读操作、少量写操作的情况。

读写锁可以执行的操作：

```go
func (rw *RWMutex) Lock()     // 对写锁加锁
func (rw *RWMutex) Unlock()   // 对写锁解锁

func (rw *RWMutex) RLock()    // 对读锁加锁
func (rw *RWMutex) RUnlock()  // 对读锁解锁
```

读写锁的特性：

1. 同时只能有一个 goroutine 能够获得写锁定。
2. 同时可以有任意多个 gorouinte 获得读锁定。
3. 同时只能存在写锁定或读锁定（读和写互斥）。

通俗理解就是**可以有多个`goroutine`同时读，也可以有一个`goroutine`写入，但是读取和写入不能同时进行**。

读写锁使用示例：

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

var cnt = 0

func read(rwMutex *sync.RWMutex, i int) {
	fmt.Printf("goroutine %d reader start\n", i)

	rwMutex.RLock()
	fmt.Printf("goroutine %d reading count:%d\n", i, cnt)
	time.Sleep(time.Millisecond)
	rwMutex.RUnlock()

	fmt.Printf("goroutine %d reader over\n", i)
}

func write(rwMutex *sync.RWMutex, i int) {
	fmt.Printf("goroutine %d writer start\n", i)

	rwMutex.Lock()
	cnt++
	fmt.Printf("goroutine %d writing count:%d\n", i, cnt)
	time.Sleep(time.Millisecond)
	rwMutex.Unlock()

	fmt.Printf("goroutine %d writer over\n", i)
}

func main() {
	var rwMutex sync.RWMutex

	// 三个写入 routine
	for i := 1; i <= 3; i++ {
		go write(&rwMutex, i)
	}

	// 三个读取 routine
	for i := 1; i <= 3; i++ {
		go read(&rwMutex, i)
	}

	time.Sleep(time.Second) // 等待子 routine 执行完毕
	fmt.Println("final count:", cnt)
}

```

#### sync.WaitGroup

主要用于实现并发任务的同步，比如等待某些任务结束后再开始操作。

主要方法：

|              方法名               | 功能                |
| :-------------------------------: | ------------------- |
| `(wg * WaitGroup) Add(delta int)` | 计数器+delta        |
|     `(wg *WaitGroup) Done()`      | 计数器-1            |
|     `(wg *WaitGroup) Wait()`      | 阻塞直到计数器变为0 |

sync.WaitGroup内部维护着一个计数器。调用Wait方法时会阻塞直到计数器归0。

使用示例：

```go
package main

import (
	"fmt"
	"sync"
)

func hello(group *sync.WaitGroup, i int) {
	defer group.Done() // 标记协程执行完成
	fmt.Println("Hello Goroutine: ", i)
}

func main() {
	var wg sync.WaitGroup

	for i := 0; i < 10; i++ {
		wg.Add(1)        // 标记新开了一个协程
		go hello(&wg, i) // 传递 WaitGroup 时需要传递指针
	}
	
	wg.Wait()
	fmt.Println("main goroutine done!")
}

```

需要注意的是：传递WaitGroup对象时需要传递指针。因为WaitGroup是结构体

#### sync.Once

`sync.Once` 是 Go 语言 `sync` 包中的一种同步原语。它可以确保一个操作（通常是一个函数）在程序的生命周期中**只被执行一次**，不论有多少 goroutine 同时调用该操作，这就保证了并发安全。

根据 `sync.Once` 的特点，很容易想到它的几种常见使用场景：

- **单例模式**：确保某个对象或配置仅初始化一次，例如使用单例模式初始化数据库连接池、配置文件加载等。
- **懒加载**：在需要时才加载某些资源，且保证它们只会加载一次。
- **并发安全的初始化**：当初始化过程涉及多个 goroutine 时，使用 `sync.Once` 保证初始化函数不会被重复调用。

使用示例：

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	var once sync.Once
	onceBody := func() {
		fmt.Println("Only once")
	}
	done := make(chan bool) // 阻塞式channel，用于同步
    // 创建10个协程执行同一个函数，最后只有一个能够执行成功。
	for i := 0; i < 10; i++ {
		go func() {
			once.Do(onceBody) // 只有一个协程会执行onceBody函数
			done <- true
		}()
	}
	for i := 0; i < 10; i++ {
		<-done
	}
}
```

注意：`var once sync.Once`只是声明，并没有初始化。也就是说：`sync.Once`**不需要显式初始化**。

##### sync.Once与init的区别

有时候我们使用init()方法进行初始化，init()方法是在其所在的package首次加载时执行的，而sync.Once可以在代码的任意位置初始化和调用，是在第一次用的它的时候才会初始化。

#### sync.Map

`go`内置的`map`并不是线程安全的。例如如下代码：

```go
package main

import (
	"fmt"
	"strconv"
	"sync"
)

var m = make(map[string]int)

func get(key string) int {
	return m[key]
}

func set(key string, value int) {
	m[key] = value
}

func main() {
	wg := sync.WaitGroup{}
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func(n int) {
			key := strconv.Itoa(n)
			set(key, n)
			fmt.Printf("k=:%v,v:=%v\n", key, get(key))
			wg.Done()
		}(i)
	}
	wg.Wait()
}

```

执行到一半报错：

```shell
fatal error: concurrent map writes
```

`sync`包提供了线程安全的`map`：`sync.Map`。`sync.Map`不用像内置的map一样使用make函数初始化就能直接使用。同时sync.Map内置了诸如`Store、Load、LoadOrStore、Delete、Range`等操作方法。

线程安全使用示例：

```go
package main

import (
	"fmt"
	"strconv"
	"sync"
)

var sMap = sync.Map{} // 不需要使用make函数

func main() {
	wg := sync.WaitGroup{}
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func(n int) {
			key := strconv.Itoa(n)     // int转string
			sMap.Store(key, n)         // 存储 key 和 value
			value, _ := sMap.Load(key) // 获取 key 对应的 value
			fmt.Printf("k=:%v,v:=%v\n", key, value)
			wg.Done()
		}(i)
	}
	wg.Wait()
}

```

#### sync.Pool

对象池。

简单使用：

```go
package main

import (
	"fmt"
	"sync"
)

type Student struct {
	Name string
	Age  int
}

func main() {
	pool := sync.Pool{
		New: func() interface{} {
			return &Student{
				Name: "zhangsan",
				Age:  18,
			}
		},
	}

	student := pool.Get().(*Student) // Get方法返回的是Any类型（interface{}），需要强转为Student类型
	println(student.Name, student.Age)
	fmt.Printf("addr is %p\n", student)

	pool.Put(student) // 如果不放回，后面取到的student1和前面的student就不是同一个对象

	student1 := pool.Get().(*Student)
	println(student1.Name, student1.Age)
	fmt.Printf("addr1 is %p\n", student1)
}

```

1. `sync.pool`主要是通过对象复用来降低GC带来的性能损耗，所以在高并发场景下，由于每个`goroutine`都可能过于频繁的创建一些大对象，造成GC压力很大。所以在高并发业务场景下出现 GC 问题时，可以使用 `sync.Pool` 减少 GC 负担
2. `sync.pool`不适合存储带状态的对象，比如socket 连接、数据库连接等，因为**pool里面的对象随时可能会被GC回收释放掉**。
3. 不适合需要控制缓存对象个数的场景，因为`Pool` 池里面的对象个数是随机变化的，因为池子里的对象是会被GC的，且释放时机是随机的。

#### sync.Cond

条件变量。用于在条件满足时唤醒正在等待的goroutine。

使用示例：

```go
type Queue struct {
    mu    sync.Mutex
    cond  *sync.Cond
    items []interface{}
}

func NewQueue() *Queue {
    q := &Queue{}
    q.cond = sync.NewCond(&q.mu)
    return q
}

// 生产者
func (q *Queue) Enqueue(item interface{}) {
    q.mu.Lock()
    defer q.mu.Unlock()
    
    q.items = append(q.items, item)
    q.cond.Signal() // 通知一个等待的 goroutine
}

// 消费者
func (q *Queue) Dequeue() interface{} {
    q.mu.Lock()
    defer q.mu.Unlock()
    
    for len(q.items) == 0 {
        q.cond.Wait() // 等待直到队列非空
    }
    
    item := q.items[0]
    q.items = q.items[1:]
    return item
}
```

