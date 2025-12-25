---
title: std::packaged_task
tags: [Cpp, 多线程， 并发]
categories: Cpp
date: 2025-08-06
---

### std::packaged_task

C++11引入的模板类，用于封装可调用对象，以便异步执行该任务，并且可以通过`std::future`获取结果。通常与线程池一起使用。

#### 主要成员函数：

`get_future()`：返回一个`std::future`对象，用于获取任务的结果。

`operator()`：执行封装的任务。

`reset()`：重置任务。使其可以被重复使用。（如果在任务执行过程中重置任务将会抛出异常）

#### 使用案例

```cpp
#include <iostream>
#include <thread>
#include <future>
#include <chrono>

int calculateSum(int a, int b) {
    std::this_thread::sleep_for(std::chrono::seconds(2)); // 模拟长时间任务
    std::cout << "thread executing" << std::endl;
    return a + b;
}

int main() {
    // 创建一个 packaged_task，封装一个返回值为int的函数
    std::packaged_task<int(int, int)> task(calculateSum);

    // 获取与该任务关联的 future
    std::future<int> result = task.get_future();

    // 创建一个线程来执行任务
    std::thread t(std::ref(task), 10, 20); // 必须使用std::move或者std::ref来传递task

    std::cout << "Task is being executed asynchronously..." << std::endl;

    // 等待任务完成并获取结果
    std::cout << "The result of the task is: " << result.get() << std::endl;

    // task.reset(); // 如果此时任务执行了一半未完成，则会抛出异常。

    t.join(); // 等待线程结束

    task.reset(); // 重置任务, 重新执行。
    std::thread t1(std::ref(task), 10, 20);
    t1.join();
    
    task.reset();
    task(); // 直接在主线程中执行任务

    return 0;
}
```

注意：传递`std::packaged_task`时，必须使用`std::move`或者`std::ref`，因为`packaged_task`的拷贝构造函数不可用。