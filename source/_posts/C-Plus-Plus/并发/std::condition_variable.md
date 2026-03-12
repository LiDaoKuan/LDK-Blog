---
title: std::condition_variable
date: 2025-07-06
tags: [C++, 并发]
categories: C++
description: C++ 11 条件变量使用
---

### std::condition_variable

#### 主要函数

- `wait`函数
    函数原型：
    ```cpp
    void wait(unique_lock<mutex>& lock)

    template<class Predicate>
    void wait(unique_lock<mutex>& lock, Predicate pred)
    ```
    包含两种重载，第一种只包含 `unique_lock` 对象，另外一个 Predicate 对象（等待条件），这里**必须使用 `unique_lock`**，因为wait函数的工作原理：
    - 当前线程调用 wait() 后将被阻塞并且函数会解锁互斥量，直到另外某个线程调用 notify_one 或者 notify_all 唤醒当前线程；一旦当前线程获得通知(notify)，wait()函数也会自动调用 lock() 。同理**不能使用 lock_guard 对象**。
    - 如果 wait 没有第二个参数，第一次调用会默认为条件不成立，直接解锁互斥量并阻塞到本行，直到某一个线程调用 notify_one 或 notify_all 为止。被唤醒后，wait 重新尝试获取互斥量，如果得不到，线程会卡在这里，直到获取到互斥量，然后无条件地继续进行后面的操作。
    - 如果 wait 包含第二个参数，如果第二个参数不满足，那么 wait 将解锁互斥量并堵塞到本行，直到某一个线程调用 notify_one 或 notify_all 为止，被唤醒后，wait 重新尝试获取互斥量，如果得不到，线程会卡在这里，直到获取到互斥量，然后继续判断第二个参数，如果表达式为 false，wait对互斥量解锁，然后休眠，如果为true，则进行后面的操作。

    也就是说：wait函数会先解锁( `unlock` )互斥锁，然后阻塞，在被唤醒后会再次锁定( `lock` )互斥锁。

- `wait_for`函数
    函数原型：
    ```cpp
    template<class Rep, class Period>
    std::cv_status wait_for(std::unique_lock<std::mutex>& lock, const std::chrono::duration<Rep, Period>& timeout_duration)
    ```
    和wait不同的是，wait_for可以执行一个时间段，在线程收到唤醒通知或者时间超时之前，该线程都会 处于阻塞状态，如果收到唤醒通知或者时间超时，wait_for返回，剩下操作和wait类似。

- `wait_until`函数
    函数原型：
    ```cpp
    template <class Clock, class Duration>
    cv_status wait_until (unique_lock<mutex>& lck,const chrono::time_point<Clock,Duration>& abs_time);

    template <class Clock, class Duration, class Predicate>
    bool wait_until (unique_lock<mutex>& lck,const chrono::time_point<Clock,Duration>& abs_time,Predicate pred);
    ```
    与wait_for类似，只是wait_until可以指定一个时间点，在当前线程收到通知或者指定的时间点超时之 前，该线程都会处于阻塞状态。如果超时或者收到唤醒通知，wait_until返回，剩下操作和wait类似 。

- `notify_one`函数
    函数原型：
    ```cpp
    void notify_one() noexcept;
    ```
- `notify_all`函数
    ```cpp
    void notify_all() noexcept;
    ```

#### 简单使用

用条件变量配合互斥锁实现一个同步队列

```cpp
// main.h
#ifndef SYNC_QUEUE_H
#define SYNC_QUEUE_H

#include <list>
#include <mutex>
#include <condition_variable>
#include <thread>
#include <iostream>

template <typename T>
class SyncQueue
{
public:
    SyncQueue(int capacity) : capacity_(capacity) {};

    void put(T t)
    {
        std::unique_lock<std::mutex> uniquelock(mtx);
        // 循环防止虚假唤醒
        while (isFull())
        {
            // 队列已满
            std::cout << "full wait..." << std::endl;
            not_full.wait(uniquelock); // 等待消费者消费数据
        }
        que.push_back(std::move(t)); // 放入数据
        not_empty.notify_one();      // 通知消费者数据到来
    }

    T get()
    {
        std::unique_lock<std::mutex> uniquelock(mtx);
        // 循环防止虚假唤醒
        while (isEmpty())
        {
            std::cout << "empty wait..." << std::endl;
            not_empty.wait(uniquelock); // 等待生产者生产数据
        }
        T temp = que.front();
        que.pop_front();
        not_full.notify_one(); // 通知生产者数据已经被取走
        return temp;
    }

    bool isFull()
    {
        return que.size() == capacity_;
    }

    bool isEmpty()
    {
        return que.empty();
    }

    int capacity()
    {
        return que.size();
    }

    int Count()
    {
        return que.size();
    }

private:
    std::list<T> que;
    std::mutex mtx;
    std::condition_variable not_empty; // 不为空的条件变量
    std::condition_variable not_full;  // 队列未满的条件变量
    int capacity_;                     // 队列容量
};

#endif
```

测试程序：

```cpp
#include <iostream>
#include <atomic>
#include "main.h"

using namespace std;

SyncQueue<int> syncQueue(5);

void PutDatas()
{
    for (int i = 0; i < 20; ++i)
    {
        syncQueue.put(888);
    }
    std::cout << "PutDatas finish\n";
}
void TakeDatas()
{
    int x = 0;
    for (int i = 0; i < 20; ++i)
    {
        x = syncQueue.get();
        std::cout << x << std::endl;
    }
    std::cout << "TakeDatas finish\n";
}
int main(void)
{
    std::thread t1(PutDatas);
    std::thread t2(TakeDatas);
    t1.join();
    t2.join();
    std::cout << "main finish\n";
    return 0;
}
```

对于上述代码中的while循环部分：

```cpp
// 循环处理虚假唤醒
while (isEmpty())
{
    std::cout << "empty wait..." << std::endl;
    not_empty.wait(uniquelock); // 等待生产者生产数据
}
```

可以简化为：

```cpp
not_empty.wait(uniquelock, [this]{return !isEmpty();});
```

简化后，依旧能处理虚假唤醒问题。

因为 not_empty 被唤醒后，会先判断后面 lambda 表达式中的条件，如果条件为 `true` ( `isEmpty()` 为 `false` )，则执行后续的代码。否则继续阻塞，等待下次被唤醒。
