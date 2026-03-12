---
title: std::unique_lock和std::lock_guard
date: 2025-08-05
tags: [C++, 并发]
categories: C++
description: C++ 11 unique_lock和lock_guard
---

### lock_guard

std::lock_guard的作用：在生命周期内自动加锁和解锁。准确来说，是在构造函数内加锁，在析构函数内解锁。

先看使用示例：

```cpp
#include <iostream>
#include <thread>
#include <string>
#include <mutex>

using std::cout;
using std::endl;
using std::thread;

std::mutex mt;

void thread_task()
{
    for (int i = 0; i < 10; i++)
    {
        std::lock_guard<std::mutex> guard(mt);
        cout << "print thread: " << i << endl;
    }
}

int main()
{
    thread t(thread_task);
    for (int i = 0; i > -10; i--)
    {
        std::lock_guard<std::mutex> guard(mt);
        cout << "print main: " << i << endl;
    }
    t.join();
    return 0;
}
```

这里会有一个问题：在构造函数里面加锁，在析构函数中解锁，那么如果 lock_guard 的生命周期比较长，那么锁的粒度就会很大，影响程序效率。

于是就有了 unique_lock.

### unique_lock

unique_lock 与 lock_guard 一样，都会在构造函数中加锁。不同的是：

unique_lock 可以利用 unique.unlock() 来解锁，所以当你觉得锁的粒度太多的时候，可以利用这个来解锁。而析构的时候会判断当前锁的状态来决定是否解锁，如果当前状态已经是解锁状态了，那么就不会再次解锁，而如果当前状态是加锁状态，就会自动调用 unique.unlock() 来解锁。

使用示例：

```cpp
#include <iostream>
#include <thread>
#include <string>
#include <mutex>
using std::cout;
using std::endl;
using std::thread;

std::mutex mt;

void thread_task()
{
    for (int i = 0; i < 10; i++)
    {
        std::unique_lock<std::mutex> unique(mt);
        unique.unlock(); // 可以使用unique_lock提前解锁
        cout << "print thread: " << i << endl;
    }
}

int main()
{
    thread t(thread_task);
    for (int i = 0; i > -10; i--)
    {
        std::unique_lock<std::mutex> unique(mt);
        cout << "print main: " << i << endl;
    }
    t.join();
    return 0;
}
```

将 lock_guard 替换为 unique_lock 即可正常使用。
