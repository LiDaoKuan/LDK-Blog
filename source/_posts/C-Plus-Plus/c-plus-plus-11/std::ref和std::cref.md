---
title: 引用封装: std::ref和std::cref
tags: [Cpp]
categories: Cpp
date: 2025-10-06
---

### 为什么需要引用封装

先看一段代码：
```cpp
#include <thread>

void increment(int &x) {
    x++;
}

int main() {
    int a = 5;
    std::thread t(increment, a); // ❌ 编译失败
    // std::thread t(increment, std::ref(a)); // 改成这样就能编译成功
    t.join();
    return 0;
}
```

上面函数为什么会编译失败呢？

因为`increment(int&)`函数需要引用类型的参数，而`std::thread`默认**按值复制参数**，它尝试将变量`a`拷贝一份传递给`increment`，这和期待的引用类型不一样，然后编译器报错。

### std::ref和std::cref是什么

- `std::ref(obj)`：返回一个**可修改引用**的包装器。
- `std::cref(obj)`：返回一个`const`引用的包装器。

这两个函数本质上返回 `std::reference_wrapper<T>` 类型，它可以模拟“按引用传参”的行为，但仍然以“按值”方式传递给调用者。其函数定义长这样：

```cpp
template <typename _Tp>
_GLIBCXX20_CONSTEXPR inline std::reference_wrapper<_Tp> ref(_Tp &__t) noexcept {
    return reference_wrapper<_Tp>(__t);
}
```

### 典型使用场景

#### 1. std::thread

```cpp
#include <thread>
#include <iostream>

void print(int& x) {
    std::cout << x << std::endl;
}

int main() {
    int a = 42;
    std::thread t(print, std::ref(a));  // ✅ 按引用传入
    t.join();
}
```

如上面所述，如果不加`std::ref`会报错。

#### 2. std::bind

这是个大坑

```cpp
#include <functional>

void set_to_100(int& x) {
    x = 100;
}

int main() {
    int a = 0;
    auto f = std::bind(set_to_100, std::ref(a));
    f();  // ✅ 成功修改 a
}
```

> 如果上面代码中不加`std::ref`，那么传参时变量`a`就会被拷贝，`f`执行时内部修改的就是拷贝后的变量而不是原变量。你就说坑不坑吧。

#### 传递函数对象

##### 1. 传递有状态的函数对象时

```cpp
struct Counter {
    int count = 0;
    void operator()(int x) {
        count += x;
    }
};

Counter c;
std::for_each(data.begin(), data.end(), std::ref(c)); // 使用std::ref保持状态
std::cout << "Total: " << c.count << std::endl; // 能访问到累计值

// 而普通传递会拷贝，每个元素使用不同的Counter实例
std::for_each(data.begin(), data.end(), c); // 错误：不会修改原始c
```

##### 2. 传递不可拷贝的函数对象

```cpp
struct NonCopyableFunctor {
    NonCopyableFunctor() = default;
    NonCopyableFunctor(const NonCopyableFunctor&) = delete;
    void operator()(int x) { std::cout << x << " "; }
};

NonCopyableFunctor f;
std::for_each(data.begin(), data.end(), std::ref(f)); // 唯一可行方式
// std::for_each(data.begin(), data.end(), f); // 错误，不可拷贝
```

##### 3. 需要共享状态的多处调用

```cpp
class Logger {
    std::mutex mtx;
    std::ofstream log_file;
public:
    void operator()(const std::string& msg) {
        std::lock_guard<std::mutex> lock(mtx);
        log_file << msg << std::endl;
    }
};

Logger logger;
std::thread t1([&] { std::for_each(data1.begin(), data1.end(), std::ref(logger)); });
std::thread t2([&] { std::for_each(data2.begin(), data2.end(), std::ref(logger)); });
```

### 注意

`std::ref`包装函数时是有性能损耗的，参照下面测试程序：

```cpp
#include <chrono>
#include <iostream>
#include <vector>
#include <algorithm>

void print(int x) {
    // 空函数体以减少IO开销
}

int main() {
    std::vector<int> data(100000000); // 一亿个int
    std::fill(data.begin(), data.end(), 42);

    // 测试1：函数指针
    auto start1 = std::chrono::high_resolution_clock::now();
    std::for_each(data.begin(), data.end(), print);
    auto end1 = std::chrono::high_resolution_clock::now();
    
    // 测试2：std::ref
    auto start2 = std::chrono::high_resolution_clock::now();
    std::for_each(data.begin(), data.end(), std::ref(print));
    auto end2 = std::chrono::high_resolution_clock::now();

    std::cout << "函数指针时间: " 
              << std::chrono::duration_cast<std::chrono::milliseconds>(end1 - start1).count()
              << "ms\n";
    std::cout << "std::ref时间: " 
              << std::chrono::duration_cast<std::chrono::milliseconds>(end2 - start2).count()
              << "ms\n";
}
```

输出：

```shell
函数指针时间: 142ms
std::ref时间: 646ms
```

